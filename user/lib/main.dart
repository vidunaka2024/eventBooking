import 'package:final_year_project_mobile_app/screens/home_screen/home.dart';
import 'package:final_year_project_mobile_app/screens/home_screen/my_tickets_screen.dart';
import 'package:final_year_project_mobile_app/screens/login_screen/login.dart';
import 'package:final_year_project_mobile_app/screens/register_screen/register.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'firebase_options.dart'; // Import the generated file with Firebase options.

import 'screens/event_information_user/information.dart';
import 'screens/tickets/credit_card_payment.dart';
import 'screens/tickets/purchased_tickets.dart';

/// Make sure you have your own Firebase initialization settings in firebase_options.dart.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase using the options for the current platform.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set your publishable key (test or live)
  Stripe.publishableKey = 'pk_test_51Qvf624D4EMO0MsdbB3dpPCawxFYAXoeBg9vgm1CnsLSy14wrhReBGtH84esEWe4vL6TbpMYJpNk0JQYjmCujL9B00bdDfOcxi'; 
  Stripe.merchantIdentifier = 'merchant.com.yourapp'; // Only needed if using Apple Pay

  
  await Stripe.instance.applySettings();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Organizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/myTickets': (context) => const MyTicketsScreen(),
        '/information': (context) => const EventInformationScreen(),
        '/creditCardPayment': (context) => const CreditCardPaymentScreen(),
        '/purchasedTickets': (context) => const PurchasedTicketsScreen(),
      },
    );
  }
}
