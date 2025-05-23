import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_sorteio_cliente/screens/sorteio/home_page.dart';
import 'firebase_options.dart'; // auto-generated by FlutterFire CLI

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sorteio App',
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}