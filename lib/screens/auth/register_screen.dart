import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      // Crear usuario en Firebase Auth
      final credential = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Extraer nombre y apellido del nombre completo
      final fullName = _nameController.text.trim();
      final nameParts = fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : fullName;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Generar username simple del email
      final username = _emailController.text.trim().split('@')[0].toLowerCase();

      // Crear perfil en Firestore
      if (credential.user != null) {
        await _firestoreService.createUserProfile(
          userId: credential.user!.uid,
          email: _emailController.text.trim(),
          firstName: firstName,
          lastName: lastName,
          username: username,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Banner superior con título superpuesto
              Stack(
                children: [
                  // Imagen de fondo
                  Container(
                    width: double.infinity,
                    height: 280,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/milan_banner.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Título y subtítulo sobre la imagen
                  Positioned(
                    bottom: 15,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Text(
                          'Sign Up',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create an account to start your adventure.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Contenido del formulario
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Campo Nombre
                      _buildTextField(
                        controller: _nameController,
                        hintText: 'Full Name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo Email
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo Contraseña
                      _buildTextField(
                        controller: _passwordController,
                        hintText: 'Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        showToggle: true,
                        onToggle: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter a password';
                          }
                          if (value.length < 6) {
                            return 'At least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo Confirmar Contraseña
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscureConfirmPassword,
                        showToggle: true,
                        onToggle: () {
                          setState(() => _obscureConfirmPassword =
                              !_obscureConfirmPassword);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Botón Crear Cuenta
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF9A56),
                              Color(0xFFFF7A3D),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF9A56).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Términos y condiciones
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodySmall,
                          children:  [
                            const TextSpan(text: 'By signing up you accept our\n'),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Link a login
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.secondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

   Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool showToggle = false,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
  }) {
    return FormField<String>(
      validator: validator,
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                obscureText: obscureText,
                onChanged: (v) {
                  state.didChange(v); // actualiza el valor del FormField
                },
                onEditingComplete: () {
                  state.validate(); // fuerza validación al terminar
                  FocusScope.of(state.context).nextFocus();
                },
                decoration: InputDecoration(
                  hintText: hintText,
                  prefixIcon: Icon(icon),
                  suffixIcon: showToggle
                      ? IconButton(
                          icon: Icon(
                            obscureText
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: onToggle,
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(state.context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
              ),
            ),

            if (state.hasError) ...[
              const SizedBox(height: 6),
              Text(
                state.errorText!,
                style: Theme.of(state.context).textTheme.bodySmall?.copyWith(
                color: Theme.of(state.context).colorScheme.error,
                    ),
              ),
            ],
          ],
        );
      },
    );
  }
}
