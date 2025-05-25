import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'my_tickets_screen.dart'; // Import the screen where purchases are shown

class ModernDrawer extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? profileImageUrl;
  final VoidCallback onLogout;
  final String userId; // Used for updating the location

  // Whether the 10 km radius filter is currently on/off
  final bool isRadiusFilterActive;

  // Callback invoked when the user toggles the 10 km radius filter switch
  final ValueChanged<bool> onRadiusFilterChanged;

  const ModernDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    this.profileImageUrl,
    required this.onLogout,
    required this.userId,
    required this.isRadiusFilterActive,
    required this.onRadiusFilterChanged,
  });

  @override
  State<ModernDrawer> createState() => _ModernDrawerState();
}

class _ModernDrawerState extends State<ModernDrawer> {
  // Function to update the user's location via the backend API.
  Future<void> updateUserLocation(String location) async {
    // Build the URL with query parameter for location.
    final url = 'http://10.0.2.2:8080/api/users/${widget.userId}/location?location=$location';

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        debugPrint('Location updated successfully.');
      } else {
        debugPrint('Failed to update location: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero, // Remove default padding at the top of the drawer
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(widget.userName),
            accountEmail: Text(widget.userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundImage: widget.profileImageUrl != null
                  ? NetworkImage(widget.profileImageUrl!)
                  : null,
              child: widget.profileImageUrl == null ? const Icon(Icons.person) : null,
            ),
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
          ),
          // Menu item to update location.
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Update Location'),
            onTap: () async {
              // For demonstration, we use a hard-coded location value.
              const String location = '6.9271,79.8612';
              await updateUserLocation(location);

              // Optionally show a confirmation message.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location updated')),
              );
              Navigator.pop(context); // Close the drawer.
            },
          ),
          // Toggle option for searching events within 10 km radius.
          SwitchListTile(
            secondary: const Icon(Icons.my_location),
            title: const Text('Search within 10 km radius'),
            value: widget.isRadiusFilterActive,
            onChanged: (bool value) {
              // Notify HomeScreen that the user toggled the switch
              widget.onRadiusFilterChanged(value);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Search within 10 km radius ${value ? 'enabled' : 'disabled'}"),
                ),
              );
            },
          ),
          // Menu item to navigate to MyTicketsScreen.
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('View My Purchases'),
            onTap: () {
              Navigator.pop(context); // Close the drawer before navigating
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyTicketsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          // Existing logout item.
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: widget.onLogout,
          ),
        ],
      ),
    );
  }
}
