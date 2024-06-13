import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioButtonHandler extends BaseAudioHandler{
  static final _item = MediaItem(
    id: 'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3',
    album: "CarriOn",
    title: "CarriOn",
    artist: "Carrier",
    duration: const Duration(milliseconds: 5739820),
    artUri: Uri.parse(
        'https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg'),

  );

  final player = AudioPlayer();
  

  /// Initialise our audio handler.
  AudioButtonHandler() {
    // So that our clients (the Flutter UI and the system notification) know
    // what state to display, here we set up our audio handler to broadcast all
    // playback state changes as they happen via playbackState...
    player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    // ... and also the current media item via mediaItem.
    mediaItem.add(_item);

    // Load the player.
    player.setAudioSource(AudioSource.uri(Uri.parse(_item.id)));
    player.setVolume(0);
    player.play();
  }
  Future<void> Function()? nextButtonFunc;
  Future<void> Function()? previousButtonFunc;

  void setButtonFunc(Future<void> Function()? nextFunc, Future<void> Function()? prevFunc){
    nextButtonFunc = nextFunc;
    previousButtonFunc = prevFunc;
    player.play();
  }

  void init(){
    nextButtonFunc = null;
    previousButtonFunc = null;
    player.stop();
  }

  
  @override
  Future<void> skipToNext() async{
    if (kDebugMode) {
      print("next button");
    }
    if(nextButtonFunc!=null) await nextButtonFunc!();
  }
  @override
  Future<void> skipToPrevious() async{
    if (kDebugMode) {
      print("prev button");
    }
    if(previousButtonFunc!=null) await previousButtonFunc!();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
    );
  }
}