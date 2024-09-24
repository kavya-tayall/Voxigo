import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import '../main.dart';
import 'package:test_app/parent_pages/parent_login_page.dart';
import '../auth_logic.dart';



class ChildLoginPage extends StatelessWidget {
  ChildLoginPage({super.key});
  final AuthService _auth = AuthService();

  String? checkUsername(input) {
    return null;
  }

  Future<String?> _authUser(BuildContext context, LoginData data) async {
    try {
      await _auth.signInChild(data.name, data.password, context);
    } on ChildDoesNotExistException {
      return ChildDoesNotExistException().toString();
    } catch (e) {
      print(e);
      return e.toString();
    }
    return null;
  }


  Future<String?> _recoverPassword(String name) async {
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      FlutterLogin(
        onLogin: (loginData) => _authUser(context, loginData),
        hideForgotPasswordButton: true,
        onRecoverPassword: _recoverPassword,
        userValidator: checkUsername,
        title: "Child Login",
        userType: LoginUserType.name,
        theme: LoginTheme(primaryColor: Color(0xFF56B1FB)),
        messages: LoginMessages(userHint: 'Username'),
        footer: "ConnectAutism, Inc",
        onSubmitAnimationCompleted: () {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => BasePage(),
          ));
        },
      )

      ,Positioned(
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
