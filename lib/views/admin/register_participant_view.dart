import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterParticipantView extends StatefulWidget {
  final String? userId;
  final String? editionId;
  final String? eventId;
  const RegisterParticipantView({
    super.key,
    this.userId,
    this.editionId,
    this.eventId,
  });

  @override
  State<RegisterParticipantView> createState() =>
      _RegisterParticipantViewState();
}

class _RegisterParticipantViewState extends State<RegisterParticipantView> {
  bool isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final TextEditingController veiculoMatricula = TextEditingController();
  final TextEditingController veiculoModelo = TextEditingController();

  final TextEditingController equipaNome = TextEditingController();
  final TextEditingController equipaHino = TextEditingController();

  List<Map<String, String>> acompanhantes = [];

  String? veiculoId;
  String? equipaId;

  void adicionarAcompanhante() {
    setState(() {
      acompanhantes.add({
        "nome": "",
        "telefone": "",
        "tshirt": "",
      });
    });
  }

  void carregarDados(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    final dados = doc.data();
    if (dados != null) {
      setState(() {
        nomeController.text = dados['nome'] ?? '';
        emailController.text = dados['email'] ?? '';
        equipaId = dados['equipaId'];
        veiculoId = dados['veiculoId'];
      });

      if (veiculoId != null && veiculoId!.isNotEmpty) {
        final vDoc = await _db.collection('veiculos').doc(veiculoId!).get();
        final v = vDoc.data();
        if (v != null) {
          veiculoMatricula.text = v['matricula'] ?? '';
          veiculoModelo.text = v['modelo'] ?? '';
        }
      }

      if (equipaId != null && equipaId!.isNotEmpty) {
        final eDoc = await _db.collection('equipas').doc(equipaId!).get();
        final e = eDoc.data();
        if (e != null) {
          equipaNome.text = e['nome'] ?? '';
          equipaHino.text = e['hino'] ?? '';
        }
      }
    }
  }

  Future<void> salvarParticipante() async {
    if (!_formKey.currentState!.validate()) return;

    if (acompanhantes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insira pelo menos 1 acompanhante")),
      );
      return;
    }

    try {
      if (widget.userId != null) {
        await _db.collection('users').doc(widget.userId).update({
          "nome": nomeController.text,
          "email": emailController.text,
          "editionId": widget.editionId,
          "eventId": widget.eventId,
        });
        if (veiculoId != null) {
          // limpar passageiros antes de adicionar novos acompanhantes
          await _db.collection('veiculos').doc(veiculoId).update({
            "matricula": veiculoMatricula.text,
            "modelo": veiculoModelo.text,
            "passageiros": [],
          });
        }
        if (equipaId != null) {
          // manter condutor como membro e limpar os outros membros antes de adicionar acompanhantes
          final docUser = await _db.collection('users').doc(widget.userId).get();
          final condutorId = docUser.id;
          await _db.collection('equipas').doc(equipaId).update({
            "nome": equipaNome.text,
            "hino": equipaHino.text,
            "membros": [condutorId],
          });
        }
        if (veiculoId != null) {
          await _db.collection('veiculos').doc(veiculoId).update({
            "passageiros": acompanhantes,
          });
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Participante atualizado com sucesso.")),
        );
        return;
      }

      final cred = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final condutorId = cred.user!.uid;

      // Criar equipa
      final equipaDoc = await _db.collection('equipas').add({
        "nome": equipaNome.text,
        "hino": equipaHino.text,
        "bandeiraUrl": "", // poderá ser carregada depois
        "pontuacaoTotal": 0,
        "ranking": 0,
        "membros": [condutorId],
      });

      // Criar veículo
      final veiculoDoc = await _db.collection('veiculos').add({
        "matricula": veiculoMatricula.text,
        "modelo": veiculoModelo.text,
        "condutorId": condutorId,
        "passageiros": [],
      });

      // Criar utilizador condutor
      await _db.collection('users').doc(condutorId).set({
        "nome": nomeController.text,
        "email": emailController.text,
        "tipo": "user",
        "equipaId": equipaDoc.id,
        "veiculoId": veiculoDoc.id,
        "checkpointsVisitados": [],
        "editionId": widget.editionId,
        "eventId": widget.eventId,
      });

      await _db.collection('veiculos').doc(veiculoDoc.id).update({
        "passageiros": acompanhantes,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Participante registado com sucesso.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  @override
  void initState() {
    super.initState();
    isEditing = widget.userId != null && widget.userId!.isNotEmpty;
    if (isEditing) {
      carregarDados(widget.userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Editar Participante" : "Registar Participante")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "Condutor",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: "Nome"),
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              if (!isEditing)
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Senha"),
                ),
              const SizedBox(height: 20),

              const Text(
                "Veículo",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: veiculoMatricula,
                decoration: const InputDecoration(labelText: "Matrícula"),
              ),
              TextFormField(
                controller: veiculoModelo,
                decoration: const InputDecoration(labelText: "Modelo"),
              ),
              const SizedBox(height: 20),

              const Text(
                "Equipa",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: equipaNome,
                decoration: const InputDecoration(labelText: "Nome da Equipa"),
              ),
              TextFormField(
                controller: equipaHino,
                decoration: const InputDecoration(labelText: "Hino"),
              ),
              const SizedBox(height: 20),

              const Text(
                "Acompanhantes",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...acompanhantes.map((a) {
                return Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Nome"),
                      initialValue: a["nome"],
                      onChanged: (value) => a["nome"] = value,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Telefone"),
                      initialValue: a["telefone"],
                      onChanged: (value) => a["telefone"] = value,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "T-Shirt"),
                      initialValue: a["tshirt"],
                      onChanged: (value) => a["tshirt"] = value,
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              }),
              ElevatedButton(
                onPressed: adicionarAcompanhante,
                child: const Text("Adicionar Acompanhante"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: salvarParticipante,
                child: Text(isEditing ? "Atualizar Participante" : "Salvar Participante"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
