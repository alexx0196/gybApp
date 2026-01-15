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

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password
    );
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

  Future<void> reAuthUser({required String enteredPassword}) async {
    final credential = EmailAuthProvider.credential(
      email: currentUser!.email!,
      password: enteredPassword,
    );

    await currentUser!.reauthenticateWithCredential(credential);
  }

  Future<void> changeEmail({required String email}) async {
    await currentUser!.verifyBeforeUpdateEmail(email);
    await currentUser!.reload();
  }
}


class AuthFireStoreService {
  final fireStore = FirebaseFirestore.instance;

  Future<bool> isUsernameTaken(String uid, String username) async {
    try {
      await fireStore.collection('nicknames').doc(username.toLowerCase().replaceAll(' ', '_')).set({
        'uid': uid,
      });
      print('sss');
      return false;
    } catch (e) {
      return true;
    }
  }

  Future<void> createUserData(String uid, String username, DateTime dateOfBirth, String gender, double weight, double height) async {
    await fireStore.collection('users').doc(uid).set({
      'isEmailVerificationCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'username': username,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender,
      'weight': weight,
      'height': height,
      'exercises': ['Приседания', 'Жим лежа', 'Подтягивания'],
    });

    addWeightEntry(uid, weight);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(String uid) async {
    final doc = await fireStore.collection('users').doc(uid).get();
    return doc;
  }

  Future<List<Map<String, dynamic>>> getWeightHistory(String uid) async {
    final snapshot = await fireStore.collection('users').doc(uid).collection('weight_history').orderBy('date').get();

    List<Map<String, dynamic>> weightData = [];

    snapshot.docs.map((doc) {
      final data = doc.data();
      weightData.add({
        'weight': (data['weight'] as num).toDouble(),
        'date': (data['date'] as Timestamp).toDate(),
      });
    }).toList();

    // final firstDate = snapshot.docs.isNotEmpty ? snapshot.docs.first['createdAt'] as Timestamp : null;
    // final lastDate = snapshot.docs.isNotEmpty ? snapshot.docs.last['createdAt'] as Timestamp : null;
    return weightData;
  }

  Future<void> addWeightEntry(String uid, double weight) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfDay.add(const Duration(days: 1));

    final querySnapshot = await fireStore.collection('users').doc(uid).collection('weight_history').where(
      'date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay)
    ).where(
      'date', isLessThanOrEqualTo: Timestamp.fromDate(startOfTomorrow)
    ).limit(1).get();
    
    if (querySnapshot.docs.isNotEmpty) {
      await fireStore.collection('users').doc(uid).collection('weight_history').doc(querySnapshot.docs.first.id).update({
        'weight': weight,
      });

      await fireStore.collection('users').doc(uid).update({
        'weight': weight,
      });
      return;
    }

    await fireStore.collection('users').doc(uid).collection('weight_history').doc().set({
      'weight': weight,
      'date': FieldValue.serverTimestamp(),
    });

    await fireStore.collection('users').doc(uid).update({
      'weight': weight,
    });
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
