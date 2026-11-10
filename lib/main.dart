import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'state.dart';
import 'screens.dart';
import 'reminder_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  final state = AppState();
  runApp(
    ChangeNotifierProvider.value(value: state, child: const AutoSphereApp()),
  );
  await Future.wait([state.initDB(), ReminderNotifications.initialize()]);
  await ReminderNotifications.scheduleAll(state.reminders);
}

class AutoSphereApp extends StatelessWidget {
  const AutoSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoSphere',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        fontFamily: 'Avenir Next',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF5E91FF),
          onPrimary: Color(0xFFFFFFFF),
          secondary: Color(0xFF43D6B5),
          surface: Color(0xFF151C25),
          onSurface: Color(0xFFF3F6FB),
          error: Color(0xFFFF7468),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF222D39),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2C3847)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2C3847)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF5E91FF), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF7468)),
          ),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
