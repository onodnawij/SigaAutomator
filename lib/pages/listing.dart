import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:siga/api/models/user.dart';
import 'package:siga/providers/api_provider.dart';
import 'package:siga/providers/listing_provider.dart';
// import 'package:siga/providers/theme_provider.dart';
import 'package:siga/utils/extensions.dart';
import 'package:siga/vars.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _loadingState = StateProvider((ref) => false);

class ListingPage extends ConsumerStatefulWidget {
  final String menu;
  final String jenis;
  const ListingPage({
    super.key,
    self,
    required this.menu,
    required this.jenis,
  });

  @override
  ConsumerState<ListingPage> createState() => ListingPageState();
}

class ListingPageState extends ConsumerState<ListingPage> {
  final GlobalKey<ListingPageState> self = GlobalKey();
  late List<WilKelurahan> kelurahanList;
  WilKelurahan? currentKelurahan;
  String? kelurahanSelectorError;
  final allKelurahan = WilKelurahan(namaKelurahan: 'Semua Kelurahan');
  late String menu;
  late String jenis;
  late String path;

  @override
  void initState() {
    menu = widget.menu.capitalize!;
    if (menu != 'Poktan') {
      menu = menu.toUpperCase();
    }
    jenis = widget.jenis.toUpperCase();
    path = "$menu/$jenis".toLowerCase();    
    
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => makeKelurahan());
  }

  Future<void> makeKelurahan() async {
    final userRef = ref.read(userProvider);
    await userRef.user!.initDone;
    kelurahanList = List.of(
      userRef.user!.wilKecamatan.wilKelurahan,
    );
    kelurahanList.add(allKelurahan);
    List? data = ref.read(listingCacheProvider)[path];

    if (data != null) {
      updateCache(data);
    }
  }

  void showMyBottomSheet() {
    showModalBottomSheet(
      context: context,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      // backgroundColor: Theme.of(context).colorScheme.surfaceBright,
      showDragHandle: true,
      builder: (ctx) => _bottomSheetBuilder(ctx),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final appTheme = ref.watch(appThemeStateNotifier);
    final userRef = ref.read(userProvider);
    
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      ref.read(listingKeyProvider.notifier).state = path;

      await Future.delayed(Duration(milliseconds: 300));
      final data = ref.read(listingCacheProvider)[ref.read(listingKeyProvider)];
      if (data == null) {
        showMyBottomSheet();
      }
    });
    
    return Scaffold(
      appBar: AppBar(
        title: Text('$menu $jenis'),
        forceMaterialTransparency: true,
        actionsPadding: EdgeInsets.only(right: 10),
        actions: [
          IconButton(
            onPressed: () => showMyBottomSheet(),
            icon: Icon(Icons.filter_list_outlined),
          ),
          appOptions(context),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Container(
          padding: EdgeInsets.fromLTRB(5, 2, 5, 2),
          // decoration:
          //     appTheme.isDarkModeEnabled
          //       ? appTheme.theme.innerNone
          //       : appTheme.theme.innerColor,
          child: ContentList(
            kelurahanList:
                userRef.user!.wilKecamatan.wilKelurahan,
          ),
        ),
      ),
    );
  }

  void updateCache(List items) {
    final cache = ref.read(listingCacheProvider.notifier);
    final key = ref.read(listingKeyProvider);
    ref.read(lastDataLengthProvider.notifier).state = cache.state[key]?.length ?? 3;
    cache.update((state){
      state[path] = items;
      return state;
    });
  }

  void updateContent({String? errorText, Object? filter}) {
    final contentProvider = ref.read(listingContentProvider.notifier);
    if (errorText != null) {
      contentProvider.state.errorText = errorText.isNotEmpty ? errorText : null;
    }

    if (filter != null) {
      final key = ref.read(listingKeyProvider);
      if (filter == "") {
        contentProvider.state.filter[key] = null;
      } else if (filter is WilKelurahan) {
        contentProvider.state.filter[key] = filter;
      }
    }
    
  }

  Future<void> fetchData(int? idKelurahan) async {
    final api = ref.read(apiProvider);
    
    final isLoading = ref.read(_loadingState.notifier);
    isLoading.state = true;
    updateCache([]);
    var items = await api.getPoktan(
      jenis: jenis,
      idKelurahan: idKelurahan,
    );
    // widget.api.contextController.items["$menu/$jenis".toLowerCase()] = items;
    updateCache(items);
    await Future.delayed(Duration(seconds: 2));
    isLoading.state = false;
  }

  Widget _bottomSheetBuilder(context) {
    final contentProvider = ref.read(listingContentProvider);
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 28),
      child: SingleChildScrollView(
        controller: ModalScrollController.of(context),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final filter = contentProvider.filter[path];
                      return DropdownMenu(
                        menuStyle: MenuStyle(
                          backgroundColor: WidgetStateProperty<Color>.fromMap(
                            <WidgetStatesConstraint, Color>{
                              WidgetState.any:
                                  Theme.of(context).colorScheme.surfaceBright,
                            },
                          ),
                        ),
                        width: 400,
                        initialSelection: filter,
                        onSelected: (value) {
                          updateContent(errorText: "", filter: value);
                        },
                        enableFilter: true,
                        hintText: "Pilih Kelurahan",
                        errorText: ref.watch(listingContentProvider).errorText,
                        dropdownMenuEntries: List.generate(kelurahanList.length, (
                          x,
                        ) {
                          WilKelurahan val = kelurahanList[x];
                          return DropdownMenuEntry(
                            value: val,
                            label: val.namaKelurahan!,
                          );
                        }),
                      );
                    }
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              label: Text('Cari'),
              icon: Icon(Icons.search),
              style: ButtonStyle(elevation: WidgetStatePropertyAll(3)),
              onPressed: () {
                final WilKelurahan? current = ref.read(listingContentProvider).filter[ref.read(listingKeyProvider)];
                if (current != null) {
                  fetchData(current.idKelurahan);
                  Navigator.pop(context);

                  if (current.namaKelurahan == allKelurahan.namaKelurahan) {
                    updateContent(filter: "");
                  }
                } else {
                  updateContent(errorText: 'pilih bos');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ContentList extends ConsumerStatefulWidget {
  final String type = 'list';
  final List<WilKelurahan> kelurahanList;
  const ContentList({
    super.key,
    required this.kelurahanList,
  });

  @override
  ConsumerState<ContentList> createState() => ContentListState();
}

class ContentListState extends ConsumerState<ContentList> {
  late Offset touch;
  late RenderBox overlay;
  final MenuController menuController = MenuController();

  void getPosition(details) {
    touch = details.globalPosition;
  }

  RelativeRect get relRectSize => RelativeRect.fromSize(touch & const Size(40, 40), overlay.size);

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(listingCacheProvider)
      [ref.read(listingKeyProvider)]
      ?? []
    ;
    final filter = ref.read(listingContentProvider).filter[ref.read(listingKeyProvider)];
    overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    return CustomScrollView(
      slivers: [
        Skeletonizer.sliver(
          enabled: ref.watch(_loadingState),
          child: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200.0,
              mainAxisSpacing: 10.0,
              crossAxisSpacing: 10.0,
              childAspectRatio: 1.24,
            ),
            delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
              WilKelurahan? kelurahan =
                data.isNotEmpty
                  ? widget.kelurahanList.firstWhereOrNull(
                    (kel) =>
                        data[index]['kelurahanId'].toString() ==
                        kel.idKelurahan.toString(),
                  )
                  : null;
              return MyGridItem(
                index: index,
                context: context,
                item: data.isNotEmpty ? data[index] : null,
                kelurahan: kelurahan?.namaKelurahan ?? "not set",
              );
            }, childCount: data.isNotEmpty ? data.length : filter == null ? 0 : ref.read(lastDataLengthProvider)),
          ),
        ),
      ],
    );
  }
}

class MyGridItem extends ConsumerStatefulWidget {
  final String kelurahan;
  final int index;
  final BuildContext context;
  final Map? item;
  const MyGridItem({
    super.key,
    required this.index,
    required this.context,
    this.item,
    required this.kelurahan,
  });

  @override
  ConsumerState<MyGridItem> createState() => _MyGridItemState();
}

class _MyGridItemState extends ConsumerState<MyGridItem> {
  final FocusNode _gridFocusNode = FocusNode();
  late Offset touch;

  @override
  void dispose() {
    _gridFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingKey = ref.read(listingKeyProvider);

    return MenuAnchor(
      childFocusNode: _gridFocusNode,
      style: MenuStyle(backgroundColor: WidgetStatePropertyAll(Colors.white)),
      menuChildren: [
        PopupMenuItem(
          enabled: false,
          child: Text(
            widget.kelurahan,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ],
      builder:
          (context, controller, child) => Card.filled(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: InkWell(
              focusNode: _gridFocusNode,
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                }
              },
              onLongPress: () {
                if (!controller.isOpen) {
                  controller.open(position: Offset(0, 0));
                }
              },
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Skeleton.ignore(
                        child: PopupMenuButton(
                          icon: Icon(Icons.chevron_left, size: 20),
                          tooltip: 'Opsi',
                          color: Theme.of(context).colorScheme.surfaceBright,
                          itemBuilder:
                              (context) => <PopupMenuEntry>[
                                PopupMenuItem(
                                  child: Text('Anggota'),
                                  onTap: () {
                                    var path =
                                        "$listingKey/anggota"
                                            .toLowerCase();
                                    if (supportedRoute.contains(path)) {
                                      ref.read(listingIndexProvider.notifier).state = widget.index;
                                      Navigator.of(context).pushNamed(
                                        "/$path",
                                        arguments: widget.index,
                                      );
                                    } else {
                                      ref.read(apiProvider).showError("masih belum bisa");
                                    }
                                  },
                                ),
                                PopupMenuDivider(),
                                PopupMenuItem(
                                  child: Text('Register'),
                                  onTap: () {
                                    var path =
                                        "$listingKey/register";
                                    if (supportedRoute.contains(path)) {
                                      ref.read(listingIndexProvider.notifier).state = widget.index;
                                      Navigator.of(context).pushNamed(
                                        '/$listingKey/register',
                                        arguments: widget.index,
                                      );
                                    } else {
                                      ref.read(apiProvider).showError("masih belum bisa");
                                    }
                                  },
                                ),
                              ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.groups, size: 36),
                        Center(
                          child: Text(
                            widget.item?['namaKelompok'] ??
                                '${listingKey.split("/").last.toUpperCase()} ${widget.index}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize:
                                  TextTheme.of(context).titleMedium?.fontSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
