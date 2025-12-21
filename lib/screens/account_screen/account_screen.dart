import 'package:flutter/material.dart';
import 'package:gym_tracker/db_services/auth_layout.dart';
import 'package:gym_tracker/db_services/db_services.dart';
import 'package:gym_tracker/screens/app_drawer/app_drawer.dart';


class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final authService = sl.get<AuthService>();

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
    return Scaffold(
      appBar: AppBar(title: const Text('Accont screen'),),
      body: Center(
        child: Column(
          children: [
            const Text('HomeScreen'),
            ElevatedButton(onPressed: () => singOut(), child: const Text('Sign out')),
          ],
        )
      ),
      drawer: AppDrawer(),
    );
  }
}

