import 'package:flutter/material.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';
import 'package:mano_mano_dashboard/views/auth/user_summary_view.dart';

class SuccessRegisterView extends StatelessWidget {
  final String nome;

  const SuccessRegisterView({super.key, required this.nome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified, color: AppColors.primary, size: 80),
              const SizedBox(height: 24),
              Text(
                'Olá $nome, registo concluído com sucesso!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Obrigado por se registar no sistema do evento "Shell ao KM".\n\nAs suas credenciais foram guardadas com sucesso e em breve receberá por email ou WhatsApp o link para download da App Mobile.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                label: const Text('Fechar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => UserSummaryView(
                            nome: nome,
                            email:
                                '', // Substituir pelo email real se disponível
                            telefone: '',
                            emergencia: '',
                            equipa: '',
                            tShirt: '',
                            eventoNome: '',
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('Ver detalhes do registo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
