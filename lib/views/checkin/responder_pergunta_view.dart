// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ResponderPerguntaView extends StatefulWidget {
  final String checkpointId;

  const ResponderPerguntaView({super.key, required this.checkpointId});

  @override
  State<ResponderPerguntaView> createState() => _ResponderPerguntaViewState();
}

class _ResponderPerguntaViewState extends State<ResponderPerguntaView> {
  Map<String, dynamic>? pergunta;
  Map<String, dynamic>? checkpoint;
  int? respostaSelecionada;
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _carregarPergunta();
  }

  Future<void> _carregarPergunta() async {
    try {
      // Buscar checkpoint
      final checkpointDoc =
          await FirebaseFirestore.instance
              .collection('editions')
              .doc('shell_2025')
              .collection('events')
              .doc('shell_km_02')
              .collection('checkpoints')
              .doc(widget.checkpointId)
              .get();

      if (checkpointDoc.exists) {
        checkpoint = checkpointDoc.data();
        final perguntaRef = checkpoint!['pergunta1Ref'] as DocumentReference?;

        if (perguntaRef != null) {
          final perguntaDoc = await perguntaRef.get();
          if (perguntaDoc.exists) {
            pergunta = perguntaDoc.data() as Map<String, dynamic>?;
          }
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar pergunta: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _submeterResposta() async {
    if (respostaSelecionada == null) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final respostaCorreta = pergunta!['respostaCerta'] as int;
      final acertou = respostaSelecionada == respostaCorreta;
      final pontuacaoPergunta =
          acertou ? (pergunta!['pontos'] as int? ?? 10) : 0;

      // Atualizar pontuação no Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('eventos')
          .doc('shell_2025')
          .collection('pontuacoes')
          .doc(widget.checkpointId)
          .update({
            'respostaCorreta': acertou,
            'pontuacaoPergunta': pontuacaoPergunta,
            'perguntaRespondida': true,
            'respostaSelecionada': respostaSelecionada,
          });

      // Mostrar resultado baseado na resposta
      if (acertou) {
        _mostrarResultadoCorreto(pontuacaoPergunta);
      } else {
        _mostrarResultadoIncorreto();
      }
    } catch (e) {
      debugPrint('Erro ao submeter resposta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao submeter resposta'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  void _mostrarResultadoCorreto(int pontos) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text(
                  'Parabéns!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Resposta correta!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  'Ganhaste $pontos pontos!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fecha o dialog
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  void _mostrarResultadoIncorreto() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(Icons.close, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text(
                  'Oops!',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: Text(
              'Infelizmente não acertaste',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fecha o dialog
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pergunta - ${widget.checkpointId}'),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : pergunta == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Pergunta não encontrada',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed:
                          () => Navigator.of(
                            context,
                          ).pushReplacementNamed('/home'),
                      child: Text('Voltar ao Início'),
                    ),
                  ],
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.quiz,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Pergunta',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              pergunta!['pergunta'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Escolha uma resposta:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: (pergunta!['respostas'] as List).length,
                        itemBuilder: (context, index) {
                          final resposta = pergunta!['respostas'][index];
                          final isSelected = respostaSelecionada == index;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Card(
                              elevation: isSelected ? 4 : 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color:
                                      isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: InkWell(
                                onTap:
                                    isSubmitting
                                        ? null
                                        : () {
                                          setState(() {
                                            respostaSelecionada = index;
                                          });
                                        },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? AppColors.primary
                                                    : Colors.grey,
                                            width: 2,
                                          ),
                                          color:
                                              isSelected
                                                  ? AppColors.primary
                                                  : Colors.transparent,
                                        ),
                                        child:
                                            isSelected
                                                ? Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: Colors.white,
                                                )
                                                : null,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${String.fromCharCode(65 + index)}) $resposta',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                            color:
                                                isSelected
                                                    ? AppColors.primary
                                                    : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed:
                          respostaSelecionada != null && !isSubmitting
                              ? _submeterResposta
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                      ),
                      child:
                          isSubmitting
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Submetendo...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                              : Text(
                                'Submeter Resposta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
    );
  }
}
