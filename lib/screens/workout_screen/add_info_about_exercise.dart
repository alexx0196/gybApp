import 'package:flutter/material.dart';
import 'package:gym_tracker/db_services/db_services.dart';


/*
Кратко: храню список sets как модель SetEntry {int reps; double weight;}.
Добавление/редактирование: открывать диалог (AlertDialog/BottomSheet) с локальными
TextEditingController, валидировать и возвращать готовый SetEntry.
Нет долгоживущих контроллеров — модель sets остаётся источником правды.
*/


class ExerciseSet {
  int reps;
  double weight;
  ExerciseSet({required this.reps, required this.weight});
}


class AddInfoAboutExercise extends StatefulWidget {
  final String exerciseName;
  final String workoutId;
  const AddInfoAboutExercise({super.key, required this.exerciseName, required this.workoutId});

  @override
  State<AddInfoAboutExercise> createState() => _AddInfoAboutExerciseState();
}


class _AddInfoAboutExerciseState extends State<AddInfoAboutExercise> {
  WorkoutsService workoutsService = WorkoutsService();
  AuthService authService = AuthService();

  Map<String, ExerciseSet> sets = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Info About Exercise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // Save the exercise info along with sets
              workoutsService.addExerciseAndInfo(
                authService.currentUser!.uid,
                widget.workoutId,
                widget.exerciseName,
                sets,
              );
              print('Saving exercise info with sets: $sets');
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
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
                    subtitle: Text('Reps: ${sets.values.toList()[index].reps}, Weight: ${sets.values.toList()[index].weight} kg'),
                    onTap: () {
                      print('Edit set ${index + 1}');
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await showModalBottomSheet(
                  context: context, 
                  builder: (_) => AddSetBottomSheet(),
                );
                setState(() {
                  sets['Set ${sets.length}'] = ExerciseSet(
                    reps: result.reps,
                    weight: result.weight,
                  );
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


class AddSetBottomSheet extends StatefulWidget {
  const AddSetBottomSheet({super.key});

  @override
  State<AddSetBottomSheet> createState() => _AddSetBottomSheetState();
}

class _AddSetBottomSheetState extends State<AddSetBottomSheet> {
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Reps'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Weight'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(
                ExerciseSet(
                  reps: int.parse(_repsController.text),
                  weight: double.parse(_weightController.text),
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
