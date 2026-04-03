// import 'package:flutter/material.dart';
// import 'package:inersia_supabase/features/auth/screens/login_screen.dart';

// class SplashScreen extends StatelessWidget {
//   const SplashScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0D0D0D),
//       body: Stack(
//         children: [
//           Positioned(
//             top: -50,
//             right: -50,
//             child: Container(
//               width: 200,
//               height: 200,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Colors.blue.withOpacity(0.15),
//               ),
//             ),
//           ),
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Spacer(),
//                   const Text(
//                     "Inersia",
//                     style: TextStyle(
//                       fontSize: 48,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                       letterSpacing: 2,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   const Text(
//                     "Draft your thoughts, publish your world",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(color: Colors.grey, fontSize: 16),
//                   ),
//                   const Spacer(),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 55,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const LoginScreen(),
//                           ),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF3F7AF6),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: const Text(
//                         "Mulai Menulis",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.popAndPushNamed(context, approute)
//                     },
//                     child: const Text(
//                       "Lanjutkan sebagai Tamu",
//                       style: TextStyle(
//                         color: Color(0xFF3F7AF6),
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 40),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
