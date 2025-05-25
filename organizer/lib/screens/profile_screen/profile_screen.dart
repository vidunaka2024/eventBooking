import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? "No Name";

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1B24),
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Text(
          "Hello, $displayName",
          style: const TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}
