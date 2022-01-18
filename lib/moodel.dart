import 'package:cloud_firestore/cloud_firestore.dart';

class Model{
  String name;
  String token;
  String channel;

  Model({required this.name,required this.token,required this.channel});
  factory Model.fromDocumentSnapshot({required DocumentSnapshot<Map<String,dynamic>> doc}){
    return Model(
      name: doc.data()!["name"],
      token: doc.data()!["token"],
      channel: doc.data()!["channel"],
    );
  }
}