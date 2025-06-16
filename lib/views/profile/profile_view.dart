import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../widgets/shared/nav_bottom.dart';
import '../../widgets/shared/nav_topbar.dart';

class InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const InfoTile(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text('$label: $value');
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  Future<Map<String, dynamic>> _getUserAndCarData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? {};

    final carId = userData['veiculoId'];
    if (carId == null) {
      throw Exception('Veículo não encontrado para o usuário.');
    }

    final carDoc =
        await FirebaseFirestore.instance.collection('cars').doc(carId).get();
    final carData = carDoc.data() ?? {};

    return {'user': userData, 'car': carData};
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
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: NavTopBar(
              userName: userData['nome'] ?? '',
              location: 'Perfil',
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perfil do Condutor',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Informações Pessoais',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InfoTile('👤 Nome', userData['nome'] ?? ''),
                InfoTile('📧 Email', userData['email'] ?? ''),
                InfoTile('📞 Telefone', userData['telefone'] ?? ''),
                InfoTile('🆘 Contato Emergência', userData['emergencia'] ?? ''),
                InfoTile('👕 T-shirt', userData['tshirt'] ?? ''),
                const Divider(height: 32),
                const Text(
                  'Informações do Veículo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InfoTile('🚗 Modelo', carData['modelo'] ?? ''),
                InfoTile('📋 Matrícula', carData['matricula'] ?? ''),
                InfoTile('🔰 Dístico', carData['distico'] ?? ''),
                const Divider(height: 32),
                const Text(
                  'QR Code do Condutor:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Center(
                  child: QrImageView(
                    data:
                      'UID: ${FirebaseAuth.instance.currentUser?.uid ?? ''}\n'
                      'Nome: ${userData['nome'] ?? ''}\n'
                      'Matrícula: ${carData['matricula'] ?? ''}\n'
                      'Email: ${userData['email'] ?? ''}\n'
                      'Telefone: ${userData['telefone'] ?? ''}',
                    version: QrVersions.auto,
                    size: MediaQuery.of(context).size.width * 0.6,
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
                ...passageiros.map((p) {
                  final nome = p['nome'] ?? 'Sem nome';
                  final telefone = p['telefone'] ?? 'Sem telefone';
                  final tshirt = p['tshirt'] ?? '-';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('- $nome ($telefone, T-shirt: $tshirt)'),
                  );
                }),
              ],
            ),
          ),
          bottomNavigationBar: const BottomNavBar(currentIndex: 4),
        );
      },
    );
  }
}
