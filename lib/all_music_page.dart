import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:music_player_app/display_favourite_songs.dart';
import 'package:music_player_app/display_most_played_songs.dart';
import 'package:music_player_app/display_recently_added_songs.dart';
import 'package:music_player_app/appdata/global_library.dart';
import 'package:music_player_app/class/audio_complete_data_class.dart';
import 'package:music_player_app/class/audio_complete_data_notifier.dart';
import 'package:music_player_app/class/audio_listen_count_class.dart';
import 'package:music_player_app/class/audio_listen_count_notifier.dart';
import 'package:music_player_app/custom/custom_audio_player.dart';
import 'package:music_player_app/custom/custom_button.dart';
import 'package:music_player_app/custom/custom_currently_playing_bottom_widget.dart';
import 'package:music_player_app/redux/redux_library.dart';
import 'package:music_player_app/service/audio_handler.dart';
import 'package:music_player_app/sqflite/local_db_configuration.dart';
import 'package:music_player_app/state/main.dart';
import 'package:music_player_app/styles/app_styles.dart';
import 'package:music_player_app/transition/right_to_left_transition.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';

class AllMusicPageWidget extends StatelessWidget {
  final void Function(bool, LoadType) setLoadingState;
  const AllMusicPageWidget({super.key, required this.setLoadingState});

  @override
  Widget build(BuildContext context) {
    return _AllMusicPageWidgetStateful(setLoadingState: setLoadingState);
  }
}

class _AllMusicPageWidgetStateful extends StatefulWidget {
  final Function setLoadingState;
  const _AllMusicPageWidgetStateful({required this.setLoadingState});

  @override
  State<_AllMusicPageWidgetStateful> createState() => _AllMusicPageWidgetState();
}

class _AllMusicPageWidgetState extends State<_AllMusicPageWidgetStateful> with AutomaticKeepAliveClientMixin{
  List<String> audioUrls = [];

  @override
  void initState(){
    super.initState();
    fetchLocalSongs(LoadType.initial);
  }

  @override void dispose(){
    super.dispose();
  }
  
  void fetchLocalSongs(LoadType loadType) async{
    bool permissionIsGranted = false;
    ph.Permission? permission;
    if(Platform.isAndroid){
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if(androidInfo.version.sdkInt <= 32){
        permission = ph.Permission.storage;
      }else{
        permission = ph.Permission.audio;
      }
    }
    permissionIsGranted = await permission!.isGranted;
    if(!permissionIsGranted){
      await permission.request();
      permissionIsGranted = await permission.isGranted;
    }
    if(permissionIsGranted){
      await initializeAudioService().then((value) async{
        Directory dir = Directory(defaultDirectory);
        List<String> songsList =  dir.listSync(recursive: true, followLinks: false).map((e) => e.path).where((e) => e.endsWith('.mp3')).toList();
        final Map<String, AudioCompleteDataNotifier> filesCompleteDataList = {};
        final Map<String, AudioListenCountNotifier> localListenCountData = await LocalDatabase().fetchAudioListenCountData();
        Map<String, AudioListenCountNotifier> getListenCountData = {};
        List<String> songUrlsList = [];
        
        for(int i = 0; i < songsList.length; i++){
          String path = songsList[i];
          if(await File(path).exists()){
            var metadata = await fetchAudioMetadata(path);
            if(metadata != null){
              songUrlsList.add(path);
              filesCompleteDataList[path] = AudioCompleteDataNotifier(
                path, 
                ValueNotifier(
                  AudioCompleteDataClass(
                    path, metadata, AudioPlayerState.stopped, false
                  )
                ),
              );
              if(localListenCountData[path] != null){
                getListenCountData[path] = localListenCountData[path]!;
              }else{
                getListenCountData[path] = AudioListenCountNotifier(
                  path, ValueNotifier(AudioListenCountClass(path, 0))
                );
              }
            }
          }
        }
        
        if(mounted){
          audioUrls = songUrlsList;
          StoreProvider.of<AppState>(context).dispatch(AllAudiosList(filesCompleteDataList));
          appStateClass.audioListenCount = getListenCountData;
          appStateClass.setFavouritesList(await LocalDatabase().fetchAudioFavouritesData());
          appStateClass.setPlaylistList('', await LocalDatabase().fetchAudioPlaylistsData());
        }
        setState((){});
      });   
    }
    Future.delayed(const Duration(milliseconds: 1500), (){
      widget.setLoadingState(true, loadType);
    });
  }

  Future<void> initializeAudioService() async{
    if(appStateClass.audioHandler == null){
      MyAudioHandler audioHandler = await AudioService.init(
        builder: () => MyAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.example.music_player_app',
          androidNotificationChannelName: 'Music playback',
        ),
      );
      audioHandler.init();
      if(mounted){
        appStateClass.audioHandler = audioHandler;
      }
    }
  }

  void scan() async{
    if(mounted){
      await appStateClass.audioHandler!.stop().then((value){
        widget.setLoadingState(false, LoadType.scan);
        runDelay(() async{
          await LocalDatabase().replaceAudioFavouritesData(appStateClass.favouritesList).then((value) async{
            await LocalDatabase().replaceAudioPlaylistsData(appStateClass.playlistList).then((value) async{
              await LocalDatabase().replaceAudioListenCountData(appStateClass.audioListenCount).then((value) async{
                fetchLocalSongs(LoadType.scan);
              });
            });
          });
        }, actionDelayDuration);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: StoreConnector<AppState, Map<String, AudioCompleteDataNotifier>>(
        converter: (store) => store.state.allAudiosList,
        builder: (context, Map<String, AudioCompleteDataNotifier> audiosListNotifiers){
          return Center(
            child: ListView(
              shrinkWrap: false,
              key: UniqueKey(),
              scrollDirection: Axis.vertical,
              primary: false,
              physics: const AlwaysScrollableScrollPhysics(),
              children: <Widget>[
                Column(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding /2 , vertical: defaultVerticalPadding / 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CustomButton(
                                width: (getScreenWidth() - defaultHorizontalPadding) / 2 - defaultHorizontalPadding / 2, 
                                height: getScreenHeight() * 0.075, 
                                buttonColor: defaultCustomButtonColor, 
                                buttonText: 'Scan folder', 
                                onTapped: () => runDelay((){
                                  if(mounted){
                                    scan();
                                  }
                                }, navigationDelayDuration), 
                                setBorderRadius: true
                              ),
                              SizedBox(
                                width: defaultHorizontalPadding / 2
                              ),
                              CustomButton(
                                width: (getScreenWidth() - defaultHorizontalPadding) / 2 - defaultHorizontalPadding / 2, 
                                height: getScreenHeight() * 0.075, 
                                buttonColor: defaultCustomButtonColor, 
                                buttonText: 'Favourites', 
                                onTapped: () => runDelay((){
                                  if(mounted){
                                    Navigator.push(
                                      context,
                                      SliderRightToLeftRoute(
                                        page: const DisplayFavouritesClassWidget()
                                      )
                                    );
                                  }
                                }, navigationDelayDuration), 
                                setBorderRadius: true
                              ),
                            ],
                          ),
                          SizedBox(height: getScreenHeight() * 0.015),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CustomButton(
                                width: (getScreenWidth() - defaultHorizontalPadding) / 2 - defaultHorizontalPadding / 2, 
                                height: getScreenHeight() * 0.075, 
                                buttonColor: defaultCustomButtonColor, 
                                buttonText: 'Most played', 
                                onTapped: () => runDelay((){
                                  if(mounted){
                                    Navigator.push(
                                      context,
                                      SliderRightToLeftRoute(
                                        page: const DisplayMostPlayedClassWidget()
                                      )
                                    );
                                  }
                                }, navigationDelayDuration),
                                setBorderRadius: true
                              ),
                              SizedBox(
                                width: defaultHorizontalPadding / 2
                              ),
                              CustomButton(
                                width: (getScreenWidth() - defaultHorizontalPadding) / 2 - defaultHorizontalPadding / 2, 
                                height: getScreenHeight() * 0.075, 
                                buttonColor: defaultCustomButtonColor, 
                                buttonText: 'Recently added', 
                                onTapped: () => runDelay((){
                                  if(mounted){
                                    Navigator.push(
                                      context,
                                      SliderRightToLeftRoute(
                                        page: const DisplayRecentlyAddedClassWidget()
                                      )
                                    );
                                  }
                                }, navigationDelayDuration),
                                setBorderRadius: true
                              ),
                            ],
                          )
                        ]
                      )
                    )
                  ],
                ),
                SizedBox(height: getScreenHeight() * 0.0075),
                const Divider(color: Colors.grey, height: 3.5),
                SizedBox(height: getScreenHeight() * 0.0075),
                ListView.builder(
                  shrinkWrap: true,
                  key: UniqueKey(),
                  scrollDirection: Axis.vertical,
                  primary: false,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: audioUrls.length,
                  itemBuilder: (context, index){
                    if(audiosListNotifiers[audioUrls[index]] == null){
                      return Container();
                    }
                    return ValueListenableBuilder(
                      valueListenable: audiosListNotifiers[audioUrls[index]]!.notifier,
                      builder: (context, audioCompleteData, child){
                        return CustomAudioPlayerWidget(
                          audioCompleteData: audioCompleteData,
                          key: UniqueKey(),
                          directorySongsList: audioUrls,
                          playlistSongsData: null
                        );
                      }
                    );
                  }
                )
              ],
            )
          );
        }
      ),
      bottomNavigationBar: CustomCurrentlyPlayingBottomWidget(key: UniqueKey())
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}


