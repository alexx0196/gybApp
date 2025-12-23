import 'package:flutter/material.dart';
import 'package:gym_tracker/db_services/db_services.dart';
import 'package:gym_tracker/screens/app_drawer/app_drawer.dart';
import 'package:gym_tracker/screens/workout_screen/add_exercise_to_workout.dart';


class WorkoutScreen extends StatefulWidget {
  final String id;
  const WorkoutScreen({super.key, required this.id});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  WorkoutsService workoutsService = WorkoutsService();
  final authService = sl.get<AuthService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your workout ${widget.id}')),
      body: Center(
        child: StreamBuilder(
          stream: workoutsService.getWorkout(authService.currentUser!.uid, widget.id), 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            
            if (!snapshot.hasData || snapshot.data == null || snapshot.data!.data() == null || snapshot.data!.data()?['exercices'] == null) {
              return Text('No exercices');
            }
            final workout = snapshot.data!.data();
            
            return Column(children: [
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: workout?.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Center(child: Text('Name of exercice')),
                    onTap: () => print('I pushed exercice'),
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
            MaterialPageRoute(builder: (context) => AddExerciseToWorkout())
          );
        },
        child: Icon(Icons.add),
      ),
      drawer: AppDrawer(),
    );
  }
}
