import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:music_player_app/global_files.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';

class AllSongsController {
  final BuildContext context;
  final Function(bool, LoadType) setLoadingState;
  ValueNotifier<List<String>> audioUrls = ValueNotifier([]);

  AllSongsController(
    this.context,
    this.setLoadingState
  );

  bool get mounted => context.mounted;

  void initializeController() {
    fetchLocalSongs(LoadType.initial);
  }

  void dispose(){}

  void fetchLocalSongs(LoadType loadType) async{
    bool permissionIsGranted = false;
    ph.Permission? permission;
    if(Platform.isAndroid){
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if(androidInfo.version.sdkInt <= 32) {
        permission = ph.Permission.storage;
      } else {
        permission = ph.Permission.photos;
      }
    } else if (Platform.isIOS) {
      permission = ph.Permission.photos;
    }
    permissionIsGranted = await permission!.isGranted;
    if(!permissionIsGranted){
      await permission.request();
      permissionIsGranted = await permission.isGranted;
    }
    if(permissionIsGranted){
      await initializeAudioService().then((value) async{
        Directory dir = Directory(defaultDirectory);
        List<FileSystemEntity> directoryList = await dir.list().toList();
        directoryList.removeWhere((e) => e.path == restrictedDirectory);
        List<FileSystemEntity> songsList = [];

        for(var dir in directoryList){
          if(dir is Directory) {
            try {
              songsList.addAll(await dir.list(recursive: true).where((e) => e.path.endsWith('.mp3')).toList());
            } catch (e) {
              if(mounted) {
                handler.displaySnackbar(
                  context, 
                  SnackbarType.error, 
                  e.toString()
                );
              }
            }
          }  
        }
        final Map<String, AudioCompleteDataNotifier> filesCompleteDataList = {};
        final Map<String, AudioListenCountNotifier> localListenCountData = await LocalDatabase().fetchAudioListenCountData();
        Map<String, AudioListenCountNotifier> getListenCountData = {};
        List<String> songUrlsList = [];
        
        for(int i = 0; i < songsList.length; i++){
          String path = songsList[i].path;
          if(await File(path).exists()){
            var metadata = await ffmpegController.fetchAudioMetadata(path);
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
          audioUrls.value = [...songUrlsList];
          appStateRepo.allAudiosList = filesCompleteDataList;
          appStateRepo.audioListenCount = getListenCountData;
          appStateRepo.setFavouritesList(await LocalDatabase().fetchAudioFavouritesData());
          appStateRepo.setPlaylistList('', await LocalDatabase().fetchAudioPlaylistsData());
        }
      });   
    }
    Future.delayed(const Duration(milliseconds: 1500), (){
      setLoadingState(true, loadType);
    });
  }

  Future<void> initializeAudioService() async{
    if(appStateRepo.audioHandler == null){
      MyAudioHandler audioHandler = await AudioService.init(
        builder: () => MyAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.example.music_player_app',
          androidNotificationChannelName: 'Music playback',
        ),
      );
      audioHandler.initializeController();
      if(mounted){
        appStateRepo.audioHandler = audioHandler;
      }
    }
  }

  void scan() async{
    if(mounted){
      await appStateRepo.audioHandler!.stop().then((value){
        setLoadingState(false, LoadType.scan);
        runDelay(() async{
          await LocalDatabase().replaceAudioFavouritesData(appStateRepo.favouritesList).then((value) async{
            await LocalDatabase().replaceAudioPlaylistsData(appStateRepo.playlistList).then((value) async{
              await LocalDatabase().replaceAudioListenCountData(appStateRepo.audioListenCount).then((value) async{
                fetchLocalSongs(LoadType.scan);
              });
            });
          });
        }, actionDelayDuration);
      });
    }
  }
}