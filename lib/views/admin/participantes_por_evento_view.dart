// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'edit_participantes.dart';
import 'package:flutter/services.dart';
import '../../web_download_stub.dart'
    if (dart.library.html) '../../web_download_html.dart'
    as webdl;
import 'package:excel/excel.dart' as xlsx;

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
  String ordenacao = 'nome';
  bool ordenacaoDecrescente = false;
  late AnimationController _animationController;

  final Map<String, String> equipasCache = {};
  final Map<String, int> pontuacoesCache = {};

  // Cores oficiais Shell (conforme swatch)
  // Shell Yellow #ffc600, Shell Red #dd1d21, Sunrise (laranja) #ed8a00
  static const Color primaryYellow = Color(0xFFFFC600);
  static const Color primaryOrange = Color(0xFFED8A00);
  static const Color primaryRed = Color(0xFFDD1D21);
  static const Color lightYellow = Color(0xFFFFF3E5); // Sunrise 50
  static const Color lightOrange = Color(0xFFFFDAAE); // Sunrise 100 aproximado
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
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: const Color(0xFFFFFCF7),
        canvasColor: const Color(0xFFFFFCF7),
        cardColor: Colors.white,
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        dialogTheme: DialogThemeData(backgroundColor: Colors.white),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFCF7),
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
      ),
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
                  style: const TextStyle(color: Colors.black),
                  dropdownColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Edição',
                    labelStyle: const TextStyle(
                      color: Colors.black,
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
                    style: const TextStyle(color: Colors.black),
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Evento',
                      labelStyle: const TextStyle(
                        color: Colors.black,
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
    final String eventPath =
        'editions/$edicaoSelecionadaId/events/$eventoSelecionadoId';
    return FirebaseFirestore.instance
        .collection('users')
        .where('eventoId', isEqualTo: eventPath)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
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

  /// Lê o documento do veículo associado ao utilizador e devolve a lista de passageiros.
  /// Tenta os possíveis campos no user: 'veiculoId', 'veiculoSelecionado', 'veiculoSelecionadoId'.
  Future<List<Map<String, dynamic>>> _getPassageirosDoVeiculo(
    Map<String, dynamic> userData,
  ) async {
    final veiculoId =
        (userData['veiculoId'] ??
                userData['veiculoSelecionado'] ??
                userData['veiculoSelecionadoId'])
            ?.toString();
    if (veiculoId == null || veiculoId.isEmpty) return const [];
    try {
      final vSnap =
          await FirebaseFirestore.instance
              .collection('veiculos')
              .doc(veiculoId)
              .get();
      if (!vSnap.exists) return const [];
      final vData = vSnap.data() ?? {};
      final raw = vData['passageiros'];
      final List<Map<String, dynamic>> passageiros = [];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) {
            try {
              passageiros.add(Map<String, dynamic>.from(e));
            } catch (_) {}
          }
        }
      }
      return passageiros;
    } catch (_) {
      return const [];
    }
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
        hasScrollBody: false,
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
            hasScrollBody: false,
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
            hasScrollBody: false,
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
            hasScrollBody: false,
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
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
                  ),
                ),
              );
            }
            if (usersSnap.hasError || !usersSnap.hasData) {
              return SliverFillRemaining(
                hasScrollBody: false,
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
                hasScrollBody: false,
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
    // Evita overflow dentro de SliverFillRemaining(hasScrollBody: false)
    // sem usar LayoutBuilder (que não fornece intrinsics em slivers).
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color:
                      (color == primaryYellow
                          ? primaryYellow.withValues(alpha: 0.12)
                          : color.withValues(alpha: 0.1)),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 80, color: color),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightYellow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryYellow.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: primaryYellow,
              borderRadius: BorderRadius.circular(12),
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
    final nome = (data['nome'] ?? 'Sem nome').toString();
    final email = (data['email'] ?? '').toString();
    final telefone = (data['telefone'] ?? '').toString();
    final equipaId = data['equipaId'];
    final nomeEquipa =
        equipaId != null
            ? (equipasCache[equipaId] ?? 'Sem equipa')
            : 'Sem equipa';

    return Card(
      color: const Color(0xFFFFFFFF),
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _abrirDetalhes(doc.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              // Avatar simples com iniciais
              CircleAvatar(
                radius: 22,
                backgroundColor: primaryYellow.withAlpha(64),
                child: Text(
                  nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: primaryOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Texto (nome, email/equipa, telefone)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: darkGrey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (email.isNotEmpty) const SizedBox(width: 6),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.group,
                                size: 14,
                                color: primaryOrange,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  nomeEquipa,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: primaryOrange,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (telefone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: darkGrey,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              telefone,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Trailing: pagamento status icon, pontos em Chip
              FutureBuilder<DocumentSnapshot>(
                future:
                    (eventoSelecionadoId == null)
                        ? Future.value(
                          FirebaseFirestore.instance.doc('dummy/path').get(),
                        )
                        : FirebaseFirestore.instance
                            .collection('users')
                            .doc(doc.id)
                            .collection('eventos')
                            .doc(eventoSelecionadoId)
                            .get(),
                builder: (context, snap) {
                  // Extrai dados com segurança
                  final raw = snap.data?.data();
                  final map =
                      raw is Map<String, dynamic>
                          ? raw
                          : const <String, dynamic>{};
                  final pag = map['pagamento'];
                  final pagMap =
                      pag is Map<String, dynamic>
                          ? pag
                          : const <String, dynamic>{};

                  // Possíveis campos usados no app:
                  // - pagamento.valorPago (num)
                  // - pagamento.valorPrevisto | valor | preco (num)
                  // - pagamento.status | estado | state | statusPagamento ('pago'/'paid'/...)
                  // - pagamento.pago | pago | isPaid (bool)
                  // - (fallback) campo raiz: pago | statusPagamento
                  num toNum(dynamic v) {
                    if (v is num) return v;
                    if (v is String) {
                      final s = v.replaceAll(RegExp(r'[^0-9\.\-]'), '');
                      return num.tryParse(s) ?? 0;
                    }
                    return 0;
                  }

                  final valorPago = toNum(
                    pagMap['valorPago'] ?? map['valorPago'],
                  );
                  final valorPrevisto = toNum(
                    pagMap['valorPrevisto'] ??
                        pagMap['valor'] ??
                        map['valorPrevisto'] ??
                        map['preco'] ??
                        0,
                  );

                  final statusRaw =
                      (pagMap['status'] ??
                          pagMap['estado'] ??
                          pagMap['state'] ??
                          map['statusPagamento'] ??
                          map['pago'] ??
                          pagMap['pago'] ??
                          pagMap['isPaid']);

                  bool statusStringPaid = false;
                  if (statusRaw is String) {
                    final s = statusRaw.toLowerCase().trim();
                    statusStringPaid = [
                      'pago',
                      'paga',
                      'paid',
                      'confirmado',
                      'confirmada',
                      'ok',
                    ].contains(s);
                  }
                  final statusBoolPaid =
                      statusRaw is bool ? statusRaw == true : false;

                  // Regras:
                  // 1) Pago se status for "pago/paid" OU bool true OU valorPago >= valorPrevisto (com tolerância)
                  // 2) Parcial se valorPago > 0 mas < valorPrevisto
                  // 3) Pendente caso contrário
                  const tol = 0.01; // tolerância monetária
                  final isPaidByAmount =
                      (valorPrevisto > 0)
                          ? (valorPago + tol >= valorPrevisto)
                          : (valorPago > 0);
                  final isPago =
                      statusStringPaid || statusBoolPaid || isPaidByAmount;
                  final isParcial = !isPago && (valorPago > 0);

                  String tooltip;
                  IconData iconData;
                  Color iconColor;

                  if (isPago) {
                    tooltip =
                        valorPrevisto > 0
                            ? 'Pago • ${valorPago.toStringAsFixed(0)} / ${valorPrevisto.toStringAsFixed(0)} CVE'
                            : 'Pago';
                    iconData = Icons.check_circle;
                    iconColor = accentGreen;
                  } else if (isParcial) {
                    tooltip =
                        'Parcial • ${valorPago.toStringAsFixed(0)} / ${valorPrevisto.toStringAsFixed(0)} CVE';
                    iconData = Icons.payments;
                    iconColor = primaryOrange; // parcial em laranja
                  } else {
                    tooltip =
                        valorPrevisto > 0
                            ? 'Pendente • 0 / ${valorPrevisto.toStringAsFixed(0)} CVE'
                            : 'Pendente';
                    iconData = Icons.warning_amber_rounded;
                    iconColor = primaryYellow;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Tooltip(
                      message: tooltip,
                      child: Icon(iconData, color: iconColor, size: 20),
                    ),
                  );
                },
              ),
              FutureBuilder<int>(
                future: _getPontuacaoTotal(doc.id),
                builder: (context, snapshot) {
                  final pontos = snapshot.data ?? 0;
                  if (!pontuacoesCache.containsKey(doc.id)) {
                    pontuacoesCache[doc.id] = pontos;
                  }
                  final bool temPontos = pontos > 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          temPontos
                              ? primaryRed.withAlpha(25)
                              : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            temPontos
                                ? primaryRed.withAlpha(90)
                                : Colors.grey[300]!,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 16,
                          color: temPontos ? primaryRed : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$pontos pts',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: temPontos ? primaryRed : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: darkGrey),
                elevation: 14,
                shadowColor: Colors.black54,
                color: Colors.white,
                constraints: const BoxConstraints(minWidth: 260),
                offset: const Offset(-8, 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.black26, width: 1),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'editar':
                      _abrirDetalhes(doc.id);
                      break;
                    case 'veiculo':
                      _abrirVeiculo(doc.id);
                      break;
                    case 'acompanhantes':
                      _abrirAcompanhantes(doc.id);
                      break;
                    case 'equipa':
                      _abrirEquipa(doc.id);
                      break;
                    case 'pagamento':
                      _abrirPagamento(doc.id);
                      break;
                    case 'detalhes':
                      _abrirDetalhes(doc.id);
                      break;
                    case 'qrcode':
                      _mostrarQrCode(doc.id);
                      break;
                    case 'eliminar':
                      _removerParticipanteDoEvento(doc.id);
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: primaryOrange),
                            SizedBox(width: 10),
                            Text(
                              'Editar',
                              style: TextStyle(
                                color: darkGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'veiculo',
                        child: Row(
                          children: [
                            Icon(
                              Icons.directions_car,
                              size: 18,
                              color: primaryOrange,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Veículo',
                              style: TextStyle(
                                color: darkGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'acompanhantes',
                        child: Row(
                          children: [
                            Icon(Icons.people, size: 18, color: primaryOrange),
                            SizedBox(width: 10),
                            Text(
                              'Acompanhantes',
                              style: TextStyle(
                                color: darkGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'equipa',
                        child: Row(
                          children: [
                            Icon(Icons.flag, size: 18, color: primaryOrange),
                            SizedBox(width: 10),
                            Text(
                              'Equipa',
                              style: TextStyle(
                                color: darkGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'detalhes',
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: primaryOrange,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Detalhes',
                              style: TextStyle(
                                color: darkGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'qrcode',
                        child: Row(
                          children: [
                            Icon(Icons.qr_code, size: 18, color: primaryOrange),
                            SizedBox(width: 10),
                            Text(
                              'QR Code',
                              style: TextStyle(
                                color: darkGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Insert Pagamento before divider
                      const PopupMenuItem(
                        value: 'pagamento',
                        child: Row(
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 18,
                              color: primaryOrange,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Pagamento',
                              style: TextStyle(
                                color: darkGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: primaryRed,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Eliminar',
                              style: TextStyle(
                                color: primaryRed,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
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

  /// Converte uma matriz de linhas em bytes de um ficheiro Excel (.xlsx)
  Uint8List _excelBytesFromRows(List<List<dynamic>> rows) {
    final book = xlsx.Excel.createExcel();
    final sheet = book['Participantes'];
    for (final row in rows) {
      sheet.appendRow(
        row.map<xlsx.CellValue?>((e) {
          if (e == null) return null;
          if (e is int) return xlsx.IntCellValue(e);
          if (e is double) return xlsx.DoubleCellValue(e);
          if (e is num) return xlsx.DoubleCellValue(e.toDouble());
          if (e is bool) return xlsx.BoolCellValue(e);
          if (e is DateTime) {
            return xlsx.DateTimeCellValue(
              year: e.year,
              month: e.month,
              day: e.day,
              hour: e.hour,
              minute: e.minute,
              second: e.second,
            );
          }
          return xlsx.TextCellValue(e.toString());
        }).toList(),
      );
    }
    // Remove a folha padrão se existir (evita ficar com "Sheet1")
    final defaultSheet = book.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'Participantes') {
      book.delete(defaultSheet);
    }
    final bytes = book.encode();
    return Uint8List.fromList(bytes!);
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
                      'Preparando ficheiro Excel',
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
        // Detalhes do veículo / passageiros
        'Condutor - Nome',
        'Condutor - Telefone',
        'Condutor - T-shirt',
        'Co-piloto - Nome',
        'Co-piloto - Telefone',
        'Co-piloto - T-shirt',
        'Acompanhante 1 - Nome',
        'Acompanhante 1 - Telefone',
        'Acompanhante 1 - T-shirt',
        'Acompanhante 2 - Nome',
        'Acompanhante 2 - Telefone',
        'Acompanhante 2 - T-shirt',
      ]);

      for (final doc in participantes) {
        final data = doc.data() as Map<String, dynamic>;
        final equipaId = data['equipaId'];
        final pontos = await _getPontuacaoTotal(doc.id);

        // Lê passageiros do veículo associado
        final passageiros = await _getPassageirosDoVeiculo(data);
        // Helpers seguros para extrair campos
        String nomeAt(int i) =>
            (i < passageiros.length ? (passageiros[i]['nome'] ?? '') : '')
                .toString();
        String telAt(int i) =>
            (i < passageiros.length ? (passageiros[i]['telefone'] ?? '') : '')
                .toString();
        String tshirtAt(int i) =>
            (i < passageiros.length
                    ? (passageiros[i]['tshirt'] ??
                        passageiros[i]['T-shirt'] ??
                        passageiros[i]['t_shirt'] ??
                        '')
                    : '')
                .toString();

        rows.add([
          data['nome'] ?? '',
          data['email'] ?? '',
          data['telefone'] ?? '',
          data['emergencia'] ?? '',
          data['tshirt'] ?? '',
          equipaId != null ? (equipasCache[equipaId] ?? '') : '',
          pontos,
          // Passageiros por posição
          nomeAt(0), telAt(0), tshirtAt(0), // Condutor
          nomeAt(1), telAt(1), tshirtAt(1), // Co-piloto
          nomeAt(2), telAt(2), tshirtAt(2), // Acomp 1
          nomeAt(3), telAt(3), tshirtAt(3), // Acomp 2
        ]);
      }

      // Gera bytes do Excel (.xlsx) a partir das linhas
      final xlsBytes = _excelBytesFromRows(rows);

      // Web: descarrega o ficheiro Excel (.xlsx) diretamente
      if (kIsWeb) {
        if (mounted) Navigator.of(context).pop(); // fechar o diálogo de loading
        final filename =
            'participantes_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        await webdl.saveBytesWeb(filename, xlsBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ficheiro Excel descarregado com sucesso'),
              backgroundColor: accentGreen,
            ),
          );
        }
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/participantes_$timestamp.xlsx';
      final file = File(path);
      await file.writeAsBytes(xlsBytes, flush: true);

      if (mounted) Navigator.of(context).pop();

      await Share.shareXFiles([
        XFile(
          path,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          name: 'participantes_$timestamp.xlsx',
        ),
      ], subject: 'Participantes (Excel) - $eventoSelecionadoId');

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
                          'Ficheiro Excel criado com sucesso',
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
  // --- Helpers e ações de menu ---

  Widget _buildTextField(
    String label,
    TextEditingController ctl,
    IconData icon,
  ) {
    return TextField(
      controller: ctl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryOrange),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  void _abrirPagamento(String userId) async {
    if (eventoSelecionadoId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecione um evento para editar o pagamento.'),
            backgroundColor: primaryRed,
          ),
        );
      }
      return;
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final eventoRef = userRef.collection('eventos').doc(eventoSelecionadoId);

    // Carrega dados atuais
    final snap = await eventoRef.get();
    if (!mounted) return;
    final Map<String, dynamic> dados = snap.data() ?? {};
    final Map<String, dynamic> pagamento =
        (dados['pagamento'] ?? {}) as Map<String, dynamic>;

    final valorPrevistoCtl = TextEditingController(
      text: ((pagamento['valorPrevisto'] ?? dados['preco'] ?? 0).toString()),
    );
    final valorPagoCtl = TextEditingController(
      text: ((pagamento['valorPago'] ?? 0).toString()),
    );
    String metodo = (pagamento['metodo'] ?? 'Pagali').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.payments_outlined, color: darkGrey, size: 26),
                      SizedBox(width: 12),
                      Text(
                        'Pagamento da Inscrição',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: darkGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Valor previsto
                  TextField(
                    controller: valorPrevistoCtl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Valor previsto (CVE)',
                      prefixIcon: const Icon(
                        Icons.request_quote,
                        color: primaryOrange,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Valor pago
                  TextField(
                    controller: valorPagoCtl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Valor pago (CVE)',
                      prefixIcon: const Icon(
                        Icons.attach_money,
                        color: accentGreen,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Método
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: primaryOrange,
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: metodo,
                        items: const [
                          DropdownMenuItem(
                            value: 'Pagali',
                            child: Text('Pagali'),
                          ),
                          DropdownMenuItem(
                            value: 'Transferência',
                            child: Text('Transferência'),
                          ),
                          DropdownMenuItem(
                            value: 'Dinheiro',
                            child: Text('Dinheiro'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => metodo = v);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar'),
                          onPressed: () async {
                            double parseValor(String txt) {
                              final t = txt
                                  .trim()
                                  .replaceAll(' ', '')
                                  .replaceAll(',', '.');
                              if (t.isEmpty) return 0.0;
                              final v = double.tryParse(t);
                              return v?.isFinite == true ? v! : 0.0;
                            }

                            final double valorPrevisto = parseValor(
                              valorPrevistoCtl.text,
                            );
                            final double valorPago = parseValor(
                              valorPagoCtl.text,
                            );

                            try {
                              await eventoRef.set({
                                'pagamento': {
                                  'valorPrevisto': valorPrevisto,
                                  'valorPago': valorPago,
                                  'metodo': metodo,
                                  'atualizadoEm': FieldValue.serverTimestamp(),
                                },
                              }, SetOptions(merge: true));

                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Pagamento atualizado com sucesso',
                                  ),
                                  backgroundColor: accentGreen,
                                ),
                              );
                              setState(() {}); // refresh a lista
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Erro ao guardar pagamento: $e',
                                  ),
                                  backgroundColor: primaryRed,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _abrirVeiculo(String userId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final snap = await userRef.get();
    if (!mounted) return;
    final data = snap.data() ?? {};
    final veiculo = (data['veiculo'] ?? {}) as Map<String, dynamic>;

    final marcaCtl = TextEditingController(
      text: (veiculo['marca'] ?? '').toString(),
    );
    final modeloCtl = TextEditingController(
      text: (veiculo['modelo'] ?? '').toString(),
    );
    final matriculaCtl = TextEditingController(
      text: (veiculo['matricula'] ?? '').toString(),
    );
    final corCtl = TextEditingController(
      text: (veiculo['cor'] ?? '').toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.directions_car, color: darkGrey, size: 26),
                      SizedBox(width: 12),
                      Text(
                        'Veículo do Participante',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: darkGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Marca',
                    marcaCtl,
                    Icons.directions_car_filled,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField('Modelo', modeloCtl, Icons.build),
                  const SizedBox(height: 10),
                  _buildTextField('Matrícula', matriculaCtl, Icons.badge),
                  const SizedBox(height: 10),
                  _buildTextField('Cor', corCtl, Icons.color_lens),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar'),
                          onPressed: () async {
                            try {
                              await userRef.update({
                                'veiculo': {
                                  'marca': marcaCtl.text.trim(),
                                  'modelo': modeloCtl.text.trim(),
                                  'matricula': matriculaCtl.text.trim(),
                                  'cor': corCtl.text.trim(),
                                },
                              });
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Veículo atualizado com sucesso',
                                  ),
                                  backgroundColor: accentGreen,
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao guardar veículo: $e'),
                                  backgroundColor: primaryRed,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _abrirAcompanhantes(String userId) {
    final acompRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('acompanhantes');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.people, color: darkGrey, size: 26),
                      SizedBox(width: 12),
                      Text(
                        'Acompanhantes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: darkGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: acompRef.orderBy('nome').snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
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
                        final docs = snap.data!.docs;
                        if (docs.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: primaryOrange),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text('Sem acompanhantes adicionados'),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          itemCount: docs.length,
                          separatorBuilder: (_, _) => const Divider(height: 8),
                          itemBuilder: (context, i) {
                            final d = docs[i];
                            final m = d.data() as Map<String, dynamic>;
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                m['nome'] ?? 'Sem nome',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle:
                                  (m['telefone'] ?? '').toString().isNotEmpty
                                      ? Text((m['telefone'] ?? '').toString())
                                      : null,
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: primaryRed,
                                ),
                                onPressed: () async {
                                  await acompRef.doc(d.id).delete();
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Adicionar'),
                      onPressed: () async {
                        final nomeCtl = TextEditingController();
                        final telCtl = TextEditingController();
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Novo acompanhante'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTextField(
                                    'Nome',
                                    nomeCtl,
                                    Icons.person,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildTextField(
                                    'Telefone',
                                    telCtl,
                                    Icons.phone,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentGreen,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    if (nomeCtl.text.trim().isEmpty) return;
                                    await acompRef.add({
                                      'nome': nomeCtl.text.trim(),
                                      'telefone': telCtl.text.trim(),
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Guardar'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _abrirEquipa(String userId) {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.flag, color: darkGrey, size: 26),
                    SizedBox(width: 12),
                    Text(
                      'Selecionar Equipa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: darkGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('equipas')
                            .orderBy('nome')
                            .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
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
                      final docs = snap.data!.docs;
                      if (docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Nenhuma equipa cadastrada'),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: docs.length,
                        separatorBuilder: (_, _) => const Divider(height: 8),
                        itemBuilder: (context, i) {
                          final d = docs[i];
                          final m = d.data() as Map<String, dynamic>;
                          return ListTile(
                            onTap: () async {
                              await userRef.update({'equipaId': d.id});
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Equipa atualizada'),
                                  backgroundColor: accentGreen,
                                ),
                              );
                              setState(() {}); // refresca listagem
                            },
                            leading: const Icon(
                              Icons.group,
                              color: primaryOrange,
                            ),
                            title: Text(m['nome'] ?? 'Sem nome'),
                            subtitle:
                                (m['descricao'] ?? '').toString().isNotEmpty
                                    ? Text((m['descricao'] ?? '').toString())
                                    : null,
                            trailing: const Icon(
                              Icons.check,
                              color: Colors.transparent,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _removerParticipanteDoEvento(String userId) async {
    if (edicaoSelecionadaId == null || eventoSelecionadoId == null) return;

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover do evento?'),
          content: const Text(
            'Isto vai remover a inscrição deste participante neste evento e as suas pontuações associadas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      final eventoDocRef = userRef
          .collection('eventos')
          .doc(eventoSelecionadoId);

      // Apagar pontuações associadas a este evento
      final pontSnap = await eventoDocRef.collection('pontuacoes').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in pontSnap.docs) {
        batch.delete(d.reference);
      }
      // Apagar doc de evento do user
      batch.delete(eventoDocRef);
      // Remover referência de eventoId (se usada para inscrição)
      batch.update(userRef, {'eventoId': FieldValue.delete()});
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Participante removido do evento'),
            backgroundColor: accentGreen,
          ),
        );
        setState(() {
          pontuacoesCache.remove(userId);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover: $e'),
            backgroundColor: primaryRed,
          ),
        );
      }
    }
  }

  void _mostrarQrCode(String userId) {
    final String eventPath =
        (edicaoSelecionadaId != null && eventoSelecionadoId != null)
            ? 'editions/$edicaoSelecionadaId/events/$eventoSelecionadoId'
            : '';
    final String payload = 'CHECKIN|$eventPath|$userId';
    final String url =
        'https://chart.googleapis.com/chart?chs=420x420&cht=qr&chl=${Uri.encodeComponent(payload)}&choe=UTF-8';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.qr_code_2, color: darkGrey, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'QR Code do Participante',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: darkGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    url,
                    width: 280,
                    height: 280,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) {
                      return Container(
                        width: 280,
                        height: 280,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            payload,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link, size: 18, color: primaryOrange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          payload,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copiar',
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: payload));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Código copiado para a área de transferência',
                              ),
                              backgroundColor: primaryOrange,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, color: darkGrey),
                      ),
                      IconButton(
                        tooltip: 'Partilhar',
                        onPressed: () async {
                          await Share.share(
                            'QR do participante:\n$payload\n$url',
                          );
                        },
                        icon: const Icon(Icons.share, color: darkGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
