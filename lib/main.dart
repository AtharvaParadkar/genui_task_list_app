import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:genui_task_list_app/app_theme.dart';
import 'package:genui_task_list_app/firebase_options.dart';
import 'package:genui_task_list_app/home_page.dart';

const taskDisplaySurfaceId = 'task_display';

/// Global notifier so any widget can toggle the theme.
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Just Today',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          debugShowCheckedModeBanner: false,
          home: const MyHomePage(),
        );
      },
    );
  }
}
