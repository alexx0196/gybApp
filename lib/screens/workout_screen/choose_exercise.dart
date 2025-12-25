import 'package:flutter/material.dart';
import 'package:gym_tracker/db_services/db_services.dart';
import 'package:gym_tracker/screens/workout_screen/add_info_about_exercise.dart';


class ChooseExercise extends StatefulWidget {
  const ChooseExercise({super.key});

  @override
  State<ChooseExercise> createState() => _ChooseExerciseState();
}


class _ChooseExerciseState extends State<ChooseExercise> {
  CollectionService collectionService = CollectionService();
  AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Exercise'),),
      body: Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder(
          stream: collectionService.getAllExercises(authService.currentUser!.uid), 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            
            if (snapshot.hasError) {
              return Text('Error loading exercises');
            }
            final exerciseList = snapshot.data ?? [];

            return Column(
              spacing: 16.0,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('Choose exercise'),
                Expanded(child: ListView.builder(
                  itemCount: exerciseList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Center(child: Text(exerciseList[index])),
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => AddInfoAboutExercise(exerciseName: exerciseList[index],))
                        );
                      },
                    );
                  },
                ),),
              ],
            );
          }
        ), 
      ),
    ),
    );
  }
}
