import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
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


class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  AuthService authService = sl.get<AuthService>();

  String? currentEmail = '';

  final _emailFormKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();

  final _passwordFormKey = GlobalKey<FormState>();
  final _enteredPassword = TextEditingController();

  @override
  void dispose() {
    _enteredPassword.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    currentEmail = authService.currentUser?.email;
  }

  // Если пользователь зарегистрировался, ему отравилось письмо и он долго его не подтверждал, то вызовется requires-recent-login.
  // это означает, что мне надо еще раз пользователя обновить, для этого я тут пароль проверяю.
  Future<void> _checkPasswordForChangeEmail({required String email}) {
    return showDialog(
      context: context, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Нужно, чтобы вы ввели пароль'),
          content: Form(
            key: _passwordFormKey,
            child: TextFormField(
              controller: _enteredPassword,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              validator: MultiValidator([
                RequiredValidator(errorText: 'Please enter your password'),
              ],).call,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (!_passwordFormKey.currentState!.validate()) return;
                await authService.reAuthUser(enteredPassword: _enteredPassword.text);
                await authService.changeEmail(email: email);
                Navigator.of(context).pop();
              }, 
              child: const Text('Next'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: const Text('Cancel'),
            ),
          ],
        );
      }
    );
  }

  Future<void> _changeEmailAlert() {
    return showDialog(
      context: context, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change email'),
          content: Form(
            key: _emailFormKey,
            child: TextFormField(
              controller: _newEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'New email',
                border: OutlineInputBorder(),
              ),
              validator: MultiValidator([
                RequiredValidator(errorText: 'Please enter your email'),
                EmailValidator(errorText: 'Please enter a valid email address'),
              ],).call,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (!_emailFormKey.currentState!.validate()) return;
                try {
                  await authService.changeEmail(
                    email: _newEmailController.text,
                  );

                  setState(() {
                    currentEmail = _newEmailController.text;
                  });

                  Navigator.of(context).pop();
                } on FirebaseAuthException catch (e) {
                  if (e.code == 'requires-recent-login') {
                    Navigator.of(context).pop();
                    await _checkPasswordForChangeEmail(email: _newEmailController.text);
                  } else {
                    print(e.code);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.code),
                      ),
                    );
                  }
                }
              }, 
              child: const Text('Change'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: const Text('Cancel'),
            )
          ],
        );
      }
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Please verify your email to continue.',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),
            Text.rich(
              TextSpan(
                children: <TextSpan>[
                  TextSpan(text: 'A verification link has been sent to your email('),
                  TextSpan(
                    text: currentEmail,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ').'),
                ],
              ),
            ),
            SizedBox(height: 14,),
            Padding(
              padding: EdgeInsets.only(left: 16.0, right: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () async {
                    final authService = sl.get<AuthService>();
                    
                    // при обновление почты оно, видимо, вызвается к старому токену, который не обновляется после обновления почты, и появляется
                    // ошибка user-token-expired. в ее случае я просто логаут делаю.
                    try {
                      await authService.currentUser?.reload();
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'user-token-expired') {
                        await authService.signOut();
                        return;
                      }
                    }

                    if (authService.currentUser!.emailVerified) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(authService.currentUser!.uid)
                          .update({'isEmailVerificationCompleted': true});
                      
                      if (!context.mounted) return;

                      Navigator.pushAndRemoveUntil(
                        context, 
                        MaterialPageRoute(builder: (context) => HomeScreen()), 
                        (route) => false,
                      );
                    } else {
                      ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text('Нужно подтвердить почту'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      return;
                    }
                  }, 
                  child: const Text('Continue'),
                ),
              ),
            ),
            SizedBox(height: 8,),
            OutlinedButton(
              onPressed: () => _changeEmailAlert(), 
              child: const Text('Change email')
            ),
          ],
        ),
      ),
    );
  }
}
