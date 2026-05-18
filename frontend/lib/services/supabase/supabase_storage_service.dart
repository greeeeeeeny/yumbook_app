import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/core/supabase/supabase_client.dart';

/// Supabase Storage 업로드 헬퍼.
/// food_records 버킷(public)에 user/{userId}/{timestamp}_{name} 으로 업로드.
class SupabaseStorageService {
  SupabaseStorageService._();

  static const String foodRecordBucket = 'food_records';

  static SupabaseClient get _client => SupabaseClientManager.client;

  /// 바이트 데이터를 업로드하고 public URL 을 반환.
  /// [path] 없으면 user/{uid}/{timestamp}_{originalName} 자동 생성.
  static Future<String> uploadFoodRecordImage({
    required Uint8List bytes,
    required String originalName,
    String? userId,
    String? contentType,
  }) async {
    final uid = userId ?? _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('No authenticated user — sign in before uploading.');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = _sanitizeFileName(originalName);
    final path = 'user/$uid/${timestamp}_$safeName';

    final storage = _client.storage.from(foodRecordBucket);
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        upsert: false,
        contentType: contentType ?? _guessContentType(originalName),
      ),
    );

    return storage.getPublicUrl(path);
  }

  static String _sanitizeFileName(String name) {
    final base = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    return base.isEmpty ? 'image.jpg' : base;
  }

  static String _guessContentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
