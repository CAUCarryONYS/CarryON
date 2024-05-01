import 'package:dio/dio.dart';

class AudioUploader {
  static Future<void> uploadAudio(String filePath) async {
    final dio = Dio();
    const url = 'http://'; // 업로드할 서버의 URL

    try {
      final response = await dio.post(
        url,
        data: FormData.fromMap({
          'audio': await MultipartFile.fromFile(filePath),
        }),
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200) {
        print('Audio uploaded successfully.');
      } else {
        print('Failed to upload audio: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading audio: $e');
    }
  }
}
