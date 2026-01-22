import 'package:flutter/material.dart';

// Import only necessary screens
import 'splash_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';

void main() {
  runApp(WorkerApp());
}

class WorkerApp extends StatelessWidget {
  const WorkerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Worker App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFC8E6C9),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.green),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(), // removed const
        '/login': (context) => LoginScreen(), // removed const
        '/home': (context) => HomeScreen(), // removed const
      },
    );
  }
}
