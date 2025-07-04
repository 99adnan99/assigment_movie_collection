import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String connectionStatus = await _checkFirebaseConnection();
  runApp(MyApp(connectionStatus: connectionStatus));
}

Future<String> _checkFirebaseConnection() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return 'Firebase connection successful!';
  } catch (e) {
    return 'Firebase connection failed. Error: $e';
  }
}

class MyApp extends StatelessWidget {
  final String connectionStatus;
  const MyApp({super.key, required this.connectionStatus});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Connection Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MyHomePage(title: 'Firebase Connection Status', connectionStatus: connectionStatus),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String title;
  final String connectionStatus;

  const MyHomePage({super.key, required this.title, required this.connectionStatus});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: Text(
          connectionStatus,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
