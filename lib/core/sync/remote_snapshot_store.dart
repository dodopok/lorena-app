import '../../app/models.dart';

/// Remote persistence boundary for the authenticated user's app snapshot.
///
/// Implementations are expected to keep the local/offline store as the source
/// used by the UI. A remote implementation may enqueue writes while offline.
abstract interface class RemoteSnapshotStore {
  Future<AppSnapshot?> read();

  Future<void> write(AppSnapshot snapshot);

  Future<void> clear();
}
