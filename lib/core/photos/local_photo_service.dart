import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

enum LocalPhotoKind { gratitude, bookCover, wishlist }

abstract interface class PhotoPicker {
  Future<XFile?> pickImage({required ImageSource source});
}

class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<XFile?> pickImage({required ImageSource source}) => _picker.pickImage(
    source: source,
    imageQuality: 88,
    maxWidth: 2400,
    maxHeight: 2400,
  );
}

/// Seleciona uma imagem e copia a posse local para o suporte do aplicativo.
/// Nenhum upload ou caminho temporário do seletor é tratado como persistente.
class LocalPhotoService {
  LocalPhotoService({PhotoPicker? picker})
    : _picker = picker ?? ImagePickerPhotoPicker();

  final PhotoPicker _picker;

  Future<String?> pickAndStore(
    LocalPhotoKind kind, {
    ImageSource source = ImageSource.gallery,
  }) async {
    final selected = await _picker.pickImage(source: source);
    if (selected == null) return null;
    return storeSelected(selected, kind);
  }

  Future<String> storeSelected(XFile selected, LocalPhotoKind kind) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final directory = Directory(
      '${supportDirectory.path}/lume_photos/${kind.name}',
    );
    await directory.create(recursive: true);

    final extension = _safeExtension(
      selected.name.isEmpty ? selected.path : selected.name,
    );
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$extension';
    final destination = File('${directory.path}/$fileName');
    await destination.writeAsBytes(await selected.readAsBytes(), flush: true);
    return destination.path;
  }

  /// Removes one file only when it belongs to the app's private media folder.
  /// Paths coming from a remote document or another app are ignored.
  Future<void> deleteStored(String path) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final root = Directory('${supportDirectory.path}/lume_photos');
    final normalizedRoot = _normalizedPath(root.path);
    final normalizedPath = _normalizedPath(path);
    if (!normalizedPath.startsWith('$normalizedRoot/')) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  Future<void> clearStoredPhotos() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final directory = Directory('${supportDirectory.path}/lume_photos');
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  static String _normalizedPath(String value) =>
      value.replaceAll('\\', '/').replaceAll(RegExp(r'/+'), '/');

  static String _safeExtension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '.jpg';
    final extension = name.substring(dot).toLowerCase();
    return const {'.jpg', '.jpeg', '.png', '.heic', '.webp'}.contains(extension)
        ? extension
        : '.jpg';
  }
}
