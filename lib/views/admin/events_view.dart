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
  final bool _sortAsc = true;
  final int _sortColumnIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos: Mano a Mano'),
        backgroundColor: const Color(0xFFFFC600), // Shell Yellow
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('editions')
                      .doc(widget.edicaoId)
                      .collection('events')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum evento encontrado'));
                }

                final docs = snapshot.data!.docs;
                final q = _query.toLowerCase();
                final filtered = docs.where((d) {
                  final m = d.data() as Map<String, dynamic>;
                  return [
                    m['nome']?.toString() ?? '',
                    m['local']?.toString() ?? '',
                    m['descricao']?.toString() ?? '',
                    m['entidade']?.toString() ?? '',
                  ].any((s) => s.toLowerCase().contains(q));
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Pesquisar por título, local, descrição ou entidade',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Table in a Card
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFFFC600), // Shell Yellow
                ),
                sortAscending: _sortAsc,
                sortColumnIndex: _sortColumnIndex,
                columns: [
                  DataColumn(
                    label: Text(
                      'DATA',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'TÍTULO',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'LOCAL',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'PREÇO',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // DESCRIÇÃO column
                  DataColumn(
                    label: Text(
                      'DESCRIÇÃO',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // ENTIDADE column
                  DataColumn(
                    label: Text(
                      'ENTIDADE',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'STATUS',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'CHECKPOINTS',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'AÇÕES / PERCURSO',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
                rows: List<DataRow>.generate(filtered.length, (index) {
                  final doc = filtered[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final dataEvento = (data['data'] as Timestamp?)?.toDate();
                  final dataTexto =
                      dataEvento != null
                          ? DateFormat(
                              'dd/MM/yyyy – HH:mm',
                            ).format(dataEvento)
                          : '';
                  final borderSide = BorderSide(
                    color: Colors.black12,
                    width: 0.8,
                  );
                  final cellDecoration = BoxDecoration(
                    border: Border(bottom: borderSide),
                  );
                  const cellPadding = EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  );
                  return DataRow(
                    color: MaterialStateProperty.resolveWith(
                        (states) => index.isOdd ? const Color(0xFFFFF3E5) : Colors.white),
                    cells: [
                      DataCell(
                        Container(
                          decoration: cellDecoration,
                          padding: cellPadding,
                          child: Text(
                            dataTexto,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black87),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          decoration: cellDecoration,
                          padding: cellPadding,
                          child: Text(
                            data['nome'] ?? '',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black87),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          decoration: cellDecoration,
                          padding: cellPadding,
                          child: Text(
                            data['local'] ?? '',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black87),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          decoration: cellDecoration,
                          padding: cellPadding,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              data['price'] != null
                                  ? '${NumberFormat('#,##0.##', 'pt_CV').format(data['price'])} ECV'
                                  : '—',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                            ),
                          ),
                        ),
                      ),
                      // DESCRIÇÃO column
                      DataCell(
                        Container(
                          decoration: cellDecoration,
                          padding: cellPadding,
                          child: Text(
                            data['descricao'] ?? '',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black87),
                          ),
                        ),
                      ),
                      // ENTIDADE column
                      DataCell(
                        Container(
                          decoration: cellDecoration,
                          padding: cellPadding,
                          child: Text(
                            data['entidade'] ?? '',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black87),
                          ),
                        ),
                      ),
                      // STATUS column
                      DataCell(
                        Container(
                          decoration: cellDecoration,
                          padding: cellPadding,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Chip(
                              label: Text(
                                data['status'] == true ? 'Ativo' : 'Inativo',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: data['status'] == true
                                  ? const Color(0xFFCBE6D7) // Forest 100
                                  : const Color(0xFFE0E0E0), // Grey 100
                              shape: StadiumBorder(side: BorderSide(color: Colors.black12)),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                            ),
                          ),
                        ),
                      ),
                      // CHECKPOINTS column
                      DataCell(
                        Container(
                          decoration: cellDecoration,
                          padding: cellPadding,
                          child: StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('editions')
                                    .doc(widget.edicaoId)
                                    .collection('events')
                                    .doc(doc.id)
                                    .collection('checkpoints')
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Text('...');
                              }
                              return Chip(
                                label: Text(
                                  '${snapshot.data!.docs.length}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: const Color(0xFFF5F5F5), // Shell Grey 50
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                              );
                            },
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            // Adicionar checkpoints
                            IconButton(
                              icon: const Icon(
                                Icons.playlist_add,
                                color: AppColors.secondaryDark,
                              ),
                              tooltip: 'Adicionar checkpoints',
                              onPressed: () {
                                Get.toNamed(
                                  '/add-checkpoints',
                                  arguments: {
                                    'edicaoId': widget.edicaoId,
                                    'eventId': doc.id,
                                  },
                                );
                              },
                            ),
                            // Ver checkpoints
                            IconButton(
                              icon: const Icon(
                                Icons.list_alt,
                                color: AppColors.secondary,
                              ),
                              tooltip: 'Ver checkpoints',
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
                            ),
                            /*
                            IconButton(
                              icon: const Icon(
                                Icons.map,
                                color: AppColors.primary,
                              ),
                              tooltip: 'Ver percurso',
                              onPressed: () {
                                final data =
                                    doc.data() as Map<String, dynamic>;
                                final percurso =
                                    (data['percurso'] as List<dynamic>? ??
                                            [])
                                        .cast<Map<String, dynamic>>();
                                final checkpoints =
                                    (data['checkpoints']
                                            as Map<String, dynamic>? ??
                                        {});
                                final Map<String, String> checkpointLabels =
                                    {};
                                checkpoints.forEach((postoId, postoData) {
                                  if (postoData is Map<String, dynamic> &&
                                      postoData['name'] != null) {
                                    checkpointLabels[postoId] =
                                        postoData['name'].toString();
                                  }
                                });
                                Get.toNamed(
                                  '/route-map',
                                  arguments: {
                                    'eventId': doc.id,
                                    'percurso': percurso,
                                    'checkpoints': checkpoints,
                                    'checkpointLabels': checkpointLabels,
                                  },
                                );
                              },
                            ),
                            */
                            // Editar evento
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: AppColors.secondaryDark,
                              ),
                              tooltip: 'Editar evento',
                              onPressed: () {
                                showEditEventDialog(context, doc);
                              },
                            ),
                            // Eliminar evento (com confirmação)
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              tooltip: 'Eliminar evento',
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (ctx) => AlertDialog(
                                        title: const Text('Confirmação'),
                                        content: const Text(
                                          'Deseja realmente eliminar este evento?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  ctx,
                                                  false,
                                                ),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  ctx,
                                                  true,
                                                ),
                                            child: const Text('Eliminar'),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirmed == true) {
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
                                  await doc.reference.delete();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        );
      },
    ),
  ),
),
floatingActionButton: FloatingActionButton(
  tooltip: 'Adicionar Evento',
  onPressed: _showAddEventDialog,
  backgroundColor: const Color(0xFFDD1D21), // Shell Red
  child: const Icon(Icons.add, color: Colors.white),
),
floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Novo Evento',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.black),
            ),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Descrição do evento',
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? 'Informe a descrição'
                                  : null,
                    ),
                    TextFormField(
                      controller: _entidadeController,
                      decoration: const InputDecoration(
                        labelText: 'Entidade',
                        hintText: 'Entidade responsável',
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? 'Informe a entidade'
                                  : null,
                    ),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        hintText: 'Título do evento',
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? 'Informe o título'
                                  : null,
                    ),
                    TextFormField(
                      controller: _localController,
                      decoration: const InputDecoration(
                        labelText: 'Local',
                        hintText: 'Ex: Parque, ginásio...',
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                      validator:
                          (v) =>
                              v == null || v.isEmpty ? 'Informe o local' : null,
                    ),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Preço',
                        hintText: 'Ex: 25.00',
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                      keyboardType: TextInputType.number,
                      validator:
                          (v) =>
                              v == null || v.isEmpty ? 'Informe o preço' : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Data e Hora:',
                          style: TextStyle(color: Colors.black),
                        ),
                        TextButton(
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
                          child: Text(
                            _selectedDate == null
                                ? 'Selecionar'
                                : DateFormat(
                                  'dd/MM/yyyy – HH:mm',
                                ).format(_selectedDate!),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text(
                          'Ativo:',
                          style: TextStyle(color: Colors.black),
                        ),
                        Switch(
                          value: _status,
                          onChanged: (v) => setState(() => _status = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDD1D21), // Shell Red
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (_formKey.currentState?.validate() != true ||
                      _selectedDate == null) {
                    return;
                  }
                  await FirebaseFirestore.instance
                      .collection('editions')
                      .doc(widget.edicaoId)
                      .collection('events')
                      .add({
                        'nome': _nameController.text.trim(),
                        'local': _localController.text.trim(),
                        'price':
                            double.tryParse(_priceController.text.trim()) ?? 0,
                        'data': Timestamp.fromDate(_selectedDate!),
                        'status': _status,
                        'descricao': _descricaoController.text.trim(),
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
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
    );
  }

  void showEditEventDialog(BuildContext context, DocumentSnapshot doc) {
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
                (context, setState) => AlertDialog(
                  title: const Text('Editar Evento'),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: descricaoController,
                            decoration: const InputDecoration(
                              labelText: 'Descrição',
                              hintText: 'Descrição do evento',
                              labelStyle: TextStyle(color: Colors.black87),
                            ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black87),
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? 'Informe a descrição'
                                        : null,
                          ),
                          TextFormField(
                            controller: entidadeController,
                            decoration: const InputDecoration(
                              labelText: 'Entidade',
                              hintText: 'Entidade responsável',
                              labelStyle: TextStyle(color: Colors.black87),
                            ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black87),
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? 'Informe a entidade'
                                        : null,
                          ),
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Título',
                              hintText: 'Título do evento',
                              labelStyle: TextStyle(color: Colors.black87),
                            ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black87),
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? 'Informe o título'
                                        : null,
                          ),
                          TextFormField(
                            controller: localController,
                            decoration: const InputDecoration(
                              labelText: 'Local',
                              hintText: 'Ex: Parque, ginásio...',
                              labelStyle: TextStyle(color: Colors.black87),
                            ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black87),
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? 'Informe o local'
                                        : null,
                          ),
                          TextFormField(
                            controller: priceController,
                            decoration: const InputDecoration(
                              labelText: 'Preço',
                              hintText: 'Ex: 25.00',
                              labelStyle: TextStyle(color: Colors.black87),
                            ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black87),
                            keyboardType: TextInputType.number,
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? 'Informe o preço'
                                        : null,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Data e Hora:'),
                              TextButton(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (!context.mounted || date == null) return;
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(
                                      selectedDate ?? DateTime.now(),
                                    ),
                                  );
                                  if (!context.mounted || time == null) return;
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
                                child: Text(
                                  selectedDate == null
                                      ? 'Selecionar'
                                      : DateFormat(
                                        'dd/MM/yyyy – HH:mm',
                                      ).format(selectedDate!),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text('Ativo:'),
                              Switch(
                                value: status,
                                onChanged: (v) => setState(() => status = v),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState?.validate() != true ||
                            selectedDate == null) {
                          return;
                        }
                        await doc.reference.update({
                          'nome': nameController.text.trim(),
                          'local': localController.text.trim(),
                          'price':
                              double.tryParse(priceController.text.trim()) ?? 0,
                          'data': Timestamp.fromDate(selectedDate!),
                          'status': status,
                          'descricao': descricaoController.text.trim(),
                          'entidade': entidadeController.text.trim(),
                        });
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
          ),
    );
  }
}
