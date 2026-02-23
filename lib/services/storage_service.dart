import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Storage service for file upload and retrieval
class StorageService {
  final _client = SupabaseService.client;

  /// Upload an image and return the public URL
  Future<String?> uploadImage({
    required File file,
    required String bucket,
    String? folder,
    bool logErrors = true,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = folder != null ? '$folder/$fileName' : fileName;

      await _client.storage.from(bucket).upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = _client.storage.from(bucket).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      if (logErrors) {
        debugPrint('Error uploading image: $e');
      }
      return null;
    }
  }

  /// Upload profile image
  Future<String?> uploadProfileImage(File file) async {
    final userId = SupabaseService.currentUser?.id;
    return uploadImage(
      file: file,
      bucket: 'avatars',
      folder: userId,
    );
  }

  /// Upload pet image
  Future<String?> uploadPetImage(File file, String petId) async {
    return uploadImage(
      file: file,
      bucket: 'pets',
      folder: petId,
    );
  }

  /// Upload payment screenshot.
  ///
  /// Primary target is `transactions` bucket. If that bucket is not available
  /// in the project, falls back to `posts` to avoid blocking payment flow.
  Future<String?> uploadPaymentScreenshot(File file, {String? folder}) async {
    final baseFolder = folder ?? DateTime.now().millisecondsSinceEpoch.toString();

    final primary = await uploadImage(
      file: file,
      bucket: 'transactions',
      folder: 'payments/$baseFolder',
      logErrors: false,
    );

    if (primary != null) return primary;

    debugPrint('transactions bucket unavailable, falling back to posts bucket for payment screenshot');

    return uploadImage(
      file: file,
      bucket: 'posts',
      folder: 'payment_screenshots/$baseFolder',
    );
  }

  /// Delete a file from storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  /// Get public URL for a file
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }
}
