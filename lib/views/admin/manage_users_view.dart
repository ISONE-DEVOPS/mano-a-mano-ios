import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageUsersView extends StatelessWidget {
  ManageUsersView({super.key});

  final ValueNotifier<String> _searchQuery = ValueNotifier('');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Gestão de Utilizadores'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Pesquisar utilizador...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => _searchQuery.value = value.toLowerCase(),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: _searchQuery,
              builder: (context, query, _) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final users = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final nome = data['nome']?.toString().toLowerCase() ?? '';
                      final email = data['email']?.toString().toLowerCase() ?? '';
                      return nome.contains(query) || email.contains(query);
                    }).toList();

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Nome')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Tipo')),
                          DataColumn(label: Text('Ações')),
                        ],
                        rows: users.map((doc) {
                          final data = doc.data() as Map<String, dynamic>? ?? {};
                          return DataRow(
                            cells: [
                              DataCell(Text(data['nome'] ?? '')),
                              DataCell(Text(data['email'] ?? '')),
                              DataCell(Text(data['tipo'] ?? '')),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      final nameController = TextEditingController(text: data['nome']);
                                      final emailController = TextEditingController(text: data['email']);
                                      String tipo = data['tipo'];

                                      showDialog(
                                        context: context,
                                        builder: (_) {
                                          return AlertDialog(
                                            title: const Text('Editar Utilizador'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: nameController,
                                                  decoration: const InputDecoration(labelText: 'Nome'),
                                                ),
                                                TextField(
                                                  controller: emailController,
                                                  decoration: const InputDecoration(labelText: 'Email'),
                                                ),
                                                StatefulBuilder(
                                                  builder: (context, setState) {
                                                    return DropdownButton<String>(
                                                      value: tipo,
                                                      onChanged: (value) {
                                                        if (value != null) {
                                                          setState(() => tipo = value);
                                                        }
                                                      },
                                                      items: ['admin', 'user'].map((role) {
                                                        return DropdownMenuItem(value: role, child: Text(role));
                                                      }).toList(),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancelar'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  await doc.reference.update({
                                                    'nome': nameController.text,
                                                    'email': emailController.text,
                                                    'tipo': tipo,
                                                  });
                                                  if (context.mounted) Navigator.pop(context);
                                                },
                                                child: const Text('Salvar'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) {
                                          return AlertDialog(
                                            title: const Text('Remover Utilizador'),
                                            content: const Text('Tem certeza que deseja apagar este utilizador?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancelar'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  await doc.reference.delete();
                                                  if (context.mounted) Navigator.pop(context);
                                                },
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                child: const Text('Apagar', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}