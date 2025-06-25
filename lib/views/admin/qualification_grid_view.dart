import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QualificationGridView extends StatefulWidget {
  const QualificationGridView({super.key});

  @override
  State<QualificationGridView> createState() => _QualificationGridViewState();
}

class _QualificationGridViewState extends State<QualificationGridView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<EquipaGridData> _equipas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEquipasData();
  }

  // ✅ VERSÃO OTIMIZADA - SEM LOOPS
  Future<void> _loadEquipasData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('🔄 Iniciando carregamento de dados...');

      // 1. Buscar todas as coleções em paralelo (não sequencial)
      final futures = await Future.wait([
        _firestore.collection('equipas').get(),
        _firestore.collection('users').get(),
        _firestore.collection('veiculos').get(),
        _firestore.collection('ranking').get(),
      ]);

      final equipasSnapshot = futures[0] as QuerySnapshot;
      final usersSnapshot = futures[1] as QuerySnapshot;
      final veiculosSnapshot = futures[2] as QuerySnapshot;
      final rankingSnapshot = futures[3] as QuerySnapshot;

      debugPrint('✅ Dados carregados:');
      debugPrint('   - Equipas: ${equipasSnapshot.docs.length}');
      debugPrint('   - Users: ${usersSnapshot.docs.length}');
      debugPrint('   - Veículos: ${veiculosSnapshot.docs.length}');
      debugPrint('   - Rankings: ${rankingSnapshot.docs.length}');

      // 2. Criar mapas para acesso rápido (O(1) ao invés de O(n))
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

      // 3. Filtrar equipas (excluir admins)
      final filteredEquipas =
          equipasSnapshot.docs.where((doc) {
            final membros =
                (doc.data() as Map<String, dynamic>)['membros'] ?? [];
            if (membros is! List) return true;

            return !membros.any((uid) => usersMap[uid]?['tipo'] == 'admin');
          }).toList();

      debugPrint('🔍 Equipas filtradas: ${filteredEquipas.length}');

      // 4. Processar equipas (sem loops aninhados)
      List<EquipaGridData> equipasData = [];

      for (var equipaDoc in filteredEquipas) {
        try {
          final equipaData = equipaDoc.data() as Map<String, dynamic>;
          final veiculoId = equipaData['veiculoId'] as String?;

          // Buscar dados do veículo (acesso direto, não query)
          String modelo = '';
          String matricula = '';
          String condutorNome = '';

          if (veiculoId != null && veiculosMap.containsKey(veiculoId)) {
            final veiculoData = veiculosMap[veiculoId]!;
            modelo = veiculoData['modelo']?.toString() ?? '';
            matricula = veiculoData['matricula']?.toString() ?? '';

            final condutorId = veiculoData['condutorId'] as String?;
            if (condutorId != null && usersMap.containsKey(condutorId)) {
              condutorNome = usersMap[condutorId]!['nome']?.toString() ?? '';
            }
          }

          // Buscar pontuação (acesso direto, não query)
          int pontuacaoTotal = 0;
          if (rankingMap.containsKey(equipaDoc.id)) {
            pontuacaoTotal = rankingMap[equipaDoc.id]!['pontuacao'] ?? 0;
          }

          equipasData.add(
            EquipaGridData(
              id: equipaDoc.id,
              nome:
                  equipaData['nome']?.toString() ??
                  'Equipa ${equipasData.length + 1}',
              condutorNome: condutorNome,
              modelo: modelo,
              matricula: matricula,
              grupo: equipaData['grupo']?.toString() ?? 'A',
              pontuacaoTotal: pontuacaoTotal,
              bandeiraUrl: equipaData['bandeiraUrl']?.toString(),
            ),
          );
        } catch (e) {
          debugPrint('⚠️ Erro ao processar equipa ${equipaDoc.id}: $e');
          continue; // Pular esta equipa e continuar
        }
      }

      // 5. Ordenar por pontuação
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.grid_view, size: 32, color: Colors.red),
              const SizedBox(width: 16),
              const Text(
                '🏁 GRELHA DE QUALIFICAÇÃO',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
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
                        : const Icon(Icons.refresh),
                label: Text(_isLoading ? 'Carregando...' : 'Atualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Debug info
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
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
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Status info
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  _isLoading
                      ? 'Carregando dados do Firebase...'
                      : 'Equipas carregadas: ${_equipas.length}',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ],
            ),
          ),

          // Conteúdo
          if (_isLoading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.red),
                    SizedBox(height: 16),
                    Text('Carregando equipas...'),
                  ],
                ),
              ),
            )
          else if (_equipas.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Nenhuma equipa encontrada',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(child: _buildQualificationGrid()),
        ],
      ),
    );
  }

  Widget _buildQualificationGrid() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Estatísticas
          QualificationStats(equipas: _equipas),

          const SizedBox(height: 24),

          // Título dos grupos
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'GRUPO A',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'PERCURSO NORTE',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.green.shade400],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'GRUPO B',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'PERCURSO SUL',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
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
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
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
            style: TextStyle(color: Colors.grey),
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
            color: Colors.white,
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
                    child: _buildGridPosition(equipaA, index + 1),
                  ),
                ),

                // Divisor
                Container(width: 4, height: 100, color: Colors.grey.shade300),

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
                    child: _buildGridPosition(equipaB, index + 1),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGridPosition(EquipaGridData? equipa, int position) {
    if (equipa == null) {
      return Container(
        height: 100,
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'P$position',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'VAZIA',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              // Posição
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getPositionColor(position),
                  borderRadius: BorderRadius.circular(8),
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

              // Nome da equipa
              Expanded(
                child: Text(
                  equipa.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Pontuação
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  '${equipa.pontuacaoTotal}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Informações adicionais
          Row(
            children: [
              Icon(Icons.person, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  equipa.condutorNome,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          Row(
            children: [
              Icon(Icons.directions_car, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${equipa.modelo} • ${equipa.matricula}',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber.shade600;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade400;
      case 4:
      case 5:
        return Colors.green.shade600;
      case 6:
      case 7:
      case 8:
      case 9:
      case 10:
        return Colors.blue.shade600;
      default:
        return Colors.red.shade600;
    }
  }
}

// Classes auxiliares (mantidas iguais)
class EquipaGridData {
  final String id;
  final String nome;
  final String condutorNome;
  final String modelo;
  final String matricula;
  final String grupo;
  final int pontuacaoTotal;
  final String? bandeiraUrl;

  EquipaGridData({
    required this.id,
    required this.nome,
    required this.condutorNome,
    required this.modelo,
    required this.matricula,
    required this.grupo,
    required this.pontuacaoTotal,
    this.bandeiraUrl,
  });
}

class QualificationStats extends StatelessWidget {
  final List<EquipaGridData> equipas;

  const QualificationStats({super.key, required this.equipas});

  @override
  Widget build(BuildContext context) {
    final equipasGrupoA = equipas.where((e) => e.grupo == 'A').length;
    final equipasGrupoB = equipas.where((e) => e.grupo == 'B').length;
    final melhorPontuacao =
        equipas.isNotEmpty ? equipas.first.pontuacaoTotal : 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total',
              '${equipas.length}',
              Icons.groups,
              Colors.red.shade600,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Grupo A',
              '$equipasGrupoA',
              Icons.flag,
              Colors.blue.shade600,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Grupo B',
              '$equipasGrupoB',
              Icons.flag,
              Colors.green.shade600,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Melhor',
              '$melhorPontuacao pts',
              Icons.star,
              Colors.amber.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
