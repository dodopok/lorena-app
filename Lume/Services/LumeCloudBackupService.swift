import BackgroundTasks
import CloudKit
import Combine
import Foundation
import SwiftData

/// Keeps complete daily snapshots in the user's private iCloud database.
/// Access comes from the signed-in iCloud account and the app entitlement.
@MainActor
final class LumeCloudBackupService: ObservableObject {
    static let shared = LumeCloudBackupService()
    static let taskIdentifier = "com.dodopok.lume.daily-backup"

    private static let containerIdentifier = "iCloud.com.dodopok.lume"
    private static let recordType = "LumeDailyBackup"
    private static let assetField = "backupJSON"
    private static let indexRecordName = "backup-latest"
    private static let lastBackupDayKey = "lume.cloudBackup.lastDay"
    private static let lastBackupDateKey = "lume.cloudBackup.lastDate"

    struct BackupResult {
        let success: Bool
        let message: String
    }

    @Published private(set) var isWorking = false
    @Published private(set) var isCheckingStatus = false
    @Published private(set) var lastBackupDate: Date?
    @Published private(set) var availableBackupDate: Date?
    @Published private(set) var statusMessage = ""

    private let container: CKContainer
    private let defaults: UserDefaults

    private init() {
        container = CKContainer(identifier: Self.containerIdentifier)
        defaults = UserDefaults(suiteName: LumeModelContainer.appGroupID) ?? .standard
        lastBackupDate = defaults.object(forKey: Self.lastBackupDateKey) as? Date
    }

    /// Must be called during app launch, before the system can deliver a
    /// background task.
    static func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let task = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }

            let run = LumeBackupTaskRun(task: task)
            task.expirationHandler = {
                Task { @MainActor in run.expire() }
            }
            Task { @MainActor in run.start() }
        }
    }

    /// iOS decides the exact execution time. This asks for a run shortly
    /// after the next local midnight; opening the app also checks immediately.
    static func scheduleNextBackup() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)

        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let tomorrow = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: .now)
        ) ?? Date.now.addingTimeInterval(24 * 60 * 60)
        request.earliestBeginDate = tomorrow.addingTimeInterval(5 * 60)

        try? BGTaskScheduler.shared.submit(request)
    }

    func backupIfNeeded() async -> BackupResult {
        if Task.isCancelled {
            return BackupResult(success: false, message: "O backup foi interrompido pelo sistema.")
        }
        let day = Self.dayKey(for: .now)
        if defaults.string(forKey: Self.lastBackupDayKey) == day {
            return BackupResult(success: true, message: "O backup de hoje já foi feito.")
        }
        return await performBackup(for: day)
    }

    func backupNow() async -> BackupResult {
        await performBackup(for: Self.dayKey(for: .now))
    }

    func refreshBackupStatus() async {
        guard !isCheckingStatus, !isWorking else { return }
        isCheckingStatus = true
        defer { isCheckingStatus = false }

        do {
            try await requireAvailableAccount()
            let database = container.privateCloudDatabase
            let indexID = CKRecord.ID(recordName: Self.indexRecordName)
            if let index = try await fetchRecord(with: indexID, from: database),
               let recordName = index["backupRecordName"] as? String,
               let record = try await fetchRecord(
                    with: CKRecord.ID(recordName: recordName),
                    from: database
               ) {
                availableBackupDate = (record["exportedAt"] as? Date) ?? (index["exportedAt"] as? Date)
                statusMessage = ""
                return
            }

            if let record = try await latestBackupRecord(in: database) {
                availableBackupDate = record["exportedAt"] as? Date
            } else {
                availableBackupDate = nil
            }
            statusMessage = ""
        } catch {
            statusMessage = Self.userMessage(for: error)
        }
    }

    func restoreLatestBackup(into context: ModelContext) async -> BackupResult {
        guard !isWorking else {
            return BackupResult(success: false, message: "Já existe uma operação de backup em andamento.")
        }

        isWorking = true
        defer { isWorking = false }

        do {
            try await requireAvailableAccount()

            let database = container.privateCloudDatabase
            let indexID = CKRecord.ID(recordName: Self.indexRecordName)
            let indexRecord = try await fetchRecord(with: indexID, from: database)
            let backupRecord: CKRecord

            if let recordName = indexRecord?["backupRecordName"] as? String {
                let backupID = CKRecord.ID(recordName: recordName)
                if let indexedRecord = try await fetchRecord(with: backupID, from: database) {
                    backupRecord = indexedRecord
                } else if let fallbackRecord = try await latestBackupRecord(in: database) {
                    backupRecord = fallbackRecord
                } else {
                    throw BackupError.noBackupFound
                }
            } else {
                guard let latestRecord = try await latestBackupRecord(in: database) else {
                    throw BackupError.noBackupFound
                }
                backupRecord = latestRecord
            }

            guard let asset = backupRecord[Self.assetField] as? CKAsset,
                  let sourceURL = asset.fileURL else {
                throw BackupError.invalidBackup
            }

            let destinationURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("lume-cloud-restore-\(UUID().uuidString).json")
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            defer { try? FileManager.default.removeItem(at: destinationURL) }

            let importResult = LumeBackupImportService.restoreBackupJSON(from: destinationURL, into: context)
            let day = (backupRecord["day"] as? String) ?? "uma data anterior"
            statusMessage = importResult.errors.isEmpty ? "" : importResult.message

            if importResult.errors.isEmpty {
                return BackupResult(
                    success: true,
                    message: "Backup de \(day) restaurado. \(importResult.message)"
                )
            }

            return BackupResult(
                success: false,
                message: "Backup de \(day) encontrado, mas a importação teve problemas. \(importResult.message)"
            )
        } catch {
            let message = Self.userMessage(for: error)
            statusMessage = message
            return BackupResult(success: false, message: message)
        }
    }

    private func performBackup(for day: String) async -> BackupResult {
        guard !isWorking else {
            return BackupResult(success: false, message: "Já existe uma operação de backup em andamento.")
        }

        isWorking = true
        defer { isWorking = false }

        var exportURL: URL?
        defer {
            if let exportURL {
                try? FileManager.default.removeItem(at: exportURL)
            }
        }

        do {
            try await requireAvailableAccount()
            try Task.checkCancellation()

            let generatedURL = try LumeBackupArchiveService.writeBackupExport()
            try Task.checkCancellation()
            exportURL = generatedURL

            let database = container.privateCloudDatabase
            let previousRecordCount = await indexedBackupRecordCount(in: database)
            let currentRecordCount = Self.recordCount(in: generatedURL)
            try Task.checkCancellation()
            let shouldAdvanceLatest = !(previousRecordCount ?? 0 > 1 && currentRecordCount <= 1)
            let backupRecordName = shouldAdvanceLatest ? "backup-\(day)" : "snapshot-\(day)"
            let backupRecordID = CKRecord.ID(recordName: backupRecordName)
            let record = try await fetchRecord(with: backupRecordID, from: database)
                ?? CKRecord(recordType: Self.recordType, recordID: backupRecordID)
            try Task.checkCancellation()
            record["kind"] = (shouldAdvanceLatest ? "daily" : "snapshot") as CKRecordValue
            record["day"] = day as CKRecordValue
            record["exportedAt"] = Date.now as CKRecordValue
            record["format"] = "lume-backup-v1" as CKRecordValue
            record["recordCount"] = currentRecordCount as CKRecordValue
            record[Self.assetField] = CKAsset(fileURL: generatedURL)

            _ = try await save(record, in: database)
            try Task.checkCancellation()

            // Keep dated backups, and point the index only at a complete snapshot.
            if shouldAdvanceLatest {
                let indexID = CKRecord.ID(recordName: Self.indexRecordName)
                let index = try await fetchRecord(with: indexID, from: database)
                    ?? CKRecord(recordType: Self.recordType, recordID: indexID)
                try Task.checkCancellation()
                index["kind"] = "index" as CKRecordValue
                index["backupRecordName"] = backupRecordName as CKRecordValue
                index["day"] = day as CKRecordValue
                index["exportedAt"] = Date.now as CKRecordValue
                _ = try await save(index, in: database)
                try Task.checkCancellation()
            }

            let now = Date.now
            defaults.set(day, forKey: Self.lastBackupDayKey)
            defaults.set(now, forKey: Self.lastBackupDateKey)
            lastBackupDate = now
            if shouldAdvanceLatest {
                availableBackupDate = now
            }
            statusMessage = ""
            Self.scheduleNextBackup()

            let message = shouldAdvanceLatest
                ? "Backup diário salvo no iCloud (\(day))."
                : "Snapshot diário salvo (\(day)); o backup anterior foi preservado porque este aparelho ainda tem apenas o perfil."
            return BackupResult(success: true, message: message)
        } catch {
            let message = Self.userMessage(for: error)
            statusMessage = message
            Self.scheduleNextBackup()
            return BackupResult(success: false, message: message)
        }
    }

    private func requireAvailableAccount() async throws {
        let status = try await accountStatus()
        switch status {
        case .available:
            return
        case .noAccount:
            throw BackupError.noAccount
        case .restricted:
            throw BackupError.restricted
        case .temporarilyUnavailable:
            throw BackupError.temporarilyUnavailable
        case .couldNotDetermine:
            throw BackupError.accountUnavailable
        @unknown default:
            throw BackupError.accountUnavailable
        }
    }

    private func accountStatus() async throws -> CKAccountStatus {
        try await withCheckedThrowingContinuation { continuation in
            container.accountStatus { status, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: status)
                }
            }
        }
    }

    private func save(_ record: CKRecord, in database: CKDatabase) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            database.save(record) { savedRecord, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let savedRecord {
                    continuation.resume(returning: savedRecord)
                } else {
                    continuation.resume(throwing: BackupError.noRecordReturned)
                }
            }
        }
    }

    private func fetchRecord(with id: CKRecord.ID, from database: CKDatabase) async throws -> CKRecord? {
        try await withCheckedThrowingContinuation { continuation in
            database.fetch(withRecordID: id) { record, error in
                if let ckError = error as? CKError, ckError.code == .unknownItem {
                    continuation.resume(returning: nil)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: record)
                }
            }
        }
    }

    private func latestBackupRecord(in database: CKDatabase) async throws -> CKRecord? {
        let query = CKQuery(recordType: Self.recordType, predicate: NSPredicate(value: true))
        let result = try await database.records(
            matching: query,
            desiredKeys: [Self.assetField, "kind", "day", "exportedAt"],
            resultsLimit: 50
        )

        let records: [CKRecord] = result.matchResults.compactMap { (_, value) -> CKRecord? in
            guard let record = try? value.get(),
                  (record["kind"] as? String) == "daily",
                  record[Self.assetField] as? CKAsset != nil else {
                return nil
            }
            return record
        }

        return records.sorted {
            let left = ($0["exportedAt"] as? Date) ?? .distantPast
            let right = ($1["exportedAt"] as? Date) ?? .distantPast
            return left > right
        }
        .first
    }

    private func indexedBackupRecordCount(in database: CKDatabase) async -> Int? {
        guard let index = try? await fetchRecord(
            with: CKRecord.ID(recordName: Self.indexRecordName),
            from: database
        ),
        let recordName = index["backupRecordName"] as? String else {
            return nil
        }

        guard let backup = try? await fetchRecord(
            with: CKRecord.ID(recordName: recordName),
            from: database
        ) else {
            return nil
        }

        return backup["recordCount"] as? Int
    }

    private enum BackupError: LocalizedError {
        case noAccount
        case restricted
        case temporarilyUnavailable
        case accountUnavailable
        case noRecordReturned
        case noBackupFound
        case invalidBackup

        var errorDescription: String? {
            switch self {
            case .noAccount:
                "Nenhuma conta do iCloud está conectada neste iPhone."
            case .restricted:
                "O acesso ao iCloud está restrito neste iPhone."
            case .temporarilyUnavailable:
                "O iCloud está temporariamente indisponível. Tente novamente mais tarde."
            case .accountUnavailable:
                "Não foi possível verificar a conta do iCloud."
            case .noRecordReturned:
                "O iCloud não confirmou o backup."
            case .noBackupFound:
                "Ainda não existe um backup diário no iCloud."
            case .invalidBackup:
                "O backup encontrado não contém um arquivo recuperável."
            }
        }
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func recordCount(in url: URL) -> Int {
        guard let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let counts = root["counts"] as? [String: Any],
              let total = counts["total"] as? NSNumber else {
            return 0
        }
        return total.intValue
    }

    private static func userMessage(for error: Error) -> String {
        if error is CancellationError {
            return "O iOS interrompeu o backup em segundo plano; ele tentará novamente."
        }
        if let description = (error as? LocalizedError)?.errorDescription {
            return description
        }

        if let error = error as? CKError {
            switch error.code {
            case .notAuthenticated:
                return "O iCloud não está autenticado neste iPhone."
            case .networkFailure, .networkUnavailable:
                return "Sem conexão para falar com o iCloud. O app tentará novamente depois."
            case .quotaExceeded:
                return "O espaço do iCloud está cheio para este backup."
            case .permissionFailure:
                return "O container do iCloud ainda não está autorizado para este app."
            case .serverRejectedRequest, .serviceUnavailable, .requestRateLimited:
                return "O iCloud recusou temporariamente o backup. O app tentará novamente."
            default:
                break
            }
        }

        return "Não foi possível concluir o backup no iCloud: \(error.localizedDescription)"
    }
}

@MainActor
private final class LumeBackupTaskRun {
    private let task: BGProcessingTask
    private var operation: Task<Void, Never>?
    private var isCompleted = false

    init(task: BGProcessingTask) {
        self.task = task
    }

    func start() {
        guard !isCompleted else { return }
        operation = Task { @MainActor [weak self] in
            guard let self else { return }
            let result = await LumeCloudBackupService.shared.backupIfNeeded()
            guard !isCompleted else { return }
            finish(success: result.success)
            LumeCloudBackupService.scheduleNextBackup()
        }
    }

    func expire() {
        guard !isCompleted else { return }
        operation?.cancel()
        finish(success: false)
        LumeCloudBackupService.scheduleNextBackup()
    }

    private func finish(success: Bool) {
        guard !isCompleted else { return }
        isCompleted = true
        task.expirationHandler = nil
        task.setTaskCompleted(success: success)
    }
}
