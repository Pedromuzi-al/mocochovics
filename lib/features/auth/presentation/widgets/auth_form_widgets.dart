import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({
    required this.title,
    required this.description,
    required this.child,
    this.showBack = true,
    super.key,
  });

  final String title;
  final String description;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        middle: const Text('Bar do Mocochovisk'),
        leading: showBack
            ? CupertinoNavigationBarBackButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/login');
                  }
                },
                previousPageTitle: 'Entrar',
              )
            : null,
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 48).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBlue.resolveFrom(
                              context,
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            CupertinoIcons.chart_bar_alt_fill,
                            color: CupertinoColors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        style: theme.textTheme.navLargeTitleTextStyle,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: theme.textTheme.textStyle.copyWith(
                          color: AppTheme.secondaryTextColor.resolveFrom(
                            context,
                          ),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthField extends StatelessWidget {
  const AuthField({
    required this.label,
    required this.controller,
    required this.validator,
    required this.autofillHints,
    this.placeholder,
    this.isPassword = false,
    this.enabled = true,
    this.onSubmitted,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final Iterable<String> autofillHints;
  final String? placeholder;
  final bool isPassword;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: CupertinoTheme.of(context).textTheme.textStyle
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
              context,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Semantics(
            label: label,
            child: CupertinoTextFormFieldRow(
              controller: controller,
              placeholder: placeholder,
              placeholderStyle: TextStyle(
                color: AppTheme.secondaryTextColor.resolveFrom(context),
              ),
              obscureText: isPassword,
              enabled: enabled,
              autocorrect: false,
              enableSuggestions: !isPassword,
              keyboardType: isPassword
                  ? TextInputType.visiblePassword
                  : TextInputType.emailAddress,
              autofillHints: autofillHints,
              textInputAction: textInputAction,
              onFieldSubmitted: onSubmitted,
              onChanged: onChanged,
              validator: validator,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

class AuthMessage extends StatelessWidget {
  const AuthMessage(this.message, {this.isError = false, super.key});

  final String? message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          message!,
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
            color: (isError ? AppTheme.destructiveColor : CupertinoColors.label)
                .resolveFrom(context),
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    required this.label,
    required this.isBusy,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton.filled(
    onPressed: isBusy ? null : onPressed,
    child: isBusy
        ? Semantics(label: 'Aguarde', child: const CupertinoActivityIndicator())
        : Text(label, textAlign: TextAlign.center),
  );
}
