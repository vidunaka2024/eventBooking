import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventInformationScreen extends StatelessWidget {
  const EventInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? docId = ModalRoute.of(context)?.settings.arguments as String?;
    if (docId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Information')),
        body: const Center(child: Text('No event selected.')),
      );
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final docRef = firestore.collection('events').doc(docId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Information'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: docRef.get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading event info.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Event not found.'));
          }

          final data = snapshot.data!.data()!;
          final eventName = data['event_name'] ?? 'No Name';
          final date = data['date']?.toDate()?.toString() ?? 'No Date';
          final eventType = data['event_type'] ?? 'No Type';
          final price = data['price']?.toString() ?? 'No Price';
          final availableCount = data['available_count']?.toString() ?? 'N/A';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  eventName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Date: $date'),
                Text('Type: $eventType'),
                Text('Price: $price'),
                Text('Available Tickets: $availableCount'),
                const SizedBox(height: 16),
                const Text(
                  'Additional event description goes here. '
                  'Enjoy a great time with music, fun, and more!',
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to the payment gateway
                    // Pass event docId or data if needed
                    Navigator.pushNamed(
                      context,
                      '/creditCardPayment',
                      arguments: {
                        'docId': docId,
                        'eventName': eventName,
                        'price': double.tryParse(price) ?? 0.0,
                      },
                    );
                  },
                  child: const Text('Purchase Tickets'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
