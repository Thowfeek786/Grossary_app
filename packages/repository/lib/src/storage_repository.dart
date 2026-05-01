import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProductImage(File imageFile, String productId) async {
    final ext = path.extension(imageFile.path);
    final ref = _storage
        .ref()
        .child('products')
        .child(productId)
        .child('${DateTime.now().millisecondsSinceEpoch}$ext');
    final task = await ref.putFile(imageFile);
    return await task.ref.getDownloadURL();
  }

  Future<String> uploadUserAvatar(File imageFile, String userId) async {
    final ext = path.extension(imageFile.path);
    final ref = _storage.ref().child('users').child(userId).child('avatar$ext');
    final task = await ref.putFile(imageFile);
    return await task.ref.getDownloadURL();
  }

  Future<String> uploadBannerImage(File imageFile, String bannerId) async {
    final ext = path.extension(imageFile.path);
    final ref = _storage.ref().child('banners').child('$bannerId$ext');
    final task = await ref.putFile(imageFile);
    return await task.ref.getDownloadURL();
  }

  Future<String> uploadCategoryImage(File imageFile, String categoryId) async {
    final ext = path.extension(imageFile.path);
    final ref = _storage.ref().child('categories').child('$categoryId$ext');
    final task = await ref.putFile(imageFile);
    return await task.ref.getDownloadURL();
  }

  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (_) {}
  }
}
