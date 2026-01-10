import 'package:cloud_firestore/cloud_firestore.dart';
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
          widget = const OnBoardingRouter();
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


class OnBoardingRouter extends StatelessWidget {
  const OnBoardingRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = sl.get<AuthService>().currentUser!.uid;

    return FutureBuilder(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingPage();
        }

        final userData = snapshot.data!.data();
        final emailVerificationCompleted = userData != null && userData['isEmailVerificationCompleted'] == true;

        // return LoginScreen();
        if (emailVerificationCompleted) {
          return const HomeScreen();
        } else {
          return const EmailVerificationScreen();
        }
      },
    );
  }
}


class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('A verification link has been sent to your email.'),
            SizedBox(height: 16),
            Text('Please verify your email to continue.'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final authService = sl.get<AuthService>();


                await authService.currentUser?.reload();
                if (authService.currentUser!.emailVerified) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(authService.currentUser!.uid)
                      .update({'isEmailVerificationCompleted': true});
                  Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(builder: (context) => HomeScreen()), 
                    (route) => false,
                  );
                }
              }, 
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
