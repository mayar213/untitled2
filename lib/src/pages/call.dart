import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_local_remote;
import 'package:untitled2/src/utils/settings.dart';
class CallPage extends StatefulWidget {
  final String? channelName;
  final ClientRole? role;

  const CallPage({Key? key,
  this.channelName,
    this.role
  }) : super(key: key);
  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  bool viewPanel = false;
  RtcEngine? _engine;

  @override
  void intState(){
    super.initState();
    initialize();
  }
  @override
  void dispose(){
    _users.clear();
    _engine!.leaveChannel();
    _engine!.destroy();
    super.dispose();

  }
  Future<void> initialize() async{
    if(appId.isEmpty) {
     setState(() {
       _infoStrings.add('APP_ID missing, please provide your App_ID in setting.dart',);
       _infoStrings.add('Agora Engine is not starting',);
     });
     return;
    }
    // _initAgoraRtcEngine
_engine = await RtcEngine.create(appId);
    await _engine!.enableVideo();
    await _engine!.setChannelProfile(ChannelProfile.LiveBroadcasting);
    // addAgoraEventHandlers
    _addAgoraEventHandlers();
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    configuration.dimensions= const VideoDimensions(width: 1920, height: 1080);
    await _engine!.setVideoEncoderConfiguration(configuration);
    await _engine!.joinChannel(token, widget.channelName!, null, 0);
  }
  void _addAgoraEventHandlers(){
    _engine!.setEventHandler(RtcEngineEventHandler(error: (code){
      setState(() {
        final info = 'Error: $code';
        _infoStrings.add(info);

      });
    },
    joinChannelSuccess: (channel, uid, elapsed){
      setState(() {
        final info = 'join Channel: $channel, uid: $uid';
        _infoStrings.add(info);
      });
    },
      leaveChannel: (stats) {
      setState(() {
        _infoStrings.add('leave channel');
        _users.clear();

      });
      },
      userJoined: (uid,elapsed){
      setState(() {
        final info= 'User joined : $uid';
        _infoStrings.add(info);
        _users.add(uid);
      });
      },
    userOffline: (uid, elapsed){
      setState(() {
        final info = 'User offline: $uid';
        _infoStrings.add(info);
        _users.remove(uid);
      });
    },
      firstRemoteVideoFrame: (uid, width, height,elapsed){
      setState(() {
        final info = 'First Remote Video: $uid ${width}x $height';
        _infoStrings.add(info);
      });
      }
    ));
  }
  Widget _viewRows(){
    final List<StatefulWidget> list = [];
    if (widget.role == ClientRole.Broadcaster){
      list.add( const rtc_local_view.SurfaceView());
    }
   for (var uid in _users) {
  list.add(rtc_local_remote.SurfaceView(
    uid: uid,
    channelId: widget.channelName!,
  ));
}
   final views =list;
   return Column(
     children: List.generate(
       views.length,
         (index)=> Expanded(child: views[index])
     ),
   );
  }
  Widget _toolbar(){
    if (widget.role == ClientRole.Audience) return const SizedBox();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical:48 ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(onPressed: (){
            setState(() {
              muted =!muted;
            });
            _engine!.muteLocalAudioStream(muted);
          },
            shape: const CircleBorder(),
            elevation: 2,
            fillColor: muted ? Colors.blueAccent: Colors.white ,
            padding: const EdgeInsets.all(12.0),
          child: Icon(
            muted ? Icons.mic_off : Icons.mic ,
            color: muted ? Colors.white : Colors.blueAccent,
            size: 20,
          ),
          ),
          RawMaterialButton(onPressed: () =>Navigator.pop(context),
            shape: const CircleBorder(),
            elevation: 2,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
            child: const Icon(
             Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),

          ),
          RawMaterialButton(onPressed: () {
            _engine!.switchCamera();
          },
            shape: const CircleBorder(),
            elevation: 2,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.blueAccent,
              size: 20.0,
            ),
          ),

        ],
      ),
    );
  }
  Widget _panel(){
    return Visibility(visible: viewPanel,
    child:Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(heightFactor: 0.5,
       child:Container(
         padding: const EdgeInsets.symmetric(vertical: 48),

           child: ListView.builder(
             reverse: true,
            itemCount: _infoStrings.length,
             itemBuilder: (BuildContext context,int index) {
               if (_infoStrings.isEmpty){
                 return const Text('null');
               }
               return  Padding(padding: const EdgeInsets.symmetric(
                 vertical: 3,
                 horizontal: 10,
               ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Container(
                      padding:  const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 5,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Text(
                        _infoStrings[index],
                        style: const TextStyle(
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),)
                  ],
                ),
               );
             },
),
       ) ,
      ),
    ) ,
    );
  }
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title:const Text('Agora') ,
        centerTitle: true,
        actions: [
          IconButton(onPressed: (){
            setState(() {
              viewPanel = !viewPanel;
            });
          }, icon: const Icon(Icons.info_outline)),
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: <Widget>[
            _viewRows(),
            _panel(),
            _toolbar(),
          ],
        ),
      ),
    );
  }
}
