import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PurchasedTicketsScreen extends StatelessWidget {
  const PurchasedTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchased Tickets'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore.collection('tickets').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading tickets.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No purchased tickets found.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final eventId = data['event_id'] ?? 'Unknown';
              final eventName = data['event_name'] ?? 'No Name';
              final noOfTickets = data['no_of_tickets'] ?? 1;
              final totalPrice = data['total_price'] ?? 0;
              final unitPrice = data['unit_price'] ?? 0;
              final purchaseDate =
                  (data['purchase_date'] as Timestamp).toDate().toString();

              return Card(
                child: ListTile(
                  title: Text(eventName),
                  subtitle: Text(
                    "Event ID: $eventId\n"
                    "Tickets: $noOfTickets\n"
                    "Unit Price: $unitPrice\n"
                    "Total Price: $totalPrice\n"
                    "Purchased: $purchaseDate",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
