import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termos e Condições')),
      backgroundColor: const Color(0xFF0E0E2C),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Ao participar do evento “Mano a Mano”, o utilizador concorda em cumprir as regras estabelecidas no Regulamento Oficial do Evento, incluindo, mas não se limitando a:\n\n'
                '• Garantir a veracidade das informações fornecidas durante o registo;\n'
                '• Cumprir as normas de segurança e o Código da Estrada;\n'
                '• Autorizar o uso da sua imagem e dados para fins promocionais do evento;\n'
                '• Aceitar que a organização não se responsabiliza por acidentes ou infrações cometidas durante o percurso.\n\n'
                'O não cumprimento dos termos pode resultar em desclassificação imediata.',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 30),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo1.jpg', height: 80),
                  const SizedBox(height: 10),
                  const Text(
                    'Boa sorte e divirtam-se!',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
