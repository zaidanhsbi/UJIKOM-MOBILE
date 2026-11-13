import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  /// Membuat state untuk halaman login.
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _npsnController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  /// Membersihkan seluruh controller input teks saat halaman ditutup.
  @override
  void dispose() {
    _npsnController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Memvalidasi form dan mengirimkan kredensial login siswa.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
          identifier: _identifierController.text,
          password: _passwordController.text,
          npsn: _npsnController.text,
        );
  }

  /// Membangun tampilan halaman login secara responsif untuk desktop dan seluler.
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTokens.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 960;
          if (isDesktop) {
            return Row(
              children: [
                Expanded(child: _LeftBrandPanel()),
                Expanded(
                  child: _RightLoginForm(
                    formKey: _formKey,
                    npsnController: _npsnController,
                    identifierController: _identifierController,
                    passwordController: _passwordController,
                    obscurePassword: _obscurePassword,
                    loading: authState.loading,
                    error: authState.error,
                    onTogglePassword: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onSubmit: _submit,
                  ),
                ),
              ],
            );
          }

          return SafeArea(
            child: _RightLoginForm(
              formKey: _formKey,
              npsnController: _npsnController,
              identifierController: _identifierController,
              passwordController: _passwordController,
              obscurePassword: _obscurePassword,
              loading: authState.loading,
              error: authState.error,
              onTogglePassword: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onSubmit: _submit,
            ),
          );
        },
      ),
    );
  }
}

class _LeftBrandPanel extends StatelessWidget {
  /// Membangun panel branding sisi kiri pada tampilan desktop.
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTokens.surface,
            Color(0xFFF1F6FE),
            AppTokens.softBlue,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0, 0.05),
              child: SvgPicture.asset(
                'assets/images/Indonesia_Map.svg',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Opacity(
                      opacity: 0.5,
                      child: SvgPicture.asset(
                        'assets/images/Logo.svg',
                        width: 40,
                        height: 41,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Text(
                      'BinoExam',
                      style: TextStyle(
                        fontSize: AppTokens.textXxxl,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.navy,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hadapi Ujian\ndengan Senyuman\ndan Kenyamanan',
                        style: TextStyle(
                          fontSize: AppTokens.textXxxl,
                          fontWeight: FontWeight.w700,
                          color: AppTokens.navy,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'BinoExam merupakan Aplikasi CBT dengan pendekatan semi-offline yang ramah guru, hemat server, dan tetap berjalan lancar meski listrik atau internet bermasalah.',
                        style: TextStyle(
                          fontSize: AppTokens.textMd,
                          color: AppTokens.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 41),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RightLoginForm extends StatelessWidget {
  const _RightLoginForm({
    required this.formKey,
    required this.npsnController,
    required this.identifierController,
    required this.passwordController,
    required this.obscurePassword,
    required this.loading,
    required this.error,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController npsnController;
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool loading;
  final String? error;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  /// Membangun panel form login siswa.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceXl,
          vertical: AppTokens.spaceXxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Selamat Datang!',
                  style: TextStyle(
                    fontSize: AppTokens.textXxxl,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.text,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                if (error != null && !loading) ...[
                  Container(
                    padding: const EdgeInsets.all(AppTokens.spaceMd),
                    decoration: BoxDecoration(
                      color: AppTokens.coral,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      border: Border.all(color: AppTokens.coral),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gagal Masuk',
                          style: TextStyle(
                            fontSize: AppTokens.textMd,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.navy,
                          ),
                        ),
                        const SizedBox(height: AppTokens.spaceXxs),
                        Text(
                          error!,
                          style: const TextStyle(
                            fontSize: AppTokens.textMd,
                            fontWeight: FontWeight.w500,
                            color: AppTokens.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _WebStyleInput(
                  controller: npsnController,
                  hint: 'NPSN Sekolah',
                  icon: LucideIcons.school,
                  keyboardType: TextInputType.number,
                  enabled: !loading,
                ),
                const SizedBox(height: 20),
                _WebStyleInput(
                  controller: identifierController,
                  hint: 'NISN',
                  icon: LucideIcons.mail,
                  enabled: !loading,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'NISN wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _WebStyleInput(
                  controller: passwordController,
                  hint: 'Kata Sandi',
                  icon: LucideIcons.lock,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.done,
                  enabled: !loading,
                  suffix: TextButton(
                    onPressed: onTogglePassword,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTokens.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(
                      obscurePassword ? 'Lihat' : 'Tutup',
                      style: const TextStyle(
                        fontSize: AppTokens.textSm,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Kata sandi wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Material(
                  color: loading ? AppTokens.textDisabled : AppTokens.navy,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: loading ? null : onSubmit,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spaceXl,
                      ),
                      child: Text(
                        loading ? 'Memeriksa lisensi...' : 'Sign In',
                        style: const TextStyle(
                          fontSize: AppTokens.textMd,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.white,
                        ),
                      ),
                    ),
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

class _WebStyleInput extends StatelessWidget {
  const _WebStyleInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.suffix,
    this.validator,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final bool enabled;

  /// Membangun input teks bergaya web dengan ikon dan validasi.
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      enabled: enabled,
      style: const TextStyle(
        fontSize: AppTokens.textMd,
        color: AppTokens.text,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: AppTokens.textMd,
          color: AppTokens.textDisabled,
        ),
        filled: true,
        fillColor: enabled ? AppTokens.white : AppTokens.background,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Opacity(
            opacity: 0.5,
            child: Icon(icon, size: 20, color: AppTokens.textSecondary),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 52, minHeight: 52),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.error),
        ),
      ),
    );
  }
}
