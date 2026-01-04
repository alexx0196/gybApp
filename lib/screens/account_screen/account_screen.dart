import 'package:cloud_firestore/cloud_firestore.dart';
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
  AuthFireStoreService authFireStoreService = AuthFireStoreService();
  DocumentSnapshot<Map<String, dynamic>>? userData;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void getUserData() async {
    var data = await authFireStoreService.getUserData(authService.currentUser!.uid);
    setState(() {
      userData = data;
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
      body: Center(
        child: Column(
          children: [
            Text('Your account, ${dataMap['username']}'),
            const SizedBox(height: 20),
            Text('Email: ${dataMap['gender']}, ${dataMap['dateOfBirth'].toDate().toString().split(' ')[0]}'), 
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Weight: ${dataMap['weight'].toString()} kg'),
                const SizedBox(width: 20),
                Text('Height: ${dataMap['height'].toString()} cm'),
                const SizedBox(width: 20),
                Text('BMI: ${(dataMap['weight'] / ((dataMap['height'] / 100) * (dataMap['height'] / 100))).toStringAsFixed(2)}'),
              ],
            ),
            ElevatedButton(onPressed: () => singOut(), child: const Text('Sign out')),
          ],
        )
      ),
      drawer: AppDrawer(),
    );
  }
}

