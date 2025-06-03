

import 'package:flutter/material.dart';

class ResultadosFinaisView extends StatelessWidget {
  const ResultadosFinaisView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados Finais'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ranking Final',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 10, // Placeholder para número de equipas
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text('${index + 1}'),
                      ),
                      title: Text('Equipa ${index + 1}'),
                      subtitle: Text('Pontuação Total: ${120 - index * 8}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}