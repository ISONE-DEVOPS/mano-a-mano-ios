import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';
import 'package:mano_mano_dashboard/views/admin/checkpoints_list_dialog.dart';

class EventsView extends StatefulWidget {
  const EventsView({super.key, required this.edicaoId});
  final String edicaoId;

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
  final _nameController = TextEditingController();
  final _localController = TextEditingController();
  final _priceController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _entidadeController = TextEditingController();
  final _searchController = TextEditingController();
  String _query = '';
  DateTime? _selectedDate;
  bool _status = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _localController.dispose();
    _priceController.dispose();
    _descricaoController.dispose();
    _entidadeController.dispose();
    _searchController.dispose();
    super.dispose();
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
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
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
                    Icons.event_available,
                    color: AppColors.secondary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestão de Eventos',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gerencie os eventos e checkpoints desta edição',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddEventDialog,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    'Novo Evento',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  hintText:
                      'Pesquisar por título, local, descrição ou entidade...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.secondary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Lista de Eventos
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('editions')
                      .doc(widget.edicaoId)
                      .collection('events')
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
                    padding: const EdgeInsets.all(64),
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
                          Icons.event_busy,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Nenhum evento cadastrado',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Clique no botão "Novo Evento" para começar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                final q = _query.toLowerCase();
                final filtered =
                    docs.where((d) {
                      final m = d.data() as Map<String, dynamic>;
                      return [
                        m['nome']?.toString() ?? '',
                        m['local']?.toString() ?? '',
                        m['descricao']?.toString() ?? '',
                        m['entidade']?.toString() ?? '',
                      ].any((s) => s.toLowerCase().contains(q));
                    }).toList();

                if (filtered.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum resultado encontrado',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 1400
                            ? 3
                            : MediaQuery.of(context).size.width > 900
                            ? 2
                            : 1,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    // Fix overflow by giving cards a fixed vertical extent
                    mainAxisExtent:
                        MediaQuery.of(context).size.width > 900 ? 300 : 360,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final dataEvento = (data['data'] as Timestamp?)?.toDate();
                    final isAtivo = data['status'] == true;

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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.event,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        data['nome'] ?? 'Sem título',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isAtivo
                                                ? Colors.green.shade50
                                                : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color:
                                              isAtivo
                                                  ? Colors.green.shade200
                                                  : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Text(
                                        isAtivo ? 'Ativo' : 'Inativo',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isAtivo
                                                  ? Colors.green.shade700
                                                  : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (dataEvento != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        DateFormat(
                                          'dd/MM/yyyy – HH:mm',
                                        ).format(dataEvento),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
                                  if (data['descricao'] != null &&
                                      data['descricao'] != '') ...[
                                    Text(
                                      data['descricao'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        height: 1.5,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          data['local'] ??
                                              'Local não informado',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.business_outlined,
                                        size: 16,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          data['entidade'] ?? 'Sem entidade',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.attach_money,
                                        size: 16,
                                        color: AppColors.secondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        data['price'] != null
                                            ? '${NumberFormat('#,##0.##', 'pt_CV').format(data['price'])} ECV'
                                            : 'Gratuito',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                      const Spacer(),
                                      StreamBuilder<QuerySnapshot>(
                                        stream:
                                            FirebaseFirestore.instance
                                                .collection('editions')
                                                .doc(widget.edicaoId)
                                                .collection('events')
                                                .doc(doc.id)
                                                .collection('checkpoints')
                                                .snapshots(),
                                        builder: (context, cpSnapshot) {
                                          final count =
                                              cpSnapshot.data?.docs.length ?? 0;
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.secondary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  size: 14,
                                                  color: AppColors.secondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$count',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.secondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Ações
                          Container(
                            padding: const EdgeInsets.all(12),
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
                                      Get.toNamed(
                                        '/add-checkpoints',
                                        arguments: {
                                          'edicaoId': widget.edicaoId,
                                          'eventId': doc.id,
                                        },
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.add_location,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Adicionar',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.secondary,
                                      side: BorderSide(
                                        color: AppColors.secondary,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () async {
                                    await showDialog(
                                      context: context,
                                      builder:
                                          (_) => CheckpointsListDialog(
                                            edicaoId: widget.edicaoId,
                                            eventId: doc.id,
                                          ),
                                    );
                                  },
                                  icon: const Icon(Icons.list_alt),
                                  color: Colors.blue.shade600,
                                  tooltip: 'Ver Checkpoints',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.blue.shade50,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: () => _showEditEventDialog(doc),
                                  icon: const Icon(Icons.edit_outlined),
                                  color: Colors.orange.shade600,
                                  tooltip: 'Editar',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.orange.shade50,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: () => _confirmDelete(doc),
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red.shade600,
                                  tooltip: 'Eliminar',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red.shade50,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
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

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
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
                            Icons.add_circle_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Novo Evento',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Form
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: 'Título do Evento',
                              hint: 'Ex: Rally Paper Shell ao KM',
                              icon: Icons.title,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? 'Campo obrigatório'
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _descricaoController,
                              label: 'Descrição',
                              hint: 'Descreva o evento...',
                              icon: Icons.description,
                              maxLines: 3,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? 'Campo obrigatório'
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _localController,
                                    label: 'Local',
                                    hint: 'Ex: Kebra Canela',
                                    icon: Icons.location_on,
                                    validator:
                                        (v) =>
                                            v == null || v.isEmpty
                                                ? 'Campo obrigatório'
                                                : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _entidadeController,
                                    label: 'Entidade',
                                    hint: 'Ex: Vivo Energy',
                                    icon: Icons.business,
                                    validator:
                                        (v) =>
                                            v == null || v.isEmpty
                                                ? 'Campo obrigatório'
                                                : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _priceController,
                              label: 'Preço (ECV)',
                              hint: 'Ex: 0.00',
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.number,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? 'Campo obrigatório'
                                          : null,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 20,
                                        color: AppColors.secondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Data e Hora do Evento',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const Spacer(),
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100),
                                          );
                                          if (!mounted || date == null) return;

                                          final time = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.now(),
                                          );
                                          if (!mounted || time == null) return;

                                          setState(() {
                                            _selectedDate = DateTime(
                                              date.year,
                                              date.month,
                                              date.day,
                                              time.hour,
                                              time.minute,
                                            );
                                          });
                                        },
                                        icon: const Icon(Icons.event, size: 18),
                                        label: Text(
                                          _selectedDate == null
                                              ? 'Selecionar'
                                              : DateFormat(
                                                'dd/MM/yyyy – HH:mm',
                                              ).format(_selectedDate!),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.secondary,
                                          side: BorderSide(
                                            color: AppColors.secondary,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.toggle_on,
                                    size: 20,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Status do Evento',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: _status,
                                    onChanged:
                                        (v) => setState(() => _status = v),
                                    activeThumbColor: AppColors.secondary,
                                  ),
                                  Text(
                                    _status ? 'Ativo' : 'Inativo',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          _status
                                              ? Colors.green.shade700
                                              : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
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
                          onPressed: () => Navigator.pop(context),
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
                            if (_formKey.currentState?.validate() != true ||
                                _selectedDate == null) {
                              _showSnackBar(
                                'Preencha todos os campos',
                                isError: true,
                              );
                              return;
                            }

                            try {
                              await FirebaseFirestore.instance
                                  .collection('editions')
                                  .doc(widget.edicaoId)
                                  .collection('events')
                                  .add({
                                    'nome': _nameController.text.trim(),
                                    'local': _localController.text.trim(),
                                    'price':
                                        double.tryParse(
                                          _priceController.text.trim(),
                                        ) ??
                                        0,
                                    'data': Timestamp.fromDate(_selectedDate!),
                                    'status': _status,
                                    'descricao':
                                        _descricaoController.text.trim(),
                                    'entidade': _entidadeController.text.trim(),
                                  });

                              if (!mounted) return;
                              Navigator.pop(context);

                              _nameController.clear();
                              _localController.clear();
                              _priceController.clear();
                              _descricaoController.clear();
                              _entidadeController.clear();
                              setState(() => _selectedDate = null);

                              _showSnackBar(
                                'Evento criado com sucesso! 🎉',
                                isError: false,
                              );
                            } catch (e) {
                              _showSnackBar('Erro ao criar: $e', isError: true);
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
                                'Criar Evento',
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

  void _showEditEventDialog(DocumentSnapshot doc) {
    final formKey = GlobalKey<FormState>();
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final nameController = TextEditingController(text: data['nome'] ?? '');
    final localController = TextEditingController(text: data['local'] ?? '');
    final priceController = TextEditingController(
      text: '${data['price'] ?? ''}',
    );
    final descricaoController = TextEditingController(
      text: data['descricao'] ?? '',
    );
    final entidadeController = TextEditingController(
      text: data['entidade'] ?? '',
    );
    DateTime? selectedDate =
        (data['data'] as Timestamp?)?.toDate() ?? DateTime.now();
    bool status = data['status'] ?? true;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => Dialog(
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
                                Colors.orange.shade600,
                                Colors.orange.shade400,
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
                                  'Editar Evento',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  nameController.dispose();
                                  localController.dispose();
                                  priceController.dispose();
                                  descricaoController.dispose();
                                  entidadeController.dispose();
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
                              key: formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTextField(
                                    controller: nameController,
                                    label: 'Título do Evento',
                                    hint: 'Ex: Rally Paper Shell ao KM',
                                    icon: Icons.title,
                                    validator:
                                        (v) =>
                                            v == null || v.isEmpty
                                                ? 'Campo obrigatório'
                                                : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: descricaoController,
                                    label: 'Descrição',
                                    hint: 'Descreva o evento...',
                                    icon: Icons.description,
                                    maxLines: 3,
                                    validator:
                                        (v) =>
                                            v == null || v.isEmpty
                                                ? 'Campo obrigatório'
                                                : null,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: localController,
                                          label: 'Local',
                                          hint: 'Ex: Kebra Canela',
                                          icon: Icons.location_on,
                                          validator:
                                              (v) =>
                                                  v == null || v.isEmpty
                                                      ? 'Campo obrigatório'
                                                      : null,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: entidadeController,
                                          label: 'Entidade',
                                          hint: 'Ex: Vivo Energy',
                                          icon: Icons.business,
                                          validator:
                                              (v) =>
                                                  v == null || v.isEmpty
                                                      ? 'Campo obrigatório'
                                                      : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: priceController,
                                    label: 'Preço (ECV)',
                                    hint: 'Ex: 0.00',
                                    icon: Icons.attach_money,
                                    keyboardType: TextInputType.number,
                                    validator:
                                        (v) =>
                                            v == null || v.isEmpty
                                                ? 'Campo obrigatório'
                                                : null,
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 20,
                                              color: Colors.orange.shade600,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Data e Hora do Evento',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const Spacer(),
                                            OutlinedButton.icon(
                                              onPressed: () async {
                                                final date =
                                                    await showDatePicker(
                                                      context: context,
                                                      initialDate:
                                                          selectedDate ??
                                                          DateTime.now(),
                                                      firstDate: DateTime(2000),
                                                      lastDate: DateTime(2100),
                                                    );
                                                if (!context.mounted ||
                                                    date == null) {
                                                  return;
                                                }

                                                final time =
                                                    await showTimePicker(
                                                      context: context,
                                                      initialTime:
                                                          TimeOfDay.fromDateTime(
                                                            selectedDate ??
                                                                DateTime.now(),
                                                          ),
                                                    );
                                                if (!context.mounted ||
                                                    time == null) {
                                                  return;
                                                }

                                                setState(() {
                                                  selectedDate = DateTime(
                                                    date.year,
                                                    date.month,
                                                    date.day,
                                                    time.hour,
                                                    time.minute,
                                                  );
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.event,
                                                size: 18,
                                              ),
                                              label: Text(
                                                selectedDate == null
                                                    ? 'Selecionar'
                                                    : DateFormat(
                                                      'dd/MM/yyyy – HH:mm',
                                                    ).format(selectedDate!),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    Colors.orange.shade600,
                                                side: BorderSide(
                                                  color: Colors.orange.shade600,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.toggle_on,
                                          size: 20,
                                          color: Colors.orange.shade600,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Status do Evento',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const Spacer(),
                                        Switch(
                                          value: status,
                                          onChanged:
                                              (v) => setState(() => status = v),
                                          activeThumbColor:
                                              Colors.orange.shade600,
                                        ),
                                        Text(
                                          status ? 'Ativo' : 'Inativo',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                status
                                                    ? Colors.green.shade700
                                                    : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
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
                                  Navigator.pop(context);
                                  nameController.dispose();
                                  localController.dispose();
                                  priceController.dispose();
                                  descricaoController.dispose();
                                  entidadeController.dispose();
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
                                  if (formKey.currentState?.validate() !=
                                          true ||
                                      selectedDate == null) {
                                    return;
                                  }

                                  try {
                                    await doc.reference.update({
                                      'nome': nameController.text.trim(),
                                      'local': localController.text.trim(),
                                      'price':
                                          double.tryParse(
                                            priceController.text.trim(),
                                          ) ??
                                          0,
                                      'data': Timestamp.fromDate(selectedDate!),
                                      'status': status,
                                      'descricao':
                                          descricaoController.text.trim(),
                                      'entidade':
                                          entidadeController.text.trim(),
                                    });

                                    if (!context.mounted) return;
                                    Navigator.pop(context);

                                    nameController.dispose();
                                    localController.dispose();
                                    priceController.dispose();
                                    descricaoController.dispose();
                                    entidadeController.dispose();

                                    _showSnackBar(
                                      'Evento atualizado com sucesso! ✓',
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
                                  backgroundColor: Colors.orange.shade600,
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
          ),
    );
  }

  void _confirmDelete(DocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade400,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text('Confirmar exclusão'),
              ],
            ),
            content: const Text(
              'Deseja mesmo eliminar este evento? Todos os checkpoints associados também serão eliminados. Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // Eliminar checkpoints primeiro
        final checkpoints =
            await FirebaseFirestore.instance
                .collection('editions')
                .doc(widget.edicaoId)
                .collection('events')
                .doc(doc.id)
                .collection('checkpoints')
                .get();

        for (final cp in checkpoints.docs) {
          await cp.reference.delete();
        }

        // Eliminar evento
        await doc.reference.delete();

        if (mounted) {
          _showSnackBar('Evento eliminado com sucesso', isError: false);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Erro ao eliminar: $e', isError: true);
        }
      }
    }
  }
}
