import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gym_tracker/db_services/auth_layout.dart';
import 'package:gym_tracker/db_services/db_services.dart';
import 'package:gym_tracker/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setupAuthLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthLayout(),
    );
  }
}
