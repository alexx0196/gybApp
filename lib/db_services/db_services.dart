import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:gym_tracker/screens/workout_screen/add_info_about_exercise.dart' show ExerciseSet;


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

  Future<Object> signIn({
    required String email,
    required String password,
  }) async {
    UserCredential userCredential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password
    );
    return userCredential;
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    UserCredential userCredential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email, password: password
    );

    await userCredential.user!.sendEmailVerification();

    return userCredential; 
  }
}


class AuthFireStoreService {
  final fireStore = FirebaseFirestore.instance;

  Future<void> createUserData(String uid, String username, DateTime dateOfBirth, double weight, double height) async {
    await fireStore.collection('users').doc(uid).set({
      'createdAt': FieldValue.serverTimestamp(),
      'username': username,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'weight': weight,
      'height': height,
      'exercises': ['Приседания', 'Жим лежа', 'Подтягивания'],
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(String uid) async {
    final doc = await fireStore.collection('users').doc(uid).get();
    return doc;
  }
}


class CollectionService {
  final fireStore = FirebaseFirestore.instance;

  Stream<List<String>> getAllExercises(String uid) {
    final doc = fireStore.collection('users').doc(uid).snapshots().map((doc) {
        final data = doc.data();
        final List<dynamic> raw = data?['exercises'] ?? [];
        return raw.cast<String>();
    });
    return doc;
  }

  Future<String> addCustomExercise(String uid, String name) async {
    final docRef = fireStore.collection('users').doc(uid); 
    await docRef.update({
      'exercises': FieldValue.arrayUnion([name]),
    });
    // SetOptions(merge: true); // нужно чтобы обновить документ, не создавая новый
    return docRef.id;
  }

  // Future<void> addExercice(String uid, String workout, String name, ) async {
  //   DocumentReference<Map<String, dynamic>> docRef = fireStore.collection('users').doc(uid).collection('catalogs').doc(catalogId);
  //   DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();
  //   if (snapshot.exists) {
  //     Map<String, dynamic> existingData = snapshot.data()!;
  //     Map<String, dynamic> existingWords = existingData['words'] ?? {};

  //     existingWords.addAll(words);
  //     await docRef.update({'words': existingWords});
  //   }
  //   else {
  //     await docRef.set({'words': words});
  //   }
  // }
}


class WorkoutsService {
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

  Stream<QuerySnapshot<Map<String, dynamic>>> getExercisesFromWorkout(String uid, String workoutId) {
    final doc = fireStore.collection('users').doc(uid).collection('workouts').doc(workoutId).collection('exercises').snapshots();
    return doc;
  }

  Future<Map<int, ExerciseSet>> getCertainExercise(String uid, String workoutId, String exerciseId) async {
    final snapshot = await fireStore.collection('users').doc(uid).collection('workouts').doc(workoutId).collection('exercises')
                .doc(exerciseId).collection('sets').orderBy(FieldPath.documentId).get();
    final Map<int, ExerciseSet> sets = {
      for (final doc in snapshot.docs)
        int.parse(doc.id): ExerciseSet(
          reps: doc['reps'],
          weight: (doc['weight'] as num).toDouble(),
        ),
    };
    return sets;
  }

  Future<String> addExerciseAndInfo(String uid, String workoutId, String exerciseId, String name, Map<int, ExerciseSet> sets) async {
    final exerciseRef = fireStore.collection('users').doc(uid).collection('workouts').doc(workoutId).collection('exercises');
    final docRef = exerciseId.isNotEmpty
      ? exerciseRef.doc(exerciseId)
      : exerciseRef.doc();
    
    docRef.set({
      'name': name,
    }, SetOptions(merge: true));
    
    final batch = FirebaseFirestore.instance.batch();
    final snapshot = await docRef.collection('sets').get();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    
    sets.forEach((key, value) {
      docRef.collection('sets').doc(key.toString()).set({
        'reps': value.reps,
        'weight': value.weight,
      }, SetOptions(merge: true));
    });
    return docRef.id;
  }

  Future<void> deleteExerciseFromWorkout(String uid, String workoutId, String exerciseId) async {
    final exerciseRef = fireStore.collection('users').doc(uid).collection('workouts').doc(workoutId).collection('exercises').doc(exerciseId);
    
    final setsSnapshot = await exerciseRef.collection('sets').get();
    for (final doc in setsSnapshot.docs) {
      await doc.reference.delete();
    }

    await exerciseRef.delete();
  }
}


class WorkoutAlreadyExistsException implements Exception {
  final String id;
  WorkoutAlreadyExistsException(this.id);
}
