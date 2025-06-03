import 'package:flutter/material.dart';

class TeamProfileView extends StatelessWidget {
  const TeamProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil da Equipa'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações da Equipa',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Nome da Equipa'),
              subtitle: const Text('Os Velozes'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Condutor'),
              subtitle: const Text('João Silva'),
            ),
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text('Viatura'),
              subtitle: const Text('Toyota Hilux - CV12345'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Passageiros',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Maria Andrade'),
            ),
            const ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Carlos Monteiro'),
            ),
            const ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Ana Sousa'),
            ),
          ],
        ),
      ),
    );
  }
}
