import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAcompanhantesView extends StatefulWidget {
  final String userId;
  const EditAcompanhantesView({super.key, required this.userId});

  @override
  State<EditAcompanhantesView> createState() => _EditAcompanhantesViewState();
}

class _EditAcompanhantesViewState extends State<EditAcompanhantesView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  String? equipaId;
  String? veiculoId;
  List<Map<String, dynamic>> acompanhantes = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      // Buscar dados do usuário principal
      final userDoc =
          await _firestore.collection('users').doc(widget.userId).get();
      final userData = userDoc.data();

      if (userData != null) {
        equipaId = userData['equipaId'];
        veiculoId = userData['veiculoId'];
      }

      if (equipaId != null) {
        await _carregarAcompanhantes();
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar dados: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _carregarAcompanhantes() async {
    if (equipaId == null) return;

    try {
      // Buscar todos os membros da equipa exceto o condutor atual
      final equipaDoc =
          await _firestore.collection('equipas').doc(equipaId).get();
      final equipaData = equipaDoc.data();

      if (equipaData != null && equipaData['membros'] != null) {
        final List<String> membrosIds = List<String>.from(
          equipaData['membros'],
        );

        // Remover o ID do condutor atual da lista
        membrosIds.remove(widget.userId);

        acompanhantes.clear();

        for (String membroId in membrosIds) {
          final membroDoc =
              await _firestore.collection('users').doc(membroId).get();
          if (membroDoc.exists) {
            final membroData = membroDoc.data()!;
            acompanhantes.add({
              'id': membroId,
              'nome': membroData['nome'] ?? '',
              'email': membroData['email'] ?? '',
              'telefone': membroData['telefone'] ?? '',
              'emergencia': membroData['emergencia'] ?? '',
              'tshirt': membroData['tshirt'] ?? '',
            });
          }
        }
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar acompanhantes: $e');
    }
  }

  void _adicionarAcompanhante() {
    if (acompanhantes.length >= 3) {
      _mostrarErro('Máximo de 3 acompanhantes permitidos');
      return;
    }

    setState(() {
      acompanhantes.add({
        'id': null, // Novo acompanhante
        'nome': '',
        'email': '',
        'telefone': '',
        'emergencia': '',
        'tshirt': '',
      });
    });
  }

  void _removerAcompanhante(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar remoção'),
            content: const Text(
              'Tem certeza que deseja remover este acompanhante?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _removerAcompanhanteConfirmado(index);
                },
                child: const Text(
                  'Remover',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _removerAcompanhanteConfirmado(int index) async {
    try {
      final acompanhante = acompanhantes[index];

      if (acompanhante['id'] != null) {
        // Remover do Firestore se já existe
        await _firestore.collection('users').doc(acompanhante['id']).delete();

        // Atualizar lista de membros da equipa
        if (equipaId != null) {
          final equipaDoc =
              await _firestore.collection('equipas').doc(equipaId!).get();
          final equipaData = equipaDoc.data();
          if (equipaData != null && equipaData['membros'] != null) {
            List<String> membros = List<String>.from(equipaData['membros']);
            membros.remove(acompanhante['id']);
            await _firestore.collection('equipas').doc(equipaId!).update({
              'membros': membros,
            });
          }
        }
      }

      setState(() {
        acompanhantes.removeAt(index);
      });

      _mostrarSucesso('Acompanhante removido com sucesso');
    } catch (e) {
      _mostrarErro('Erro ao remover acompanhante: $e');
    }
  }

  Future<void> _salvarAlteracoes() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<String> membrosIds = [widget.userId]; // Incluir o condutor

      for (int i = 0; i < acompanhantes.length; i++) {
        final acompanhante = acompanhantes[i];

        // Validar dados obrigatórios
        if (acompanhante['nome'].toString().trim().isEmpty) {
          _mostrarErro('Nome do acompanhante ${i + 1} é obrigatório');
          return;
        }

        String? acompanhanteId = acompanhante['id'];

        if (acompanhanteId == null) {
          // Criar novo acompanhante
          final docRef = await _firestore.collection('users').add({
            'nome': acompanhante['nome'].toString().trim(),
            'email': acompanhante['email'].toString().trim(),
            'telefone': acompanhante['telefone'].toString().trim(),
            'emergencia': acompanhante['emergencia'].toString().trim(),
            'tshirt': acompanhante['tshirt'].toString().trim(),
            'role': 'user',
            'equipaId': equipaId,
            'veiculoId': veiculoId,
            'ativo': true,
            'createAt': FieldValue.serverTimestamp(),
          });
          acompanhanteId = docRef.id;
        } else {
          // Atualizar acompanhante existente
          await _firestore.collection('users').doc(acompanhanteId).update({
            'nome': acompanhante['nome'].toString().trim(),
            'email': acompanhante['email'].toString().trim(),
            'telefone': acompanhante['telefone'].toString().trim(),
            'emergencia': acompanhante['emergencia'].toString().trim(),
            'tshirt': acompanhante['tshirt'].toString().trim(),
            'equipaId': equipaId,
            'veiculoId': veiculoId,
          });
        }

        membrosIds.add(acompanhanteId);
      }

      // Atualizar lista de membros da equipa
      if (equipaId != null) {
        await _firestore.collection('equipas').doc(equipaId!).update({
          'membros': membrosIds,
        });
      }

      // Atualizar lista de passageiros no veículo
      if (veiculoId != null) {
        List<String> passageiros = List<String>.from(membrosIds);
        passageiros.remove(
          widget.userId,
        ); // Remover o condutor da lista de passageiros

        await _firestore.collection('veiculos').doc(veiculoId!).update({
          'passageiros': passageiros,
        });
      }

      _mostrarSucesso('Acompanhantes salvos com sucesso');
      if (mounted) {
        Navigator.pop(
          context,
          true,
        ); // Retorna true para indicar que houve mudanças
      }
    } catch (e) {
      _mostrarErro('Erro ao salvar: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _mostrarErro(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
      );
    }
  }

  void _mostrarSucesso(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Acompanhantes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _salvarAlteracoes,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Acompanhantes (${acompanhantes.length}/3)',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (acompanhantes.length < 3)
                  ElevatedButton.icon(
                    onPressed: _adicionarAcompanhante,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  acompanhantes.isEmpty
                      ? const Center(
                        child: Text(
                          'Nenhum acompanhante adicionado.\nToque em "Adicionar" para incluir um acompanhante.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        itemCount: acompanhantes.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Acompanhante ${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _removerAcompanhante(index),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Nome *',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      acompanhantes[index]['nome'] = value;
                                    },
                                    controller: TextEditingController(
                                      text: acompanhantes[index]['nome'],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      acompanhantes[index]['email'] = value;
                                    },
                                    controller: TextEditingController(
                                      text: acompanhantes[index]['email'],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Telefone',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      acompanhantes[index]['telefone'] = value;
                                    },
                                    controller: TextEditingController(
                                      text: acompanhantes[index]['telefone'],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Contacto de emergência',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      acompanhantes[index]['emergencia'] =
                                          value;
                                    },
                                    controller: TextEditingController(
                                      text: acompanhantes[index]['emergencia'],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Tamanho de T-shirt',
                                      border: OutlineInputBorder(),
                                    ),
                                    initialValue:
                                        acompanhantes[index]['tshirt'].isEmpty
                                            ? null
                                            : acompanhantes[index]['tshirt'],
                                    items:
                                        ['XS', 'S', 'M', 'L', 'XL', 'XXL']
                                            .map(
                                              (size) => DropdownMenuItem(
                                                value: size,
                                                child: Text(size),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        acompanhantes[index]['tshirt'] =
                                            value ?? '';
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvarAlteracoes,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Salvar Alterações',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
