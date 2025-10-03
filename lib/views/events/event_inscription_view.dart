import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EventInscriptionView extends StatefulWidget {
  const EventInscriptionView({super.key});

  @override
  State<EventInscriptionView> createState() => _EventInscriptionViewState();
}

class _EventInscriptionViewState extends State<EventInscriptionView> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emergenciaController = TextEditingController();

  String? _selectedTshirtSize;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _acceptTerms = false;

  final List<String> _tshirtSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _emergenciaController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _nomeController.text = data['nome'] ?? '';
          _emailController.text = data['email'] ?? user.email ?? '';
          _telefoneController.text = data['telefone'] ?? '';
          _emergenciaController.text = data['emergencia'] ?? '';
          _selectedTshirtSize = data['tshirt'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _emailController.text = user.email ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Erro ao carregar dados do usuário');
    }
  }

  Future<void> _submitInscricao() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      _showErrorDialog(
        'Você precisa aceitar os termos e condições para se inscrever.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final evento =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final editionId = evento['editionId'];
      final eventId = evento['id'];
      final eventoPath = 'editions/$editionId/events/$eventId';

      // Atualizar dados do usuário
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'nome': _nomeController.text,
            'telefone': _telefoneController.text,
            'emergencia': _emergenciaController.text,
            'tshirt': _selectedTshirtSize,
          });

      // Criar inscrição no evento
      final inscricaoRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('events')
              .doc();

      await inscricaoRef.set({
        'eventoId': eventoPath,
        'editionId': editionId,
        'eventId': eventId,
        'dataInscricao': FieldValue.serverTimestamp(),
        'ativo': true,
        'nome': _nomeController.text,
        'email': _emailController.text,
        'telefone': _telefoneController.text,
        'emergencia': _emergenciaController.text,
        'tshirt': _selectedTshirtSize,
        'status': 'confirmado',
      });

      setState(() => _isSubmitting = false);

      // Mostrar diálogo de sucesso
      _showSuccessDialog();
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showErrorDialog('Erro ao realizar inscrição: ${e.toString()}');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Inscrição Confirmada!'),
              ],
            ),
            content: const Text(
              'Sua inscrição foi realizada com sucesso! '
              'Você receberá mais informações por e-mail.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fechar diálogo
                  Navigator.of(context).pop(); // Voltar para detalhes
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 32),
                SizedBox(width: 12),
                Text('Erro'),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final evento =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (evento == null) {
      return const Scaffold(
        body: Center(child: Text('Evento não encontrado.')),
      );
    }

    final data = (evento['data'] as Timestamp?)?.toDate();
    final price = evento['price'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscrição no Evento'),
        centerTitle: true,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header do evento
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFdd1d21),
                            const Color(0xFFdd1d21).withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.event_available,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            evento['nome'] ?? 'Evento',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (data != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(data),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              price > 0
                                  ? 'Valor: ${price.toStringAsFixed(0)} CVE'
                                  : 'Evento Gratuito',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFdd1d21),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Formulário
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Seus Dados',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Preencha os dados abaixo para confirmar sua inscrição',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 24),

                            // Nome completo
                            TextFormField(
                              controller: _nomeController,
                              decoration: InputDecoration(
                                labelText: 'Nome Completo *',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor, informe seu nome completo';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'E-mail *',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor, informe seu e-mail';
                                }
                                if (!value.contains('@')) {
                                  return 'E-mail inválido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Telefone
                            TextFormField(
                              controller: _telefoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Telefone *',
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                hintText: '+238 XXX XX XX',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor, informe seu telefone';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Contato de emergência
                            TextFormField(
                              controller: _emergenciaController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Contato de Emergência *',
                                prefixIcon: const Icon(Icons.emergency),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                hintText: '+238 XXX XX XX',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor, informe um contato de emergência';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Tamanho da camiseta
                            DropdownButtonFormField<String>(
                              initialValue: _selectedTshirtSize,
                              decoration: InputDecoration(
                                labelText: 'Tamanho da T-Shirt *',
                                prefixIcon: const Icon(Icons.checkroom),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              items:
                                  _tshirtSizes.map((size) {
                                    return DropdownMenuItem(
                                      value: size,
                                      child: Text(size),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedTshirtSize = value);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, selecione o tamanho da T-shirt';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Termos e condições
                            Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: CheckboxListTile(
                                value: _acceptTerms,
                                onChanged: (value) {
                                  setState(() => _acceptTerms = value ?? false);
                                },
                                title: const Text(
                                  'Li e aceito os termos e condições',
                                  style: TextStyle(fontSize: 14),
                                ),
                                subtitle: TextButton(
                                  onPressed: _showTermsDialog,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    alignment: Alignment.centerLeft,
                                  ),
                                  child: const Text(
                                    'Ver termos e condições',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Botão de inscrição
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    _isSubmitting ? null : _submitInscricao,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFdd1d21),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child:
                                    _isSubmitting
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
                                          'Confirmar Inscrição',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Nota
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Após confirmar a inscrição, você receberá um e-mail com mais detalhes sobre o evento.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Termos e Condições'),
            content: const SingleChildScrollView(
              child: Text(
                'TERMOS E CONDIÇÕES DE PARTICIPAÇÃO\n\n'
                '1. O participante declara estar em boas condições de saúde para participar do evento.\n\n'
                '2. O participante autoriza o uso de sua imagem em materiais de divulgação do evento.\n\n'
                '3. A organização não se responsabiliza por objetos perdidos durante o evento.\n\n'
                '4. O participante deve seguir todas as orientações da organização e equipe de apoio.\n\n'
                '5. Em caso de condições climáticas adversas, a organização reserva-se o direito de cancelar ou reagendar o evento.\n\n'
                '6. O valor pago na inscrição não é reembolsável, exceto em caso de cancelamento do evento pela organização.\n\n'
                '7. O participante declara ter lido e compreendido o regulamento do evento.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }
}
