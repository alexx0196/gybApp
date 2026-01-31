import 'package:flutter/material.dart';
import 'package:gym_tracker/db_services/db_services.dart';
import 'package:gym_tracker/screens/workout_screen/add_info_about_exercise.dart';


class WorkoutScreen extends StatefulWidget {
  final String id;
  final String date;
  const WorkoutScreen({super.key, required this.id, required this.date});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  WorkoutsService workoutsService = WorkoutsService();
  CollectionService collectionService = CollectionService();
  final authService = sl.get<AuthService>();

  void _chooseEcercise() async {
    return await showDialog(
      context: context, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose exercices'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.4,
            height: MediaQuery.of(context).size.height * 0.4,
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

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: exerciseList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Center(child: Text(exerciseList[index])),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => AddInfoAboutExercise(
                            exerciseName: exerciseList[index], 
                            workoutId: widget.id,
                          ),)
                        );
                      },
                    );
                  },
                );
              }
            ),
          ),
        );
      }
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your workout ${widget.date}')),
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
            
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: exercises.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Center(child: Text(exercises[index]['name'])),
                        onTap: () {
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
                        onLongPress: () {
                          workoutsService.deleteExerciseFromWorkout(
                            authService.currentUser!.uid,
                            widget.id,
                            exercises[index].id,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Exercise ${exercises[index]['name']} deleted')),
                          );
                        },
                      );
                    }  
                  ),
                ),
              ],
            );
          }
        )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _chooseEcercise(),
        child: Icon(Icons.add),
      ),
    );
  }
}
