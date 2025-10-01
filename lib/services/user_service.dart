import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static Future<void> converterParaParticipante(String uid) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Atualiza campos obrigatórios do user
      await firestore.collection('users').doc(uid).update({
        'nome': 'Novo Participante',
        'telefone': '',
        'emergencia': '',
        'tshirt': 'M',
        'equipaId': null,
        'veiculoId': null,
      });

      // Cria documento de evento se não existir
      final eventoRef = firestore
          .collection('users')
          .doc(uid)
          .collection('eventos')
          .doc('shell_2025');

      final eventoDoc = await eventoRef.get();
      if (!eventoDoc.exists) {
        await eventoRef.set({
          'participando': true,
          'checkinInicial': null,
          'pontuacaoTotal': 0,
        });
      }
    } catch (e) {
      throw Exception('Erro ao converter para participante: $e');
    }
  }
}
