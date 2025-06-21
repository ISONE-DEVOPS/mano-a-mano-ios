import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditParticipantesView extends StatefulWidget {
  final String userId;
  const EditParticipantesView({super.key, required this.userId});

  @override
  State<EditParticipantesView> createState() => _EditParticipantesViewState();
}

class _EditParticipantesViewState extends State<EditParticipantesView> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final emergenciaController = TextEditingController();
  final tshirtController = TextEditingController();

  Map<String, String> equipas = {};
  String? equipaSelecionada;

  Map<String, String> veiculos = {};
  String? veiculoSelecionado;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();
    final data = doc.data();

    final equipesSnapshot =
        await FirebaseFirestore.instance.collection('equipas').get();
    for (final doc in equipesSnapshot.docs) {
      equipas[doc.id] = doc['nome'] ?? 'Sem nome';
    }

    final veiculosSnapshot =
        await FirebaseFirestore.instance.collection('veiculos').get();
    for (final doc in veiculosSnapshot.docs) {
      veiculos[doc.id] = doc['matricula'] ?? 'Sem matrícula';
    }

    if (data != null) {
      nomeController.text = data['nome'] ?? '';
      emailController.text = data['email'] ?? '';
      telefoneController.text = data['telefone'] ?? '';
      emergenciaController.text = data['emergencia'] ?? '';
      tshirtController.text = data['tshirt'] ?? '';
      equipaSelecionada = data['equipaId'];
      veiculoSelecionado = data['veiculoId'];
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _salvarAlteracoes() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participante atualizado com sucesso')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Participante')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: telefoneController,
              decoration: const InputDecoration(labelText: 'Telefone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emergenciaController,
              decoration: const InputDecoration(
                labelText: 'Contacto de emergência',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tshirtController,
              decoration: const InputDecoration(
                labelText: 'Tamanho de T-shirt',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: equipas.containsKey(equipaSelecionada) ? equipaSelecionada : null,
              decoration: const InputDecoration(labelText: 'Equipa'),
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
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: veiculos.containsKey(veiculoSelecionado) ? veiculoSelecionado : null,
              decoration: const InputDecoration(labelText: 'Veículo'),
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
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _salvarAlteracoes,
              child: const Text('Salvar alterações'),
            ),
            const SizedBox(height: 24),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('eventos')
                  .limit(1)
                  .get()
                  .then((snap) {
                    if (snap.docs.isEmpty) {
                      return Future.value(QuerySnapshotMock());
                    }
                    final eventoId = snap.docs.first.id;
                    return FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .collection('eventos')
                        .doc(eventoId)
                        .collection('pontuacoes')
                        .get();
                  }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Text('Sem pontuação registrada.');
                }

                final docs = snapshot.data!.docs;
                final total = docs.fold<int>(0, (acumulado, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final pontos = data['pontuacaoTotal'];
                  return acumulado + ((pontos ?? 0) as num).toInt();
                });
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pontuações',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text('Checkpoint: ${doc.id}'),
                        subtitle: Text(
                          'Total: ${data['pontuacaoTotal'] ?? 0} pontos',
                        ),
                      );
                    }),
                    Text(
                      'Total acumulado: $total pontos',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class QuerySnapshotMock implements QuerySnapshot {
  @override
  List<QueryDocumentSnapshot<Object?>> get docs =>
      <QueryDocumentSnapshot<Object?>>[];
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
