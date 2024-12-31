import 'package:flutter/material.dart';

class VoxigoLoginWidget extends StatefulWidget {
  final Future<String?> Function(String email, String password) onLogin;
  final Future<String?> Function(String email, String password,
      Map<String, String> additionalSignupFields) onSignup;
  final Future<String?> Function(String email) onRecoverPassword;

  final String title;
  final String savedEmail;
  final String savedPassword;
  final String? footer;
  final LoginMessages messages;
  final LoginTheme theme;

  final String? Function(String? value)? userValidator;
  final String? Function(String? value)? passwordValidator;

  final bool loginAfterSignUp;
  final void Function()? onSubmitAnimationCompleted;
  final void Function()? redirectAfterSignup;
  final void Function()? redirectAfterRecoverPassword;
  final Future<String?> Function() onGoogleSignIn;
  final List<UserFormField>? additionalSignupFields;

  const VoxigoLoginWidget({
    Key? key,
    required this.onLogin,
    required this.onSignup,
    required this.onRecoverPassword,
    this.title = "Login",
    this.savedEmail = '',
    this.savedPassword = '',
    this.footer,
    this.messages = const LoginMessages(),
    this.theme = const LoginTheme(),
    this.userValidator,
    this.passwordValidator,
    this.loginAfterSignUp = false,
    this.onSubmitAnimationCompleted,
    this.additionalSignupFields,
    this.redirectAfterSignup,
    this.redirectAfterRecoverPassword,
    required this.onGoogleSignIn,
  }) : super(key: key);

  @override
  _VoxigoLoginWidgetState createState() => _VoxigoLoginWidgetState();
}

class _VoxigoLoginWidgetState extends State<VoxigoLoginWidget> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  bool isSignUpMode = false; // Tracks whether the user is in Signup mode
  int signupStep = 1; // Tracks the current step in the signup process
  bool isRecoverPasswordMode = false;

  @override
  void initState() {
    super.initState();
    emailController.text = widget.savedEmail;
    passwordController.text = widget.savedPassword;
    isValidationTriggered = false;
  }

  Future<void> _handleLogin() async {
    _triggerValidation();
    // Existing login logic
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (widget.userValidator != null && widget.userValidator!(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.userValidator!(email)!)),
      );
      return;
    }
    if (widget.passwordValidator != null &&
        widget.passwordValidator!(password) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.passwordValidator!(password)!)),
      );
      return;
    }
    final result = await widget.onLogin(email, password);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
      throw Exception("Login failed: $result");
    }

    widget.onSubmitAnimationCompleted?.call();
  }

  void _goToNextSignupStep() {
    _triggerValidation();

    // Validate first-page fields
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match.")),
      );
      return;
    }

    setState(() {
      // Reset validation trigger for the new step
      isValidationTriggered = false;
      signupStep = 2; // Move to step 2
    });
  }

  bool _validateFields() {
    if (signupStep == 1) {
      return !(emailController.text.isEmpty || passwordController.text.isEmpty);
    } else if (signupStep == 2) {
      return !(usernameController.text.isEmpty ||
          firstNameController.text.isEmpty ||
          lastNameController.text.isEmpty);
    }
    return true; // Default case
  }

  Future<void> _handleSignup() async {
    _triggerValidation();
    if (_validateFields()) {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      final username = usernameController.text.trim();
      final firstName = firstNameController.text.trim();
      final lastName = lastNameController.text.trim();

      // Field validations
      if (email.isEmpty ||
          password.isEmpty ||
          username.isEmpty ||
          firstName.isEmpty ||
          lastName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields.')),
        );
        return;
      }

      // Prepare additional signup data
      final additionalData = {
        "Username": username,
        "First name": firstName,
        "Last name": lastName,
      };

      // Call the onSignup function
      final result = await widget.onSignup(email, password, additionalData);

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      } else if (widget.loginAfterSignUp) {
        // await widget.onLogin(email, password);
      }

      widget.redirectAfterSignup?.call();
    }
  }

  Future<void> _handleRecoverPassword() async {
    final email = emailController.text.trim();
    final result = await widget.onRecoverPassword(email);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
      widget.redirectAfterRecoverPassword?.call();
    }
  }

  void _handleGoogleLogin() async {
    // Implement Google login logic
    final result = await widget.onGoogleSignIn();
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
      widget.onSubmitAnimationCompleted?.call();
    }
  }

  bool isValidationTriggered = false;

  void _triggerValidation() {
    setState(() {
      isValidationTriggered = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF56B1FB),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title Section
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 48.0,
                  fontWeight: FontWeight.w200,
                ),
              ),
              const SizedBox(height: 20), // Space between title and card

              // Card Section
              Container(
                width: 350.0,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Data Entry Section
                    isRecoverPasswordMode
                        ? _buildRecoverPasswordSection()
                        : _buildDataEntrySection(),

                    const SizedBox(height: 20),

                    // Action Section
                    isRecoverPasswordMode
                        ? _buildRecoverPasswordActionSection()
                        : _buildActionSection(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecoverPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Please enter the email address associated with your account.",
          style: TextStyle(color: Colors.grey[700]),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: emailController,
          labelText: 'Email',
          errorText: 'Email is required',
          prefixIcon: const Icon(Icons.email),
          showError: emailController.text.isEmpty,
          validationTriggered: isValidationTriggered,
        ),
        const SizedBox(height: 16),
        Text(
          "We will send you a link to reset your password.",
          style: TextStyle(color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildRecoverPasswordActionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _handleRecoverPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF56B1FB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
          child: const Text(
            'RECOVER',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            _handleRecoverPassword();
            setState(() {
              isRecoverPasswordMode = false; // Go back to the login screen
            });
          },
          child: const Text(
            'Back',
            style: TextStyle(color: Color(0xFF56B1FB)),
          ),
        ),
      ],
    );
  }

  Widget _buildDataEntrySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isSignUpMode && signupStep == 2) ...[
          // Step 2: Collect additional details
          CustomTextField(
            controller: usernameController,
            labelText: 'Username',
            errorText: 'Username is required',
            prefixIcon: const Icon(Icons.person),
            showError: usernameController.text.isEmpty && isSignUpMode,
            validationTriggered: isValidationTriggered,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: firstNameController,
            labelText: 'First Name',
            errorText: 'First name is required',
            prefixIcon: const Icon(Icons.person_outline),
            showError: firstNameController.text.isEmpty && isSignUpMode,
            validationTriggered: isValidationTriggered,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: lastNameController,
            labelText: 'Last Name',
            errorText: 'Last name is required',
            prefixIcon: const Icon(Icons.person_outline),
            showError: lastNameController.text.isEmpty && isSignUpMode,
            validationTriggered: isValidationTriggered,
          ),
        ] else ...[
          // Step 1: Email and password
          CustomTextField(
            controller: emailController,
            labelText: 'Email',
            errorText: 'Email is required',
            prefixIcon: const Icon(Icons.email),
            showError: emailController.text.isEmpty,
            validationTriggered: isValidationTriggered,
          ),
          const SizedBox(height: 16),
          StatefulBuilder(
            builder: (context, setState) {
              bool isPasswordVisible = false;
              return Column(
                children: [
                  CustomTextField(
                    controller: passwordController,
                    labelText: 'Password',
                    errorText: 'Password is required',
                    prefixIcon: const Icon(Icons.lock),
                    isPassword: true,
                    showError: passwordController.text.isEmpty,
                    validationTriggered: isValidationTriggered,
                    onTogglePassword: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                  if (isSignUpMode) const SizedBox(height: 16),
                  if (isSignUpMode)
                    CustomTextField(
                      controller: confirmPasswordController,
                      labelText: 'Confirm Password',
                      errorText: 'Confirm Password is required',
                      prefixIcon: const Icon(Icons.lock),
                      isPassword: true,
                      validationTriggered: isValidationTriggered,
                      showError: confirmPasswordController.text.isEmpty,
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildActionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: isSignUpMode
              ? (signupStep == 1 ? _goToNextSignupStep : _handleSignup)
              : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF56B1FB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
          child: Text(
            isSignUpMode ? (signupStep == 1 ? 'NEXT' : 'SIGN UP') : 'LOGIN',
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (!isSignUpMode)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  isRecoverPasswordMode = true;
                });
              }, // Your forgot password logic
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Color(0xFF56B1FB), // Same color as your theme
                ),
              ),
            ),
          ),
        if (isSignUpMode && signupStep == 2)
          TextButton(
            onPressed: () {
              setState(() {
                signupStep = 1; // Go back to step 1
                isValidationTriggered = false; // Reset validation for step 1
              });
            },
            child:
                const Text('Back', style: TextStyle(color: Color(0xFF56B1FB))),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.grey[400],
                thickness: 1.0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(isSignUpMode ? 'or signup with' : 'or login with'),
            ),
            Expanded(
              child: Divider(
                color: Colors.grey[400],
                thickness: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _handleGoogleLogin,
          child: Image.asset(
            'assets/icon/google_icon.png',
            width: 48.0,
            height: 48.0,
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              isSignUpMode = !isSignUpMode;
              signupStep = 1; // Reset to first step when toggling
              isValidationTriggered = false;
            });
          },
          child: Text(
            isSignUpMode
                ? 'Already have an account? Login'
                : 'Don’t have an account? Sign Up',
            style: const TextStyle(
              color: Color(0xFF56B1FB),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String errorText;
  final bool isPassword;
  final Icon prefixIcon;
  final bool showError;
  final bool validationTriggered;
  final VoidCallback? onTogglePassword;

  const CustomTextField({
    required this.controller,
    required this.labelText,
    required this.errorText,
    required this.prefixIcon,
    required this.showError,
    this.isPassword = false,
    this.onTogglePassword,
    this.validationTriggered = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword && (onTogglePassword != null),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  onTogglePassword != null
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        errorText: validationTriggered && showError ? errorText : null,
      ),
    );
  }
}

class LoginMessages {
  final String recoverPasswordIntro;
  final String recoverPasswordDescription;

  const LoginMessages({
    this.recoverPasswordIntro = 'Forgot Password?',
    this.recoverPasswordDescription = 'Recover your account credentials here.',
  });
}

class LoginTheme {
  final Color primaryColor;

  const LoginTheme({this.primaryColor = Colors.blue});
}

class UserFormField {
  final String keyName;

  UserFormField({required this.keyName});
}

class LoginData {
  final String name;
  final String password;

  LoginData({required this.name, required this.password});
}

class SignupData {
  final String? name;
  final String? password;
  final Map<String, String>? additionalSignupData;

  SignupData({this.name, this.password, this.additionalSignupData});
}
