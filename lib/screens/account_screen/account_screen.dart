import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gym_tracker/db_services/auth_layout.dart';
import 'package:gym_tracker/db_services/db_services.dart';
import 'package:gym_tracker/screens/app_drawer/app_drawer.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';


class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final authService = sl.get<AuthService>();
  AuthFireStoreService authFireStoreService = AuthFireStoreService();
  DocumentSnapshot<Map<String, dynamic>>? userData;

  List<Map<String, dynamic>> weightHistory = [];

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void getUserData() async {
    var data = await authFireStoreService.getUserData(authService.currentUser!.uid);
    var weightData = await authFireStoreService.getWeightHistory(authService.currentUser!.uid);

    setState(() {
      userData = data;
      weightHistory = weightData;
    });
  }

  void singOut() async {
    authService.signOut();
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (context) => AuthLayout()), 
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dataMap = userData!.data()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Accont screen'),),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Привет, ${dataMap['username']}', 
              style: Theme.of(context).textTheme.headlineSmall
            ),
            const SizedBox(height: 4),
            Text(
              '${dataMap['gender']}, ${dataMap['dateOfBirth'].toDate().toString().split(' ')[0]}', 
              style: Theme.of(context).textTheme.bodySmall
            ), 

            const SizedBox(height: 24),

            Center(
              child: Column(
                children: [
                  Text(
                    '${dataMap['weight']} kg',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const Text('Current Weight'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('Height'),
                    Text('${dataMap['height']} cm'),
                  ],
                ),
                Column(
                  children: [
                    const Text('BMI'),
                    Text('BMI: ${(dataMap['weight'] / ((dataMap['height'] / 100) * (dataMap['height'] / 100))).toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            Text( 
              'Weight History', 
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: WeightGraph(weightHistory: weightHistory),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await showDialog(
                    context: context, 
                    builder: (context) {
                      return ChangeWeightDialog();
                    }
                  );
                  getUserData();
                },
                child: const Text('Change weight'),
              )
            ),

            const SizedBox(height: 16),

            Center(
              child: ElevatedButton(
                onPressed: singOut, 
                child: const Text('Sign Out')
              ),
            ),
          ],
        )
      ),
      drawer: AppDrawer(),
    );
  }
}


class WeightGraph extends StatelessWidget {
  final List<Map<String, dynamic>> weightHistory;

  const WeightGraph({super.key, required this.weightHistory});

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: DateTimeAxis(
        minimum: weightHistory.isNotEmpty ? weightHistory.first['date'] : DateTime.now().subtract(const Duration(days: 7)),
        maximum: weightHistory.isNotEmpty ? weightHistory.last['date'] : DateTime.now(),
        rangePadding: ChartRangePadding.normal,
        edgeLabelPlacement: EdgeLabelPlacement.shift,
        intervalType: DateTimeIntervalType.days,
        dateFormat: DateFormat.Md(),
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
          dataSource: weightHistory,
          xValueMapper: (Map<String, dynamic> data, _) => data['date'],
          yValueMapper: (Map<String, dynamic> data, _) => data['weight'],
          name: 'Weight',
          dataLabelSettings: DataLabelSettings(isVisible: true),
          markerSettings: const MarkerSettings(isVisible: true),
        )
      ]
    );
  }
}


class ChangeWeightDialog extends StatefulWidget {
  const ChangeWeightDialog({super.key});

  @override
  State<ChangeWeightDialog> createState() => _ChangeWeightDialogState();
}

class _ChangeWeightDialogState extends State<ChangeWeightDialog> {
  AuthService authService = sl.get<AuthService>();
  AuthFireStoreService authFireStoreService = AuthFireStoreService();

  @override
  Widget build(BuildContext context) {
    final weightController = TextEditingController();

    return AlertDialog(
      title: const Text('Change Weight'),
      content: TextField(
        controller: weightController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Enter new weight in kg',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('Cancel')
        ),
        ElevatedButton(
          onPressed: () {
            final newWeight = double.tryParse(weightController.text);
            if (newWeight != null) {
              authFireStoreService.addWeightEntry(authService.currentUser!.uid, newWeight);
              Navigator.pop(context);
            }
          }, 
          child: const Text('Save')
        ),
      ],
    );
  }
}
