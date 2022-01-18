import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:video_audio_call/calling_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:video_audio_call/settings.dart';
import 'package:video_audio_call/variable.dart';



class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);



  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {



  final db = FirebaseFirestore.instance;



  bool _validateError = false;
// _channelController is a false data
  String _channelController = 'ssss';
// generate random string for channel name
  String generateRandomString() {
    int length = 50;
    final _random = Random();
    const _availableChars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final randomString = List.generate(length,
            (index) => _availableChars[_random.nextInt(_availableChars.length)])
        .join();

    return randomString;
  }



// to get permission of camera and microphone
  Future<void> _handleCameraAndMic(Permission permission) async {



    final status = await permission.request();
    print(status);
  }
// to get a token from local golang token server
  getToken(String channelName) async{
    final response = await http
        .get(Uri.parse('http://192.168.1.79:7800/rtc/$channelName/publisher/uid/0/'),);

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      var v = jsonDecode(response.body)['rtcToken'];
      return v;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }


  }






  Future<void> onJoin() async {
    // var x is the channel name
    var x = generateRandomString();
    // creating a channel by the token server
    var token = await getToken(x);
    // update input validation
    setState(() {


      Variable.token=token;
      Variable.channelName= x;
      // firebase local data changing
      var data = {
        "name": Variable.callingId,
        'channel': x,
        'token': token
      };
      db.collection('id').doc(Variable.callingId).set(data);
      _channelController.isEmpty
          ? _validateError = true
          : _validateError = false;
    });
    if (_channelController.isNotEmpty) {
      await _handleCameraAndMic(Permission.camera);
      await _handleCameraAndMic(Permission.microphone);
      // await for camera and mic permissions before pushing video page

      // push video page with given channel name
      await Navigator.push(
        context,
        MaterialPageRoute(
          //ClientRole.broadcaster for one to one calling or group call
          //ClientRole.Audience is for zoom meeting type call
            builder: (context) => CallingScreen(_channelController,ClientRole.Broadcaster)
        ),
      );
    }
  }




  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('Video Audio Call'),),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlatButton(
                color: Colors.black.withOpacity(0.2),
                child: const Text('Video Call', style: TextStyle(fontSize: 20.0),),
                onPressed: onJoin
            ),
            const SizedBox(width: 5,),
            FlatButton(
              color: Colors.black.withOpacity(0.2),
              child: const Text('Audio Call', style: TextStyle(fontSize: 20.0),),
              onPressed: ()  {
                Variable.videoCall= false;
                onJoin();
              },
            ),
          ],
        ),
      ),
    );
  }
}