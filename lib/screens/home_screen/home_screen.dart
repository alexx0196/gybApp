import 'package:flutter/material.dart';
import 'package:gym_tracker/db_services/db_services.dart';
import 'package:gym_tracker/screens/app_drawer/app_drawer.dart';
import 'package:gym_tracker/screens/workout_screen/workout_screen.dart';
import 'package:intl/intl.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WorkoutsService workoutsService = WorkoutsService();
  final authService = sl.get<AuthService>();

  late ValueNotifier<bool> isSelecting;
  late ValueNotifier<List<String>> selectedWorkouts;

  @override
  void initState() {
    super.initState();
    isSelecting = ValueNotifier(false);
    selectedWorkouts = ValueNotifier([]);
  }

  @override
  void dispose() {
    isSelecting.dispose();
    selectedWorkouts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
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
                        for (var workoutId in selectedWorkouts.value) {
                          await workoutsService.deleteWorkout(
                            authService.currentUser!.uid,
                            workoutId,
                          );
                        }
                        isSelecting.value = false;
                        selectedWorkouts.value = [];
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        isSelecting.value = false;
                        selectedWorkouts.value = [];
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
          stream: workoutsService.getAllWorkouts(authService.currentUser!.uid), 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } 
            
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text('No notes');
            }

            final workouts = snapshot.data!.docs;

            return Column(children: [
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: workouts.length,
                itemBuilder: (BuildContext context, int index) {
                  final data = workouts[index].data();
                  final timestamp = data?['createdAt'];

                  final dateText = timestamp == null ? '...' : DateFormat('dd.MM.yyyy').format(timestamp.toDate());

                  return WorkoutListItem(
                    workoutId: workouts[index].id,
                    dateText: dateText,
                    isSelecting: isSelecting,
                    selectedWorkouts: selectedWorkouts,
                    onLongPress: () {
                      isSelecting.value = true;
                      selectedWorkouts.value = [...selectedWorkouts.value, workouts[index].id];
                    },
                    onTap: () {
                      if (isSelecting.value) {
                        if (selectedWorkouts.value.contains(workouts[index].id)) {
                          selectedWorkouts.value = selectedWorkouts.value.where((id) => id != workouts[index].id).toList();
                          if (selectedWorkouts.value.isEmpty) {
                            isSelecting.value = false;
                          }
                        } else {
                          selectedWorkouts.value = [...selectedWorkouts.value, workouts[index].id];
                        }
                      } else {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => WorkoutScreen(id: workouts[index].id, date: dateText),)
                        );
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
        child: PopupMenuButton(
          icon: Icon(Icons.add),
          onSelected: (item) async {
            if (item == 'add_workout') {
              try {
                String workoutId = await workoutsService.addWorkout(authService.currentUser!.uid);
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => WorkoutScreen(id: workoutId, date: DateFormat('dd.MM.yyyy').format(DateTime.now())))
                );
              } on WorkoutAlreadyExistsException catch (e) {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => WorkoutScreen(id: e.id, date: DateFormat('dd.MM.yyyy').format(e.date)))
                );
              }
            } else if (item == 'select_date') {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                try {
                  await workoutsService.addWorkoutWithDate(
                    authService.currentUser!.uid, 
                    pickedDate
                  );
                } on WorkoutAlreadyExistsException catch (e) {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => WorkoutScreen(id: e.id, date: DateFormat('dd.MM.yyyy').format(e.date))),
                  );
                }
              }
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry>[
            const PopupMenuItem(value: 'add_workout', child: Text('Добавить тренировку')),
            const PopupMenuItem(value: 'select_date', child: Text('Выбрать дату')),
          ],
        ),
        onPressed: () {},
      ),
      drawer: AppDrawer(),
    );
  }
}


class WorkoutListItem extends StatelessWidget {
  final String workoutId;
  final String dateText;
  final ValueNotifier<bool> isSelecting;
  final ValueNotifier<List<String>> selectedWorkouts;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const WorkoutListItem({
    super.key,
    required this.workoutId,
    required this.dateText,
    required this.isSelecting,
    required this.selectedWorkouts,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isSelecting,
      builder: (context, selecting, _) {
        return ValueListenableBuilder<List<String>>(
          valueListenable: selectedWorkouts,
          builder: (context, selected, _) {
            return ListTile(
              title: Center(child: Text(dateText)),
              leading: selecting ? 
                (selected.contains(workoutId) ? Icon(Icons.check_box) : Icon(Icons.check_box_outline_blank)) 
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
