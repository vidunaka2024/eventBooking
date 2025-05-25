import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class CustomCardEntryScreen extends StatefulWidget {
  const CustomCardEntryScreen({Key? key}) : super(key: key);

  @override
  _CustomCardEntryScreenState createState() => _CustomCardEntryScreenState();
}

class _CustomCardEntryScreenState extends State<CustomCardEntryScreen> {
  bool _isProcessing = false;
  PaymentMethod? _paymentMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Card Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Card form field for entering card details
            CardFormField(
              onCardChanged: (card) {
                // Handle card changes if needed.
              },
            ),
            const SizedBox(height: 24),
            // Button to create the payment method
            _isProcessing
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handlePayPress,
                    child: const Text('Pay with Card'),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayPress() async {
    setState(() => _isProcessing = true);
    try {
      // Create a PaymentMethod using the updated API signature.
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              email: 'test@example.com', // Replace with real billing info if available.
            ),
          ),
        ),
      );

      setState(() {
        _paymentMethod = paymentMethod;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PaymentMethod created: ${paymentMethod.id}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating PaymentMethod: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}
