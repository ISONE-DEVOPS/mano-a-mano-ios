import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  final priceController = TextEditingController();

  // Data
  Map<String, String> equipas = {};
  String? equipaSelecionada;
  Map<String, String> veiculos = {};
  String? veiculoSelecionado;

  bool isLoading = true;
  bool isSaving = false;
  bool isPago = false;
  bool isAtivo = true;
  String? role = 'user';
  DateTime? createAt;
  DateTime? ultimoLogin;

  // T-shirt sizes
  final List<String> tamanhosTshirt = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  final List<String> roles = ['admin', 'user', 'staff'];

  final currencyFormatter = NumberFormat.currency(
    locale: 'pt_CV',
    symbol: 'CVE',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    priceController.dispose();
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

            // Novos campos
            priceController.text = (data['price'] ?? 0).toString();
            isPago = data['isPago'] ?? false;
            isAtivo = data['ativo'] ?? true;
            role = data['role'] ?? 'user';

            if (data['createAt'] != null) {
              createAt = (data['createAt'] as Timestamp).toDate();
            }
            if (data['ultimoLogin'] != null) {
              ultimoLogin = (data['ultimoLogin'] as Timestamp).toDate();
            }
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
      final price = double.tryParse(priceController.text) ?? 0;

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
            'price': price,
            'isPago': isPago,
            'ativo': isAtivo,
            'role': role,
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

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Valor é obrigatório';
    }
    final price = double.tryParse(value);
    if (price == null || price < 0) {
      return 'Valor inválido';
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
            Tab(icon: Icon(Icons.person), text: 'Pessoal'),
            Tab(icon: Icon(Icons.payment), text: 'Pagamento'),
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
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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
        children: [
          _buildDadosPessoaisTab(),
          _buildPagamentoTab(),
          _buildPontuacoesTab(),
        ],
      ),
    );
  }

  Widget _buildDadosPessoaisTab() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          _buildStatusCard(),
          const SizedBox(height: 16),

          // Informações Pessoais
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
                enabled: false, // Email não deve ser editável
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

          // Configurações do Evento
          _buildSectionCard(
            title: 'Configurações do Evento',
            icon: Icons.settings,
            children: [
              DropdownButtonFormField<String>(
                initialValue:
                    tamanhosTshirt.contains(tshirtController.text)
                        ? tshirtController.text
                        : null,
                decoration: InputDecoration(
                  labelText: 'Tamanho da T-shirt',
                  prefixIcon: const Icon(Icons.checkroom_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
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
                initialValue:
                    equipas.containsKey(equipaSelecionada)
                        ? equipaSelecionada
                        : null,
                decoration: InputDecoration(
                  labelText: 'Equipa',
                  prefixIcon: const Icon(Icons.group_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
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
                initialValue:
                    veiculos.containsKey(veiculoSelecionado)
                        ? veiculoSelecionado
                        : null,
                decoration: InputDecoration(
                  labelText: 'Veículo',
                  prefixIcon: const Icon(Icons.directions_car_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
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
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: InputDecoration(
                  labelText: 'Função (Role)',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items:
                    roles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Row(
                              children: [
                                Icon(
                                  r == 'admin'
                                      ? Icons.admin_panel_settings
                                      : r == 'staff'
                                      ? Icons.support_agent
                                      : Icons.person,
                                  size: 20,
                                  color:
                                      r == 'admin'
                                          ? Colors.red
                                          : r == 'staff'
                                          ? Colors.orange
                                          : Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(r.toUpperCase()),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (val) => setState(() => role = val),
              ),
              const SizedBox(height: 16),

              // Switch de status ativo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAtivo ? Icons.check_circle : Icons.cancel,
                      color: isAtivo ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status do Participante',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            isAtivo ? 'Ativo no evento' : 'Inativo',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isAtivo,
                      onChanged: (val) => setState(() => isAtivo = val),
                      activeThumbColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Informações de Auditoria
          if (createAt != null || ultimoLogin != null)
            _buildSectionCard(
              title: 'Informações de Auditoria',
              icon: Icons.info_outline,
              children: [
                if (createAt != null) ...[
                  _buildInfoRow(
                    'Data de Criação',
                    DateFormat('dd/MM/yyyy HH:mm').format(createAt!),
                    Icons.calendar_today,
                  ),
                  const SizedBox(height: 12),
                ],
                if (ultimoLogin != null)
                  _buildInfoRow(
                    'Último Login',
                    DateFormat('dd/MM/yyyy HH:mm').format(ultimoLogin!),
                    Icons.login,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPagamentoTab() {
    final price = double.tryParse(priceController.text) ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card de resumo de pagamento
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors:
                    isPago
                        ? [Colors.green, Colors.green[700]!]
                        : [Colors.orange, Colors.orange[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  isPago ? Icons.check_circle : Icons.pending,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  isPago ? 'PAGAMENTO CONFIRMADO' : 'PAGAMENTO PENDENTE',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormatter.format(price),
                  style: const TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Seção de detalhes de pagamento
        _buildSectionCard(
          title: 'Detalhes do Pagamento',
          icon: Icons.payment,
          children: [
            _buildTextFormField(
              controller: priceController,
              label: 'Valor do Pagamento (CVE)',
              icon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _validatePrice,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 20),

            // Checkbox de confirmação de pagamento
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isPago ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPago ? Colors.green : Colors.orange,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user,
                        color: isPago ? Colors.green : Colors.orange,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Confirmação de Pagamento',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: isPago,
                    onChanged: (val) => setState(() => isPago = val ?? false),
                    title: const Text(
                      'Confirmar que o pagamento foi recebido',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      isPago
                          ? '✓ Pagamento confirmado e registrado'
                          : 'Marque esta opção após confirmar o recebimento',
                      style: TextStyle(
                        color: isPago ? Colors.green[700] : Colors.orange[700],
                        fontSize: 12,
                      ),
                    ),
                    activeColor: Colors.green,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Alerta informativo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Certifique-se de confirmar o pagamento apenas após a verificação do valor recebido.',
                      style: TextStyle(color: Colors.blue[900], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Histórico de transações (simulado)
        _buildSectionCard(
          title: 'Histórico de Transações',
          icon: Icons.history,
          children: [
            if (isPago) ...[
              _buildTransactionItem(
                'Pagamento Recebido',
                price,
                DateTime.now(),
                true,
              ),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nenhuma transação registrada',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'As pontuações aparecerão aqui após a participação no evento',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
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

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isAtivo ? Icons.check_circle : Icons.cancel,
                color: isAtivo ? Colors.green : Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nomeController.text.isNotEmpty
                        ? nomeController.text
                        : 'Participante',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatusBadge(
                        isAtivo ? 'ATIVO' : 'INATIVO',
                        isAtivo ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(
                        isPago ? 'PAGO' : 'PENDENTE',
                        isPago ? Colors.blue : Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    String description,
    double amount,
    DateTime date,
    bool isSuccess,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSuccess ? Icons.check : Icons.close,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            currencyFormatter.format(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isSuccess ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
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
            colors: [Colors.purple, Colors.purpleAccent],
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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
                    color: Colors.purple.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on, color: Colors.purple),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
    bool enabled = true,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
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
