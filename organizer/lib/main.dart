import 'package:event_scheduler_app/screens/event_create_screen/create_event_screen.dart';
import 'package:event_scheduler_app/screens/home_screen/organizer_events_screen.dart';
import 'package:event_scheduler_app/screens/login_screen/login.dart';
import 'package:event_scheduler_app/screens/register_screen/register.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart'; // Import the generated file with Firebase options.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase using the options for the current platform.
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
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/eventCreate': (context) => const CreateEventScreen(),
        '/event': (context) => const OrganizerEventsScreen(),
      },
    );
  }
}
