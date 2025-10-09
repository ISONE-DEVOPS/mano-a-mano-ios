import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'edit_participantes.dart';

class ParticipantesPorEventoView extends StatefulWidget {
  const ParticipantesPorEventoView({super.key});

  @override
  State<ParticipantesPorEventoView> createState() =>
      _ParticipantesPorEventoViewState();
}

class _ParticipantesPorEventoViewState extends State<ParticipantesPorEventoView>
    with SingleTickerProviderStateMixin {
  String? eventoSelecionadoId;
  String? edicaoSelecionadaId;
  String searchQuery = '';
  String? filtroEquipa;
  bool showOnlyWithPoints = false;
  String ordenacao = 'pontuacao';
  bool ordenacaoDecrescente = true;
  late AnimationController _animationController;

  final Map<String, String> equipasCache = {};
  final Map<String, int> pontuacoesCache = {};

  // Cores em sintonia com o logo Shell
  static const Color primaryYellow = Color(0xFFFBBC04);
  static const Color primaryOrange = Color(0xFFFF6F00);
  static const Color primaryRed = Color(0xFFE53935);
  static const Color lightYellow = Color(0xFFFFF9C4);
  static const Color lightOrange = Color(0xFFFFE0B2);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFC8E6C9);
  static const Color darkGrey = Color(0xFF424242);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildEventoSelector()),
          if (eventoSelecionadoId != null) ...[
            SliverToBoxAdapter(child: _buildSearchAndFilters()),
            SliverToBoxAdapter(child: _buildQuickStats()),
          ],
          _buildParticipantesList(),
        ],
      ),
      floatingActionButton:
          eventoSelecionadoId != null ? _buildFloatingButtons() : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryOrange, primaryRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.people_alt,
                          color: primaryOrange,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Participantes',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Gestão de Participantes por Evento',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                pontuacoesCache.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Dados atualizados!'),
                    ],
                  ),
                  backgroundColor: accentGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            tooltip: 'Atualizar',
          ),
        ),
      ],
    );
  }

  Widget _buildEventoSelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryOrange, primaryRed],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_note,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Selecione o Evento',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('editions')
                    .orderBy('dataInicio', descending: true)
                    .snapshots(),
            builder: (context, edicoesSnapshot) {
              if (!edicoesSnapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
                    ),
                  ),
                );
              }

              final edicoes = edicoesSnapshot.data!.docs;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: edicaoSelecionadaId,
                  decoration: InputDecoration(
                    labelText: 'Edição',
                    labelStyle: const TextStyle(
                      color: primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                    prefixIcon: const Icon(
                      Icons.calendar_today,
                      color: primaryOrange,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  items:
                      edicoes.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(
                            data['nome'] ?? 'Sem nome',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
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
              stream:
                  FirebaseFirestore.instance
                      .collection('editions')
                      .doc(edicaoSelecionadaId)
                      .collection('events')
                      .orderBy('data', descending: true)
                      .snapshots(),
              builder: (context, eventosSnapshot) {
                if (!eventosSnapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          primaryOrange,
                        ),
                      ),
                    ),
                  );
                }

                final eventos = eventosSnapshot.data!.docs;

                if (eventos.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: lightOrange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: primaryOrange,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Nenhum evento disponível nesta edição',
                            style: TextStyle(
                              color: primaryOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: eventoSelecionadoId,
                    decoration: InputDecoration(
                      labelText: 'Evento',
                      labelStyle: const TextStyle(
                        color: primaryRed,
                        fontWeight: FontWeight.w600,
                      ),
                      prefixIcon: const Icon(Icons.event, color: primaryRed),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    items:
                        eventos.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final timestamp = data['data'] as Timestamp?;
                          final dataFormatada =
                              timestamp != null
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
                                    fontSize: 15,
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de pesquisa
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome ou email...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(
                  Icons.search,
                  color: primaryOrange,
                  size: 24,
                ),
                suffixIcon:
                    searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () => setState(() => searchQuery = ''),
                        )
                        : null,
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          const SizedBox(height: 16),
          // Filtros em linha
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Apenas com Pontos',
                  icon:
                      showOnlyWithPoints
                          ? Icons.filter_alt
                          : Icons.filter_alt_outlined,
                  isSelected: showOnlyWithPoints,
                  color: accentGreen,
                  onTap:
                      () => setState(
                        () => showOnlyWithPoints = !showOnlyWithPoints,
                      ),
                ),
                const SizedBox(width: 12),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
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

                    return PopupMenuButton<String>(
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _buildFilterChip(
                        label:
                            filtroEquipa != null
                                ? equipasCache[filtroEquipa!] ?? 'Equipa'
                                : 'Todas as Equipas',
                        icon: Icons.group,
                        isSelected: filtroEquipa != null,
                        color: primaryYellow,
                        onTap: null,
                      ),
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              value: null,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.clear_all,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Todas as Equipas'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            ...equipas.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return PopupMenuItem(
                                value: doc.id,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.group,
                                      color: primaryYellow,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(data['nome'] ?? 'Sem nome'),
                                  ],
                                ),
                              );
                            }),
                          ],
                      onSelected:
                          (value) => setState(() => filtroEquipa = value),
                    );
                  },
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  offset: const Offset(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildFilterChip(
                    label: _getOrdenacaoLabel(),
                    icon:
                        ordenacaoDecrescente
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                    isSelected: true,
                    color: primaryRed,
                    onTap: null,
                  ),
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'nome',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.sort_by_alpha,
                                color: primaryRed,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text('Nome'),
                              if (ordenacao == 'nome') ...[
                                const Spacer(),
                                const Icon(
                                  Icons.check,
                                  color: primaryRed,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'pontuacao',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: primaryRed,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text('Pontuação'),
                              if (ordenacao == 'pontuacao') ...[
                                const Spacer(),
                                const Icon(
                                  Icons.check,
                                  color: primaryRed,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'equipa',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.group,
                                color: primaryRed,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text('Equipa'),
                              if (ordenacao == 'equipa') ...[
                                const Spacer(),
                                const Icon(
                                  Icons.check,
                                  color: primaryRed,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'toggle_order',
                          child: Row(
                            children: [
                              Icon(
                                ordenacaoDecrescente
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: primaryRed,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                ordenacaoDecrescente
                                    ? 'Ordem Crescente'
                                    : 'Ordem Decrescente',
                              ),
                            ],
                          ),
                        ),
                      ],
                  onSelected: (value) {
                    setState(() {
                      if (value == 'toggle_order') {
                        ordenacaoDecrescente = !ordenacaoDecrescente;
                      } else {
                        ordenacao = value;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getOrdenacaoLabel() {
    switch (ordenacao) {
      case 'nome':
        return 'Nome';
      case 'pontuacao':
        return 'Pontuação';
      case 'equipa':
        return 'Equipa';
      default:
        return 'Ordenar';
    }
  }

  // Stream de IDs de utilizadores inscritos no evento selecionado
  Stream<List<String>> _participanteUserIdsStream() {
    if (edicaoSelecionadaId == null || eventoSelecionadoId == null) {
      return const Stream<List<String>>.empty();
    }
    final ref = FirebaseFirestore.instance
        .collection('editions')
        .doc(edicaoSelecionadaId)
        .collection('events')
        .doc(eventoSelecionadoId)
        .collection('participants');
    return ref.snapshots().map((snap) {
      return snap.docs
          .map((d) {
            final Map<String, dynamic> data = d.data();
            // Tenta userId no documento; caso contrário, usa o id do doc
            return (data['userId'] as String?) ?? d.id;
          })
          .whereType<String>()
          .toList();
    });
  }

  // Busca os documentos de utilizadores por lotes (limite de 10 para whereIn)
  Future<List<QueryDocumentSnapshot>> _fetchUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final List<QueryDocumentSnapshot> result = [];
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, (i + 10 > ids.length) ? ids.length : i + 10);
      final snap =
          await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
      result.addAll(snap.docs);
    }
    return result;
  }

  Widget _buildQuickStats() {
    return StreamBuilder<List<String>>(
      stream: _participanteUserIdsStream(),
      builder: (context, idsSnap) {
        if (!idsSnap.hasData) return const SizedBox.shrink();
        final ids = idsSnap.data!;
        return FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _fetchUsersByIds(ids),
          builder: (context, usersSnap) {
            if (!usersSnap.hasData) return const SizedBox.shrink();

            final participantes = usersSnap.data!;
            final total = participantes.length;
            final comPontuacao =
                participantes
                    .where((doc) => (pontuacoesCache[doc.id] ?? 0) > 0)
                    .length;
            final semPontuacao = total - comPontuacao;

            return Container(
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      '$total',
                      Icons.people_alt,
                      primaryOrange,
                      lightOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Com Pontos',
                      '$comPontuacao',
                      Icons.emoji_events,
                      accentGreen,
                      lightGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Sem Pontos',
                      '$semPontuacao',
                      Icons.pending_actions,
                      primaryYellow,
                      lightYellow,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantesList() {
    if (eventoSelecionadoId == null || edicaoSelecionadaId == null) {
      return SliverFillRemaining(
        child: _buildEmptyState(
          icon: Icons.event_note,
          title: 'Selecione um evento',
          subtitle:
              'Escolha uma edição e evento acima para ver os participantes',
          color: primaryOrange,
        ),
      );
    }

    return StreamBuilder<List<String>>(
      stream: _participanteUserIdsStream(),
      builder: (context, idsSnap) {
        if (idsSnap.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryOrange, primaryRed],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryOrange.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Carregando participantes...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (idsSnap.hasError) {
          return SliverFillRemaining(
            child: _buildEmptyState(
              icon: Icons.error_outline,
              title: 'Erro ao carregar',
              subtitle: 'Tente novamente mais tarde',
              color: primaryRed,
            ),
          );
        }

        final ids = idsSnap.data ?? [];
        if (ids.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(
              icon: Icons.people_outline,
              title: 'Nenhum participante',
              subtitle: 'Ainda não há participantes inscritos neste evento',
              color: primaryYellow,
            ),
          );
        }

        return FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _fetchUsersByIds(ids),
          builder: (context, usersSnap) {
            if (usersSnap.connectionState == ConnectionState.waiting) {
              return SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
                  ),
                ),
              );
            }
            if (usersSnap.hasError || !usersSnap.hasData) {
              return SliverFillRemaining(
                child: _buildEmptyState(
                  icon: Icons.error_outline,
                  title: 'Erro ao carregar',
                  subtitle: 'Tente novamente mais tarde',
                  color: primaryRed,
                ),
              );
            }

            var participantes = _filtrarEOrdenarParticipantes(usersSnap.data!);

            if (participantes.isEmpty) {
              return SliverFillRemaining(
                child: _buildEmptyState(
                  icon: Icons.search_off,
                  title: 'Nenhum resultado',
                  subtitle: 'Tente ajustar os filtros de pesquisa',
                  color: primaryOrange,
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildListHeader(participantes.length),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildParticipanteCard(
                      participantes[index - 1],
                      index - 1,
                    ),
                  );
                }, childCount: participantes.length + 1),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: color),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: darkGrey,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lightYellow, lightOrange.withValues(alpha: 0.5)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryOrange, primaryRed],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryOrange.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_alt, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$count ${count == 1 ? 'Participante' : 'Participantes'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipanteCard(QueryDocumentSnapshot doc, int index) {
    final data = doc.data() as Map<String, dynamic>;
    final nome = data['nome'] ?? 'Sem nome';
    final email = data['email'] ?? '';
    final telefone = data['telefone'] ?? '';
    final equipaId = data['equipaId'];
    final nomeEquipa = equipaId != null ? equipasCache[equipaId] : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _abrirDetalhes(doc.id),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar com ranking
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [primaryOrange, primaryRed],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryOrange.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(3),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white,
                            child: Text(
                              nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: primaryOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                          ),
                        ),
                        if (ordenacao == 'pontuacao' && index < 3)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _getRankColor(index),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.emoji_events,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
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
                              color: darkGrey,
                            ),
                          ),
                          if (nomeEquipa != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: lightOrange,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: primaryOrange.withValues(alpha: 0.3),
                                  width: 1.5,
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
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      nomeEquipa,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: primaryOrange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FutureBuilder<int>(
                      future: _getPontuacaoTotal(doc.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
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
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  pontos > 0
                                      ? [
                                        accentGreen,
                                        accentGreen.withValues(alpha: 0.7),
                                      ]
                                      : [Colors.grey[300]!, Colors.grey[400]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    pontos > 0
                                        ? accentGreen.withValues(alpha: 0.3)
                                        : Colors.transparent,
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.emoji_events,
                                color:
                                    pontos > 0
                                        ? Colors.white
                                        : Colors.grey[600],
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$pontos',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color:
                                      pontos > 0
                                          ? Colors.white
                                          : Colors.grey[600],
                                ),
                              ),
                              Text(
                                'pts',
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      pontos > 0
                                          ? Colors.white70
                                          : Colors.grey[500],
                                  fontWeight: FontWeight.w600,
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
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildContactInfo(
                        Icons.email_outlined,
                        email,
                        primaryYellow,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildContactInfo(
                        Icons.phone_outlined,
                        telefone,
                        accentGreen,
                      ),
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

  Color _getRankColor(int position) {
    switch (position) {
      case 0:
        return const Color(0xFFFFD700); // Ouro
      case 1:
        return const Color(0xFFC0C0C0); // Prata
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return primaryOrange;
    }
  }

  Widget _buildContactInfo(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: darkGrey,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'stats',
          onPressed: _mostrarEstatisticas,
          backgroundColor: primaryOrange,
          child: const Icon(Icons.bar_chart, color: Colors.white),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<String>>(
          stream: _participanteUserIdsStream(),
          builder: (context, idsSnap) {
            if (!idsSnap.hasData) return const SizedBox.shrink();
            return FutureBuilder<List<QueryDocumentSnapshot>>(
              future: _fetchUsersByIds(idsSnap.data!),
              builder: (context, usersSnap) {
                if (!usersSnap.hasData) return const SizedBox.shrink();
                final participantes = _filtrarEOrdenarParticipantes(
                  usersSnap.data!,
                );
                return FloatingActionButton.extended(
                  heroTag: 'export',
                  onPressed: () => _exportarParticipantes(participantes),
                  backgroundColor: accentGreen,
                  icon: const Icon(Icons.file_download, color: Colors.white),
                  label: const Text(
                    'Exportar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  List<QueryDocumentSnapshot> _filtrarEOrdenarParticipantes(
    List<QueryDocumentSnapshot> participantes,
  ) {
    if (searchQuery.isNotEmpty) {
      participantes =
          participantes.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final nome = (data['nome'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            final query = searchQuery.toLowerCase();
            return nome.contains(query) || email.contains(query);
          }).toList();
    }

    if (filtroEquipa != null) {
      participantes =
          participantes.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['equipaId'] == filtroEquipa;
          }).toList();
    }

    if (showOnlyWithPoints) {
      participantes =
          participantes.where((doc) {
            return (pontuacoesCache[doc.id] ?? 0) > 0;
          }).toList();
    }

    participantes.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      int comparacao = 0;

      switch (ordenacao) {
        case 'nome':
          comparacao = (dataA['nome'] ?? '').toString().compareTo(
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

  Future<int> _getPontuacaoTotal(String userId) async {
    try {
      if (eventoSelecionadoId == null) return 0;

      final eventosSnapshot =
          await FirebaseFirestore.instance
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
        builder:
            (context) => Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryOrange, primaryRed],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Exportando dados...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preparando arquivo CSV',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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

      // Web: partilhar o CSV como texto (evita path_provider no Web)
      if (kIsWeb) {
        if (mounted) Navigator.of(context).pop(); // fechar o diálogo de loading
        // ignore: deprecated_member_use
        await Share.share(csv, subject: 'Participantes - $eventoSelecionadoId');
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/participantes_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(csv);

      if (mounted) Navigator.of(context).pop();

      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile(path),
      ], subject: 'Participantes - $eventoSelecionadoId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 28),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Exportação concluída!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Arquivo CSV criado com sucesso',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Erro na exportação',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$e',
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
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
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryOrange, primaryRed],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Row(
                            children: [
                              Icon(
                                Icons.bar_chart,
                                color: Colors.white,
                                size: 32,
                              ),
                              SizedBox(width: 16),
                              Text(
                                'Estatísticas do Evento',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<List<String>>(
                        stream: _participanteUserIdsStream(),
                        builder: (context, idsSnap) {
                          if (!idsSnap.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryOrange,
                                ),
                              ),
                            );
                          }
                          return FutureBuilder<List<QueryDocumentSnapshot>>(
                            future: _fetchUsersByIds(idsSnap.data!),
                            builder: (context, usersSnap) {
                              if (!usersSnap.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      primaryOrange,
                                    ),
                                  ),
                                );
                              }
                              final participantes =
                                  _filtrarEOrdenarParticipantes(
                                    usersSnap.data!,
                                  );
                              return ListView(
                                controller: scrollController,
                                padding: const EdgeInsets.all(24),
                                children: [
                                  _buildStatisticCard(
                                    'Total de Participantes',
                                    '${participantes.length}',
                                    Icons.people_alt,
                                    primaryOrange,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildStatisticCard(
                                    'Com Pontuação',
                                    '${participantes.where((p) => (pontuacoesCache[p.id] ?? 0) > 0).length}',
                                    Icons.emoji_events,
                                    accentGreen,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildStatisticCard(
                                    'Pontuação Média',
                                    _calcularMediaPontuacao(participantes),
                                    Icons.bar_chart,
                                    primaryYellow,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildStatisticCard(
                                    'Pontuação Máxima',
                                    _calcularMaximaPontuacao(participantes),
                                    Icons.star,
                                    primaryRed,
                                  ),
                                  const SizedBox(height: 32),
                                  const Text(
                                    'Top 5 Participantes',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: darkGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTop5(participantes),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildStatisticCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
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

    final maxima = participantes.fold<int>(0, (currentMax, p) {
      final pontos = pontuacoesCache[p.id] ?? 0;
      return pontos > currentMax ? pontos : currentMax;
    });

    return maxima.toString();
  }

  Widget _buildTop5(List<QueryDocumentSnapshot> participantes) {
    final top5 = List<QueryDocumentSnapshot>.from(participantes)..sort((a, b) {
      final pontosA = pontuacoesCache[a.id] ?? 0;
      final pontosB = pontuacoesCache[b.id] ?? 0;
      return pontosB.compareTo(pontosA);
    });

    final lista = top5.take(5).toList();

    if (lista.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: lightYellow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Nenhum participante com pontuação',
            style: TextStyle(color: primaryYellow, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Column(
      children:
          lista.asMap().entries.map((entry) {
            final index = entry.key;
            final doc = entry.value;
            final data = doc.data() as Map<String, dynamic>;
            final pontos = pontuacoesCache[doc.id] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getRankColor(index).withValues(alpha: 0.1),
                    _getRankColor(index).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getRankColor(index).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getRankColor(index),
                        _getRankColor(index).withValues(alpha: 0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getRankColor(index).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 28,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentGreen, accentGreen.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: accentGreen.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
}
