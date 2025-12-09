// import 'package:flutter/material.dart';
// import '../models/app_models.dart';

// class MedicationScreen extends StatefulWidget {
//   const MedicationScreen({super.key});

//   @override
//   State<MedicationScreen> createState() => _MedicationScreenState();
// }

// class _MedicationScreenState extends State<MedicationScreen> {
//   final List<Medication> _medications = [
//     Medication(
//       id: 1,
//       name: 'Metacam',
//       pet: 'Buddy',
//       dosage: '5mg',
//       frequency: 'Once daily',
//       nextDose: '8:00 AM',
//       timeLeft: '2 hours',
//       completed: false,
//       reminderEnabled: true,
//       daysLeft: 7,
//       instructions: 'Give with food',
//     ),
//     Medication(
//       id: 2,
//       name: 'Antibiotic Drops',
//       pet: 'Whiskers',
//       dosage: '2 drops',
//       frequency: 'Twice daily',
//       nextDose: '6:00 PM',
//       timeLeft: '8 hours',
//       completed: true,
//       reminderEnabled: true,
//       daysLeft: 3,
//       instructions: 'Apply to affected eye',
//     ),
//     Medication(
//       id: 3,
//       name: 'Heartworm Prevention',
//       pet: 'Buddy',
//       dosage: '1 tablet',
//       frequency: 'Monthly',
//       nextDose: 'Dec 15',
//       timeLeft: '3 days',
//       completed: false,
//       reminderEnabled: true,
//       daysLeft: 30,
//       instructions: 'Give on same date each month',
//     ),
//   ];

//   final List<Map<String, dynamic>> _todaySchedule = [
//     {
//       'time': '8:00 AM',
//       'medication': 'Metacam',
//       'pet': 'Buddy',
//       'status': 'pending'
//     },
//     {
//       'time': '12:00 PM',
//       'medication': 'Vitamin Supplement',
//       'pet': 'Buddy',
//       'status': 'completed'
//     },
//     {
//       'time': '6:00 PM',
//       'medication': 'Antibiotic Drops',
//       'pet': 'Whiskers',
//       'status': 'pending'
//     },
//     {
//       'time': '8:00 PM',
//       'medication': 'Pain Relief',
//       'pet': 'Whiskers',
//       'status': 'missed'
//     },
//   ];

//   void _toggleReminder(int id) {
//     setState(() {
//       final index = _medications.indexWhere((med) => med.id == id);
//       if (index != -1) {
//         final med = _medications[index];
//         _medications[index] = Medication(
//           id: med.id,
//           name: med.name,
//           pet: med.pet,
//           dosage: med.dosage,
//           frequency: med.frequency,
//           nextDose: med.nextDose,
//           timeLeft: med.timeLeft,
//           completed: med.completed,
//           reminderEnabled: !med.reminderEnabled,
//           daysLeft: med.daysLeft,
//           instructions: med.instructions,
//         );
//       }
//     });
//   }

//   void _markCompleted(int id) {
//     setState(() {
//       final index = _medications.indexWhere((med) => med.id == id);
//       if (index != -1) {
//         final med = _medications[index];
//         _medications[index] = Medication(
//           id: med.id,
//           name: med.name,
//           pet: med.pet,
//           dosage: med.dosage,
//           frequency: med.frequency,
//           nextDose: med.nextDose,
//           timeLeft: med.timeLeft,
//           completed: !med.completed,
//           reminderEnabled: med.reminderEnabled,
//           daysLeft: med.daysLeft,
//           instructions: med.instructions,
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Medication'),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//         actions: [
//           ElevatedButton.icon(
//             onPressed: () {},
//             icon: const Icon(Icons.add, size: 16),
//             label: const Text(
//               'Add New',
//               style: TextStyle(fontSize: 12),
//             ),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF10B981),
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             ),
//           ),
//           const SizedBox(width: 16),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildTodaySchedule(),
//             _buildActiveMedications(),
//             _buildQuickActions(),
//             const SizedBox(height: 100),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTodaySchedule() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Today\'s Schedule',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF111827),
//             ),
//           ),
//           const SizedBox(height: 16),
//           ..._todaySchedule.map((item) => _buildScheduleItem(item)),
//         ],
//       ),
//     );
//   }

//   Widget _buildScheduleItem(Map<String, dynamic> item) {
//     Color statusColor;
//     switch (item['status']) {
//       case 'completed':
//         statusColor = const Color(0xFF10B981);
//         break;
//       case 'missed':
//         statusColor = const Color(0xFFEF4444);
//         break;
//       default:
//         statusColor = const Color(0xFFF97316);
//     }

//     return Card(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Row(
//           children: [
//             Container(
//               width: 12,
//               height: 12,
//               decoration: BoxDecoration(
//                 color: statusColor,
//                 shape: BoxShape.circle,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     item['time'],
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   Text(
//                     '${item['medication']} • ${item['pet']}',
//                     style: const TextStyle(
//                       fontSize: 12,
//                       color: Color(0xFF6B7280),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: statusColor.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 item['status'],
//                 style: TextStyle(
//                   fontSize: 10,
//                   color: statusColor,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//             if (item['status'] == 'pending') ...[
//               const SizedBox(width: 8),
//               OutlinedButton(
//                 onPressed: () {},
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                 ),
//                 child: const Icon(Icons.check, size: 12),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActiveMedications() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Active Medications',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF111827),
//             ),
//           ),
//           const SizedBox(height: 16),
//           ..._medications.map((med) => _buildMedicationCard(med)),
//         ],
//       ),
//     );
//   }

//   Widget _buildMedicationCard(Medication med) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Text(
//                             med.name,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               border: Border.all(color: const Color(0xFFE5E7EB)),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               med.pet,
//                               style: const TextStyle(
//                                 fontSize: 10,
//                                 color: Color(0xFF6B7280),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${med.dosage} • ${med.frequency}',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           color: Color(0xFF6B7280),
//                         ),
//                       ),
//                       Text(
//                         med.instructions,
//                         style: const TextStyle(
//                           fontSize: 12,
//                           color: Color(0xFF6B7280),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.notifications,
//                       size: 16,
//                       color: med.reminderEnabled
//                           ? const Color(0xFF10B981)
//                           : const Color(0xFF6B7280),
//                     ),
//                     const SizedBox(width: 4),
//                     Switch(
//                       value: med.reminderEnabled,
//                       onChanged: (value) => _toggleReminder(med.id),
//                       activeThumbColor: const Color(0xFF10B981),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.access_time,
//                       size: 16,
//                       color: Color(0xFF6B7280),
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       'Next: ${med.nextDose}',
//                       style: const TextStyle(
//                         fontSize: 14,
//                         color: Color(0xFF6B7280),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(width: 16),
//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.warning_amber,
//                       size: 16,
//                       color: Color(0xFF6B7280),
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       '${med.daysLeft} days left',
//                       style: const TextStyle(
//                         fontSize: 14,
//                         color: Color(0xFF6B7280),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(
//                   children: [
//                     const Text(
//                       'Next dose in:',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Color(0xFF6B7280),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFFEF3C7),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         med.timeLeft,
//                         style: const TextStyle(
//                           fontSize: 12,
//                           color: Color(0xFFF97316),
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _markCompleted(med.id),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: med.completed
//                         ? Colors.grey[300]
//                         : const Color(0xFF10B981),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 8,
//                     ),
//                   ),
//                   child: Text(
//                     med.completed ? 'Undo' : 'Mark Given',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: med.completed ? Colors.black : Colors.white,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildQuickActions() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Quick Actions',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF111827),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: Card(
//                   child: Container(
//                     decoration: BoxDecoration(
//                       gradient: const LinearGradient(
//                         colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
//                       ),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         children: [
//                           Container(
//                             width: 40,
//                             height: 40,
//                             decoration: const BoxDecoration(
//                               color: Color(0xFF10B981),
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(
//                               Icons.add,
//                               color: Colors.white,
//                               size: 20,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           const Text(
//                             'Add Medication',
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Card(
//                   child: Container(
//                     decoration: BoxDecoration(
//                       gradient: const LinearGradient(
//                         colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
//                       ),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         children: [
//                           Container(
//                             width: 40,
//                             height: 40,
//                             decoration: const BoxDecoration(
//                               color: Color(0xFF3B82F6),
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(
//                               Icons.notifications,
//                               color: Colors.white,
//                               size: 20,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           const Text(
//                             'Set Reminder',
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
