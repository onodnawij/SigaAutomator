import "package:carousel_slider_plus/carousel_slider_plus.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:siga/providers/api_provider.dart";
import "package:siga/providers/setting_provider.dart";
import "package:siga/providers/theme_provider.dart";
import "package:siga/vars.dart" as vars;

class HomePage extends ConsumerStatefulWidget {
  final String title = 'Dashboard';
  const HomePage({super.key});
  
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

enum Menu {logout, settings, about}

class _HomePageState extends ConsumerState<HomePage> {
  
  void doLogout() {
    final api = ref.read(apiProvider);
    
    ref.read(settingProvider.notifier).update((state) {
      state.login["stayLoggedIn"] = false;
      state.login["userData"] = null;
      return state;
    });
    api.showInfo("Logged Out!");
  }

  void menuCallback(value) {
    String path = '/';

    switch (value) {
      case Menu.logout:
        doLogout();
        path = '/login';
      case Menu.settings:
        path = '/setting';
      case Menu.about:
        path = '/about';
    }

    Navigator.of(context).pushNamed(path);
  }

// Future<void> waitForWilayah () async {
//   final userRef = ref.read(userProvider);
//   await userRef.user!.initDone;
// }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(appThemeStateNotifier);
    
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        title: Text(
          widget.title,
        style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actionsPadding: EdgeInsets.only(right: 10),
        actions: [
          PopupMenuButton(
            color: Theme.of(context).colorScheme.surfaceBright,
            onSelected: menuCallback,
            itemBuilder: (context) => <PopupMenuEntry<Menu>>[
            PopupMenuItem<Menu>(
              value: Menu.settings,
              child: const ListTile(
                title: Text('Settings'),
                leading: Icon(Icons.settings),
              )
            ),
            const PopupMenuItem<Menu>(
              value: Menu.about,
              child: ListTile(
                title: Text('About'),
                leading: Icon(Icons.info),
              )
            ),
            const PopupMenuItem<Menu>(
              value: Menu.logout,
              child: ListTile(
                title: Text('Logout'),
                leading: Icon(Icons.logout),
              )
            ),
          ]),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          padding: const EdgeInsets.all(4.0),
          decoration: appTheme.isDarkModeEnabled ? appTheme.theme.innerNone : appTheme.theme.innerColor,
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate.fixed(
                  [
                    Stack(
                      children: [
                        Center(
                          child: SizedBox(
                            child: CarouselSlider(
                              options: CarouselOptions(
                                autoPlay: true,
                                autoPlayInterval: Duration(seconds: 7),
                                pauseAutoPlayOnManualNavigate: true,
                                enlargeFactor: .25,
                                pauseAutoPlayOnTouch: true,
                                autoPlayCurve: Curves.fastOutSlowIn,
                                // aspectRatio: ,
                                height: 300,
                                enlargeCenterPage: true,
                                viewportFraction: .6,
                              ),
                              items: [1,2,3,4,5].map((i) {
                                return Builder(
                                  builder: (BuildContext ctx) {
                                    return Container(
                                      width: MediaQuery.of(ctx).size.width,
                                      margin: EdgeInsets.fromLTRB(5, 4, 5, 6),
                                      child: Card(
                                        elevation: 5,
                                        child: Container(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Text('Data $i'),
                                                ],
                                              ),
                                              Flexible(
                                                fit: FlexFit.tight,
                                                child: SizedBox.square(
                                                  child: Center(child: Text('DATA WILL BE HERE'))
                                                )
                                              ),
                                              Row(
                                                children: [
                                                  Column(
                                                    children: [
                                                      Text('data1'),
                                                      Text('data2'),
                                                      Text('data3'),
                                                    ],
                                                  ),
                                                  Column(
                                                    children: [
                                                      Text('   :  '),
                                                      Text('   :  '),
                                                      Text('   :  '),
                                                    ],
                                                  ),
                                                  Column(
                                                    children: [
                                                      Text('explanation1'),
                                                      Text('explanation2'),
                                                      Text('explanation3'),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Text(''),
                                            ],
                                          ),
                                        ),
                                      )
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10,),
                    Center(
                      child: Stack(
                        children: [ElevatedButton(
                          onPressed: (){
                            // waitForWilayah();
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                          ),
                          child: Text('show more')),]
                      ),
                    ),
                  ]
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate.fixed(
                  [
                    SizedBox(
                      height: 20
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: Text(
                        'Poktan',
                        style: TextTheme.of(context).titleLarge,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: Divider(color: Colors.black45),
                    )
                  ]
                ),
              ),
              DecoratedSliver(
                position: DecorationPosition.background,
                decoration: BoxDecoration(
                  
                ),
                sliver: SliverPadding(
                  padding: const EdgeInsets.all(5),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200.0,
                      mainAxisSpacing: 5.0,
                      crossAxisSpacing: 5.0,
                      childAspectRatio: 1.0,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return Card(
                          // color: Theme.of(context).colorScheme.surfaceBright,
                          elevation: 4,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTapUp: (details) {
                              var route = '/poktan/${vars.poktanList[index].toLowerCase()}';
                              Navigator.of(context).pushNamed(route);
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.groups_rounded,
                                  size: 36,
                                ),
                                Text(
                                  vars.poktanList[index].toUpperCase(),
                                  style: TextTheme.of(context).titleSmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: vars.poktanList.length,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate.fixed(
                  [
                    SizedBox(
                      height: 20
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: Text(
                        'SDM',
                        style: TextTheme.of(context).titleLarge,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: Divider(color: Colors.black45),
                    )
                  ]
                ),
              ),
              SliverPadding(
                  padding: EdgeInsets.all(5),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200.0,
                      mainAxisSpacing: 5.0,
                      crossAxisSpacing: 5.0,
                      childAspectRatio: 1.0,
                    ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return Card(
                        elevation: 4,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTapUp: (details) {
                            var cur = vars.ppkbdList[index];
                            Navigator.of(context).pushNamed('/sdm/$cur');
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                size: 36,
                              ),
                              Text(
                                vars.ppkbdList[index].toUpperCase(),
                                style: TextTheme.of(context).titleSmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: vars.ppkbdList.length,
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate.fixed(
                  [
                    SizedBox(
                      height: 20
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: Text(
                        'Admin Tools',
                        style: TextTheme.of(context).titleLarge,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: Divider(color: Colors.black45),
                    )
                  ]
                ),
              ),
              SliverPadding(
                  padding: EdgeInsets.all(5),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200.0,
                      mainAxisSpacing: 5.0,
                      crossAxisSpacing: 5.0,
                      childAspectRatio: 1.0,
                    ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return Card(
                        elevation: 4,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTapUp: (details) {
                            var cur = vars.ppkbdList[index];
                            Navigator.of(context).pushNamed('/tools/$cur');
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                size: 36,
                              ),
                              Text(
                                vars.toolList[index].toUpperCase(),
                                style: TextTheme.of(context).titleSmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: vars.toolList.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}