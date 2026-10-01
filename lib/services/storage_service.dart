import 'dart:io';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// Service responsible for handling image uploads to Supabase Storage.
class StorageService {
  static const String bucketName = 'hazard-reports';

  /// Upload a photo file for a hazard report and return the public URL.
  static Future<String?> uploadReportImage({
    required File imageFile,
    required String reportId,
    String? userId,
  }) async {
    final client = SupabaseService.instance.client;
    if (client == null) {
      debugPrint('[StorageService] Supabase client unavailable for upload.');
      return null;
    }

    try {
      final userPath = userId ?? 'anonymous';
      final fileExt = imageFile.path.split('.').last;
      final filePath = 'reports/$userPath/$reportId.$fileExt';

      final bytes = await imageFile.readAsBytes();

      debugPrint('[StorageService] Uploading image to $bucketName/$filePath...');
      await client.storage.from(bucketName).uploadBinary(
            filePath,
            bytes,
          );

      final publicUrl = client.storage.from(bucketName).getPublicUrl(filePath);
      debugPrint('[StorageService] Upload successful: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('[StorageService] Image upload error: $e');
      return null;
    }
  }
}
