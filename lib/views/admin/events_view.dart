import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      appBar: AppBar(title: const Text('Gestão de Eventos'), actions: []),
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
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                sortAscending: _sortAsc,
                sortColumnIndex: _sortColumnIndex,
                columns: [
                  const DataColumn(label: Text('DATA')),
                  const DataColumn(label: Text('TÍTULO')),
                  const DataColumn(label: Text('LOCAL')),
                  const DataColumn(label: Text('PREÇO')),
                  const DataColumn(label: Text('AÇÕES / PERCURSO')),
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
                      return DataRow(
                        cells: [
                          DataCell(Text(dataTexto)),
                          DataCell(Text(data['nome'] ?? '')),
                          DataCell(Text(data['local'] ?? '')),
                          DataCell(Text('${data['price'] ?? ''}')),
                          DataCell(
                            Row(
                              children: [
                                // Adicionar checkpoints
                                IconButton(
                                  icon: const Icon(
                                    Icons.playlist_add,
                                    color: Colors.teal,
                                  ),
                                  tooltip: 'Adicionar checkpoints',
                                  onPressed: () {
                                    // Aqui você pode abrir um diálogo ou redirecionar para uma nova tela
                                    Get.toNamed(
                                      '/add-checkpoints',
                                      arguments: doc.id,
                                    );
                                  },
                                ),
                                // Ver percurso
                                IconButton(
                                  icon: const Icon(
                                    Icons.map,
                                    color: Colors.blue,
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
                                    // Montar infoWindowText para cada checkpoint
                                    // Exemplo de estrutura esperada: {postoId: {name: 'Posto A', ...}}
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
                                    color: Colors.orange,
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
        backgroundColor: Colors.black,
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
            title: const Text('Novo Evento'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Título'),
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? 'Informe o título'
                                  : null,
                    ),
                    TextFormField(
                      controller: _localController,
                      decoration: const InputDecoration(labelText: 'Local'),
                      validator:
                          (v) =>
                              v == null || v.isEmpty ? 'Informe o local' : null,
                    ),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Preço'),
                      keyboardType: TextInputType.number,
                      validator:
                          (v) =>
                              v == null || v.isEmpty ? 'Informe o preço' : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Data e Hora:'),
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
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Ativo:'),
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
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
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
                            ),
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
                            ),
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
                            ),
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
