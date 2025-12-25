import 'package:flutter/material.dart';


class AddInfoAboutExercise extends StatefulWidget {
  final String exerciseName;
  const AddInfoAboutExercise({super.key, required this.exerciseName});

  @override
  State<AddInfoAboutExercise> createState() => _AddInfoAboutExerciseState();
}


class _AddInfoAboutExerciseState extends State<AddInfoAboutExercise> {
  final TextEditingController _controllerRep = TextEditingController();
  final TextEditingController _controllerWeigth = TextEditingController();

  @override
  void dispose() {
    _controllerRep.dispose();
    _controllerWeigth.dispose();
    super.dispose();
  }

  List sets = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Info About Exercise'),),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Add Info About Exercise Screen'),
            Text(widget.exerciseName),
            Expanded(
              child: ListView.builder(
                itemCount: sets.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Set ${index + 1}'),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Repetition'),
                            SizedBox(height: 4.0),
                            TextField(controller: _controllerRep,),
                          ],
                        ),),
                        Expanded(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Weight'),
                            SizedBox(height: 4.0),
                            TextField(controller: _controllerWeigth,),
                          ],
                        ),),
                      ],
                    ),
                    onTap: () => print('Tapped set ${index + 1}'),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  sets.add('Set ${sets.length + 1}');
                });
              }, 
              child: const Text('Add Set'),
            ),
          ],
        ),
      ),
    );
  }
}
