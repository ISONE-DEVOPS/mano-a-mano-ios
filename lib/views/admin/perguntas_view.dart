import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerguntasView extends StatefulWidget {
  const PerguntasView({super.key});

  @override
  State<PerguntasView> createState() => _PerguntasViewState();
}

class _PerguntasViewState extends State<PerguntasView> {
  // Cores do tema Mano a Mano
  static const Color laranjaPrimario = Color(0xFFFF6B00);
  static const Color laranjaEscuro = Color(0xFFE55A00);
  static const Color pretoPrimario = Color(0xFF1A1A1A);
  static const Color cinzaClaro = Color(0xFFF5F5F5);
  static const Color brancoCard = Colors.white;

  String? _edicaoSelecionada;
  Map<String, String> _edicoes = {};
  String? _eventoSelecionado;
  Map<String, String> _eventos = {};
  final _perguntaController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _pontosController = TextEditingController();
  final List<TextEditingController> _opcoes = List.generate(
    3,
    (_) => TextEditingController(),
  );
  int _respostaCorreta = 0;
  String? _perguntaIdEmEdicao;

  @override
  void initState() {
    super.initState();
    _carregarEdicoes();
  }

  void _carregarEdicoes() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('editions').get();
    final mapa = {
      for (var doc in snapshot.docs)
        doc.id: doc.data()['nome']?.toString() ?? doc.id,
    };
    setState(() => _edicoes = Map<String, String>.from(mapa));
  }

  void _carregarEventos(String editionId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('editions')
            .doc(editionId)
            .collection('events')
            .get();
    final mapa = {
      for (var doc in snapshot.docs)
        doc.id: doc.data()['nome']?.toString() ?? doc.id,
    };
    setState(() => _eventos = Map<String, String>.from(mapa));
  }

  void _salvarPergunta() async {
    final pergunta = _perguntaController.text.trim();
    final categoria = _categoriaController.text.trim();
    final opcoes = _opcoes.map((c) => c.text.trim()).toList();
    final pontosText = _pontosController.text.trim();
    final pontos = int.tryParse(pontosText);

    if (_edicaoSelecionada == null || _eventoSelecionado == null) {
      _mostrarSnackBar(
        'Selecione uma edição e um evento válido',
        isError: true,
      );
      return;
    }

    if (pergunta.isEmpty ||
        categoria.isEmpty ||
        opcoes.any((o) => o.isEmpty) ||
        pontos == null) {
      _mostrarSnackBar('Preencha todos os campos corretamente', isError: true);
      return;
    }

    try {
      if (_perguntaIdEmEdicao != null) {
        if (_perguntaIdEmEdicao!.isEmpty) {
          _mostrarSnackBar(
            'Erro interno: ID da pergunta inválido',
            isError: true,
          );
          return;
        }
        await FirebaseFirestore.instance
            .collection('perguntas')
            .doc(_perguntaIdEmEdicao!)
            .update({
              'editionId': _edicaoSelecionada,
              'eventId': _eventoSelecionado,
              'pergunta': pergunta,
              'categoria': categoria,
              'respostas': opcoes,
              'respostaCerta': _respostaCorreta,
              'pontos': pontos,
            });
      } else {
        await FirebaseFirestore.instance.collection('perguntas').add({
          'editionId': _edicaoSelecionada,
          'eventId': _eventoSelecionado,
          'pergunta': pergunta,
          'categoria': categoria,
          'respostas': opcoes,
          'respostaCerta': _respostaCorreta,
          'pontos': pontos,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      _mostrarSnackBar(
        _perguntaIdEmEdicao != null
            ? 'Pergunta atualizada com sucesso!'
            : 'Pergunta criada com sucesso!',
      );

      _limparFormulario();
    } catch (e) {
      if (!mounted) return;
      _mostrarSnackBar('Erro ao salvar: $e', isError: true);
    }
  }

  void _limparFormulario() {
    setState(() {
      _edicaoSelecionada = null;
      _eventoSelecionado = null;
      _perguntaController.clear();
      _categoriaController.clear();
      _pontosController.clear();
      for (final c in _opcoes) {
        c.clear();
      }
      _respostaCorreta = 0;
      _eventos = {};
      _perguntaIdEmEdicao = null;
    });
  }

  void _mostrarSnackBar(String mensagem, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cinzaClaro,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [laranjaPrimario, laranjaEscuro],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: laranjaPrimario.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.quiz_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gestão de Perguntas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Crie e gerencie perguntas para o rally',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
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

          // Formulário
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildFormularioCard(),
                  const SizedBox(height: 32),
                  _buildListaPerguntas(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioCard() {
    return Container(
      decoration: BoxDecoration(
        color: brancoCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header do formulário
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: pretoPrimario,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _perguntaIdEmEdicao != null ? Icons.edit : Icons.add_circle,
                  color: laranjaPrimario,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  _perguntaIdEmEdicao != null
                      ? 'Editar Pergunta'
                      : 'Nova Pergunta',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo do formulário
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Edição e Evento - em grid
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Edição',
                        value: _edicaoSelecionada,
                        items: _edicoes,
                        icon: Icons.event_note,
                        onChanged: (value) {
                          setState(() {
                            _edicaoSelecionada = value;
                            _eventoSelecionado = null;
                            if (value != null) _carregarEventos(value);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Evento',
                        value: _eventoSelecionado,
                        items: _eventos,
                        icon: Icons.flag,
                        onChanged: (value) {
                          setState(() => _eventoSelecionado = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Pergunta
                _buildTextField(
                  controller: _perguntaController,
                  label: 'Pergunta',
                  icon: Icons.help_outline,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Categoria e Pontos
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _categoriaController,
                        label: 'Categoria',
                        icon: Icons.category,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _pontosController,
                        label: 'Pontos',
                        icon: Icons.stars,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Divider decorativo
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: cinzaClaro)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OPÇÕES DE RESPOSTA',
                        style: TextStyle(
                          color: pretoPrimario,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Expanded(child: Container(height: 1, color: cinzaClaro)),
                  ],
                ),
                const SizedBox(height: 24),

                // Opções de resposta
                ...List.generate(_opcoes.length, (index) {
                  final isCorreta = _respostaCorreta == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              isCorreta
                                  ? laranjaPrimario
                                  : Colors.grey.shade300,
                          width: isCorreta ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color:
                            isCorreta
                                ? laranjaPrimario.withValues(alpha: 0.2)
                                : Colors.white,
                      ),
                      child: Row(
                        children: [
                          // Radio button customizado
                          InkWell(
                            onTap:
                                () => setState(() => _respostaCorreta = index),
                            child: Container(
                              margin: const EdgeInsets.all(12),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      isCorreta
                                          ? laranjaPrimario
                                          : Colors.grey.shade400,
                                  width: 2,
                                ),
                                color:
                                    isCorreta ? laranjaPrimario : Colors.white,
                              ),
                              child:
                                  isCorreta
                                      ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 18,
                                      )
                                      : null,
                            ),
                          ),
                          // Campo de texto
                          Expanded(
                            child: TextFormField(
                              controller: _opcoes[index],
                              style: TextStyle(
                                color: pretoPrimario,
                                fontWeight:
                                    isCorreta
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Opção ${index + 1}',
                                labelStyle: TextStyle(
                                  color:
                                      isCorreta
                                          ? laranjaPrimario
                                          : Colors.grey.shade600,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          if (isCorreta)
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: laranjaPrimario,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'CORRETA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 32),

                // Botões de ação
                Row(
                  children: [
                    if (_perguntaIdEmEdicao != null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _limparFormulario,
                          icon: const Icon(Icons.close),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _salvarPergunta,
                        icon: Icon(
                          _perguntaIdEmEdicao != null ? Icons.save : Icons.add,
                        ),
                        label: Text(
                          _perguntaIdEmEdicao != null
                              ? 'Atualizar Pergunta'
                              : 'Criar Pergunta',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: laranjaPrimario,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaPerguntas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header da lista
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: pretoPrimario,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.list_alt,
                  color: laranjaPrimario,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Perguntas Cadastradas',
                style: TextStyle(
                  color: pretoPrimario,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Lista de perguntas
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('perguntas')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: laranjaPrimario),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: brancoCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma pergunta cadastrada',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crie sua primeira pergunta usando o formulário acima',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final docs = snapshot.data!.docs;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (context, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final isEditing = _perguntaIdEmEdicao == doc.id;

                return _buildPerguntaCard(doc.id, data, isEditing);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPerguntaCard(
    String id,
    Map<String, dynamic> data,
    bool isEditing,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: brancoCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditing ? laranjaPrimario : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isEditing
                    ? laranjaPrimario.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isEditing
                      ? laranjaPrimario.withValues(alpha: 0.1)
                      : cinzaClaro,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    data['pergunta'] ?? '',
                    style: TextStyle(
                      color: pretoPrimario,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isEditing)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: laranjaPrimario,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'EDITANDO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Conteúdo do card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categoria e Pontos
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.category,
                      label: data['categoria'] ?? 'Sem categoria',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.stars,
                      label: '${data['pontos'] ?? 0} pontos',
                      color: Colors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Opções de resposta
                const Text(
                  'Opções:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate((data['respostas'] as List?)?.length ?? 0, (
                  i,
                ) {
                  final isCorreta = data['respostaCerta'] == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          isCorreta
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 16,
                          color: isCorreta ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data['respostas'][i] ?? '',
                            style: TextStyle(
                              color: pretoPrimario,
                              fontWeight:
                                  isCorreta
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Ações
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cinzaClaro,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editarPergunta(id, data),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Editar'),
                  style: TextButton.styleFrom(foregroundColor: laranjaPrimario),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _confirmarExclusao(id),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Excluir'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color.shade800,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required Map<String, String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: pretoPrimario,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cinzaClaro,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: pretoPrimario),
              style: TextStyle(
                color: pretoPrimario,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              hint: Row(
                children: [
                  Icon(icon, size: 18, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    'Selecione $label',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              onChanged: onChanged,
              items:
                  items.entries
                      .map(
                        (entry) => DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: pretoPrimario,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cinzaClaro,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(
              color: pretoPrimario,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: laranjaPrimario, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintText: 'Digite $label',
              hintStyle: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  void _editarPergunta(String id, Map<String, dynamic> data) {
    setState(() {
      _perguntaIdEmEdicao = id;
      _edicaoSelecionada = data['editionId'];
      _eventoSelecionado = data['eventId'];
      _perguntaController.text = data['pergunta'] ?? '';
      _categoriaController.text = data['categoria'] ?? '';
      _pontosController.text = data['pontos']?.toString() ?? '';
      _respostaCorreta = data['respostaCerta'] ?? 0;

      final respostas = data['respostas'] as List?;
      for (int i = 0; i < _opcoes.length; i++) {
        _opcoes[i].text = i < (respostas?.length ?? 0) ? respostas![i] : '';
      }

      if (_edicaoSelecionada != null) {
        _carregarEventos(_edicaoSelecionada!);
      }
    });

    // Scroll para o formulário
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _confirmarExclusao(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                const SizedBox(width: 12),
                const Text('Confirmar Exclusão'),
              ],
            ),
            content: const Text(
              'Tem certeza que deseja excluir esta pergunta? Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('perguntas')
            .doc(id)
            .delete();
        if (mounted) {
          _mostrarSnackBar('Pergunta excluída com sucesso');
        }
      } catch (e) {
        if (mounted) {
          _mostrarSnackBar('Erro ao excluir pergunta: $e', isError: true);
        }
      }
    }
  }

  @override
  void dispose() {
    _perguntaController.dispose();
    _categoriaController.dispose();
    _pontosController.dispose();
    for (final controller in _opcoes) {
      controller.dispose();
    }
    super.dispose();
  }
}
