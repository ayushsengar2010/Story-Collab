import 'package:collabwrite/core/constants/assets.dart';
import 'package:collabwrite/views/home/home_screen.dart';
import 'package:flutter/material.dart';

// Import your AuthService
import '../../services/auth_service.dart'; // Adjust path as necessary
import '../signup/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService(); // Instantiate AuthService
  bool _isLoading = false; // To manage loading state

  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Show an initial "Logging in..." SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logging in...')),
    );

    final String email = _emailController.text;
    final String password = _passwordController.text;

    final result = await _authService.login(
      email: email,
      password: password,
    );

    if (mounted) {
      // Check if the widget is still in the tree
      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar(); // Hide "Logging in..."

      if (result['success'] == true) {
        final String token = result['token'] ?? 'N/A';
        print('Login successful! Token: $token');
        // TODO: Store the token securely (e.g., using flutter_secure_storage or a state management solution)
        // For now, we just print it and navigate.

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Login successful!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(result['message'] ?? 'Login failed. Please try again.')),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void signInWithGoogle() {
    // Implement Google Sign-In logic here (can also be moved to AuthService)
    print('Google sign-in button pressed');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In not implemented yet.')),
      );
    }
  }

  void signInWithFacebook() {
    // Implement Facebook Sign-In logic here (can also be moved to AuthService)
    print('Facebook sign-in button pressed');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Facebook Sign-In not implemented yet.')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height,
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Login to your account',
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "It's great to see you again.",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF808080),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFields(
                    // Using the consistent TextFields widget
                    name: 'Email',
                    hintText: 'Enter your email address',
                    controller: _emailController,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !value.contains('@') ||
                          !value.contains('.')) {
                        // Basic email validation
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFields(
                    // Using the consistent TextFields widget
                    name: 'Password',
                    hintText: 'Enter your password',
                    controller: _passwordController,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            print('Forgot password tapped');
                            // TODO: Navigate to forgot password screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Forgot Password not implemented yet.')),
                            );
                          },
                    child: const Text.rich(
                      TextSpan(
                        text: 'Forgot your password?  ',
                        style: TextStyle(color: Colors.black54),
                        children: [
                          TextSpan(
                            text: 'Reset your password',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Button(
                    // Using the consistent Button widget
                    name: _isLoading ? 'Logging in...' : 'Login',
                    textColor: Colors.white,
                    color: MaterialStateProperty.all<Color>(
                      const Color(0xFF1A1A1A),
                    ),
                    onPressed: _isLoading ? null : _performLogin,
                  ),
                  const SizedBox(height: 20),
                  const Divider(
                    color: Color(0xFFE6E6E6),
                    thickness: 1,
                  ),
                  const SizedBox(height: 10),
                  Button(
                    // Using the consistent Button widget
                    name: 'Sign In with Google', // Changed text
                    textColor: Colors.black,
                    color: MaterialStateProperty.all<Color>(Colors.white),
                    isOutlined: true,
                    imagePath: AppAssets.google,
                    onPressed: _isLoading ? null : signInWithGoogle,
                  ),
                  const SizedBox(height: 10),
                  Button(
                    // Using the consistent Button widget
                    name: 'Sign In with Facebook', // Changed text
                    textColor: Colors.white,
                    color: MaterialStateProperty.all<Color>(
                        const Color(0xFF1877F2)),
                    imagePath: AppAssets.facebook,
                    onPressed: _isLoading ? null : signInWithFacebook,
                  ),
                  const Spacer(),
                  Center(
                    child: GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignupScreen(),
                                ),
                              );
                            },
                      child: RichText(
                        text: const TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(
                            color: Color(0xFF808080),
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Sign up',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Re-usable Button Widget (ensure this is consistent with your SignupScreen's version) ---
class Button extends StatelessWidget {
  final MaterialStateProperty<Color?> color;
  final String name;
  final Color textColor;
  final String? imagePath;
  final bool isOutlined;
  final VoidCallback? onPressed; // Changed to VoidCallback? to allow null

  const Button({
    super.key,
    required this.name,
    required this.textColor,
    required this.color,
    this.imagePath,
    this.isOutlined = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ButtonStyle(
      fixedSize: MaterialStateProperty.all<Size>(const Size.fromHeight(55)),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      backgroundColor:
          isOutlined ? MaterialStateProperty.all<Color>(Colors.white) : color,
      side: isOutlined
          ? MaterialStateProperty.all<BorderSide>(
              BorderSide(color: textColor),
            )
          : null,
      foregroundColor: MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return textColor.withOpacity(0.5);
          }
          return textColor;
        },
      ),
      overlayColor: MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.pressed)) {
            return textColor.withOpacity(0.12);
          }
          return null;
        },
      ),
    );

    final childWidget = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (imagePath != null) Image.asset(imagePath!, width: 30, height: 30),
        if (imagePath != null) const SizedBox(width: 10),
        Text(
          name,
          style: TextStyle(
              color:
                  onPressed == null ? textColor.withOpacity(0.5) : textColor),
        ),
      ],
    );

    if (isOutlined) {
      return OutlinedButton(
        style: buttonStyle,
        onPressed: onPressed,
        child: childWidget,
      );
    } else {
      return ElevatedButton(
        style: buttonStyle,
        onPressed: onPressed,
        child: childWidget,
      );
    }
  }
}

// --- Re-usable TextFields Widget (ensure this is consistent with your SignupScreen's version) ---
class TextFields extends StatefulWidget {
  final String name;
  final String hintText;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final bool obscureText;

  const TextFields({
    super.key,
    required this.name,
    required this.hintText,
    required this.controller,
    this.validator,
    this.obscureText = false,
  });

  @override
  _TextFieldsState createState() => _TextFieldsState();
}

class _TextFieldsState extends State<TextFields> {
  late FocusNode _focusNode;
  // bool _isFocused = false; // Not strictly needed for border if using TextFormField's own error/focus states
  bool _isObscureTextVisible = false; // For password visibility toggle

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // _focusNode.addListener(_onFocusChange); // Listener might not be needed if relying on TextFormField states
    _isObscureTextVisible =
        widget.obscureText; // Initialize based on widget property
  }

  // void _onFocusChange() {
  //   if (mounted) {
  //     setState(() {
  //       _isFocused = _focusNode.hasFocus;
  //     });
  //   }
  // }

  @override
  void dispose() {
    // _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.name,
          style: const TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          // Using TextFormField for better form integration
          controller: widget.controller,
          obscureText: widget.obscureText &&
              !_isObscureTextVisible, // Use local state for visibility
          cursorColor: const Color(0xFF808080),
          validator: widget.validator,
          focusNode: _focusNode,
          onChanged: (value) {
            // Optional: if you want live validation feedback as user types,
            // but Form's validate() on submit or AutovalidateMode is usually sufficient.
            // if(mounted) setState(() {});
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(
              fontWeight: FontWeight.w300,
              color: Color(0xFF808080),
              fontFamily: 'GeneralSans',
            ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _isObscureTextVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscureTextVisible = !_isObscureTextVisible;
                      });
                    },
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.grey, // Default border color
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context)
                    .primaryColor, // Use theme's primary color for focus
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2.0,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          ),
        ),
      ],
    );
  }
}
