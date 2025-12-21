import 'package:flutter/material.dart';
import 'package:gym_tracker/db_services/db_services.dart';
import 'package:gym_tracker/screens/home_screen/home_screen.dart';
import 'package:gym_tracker/screens/registration_login_screens/login_screen.dart';


class AuthLayout extends StatefulWidget {
  const AuthLayout({super.key});

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout> {
  final authService = sl.get<AuthService>();
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: authService.authStateChanges, 
      builder: (context, snapshot) {
        Widget widget;
        if (snapshot.connectionState == ConnectionState.waiting) {
          widget = AppLoadingPage();
        } else if (snapshot.hasData) {
          widget = const HomeScreen();
        } else {
          widget = const LoginScreen();
        }
        return widget;
      },
    );
  }
}


class AppLoadingPage extends StatelessWidget {
  const AppLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator.adaptive(),
      ),
    );
  }
}
