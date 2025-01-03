import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

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
  final Widget privacyPolicy;
  final Widget termsOfService;
  final bool hideForgotPasswordButton;
  final bool hideSignupButton;
  final String userType;

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
    required this.privacyPolicy,
    required this.termsOfService,
    this.hideForgotPasswordButton = false,
    this.hideSignupButton = false,
    this.userType = 'parent',
  }) : super(key: key);

  @override
  _VoxigoLoginWidgetState createState() => _VoxigoLoginWidgetState();
}

class _VoxigoLoginWidgetState extends State<VoxigoLoginWidget> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  bool isSignUpMode = false; // Tracks whether the user is in Signup mode
  bool isRecoverPasswordMode = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    emailController.text = widget.savedEmail;
    passwordController.text = widget.savedPassword;
    isValidationTriggered = false;
  }

  String? emailValidator(String? value) {
    final emailRegex =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (value == null || value.isEmpty) {
      print("Email is required");

      return "Email is required";
    } else if (!emailRegex.hasMatch(value)) {
      return "Please enter a valid email address";
    }
    return null;
  }

  Future<void> _handleLogin() async {
    // Existing login logic
    final email = emailController.text.trim();

    if (widget.userType == 'parent') {
      String emailvalidationresult = emailValidator(emailController.text) ?? '';
      if (emailvalidationresult.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(emailvalidationresult)),
        );
        return;
      }
    }
    _triggerValidation();

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
    });
  }

  bool _validateFields() {
    if (isSignUpMode) {
      return !(emailController.text.isEmpty ||
          passwordController.text.isEmpty ||
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
      final confirmPassword = confirmPasswordController.text.trim();
      final firstName = firstNameController.text.trim();
      final lastName = lastNameController.text.trim();

      // Field validations
      if (email.isEmpty ||
          password.isEmpty ||
          firstName.isEmpty ||
          lastName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields.')),
        );
        return;
      }
      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match.")),
        );
        return;
      }
      // Prepare additional signup data
      final additionalData = {
        "Username": 'voxigo',
        "First name": firstName,
        "Last name": lastName,
      };

      // Call the onSignup function
      final result = await widget.onSignup(email, password, additionalData);

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      }
      if (result != null && !result.contains('Registration failed')) {
        widget.redirectAfterSignup?.call();
      }
    }
  }

  Future<void> _handleRecoverPassword() async {
    print('_handleRecoverPassword');
    final email = emailController.text.trim();
    String validationresult = emailValidator(email) ?? '';

    if (validationresult.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationresult)),
      );
      return;
    }

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
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile =
                constraints.maxWidth < 600; // Define breakpoint for mobile
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile
                              ? 16.0
                              : 40.0, // Adjust padding based on device
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title Section
                            Text(
                              widget.title,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: isMobile
                                    ? 32.0
                                    : 48.0, // Responsive font size
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox(
                                height: 20), // Space between title and card

                            // Card Section
                            Container(
                              width: isMobile
                                  ? double.infinity
                                  : 450.0, // Adjust card width
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
                  ),
                ),
                // Footer Section
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Text(
                    widget.footer ?? "",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: isMobile ? 16.0 : 20.0, // Responsive font size
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            );
          },
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
          labelText: widget.userType == 'parent' ? 'Email' : 'Username',
          errorText: widget.userType == 'parent'
              ? (emailValidator(emailController.text) ?? '')
              : 'Username is required',
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
            setState(() {
              isValidationTriggered = false; // Reset validation
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
        // Step 1: Email and password
        CustomTextField(
          controller: emailController,
          labelText: widget.userType == 'parent' ? 'Email' : 'Username',
          errorText: widget.userType == 'parent'
              ? (emailValidator(emailController.text) ?? '')
              : 'Username is required',
          prefixIcon: widget.userType == 'parent'
              ? const Icon(Icons.email)
              : Icon(Icons.person_outline_rounded),
          showError: emailController.text.isEmpty,
          validationTriggered: isValidationTriggered,
        ),
        const SizedBox(height: 16),
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                CustomTextField(
                  controller: passwordController,
                  labelText: 'Password',
                  errorText: 'Password is required',
                  prefixIcon: const Icon(Icons.lock),
                  isPassword: true,
                  isPasswordVisible: isPasswordVisible,
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
                    isPasswordVisible: isConfirmPasswordVisible,
                    validationTriggered: isValidationTriggered,
                    showError: confirmPasswordController.text.isEmpty,
                    onTogglePassword: () {
                      setState(() {
                        isConfirmPasswordVisible = !isConfirmPasswordVisible;
                      });
                    },
                  ),
              ],
            );
          },
        ),
        if (isSignUpMode) ...[
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
        ]
      ],
    );
  }

  Widget _buildActionSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600; // Threshold for compact layout

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isSignUpMode && !widget.hideSignupButton)
          Column(
            children: [
              SizedBox(height: isCompact ? 8.0 : 16.0), // Dynamic spacing
              Padding(
                padding: EdgeInsets.only(bottom: isCompact ? 12.0 : 24.0),
                child: Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: "I have read and accepted Voxigo's ",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize:
                            isCompact ? 12.0 : 14.0, // Responsive font size
                      ),
                      children: [
                        TextSpan(
                          text: "Terms of Service",
                          style: const TextStyle(
                            color: Color(0xFF56B1FB),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(context, '/terms_of_use');
                            },
                        ),
                        const TextSpan(text: " and "),
                        TextSpan(
                          text: "Privacy Policy",
                          style: const TextStyle(
                            color: Color(0xFF56B1FB),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(context, '/privacy_policy');
                            },
                        ),
                        const TextSpan(text: "."),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ElevatedButton(
          onPressed: isSignUpMode ? _handleSignup : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF56B1FB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            padding: EdgeInsets.symmetric(vertical: isCompact ? 12.0 : 16.0),
          ),
          child: Text(
            isSignUpMode ? 'SIGN UP' : 'LOGIN',
            style: TextStyle(
              fontSize: isCompact ? 18.0 : 20.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (!isSignUpMode && !widget.hideForgotPasswordButton)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  isRecoverPasswordMode = true;
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.fromLTRB(8.0, 4.0, 0.0, 4.0),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: const Color(0xFF56B1FB),
                  fontSize: isCompact ? 14.0 : 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (widget.userType ==
            'parent') // Show Google and toggle sections only for 'parent'
          ...[
          SizedBox(height: isCompact ? 8.0 : 16.0),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: Colors.grey[400],
                  thickness: isCompact ? 0.5 : 1.0,
                ),
              ),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: isCompact ? 4.0 : 8.0),
                child: Text(
                  isSignUpMode ? 'or signup with' : 'or login with',
                  style: TextStyle(fontSize: isCompact ? 12.0 : 14.0),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Colors.grey[400],
                  thickness: isCompact ? 0.5 : 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 8.0 : 16.0),
          GestureDetector(
            onTap: _handleGoogleLogin,
            child: Image.asset(
              'assets/icon/google_icon.png',
              width: isCompact ? 40.0 : 48.0,
              height: isCompact ? 40.0 : 48.0,
            ),
          ),
          SizedBox(height: isCompact ? 8.0 : 16.0),
          TextButton(
            onPressed: () {
              setState(() {
                isSignUpMode = !isSignUpMode;
                isValidationTriggered = false;
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
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
  final bool isPasswordVisible;
  final VoidCallback? onTogglePassword;

  const CustomTextField({
    required this.controller,
    required this.labelText,
    required this.errorText,
    required this.prefixIcon,
    required this.showError,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onTogglePassword,
    this.validationTriggered = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: Colors.black,
          fontSize: 18.0,
          fontWeight: FontWeight.w200,
        ),
        prefixIcon: prefixIcon,
        prefixIconColor: theme.colorScheme.secondary,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: theme.colorScheme.secondary,
                ),
                onPressed: onTogglePassword,
                tooltip: isPasswordVisible
                    ? 'Hide password'
                    : 'Show password', // Improves accessibility
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(
            color: Color(0xFF56B1FB),
            width: 2.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(
            color: Color(0xFF56B1FB).withOpacity(0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(
            color: Color(0xFF56B1FB),
            width: 2.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2.5,
          ),
        ),
        errorText: validationTriggered && showError ? errorText : null,
        errorStyle: TextStyle(
          color: theme.colorScheme.error,
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
      ),
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontSize: 16.0,
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
