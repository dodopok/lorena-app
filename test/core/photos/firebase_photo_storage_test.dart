import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/photos/firebase_photo_storage.dart';

void main() {
  group('photo storage path helpers', () {
    test('builds the private path with a safe extension', () {
      expect(
        buildPhotoStoragePath(
          uid: 'user-123',
          category: PhotoCategory.bookCover,
          id: 'book-456',
          extension: 'cover.PNG',
        ),
        'users/user-123/books/book-456/image.png',
      );
    });

    test('maps every allowed category to its storage segment', () {
      expect(PhotoCategory.gratitude.storageName, 'gratitude');
      expect(PhotoCategory.bookCover.storageName, 'books');
      expect(PhotoCategory.wishlist.storageName, 'wishlist');
      expect(PhotoCategory.receipt.storageName, 'receipt');
    });

    test('rejects path traversal and empty path segments', () {
      expect(
        () => buildPhotoStoragePath(
          uid: '../user',
          category: PhotoCategory.gratitude,
          id: 'entry',
          extension: '.jpg',
        ),
        throwsArgumentError,
      );
      expect(
        () => buildPhotoStoragePath(
          uid: 'user',
          category: PhotoCategory.gratitude,
          id: 'folder/photo',
          extension: '.jpg',
        ),
        throwsArgumentError,
      );
      expect(
        () => buildPhotoStoragePath(
          uid: 'user',
          category: PhotoCategory.gratitude,
          id: '',
          extension: '.jpg',
        ),
        throwsArgumentError,
      );
    });
  });

  group('photo extension and content type helpers', () {
    test('keeps supported extensions and normalizes case', () {
      expect(deriveSafePhotoExtension('photo.JPEG'), '.jpeg');
      expect(deriveSafePhotoExtension('.webp'), '.webp');
      expect(photoContentType('photo.png'), 'image/png');
      expect(photoContentType('.heic'), 'image/heic');
    });

    test('falls back to a safe JPEG extension for unknown input', () {
      expect(deriveSafePhotoExtension(null), '.jpg');
      expect(deriveSafePhotoExtension('photo'), '.jpg');
      expect(deriveSafePhotoExtension('photo.exe'), '.jpg');
      expect(photoContentType('photo.exe'), 'image/jpeg');
    });
  });

  group('photo size validation', () {
    test('accepts a non-empty payload at the maximum boundary', () {
      expect(
        () => validatePhotoBytes(List<int>.filled(4, 1), maxBytes: 4),
        returnsNormally,
      );
      expect(() => validatePhotoSize(4, maxBytes: 4), returnsNormally);
    });

    test('rejects empty, oversized, and invalid limits', () {
      expect(
        () => validatePhotoBytes(const <int>[], maxBytes: 4),
        throwsArgumentError,
      );
      expect(() => validatePhotoSize(5, maxBytes: 4), throwsArgumentError);
      expect(() => validatePhotoSize(1, maxBytes: 0), throwsArgumentError);
    });
  });
}
