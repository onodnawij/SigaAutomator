import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:siga/api/format.dart';
import 'package:siga/pages/anggota/anggota.dart';
import 'package:siga/providers/api_provider.dart';
import 'package:siga/providers/listing_provider.dart';
import 'package:siga/utils/block_ui.dart';
import 'package:siga/utils/string_utility.dart';
import 'package:siga/vars.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AnggotaPageBKB extends ConsumerStatefulWidget {
  final dynamic index;
  final String menu;
  final String jenis;
  
  const AnggotaPageBKB({super.key, required this.index, required this.menu, required this.jenis});
  @override
  ConsumerState<AnggotaPageBKB> createState() => _AnggotaPageBKBState();
}

class _AnggotaPageBKBState extends ConsumerState<AnggotaPageBKB> {
  List<Map> anggotaItem = [];
  late TextStyle headerStyle;
  late TextStyle itemStyle;
  int maxAnggota = 1;
  List invalidItems = [];
  List fatalItems = [];
  List diffItems = [];
  bool anyDuplicate = false;
  int duplicateItems = 0;
  Map itemDetails = {};
  late Icon _fatalIcon;
  late Icon _invalidIcon;
  late Icon _diffIcon;
  late Icon _duplicateIcon;
  Map<String, CancelableOperation> pendingTask = {};

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => pendingTask["init"] = CancelableOperation.fromFuture(fetchData("init")));
    super.initState();
  }

  @override
  void dispose() {
    for (var task in pendingTask.values.toList()) {
      task.cancel();
    }
    super.dispose();
  }

  Future<void> fetchData(String taskName) async {
    final api = ref.read(apiProvider);
    var item = ref.read(listingCacheProvider)[ref.read(listingKeyProvider)]![widget.index];
    ref.read(loadingState.notifier).state = true;

    invalidItems = [];
    fatalItems = [];
    diffItems = [];

    await Future.delayed(Duration(seconds: 1));
    
    itemDetails = await api.getDetailPoktan(
      idPoktan: item["id"],
      jenis: widget.jenis,
    );
    List anggotaKelompok = itemDetails["anggotaKelompok"];

    List invalids = [];
    Map knownAnggota = {};
    int duplicates = 0;
    List isFatal = [];
    List result = [];

    Future<Map> task(index) async {
      Map fixableData = {};
      int usiaAnak = DateTime.now()
        .difference(
          parseAutoDate(anggotaKelompok[index]["tanggalLahirAnak"])!
        )
        .inDays ~/
        365;
      var nama = anggotaKelompok[index]["namaAnggota"];
      var namaAnak = anggotaKelompok[index]["namaAnak"];
      var valid = usiaAnak < 7;

      if (anggotaKelompok[index]["kki"] == null) {
        isFatal.add(anggotaKelompok[index]);
      }

      var nik = anggotaKelompok[index]["nik"];

      var childResp = await api.getChildData(
        anggotaKelompok[index]["kki"],
      );

      bool fatal = false;
      bool kkiDiff = false;

      List childData =
          childResp.where((ele) {
            return ele["nama"] == anggotaKelompok[index]["namaAnak"];
          }).toList();
      if (childData.isEmpty) {
        final filters = {
          "nik": nik,
          "nama": nama,
        };
        
        final parentResp = await api.getParentData(
          idKelurahan: itemDetails["kelurahanId"],
          filters: filters,
        );

        if (parentResp.isEmpty) {
          valid = false;
          fatal = true;
        } else {
          var secondChildResp = await api.getChildData(
            parentResp[0]["noKeluarga"],
          );
          List secondChildData =
              secondChildResp
                  .where(
                    (elem) =>
                        elem["nama"] ==
                        anggotaKelompok[index]["namaAnak"],
                  )
                  .toList();

          if (secondChildData.isEmpty) {
            valid = false;
            fatal = true;
          } else {
            kkiDiff = true;
            fixableData = {
              "kki": secondChildData[0]["noKeluarga"],
              "noKeluarga": secondChildData[0]["noKeluarga"],
              "nikAnggota": secondChildData[0]["nik"],
              "BKBID": item["id"],
            };
          }
        }
      }

      final bool duplicate = knownAnggota.keys.toList().contains(nama);

      final rawData = Map.from(anggotaKelompok[index]);

      var rowItem = {
        "no": "${index + 1}",
        "nama": nama,
        "namaAnak": namaAnak,
        "usiaAnak": usiaAnak.toString(),
        "valid": valid,
        "duplicate": duplicate,
        "fatal": fatal,
        "kkiDiff": kkiDiff,
        "rawData": rawData,
        "fixableData": fixableData,
      };

      if (!duplicate) {
        knownAnggota[nama] = [index];
      } else {
        knownAnggota[nama].add(index);
      }

      if (!valid && !fatal) {
        invalids.add(rowItem);
      }

      if (fatal) {
        isFatal.add(rowItem);
      }

      if (kkiDiff && valid) {
        diffItems.add(rowItem);
      }

      return rowItem;
    }

    result = await Future.wait(
      List<Future<Map>>.generate(anggotaKelompok.length, (index) {
        return task(index);
      }).toList()
    );

    anggotaItem = List.from(result);

    knownAnggota.forEach((k, v) {
      if (v.length > 1) {
        duplicates += 1;
        v.forEach((i) {
          anggotaItem[i]["duplicate"] = true;
        });
      }
    });

    invalidItems = invalids;
    duplicateItems = duplicates;
    fatalItems = isFatal;
    pendingTask.remove(taskName);
    if (mounted) {
      ref.read(loadingState.notifier).state = false;
    }
  }

  void doSubmit(int jumlah, {String? idRw}) async {
    final api = ref.read(apiProvider);
    blockUI(context);
    api.showLoading();

    bool success = false;
    int done = 0;
    Map result = {};

    try {
      final filters = {"keluargaSasaranBkb": "true", "kesertaanBkb": "false"};    
      final idKelurahan = itemDetails["kelurahanId"];
      final listKeluarga = await api.getParentData(idKelurahan: idKelurahan, idRw: idRw, filters: filters);
      listKeluarga.shuffle();
      
      result = await api.autoAnggotaPoktan(
        itemDetails: itemDetails,
        listKeluarga: listKeluarga,
        jumlah: jumlah,
        jenis: widget.jenis
      );

      if (result["status"] == 200) {
        success = true;
        done = result["data"];
      }
      
    }
    catch(e, s) {
      print("Error: $e\nStacktrace: $s");
    }
    finally {
      api.dismiss();
      unblockUI(context);

      if (success) {
        api.showSuccess("$done anggota berhasil ditambahkan!");
        pendingTask["submit"] = CancelableOperation.fromFuture(fetchData("submit"));
      } else {
        api.showError("Error!\n$result");
      }
    }
  }

  void doCleanse(List cleanseItems) async {
    final api = ref.read(apiProvider);

    final fixNomorUrut = {
      for (var x in cleanseItems)
      x["rawData"]["nomorUrut"]: Map.fromEntries(
        Map.from(x["rawData"]).entries.followedBy(
          Map.from(x["fixableData"]).entries).followedBy(
            [
              MapEntry("flag", x["kkiDiff"] && x["valid"] ? "Upsert": "Delete"),
              MapEntry("nomor", int.parse(x["rawData"]["nomorUrut"])),
            ],
          )
        )
    };

    Map anggota = {
      for (var x in itemDetails["anggotaKelompok"])
      x["nomorUrut"]: Map.fromEntries(Map.from(x).entries.followedBy(
        [MapEntry("nomor", int.parse(x["nomorUrut"]))]
      ))
    };

    anggota.addAll(fixNomorUrut);

    final fixItems = anggota.values.map((x) {
      return formatUpsertPoktanBKB["anggotaKelompok"][x["flag"] == "Upsert" ? 1 : 0].map((k, v) {
        return MapEntry(k, x[k]);
      });
    }).toList();

    blockUI(context);
    api.showLoading();

    Map result = {};
    
    try {
      result = await api.autoAnggotaPoktan(itemDetails: itemDetails, jenis: widget.jenis, fixItems: fixItems);
      
    } finally {
      api.dismiss();
      unblockUI(context);;

      if (result["status"] == 200) {
        api.showSuccess("Done cleansing!"); 
        pendingTask["cleanse"] = CancelableOperation.fromFuture(fetchData("cleanse"));
      } else {
        api.showError("Error\nstatus: ${result['status']}\n msg: ${result['data']}");
      }
    }
  }

  void quickInfo(context) {
    if (duplicateItems > 0 ||
        invalidItems.isNotEmpty ||
        fatalItems.isNotEmpty ||
        diffItems.isNotEmpty) {
      showAdaptiveDialog(
        context: context,
        builder:
            (context) => AlertDialog.adaptive(
              icon: Icon(Icons.warning_amber_rounded),
              title: Text("Quick Info"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Oke"),
                ),
              ],
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    Text("beberapa item yang bisa diperbaiki:"),
                    SizedBox(height: 20),
                    fatalItems.isNotEmpty
                        ? ListTile(
                          leading: _fatalIcon,
                          title: Text(
                            "${fatalItems.length} anggota data tidak ditemukan",
                          ),
                          subtitle: Text(
                            "Data tidak ada di wilayah\nSolusi: Cleanse!",
                          ),
                        )
                        : Container(),
                    fatalItems.isNotEmpty && invalidItems.isNotEmpty
                        ? Divider()
                        : Container(),
                    invalidItems.isNotEmpty
                        ? ListTile(
                          leading: _invalidIcon,
                          title: Text(
                            "${invalidItems.length} anggota invalid",
                          ),
                          subtitle: Text("Umur anak > 6\nSolusi: Cleanse!"),
                        )
                        : Container(),
                    (fatalItems.isNotEmpty || invalidItems.isNotEmpty) &&
                            diffItems.isNotEmpty
                        ? Divider()
                        : Container(),
                    diffItems.isNotEmpty
                        ? ListTile(
                          leading: _diffIcon,
                          title: Text(
                            "${diffItems.length} anggota kki mismatch",
                          ),
                          subtitle: Text(
                            "Kode keluarga anggota berbeda dengan di Rekapitulasi SIGA\nSolusi: Cleanse!",
                          ),
                        )
                        : Container(),
                    (fatalItems.isNotEmpty ||
                                invalidItems.isNotEmpty ||
                                diffItems.isNotEmpty) &&
                            duplicateItems > 0
                        ? Divider()
                        : Container(),
                    duplicateItems > 0
                        ? ListTile(
                          leading: _duplicateIcon,
                          title: Text("$duplicateItems Anggota duplikat"),
                          subtitle: Text("Solusi: Hapus melalui web SIGA"),
                        )
                        : Container(),
                  ],
                ),
              ),
            ),
      );
    }
  }

  void cleanseAnggota() async {
    var cleanseItems = invalidItems + fatalItems + diffItems;
    cleanseItems.sort(
      (a, b) => int.parse(a["no"]).compareTo(int.parse(b["no"])),
    );
    if (cleanseItems.isNotEmpty) {
      var res = await showDialog(
        context: context,
        builder:
            (ctx) => CleanseDialog(
              cleanseItems: cleanseItems,
              cleanseCallback: doCleanse,
            ),
      );

      if (res != null) {
        if (res) {
          if (widget.jenis.toLowerCase() == "bkb") {
            doCleanse(cleanseItems);
          } else {
            ref.read(apiProvider).showError("masih belum bisaa");
          }
        }
      }
      
    } else {
      ref.read(apiProvider).showSuccess("Semua sampun valid !");
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

  @override
  Widget build(BuildContext context) {
    _fatalIcon = Icon(
      Icons.cancel_outlined,
      color: Theme.of(context).colorScheme.error,
    );
    _invalidIcon = Icon(
      Icons.remove_circle_outline_rounded,
      color: Theme.of(context).colorScheme.error,
    );
    _diffIcon = Icon(
      Icons.check_circle,
      color: ColorScheme.fromSeed(seedColor: Colors.amber).primaryContainer,
    );
    _duplicateIcon = Icon(Icons.compare_arrows_outlined);

    return Scaffold(
      appBar: AppBar(
        title: Text("Anggota BKB"),
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
                        child: Skeletonizer(
                          enabled: ref.watch(loadingState),
                          child: Container(
                            width: 536,
                            padding: EdgeInsets.all(8),
                            child: DataTableBKB(data: anggotaItem),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 96,
                  width: 556,
                  child: Skeletonizer(
                    enabled: ref.watch(loadingState),
                    child: InkWell(
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onLongPress: () => quickInfo(context),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 6,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          var icon = [
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
                              _fatalIcon.icon,
                              color: _fatalIcon.color,
                              size: 20,
                            ),
                            Icon(
                              _invalidIcon.icon,
                              color: _invalidIcon.color,
                              size: 20,
                            ),
                            Icon(
                              _diffIcon.icon,
                              color: _diffIcon.color,
                              size: 20,
                            ),
                            Icon(
                              _duplicateIcon.icon,
                              color: _duplicateIcon.color,
                              size: 20,
                            ),
                          ];

                          var valid =
                              anggotaItem
                                  .where(
                                    (ele) => ele["valid"] && !ele["kkiDiff"],
                                  )
                                  .toList();

                          var text = [
                            "${anggotaItem.length} total",
                            "${valid.length} valid",
                            "${fatalItems.length} tidak ditemukan",
                            "${invalidItems.length} invalid",
                            "${diffItems.length} KKI invalid",
                            "$duplicateItems duplikat",
                          ];

                          return SizedBox(
                            width: 160,
                            child: Card(
                              child: Container(
                                margin: EdgeInsets.all(10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 5,
                                  children: [
                                    icon[index],
                                    Text(
                                      text[index],
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

class CleanseDialog extends StatefulWidget {
  final List cleanseItems;
  final Function cleanseCallback;

  const CleanseDialog({
    super.key,
    required this.cleanseItems,
    required this.cleanseCallback,
  });

  @override
  State<StatefulWidget> createState() => _CleanseDialogState();
}

class _CleanseDialogState extends State<CleanseDialog> {
  @override
  Widget build(BuildContext context) {
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
              child: DataTableBKB(data: widget.cleanseItems, adaptive: true),
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

class DataTableBKB extends StatefulWidget {
  final List data;
  final bool adaptive;
  const DataTableBKB({super.key, required this.data, this.adaptive = false});

  @override
  State<StatefulWidget> createState() => _DataTableState();
}

class _DataTableState extends State<DataTableBKB> {
  @override
  Widget build(BuildContext context) {
    var headerStyle = TextTheme.of(context).bodyMedium!.copyWith(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    var itemStyle = TextTheme.of(context).bodyMedium!.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    var validIcon = Icon(
      Icons.check_circle,
      color: ColorScheme.fromSeed(seedColor: Colors.green).primary,
      size: 18,
      weight: 1,
    );
    var diffIcon = Icon(
      Icons.check_circle,
      color: ColorScheme.fromSeed(seedColor: Colors.amber).primaryContainer,
      size: 18,
      weight: 1,
    );
    var invalidIcon = Icon(
      Icons.remove_circle,
      color: Theme.of(context).colorScheme.error,
      size: 18,
      weight: 1,
    );
    var fatalIcon = Icon(
      Icons.cancel,
      color: Theme.of(context).colorScheme.error,
      size: 18,
      weight: 1,
    );

    return DataTable(
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
            "Nama Anak",
            style: headerStyle,
            textAlign: TextAlign.center,
          ),
          headingRowAlignment: MainAxisAlignment.center,
          columnWidth: FixedColumnWidth(160),
        ),
        DataColumn(
          label: Center(
            child: Text(
              "Usia\nAnak",
              maxLines: 2,
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
          headingRowAlignment: MainAxisAlignment.center,
          columnWidth: FixedColumnWidth(64),
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
        widget.data.isNotEmpty
        ? List.generate(widget.data.length, (i) {
          return DataRow(
            cells: [
              DataCell(
                Center(
                  child: Text(widget.data[i]["no"], style: itemStyle),
                ),
              ),
              DataCell(
                Tooltip(
                  message: widget.data[i]["nama"],
                  triggerMode: TooltipTriggerMode.longPress,
                  child: Text(
                    widget.data[i]["nama"],
                    style: itemStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              DataCell(
                Tooltip(
                  message: widget.data[i]["namaAnak"],
                  triggerMode: TooltipTriggerMode.longPress,
                  child: Text(
                    widget.data[i]["namaAnak"],
                    style: itemStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              DataCell(
                Center(
                  child: Text(
                    widget.data[i]["usiaAnak"],
                    style: itemStyle,
                  ),
                ),
              ),
              DataCell(
                Center(
                  child:
                      widget.data[i]["fatal"]
                          ? fatalIcon
                          : widget.data[i]["kkiDiff"] &&
                              widget.data[i]["valid"]
                          ? diffIcon
                          : widget.data[i]["valid"]
                          ? validIcon
                          : invalidIcon,
                ),
              ),
            ],
            color:
                widget.data[i]["duplicate"]
                    ? WidgetStatePropertyAll(
                      Theme.of(context).highlightColor,
                    )
                    : null,
          );
        }).toList()
      : List.filled(
        50,
        DataRow(
          cells: [
            DataCell(Text("00", style: itemStyle)),
            DataCell(Text("data", style: itemStyle)),
            DataCell(Text("data", style: itemStyle)),
            DataCell(Text("0", style: itemStyle)),
            DataCell(Text("100", style: itemStyle)),
          ],
        ),
      ),
    );
  }
}