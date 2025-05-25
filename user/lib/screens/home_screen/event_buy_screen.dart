import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart' as geo;

// Make sure you have PaymentGatewayScreen imported from its own file.
import 'payment_gateway_screen.dart';

// Import your updated Event model.
import 'event_model.dart';

/// Helper function to geocode an address into LatLng.
/// On Web, uses the Google Geocoding REST API with [googleApiKey].
/// On Android/iOS, uses the device-based geocoding plugin.
Future<LatLng?> geocodeAddress(String address, String googleApiKey) async {
  if (kIsWeb) {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$googleApiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          double lat = location['lat'];
          double lng = location['lng'];
          return LatLng(lat, lng);
        } else {
          print("Web geocoding: got status=${data['status']}");
          return null;
        }
      } else {
        print("Web geocoding: HTTP error ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Web geocoding error: $e");
      return null;
    }
  } else {
    try {
      final List<geo.Location> locations =
          await geo.locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        return LatLng(loc.latitude, loc.longitude);
      }
      return null;
    } catch (e) {
      print("Mobile geocoding error: $e");
      return null;
    }
  }
}

class EventBuyScreen extends StatefulWidget {
  final Event event;
  const EventBuyScreen({super.key, required this.event});

  @override
  State<EventBuyScreen> createState() => _EventBuyScreenState();
}

class _EventBuyScreenState extends State<EventBuyScreen> {
  int _ticketCount = 1;
  bool _isPurchasing = false;
  int? _userRating; // User's submitted rating

  LatLng? _eventLocation;
  bool _isLocationLoading = true;
  GoogleMapController? _mapController;

  // Replace with your actual API key for web geocoding.
  static const String _webGeocodingApiKey =
      'AIzaSyDQttE3cSnfZPt_K2UB9HYg1UWhdncQuPs';

  @override
  void initState() {
    super.initState();
    _initEventLocation();
    _fetchUserRating();
  }

  /// Initializes the event's location (by parsing or geocoding).
  Future<void> _initEventLocation() async {
    String locStr = widget.event.location;
    if (locStr.startsWith("[") && locStr.endsWith("]")) {
      // Parse the coordinate string, e.g., "[37.7749, -122.4194]"
      locStr = locStr.substring(1, locStr.length - 1);
      List<String> parts = locStr.split(",");
      if (parts.length >= 2) {
        double? lat = double.tryParse(parts[0].trim());
        double? lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          setState(() {
            _eventLocation = LatLng(lat, lng);
            _isLocationLoading = false;
          });
          return;
        }
      }
    }
    // If not a coordinate string, geocode the location text.
    final loc = await geocodeAddress(widget.event.location, _webGeocodingApiKey);
    setState(() {
      _eventLocation = loc;
      _isLocationLoading = false;
    });
  }

  /// Fetches the current user's rating for this event.
  Future<void> _fetchUserRating() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final userId = currentUser.uid;
    final eventId = widget.event.id;
    final url = "http://10.0.2.2:8080/api/ratings/user/$userId/event/$eventId";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userRating = data['rating'] as int?;
        });
      } else if (response.statusCode == 204) {
        setState(() {
          _userRating = null;
        });
      } else {
        print("Failed to fetch user rating: ${response.body}");
      }
    } catch (e) {
      print("Error fetching user rating: $e");
    }
  }

  /// Submits the user's rating.
  Future<void> _submitRating() async {
    if (_userRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a rating.")),
      );
      return;
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not authenticated")),
      );
      return;
    }
    final userId = currentUser.uid;
    final eventId = widget.event.id;
    try {
      // First, attempt to get existing rating.
      final urlGet =
          "http://10.0.2.2:8080/api/ratings/user/$userId/event/$eventId";
      final responseGet = await http.get(Uri.parse(urlGet));

      if (responseGet.statusCode == 200) {
        // Rating exists: update it via two separate PUT requests.
        final urlPut =
            "http://10.0.2.2:8080/api/events/$eventId/rating?rating=$_userRating";
        final responsePut = await http.put(Uri.parse(urlPut));
        if (responsePut.statusCode == 200 || responsePut.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text("Rating updated successfully (events)")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Rating update failed: ${responsePut.body}")),
          );
        }

        final url2Put =
            "http://10.0.2.2:8080/api/ratings/user/$userId/event/$eventId?rating=$_userRating";
        final responsePut2 = await http.put(Uri.parse(url2Put));
        if (responsePut2.statusCode == 200 ||
            responsePut2.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Rating updated successfully (ratings)")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Rating update failed: ${responsePut2.body}")),
          );
        }
      } else if (responseGet.statusCode == 204) {
        final ratingPayload = {
          "userId": userId,
          "eventId": eventId,
          "rating": _userRating,
        };
        const urlPost = "http://10.0.2.2:8080/api/ratings";
        final responsePost = await http.post(
          Uri.parse(urlPost),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(ratingPayload),
        );
        if (responsePost.statusCode == 200 ||
            responsePost.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Rating submitted successfully")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Rating submission failed: ${responsePost.body}")),
          );
        }
      } else {
        final ratingPayload = {
          "userId": userId,
          "eventId": eventId,
          "rating": _userRating,
        };
        const urlPost = "http://10.0.2.2:8080/api/ratings";
        final responsePost = await http.post(
          Uri.parse(urlPost),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(ratingPayload),
        );
        if (responsePost.statusCode == 200 ||
            responsePost.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Rating submitted successfully")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Rating submission failed: ${responsePost.body}")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating rating: $e")),
      );
    }
  }

  /// Navigates to PaymentGatewayScreen, and if payment succeeds, posts ticket data and updates the event's ticket count.
  Future<void> _purchaseTicket() async {
    setState(() {
      _isPurchasing = true;
    });

    try {
      // Navigate to PaymentGatewayScreen and wait for payment result.
      final paymentResult = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PaymentGatewayScreen()),
      );

      if (paymentResult != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment was not successful")),
        );
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }
      final userId = currentUser.uid;
      final unitPrice = widget.event.price;
      final totalPrice = unitPrice * _ticketCount;
      final purchaseDate = DateTime.now().toIso8601String();
      final eventId = widget.event.id.toString();

      final Map<String, dynamic> ticketData = {
        "eventId": eventId,
        "userId": userId,
        "eventName": widget.event.eventName,
        "noOfTickets": _ticketCount,
        "purchaseDate": purchaseDate,
        "totalPrice": totalPrice,
        "unitPrice": unitPrice,
      };

      final purchaseUrl = "http://10.0.2.2:8080/api/tickets/$userId";
      final purchaseResponse = await http.post(
        Uri.parse(purchaseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(ticketData),
      );

      if (purchaseResponse.statusCode != 200 &&
          purchaseResponse.statusCode != 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Purchase failed: ${purchaseResponse.body}")),
        );
        return;
      }

      final updateUrl =
          "http://10.0.2.2:8080/api/events/$eventId/tickets?ticketCount=$_ticketCount";
      final updateResponse = await http.put(Uri.parse(updateUrl));
      if (updateResponse.statusCode == 200 ||
          updateResponse.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ticket purchased successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Purchase succeeded but update failed: ${updateResponse.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error purchasing ticket: $e")),
      );
    } finally {
      setState(() {
        _isPurchasing = false;
      });
    }
  }

  /// Builds a row of 5 star icons for rating input.
  Widget _buildStarRating() {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      stars.add(
        IconButton(
          icon: Icon(
            i <= (_userRating ?? 0) ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () {
            setState(() {
              _userRating = i;
            });
          },
        ),
      );
    }
    return Row(children: stars);
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.event.price * _ticketCount;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.eventName),
        backgroundColor: const Color(0xFF1F1B24),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event image with rounded corners.
              Center(
                child: widget.event.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          widget.event.imageUrl,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.event,
                            size: 100, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 20),
              // Event details container.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1B24),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event name.
                    Text(
                      widget.event.eventName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Overall rating.
                    Text(
                      "Overall Rating: ${widget.event.rating}/5",
                      style: const TextStyle(
                          fontSize: 18, color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    // Your Rating input.
                    const Text(
                      "Your Rating:",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    _buildStarRating(),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _submitRating,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                      child: const Text(
                        "Submit Rating",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Ticket and event info container.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1B24),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ticket price.
                    Text(
                      "Ticket Price: \$${widget.event.price}",
                      style:
                          const TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    // Venue.
                    Text(
                      "Venue: ${widget.event.location}",
                      style:
                          const TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    // Date & Time.
                    Text(
                      "Date & Time: ${widget.event.date}",
                      style:
                          const TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Map container.
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade900,
                ),
                child: _isLocationLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _eventLocation == null
                        ? const Center(
                            child: Text(
                              "Unable to load map for this location",
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _eventLocation!,
                                zoom: 14,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('eventVenue'),
                                  position: _eventLocation!,
                                  infoWindow: InfoWindow(
                                    title: widget.event.eventName,
                                    snippet: widget.event.location,
                                  ),
                                ),
                              },
                            ),
                          ),
              ),
              const SizedBox(height: 20),
              // Ticket quantity selector.
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1B24),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Tickets:",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_ticketCount > 1) _ticketCount--;
                        });
                      },
                      icon: const Icon(Icons.remove, color: Colors.white),
                    ),
                    Text(
                      _ticketCount.toString(),
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _ticketCount++;
                        });
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Total price.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1B24),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "Total Price: \$$totalPrice",
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              // Buy Ticket button.
              Center(
                child: _isPurchasing
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _purchaseTicket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Buy Ticket",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}