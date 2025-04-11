import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:siga/providers/api_provider.dart';
import 'package:siga/providers/listing_provider.dart';
import 'package:siga/providers/register_provider.dart';
import 'package:siga/utils/string_utility.dart' show formatDateLocalized;
import 'package:siga/vars.dart';
import 'package:skeletonizer/skeletonizer.dart';

class RegisterPage extends ConsumerStatefulWidget {
  final dynamic index;
  final String menu;
  final String jenis;

  const RegisterPage({super.key, required this.index, required this.menu, required this.jenis});
  
  
  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();  
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  List? kegiatanList;
  bool isLoading = true;

  void fetchData () async {
    final api = ref.read(apiProvider);
    var items = ref.read(listingCacheProvider)[ref.read(listingKeyProvider)]!;
    var idPoktan = items[widget.index]["id"];
    kegiatanList = await api.getPoktanKegiatan(
      idPoktan: idPoktan,
      jenis: widget.jenis
    );

    if (mounted) {
      ref.read(registerListProvider.notifier).state = kegiatanList!;
    }

    if (mounted) {
      setState(() {
        isLoading = false; 
    });
    }
  }

  void viewForm (int? index, String mode, Map kelompok) {
    final String route = ['', widget.menu, widget.jenis, 'register', mode].join('/');
    Navigator.of(context).pushNamed(route, arguments: [index, kelompok]).then((value) {
      if (value == true) {
        setState(() {
          isLoading = true;
        });
        fetchData();
      }
    },);
  }
  
  @override
  void initState() {
    fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var kelompok = ref.read(listingCacheProvider)[ref.read(listingKeyProvider)]?[widget.index];
    var namaKelompok = kelompok["namaKelompok"] ?? "${widget.index}";
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Register ${widget.jenis.toUpperCase()} - $namaKelompok'),
        forceMaterialTransparency: true,
        actions: [
          IconButton(
            onPressed: () async {
              viewForm(null, "new", kelompok);
            },
            icon: Icon(Icons.add_circle_outline)
          ),
          appOptions(context)
        ],
        actionsPadding: appActionsPadding,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(14, 3, 14, 8),
        child: CustomScrollView(
          slivers: [
            Skeletonizer.sliver(
              enabled: isLoading,
              child: SliverList(
                delegate: SliverChildBuilderDelegate((ctx, index) {
                  Map?item = kegiatanList?[index];
                  final String tanggalKegiatan = formatDateLocalized((item?["tanggalKegiatan"] ?? "01-01-2020"), context);
                  final int hadir = item?['pesertaKegiatan'].length ?? 0;
                  var narsums = [];
                  var materis = [];

                  item?.forEach((k, v) {
                    var key = k.toString();
                    var value = v.toString();

                    if (key.startsWith("penyajiNaraSumber")) {
                      if (value == "1" && !key.endsWith("Deskripsi")) {
                        var narsum = "";
                        if (key.endsWith("Lainnya")) {
                          String nars = item["penyajiNaraSumberLainnyaDeskripsi"] ?? "";
                          narsum =  "${nars.isEmpty ? "..." : nars} (Lainnya)";
                        } else {
                          narsum = narsumPoktan[key.replaceAll('penyajiNaraSumber', "")];
                        }
                        
                        narsums.add(narsum);
                      }
                    } else if (key.startsWith("materiPenyuluhan")) {
                      if (value == "1" && !key.endsWith("Deskripsi")) {
                        var materi = "";
                        if (key.endsWith("Lainnya")) {
                          materi = item["materiPenyuluhanLainnyaDeskripsi"] ?? "";
                        } else {
                          materi = materiPoktan[widget.jenis.toLowerCase()][int.parse(key.replaceAll('materiPenyuluhan', ""))];
                        }
                        
                        materis.add(materi);
                      }
                    }
                  });
                  
                  final String narsum = narsums.join(", ");
                  final String materi = materis.join(", ");
                  return MyListItem(menu: widget.menu, jenis: widget.jenis, tanggal: tanggalKegiatan, hadir: hadir, materi: materi, narsum: narsum, index: index, kelompok: kelompok, navCallback: viewForm,);
                },
                childCount: kegiatanList?.length ?? 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyListItem extends StatefulWidget {
  final String menu;
  final String jenis;
  final String tanggal;
  final int hadir;
  final String narsum;
  final String materi;
  final int index;
  final Map kelompok;
  final Function navCallback;
  
  const MyListItem({super.key, required this.menu, required this.jenis, required this.tanggal, required this.hadir, required this.narsum, required this.materi, required this.index, required this.kelompok, required this.navCallback});

  @override
  State<MyListItem> createState() => _MyListItemState();
}

class _MyListItemState extends State<MyListItem> {

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            SizedBox(
              width: 65,
              child: Center(
                child: Text(widget.tanggal, textAlign: TextAlign.center,),
              ),
            ),
            SizedBox(width: 10,),
            Expanded(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hadir'),
                      Text('Narasumber'),
                      Text('Materi'),
                    ],
                  ),
                  SizedBox(width: 10,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(':'),
                      Text(':'),
                      Text(':'),
                    ],
                  ),
                  SizedBox(width: 10,),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.hadir.toString(), overflow: TextOverflow.ellipsis, softWrap: false, maxLines: 1,),
                        Text(widget.narsum, overflow: TextOverflow.ellipsis,softWrap: false, maxLines: 1),
                        Text(widget.materi, overflow: TextOverflow.ellipsis,softWrap: false, maxLines: 1),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(onPressed: (){
                  widget.navCallback(widget.index, "edit", widget.kelompok);
                }, icon: Icon(Icons.edit_outlined), style: ButtonStyle(iconSize: WidgetStatePropertyAll(20))),
                IconButton(onPressed: (){
                  widget.navCallback(widget.index, "view", widget.kelompok);
                }, icon: Icon(Icons.search_outlined),style: ButtonStyle(iconSize: WidgetStatePropertyAll(20)))
              ],
            ),
          ],
        ),
      ),
    );
  }
}