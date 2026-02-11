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
  String? _graphType;
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
          Padding(
            padding: EdgeInsets.all(10.0), 
            child: Row(
              children: [
                const Text('Упражнение'),
                const SizedBox(width: 20,),
                FutureBuilder(
                  future: statisticService.getAllExercises(authService.currentUser!.uid), builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final exercises = snapshot.data!;
                      return DropdownMenu(
                        requestFocusOnTap: false,
                        dropdownMenuEntries: exercises.map((exercise) => DropdownMenuEntry(value: exercise, label: exercise)).toList(), 
                        onSelected: (value) {
                          setState(() {
                            _choosedExercise = value;
                          });
                          _loadStatistics();
                        },
                      );
                    }
                    return const CircularProgressIndicator();
                  }
                ),
                Expanded(child: SizedBox()),
                const Text('Выберите тип графика'),
                const SizedBox(width: 20,),
                DropdownMenu(
                  requestFocusOnTap: false,
                  dropdownMenuEntries: [
                    const DropdownMenuEntry(value: 'weight', label: 'Макс вес'),
                    const DropdownMenuEntry(value: 'avgWeight', label: 'Средний вес за тренировку'),
                    const DropdownMenuEntry(value: 'volume', label: 'Объем'),
                  ], 
                  onSelected: (value) {
                    setState(() {
                      _graphType = value;
                      if (value == 'weight') {
                        _graphType = 'weight';
                      } else if (value == 'avgWeight') {
                        _graphType = 'avgWeight';
                      } else if (value == 'volume') {
                        _graphType = 'volume';
                      }
                    });
                  },
                )
              ],
            ),
          ),
          SizedBox(height: 20,),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Макс вес',
                  value: _isLoading ? 'Загрузка...' : '${_maxWeight ?? 0}',
                  unit: 'kg',
                ),
              ),
              SizedBox(width: 16,),
              Expanded(
                child: StatCard(
                  title: 'Объем',
                  value: _isLoading ? 'Загрузка...' : '${_volume ?? 0}',
                  unit: 'kg',
                ),
              ),
              SizedBox(width: 16,),
              Expanded(
                child: StatCard(
                  title: 'Кол-во тренировок',
                  value: _isLoading ? 'Загрузка...' : '${_workoutCount ?? 0}',
                ),
              ),
            ],
          ),
          SizedBox(height: 20,),
          StatsGraph(stats: _stats ?? {}, graphType: _graphType,),
        ],
      ),
    drawer: AppDrawer(),
    );
  }
}


class StatsGraph extends StatefulWidget {
  final Map<String, List<dynamic>> stats;
  final String? graphType;

  const StatsGraph({super.key, this.stats = const {}, this.graphType});

  @override
  State<StatsGraph> createState() => _StatsGraphState();
}

class _StatsGraphState extends State<StatsGraph> {
  @override
  Widget build(BuildContext context) {
    final dates = widget.stats['dates'] ?? [];
    final maxWeights = widget.stats['maxWeights'];
    final volumes = widget.stats['volumes'];
    final avgWeights = widget.stats['avgWeights'];
    print(dates);
    print(maxWeights);
    print(volumes);
    print(widget.graphType);

    final List<CartesianSeries<dynamic, dynamic>> series = [];

    if (widget.graphType == 'weight') {
      series.add(LineSeries<Map<String, dynamic>, DateTime>(
        dataSource: dates.asMap().entries.map((entry) => {
          'date': entry.value,
          'value': maxWeights != null && entry.key < maxWeights.length ? maxWeights[entry.key] : 0,
        }).toList(),
        xValueMapper: (Map<String, dynamic> data, _) => data['date'],
        yValueMapper: (Map<String, dynamic> data, _) => data['value'],
        name: 'Макс вес',
        dataLabelSettings: DataLabelSettings(isVisible: true),
        markerSettings: const MarkerSettings(isVisible: true),
      ));
    } else if (widget.graphType == 'volume') {
      series.add(LineSeries<Map<String, dynamic>, DateTime>(
        dataSource: dates.asMap().entries.map((entry) => {
          'date': entry.value,
          'value': volumes != null && entry.key < volumes.length ? volumes[entry.key] : 0,
        }).toList(),
        xValueMapper: (Map<String, dynamic> data, _) => data['date'],
        yValueMapper: (Map<String, dynamic> data, _) => data['value'],
        name: 'Объем',
        dataLabelSettings: DataLabelSettings(isVisible: true),
        markerSettings: const MarkerSettings(isVisible: true),
      ));
    } else if (widget.graphType == 'avgWeight') {
      series.add(LineSeries<Map<String, dynamic>, DateTime>(
        dataSource: dates.asMap().entries.map((entry) => {
          'date': entry.value,
          'value': avgWeights != null && entry.key < avgWeights.length ? avgWeights[entry.key] : 0,
        }).toList(),
        xValueMapper: (Map<String, dynamic> data, _) => data['date'],
        yValueMapper: (Map<String, dynamic> data, _) => data['value'],
        name: 'Средний вес',
        dataLabelSettings: DataLabelSettings(isVisible: true),
        markerSettings: const MarkerSettings(isVisible: true),
      ));
    }

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
      series: series,
    );
  }
}


class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),

          const Divider(height: 1),

          // Body (value)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(text: value),
                    if (unit.isNotEmpty)
                      TextSpan(
                        text: ' $unit',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
