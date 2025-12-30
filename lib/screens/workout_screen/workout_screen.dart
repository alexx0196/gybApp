import 'package:flutter/material.dart';
import 'package:gym_tracker/db_services/db_services.dart';
import 'package:gym_tracker/screens/workout_screen/add_info_about_exercise.dart';
import 'package:gym_tracker/screens/workout_screen/choose_exercise.dart';


class WorkoutScreen extends StatefulWidget {
  final String id;
  const WorkoutScreen({super.key, required this.id});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  WorkoutsService workoutsService = WorkoutsService();
  final authService = sl.get<AuthService>();

  void _exerciseAlertDialog(String exerciseId, List exercises, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exercise'),
          content: const Text('Choose an exercise to add to your workout.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                workoutsService.deleteExerciseFromWorkout(
                  authService.currentUser!.uid,
                  widget.id,
                  exerciseId,
                );
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Change'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => AddInfoAboutExercise(
                      exerciseName: exercises[index]['name'],
                      workoutId: widget.id,
                      exerciseId: exercises[index].id,
                    )
                  )
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your workout ${widget.id}')),
      body: Center(
        child: StreamBuilder(
          stream: workoutsService.getExercisesFromWorkout(authService.currentUser!.uid, widget.id), 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            
            if (snapshot.hasError) {
              return const Text('Error loading exercises');
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('No exercises');
            }

            final exercises = snapshot.data!.docs;
            
            return Column(children: [
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: exercises.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Center(child: Text(exercises[index]['name'])),
                    onTap: () => _exerciseAlertDialog(
                      exercises[index].id,
                      exercises,
                      index,
                    ),
                  );
                }
              ),),
            ],);
          }
        )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => ChooseExercise(workoutId: widget.id,))
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
