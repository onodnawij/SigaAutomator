import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:siga/providers/api_provider.dart';
import 'package:siga/providers/dashboard.dart';
import 'package:siga/providers/register_provider.dart';
import 'package:siga/utils/block_ui.dart';
import 'package:siga/utils/extensions.dart';
import 'package:siga/utils/string_utility.dart' show parseAutoDate, textSplit;
import 'package:siga/vars.dart';

final _formDataProvider = StateProvider<Map>((ref) => {
  'materi': [],
  "materiLainnya": "",
  'narasumber': [],
  "narasumberLainnya": "",
  'maxPeserta': null,
  'perempuan': null,
});

enum FormGroup {narasumber, materi}

class R1Page extends ConsumerStatefulWidget {
  final String menu;
  final String jenis;
  final String mode;
  final dynamic options;
  
  const R1Page({super.key, required this.menu, required this.jenis, required this.mode, required this.options});

  @override
  ConsumerState<R1Page> createState() => _R1PageState();
}

class _R1PageState extends ConsumerState<R1Page> {
  bool _isFinalized = false;
  final TextEditingController tanggalController = TextEditingController();
  late DateTime selectedDate;
  bool perempuanOnly = false;
  TextEditingController maxPesertaController = TextEditingController.fromValue(TextEditingValue(text: '15'));
  List<bool> narasumberList = [];
  List<bool> materiList = [];
  final TextEditingController narasumberLainnyaController = TextEditingController();
  final TextEditingController materiLainnyaController = TextEditingController();
  late String title;
  int? index;
  late Map kelompok;
  // Map<String, dynamic> formData = {
  //   'materi': [],
  //   "materiLainnya": "",
  //   'narasumber': [],
  //   "narasumberLainnya": "",
  //   'maxPeserta': null,
  //   'perempuan': null,
  // };

  @override
  void initState() {
    index = widget.options[0];
    kelompok = widget.options[1];
    title = '${widget.mode.capitalize} Register ${widget.jenis.toUpperCase()} - ${kelompok["namaKelompok"]}';
    super.initState();    
  }

  @override
  void dispose() {
    tanggalController.dispose();
    maxPesertaController.dispose();
    narasumberLainnyaController.dispose();
    materiLainnyaController.dispose();
    super.dispose();
  }

  Future<void> showConfirm(context) async {
    final formDataState = ref.read(_formDataProvider);
    
    List materi = materiPoktan[widget.jenis.toLowerCase()].sublist(1).where((e) {
      return formDataState["materi"][materiPoktan[widget.jenis.toLowerCase()].indexOf(e)-1] == true;
    },).toList();

    List narasumber = narsumPoktan.values.where((value) {
      return formDataState["narasumber"][narsumPoktan.values.toList().indexOf(value)] == true;
    }).toList();

    List<Widget> narsumExpandChild = List<Widget>.generate(narasumber.length, (index) => ListTile(title: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 24, child: Text("${index + 1}.")), Expanded(child: Text("${narasumber[index]}", style: TextTheme.of(context).labelLarge,))],),));
    List<Widget> materiExpandChild = List<Widget>.generate(materi.length, (index) => ListTile(title: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 24, child: Text("${index + 1}.")), Expanded(child: Text("${materi[index]}", style: TextTheme.of(context).labelLarge))],),));

    if (formDataState["narasumberLainnya"].isNotEmpty) {
      narsumExpandChild.add(ListTile(title: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 24, child: Text("${narsumExpandChild.length + 1}.", style: TextTheme.of(context).labelLarge)), Expanded(child: Text(formDataState["narasumberLainnya"], style: TextTheme.of(context).labelLarge,))])));
    }
    if (formDataState["materiLainnya"].isNotEmpty) {
      materiExpandChild.add(ListTile(title: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 24, child: Text("${materiExpandChild.length + 1}.", style: TextTheme.of(context).labelLarge)), Expanded(child: Text(formDataState["materiLainnya"], style: TextTheme.of(context).labelLarge,))])));
    }

    showAdaptiveDialog(context: context, builder: (context) {
      return AlertDialog.adaptive(
        actions: [
          TextButton(onPressed: (){Navigator.pop(context);}, child: Text("gajadi", style: TextStyle(color: Theme.of(context).colorScheme.error),),),
          FilledButton(style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.tertiaryContainer.withAlpha(32))), onPressed: (){Navigator.pop(context);doSubmit(context);}, child: Text("lesgo", style: TextStyle(color: Theme.of(context).colorScheme.tertiary),),),
        ],
        icon: Icon(Icons.warning_amber_rounded),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("Tanggal Kegiatan"),
              titleTextStyle: TextTheme.of(context).labelLarge!.copyWith(fontWeight: FontWeight.bold),
              subtitle: Text(formDataState["tanggal"].toString()),
            ),
            ExpansionTile(
              childrenPadding: EdgeInsets.only(left: 10),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Narasumber:", style: TextTheme.of(context).labelLarge!.copyWith(fontWeight: FontWeight.bold)),
                  Text("[ ${narsumExpandChild.length} ]", style: TextTheme.of(context).labelSmall!.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              children: narsumExpandChild,
            ),
            ExpansionTile(
              childrenPadding: EdgeInsets.only(left: 10),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Materi:", style: TextTheme.of(context).labelLarge!.copyWith(fontWeight: FontWeight.bold)),
                  Text("[ ${materiExpandChild.length} ]", style: TextTheme.of(context).labelSmall!.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              children: materiExpandChild,
            ),
            ListTile(
              title: Text("Max Peserta"),
              titleTextStyle: TextTheme.of(context).labelLarge!.copyWith(fontWeight: FontWeight.bold),
              subtitle: Text(formDataState["maxPeserta"].toString()),
            ),
          ],
        ),
        iconColor: Theme.of(context).colorScheme.error,
        title: Text("Kamu yakin ?"),
        scrollable: true,
      );},
    );
  }

  Future<void> doSubmit(_) async {
    final api = ref.read(apiProvider);
    final formDataState = ref.read(_formDataProvider);
    
    if ((formDataState["materi"] as List).any((elem) => elem)) {
      if ((formDataState["narasumber"] as List).any((elem) => elem)) {
        if (formDataState["maxPeserta"] != null && maxPesertaController.text.isNotEmpty) {
          blockUI(context);
          api.showLoading(message: "Bentar yaa...");
          final ret = await api.autoKegiatan(
            item: kelompok,
            data: formDataState,
            jenis: widget.jenis.toLowerCase(),
            editItem: widget.mode == "edit");
          await EasyLoading.dismiss();
          unblockUI(context);

          if (ret) {
            ref.read(rekapPoktanProvider).refresh();
            Navigator.of(context).pop(true);
            api.showSuccess("Auto Kegiatan Sukses!");
          } else {
            api.showError("Gagal, gatau kenapa");
          }
          return;
        }
      }
    }
    
    api.showError("Form kurang lengkap\nPastikan semua bagian terisi !");
  }

  Future<void> showDate (context) async {
    if (widget.mode == 'new') {
      var now = DateTime.now();
      var start = DateTime(now.year, now.month - 3, 1);
      final date = await showDatePicker(context: context, firstDate: start, lastDate: now, initialDate: selectedDate, locale: Locale('id', 'ID'));

      if (date == null) {
        return;
      }

      selectedDate = date;
      tanggalController.text = DateFormat('dd-MM-yyyy', 'id_ID').format(selectedDate);
      updateFormData();
    }
  }

  void onFormChecked (bool value, int index, FormGroup group) {
    final formDataState = ref.read(_formDataProvider.notifier).state;
    if (group == FormGroup.materi) {
      // materiList[index] = value;
      formDataState["materi"][index] = value;
    } else if (group == FormGroup.narasumber) {
      // narasumberList[index] = value;
      formDataState["narasumber"][index] = value;
    }
  }

  void updateFormData () {
    final formDataState = ref.read(_formDataProvider.notifier).state;
    formDataState["tanggal"] = tanggalController.text;
    formDataState['maxPeserta'] = int.tryParse(maxPesertaController.text) ?? -1;
    formDataState['perempuan'] = perempuanOnly;
    formDataState['narasumber'] = narasumberList;
    formDataState["narasumberLainnya"] = narasumberLainnyaController.text;
    formDataState['materi'] = materiList;
    formDataState["materiLainnya"] = materiLainnyaController.text;

    setState((){});
  }

  void prebuild() {
    final registers = ref.read(registerListProvider);
    Map? item = registers.elementAtOrNull(index ?? registers.length + 1);
    selectedDate = parseAutoDate(item?["tanggalKegiatan"]) ?? DateTime.now();
    materiList = List.filled(materiPoktan[widget.jenis.toLowerCase()].length, false);
    narasumberList = List.filled(narsumPoktan.values.length + 1, false);
    item?.forEach((k, v) {
      String key = k.toString();
      String value = v.toString();

      if (key.startsWith("penyajiNaraSumber")) {
        if (key.endsWith("Lainnya")) {
          narasumberList[narasumberList.length - 1] = value == "1";
        } else if (!key.endsWith("Deskripsi")) {
          narasumberList[narsumPoktan.keys.toList().indexOf(key.replaceAll("penyajiNaraSumber", ""))] = value == "1";
        } else {
          narasumberLainnyaController.text = value == "null" ? "" : value;
        }
      } else if (key.startsWith("materiPenyuluhan")) {
        if (key.endsWith("Lainnya")) {
          materiList[materiList.length - 1] = value == "1";
        } else if (!key.endsWith("Deskripsi")) {
          materiList[int.parse(key.replaceAll("materiPenyuluhan", "")) - 1] = value == "1";
        } else {
          materiLainnyaController.text = value == "null" ? "" : value;
        }
      }
    });
    
    tanggalController.text = DateFormat('dd-MM-yyyy', 'id_ID').format(selectedDate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateFormData();
    });
    _isFinalized = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFinalized) {
      prebuild();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actionsPadding: appActionsPadding,
        actions: [appOptions(context)],
        forceMaterialTransparency: true,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(14, 5, 14, 14),
        child: CustomScrollView(
          slivers: [
            SliverList(delegate: SliverChildListDelegate.fixed(
              [
                Divider(),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.only(left: 6),
                  child: Text('Tanggal Kegiatan :', style: TextStyle(
                    fontSize: TextTheme.of(context).titleMedium!.fontSize! + 2,
                    fontWeight: FontWeight.bold,
                  )),
                ),
                SizedBox(height: 6),
              ]
            ),),
            SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4, // Space between columns
                // mainAxisSpacing: 4,  // Space between row
                mainAxisExtent: 64,
              ),
              itemCount: 1, // Number of items
              itemBuilder: (context, index) {
                return Card(
                  child: TextField(
                    readOnly: true,
                    controller: tanggalController,
                    onTap: () {
                      showDate(context);
                    },
                    textAlign: TextAlign.center,
                    enableInteractiveSelection: false,
                    decoration: InputDecoration(
                      
                      filled: false,
                      suffixIconColor: Theme.of(context).primaryColor,
                      suffixIcon: IconButton(onPressed: (){
                        showDate(context);
                      }, icon: Icon(Icons.calendar_month_outlined))
                    ),
                  ),
                );
              }
            ),
            SliverList(delegate: SliverChildListDelegate.fixed(
              [
                Divider(),
                SizedBox(height: 10,),
                Container(
                  padding: EdgeInsets.only(left: 6),
                  child: Text('Narasumber :', style: TextStyle(
                    fontSize: TextTheme.of(context).titleMedium!.fontSize! + 2,
                    fontWeight: FontWeight.bold,
                  )),
                ),
              ]
            ),),
            SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4, // Space between columns
                mainAxisSpacing: 4,  // Space between row
                mainAxisExtent: 75,
              ),
              itemCount: narasumberList.length - 1, // Number of items
              itemBuilder: (context, index) {
                int row = index % 2;
                int col = index ~/ 2;
                int newIndex = row * ((narasumberList.length) ~/ 2) + col;
                return FormGridItem(
                  index: newIndex,
                  readOnly: widget.mode == 'view',
                  content: narsumPoktan[narsumPoktan.keys.toList()[newIndex]],
                  group: FormGroup.narasumber,
                  onChanged: onFormChecked,
                  initValue: narasumberList[newIndex],
                );
              }
            ),
            SliverList(
              delegate: SliverChildListDelegate.fixed(
                [
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 90,
                          child: FormGridItem(
                            index: narasumberList.length - 1,
                            readOnly: widget.mode == 'view',
                            content: "Lainnya",
                            group: FormGroup.narasumber,
                            controller: narasumberLainnyaController,
                            initValue: narasumberList.lastOrNull,
                            onChanged: onFormChecked,
                          )
                        ),
                      ),
                      Expanded(
                        child: Container(),
                      ),
                    ],
                  ),
                ]
              ),
            ),
            SliverList(delegate: SliverChildListDelegate.fixed(
              [
                Divider(),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.only(left: 6),
                  child: Text('Materi :', style: TextStyle(
                    fontSize: TextTheme.of(context).titleMedium!.fontSize! + 2,
                    fontWeight: FontWeight.bold,
                  )),
                ),
              ]
            ),),
            SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4, // Space between columns
                mainAxisSpacing: 4,  // Space between row
                mainAxisExtent: 90,
              ),
              itemCount: materiList.length - 1, // Number of items
              itemBuilder: (context, index) {
                int row = index % 2;
                int col = index ~/ 2;
                int newIndex = row * ((materiList.length) ~/ 2) + col;
                return FormGridItem(
                  index: newIndex,
                  readOnly: widget.mode == 'view',
                  content: materiPoktan[widget.jenis.toLowerCase()][newIndex + 1],
                  group: FormGroup.materi,
                  onChanged: onFormChecked,
                  initValue: materiList[newIndex],
                );
              }
            ),
            SliverList(
              delegate: SliverChildListDelegate.fixed(
                [
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 90,
                          child: FormGridItem(
                            index: materiList.length - 1,
                            content: "Lainnya",
                            readOnly: widget.mode == 'view',
                            group: FormGroup.materi,
                            controller: materiLainnyaController,
                            initValue: materiList.lastOrNull,
                            onChanged: onFormChecked,
                          )
                        ),
                      ),
                      Expanded(
                        child: Container(),
                      ),
                    ],
                  ),
                ]
              ),
            ),
            SliverList(delegate: SliverChildListDelegate.fixed(
              [
                SizedBox(height: 10),
                ExpansionTile(
                  minTileHeight: 0,
                  showTrailingIcon: false,
                  enabled: false,
                  initiallyExpanded: widget.mode != 'view',
                  title: Text(''),
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(widget.mode == 'view'?'':'Submit :', style: TextStyle(
                            fontSize: TextTheme.of(context).titleMedium!.fontSize! + 2,
                            fontWeight: FontWeight.bold,
                          )),
                        ),
                      ],
                    ),
                    Column(
                      spacing: 12,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text('Max Peserta')
                            ),
                            SizedBox(width: 20, child: Text(':')),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                textAlign: TextAlign.center,
                                style: TextTheme.of(context).labelLarge,
                                keyboardType: TextInputType.number,
                                controller: maxPesertaController,
                                onChanged: (value) {
                                  updateFormData();
                                },
                                onSubmitted: (value) {
                                  if (value == "") {
                                    maxPesertaController.text = "0";
                                    updateFormData();
                                  }
                                },
                                inputFormatters: [
                                  TextInputFormatter.withFunction((oldValue, newValue) {
                                    return (newValue.text.isNum || newValue.text == "")
                                      ? newValue
                                      : oldValue;
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text('Hanya Perempuan')
                            ),
                            SizedBox(width: 20, child: Text(':')),
                            SizedBox(
                              width: 60,
                              child: Switch(value: perempuanOnly, onChanged: (value){
                                setState(() {
                                  perempuanOnly = !perempuanOnly;
                                });
                              })
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 30,),
                    SizedBox(
                      height: 40,
                      width: 100,
                      child: FittedBox(
                        child: FilledButton.icon(
                          onPressed: (){
                            if (maxPesertaController.text.isEmpty) {
                              maxPesertaController.text = "0";
                              updateFormData();
                            }
                            showConfirm(context);
                          }, 
                          label: Text('Submit'),
                          icon: Icon(Icons.send),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                )
              ]
            ),),
          ],
        ),
      ),
    );
  }
}


class FormGridItem extends ConsumerStatefulWidget {
  final FormGroup group;
  final int index;
  final String content;
  final bool? initValue;
  final Function? onChanged;
  final bool? readOnly;
  final TextEditingController? controller;
  const FormGridItem({super.key, required this.index, required this.content, this.onChanged, this.initValue, required this.group, this.readOnly, this.controller});

  @override
  ConsumerState<FormGridItem> createState() => _FormGridItemState();
}

class _FormGridItemState extends ConsumerState<FormGridItem> {
  bool? isActive;

  void selfToggle() {
    if (widget.readOnly ?? false) {
      return;
    }
    setState(() {
      isActive = !isActive!;
    });

    if (widget.onChanged != null) {
      widget.onChanged!(isActive, widget.index, widget.group);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valueState = ref.watch(_formDataProvider);
    final bool? curValue = List.from(valueState[
      widget.group == FormGroup.materi
        ? "materi"
        : "narasumber"
    ]).elementAtOrNull(widget.index);
    
    isActive = curValue ?? false;

    List<Widget> contents = [
      Text(widget.content,
      semanticsLabel: widget.content,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      ),
    ];

    if (widget.content == "Lainnya") {
      var k = widget.group == FormGroup.materi
        ? "materiLainnya"
        : "narasumberLainnya";
      contents = [TextField(
        readOnly: widget.readOnly ?? false,
        controller: widget.controller,
        style: TextTheme.of(context).labelLarge,
        onChanged: (value) {
          ref.read(_formDataProvider.notifier).state[k] = value;
        },
        decoration: InputDecoration(
          filled: true,
          label: Text("Lainnya :"),
          hintText: widget.group == FormGroup.materi ? "Materi Lainnya" : "Narasumber Lainnya",
          hintStyle: TextStyle(fontStyle: FontStyle.italic),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      )];
    }
    
    return Tooltip(
      triggerMode: TooltipTriggerMode.longPress,
      richMessage: TextSpan(text: textSplit(widget.content).join("\n")),
      child: Card(
        child: InkWell(
          onTap: widget.content != "Lainnya"? () {
            selfToggle();
          } : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              spacing: 4,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: contents,
                  ),
                ),
                Wrap(
                  children: [
                    Checkbox.adaptive(value: isActive, onChanged: (value){
                      selfToggle();
                    })
                  ],
                )
              ],
            ),
          ),
        )
      ),
    );
  }
}