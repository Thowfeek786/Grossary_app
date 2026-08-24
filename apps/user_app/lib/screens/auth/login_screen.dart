import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _agreedToTerms = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the Terms & Conditions to proceed.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0B3820),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Dark Forest Green Hero Header with 3D Basket & Floating Leaves
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF092E1A),
                            Color(0xFF0C3E24),
                            Color(0xFF0F4D2E),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Floating decorative leaf accents
                          Positioned(
                            top: topPadding + 14,
                            left: 90,
                            child: Transform.rotate(
                              angle: -0.3,
                              child: Icon(Icons.eco_rounded, color: Colors.greenAccent.withValues(alpha: 0.18), size: 28),
                            ),
                          ),
                          Positioned(
                            top: topPadding + 65,
                            left: 170,
                            child: Transform.rotate(
                              angle: 0.5,
                              child: Icon(Icons.eco_rounded, color: Colors.greenAccent.withValues(alpha: 0.14), size: 20),
                            ),
                          ),

                          // Top Right 3D Grocery Basket Image (Transparent PNG)
                          Positioned(
                            top: topPadding - 10,
                            right: -6,
                            child: SizedBox(
                              width: 175,
                              height: 165,
                              child: Image.asset(
                                'assets/images/auth_grocery_basket.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          // Header Text Content
                          Padding(
                            padding: EdgeInsets.fromLTRB(20, topPadding + 28, 20, 36),
                            child: SizedBox(
                              width: screenWidth > 380 ? screenWidth - 165 : screenWidth - 145,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome back!',
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sign in to order fresh groceries\ndelivered in minutes',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: Colors.white.withValues(alpha: 0.82),
                                      height: 1.35,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // White Floating Form Card (Expands to Bottom)
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(20, 28, 20, 36 + bottomPadding),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email Address Label & Field
                              _buildInputLabel('Email Address'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _emailCtrl,
                                hint: 'you@example.com',
                                icon: Icons.mail_outline_rounded,
                                type: TextInputType.emailAddress,
                                validator: Validators.email,
                                action: TextInputAction.next,
                              ),
                              const SizedBox(height: 20),

                              // Password Label & Field
                              _buildInputLabel('Password'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _passCtrl,
                                hint: 'Enter your password',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscurePassword,
                                validator: Validators.password,
                                action: TextInputAction.done,
                                onSubmitted: (_) => _login(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: const Color(0xFF0A633D),
                                    size: 22,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),

                              // Forgot Password Link
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 6),
                                  child: GestureDetector(
                                    onTap: () => context.push('/forgot-password'),
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Color(0xFF087247),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Terms & Conditions Checkbox
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: Checkbox(
                                      value: _agreedToTerms,
                                      onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                                      activeColor: const Color(0xFF0A633D),
                                      checkColor: Colors.white,
                                      side: const BorderSide(color: Color(0xFF0A633D), width: 1.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        const Text(
                                          'I agree to the ',
                                          style: TextStyle(fontSize: 12.5, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
                                        ),
                                        GestureDetector(
                                          onTap: () => context.push('/terms'),
                                          child: const Text(
                                            'Terms & Conditions',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF087247),
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                        const Text(
                                          ' & ',
                                          style: TextStyle(fontSize: 12.5, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
                                        ),
                                        GestureDetector(
                                          onTap: () => context.push('/terms'),
                                          child: const Text(
                                            'Privacy Policy',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF087247),
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Sign In CTA Button with Forward Arrow
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: auth.isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0A633D),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                        )
                                      : Row(
                                          children: const [
                                            Spacer(),
                                            Text(
                                              'Sign In',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                                            ),
                                            Spacer(),
                                            Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // OR Divider
                              Row(
                                children: [
                                  Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Google Sign-In Button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: auth.isLoading
                                      ? null
                                      : () async {
                                          if (!_agreedToTerms) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: const Text('Please accept the Terms & Conditions to proceed.'),
                                                backgroundColor: AppColors.error,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            );
                                            return;
                                          }
                                          final messenger = ScaffoldMessenger.of(context);
                                          final ok = await auth.signInWithGoogle();
                                          if (!ok && mounted && auth.error != null) {
                                            messenger.showSnackBar(
                                              SnackBar(content: Text(auth.error!), backgroundColor: AppColors.error),
                                            );
                                          }
                                        },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    backgroundColor: Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/logos/google.png',
                                        width: 22,
                                        height: 22,
                                        errorBuilder: (_, _, _) => Image.asset(
                                          'assets/icons/google.png',
                                          width: 22,
                                          height: 22,
                                          errorBuilder: (_, _, _) => const Text(
                                            'G',
                                            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4285F4), fontSize: 16),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Continue with Google',
                                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Don't have an account? Sign Up
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account? ",
                                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.push('/register'),
                                    child: const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: Color(0xFF0A633D),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1F2937)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputAction action = TextInputAction.next,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      textInputAction: action,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: Color(0xFF1F2937)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 8, right: 10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF7EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0A633D), size: 20),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 56, minHeight: 48),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0A633D), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
        ),
      ),
    );
  }
}
