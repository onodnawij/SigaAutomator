import "dart:math";

import "package:carousel_slider_plus/carousel_slider_plus.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:siga/providers/api_provider.dart";
import "package:siga/providers/dashboard.dart";
import "package:siga/providers/setting_provider.dart";
import "package:siga/providers/theme_provider.dart";
import "package:siga/vars.dart" as vars;
import 'package:syncfusion_flutter_charts/charts.dart';

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
    // final appTheme = ref.watch(appThemeStateNotifier);
    
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
          // decoration: appTheme.isDarkModeEnabled ? appTheme.theme.innerNone : appTheme.theme.innerColor,
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
                                autoPlayInterval: Duration(seconds: 10),
                                pauseAutoPlayOnManualNavigate: true,
                                pauseAutoPlayOnTouch: true,
                                autoPlayCurve: Curves.fastOutSlowIn,
                                height: 420,
                                enlargeCenterPage: true,
                                viewportFraction: 1,
                              ),
                              items: [
                                PoktanProgress(prev: false),
                                PoktanProgress(prev: true),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20,),
                    Center(
                      child: Stack(
                        children: [FilledButton(
                          onPressed: (){
                            Navigator.of(context).pushNamed("/reports");
                          },
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
                        return Card.filled(
                          color: Theme.of(context).colorScheme.surfaceContainerLow,
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
                                  vars.poktanList[index] == "pikrm"
                                    ? "PIK-R"
                                    : vars.poktanList[index].toUpperCase(),
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
                      return Card.filled(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
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
                      return Card.filled(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
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
      child: Card.filled(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
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

class PoktanProgress extends ConsumerWidget {
  final bool prev;
  
  const PoktanProgress({super.key, required this.prev});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(rekapPoktanProgressLoading);
    
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.fromLTRB(5, 4, 5, 6),
      child: Card.filled(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Capaian Poktan'),
                  IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(seconds: 1),
                      switchInCurve: Curves.bounceIn,
                      switchOutCurve: Curves.bounceInOut,
                      child: loading
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                        : Icon(Icons.refresh),
                    ),
                    tooltip: "Refresh",
                    onPressed: loading ? null : () {
                      ref.read(rekapPoktanProvider).refresh();
                    },
                  ),
                ],
              ),
              Wrap(
                children: [SizedBox(height: 10)],
              ),
              Flexible(
                fit: FlexFit.tight,
                child: Chart(type: "progress", prev: prev)
              ),
              Wrap(
                children: [SizedBox(height: 10)],
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
                        DateFormat("MMMM yyyy", Localizations.localeOf(context).toString()).format(prev ? ref.read(rekapPoktanProvider).prevBulanLapor: DateTime.now()),
                      ),
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

class Chart extends ConsumerStatefulWidget {
  final String type;
  final bool prev;
  
  const Chart({super.key, required this.type, required this.prev});

  @override
  ConsumerState<Chart> createState() => _ChartState();
}

class _ChartState extends ConsumerState<Chart> {
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    // Start animation after slight delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _animate = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.prev
      ? ref.watch(rekapPoktanProvider).prevProgress
      : ref.watch(rekapPoktanProvider).progress;
    final loading = ref.watch(rekapPoktanProgressLoading);
    final isDark = ref.watch(appThemeStateNotifier).isDarkModeEnabled;
    
    final List<_ChartData> chartData = [];

    data.forEach((name, value) {
      double yValue;
      if (loading) {
        yValue = 40 + Random().nextDouble() * 45; // Fake random skeleton data
      } else {
        yValue = _animate ? value : 0; // Animate from 0 to real value
      }
      chartData.add(_ChartData(name, yValue));
    });

    // Create the chart widget
    final chartWidget = SfCartesianChart(
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: 100,
        isVisible: false,
      ),
      plotAreaBorderWidth: 0,
      tooltipBehavior: TooltipBehavior(
        enable: !loading,
        tooltipPosition: TooltipPosition.auto,
        builder: (data, point, series, pointIndex, seriesIndex) {
          final rekap = ref.read(rekapPoktanProvider)[point.x];
          final done = widget.prev ? rekap.donePrev.length : rekap.done.length;

          if (loading) {
            return SizedBox.shrink();
          }
          
          return Container(
            margin: EdgeInsets.all(5),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: point.x + "\n", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(
                    text: "$done / ${rekap.list.length}"
                    ),
                ],
                style: TextTheme.of(context).bodySmall!.copyWith(color: Theme.of(context).colorScheme.onInverseSurface)
              ),
            )
          );
        },
      ),
      series: [
        ColumnSeries<_ChartData, String>(
          dataSource: chartData,
          xValueMapper: (data, _) => data.label,
          yValueMapper: (data, _) => data.value,
          name: 'Progress', // Add series name for better tooltips
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          color: loading ? Colors.grey.shade300 : Theme.of(context).colorScheme.tertiary.withAlpha(isDark ? 255 : 125),
          animationDuration: loading ? 0 : 1200,
          // Add data labels to show percentages on top of bars
          dataLabelSettings: DataLabelSettings(
            isVisible: !loading, // Only show when not loading
            labelAlignment: ChartDataLabelAlignment.top,
            // Format as percentage
            builder: (data, point, series, pointIndex, seriesIndex) {
              return Text('${data.value.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 10,
                ),
              );
            },
          ),
        )
      ],
    );

    // Wrap the chart with CustomSkeletonizer when loading
    if (loading) {
      return CustomSkeletonizer(
        child: chartWidget,
      );
    }
    
    return chartWidget;
  }
}

// Custom skeletonizer for chart
class CustomSkeletonizer extends StatefulWidget {
  final Widget child;

  const CustomSkeletonizer({super.key, required this.child});

  @override
  State<CustomSkeletonizer> createState() => _CustomSkeletonizerState();
}

class _CustomSkeletonizerState extends State<CustomSkeletonizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.5, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [
                Colors.grey.shade700,
                Colors.grey.shade300,
                Colors.grey.shade700,
              ],
              stops: [
                0.0,
                _animation.value,
                1.0,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _ChartData {
  final String label;
  final double value;

  _ChartData(this.label, this.value);
}