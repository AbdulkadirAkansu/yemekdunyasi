import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:yemekdunyasi/features/auth/data/repositories/auth_repository.dart';
import 'dart:async';
import 'package:yemekdunyasi/features/auth/data/exceptions/auth_exception.dart';
import 'package:google_fonts/google_fonts.dart';

class EmailConfirmationView extends StatefulWidget {
  final String email;
  
  const EmailConfirmationView({
    super.key,
    required this.email,
  });

  @override
  State<EmailConfirmationView> createState() => _EmailConfirmationViewState();
}

class _EmailConfirmationViewState extends State<EmailConfirmationView> {
  final _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _canResend = true;
  int _resendTimer = 60;
  int _remainingTime = 300; // 5 dakika
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          timer.cancel();
          // Süre bittiğinde login sayfasına yönlendir
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Doğrulama süresi doldu. Lütfen tekrar kayıt olun.'),
                backgroundColor: Colors.red,
              ),
            );
            context.go('/auth');
          }
        }
      });
    });
  }

  String get _timeDisplay {
    int minutes = _remainingTime ~/ 60;
    int seconds = _remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendTimer = 60;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);
    
    try {
      await _authRepository.signInWithOtp(
        email: widget.email,
        shouldCreateUser: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Yeni doğrulama kodu gönderildi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        _startResendTimer();
      }
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage = e.message;
        
        if (e.statusCode == '429') {
          if (e.message.contains('Lütfen')) {
            errorMessage = e.message;
            final seconds = int.tryParse(
              e.message.split(' ')[1],
            ) ?? 60;
            _resendTimer = seconds;
            _startResendTimer();
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      await _authRepository.verifyOTP(
        email: widget.email,
        token: _otpController.text,
      );

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Hatalı kod. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.shade300,
              Colors.orange.shade100,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo ve başlık
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(230),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                  ).animate()
                    .fadeIn()
                    .scale(),
                  
                  const SizedBox(height: 40),
                  
                  Text(
                    'Email Doğrulama',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ).animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.3, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    widget.email,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ).animate()
                    .fadeIn(delay: 400.ms),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'adresine gönderilen 6 haneli kodu girin',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Kalan süre
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _remainingTime < 60 
                          ? Colors.red.withAlpha(26) 
                          : Colors.green.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: _remainingTime < 60 ? Colors.red : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Kalan Süre: $_timeDisplay',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _remainingTime < 60 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ).animate()
                    .fadeIn(delay: 600.ms),
                  
                  const SizedBox(height: 40),
                  
                  // Kod girişi
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _otpController,
                      decoration: InputDecoration(
                        labelText: 'Doğrulama Kodu',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Theme.of(context).primaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      style: const TextStyle(
                        fontSize: 20,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Doğrulama kodu gerekli';
                        }
                        if (value.length != 6) {
                          return '6 haneli kodu girin';
                        }
                        return null;
                      },
                    ),
                  ).animate()
                    .fadeIn(delay: 800.ms)
                    .slideX(),
                  
                  const SizedBox(height: 24),
                  
                  // Doğrula butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleVerification,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: Theme.of(context).primaryColor.withAlpha(128),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Doğrula',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ).animate()
                    .fadeIn(delay: 1000.ms)
                    .slideY(begin: 0.3, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  // Tekrar gönder butonu
                  TextButton.icon(
                    onPressed: (_canResend && !_isLoading) ? _resendCode : null,
                    icon: Icon(
                      Icons.refresh,
                      size: 20,
                      color: _canResend ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                    label: Text(
                      _canResend 
                          ? 'Tekrar Gönder'
                          : '$_resendTimer saniye sonra tekrar dene',
                      style: TextStyle(
                        color: _canResend ? Theme.of(context).primaryColor : Colors.grey,
                      ),
                    ),
                  ).animate()
                    .fadeIn(delay: 1200.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }
} 