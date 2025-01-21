import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';



class KdSettings extends StatefulWidget{
  const KdSettings({super.key});

  @override
  State<KdSettings> createState() => _KdSettingsState();
}

class _KdSettingsState extends State<KdSettings>{

  //debug
  late List <String> AreaList;
  late List <String> FormatList;
  int cnt = 0;
  int egg = 0;
  late bool isSwitch;
  var EasterEggColor = Color.fromRGBO(254, 247, 255, 0);
  final TextEditingController _controller_noti = TextEditingController();

@override
  void initState(){
    super.initState();
    _read_shprefs();
  }

  void _read_shprefs() async{
    final shprefs = await SharedPreferences.getInstance();
    setState((){
      cnt = shprefs.getInt('count_easter_egg')!;
      _controller_noti.text = shprefs.getInt('notification_time').toString();
      //_controller_noti.text ??= '';
      isSwitch = shprefs.getBool('notification_tf')!;
      //isSwitch ??= false; // nullならfalseに
    }); // cntに読み出し
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
            child:Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Spacer(),

                  Material(
                    child: Ink.image(
                      height: 100,
                      width:240,
                      image: const AssetImage('assets/images/kadahira-lbb-v2.png'),
                      fit: BoxFit.cover,
                      child: InkWell(
                          onTap:() async {  // tapping more than ten times to appear the Easter Egg content
                            egg++;
                            if(egg>9){setState(() {
                              EasterEggColor = Colors.black87;
                            });
                            }
                          },
                          splashColor: Colors.white.withOpacity(0.2)//withOpacity:add opacity
                      ),
                    ),
                  ),


                  const Padding(
                    padding: EdgeInsets.only(top:20,),
                    child: Text (
                      'カダイがでたらヒラくやつ β0.3',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    )
                  ),

                  const Padding(
                      padding: EdgeInsets.only(top:10),
                      child: Text (
                        '©︎2024 v_tnta',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54),
                      )
                  ),

                  const Padding(
                      padding: EdgeInsets.only(top:10, bottom:26),
                      child: Text (
                        'Thank you for using !',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                      )
                  ),

                  // Easter Egg //
                  Padding(
                      padding: EdgeInsets.only(bottom:24),
                      child: Text (
                            '今までこなしてきた課題の数:$cnt',
                            style: TextStyle(color: EasterEggColor),
                          )
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                            "提出〆切の",
                            style: TextStyle(
                                fontSize: 18
                            )
                        ),
                        SizedBox(
                          width:20,
                          child:TextFormField(
                            controller: _controller_noti,
                            keyboardType: TextInputType.text,
                            onChanged:(input) async {
                              final shprefs = await SharedPreferences.getInstance();
                              // 入力を整数に変換して保存
                              if (int.tryParse(input) != null) {
                                shprefs.setInt('notification_time', int.parse(input));
                              }
                            }
                          ),
                        ),
                        const Text(
                          "分前に通知",
                          style: TextStyle(
                            fontSize: 18
                          )
                        ),

                        const SizedBox(width:10),

                        Switch(
                            value: isSwitch,
                            onChanged: (val) async{
                              final shprefs = await SharedPreferences.getInstance();

                              if (val==true){
                                shprefs.setBool('notification_tf', true);
                              }else{
                                shprefs.setBool('notification_tf', false);
                              }
                              setState((){
                                isSwitch = val; // 状態を更新
                              });
                            }
                        )
                      ],
                    )
                  ),

                  const SizedBox(width: 8),

                  TextButton(
                      onPressed: (){
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                        },
                      child: const Text('< Back',
                          style: TextStyle(fontSize: 16, color: Colors.indigo)
                    ),
                  ),

                  Spacer(),
                  Spacer()
            ]
          ),
        )
      );
  }
}