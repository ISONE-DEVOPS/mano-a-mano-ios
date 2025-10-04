import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:mano_mano_dashboard/views/events/doacao_web_view.dart';

class EventDetailsView extends StatefulWidget {
  const EventDetailsView({super.key});

  @override
  State<EventDetailsView> createState() => _EventDetailsViewState();
}

class _EventDetailsViewState extends State<EventDetailsView> {
  bool _isInscrito = false;
  bool _isLoading = true;

  Map<String, dynamic>? _evento;
  DateTime? _data;
  bool _isActive = false;
  bool _inscricoesAbertas = false;
  bool _isPast = false;
  num _price = 0;
  Map<String, num> _pricesByLocation = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _evento = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    _loadEventStatus();
    _checkInscricao();
  }
  Future<void> _loadEventStatus() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      setState(() {
        _evento = null;
        _isActive = false;
        _inscricoesAbertas = false;
        _isPast = false;
        _price = 0;
      });
      return;
    }

    final editionId = args['editionId'];
    final eventId = args['id'];

    try {
      final docRef = FirebaseFirestore.instance
          .collection('editions')
          .doc(editionId)
          .collection('events')
          .doc(eventId);
      final snap = await docRef.get();
      final Map<String, dynamic> data = snap.data() ?? {};

      final timestamp = data['data'] as Timestamp?;
      final eventDate = timestamp?.toDate();
      final active = data['status'] == true;

      // Regra de validação: para eventos ATIVOS e FUTUROS, as inscrições
      // devem estar abertas por padrão, salvo se explicitamente fechadas.
      final inscrFlag = data.containsKey('inscricoesAbertas')
          ? (data['inscricoesAbertas'] == true)
          : null;

      final now = DateTime.now();
      final past = (eventDate != null && eventDate.isBefore(now));

      final inscricoesValidadas = (inscrFlag == true)
          || (inscrFlag == null && active && !past);

      final parsedPrices = <String, num>{};
      final rawPrices = data['pricesByLocation'];
      if (rawPrices is Map) {
        rawPrices.forEach((key, value) {
          if (value is num) {
            parsedPrices[key.toString()] = value;
          } else if (value is String) {
            final v = num.tryParse(value);
            if (v != null) parsedPrices[key.toString()] = v;
          }
        });
      }

      setState(() {
        _evento = {...args, ...data, 'editionId': editionId, 'id': eventId};
        _data = eventDate;
        _isActive = active;
        _isPast = past;
        _inscricoesAbertas = inscricoesValidadas;
        final rawPrice = data['price'];
        if (rawPrice is int) {
          _price = rawPrice;
        } else if (rawPrice is double) {
          _price = rawPrice;
        } else {
          _price = 0;
        }
        _pricesByLocation = parsedPrices;
        if (_price == 0 && parsedPrices.isNotEmpty) {
          _price = parsedPrices.values.first;
        }
      });
    } catch (e) {
      // Em caso de erro, manter fallback com os argumentos e lógica atual
      final timestamp = args['data'] as Timestamp?;
      final eventDate = timestamp?.toDate();
      final active = args['status'] == true;
      final past = (eventDate != null && eventDate.isBefore(DateTime.now()));
      final inscrArg = args['inscricoesAbertas'];
      final inscricoesValidadas = (inscrArg == true) || (inscrArg == null && active && !past);

      final parsedPrices = <String, num>{};
      final rawPrices = args['pricesByLocation'];
      if (rawPrices is Map) {
        rawPrices.forEach((key, value) {
          if (value is num) {
            parsedPrices[key.toString()] = value;
          } else if (value is String) {
            final v = num.tryParse(value);
            if (v != null) parsedPrices[key.toString()] = v;
          }
        });
      }

      setState(() {
        _evento = args;
        _data = eventDate;
        _isActive = active;
        _isPast = past;
        _inscricoesAbertas = inscricoesValidadas;
        final rawPrice = args['price'];
        if (rawPrice is int) {
          _price = rawPrice;
        } else if (rawPrice is double) {
          _price = rawPrice;
        } else {
          _price = 0;
        }
        _pricesByLocation = parsedPrices;
        if (_price == 0 && parsedPrices.isNotEmpty) {
          _price = parsedPrices.values.first;
        }
      });
    }
  }

  Future<void> _checkInscricao() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final evento =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (evento == null) {
      setState(() => _isLoading = false);
      return;
    }

    final editionId = evento['editionId'];
    final eventId = evento['id'];

    try {
      final userEventDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('events')
          .where('eventoId', isEqualTo: 'editions/$editionId/events/$eventId')
          .where('ativo', isEqualTo: true)
          .get();

      setState(() {
        _isInscrito = userEventDoc.docs.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final evento = _evento;
    if (evento == null) {
      return const Scaffold(
        body: Center(child: Text('Evento não encontrado.')),
      );
    }

    final data = _data;
    final isPast = _isPast;
    final isActive = _isActive;
    final inscricoesAbertas = _inscricoesAbertas;
    final price = _price;
    final pricesByLocation = _pricesByLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Evento'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header com imagem ou gradient
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFdd1d21),
                    const Color(0xFFdd1d21).withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.event,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        (evento['nome'] ?? evento['name'] ?? 'Evento').toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Badges de status
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.grey.shade100,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (!isActive)
                    _buildBadge('Evento Inativo', Colors.grey, Icons.cancel),
                  if (isActive && isPast)
                    _buildBadge('Evento Encerrado', Colors.orange, Icons.event_busy),
                  if (isActive && !isPast && inscricoesAbertas)
                    _buildBadge(
                      'Inscrições Abertas',
                      Colors.green,
                      Icons.check_circle,
                    ),
                  if (isActive && !isPast && !inscricoesAbertas)
                    _buildBadge(
                      'Inscrições Fechadas',
                      Colors.orange,
                      Icons.lock_clock,
                    ),
                  if (_isInscrito)
                    _buildBadge('Você está inscrito', Colors.blue, Icons.how_to_reg),
                ],
              ),
            ),

            // Conteúdo principal
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de informações principais
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (data != null)
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Data e Hora',
                              DateFormat('dd/MM/yyyy HH:mm').format(data),
                            ),
                          if (evento['local'] != null) ...[
                            const Divider(height: 24),
                            _buildInfoRow(
                              Icons.location_on,
                              'Local',
                              evento['local'],
                            ),
                          ],
                          if (evento['entidade'] != null) ...[
                            const Divider(height: 24),
                            _buildInfoRow(
                              Icons.volunteer_activism,
                              'Entidade Beneficiada',
                              evento['entidade'],
                            ),
                          ],
                          const Divider(height: 24),
                          if (pricesByLocation.isNotEmpty) ...[
                            _buildInfoRow(
                              Icons.attach_money,
                              'Valor por Ilha',
                              pricesByLocation.length == 1
                                  ? '${pricesByLocation.keys.first}: ${pricesByLocation.values.first.toDouble().toStringAsFixed(0)} CVE'
                                  : 'Consulte abaixo',
                              valueColor: const Color(0xFFdd1d21),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children: (pricesByLocation.entries
                                    .toList()
                                    ..sort((a, b) => a.key.compareTo(b.key)))
                                  .map((e) => Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: _buildInfoRow(
                                          Icons.place,
                                          e.key,
                                          '${e.value.toDouble().toStringAsFixed(0)} CVE',
                                          valueColor: const Color(0xFFdd1d21),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ] else ...[
                            _buildInfoRow(
                              Icons.attach_money,
                              'Valor da Inscrição',
                              price > 0 ? '${price.toDouble().toStringAsFixed(0)} CVE' : 'Gratuito',
                              valueColor: const Color(0xFFdd1d21),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Descrição
                  if (evento['descricao'] != null) ...[
                    const Text(
                      'Sobre o Evento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          evento['descricao'],
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Mensagem motivacional
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFdd1d21).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFdd1d21).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: Color(0xFFdd1d21),
                          size: 32,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Juntos, podemos transformar quilómetros em esperança.',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botões de ação
                  /* 
                  // BOTÃO DE DOAÇÃO - Comentado conforme solicitado
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFdd1d21),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.favorite, size: 24),
                      label: const Text(
                        'Contribuir com Doação',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const DoacaoWebView(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  */

                  // Botão de inscrição
                  if (isActive && !isPast && inscricoesAbertas)
                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isInscrito
                                    ? Colors.grey
                                    : Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              icon: Icon(
                                _isInscrito
                                    ? Icons.check_circle
                                    : Icons.event_available,
                                size: 24,
                              ),
                              label: Text(
                                _isInscrito
                                    ? 'Você já está inscrito'
                                    : 'Inscrever-se no Evento',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: _isInscrito
                                  ? null
                                  : () {
                                      Navigator.of(context).pushNamed(
                                        '/event-inscription',
                                        arguments: evento,
                                      ).then((_) => _checkInscricao());
                                    },
                            ),
                    ),

                  // Mensagem se não puder se inscrever
                  if (!isActive || isPast || !inscricoesAbertas) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              !isActive
                                  ? 'Este evento está inativo no momento.'
                                  : isPast
                                      ? 'Este evento já foi encerrado.'
                                      : 'As inscrições para este evento estão fechadas.',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}