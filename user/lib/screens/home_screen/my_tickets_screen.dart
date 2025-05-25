import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'ticket_model.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  late Future<List<Ticket>> _ticketsFuture;

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _fetchTickets();
  }

  Future<List<Ticket>> _fetchTickets() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("User not authenticated");
    }
    final userId = currentUser.uid;
    // API endpoint: GET http://localhost:8080/api/tickets/user/{userId}
    final apiUrl = "http://10.0.2.2:8080/api/tickets/user/$userId";
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      List<dynamic> data;
      // The API might return a plain list or an object with an "events" or "tickets" key.
      if (jsonResponse is List) {
        data = jsonResponse;
      } else if (jsonResponse is Map && jsonResponse.containsKey('tickets')) {
        data = jsonResponse['tickets'];
      } else {
        data = [];
      }
      return data.map((e) => Ticket.fromJson(e)).toList();
    } else if (response.statusCode == 204) {
      // 204 No Content
      return [];
    } else {
      throw Exception("Failed to fetch tickets: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tickets"),
        backgroundColor: const Color(0xFF1F1B24),
      ),
      backgroundColor: const Color(0xFF121212),
      body: FutureBuilder<List<Ticket>>(
        future: _ticketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No tickets purchased yet.",
                style: TextStyle(color: Colors.white),
              ),
            );
          } else {
            final tickets = snapshot.data!;
            return ListView.builder(
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: ListTile(
                    title: Text(ticket.eventName),
                    subtitle: Text(
                      "Tickets: ${ticket.noOfTickets}\nTotal Price: \$${ticket.totalPrice}\nPurchased on: ${ticket.purchaseDate}",
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
