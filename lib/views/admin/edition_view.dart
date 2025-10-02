import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';
import 'package:mano_mano_dashboard/views/admin/events_view.dart';

class EditionView extends StatefulWidget {
  const EditionView({super.key});

  @override
  State<EditionView> createState() => _EditionViewState();
}

class _EditionViewState extends State<EditionView> {
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _dataInicioController = TextEditingController();
  final _dataFimController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _dataInicioController.dispose();
    _dataFimController.dispose();
    super.dispose();
  }

  void _salvarEdicao() async {
    if (!_formKey.currentState!.validate()) return;

    final nome = _nomeController.text.trim();
    final descricao = _descricaoController.text.trim();
    final dataInicio = DateTime.tryParse(_dataInicioController.text.trim());
    final dataFim = DateTime.tryParse(_dataFimController.text.trim());

    if (dataInicio == null || dataFim == null) {
      _showSnackBar('Formato de data inválido. Use YYYY-MM-DD', isError: true);
      return;
    }

    if (dataInicio.isAfter(dataFim)) {
      _showSnackBar(
        'Data de início deve ser antes da data de fim',
        isError: true,
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('editions').add({
        'nome': nome,
        'descricao': descricao,
        'dataInicio': dataInicio,
        'dataFim': dataFim,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showSnackBar('Edição salva com sucesso! 🎉', isError: false);

      _nomeController.clear();
      _descricaoController.clear();
      _dataInicioController.clear();
      _dataFimController.clear();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erro ao salvar: $e', isError: true);
    }
  }

  void _editarEdicao(String docId, Map<String, dynamic> data) {
    final editNomeController = TextEditingController(text: data['nome']);
    final editDescricaoController = TextEditingController(
      text: data['descricao'],
    );

    final inicio = (data['dataInicio'] as Timestamp?)?.toDate();
    final fim = (data['dataFim'] as Timestamp?)?.toDate();

    final editDataInicioController = TextEditingController(
      text: inicio != null ? _formatDateForInput(inicio) : '',
    );
    final editDataFimController = TextEditingController(
      text: fim != null ? _formatDateForInput(fim) : '',
    );

    final editFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondary,
                          AppColors.secondary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Editar Edição',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(ctx);
                            editNomeController.dispose();
                            editDescricaoController.dispose();
                            editDataInicioController.dispose();
                            editDataFimController.dispose();
                          },
                        ),
                      ],
                    ),
                  ),

                  // Form
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: editFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: editDataInicioController,
                                    label: 'Data de Início',
                                    hint: 'Ex: 2025-06-28',
                                    icon: Icons.calendar_today,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Campo obrigatório';
                                      }
                                      if (DateTime.tryParse(value) == null) {
                                        return 'Data inválida';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: editDataFimController,
                                    label: 'Data de Fim',
                                    hint: 'Ex: 2025-06-28',
                                    icon: Icons.event,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Campo obrigatório';
                                      }
                                      if (DateTime.tryParse(value) == null) {
                                        return 'Data inválida';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: editNomeController,
                              label: 'Nome da Edição',
                              hint: 'Ex: Shell ao KM 2025',
                              icon: Icons.title,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Campo obrigatório';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: editDescricaoController,
                              label: 'Descrição',
                              hint: 'Ex: Corrida solidária com checkpoints',
                              icon: Icons.description,
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Campo obrigatório';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Actions
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            editNomeController.dispose();
                            editDescricaoController.dispose();
                            editDataInicioController.dispose();
                            editDataFimController.dispose();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (!editFormKey.currentState!.validate()) return;

                            final novoNome = editNomeController.text.trim();
                            final novaDescricao =
                                editDescricaoController.text.trim();
                            final novaDataInicio = DateTime.tryParse(
                              editDataInicioController.text.trim(),
                            );
                            final novaDataFim = DateTime.tryParse(
                              editDataFimController.text.trim(),
                            );

                            if (novaDataInicio == null || novaDataFim == null) {
                              _showSnackBar(
                                'Formato de data inválido',
                                isError: true,
                              );
                              return;
                            }

                            if (novaDataInicio.isAfter(novaDataFim)) {
                              _showSnackBar(
                                'Data de início deve ser antes da data de fim',
                                isError: true,
                              );
                              return;
                            }

                            try {
                              await FirebaseFirestore.instance
                                  .collection('editions')
                                  .doc(docId)
                                  .update({
                                    'nome': novoNome,
                                    'descricao': novaDescricao,
                                    'dataInicio': novaDataInicio,
                                    'dataFim': novaDataFim,
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });

                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);

                              editNomeController.dispose();
                              editDescricaoController.dispose();
                              editDataInicioController.dispose();
                              editDataFimController.dispose();

                              _showSnackBar(
                                'Edição atualizada com sucesso! ✓',
                                isError: false,
                              );
                            } catch (e) {
                              _showSnackBar(
                                'Erro ao atualizar: $e',
                                isError: true,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Salvar Alterações',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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

  String _formatDateForInput(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.secondary, size: 22),
        labelStyle: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event_note,
                    color: AppColors.secondary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestão de Edições',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Crie e gerencie as edições do evento',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Formulário em Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nova Edição',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Preencha os dados para criar uma nova edição',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _dataInicioController,
                            label: 'Data de Início',
                            hint: 'Ex: 2025-06-28',
                            icon: Icons.calendar_today,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Campo obrigatório';
                              }
                              if (DateTime.tryParse(value) == null) {
                                return 'Data inválida';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _dataFimController,
                            label: 'Data de Fim',
                            hint: 'Ex: 2025-06-28',
                            icon: Icons.event,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Campo obrigatório';
                              }
                              if (DateTime.tryParse(value) == null) {
                                return 'Data inválida';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _nomeController,
                      label: 'Nome da Edição',
                      hint: 'Ex: Shell ao KM 2025',
                      icon: Icons.title,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _descricaoController,
                      label: 'Descrição',
                      hint: 'Ex: Corrida solidária com checkpoints',
                      icon: Icons.description,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _salvarEdicao,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_circle_outline, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Salvar Edição',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Lista de Edições
            Row(
              children: [
                Icon(Icons.list_alt, color: AppColors.secondary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Edições Criadas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('editions')
                      .orderBy('dataInicio', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: AppColors.secondary,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma edição criada',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crie sua primeira edição usando o formulário acima',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 1200
                            ? 3
                            : MediaQuery.of(context).size.width > 800
                            ? 2
                            : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final inicio = (data['dataInicio'] as Timestamp?)?.toDate();
                    final fim = (data['dataFim'] as Timestamp?)?.toDate();

                    String formatDate(DateTime? dt) {
                      if (dt == null) return '-';
                      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.shade100,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header do Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.secondary.withValues(alpha: 0.1),
                                  AppColors.secondary.withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.event,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    data['nome'] ?? 'Sem nome',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Conteúdo
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['descricao'] ?? 'Sem descrição',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      height: 1.5,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${formatDate(inicio)} - ${formatDate(fim)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Ações
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (_) => Dialog(
                                              backgroundColor: Colors.white,
                                              insetPadding:
                                                  const EdgeInsets.all(16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Column(
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          AppColors.secondary,
                                                          AppColors.secondary
                                                              .withValues(
                                                                alpha: 0.8,
                                                              ),
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          const BorderRadius.only(
                                                            topLeft:
                                                                Radius.circular(
                                                                  20,
                                                                ),
                                                            topRight:
                                                                Radius.circular(
                                                                  20,
                                                                ),
                                                          ),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 24,
                                                          vertical: 20,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.event_note,
                                                          color: Colors.white,
                                                          size: 24,
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            'Eventos: ${data['nome'] ?? doc.id}',
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 18,
                                                                ),
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.close,
                                                            color: Colors.white,
                                                          ),
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                  ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: SizedBox(
                                                      width:
                                                          MediaQuery.of(
                                                            context,
                                                          ).size.width *
                                                          0.9,
                                                      child: EventsView(
                                                        edicaoId: doc.id,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                      );
                                    },
                                    icon: const Icon(Icons.settings, size: 18),
                                    label: const Text(
                                      'Eventos',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.secondary,
                                      side: BorderSide(
                                        color: AppColors.secondary,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _editarEdicao(doc.id, data),
                                  icon: const Icon(Icons.edit_outlined),
                                  color: Colors.blue.shade600,
                                  tooltip: 'Editar',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.blue.shade50,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (ctx) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            title: Row(
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.orange.shade400,
                                                  size: 28,
                                                ),
                                                const SizedBox(width: 12),
                                                const Text(
                                                  'Confirmar exclusão',
                                                ),
                                              ],
                                            ),
                                            content: const Text(
                                              'Deseja mesmo eliminar esta edição? Esta ação não pode ser desfeita.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      ctx,
                                                      false,
                                                    ),
                                                child: Text(
                                                  'Cancelar',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      ctx,
                                                      true,
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                child: const Text('Eliminar'),
                                              ),
                                            ],
                                          ),
                                    );

                                    if (confirm == true) {
                                      await FirebaseFirestore.instance
                                          .collection('editions')
                                          .doc(doc.id)
                                          .delete();
                                      if (context.mounted) {
                                        _showSnackBar(
                                          'Edição eliminada com sucesso',
                                          isError: false,
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red.shade400,
                                  tooltip: 'Eliminar',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red.shade50,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
