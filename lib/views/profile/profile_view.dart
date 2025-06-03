import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../widgets/shared/nav_bottom.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  Future<Map<String, dynamic>> _getUserAndCarData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final carDoc =
        await FirebaseFirestore.instance.collection('cars').doc(uid).get();
    return {'user': userDoc.data() ?? {}, 'car': carDoc.data() ?? {}};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserAndCarData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Dados não encontrados.')),
          );
        }

        final userData = snapshot.data!['user'] as Map<String, dynamic>;
        final carData = snapshot.data!['car'] as Map<String, dynamic>;
        final passageiros = carData['passageiros'] as List<dynamic>? ?? [];

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF0E0E2C),
            title: const Text('Perfil do Condutor'),
            centerTitle: true,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // Redirecionar para tela de edição (criar futuramente)
                  Navigator.of(context).pushNamed('/edit-profile');
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informações Pessoais',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('👤 Nome: ${userData['nome'] ?? ''}'),
                Text('📧 Email: ${userData['email'] ?? ''}'),
                Text('📞 Telefone: ${userData['telefone'] ?? ''}'),
                Text('🆘 Contato Emergência: ${userData['emergencia'] ?? ''}'),
                Text('👕 T-shirt: ${userData['tshirt'] ?? ''}'),
                const Divider(height: 32),
                Text(
                  'Carro: ${carData['modelo'] ?? ''} (${carData['matricula'] ?? ''})',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Divider(height: 32),
                const Text(
                  'QR Code do Condutor:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Center(
                  child: QrImageView(
                    data:
                        'Nome: ${userData['nome'] ?? ''}\nMatrícula: ${carData['matricula'] ?? ''}\nEmail: ${userData['email'] ?? ''}\nTelefone: ${userData['telefone'] ?? ''}',
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const Divider(height: 32),
                const Text(
                  'Passageiros:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (passageiros.isEmpty)
                  const Text('Nenhum passageiro registrado.'),
                ...passageiros.map(
                  (p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '- ${p['nome']} (${p['telefone']}, T-shirt: ${p['tshirt']})',
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavBar(currentIndex: 3),
        );
      },
    );
  }
}
