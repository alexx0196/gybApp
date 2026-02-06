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
    await firebaseAuth.signOut();
    // try {
    //   await firebaseAuth.signOut();
    // } on FirebaseAuthException catch (e) {
    //   // print(e.code);
    // }
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
      throw WorkoutAlreadyExistsException(querySnapshot.docs.first.id, startOfDay);
    }

    final docRef = fireStore.collection('users').doc(uid).collection('workouts').doc(); 
    await docRef.set({
      'createdAt': FieldValue.serverTimestamp(),
    });
    // SetOptions(merge: true); // нужно чтобы обновить документ, не создавая новый
    return docRef.id;
  }

  Future<String> addWorkoutWithDate(String uid, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final startOfTomorrow = startOfDay.add(const Duration(days: 1));

    final docRef = fireStore.collection('users').doc(uid).collection('workouts').doc(); 

    final querySnapshot = await fireStore.collection('users').doc(uid).collection('workouts')
    .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
    .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(startOfTomorrow)).limit(1).get();

    if (querySnapshot.docs.isNotEmpty) {
      throw WorkoutAlreadyExistsException(querySnapshot.docs.first.id, startOfDay);
    } else {
      await docRef.set({
        'createdAt': Timestamp.fromDate(startOfDay),
      });
    }
    // SetOptions(merge: true); // нужно чтобы обновить документ, не создавая новый
    return docRef.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>?>> getAllWorkouts(String uid) {
    final doc = fireStore.collection('users').doc(uid).collection('workouts').orderBy('createdAt', descending: true).snapshots();
    return doc;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getWorkout(String uid, String workoutId) {
    final doc = fireStore.collection('users').doc(uid).collection('workouts').doc(workoutId).snapshots();
    return doc;
  }

  Future<void> deleteWorkout(String uid, String workoutId) async {
    final workoutRef = fireStore.collection('users').doc(uid).collection('workouts').doc(workoutId);
    
    final exercisesSnapshot = await workoutRef.collection('exercises').get();
    for (final exerciseDoc in exercisesSnapshot.docs) {
      final setsSnapshot = await exerciseDoc.reference.collection('sets').get();
      for (final setDoc in setsSnapshot.docs) {
        await setDoc.reference.delete();
      }
      await exerciseDoc.reference.delete();
    }

    await workoutRef.delete();
  }
}


class ExerciseService {
  final fireStore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> getExercisesFromWorkout(String uid, String workoutId){
    final doc = fireStore.collection('users').doc(uid).collection('workouts').doc(workoutId).collection('exercises').orderBy('exerciseIndex', descending: true).snapshots();

    return doc;
  }

  Future<Map<int, ExerciseSet>> getCertainExercise(String uid, String workoutId, String exerciseId) async {
    final snapshot = await fireStore.collection('users').doc(uid).collection('workouts').doc(workoutId).collection('exercises')
                .doc(exerciseId).collection('sets').orderBy(FieldPath.documentId).get();

    final Map<int, ExerciseSet> sets = {};

    for (final i in snapshot.docs) {
      final data = i.data() as Map<String, dynamic>?;

      // если поля нет, добавляем isWarmUp = true
      sets[int.parse(i.id)] = ExerciseSet(
        reps: data?['reps'] ?? 0,
        weight: (data?['weight'] as num?)?.toDouble() ?? 0.0,
        isWarmUp: data != null && data.containsKey('isWarmUp') ? data['isWarmUp'] : false,
      );
    }

    return sets;
  }

  Future<String> addExerciseAndInfo(String uid, String workoutId, String exerciseId, String name, Map<int, ExerciseSet> sets) async {
    final exerciseRef = fireStore.collection('users').doc(uid).collection('workouts').doc(workoutId).collection('exercises');
    final docRef = exerciseId.isNotEmpty
      ? exerciseRef.doc(exerciseId)
      : exerciseRef.doc();

    int finalIndex = 0;
    if (exerciseId.isNotEmpty) {
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        finalIndex = snapshot.data()?['exerciseIndex'] as int? ?? 0;
      }
    }
  
    if (finalIndex == 0) {
      // Получи все упражнения в этом workout
      final exercisesSnapshot = await fireStore
          .collection('users').doc(uid)
          .collection('workouts').doc(workoutId)
          .collection('exercises')
          .get();
      
      // Найди максимальный индекс
      int maxIndex = 0;
      for (var doc in exercisesSnapshot.docs) {
        final index = doc.data()['exerciseIndex'] as int? ?? 0;
        if (index > maxIndex) {
          maxIndex = index;
        }
      }
      
      // Новый индекс = maxIndex + 1
      finalIndex = maxIndex + 1;
    }
    
    docRef.set({
      'name': name,
      'exerciseIndex': finalIndex,
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
        'isWarmUp': value.isWarmUp,
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


class StatisticService {
  final fireStore = FirebaseFirestore.instance;

  Future<List<String>> getAllExercises(String uid) async {
    final doc = await fireStore.collection('users').doc(uid).get();
    final data = doc.data();
    final List<dynamic> raw = data?['exercises'] ?? [];
    return raw.cast<String>();
  }

  Future<List<DateTime>> getWorkoutDates(String uid) async {
    final snapshot = await fireStore.collection('users').doc(uid).collection('workouts').orderBy('createdAt').get();

    List<DateTime> workoutDates = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final timestamp = data['createdAt'] as Timestamp?;
      if (timestamp != null) {
        workoutDates.add(timestamp.toDate());
      }
    }

    return workoutDates;
  }

  Future<Map<String, dynamic>> getStatisticsForExercise(String uid, String exerciseName) async {
    final snapshot = await fireStore
      .collection('users')
      .doc(uid)
      .collection('statistics')
      .doc(exerciseName)
      .collection('history')
      .get();
    
    Map<int, List> stats = {};
    double maxWeight = 0.0;
    double totalVolume = 0.0;
    int workoutCount = snapshot.docs.length;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final maxWeightFromDoc = data['maxWeight'] as double? ?? 0.0;
      final totalVolumeFromDoc = data['totalVolume'] as double? ?? 0.0;

      final date = DateTime.parse(doc.id);
      stats[date.millisecondsSinceEpoch] = [maxWeightFromDoc, totalVolumeFromDoc];

      if (maxWeightFromDoc > maxWeight) {
        maxWeight = maxWeightFromDoc;
      }
      totalVolume += totalVolumeFromDoc;
    }

    final entries = stats.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key));
    final dates = entries.map((e) => DateTime.fromMillisecondsSinceEpoch(e.key)).toList();
    final maxWeights = entries.map((e) => e.value[0]).toList();
    final volumes = entries.map((e) => e.value[1]).toList();

    return {
      'maxWeight': maxWeight,
      'volume': totalVolume,
      'workoutCount': workoutCount,
      'detailedStats': {
        'dates': dates,
        'maxWeights': maxWeights,
        'volumes': volumes,
      },
    };
  }



  Future<void> migrationForStats(String uid) async {
    List<String> exercisesList = [];
    await fireStore.collection('users').doc(uid).get().then((doc) {
      final data = doc.data();
      final List<dynamic> raw = data?['exercises'] ?? [];
      exercisesList = raw.cast<String>();
    });
    print('exercisesList: $exercisesList');

    final snapshot = await fireStore.collection('users').doc(uid).collection('workouts').get();

    for (final workoutDoc in snapshot.docs) {
      final exercisesSnapshot = await workoutDoc.reference.collection('exercises').get();

      for (final exerciseDoc in exercisesSnapshot.docs) {
        double maxWeight = 0.0;
        double totalVolume = 0.0;
        int totalReps = 0;

        final setsSnapshot = await exerciseDoc.reference.collection('sets').get();

        for (final setDoc in setsSnapshot.docs) {
          final data = setDoc.data();
          final weight = (data['weight'] as num?)?.toDouble() ?? 0.0;
          final reps = data['reps'] as int? ?? 0;

          if (weight > maxWeight) {
            maxWeight = weight;
          }

          totalVolume += weight * reps;
          totalReps += reps;
        }

        final docRef = fireStore
          .collection('users')
          .doc(uid)
          .collection('statistics')
          .doc(exerciseDoc.data()['name'])
          .collection('history')
          .doc(workoutDoc['createdAt'].toDate().toIso8601String());
        await docRef.set({
          'maxWeight': maxWeight,
          'totalVolume': totalVolume,
          'totalReps': totalReps,
        });
        print('sss');
      }
    }
    
  }
}


class WorkoutAlreadyExistsException implements Exception {
  final String id;
  final DateTime date;
  WorkoutAlreadyExistsException(this.id, this.date);
}
