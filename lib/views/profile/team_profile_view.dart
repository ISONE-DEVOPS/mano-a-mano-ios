import 'package:flutter/material.dart';

class TeamProfileView extends StatelessWidget {
  const TeamProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil da Equipa'), centerTitle: true),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações da Equipa',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.group),
              title: Text('Nome da Equipa'),
              subtitle: Text('Os Velozes'),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Condutor'),
              subtitle: Text('João Silva'),
            ),
            ListTile(
              leading: Icon(Icons.directions_car),
              title: Text('Viatura'),
              subtitle: Text('Toyota Hilux - CV12345'),
            ),
            SizedBox(height: 24),
            Text(
              'Passageiros',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Maria Andrade'),
            ),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Carlos Monteiro'),
            ),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Ana Sousa'),
            ),
          ],
        ),
      ),
    );
  }
}
