import "package:carousel_slider_plus/carousel_slider_plus.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:siga/providers/api_provider.dart";
import "package:siga/providers/dashboard.dart";
import "package:siga/providers/setting_provider.dart";
import "package:siga/providers/theme_provider.dart";
import "package:siga/vars.dart" as vars;
import "package:skeletonizer/skeletonizer.dart";
import 'package:fl_chart/fl_chart.dart';

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

  void fetchInfo() async {
    ref.read(rekapPoktanProvider).refresh();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_)=> fetchInfo());
  }

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
                                autoPlayInterval: Duration(seconds: 30),
                                pauseAutoPlayOnManualNavigate: true,
                                pauseAutoPlayOnTouch: true,
                                autoPlayCurve: Curves.fastOutSlowIn,
                                height: 420,
                                enlargeCenterPage: true,
                                viewportFraction: 1,
                              ),
                              items: [1,2,3,4,5].map((i) {
                                return Builder(
                                  builder: (BuildContext ctx) {
                                    if (i == 1) {
                                      return PoktanProgress(index: i);
                                    }
                                    
                                    return DummyData(index: i);
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20,),
                    Center(
                      child: Stack(
                        children: [ElevatedButton(
                          onPressed: (){
                            ref.read(rekapPoktanProvider).refresh();
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

class DummyData extends StatelessWidget {
  final int index;
  const DummyData({super.key, required this.index});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.fromLTRB(5, 4, 5, 6),
      child: Card(
        elevation: 5,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Text('Data $index'),
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
  }
}

class PoktanProgress extends StatefulWidget {
  final int index;
  const PoktanProgress({super.key, required this.index});

  @override
  State<PoktanProgress> createState() => _PoktanProgressState();
}

class _PoktanProgressState extends State<PoktanProgress> {

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.fromLTRB(5, 4, 5, 6),
      child: Card(
        elevation: 5,
        child: Consumer(
          builder: (context, ref, child) {
            return Skeletonizer(
              enabled: ref.watch(rekapPoktanProvider).isLoading,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Skeleton.ignore(
                      ignore: true,
                      child: Row(
                        children: [
                          Text('Capaian Poktan'),
                        ],
                      ),
                    ),
                    Wrap(
                      children: [SizedBox(height: 30)],
                    ),
                    Flexible(
                      fit: FlexFit.tight,
                      child: Chart()
                    ),
                    Wrap(
                      children: [SizedBox(height: 30)],
                    ),
                    Row(
                      children: [
                        Column(
                          children: [
                            Text('Bulan Lapor'),
                          ],
                        ),
                        Column(
                          children: [
                            Text('   :  '),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              DateFormat("MMMM yyyy").format(DateTime.now()),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(''),
                  ],
                ),
              ),
            );
          }
        ),
      )
    );
  }
}

class Chart extends ConsumerStatefulWidget {
  const Chart({super.key});

  @override
  ConsumerState<Chart> createState() => ChartState(); 
}

class ChartState extends ConsumerState<Chart> {
  bool _showRealData = false;

  @override
  void initState() {
    super.initState();
    // Trigger animation after a slight delay
    Future.delayed(Duration(milliseconds: 400), () {
      setState(() {
        _showRealData = true;
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final poktanProgress = ref.watch(rekapPoktanProvider).progress;

    final List<BarChartGroupData> barGroups = [];
    int i = 0;
    poktanProgress.forEach((name, value) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _showRealData ? value : 0,
              width: 30,
              color: ref.watch(rekapPoktanProvider).isLoading ? Colors.transparent : Theme.of(context).colorScheme.tertiary,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
          showingTooltipIndicators: [0],
        ),
      );
      i++;
    });
    
    return BarChart(
      BarChartData(
        maxY: 100,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
              reservedSize: 30,
              getTitlesWidget: (value, _) => Text('${value.toInt()}%', style: TextTheme.of(context).bodySmall,),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < poktanProgress.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      poktanProgress.keys.elementAt(index),
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.transparent,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final name = poktanProgress.keys.elementAt(group.x.toInt());
              return BarTooltipItem('$name: ${rod.toY.toInt()}%', TextTheme.of(context).bodySmall!);
            },
          ),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
      duration: Duration(milliseconds: 2000), // animation duration
      curve: Curves.easeOutCubic,
    );
  }
}