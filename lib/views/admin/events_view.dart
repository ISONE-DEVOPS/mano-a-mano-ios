import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';
import 'package:mano_mano_dashboard/views/admin/checkpoints_list_dialog.dart';

class EventsView extends StatefulWidget {
  const EventsView({super.key});

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
  final bool _sortAsc = true;
  final int _sortColumnIndex = 0;

  final _nameController = TextEditingController();
  final _localController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime? _selectedDate;
  bool _status = true;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar removido — top bar já vem do AdminView
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('events')
                  .where('status', isEqualTo: true)
                  .orderBy('data_event', descending: !_sortAsc)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  AppColors.secondaryDark.withAlpha(50),
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
                rows:
                    docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final dataEvento =
                          (data['data_event'] as Timestamp?)?.toDate();
                      final dataTexto =
                          dataEvento != null
                              ? DateFormat(
                                'dd/MM/yyyy – HH:mm',
                              ).format(dataEvento)
                              : '';
                      final borderSide = BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      );
                      final cellDecoration = BoxDecoration(
                        border: Border(bottom: borderSide),
                      );
                      const cellPadding = EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      );
                      return DataRow(
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
                              child: Text(
                                data['price'] != null
                                    ? '${NumberFormat('#,##0', 'pt_CV').format(data['price'])} ECV'
                                    : '',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.black87),
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
                                      arguments: doc.id,
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
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => CheckpointsListDialog(eventId: doc.id),
                                    );
                                  },
                                ),
                                // Ver percurso
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
                                      await doc.reference.delete();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Adicionar Evento',
        onPressed: _showAddEventDialog,
        backgroundColor: AppColors.secondaryDark,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.surface,
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
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  if (_formKey.currentState?.validate() != true ||
                      _selectedDate == null) {
                    return;
                  }
                  await FirebaseFirestore.instance.collection('events').add({
                    'nome': _nameController.text.trim(),
                    'local': _localController.text.trim(),
                    'price': double.tryParse(_priceController.text.trim()) ?? 0,
                    'data_event': _selectedDate,
                    'status': _status,
                    'percurso': <Map<String, dynamic>>[],
                    'checkpoints': <Map<String, dynamic>>[],
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  _nameController.clear();
                  _localController.clear();
                  _priceController.clear();
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
    DateTime? selectedDate =
        (data['data_event'] as Timestamp?)?.toDate() ?? DateTime.now();
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
                          'data_event': selectedDate,
                          'status': status,
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
