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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
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
      appBar: AppBar(title: const Text('Exercises')),
      body: Center(
        child: StreamBuilder(
          stream: collectionService.getAllExercises(authService.currentUser!.uid), 
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
                  final data = exercises[index];

                  return ListTile(
                    title: Center(child: Text(data)),
                    onTap: () => {
                      // print('change or delete exercise')
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
