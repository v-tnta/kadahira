import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'kadaidata.dart';
import 'dbhelper.dart';

// pubspec.yaml was incorrect!!!

// SaveData
Future<void> saveLocalData(kadaidata submit) async {
  DatabaseHelper dbHelper = DatabaseHelper();
  Map<String, dynamic> record = {
    'name': submit.name,
    'datetime': submit.datetime,
    'area': submit.area,
    'format': submit.format,
    'timestamp': submit.timestamp,
  };
  await dbHelper.insertRecord(record).then((id) { // then contains the return value
    submit.id=id;
    debugPrint('Record inserted with id: ${submit.id}');
  }).catchError((error) {
    debugPrint('Error inserting record: $error');
  });
}

class Submit extends StatefulWidget {
  const Submit({super.key});

  @override
  _SubmitState createState() => _SubmitState();
}

class _SubmitState extends State<Submit> {

  // for data saving
  final shardPreferences = SharedPreferences.getInstance();

  // kadailist class
  kadaidata submit = kadaidata(0, '', '', '', '', 0);

  // DateFomatter
  DateFormat formatter = DateFormat('yyyy-M-d HH:mm');

  // DateTime for Date Time picker default
  DateTime dtdef = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59);

  // TextEditingController を定義して TextField に使う
  final TextEditingController _dateController = TextEditingController();
  // TextEditingControllerを使用して値を管理
  final TextEditingController _controllerone = TextEditingController();
  final TextEditingController _controllertwo = TextEditingController();


  @override
  void initState() { // execute when app wakeup
    super.initState();
    Timer.periodic(const Duration(seconds: 1), _onTimer); // execute _onTimer for each one second
    // 初期値を設定
    _controllerone.text = '0';
    _controllertwo.text = '1';
  }

  void _onTimer(Timer timer) {
    if (mounted){ // avoid calling _ontimer after executing dispose()
      setState((){
        DateFormat('HH:mm:ss').format(DateTime.now());
      });
    }
  }

  void setText(){
    _controllerone.text = 'manaba';
    _controllertwo.text = 'PDF';
  }


  @override
  void dispose() {
    // TextEditingControllerの破棄
    _dateController.dispose();
    _controllerone.dispose();
    _controllertwo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector( // close keyboard etc when tap on un focus area
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(

        appBar: AppBar(
          // ローカル画像をAppBarに表示
          backgroundColor: Colors.black,
          title: Image.asset(
            'assets/images/kadahira-blkb-v2.png',
            fit: BoxFit.contain,
            height: 80,
          ),
          centerTitle: true,
        ),

        body:SingleChildScrollView(
          child: Center(
            child:Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children:[
                Padding(
                  padding: const EdgeInsets.only(top:50, bottom:30),
                  child: Column(
                    children: [
                      Text(
                        DateFormat.yMMMMEEEEd('ja_JP').format(DateTime.now()),
                        style: const TextStyle(
                          fontSize:24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm:ss').format(DateTime.now()),
                        style: const TextStyle(
                          fontSize:30,
                          fontWeight: FontWeight.bold,
                        ),
                        )
                    ]
                  ),
                ),
                SizedBox(
                  height: 80,
                  width: 200,
                  child: TextFormField(
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                        labelText: 'カダイの名前',
                        hintText: '○○のレポート 等'
                    ),
                    onChanged: (kadaiName){
                      submit.name = kadaiName; // substitute the data for kadaidata class instance 'submit'
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 80,
                      width: 200,
                      child: TextField(
                        enabled: false, // prohibit input
                        controller: _dateController, // これだけでコントローラーが取得した文字がくる
                        style: const TextStyle(
                          color: Colors.black
                        ),
                        decoration: const InputDecoration(
                          labelText: '〆切       ここから選択 →'
                        ),
                      ),
                    ),

                    Padding(padding: const EdgeInsets.only(bottom: 20),
                      child:
                      IconButton(
                        alignment: Alignment.topCenter,
                        onPressed: () {
                          DatePicker.showDateTimePicker(
                            context,
                            showTitleActions: true,
                            minTime: DateTime(2024, 4, 1),
                            currentTime: dtdef,
                            locale: LocaleType.jp,
                            onChanged: (datetime) {
                              debugPrint('change $datetime');
                              },
                            onConfirm: (datetime) {
                              dtdef=datetime;
                              setState(() {
                                _dateController.text = formatter.format(datetime); // give controller a text as String
                                submit.datetime = _dateController.text;
                                submit.timestamp = datetime.millisecondsSinceEpoch; // datetime written by int
                              });
                              debugPrint('-- confirm $datetime --');
                            },
                          );
                        },
                        icon: const Icon(
                          Icons.calendar_month_outlined, size: 30,
                        ),
                      ),
                    )
                  ]
                ),


                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        height: 80,
                        width: 200,
                        child: TextFormField(
                          decoration: const InputDecoration(
                              labelText: '提出サキ',
                              hintText: 'Teams, manaba  等'
                          ),
                          onChanged: (kadaiArea){
                              submit.area = kadaiArea;
                          },
                        )
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        height: 80,
                        width: 200,
                        child: TextFormField(
                          //controller: _controllertwo, // // // this is also my settings
                          decoration: const InputDecoration(
                              labelText: '提出ケイシキ',
                              hintText: 'PDF, Word  等'
                            ),
                          onChanged: (kadaiFormat){
                              submit.format = kadaiFormat;
                          },
                        )
                    ),
                  ],
                ),

                Material(
                  child: Container(
                    decoration: BoxDecoration( // BoxDecorationで角丸に
                      border: Border.all(color: Colors.black87, width: 3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:TextButton(
                      child: const Text('トウロク', style: TextStyle(fontSize: 22, color: Colors.indigo)),
                      onPressed:(){
                        FocusScope.of(context).unfocus(); // close keyboard
                        if (submit.name!=''&&submit.datetime!='') {
                          if (submit.area==''){
                            submit.area='登録なし'; // in case of val was null
                          }
                          if (submit.format==''){
                            submit.format='登録なし';
                          }
                          saveLocalData(submit);
                          Navigator.pop(context,submit);
                        }else{
                          showDialog(
                              context: context,
                              builder: (context){
                                return const AlertDialog(title: Text('カダイ名と〆切は必須です', style: TextStyle(fontSize: 18),), alignment: Alignment.center);
                              });
                        }},
                      //splashColor: Colors.white.withOpacity(0.2)//withOpacity:add opacity
                    ),
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: TextButton(
                        onPressed: (){
                          FocusScope.of(context).unfocus();
                          Navigator.pop(context, null);
                          },
                        child: const Text('< Back', style: TextStyle(fontSize: 14, color: Colors.indigo))
                    )
                )
              ]
            )
          )
        )
      )
    );
  }
}
