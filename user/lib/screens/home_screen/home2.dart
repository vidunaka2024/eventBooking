// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   // Sign-Out Method
//   Future<void> _signOut() async {
//     try {
//       await FirebaseAuth.instance.signOut(); // Sign out from FirebaseAuth
//       // Navigate to the Login Screen
//       Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
//     } catch (e) {
//       // Handle sign-out error
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error signing out: $e")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF161616),
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Row(
//           children: [
//             SizedBox(width: 10),
//             CircleAvatar(
//               backgroundImage: AssetImage('assets/images/image.png'),
//               radius: 20,
//             ),
//             SizedBox(width: 10),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Discover events near you,",
//                   style: TextStyle(fontSize: 14, color: Colors.white),
//                 ),
//                 Text(
//                   "Welcome to Event Organizer",
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications, color: Colors.white),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.logout_outlined, color: Colors.white),
//             onPressed: () async {
//               await _signOut();
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Search bar
//               TextField(
//                 style: const TextStyle(color: Colors.white),
//                 decoration: InputDecoration(
//                   hintText: "Search events...",
//                   hintStyle: const TextStyle(color: Colors.grey),
//                   prefixIcon: const Icon(Icons.search, color: Colors.grey),
//                   filled: true,
//                   fillColor: const Color(0xFF2A2A2A),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(30),
//                     borderSide: BorderSide.none,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // Event categories
//               const Text(
//                 "Event categories",
//                 style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 10),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   _buildCategoryIcon(Icons.music_note, "Music"),
//                   _buildCategoryIcon(Icons.sports_soccer, "Sports"),
//                   _buildCategoryIcon(Icons.local_movies, "Movies"),
//                   _buildCategoryIcon(Icons.local_activity, "Theatre"),
//                 ],
//               ),
//               const SizedBox(height: 20),

//               // Trending events
//               const Text(
//                 "Trending events near you",
//                 style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 10),
//               _buildTrendingCard(
//                 imageUrl: "assets/images/image1.png",
//                 title: "Live music experience",
//                 organizer: "Event Organizer",
//               ),
//               const SizedBox(height: 10),
//               _buildEventCard(
//                 imageUrl: "assets/images/image2.png",
//                 title: "Live Music Festival",
//                 date: "October 15, 2025",
//                 time: "6:00 PM - 11:00 PM",
//               ),
//               const SizedBox(height: 10),
//               _buildEventCard(
//                 imageUrl: "assets/images/event_placeholder.jpg",
//                 title: "Live Music Festival",
//                 date: "October 16, 2025",
//                 time: "8:00 PM - 11:45 PM",
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCategoryIcon(IconData icon, String label) {
//     return Column(
//       children: [
//         CircleAvatar(
//           radius: 30,
//           backgroundColor: const Color(0xFF2A2A2A),
//           child: Icon(icon, color: Colors.white),
//         ),
//         const SizedBox(height: 5),
//         Text(label, style: const TextStyle(color: Colors.grey)),
//       ],
//     );
//   }

//   Widget _buildTrendingCard({
//     required String imageUrl,
//     required String title,
//     required String organizer,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(10),
//         color: Colors.black,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           ClipRRect(
//             borderRadius: const BorderRadius.only(
//               topLeft: Radius.circular(10),
//               topRight: Radius.circular(10),
//             ),
//             child: AspectRatio(
//               aspectRatio: 16 / 9, // Maintain a consistent aspect ratio
//               child: Image.asset(
//                 imageUrl,
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 Text(
//                   organizer,
//                   style: const TextStyle(color: Colors.grey, fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEventCard({
//     required String imageUrl,
//     required String title,
//     required String date,
//     required String time,
//   }) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 5), // Spacing between cards
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 15,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Image Section with Gradient Overlay
//           Stack(
//             children: [
//               ClipRRect(
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(15),
//                   topRight: Radius.circular(15),
//                 ),
//                 child: Image.asset(
//                   imageUrl,
//                   fit: BoxFit.cover,
//                   width: double.infinity,
//                   height: 150,
//                 ),
//               ),
//               // Gradient Overlay
//               Positioned.fill(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         Colors.black.withOpacity(0.6),
//                         Colors.transparent,
//                       ],
//                       begin: Alignment.bottomCenter,
//                       end: Alignment.topCenter,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           // Content Section
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 // Event Details
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         title,
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           const Icon(Icons.calendar_today,
//                               size: 14, color: Colors.grey),
//                           const SizedBox(width: 5),
//                           Text(
//                             date,
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 5),
//                       Row(
//                         children: [
//                           const Icon(Icons.access_time,
//                               size: 14, color: Colors.grey),
//                           const SizedBox(width: 5),
//                           Text(
//                             time,
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 // Modern View Button
//                 SizedBox(
//                   width: 85,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       elevation: 0,
//                       backgroundColor: const Color.fromARGB(255, 0, 0, 0),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 18,
//                         vertical: 12,
//                       ),
//                     ),
//                     onPressed: () {
//                       // Add functionality here
//                     },
//                     child: const Text(
//                       "View",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
