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
  String ordenacao = 'nome';
  bool ordenacaoDecrescente = false;

  final Map<String, String> equipasCache = {};
  final Map<String, int> pontuacoesCache = {};

  // Cores em sintonia com o logo Shell
  static const Color primaryYellow = Color(0xFFFBBC04);
  static const Color primaryOrange = Color(0xFFFF6F00);
  static const Color primaryRed = Color(0xFFE53935);
  static const Color lightYellow = Color(0xFFFFF9C4);
  static const Color lightOrange = Color(0xFFFFE0B2);
  static const Color lightRed = Color(0xFFFFCDD2);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFC8E6C9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryOrange, primaryRed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.people, color: primaryOrange, size: 24),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Participantes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Gestão de Participantes por Evento',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            onPressed: _mostrarEstatisticas,
            tooltip: 'Estatísticas',
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() => pontuacoesCache.clear()),
            tooltip: 'Atualizar',
          ),
        ),
      ],
    );
  }

  Widget _buildEventoSelector() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lightYellow, lightOrange.withValues(alpha: 0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.event_note, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Selecione o Evento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('editions')
                .orderBy('dataInicio', descending: true)
                .snapshots(),
            builder: (context, edicoesSnapshot) {
              if (!edicoesSnapshot.hasData) {
                return const LinearProgressIndicator(
                  backgroundColor: lightYellow,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
                );
              }

              final edicoes = edicoesSnapshot.data!.docs;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryOrange.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: edicaoSelecionadaId,
                  decoration: InputDecoration(
                    labelText: 'Edição do Evento',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    prefixIcon: const Icon(Icons.event_note, color: primaryOrange),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryOrange, width: 2),
                    ),
                  ),
                  items: edicoes.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(
                        data['nome'] ?? 'Sem nome',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      edicaoSelecionadaId = value;
                      eventoSelecionadoId = null;
                      pontuacoesCache.clear();
                    });
                  },
                ),
              );
            },
          ),
          if (edicaoSelecionadaId != null) ...[
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('editions')
                  .doc(edicaoSelecionadaId)
                  .collection('events')
                  .orderBy('data', descending: true)
                  .snapshots(),
              builder: (context, eventosSnapshot) {
                if (!eventosSnapshot.hasData) {
                  return const LinearProgressIndicator(
                    backgroundColor: lightYellow,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
                  );
                }

                final eventos = eventosSnapshot.data!.docs;

                if (eventos.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: primaryOrange),
                        const SizedBox(width: 12),
                        const Text(
                          'Nenhum evento nesta edição',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryOrange.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: eventoSelecionadoId,
                    decoration: InputDecoration(
                      labelText: 'Evento Específico',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      prefixIcon: const Icon(Icons.event, color: primaryRed),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryRed, width: 2),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
                  ),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Barra de pesquisa
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryYellow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar participante...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: primaryOrange),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () => setState(() => searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryOrange, width: 2),
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          const SizedBox(height: 12),
          // Filtros
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

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryYellow.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: filtroEquipa,
                        decoration: InputDecoration(
                          labelText: 'Equipa',
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          prefixIcon: const Icon(Icons.group, color: primaryYellow),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todas'),
                          ),
                          ...equipas.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(data['nome'] ?? 'Sem nome'),
                            );
                          }),
                        ],
                        onChanged: (value) =>
                            setState(() => filtroEquipa = value),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryYellow.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: ordenacao,
                    decoration: InputDecoration(
                      labelText: 'Ordenar',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      prefixIcon: const Icon(Icons.sort, color: primaryRed),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
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
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: ordenacaoDecrescente ? primaryOrange : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryYellow.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                ),
                child: IconButton(
                  icon: Icon(
                    ordenacaoDecrescente
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: ordenacaoDecrescente ? Colors.white : primaryOrange,
                  ),
                  onPressed: () =>
                      setState(() => ordenacaoDecrescente = !ordenacaoDecrescente),
                  tooltip: ordenacaoDecrescente ? 'Decrescente' : 'Crescente',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: showOnlyWithPoints ? accentGreen : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryYellow.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    showOnlyWithPoints
                        ? Icons.filter_alt
                        : Icons.filter_alt_outlined,
                    color: showOnlyWithPoints ? Colors.white : accentGreen,
                  ),
                  onPressed: () =>
                      setState(() => showOnlyWithPoints = !showOnlyWithPoints),
                  tooltip: 'Apenas com pontuação',
                ),
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
            .where((doc) => (pontuacoesCache[doc.id] ?? 0) > 0)
            .length;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryYellow.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  Icons.people,
                  'Total',
                  '$total',
                  primaryOrange,
                  lightOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatChip(
                  Icons.emoji_events,
                  'Com Pontos',
                  '$comPontuacao',
                  accentGreen,
                  lightGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatChip(
                  Icons.pending,
                  'Sem Pontos',
                  '${total - comPontuacao}',
                  primaryYellow,
                  lightYellow,
                ),
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
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantesList() {
    if (eventoSelecionadoId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: lightYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event,
                size: 64,
                color: primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Selecione um evento',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha um evento acima para ver os participantes',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
                ),
                const SizedBox(height: 16),
                Text(
                  'Carregando participantes...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: lightRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: primaryRed,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar dados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: lightOrange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: primaryOrange,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Nenhum participante',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ainda não há participantes neste evento',
                  style: TextStyle(color: Colors.grey[600]),
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
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: lightYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_off,
                    size: 64,
                    color: primaryYellow,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Nenhum resultado',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tente ajustar os filtros de pesquisa',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [lightYellow, lightOrange.withValues(alpha: 0.3)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryOrange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${participantes.length} participante${participantes.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: accentGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton.icon(
                      onPressed: () => _exportarParticipantes(participantes),
                      icon: const Icon(Icons.download, size: 18, color: Colors.white),
                      label: const Text(
                        'Exportar CSV',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
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
    if (searchQuery.isNotEmpty) {
      participantes = participantes.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final nome = (data['nome'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        final query = searchQuery.toLowerCase();
        return nome.contains(query) || email.contains(query);
      }).toList();
    }

    if (filtroEquipa != null) {
      participantes = participantes.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['equipaId'] == filtroEquipa;
      }).toList();
    }

    if (showOnlyWithPoints) {
      participantes = participantes.where((doc) {
        return (pontuacoesCache[doc.id] ?? 0) > 0;
      }).toList();
    }

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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryYellow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _abrirDetalhes(doc.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryOrange, primaryRed],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: Text(
                          nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: primaryOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (nomeEquipa != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: lightOrange,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: primaryOrange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.group,
                                    size: 14,
                                    color: primaryOrange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    nomeEquipa,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: primaryOrange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    FutureBuilder<int>(
                      future: _getPontuacaoTotal(doc.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            width: 90,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    primaryOrange,
                                  ),
                                ),
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
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  pontos > 0
                                      ? [accentGreen, accentGreen.withValues(alpha: 0.7)]
                                      : [Colors.grey[300]!, Colors.grey[400]!],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    pontos > 0
                                        ? accentGreen.withValues(alpha: 0.3)
                                        : Colors.transparent,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.emoji_events,
                                size: 18,
                                color: pontos > 0 ? Colors.white : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$pontos',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color:
                                      pontos > 0 ? Colors.white : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'pts',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      pontos > 0 ? Colors.white : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(Icons.email, email, primaryYellow),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoChip(Icons.phone, telefone, accentGreen),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
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
        setState(() => pontuacoesCache.clear());
      }
    });
  }

  Future<void> _exportarParticipantes(
    List<QueryDocumentSnapshot> participantes,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Exportando dados...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      List<List<dynamic>> rows = [];
      rows.add([
        'Nome',
        'Email',
        'Telefone',
        'Emergência',
        'T-shirt',
        'Equipa',
        'Pontuação Total',
      ]);

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

      String csv = const ListToCsvConverter().convert(rows);
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/participantes_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(csv);

      if (mounted) Navigator.of(context).pop();

      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Participantes - $eventoSelecionadoId',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: accentGreen,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Arquivo CSV exportado com sucesso!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error, color: primaryRed),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erro ao exportar: $e',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildParticipantesQuery(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
                  ),
                );
              }

              final participantes =
                  _filtrarEOrdenarParticipantes(snapshot.data!.docs);

              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryOrange, primaryRed],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bar_chart,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Estatísticas do Evento',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildStatCard(
                    'Total de Participantes',
                    '${participantes.length}',
                    Icons.people,
                    primaryOrange,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'Com Pontuação',
                    '${participantes.where((p) => (pontuacoesCache[p.id] ?? 0) > 0).length}',
                    Icons.emoji_events,
                    accentGreen,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'Pontuação Média',
                    _calcularMediaPontuacao(participantes),
                    Icons.bar_chart,
                    primaryYellow,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'Pontuação Máxima',
                    _calcularMaximaPontuacao(participantes),
                    Icons.star,
                    primaryRed,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: lightYellow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: primaryOrange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Top 5 Participantes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTop5(participantes),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: lightOrange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.pie_chart,
                          color: primaryOrange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Distribuição por Equipa',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDistribuicaoEquipas(participantes),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: lightGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.show_chart,
                          color: accentGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Gráfico de Pontuações',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 320,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryYellow.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildGraficoPontuacoes(participantes),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: lightYellow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
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
        Color bgColor;

        switch (index) {
          case 0:
            medalColor = const Color(0xFFFFD700); // Ouro
            medalIcon = Icons.emoji_events;
            bgColor = const Color(0xFFFFFAE6);
            break;
          case 1:
            medalColor = const Color(0xFFC0C0C0); // Prata
            medalIcon = Icons.emoji_events;
            bgColor = const Color(0xFFF5F5F5);
            break;
          case 2:
            medalColor = const Color(0xFFCD7F32); // Bronze
            medalIcon = Icons.emoji_events;
            bgColor = const Color(0xFFFFE4D6);
            break;
          default:
            medalColor = primaryOrange;
            medalIcon = Icons.star;
            bgColor = lightOrange;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: medalColor.withValues(alpha: 0.3), width: 2),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [medalColor, medalColor.withValues(alpha: 0.7)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(medalIcon, color: Colors.white, size: 28),
            ),
            title: Text(
              data['nome'] ?? 'Sem nome',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              equipasCache[data['equipaId']] ?? 'Sem equipa',
              style: TextStyle(color: Colors.grey[700]),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentGreen, accentGreen.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$pontos pts',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
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
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: lightOrange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Nenhuma equipa atribuída'),
        ),
      );
    }

    final colors = [
      primaryOrange,
      primaryRed,
      primaryYellow,
      accentGreen,
      Colors.purple,
      Colors.blue,
    ];

    return Column(
      children: distribuicao.entries.map((entry) {
        final index = distribuicao.keys.toList().indexOf(entry.key);
        final color = colors[index % colors.length];
        final nomeEquipa = equipasCache[entry.key] ?? 'Sem nome';
        final quantidade = entry.value;
        final percentual =
            ((quantidade / participantes.length) * 100).toStringAsFixed(1);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        nomeEquipa,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$quantidade ($percentual%)',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: quantidade / participantes.length,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGraficoPontuacoes(List<QueryDocumentSnapshot> participantes) {
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

    final colors = [
      Colors.grey,
      primaryYellow,
      primaryOrange,
      primaryRed,
      accentGreen,
    ];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: faixas.values.reduce((a, b) => a > b ? a : b).toDouble() + 2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black87,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final faixa = faixas.keys.elementAt(group.x.toInt());
              return BarTooltipItem(
                '$faixa pontos\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: '${rod.toY.toInt()} participantes',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
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
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
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
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: faixas.entries.map((entry) {
          final index = faixas.keys.toList().indexOf(entry.key);
          final color = colors[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 28,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}