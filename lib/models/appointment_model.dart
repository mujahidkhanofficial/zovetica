class Appointment {
  final int id;
  final String? uuid; // Actual database UUID for updates
  final String? doctorId; // Doctor's user_id for fetching available slots
  final String? doctorImage; // Doctor's profile image URL
  final String doctor;
  final String clinic;
  final String date;
  final String time;
  final String pet;
  final String type;
  final String status;

  Appointment({
    required this.id,
    this.uuid,
    this.doctorId,
    this.doctorImage,
    required this.doctor,
    required this.clinic,
    required this.date,
    required this.time,
    required this.pet,
    required this.type,
    required this.status,
    this.petId,
    this.petImage,
    this.ownerId,
    this.ownerImage,
  });

  final String? petId;
  final String? petImage;
  final String? ownerId;
  final String? ownerImage;
}

