import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:genui_task_list_app/firebase_options.dart';
import 'package:genui_task_list_app/home_page.dart';

void main() async {
  // debugPrintRebuildDirtyWidgets: true;
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const GenUiTaskListApp());
}

class GenUiTaskListApp extends StatelessWidget {
  const GenUiTaskListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Just today',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.cyan)),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}
