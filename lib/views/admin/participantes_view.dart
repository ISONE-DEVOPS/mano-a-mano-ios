import 'package:flutter/material.dart';
import 'edit_participantes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;

class ParticipantesView extends StatefulWidget {
  const ParticipantesView({super.key});

  @override
  State<ParticipantesView> createState() => _ParticipantesViewState();
}

class _ParticipantesViewState extends State<ParticipantesView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterRole = 'Todos';
  String _filterTshirt = 'Todos';
  String _filterGrupo = 'Todos';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho com filtros e pesquisa
            _buildHeader(),

            // Conteúdo principal
            Expanded(child: _buildParticipantesList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Título
          const Text(
            'Gestão de Participantes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // Barra de pesquisa
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Pesquisar participantes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.grey.shade100,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filtros e botões de ação
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              // Filtro por Papel
              Container(
                constraints: const BoxConstraints(minWidth: 120),
                child: DropdownButtonFormField<String>(
                  value: _filterRole,
                  decoration: InputDecoration(
                    labelText: 'Papel',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items:
                      ['Todos', 'admin', 'user', 'staff'].map((role) {
                        return DropdownMenuItem(value: role, child: Text(role));
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterRole = value!;
                    });
                  },
                ),
              ),

              // Filtro por T-Shirt
              Container(
                constraints: const BoxConstraints(minWidth: 120),
                child: DropdownButtonFormField<String>(
                  value: _filterTshirt,
                  decoration: InputDecoration(
                    labelText: 'T-Shirt',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items:
                      ['Todos', 'XS', 'S', 'M', 'L', 'XL', 'XXL'].map((size) {
                        return DropdownMenuItem(value: size, child: Text(size));
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterTshirt = value!;
                    });
                  },
                ),
              ),

              // Filtro por Grupo
              Container(
                constraints: const BoxConstraints(minWidth: 120),
                child: DropdownButtonFormField<String>(
                  value: _filterGrupo,
                  decoration: InputDecoration(
                    labelText: 'Grupo',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items:
                      ['Todos', 'A', 'B'].map((grupo) {
                        return DropdownMenuItem(
                          value: grupo,
                          child: Text(
                            grupo == 'Todos' ? grupo : 'Grupo $grupo',
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterGrupo = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botões de ação
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/register-participant');
                },
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Novo Participante'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),

              ElevatedButton.icon(
                onPressed: _exportParticipantesCsv,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Exportar CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),

              ElevatedButton.icon(
                onPressed: _exportListaCompleta,
                icon: const Icon(Icons.groups, size: 18),
                label: const Text('Lista Completa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),

              ElevatedButton.icon(
                onPressed: _showBulkActions,
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('Ações em Lote'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantesList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .orderBy('createdAt', descending: false)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhum participante encontrado',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data!.docs;
        final filteredUsers = _filterUsers(users);

        return Column(
          children: [
            // Contador de resultados
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${filteredUsers.length} participante(s) encontrado(s)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),

            // Lista de participantes
            Expanded(
              child:
                  filteredUsers.isEmpty
                      ? const Center(
                        child: Text(
                          'Nenhum participante corresponde aos filtros',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final doc = filteredUsers[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildParticipanteCard(doc, data);
                        },
                      ),
            ),
          ],
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _filterUsers(List<QueryDocumentSnapshot> users) {
    return users.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // Filtro por pesquisa
      if (_searchQuery.isNotEmpty) {
        final nome = (data['nome'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        final telefone = (data['telefone'] ?? '').toString().toLowerCase();

        if (!nome.contains(_searchQuery) &&
            !email.contains(_searchQuery) &&
            !telefone.contains(_searchQuery)) {
          return false;
        }
      }

      // Filtro por papel
      if (_filterRole != 'Todos') {
        final role = data['role'] ?? 'user';
        if (role != _filterRole) {
          return false;
        }
      }

      // Filtro por t-shirt
      if (_filterTshirt != 'Todos') {
        final tshirt = data['tshirt'] ?? '';
        if (tshirt != _filterTshirt) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _buildParticipanteCard(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do card
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (data['nome'] ?? 'U')
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Informações principais
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            data['nome'] ?? 'Nome não informado',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildRoleBadge(data['role'] ?? 'user'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['email'] ?? 'Email não informado',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu de ações
                PopupMenuButton<String>(
                  onSelected: (value) => _handleAction(value, doc, data),
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: ListTile(
                            leading: Icon(Icons.edit, color: Colors.orange),
                            title: Text('Editar Participante'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'veiculo',
                          child: ListTile(
                            leading: Icon(
                              Icons.directions_car,
                              color: Colors.green,
                            ),
                            title: Text('Editar Veículo'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'acompanhantes',
                          child: ListTile(
                            leading: Icon(Icons.group, color: Colors.blue),
                            title: Text('Editar Acompanhantes'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'equipa',
                          child: ListTile(
                            leading: Icon(Icons.groups, color: Colors.purple),
                            title: Text('Editar Equipa'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'detalhes',
                          child: ListTile(
                            leading: Icon(Icons.info, color: Colors.deepPurple),
                            title: Text('Ver Detalhes'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'qr',
                          child: ListTile(
                            leading: Icon(Icons.qr_code, color: Colors.indigo),
                            title: Text('Gerar QR Code'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'eliminar',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Eliminar'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Informações detalhadas
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  Icons.phone,
                  data['telefone'] ?? 'Sem telefone',
                  Colors.blue,
                ),
                _buildInfoChip(
                  Icons.local_offer,
                  'T-Shirt: ${data['tshirt'] ?? 'N/A'}',
                  Colors.green,
                ),
                if (data['emergencia'] != null &&
                    data['emergencia'].toString().isNotEmpty)
                  _buildInfoChip(
                    Icons.emergency,
                    'Emergência: ${data['emergencia']}',
                    Colors.red,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Informações de equipa e veículo
            Row(
              children: [
                Expanded(child: _buildEquipaInfo(data)),
                const SizedBox(width: 16),
                Expanded(child: _buildVeiculoInfo(data)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    String label;

    switch (role) {
      case 'admin':
        color = Colors.red;
        label = 'Admin';
        break;
      case 'staff':
        color = Colors.orange;
        label = 'Staff';
        break;
      default:
        color = Colors.blue;
        label = 'Participante';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: (color is MaterialColor ? color.shade700 : color),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipaInfo(Map<String, dynamic> data) {
    return FutureBuilder<DocumentSnapshot?>(
      future: _getEquipaInfo(data['equipaId']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Carregando equipa...',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          );
        }

        if (snapshot.data == null || !snapshot.data!.exists) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Sem equipa',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          );
        }

        final equipa = snapshot.data!.data() as Map<String, dynamic>;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Equipa: ${equipa['nome'] ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (equipa['grupo'] != null)
                Text(
                  'Grupo: ${equipa['grupo']}',
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVeiculoInfo(Map<String, dynamic> data) {
    return FutureBuilder<DocumentSnapshot?>(
      future: _getVeiculoInfo(data['veiculoId']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Carregando veículo...',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          );
        }

        if (snapshot.data == null || !snapshot.data!.exists) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Sem veículo',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          );
        }

        final veiculo = snapshot.data!.data() as Map<String, dynamic>;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${veiculo['marca'] ?? ''} ${veiculo['modelo'] ?? ''}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'Matrícula: ${veiculo['matricula'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 11, color: Colors.black87),
              ),
              if (veiculo['distico'] != null)
                Text(
                  'Distíco: ${veiculo['distico']}',
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<DocumentSnapshot?> _getEquipaInfo(String? equipaId) async {
    if (equipaId == null || equipaId.isEmpty) return null;
    try {
      return await FirebaseFirestore.instance
          .collection('equipas')
          .doc(equipaId)
          .get();
    } catch (e) {
      return null;
    }
  }

  Future<DocumentSnapshot?> _getVeiculoInfo(String? veiculoId) async {
    if (veiculoId == null || veiculoId.isEmpty) return null;
    try {
      return await FirebaseFirestore.instance
          .collection('veiculos')
          .doc(veiculoId)
          .get();
    } catch (e) {
      return null;
    }
  }

  void _handleAction(
    String action,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    switch (action) {
      case 'editar':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EditParticipantesView(userId: doc.id),
          ),
        );
        break;
      case 'veiculo':
        _editarVeiculo(context, data);
        break;
      case 'acompanhantes':
        _editarAcompanhantes(context, data);
        break;
      case 'equipa':
        _editarEquipa(context, data);
        break;
      case 'detalhes':
        _verDetalhes(context, data);
        break;
      case 'qr':
        _gerarQrCode(context, doc.id, data);
        break;
      case 'eliminar':
        _eliminarParticipante(context, doc, data);
        break;
    }
  }

  // Método para editar equipa
  void _editarEquipa(BuildContext context, Map<String, dynamic> data) async {
    final equipaId = data['equipaId'];
    if (equipaId == null || equipaId.toString().trim().isEmpty) {
      _showInfoDialog(
        context,
        'Editar Equipa',
        'Participante não possui equipa definida.',
      );
      return;
    }

    final equipaDoc =
        await FirebaseFirestore.instance
            .collection('equipas')
            .doc(equipaId)
            .get();

    if (!context.mounted) return;

    if (!equipaDoc.exists) {
      _showInfoDialog(context, 'Editar Equipa', 'Equipa não encontrada.');
      return;
    }

    final equipa = equipaDoc.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (ctx) {
        final nomeController = TextEditingController(
          text: equipa['nome'] ?? '',
        );
        final hinoController = TextEditingController(
          text: equipa['hino'] ?? '',
        );
        String? selectedGrupo = equipa['grupo'];

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Editar Equipa',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Equipa',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: hinoController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Hino/Grito de Guerra',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedGrupo,
                      decoration: const InputDecoration(
                        labelText: 'Grupo',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          ['A', 'B'].map((grupo) {
                            return DropdownMenuItem(
                              value: grupo,
                              child: Text('Grupo $grupo'),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedGrupo = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('equipas')
                        .doc(equipaId)
                        .update({
                          'nome': nomeController.text,
                          'hino': hinoController.text,
                          'grupo': selectedGrupo,
                        });

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      _showSuccessSnackBar(
                        context,
                        'Equipa atualizada com sucesso',
                      );
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Método para gerar QR Code
  void _gerarQrCode(
    BuildContext context,
    String userId,
    Map<String, dynamic> data,
  ) {
    final Map<String, dynamic> qrData = {
      'userId': userId,
      'nome': data['nome'],
      'email': data['email'],
      'type': 'participant',
    };

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('QR Code do Participante'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text(qrData.toString())),
                ),
                const SizedBox(height: 16),
                Text(
                  'QR Code para: ${data['nome']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: $userId',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fechar'),
              ),
              ElevatedButton(
                onPressed: () {
                  _showSuccessSnackBar(context, 'QR Code gerado com sucesso');
                },
                child: const Text('Baixar'),
              ),
            ],
          ),
    );
  }

  // Método para mostrar ações em lote
  void _showBulkActions() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Ações em Lote',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.blue),
                  title: const Text('Enviar emails em lote'),
                  subtitle: const Text(
                    'Enviar informações para todos os participantes',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _enviarEmailsLote();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code, color: Colors.green),
                  title: const Text('Gerar QR Codes em lote'),
                  subtitle: const Text(
                    'Gerar QR codes para todos os participantes',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _gerarQrCodesLote();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.groups, color: Colors.orange),
                  title: const Text('Redistribuir grupos'),
                  subtitle: const Text(
                    'Reorganizar participantes em grupos A e B',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _redistribuirGrupos();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_offer, color: Colors.purple),
                  title: const Text('Atualizar T-Shirts'),
                  subtitle: const Text('Atualizar tamanhos de T-Shirt em lote'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _atualizarTshirtsLote();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  // Métodos de ações em lote
  void _enviarEmailsLote() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Enviar Emails em Lote'),
            content: const Text(
              'Deseja enviar um email com as informações do evento para todos os participantes?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Enviar'),
              ),
            ],
          ),
    );

    if (result == true) {
      if (!mounted) return;
      _showSuccessSnackBar(context, 'Emails enviados com sucesso');
    }
  }

  // Método para gerar QR Codes em lote
  void _gerarQrCodesLote() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Gerar QR Codes em Lote'),
            content: const Text(
              'Deseja gerar QR codes para todos os participantes? Isso pode demorar alguns minutos.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Gerar'),
              ),
            ],
          ),
    );

    if (result == true) {
      if (!mounted) return;
      _showSuccessSnackBar(context, 'QR Codes gerados com sucesso');
    }
  }

  void _redistribuirGrupos() {
    showDialog(
      context: context,
      builder: (ctx) {
        String criterio = 'automatico';

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Redistribuir Grupos'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Escolha o critério para redistribuição:'),
                  const SizedBox(height: 16),
                  RadioListTile<String>(
                    title: const Text('Automático (Equilibrado)'),
                    subtitle: const Text(
                      'Distribui automaticamente de forma equilibrada',
                    ),
                    value: 'automatico',
                    groupValue: criterio,
                    onChanged: (value) {
                      setState(() {
                        criterio = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Por Ordem de Inscrição'),
                    subtitle: const Text('Alterna A-B pela ordem de inscrição'),
                    value: 'ordem',
                    groupValue: criterio,
                    onChanged: (value) {
                      setState(() {
                        criterio = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Aleatório'),
                    subtitle: const Text('Distribui aleatoriamente'),
                    value: 'aleatorio',
                    groupValue: criterio,
                    onChanged: (value) {
                      setState(() {
                        criterio = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _executarRedistribuicao(criterio);
                  },
                  child: const Text('Redistribuir'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Método para atualizar T-Shirts em lote (localizado)
  void _atualizarTshirtsLote() {
    showDialog(
      context: context,
      builder: (ctx) {
        final Map<String, int> contadores = {
          'XS': 0,
          'S': 0,
          'M': 0,
          'L': 0,
          'XL': 0,
          'XXL': 0,
        };

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Atualizar T-Shirts em Lote'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Defina a quantidade por tamanho:'),
                    const SizedBox(height: 16),
                    ...contadores.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '0',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    contadores[entry.key] =
                                        int.tryParse(value) ?? 0;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _executarAtualizacaoTshirts(contadores);
                  },
                  child: const Text('Atualizar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executarRedistribuicao(String criterio) async {
    try {
      final equipasSnapshot =
          await FirebaseFirestore.instance.collection('equipas').get();

      final equipas = equipasSnapshot.docs;

      for (int i = 0; i < equipas.length; i++) {
        String novoGrupo;

        switch (criterio) {
          case 'automatico':
          case 'ordem':
            novoGrupo = i % 2 == 0 ? 'A' : 'B';
            break;
          case 'aleatorio':
            novoGrupo = ['A', 'B'][DateTime.now().millisecond % 2];
            break;
          default:
            novoGrupo = 'A';
        }

        await equipas[i].reference.update({'grupo': novoGrupo});
      }

      if (mounted) {
        _showSuccessSnackBar(context, 'Grupos redistribuídos com sucesso');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, 'Erro ao redistribuir grupos: $e');
      }
    }
  }

  Future<void> _executarAtualizacaoTshirts(Map<String, int> contadores) async {
    _showSuccessSnackBar(context, 'T-Shirts atualizadas com sucesso');
  }

  // Método para editar acompanhantes
  void _editarAcompanhantes(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final veiculoId = data['veiculoId'];
    if (veiculoId == null || veiculoId.toString().trim().isEmpty) {
      _showInfoDialog(context, 'Acompanhantes', 'ID do veículo não definido.');
      return;
    }

    final veiculoDoc =
        await FirebaseFirestore.instance
            .collection('veiculos')
            .doc(veiculoId)
            .get();
    if (!context.mounted) return;

    final veiculo = veiculoDoc.data();
    final acompanhantes = veiculo?['passageiros'] ?? [];

    showDialog(
      context: context,
      builder: (_) {
        final List<TextEditingController> nomeControllers = List.generate(
          acompanhantes.length,
          (i) => TextEditingController(text: acompanhantes[i]['nome'] ?? ''),
        );
        final List<TextEditingController> telefoneControllers = List.generate(
          acompanhantes.length,
          (i) =>
              TextEditingController(text: acompanhantes[i]['telefone'] ?? ''),
        );
        final List<TextEditingController> tshirtControllers = List.generate(
          acompanhantes.length,
          (i) => TextEditingController(text: acompanhantes[i]['tshirt'] ?? ''),
        );

        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Editar Acompanhantes',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: SizedBox(
            width: 500,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    acompanhantes.isEmpty
                        ? [
                          const Text(
                            'Nenhum acompanhante cadastrado.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                        ]
                        : List.generate(acompanhantes.length, (index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Acompanhante ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: nomeControllers[index],
                                  decoration: const InputDecoration(
                                    labelText: 'Nome',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: telefoneControllers[index],
                                  decoration: const InputDecoration(
                                    labelText: 'Telefone',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value:
                                      (tshirtControllers[index]
                                                  .text
                                                  .isNotEmpty &&
                                              [
                                                'XS',
                                                'S',
                                                'M',
                                                'L',
                                                'XL',
                                                'XXL',
                                              ].contains(
                                                tshirtControllers[index].text,
                                              ))
                                          ? tshirtControllers[index].text
                                          : null,
                                  decoration: const InputDecoration(
                                    labelText: 'Tamanho T-Shirt',
                                    border: OutlineInputBorder(),
                                  ),
                                  items:
                                      ['XS', 'S', 'M', 'L', 'XL', 'XXL'].map((
                                        String value,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      tshirtControllers[index].text = newValue;
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
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
                final updated = List.generate(acompanhantes.length, (index) {
                  return {
                    'nome': nomeControllers[index].text,
                    'telefone': telefoneControllers[index].text,
                    'tshirt': tshirtControllers[index].text,
                  };
                });
                await FirebaseFirestore.instance
                    .collection('veiculos')
                    .doc(veiculoId)
                    .update({'passageiros': updated});
                if (context.mounted) {
                  Navigator.pop(context);
                  _showSuccessSnackBar(
                    context,
                    'Acompanhantes atualizados com sucesso',
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  // Método para editar veículo
  void _editarVeiculo(BuildContext context, Map<String, dynamic> data) async {
    final veiculoId = data['veiculoId'];
    if (veiculoId == null) return;

    final veiculoDoc =
        await FirebaseFirestore.instance
            .collection('veiculos')
            .doc(veiculoId)
            .get();
    if (!context.mounted) return;

    final veiculo = veiculoDoc.data();
    final equipaId = data['equipaId'];
    DocumentSnapshot? equipaDoc;
    Map<String, dynamic>? equipa;

    if (equipaId != null && equipaId.toString().isNotEmpty) {
      equipaDoc =
          await FirebaseFirestore.instance
              .collection('equipas')
              .doc(equipaId)
              .get();
      if (!context.mounted) return;
      if (equipaDoc.exists) {
        equipa = equipaDoc.data() as Map<String, dynamic>?;
      }
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        final modeloController = TextEditingController(
          text: veiculo?['modelo'] ?? '',
        );
        final disticoController = TextEditingController(
          text: veiculo?['distico'] ?? '',
        );
        String? selectedGrupo =
            (equipa != null &&
                    equipa['grupo'] != null &&
                    ['A', 'B'].contains(equipa['grupo']))
                ? equipa['grupo'] as String
                : null;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Editar Veículo',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content:
                  veiculo == null
                      ? const Text('Veículo não encontrado.')
                      : SizedBox(
                        width: 400,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Informações do Veículo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('Marca: ${veiculo['marca'] ?? 'N/A'}'),
                                  Text(
                                    'Matrícula: ${veiculo['matricula'] ?? 'N/A'}',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: modeloController,
                              decoration: const InputDecoration(
                                labelText: 'Modelo',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: disticoController,
                              decoration: const InputDecoration(
                                labelText: 'Distíco',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: selectedGrupo,
                              decoration: const InputDecoration(
                                labelText: 'Grupo',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  ['A', 'B'].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text('Grupo $value'),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedGrupo = newValue;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('veiculos')
                        .doc(veiculoId)
                        .update({
                          'modelo': modeloController.text,
                          'distico': disticoController.text,
                          'grupo': selectedGrupo,
                        });
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      _showSuccessSnackBar(
                        context,
                        'Veículo atualizado com sucesso',
                      );
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Método para ver detalhes
  void _verDetalhes(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Detalhes do Participante',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: SizedBox(
              width: 500,
              height: 600,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection('Informações Pessoais', [
                      'Nome: ${data['nome'] ?? 'N/A'}',
                      'Email: ${data['email'] ?? 'N/A'}',
                      'Telefone: ${data['telefone'] ?? 'N/A'}',
                      'Emergência: ${data['emergencia'] ?? 'N/A'}',
                      'T-Shirt: ${data['tshirt'] ?? 'N/A'}',
                      'Papel: ${data['role'] ?? 'user'}',
                    ], Colors.blue),
                    const SizedBox(height: 16),
                    _buildEquipaDetailSection(data['equipaId']),
                    const SizedBox(height: 16),
                    _buildVeiculoDetailSection(data['veiculoId']),
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailSection(String title, List<String> items, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha((0.3 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: (color is MaterialColor ? color.shade700 : color),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                item,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipaDetailSection(String? equipaId) {
    if (equipaId == null || equipaId.isEmpty) {
      return _buildDetailSection('Informações da Equipa', [
        'Equipa não definida',
      ], Colors.grey);
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('equipas').doc(equipaId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildDetailSection('Informações da Equipa', [
            'Equipa não encontrada',
          ], Colors.red);
        }

        final equipa = snapshot.data!.data() as Map<String, dynamic>;
        return _buildDetailSection('Informações da Equipa', [
          'Nome: ${equipa['nome'] ?? 'N/A'}',
          'Hino: ${equipa['hino'] ?? 'N/A'}',
          'Grupo: ${equipa['grupo'] ?? 'N/A'}',
          'Pontuação Total: ${equipa['pontuacaoTotal'] ?? 0}',
        ], Colors.green);
      },
    );
  }

  Widget _buildVeiculoDetailSection(String? veiculoId) {
    if (veiculoId == null || veiculoId.isEmpty) {
      return _buildDetailSection('Informações do Veículo', [
        'Veículo não definido',
      ], Colors.grey);
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('veiculos')
              .doc(veiculoId)
              .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildDetailSection('Informações do Veículo', [
            'Veículo não encontrado',
          ], Colors.red);
        }

        final veiculo = snapshot.data!.data() as Map<String, dynamic>;
        final acompanhantes = veiculo['passageiros'] ?? [];
        final acompanhantesText =
            acompanhantes.isNotEmpty
                ? acompanhantes
                    .map((p) => '${p['nome'] ?? ''} (${p['tshirt'] ?? ''})')
                    .join(', ')
                : 'Nenhum acompanhante';

        return _buildDetailSection('Informações do Veículo', [
          'Marca: ${veiculo['marca'] ?? 'N/A'}',
          'Modelo: ${veiculo['modelo'] ?? 'N/A'}',
          'Matrícula: ${veiculo['matricula'] ?? 'N/A'}',
          'Distíco: ${veiculo['distico'] ?? 'N/A'}',
          'Grupo: ${veiculo['grupo'] ?? 'N/A'}',
          'Acompanhantes: $acompanhantesText',
        ], Colors.orange);
      },
    );
  }

  // Método para eliminar participante
  void _eliminarParticipante(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Eliminar Participante',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Tem certeza que deseja eliminar ${data['nome']}?'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Esta ação irá eliminar:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('• O participante'),
                      Text('• O veículo associado'),
                      Text('• A equipa (se não tiver outros membros)'),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        final userId = doc.id;
        final veiculoId = data['veiculoId'];
        final equipaId = data['equipaId'];

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .delete();

        if (veiculoId != null) {
          await FirebaseFirestore.instance
              .collection('veiculos')
              .doc(veiculoId)
              .delete();
        }

        if (equipaId != null) {
          final equipaUsada =
              await FirebaseFirestore.instance
                  .collection('users')
                  .where('equipaId', isEqualTo: equipaId)
                  .get();

          if (equipaUsada.docs.length <= 1) {
            await FirebaseFirestore.instance
                .collection('equipas')
                .doc(equipaId)
                .delete();
          }
        }

        if (context.mounted) {
          _showSuccessSnackBar(context, 'Participante eliminado com sucesso');
        }
      } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar(context, 'Erro ao eliminar participante: $e');
        }
      }
    }
  }

  // Métodos de exportação
  Future<void> _exportParticipantesCsv() async {
    try {
      final equipasSnapshot =
          await FirebaseFirestore.instance.collection('equipas').get();
      final Map<String, String> equipas = {
        for (var doc in equipasSnapshot.docs) doc.id: doc['nome'] ?? '',
      };

      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final buffer = StringBuffer();
      buffer.writeln('Nome,Email,Telefone,Emergência,T-Shirt,Equipa');

      for (var doc in snapshot.docs) {
        final d = doc.data();
        buffer.writeln(
          [
            d['nome'] ?? '',
            d['email'] ?? '',
            d['telefone'] ?? '',
            d['emergencia'] ?? '',
            d['tshirt'] ?? '',
            equipas[d['equipaId']] ?? '',
          ].map((v) => '"${v.toString().replaceAll('"', '""')}"').join(','),
        );
      }

      final bytes = utf8.encode(buffer.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'participantes.csv')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        _showSuccessSnackBar(context, 'CSV exportado com sucesso');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, 'Erro ao exportar CSV: $e');
      }
    }
  }

  Future<void> _exportListaCompleta() async {
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final veiculosSnapshot =
          await FirebaseFirestore.instance.collection('veiculos').get();
      final equipasSnapshot =
          await FirebaseFirestore.instance.collection('equipas').get();

      final veiculos = {
        for (var doc in veiculosSnapshot.docs) doc.id: doc.data(),
      };
      final equipas = {
        for (var doc in equipasSnapshot.docs) doc.id: doc.data()['nome'] ?? '',
      };

      final buffer = StringBuffer();
      buffer.writeln(
        'Condutor,Matricula,Modelo,Distico,Grupo,Telefone,T-Shirt,Acompanhantes,Equipa',
      );

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final nome = data['nome'] ?? '';
        final telefone = data['telefone'] ?? '';
        final tshirt = data['tshirt'] ?? '';
        final veiculoId = data['veiculoId'];
        final equipaId = data['equipaId'];
        final veiculo = veiculos[veiculoId];
        final matricula = veiculo?['matricula'] ?? '';
        final modelo = veiculo?['modelo'] ?? '';
        final distico = veiculo?['distico'] ?? '';
        final grupo = veiculo?['grupo'] ?? '';
        final acompanhantes = (veiculo?['passageiros'] ?? [])
            .map((p) => '${p['nome'] ?? ''} (${p['tshirt'] ?? ''})')
            .join(' | ');
        final equipaNome = equipas[equipaId] ?? '';

        buffer.writeln(
          [
            nome,
            matricula,
            modelo,
            distico,
            grupo,
            telefone,
            tshirt,
            acompanhantes,
            equipaNome,
          ].map((v) => '"${v.toString().replaceAll('"', '""')}"').join(','),
        );
      }

      final bytes = utf8.encode(buffer.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'lista_completa.csv')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        _showSuccessSnackBar(context, 'Lista completa exportada com sucesso');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, 'Erro ao exportar lista completa: $e');
      }
    }
  }

  // Métodos de utilitários para exibir mensagens
  void _showSuccessSnackBar(BuildContext context, String message) {
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(message, style: const TextStyle(color: Colors.black)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
