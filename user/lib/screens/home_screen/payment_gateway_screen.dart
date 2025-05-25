import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentGatewayScreen extends StatefulWidget {
  const PaymentGatewayScreen({super.key});

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  bool _loading = false;
  bool _ready = false; // Indicates if the PaymentSheet is initialized.
  PaymentMethod? _paymentMethod; // Holds the PaymentMethod from custom card entry.

  // Replace with your backend endpoint which creates a PaymentIntent.
  final String _paymentIntentUrl = 'http://10.0.2.2:8080/create-payment-intent';

  @override
  void initState() {
    super.initState();
    // Conditional initialization for web and mobile.
    if (kIsWeb) {
      debugPrint("Running on web: PaymentSheet might not be fully supported.");
      Stripe.publishableKey = 'your-web-publishable-key-here';
    } else {
      // Initialize Stripe for mobile platforms.
      Stripe.publishableKey =
          'pk_test_51Qvf624D4EMO0MsdbB3dpPCawxFYAXoeBg9vgm1CnsLSy14wrhReBGtH84esEWe4vL6TbpMYJpNk0JQYjmCujL9B00bdDfOcxi';
      Stripe.merchantIdentifier = 'merchant.com.yourapp';
    }
  }

  /// Creates a PaymentIntent on your backend and retrieves the required data.
  Future<Map<String, dynamic>> _createTestPaymentSheet() async {
    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse(_paymentIntentUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': 1099, // Amount in cents (e.g., $10.99)
          'currency': 'usd',
        }),
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      } else {
        throw Exception(
            'Failed to create PaymentIntent. Status code: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating PaymentIntent: $e')),
      );
      rethrow;
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Initializes the PaymentSheet with the client secret and additional parameters.
  Future<void> initPaymentSheet() async {
    try {
      // 1. Create PaymentIntent on the server
      final data = await _createTestPaymentSheet();

      // 2. Initialize the PaymentSheet with extra options.
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          customFlow: false,
          merchantDisplayName: 'Flutter Stripe Store Demo',
          paymentIntentClientSecret: data['paymentIntent'],
          customerEphemeralKeySecret: data['ephemeralKey'],
          customerId: data['customer'],
          applePay: const PaymentSheetApplePay(
            merchantCountryCode: 'US',
          ),
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'US',
            testEnv: true,
          ),
          style: ThemeMode.dark,
        ),
      );
      setState(() {
        _ready = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      rethrow;
    }
  }

  /// Presents the PaymentSheet to complete the payment.
  /// On success, pop true; on failure/cancel, pop false.
  Future<void> _presentPaymentSheet() async {
    await initPaymentSheet();
    if (!_ready) return; // Stop if initialization failed.
    try {
      await Stripe.instance.presentPaymentSheet();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment successful via PaymentSheet")),
      );
      Navigator.of(context).pop(true); // <-- Return true to the previous screen
    } catch (e) {
      if (e is StripeException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Payment cancelled: ${e.error.localizedMessage}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during payment: $e')),
        );
      }
      Navigator.of(context)
          .pop(false); // <-- Return false to the previous screen
    }
  }

  /// Handles the custom card entry flow:
  /// Creates a PaymentMethod using the card details entered in CardFormField.
  /// NOTE: This does NOT finalize payment — you'd need to confirm the PaymentIntent
  /// on your server with this PaymentMethod ID for a real charge.
  Future<void> _handlePayPress() async {
    setState(() => _loading = true);
    try {
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              email:
                  'test@example.com', // Replace with actual billing info if available.
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
      // For a real payment, call your backend to confirm the PaymentIntent.
      // Here, we'll just pop true for demonstration.
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating PaymentMethod: $e')),
      );
      Navigator.of(context).pop(false);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment Gateway"),
        backgroundColor: Colors.blue,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // PaymentSheet Integration Button
                    ElevatedButton(
                      onPressed: _presentPaymentSheet,
                      child: const Text("Pay Now with PaymentSheet"),
                    ),
                    const Divider(height: 40),
                    // Custom Card Entry Integration
                    const Text(
                      "Or enter your card details below:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Wrap CardFormField with a Theme to override icon colors.
                    Theme(
                      data: Theme.of(context).copyWith(
                        iconTheme: const IconThemeData(color: Colors.white),
                        inputDecorationTheme: const InputDecorationTheme(
                          iconColor: Colors.white,
                        ),
                      ),
                      child: CardFormField(
                        style:  CardFormStyle(
                          textColor: Colors.white,
                          placeholderColor: Colors.white,
                          borderColor: Colors.white,
                        ),
                        onCardChanged: (card) {
                          // Handle card details changes if needed.
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _handlePayPress,
                      child: const Text("Pay with Card"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}