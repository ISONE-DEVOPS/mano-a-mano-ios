import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';

class UsersAdminView extends StatelessWidget {
  const UsersAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Utilizadores', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum utilizador encontrado.'));
          }

          final users = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final data = users[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(data['nome'] ?? 'Sem nome'),
                subtitle: Text(data['email'] ?? 'Sem email'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.secondaryDark),
                      onPressed: () async {
                        final nomeController = TextEditingController(text: data['nome']);
                        final emailController = TextEditingController(text: data['email']);
                        final formKey = GlobalKey<FormState>();

                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Editar Utilizador'),
                            content: Form(
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                    controller: nomeController,
                                    decoration: const InputDecoration(labelText: 'Nome'),
                                    validator: (value) => value == null || value.trim().isEmpty ? 'Nome obrigatório' : null,
                                  ),
                                  TextFormField(
                                    controller: emailController,
                                    decoration: const InputDecoration(labelText: 'Email'),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) return 'Email obrigatório';
                                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                      return emailRegex.hasMatch(value) ? null : 'Email inválido';
                                    },
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                              TextButton(
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    await snapshot.data!.docs[index].reference.update({
                                      'nome': nomeController.text.trim(),
                                      'email': emailController.text.trim(),
                                    });
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Utilizador atualizado com sucesso'),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Guardar'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.primary),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmar remoção'),
                            content: const Text('Deseja apagar este utilizador?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar')),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await snapshot.data!.docs[index].reference.delete();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Utilizador removido com sucesso'),
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
          );
        },
      ),
    );
  }
}
