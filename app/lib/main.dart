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
  
  // Ensure we have a logged-in user for Sync
  if (FirebaseAuth.instance.currentUser == null) {
    debugPrint("Signing in with hardcoded sync user...");
    
    // Use MEMORY persistence to avoid keychain errors in unsigned/debug builds
    try {
      await FirebaseAuth.instance.setPersistence(Persistence.NONE);
    } catch (e) {
      debugPrint("WARN: Failed to set persistence to MEMORY: $e");
    }

    const email = 'sync_user@example.com';
    const password = 'SyncUser2025!';
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("Signed in as $email");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
         debugPrint("User not found, creating new sync user...");
         try {
           await FirebaseAuth.instance.createUserWithEmailAndPassword(
             email: email,
             password: password,
           );
           debugPrint("Created and signed in as $email");
         } catch (createError) {
            // Handle keychain error specifically for create/sign-in
            if (createError.toString().contains('keychain-error')) {
               debugPrint("WARN: Keychain error ignored. Session is valid but may not persist restart.");
            } else {
               debugPrint("Failed to create user: $createError");
               rethrow;
            }
         }
      } else if (e.code == 'keychain-error' || e.toString().contains('keychain-error')) {
          debugPrint("WARN: Keychain error during sign-in ignored. Session is valid but may not persist restart.");
      } else {
        debugPrint("Login failed: ${e.code} - ${e.message}");
        rethrow;
      }
    }
  }
  
  runApp(const ProviderScope(child: MyApp()));
}