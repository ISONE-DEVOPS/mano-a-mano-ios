import 'package:flutter/material.dart';
import 'package:mano_mano_dashboard/views/admin/fix_users.dart';

class GestaoView extends StatefulWidget {
  const GestaoView({super.key});

  @override
  State<GestaoView> createState() => _GestaoViewState();
}

class _GestaoViewState extends State<GestaoView> {
  bool _loading = false;
  int? _corrigidos;

  @override
  void initState() {
    super.initState();
    _executarCorrecao();
  }

  void _executarCorrecao() async {
    setState(() => _loading = true);
    final total = await corrigirUsuarios();
    setState(() {
      _corrigidos = total;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão do Sistema'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_pin),
                    label: const Text('Corrigir Utilizadores'),
                    onPressed: _executarCorrecao,
                  ),
                  const SizedBox(height: 16),
                  if (_corrigidos != null)
                    Text(
                      'Corrigidos $_corrigidos utilizador(es)',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  // Adicione aqui mais botões de gestão conforme necessário
                ],
              ),
            ),
    );
  }
}
