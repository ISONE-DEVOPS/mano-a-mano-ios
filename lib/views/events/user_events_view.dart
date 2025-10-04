import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../widgets/shared/nav_bottom.dart';

class UserEventsView extends StatefulWidget {
  const UserEventsView({super.key});

  @override
  State<UserEventsView> createState() => _UserEventsViewState();
}

class _UserEventsViewState extends State<UserEventsView> {
  late Future<List<Map<String, dynamic>>> _futureEdicoes;

  @override
  void initState() {
    super.initState();
    _futureEdicoes = _loadEdicoesComEventos();
  }

  Future<List<Map<String, dynamic>>> _loadEdicoesComEventos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Future.error('not_logged_in');

    final userEventsSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('events')
            .get();

    final Set<String> inscritos =
        userEventsSnapshot.docs
            .where((doc) => doc.data()['ativo'] == true)
            .map((doc) => doc.data()['eventoId'] as String)
            .toSet();

    final edicoesSnapshot =
        await FirebaseFirestore.instance.collection('editions').get();

    List<Map<String, dynamic>> edicoes = [];

    for (final ed in edicoesSnapshot.docs) {
      final edId = ed.id;
      final eventosSnapshot =
          await FirebaseFirestore.instance
              .collection('editions')
              .doc(edId)
              .collection('events')
              .get();

      final eventos =
          eventosSnapshot.docs.map((e) {
            final data = e.data();
            return {
              'id': e.id,
              'editionId': edId,
              'inscrito': inscritos.contains('editions/$edId/events/${e.id}'),
              ...data,
            };
          }).toList();

      edicoes.add({
        'id': edId,
        'nome': ed.data()['nome'] ?? edId,
        'eventos': eventos,
      });
    }

    return edicoes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
        centerTitle: true,
        elevation: 0,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index != 1) {
            Navigator.pushReplacementNamed(
              context,
              [
                '/home',
                '/my-events',
                '/checkin',
                '/ranking',
                '/profile',
              ][index],
            );
          }
        },
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureEdicoes,
        builder: (ctx, snapshot) {
          if (snapshot.hasError && snapshot.error == 'not_logged_in') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/login');
            });
            return const SizedBox.shrink();
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma edição encontrada',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final edicoes = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: edicoes.length,
            itemBuilder: (ctx, i) {
              final ed = edicoes[i];
              final eventos = ed['eventos'] as List<Map<String, dynamic>>;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFdd1d21).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event_note,
                      color: Color(0xFFdd1d21),
                    ),
                  ),
                  title: Text(
                    ed['nome'] ?? ed['id'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${eventos.length} evento(s)',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  children:
                      eventos.map((evento) {
                        return _buildEventCard(context, evento);
                      }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> evento) {
    final data = (evento['data'] as Timestamp).toDate();
    final isPast = data.isBefore(DateTime.now());
    final isActive = evento['status'] == true;
    final inscricoesAbertas =
        isActive ? true : (evento['inscricoesAbertas'] == true);
    double parseNum(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) {
        final parsed = double.tryParse(
          v.replaceAll('.', '').replaceAll(',', '.'),
        );
        if (parsed != null) return parsed;
      }
      return 0.0;
    }

    String norm(String s) {
      // remove acentos, espaços extras e casefold
      const withAccents = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
      const noAccents = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
      final sb = StringBuffer();
      for (final ch in s.runes) {
        final i = withAccents.indexOf(String.fromCharCode(ch));
        sb.write(i >= 0 ? noAccents[i] : String.fromCharCode(ch));
      }
      return sb.toString().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    final price =
        (() {
          // 1) Preço simples direto
          final direct = parseNum(
            evento['price'] ??
                evento['preco'] ??
                evento['valor'] ??
                evento['price_cve'],
          );
          if (direct > 0) return direct;

          // 2) Mapa de preços por ilha/local em vários nomes possíveis
          final pricesMap =
              (evento['prices'] ??
                  evento['precos'] ??
                  evento['precosPorIlha'] ??
                  evento['pricesByLocation'] ??
                  evento['priceByIsland'] ??
                  evento['pricesByIsland'] ??
                  evento['locationPrices']);
          final islandKeyRaw = (evento['ilha'] ?? evento['local'])?.toString();
          if (pricesMap is Map) {
            // 2a) tentativa por chave exata
            if (islandKeyRaw != null) {
              final exact = parseNum(
                pricesMap[islandKeyRaw] ??
                    pricesMap[islandKeyRaw.toUpperCase()] ??
                    pricesMap[islandKeyRaw.toLowerCase()],
              );
              if (exact > 0) return exact;
            }
            // 2b) correspondência por normalização (ignora acentos/case)
            if (islandKeyRaw != null) {
              final islandNorm = norm(islandKeyRaw);
              for (final entry in pricesMap.entries) {
                final k = entry.key?.toString() ?? '';
                if (norm(k) == islandNorm) {
                  final v = parseNum(entry.value);
                  if (v > 0) return v;
                }
              }
            }
            // 2c) fallback: primeiro valor numérico positivo do mapa
            for (final v in pricesMap.values) {
              final n = parseNum(v);
              if (n > 0) return n;
            }
          }

          // 3) Estruturas aninhadas comuns (ex.: {pricing: {price: 1000}})
          final pricing = evento['pricing'];
          if (pricing is Map) {
            final nested = parseNum(
              pricing['price'] ?? pricing['preco'] ?? pricing['valor'],
            );
            if (nested > 0) return nested;
          }

          return 0.0;
        })();
    final isInscrito = evento['inscrito'] == true;

    // Determinar cor de fundo baseado no status
    Color backgroundColor;
    Color borderColor;
    if (!isActive) {
      backgroundColor = Colors.grey.shade100;
      borderColor = Colors.grey.shade300;
    } else if (isPast) {
      backgroundColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade200;
    } else if (isInscrito) {
      backgroundColor = Colors.green.shade50;
      borderColor = Colors.green.shade200;
    } else {
      backgroundColor = Colors.white;
      borderColor = Colors.grey.shade200;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap:
            isActive
                ? () {
                  Navigator.of(
                    context,
                  ).pushNamed('/event-details', arguments: evento);
                }
                : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com nome e badges
              Row(
                children: [
                  Expanded(
                    child: Text(
                      evento['nome'] ?? 'Evento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ),
                  if (!isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'INATIVO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isActive && isPast)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ENCERRADO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isInscrito)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 12),
                          SizedBox(width: 2),
                          Text(
                            'INSCRITO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Informações do evento
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isActive ? Colors.grey[600] : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(data),
                    style: TextStyle(
                      color: isActive ? Colors.grey[700] : Colors.grey,
                    ),
                  ),
                ],
              ),

              if (evento['local'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: isActive ? Colors.grey[600] : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        evento['local'],
                        style: TextStyle(
                          color: isActive ? Colors.grey[700] : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (evento['entidade'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.volunteer_activism,
                      size: 16,
                      color: isActive ? Colors.grey[600] : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Entidade: ${evento['entidade']}',
                        style: TextStyle(
                          color: isActive ? Colors.grey[700] : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Footer com preço e status de inscrição
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Preço
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFdd1d21).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Color(0xFFdd1d21),
                        ),
                        Text(
                          price > 0
                              ? '${price.toStringAsFixed(0)} CVE'
                              : 'Gratuito',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFdd1d21),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status de inscrição
                  Row(
                    children: [
                      if (isActive && !isPast)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                inscricoesAbertas
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                inscricoesAbertas
                                    ? Icons.check_circle_outline
                                    : Icons.lock_clock,
                                size: 14,
                                color:
                                    inscricoesAbertas
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                inscricoesAbertas
                                    ? 'Inscrições abertas'
                                    : 'Inscrições fechadas',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      inscricoesAbertas
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isActive) const SizedBox(width: 8),
                      if (isActive)
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
