class Review {
  final String id;
  final String doctorId;
  final String userId;
  final String appointmentId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.doctorId,
    required this.userId,
    required this.appointmentId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      doctorId: json['doctor_id'] ?? '',
      userId: json['user_id'] ?? '',
      appointmentId: json['appointment_id'] ?? '',
      rating: json['rating'] is int ? json['rating'] : int.tryParse(json['rating'].toString()) ?? 0,
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctor_id': doctorId,
      'user_id': userId,
      'appointment_id': appointmentId,
      'rating': rating,
      'comment': comment,
    };
  }
}
