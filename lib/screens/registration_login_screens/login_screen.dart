import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gym_tracker/db_services/db_services.dart';
import 'package:gym_tracker/screens/home_screen/home_screen.dart';
import 'package:gym_tracker/screens/registration_login_screens/registrations_etaps.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreen();
}

class _LoginScreen extends State<LoginScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final authService = sl.get<AuthService>();

  String? forceErrorEmail;
  String? forceErrorPassword;

  void login() async {
    try {
      await authService.signIn(
        email: email.text,
        password: password.text,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => HomeScreen()), 
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        // print(e.code + e.message!);
        if (e.code == 'invalid-email') {
          forceErrorEmail = e.message!;
        } else if (e.code == 'unknown-error') {
          forceErrorPassword = e.message!;
        }
      });
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration'),),
      body: Center(child: FractionallySizedBox(
        widthFactor: 0.8,
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(
                  color: Colors.deepPurple,
                  blurRadius: 5.0
                )],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Padding(
                padding: EdgeInsetsGeometry.all(6.0),
                child: Column(
                  children: [
                    Text('Registration'),
                    SizedBox(height: 10.0,),
                    TextFormField(
                      forceErrorText: forceErrorEmail,
                      controller: email,
                      decoration: const InputDecoration(hintText: 'Email'),
                    ),
                    SizedBox(height: 10.0,),
                    TextFormField(
                      forceErrorText: forceErrorPassword,
                      controller: password,
                      decoration: const InputDecoration(hintText: 'Password'),
                    ),
                    SizedBox(height: 10.0,),
                    ElevatedButton(
                      onPressed: () => login(), 
                      child: const Text('login'),
                    ),
                    SizedBox(height: 10.0,),
                    Text.rich(
                      TextSpan(
                        text: 'Don t have an account?',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrationEmailPassword()));
                        }
                      )
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),)
    );
  }
}