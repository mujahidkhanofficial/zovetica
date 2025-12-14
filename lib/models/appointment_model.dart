class Appointment {
  final String id;
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
  final int price;

  final String? petId;
  final String? petImage;
  final String? ownerId;
  final String? ownerImage;

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
    this.price = 0,
    this.petId,
    this.petImage,
    this.ownerId,
    this.ownerImage,
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    // Extract nested data
    final userData = map['users'] as Map<String, dynamic>?;
    final doctorData = map['doctors'] as Map<String, dynamic>?;
    final petData = map['pets'] as Map<String, dynamic>?;
    
    return Appointment(
      id: map['id']?.toString() ?? '',
      uuid: map['id']?.toString(),
      doctorId: map['doctor_id']?.toString(),
      doctorImage: doctorData?['users']?['profile_image'] ?? userData?['profile_image'],
      doctor: doctorData?['users']?['name'] ?? userData?['name'] ?? 'Doctor',
      clinic: doctorData?['clinic'] ?? map['clinic'] ?? 'Clinic',
      date: map['date']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      pet: petData?['name'] ?? map['pet_name'] ?? 'Pet',
      type: map['type']?.toString() ?? 'Checkup',
      status: map['status']?.toString() ?? 'pending',
      price: map['price'] ?? 0,
      petId: map['pet_id']?.toString(),
      petImage: petData?['image_url'],
      ownerId: map['user_id']?.toString(),
      ownerImage: userData?['profile_image'],
    );
  }

  /// Parse date string to DateTime
  DateTime get dateTime {
    try {
      return DateTime.parse(date);
    } catch (e) {
      return DateTime.now();
    }
  }
}

