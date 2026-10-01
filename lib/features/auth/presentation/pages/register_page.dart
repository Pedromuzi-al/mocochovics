import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/auth_validators.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_form_widgets.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _confirmationSent = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final controller = ref.read(authControllerProvider);
    final success = await controller.signUp(
      email: _email.text,
      password: _password.text,
    );
    if (!mounted || !success) return;
    TextInput.finishAutofillContext();
    if (controller.isAuthenticated) {
      context.go('/inicio');
    } else {
      setState(() => _confirmationSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(authControllerProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => AuthPageLayout(
        title: _confirmationSent ? 'Confira seu e-mail' : 'Criar sua conta',
        description: _confirmationSent
            ? 'Se o cadastro puder ser concluído, você receberá um link para confirmar seu e-mail. Confira também a caixa de spam.'
            : 'Organize as contas do bar em um só lugar.',
        child: _confirmationSent
            ? CupertinoButton.filled(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'Voltar para entrar',
                  textAlign: TextAlign.center,
                ),
              )
            : AutofillGroup(
                child: Form(
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
                        onChanged: (_) => controller.clearError(),
                      ),
                      AuthField(
                        label: 'Senha',
                        controller: _password,
                        placeholder: 'Pelo menos 8 caracteres',
                        validator: AuthValidators.newPassword,
                        autofillHints: const [AutofillHints.newPassword],
                        isPassword: true,
                        enabled: !controller.isBusy,
                        onChanged: (_) => controller.clearError(),
                      ),
                      AuthField(
                        label: 'Confirmar senha',
                        controller: _confirmation,
                        placeholder: 'Repita sua senha',
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
                        label: 'Criar conta',
                        isBusy: controller.isBusy,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
