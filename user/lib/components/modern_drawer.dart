import 'package:flutter/material.dart';

class ModernDrawer extends StatelessWidget {
  final VoidCallback onLogout;

  const ModernDrawer({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E1E), Color(0xFF161616)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Modern Header with gradient background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A148C), Color(0xFF880E4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(50),
                ),
              ),
              // ignore: prefer_const_constructors
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/images/image.png'),
                    radius: 40,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Event Organizer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Optionally add a subtitle, like an email:
                  // Text('organizer@example.com', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            // Drawer Options
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading:
                        Icon(Icons.home, color: Colors.white.withOpacity(0.8)),
                    title: const Text('Home',
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      // Add your navigation logic here.
                    },
                  ),
                  // ListTile(
                  //   leading: Icon(Icons.settings,
                  //       color: Colors.white.withOpacity(0.8)),
                  //   title: const Text('Settings',
                  //       style: TextStyle(color: Colors.white)),
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //     // Add settings navigation logic here.
                  //   },
                  // ),
                  const Divider(
                      color: Colors.white54, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(Icons.logout,
                        color: Colors.white.withOpacity(0.8)),
                    title: const Text('Logout',
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      onLogout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
