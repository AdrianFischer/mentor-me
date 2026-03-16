import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/data/repository/firebase_storage_repository.dart';
import 'package:flutter_app/models/node.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockCollectionReference<T extends Object?> extends Mock implements CollectionReference<T> {}
class MockDocumentReference<T extends Object?> extends Mock implements DocumentReference<T> {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  test('Test 17: Cloud Sync Exponential Backoff Test', () async {
    final firestore = MockFirebaseFirestore();
    final auth = MockFirebaseAuth();
    final user = MockUser();
    
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('test_user_id');
    when(() => auth.authStateChanges()).thenAnswer((_) => Stream.value(user));

    final usersCollection = MockCollectionReference<Map<String, dynamic>>();
    final userDoc = MockDocumentReference<Map<String, dynamic>>();
    final nodesCollection = MockCollectionReference<Map<String, dynamic>>();
    final nodeDoc = MockDocumentReference<Map<String, dynamic>>();

    when(() => firestore.collection('users')).thenReturn(usersCollection);
    when(() => usersCollection.doc('test_user_id')).thenReturn(userDoc);
    
    // For all collections in _setupListeners
    when(() => userDoc.collection(any())).thenReturn(nodesCollection);
    when(() => nodesCollection.snapshots()).thenAnswer((_) => Stream.empty());

    when(() => nodesCollection.doc(any())).thenReturn(nodeDoc);

    int attemptCount = 0;
    when(() => nodeDoc.set(any())).thenAnswer((_) async {
      attemptCount++;
      if (attemptCount < 3) {
        throw FirebaseException(plugin: 'cloud_firestore', message: 'Transient network failure');
      }
      return;
    });

    final repo = FirebaseStorageRepository(firestore: firestore, auth: auth);
    await repo.init(); // Sets up listeners

    final node = Node(id: 'node1', title: 'Test Node');
    
    final stopwatch = Stopwatch()..start();
    await repo.saveNode(node);
    stopwatch.stop();

    expect(attemptCount, 3, reason: 'Should retry 3 times');
    // Delay 1: 500ms, Delay 2: 1000ms -> Total expected ~1500ms
    expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(1400), reason: 'Should wait with exponentially increasing delays');
    expect(stopwatch.elapsedMilliseconds, lessThan(3000), reason: 'Should not wait too long');
  });
}
