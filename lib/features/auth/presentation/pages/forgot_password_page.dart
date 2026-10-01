import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/auth_validators.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_form_widgets.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final success = await ref
        .read(authControllerProvider)
        .sendPasswordReset(email: _email.text);
    if (mounted && success) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(authControllerProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => AuthPageLayout(
        title: _sent ? 'Confira seu e-mail' : 'Recuperar senha',
        description: _sent
            ? 'Se houver uma conta com esse e-mail, enviaremos um link para criar uma nova senha. Confira também a caixa de spam e abra o link neste dispositivo.'
            : 'Informe o e-mail da sua conta para receber o link de recuperação.',
        child: _sent
            ? CupertinoButton.filled(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'Voltar para entrar',
                  textAlign: TextAlign.center,
                ),
              )
            : Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthField(
                      label: 'E-mail',
                      controller: _email,
                      placeholder: 'seu@email.com',
                      validator: AuthValidators.email,
                      autofillHints: const [AutofillHints.email],
                      enabled: !controller.isBusy,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      onChanged: (_) => controller.clearError(),
                    ),
                    AuthMessage(controller.errorMessage, isError: true),
                    AuthSubmitButton(
                      label: 'Enviar link',
                      isBusy: controller.isBusy,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
