import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Política de Privacidade')),
      backgroundColor: const Color(0xFF0E0E2C),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Os dados pessoais recolhidos na aplicação “Shell ao KM” — como nome, email, localização e desempenho no evento — serão utilizados exclusivamente para fins de registo, pontuação e organização do Rally Paper.\n\n'
                'A organização compromete-se a:\n'
                '• Proteger os dados dos utilizadores com medidas de segurança adequadas;\n'
                '• Não partilhar os dados com terceiros sem o consentimento prévio do participante;\n'
                '• Permitir a eliminação dos dados após o evento, mediante solicitação formal.\n\n'
                'Para mais informações, entre em contacto com a organização através do email: info@manoamano.com.',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    Image.asset('assets/images/Logo_Shell_KM.png', height: 80),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
