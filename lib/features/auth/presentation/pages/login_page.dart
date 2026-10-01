import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/auth_validators.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_form_widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final success = await ref
        .read(authControllerProvider)
        .signIn(email: _email.text, password: _password.text);
    if (!mounted || !success) return;
    TextInput.finishAutofillContext();
    context.go('/inicio');
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(authControllerProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => AuthPageLayout(
        title: 'Seu bar, em dia.',
        description: 'Entre para cuidar das finanças do Bar do Mocochovisk.',
        showBack: false,
        child: AutofillGroup(
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
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email,
                  ],
                  enabled: !controller.isBusy,
                  onChanged: (_) => controller.clearError(),
                ),
                AuthField(
                  label: 'Senha',
                  controller: _password,
                  placeholder: 'Sua senha',
                  validator: AuthValidators.password,
                  autofillHints: const [AutofillHints.password],
                  isPassword: true,
                  enabled: !controller.isBusy,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) => controller.clearError(),
                ),
                AuthMessage(controller.errorMessage, isError: true),
                AuthSubmitButton(
                  label: 'Entrar',
                  isBusy: controller.isBusy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                CupertinoButton(
                  onPressed: controller.isBusy
                      ? null
                      : () {
                          controller.clearError();
                          context.push('/forgot-password');
                        },
                  child: const Text(
                    'Esqueci minha senha',
                    textAlign: TextAlign.center,
                  ),
                ),
                CupertinoButton(
                  onPressed: controller.isBusy
                      ? null
                      : () {
                          controller.clearError();
                          context.push('/register');
                        },
                  child: const Text(
                    'Criar uma conta',
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
