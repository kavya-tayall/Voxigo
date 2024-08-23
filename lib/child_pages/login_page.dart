import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import '../main.dart';

Map<String, String> users = {
  "kavya" : "password1",
  "tatikonda.nihanth@gmail.com" : "password2"
};



class LoginID {
  String username;
  String password;
  String accountType;

  String? email;


  LoginID(this.username, this.password, this.accountType, {this.email});
}


class ParentLoginPage extends StatelessWidget {
  const ParentLoginPage({super.key});

  String? checkUsername(input){
    return null;
  }

  Future<String?> _authUser(LoginData data) async {
    if (!users.containsKey(data.name)) {
      return 'User not exists';
    }
    if (users[data.name] != data.password) {
      return 'Password does not match';
    }
    LoginID currentUser = LoginID(data.name, data.password, "child");
    await Future.delayed(const Duration(seconds: 2));
    return null; // Successful login
  }

  Future<String?> _recoverPassword(String name) async {
    return null;
  }

  Future<String?> _signUp (SignupData data) async{
    print(data.name);
    print(data.password);
    return null;
}


  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      onLogin: _authUser,
      onRecoverPassword: _recoverPassword,
      onSignup: _signUp,
      userValidator: checkUsername,
      additionalSignupFields: [UserFormField(keyName: "Email", userType: LoginUserType.email)],
      title: "ConnectAutism",
      userType: LoginUserType.name,
      theme: LoginTheme(
        primaryColor: Color(0xFF56B1FB),
      ),
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) =>  BasePage(),
        ));
      },
    );
  }
}
