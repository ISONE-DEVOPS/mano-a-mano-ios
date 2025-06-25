import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditParticipantesView extends StatefulWidget {
  final String userId;
  const EditParticipantesView({super.key, required this.userId});

  @override
  State<EditParticipantesView> createState() => _EditParticipantesViewState();
}

class _EditParticipantesViewState extends State<EditParticipantesView>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Controllers
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final emergenciaController = TextEditingController();
  final tshirtController = TextEditingController();

  // Data
  Map<String, String> equipas = {};
  String? equipaSelecionada;
  Map<String, String> veiculos = {};
  String? veiculoSelecionado;

  bool isLoading = true;
  bool isSaving = false;

  // T-shirt sizes
  final List<String> tamanhosTshirt = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    emergenciaController.dispose();
    tshirtController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    try {
      // Carregar dados do usuário
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .get();

      // Carregar equipas
      final equipesSnapshot =
          await FirebaseFirestore.instance.collection('equipas').get();
      final equipasTemp = <String, String>{};
      for (final doc in equipesSnapshot.docs) {
        equipasTemp[doc.id] = doc['nome'] ?? 'Sem nome';
      }

      // Carregar veículos
      final veiculosSnapshot =
          await FirebaseFirestore.instance.collection('veiculos').get();
      final veiculosTemp = <String, String>{};
      for (final doc in veiculosSnapshot.docs) {
        veiculosTemp[doc.id] =
            '${doc['modelo'] ?? 'Modelo'} - ${doc['matricula'] ?? 'Sem matrícula'}';
      }

      if (mounted) {
        setState(() {
          equipas = equipasTemp;
          veiculos = veiculosTemp;

          final data = doc.data();
          if (data != null) {
            nomeController.text = data['nome'] ?? '';
            emailController.text = data['email'] ?? '';
            telefoneController.text = data['telefone'] ?? '';
            emergenciaController.text = data['emergencia'] ?? '';
            tshirtController.text = data['tshirt'] ?? '';
            equipaSelecionada = data['equipaId'];
            veiculoSelecionado = data['veiculoId'];
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showErrorSnackBar('Erro ao carregar dados: $e');
      }
    }
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'nome': nomeController.text.trim(),
            'email': emailController.text.trim(),
            'telefone': telefoneController.text.trim(),
            'emergencia': emergenciaController.text.trim(),
            'tshirt': tshirtController.text.trim(),
            'equipaId': equipaSelecionada,
            'veiculoId': veiculoSelecionado,
          });

      if (mounted) {
        _showSuccessSnackBar('Participante atualizado com sucesso!');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao salvar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email é obrigatório';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefone é obrigatório';
    }
    if (value.length < 7) {
      return 'Telefone deve ter pelo menos 7 dígitos';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Participante'), elevation: 0),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando dados...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Participante'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Dados Pessoais'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Pontuações'),
          ],
        ),
        actions: [
          if (!isSaving)
            TextButton.icon(
              onPressed: _salvarAlteracoes,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Salvar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          if (isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDadosPessoaisTab(), _buildPontuacoesTab()],
      ),
    );
  }

  Widget _buildDadosPessoaisTab() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard(
            title: 'Informações Pessoais',
            icon: Icons.person,
            children: [
              _buildTextFormField(
                controller: nomeController,
                label: 'Nome Completo',
                icon: Icons.person_outline,
                validator: (value) => _validateRequired(value, 'Nome'),
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: telefoneController,
                label: 'Telefone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: emergenciaController,
                label: 'Contacto de Emergência',
                icon: Icons.emergency_outlined,
                keyboardType: TextInputType.phone,
                validator:
                    (value) =>
                        _validateRequired(value, 'Contacto de emergência'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Configurações do Evento',
            icon: Icons.settings,
            children: [
              DropdownButtonFormField<String>(
                value:
                    tamanhosTshirt.contains(tshirtController.text)
                        ? tshirtController.text
                        : null,
                decoration: InputDecoration(
                  labelText: 'Tamanho da T-shirt',
                  prefixIcon: const Icon(Icons.checkroom_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items:
                    tamanhosTshirt
                        .map(
                          (size) =>
                              DropdownMenuItem(value: size, child: Text(size)),
                        )
                        .toList(),
                onChanged:
                    (value) =>
                        setState(() => tshirtController.text = value ?? ''),
                validator:
                    (value) => _validateRequired(value, 'Tamanho da T-shirt'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value:
                    equipas.containsKey(equipaSelecionada)
                        ? equipaSelecionada
                        : null,
                decoration: InputDecoration(
                  labelText: 'Equipa',
                  prefixIcon: const Icon(Icons.group_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items:
                    equipas.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                onChanged: (val) => setState(() => equipaSelecionada = val),
                validator:
                    (value) => value == null ? 'Selecione uma equipa' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value:
                    veiculos.containsKey(veiculoSelecionado)
                        ? veiculoSelecionado
                        : null,
                decoration: InputDecoration(
                  labelText: 'Veículo',
                  prefixIcon: const Icon(Icons.directions_car_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items:
                    veiculos.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                onChanged: (val) => setState(() => veiculoSelecionado = val),
                validator:
                    (value) => value == null ? 'Selecione um veículo' : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPontuacoesTab() {
    return FutureBuilder<QuerySnapshot>(
      future: _getPontuacoes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Carregando pontuações...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erro: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhuma pontuação registrada',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'As pontuações aparecerão aqui após a participação no evento',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final total = docs.fold<int>(0, (acumulado, doc) {
          final data = doc.data() as Map<String, dynamic>;
          final pontos = data['pontuacaoTotal'] ?? 0;
          return acumulado + (pontos as num).toInt();
        });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTotalScoreCard(total),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Detalhes por Checkpoint',
              icon: Icons.list_alt,
              children: docs.map((doc) => _buildCheckpointCard(doc)).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTotalScoreCard(int total) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, size: 48, color: Colors.white),
            const SizedBox(height: 8),
            const Text(
              'Pontuação Total',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$total pontos',
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckpointCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final pontuacaoTotal = data['pontuacaoTotal'] ?? 0;
    final pontuacaoPergunta = data['pontuacaoPergunta'] ?? 0;
    final pontuacaoJogo = data['pontuacaoJogo'] ?? 0;
    final respostaCorreta = data['respostaCorreta'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Checkpoint: ${doc.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$pontuacaoTotal pontos totais',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: pontuacaoTotal > 0 ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pontuacaoTotal pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildScoreItem(
                    'Pergunta',
                    pontuacaoPergunta,
                    respostaCorreta ? Icons.check_circle : Icons.cancel,
                    respostaCorreta ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildScoreItem(
                    'Jogo',
                    pontuacaoJogo,
                    Icons.sports_esports,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, int score, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$score pts',
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }

  Future<QuerySnapshot> _getPontuacoes() async {
    try {
      final eventosSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('eventos')
              .limit(1)
              .get();

      if (eventosSnapshot.docs.isEmpty) {
        return QuerySnapshotMock();
      }

      final eventoId = eventosSnapshot.docs.first.id;
      return await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('eventos')
          .doc(eventoId)
          .collection('pontuacoes')
          .get();
    } catch (e) {
      throw Exception('Erro ao carregar pontuações: $e');
    }
  }
}

class QuerySnapshotMock implements QuerySnapshot {
  @override
  List<QueryDocumentSnapshot<Object?>> get docs =>
      <QueryDocumentSnapshot<Object?>>[];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
