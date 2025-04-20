import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:siga/pages/anggota/bkb.dart';
import 'package:siga/pages/anggota/bkl.dart';

final loadingState = StateProvider((ref) => false);

class AnggotaPage extends ConsumerStatefulWidget {
  final dynamic index;
  final String menu;
  final String jenis;

  const AnggotaPage({
    super.key,
    this.index,
    required this.menu,
    required this.jenis,
  });

  @override
  ConsumerState<AnggotaPage> createState() => _AnggotaPageState();
}

class _AnggotaPageState extends ConsumerState<AnggotaPage> {
  @override
  Widget build(BuildContext context) {
    if (widget.jenis.toLowerCase() == "bkb") {
      return AnggotaPageBKB(index: widget.index, menu: widget.menu, jenis: widget.jenis);
    } else if (widget.jenis.toLowerCase() == "bkl") {
      return AnggotaPageBKL(index: widget.index, menu: widget.menu, jenis: widget.jenis);
    }
    
    return Scaffold();
  }
}

class TambahAnggotaSheet extends StatefulWidget {
  const TambahAnggotaSheet({super.key});

  @override
  State<StatefulWidget> createState() => _TambahAnggotaSheetState();
}

class _TambahAnggotaSheetState extends State<TambahAnggotaSheet> {
  int currentValue = 1;

  @override
  Widget build(context) {
    return Container(
      width: 400,
      padding: EdgeInsets.fromLTRB(8, 8, 8, 28),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Text("Tambah Anggota"),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60,
                  child: Card.outlined(
                    child: NumberPicker(
                      textStyle: TextTheme.of(context).labelLarge,
                      selectedTextStyle: TextTheme.of(
                        context,
                      ).titleLarge!.copyWith(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      minValue: 1,
                      maxValue: 20,
                      value: currentValue,
                      itemCount: 3,
                      itemHeight: 24,
                      infiniteLoop: true,
                      onChanged: (value) {
                        setState(() {
                          currentValue = value;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Wrap(
                  direction: Axis.vertical,
                  children: [
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          currentValue =
                              currentValue == 20 ? 1 : currentValue + 1;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          currentValue =
                              currentValue == 1 ? 20 : currentValue - 1;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            Container(
              width: 400,
              padding: const EdgeInsets.fromLTRB(80, 10, 80, 10),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              label: Text('Submit'),
              icon: Icon(Icons.send_rounded),
              style: ButtonStyle(elevation: WidgetStatePropertyAll(3)),
              onPressed: () {
                Navigator.of(context).pop(currentValue);
              },
            ),
          ],
        ),
      ),
    );
  }
}
