import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/auth_service.dart';
import 'splash_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    String? err;
    if (_isLogin) {
      err = await AuthService.login(email: _emailCtrl.text, password: _passCtrl.text);
    } else {
      err = await AuthService.register(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
    }

    if (!mounted) return;
    if (err != null) {
      setState(() { _loading = false; _error = err; });
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const SplashScreen()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0C0C14), const Color(0xFF1A1A2E)]
                : [const Color(0xFFECFDF5), const Color(0xFFF0F9FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.shield, color: const Color(0xFF00E5FF).withOpacity(0.15), size: 80),
                        const Icon(Icons.shield_outlined, color: const Color(0xFF00E5FF), size: 80),
                        const Icon(Icons.ac_unit, color: const Color(0xFF00E5FF), size: 36),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Title
                    Text('ColdGuard', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: context.onSurface, letterSpacing: -1)),
                    const SizedBox(height: 4),
                    Text('AI-Powered Cold Chain Protection', style: TextStyle(fontSize: 14, color: context.onSurfaceVariant)),
                    const SizedBox(height: 32),

                    // Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        border: Border.all(color: context.outline.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 30, spreadRadius: -5, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Tab toggle
                            Container(
                              decoration: BoxDecoration(
                                color: context.surfaceColor.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              child: Row(
                                children: [
                                  _buildTab('Sign In', _isLogin),
                                  _buildTab('Create Account', !_isLogin),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Name field (register only)
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Padding(padding: EdgeInsets.only(left: 12, right: 8), child: Icon(Icons.person_outline, size: 20))),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Email
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Padding(padding: EdgeInsets.only(left: 12, right: 8), child: Icon(Icons.email_outlined, size: 20))),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter your email';
                                if (!v.contains('@')) return 'Enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Padding(padding: EdgeInsets.only(left: 12, right: 8), child: Icon(Icons.lock_outline, size: 20)),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Enter your password';
                                if (v.length < 6) return 'Min 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),

                            // Error
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13), textAlign: TextAlign.center),
                              ),

                            const SizedBox(height: 16),

                            // Submit
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                              ),
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                                ),
                                child: _loading
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                    : Text(_isLogin ? 'Sign In' : 'Create Account', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _isLogin = label == 'Sign In'; _error = null; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppTheme.primary : context.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
