import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../model/event_model.dart';
import '../event_details_screen/event_detail_screen.dart';
import '../profile_screen/profile_screen.dart';

// Global RouteObserver instance
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class OrganizerEventsScreen extends StatefulWidget {
  const OrganizerEventsScreen({Key? key}) : super(key: key);

  @override
  State<OrganizerEventsScreen> createState() => _OrganizerEventsScreenState();
}

class _OrganizerEventsScreenState extends State<OrganizerEventsScreen> with RouteAware {
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = fetchOrganizerEvents();
  }

  Future<List<Event>> fetchOrganizerEvents() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("User not authenticated");
    }
    final organizerId = currentUser.uid;
    final apiUrl = "http://localhost:8080/api/events/organizer/$organizerId";
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      List<dynamic> data;
      if (jsonResponse is List) {
        data = jsonResponse;
      } else if (jsonResponse is Map) {
        data = jsonResponse.containsKey('events') ? jsonResponse['events'] : [jsonResponse];
      } else {
        throw Exception("Unexpected JSON format");
      }
      return data.map((e) => Event.fromJson(e)).toList();
    } else {
      throw Exception("No created Events");
    }
  }

  Future<void> _refreshEvents() async {
    setState(() {
      _eventsFuture = fetchOrganizerEvents();
    });
    await _eventsFuture;
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error signing out: $e")));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshEvents();
    super.didPopNext();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Text("My Events", style: textTheme.titleLarge?.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEvents,
        child: FutureBuilder<List<Event>>(
          future: _eventsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text("No events found.", style: TextStyle(color: Colors.white)),
              );
            } else {
              final events = snapshot.data!;
              return ListView.separated(
                padding: const EdgeInsets.all(8),
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    color: Colors.grey[850],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Image Section with full-width display and fixed height
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: event.imageUrl.isNotEmpty
                                ? Image.network(
                                    event.imageUrl,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 180,
                                    color: Colors.grey[700],
                                    child: const Icon(Icons.event, size: 50, color: Colors.white),
                                  ),
                          ),
                          // Details Section below the image
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.eventName,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  event.eventType,
                                  style: textTheme.bodySmall?.copyWith(color: Colors.grey[300]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  event.date,
                                  style: textTheme.bodySmall?.copyWith(color: Colors.grey[300]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text(
          "Create Event",
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        backgroundColor: const Color.fromARGB(255, 80, 26, 206),
        onPressed: () {
          Navigator.pushNamed(context, '/eventCreate');
        },
      ),
    );
  }
}
