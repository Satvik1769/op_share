import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:opShare/main.dart';

class ChunkedUploadService {
  static const int _chunkSize = 512 * 1024; // 512 KB

  Future<String> initUpload(
      String fileName, int fileSize, String mimeType, int roomId) async {
    final res = await http.post(
      Uri.parse('${appConfig.baseUrl}/upload/init'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fileName': fileName,
        'fileSize': fileSize,
        'mimeType': mimeType,
        'roomId': roomId,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception('initUpload failed: ${res.statusCode}');
    }
    return (jsonDecode(res.body) as Map<String, dynamic>)['uploadId'] as String;
  }

  Future<void> uploadChunks(
    String uploadId,
    Uint8List bytes, {
    void Function(double)? onProgress,
  }) async {
    final total = bytes.length;
    int chunkNumber = 0;
    for (int i = 0; i < total; i += _chunkSize) {
      final end = (i + _chunkSize > total) ? total : i + _chunkSize;
      final chunk = bytes.sublist(i, end);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '${appConfig.baseUrl}/upload/$uploadId/chunk/$chunkNumber'),
      );
      request.headers['Authorization'] = 'Bearer $authToken';
      request.files.add(http.MultipartFile.fromBytes(
        'chunk',
        chunk,
        filename: 'chunk_$chunkNumber',
      ));

      final streamed = await request.send();
      if (streamed.statusCode != 200) {
        throw Exception('uploadChunk $chunkNumber failed: ${streamed.statusCode}');
      }

      chunkNumber++;
      onProgress?.call(end / total);
    }
  }

  Future<void> completeUpload(String uploadId) async {
    final res = await http.post(
      Uri.parse('${appConfig.baseUrl}/upload/$uploadId/complete'),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    if (res.statusCode != 200) {
      throw Exception('completeUpload failed: ${res.statusCode}');
    }
  }

  Future<bool> isDuplicate(String fileHash, int roomId) async {
    try {
      final res = await http.get(
        Uri.parse(
            '${appConfig.baseUrl}/upload/check-duplicate?fileHash=$fileHash&roomId=$roomId'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      if (res.statusCode != 200) return false;
      return (jsonDecode(res.body) as Map<String, dynamic>)['isDuplicate']
              as bool? ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> cancelUpload(String uploadId) async {
    try {
      await http.delete(
        Uri.parse('${appConfig.baseUrl}/upload/$uploadId'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
    } catch (_) {}
  }

  static String computeHash(Uint8List bytes) => md5.convert(bytes).toString();
}
