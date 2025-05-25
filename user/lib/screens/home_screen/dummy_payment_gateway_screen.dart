import 'package:flutter/material.dart';

class DummyPaymentGatewayScreen extends StatefulWidget {
  const DummyPaymentGatewayScreen({super.key});

  @override
  State<DummyPaymentGatewayScreen> createState() =>
      _DummyPaymentGatewayScreenState();
}

class _DummyPaymentGatewayScreenState extends State<DummyPaymentGatewayScreen> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  bool _isProcessing = false;

  /// Simulate the payment process.
  Future<void> _simulatePayment() async {
    if (_cardNumberController.text.isEmpty ||
        _expiryController.text.isEmpty ||
        _cvvController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate a delay to mimic processing time.
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isProcessing = false;
    });

    // Show a success message and then pop back to the previous screen.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Payment Successful"),
        content: const Text("Your payment has been processed successfully."),
        actions: [
          TextButton(
            onPressed: () {
              // This pops the AlertDialog *and* returns `'success'` 
              // from the payment screen to wherever it was called.
              Navigator.of(context).pop('success');
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dummy Payment Gateway"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Card Number Field
            TextField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: "Card Number",
                hintText: "1234 5678 9012 3456",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            // Expiry Date Field
            TextField(
              controller: _expiryController,
              decoration: const InputDecoration(
                labelText: "Expiry Date",
                hintText: "MM/YY",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 16),
            // CVV Field
            TextField(
              controller: _cvvController,
              decoration: const InputDecoration(
                labelText: "CVV",
                hintText: "123",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            // Pay Now Button or processing indicator
            _isProcessing
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _simulatePayment,
                    child: const Text("Pay Now"),
                  ),
          ],
        ),
      ),
    );
  }
}
