import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Ensure we have an anonymous user for Cloud Functions / Storage security
  if (FirebaseAuth.instance.currentUser == null) {
    debugPrint("Signing in anonymously...");
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'keychain-error' || e.code == 'internal-error') {
         debugPrint("WARN: Keychain persistence failed (expected without valid signing). Session will be memory-only.");
         // Swallow the error. The session *might* still be active in memory for this run,
         // or we might need to rely on the fact that some features might be degraded.
         // However, typically signInAnonymously *throws* if it can't write to keychain.
         // Let's try to proceed.
      } else {
        rethrow;
      }
    }
  }
  
  runApp(const ProviderScope(child: MyApp()));
}