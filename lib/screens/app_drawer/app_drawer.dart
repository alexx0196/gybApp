import 'package:flutter/material.dart';
import 'package:gym_tracker/screens/account_screen/account_screen.dart';
import 'package:gym_tracker/screens/exercises_screen/exercises_screen.dart';
import 'package:gym_tracker/screens/home_screen/home_screen.dart';
import 'package:gym_tracker/screens/statistic_screen/statistic_screen.dart';


class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child: Text('Drawer Header'),
          ),
          ListTile(
            title: const Text('HomePage'),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (BuildContext context) => const HomeScreen(),
              ));
            },
          ),        
          ListTile(
            title: const Text('Exercices'),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (BuildContext context) => const ExercisesScreen(),
              ));
            },
          ),
          ListTile(
            title: const Text('Statistics'),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (BuildContext context) => const StatisticScreen(),
              ));
            },
          ),
          ListTile(
            title: const Text('Account'),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (BuildContext context) => const AccountScreen(),
              ));
            },
          ),
        ],
      ),
    );
  }
}
