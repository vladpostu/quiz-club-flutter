// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, prefer_const_constructors_in_immutables, must_call_super, must_be_immutable

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';

class SecondRoute extends StatefulWidget {
  bool selectedTeam;
  GoogleSignIn googleSignIn;

  SecondRoute(
      {Key? key, required this.selectedTeam, required this.googleSignIn})
      : super(key: key);

  @override
  State<SecondRoute> createState() => _SecondRouteState();
}

class _SecondRouteState extends State<SecondRoute> {
  final user = FirebaseAuth.instance.currentUser;
  int index = 1;
  int points = 0;

  Future googleLogout() async {
    try {
      var response = await Dio().get('http://10.0.2.2:3000/users/');
      await Dio().delete("http://10.0.2.2:3000/users/" +
          response.data[response.data.length - 1]["id"].toString());
    } catch (e) {}

    await widget.googleSignIn.disconnect();

    Navigator.pop(context);
  }

  void fetchData() async {
    try {
      var response =
          await Dio().get('https://opentdb.com/api.php?amount=1&type=boolean');

      await Dio().post("http://10.0.2.2:3000/current_questions/", data: {
        "question": response.data["results"][0]["question"],
        "correct_answer": response.data["results"][0]["correct_answer"],
        "incorrect_answer": response.data["results"][0]["incorrect_answers"][0]
      });
    } catch (e) {}
  }

  Future retriveQuestion(int index) async {
    try {
      var response = await Dio()
          .get('http://10.0.2.2:3000/current_questions/' + index.toString());

      return response.data["question"].toString();
    } catch (e) {
      return "Blue is a color?";
    }
  }

  Future retriveCorrectAnswer(int index) async {
    try {
      var response = await Dio()
          .get('http://10.0.2.2:3000/current_questions/' + index.toString());

      return response.data["correct_answer"].toString();
    } catch (e) {
      return "True";
    }
  }

  Future retriveIncorrectAnswer(int index) async {
    try {
      var response = await Dio()
          .get('http://10.0.2.2:3000/current_questions/' + index.toString());

      return response.data["incorrect_answer"].toString();
    } catch (e) {
      return "False";
    }
  }

  Future getFirstPoints() async {
    var response = await Dio().get("http://10.0.2.2:3000/teams/1");

    return response.data["points"].toString();
  }

  Future getSecondsPoints() async {
    var response = await Dio().get("http://10.0.2.2:3000/teams/2");

    return response.data["points"].toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logged as " + user!.displayName!),
        actions: [
          GestureDetector(
            child: Icon(Icons.logout),
            onTap: () {
              googleLogout();
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(15),
              child: Text("You are in the " +
                  (widget.selectedTeam == true ? "Second" : "First") +
                  " Team"),
            ),
            FutureBuilder(
              future: retriveQuestion(index),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Container(
                    child: Text(
                      snapshot.data.toString(),
                      style: TextStyle(fontSize: 20),
                    ),
                    width: 350,
                  );
                } else {
                  return Text("error");
                }
              },
            ),
            FutureBuilder(
              future: retriveCorrectAnswer(index),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Container(
                    margin: EdgeInsets.only(top: 30),
                    child: ElevatedButton(
                        onPressed: () async {
                          fetchData();
                          setState(() {
                            points++;
                            if (index < 11) index++;
                          });
                        },
                        child:
                            Container(child: Text(snapshot.data.toString()))),
                  );
                } else {
                  return Text("error");
                }
              },
            ),
            FutureBuilder(
              future: retriveIncorrectAnswer(index),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ElevatedButton(
                      onPressed: () async {
                        fetchData();
                        setState(() {
                          if (index < 11) index++;
                        });
                      },
                      child: Text(snapshot.data.toString()));
                } else {
                  return Text("error");
                }
              },
            ),
            Container(
              margin: EdgeInsets.only(top: 30),
              child: ElevatedButton(
                  onPressed: () async {
                    if (widget.selectedTeam == true) {
                      var prevPoints =
                          await Dio().get("http://10.0.2.2:3000/teams/2");
                      await Dio().put("http://10.0.2.2:3000/teams/2", data: {
                        "id": 2,
                        "name": "Second Team",
                        "points":
                            (int.parse(prevPoints.data["points"].toString()) +
                                points)
                      });
                    } else {
                      var prevPoints =
                          await Dio().get("http://10.0.2.2:3000/teams/1");
                      try {
                        await Dio().put("http://10.0.2.2:3000/teams/", data: {
                          "id": 1,
                          "name": "First Team",
                          "points":
                              int.parse(prevPoints.data["points"].toString()) +
                                  points
                        });
                      } catch (e) {}
                    }

                    int deleteIndex = 1;
                    while (true) {
                      try {
                        await Dio().delete(
                          "http://10.0.2.2:3000/current_questions/" +
                              deleteIndex.toString(),
                        );
                        deleteIndex++;
                      } catch (e) {
                        break;
                      }
                    }
                  },
                  child: Text("Finish Quiz")),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Text(
                "You have " + points.toString() + " points",
                style: TextStyle(fontSize: 25),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 50),
              child: FutureBuilder(
                future: getFirstPoints(),
                builder: (context, snapshot) {
                  return Text("First Team points: " + snapshot.data.toString());
                },
              ),
            ),
            FutureBuilder(
              future: getSecondsPoints(),
              builder: (context, snapshot) {
                return Text("Second Team points: " + snapshot.data.toString());
              },
            )
          ],
        ),
      ),
    );
  }
}
