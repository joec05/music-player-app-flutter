import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player_app/global_files.dart';
import 'package:audio_service/audio_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await isarController.initialize();
  await initializeAudioService();
  GlobalObserver globalObserver = GlobalObserver();
  WidgetsBinding.instance.addObserver(globalObserver);
  runApp(
    const MyApp()
  );
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
    appStateRepo.audioHandler = audioHandler;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    appStateRepo.soundwaveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 500,
      )
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) =>
              const MainPageWidget()
            );
          default:
            assert(false, 'Page ${settings.name} not found');
            return null;
        }
      },
      theme: globalTheme.dark,
      initialBinding: StoreBinding()
    );
  }
}

class StoreBinding implements Bindings {
  @override
  void dependencies() {
    /// Get.lazyPut(() => appStateRepo.allAudiosList);
  }
}