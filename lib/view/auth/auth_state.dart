import 'package:flutter/material.dart';

import '../../repositories/user_repository.dart';
import '../../services/deep_link_service.dart';

enum SignInState { login, signup }

class AuthState extends ChangeNotifier {
  final userRepo = Userrepository.instance;
  final deepLinkRepo = DeepLinkService.instance;
  late TextEditingController referController;

  SignInState _signInState = SignInState.login;
  bool isLoading = false;
  SignInState get signInState => _signInState;

  set changeState(SignInState v) {
    _signInState = v;
    notifyListeners();
  }

  set changeIsLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }

  AuthState() {
    referController =
        TextEditingController(text: deepLinkRepo?.referrerCode.value);
  }
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> signUplogin() async {
    if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      changeIsLoading = true;
      if (_signInState == SignInState.login) {
        await userRepo.login(
            emailController.text.toString().trim(), passwordController.text);
      } else if (_signInState == SignInState.signup) {
        await userRepo.registeruser(nameController.text,
            emailController.text.toString().trim(), passwordController.text,
            referrerCode: deepLinkRepo?.referrerCode.value ?? '');
      }
      changeIsLoading = false;
    }
  }
}
