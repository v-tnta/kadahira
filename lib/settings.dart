import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KdSettings extends StatefulWidget {
  const KdSettings({super.key});
  @override
  State<KdSettings> createState() => _KdSettingsState();
}

class _KdSettingsState extends State<KdSettings> {
  int cnt = 0;
  int egg = 0;
  bool isSwitch = false;
  Color EasterEggColor = const Color.fromRGBO(254, 247, 255, 0);
  final TextEditingController _controller_noti = TextEditingController();

  @override
  void initState() {
    super.initState();
    _readSharedPrefs();
  }

  void _readSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      cnt = prefs.getInt('count_easter_egg') ?? 0;
      int? notiTime = prefs.getInt('notification_time');
      _controller_noti.text = notiTime?.toString() ?? '10';
      isSwitch = prefs.getBool('notification_tf') ?? false;
    });

    // debug log
    debugPrint("count_easter_egg: $cnt");
    debugPrint("notification_time: ${_controller_noti.text}");
    debugPrint("notification_tf: $isSwitch");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Image.asset(
            'assets/images/kadahira-blkb-v2.png',
            fit: BoxFit.contain,
            height: 80,
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                Material(
                  child: Ink.image(
                    height: 100,
                    width: 240,
                    image:
                    const AssetImage('assets/images/kadahira-lbb-v2.png'),
                    fit: BoxFit.cover,
                    child: InkWell(
                      onTap: () {
                        egg++;
                        if (egg > 9) {
                          setState(() {
                            EasterEggColor = Colors.black87;
                          });
                        }
                      },
                      splashColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),

                const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      'カダイがでたらヒラくやつ v1.3.0',
                      style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    )),

                const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      '©︎2024 v_tnta',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54),
                    )),

                const Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 26),
                    child: Text(
                      'Thank you for using !',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    )),

                Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      '今までこなしてきた課題の数: $cnt',
                      style: TextStyle(color: EasterEggColor),
                    )),

                Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "提出〆切の",
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(
                          width: 40,
                          child: TextFormField(
                              textAlign: TextAlign.center,
                              controller: _controller_noti,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              onChanged: (input) async {
                                final prefs = await SharedPreferences.getInstance();
                                final intVal = int.tryParse(input);
                                if (intVal != null) {
                                  await prefs.setInt('notification_time', intVal);
                                  debugPrint("notification_time: $intVal");
                                }else{
                                  await prefs.setInt('notification_time', 10);
                                  debugPrint("notification_time: 10");
                                }
                              }),
                        ),
                        const Text(
                          "分前",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          "に通知",
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 10),
                        Switch(
                            value: isSwitch,
                            onChanged: (val) async {
                              final prefs =
                              await SharedPreferences.getInstance();
                              await prefs.setBool('notification_tf', val);
                              setState(() {
                                isSwitch = val;
                              });
                              debugPrint("notification_tf: $val");
                            })
                      ],
                    )),

                const SizedBox(width: 8),

                TextButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
                  },
                  child: const Text('< Back',
                      style: TextStyle(fontSize: 16, color: Colors.indigo)),
                ),

                const Spacer(),
                const Spacer(),
              ]),
        ));
  }
}