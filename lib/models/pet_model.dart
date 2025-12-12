
class Pet {
  final String id;
  final String ownerId;
  final String name;
  final String type;
  final String breed;
  final String gender;
  final String age;
  final String weight; // New
  final String height; // New
  final String nextCheckup;
  final String health;
  final String emoji;
  final String imageUrl;

  Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    this.breed = '',
    required this.gender,
    required this.age,
    this.weight = '',
    this.height = '',
    required this.nextCheckup,
    required this.health,
    required this.emoji,
    required this.imageUrl,
  });

  // Factory constructor to create Pet from database (supports both camelCase and snake_case)
  factory Pet.fromMap(Map<String, dynamic> data) {
    return Pet(
      id: data['id']?.toString() ?? '',
      ownerId: data['owner_id']?.toString() ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      breed: data['breed'] ?? '',
      gender: data['gender'] ?? 'Unknown',
      age: data['age'] ?? '',
      weight: data['weight'] ?? '',
      height: data['height'] ?? '',
      nextCheckup: data['next_checkup'] ?? data['nextCheckup'] ?? '',
      health: data['health'] ?? '',
      emoji: data['emoji'] ?? '🐾',
      imageUrl: data['image_url'] ?? data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'type': type,
      'breed': breed,
      'gender': gender,
      'age': age,
      'weight': weight,
      'height': height,
      'nextCheckup': nextCheckup,
      'health': health,
      'emoji': emoji,
      'imageUrl': imageUrl,
    };
  }
}
