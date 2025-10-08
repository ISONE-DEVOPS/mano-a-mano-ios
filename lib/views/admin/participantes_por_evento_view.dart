import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'edit_participantes.dart';

class ParticipantesPorEventoView extends StatefulWidget {
  const ParticipantesPorEventoView({super.key});

  @override
  State<ParticipantesPorEventoView> createState() =>
      _ParticipantesPorEventoViewState();
}

class _ParticipantesPorEventoViewState
    extends State<ParticipantesPorEventoView> {
  String? eventoSelecionadoId;
  String? edicaoSelecionadaId;
  String searchQuery = '';
  String? filtroEquipa;
  bool showOnlyWithPoints = false;
  String ordenacao = 'nome'; // nome, pontuacao, equipa
  bool ordenacaoDecrescente = false;

  final Map<String, String> equipasCache = {};
  final Map<String, int> pontuacoesCache = {};
  bool isLoadingStats = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Participantes por Evento'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _mostrarEstatisticas,
            tooltip: 'Estatísticas',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                pontuacoesCache.clear();
              });
            },
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildEventoSelector(),
          _buildSearchAndFilters(),
          if (eventoSelecionadoId != null) _buildQuickStats(),
          Expanded(child: _buildParticipantesList()),
        ],
      ),
    );
  }

  Widget _buildEventoSelector() {
    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecione o Evento',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('editions')
                .orderBy('dataInicio', descending: true)
                .snapshots(),
            builder: (context, edicoesSnapshot) {
              if (!edicoesSnapshot.hasData) {
                return const LinearProgressIndicator();
              }

              final edicoes = edicoesSnapshot.data!.docs;

              return DropdownButtonFormField<String>(
                initialValue: edicaoSelecionadaId,
                decoration: InputDecoration(
                  labelText: 'Edição',
                  prefixIcon: const Icon(Icons.event_note),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: edicoes.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(data['nome'] ?? 'Sem nome'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    edicaoSelecionadaId = value;
                    eventoSelecionadoId = null;
                    pontuacoesCache.clear();
                  });
                },
              );
            },
          ),
          if (edicaoSelecionadaId != null) ...[
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('editions')
                  .doc(edicaoSelecionadaId)
                  .collection('events')
                  .orderBy('data', descending: true)
                  .snapshots(),
              builder: (context, eventosSnapshot) {
                if (!eventosSnapshot.hasData) {
                  return const LinearProgressIndicator();
                }

                final eventos = eventosSnapshot.data!.docs;

                if (eventos.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Nenhum evento nesta edição'),
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  initialValue: eventoSelecionadoId,
                  decoration: InputDecoration(
                    labelText: 'Evento',
                    prefixIcon: const Icon(Icons.event),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: eventos.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = data['data'] as Timestamp?;
                    final dataFormatada = timestamp != null
                        ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}'
                        : '';
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            data['nome'] ?? 'Sem nome',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (dataFormatada.isNotEmpty)
                            Text(
                              dataFormatada,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      eventoSelecionadoId = value;
                      filtroEquipa = null;
                      pontuacoesCache.clear();
                    });
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    if (eventoSelecionadoId == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Pesquisar participante...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => setState(() => searchQuery = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('equipas')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();

                    final equipas = snapshot.data!.docs;
                    equipasCache.clear();
                    for (final doc in equipas) {
                      equipasCache[doc.id] =
                          (doc.data() as Map<String, dynamic>)['nome'] ??
                              'Sem nome';
                    }

                    return DropdownButtonFormField<String?>(
                      initialValue: filtroEquipa,
                      decoration: InputDecoration(
                        labelText: 'Equipa',
                        prefixIcon: const Icon(Icons.group),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todas'),
                        ),
                        ...equipas.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String?>(
                            value: doc.id,
                            child: Text(data['nome'] ?? 'Sem nome'),
                          );
                        }),
                      ],
                      onChanged: (value) =>
                          setState(() => filtroEquipa = value),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: ordenacao,
                  decoration: InputDecoration(
                    labelText: 'Ordenar',
                    prefixIcon: const Icon(Icons.sort),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'nome', child: Text('Nome')),
                    DropdownMenuItem(
                      value: 'pontuacao',
                      child: Text('Pontuação'),
                    ),
                    DropdownMenuItem(value: 'equipa', child: Text('Equipa')),
                  ],
                  onChanged: (value) =>
                      setState(() => ordenacao = value ?? 'nome'),
                ),
              ),
              IconButton(
                icon: Icon(
                  ordenacaoDecrescente
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                ),
                onPressed: () =>
                    setState(() => ordenacaoDecrescente = !ordenacaoDecrescente),
                tooltip: ordenacaoDecrescente ? 'Decrescente' : 'Crescente',
              ),
              IconButton(
                icon: Icon(
                  showOnlyWithPoints
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                  color: showOnlyWithPoints ? Colors.blue : null,
                ),
                onPressed: () =>
                    setState(() => showOnlyWithPoints = !showOnlyWithPoints),
                tooltip: 'Apenas com pontuação',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildParticipantesQuery(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final participantes = snapshot.data!.docs;
        final total = participantes.length;
        final comPontuacao = participantes
            .where((doc) =>
                (pontuacoesCache[doc.id] ?? 0) > 0 ||
                _hasPontuacao(doc.data() as Map<String, dynamic>))
            .length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[100],
          child: Row(
            children: [
              _buildStatChip(
                Icons.people,
                'Total',
                '$total',
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                Icons.emoji_events,
                'Com Pontos',
                '$comPontuacao',
                Colors.green,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                Icons.pending,
                'Sem Pontos',
                '${total - comPontuacao}',
                Colors.orange,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasPontuacao(Map<String, dynamic> data) {
    // Verifica se há algum indicador de pontuação no documento
    return false; // Ajuste conforme sua estrutura
  }

  Widget _buildParticipantesList() {
    if (eventoSelecionadoId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Selecione um evento para ver os participantes',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _buildParticipantesQuery(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Carregando participantes...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erro: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'Nenhum participante encontrado',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        var participantes = _filtrarEOrdenarParticipantes(snapshot.data!.docs);

        if (participantes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'Nenhum resultado encontrado',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  Text(
                    '${participantes.length} participante${participantes.length != 1 ? 's' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _exportarParticipantes(participantes),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Exportar CSV'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: participantes.length,
                itemBuilder: (context, index) {
                  return _buildParticipanteCard(participantes[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _filtrarEOrdenarParticipantes(
    List<QueryDocumentSnapshot> participantes,
  ) {
    // Filtrar por busca
    if (searchQuery.isNotEmpty) {
      participantes = participantes.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final nome = (data['nome'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        final query = searchQuery.toLowerCase();
        return nome.contains(query) || email.contains(query);
      }).toList();
    }

    // Filtrar por equipa
    if (filtroEquipa != null) {
      participantes = participantes.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['equipaId'] == filtroEquipa;
      }).toList();
    }

    // Filtrar apenas com pontuação
    if (showOnlyWithPoints) {
      participantes = participantes.where((doc) {
        return (pontuacoesCache[doc.id] ?? 0) > 0;
      }).toList();
    }

    // Ordenar
    participantes.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      int comparacao = 0;

      switch (ordenacao) {
        case 'nome':
          comparacao =
              (dataA['nome'] ?? '').toString().compareTo(
                    (dataB['nome'] ?? '').toString(),
                  );
          break;
        case 'pontuacao':
          final pontosA = pontuacoesCache[a.id] ?? 0;
          final pontosB = pontuacoesCache[b.id] ?? 0;
          comparacao = pontosA.compareTo(pontosB);
          break;
        case 'equipa':
          final equipaA = equipasCache[dataA['equipaId']] ?? '';
          final equipaB = equipasCache[dataB['equipaId']] ?? '';
          comparacao = equipaA.compareTo(equipaB);
          break;
      }

      return ordenacaoDecrescente ? -comparacao : comparacao;
    });

    return participantes;
  }

  Widget _buildParticipanteCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nome = data['nome'] ?? 'Sem nome';
    final email = data['email'] ?? '';
    final telefone = data['telefone'] ?? '';
    final equipaId = data['equipaId'];
    final nomeEquipa = equipaId != null ? equipasCache[equipaId] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirDetalhes(doc.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (nomeEquipa != null)
                          Row(
                            children: [
                              Icon(
                                Icons.group,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                nomeEquipa,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  FutureBuilder<int>(
                    future: _getPontuacaoTotal(doc.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          width: 80,
                          height: 32,
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final pontos = snapshot.data ?? 0;
                      if (!pontuacoesCache.containsKey(doc.id)) {
                        pontuacoesCache[doc.id] = pontos;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              pontos > 0
                                  ? Colors.green.shade100
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.emoji_events,
                              size: 16,
                              color: pontos > 0 ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$pontos pts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: pontos > 0 ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildInfoChip(Icons.email, email)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildInfoChip(Icons.phone, telefone)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _buildParticipantesQuery() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'user')
        .snapshots();
  }

  Future<int> _getPontuacaoTotal(String userId) async {
    try {
      if (eventoSelecionadoId == null) return 0;

      final eventosSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('eventos')
          .doc(eventoSelecionadoId)
          .collection('pontuacoes')
          .get();

      return eventosSnapshot.docs.fold<int>(0, (total, doc) {
        final data = doc.data();
        final pontos = data['pontuacaoTotal'] ?? 0;
        return total + (pontos as num).toInt();
      });
    } catch (e) {
      return 0;
    }
  }

  void _abrirDetalhes(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditParticipantesView(userId: userId),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {
          pontuacoesCache.clear();
        });
      }
    });
  }

  Future<void> _exportarParticipantes(
    List<QueryDocumentSnapshot> participantes,
  ) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Exportando dados...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Preparar dados para CSV
      List<List<dynamic>> rows = [];

      // Cabeçalho
      rows.add([
        'Nome',
        'Email',
        'Telefone',
        'Emergência',
        'T-shirt',
        'Equipa',
        'Pontuação Total',
      ]);

      // Dados dos participantes
      for (final doc in participantes) {
        final data = doc.data() as Map<String, dynamic>;
        final equipaId = data['equipaId'];
        final pontos = await _getPontuacaoTotal(doc.id);

        rows.add([
          data['nome'] ?? '',
          data['email'] ?? '',
          data['telefone'] ?? '',
          data['emergencia'] ?? '',
          data['tshirt'] ?? '',
          equipaId != null ? (equipasCache[equipaId] ?? '') : '',
          pontos,
        ]);
      }

      // Converter para CSV
      String csv = const ListToCsvConverter().convert(rows);

      // Salvar arquivo
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/participantes_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(csv);

      // Fechar loading
      if (mounted) Navigator.of(context).pop();

      // Compartilhar arquivo
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Participantes - $eventoSelecionadoId',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Arquivo CSV exportado com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Fechar loading se estiver aberto
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erro ao exportar: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarEstatisticas() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEstatisticasSheet(),
    );
  }

  Widget _buildEstatisticasSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildParticipantesQuery(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final participantes =
                  _filtrarEOrdenarParticipantes(snapshot.data!.docs);

              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Estatísticas do Evento',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Cards de estatísticas
                  _buildStatCard(
                    'Total de Participantes',
                    '${participantes.length}',
                    Icons.people,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'Com Pontuação',
                    '${participantes.where((p) => (pontuacoesCache[p.id] ?? 0) > 0).length}',
                    Icons.emoji_events,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'Pontuação Média',
                    _calcularMediaPontuacao(participantes),
                    Icons.bar_chart,
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'Pontuação Máxima',
                    _calcularMaximaPontuacao(participantes),
                    Icons.star,
                    Colors.amber,
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Top 5 Participantes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildTop5(participantes),

                  const SizedBox(height: 24),
                  const Text(
                    'Distribuição por Equipa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDistribuicaoEquipas(participantes),

                  const SizedBox(height: 24),
                  const Text(
                    'Gráfico de Pontuações',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: _buildGraficoPontuacoes(participantes),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calcularMediaPontuacao(List<QueryDocumentSnapshot> participantes) {
    if (participantes.isEmpty) return '0';

    final total = participantes.fold<int>(
      0,
      (acc, p) => acc + (pontuacoesCache[p.id] ?? 0),
    );

    final media = total / participantes.length;
    return media.toStringAsFixed(1);
  }

  String _calcularMaximaPontuacao(List<QueryDocumentSnapshot> participantes) {
    if (participantes.isEmpty) return '0';

    final maxima = participantes.fold<int>(
      0,
      (currentMax, p) {
        final pontos = pontuacoesCache[p.id] ?? 0;
        return pontos > currentMax ? pontos : currentMax;
      },
    );

    return maxima.toString();
  }

  Widget _buildTop5(List<QueryDocumentSnapshot> participantes) {
    final top5 = List<QueryDocumentSnapshot>.from(participantes)
      ..sort((a, b) {
        final pontosA = pontuacoesCache[a.id] ?? 0;
        final pontosB = pontuacoesCache[b.id] ?? 0;
        return pontosB.compareTo(pontosA);
      });

    final lista = top5.take(5).toList();

    if (lista.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Nenhum participante com pontuação'),
        ),
      );
    }

    return Column(
      children: lista.asMap().entries.map((entry) {
        final index = entry.key;
        final doc = entry.value;
        final data = doc.data() as Map<String, dynamic>;
        final pontos = pontuacoesCache[doc.id] ?? 0;

        Color medalColor;
        IconData medalIcon;

        switch (index) {
          case 0:
            medalColor = Colors.amber;
            medalIcon = Icons.emoji_events;
            break;
          case 1:
            medalColor = Colors.grey;
            medalIcon = Icons.emoji_events;
            break;
          case 2:
            medalColor = Colors.brown;
            medalIcon = Icons.emoji_events;
            break;
          default:
            medalColor = Colors.blue;
            medalIcon = Icons.star;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: medalColor,
              child: Icon(medalIcon, color: Colors.white),
            ),
            title: Text(
              data['nome'] ?? 'Sem nome',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              equipasCache[data['equipaId']] ?? 'Sem equipa',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$pontos pts',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDistribuicaoEquipas(List<QueryDocumentSnapshot> participantes) {
    final Map<String, int> distribuicao = {};

    for (final doc in participantes) {
      final data = doc.data() as Map<String, dynamic>;
      final equipaId = data['equipaId'] as String?;
      if (equipaId != null) {
        distribuicao[equipaId] = (distribuicao[equipaId] ?? 0) + 1;
      }
    }

    if (distribuicao.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Nenhuma equipa atribuída'),
        ),
      );
    }

    return Column(
      children: distribuicao.entries.map((entry) {
        final nomeEquipa = equipasCache[entry.key] ?? 'Sem nome';
        final quantidade = entry.value;
        final percentual =
            ((quantidade / participantes.length) * 100).toStringAsFixed(1);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      nomeEquipa,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$quantidade ($percentual%)',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: quantidade / participantes.length,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGraficoPontuacoes(List<QueryDocumentSnapshot> participantes) {
    // Agrupar pontuações em faixas
    final Map<String, int> faixas = {
      '0': 0,
      '1-50': 0,
      '51-100': 0,
      '101-150': 0,
      '151+': 0,
    };

    for (final doc in participantes) {
      final pontos = pontuacoesCache[doc.id] ?? 0;

      if (pontos == 0) {
        faixas['0'] = faixas['0']! + 1;
      } else if (pontos <= 50) {
        faixas['1-50'] = faixas['1-50']! + 1;
      } else if (pontos <= 100) {
        faixas['51-100'] = faixas['51-100']! + 1;
      } else if (pontos <= 150) {
        faixas['101-150'] = faixas['101-150']! + 1;
      } else {
        faixas['151+'] = faixas['151+']! + 1;
      }
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: faixas.values.reduce((a, b) => a > b ? a : b).toDouble() + 2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final faixa = faixas.keys.elementAt(group.x.toInt());
              return BarTooltipItem(
                '$faixa pontos\n${rod.toY.toInt()} participantes',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final faixa = faixas.keys.elementAt(value.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    faixa,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: faixas.entries.map((entry) {
          final index = faixas.keys.toList().indexOf(entry.key);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: Colors.blue,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}