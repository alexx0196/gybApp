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
  bool isWarmUp;
  ExerciseSet({required this.reps, required this.weight, required this.isWarmUp});
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
                          Expanded(child: Text(sets.values.toList()[index].isWarmUp ? 'Warm-up' : 'Working set')),
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
                          isScrollControlled: true,
                          builder: (_) => AddSetBottomSheet(
                            reps: sets.values.toList()[index].reps,
                            weight: sets.values.toList()[index].weight,
                            isWarmUp: sets.values.toList()[index].isWarmUp,
                          ),
                        );

                        if (result == null) return;

                        setState(() {
                          sets[index] = ExerciseSet(
                            reps: result.reps,
                            weight: result.weight,
                            isWarmUp: result.isWarmUp,
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
                      isWarmUp: result.isWarmUp,
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
  final bool isWarmUp;
  const AddSetBottomSheet({super.key, this.reps = 0, this.weight = 0.0, this.isWarmUp = false});

  @override
  State<AddSetBottomSheet> createState() => _AddSetBottomSheetState();
}

class _AddSetBottomSheetState extends State<AddSetBottomSheet> {
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late bool _isWarmUpController = widget.isWarmUp;
  String? _repsErrorText;
  String? _weightErrorText;

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
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Reps',
                      errorText: _repsErrorText,
                    ),
                    onChanged: (value) => {
                      setState(() {
                         _repsErrorText = null;
                      })
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Weight',
                      errorText: _weightErrorText,
                    ),
                    onChanged: (value) => {
                      setState(() {
                         _weightErrorText = null;
                      })
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: const Text('Is Warm-up Set'),),
                Expanded(child: Checkbox(
                  value: _isWarmUpController,
                  onChanged: (bool? value) {
                    setState(() {
                      _isWarmUpController = value ?? false;
                    });
                  },
                ),),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    final reps = int.tryParse(_repsController.text.trim());
                    if (reps == null) {
                      setState(() {
                        _repsErrorText = 'Please enter a valid number of reps';
                      });
                      return;
                    }
                    if (reps <= 0) {
                      setState(() {
                        _repsErrorText = 'Please enter a valid number of reps';
                      });
                      return;
                    }

                    final weight = double.tryParse(_weightController.text.trim());
                    if (weight == null) {
                      setState(() {
                        _weightErrorText = 'Please enter a valid weight';
                      });
                      return;
                    }
                    if (weight < 0) {
                      setState(() {
                        _weightErrorText = 'Please enter a valid weight';
                      });
                      return;
                    }

                    Navigator.of(context).pop(
                      ExerciseSet(
                        reps: reps,
                        weight: weight,
                        isWarmUp: _isWarmUpController,
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
      )
    );
  }
}
