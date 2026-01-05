import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:just_audio/just_audio.dart';

class TtsService {
  FirebaseFunctions get _functions => FirebaseFunctions.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;
  final player = AudioPlayer();

  Future<String> generateAndGetUrl({
    required String text,
    required String languageCode, // "de-DE" or "en-US"
    double speakingRate = 1.0,
    double pitch = 0.0,
  }) async {
    print("[TTS] Requesting audio for: '${text.substring(0, text.length > 20 ? 20 : text.length)}...' ($languageCode)");
    final callable = _functions.httpsCallable('generateTts');
    
    try {
      final res = await callable.call(<String, dynamic>{
        'text': text,
        'languageCode': languageCode,
        'speakingRate': speakingRate,
        'pitch': pitch,
        'audioEncoding': 'MP3',
      });
      print("[TTS] Cloud Function success. Metadata: ${res.data}");

      final storagePath = res.data['storagePath'] as String;
      final ref = _storage.ref(storagePath);
      final url = await ref.getDownloadURL();
      print("[TTS] Download URL obtained: $url");
      return url;
    } catch (e) {
      print("[TTS] ERROR in generateAndGetUrl: $e");
      rethrow;
    }
  }

  Future<void> playUrl(String url) async {
    print("[TTS] Attempting to play URL...");
    try {
      await player.setUrl(url);
      await player.play();
      print("[TTS] Playback started.");
    } catch (e) {
      print("[TTS] Playback ERROR: $e");
    }
  }

  Future<void> stop() async {
    await player.stop();
  }

  Future<void> dispose() async {
    await player.dispose();
  }
}
