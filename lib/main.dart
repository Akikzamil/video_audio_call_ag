
import 'package:flutter/material.dart';
import 'package:video_audio_call/select_id.dart';
import 'package:firebase_core/firebase_core.dart';
// Import the generated file





void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        primarySwatch: Colors.blue,
      ),
      home: const SelectId(),
    );
  }
}






