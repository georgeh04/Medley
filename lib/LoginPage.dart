import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ProfilePage.dart';
import 'package:Medley/main.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 20),child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 60.0,
            ),
            SizedBox(height: 30),
            Text('Your taste, in one place.'),
            SizedBox(height: 20,),
            TextField(
              controller: _usernameController,
            ),
            SizedBox(height: 12.0),
            TextField(
              controller: _passwordController,
              obscureText: true,
            ),
            SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: () async {
                var response = await post(Uri.parse('https://app.medleyapp.co.uk/authenticate.php'), body: {'username' : _usernameController.text, 'password' : _passwordController.text});
                if(response.body == 'Please fill both the username and password fields' || response.body == 'Incorrect username and/or password!'){
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Incorrect username/password, try again.'), backgroundColor: Colors.redAccent,));
                } else {
                    var jsonResponse = json.decode(response.body);
                    userData.setUsername(jsonResponse['username']);
                    userData.setUserId(jsonResponse['userid']);
                    userData.setAccessToken(jsonResponse['access_token']);
                    saveUserLogin(jsonResponse['userid'], jsonResponse['access_token'], jsonResponse['username']);
                    print('user logged in as ${userData.username} ${userData.userId} ${userData.accesstoken}');
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen()));
                }
                },
              child: Text('Login'),
            ),
            ElevatedButton(onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));}, child: Text('Register an Account'))
          ],
        ),
      ),
      ),
    );
  }
}


class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _emailController = TextEditingController();
  bool rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 20),child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 60.0,
            ),
            SizedBox(height: 30),
            Text('Your taste, in one place.'),
            SizedBox(height: 20,),
            TextField(
              decoration: InputDecoration(hintText: 'Username'),
              controller: _usernameController,
            ),
            TextField(
              decoration: InputDecoration(hintText: 'Password'),
              controller: _passwordController,
              obscureText: true,
            ),
            TextField(
              decoration: InputDecoration(hintText: 'Confirm Password'),
              controller: _passwordConfirmController,
              obscureText: true,
            ),
            TextField(
              decoration: InputDecoration(hintText: 'Email'),
              controller: _emailController,
            ),
            SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: () async {
                var response = await post(Uri.parse('https://app.medleyapp.co.uk/register-process.php'), body: {'username' : _usernameController.text, 'password' : _passwordController.text, 'cpassword' : _passwordConfirmController.text, 'email' : _emailController.text});
                if(response.body == 'Please complete the registration form!' || response.body == 'Please provide a valid email address!' || response.body == 'Username must contain only letters and numbers!' || response.body == 'Password must be between 5 and 20 characters long!' || response.body == 'Passwords do not match!' || response.body == 'Username and/or email exists!'){
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.body), backgroundColor: Colors.redAccent,));
                } if(response.body == 'Please check your email to activate your account!'){
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.body), backgroundColor: Colors.green,));
                  Navigator.pop(context);
                }else {
                    print('response from register ${response.body}');
                    var jsonResponse = json.decode(response.body);
                    User user = User();
                    user.setUsername(jsonResponse['username']);
                    user.setUserId(jsonResponse['userid']);
                    user.setAccessToken(jsonResponse['access_token']);
                    print('user logged in as ${user.username} ${user.userId} ${user.accesstoken}');
                    saveUserLogin(jsonResponse['userid'], jsonResponse['access_token'], jsonResponse['username']);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RegisterCompletionPage()));
                }
                },
              child: Text('Register'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}


Future<void> saveUserLogin(String userId, String accesstoken, String username) async {
final SharedPreferences prefs = await SharedPreferences.getInstance();

await prefs.setString('userId', userId);
await prefs.setString('accesstoken', accesstoken);
await prefs.setString('username', username);
}

Future<void> clearUserLogin() async {
final SharedPreferences prefs = await SharedPreferences.getInstance();

await prefs.remove('userId');
await prefs.remove('accesstoken');
await prefs.remove('username');
}




