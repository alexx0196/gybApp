import 'package:flutter/material.dart';
import 'package:gym_tracker/db_services/db_services.dart';


class AddExerciseToWorkout extends StatefulWidget {
  const AddExerciseToWorkout({super.key});

  @override
  State<AddExerciseToWorkout> createState() => _AddExerciseToWorkoutState();
}

class _AddExerciseToWorkoutState extends State<AddExerciseToWorkout> {
  AuthService authService = AuthService();
  CollectionService collectionService = CollectionService();

  String? selectedExercise = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add exercise'),),
      body: Center(
        child: Column(children: [
          ElevatedButton(
            onPressed: () async {
              selectedExercise = await ExerciseSelector(context).show(collectionService.getAllExercises(authService.currentUser!.uid));
              print('Selected exercise: $selectedExercise');
            }, 
            child: Text('Choose exercise'),
          ),
        ],),
      ),
    );
  }
}


class ExerciseSelector {
  final BuildContext context;

  ExerciseSelector(this.context);

  Future<String?> show(Stream<List<String>> exercises) async {
    final List<String> exerciseList = await exercises.first;

    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 200,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                spacing: 16.0,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Choose exercise'),
                  Expanded(child: ListView.builder(
                    itemCount: exerciseList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Text(exerciseList[index]),
                        onTap: () {
                          Navigator.of(context).pop(exerciseList[index]);
                        },
                      );
                    },
                  ),),
                  ElevatedButton(
                    child: const Text('Close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
