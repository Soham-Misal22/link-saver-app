// // In your admin_dashboard_screen.dart file
//
// import 'package:flutter/material.dart';
// import 'package:cloud_functions/cloud_functions.dart';
// import 'kpi_card.dart'; // Import the new card widget
//
// class AdminDashboardScreen extends StatefulWidget {
//   const AdminDashboardScreen({super.key});
//
//   @override
//   State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
// }
//
// class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
//   // Use FutureBuilder to handle loading the data from the Cloud Functions
//   Future<int> _fetchTotalUsers() async {
//     final result = await FirebaseFunctions.instance.httpsCallable('getTotalUsers').call();
//     return result.data['count'];
//   }
//
//   Future<int> _fetchTotalLinks() async {
//     final result = await FirebaseFunctions.instance.httpsCallable('getTotalLinksSaved').call();
//     return result.data['count'];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Admin Dashboard")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: GridView.count(
//           crossAxisCount: 2,
//           crossAxisSpacing: 16,
//           mainAxisSpacing: 16,
//           childAspectRatio: 1.2,
//           children: [
//             // Card for Total Users
//             FutureBuilder<int>(
//               future: _fetchTotalUsers(),
//               builder: (context, snapshot) {
//                 return KpiCard(
//                   title: "Total Users",
//                   value: snapshot.hasData ? snapshot.data.toString() : "...",
//                   icon: Icons.people_alt_outlined,
//                   iconColor: Colors.purple,
//                 );
//               },
//             ),
//             // Card for Total Links Saved
//             FutureBuilder<int>(
//               future: _fetchTotalLinks(),
//               builder: (context, snapshot) {
//                 return KpiCard(
//                   title: "Total Links Saved",
//                   value: snapshot.hasData ? snapshot.data.toString() : "...",
//                   icon: Icons.link,
//                   iconColor: Colors.orange,
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }