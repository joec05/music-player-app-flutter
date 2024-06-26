import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player_app/global_files.dart';
import 'package:rxdart/rxdart.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler {
  final audioPlayer = AudioPlayer();
  final currentSong = BehaviorSubject<AudioCompleteDataClass>();
  String currentAudioUrl = '';
  List<String> currentDirectoryAudioList = [];
  List<String> currentDirectoryAudioListShuffled = [];
  LoopStatus currentLoopStatus = LoopStatus.repeatCurrent;
  AudioPlayerState playerState = AudioPlayerState.stopped;

  void initializeController() {
    audioPlayer.playbackEventStream.listen(_broadcastState);
    audioPlayer.playerStateStream.listen((event) {
      if(event.processingState == ProcessingState.completed){
        startNextAfterFinishAudio();
      }else if(event.processingState == ProcessingState.ready){
        if(!event.playing){
          playerState = AudioPlayerState.paused;
          updateAudioPlayerState(playerState);
        }else{
          playerState = AudioPlayerState.playing;
          updateAudioPlayerState(playerState);
        }
      }
    });
  }

  void updateListDirectory(List<String> directory, List<String> directoryShuffled){
    currentDirectoryAudioList = directory.where((songID) => appStateRepo.allAudiosList[songID] != null).toList();
    currentDirectoryAudioListShuffled = directoryShuffled;
    List<MediaItem> mediaItemList = currentDirectoryAudioList.map((songID){
      AudioCompleteDataClass audioData = appStateRepo.allAudiosList[songID]!.notifier.value;
      AudioMetadataInfoClass metadata = audioData.audioMetadataInfo;
      return MediaItem(
        id: audioData.audioUrl,
        album: metadata.albumName,
        artist: metadata.artistName,
        title: metadata.title ?? audioData.audioUrl.split('/').last,
        artUri: Uri.file(appStateRepo.audioImageData!.path)
      );      
    }).toList();
    queue.add(mediaItemList);
  }
  
  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0) {
      await setCurrentSong(appStateRepo.allAudiosList[currentDirectoryAudioList[currentDirectoryAudioList.length - 1]]!.notifier.value);
    }else if(index >= queue.value.length){
      await setCurrentSong(appStateRepo.allAudiosList[currentDirectoryAudioList[0]]!.notifier.value);
    }else{
      await setCurrentSong(appStateRepo.allAudiosList[currentDirectoryAudioList[index]]!.notifier.value);
    }
  }

  Future<void> startNextAfterFinishAudio() async {
    if (currentLoopStatus == LoopStatus.repeatCurrent) {
      await setNewAudioSession(appStateRepo.allAudiosList[currentAudioUrl]!.notifier.value);
    }else if(currentLoopStatus == LoopStatus.repeatAll){
      playerState = AudioPlayerState.completed;
      updateAudioPlayerState(playerState);
      await skipToNext();
    }else{
      playerState = AudioPlayerState.completed;
      updateAudioPlayerState(playerState);
      await setCurrentSong(appStateRepo.allAudiosList[
        currentDirectoryAudioListShuffled[(currentDirectoryAudioListShuffled.indexOf(currentAudioUrl) + 1) % currentDirectoryAudioListShuffled.length]
      ]!.notifier.value);
    }
  }

  Future<void> setCurrentSong(AudioCompleteDataClass audioCompleteData) async{
    if(File(audioCompleteData.audioUrl).existsSync()) {
      if(audioCompleteData.audioUrl != currentAudioUrl){
        updateAudioPlayerState(AudioPlayerState.completed);
      }
      await setNewAudioSession(audioCompleteData);
      playerState = AudioPlayerState.playing;  
    }  
  }

  void addAudioListenCount(AudioCompleteDataClass audioCompleteData) async{
    if(File(audioCompleteData.audioUrl).existsSync()) {
      AudioListenCountModel listenCountData = appStateRepo.audioListenCount[audioCompleteData.audioUrl]!;
      AudioListenCountModel updatedListenCountData = AudioListenCountModel(listenCountData.audioUrl, listenCountData.listenCount + 1);
      appStateRepo.audioListenCount[audioCompleteData.audioUrl] = updatedListenCountData;
      isarController.putNewCount(updatedListenCountData);
    }
  }

  Future<void> setNewAudioSession(AudioCompleteDataClass audioCompleteData) async{
    if(File(audioCompleteData.audioUrl).existsSync()) {
      AudioMetadataInfoClass metadata = audioCompleteData.audioMetadataInfo;
      currentSong.add(audioCompleteData);
      currentAudioUrl = audioCompleteData.audioUrl;
      mediaItem.add(
        MediaItem(
          id: audioCompleteData.audioUrl,
          album: metadata.albumName,
          artist: metadata.artistName,
          title: metadata.title ?? audioCompleteData.audioUrl.split('/').last,
          artUri: Uri.file(appStateRepo.audioImageData!.path),
          extras: <String, dynamic>{
          },
        )
      );
      addAudioListenCount(audioCompleteData);
      await audioPlayer.setAudioSource(
        ProgressiveAudioSource(Uri.parse(audioCompleteData.audioUrl)),
      );
      emitCurrentAudioStreamData();
    }
  }

  void updateAudioPlayerState(AudioPlayerState newState){
    if(currentAudioUrl.isNotEmpty && appStateRepo.allAudiosList[currentAudioUrl] != null){
      AudioCompleteDataClass x = appStateRepo.allAudiosList[currentAudioUrl]!.notifier.value;
      AudioCompleteDataClass y = AudioCompleteDataClass(
        x.audioUrl, x.audioMetadataInfo, newState, x.deleted
      );
      appStateRepo.allAudiosList[currentAudioUrl]!.notifier.value = y;
      CurrentAudioStreamClass().emitData(
        CurrentAudioStreamControllerClass(y)
      );
    }
  }

  void emitCurrentAudioStreamData(){
    if(currentAudioUrl.isNotEmpty && appStateRepo.allAudiosList[currentAudioUrl] != null){
      AudioCompleteDataClass x = appStateRepo.allAudiosList[currentAudioUrl]!.notifier.value;
      AudioCompleteDataClass y = AudioCompleteDataClass(
        x.audioUrl, x.audioMetadataInfo, AudioPlayerState.playing, x.deleted
      );
      appStateRepo.allAudiosList[currentAudioUrl]!.notifier.value = y;
      CurrentAudioStreamClass().emitData(
        CurrentAudioStreamControllerClass(
          y
        )
      );
    }
  }

  @override
  Future<void> play() async {
    try {
      await audioPlayer.play();
    } catch (_) {}
  }

  @override
  Future<void> pause() async {
    try {
      await audioPlayer.pause();
    } catch (_) {}
  }
  
  @override
  Future<void> stop() async {
    await audioPlayer.stop().then((value){
      playerState = AudioPlayerState.stopped;
      updateAudioPlayerState(playerState);
      currentAudioUrl = '';
    });
  }

  void modifyLoopStatus(LoopStatus newStatus){
    currentLoopStatus = newStatus;
  }

  void _broadcastState(PlaybackEvent event) {
    bool isPlaying = audioPlayer.playing;
    final songValue = currentSong.hasValue == false ? null : currentSong.value.audioUrl;
    if(songValue != null){
      final queueIndex = currentDirectoryAudioList.indexOf(songValue);
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          isPlaying ? MediaControl.pause : MediaControl.play ,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[audioPlayer.processingState]!,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        playing: isPlaying,
        queueIndex: queueIndex,
      ));
    }

  }
}