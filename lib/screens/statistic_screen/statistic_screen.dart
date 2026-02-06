import 'package:flutter/material.dart';
import 'package:gym_tracker/db_services/db_services.dart';
import 'package:gym_tracker/screens/app_drawer/app_drawer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';


class StatisticScreen extends StatefulWidget {
  const StatisticScreen({super.key});

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}


class _StatisticScreenState extends State<StatisticScreen> {
  final authService = sl.get<AuthService>();
  StatisticService statisticService = StatisticService();

  String? _choosedExercise;
  double? _maxWeight;
  double? _volume;
  int? _workoutCount;
  Map<String, List<dynamic>>? _stats;
  bool _isLoading = false;

  Future<void> _loadStatistics() async {
    // statisticService.migrationForStats(authService.currentUser!.uid);
    if (_choosedExercise == null) return;
    setState(() {
      _isLoading = true;
    });
    final stats = await statisticService.getStatisticsForExercise(
      authService.currentUser!.uid,
      _choosedExercise!,
    );
    setState(() {
      _maxWeight = stats['maxWeight'];
      _volume = stats['volume'];
      _workoutCount = stats['workoutCount'];
      _stats = stats['detailedStats'];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistic Screen'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                const Text('Упражнение'),
                const SizedBox(width: 20,),
                FutureBuilder(
                  future: statisticService.getAllExercises(authService.currentUser!.uid), builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final exercises = snapshot.data!;
                      return DropdownMenu(
                        dropdownMenuEntries: exercises.map((e) => DropdownMenuEntry(value: e, label: e)).toList(),
                        onSelected: (value) {
                          setState(() {
                            _choosedExercise = value;
                            _loadStatistics();
                          });
                        },
                      );
                    }
                    return const CircularProgressIndicator();
                  }
                ),
              ],
            )
          ),
          SizedBox(height: 20,),
          Text(_isLoading ? 'Загрузка...' : 'Максимальный вес: ${_maxWeight ?? 0}'),
          SizedBox(height: 20,),
          Text(_isLoading ? 'Загрузка...' : 'Объем: ${_volume ?? 0}'),
          SizedBox(height: 20,),
          Text(_isLoading ? 'Загрузка...' : 'Количество тренировок: ${_workoutCount ?? 0}'),
          SizedBox(height: 20,),
          StatsGraph(stats: _stats ?? {}),
          SizedBox(height: 20,),
        ],
      ),
    drawer: AppDrawer(),
    );
  }
}


class StatsGraph extends StatefulWidget {
  final Map<String, List<dynamic>> stats;

  const StatsGraph({super.key, this.stats = const {}});

  @override
  State<StatsGraph> createState() => _StatsGraphState();
}

class _StatsGraphState extends State<StatsGraph> {
  @override
  Widget build(BuildContext context) {
    final dates = widget.stats['dates'] ?? [];
    final maxWeights = widget.stats['maxWeights'];
    final volumes = widget.stats['volumes'];
    // print(dates);
    // print(maxWeights);
    // print(volumes);

    final List<Map<String, dynamic>> data = [];
    for (int i = 0; i < dates.length; i++) {
      data.add({
        'date': dates[i],
        'weight': maxWeights![i],
        'volume': volumes![i],
      });
    }

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: DateTimeAxis(
        minimum: dates.isNotEmpty ? dates.first : DateTime.now().subtract(const Duration(days: 7)),
        maximum: dates.isNotEmpty ? dates.last : DateTime.now(),
        rangePadding: ChartRangePadding.normal,
        edgeLabelPlacement: EdgeLabelPlacement.shift,
        intervalType: DateTimeIntervalType.days,
        axisLine: AxisLine(width: 0),
        majorTickLines: MajorTickLines(size: 0)
      ),
      primaryYAxis: const NumericAxis(
        labelFormat: '{value} kg',
        axisLine: AxisLine(width: 0),
        majorTickLines: MajorTickLines(size: 0)
      ),
      title: ChartTitle(text: 'Weight History'),
      legend: Legend(isVisible: false),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <LineSeries>[
        LineSeries<Map<String, dynamic>, DateTime>(
          dataSource: data,
          xValueMapper: (Map<String, dynamic> data, _) => data['date'],
          yValueMapper: (Map<String, dynamic> data, _) => data['weight'],
          name: 'Weight',
          dataLabelSettings: DataLabelSettings(isVisible: true),
          markerSettings: const MarkerSettings(isVisible: true),
        ),
        LineSeries<Map<String, dynamic>, DateTime>(
          dataSource: data,
          xValueMapper: (Map<String, dynamic> data, _) => data['date'],
          yValueMapper: (Map<String, dynamic> data, _) => data['volume'],
          name: 'Volume',
          dataLabelSettings: DataLabelSettings(isVisible: true),
          markerSettings: const MarkerSettings(isVisible: true),
        )
      ]
    );
  }
}
