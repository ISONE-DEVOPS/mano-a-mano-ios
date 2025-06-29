import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observables para reactive state
  final Rx<User?> _user = Rx<User?>(null);
  final RxString _userRole = 'user'.obs;
  final RxMap<String, dynamic> _userData = <String, dynamic>{}.obs;
  final RxBool _isLoading = false.obs;

  // Getters
  User? get currentUser => _user.value;
  String get userRole => _userRole.value;
  Map<String, dynamic> get userData => _userData;
  bool get isLoading => _isLoading.value;
  bool get isLoggedIn => _user.value != null;

  // Stream do estado de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  void onInit() {
    super.onInit();

    // Escutar mudanças de autenticação
    _auth.authStateChanges().listen((User? user) {
      _user.value = user;
      if (user != null) {
        _loadUserData();
      } else {
        _clearUserData();
      }
    });
  }

  // Login com email e senha
  Future<bool> loginWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading.value = true;

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _updateLastLogin(result.user!.uid);
        await _loadUserData();
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar(
        'Erro de Login',
        _getErrorMessage(e.toString()),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _clearUserData();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao fazer logout: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Carregar dados do usuário
  Future<void> _loadUserData() async {
    try {
      if (_user.value == null) return;

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_user.value!.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        _userData.value = data;
        _userRole.value = data['role'] ?? 'user';

        // Verificar se usuário está ativo apenas se for participante
        if (_userRole.value == 'user' && data['ativo'] != true) {
          await logout();
          Get.snackbar(
            'Conta Inativa',
            'Sua conta foi desativada. Entre em contato com a organização.',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados do usuário: $e');
    }
  }

  // Limpar dados do usuário
  void _clearUserData() {
    _userData.clear();
    _userRole.value = 'user';
    _user.value = null;
  }

  // Atualizar último login
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'ultimoLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erro ao atualizar último login: $e');
    }
  }

  // Verificar se usuário pode usar scanner
  Future<bool> canUseScanner() async {
    try {
      if (_user.value == null) return false;

      // Verificar se é participante ativo
      if (_userRole.value == 'user') {
        return _userData['ativo'] == true &&
            _userData['equipaId'] != null &&
            _userData['equipaId'].toString().isNotEmpty;
      }

      // Staff e admin sempre podem usar scanner
      return _userRole.value == 'staff' || _userRole.value == 'admin';
    } catch (e) {
      debugPrint('Erro ao verificar permissão do scanner: $e');
      return false;
    }
  }

  // Obter dados da equipa do usuário
  Future<Map<String, dynamic>?> getUserTeamData() async {
    try {
      if (_userData['equipaId'] == null) return null;

      DocumentSnapshot teamDoc =
          await _firestore
              .collection('equipas')
              .doc(_userData['equipaId'])
              .get();

      if (teamDoc.exists) {
        return teamDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao carregar dados da equipa: $e');
      return null;
    }
  }

  // Verificar se usuário já fez check-in em um checkpoint
  Future<bool> hasCheckedIn(String checkpointId) async {
    try {
      if (_user.value == null) return false;

      DocumentSnapshot pontuacaoDoc =
          await _firestore
              .collection('users')
              .doc(_user.value!.uid)
              .collection('pontuacoes')
              .doc(checkpointId)
              .get();

      if (pontuacaoDoc.exists) {
        Map<String, dynamic> data = pontuacaoDoc.data() as Map<String, dynamic>;
        return data['timestampEntrada'] != null;
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao verificar check-in: $e');
      return false;
    }
  }

  // Verificar se usuário pode fazer check-out
  Future<bool> canCheckOut(String checkpointId) async {
    try {
      if (_user.value == null) return false;

      DocumentSnapshot pontuacaoDoc =
          await _firestore
              .collection('users')
              .doc(_user.value!.uid)
              .collection('pontuacoes')
              .doc(checkpointId)
              .get();

      if (pontuacaoDoc.exists) {
        Map<String, dynamic> data = pontuacaoDoc.data() as Map<String, dynamic>;

        // Deve ter feito entrada e respondido pergunta
        bool hasEntry = data['timestampEntrada'] != null;
        bool hasAnswered = data['respostaCorreta'] != null;
        bool hasExit = data['timestampSaida'] != null;

        return hasEntry && hasAnswered && !hasExit;
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao verificar check-out: $e');
      return false;
    }
  }

  // Obter papel do usuário (melhorado)
  Future<String> getUserRole() async {
    try {
      if (_userRole.value != 'user') {
        return _userRole.value;
      }

      // Se ainda não carregou, carregar dos dados
      if (_userData.isEmpty && _user.value != null) {
        await _loadUserData();
      }

      return _userRole.value;
    } catch (e) {
      debugPrint('Erro ao obter role do usuário: $e');
      return 'user';
    }
  }

  // Verificar se é admin
  bool get isAdmin => _userRole.value == 'admin';

  // Verificar se é staff
  bool get isStaff => _userRole.value == 'staff';

  // Verificar se é participante
  bool get isParticipant => _userRole.value == 'user';

  // Navegar baseado no role
  void navigateBasedOnRole() {
    switch (_userRole.value) {
      case 'admin':
        Get.offAllNamed('/admin');
        break;
      case 'staff':
        Get.offAllNamed('/staff');
        break;
      case 'user':
      default:
        Get.offAllNamed('/');
        break;
    }
  }

  // Obter mensagem de erro amigável
  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'Utilizador não encontrado';
    } else if (error.contains('wrong-password')) {
      return 'Senha incorreta';
    } else if (error.contains('invalid-email')) {
      return 'Email inválido';
    } else if (error.contains('too-many-requests')) {
      return 'Muitas tentativas. Tente novamente mais tarde';
    } else if (error.contains('network-request-failed')) {
      return 'Erro de conexão. Verifique sua internet';
    } else {
      return 'Erro inesperado. Tente novamente';
    }
  }

  // Recarregar dados do usuário
  Future<void> refreshUserData() async {
    await _loadUserData();
  }

  // Verificar se dados estão carregados
  bool get isUserDataLoaded => _userData.isNotEmpty;

  // Enviar email de recuperação de senha
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      debugPrint('Erro ao enviar recuperação de senha: $e');
      return false;
    }
  }

  // Registro com email, nome e senha
  Future<bool> registerWithEmail(
    String nome,
    String email,
    String password,
  ) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(cred.user!.uid).set({
        'nome': nome,
        'email': email,
        'role': 'user',
        'ativo': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _user.value = cred.user;
      await _loadUserData();

      return true;
    } catch (e) {
      Get.snackbar(
        'Erro ao criar conta',
        _getErrorMessage(e.toString()),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
}
