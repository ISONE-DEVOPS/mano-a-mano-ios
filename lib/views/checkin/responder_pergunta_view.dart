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

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('events')
            .doc('shell_km_02')
            .collection('pontuacoes')
            .doc(widget.checkpointId)
            .get();

    if (doc.exists && doc.data()?['respostaSelecionada'] != null) {
      setState(() {
        respostaEnviada = true;
        acertou = doc.data()?['respostaCorreta'] ?? false;
        pontos = doc.data()?['pontuacaoPergunta'] ?? 0;
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) Navigator.pop(context);
      });
      return;
    }

    // Buscar o checkpoint para obter o campo pergunta1Id
    final checkpointDoc =
        await FirebaseFirestore.instance
            .collection('checkpoints')
            .doc(widget.checkpointId)
            .get();

    final perguntaRef =
        checkpointDoc.data()?['pergunta1Id'] ??
        checkpointDoc.data()?['perguntaRef'];
    String? pergunta1Id;

    if (perguntaRef is DocumentReference) {
      pergunta1Id = perguntaRef.id;
    } else if (perguntaRef is String && perguntaRef.contains('/')) {
      pergunta1Id = perguntaRef.split('/').last;
    } else if (perguntaRef is String) {
      pergunta1Id = perguntaRef;
    }
    if (pergunta1Id == null) return;

    final perguntaDoc =
        await FirebaseFirestore.instance
            .collection('perguntas')
            .doc(pergunta1Id)
            .get();

    if (!perguntaDoc.exists) return;

    setState(() {
      perguntaId = perguntaDoc.id;
      perguntaTexto = perguntaDoc['pergunta'];
      respostas = perguntaDoc['respostas'];
      respostaCerta = perguntaDoc['respostaCerta'];
      pontos = perguntaDoc['pontos'] ?? 0;
    });
  }

  Future<void> enviarResposta() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || respostaSelecionada == null) return;

    final acertouResposta = respostaSelecionada == respostaCerta;
    final pontuacao = acertouResposta ? pontos : 0;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('events')
        .doc('shell_km_02')
        .collection('pontuacoes')
        .doc(widget.checkpointId)
        .set({
          'checkpointId': widget.checkpointId,
          'respostaSelecionada': respostaSelecionada,
          'respostaCorreta': acertouResposta,
          'pontuacaoPergunta': pontuacao,
          'timestampEntrada': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    setState(() {
      respostaEnviada = true;
      acertou = acertouResposta;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pergunta - ${widget.checkpointId}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            perguntaTexto == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(perguntaTexto!, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 20),
                    ...List.generate(respostas.length, (index) {
                      return RadioListTile<int>(
                        title: Text(respostas[index]),
                        value: index,
                        groupValue: respostaSelecionada,
                        onChanged:
                            respostaEnviada
                                ? null
                                : (val) => setState(() {
                                  respostaSelecionada = val;
                                }),
                      );
                    }),
                    const SizedBox(height: 20),
                    if (!respostaEnviada)
                      ElevatedButton(
                        onPressed: enviarResposta,
                        child: const Text('Responder'),
                      ),
                    if (respostaEnviada)
                      Text(
                        acertou
                            ? '✅ Resposta correta! Ganhou $pontos pontos.'
                            : '❌ Resposta errada. Tente aprender com isso!',
                        style: TextStyle(
                          fontSize: 16,
                          color: acertou ? Colors.green : Colors.red,
                        ),
                      ),
                  ],
                ),
      ),
    );
  }
}
