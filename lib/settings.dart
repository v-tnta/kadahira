import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class KdSettings extends StatefulWidget{
  @override
  _KdSettingsState createState() => _KdSettingsState();
}


class _KdSettingsState extends State<KdSettings>{
  String? isSelectedItem = 'aaa';

  //debug
  late List <String> AreaList;
  late List <String> FormatList;


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
                  Text (
                    '今までに倒した課題の累計数:'
                  ),

                  TextButton(
                      onPressed: (){
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                        },
                      child: const Text('< Back <')
              )
            ]
          ),
        )
      );
  }

}