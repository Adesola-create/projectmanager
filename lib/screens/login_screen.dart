import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await ApiService.authenticateUser(email, password);
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', json.encode(user.toJson()));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(employee: user),
          ),
        );
      } else {
        _showError('Login failed. Please try again.');
      }
    } catch (e) {
      _showError('Login failed. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Color(0xFF3B82F6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: Color(0xFF1D4ED8).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status indicator
                    // Container(
                    //   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    //   decoration: BoxDecoration(
                    //     color: Colors.white,
                    //     borderRadius: BorderRadius.circular(20),
                    //     border: Border.all(color: Color(0xFFE2E8F0)),
                    //   ),
                      // child: Row(
                      //   mainAxisSize: MainAxisSize.min,
                      //   children: [
                      //     Container(
                      //       width: 8,
                      //       height: 8,
                      //       decoration: BoxDecoration(
                      //         color: Color(0xFF10B981),
                      //         shape: BoxShape.circle,
                      //       ),
                      //     ),
                      //     SizedBox(width: 8),
                      //     Text(
                      //       'System Online v2.4',
                      //       style: TextStyle(
                      //         fontSize: 12,
                      //         fontWeight: FontWeight.w600,
                      //         color: Color(0xFF64748B),
                      //       ),
                      //     ),
                      //   ],
                      // ),
                   // ),
                    SizedBox(height: 40),
                    // Login card
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header gradient
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF0EA5E9), Color(0xFF3B82F6), Color(0xFF6366F1)],
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                // App icon
                                // Container(
                                //   width: 80,
                                //   height: 80,
                                //   decoration: BoxDecoration(
                                //     gradient: LinearGradient(
                                //       colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                                //       begin: Alignment.topLeft,
                                //       end: Alignment.bottomRight,
                                //     ),
                                //     borderRadius: BorderRadius.circular(20),
                                //     boxShadow: [
                                //       BoxShadow(
                                //         color: Color(0xFF3B82F6).withOpacity(0.3),
                                //         blurRadius: 12,
                                //         offset: Offset(0, 4),
                                //       ),
                                //     ],
                                //   ),
                                //   child: Icon(Icons.schedule, color: Colors.white, size: 40),
                                // ),
                                // SizedBox(height: 24),
                                // Title
                                Text(
                                  'TimeTrack Pro',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Enter your credentials to clock in.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                SizedBox(height: 32),
                                // Email field
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Email',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: _emailController,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                // Password field
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Password',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                        // Text(
                                        //   'Forgot Password?',
                                        //   style: TextStyle(
                                        //     fontSize: 12,
                                        //     fontWeight: FontWeight.w600,
                                        //     color: Color(0xFF3B82F6),
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        hintText: '••••••••',
                                        prefixIcon: Icon(Icons.lock, color: Color(0xFF64748B)),
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 32),
                                // Login button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF3B82F6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.login, size: 20),
                                              SizedBox(width: 8),
                                              Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                SizedBox(height: 24),
                                // Footer
                                // Container(
                                //   padding: EdgeInsets.only(top: 24),
                                //   decoration: BoxDecoration(
                                //     border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                                //   ),
                                //   child: Text(
                                //     'Don\'t have an account? Register Business',
                                //     style: TextStyle(
                                //       fontSize: 14,
                                //       color: Color(0xFF64748B),
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
                    // Bottom links
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Text('Privacy Policy', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                    //     Container(
                    //       margin: EdgeInsets.symmetric(horizontal: 8),
                    //       width: 4,
                    //       height: 4,
                    //       decoration: BoxDecoration(
                    //         color: Color(0xFF9CA3AF),
                    //         shape: BoxShape.circle,
                    //       ),
                    //     ),
                    //     Text('Terms of Service', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                    //     Container(
                    //       margin: EdgeInsets.symmetric(horizontal: 8),
                    //       width: 4,
                    //       height: 4,
                    //       decoration: BoxDecoration(
                    //         color: Color(0xFF9CA3AF),
                    //         shape: BoxShape.circle,
                    //       ),
                    //     ),
                    //     Text('Help', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                    //   ],
                    // ),
                    // SizedBox(height: 8),
                    // Text(
                    //   '© 2024 TimeTrack Pro Inc.',
                    //   style: TextStyle(fontSize: 10, color: Color(0xFFD1D5DB)),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
