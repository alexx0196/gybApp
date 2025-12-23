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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page'),),
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
                  print(data);
                  final timestamp = data?['createdAt'];

                  final dateText = timestamp == null ? '...' : DateFormat('dd.MM.yyyy').format(timestamp.toDate());

                  return ListTile(
                    title: Center(child: Text(dateText)),
                    onTap: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => WorkoutScreen(id: workouts[index].id))
                    ),
                  );
                }
              ),),
            ],);
          }
        )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await workoutsService.addWorkout(authService.currentUser!.uid);
          } on WorkoutAlreadyExistsException catch (e) {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => WorkoutScreen(id: e.id))
            );
          }
        },
        child: Icon(Icons.add),
      ),
      drawer: AppDrawer(),
    );
  }
}
