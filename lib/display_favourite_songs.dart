import 'dart:async';
import 'package:flutter/material.dart';
import 'package:music_player_app/appdata/global_functions.dart';
import 'package:music_player_app/class/audio_complete_data_notifier.dart';
import 'package:music_player_app/custom/custom_audio_player.dart';
import 'package:music_player_app/custom/custom_currently_playing_bottom_widget.dart';
import 'package:music_player_app/state/main.dart';
import 'package:music_player_app/streams/update_favourite_stream_class.dart';
import 'package:music_player_app/styles/app_styles.dart';

class DisplayFavouritesClassWidget extends StatelessWidget {
  const DisplayFavouritesClassWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DisplayFavouritesClassWidgetStateful();
  }
}

class _DisplayFavouritesClassWidgetStateful extends StatefulWidget {
  const _DisplayFavouritesClassWidgetStateful();

  @override
  State<_DisplayFavouritesClassWidgetStateful> createState() => _DisplayFavouritesClassWidgetState();
}

class _DisplayFavouritesClassWidgetState extends State<_DisplayFavouritesClassWidgetStateful> {
  List<String> favouriteSongsData = appStateClass.favouritesList;
  late StreamSubscription updateFavouriteStreamClassSubscription;

  @override
  void initState(){
    super.initState();
    updateFavouriteStreamClassSubscription = UpdateFavouriteStreamClass().updateFavouriteStream.listen((UpdateFavouriteStreamControllerClass data) {
      favouriteSongsData = data.favouritesList;
      setState((){});
    });
  }

  @override
  void dispose(){
    super.dispose();
    updateFavouriteStreamClassSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, AudioCompleteDataNotifier> audiosListNotifiers = fetchReduxDatabase().allAudiosList;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        ),
        title: const Text('Favourites'), titleSpacing: defaultAppBarTitleSpacingWithBackBtn,
      ),
      body: Center(
        child: ListView.builder(
          shrinkWrap: false,
          key: UniqueKey(),
          scrollDirection: Axis.vertical,
          primary: false,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: favouriteSongsData.length,
          itemBuilder: (context, index){
            if(audiosListNotifiers[favouriteSongsData[index]] == null){
              return Container();
            }
            return ValueListenableBuilder(
              valueListenable: audiosListNotifiers[favouriteSongsData[index]]!.notifier, 
              builder: (context, audioCompleteData, child){
                return CustomAudioPlayerWidget(
                  audioCompleteData: audioCompleteData,
                  key: UniqueKey(),
                  directorySongsList: favouriteSongsData,
                  playlistSongsData: null
                );
              }
            );
          }
        )
      ),
      bottomNavigationBar: CustomCurrentlyPlayingBottomWidget(key: UniqueKey()),
    );
  }
}


