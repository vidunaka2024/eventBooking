// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class PostedEventsScreen extends StatelessWidget {
//   const PostedEventsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final FirebaseFirestore firestore = FirebaseFirestore.instance;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Posted Events'),
//       ),
//       body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//         stream: firestore.collection('events').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return const Center(child: Text('Error loading events'));
//           }
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final docs = snapshot.data?.docs ?? [];
//           if (docs.isEmpty) {
//             return const Center(child: Text('No posted events found.'));
//           }

//           return ListView.builder(
//             itemCount: docs.length,
//             itemBuilder: (context, index) {
//               final data = docs[index].data();
//               final eventName = data['event_name'] ?? 'No Name';
//               final date = data['date']?.toDate()?.toString() ?? 'No Date';
//               final eventType = data['event_type'] ?? 'No Type';
//               final price = data['price']?.toString() ?? 'No Price';

//               return ListTile(
//                 title: Text(eventName),
//                 subtitle: Text(
//                   "Date: $date | Type: $eventType | Price: $price",
//                 ),
//                 trailing: IconButton(
//                   icon: const Icon(Icons.edit),
//                   onPressed: () {
//                     // Handle edit logic or navigate to an editing screen
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
