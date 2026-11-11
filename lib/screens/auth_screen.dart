import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _entranceController;
  late final AnimationController _particleController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showContent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showContent = true);
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await AuthService.instance.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await AuthService.instance.signUp(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = switch (error.code) {
          'invalid-email' => 'Please enter a valid email address.',
          'user-not-found' => 'No account found. Please register first.',
          'wrong-password' => 'Incorrect password. Try again.',
          'invalid-credential' => 'Invalid email or password.',
          'email-already-in-use' =>
            'An account already exists with this email.',
          'weak-password' =>
            'Choose a stronger password with at least 6 characters.',
          'network-request-failed' =>
            'Network error. Check your internet connection.',
          'too-many-requests' => 'Too many attempts. Please try again later.',
          _ => error.message ?? 'Authentication failed. Please try again.',
        };
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _switchMode() {
    if (_isLoading) return;

    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
      _obscurePassword = true;
      _formKey.currentState?.reset();
      _passwordController.clear();
    });
  }

  Widget _gradientButton({
    required String text,
    required VoidCallback? onPressed,
    required bool loading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: onPressed == null
                ? [Colors.blueGrey.shade400, Colors.blueGrey.shade300]
                : const [
                    Color(0xFF70D8E9),
                    Color(0xFF3999D8),
                    Color(0xFF5276C9),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55399CD1),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 23,
                  width: 23,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool password,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: password && _obscurePassword,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      keyboardType: password
          ? TextInputType.visiblePassword
          : TextInputType.emailAddress,
      autofillHints: password
          ? (_isLogin
                ? const [AutofillHints.password]
                : const [AutofillHints.newPassword])
          : const [AutofillHints.email],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFD4F5FF)),
        prefixIcon: Icon(icon, color: const Color(0xFFB9EDFF)),
        suffixIcon: password
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFFB9EDFF),
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0x332A91B8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0x887DDFF5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF9CEAFF), width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return password
              ? 'Please enter your password.'
              : 'Please enter your email.';
        }

        if (!password &&
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
          return 'Enter a valid email address.';
        }

        if (password && !_isLogin && value.length < 6) {
          return 'Password must be at least 6 characters.';
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'lib/assets/images/bioluminescent_plankton.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(color: Color(0xFF031B32));
            },
          ),

          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BubblePainter(progress: _particleController.value),
                );
              },
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: constraints.maxHeight * 0.48),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeIn,
                            child: _showContent
                                ? FadeTransition(
                                    key: const ValueKey('auth-content'),
                                    opacity: _fadeAnimation,
                                    child: SlideTransition(
                                      position: _slideAnimation,
                                      child: _buildAuthCard(),
                                    ),
                                  )
                                : const SizedBox(
                                    key: ValueKey('auth-loading'),
                                    height: 100,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF9CEAFF),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x667DEBFF), width: 1.2),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isLogin ? 'Welcome Back' : 'Join the Journey',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _isLogin
                  ? 'Sign in to continue to your tasks.'
                  : 'Create an account and manage your tasks anywhere.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFFD0F2FF),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _emailController,
              label: 'Email address',
              icon: Icons.email_outlined,
              password: false,
            ),
            const SizedBox(height: 13),
            _buildField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              password: true,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFFB8B8), fontSize: 12),
              ),
            ],
            const SizedBox(height: 18),
            _gradientButton(
              text: _isLogin ? 'Sign In' : 'Create Account',
              onPressed: _isLoading ? null : _submit,
              loading: _isLoading,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isLoading ? null : _switchMode,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFBCEEFF),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                _isLogin
                    ? "Don't have an account? Register"
                    : 'Already have an account? Sign in',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final double progress;

  _BubblePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(27);

    for (int i = 0; i < 32; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;

      final speed = 0.12 + random.nextDouble() * 0.35;

      final y = (baseY - progress * size.height * speed) % size.height;

      final radius = 2.0 + random.nextDouble() * 5.0;

      final phase = progress * math.pi * 2 + i;

      final opacity = (0.35 + (math.sin(phase) + 1) * 0.2).clamp(0.0, 0.8);

      final center = Offset(x, y);

      final glowPaint = Paint()
        ..color = Color.fromRGBO(150, 230, 255, opacity * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

      canvas.drawCircle(center, radius * 2, glowPaint);

      final bubblePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = i % 2 == 0
            ? Color.fromRGBO(180, 235, 255, opacity)
            : Color.fromRGBO(255, 255, 255, opacity);

      canvas.drawCircle(center, radius, bubblePaint);

      final highlightPaint = Paint()
        ..color = Color.fromRGBO(255, 255, 255, opacity * 0.9)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x - radius * 0.3, y - radius * 0.3),
        radius * 0.2,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
