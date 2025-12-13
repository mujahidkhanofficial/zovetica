import 'package:flutter/material.dart';
import '../models/app_models.dart';

class ViewPetsScreen extends StatelessWidget {
  final List<Pet> pets;

  const ViewPetsScreen({super.key, required this.pets});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Pets"),
        backgroundColor: Color(0xFF10B981),
      ),
      body: ListView.builder(
        itemCount: pets.length,
        itemBuilder: (context, index) {
          final pet = pets[index];
          return ListTile(
            leading: pet.imageUrl != ""
                ? CircleAvatar(backgroundImage: NetworkImage(pet.imageUrl))
                : CircleAvatar(child: Text(pet.emoji)),
            title: Text(pet.name),
            subtitle: Text("${pet.type} • ${pet.age}"),
          );
        },
      ),
    );
  }
}
