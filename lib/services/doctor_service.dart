import 'supabase_service.dart';
import '../models/app_models.dart';

/// Doctor service for listing and profile operations
class DoctorService {
  final _client = SupabaseService.client;
  static const String _tableName = 'doctors';

  /// Get all verified doctors
  // Temporary: Force mock data for testing
  Future<List<Doctor>> getDoctors() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network
    return _getMockDoctors();
  }

  List<Doctor> _getMockDoctors() {
    return [
      Doctor(
        id: 1,
        name: 'Dr. Sarah Smith',
        specialty: 'Veterinary Surgeon',
        rating: 4.9,
        reviews: 124,
        nextAvailable: 'Today',
        clinic: 'Paws & Claws Clinic',
        image: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=2670&auto=format&fit=crop',
        available: true,
      ),
      Doctor(
        id: 2,
        name: 'Dr. Michael Chen',
        specialty: 'Pet Dentist',
        rating: 4.8,
        reviews: 98,
        nextAvailable: 'Tomorrow',
        clinic: 'Smile Vet Care',
        image: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?q=80&w=2670&auto=format&fit=crop',
        available: true,
      ),
      Doctor(
        id: 3,
        name: 'Dr. Jessica Taylor',
        specialty: 'General Practitioner',
        rating: 4.7,
        reviews: 86,
        nextAvailable: 'Wed, 24th',
        clinic: 'Happy Paws Hospital',
        image: 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=2574&auto=format&fit=crop',
        available: false,
      ),
      Doctor(
        id: 4,
        name: 'Dr. David Wilson',
        specialty: 'Pet Dermatologist',
        rating: 4.9,
        reviews: 156,
        nextAvailable: 'Today',
        clinic: 'Skin & Coat Clinic',
        image: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=2670&auto=format&fit=crop',
        available: true,
      ),
      Doctor(
        id: 5,
        name: 'Dr. Emily Brown',
        specialty: 'Nutritionist',
        rating: 4.6,
        reviews: 45,
        nextAvailable: 'Fri, 26th',
        clinic: 'Healthy Pet Center',
        image: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=2664&auto=format&fit=crop',
        available: true,
      ),
      Doctor(
        id: 6,
        name: 'Dr. James Wilson',
        specialty: 'Orthopedic Surgeon',
        rating: 4.9,
        reviews: 210,
        nextAvailable: 'Mon, 29th',
        clinic: 'OrthoVet Specialists',
        image: 'https://images.unsplash.com/photo-1612349316986-e413f6a5b16d?q=80&w=2670&auto=format&fit=crop',
        available: false,
      ),
      Doctor(
        id: 7,
        name: 'Dr. Olivia Martinez',
        specialty: 'Feline Specialist',
        rating: 4.8,
        reviews: 132,
        nextAvailable: 'Today',
        clinic: 'The Cat Clinic',
        image: 'https://images.unsplash.com/photo-1527613426441-4da17471b66d?q=80&w=2670&auto=format&fit=crop',
        available: true,
      ),
      Doctor(
        id: 8,
        name: 'Dr. Robert Anderson',
        specialty: 'Exotic Pet Vet',
        rating: 4.7,
        reviews: 78,
        nextAvailable: 'Tomorrow',
        clinic: 'Wild Side Vet',
        image: 'https://images.unsplash.com/photo-1582750433449-648ed127bb54?q=80&w=2574&auto=format&fit=crop',
        available: true,
      ),
    ];
  }
}
