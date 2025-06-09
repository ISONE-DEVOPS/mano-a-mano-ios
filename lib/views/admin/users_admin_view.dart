import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsersAdminView extends StatelessWidget {
  const UsersAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text(
          'Utilizadores',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final isAdmin = userData?['tipo'] == 'admin';

          final stream =
              isAdmin
                  ? FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('nome')
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('users')
                      .where(
                        FieldPath.documentId,
                        isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                      )
                      .snapshots();

          return StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum utilizador encontrado.',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }

              final users = snapshot.data!.docs;

              return Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      separatorBuilder: (context, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final data =
                            users[index].data() as Map<String, dynamic>?;
                        if (data == null || data.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['nome'] ?? 'Sem nome',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                              if (data['tipo'] == 'admin')
                                const Icon(
                                  Icons.verified_user,
                                  color: Colors.green,
                                  size: 18,
                                ),
                            ],
                          ),
                          subtitle: Text(
                            data['email'] ?? 'Sem email',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppColors.secondaryDark,
                                ),
                                onPressed: () async {
                                  final nomeController = TextEditingController(
                                    text: data['nome'] ?? '',
                                  );
                                  final emailController = TextEditingController(
                                    text: data['email'] ?? '',
                                  );
                                  final formKey = GlobalKey<FormState>();

                                  await showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text(
                                            'Editar Utilizador',
                                          ),
                                          content: Form(
                                            key: formKey,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextFormField(
                                                  controller: nomeController,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Nome',
                                                        labelStyle: TextStyle(
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                  validator:
                                                      (value) =>
                                                          value == null ||
                                                                  value
                                                                      .trim()
                                                                      .isEmpty
                                                              ? 'Nome obrigatório'
                                                              : null,
                                                ),
                                                TextFormField(
                                                  controller: emailController,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Email',
                                                        labelStyle: TextStyle(
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                  keyboardType:
                                                      TextInputType
                                                          .emailAddress,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.trim().isEmpty) {
                                                      return 'Email obrigatório';
                                                    }
                                                    final emailRegex = RegExp(
                                                      r'^[^@]+@[^@]+\.[^@]+',
                                                    );
                                                    return emailRegex.hasMatch(
                                                          value,
                                                        )
                                                        ? null
                                                        : 'Email inválido';
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(context),
                                              child: const Text(
                                                'Cancelar',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                if (formKey.currentState!
                                                    .validate()) {
                                                  await snapshot
                                                      .data!
                                                      .docs[index]
                                                      .reference
                                                      .update({
                                                        'nome':
                                                            nomeController.text
                                                                .trim(),
                                                        'email':
                                                            emailController.text
                                                                .trim(),
                                                      });
                                                  if (!context.mounted) return;
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Utilizador atualizado com sucesso',
                                                      ),
                                                      backgroundColor:
                                                          AppColors.primary,
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text(
                                                'Guardar',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.primary,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text(
                                            'Confirmar remoção',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                          content: const Text(
                                            'Deseja apagar este utilizador?',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: const Text(
                                                'Cancelar',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: const Text(
                                                'Apagar',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                  );

                                  if (confirm == true) {
                                    await snapshot.data!.docs[index].reference
                                        .delete();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Utilizador removido com sucesso',
                                        ),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
