import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:repository/repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthRepository().sendPasswordResetEmail(_emailCtrl.text.trim());
      setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            top: topPadding + 8,
                            left: 90,
                            child: Transform.rotate(
                              angle: -0.3,
                              child: Icon(Icons.eco_rounded, color: Colors.greenAccent.withValues(alpha: 0.18), size: 26),
                            ),
                          ),
                          Positioned(
                            top: topPadding + 80,
                            left: 175,
                            child: Transform.rotate(
                              angle: 0.4,
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

                          // Header Content (Back Button + Titles)
                          Padding(
                            padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 32),
                            child: SizedBox(
                              width: screenWidth > 380 ? screenWidth - 165 : screenWidth - 145,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Circular Back Button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => context.pop(),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF072716).withValues(alpha: 0.8),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.2),
                                        ),
                                        child: const Icon(
                                          Icons.arrow_back_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Title with Key Emoji
                                  const Text(
                                    'Reset Password 🔑',
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Enter your email to receive a password\nreset link',
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
                        padding: EdgeInsets.fromLTRB(20, 32, 20, 40 + bottomPadding),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: _sent
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 30),
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDF7EE),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF86EFAC), width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.mark_email_read_rounded,
                                      size: 44,
                                      color: Color(0xFF0A633D),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Reset Email Sent!',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Check your inbox at ${_emailCtrl.text} to set your new password.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.4),
                                  ),
                                  const SizedBox(height: 36),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: () => context.pop(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0A633D),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: const Text('Back to Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                ],
                              )
                            : Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Email Address',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1F2937)),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _emailCtrl,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _send(),
                                      validator: Validators.email,
                                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: Color(0xFF1F2937)),
                                      decoration: InputDecoration(
                                        hintText: 'you@example.com',
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
                                            child: const Icon(Icons.mail_outline_rounded, color: Color(0xFF0A633D), size: 20),
                                          ),
                                        ),
                                        prefixIconConstraints: const BoxConstraints(minWidth: 56, minHeight: 48),
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
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _send,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0A633D),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 20),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                              )
                                            : Row(
                                                children: const [
                                                  Spacer(),
                                                  Text('Send Reset Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                                  Spacer(),
                                                  Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    Center(
                                      child: GestureDetector(
                                        onTap: () => context.pop(),
                                        child: const Text(
                                          'Remember password? Sign In',
                                          style: TextStyle(color: Color(0xFF0A633D), fontWeight: FontWeight.w800, fontSize: 13.5),
                                        ),
                                      ),
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
}
