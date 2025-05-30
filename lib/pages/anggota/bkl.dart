import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:siga/api/format.dart';
import 'package:siga/providers/api_provider.dart';
import 'package:siga/providers/listing_provider.dart';
import 'package:siga/pages/anggota/anggota.dart';
import 'package:siga/utils/block_ui.dart';
import 'package:siga/vars.dart';
import 'package:skeletonizer/skeletonizer.dart';

final anggotaBklItem = ChangeNotifierProvider((ref) => AnggotaBKLItem(ref));
final detailBkl = StateProvider((ref) => {});
final tableLoading = StateProvider((ref) => false);
final statLoading = StateProvider((ref) => false);

class AnggotaBKLItem extends ChangeNotifier {
  List items = [];
  CancelableOperation? currentTask;
  final Ref ref;

  AnggotaBKLItem(this.ref);

  void refresh() {
    if (currentTask != null) {
      currentTask!.cancel();
    }

    currentTask = CancelableOperation.fromFuture(_refresh());
  }

  Future<void> _refreshStat() async {
    final api = ref.read(apiProvider);
    final bkl = currentListingItem(ref);
    
    final result = await Future.wait(
      List<Future<List>>.generate(items.length, (i) {
        return api.getParentData(
          idKelurahan: bkl["kelurahanId"],
          filters: {
            "nama": items[i]["namaAnggota"],
            "nik": items[i]["nik"],
          }
        );
      })
    );
    
    for (var (i, anggota) in items.indexed) {
      anggota["fatal"] = result[i].isEmpty;
    }

    ref.read(statLoading.notifier).state = false;
  }

  Future<void> _refresh() async {
    final api = ref.read(apiProvider);
    final bkl = currentListingItem(ref);
    ref.read(tableLoading.notifier).state = true;
    ref.read(statLoading.notifier).state = true;

    await Future.delayed(Duration(seconds: 1));

    final resp = await api.getDetailPoktan(
      idPoktan: bkl["id"],
      jenis: "bkl",
    );

    ref.read(detailBkl.notifier).state = resp;
    
    items = resp["anggotaKelompok"];
    notifyListeners();
    ref.read(tableLoading.notifier).state = false;
    currentTask = null;
    await _refreshStat();

  }
}

class AnggotaPageBKL extends ConsumerStatefulWidget {
  final dynamic index;
  final String menu;
  final String jenis;
  
  const AnggotaPageBKL({super.key, required this.index, required this.menu, required this.jenis});
  
  @override
  ConsumerState<AnggotaPageBKL> createState() => _AnggotaPageBKLState();
}

class _AnggotaPageBKLState extends ConsumerState<AnggotaPageBKL> {
  CancelableOperation? pendingTask;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(anggotaBklItem).refresh();
    });
  }

  void doSubmit(int jumlah) async {
    final api = ref.read(apiProvider);
    blockUI(context);
    api.showLoading(message: "Bentar yaa...");

    Map result = {};

    try {
      final filters = {"keluargaSasaranBkl": "true", "kesertaanUppka": "false"};
      final itemDetails = ref.read(detailBkl);
      final idKelurahan = itemDetails["kelurahanId"];

      final listKeluarga = await api.getParentData(
        idKelurahan: idKelurahan,
        filters: filters,
      );

      listKeluarga.shuffle();

      result = await api.autoAnggotaPoktan(
        itemDetails: itemDetails,
        listKeluarga: listKeluarga,
        jumlah: jumlah,
        jenis: widget.jenis,
      );
    } catch(e, s) {
      print("error: $e");
      print("stack: $s");
    } finally {
      api.dismiss();
      unblockUI(context);      

      if (result["status"] == 200) {
        api.showSuccess("${result['data']} anggota berhasil ditambahkan!");
        ref.read(anggotaBklItem).refresh();
      } else {
        api.showError("Error!\n$result");
      }
    }
    
  }

  void addAnggota() async {
    int? res = await showModalBottomSheet(
      context: context,
      builder: (ctx) => TambahAnggotaSheet(),
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
    );

    if (res != null) {
      doSubmit(res);
    } 
  }

  void cleanseAnggota() async {
    final cleanseItems = ref.read(anggotaBklItem).items
    .where((x) => x["fatal"] ?? false).toList();

    if (cleanseItems.isNotEmpty) {
      var res = await showDialog(
        context: context,
        builder: (ctx) => CleanseDialog(
          cleanseItems: cleanseItems,
        )
      );

      if (res == true) {
        if (widget.jenis.toLowerCase() == "bkl") {
          doCleanse(cleanseItems);
        }
      }  
    } else {
      ref.read(apiProvider).showSuccess("Semua sampun valid !");
    }
  }

  void doCleanse(List cleanseItems) async {
    final api = ref.read(apiProvider);
    final anggota = ref.read(anggotaBklItem).items;
    final itemDetails = ref.read(detailBkl);
    final fixes = cleanseItems.map((x) => x["nomorUrut"]);
    final fixItems = List.from(anggota).map((x) {
      var item = Map.from(x);
      if (fixes.contains(item["nomorUrut"])) {
        item["flag"] = "Delete";
      }
      return formatUpsertPoktanBKL["anggotaKelompok"][0].map((k, v) {
        dynamic val;
        if (k == "nomor") {
          val = int.parse(item["nomorUrut"]);
        } else if (k == "nomorBKL") {
          val = int.parse(item["nomorUrut"]).toString().padLeft(3, "0");
        } else {
          val = item[k];
        }
        return MapEntry(k, val);
      });
    }).toList();

    blockUI(context);
    api.showLoading(message: "Okee, bentar...");

    Map result = {};

    try {
      result = await api.autoAnggotaPoktan(
        itemDetails: itemDetails,
        jenis: widget.jenis,
        fixItems: fixItems,
      );
    } finally {
      api.dismiss();
      unblockUI(context);

      if (result["status"] == 200) {
        api.showSuccess("Done cleansing!");
        ref.read(anggotaBklItem).refresh();
      } else {
        api.showError("Error\nstatus: ${result['status']}\n msg: ${result['data']}");
      }
      
    }
    
  }
  
  @override
  Widget build(BuildContext context) {
    final anggota = ref.watch(anggotaBklItem).items;
    final valid = anggota.where(
      (ele) => !(ele["fatal"] ?? false),
    ).length;

    final statIcon = [
      Icon(Icons.list, size: 20),
      Icon(
        Icons.check_circle,
        color:
            ColorScheme.fromSeed(
              seedColor: Colors.green,
            ).primary,
        size: 20,
      ),
      Icon(
        Icons.cancel_outlined,
        color: Theme.of(context).colorScheme.error,
      ),
    ];
    
    final statText = [
      "${anggota.length} total",
      "$valid valid",
      "${anggota.length - valid} tidak ditemukan",
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Anggota BKL"),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: () => addAnggota(),
          ),
          IconButton(
            icon: Icon(Icons.checklist_rtl_rounded),
            onPressed: () => cleanseAnggota(),
          ),
          appOptions(context),
        ],
        forceMaterialTransparency: true,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 10, right: 10),
                    padding: EdgeInsetsDirectional.all(10),
                    width: 556,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).cardColor.withAlpha(90),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Container(
                          width: 536,
                          padding: EdgeInsets.all(8),
                          child: DataTableBKL(data: anggota),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 96,
                  width: 556,
                  child: Skeletonizer(
                    enabled: ref.watch(statLoading),
                    child: InkWell(
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onLongPress: () {},
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: 160,
                            child: Card(
                              child: Container(
                                margin: EdgeInsets.all(10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 5,
                                  children: [
                                    statIcon[index],
                                    Text(
                                      statText[index],
                                      style: TextTheme.of(context).bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DataTableBKL extends ConsumerWidget {
  final List data;
  const DataTableBKL({super.key, required this.data});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fatalIcon = Icon(
      Icons.cancel_outlined,
      color: Theme.of(context).colorScheme.error,
    );
    final validIcon = Icon(
      Icons.check_circle,
      color: ColorScheme.fromSeed(seedColor: Colors.green,).primary,
    );
    
    TextStyle headerStyle = TextTheme.of(context).bodyMedium!.copyWith(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    TextStyle itemStyle = TextTheme.of(context).bodyMedium!.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Skeletonizer(
      enabled: ref.watch(tableLoading),
      child: DataTable(
        columnSpacing: 10,
        horizontalMargin: 0,
        border: TableBorder(
          horizontalInside: BorderSide(
            width: 1,
            color: Theme.of(context).dividerColor,
          ),
          verticalInside: BorderSide(
            width: 1,
            color: Theme.of(context).dividerColor,
          ),
        ),
        columns: [
          DataColumn(
            label: Text("No", style: headerStyle, textAlign: TextAlign.center),
            headingRowAlignment: MainAxisAlignment.center,
            columnWidth: FixedColumnWidth(48),
          ),
          DataColumn(
            label: Text("Nama", style: headerStyle, textAlign: TextAlign.center),
            headingRowAlignment: MainAxisAlignment.center,
            columnWidth: FixedColumnWidth(160),
          ),
          DataColumn(
            label: Text(
              "Status\nLansia",
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
            headingRowAlignment: MainAxisAlignment.center,
            columnWidth: FixedColumnWidth(64),
          ),
          DataColumn(
            label: Center(
              child: Text(
                "Kemandirian\nLansia",
                maxLines: 2,
                style: headerStyle,
                textAlign: TextAlign.center,
              ),
            ),
            headingRowAlignment: MainAxisAlignment.center,
            columnWidth: FixedColumnWidth(140),
          ),
          DataColumn(
            label: Text(
              "Status",
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
            headingRowAlignment: MainAxisAlignment.center,
            columnWidth: FixedColumnWidth(64),
          ),
        ],
        rows:
          data.isNotEmpty
          ? List.generate(data.length, (i) {
            return DataRow(
              cells: [
                DataCell(
                  Center(
                    child: Text((i+1).toString(), style: itemStyle),
                  ),
                ),
                DataCell(
                  Tooltip(
                    message: data[i]["namaAnggota"],
                    triggerMode: TooltipTriggerMode.longPress,
                    child: Text(
                      data[i]["namaAnggota"],
                      style: itemStyle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                DataCell(
                  Center(
                    child: Text(
                      data[i]["statusLansia"] == "1" ? "Ya" : "Tidak",
                      style: itemStyle,
                    ),
                  ),
                ),
                DataCell(
                  Center(
                    child: Text(
                      data[i]["tingkatKemandirian"] == "1" ? "Mandiri" : "Tidak",
                      style: itemStyle,
                    ),
                  ),
                ),
                DataCell(
                  Skeleton.keep(
                    keep: true,
                    child: Skeletonizer(
                      enabled: ref.watch(statLoading),
                      child: Center(
                        child: data[i]["fatal"] ?? false
                          ? fatalIcon
                          : validIcon
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList()
        : List.filled(
          50,
          DataRow(
            cells: [
              DataCell(Text("00", style: itemStyle)),
              DataCell(Text("dataLansiaaa", style: itemStyle)),
              DataCell(Text("YA", style: itemStyle)),
              DataCell(Text("dataLansiaaa", style: itemStyle)),
              DataCell(Text("100", style: itemStyle)),
            ],
          ),
        ),
      ),
    );
  }
}

class CleanseDialog extends ConsumerWidget {
  final List cleanseItems;
  const CleanseDialog({super.key, required this.cleanseItems});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog.adaptive(
      insetPadding: EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      icon: Icon(Icons.checklist_rtl_rounded),
      title: Text("Cleanse Anggota"),
      content: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Text(
              "Fix anggota KKI berbeda dengan data SIGA dan bersihkan semua anggota invalid atau tidak ditemukan ?",
            ),
            SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTableBKL(data: cleanseItems),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text("gajadi"),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text("lesgo"),
        ),
      ],
    );
  }
  
}