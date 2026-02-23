import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'notification_service.dart';
import 'user_service.dart';
import '../models/app_models.dart';
import '../utils/pricing.dart';

/// Appointment service for booking and management
class AppointmentService {
  final _client = SupabaseService.client;
  final _notificationService = NotificationService();
  final _userService = UserService();
  static const String _tableName = 'appointments';
  static const String _slotsTable = 'availability_slots';

  /// Book a new appointment
  ///
  /// For manual Easypaisa payments, the client will first send money to
  /// the platform account (name: Taimoor, number: 03448962643). After the
  /// transfer the user calls [confirmPaymentByUser] which sets
  /// `payment_confirmed_by_user=true` and keeps the appointment in
  /// `pending` status until the admin approves it.
  Future<void> bookAppointment({
    required String doctorId,
    required String petId,
    required DateTime date,
    required String time,
    required String type,
    String? paymentRefId,
    int? price,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Robustly resolve doctor_id (handle if user passed UserID instead of DoctorID)
    String finalDoctorId = doctorId;
    final resolvedId = await _getDoctorIdFromUserId(doctorId);
    if (resolvedId != null) {
      finalDoctorId = resolvedId;
    }

    final appliedPrice = fixedAppointmentFeePkr;

    // Insert and return the appointment ID
    final response = await _client.from(_tableName).insert({
      'user_id': userId,
      'doctor_id': finalDoctorId,
      'pet_id': petId,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      'type': type,
      'status': 'pending',
      'price': appliedPrice,
      if (paymentRefId != null) 'payment_ref_id': paymentRefId,
      if (paymentRefId != null) 'payment_status': 'paid_to_platform',
    }).select('id').single();
    
    final appointmentId = response['id']?.toString();

    // Send notification to doctor about new appointment request
    await _sendAppointmentNotification(
      appointmentData: {
        'id': appointmentId,
        'doctor_id': finalDoctorId,
        'user_id': userId,
        'date': date.toIso8601String().split('T')[0],
        'time': time,
      },
      status: 'new_request',
    );
    
    // Schedule 1-hour reminder (will fail gracefully if past)
    if (appointmentId != null) {
      try {
        // Get doctor and pet names for reminder
        final doctorData = await _client
            .from('doctors')
            .select('users(name)')
            .eq('id', finalDoctorId)
            .maybeSingle();
        final petData = await _client
            .from('pets')
            .select('name')
            .eq('id', petId)
            .maybeSingle();
        
        final doctorName = doctorData?['users']?['name'] ?? 'Doctor';
        final petName = petData?['name'] ?? 'Pet';
        
        // Parse appointment date/time
        final appointmentDateTime = _parseAppointmentDateTime(date, time);
        
        await _notificationService.scheduleAppointmentReminder(
          appointmentId: appointmentId,
          appointmentDateTime: appointmentDateTime,
          doctorName: doctorName,
          petName: petName,
        );
      } catch (e) {
        debugPrint('⚠️ Failed to schedule reminder: $e');
      }
    }
  }
  
  /// Parse appointment date and time into DateTime
  DateTime _parseAppointmentDateTime(DateTime date, String time) {
    final timeParts = time.split(':');
    var hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1].split(' ')[0]);
    
    // Handle AM/PM if present
    if (time.toUpperCase().contains('PM') && hour < 12) {
      hour += 12;
    } else if (time.toUpperCase().contains('AM') && hour == 12) {
      hour = 0;
    }
    
    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  /// Get appointments for current user (pet owner)
  Future<List<Appointment>> getUserAppointments() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    try {
      // 1. Fetch raw appointments and pet info
      final response = await _client
          .from(_tableName)
          .select('*, pets(*)')
          .eq('user_id', userId)
          .order('date', ascending: true);

      final appointments = <Appointment>[];
      
      for (var data in (response as List)) {
        // 2. Resolve Doctor Info (User ID might be stored or Doctor ID)
        final doctorId = data['doctor_id']?.toString();
        Map<String, dynamic>? doctorInfo;
        
        if (doctorId != null) {
          // Try fetching directly from users first (New Flow)
          try {
            doctorInfo = await _client
                .from('users')
                .select()
                .eq('id', doctorId)
                .maybeSingle();
          } catch (_) {}
          
          // If not found in users (or wrong UUID type), try resolving via doctors table (Legacy Flow)
          if (doctorInfo == null) {
            final resolvedId = await _getDoctorIdFromUserId(doctorId);
            if (resolvedId != null && resolvedId != doctorId) {
               doctorInfo = await _client
                  .from('users')
                  .select()
                  .eq('id', resolvedId)
                  .maybeSingle();
            }
          }
        }

        final petData = data['pets'] ?? {};
        
        appointments.add(Appointment(
          id: data['id']?.toString() ?? '',
          uuid: data['id']?.toString(),
          doctorId: doctorId,
          doctor: doctorInfo?['name'] ?? 'Doctor',
          doctorImage: doctorInfo?['profile_image'],
          clinic: doctorInfo?['clinic'] ?? 'Pets & Vets Clinic',
          date: data['date'] ?? '',
          time: data['time'] ?? '',
          pet: petData['name'] ?? 'Pet',
          type: data['type'] ?? '',
          status: data['status'] ?? 'pending',
           price: fixedAppointmentFeePkr,
          petId: petData['id']?.toString(),
          petImage: petData['image_url'],
          ownerId: userId,
          paymentMethod: data['payment_method']?.toString(),
          paymentConfirmedByUser: data['payment_confirmed_by_user'] as bool?,
          paymentConfirmedByAdmin: data['payment_confirmed_by_admin'] as bool?,
          paymentStatus: data['payment_status']?.toString(),
        ));
      }

      return appointments;
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      return [];
    }
  }

  /// Get appointments for current logged-in doctor
  Future<List<Appointment>> getMyDoctorAppointments() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    try {
      // 1. Get doctor_id from users table (or doctors table via user_id)
      final doctorId = await _getDoctorIdFromUserId(userId);
      if (doctorId == null) return [];

      // 2. Fetch appointments for this doctor
      return await getDoctorAppointments(doctorId);
    } catch (e) {
      debugPrint('Error fetching my doctor appointments: $e');
      return [];
    }
  }

  /// Get appointment count for user
  Future<int> getAppointmentCount(String userId) async {
    final response = await _client
        .from(_tableName)
        .select('id')
        .eq('user_id', userId)
        .count(CountOption.exact);
        
    return response.count;
  }

  /// Get appointments for doctor
  Future<List<Appointment>> getDoctorAppointments(String doctorId) async {
    try {
      debugPrint('Fetching appointments for doctor_id: $doctorId');
      
      // Simple query without complex joins to avoid foreign key issues
      final response = await _client
          .from(_tableName)
          .select()
          .eq('doctor_id', doctorId) // Querying by Doctor Table ID
          .order('date', ascending: true);

      debugPrint('✅ Query successful. Found ${response.length} raw appointments.');
      if (response.isNotEmpty) {
        for (var i = 0; i < response.length; i++) {
          final r = response[i];
          debugPrint('📄 Appt #$i: ID=${r['id']}, Date=${r['date']}, Time=${r['time']}, Status=${r['status']}, UserID=${r['user_id']}');
        }
      }

      debugPrint('Raw response: ${response.length} items');
      
      if (response.isEmpty) {
        return [];
      }

      // Now get pet and user data for each appointment
      List<Appointment> appointments = [];
      for (var data in response) {
        // Fetch pet info
        Map<String, dynamic> petData = {};
        if (data['pet_id'] != null) {
          try {
            final petResponse = await _client
                .from('pets')
                .select()
                .eq('id', data['pet_id'])
                .maybeSingle();
            petData = petResponse ?? {};
          } catch (e) {
            debugPrint('Error fetching pet: $e');
          }
        }

        // Fetch patient (user) info
        Map<String, dynamic> patientData = {};
        if (data['user_id'] != null) {
          try {
            final userResponse = await _client
                .from('users')
                .select()
                .eq('id', data['user_id'])
                .maybeSingle();
            patientData = userResponse ?? {};
          } catch (e) {
            debugPrint('Error fetching user: $e');
          }
        }

        appointments.add(Appointment(
          id: data['id']?.toString() ?? '',
          uuid: data['id']?.toString(), // Store actual UUID for updates
          doctorId: data['doctor_id']?.toString(), // CRITICAL FIX: Store doctor ID for local query filtering
          doctor: patientData['name'] ?? 'Unknown Patient',
          doctorImage: patientData['profile_image'], // Map patient image to avatar slot
          clinic: 'Pet Owner', // Show role instead of fake clinic
          date: data['date'] ?? '',
          time: data['time'] ?? '',
          pet: petData['name'] ?? 'Pet',
          type: data['type'] ?? '',
          status: data['status'] ?? 'pending',
          petId: petData['id']?.toString(),
          petImage: petData['image_url'],
          ownerId: patientData['id']?.toString(),
          ownerImage: patientData['profile_image'],
          paymentMethod: data['payment_method']?.toString(),
          paymentStatus: data['payment_status']?.toString(),
          paymentConfirmedByUser: data['payment_confirmed_by_user'] as bool?,
          paymentConfirmedByAdmin: data['payment_confirmed_by_admin'] as bool?,
        ));
      }

      debugPrint('Found ${appointments.length} appointments for doctor');
      return appointments;
    } catch (e) {
      debugPrint('Error fetching doctor appointments: $e');
      return [];
    }
  }

  /// Parse appointments for doctor view
  List<Appointment> _parseDoctorAppointments(List<dynamic> response) {
    return response.map((data) {
      // 'patient' alias from the query for user data (pet owner)
      final patientData = data['patient'] ?? {};
      final petData = data['pets'] ?? {};

      return Appointment(
        id: data['id']?.toString() ?? '',
        doctor: patientData['name'] ?? 'Unknown Patient',
        doctorImage: patientData['profile_image'], // Map for avatar
        clinic: 'Pet Owner',
        date: data['date'] ?? '',
        time: data['time'] ?? '',
        pet: petData['name'] ?? 'Pet',
        type: data['type'] ?? '',
        status: data['status'] ?? 'pending',
        petId: petData['id']?.toString(),
        petImage: petData['image_url'],
        ownerId: patientData['id']?.toString(),
        ownerImage: patientData['profile_image'],
        paymentMethod: data['payment_method']?.toString(),
        paymentStatus: data['payment_status']?.toString(),
        paymentConfirmedByUser: data['payment_confirmed_by_user'] as bool?,
        paymentConfirmedByAdmin: data['payment_confirmed_by_admin'] as bool?,
      );
    }).toList();
  }

  /// Update appointment status with notification
  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String status,
    String? rejectionReason,
  }) async {
    // 1. Fetch appointment details first
    final appointmentData = await _client
        .from(_tableName)
        .select()
        .eq('id', appointmentId)
        .maybeSingle();
    
    if (appointmentData == null) {
      throw Exception('Appointment not found');
    }

    final updateData = <String, dynamic>{'status': status};

    // 2. Handle Payment & Wallet Logic for Easypaisa
    if (status == 'accepted' && appointmentData['payment_status'] == 'paid_to_platform') {
        final price = fixedAppointmentFeePkr.toDouble();
      if (price > 0) {
        // Calculate 15% platform fee, 85% vet earnings
        final platformFee = price * platformCommissionRate;
        final vetEarnings = price - platformFee;

        updateData['platform_fee'] = platformFee;
        updateData['vet_earnings'] = vetEarnings;

        // Update Doctor's Wallet Balance
        final doctorId = appointmentData['doctor_id'];
        final ownerId = appointmentData['user_id'];
        if (doctorId != null) {
          final doctorData = await _client.from('users').select('wallet_balance').eq('id', doctorId).maybeSingle();
          final currentBalance = (doctorData?['wallet_balance'] as num?)?.toDouble() ?? 0.0;
          
          await _client.from('users').update({
            'wallet_balance': currentBalance + vetEarnings
          }).eq('id', doctorId);

          // Log vet earning transaction
          await _client.from('wallet_transactions').insert({
            'doctor_id': doctorId,
            'appointment_id': appointmentId,
            'type': 'credit',
            'amount': vetEarnings,
            'description': 'Vet earnings for appointment $appointmentId (85% after 15% commission)',
          });
        }

        // Log owner payment transaction
        if (ownerId != null) {
          await _client.from('wallet_transactions').insert({
            'user_id': ownerId,
            'appointment_id': appointmentId,
            'type': 'debit',
            'amount': price,
            'description': 'Paid PKR $price via Easypaisa (15% commission)',
          });
        }
      }
    } else if (status == 'rejected' && appointmentData['payment_status'] == 'paid_to_platform') {
      // Mark for refund
      updateData['payment_status'] = 'refunded';
      // TODO: Trigger actual Easypaisa Refund API via Edge Function here
    }

    // 3. Update the status and payment info
    await _client
        .from(_tableName)
        .update(updateData)
        .eq('id', appointmentId);

    // 4. Send notification to appropriate user
    await _sendAppointmentNotification(
      appointmentData: appointmentData,
      status: status,
      rejectionReason: rejectionReason,
    );
  }

  /// Called by pet owner after sending money via Easypaisa to Taimoor
  /// number 03448962643. Leaves appointment in pending state for admin.
  Future<void> confirmPaymentByUser(String appointmentId, {String? screenshotUrl}) async {
    bool isPaymentStatusConstraintError(PostgrestException error) {
      final msg = error.message.toLowerCase();
      return msg.contains('payment_status_check') ||
          (msg.contains('violates check constraint') && msg.contains('payment_status'));
    }

    // mark confirmation flag and attach screenshot if provided
    final baseUpdateData = {
      'payment_confirmed_by_user': true,
      'payment_status': 'pending_admin',
    };

    final updateWithScreenshot = {
      ...baseUpdateData,
      if (screenshotUrl != null) 'payment_screenshot_url': screenshotUrl,
    };

    try {
      await _client.from(_tableName).update(updateWithScreenshot).eq('id', appointmentId);
    } on PostgrestException catch (e) {
      final missingScreenshotColumn =
          screenshotUrl != null &&
          (e.message.contains('payment_screenshot_url') ||
              e.message.contains('schema cache'));

      final rlsViolation = e.message.toLowerCase().contains('row-level security');

      if (missingScreenshotColumn) {
        debugPrint(
          'appointments.payment_screenshot_url not found in schema cache; retrying payment confirmation without screenshot URL',
        );
        try {
          await _client.from(_tableName).update(baseUpdateData).eq('id', appointmentId);
        } on PostgrestException catch (statusError) {
          if (!isPaymentStatusConstraintError(statusError)) rethrow;

          // Backward compatibility for older DB constraint values.
          await _client.from(_tableName).update({
            'payment_confirmed_by_user': true,
            'payment_status': 'paid_to_platform',
          }).eq('id', appointmentId);
        }
      } else if (isPaymentStatusConstraintError(e)) {
        // Backward compatibility for older DB constraint values.
        await _client.from(_tableName).update({
          'payment_confirmed_by_user': true,
          'payment_status': 'paid_to_platform',
          if (screenshotUrl != null) 'payment_screenshot_url': screenshotUrl,
        }).eq('id', appointmentId);
      } else if (rlsViolation) {
        // Some setups allow updating only a subset of columns.
        // Retry with a minimal update to maximize compatibility.
        await _client.from(_tableName).update({
          'payment_confirmed_by_user': true,
        }).eq('id', appointmentId);
      } else {
        rethrow;
      }
    }

    // log a provisional transaction for the owner
    try {
      Map<String, dynamic>? appt;
      dynamic ownerId;

      try {
        appt = await _client
            .from(_tableName)
            .select('price, user_id')
            .eq('id', appointmentId)
            .maybeSingle();
        ownerId = appt?['user_id'];
      } on PostgrestException catch (e) {
        final missingUserIdColumn =
            e.message.contains("'user_id' column") &&
            e.message.contains('schema cache');
        if (!missingUserIdColumn) rethrow;

        // Backward compatibility for schemas that use owner_id instead of user_id.
        appt = await _client
            .from(_tableName)
            .select('price, owner_id')
            .eq('id', appointmentId)
            .maybeSingle();
        ownerId = appt?['owner_id'];
      }

      final price = fixedAppointmentFeePkr.toDouble();
      if (price > 0) {
        final txData = {
          if (ownerId != null) 'user_id': ownerId,
          'appointment_id': appointmentId,
          'type': 'debit',
          'amount': price,
          'description': 'Payment marked sent (awaiting admin verification)',
        };

        try {
          await _client.from('wallet_transactions').insert(txData);
        } on PostgrestException catch (insertError) {
          final missingWalletUserId =
              insertError.message.contains("'user_id' column") &&
              insertError.message.contains('wallet_transactions') &&
              insertError.message.contains('schema cache');

          if (missingWalletUserId) {
            final txDataWithoutUser = {
              'appointment_id': appointmentId,
              'type': 'debit',
              'amount': price,
              'description': 'Payment marked sent (awaiting admin verification)',
            };
            await _client.from('wallet_transactions').insert(txDataWithoutUser);
          } else {
            rethrow;
          }
        }
      }
    } on PostgrestException catch (e) {
      final msg = e.message.toLowerCase();
      final expectedSchemaMismatch =
          msg.contains('schema cache') &&
          (msg.contains("'user_id' column") || msg.contains("'owner_id' column"));
      if (!msg.contains('row-level security') && !expectedSchemaMismatch) {
        debugPrint('Error logging user payment confirmation: $e');
      }
    } catch (e) {
      debugPrint('Error logging user payment confirmation: $e');
    }
  }

  /// Admin uses this to mark a manual Easypaisa payment as received.
  Future<void> confirmPaymentByAdmin(String appointmentId) async {
    // Fetch price to compute wallet split when admin approves
    final appointmentData = await _client.from(_tableName).select().eq('id', appointmentId).maybeSingle();
    if (appointmentData == null) throw Exception('Appointment not found');
    final price = (appointmentData['price'] as num?)?.toDouble() ?? 0.0;

    // Mark admin confirmation and payment status first so updateAppointmentStatus can apply wallet logic
    await _client.from(_tableName).update({
      'payment_confirmed_by_admin': true,
      'payment_status': 'paid_to_platform',
    }).eq('id', appointmentId);

    // Update appointment and run the same logic as acceptance (wallet updates/transactions happen here)
    await updateAppointmentStatus(
      appointmentId: appointmentId,
      status: 'accepted',
    );
  }


  /// Send appointment notification based on status change
  Future<void> _sendAppointmentNotification({
    required Map<String, dynamic> appointmentData,
    required String status,
    String? rejectionReason,
  }) async {
    try {
      final petOwnerId = appointmentData['user_id'] as String?;
      final doctorTableId = appointmentData['doctor_id'] as String?;
      final dateStr = appointmentData['date'] ?? '';
      final timeStr = appointmentData['time'] ?? '';
      
      if (petOwnerId == null) return;

      // Get current user (the one making the action)
      final currentUserId = SupabaseService.currentUser?.id;
      final currentUserData = await _userService.getCurrentUser();
      final currentUserName = currentUserData?['name'] ?? 'User';

      // Determine recipient and notification content based on status
      String? recipientId;
      String title = '';
      String body = '';
      String notificationType = '';

      switch (status) {
        case 'accepted':
          // Doctor accepted -> notify pet owner
          recipientId = petOwnerId;
          title = 'Appointment Accepted! ✅';
          body = 'Dr. $currentUserName has accepted your appointment for $dateStr at $timeStr';
          notificationType = NotificationService.typeAppointmentAccepted;
          break;
          
        case 'rejected':
          // Doctor rejected -> notify pet owner
          recipientId = petOwnerId;
          title = 'Appointment Declined ❌';
          final reason = rejectionReason ?? 'Schedule conflict';
          body = 'Dr. $currentUserName has declined your appointment. Reason: $reason';
          notificationType = NotificationService.typeAppointmentRejected;
          break;
          
        case 'rescheduled_pending':
          // Doctor rescheduled -> notify pet owner
          recipientId = petOwnerId;
          title = 'Appointment Rescheduled 📅';
          body = 'Dr. $currentUserName has rescheduled your appointment to $dateStr at $timeStr';
          notificationType = NotificationService.typeAppointmentRescheduled;
          break;
          
        case 'cancelled':
          // Pet owner cancelled -> notify doctor
          if (currentUserId == petOwnerId && doctorTableId != null) {
            // Get doctor's user_id from doctors table
            final doctorData = await _client
                .from('doctors')
                .select('user_id')
                .eq('id', doctorTableId)
                .maybeSingle();
            recipientId = doctorData?['user_id'];
            title = 'Appointment Cancelled';
            body = '$currentUserName has cancelled the appointment for $dateStr at $timeStr';
            notificationType = 'appointment_cancelled';
          }
          break;
          
        case 'new_request':
          // Pet owner booked -> notify doctor
          if (doctorTableId != null) {
            final doctorData = await _client
                .from('doctors')
                .select('user_id')
                .eq('id', doctorTableId)
                .maybeSingle();
            recipientId = doctorData?['user_id'];
            title = 'New Appointment Request 🗓️';
            body = '$currentUserName has requested an appointment for $dateStr at $timeStr';
            notificationType = 'appointment_request';
          }
          break;
          
        default:
          return; // Don't send notification for other statuses
      }

      if (recipientId != null && recipientId != currentUserId && title.isNotEmpty) {
        await _notificationService.createNotification(
          userId: recipientId,
          title: title,
          body: body,
          type: notificationType,
          relatedId: appointmentData['id']?.toString(),
          actorId: currentUserId,
        );
        debugPrint('📬 Appointment notification sent: $status -> $recipientId');
      }
    } catch (e) {
      debugPrint('Error sending appointment notification: $e');
    }
  }

  /// Cancel appointment
  Future<void> cancelAppointment(String appointmentId) async {
    await updateAppointmentStatus(
      appointmentId: appointmentId,
      status: 'cancelled',
    );
    
    // Cancel the scheduled reminder
    await _notificationService.cancelAppointmentReminder(appointmentId);
  }

  /// Reschedule appointment (update date and time)
  /// newStatus: 'rescheduled_pending' (doctor) or 'accepted' (pet owner)
  Future<void> rescheduleAppointment({
    required String appointmentId,
    required String newDate,
    required String newTime,
    String newStatus = 'rescheduled_pending',  // Default for backward compatibility
  }) async {
    // 1. Fetch appointment details first
    final appointmentData = await _client
        .from(_tableName)
        .select('*, pets(*), doctors!appointments_doctor_id_fkey(*, users(*))')
        .eq('id', appointmentId)
        .maybeSingle();

    // 2. Update the appointment
    await _client
        .from(_tableName)
        .update({
          'date': newDate,
          'time': newTime,
          'status': newStatus,
        })
        .eq('id', appointmentId);

    // 3. Send notification with updated date/time
    if (appointmentData != null) {
      final updatedData = Map<String, dynamic>.from(appointmentData);
      updatedData['date'] = newDate;
      updatedData['time'] = newTime;
      
      await _sendAppointmentNotification(
        appointmentData: updatedData,
        status: newStatus,
      );
      
      // 4. Reschedule the reminder
      try {
        // Cancel old reminder
        await _notificationService.cancelAppointmentReminder(appointmentId);
        
        // Schedule new reminder with updated date/time
        final doctorData = appointmentData['doctors'] ?? {};
        final userData = doctorData['users'] ?? {};
        final petData = appointmentData['pets'] ?? {};
        
        final doctorName = userData['name'] ?? 'Doctor';
        final petName = petData['name'] ?? 'Pet';
        
        // Parse new appointment date/time
        final dateObj = DateTime.parse(newDate);
        final appointmentDateTime = _parseAppointmentDateTime(dateObj, newTime);
        
        await _notificationService.scheduleAppointmentReminder(
          appointmentId: appointmentId,
          appointmentDateTime: appointmentDateTime,
          doctorName: doctorName,
          petName: petName,
        );
      } catch (e) {
        debugPrint('⚠️ Failed to reschedule reminder: $e');
      }
    }
  }

  /// Helper: Get the doctor table ID from the user ID
  /// Since we are merging doctor info into the 'users' table, the User ID IS the Doctor ID.
  Future<String?> _getDoctorIdFromUserId(String userId) async {
    // Legacy support: We still check if a record in 'doctors' exists to avoid breaking existing data.
    // But for all new signups and future-proof design, User ID = Doctor ID.
    try {
      final response = await _client
          .from('doctors')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response != null) {
        return response['id']?.toString();
      }
    } catch (e) {
      debugPrint('ℹ️ Doctor table lookup failed, falling back to User ID: $e');
    }
    
    return userId;
  }

  /// Get available slots for a doctor (accepts user_id, resolves to doctor_id if needed)
  Future<List<Map<String, dynamic>>> getAvailabilitySlots(String doctorUserId) async {
    // First try with the given ID (might be doctor_id directly)
    var response = await _client
        .from(_slotsTable)
        .select()
        .eq('doctor_id', doctorUserId)
        .order('day');

    // If no results, try looking up the doctor_id from user_id
    if ((response as List).isEmpty) {
      final actualDoctorId = await _getDoctorIdFromUserId(doctorUserId);
      if (actualDoctorId != null) {
        response = await _client
            .from(_slotsTable)
            .select()
            .eq('doctor_id', actualDoctorId)
            .order('day');
      }
    }

    return List<Map<String, dynamic>>.from(response);
  }

  /// Add availability slot (for doctors)
  Future<void> addAvailabilitySlot({
    required String doctorId,
    required String day,
    required String startTime,
    required String endTime,
  }) async {
    await _client.from(_slotsTable).insert({
      'doctor_id': doctorId,
      'day': day,
      'start_time': startTime,
      'end_time': endTime,
    });
  }

  /// Remove availability slot
  Future<void> removeAvailabilitySlot(String slotId) async {
    await _client.from(_slotsTable).delete().eq('id', slotId);
  }

  /// Parse appointments from response
  List<Appointment> _parseAppointments(List<dynamic> response, {bool isDoctorView = false}) {
    return response.map((data) {
      // If doctor view, 'patient' alias contains user info. If user view, 'users' (doctor) contains info.
      final userData = isDoctorView ? (data['patient'] ?? {}) : (data['users'] ?? {});
      final petData = data['pets'] ?? {};

      return Appointment(
        id: data['id']?.toString() ?? '',
        uuid: data['id']?.toString(), // Store actual UUID for database operations
        doctorId: data['doctor_id']?.toString(), // Doctor's ID for fetching available slots
        doctorImage: userData['profile_image'], // Doctor's profile image
        // For doctor view, this field effectively becomes "Patient Name"
        doctor: userData['name'] ?? (isDoctorView ? 'Unknown Patient' : 'Doctor'),
        clinic: userData['clinic'] ?? (isDoctorView ? 'Virtual Clinic' : 'Pets & Vets Clinic'), 
        date: data['date'] ?? '',
        time: data['time'] ?? '',
        pet: petData['name'] ?? 'Pet',
        type: data['type'] ?? '',
        status: data['status'] ?? 'pending',
        petId: petData['id']?.toString(),
        petImage: petData['image_url'],
        ownerId: userData['id']?.toString(),
        ownerImage: userData['profile_image'],
      );
    }).toList();
  }

  /// Parse appointments with doctors table join (for pet owner view)
  List<Appointment> _parseAppointmentsWithDoctors(List<dynamic> response) {
    return response.map((data) {
      final doctorData = data['doctors'] ?? {};
      final userData = doctorData['users'] ?? {};
      final petData = data['pets'] ?? {};

      return Appointment(
        id: data['id']?.toString() ?? '',
        uuid: data['id']?.toString(), // Store actual UUID for database operations
        doctorId: data['doctor_id']?.toString(), // Doctor's ID for fetching available slots
        doctorImage: userData['profile_image'], // Doctor's profile image
        doctor: userData['name'] ?? doctorData['specialty'] ?? 'Doctor',
        clinic: userData['clinic'] ?? doctorData['clinic'] ?? 'Pets & Vets Clinic', 
        date: data['date'] ?? '',
        time: data['time'] ?? '',
        pet: petData['name'] ?? 'Pet',
        type: data['type'] ?? '',
        status: data['status'] ?? 'pending',
        petId: petData['id']?.toString(),
        petImage: petData['image_url'],
        ownerId: userData['id']?.toString(),
        ownerImage: userData['profile_image'],
      );
    }).toList();
  }

  // ============ REAL-TIME AVAILABILITY METHODS ============

  /// Get available time slots for a doctor on a specific date
  /// Generates 30-minute slots based on doctor's working hours
  /// and excludes already booked slots
  Future<List<Map<String, dynamic>>> getAvailableSlotsForDate(
    String doctorUserId,
    DateTime date,
  ) async {
    try {
      // Resolve the actual doctor_id from the doctors table
      String? actualDoctorId = doctorUserId;
      final doctorIdFromTable = await _getDoctorIdFromUserId(doctorUserId);
      if (doctorIdFromTable != null) {
        actualDoctorId = doctorIdFromTable;
      }

      // Get day of week (1=Monday, 7=Sunday)
      final dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final dayName = dayNames[date.weekday];
      
      // Get doctor's availability for this day
      final availability = await _client
          .from(_slotsTable)
          .select()
          .eq('doctor_id', actualDoctorId)
          .eq('day', dayName)
          .maybeSingle();

      if (availability == null) {
        // Doctor not available on this day
        return [];
      }

      final startTime = availability['start_time'] as String; // "09:00"
      final endTime = availability['end_time'] as String;     // "17:00"

      // Get existing appointments for this doctor on this date
      final dateStr = date.toIso8601String().split('T')[0];
      final existingAppointments = await _client
          .from(_tableName)
          .select('time')
          .eq('doctor_id', actualDoctorId)
          .eq('date', dateStr)
          .neq('status', 'cancelled');

      final bookedTimes = (existingAppointments as List)
          .map((a) => a['time'] as String)
          .toSet();

      // Generate 30-minute slots
      final slots = <Map<String, dynamic>>[];
      var currentTime = _parseTime(startTime);
      final end = _parseTime(endTime);

      while (_timeToMinutes(currentTime) < _timeToMinutes(end)) {
        final timeStr = _formatTime(currentTime);
        final isBooked = bookedTimes.contains(timeStr);
        
        // Determine label based on hour
        String label;
        if (currentTime.hour < 12) {
          label = 'Morning';
        } else if (currentTime.hour < 17) {
          label = 'Afternoon';
        } else {
          label = 'Evening';
        }

        slots.add({
          'time': timeStr,
          'displayTime': _formatDisplayTime(currentTime),
          'isAvailable': !isBooked,
          'label': label,
        });

        // Add 30 minutes
        currentTime = TimeOfDay(
          hour: currentTime.hour + (currentTime.minute + 30) ~/ 60,
          minute: (currentTime.minute + 30) % 60,
        );
      }

      return slots;
    } catch (e) {
      debugPrint('Error getting available slots: $e');
      return [];
    }
  }

  /// Check if a specific slot is still available (real-time check)
  Future<bool> isSlotAvailable(String doctorId, DateTime date, String time) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final existing = await _client
          .from(_tableName)
          .select('id')
          .eq('doctor_id', doctorId)
          .eq('date', dateStr)
          .eq('time', time)
          .neq('status', 'cancelled')
          .maybeSingle();
      
      return existing == null;
    } catch (e) {
      debugPrint('Error checking slot availability: $e');
      return false;
    }
  }

  /// Book appointment with real-time slot verification
  Future<String> bookWithSlotCheck({
    required String doctorUserId,
    required String petId,
    required DateTime date,
    required String time,
    required String type,
    int? priceInPKR,
  }) async {
    // Resolve the actual doctor_id from the doctors table
    String actualDoctorId = doctorUserId;
    final doctorIdFromTable = await _getDoctorIdFromUserId(doctorUserId);
    if (doctorIdFromTable != null) {
      actualDoctorId = doctorIdFromTable;
    }

    // First check if slot is still available
    final isAvailable = await isSlotAvailable(doctorUserId, date, time);
    if (!isAvailable) {
      throw Exception('This time slot is no longer available. Please select another slot.');
    }

    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Check for existing pending request for this doctor
    final hasPending = await checkPendingRequest(userId, actualDoctorId);
    if (hasPending) {
      throw Exception('You already have a pending request with this doctor. Please wait for them to respond.');
    }

    final appliedPrice = fixedAppointmentFeePkr;

    final response = await _client.from(_tableName).insert({
      'user_id': userId,
      'doctor_id': actualDoctorId,
      'pet_id': petId,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      'type': type,
      'status': 'pending',
      'price': appliedPrice,
    }).select('id').single();

    final appointmentId = response['id']?.toString();
    if (appointmentId == null || appointmentId.isEmpty) {
      throw Exception('Failed to create appointment');
    }
    return appointmentId;
  }

  /// Check if user already has a pending request with this doctor
  Future<bool> checkPendingRequest(String userId, String doctorId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('id')
          .eq('user_id', userId)
          .eq('doctor_id', doctorId)
          .eq('status', 'pending')
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      debugPrint('Error checking pending requests: $e');
      return false; // Fail safe, allow request if check errors (or handle differently)
    }
  }

  /// Get dates with availability for a doctor (next 30 days)
  Future<List<DateTime>> getAvailableDates(String doctorId) async {
    try {
      // Get doctor's weekly availability
      final availability = await getAvailabilitySlots(doctorId);
      if (availability.isEmpty) return [];

      final availableDays = availability.map((a) => a['day'] as String).toSet();
      final dayNameToWeekday = {
        'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4,
        'Friday': 5, 'Saturday': 6, 'Sunday': 7,
      };

      final availableWeekdays = availableDays
          .map((day) => dayNameToWeekday[day])
          .whereType<int>()
          .toSet();

      // Generate next 30 days that match availability
      final dates = <DateTime>[];
      final today = DateTime.now();
      
      for (var i = 1; i <= 30; i++) {
        final date = today.add(Duration(days: i));
        if (availableWeekdays.contains(date.weekday)) {
          dates.add(date);
        }
      }

      return dates;
    } catch (e) {
      debugPrint('Error getting available dates: $e');
      return [];
    }
  }

  // Helper methods
  TimeOfDay _parseTime(String time) {
    // Handle both "09:00" and "09:00 AM" formats
    time = time.trim();
    
    // Check for AM/PM format
    final isPM = time.toUpperCase().contains('PM');
    final isAM = time.toUpperCase().contains('AM');
    
    // Remove AM/PM suffix
    time = time.replaceAll(RegExp(r'[APap][Mm]', caseSensitive: false), '').trim();
    
    final parts = time.split(':');
    var hour = int.parse(parts[0].trim());
    final minute = int.parse(parts[1].trim().split(' ')[0]); // Handle extra spaces
    
    // Convert 12-hour to 24-hour format
    if (isPM && hour < 12) {
      hour += 12;
    } else if (isAM && hour == 12) {
      hour = 0;
    }
    
    return TimeOfDay(hour: hour, minute: minute);
  }

  int _timeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _formatDisplayTime(TimeOfDay time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
