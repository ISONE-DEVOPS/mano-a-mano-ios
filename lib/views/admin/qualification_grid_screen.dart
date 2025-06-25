// ================================
// QUALIFICATION GRID SCREEN
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
      ]);

      final equipasSnapshot = futures[0] as QuerySnapshot;
      final usersSnapshot = futures[1] as QuerySnapshot;
      final veiculosSnapshot = futures[2] as QuerySnapshot;
      final rankingSnapshot = futures[3] as QuerySnapshot;

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

      // Filtrar equipas (excluir admins)
      final filteredEquipas =
          equipasSnapshot.docs.where((doc) {
            final membros =
                (doc.data() as Map<String, dynamic>)['membros'] ?? [];
            if (membros is! List) return true;
            return !membros.any((uid) => usersMap[uid]?['tipo'] == 'admin');
          }).toList();

      // Processar equipas
      List<EquipaGridData> equipasData = [];

      for (var equipaDoc in filteredEquipas) {
        try {
          final equipaData = equipaDoc.data() as Map<String, dynamic>;
          final veiculoId = equipaData['veiculoId'] as String?;

          // Buscar dados do veículo
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

          // Buscar pontuação
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
          continue;
        }
      }

      // Ordenar por pontuação
      equipasData.sort((a, b) => b.pontuacaoTotal.compareTo(a.pontuacaoTotal));

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
            Icon(Icons.grid_view, size: 28),
            SizedBox(width: 12),
            Text(
              'Grelha de Qualificação',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadEquipasData,
            icon:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.refresh),
            tooltip: 'Atualizar dados',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Header com informações
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Posições organizadas por grupos de percurso',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                _buildQuickStats(),
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

  Widget _buildQuickStats() {
    final equipasGrupoA = _equipas.where((e) => e.grupo == 'A').length;
    final equipasGrupoB = _equipas.where((e) => e.grupo == 'B').length;
    final melhorPontuacao =
        _equipas.isNotEmpty ? _equipas.first.pontuacaoTotal : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Total', '${_equipas.length}', Icons.groups),
        _buildStatItem('Grupo A', '$equipasGrupoA', Icons.flag),
        _buildStatItem('Grupo B', '$equipasGrupoB', Icons.flag),
        _buildStatItem('Melhor', '$melhorPontuacao pts', Icons.star),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(77)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
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
                    child: _buildGridPosition(equipaA, index + 1, Colors.blue),
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
                    child: _buildGridPosition(equipaB, index + 1, Colors.green),
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
      height: 120,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Linha principal - posição, nome e pontuação
          Row(
            children: [
              // Número da posição
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
                    '$position',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Nome da equipa
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipa.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (equipa.condutorNome.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              equipa.condutorNome,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
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
                  '${equipa.pontuacaoTotal} pts',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: groupColor.shade700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

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
        ],
      ),
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
