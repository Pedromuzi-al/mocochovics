import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/auth_validators.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_form_widgets.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final success = await ref
        .read(authControllerProvider)
        .updatePassword(password: _password.text);
    if (!mounted || !success) return;
    TextInput.finishAutofillContext();
    unawaited(HapticFeedback.lightImpact());
    context.go('/inicio');
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(authControllerProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => AuthPageLayout(
        title: 'Definir nova senha',
        description: controller.isAuthenticated
            ? 'Escolha uma senha segura para voltar a cuidar do seu bar.'
            : 'Abra o link enviado por e-mail neste dispositivo. Se ele expirou, solicite um novo link.',
        showBack: false,
        child: !controller.isAuthenticated
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthMessage(controller.errorMessage, isError: true),
                  CupertinoButton.filled(
                    onPressed: () {
                      controller.clearError();
                      context.go('/forgot-password');
                    },
                    child: const Text(
                      'Solicitar novo link',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            : AutofillGroup(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthField(
                        label: 'Nova senha',
                        controller: _password,
                        placeholder: 'Pelo menos 8 caracteres',
                        validator: AuthValidators.newPassword,
                        autofillHints: const [AutofillHints.newPassword],
                        isPassword: true,
                        enabled: !controller.isBusy,
                        onChanged: (_) => controller.clearError(),
                      ),
                      AuthField(
                        label: 'Confirmar nova senha',
                        controller: _confirmation,
                        placeholder: 'Repita sua nova senha',
                        validator: (value) => AuthValidators.confirmPassword(
                          value,
                          _password.text,
                        ),
                        autofillHints: const [AutofillHints.newPassword],
                        isPassword: true,
                        enabled: !controller.isBusy,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),
                      AuthMessage(controller.errorMessage, isError: true),
                      AuthSubmitButton(
                        label: 'Salvar nova senha',
                        isBusy: controller.isBusy,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),
                      CupertinoButton(
                        onPressed: controller.isBusy
                            ? null
                            : () => controller.signOut(),
                        child: const Text(
                          'Sair da conta',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
