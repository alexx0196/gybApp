import 'package:flutter/material.dart';
import 'package:gym_tracker/db_services/db_services.dart';


class WorkoutScreen extends StatefulWidget {
  final String id;
  const WorkoutScreen({super.key, required this.id});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  CollectionService collectionService = CollectionService();
  final authService = sl.get<AuthService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your workout ${widget.id}')),
      body: Center(
        child: StreamBuilder(
          stream: collectionService.getWorkout(authService.currentUser!.uid, widget.id), 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            
            if (!snapshot.hasData || snapshot.data == null || snapshot.data!.data() == null || snapshot.data!.data()?['exercices'] == null) {
              return Text('No exercices');
            }
            final workout = snapshot.data!.data();
            return Text('Tout va bien');
          }
        )
      ),
    );
  }
}
