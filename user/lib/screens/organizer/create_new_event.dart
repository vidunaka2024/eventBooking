// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class CreateNewEventScreen extends StatefulWidget {
//   const CreateNewEventScreen({super.key});

//   @override
//   State<CreateNewEventScreen> createState() => _CreateNewEventScreenState();
// }

// class _CreateNewEventScreenState extends State<CreateNewEventScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _eventNameController = TextEditingController();
//   final _eventTypeController = TextEditingController();
//   final _dateController = TextEditingController();
//   final _priceController = TextEditingController();
//   final _availableCountController = TextEditingController();

//   LatLng? _selectedLocation;

//   // Save event to Firestore
//   Future<void> _createEvent() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         final double parsedPrice = double.parse(_priceController.text.trim());
//         final int parsedCount =
//             int.tryParse(_availableCountController.text.trim()) ?? 0;

//         // Convert date string to a timestamp (for simplicity, assume "February 6, 2025")
//         // Real usage: parse with DateFormat or prompt user with a date picker
//         final dateString = _dateController.text.trim();
//         final dateTime = DateTime.tryParse(dateString) ?? DateTime.now();

//         // If location is not chosen, default to (0,0). In real usage, ensure you get user location or map input.
//         final lat = _selectedLocation?.latitude ?? 0.0;
//         final lng = _selectedLocation?.longitude ?? 0.0;

//         await FirebaseFirestore.instance.collection('events').add({
//           'event_name': _eventNameController.text.trim(),
//           'event_type': _eventTypeController.text.trim().toLowerCase(),
//           'date': Timestamp.fromDate(dateTime),
//           'price': parsedPrice,
//           'available_count': parsedCount,
//           'location': GeoPoint(lat, lng),
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Event Created Successfully!')),
//         );
//         Navigator.pop(context);
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error creating event: $e')),
//         );
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _eventNameController.dispose();
//     _eventTypeController.dispose();
//     _dateController.dispose();
//     _priceController.dispose();
//     _availableCountController.dispose();
//     super.dispose();
//   }

//   // Example method to get the user's current location (optional)
//   Future<void> _pickLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) return;

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       permission = await Geolocator.requestPermission();
//       if (!(permission == LocationPermission.whileInUse ||
//           permission == LocationPermission.always)) return;
//     }

//     Position position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );

//     setState(() {
//       _selectedLocation = LatLng(position.latitude, position.longitude);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Create New Event'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               // Event name
//               TextFormField(
//                 controller: _eventNameController,
//                 decoration: const InputDecoration(
//                   labelText: 'Event Name',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) => value == null || value.isEmpty
//                     ? 'Please enter an event name'
//                     : null,
//               ),
//               const SizedBox(height: 16),
//               // Event type
//               TextFormField(
//                 controller: _eventTypeController,
//                 decoration: const InputDecoration(
//                   labelText: 'Event Type (e.g. music, sports, etc.)',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) => value == null || value.isEmpty
//                     ? 'Please enter an event type'
//                     : null,
//               ),
//               const SizedBox(height: 16),
//               // Date
//               TextFormField(
//                 controller: _dateController,
//                 decoration: const InputDecoration(
//                   labelText: 'Date (YYYY-MM-DD or parseable format)',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) => value == null || value.isEmpty
//                     ? 'Please enter a date'
//                     : null,
//               ),
//               const SizedBox(height: 16),
//               // Price
//               TextFormField(
//                 controller: _priceController,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(
//                   labelText: 'Price (e.g. 1000)',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) =>
//                     value == null || value.isEmpty ? 'Enter a price' : null,
//               ),
//               const SizedBox(height: 16),
//               // Available tickets
//               TextFormField(
//                 controller: _availableCountController,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(
//                   labelText: 'Available Tickets',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) => value == null || value.isEmpty
//                     ? 'Enter available ticket count'
//                     : null,
//               ),
//               const SizedBox(height: 16),
//               // Pick location
//               Row(
//                 children: [
//                   ElevatedButton(
//                     onPressed: _pickLocation,
//                     child: const Text('Use Current Location'),
//                   ),
//                   const SizedBox(width: 10),
//                   Text(_selectedLocation == null
//                       ? 'No location chosen'
//                       : 'Lat: ${_selectedLocation!.latitude}, '
//                         'Lng: ${_selectedLocation!.longitude}'),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               // Submit
//               ElevatedButton(
//                 onPressed: _createEvent,
//                 child: const Text('Create Event'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
