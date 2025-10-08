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
                'Os dados pessoais recolhidos na aplicação “Mano a Mano” — como nome, email, localização e desempenho no evento — serão utilizados exclusivamente para fins de registo, pontuação e organização do Evento.\n\n'
                'A organização compromete-se a:\n'
                '• Proteger os dados dos utilizadores com medidas de segurança adequadas;\n'
                '• Não partilhar os dados com terceiros sem o consentimento prévio do participante;\n'
                '• Permitir a eliminação dos dados após o evento, mediante solicitação formal.\n\n'
                'Os utilizadores podem solicitar a eliminação da sua conta e dos seus dados diretamente na aplicação, acedendo à área de perfil e selecionando a opção "Eliminar Conta".\n\n'
                'Para mais informações, entre em contacto com a organização através do email: manoamanooffroad@gmail.com.',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.arrow_back, color: Colors.white70),
                  label: Text(
                    'Voltar ao Perfil',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: Column(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
