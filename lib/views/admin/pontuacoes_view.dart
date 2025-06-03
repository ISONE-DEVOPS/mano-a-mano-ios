import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PontuacoesView extends StatefulWidget {
  const PontuacoesView({super.key});

  @override
  State<PontuacoesView> createState() => _PontuacoesViewState();
}

class _PontuacoesViewState extends State<PontuacoesView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pontuações Registradas')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('scores')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma pontuação registrada.'));
          }

          final scores = snapshot.data!.docs;

          return ListView.builder(
            itemCount: scores.length,
            itemBuilder: (context, index) {
              final data = scores[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(
                    '${data['nome'] ?? 'Sem nome'} — ${data['jogo'] ?? 'Jogo'}',
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Matrícula: ${data['matricula'] ?? '-'}'),
                      Text('Email: ${data['email'] ?? '-'}'),
                      Text('Telefone: ${data['telefone'] ?? '-'}'),
                      Text('Pontos: ${data['pontos'] ?? 0}'),
                      Text('Data: ${data['timestamp'] ?? ''}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          final pontosController = TextEditingController(
                            text: '${data['pontos']}',
                          );
                          showDialog(
                            context: context,
                            builder: (ctx) {
                              final localCtx = ctx;
                              return AlertDialog(
                                title: const Text('Editar Pontuação'),
                                content: TextField(
                                  controller: pontosController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Novo valor de pontos',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(localCtx).pop(),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final novoValor = int.tryParse(
                                        pontosController.text,
                                      );
                                      if (novoValor != null) {
                                        await snapshot
                                            .data!
                                            .docs[index]
                                            .reference
                                            .update({'pontos': novoValor});
                                        if (!context.mounted) return;
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Pontuação atualizada com sucesso.',
                                            ),
                                          ),
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
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) {
                              final localCtx = ctx;
                              return AlertDialog(
                                title: const Text('Confirmar remoção'),
                                content: const Text(
                                  'Deseja remover esta pontuação?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(localCtx).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(localCtx).pop(true),
                                    child: const Text('Remover'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirm == true) {
                            await snapshot.data!.docs[index].reference.delete();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pontuação removida com sucesso.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
