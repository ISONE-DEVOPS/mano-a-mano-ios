import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<int> corrigirUsuarios() async {
  final users = await FirebaseFirestore.instance.collection('users').get();
  int contadorCorrigidos = 0;

  for (final doc in users.docs) {
    final data = doc.data();
    final updates = <String, dynamic>{};

    if (!data.containsKey('checkpointsVisitados') || data['checkpointsVisitados'] == null) {
      updates['checkpointsVisitados'] = [];
    }

    if (!data.containsKey('role')) {
      updates['role'] = 'user';
    }

    if (!data.containsKey('createdAt')) {
      updates['createdAt'] = DateTime.now().toUtc().toIso8601String();
    }

    if (updates.isNotEmpty) {
      await doc.reference.update(updates);
      contadorCorrigidos++;
      debugPrint('Corrigido usuário: ${doc.id}');
    }
  }

  debugPrint('✅ Correção completa: $contadorCorrigidos usuários corrigidos.');
  return contadorCorrigidos;
}
