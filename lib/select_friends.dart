import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_audio_call/variable.dart';

import 'calling_screen.dart';
import 'homepage.dart';

class SelectFriend extends StatefulWidget {

 String name ;
 String channel;
 String token;


 SelectFriend(this.name,this.channel, this.token);



  @override
  _SelectFriendState createState() => _SelectFriendState(name,channel,token);
}

class _SelectFriendState extends State<SelectFriend> {
  String name;
  String channel;
  String token;

  _SelectFriendState(this.name,this.channel, this.token);

  final db = FirebaseFirestore.instance;
  bool _validateError = false;

  String _channelController = 'ssss';
  Future<void> _handleCameraAndMic(Permission permission) async {



    final status = await permission.request();
    print(status);
  }



  Future<void> onJoin() async {
    // update input validation
    setState(() {
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
            builder: (context) => CallingScreen(_channelController,ClientRole.Broadcaster)
        ),
      );
    }
  }
 @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if(token!=''&& channel!=''){
      Variable.token=token;
      Variable.channelName = channel;
      onJoin();

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Friend'),),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('id').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return ListView(
              
              children: snapshot.data!.docs.map((doc) {
                return  Card(
                  child: doc['name']!= name?ListTile(
                    title: Text(doc["name"]),
                    onTap: (){
                      Variable.callingId = doc['name'];

                      Navigator.push(context, MaterialPageRoute(builder: (context)=>MyHomePage(title: doc['name'],),),);
                    },
                  ):Container(),
                );
              }).toList(),
            );
          }
        },
      ),
    );
  }
}
