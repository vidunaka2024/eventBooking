import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreditCardPaymentScreen extends StatefulWidget {
  const CreditCardPaymentScreen({super.key});

  @override
  State<CreditCardPaymentScreen> createState() =>
      _CreditCardPaymentScreenState();
}

class _CreditCardPaymentScreenState extends State<CreditCardPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _ticketCountController = TextEditingController(text: '1');

  String? eventDocId;
  String? eventName;
  double? eventPrice;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      eventDocId = args['docId'] as String?;
      eventName = args['eventName'] as String?;
      eventPrice = args['price'] as double?;
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _ticketCountController.dispose();
    super.dispose();
  }

  /// Simulate payment and record purchase in Firestore's `tickets` collection.
  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final noOfTickets = int.tryParse(_ticketCountController.text.trim()) ?? 1;
    final totalPrice = (eventPrice ?? 0.0) * noOfTickets;

    try {
      // Insert into tickets collection
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore.collection('tickets').add({
        'event_id': eventDocId ?? 'unknown',
        'event_name': eventName ?? 'Unknown Event',
        'no_of_tickets': noOfTickets,
        'unit_price': eventPrice ?? 0.0,
        'total_price': totalPrice,
        'unit_id': 'some_unique_ticket_id', // or generate a random ID
        'purchase_date': Timestamp.now(),
      });

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful!')),
      );

      // Optionally navigate to purchased tickets screen
      Navigator.pushNamed(context, '/purchasedTickets');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayEvent = eventName ?? 'No Event Selected';
    final double displayPrice = eventPrice ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Card Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Display the event name & price
              Text(
                'Purchasing tickets for: $displayEvent',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Price per ticket: $displayPrice'),
              const SizedBox(height: 16),
              // Number of tickets
              TextFormField(
                controller: _ticketCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of Tickets',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Card Number
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: '1234 5678 9012 3456',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 16) {
                    return 'Please enter a valid card number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Expiry Date
              TextFormField(
                controller: _expiryController,
                decoration: const InputDecoration(
                  labelText: 'Expiry Date (MM/YY)',
                  hintText: '12/25',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      !RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                    return 'Please enter a valid expiry date (MM/YY)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // CVV
              TextFormField(
                controller: _cvvController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 3 || value.length > 4) {
                    return 'Please enter a valid CVV';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _processPayment,
                child: const Text('Pay Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
