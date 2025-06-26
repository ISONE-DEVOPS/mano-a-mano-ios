// ================================
// QUALIFICATION GRID SCREEN - VERSÃO MELHORADA
// ================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QualificationGridScreen extends StatefulWidget {
  const QualificationGridScreen({super.key});

  @override
  State<QualificationGridScreen> createState() =>
      _QualificationGridScreenState();
}

class _QualificationGridScreenState extends State<QualificationGridScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<EquipaGridData> _equipas = [];
  List<CheckpointData> _checkpointsGrupoA = [];
  List<CheckpointData> _checkpointsGrupoB = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEquipasData();
  }

  Future<void> _loadEquipasData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('🔄 Carregando dados da grelha de qualificação...');

      // Buscar todas as coleções em paralelo
      final futures = await Future.wait([
        _firestore.collection('equipas').get(),
        _firestore.collection('users').get(),
        _firestore.collection('veiculos').get(),
        _firestore.collection('ranking').get(),
        _firestore.collectionGroup('checkpoints').get(),
        _firestore.collection('jogos').get(),
      ]);

      final equipasSnapshot = futures[0] as QuerySnapshot;
      final usersSnapshot = futures[1] as QuerySnapshot;
      final veiculosSnapshot = futures[2] as QuerySnapshot;
      final rankingSnapshot = futures[3] as QuerySnapshot;
      final checkpointsSnapshot = futures[4] as QuerySnapshot;
      final jogosSnapshot = futures[5] as QuerySnapshot;

      debugPrint('✅ Dados carregados:');
      debugPrint('   - Equipas: ${equipasSnapshot.docs.length}');
      debugPrint('   - Users: ${usersSnapshot.docs.length}');
      debugPrint('   - Veículos: ${veiculosSnapshot.docs.length}');
      debugPrint('   - Rankings: ${rankingSnapshot.docs.length}');
      debugPrint('   - Checkpoints: ${checkpointsSnapshot.docs.length}');
      debugPrint('   - Jogos: ${jogosSnapshot.docs.length}');

      // Criar mapas para acesso rápido
      final Map<String, Map<String, dynamic>> usersMap = {
        for (var doc in usersSnapshot.docs)
          doc.id: doc.data() as Map<String, dynamic>,
      };

      final Map<String, Map<String, dynamic>> veiculosMap = {
        for (var doc in veiculosSnapshot.docs)
          doc.id: doc.data() as Map<String, dynamic>,
      };

      final Map<String, Map<String, dynamic>> rankingMap = {
        for (var doc in rankingSnapshot.docs)
          (doc.data() as Map<String, dynamic>)['equipaId']:
              doc.data() as Map<String, dynamic>,
      };

      final Map<String, Map<String, dynamic>> jogosMap = {
        for (var doc in jogosSnapshot.docs)
          doc.id: doc.data() as Map<String, dynamic>,
      };

      // Processar checkpoints
      _processCheckpoints(checkpointsSnapshot.docs, jogosMap);

      // Filtrar equipas (excluir admins)
      final filteredEquipas =
          equipasSnapshot.docs.where((doc) {
            final membros =
                (doc.data() as Map<String, dynamic>)['membros'] ?? [];
            if (membros is! List) return true;
            return !membros.any((uid) => usersMap[uid]?['tipo'] == 'admin');
          }).toList();

      debugPrint('🔍 Equipas filtradas: ${filteredEquipas.length}');

      // 🔥 BUSCAR TODOS OS STATUS DE UMA VEZ (SEM LOOPS)
      debugPrint('🔍 Buscando status de checkpoints e jogos...');

      // Coletar todos os UIDs únicos
      Set<String> allUIDs = {};
      for (var equipaDoc in filteredEquipas) {
        final equipaData = equipaDoc.data() as Map<String, dynamic>;
        final membros = equipaData['membros'] as List? ?? [];
        for (var uid in membros) {
          if (uid is String) allUIDs.add(uid);
        }
      }

      // Buscar pontuações de todos os usuários de uma vez
      Map<String, Map<String, CheckpointStatusEnum>> allCheckpointStatus = {};
      Map<String, Map<String, bool>> allJogoStatus = {};

      for (var uid in allUIDs) {
        try {
          final pontuacoesSnapshot =
              await _firestore
                  .collection('users')
                  .doc(uid)
                  .collection('eventos')
                  .doc('shell_km_02')
                  .collection('pontuacoes')
                  .get();

          Map<String, CheckpointStatusEnum> userCheckpointStatus = {};
          Map<String, bool> userJogoStatus = {};

          for (var doc in pontuacoesSnapshot.docs) {
            final data = doc.data();
            final checkpointId = doc.id;

            // 🔥 CORRIGIDO: verificar campos 'entrada' e 'saida' (não timestamp)
            final entrada = data['entrada'] ?? data['timestampEntrada'];
            final saida = data['saida'] ?? data['timestampSaida'];

            if (entrada != null && saida != null) {
              userCheckpointStatus[checkpointId] =
                  CheckpointStatusEnum.completo;
              debugPrint(
                '    ✅ Checkpoint $checkpointId: COMPLETO (entrada + saída)',
              );
            } else if (entrada != null) {
              userCheckpointStatus[checkpointId] =
                  CheckpointStatusEnum.apenasEntrada;
              debugPrint('    🟠 Checkpoint $checkpointId: APENAS ENTRADA');
            } else {
              userCheckpointStatus[checkpointId] =
                  CheckpointStatusEnum.naoCompleto;
              debugPrint('    🔘 Checkpoint $checkpointId: NÃO COMPLETO');
            }

            // Status dos jogos
            final jogosPontuados =
                data['jogosPontuados'] as Map<String, dynamic>? ?? {};
            for (var jogoId in jogosPontuados.keys) {
              userJogoStatus[jogoId] = true;
              debugPrint('    🎮 Jogo $jogoId: FEITO');
            }
          }

          allCheckpointStatus[uid] = userCheckpointStatus;
          allJogoStatus[uid] = userJogoStatus;
        } catch (e) {
          debugPrint('⚠️ Erro ao buscar dados do usuário $uid: $e');
        }
      }

      debugPrint('✅ Status carregados para ${allUIDs.length} usuários');

      // Processar equipas
      List<EquipaGridData> equipasData = [];

      for (var equipaDoc in filteredEquipas) {
        try {
          final equipaData = equipaDoc.data() as Map<String, dynamic>;
          final veiculoId = equipaData['veiculoId'] as String?;
          final membros = equipaData['membros'] as List? ?? [];

          // Buscar dados do veículo
          String modelo = '';
          String matricula = '';
          String condutorNome = '';
          String distico = '';

          if (veiculoId != null && veiculosMap.containsKey(veiculoId)) {
            final veiculoData = veiculosMap[veiculoId]!;
            modelo = veiculoData['modelo']?.toString() ?? '';
            matricula = veiculoData['matricula']?.toString() ?? '';
            distico = veiculoData['distico']?.toString() ?? '';

            // 🔥 CORRIGIDO: ownerId é o condutor, não condutorId
            final ownerId = veiculoData['ownerId'] as String?;
            if (ownerId != null && usersMap.containsKey(ownerId)) {
              condutorNome = usersMap[ownerId]!['nome']?.toString() ?? '';
            }

            debugPrint(
              '🚗 Veículo $veiculoId: modelo=$modelo, matricula=$matricula, distico=$distico, ownerId=$ownerId, condutor=$condutorNome',
            );
          } else {
            debugPrint('⚠️ Veículo $veiculoId não encontrado no mapa');
          }

          // Buscar pontuação
          int pontuacaoTotal = 0;
          if (rankingMap.containsKey(equipaDoc.id)) {
            pontuacaoTotal = rankingMap[equipaDoc.id]!['pontuacao'] ?? 0;
          }

          // 🔥 COMBINAR STATUS DE TODOS OS MEMBROS DA EQUIPA
          Map<String, CheckpointStatusEnum> equipaCheckpointStatus = {};
          Map<String, bool> equipaJogoStatus = {};

          debugPrint(
            '🔍 Processando equipa: ${equipaData['nome']} (Membros: ${membros.length})',
          );

          for (var uid in membros) {
            if (uid is! String) continue;

            debugPrint('  👤 Membro: $uid');

            // Checkpoint status - pegar o melhor status de qualquer membro
            final userCheckpointStatus = allCheckpointStatus[uid] ?? {};
            debugPrint(
              '    📍 Checkpoints do membro: ${userCheckpointStatus.keys.length}',
            );

            for (var entry in userCheckpointStatus.entries) {
              final checkpointId = entry.key;
              final status = entry.value;

              debugPrint('      Checkpoint $checkpointId: $status');

              if (!equipaCheckpointStatus.containsKey(checkpointId) ||
                  status.index > equipaCheckpointStatus[checkpointId]!.index) {
                equipaCheckpointStatus[checkpointId] = status;
              }
            }

            // Jogo status - se qualquer membro fez o jogo, a equipa fez
            final userJogoStatus = allJogoStatus[uid] ?? {};
            debugPrint('    🎮 Jogos do membro: ${userJogoStatus.keys.length}');

            for (var entry in userJogoStatus.entries) {
              debugPrint('      Jogo ${entry.key}: ${entry.value}');
              equipaJogoStatus[entry.key] = true;
            }
          }

          debugPrint('  ✅ Status final da equipa:');
          debugPrint('    📍 Checkpoints: ${equipaCheckpointStatus.length}');
          debugPrint('    🎮 Jogos: ${equipaJogoStatus.length}');

          equipasData.add(
            EquipaGridData(
              id: equipaDoc.id,
              nome:
                  equipaData['nome']?.toString() ??
                  'Equipa ${equipasData.length + 1}',
              condutorNome: condutorNome,
              modelo: modelo,
              matricula: matricula,
              distico: distico,
              grupo: equipaData['grupo']?.toString() ?? 'A',
              pontuacaoTotal: pontuacaoTotal,
              bandeiraUrl: equipaData['bandeiraUrl']?.toString(),
              checkpointStatus: equipaCheckpointStatus,
              jogoStatus: equipaJogoStatus,
            ),
          );

          debugPrint(
            '  💾 Equipa adicionada: ${equipaData['nome']} (Dístico: $distico, Condutor: $condutorNome, Veículo: $modelo $matricula)',
          );
        } catch (e) {
          debugPrint('⚠️ Erro ao processar equipa ${equipaDoc.id}: $e');
          continue;
        }
      }

      // Ordenar por pontuação
      equipasData.sort((a, b) => b.pontuacaoTotal.compareTo(a.pontuacaoTotal));

      debugPrint('✅ Processamento concluído: ${equipasData.length} equipas');

      if (!mounted) return;

      setState(() {
        _equipas = equipasData;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao carregar dados: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _processCheckpoints(
    List<QueryDocumentSnapshot> checkpointDocs,
    Map<String, Map<String, dynamic>> jogosMap,
  ) {
    List<CheckpointData> checkpointsA = [];
    List<CheckpointData> checkpointsB = [];

    for (var doc in checkpointDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final percurso = data['percurso'] as String? ?? '';
      final ordemA = data['ordemA'] as int? ?? 0;
      final ordemB = data['ordemB'] as int? ?? 0;

      // Buscar jogos deste checkpoint
      List<String> codigosJogos = [];

      // jogoRef (jogo único)
      if (data['jogoRef'] != null) {
        final jogoId = (data['jogoRef'] as DocumentReference).id;
        if (jogosMap.containsKey(jogoId)) {
          final codigo = jogosMap[jogoId]!['codigo']?.toString() ?? '';
          if (codigo.isNotEmpty) codigosJogos.add(codigo);
        }
      }

      // jogosRefs (múltiplos jogos)
      if (data['jogosRefs'] != null && data['jogosRefs'] is List) {
        for (var jogoRef in data['jogosRefs']) {
          if (jogoRef is DocumentReference) {
            final jogoId = jogoRef.id;
            if (jogosMap.containsKey(jogoId)) {
              final codigo = jogosMap[jogoId]!['codigo']?.toString() ?? '';
              if (codigo.isNotEmpty) codigosJogos.add(codigo);
            }
          }
        }
      }

      final checkpoint = CheckpointData(
        id: doc.id,
        nome: data['nome']?.toString() ?? '',
        ordemA: ordemA,
        ordemB: ordemB,
        percurso: percurso,
        codigosJogos: codigosJogos,
      );

      // Adicionar aos grupos apropriados
      if (percurso == 'A' || percurso == 'Ambos') {
        checkpointsA.add(checkpoint);
      }
      if (percurso == 'B' || percurso == 'Ambos') {
        checkpointsB.add(checkpoint);
      }
    }

    // Ordenar por ordem
    checkpointsA.sort((a, b) => a.ordemA.compareTo(b.ordemA));
    checkpointsB.sort((a, b) => a.ordemB.compareTo(b.ordemB));

    _checkpointsGrupoA = checkpointsA;
    _checkpointsGrupoB = checkpointsB;

    debugPrint('🎯 Checkpoints processados:');
    debugPrint('   - Grupo A: ${_checkpointsGrupoA.length}');
    debugPrint('   - Grupo B: ${_checkpointsGrupoB.length}');
  }

  // ✅ MÉTODOS REMOVIDOS - AGORA FAZEMOS TUDO EM LOTE
  // _getCheckpointStatus() e _getJogoStatus() removidos para evitar loops

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.grid_view, size: 24),
            SizedBox(width: 12),
            Text(
              'Grelha de Qualificação',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadEquipasData,
            icon:
                _isLoading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.refresh, size: 20),
            tooltip: 'Atualizar dados',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Header compacto otimizado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.red.shade600, Colors.red.shade500],
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'SHELL AO KM 2025',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Posições organizadas por grupos de percurso',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                _buildCompactQuickStats(),
              ],
            ),
          ),

          // Status/Error info
          if (_error != null) _buildErrorContainer(),
          if (_isLoading) _buildLoadingContainer(),

          // Conteúdo principal
          Expanded(
            child:
                _isLoading
                    ? _buildLoadingContent()
                    : _equipas.isEmpty
                    ? _buildEmptyContent()
                    : _buildQualificationGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactQuickStats() {
    final equipasGrupoA = _equipas.where((e) => e.grupo == 'A').length;
    final equipasGrupoB = _equipas.where((e) => e.grupo == 'B').length;
    final melhorPontuacao =
        _equipas.isNotEmpty ? _equipas.first.pontuacaoTotal : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCompactStatItem('Total', '${_equipas.length}', Icons.groups),
        _buildCompactStatItem('Grupo A', '$equipasGrupoA', Icons.flag),
        _buildCompactStatItem('Grupo B', '$equipasGrupoB', Icons.flag),
        _buildCompactStatItem('Melhor', '$melhorPontuacao pts', Icons.star),
      ],
    );
  }

  Widget _buildCompactStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(77)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContainer() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Erro ao carregar dados',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                Text(_error!, style: TextStyle(color: Colors.red.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContainer() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Carregando dados do Firebase...',
            style: TextStyle(color: Colors.blue.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Carregando grelha de qualificação...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhuma equipa encontrada',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'As equipas aparecerão aqui quando forem registadas',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildQualificationGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Títulos dos grupos
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade500],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withAlpha(77),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'GRUPO A',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          letterSpacing: 1.1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'PERCURSO NORTE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade500],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withAlpha(77),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'GRUPO B',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          letterSpacing: 1.1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'PERCURSO SUL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Grid das equipas
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildGridRows(),
          ),
        ],
      ),
    );
  }

  Widget _buildGridRows() {
    final equipasGrupoA = _equipas.where((e) => e.grupo == 'A').toList();
    final equipasGrupoB = _equipas.where((e) => e.grupo == 'B').toList();

    final maxRows = [
      equipasGrupoA.length,
      equipasGrupoB.length,
    ].reduce((a, b) => a > b ? a : b);

    if (maxRows == 0) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: const Center(
          child: Text(
            'Nenhuma equipa nos grupos A ou B',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(maxRows, (index) {
        final equipaA =
            index < equipasGrupoA.length ? equipasGrupoA[index] : null;
        final equipaB =
            index < equipasGrupoB.length ? equipasGrupoB[index] : null;

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade300,
                width: index < maxRows - 1 ? 1 : 0,
              ),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Grupo A
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.blue.shade50, Colors.blue.shade100],
                      ),
                    ),
                    child: _buildGridPosition(equipaA, index + 1, 'A'),
                  ),
                ),

                // Divisor central
                Container(
                  width: 6,
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.grey.shade300, Colors.grey.shade400],
                    ),
                  ),
                ),

                // Grupo B
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.green.shade100, Colors.green.shade50],
                      ),
                    ),
                    child: _buildGridPosition(equipaB, index + 1, 'B'),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGridPosition(
    EquipaGridData? equipa,
    int position,
    String grupo,
  ) {
    if (equipa == null) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Center(
                  child: Text(
                    'P$position',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'POSIÇÃO VAZIA',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final checkpoints = grupo == 'A' ? _checkpointsGrupoA : _checkpointsGrupoB;

    return Container(
      height: 220, // Aumentar altura para mais informação
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha 1: Posição, Dístico, Nome, Pontuação
          Row(
            children: [
              // Posição
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getPositionColor(position),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: _getPositionColor(position).withAlpha(77),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$position',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Dístico (mais visível)
              if (equipa.distico.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withAlpha(77),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '#${equipa.distico}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Nome da equipa
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipa.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Condutor mais visível
                    if (equipa.condutorNome.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 12,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              equipa.condutorNome,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Pontuação
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey.shade50],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${equipa.pontuacaoTotal}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Linha 2: Condutor e Veículo (SEMPRE VISÍVEIS)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Condutor
              if (equipa.condutorNome.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, size: 12, color: Colors.blue.shade600),
                      const SizedBox(width: 4),
                      Text(
                        equipa.condutorNome,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    'Condutor não definido',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              // Veículo
              if (equipa.modelo.isNotEmpty || equipa.matricula.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 12,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${equipa.modelo} ${equipa.matricula}'.trim(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    'Veículo não definido',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Linha 3: Checkpoints e Jogos alinhados
          Row(
            children: [
              // Labels
              SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Checkpoints:',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Jogos:',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // Checkpoints e Jogos alinhados verticalmente
              Expanded(
                child: Column(
                  children: [
                    // Checkpoints
                    Row(
                      children: List.generate(8, (index) {
                        final checkpointIndex = index + 1;
                        final checkpointId =
                            checkpoints.length > index
                                ? checkpoints[index].id
                                : '';
                        final status =
                            checkpointId.isNotEmpty
                                ? (equipa.checkpointStatus[checkpointId] ??
                                    CheckpointStatusEnum.naoCompleto)
                                : CheckpointStatusEnum.naoCompleto;

                        // DEBUG: Mostrar status real
                        debugPrint(
                          '🔍 Checkpoint C${checkpointIndex.toString().padLeft(2, '0')}: $status (ID: $checkpointId)',
                        );

                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            height: 22,
                            decoration: BoxDecoration(
                              color: _getCheckpointStatusColor(status),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color:
                                    status == CheckpointStatusEnum.naoCompleto
                                        ? Colors.grey.shade400
                                        : Colors.transparent,
                                width: 0.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'C${checkpointIndex.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 6),

                    // Jogos (alinhados com checkpoints)
                    Row(
                      children: List.generate(8, (index) {
                        final jogoIndex = index + 1;
                        final checkpointId =
                            checkpoints.length > index
                                ? checkpoints[index].id
                                : '';

                        // Verificar se algum jogo deste checkpoint foi feito
                        bool jogoFeito = false;
                        if (checkpointId.isNotEmpty &&
                            checkpoints.length > index) {
                          final checkpoint = checkpoints[index];
                          jogoFeito = checkpoint.codigosJogos.any(
                            (codigo) => equipa.jogoStatus[codigo] == true,
                          );
                        }

                        // DEBUG: Mostrar status real
                        debugPrint(
                          '🎮 Jogo J${jogoIndex.toString().padLeft(2, '0')}: $jogoFeito (Checkpoint: $checkpointId)',
                        );

                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            height: 22,
                            decoration: BoxDecoration(
                              color:
                                  jogoFeito
                                      ? Colors.green.shade600
                                      : Colors.grey.shade500,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color:
                                    jogoFeito
                                        ? Colors.transparent
                                        : Colors.grey.shade400,
                                width: 0.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'J${jogoIndex.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Método removido - já não é necessário
  // _getAllJogoCodigos() foi substituído pela lógica direta nos checkpoints

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber.shade600; // Ouro
      case 2:
        return Colors.grey.shade500; // Prata
      case 3:
        return Colors.brown.shade500; // Bronze
      case 4:
      case 5:
        return Colors.green.shade600; // Top 5
      case 6:
      case 7:
      case 8:
      case 9:
      case 10:
        return Colors.blue.shade600; // Top 10
      default:
        return Colors.red.shade600; // Restantes
    }
  }

  Color _getCheckpointStatusColor(CheckpointStatusEnum status) {
    switch (status) {
      case CheckpointStatusEnum.completo:
        return Colors.green.shade600; // 🟢 Completo (entrada + saída)
      case CheckpointStatusEnum.apenasEntrada:
        return Colors.orange.shade600; // 🟠 Apenas entrada
      case CheckpointStatusEnum.naoCompleto:
        return Colors.grey.shade500; // 🔘 Não visitado (era vermelho)
    }
  }
}

// ================================
// ENUMS E CLASSES AUXILIARES
// ================================

enum CheckpointStatusEnum { naoCompleto, apenasEntrada, completo }

class EquipaGridData {
  final String id;
  final String nome;
  final String condutorNome;
  final String modelo;
  final String matricula;
  final String distico;
  final String grupo;
  final int pontuacaoTotal;
  final String? bandeiraUrl;
  final Map<String, CheckpointStatusEnum> checkpointStatus;
  final Map<String, bool> jogoStatus;

  EquipaGridData({
    required this.id,
    required this.nome,
    required this.condutorNome,
    required this.modelo,
    required this.matricula,
    required this.distico,
    required this.grupo,
    required this.pontuacaoTotal,
    this.bandeiraUrl,
    required this.checkpointStatus,
    required this.jogoStatus,
  });
}

class CheckpointData {
  final String id;
  final String nome;
  final int ordemA;
  final int ordemB;
  final String percurso;
  final List<String> codigosJogos;

  CheckpointData({
    required this.id,
    required this.nome,
    required this.ordemA,
    required this.ordemB,
    required this.percurso,
    required this.codigosJogos,
  });
}
