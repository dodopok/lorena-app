import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Categories that are allowed below a user's private photo directory.
enum PhotoCategory { gratitude, bookCover, wishlist, receipt }

extension PhotoCategoryPath on PhotoCategory {
  String get storageName => switch (this) {
    PhotoCategory.gratitude => 'gratitude',
    // Storage follows the documented collection name, while the domain
    // category remains bookCover for callers.
    PhotoCategory.bookCover => 'books',
    PhotoCategory.wishlist => 'wishlist',
    PhotoCategory.receipt => 'receipt',
  };
}

/// Default upper bound for a single uploaded photo.
const int defaultMaxPhotoBytes = 10 * 1024 * 1024;

const Map<String, String> _imageContentTypes = <String, String>{
  '.avif': 'image/avif',
  '.bmp': 'image/bmp',
  '.gif': 'image/gif',
  '.heic': 'image/heic',
  '.jpeg': 'image/jpeg',
  '.jpg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
};

/// Builds the only path shape accepted by the private photo storage gateway.
///
/// The uid and id are path segments, never arbitrary paths. Invalid segments
/// are rejected instead of being normalized into a different user's path.
String buildPhotoStoragePath({
  required String uid,
  required PhotoCategory category,
  required String id,
  required String extension,
}) {
  _validatePathSegment(uid, 'uid');
  _validatePathSegment(id, 'id');
  final safeExtension = deriveSafePhotoExtension(extension);
  return 'users/$uid/${category.storageName}/$id/image$safeExtension';
}

/// Returns a whitelisted image extension, including its leading dot.
///
/// Unknown, missing, or malformed extensions deliberately fall back to JPEG.
/// This helper only derives a name; it does not claim that the bytes are a
/// valid JPEG or otherwise inspect their contents.
String deriveSafePhotoExtension(String? fileNameOrExtension) {
  if (fileNameOrExtension == null || fileNameOrExtension.trim().isEmpty) {
    return '.jpg';
  }

  final lastSegment = fileNameOrExtension
      .trim()
      .toLowerCase()
      .split(RegExp(r'[/\\]'))
      .last;
  final dot = lastSegment.lastIndexOf('.');
  final candidate = (dot < 0 ? lastSegment : lastSegment.substring(dot + 1));
  final extension = '.$candidate';
  return _imageContentTypes.containsKey(extension) ? extension : '.jpg';
}

/// Returns the content type paired with [fileNameOrExtension].
String photoContentType(String fileNameOrExtension) {
  final extension = deriveSafePhotoExtension(fileNameOrExtension);
  return _imageContentTypes[extension]!;
}

/// Validates a byte count without reading or logging the byte contents.
void validatePhotoSize(int sizeBytes, {required int maxBytes}) {
  if (maxBytes <= 0) {
    throw ArgumentError('maxBytes must be greater than zero.');
  }
  if (sizeBytes <= 0) {
    throw ArgumentError('Photo bytes must not be empty.');
  }
  if (sizeBytes > maxBytes) {
    throw ArgumentError('Photo exceeds the configured maximum size.');
  }
}

/// Validates [bytes] against [maxBytes] without exposing their contents.
void validatePhotoBytes(List<int> bytes, {required int maxBytes}) {
  validatePhotoSize(bytes.length, maxBytes: maxBytes);
}

abstract interface class PhotoStorageGateway {
  Future<String> uploadBytes({
    required String uid,
    required PhotoCategory category,
    required String id,
    required List<int> bytes,
    String? fileName,
  });

  Future<String> uploadFile({
    required String uid,
    required PhotoCategory category,
    required String id,
    required File file,
    String? fileName,
  });

  Future<void> delete({
    required String uid,
    required PhotoCategory category,
    required String id,
    String? fileName,
  });

  Future<String> downloadUrl(String storagePath);
}

/// Firebase Storage implementation for private user-owned photos.
///
/// Storage security rules must enforce the corresponding ownership check for
/// `users/{uid}/...`; this gateway keeps the client path deterministic but is
/// not a substitute for those rules.
class FirebasePhotoStorage implements PhotoStorageGateway {
  FirebasePhotoStorage({
    FirebaseStorage? storage,
    int maxBytes = defaultMaxPhotoBytes,
  }) : _storage = storage ?? FirebaseStorage.instance,
       maxBytes = _validatedMaxBytes(maxBytes);

  final FirebaseStorage _storage;
  final int maxBytes;

  @override
  Future<String> uploadBytes({
    required String uid,
    required PhotoCategory category,
    required String id,
    required List<int> bytes,
    String? fileName,
  }) async {
    validatePhotoBytes(bytes, maxBytes: maxBytes);
    final extension = deriveSafePhotoExtension(fileName);
    final reference = _reference(
      uid: uid,
      category: category,
      id: id,
      extension: extension,
    );
    final metadata = SettableMetadata(contentType: photoContentType(extension));
    await reference.putData(Uint8List.fromList(bytes), metadata);
    return reference.getDownloadURL();
  }

  @override
  Future<String> uploadFile({
    required String uid,
    required PhotoCategory category,
    required String id,
    required File file,
    String? fileName,
  }) async {
    final byteLength = await file.length();
    validatePhotoSize(byteLength, maxBytes: maxBytes);
    final sourceName = fileName ?? _fileName(file);
    final extension = deriveSafePhotoExtension(sourceName);
    final reference = _reference(
      uid: uid,
      category: category,
      id: id,
      extension: extension,
    );
    final metadata = SettableMetadata(contentType: photoContentType(extension));
    await reference.putFile(file, metadata);
    return reference.getDownloadURL();
  }

  @override
  Future<void> delete({
    required String uid,
    required PhotoCategory category,
    required String id,
    String? fileName,
  }) async {
    final extension = deriveSafePhotoExtension(fileName);
    await _reference(
      uid: uid,
      category: category,
      id: id,
      extension: extension,
    ).delete();
  }

  @override
  Future<String> downloadUrl(String storagePath) =>
      _storage.ref().child(_validateStoragePath(storagePath)).getDownloadURL();

  Reference _reference({
    required String uid,
    required PhotoCategory category,
    required String id,
    required String extension,
  }) => _storage.ref().child(
    buildPhotoStoragePath(
      uid: uid,
      category: category,
      id: id,
      extension: extension,
    ),
  );

  static String _fileName(File file) {
    final segments = file.uri.pathSegments;
    return segments.isEmpty ? '' : segments.last;
  }

  static int _validatedMaxBytes(int value) {
    if (value <= 0) {
      throw ArgumentError('maxBytes must be greater than zero.');
    }
    return value;
  }

  static String _validateStoragePath(String value) {
    final normalized = value.trim();
    if (!normalized.startsWith('users/') ||
        normalized.contains('..') ||
        normalized.contains('\\') ||
        normalized.contains('//')) {
      throw ArgumentError.value(value, 'storagePath');
    }
    return normalized;
  }
}

void _validatePathSegment(String value, String fieldName) {
  final trimmed = value.trim();
  final hasControlCharacter = value.codeUnits.any(
    (codeUnit) => codeUnit < 0x20 || codeUnit == 0x7f,
  );
  if (value.isEmpty || value != trimmed || value == '.' || value == '..') {
    throw ArgumentError('Invalid $fieldName for a photo storage path.');
  }
  if (value.contains('/') || value.contains('\\') || hasControlCharacter) {
    throw ArgumentError('Invalid $fieldName for a photo storage path.');
  }
}
