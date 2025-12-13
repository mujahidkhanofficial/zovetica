class Doctor {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final int reviews;
  // final String distance;
  final String nextAvailable;
  final String clinic;
  final String image;
  final bool available;
  final String? userId;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviews,
    // required this.distance,
    required this.nextAvailable,
    required this.clinic,
    required this.image,
    required this.available,
    this.userId,
  });
}
