import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';


final sl = GetIt.I;

void setupAuthLocator() {
  sl.registerSingleton(AuthService());
}


class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      print(e.code);
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password
      );
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
    required String username,
  }) async {
    // CollectionReference collectionRef = FirebaseFirestore.instance.collection('users');
    // QuerySnapshot snapshot = await collectionRef.where('username', isEqualTo: username).get();
    // if (snapshot.docs.isNotEmpty) {
    //   throw Exception('Nickname already existe');
    // }
    // this code can check if username already existe, but because of rules in database it does not work, so I have to
    // Firebase Cloud Function or change rules.

    UserCredential userCredential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email, password: password
    );

    await firestore.collection('users').doc(userCredential.user!.uid).set({
      'username': username, 
    });

    return userCredential; 
  }
}



class CollectionService {
  final fireStore = FirebaseFirestore.instance;

  Future<String> addWorkout(String uid) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfDay.add(const Duration(days: 1));

    final querySnapshot = await fireStore.collection('users').doc(uid).collection('workouts')
    .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
    .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(startOfTomorrow)).limit(1).get();
    
    if (querySnapshot.docs.isNotEmpty) {
      throw WorkoutAlreadyExistsException(querySnapshot.docs.first.id);
    }

    final docRef = fireStore.collection('users').doc(uid).collection('workouts').doc(); 
    await docRef.set({
      'createdAt': FieldValue.serverTimestamp(),
    });
    // SetOptions(merge: true); // нужно чтобы обновить документ, не создавая новый
    return docRef.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>?>> getAllWorkouts(String uid) {
    final doc = fireStore.collection('users').doc(uid).collection('workouts').snapshots();
    return doc;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getWorkout(String uid, String workoutId) {
    final doc = fireStore.collection('users').doc(uid).collection('workouts').doc(workoutId).snapshots();
    return doc;
  }

  Future<void> addWords(String uid, String catalogId, Map<String, String> words) async {
    DocumentReference<Map<String, dynamic>> docRef = fireStore.collection('users').doc(uid).collection('catalogs').doc(catalogId);
    DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();
    if (snapshot.exists) {
      Map<String, dynamic> existingData = snapshot.data()!;
      Map<String, dynamic> existingWords = existingData['words'] ?? {};

      existingWords.addAll(words);
      await docRef.update({'words': existingWords});
    }
    else {
      await docRef.set({'words': words});
    }
  }
}


class WorkoutAlreadyExistsException implements Exception {
  final String id;
  WorkoutAlreadyExistsException(this.id);
}
