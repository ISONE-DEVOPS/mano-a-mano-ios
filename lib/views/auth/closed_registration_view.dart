import 'package:flutter/material.dart';

class ClosedRegistrationView extends StatelessWidget {
  const ClosedRegistrationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/shell_logo.png', height: 120),
                const SizedBox(height: 24),
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Inscrições Encerradas',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Agradecemos o seu interesse, mas o número máximo de equipas já foi atingido.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                /*const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed:
                      () => Navigator.of(context).pushReplacementNamed('/home'),
                  icon: const Icon(Icons.home),
                  label: const Text('Voltar ao início'),
                ),*/
              ],
            ),
          ),
        ),
      ),
    );
  }
}
