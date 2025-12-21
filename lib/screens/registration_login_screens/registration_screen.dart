import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gym_tracker/db_services/db_services.dart';
import 'package:gym_tracker/screens/home_screen/home_screen.dart';


class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController username = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  late final authService = sl.get<AuthService>();

  String? forceErrorUsername;
  String? forceErrorEmail;
  String? forceErrorPassword;

  void registr() async {
    try {
      await authService.createAccount(
        email: email.text,
        password: password.text,
        username: username.text,
      );
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => HomeScreen()), 
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.message! == 'The email address is already in use by another account.') {
          forceErrorEmail = e.message!;
        } else if (e.message! == 'Nickname already existe') { // i did not realise that
          forceErrorUsername = e.message!;
        } else if (e.message! == 'Password is not enough strong') { // i did not realise that
          forceErrorPassword = e.message!;
        } else {
          forceErrorPassword = e.message!;
        }
      });
    }
  }

  @override
  void dispose() {
    username.dispose();
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
                    TextFormField(
                      forceErrorText: forceErrorUsername,
                      controller: username,
                      decoration: const InputDecoration(hintText: 'Username'),
                    ),
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
                      onPressed: () => registr(), 
                      child: const Text('Registr'),
                    )
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
