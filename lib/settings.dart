import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';



class KdSettings extends StatefulWidget{
  const KdSettings({super.key});

  @override
  _KdSettingsState createState() => _KdSettingsState();
}

class _KdSettingsState extends State<KdSettings>{
  String? isSelectedItem = 'aaa';

  //debug
  late List <String> AreaList;
  late List <String> FormatList;
  int cnt = 0;
  int egg = 0;
  var EasterEggColor = Color.fromRGBO(254, 247, 255, 0);

@override
  void initState(){
    super.initState();
    _read_count();
  }

  Future <void> _read_count() async{
    final shprefs = await SharedPreferences.getInstance();
    setState((){
      cnt = shprefs.getInt('count_easter_egg')!;
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
                mainAxisAlignment: MainAxisAlignment.start,
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
                      'カダイがでたらヒラくやつ β0.1',
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