import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:music_player_app/global_files.dart';

class MainPageWidget extends StatelessWidget {
  const MainPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MainPageWidgetStateful();
  }
}

class _MainPageWidgetStateful extends StatefulWidget {
  const _MainPageWidgetStateful();

  @override
  State<_MainPageWidgetStateful> createState() => __MainPageWidgetStatefulState();
}

class __MainPageWidgetStatefulState extends State<_MainPageWidgetStateful>{
  late MainPageController controller;

  @override void initState(){
    super.initState();
    controller = MainPageController(context);
    controller.initializeController();
  }

  @override void dispose(){
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([
              controller.selectedIndexValue,
              controller.widgetOptions
            ]),
            builder: (context, child) {
              int selectedIndexValue = controller.selectedIndexValue.value;
              List<Widget> widgetOptions = controller.widgetOptions.value;
              return Scaffold(
                key: controller.scaffoldKey,
                body: PageView(
                  controller: controller.pageController,
                  onPageChanged: controller.onPageChanged,
                  children: widgetOptions,
                ),
                bottomNavigationBar: Container(
                  decoration: const BoxDecoration(
                    boxShadow: [                                                               
                      BoxShadow(spreadRadius: 0, blurRadius: 10),
                    ],
                  ),
                  child: SizedBox(
                  child: BottomNavigationBar(
                    type: BottomNavigationBarType.fixed,
                    selectedFontSize: 13,
                    unselectedFontSize: 13,
                    showUnselectedLabels: true,
                    selectedItemColor: Colors.red,
                    unselectedItemColor: const Color.fromARGB(255, 110, 102, 102),
                    key: UniqueKey(),
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(FontAwesomeIcons.music, size: 25),
                        label: 'All Music',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(FontAwesomeIcons.user, size: 25),
                        label: 'Artists',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(FontAwesomeIcons.recordVinyl, size: 25),
                        label: 'Albums',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(FontAwesomeIcons.list, size: 25),
                        label: 'Playlists',
                      ),
                    ],
                    currentIndex: selectedIndexValue,
                    onTap: ((index) {
                      if(mounted){
                        if(controller.isLoaded.value){
                          controller.pageController.jumpToPage(index);
                        }
                      }
                    })
                  ),
                  )
                ),
              );
            }
          ),
          ValueListenableBuilder(
            valueListenable: controller.isLoaded,
            builder: (context, isLoaded, child){
              if(!isLoaded){
                return ValueListenableBuilder(
                  valueListenable: controller.loadType,
                  builder: (context, loadType, child){
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.transparent,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 15),
                          Text('Scanning')
                        ],
                      ),
                    );
                  }
                );
              }
              return Container();
            }
          )
        ]
      ),
    );
  }
}
