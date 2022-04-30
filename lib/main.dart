// ignore_for_file: prefer_const_constructors, unused_local_variable

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quiz_club/quiz.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const MyHomePage(title: 'Quiz Club'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _user;

  bool selectedTeam = false;

  final user = FirebaseAuth.instance.currentUser;

  Future googleLogin() async {
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return;

    _user = googleUser;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

    await FirebaseAuth.instance.signInWithCredential(credential);

    await Dio().post("http://10.0.2.2:3000/users", data: {
      "name": user!.displayName,
      "selected_team": selectedTeam ? "First Team" : "Second Team"
    });

    var response =
        await Dio().get('https://opentdb.com/api.php?amount=1&type=boolean');

    await Dio().post("http://10.0.2.2:3000/current_questions/", data: {
      "question": response.data["results"][0]["question"],
      "correct_answer": response.data["results"][0]["correct_answer"],
      "incorrect_answer": response.data["results"][0]["incorrect_answers"][0]
    });

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SecondRoute(
              googleSignIn: googleSignIn, selectedTeam: selectedTeam)),
    );

    setState(() {
      selectedTeam = !selectedTeam;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Easy quiz-app game!",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          Container(
            margin: EdgeInsets.only(top: 20),
            child: ElevatedButton(
                onPressed: () {
                  googleLogin();
                },
                child: Text("Log-in and play!")),
          ),
        ],
      )),
    );
  }
}
