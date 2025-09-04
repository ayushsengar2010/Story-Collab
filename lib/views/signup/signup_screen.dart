import 'dart:convert'; // No longer needed here directly if AuthService handles it
import 'package:collabwrite/core/constants/assets.dart';
import 'package:collabwrite/views/home/home_screen.dart';
import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http; // No longer needed here

// Import your AuthService
import '../../services/auth_service.dart'; // Adjust path as necessary
import '../login/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService(); // Instantiate AuthService
  bool _isLoading = false;

  Future<void> _performSignUp() async {
    // Renamed to avoid conflict with widget methods
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creating account...')),
    );

    final String name = _nameController.text;
    final String email = _emailController.text;
    final String password = _passwordController.text;

    // Call the AuthService signUp method
    final result = await _authService.signUp(
      name: name,
      email: email,
      password: password,
      // You can pass other fields if you collect them from the UI
      // bio: _bioController.text,
      // location: _locationController.text,
    );

    if (mounted) {
      // Check if the widget is still in the tree
      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar(); // Hide "Creating account..."

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(result['message'] ?? 'Account created successfully!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Signup failed.')),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void signUpWithGoogle() {
    // Implement Google Sign-Up logic here (can also be moved to AuthService)
    print('Google sign-up button pressed');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-Up not implemented yet.')),
      );
    }
  }

  void signUpWithFacebook() {
    // Implement Facebook Sign-Up logic here (can also be moved to AuthService)
    print('Facebook sign-up button pressed');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Facebook Sign-Up not implemented yet.')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
                    'Create an account',
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Let's create an account.",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF808080),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFields(
                    name: 'Full Name',
                    hintText: 'Enter your full name',
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFields(
                    name: 'Email',
                    hintText: 'Enter your email address',
                    controller: _emailController,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !value.contains('@') ||
                          !value.contains('.')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFields(
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
                  const Text.rich(
                    TextSpan(
                      text: 'By signing up you agree to our ',
                      children: [
                        TextSpan(
                          text: 'Terms',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ', '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ', and '),
                        TextSpan(
                          text: 'Cookies Use',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Button(
                    name: _isLoading ? 'Creating...' : 'Create an Account',
                    textColor: Colors.white,
                    color: MaterialStateProperty.all<Color>(
                      const Color(0xFF1A1A1A),
                    ),
                    onPressed: _isLoading
                        ? null
                        : _performSignUp, // Call _performSignUp
                  ),
                  const SizedBox(height: 20),
                  const Divider(
                    color: Color(0xFFE6E6E6),
                    thickness: 1,
                  ),
                  const SizedBox(height: 10),
                  Button(
                    name: 'Sign Up with Google',
                    textColor: Colors.black,
                    color: MaterialStateProperty.all<Color>(Colors.white),
                    isOutlined: true,
                    imagePath: AppAssets.google,
                    onPressed: _isLoading ? null : signUpWithGoogle,
                  ),
                  const SizedBox(height: 10),
                  Button(
                    name: 'Sign Up with Facebook',
                    textColor: Colors.white,
                    color: MaterialStateProperty.all<Color>(
                        const Color(0xFF1877F2)),
                    imagePath: AppAssets.facebook,
                    onPressed: _isLoading ? null : signUpWithFacebook,
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
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                      child: RichText(
                        text: const TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(
                            color: Color(0xFF808080),
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Log In',
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

// Your Button and TextFields widgets remain the same
// ... (Button widget code)
// ... (TextFields widget code)
// Make sure to include your Button and TextFields widgets here as they were in the previous version.
// For brevity, I'm omitting them, but they are necessary. I'll add them back if you need the full file.
class Button extends StatelessWidget {
  final MaterialStateProperty<Color?> color;
  final String name;
  final Color textColor;
  final String? imagePath;
  final bool isOutlined;
  final VoidCallback? onPressed;

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

class TextFields extends StatefulWidget {
  final String name;
  final String hintText;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final IconButton? passwordVisibilityIcon;

  const TextFields({
    super.key,
    required this.name,
    required this.hintText,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.passwordVisibilityIcon,
  });

  @override
  _TextFieldsState createState() => _TextFieldsState();
}

class _TextFieldsState extends State<TextFields> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _isObscureTextVisible = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _isObscureTextVisible = widget.obscureText;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
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
          controller: widget.controller,
          obscureText: widget.obscureText && !_isObscureTextVisible,
          cursorColor: const Color(0xFF808080),
          validator: widget.validator,
          focusNode: _focusNode,
          onChanged: (value) {
            if (mounted) setState(() {});
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
                color: Colors.grey,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.blueAccent,
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
