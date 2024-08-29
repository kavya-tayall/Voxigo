import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import '../main.dart';
import 'package:test_app/parent_pages/parent_login_page.dart';

Map<String, String> users = {"kavya": "password1", "nihanth": "password2"};

class ChildLoginID {
  String username;
  String password;
  String accountType;

  String? email;

  ChildLoginID(this.username, this.password, this.accountType, {this.email});
}

class ChildLoginPage extends StatelessWidget {
  const ChildLoginPage({super.key});

  String? checkUsername(input) {
    return null;
  }

  Future<String?> _authUser(LoginData data) async {
    if (!users.containsKey(data.name)) {
      return 'User not exists';
    }
    if (users[data.name] != data.password) {
      return 'Password does not match';
    }
    ChildLoginID currentUser = ChildLoginID(data.name, data.password, "child");
    await Future.delayed(const Duration(seconds: 2));
    return null; // Successful login
  }

  Future<String?> _recoverPassword(String name) async {
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      FlutterLogin(
        onLogin: _authUser,
        hideForgotPasswordButton: true,
        onRecoverPassword: _recoverPassword,
        userValidator: checkUsername,
        title: "Child Login",

        userType: LoginUserType.name,
        theme: LoginTheme(primaryColor: Color(0xFF56B1FB),),
        onSubmitAnimationCompleted: () {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => BasePage(),
          ));
        },
      ),
      Positioned(
        top: 20,
        right: 20,
        child: ElevatedButton(
          onPressed:(){ _navigateToParentLogin(context);},
          child: Text("Parent Login"),
        ),
      )
    ]);
  }

  void _navigateToParentLogin(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ParentLoginPage()),
    );
  }
}
