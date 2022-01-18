import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:video_audio_call/settings.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:video_audio_call/variable.dart';
import 'package:proximity_sensor/proximity_sensor.dart';




class CallingScreen extends StatefulWidget {
  final String? channelName;

  /// non-modifiable client role of the page
  final ClientRole? role;


  CallingScreen(this.channelName, this.role);

  @override
  _CallingScreenState createState() => _CallingScreenState(channelName,role);
}

class _CallingScreenState extends State<CallingScreen> {



  late StreamSubscription<dynamic> _streamSubscription;

  final db = FirebaseFirestore.instance;

  final String? channelName;

  //swipe camera
   bool swipeView = false;



  /// non-modifiable client role of the page
  final ClientRole? role;

  _CallingScreenState(this.channelName, this.role);
  //to mute or unmute microphone
  bool openMicrophone = true;
//to change between earphone and speaker
  bool enableSpeakerphone = true;
  //sensor which make screen black
  bool _isNear = false;
  // calling status that can be connected,disconnected
  static String callingStatus = '';



  bool _enableInEarMonitoring = false;
  double _recordingVolume = 0, _playbackVolume = 0, _inEarMonitoringVolume = 0;
  // number of users joined the call
  final _users = <int>[];
  // info string to get the status code
  final _infoStrings = <String>[];
  bool muted = false;
  bool videoOff =false;
  late RtcEngine _engine;
  Future<void> listenSensor() async {
    FlutterError.onError = (FlutterErrorDetails details) {

      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }

    };

    _streamSubscription = ProximitySensor.events.listen((int event) {
      setState(() {

        _isNear = (event > 0) ? true : false;
        print(_isNear);



      });

    });
  }


  @override
  void dispose() {
    // clear users
    _users.clear();
    // destroy sdk
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
    _streamSubscription.cancel();
  }

  @override
  void initState() {
    super.initState();
    // initialize agora sdk
    initialize();
    listenSensor();
  }

  _switchMicrophone() {
    _engine.enableLocalAudio(!openMicrophone).then((value) {
      setState(() {
        openMicrophone = !openMicrophone;
      });
    }).catchError((err) {
      log('enableLocalAudio $err');
    });
  }

  _switchSpeakerphone() {
    _engine.setEnableSpeakerphone(!enableSpeakerphone).then((value) {
      setState(() {
        enableSpeakerphone = !enableSpeakerphone;
      });
    }).catchError((err) {
      log('setEnableSpeakerphone $err');
    });
  }

  _onChangeInEarMonitoringVolume(double value) {
    setState(() {
      _inEarMonitoringVolume = value;
    });
    _engine.setInEarMonitoringVolume(value.toInt());
  }

  _toggleInEarMonitoring(value) {
    setState(() {
      _enableInEarMonitoring = value;
    });
    _engine.enableInEarMonitoring(value);
  }


  Future<void> initialize() async {
    if (APP_ID.isEmpty) {
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }

    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    await _engine.enableWebSdkInteroperability(true);
    //VideoEncoderConfiguration for video configaration
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    // configuration.dimensions for video quality
    configuration.dimensions = VideoDimensions(width: 1280 , height: 720);
    //to set framerate
    configuration.frameRate = VideoFrameRate.Fps30;
    configuration.minFrameRate = VideoFrameRate.Fps15;
    //to set bitrate
    configuration.bitrate = 3420;
    //orientationMode can be potrait or landscape or adaptative(both)
    configuration.orientationMode = VideoOutputOrientationMode.Adaptative;
    //to set audio profile for more information https://docs.agora.io/en/Video/audio_profile_android?platform=Android
    await _engine.setAudioProfile(AudioProfile.MusicHighQualityStereo, AudioScenario.ChatRoomEntertainment);
    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(Variable.token, Variable.channelName, null, 0);
  }

  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.create(APP_ID);
    //logic for video call audio call
    Variable.videoCall==true?await _engine.enableVideo(): await _engine.enableAudio();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(widget.role!);
    //logic for video call audio call
    if(Variable.videoCall==false){
      _engine.setEnableSpeakerphone(false);
      enableSpeakerphone = false;

    }
  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(error: (code) {
      setState(() {
        final info = 'onError: $code';
        _infoStrings.add(info);
      });
    }, joinChannelSuccess: (channel, uid, elapsed) {
      setState(() {
        final info = 'onJoinChannel: $channel, uid: $uid';
        callingStatus = 'Ringing';
        _infoStrings.add(info);
      });
    },

      leaveChannel: (stats) {
      setState(() {

        _infoStrings.add('onLeaveChannel');
        _users.clear();
      });
    }, userJoined: (uid, elapsed) {
      setState(() {
        final info = 'userJoined: $uid';
        callingStatus = 'Connected';
        _infoStrings.add(info);
        _users.add(uid);
      });
    }, userOffline: (uid, elapsed) {
      setState(() {
        final info = 'userOffline: $uid';
        callingStatus = 'Disconnected';
        _infoStrings.add(info);
        _users.remove(uid);
      });
    }, firstRemoteVideoFrame: (uid, width, height, elapsed) {
      setState(() {
        final info = 'firstRemoteVideo: $uid ${width}x $height';
        _infoStrings.add(info);
      },);
    },),);
  }
//call end
  void _onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }
//mete
  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }
  void _onVideoOff(){

    setState(() {
      videoOff = !videoOff;
    });

    _engine.muteLocalVideoStream(videoOff);

  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }
  //video call viewa
  Widget _viewRows() {
    final views = _getRenderViews();
    switch (views.length) {
      //one user
      case 1:
        return GestureDetector(
          onTap: (){setState(() {
            Variable.hideBottomBar=!Variable.hideBottomBar;
          });},
          child: Container(
              child: Column(
                children: <Widget>[_videoView(views[0])],
              ),),
        );
        //two users
      case 2:
        return Container(
            child: Stack(
              children: [
                 GestureDetector(child: _expandedVideoRow([views[1]])!=null?_expandedVideoRow([views[swipeView == false?1:0]]):Container(),
                 onTap: (){
                   setState(() {
                     Variable.hideBottomBar=!Variable.hideBottomBar;
                   });
                 },

                 ),
               //audio video swich logic
               videoOff==false? Expanded(

                  child: Container(
                    height: double.infinity,
                    width:double.infinity,
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: (){
                        setState(() {
                          swipeView=!swipeView;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: MediaQuery.of(context).size.height*0.005,top: MediaQuery.of(context).size.height*0.005 ),
                        height: MediaQuery.of(context).size.height*0.2,
                        width: MediaQuery.of(context).size.width*0.255,
                        child: ClipRRect(

                            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.height*0.01),
                            //swipe local video and remote video
                            child: _expandedVideoRow([views[ swipeView == false? 0:1]])),
                      ),
                    ),
                  ),
                ):Container()

              ],
            ),);
      case 3:
        return Container(
            child: Column(
              children: <Widget>[
                _expandedVideoRow(views.sublist(0, 2)),
                _expandedVideoRow(views.sublist(2, 3))
              ],
            ));
      case 4:
        return Container(
            child: Column(
              children: <Widget>[
                _expandedVideoRow(views.sublist(0, 2)),
                _expandedVideoRow(views.sublist(2, 4))
              ],
            ),);
      default:
    }
    return Container();
  }
  // panel is for status
  Widget _panel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: ListView.builder(
            reverse: true,
            itemCount: _infoStrings.length,
            itemBuilder: (BuildContext context, int index) {
              if (_infoStrings.isEmpty) {
                return Text("null");  // return type can't be null, a widget was required
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.yellowAccent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _infoStrings[index],
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  // for each video view
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    if (widget.role == ClientRole.Broadcaster) {
      list.add(RtcLocalView.SurfaceView(),);
    }
    _users.forEach((int uid) => list.add(RtcRemoteView.SurfaceView(uid: uid,)));
    return list;
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
  }

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map<Widget>(_videoView).toList();

    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  // sensor logic to make screen black
  ScreenBlannk(){
    if(_isNear ==true && Variable.videoCall==false){
      return true;
    }else{
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return   ScreenBlannk() ==false  ? SafeArea(
      child:Scaffold(

        body:  Container(
          color: Colors.black,
          child: Stack(
            children: [
              Container(
                child: Stack(
                  children: [
                    //video views
                    _viewRows(),
                    // _panel(),
                    Container(
                      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height*0.14),

                      alignment: Alignment.bottomCenter,
                      child: Text(callingStatus,style: TextStyle(
                        fontSize: 25,
                        color: Colors.white
                      ),),),



                  ],
                ),
              ),
              Variable.hideBottomBar == false? SizedBox(
                width: double.infinity,
                ///for bottom ui

                child: SlidingUpPanel(
                  backdropColor: Colors.black.withOpacity(0.5),
                  backdropEnabled: true,
                  color: Colors.transparent,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(MediaQuery.of(context).size.height*0.04),topLeft: Radius.circular(MediaQuery.of(context).size.height*0.04)),
                  panel: Center(child: Text("This is the sliding Widget"),),
                  header: ClipRRect(
                    
                    borderRadius: BorderRadius.only(topRight: Radius.circular(MediaQuery.of(context).size.height*0.04),topLeft: Radius.circular(MediaQuery.of(context).size.height*0.04)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10,
                        sigmaY: 10
                      ),
                      child: Container(
                        width: MediaQuery.of(context).size.width,

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(topRight: Radius.circular(MediaQuery.of(context).size.height*0.04),topLeft: Radius.circular(MediaQuery.of(context).size.height*0.04)),
                          color: Colors.white.withOpacity(0.1)
                        ),

                        height: MediaQuery.of(context).size.height*0.13,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Variable.videoCall == true?
                            MaterialButton(
                              onPressed: () {
                                setState(() {

                                  /// swiching camera
                                  _onSwitchCamera();


                                });

                              },
                              color: Colors.white.withOpacity(0.1),
                              textColor: Colors.white,
                              child: Icon(
                                Icons.cameraswitch_outlined,
                                size: 30,
                              ),
                              padding: EdgeInsets.all(16),
                              shape: CircleBorder(),
                            ):
                            MaterialButton(
                              onPressed: () {
                                setState(() {

                                  _switchSpeakerphone();

                                });

                              },

                              color: enableSpeakerphone==true?Colors.blue:Colors.white.withOpacity(0.1),
                              textColor: Colors.white,

                              child: Icon(
                                Icons.volume_up_outlined,
                                size: 30,

                              ),
                              padding: EdgeInsets.all(16),
                              shape: CircleBorder(),
                            ),
                            MaterialButton(
                              onPressed: () {
                                setState(() {
                                  ///swich video call to audio call


                                  Variable.videoCall=!Variable.videoCall;
                                  if(Variable.videoCall==true){
                                    _engine.enableVideo();
                                    enableSpeakerphone = false;
                                    _switchSpeakerphone();

                                  }else{
                                    _engine.disableVideo();
                                  }
                                });
                              },
                              color: Colors.white.withOpacity(0.1),
                              textColor: Colors.white,
                              child: Icon(
                                Variable.videoCall == true? Icons.videocam_off_outlined:Icons.videocam_outlined,
                                size: 30,
                              ),
                              padding: EdgeInsets.all(16),
                              shape: CircleBorder(),
                            ),
                            MaterialButton(
                              onPressed: () {
                                setState(() {
                                  _onToggleMute();
                                });
                              },
                              color: Colors.white.withOpacity(0.1),
                              textColor: Colors.white,
                              child: Icon(
                                muted ? Icons.mic_off : Icons.mic,
                                size: 30,
                              ),
                              padding: EdgeInsets.all(16),
                              shape: CircleBorder(),
                            ),
                      MaterialButton(
                        onPressed: () {

                          ///end call

                          _onCallEnd(context);
                          setState(() {
                            var data = {
                              "name": Variable.userId,
                              'channel': '',
                              'token': ''
                            };
                            var dat = {
                              "name": Variable.callingId,
                              'channel': '',
                              'token': ''
                            };
                            db.collection('id').doc(Variable.userId).set(data);
                            db.collection('id').doc(Variable.callingId).set(dat);

                          });
                        },
                        color: Colors.red,
                        textColor: Colors.white,
                        child: Icon(
                          Icons.call_end_outlined,
                          size: 30,
                        ),
                        padding: EdgeInsets.all(16),
                        shape: CircleBorder(),
                      ),
                          ],),
                      ),
                    ),
                  ),
                ),
              ):SizedBox()
            ],

          )
        ),
      )
    ):Container();
  }
}
// Column(
// children: <Widget>[
// _expandedVideoRow([views[0]]),
// _expandedVideoRow([views[1]])
// ],
// )