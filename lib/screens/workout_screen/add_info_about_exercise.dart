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
  final String exerciseId;
  final String workoutId;
  const AddInfoAboutExercise({super.key, required this.exerciseName, required this.workoutId, this.exerciseId = ''});

  @override
  State<AddInfoAboutExercise> createState() => _AddInfoAboutExerciseState();
}


class _AddInfoAboutExerciseState extends State<AddInfoAboutExercise> {
  WorkoutsService workoutsService = WorkoutsService();
  AuthService authService = AuthService();

  Map<int, ExerciseSet> sets = {};

  @override
  void initState() {
    super.initState();

    if (widget.exerciseId.isNotEmpty) {
      _loadSets();
    }
  }

  Future<void> _loadSets() async {
    final loadedSets = await workoutsService.getCertainExercise(
      authService.currentUser!.uid,
      widget.workoutId,
      widget.exerciseId,
    );

    setState(() {
      sets = loadedSets;
    });
  }

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
                widget.exerciseId,
                widget.exerciseName,
                sets,
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.exerciseName,
                style: TextStyle(
                  fontSize: 22.0,
                ),
              ),
              const Text('Add Info About Exercise Screen'),
              Expanded(
                child: ListView.builder(
                  itemCount: sets.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text('Set ${index + 1}'),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text('Reps: ${sets.values.toList()[index].reps}, Weight: ${sets.values.toList()[index].weight} kg'),
                          ),
                          ElevatedButton(
                            onPressed: () => {
                              setState(() {
                                sets.remove(index);
                                sets = {
                                  for (int i = 0; i < sets.length; i++)
                                    i: sets.values.toList()[i],
                                };
                              })
                            }, 
                            child: const Icon(Icons.delete)
                          )
                        ]
                      ),
                      onTap: () async {
                        final result = await showModalBottomSheet(
                          context: context, 
                          builder: (_) => AddSetBottomSheet(
                            reps: sets.values.toList()[index].reps,
                            weight: sets.values.toList()[index].weight,
                          ),
                        );
                        setState(() {
                          sets[index] = ExerciseSet(
                            reps: result.reps,
                            weight: result.weight,
                          );
                        });
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
                  if (result == null || result.reps == 0) return;
                  setState(() {
                    sets[sets.length] = ExerciseSet(
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
      ),
    );
  }
}


class AddSetBottomSheet extends StatefulWidget {
  final int reps;
  final double weight;
  const AddSetBottomSheet({super.key, this.reps = 0, this.weight = 0.0});

  @override
  State<AddSetBottomSheet> createState() => _AddSetBottomSheetState();
}

class _AddSetBottomSheetState extends State<AddSetBottomSheet> {
  late TextEditingController _repsController;
  late TextEditingController _weightController;

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override void initState() {
    _repsController = TextEditingController(text: widget.reps.toString());
    _weightController = TextEditingController(text: widget.weight.toString());
    super.initState();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
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
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(), 
                child: const Text('Cancel')
              ),
            ],
          ),
        ],
      ),
    );
  }
}
