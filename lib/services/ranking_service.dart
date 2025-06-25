import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class RankingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ 1. ATUALIZAÇÃO EM TEMPO REAL (quando participante pontua)
  static Future<void> updateRankingRealTime(String equipaId) async {
    try {
      debugPrint('🔄 Atualizando ranking para equipa: $equipaId');

      // Calcular pontuação total da equipa
      final pontuacaoTotal = await _calculateTeamTotalScore(equipaId);
      final checkpointCount = await _getCheckpointsCompleted(equipaId);

      // 🆕 ADICIONADO: Calcular tempo total
      final tempoTotal = await _calculateTotalTime(equipaId);

      // Atualizar ou criar registro no ranking
      await _firestore.collection('ranking').doc(equipaId).set({
        'equipaId': equipaId,
        'pontuacao': pontuacaoTotal,
        'checkpointCount': checkpointCount,
        'tempoTotal': tempoTotal, // 🆕 ADICIONADO
        'ultimaAtualizacao': FieldValue.serverTimestamp(),
        'ordem': 0, // Será calculado depois
      }, SetOptions(merge: true));

      // Recalcular ordem de todas as equipas
      await _recalculateAllPositions();

      debugPrint('✅ Ranking atualizado com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar ranking: $e');
    }
  }

  // ✅ 2. RECALCULO COMPLETO (manual pelo admin)
  static Future<void> recalculateCompleteRanking() async {
    try {
      debugPrint('🔄 Iniciando recálculo completo do ranking...');

      // Buscar todas as equipas
      final equipasSnapshot = await _firestore.collection('equipas').get();

      List<Map<String, dynamic>> rankingData = [];

      for (var equipaDoc in equipasSnapshot.docs) {
        final equipaId = equipaDoc.id;

        // Calcular pontuação total
        final pontuacaoTotal = await _calculateTeamTotalScore(equipaId);
        final checkpointCount = await _getCheckpointsCompleted(equipaId);
        final tempoTotal = await _calculateTotalTime(equipaId);

        rankingData.add({
          'equipaId': equipaId,
          'pontuacao': pontuacaoTotal,
          'checkpointCount': checkpointCount,
          'tempoTotal': tempoTotal,
          'ultimaAtualizacao': FieldValue.serverTimestamp(),
        });
      }

      // Ordenar por pontuação (maior para menor)
      rankingData.sort((a, b) => b['pontuacao'].compareTo(a['pontuacao']));

      // Salvar com posições corretas
      final batch = _firestore.batch();

      for (int i = 0; i < rankingData.length; i++) {
        final data = rankingData[i];
        data['ordem'] = i + 1;

        final docRef = _firestore.collection('ranking').doc(data['equipaId']);
        batch.set(docRef, data, SetOptions(merge: true));
      }

      await batch.commit();

      debugPrint(
        '✅ Recálculo completo concluído: ${rankingData.length} equipas',
      );
    } catch (e) {
      debugPrint('❌ Erro no recálculo completo: $e');
    }
  }

  // ✅ 3. ATUALIZAÇÃO QUANDO STAFF PONTUA JOGO
  static Future<void> updateRankingAfterGameScore(
    String userId,
    String checkpointId,
    String jogoId,
    int pontuacao,
  ) async {
    try {
      // Buscar equipa do user
      final equipaId = await _getUserTeam(userId);
      if (equipaId == null) return;

      debugPrint('🎮 Staff pontuou jogo: $pontuacao pts para equipa $equipaId');

      // Atualizar ranking
      await updateRankingRealTime(equipaId);
    } catch (e) {
      debugPrint('❌ Erro ao atualizar ranking após jogo: $e');
    }
  }

  // ✅ 4. ATUALIZAÇÃO QUANDO PARTICIPANTE RESPONDE PERGUNTA
  static Future<void> updateRankingAfterQuestion(
    String userId,
    String checkpointId,
    bool respostaCorreta,
  ) async {
    try {
      // Buscar equipa do user
      final equipaId = await _getUserTeam(userId);
      if (equipaId == null) return;

      final pontos = respostaCorreta ? 10 : 0;
      debugPrint('❓ Pergunta respondida: $pontos pts para equipa $equipaId');

      // Atualizar ranking
      await updateRankingRealTime(equipaId);
    } catch (e) {
      debugPrint('❌ Erro ao atualizar ranking após pergunta: $e');
    }
  }

  // ===================================
  // FUNÇÕES AUXILIARES
  // ===================================

  static Future<int> _calculateTeamTotalScore(String equipaId) async {
    int totalScore = 0;

    try {
      // Buscar todos os membros da equipa
      final equipaDoc =
          await _firestore.collection('equipas').doc(equipaId).get();
      final membros = (equipaDoc.data()?['membros'] ?? []) as List<dynamic>;

      // Para cada membro, somar todas as pontuações
      for (String userId in membros) {
        final pontuacoesSnapshot =
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('eventos')
                .doc('shell_2025')
                .collection('pontuacoes')
                .get();

        for (var doc in pontuacoesSnapshot.docs) {
          final data = doc.data();
          totalScore += (data['pontuacaoPergunta'] ?? 0) as int;
          totalScore += (data['pontuacaoJogo'] ?? 0) as int;

          // Se houver jogos múltiplos
          if (data['jogosPontuados'] != null) {
            final jogosPontuados =
                data['jogosPontuados'] as Map<String, dynamic>;
            for (var pontuacao in jogosPontuados.values) {
              totalScore += (pontuacao ?? 0) as int;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao calcular pontuação total: $e');
    }

    return totalScore;
  }

  static Future<int> _getCheckpointsCompleted(String equipaId) async {
    try {
      // Buscar primeiro membro da equipa (condutor)
      final equipaDoc =
          await _firestore.collection('equipas').doc(equipaId).get();
      final membros = (equipaDoc.data()?['membros'] ?? []) as List<dynamic>;

      if (membros.isEmpty) return 0;

      final condutorId = membros.first;
      final pontuacoesSnapshot =
          await _firestore
              .collection('users')
              .doc(condutorId)
              .collection('eventos')
              .doc('shell_2025')
              .collection('pontuacoes')
              .get();

      return pontuacoesSnapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Erro ao contar checkpoints: $e');
      return 0;
    }
  }

  // 🆕 FUNÇÃO ADICIONADA - CÁLCULO DE TEMPO TOTAL
  static Future<int> _calculateTotalTime(String equipaId) async {
    try {
      debugPrint('⏱️ Calculando tempo total para equipa: $equipaId');

      // 1. Buscar condutor principal da equipa
      final equipaDoc =
          await _firestore.collection('equipas').doc(equipaId).get();
      final membros = (equipaDoc.data()?['membros'] ?? []) as List<dynamic>;

      if (membros.isEmpty) return 0;

      final condutorId = membros.first; // Usar primeiro membro como referência

      // 2. Buscar todas as pontuações do condutor
      final pontuacoesSnapshot =
          await _firestore
              .collection('users')
              .doc(condutorId)
              .collection('eventos')
              .doc('shell_2025')
              .collection('pontuacoes')
              .get();

      if (pontuacoesSnapshot.docs.isEmpty) return 0;

      DateTime? primeiroTimestamp;
      DateTime? ultimoTimestamp;

      // 3. Encontrar primeiro e último timestamp
      for (var doc in pontuacoesSnapshot.docs) {
        final data = doc.data();

        // Timestamp de entrada
        final timestampEntrada = data['timestampEntrada'] as Timestamp?;
        if (timestampEntrada != null) {
          final entradaTime = timestampEntrada.toDate();

          if (primeiroTimestamp == null ||
              entradaTime.isBefore(primeiroTimestamp)) {
            primeiroTimestamp = entradaTime;
          }
        }

        // Timestamp de saída
        final timestampSaida = data['timestampSaida'] as Timestamp?;
        if (timestampSaida != null) {
          final saidaTime = timestampSaida.toDate();

          if (ultimoTimestamp == null || saidaTime.isAfter(ultimoTimestamp)) {
            ultimoTimestamp = saidaTime;
          }
        }
      }

      // 4. Calcular diferença em minutos
      if (primeiroTimestamp != null && ultimoTimestamp != null) {
        final diferenca = ultimoTimestamp.difference(primeiroTimestamp);
        final tempoMinutos = diferenca.inMinutes;

        debugPrint(
          '⏱️ Tempo calculado: $tempoMinutos minutos (${diferenca.inHours}h ${diferenca.inMinutes % 60}min)',
        );
        return tempoMinutos;
      }

      debugPrint('⏱️ Timestamps insuficientes para calcular tempo');
      return 0;
    } catch (e) {
      debugPrint('❌ Erro ao calcular tempo total: $e');
      return 0;
    }
  }

  static Future<String?> _getUserTeam(String userId) async {
    try {
      final equipasSnapshot =
          await _firestore
              .collection('equipas')
              .where('membros', arrayContains: userId)
              .get();

      if (equipasSnapshot.docs.isNotEmpty) {
        return equipasSnapshot.docs.first.id;
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar equipa do user: $e');
    }
    return null;
  }

  static Future<void> _recalculateAllPositions() async {
    try {
      // Buscar todos os rankings ordenados por pontuação
      final rankingsSnapshot =
          await _firestore
              .collection('ranking')
              .orderBy('pontuacao', descending: true)
              .orderBy(
                'tempoTotal',
                descending: false,
              ) // 🆕 Tempo como critério de desempate
              .get();

      final batch = _firestore.batch();

      for (int i = 0; i < rankingsSnapshot.docs.length; i++) {
        final docRef = rankingsSnapshot.docs[i].reference;
        batch.update(docRef, {'ordem': i + 1});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('❌ Erro ao recalcular posições: $e');
    }
  }

  // 🆕 FUNÇÕES EXTRAS PARA AJUDAR COM TIMESTAMPS

  /// Atualizar timestamp de entrada quando scan QR entrada
  static Future<void> updateEntryTimestamp(
    String userId,
    String checkpointId,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('eventos')
          .doc('shell_2025')
          .collection('pontuacoes')
          .doc(checkpointId)
          .set({
            'timestampEntrada': FieldValue.serverTimestamp(),
            'checkpointId': checkpointId,
          }, SetOptions(merge: true));

      debugPrint('📍 Timestamp de entrada atualizado');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar timestamp entrada: $e');
    }
  }

  /// Atualizar timestamp de saída quando scan QR saída
  static Future<void> updateExitTimestamp(
    String userId,
    String checkpointId,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('eventos')
          .doc('shell_2025')
          .collection('pontuacoes')
          .doc(checkpointId)
          .update({'timestampSaida': FieldValue.serverTimestamp()});

      // Atualizar ranking após saída
      final equipaId = await _getUserTeam(userId);
      if (equipaId != null) {
        await updateRankingRealTime(equipaId);
      }

      debugPrint('🚪 Timestamp de saída atualizado');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar timestamp saída: $e');
    }
  }
}
