import 'package:flutter/material.dart';

class PermissionScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const PermissionScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissões Necessárias'),
        backgroundColor: const Color(0xFF0E0E2C),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Para garantir o funcionamento completo da aplicação, precisamos das seguintes permissões:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.black87),
              title: Text('Câmera'),
              subtitle: Text('Para ler QR Codes durante o check-in.'),
            ),
            const ListTile(
              leading: Icon(Icons.location_on, color: Colors.black87),
              title: Text('Localização'),
              subtitle: Text('Para associar sua posição ao evento.'),
            ),
            const ListTile(
              leading: Icon(Icons.notifications, color: Colors.black87),
              title: Text('Notificações'),
              subtitle: Text('Para avisos importantes durante o evento.'),
            ),
            const ListTile(
              leading: Icon(Icons.sd_storage, color: Colors.black87),
              title: Text('Armazenamento'),
              subtitle: Text('Para guardar dados no seu dispositivo.'),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Permitir e Continuar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E0E2C),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
