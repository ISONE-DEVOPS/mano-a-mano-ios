import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateTotalScoreView extends StatefulWidget {
  const UpdateTotalScoreView({super.key});

  @override
  State<UpdateTotalScoreView> createState() => _UpdateTotalScoreViewState();
}

class _UpdateTotalScoreViewState extends State<UpdateTotalScoreView>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _isUpdating = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _searchQuery = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadScores();
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadScores() async {
    setState(() => _isLoading = true);

    try {
      QuerySnapshot snapshot = await _firestore.collection('ranking').get();

      _allUsers = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String teamName = 'Equipa';
        final rawEquipaId = data['equipaId'] as String?;
        final equipaId =
            (rawEquipaId != null && rawEquipaId.trim().isNotEmpty)
                ? rawEquipaId.trim()
                : doc.id;

        if (equipaId.isNotEmpty) {
          final teamDoc =
              await _firestore.collection('equipas').doc(equipaId).get();
          if (teamDoc.exists) {
            final teamData = teamDoc.data();
            if (teamData != null && teamData.containsKey('nome')) {
              teamName = teamData['nome'];
            } else {
              teamName = '[Nome da equipa não encontrado]';
            }
          } else {
            teamName = '[Equipa não encontrada]';
            debugPrint('⚠️ Equipa não encontrada: $equipaId');
          }
        }

        final rawName = data['nome']?.toString().trim();
        final name =
            (rawName != null && rawName.isNotEmpty) ? rawName : teamName;

        _allUsers.add({
          'uid': doc.id,
          'name': name,
          'total': data['pontuacao'] ?? 0,
          'teamName': teamName,
        });
      }

      // The 'position' key has been removed, so skip sorting by position.
      _filteredUsers = List.from(_allUsers);
      _animationController.forward();
    } catch (e) {
      _showErrorSnackBar('Erro ao carregar dados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        _filteredUsers =
            _allUsers.where((user) {
              final name = user['name'].toString().toLowerCase();
              final teamName = user['teamName'].toString().toLowerCase();
              final searchLower = query.toLowerCase();
              return name.contains(searchLower) ||
                  teamName.contains(searchLower);
            }).toList();
      }
    });
  }

  Future<void> _updateScore(String uid, int newScore, String userName) async {
    setState(() => _isUpdating[uid] = true);

    try {
      // Atualizar na coleção ranking
      await _firestore.collection('ranking').doc(uid).update({
        'pontuacao': newScore,
      });

      // Também atualizar na coleção users se existir
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        await _firestore.collection('users').doc(uid).update({
          'totalScore': newScore,
        });
      }

      // Atualizar localmente
      final userIndex = _allUsers.indexWhere((user) => user['uid'] == uid);
      if (userIndex != -1) {
        _allUsers[userIndex]['total'] = newScore;
        _filterUsers(_searchQuery); // Reaplica o filtro
      }

      _showSuccessSnackBar(
        'Pontuação de $userName atualizada para $newScore pontos',
      );
    } catch (e) {
      _showErrorSnackBar('Erro ao atualizar pontuação: $e');
    } finally {
      setState(() => _isUpdating[uid] = false);
    }
  }

  Future<void> _showUpdateConfirmation(
    String uid,
    int newScore,
    String userName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit, color: Colors.blue),
              SizedBox(width: 8),
              Text('Confirmar Atualização'),
            ],
          ),
          content: Text(
            'Deseja atualizar a pontuação de $userName para $newScore pontos?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _updateScore(uid, newScore, userName);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    final uid = user['uid'] as String;
    final name = user['name'] as String;
    final teamName = user['teamName'] as String;
    final total = user['total'] as int;
    // Removed: final position = user['position'] as int;

    _controllers[uid] ??= TextEditingController(text: total.toString());

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Removed position badge and icon
                            // Instead, just show a generic avatar/icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.group,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    teamName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Removed position badge container
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.stars,
                                      color: Colors.amber.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Pontuação atual: $total',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controllers[uid],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Nova pontuação',
                                  hintText: 'Digite a nova pontuação',
                                  prefixIcon: const Icon(Icons.edit),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    _isUpdating[uid] == true
                                        ? null
                                        : () {
                                          final newScore = int.tryParse(
                                            _controllers[uid]!.text,
                                          );
                                          if (newScore != null &&
                                              newScore != total) {
                                            _showUpdateConfirmation(
                                              uid,
                                              newScore,
                                              name,
                                            );
                                          } else if (newScore == null) {
                                            _showErrorSnackBar(
                                              'Digite um número válido',
                                            );
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                child:
                                    _isUpdating[uid] == true
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : const Icon(Icons.check),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Atualizar Pontuações',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScores,
            tooltip: 'Recarregar dados',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header com estatísticas
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  // Barra de pesquisa
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: _filterUsers,
                      decoration: InputDecoration(
                        hintText: 'Pesquisar por nome ou equipa...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Estatísticas
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(255, 255, 255, 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.group, color: Colors.white),
                              const SizedBox(height: 4),
                              Text(
                                '${_filteredUsers.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Participantes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(255, 255, 255, 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.stars, color: Colors.white),
                              const SizedBox(height: 4),
                              Text(
                                _allUsers.isNotEmpty
                                    ? '${_allUsers.map((u) => u['total'] as int).reduce((a, b) => a > b ? a : b)}'
                                    : '0',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Maior pontuação',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Lista de utilizadores
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Carregando dados...',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : _filteredUsers.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Nenhum participante encontrado'
                                : 'Nenhum resultado para "$_searchQuery"',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => _filterUsers(''),
                              child: const Text('Limpar pesquisa'),
                            ),
                          ],
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        return _buildUserCard(_filteredUsers[index], index);
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
