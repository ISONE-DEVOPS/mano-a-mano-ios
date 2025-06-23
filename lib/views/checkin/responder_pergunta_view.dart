import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResponderPerguntaView extends StatefulWidget {
  final String checkpointId;
  const ResponderPerguntaView({super.key, required this.checkpointId});

  @override
  State<ResponderPerguntaView> createState() => _ResponderPerguntaViewState();
}

class _ResponderPerguntaViewState extends State<ResponderPerguntaView> {
  String? perguntaTexto;
  List<dynamic> respostas = [];
  int? respostaCerta;
  String? perguntaId;
  int? respostaSelecionada;
  bool respostaEnviada = false;
  bool acertou = false;
  int pontos = 0;

  @override
  void initState() {
    super.initState();
    carregarPergunta();
  }

  Future<void> carregarPergunta() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Verificar se já respondeu (usando a mesma estrutura da CheckinView)
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('eventos') // Mudado de 'events' para 'eventos'
        .doc('shell_2025') // Mudado de 'shell_km_02' para 'shell_2025'
        .collection('pontuacoes')
        .doc(widget.checkpointId)
        .get();

    if (doc.exists && doc.data()?['perguntaRespondida'] == true) {
      setState(() {
        respostaEnviada = true;
        acertou = doc.data()?['respostaCorreta'] ?? false;
        pontos = doc.data()?['pontuacaoJogo'] ?? 0; // Mudado para coincidir com CheckinView
        respostaSelecionada = doc.data()?['respostaDada'];
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) Navigator.pop(context);
      });
      return;
    }

    // Buscar o checkpoint para obter o campo pergunta1Id
    final checkpointDoc = await FirebaseFirestore.instance
        .collection('checkpoints')
        .doc(widget.checkpointId)
        .get();

    final perguntaRef = checkpointDoc.data()?['pergunta1Id'] ??
        checkpointDoc.data()?['perguntaRef'];
    String? pergunta1Id;

    if (perguntaRef is DocumentReference) {
      pergunta1Id = perguntaRef.id;
    } else if (perguntaRef is String && perguntaRef.contains('/')) {
      pergunta1Id = perguntaRef.split('/').last;
    } else if (perguntaRef is String) {
      pergunta1Id = perguntaRef;
    }

    // Se não encontrar a pergunta no checkpoint, buscar por eventId
    if (pergunta1Id == null) {
      // Buscar pergunta por eventId como fallback
      final perguntasSnapshot = await FirebaseFirestore.instance
          .collection('perguntas')
          .where('eventId', isEqualTo: 'shell_km_02')
          .limit(1)
          .get();

      if (perguntasSnapshot.docs.isNotEmpty) {
        pergunta1Id = perguntasSnapshot.docs.first.id;
      }
    }

    if (pergunta1Id == null) return;

    final perguntaDoc = await FirebaseFirestore.instance
        .collection('perguntas')
        .doc(pergunta1Id)
        .get();

    if (!perguntaDoc.exists) return;

    setState(() {
      perguntaId = perguntaDoc.id;
      perguntaTexto = perguntaDoc['pergunta'];
      final respostasData = perguntaDoc['respostas'];
      
      // Converter Map para List se necessário
      if (respostasData is Map) {
        respostas = [];
        for (int i = 0; i < respostasData.length; i++) {
          respostas.add(respostasData[i.toString()]);
        }
      } else {
        respostas = respostasData;
      }
      
      respostaCerta = perguntaDoc['respostaCerta'];
      pontos = perguntaDoc['pontos'] ?? 0;
    });
  }

  Future<void> enviarResposta() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || respostaSelecionada == null) return;

    final acertouResposta = respostaSelecionada == respostaCerta;
    final pontuacao = acertouResposta ? pontos : 0;

    // Atualizar usando a mesma estrutura da CheckinView
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('eventos') // Mudado de 'events' para 'eventos'
        .doc('shell_2025') // Mudado de 'shell_km_02' para 'shell_2025'
        .collection('pontuacoes')
        .doc(widget.checkpointId)
        .update({
      'perguntaRespondida': true, // Marca que respondeu
      'respostaCorreta': acertouResposta,
      'respostaDada': respostaSelecionada, // Salva qual resposta foi dada
      'pontuacaoJogo': pontuacao, // Usar o mesmo nome da CheckinView
      'perguntaId': perguntaId, // Referência à pergunta
    });

    // Atualizar pontuação total do evento se acertou
    if (acertouResposta) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('eventos')
          .doc('shell_2025')
          .update({
        'pontuacaoTotal': FieldValue.increment(pontuacao),
      });
    }

    setState(() {
      respostaEnviada = true;
      acertou = acertouResposta;
    });

    // Voltar automaticamente após mostrar o resultado
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pergunta - ${widget.checkpointId}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: perguntaTexto == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            perguntaTexto!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pontuação: $pontos pontos',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: respostas.length,
                      itemBuilder: (context, index) {
                        String respostaTexto = respostas[index].toString();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: RadioListTile<int>(
                            title: Text(respostaTexto),
                            value: index,
                            groupValue: respostaSelecionada,
                            onChanged: respostaEnviada
                                ? null
                                : (val) => setState(() {
                                      respostaSelecionada = val;
                                    }),
                            activeColor: Colors.blue,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!respostaEnviada)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: respostaSelecionada != null ? enviarResposta : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Confirmar Resposta',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  if (respostaEnviada)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: acertou ? Colors.green.shade50 : Colors.red.shade50,
                        border: Border.all(
                          color: acertou ? Colors.green : Colors.red,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            acertou ? Icons.check_circle : Icons.cancel,
                            color: acertou ? Colors.green : Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            acertou
                                ? 'Resposta correta! Ganhou $pontos pontos.'
                                : 'Resposta errada. Tente aprender com isso!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: acertou ? Colors.green : Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (!acertou && respostaCerta != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Resposta correta: ${respostas[respostaCerta!]}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}