import 'package:agora_rtc_engine/rtc_channel.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_audio_call/homepage.dart';
import 'package:video_audio_call/select_friends.dart';
import 'package:video_audio_call/variable.dart';

import 'moodel.dart';

class SelectId extends StatefulWidget {
  const SelectId({Key? key}) : super(key: key);

  @override
  _SelectIdState createState() => _SelectIdState();
}

class _SelectIdState extends State<SelectId> {

  final db = FirebaseFirestore.instance;


    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text('Select Id'),),
        body: StreamBuilder<QuerySnapshot>(
          stream: db.collection('id').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  return Card(
                    child: ListTile(
                      title: Text(doc["name"]),
                      onTap: (){
                        Variable.userId = doc["name"];
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>SelectFriend(doc["name"],doc["channel"],doc["token"])),);
                      },
                    ),
                  );
                }).toList(),
              );
            }
          },
        ),
      );
    }
  }


