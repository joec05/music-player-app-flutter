import 'package:flutter/material.dart';
import 'package:music_player_app/global_files.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:audio_service/audio_service.dart';

class MainPageController {
  final BuildContext context;
  ValueNotifier<int> selectedIndexValue = ValueNotifier(0);
  final PageController pageController = PageController(initialPage: 0, keepPage: true);
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  ValueNotifier<bool> isLoaded = ValueNotifier(false);
  ValueNotifier<List<Widget>> widgetOptions = ValueNotifier(<Widget>[]);
  ValueNotifier<LoadType> loadType = ValueNotifier(LoadType.initial);

  MainPageController(
    this.context
  );

  bool get mounted => context.mounted;

  void initializeController(){
    initializeDefaultStartingDisplayImage();
    initializeAudioService();
    appStateRepo.audioHandler.addListener(() {
      if(appStateRepo.audioHandler.value != null) {
        widgetOptions.value = [
          AllSongsPageWidget(setLoadingState: setLoadingState), const SortedArtistsPageWidget(), const SortedAlbumsPageWidget(), const PlaylistPageWidget()
        ];
      }
    });
  }

  void dispose(){
    selectedIndexValue.dispose();
    pageController.dispose();
    isLoaded.dispose();
    loadType.dispose();
  }

  Future<void> initializeAudioService() async{
    if(appStateRepo.audioHandler.value == null){
      MyAudioHandler audioHandler = await AudioService.init(
        builder: () => MyAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.example.music_player_app',
          androidNotificationChannelName: 'Music playback',
        ),
      );
      audioHandler.initializeController();
      appStateRepo.audioHandler.value = audioHandler;
    }
  }

  void setLoadingState(bool state, LoadType loadingType){
    if(mounted){
      isLoaded.value = state;
      loadType.value = loadingType;
    }
  }

  void onPageChanged(newIndex){
    if(mounted){
      if(isLoaded.value){
        selectedIndexValue.value = newIndex;
      }
    }
  }

  Future<void> initializeDefaultStartingDisplayImage() async{
    ByteData byteData = await rootBundle.load('assets/images/music-icon.png');
    final tempFile = File('${(await getTemporaryDirectory()).path}/music-icon.png');
    final file = await tempFile.writeAsBytes(
      byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes)
    );
    final ImageDataClass audioImageDataClass = ImageDataClass(
      file.path, byteData.buffer.asUint8List()
    );
    if(mounted){
      appStateRepo.audioImageData = audioImageDataClass;
    }
  }

  PreferredSizeWidget setAppBar(index){
    if(index == 0){
      return AppBar(
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        ),
        title: const Text('All Music'), titleSpacing: defaultAppBarTitleSpacingWithoutBackBtn,
      );
    }else if(index == 1){
      return AppBar(
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        ),
        title: const Text('Artists'), titleSpacing: defaultAppBarTitleSpacingWithoutBackBtn,
      );
    }else if(index == 2){
      return AppBar(
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        ),
        title: const Text('Albums'), titleSpacing: defaultAppBarTitleSpacingWithoutBackBtn,
      );
    }else if(index == 3){
      return AppBar(
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        ),
        title: const Text('Playlists'), titleSpacing: defaultAppBarTitleSpacingWithoutBackBtn,
      );
    }
    return AppBar();
  }
}