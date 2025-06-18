import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/shared_preferences_helper.dart';
import '../../service_provider/screens/home/provider_home_screen.dart';
import '../../service_seeker/screens/home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  void _login() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Use Future.wait for parallel operations where possible
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential.user == null) {
        throw Exception('Authentication failed');
      }

      // Try cache first, then server
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get(GetOptions(source: Source.cache))
          .catchError((_) => FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get());

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final userData = userDoc.data();
      final role = _determineUserRole(userData);

      await SharedPreferencesHelper.saveLoginState(
        userId: userCredential.user!.uid,
        role: role,
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      _navigateToHome(role);
    } on FirebaseAuthException catch (e) {
      if (mounted) _showErrorMessage(e);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('An unexpected error occurred. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _determineUserRole(Map<String, dynamic>? userData) {
    if (userData == null) return 'seeker';

    return userData['role'] ??
        (userData['userType']?.toString().toLowerCase().contains('provider') ==
                true
            ? 'provider'
            : 'seeker');
  }

  void _navigateToHome(String role) {
    final route = role == 'provider'
        ? MaterialPageRoute(builder: (context) => ProviderHomeScreen())
        : MaterialPageRoute(builder: (context) => HomeScreen());

    Navigator.of(context).pushAndRemoveUntil(route, (route) => false);
  }

  void _showErrorMessage(FirebaseAuthException e) {
    String errorMessage = 'An error occurred. Please try again.';
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'No user found with this email.';
        break;
      case 'wrong-password':
        errorMessage = 'Incorrect password.';
        break;
      case 'account-exists-with-different-credential':
        errorMessage = 'The account exists with a different credential.';
        break;
      case 'invalid-credential':
        errorMessage = 'The credential is invalid.';
        break;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Override the app theme to force light theme for this screen
      data: ThemeData.light().copyWith(
        colorScheme: ColorScheme.light(),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: Colors.black87,
              displayColor: Colors.black87,
            ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 60),
                  _buildLogo(),
                  SizedBox(height: 24),
                  _buildAppName(),
                  SizedBox(height: 8),
                  _buildWelcomeText(),
                  SizedBox(height: 50),
                  _buildEmailField(),
                  SizedBox(height: 20),
                  _buildPasswordField(),
                  _buildForgotPassword(),
                  SizedBox(height: 40),
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _buildLoginButton(),
                  SizedBox(height: 50),
                  _buildSignUpOption(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF2A9D8F), Color(0xFF264653)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.handyman_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppName() {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          Color(0xFF2A9D8F), // Teal
          Colors.blue.shade600, // Blue
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      child: Text(
        "SkillLink",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Colors.white, // This will be masked by the gradient
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Text(
      "Welcome back! Please sign in to continue",
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[600],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEmailField() => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(
            color: Colors.black87, // Force dark text
            fontSize: 16,
          ),
          decoration: InputDecoration(
            labelText: "Email Address",
            labelStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF2A9D8F)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Color(0xFF2A9D8F), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
          validator: (value) =>
              value!.isEmpty ? 'Please enter your email' : null,
        ),
      );

  Widget _buildPasswordField() => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          style: TextStyle(
            color: Colors.black87, // Force dark text
            fontSize: 16,
          ),
          decoration: InputDecoration(
            labelText: "Password",
            labelStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF2A9D8F)),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Color(0xFF2A9D8F), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
          validator: (value) =>
              value!.isEmpty ? 'Please enter your password' : null,
        ),
      );

  Widget _buildForgotPassword() => Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(top: 12),
          child: TextButton(
            onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
            child: Text(
              "Forgot Password?",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.blue.shade600, // Force blue color
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue.shade600,
            ),
          ),
        ),
      );

  Widget _buildLoginButton() => Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: _isLoading
              ? LinearGradient(colors: [Colors.grey, Colors.grey])
              : LinearGradient(
                  colors: [Color(0xFF2A9D8F), Colors.blue.shade600],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF2A9D8F).withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _login, // Disable when loading
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  "Sign In",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      );

  Widget _buildSignUpOption() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue.shade600,
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Color(0xFF2A9D8F),
                  Colors.blue.shade600,
                ],
              ).createShader(bounds),
              child: Text(
                "Sign Up",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white, // This will be masked by the gradient
                ),
              ),
            ),
          ),
        ],
      );
}
