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

  @override
  void initState() {
    super.initState();
    _loadEquipasData();
  }

  Future<void> _loadEquipasData() async {
    setState(() => _isLoading = true);

    try {
      // Carrega equipas
      final equipasSnapshot = await _firestore.collection('equipas').get();

      // Carrega users
      final usersSnapshot = await _firestore.collection('users').get();
      final Map<String, Map<String, dynamic>> usersMap = {
        for (var u in usersSnapshot.docs) u.id: u.data(),
      };

      // Filtra equipas para excluir as que têm pelo menos um membro admin
      final filteredEquipas =
          equipasSnapshot.docs.where((doc) {
            final membros = (doc['membros'] ?? []) as List<dynamic>;
            return !membros.any((uid) => usersMap[uid]?['tipo'] == 'admin');
          }).toList();

      List<EquipaGridData> equipasData = [];

      for (var equipaDoc in filteredEquipas) {
        final equipaData = equipaDoc.data();
        final veiculoId = equipaData['veiculoId'];

        // Busca dados do veículo
        String modelo = '';
        String matricula = '';
        String condutorNome = '';

        if (veiculoId != null) {
          final veiculoDoc =
              await _firestore.collection('veiculos').doc(veiculoId).get();
          final veiculoData = veiculoDoc.data();

          if (veiculoData != null) {
            modelo = veiculoData['modelo'] ?? '';
            matricula = veiculoData['matricula'] ?? '';

            final condutorId = veiculoData['condutorId'];
            if (condutorId != null) {
              final condutorDoc =
                  await _firestore.collection('users').doc(condutorId).get();
              final condutorData = condutorDoc.data();
              condutorNome = condutorData?['nome'] ?? '';
            }
          }
        }

        // Calcula pontuação total (simulada - você pode adaptar conforme sua lógica)
        int pontuacaoTotal = 0;
        try {
          final rankingSnapshot =
              await _firestore
                  .collection('ranking')
                  .where('equipaId', isEqualTo: equipaDoc.id)
                  .get();

          if (rankingSnapshot.docs.isNotEmpty) {
            pontuacaoTotal =
                rankingSnapshot.docs.first.data()['pontuacao'] ?? 0;
          }
        } catch (e) {
          debugPrint('Erro ao buscar ranking para ${equipaDoc.id}: $e');
        }

        equipasData.add(
          EquipaGridData(
            id: equipaDoc.id,
            nome: equipaData['nome'] ?? 'Equipa ${equipasData.length + 1}',
            condutorNome: condutorNome,
            modelo: modelo,
            matricula: matricula,
            grupo: equipaData['grupo'] ?? 'A',
            pontuacaoTotal: pontuacaoTotal,
            bandeiraUrl: equipaData['bandeiraUrl'],
          ),
        );
      }

      // Ordena por pontuação (maior para menor) para simular qualificação
      equipasData.sort((a, b) => b.pontuacaoTotal.compareTo(a.pontuacaoTotal));

      setState(() {
        _equipas = equipasData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados das equipas: $e');
      setState(() => _isLoading = false);
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
                onPressed: _loadEquipasData,
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.red))
          else if (_equipas.isEmpty)
            const Center(
              child: Text(
                'Nenhuma equipa encontrada',
                style: TextStyle(fontSize: 18, color: Colors.grey),
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
          // Estatísticas da qualificação
          QualificationStats(equipas: _equipas),

          const SizedBox(height: 24),

          // Opções de visualização
          Row(
            children: [
              const Text(
                'Visualização:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'grid',
                    label: Text('Grelha'),
                    icon: Icon(Icons.grid_view),
                  ),
                  ButtonSegment(
                    value: 'list',
                    label: Text('Lista'),
                    icon: Icon(Icons.list),
                  ),
                ],
                selected: {'grid'},
                onSelectionChanged: (Set<String> selection) {
                  // Implementar mudança de visualização se necessário
                },
              ),
            ],
          ),

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
                // Posição e Equipa A
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.blue.shade50,
                          Colors.blue.shade100,
                        ],
                      ),
                    ),
                    child: _buildGridPosition(
                      equipaA,
                      index + 1,
                      Colors.transparent,
                    ),
                  ),
                ),

                // Divisor central com estilo F1
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.grey.shade400,
                        Colors.grey.shade300,
                        Colors.grey.shade400,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 20,
                        width: 4,
                        color: Colors.red.shade600,
                      ),
                      Expanded(
                        child: Container(width: 2, color: Colors.grey.shade300),
                      ),
                      Container(
                        height: 20,
                        width: 4,
                        color: Colors.red.shade600,
                      ),
                    ],
                  ),
                ),

                // Posição e Equipa B
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.green.shade100,
                          Colors.green.shade50,
                        ],
                      ),
                    ),
                    child: _buildGridPosition(
                      equipaB,
                      index + 1,
                      Colors.transparent,
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
    Color backgroundColor,
  ) {
    if (equipa == null) {
      return Container(
        height: 100,
        color: backgroundColor,
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
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Color positionColor = _getPositionColor(position);

    return Container(
      height: 100,
      color: backgroundColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Linha superior: Posição + Nome da equipa
          Row(
            children: [
              // Número da posição com estilo F1
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [positionColor, positionColor.withAlpha(204)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: positionColor.withAlpha(102),
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
                      fontSize: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Bandeira da equipa
              Container(
                width: 32,
                height: 22,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child:
                      equipa.bandeiraUrl != null &&
                              equipa.bandeiraUrl!.isNotEmpty
                          ? Image.network(
                            equipa.bandeiraUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.flag,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                          : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.flag,
                              size: 12,
                              color: Colors.grey,
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
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

          // Linha inferior: Informações do condutor e veículo
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  equipa.condutorNome,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          Row(
            children: [
              Icon(Icons.directions_car, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${equipa.modelo} • ${equipa.matricula}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
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
        return Colors.grey.shade400; // Prata
      case 3:
        return Colors.brown.shade400; // Bronze
      case 4:
      case 5:
        return Colors.green.shade600; // Q3
      case 6:
      case 7:
      case 8:
      case 9:
      case 10:
        return Colors.blue.shade600; // Q2
      default:
        return Colors.red.shade600; // Q1/Eliminados
    }
  }
}

// ======================================
// CLASSES AUXILIARES (do código #3)
// ======================================

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

// Widget para exibir estatísticas da qualificação
class QualificationStats extends StatelessWidget {
  final List<EquipaGridData> equipas;

  const QualificationStats({super.key, required this.equipas});

  @override
  Widget build(BuildContext context) {
    final equipasGrupoA = equipas.where((e) => e.grupo == 'A').length;
    final equipasGrupoB = equipas.where((e) => e.grupo == 'B').length;
    final melhorPontuacao =
        equipas.isNotEmpty ? equipas.first.pontuacaoTotal : 0;
    final pontuacaoMedia =
        equipas.isNotEmpty
            ? (equipas.map((e) => e.pontuacaoTotal).reduce((a, b) => a + b) /
                    equipas.length)
                .round()
            : 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Estatísticas da Qualificação',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total de Equipas',
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
                  'Melhor Pontuação',
                  '$melhorPontuacao pts',
                  Icons.star,
                  Colors.amber.shade600,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Pontuação Média',
                  '$pontuacaoMedia pts',
                  Icons.bar_chart,
                  Colors.purple.shade600,
                ),
              ),
            ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
