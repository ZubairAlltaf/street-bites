import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streetbites/provider/buyer/buyer_auth_provider.dart';
import 'package:streetbites/widgets/custom_snackbar.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    // Initial check for verification status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVerificationStatus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkVerificationStatus() async {
    setState(() {
      _isChecking = true;
    });
    final auth = Provider.of<BuyerAuthProvider>(context, listen: false);
    final isVerified = await auth.checkEmailVerification();
    if (isVerified && mounted) {
      showCustomSnackBar(context, 'Email verified!');
      Navigator.pop(context); // Navigate back or to home screen
    }
    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<BuyerAuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade600, Colors.green.shade300],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Verify Your Email',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.orange,
                          shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Please check your email (${auth.currentUser?.email ?? "your email"}) for a verification link.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _isChecking
                          ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.orange,
                          strokeWidth: 2,
                        ),
                      )
                          : GestureDetector(
                        onTapDown: (_) {
                          if (!_isChecking) {
                            _animationController.forward();
                          }
                        },
                        onTapUp: (_) {
                          if (!_isChecking) {
                            _animationController.reverse().then((_) {
                              _checkVerificationStatus();
                            });
                          }
                        },
                        onTapCancel: () {
                          if (!_isChecking) {
                            _animationController.reverse();
                          }
                        },
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: ElevatedButton(
                            onPressed: _isChecking ? null : _checkVerificationStatus,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 6,
                              shadowColor: Colors.black38,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('Refresh Status'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _isChecking
                            ? null
                            : () async {
                          final success = await auth.resendVerificationEmail();
                          if (success) {
                            showCustomSnackBar(context, 'Verification email resent!');
                          } else {
                            showCustomSnackBar(context, 'Failed to resend email. Try again.', isError: true);
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange.shade600,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: const Text('Resend Verification Email'),
                      ),
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