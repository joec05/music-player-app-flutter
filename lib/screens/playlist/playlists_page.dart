import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:music_player_app/global_files.dart';

class PlaylistPageWidget extends StatelessWidget {
  const PlaylistPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaylistPageWidgetStateful();
  }
}

class _PlaylistPageWidgetStateful extends StatefulWidget {
  const _PlaylistPageWidgetStateful();

  @override
  State<_PlaylistPageWidgetStateful> createState() => _PlaylistPageWidgetState();
}

class _PlaylistPageWidgetState extends State<_PlaylistPageWidgetStateful> with AutomaticKeepAliveClientMixin{
  late PlaylistsController controller;

  @override
  void initState(){
    super.initState();
    controller = PlaylistsController(context);
    controller.initializeController();
  }

  @override void dispose(){
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Center(
        child: Obx (() {
          List<PlaylistSongsModel> playlistsSongsList = controller.playlistsSongsList;

          if(playlistsSongsList.isEmpty) {
            return noItemsWidget(FontAwesomeIcons.list, 'playlists');
          }
          return ListView.builder(
            shrinkWrap: false,
            scrollDirection: Axis.vertical,
            primary: false,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: playlistsSongsList.length,
            itemBuilder: (context, index){
              return Obx(() {
                return CustomPlaylistDisplayWidget(
                  playlistSongsData: playlistsSongsList[index], 
                  key: UniqueKey()
                );
              });
            }
          );
        })
      ),
      bottomNavigationBar: CustomCurrentlyPlayingBottomWidget(key: UniqueKey()),
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}


