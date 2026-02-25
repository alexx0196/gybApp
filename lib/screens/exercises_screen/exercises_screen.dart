import 'package:flutter/material.dart';
import 'package:gym_tracker/db_services/db_services.dart';
import 'package:gym_tracker/screens/app_drawer/app_drawer.dart';


class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  CollectionService collectionService = CollectionService();
  AuthService authService = AuthService();
  late TextEditingController _controller;

  late ValueNotifier<bool> isSelecting;
  late ValueNotifier<List<String>> selectedExercises;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    isSelecting = ValueNotifier(false);
    selectedExercises = ValueNotifier([]);
  }

  @override
  void dispose() {
    _controller.dispose();
    isSelecting.dispose();
    selectedExercises.dispose();
    super.dispose();
  }

  Future<void> _addExercise(String uid) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Write'),
          content: TextField(controller: _controller,),
          actions: <Widget>[
            TextButton(
              child: const Text('Approve'),
              onPressed: () {
                collectionService.addCustomExercise(uid, _controller.text);
                _controller.text = '';
                Navigator.of(context).pop();
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
      appBar: AppBar(
        title: const Text('Exercises'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: isSelecting,
            builder: (context, selecting, child) {
              if (selecting) {
                return Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        for (var workoutId in selectedExercises.value) {
                          await collectionService.deleteExercise(
                            authService.currentUser!.uid,
                            workoutId,
                          );
                        }
                        isSelecting.value = false;
                        selectedExercises.value = [];
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        isSelecting.value = false;
                        selectedExercises.value = [];
                      },
                    ),
                  ],
                );
              } else {
                return SizedBox.shrink();
              }
            },
          ),
        ],
      ),
      body: Center(
        child: StreamBuilder(
          stream: collectionService.getAllActiveExercises(authService.currentUser!.uid), 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text('No exercises');
            }

            final exercises = snapshot.data!;

            return Column(children: [
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: exercises.length,
                itemBuilder: (BuildContext context, int index) {
                  final exerciseName = exercises[index];

                  return ExerciseListItem(
                    exerciseId: exerciseName, 
                    exerciseName: exerciseName, 
                    isSelecting: isSelecting, 
                    selectedExercises: selectedExercises, 
                    onLongPress: () {
                      isSelecting.value = true;
                      selectedExercises.value = [...selectedExercises.value, exerciseName];
                    },
                    onTap: () {
                      if (isSelecting.value) {
                        if (selectedExercises.value.contains(exerciseName)) {
                          selectedExercises.value = selectedExercises.value.where((id) => id != exerciseName).toList();
                          if (selectedExercises.value.isEmpty) {
                            isSelecting.value = false;
                          }
                        } else {
                          selectedExercises.value = [...selectedExercises.value, exerciseName];
                        }
                      } else {
                        print('i will change it');
                      }
                    },
                  );
                }
              ),),
            ],);
          }
        )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addExercise(authService.currentUser!.uid);
        },
        child: Icon(Icons.add),
      ),
      drawer: AppDrawer(),
    );
  }
}


class ExerciseListItem extends StatelessWidget {
  final String exerciseId;
  final String exerciseName;
  final ValueNotifier<bool> isSelecting;
  final ValueNotifier<List<String>> selectedExercises;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ExerciseListItem({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    required this.isSelecting,
    required this.selectedExercises,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isSelecting,
      builder: (context, selecting, _) {
        return ValueListenableBuilder<List<String>>(
          valueListenable: selectedExercises,
          builder: (context, selected, _) {
            return ListTile(
              title: Center(child: Text(exerciseName)),
              leading: selecting ? 
                (selected.contains(exerciseId) ? Icon(Icons.check_box) : Icon(Icons.check_box_outline_blank)) 
                : null,
              onTap: onTap,
              onLongPress: onLongPress,
            );
          },
        );
      },
    );
  }
}
