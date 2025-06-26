// ================================
// QUALIFICATION GRID SCREEN - COM STATUS DE CHECKPOINTS E JOGOS
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
  bool _isLoading = true;
  String? _error;

  // Lista de códigos e descrições dos jogos
  List<Map<String, String>> _jogosCodigos = [];

  // Mapa de nomes dos checkpoints
  Map<String, String> _checkpointNomes = {};

  // Ordem dos checkpoints por grupo (dinâmico)
  Map<String, List<String>> _checkpointOrder = {'A': [], 'B': []};

  @override
  void initState() {
    super.initState();
    _loadEquipasData();
    _loadJogosCodigos();
    _loadCheckpointNomes();
  }

  Future<void> _loadCheckpointNomes() async {
    try {
      final snapshot =
          await _firestore
              .collection('editions')
              .doc('shell_2025')
              .collection('events')
              .doc('shell_km_02')
              .collection('checkpoints')
              .get();

      final nomes = <String, String>{};
      final ordemA = <MapEntry<int, String>>[];
      final ordemB = <MapEntry<int, String>>[];

      for (var doc in snapshot.docs) {
        final id = doc.id;
        final data = doc.data();
        final descricao = data['descricao']?.toString() ?? id;
        nomes[id] = descricao;

        final percurso = data['percurso']?.toString().toLowerCase();

        if (percurso == 'a' || percurso == 'ambos') {
          if (data.containsKey('ordemA') && data['ordemA'] is int) {
            ordemA.add(MapEntry(data['ordemA'] as int, id));
          }
        }
        if (percurso == 'b' || percurso == 'ambos') {
          if (data.containsKey('ordemB') && data['ordemB'] is int) {
            ordemB.add(MapEntry(data['ordemB'] as int, id));
          }
        }
      }

      ordemA.sort((a, b) => a.key.compareTo(b.key));
      ordemB.sort((a, b) => a.key.compareTo(b.key));

      setState(() {
        _checkpointNomes = nomes;
        _checkpointOrder = {
          'A': ordemA.map((e) => e.value).toList(),
          'B': ordemB.map((e) => e.value).toList(),
        };
      });
    } catch (e) {
      debugPrint('Erro ao carregar nomes dos checkpoints: $e');
    }
  }

  Future<void> _loadJogosCodigos() async {
    try {
      final snapshot =
          await _firestore
              .collection('jogos')
              .where('editionId', isEqualTo: 'shell_2025')
              .get();

      final codigos =
          snapshot.docs
              .map((doc) {
                final codigo = doc['codigo']?.toString();
                final descricao = doc['descricao']?.toString() ?? '';
                if (codigo != null) {
                  return {'codigo': codigo, 'descricao': descricao};
                }
                return null;
              })
              .whereType<Map<String, String>>()
              .toList();

      codigos.sort((a, b) => a['codigo']!.compareTo(b['codigo']!));
      setState(() {
        _jogosCodigos = codigos;
      });
    } catch (e) {
      debugPrint('Erro ao carregar jogos: $e');
    }
  }

  Future<void> _loadEquipasData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('🔄 Carregando dados da grelha de qualificação...');

      // Buscar apenas as coleções básicas primeiro (mais rápido)
      final futures = await Future.wait([
        _firestore.collection('equipas').get(),
        _firestore.collection('users').get(),
        _firestore.collection('veiculos').get(),
        _firestore.collection('ranking').get(),
      ]);

      final equipasSnapshot = futures[0] as QuerySnapshot;
      final usersSnapshot = futures[1] as QuerySnapshot;
      final veiculosSnapshot = futures[2] as QuerySnapshot;

      // Criar mapas para acesso rápido
      final Map<String, Map<String, dynamic>> usersMap = {
        for (var doc in usersSnapshot.docs)
          doc.id: doc.data() as Map<String, dynamic>,
      };

      final Map<String, Map<String, dynamic>> veiculosMap = {
        for (var doc in veiculosSnapshot.docs)
          doc.id: doc.data() as Map<String, dynamic>,
      };

      // Filtrar equipas (excluir admins)
      final filteredEquipas =
          equipasSnapshot.docs.where((doc) {
            final membros =
                (doc.data() as Map<String, dynamic>)['membros'] ?? [];
            if (membros is! List) return true;
            return !membros.any((uid) => usersMap[uid]?['tipo'] == 'admin');
          }).toList();

      // Buscar pontuações de todas as equipas em paralelo (otimizado)
      final equipasComStatus = await Future.wait(
        filteredEquipas.map((equipaDoc) async {
          try {
            final equipaData = equipaDoc.data() as Map<String, dynamic>;
            // NOVA LÓGICA baseada em ownerId (condutorId == primeiro membro)
            final membros = equipaData['membros'] as List<dynamic>? ?? [];
            final condutorId =
                membros.isNotEmpty ? membros[0].toString() : null;

            String modelo = '';
            String matricula = '';
            String condutorNome = '';
            String distico = '';

            MapEntry<String, Map<String, dynamic>>? veiculoMatch;
            if (condutorId != null) {
              try {
                veiculoMatch = veiculosMap.entries.firstWhere(
                  (entry) =>
                      entry.value['ownerId'] == condutorId ||
                      entry.value['condutorId'] == condutorId,
                  orElse: () => const MapEntry('', {}),
                );
              } catch (_) {
                veiculoMatch = null;
              }
            }

            if (veiculoMatch != null && veiculoMatch.key.isNotEmpty) {
              final veiculoData = veiculoMatch.value;
              final statusData = await _loadEquipaStatusOptimized(
                equipaDoc.id,
                equipaData,
              );
              modelo = veiculoData['modelo']?.toString() ?? '';
              matricula = veiculoData['matricula']?.toString() ?? '';
              distico =
                  veiculoData['distico'] != null
                      ? veiculoData['distico'].toString()
                      : '';

              final condutorFieldId = veiculoData['condutorId'] as String?;
              if (condutorFieldId != null &&
                  usersMap.containsKey(condutorFieldId)) {
                condutorNome =
                    usersMap[condutorFieldId]!['nome']?.toString() ?? '';
              }

              // Calcular pontuação real somando respostas e jogos dos membros
              int pontuacaoTotal = 0;
              int tempoTotal = 0;
              for (var resultado in statusData['rawPontuacoes'] ?? []) {
                if (resultado == null) continue;

                final pontuacoesDocs =
                    resultado['pontuacoes'] as List<QueryDocumentSnapshot>;

                for (var doc in pontuacoesDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final pergunta = (data['pontuacaoPergunta'] ?? 0) as num;
                  final jogo = (data['pontuacaoJogo'] ?? 0) as num;
                  pontuacaoTotal += pergunta.toInt() + jogo.toInt();

                  final entrada = data['timestampEntrada']?.toDate();
                  final saida = data['timestampSaida']?.toDate();
                  if (entrada != null && saida != null) {
                    tempoTotal +=
                        (saida.difference(entrada).inSeconds as num).toInt();
                  }
                }
              }

              return EquipaGridData(
                id: equipaDoc.id,
                nome:
                    equipaData['nome']?.toString() ??
                    'Equipa ${filteredEquipas.indexOf(equipaDoc) + 1}',
                condutorNome: condutorNome,
                modelo: modelo,
                matricula: matricula,
                distico: distico,
                grupo: equipaData['grupo']?.toString() ?? 'A',
                pontuacaoTotal: pontuacaoTotal,
                tempoTotal: tempoTotal,
                bandeiraUrl: equipaData['bandeiraUrl']?.toString(),
                checkpointStatus: Map<String, CheckpointStatus>.from(
                  statusData['checkpoints'] ?? {},
                ),
                jogosStatus: Map<String, bool>.from(statusData['jogos'] ?? {}),
              );
            }

            // Buscar status otimizado
            final statusData = await _loadEquipaStatusOptimized(
              equipaDoc.id,
              equipaData,
            );

            // Caso não haja veículo, usar distico vazio
            // Calcular pontuação real somando respostas e jogos dos membros
            int pontuacaoTotal = 0;
            int tempoTotal = 0;
            for (var resultado in statusData['rawPontuacoes'] ?? []) {
              if (resultado == null) continue;

              final pontuacoesDocs =
                  resultado['pontuacoes'] as List<QueryDocumentSnapshot>;

              for (var doc in pontuacoesDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final pergunta = (data['pontuacaoPergunta'] ?? 0) as num;
                final jogo = (data['pontuacaoJogo'] ?? 0) as num;
                pontuacaoTotal += pergunta.toInt() + jogo.toInt();

                final entrada = data['timestampEntrada']?.toDate();
                final saida = data['timestampSaida']?.toDate();
                if (entrada != null && saida != null) {
                  tempoTotal +=
                      (saida.difference(entrada).inSeconds as num).toInt();
                }
              }
            }

            return EquipaGridData(
              id: equipaDoc.id,
              nome:
                  equipaData['nome']?.toString() ??
                  'Equipa ${filteredEquipas.indexOf(equipaDoc) + 1}',
              condutorNome: condutorNome,
              modelo: modelo,
              matricula: matricula,
              distico: '',
              grupo: equipaData['grupo']?.toString() ?? 'A',
              pontuacaoTotal: pontuacaoTotal,
              tempoTotal: tempoTotal,
              bandeiraUrl: equipaData['bandeiraUrl']?.toString(),
              checkpointStatus: Map<String, CheckpointStatus>.from(
                statusData['checkpoints'] ?? {},
              ),
              jogosStatus: Map<String, bool>.from(statusData['jogos'] ?? {}),
            );
          } catch (e) {
            debugPrint('⚠️ Erro ao processar equipa ${equipaDoc.id}: $e');
            return null;
          }
        }),
      );

      // Filtrar nulls e ordenar
      final equipasData =
          equipasComStatus
              .where((equipa) => equipa != null)
              .cast<EquipaGridData>()
              .toList();

      equipasData.sort((a, b) {
        final aD = int.tryParse(a.distico) ?? 9999;
        final bD = int.tryParse(b.distico) ?? 9999;
        return aD.compareTo(bD);
      });

      if (!mounted) return;

      setState(() {
        _equipas = equipasData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erro ao carregar dados: $e');

      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Função otimizada que busca status de checkpoints e jogos em uma única consulta
  Future<Map<String, dynamic>> _loadEquipaStatusOptimized(
    String equipaId,
    Map<String, dynamic> equipaData,
  ) async {
    try {
      final membros = equipaData['membros'] as List<dynamic>? ?? [];
      if (membros.isEmpty) return {'checkpoints': {}, 'jogos': {}};

      Map<String, CheckpointStatus> checkpointStatus = {};
      Map<String, bool> jogosStatus = {};

      // Buscar pontuações de todos os membros em paralelo
      final pontuacoesFutures =
          membros.map((membroId) async {
            if (membroId == null) return null;

            try {
              // Buscar na estrutura correta: users/{uid}/eventos/shell_2025/pontuacoes
              final pontuacoesSnapshot =
                  await _firestore
                      .collection('users')
                      .doc(membroId.toString())
                      .collection('eventos')
                      .doc('shell_2025')
                      .collection('pontuacoes')
                      .get();

              return {
                'membroId': membroId,
                'pontuacoes': pontuacoesSnapshot.docs,
              };
            } catch (e) {
              debugPrint('❌ Erro ao buscar pontuações do membro $membroId: $e');
              return null;
            }
          }).toList();

      final resultados = await Future.wait(pontuacoesFutures);

      // Processar resultados
      for (var resultado in resultados) {
        if (resultado == null) continue;

        final pontuacoesDocs =
            resultado['pontuacoes'] as List<QueryDocumentSnapshot>;

        for (var pontuacaoDoc in pontuacoesDocs) {
          final data = pontuacaoDoc.data() as Map<String, dynamic>;
          final checkpointId = pontuacaoDoc.id;

          // Processar status do checkpoint
          final hasEntrada = data['timestampEntrada'] != null;
          final hasSaida = data['timestampSaida'] != null;

          CheckpointStatusType statusType;
          if (hasEntrada && hasSaida) {
            statusType = CheckpointStatusType.completo;
          } else if (hasEntrada) {
            statusType = CheckpointStatusType.apenasEntrada;
          } else {
            statusType = CheckpointStatusType.naoCompleto;
          }

          // Manter o melhor status encontrado
          if (!checkpointStatus.containsKey(checkpointId) ||
              statusType.index > checkpointStatus[checkpointId]!.status.index) {
            checkpointStatus[checkpointId] = CheckpointStatus(
              checkpointId: checkpointId,
              status: statusType,
              timestampEntrada: data['timestampEntrada'],
              timestampSaida: data['timestampSaida'],
            );
          }

          // Processar jogos pontuados
          final jogosPontuados =
              data['jogosPontuados'] as Map<String, dynamic>?;
          if (jogosPontuados != null) {
            jogosPontuados.forEach((jogoId, pontuacao) {
              if (pontuacao != null && pontuacao > 0) {
                jogosStatus[jogoId] = true;
              }
            });
          }
        }
      }

      return {
        'checkpoints': checkpointStatus,
        'jogos': jogosStatus,
        'rawPontuacoes': resultados,
      };
    } catch (e) {
      debugPrint('❌ Erro ao carregar status da equipa $equipaId: $e');
      return {'checkpoints': {}, 'jogos': {}};
    }
  }

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
                  'Status de checkpoints e jogos por equipa',
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
                    child: _buildGridPosition(
                      equipaA,
                      index + 1,
                      Colors.blue,
                      'A',
                    ),
                  ),
                ),

                // Divisor central
                Container(
                  width: 6,
                  height: 120,
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
                    child: _buildGridPosition(
                      equipaB,
                      index + 1,
                      Colors.green,
                      'B',
                    ),
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
    MaterialColor groupColor,
    String grupo,
  ) {
    if (equipa == null) {
      return Container(
        height: 120,
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

    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha principal - posição, dístico, nome e pontuação
          Row(
            children: [
              // Bloco circular com número da posição
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getPositionColor(position),
                      _getPositionColor(position).withAlpha(204),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _getPositionColor(position).withAlpha(77),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$positionº',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Dístico
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_taxi, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      equipa.distico.isNotEmpty
                          ? equipa.distico
                          : 'Sem Dístico',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Nome da equipa
              Expanded(
                child: Text(
                  equipa.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Pontuação
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: groupColor.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: groupColor.shade100,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${equipa.pontuacaoTotal}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: groupColor.shade700,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Tempo total
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Text(
                  '${(equipa.tempoTotal / 60).toStringAsFixed(1)} min',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Condutor
          if (equipa.condutorNome.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text(
                    equipa.condutorNome,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Informações do veículo
          if (equipa.modelo.isNotEmpty || equipa.matricula.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${equipa.modelo} • ${equipa.matricula}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

          // Espaçamento extra entre dados do veículo e blocos de status
          const SizedBox(height: 12),

          const Spacer(),

          // Status dos checkpoints e jogos (horizontal)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkpoints
              Row(
                children: [
                  Text(
                    'Checkpoints:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCheckpointStatusHorizontal(equipa, grupo),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Jogos
              Row(
                children: [
                  Text(
                    'Jogos:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _buildJogosStatusHorizontal(equipa)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckpointStatusHorizontal(EquipaGridData equipa, String grupo) {
    final checkpointsOrdem = _checkpointOrder[grupo] ?? [];

    return Row(
      children:
          checkpointsOrdem.asMap().entries.map((entry) {
            final index = entry.key;
            final checkpointId = entry.value;

            CheckpointStatus? status = equipa.checkpointStatus[checkpointId];
            Color cor = Colors.red.shade600; // Padrão: vermelho (não completo)

            if (status != null) {
              switch (status.status) {
                case CheckpointStatusType.completo:
                  cor = Colors.green.shade600; // Verde
                  break;
                case CheckpointStatusType.apenasEntrada:
                  cor = Colors.orange.shade600; // Laranja
                  break;
                case CheckpointStatusType.naoCompleto:
                  cor = Colors.red.shade600; // Vermelho
                  break;
              }
            }

            final descricao =
                _checkpointNomes[checkpointId] ?? 'CP ${index + 1}';

            return Expanded(
              child: Container(
                height: 24,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Tooltip(
                    message: descricao,
                    child: Text(
                      descricao,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildJogosStatusHorizontal(EquipaGridData equipa) {
    final jogosCodigos = _jogosCodigos;

    return Row(
      children:
          jogosCodigos.map((jogo) {
            final codigo = jogo['codigo']!;
            final descricao = jogo['descricao'] ?? codigo;
            final feito = equipa.jogosStatus[codigo] == true;

            return Expanded(
              child: Container(
                height: 24,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: feito ? Colors.green.shade600 : Colors.red.shade600,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Tooltip(
                    message: descricao,
                    child: Text(
                      codigo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

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
}

// ================================
// DATA CLASSES
// ================================

class EquipaGridData {
  final String id;
  final String nome;
  final String condutorNome;
  final String modelo;
  final String matricula;
  final String distico;
  final String grupo;
  final int pontuacaoTotal;
  final int tempoTotal;
  final String? bandeiraUrl;
  final Map<String, CheckpointStatus> checkpointStatus;
  final Map<String, bool> jogosStatus;

  EquipaGridData({
    required this.id,
    required this.nome,
    required this.condutorNome,
    required this.modelo,
    required this.matricula,
    required this.distico,
    required this.grupo,
    required this.pontuacaoTotal,
    required this.tempoTotal,
    this.bandeiraUrl,
    required this.checkpointStatus,
    required this.jogosStatus,
  });
}

class CheckpointStatus {
  final String checkpointId;
  final CheckpointStatusType status;
  final dynamic timestampEntrada;
  final dynamic timestampSaida;

  CheckpointStatus({
    required this.checkpointId,
    required this.status,
    this.timestampEntrada,
    this.timestampSaida,
  });
}

enum CheckpointStatusType {
  naoCompleto, // Vermelho - não completo (sem entrada ou apenas entrada sem saída) - INDEX 0
  apenasEntrada, // Laranja - apenas entrada registrada - INDEX 1
  completo, // Verde - tem entrada E saída - INDEX 2
}
