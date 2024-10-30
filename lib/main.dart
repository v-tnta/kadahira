import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:kadahira/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dbhelper.dart';
import 'kadaidata.dart';
import 'submit.dart';

//debug zone//
void func(BuildContext context) {
  //  //
  debugPrint('onfunc');//debug
}

Future<void> editLocalData(kadaidata edit_kadai) async {
  DatabaseHelper dbHelper = DatabaseHelper();
  Map<String, dynamic> record = {
    'name': edit_kadai.name,
    'datetime': edit_kadai.datetime,
    'area': edit_kadai.area,
    'format': edit_kadai.format,
    'timestamp': edit_kadai.timestamp,
  };
  await dbHelper.editRecord(edit_kadai.id, record).then((rowsDeleted) {}).catchError((error) {
    debugPrint('----debugPrint----Error deleting record: $error----');
  });
}

Future<void> deleteLocalData(int id) async {
  DatabaseHelper dbHelper = DatabaseHelper();
  await dbHelper.deleteRecord(id).then((rowsDeleted) {}).catchError((error) {
    debugPrint('----debugPrint----Error deleting record: $error----');
  });
}

Future<void> loadLocalData(List<kadaidata> kadaiList) async{
  DatabaseHelper dbHelper = DatabaseHelper();
  // データベースからすべてのレコードを取得し、kadaidataリストに変換して格納
  await dbHelper.getAllRecords().then((List<Map<String, dynamic>> records) {
    // 取得したレコードをkadaidataリストに変換して追加
    for (var record in records) {
      kadaiList.add(kadaidata.fromMap(record));
    }
    kadaiList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }).catchError((error) {
    debugPrint('Error loading records: $error');
  });
}

////////////

void main() {
  initializeDateFormatting('ja_JP', '');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false, // remove debug banner
      home: MyHomePage(title: 'カダヒラ'),
    );
  }
}


class MyHomePage extends StatefulWidget{
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState(kadaidata(0,'','','','', 0));
}


class _MyHomePageState extends State<MyHomePage>{

  //initializer
  _MyHomePageState(this.new_kadai);

  // for data saving
  final shardPreferences = SharedPreferences.getInstance();

  ///////////////////////////////////////////

  // kadaidata instance for data adding
  kadaidata new_kadai = new kadaidata(0, '', '', '', '', 0);


  // List for kadai list below the button
  List<kadaidata> kadaiList = [];
  kadaidata poolkadai = new kadaidata(0, '', '', '', '', 0);

  ///////////////////////////////////////////

  @override
  void initState() { // execute when app wakeup
    super.initState();
    loadLocalData(kadaiList);
    debugPrint('---------------initState--------------');
    Timer.periodic(const Duration(seconds: 1), _onTimer); // execute _onTimer for each one second
  }

  void _onTimer(Timer timer) {
    DateFormat('HH:mm:ss').format(DateTime.now()); // Substitute new_Time for the value of DateTime.now()
    kadaiList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    setState((){});
  }

  Future<void> showEditDialog(BuildContext context, kadaidata poolkadai) async {
    DateTime selectedDate = DateTime.now();
    // kadailist class
    kadaidata edited_kadai = kadaidata(poolkadai.id, poolkadai.name, poolkadai.datetime, poolkadai.area, poolkadai.format, poolkadai.timestamp);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        //controller
        final TextEditingController _dateController = TextEditingController();
        late DateTime marged;
        return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus(); // close keyboard etc when tap on un focus area
            },
            child:AlertDialog(
              title: Text('データを編集'),
              content: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    TextFormField(
                      decoration: InputDecoration(labelText: 'カダイの名前', hintText: '${poolkadai.name} (変更なし)'),
                      onChanged: (val){
                          edited_kadai.name=val;
                        },
                    ),

                    TextFormField(
                      decoration: InputDecoration(labelText: '提出サキ', hintText: '${poolkadai.area} (変更なし)'),
                      onChanged: (val){
                          edited_kadai.area=val;
                        },
                    ),

                    TextFormField(
                      decoration: InputDecoration(labelText: '提出ケイシキ', hintText: '${poolkadai.format} (変更なし)'),
                      onChanged: (val) {
                         edited_kadai.format = val;
                      }
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      enabled: false, // prohibit input
                      controller: _dateController,
                      style: const TextStyle(
                          color: Colors.black
                      ),
                      decoration: const InputDecoration(
                          labelText: '提出日'
                      ),
                    ),

                    ElevatedButton(
                      onPressed: () async {

                        //Date, Time picker
                        DateTime dtnow = DateTime.now();
                        DateFormat formatter = DateFormat('yyyy-M-d HH:mm');
                        DateTime selectedDate = DateTime.now();
                        TimeOfDay selectedTime = TimeOfDay(hour: 23, minute: 59);
                        // // // // // // //

                        //  //  //  //
                        // DatePicker
                        final datepicked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2024, 4, 1), lastDate: DateTime(2200),
                            currentDate: DateTime(dtnow.year, dtnow.month, dtnow.day, 23, 59)
                        );
                        if (datepicked != null && datepicked != selectedDate) {
                          selectedDate = datepicked;

                          //  //  //  //
                          // TimePicker
                          final timepicked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                              builder: (BuildContext context, Widget? child) {
                                return MediaQuery( // enable 24h style Time Piker
                                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                  child: child!,
                                );
                              });
                          if (timepicked != null && timepicked != selectedTime) {
                            selectedTime = timepicked;
                          }

                          marged = DateTime( //
                              selectedDate.year,selectedDate.month,selectedDate.day,
                              selectedTime.hour, selectedTime.minute
                          );

                          _dateController.text = formatter.format(marged); // give controller a text as String
                          edited_kadai.datetime = _dateController.text;
                          edited_kadai.timestamp = marged.microsecondsSinceEpoch; // datetime written by int

                        }
                      },
                      child: const Icon(Icons.calendar_month_outlined),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('キャンセル'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    editLocalData(edited_kadai);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            )
        );
      },
    );
  }

  @override
    Widget build(BuildContext context) {
    return Scaffold(
      //resizeToAvoidBottomInset:true,
        appBar: AppBar(
        // ローカル画像をAppBarに表示
          backgroundColor: Colors.black,
          centerTitle: true,
          title: Image.asset(
            'assets/images/kadahira-blkb-v2.png',
            fit: BoxFit.contain,
            height: 80,
          ),
          actions: [
            IconButton(
             icon: const Icon(
               Icons.settings, size: 30,
             ),
              color: Colors.white,
              onPressed: (){
               debugPrint('pushed');
               Navigator.push(context,MaterialPageRoute(builder: (context) => KdSettings()));
              }
            )
          ],

        ),

      body: SingleChildScrollView(
        child:Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Padding(
                padding: EdgeInsets.only(top:50, bottom:15),
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
                  ),
                ])
              ),

              Material(
                child: Ink.image(
                  height: 200,
                  width: 200,
                  image: const AssetImage('assets/images/kadahira-logo-v2.png'),
                  fit: BoxFit.cover,
                  child: InkWell(
                      onTap:() async {
                        new_kadai = await Navigator.push(
                          context,
                            MaterialPageRoute(builder: (context)=> Submit())
                          );

                        //loadLocalData(kadaiList);
                        kadaiList.add(new_kadai); // push new kadai for the Lists
                        //
                        //debugPrint(new_kadai as String);//.. ..// debug print result //..   ..//
                        },
                      splashColor: Colors.white.withOpacity(0.2)//withOpacity:add opacity
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(top:15, bottom:5),
                child:Text(
                  '▲ 課題の登録 ▲',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18
                  ),
                ),
              ),

              Container(
                height: 300,
                padding: const EdgeInsets.all(4),
                // childrenを指定してリスト表示

                child: ListView(
                  children:List<Widget>.generate(kadaiList.length, (int index) { // gererate(number of kadai ( value of index () {
                    poolkadai = kadaiList.elementAt(index); // extract kadai of index
                    Color datetimeColor = Colors.black;
                    Color kadainameColor = Colors.black;
                    String nowDateTime = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    String poolDateTime = DateFormat('yyyy-MM-dd').format(DateTime.fromMicrosecondsSinceEpoch(poolkadai.timestamp));

                    if ( nowDateTime == poolDateTime){ // if the due of the kadai is today
                      if (DateTime.now().microsecondsSinceEpoch < poolkadai.timestamp) { // && now < the due
                        datetimeColor = Colors.redAccent; // set text color red
                      }else{
                        datetimeColor = Colors.black26; // now > the due (but same day)
                        kadainameColor = Colors.black26;
                      }
                    }else if ( DateTime.now().microsecondsSinceEpoch > poolkadai.timestamp ){
                      datetimeColor = Colors.black26; // now > the due
                      kadainameColor = Colors.black26;
                    }
                    return Padding(
                      padding: const EdgeInsets.all(10),
                      child:
                      InkWell( // InkWellのchildとすることでContainerのタップを実装できる
                          onTap: (){
                            poolkadai = kadaiList.elementAt(index);
                            showDialog(
                                context: context,
                                builder: (context){
                                    return AlertDialog(
                                        content: Padding(
                                          padding: const EdgeInsets.only(top: 15, bottom: 5),
                                          child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                            // minimum area size for children of column
                                          children: [
                                            Text('提出先 : ${poolkadai.area}', style: TextStyle(fontSize: 22)),
                                            Text('形式 : ${poolkadai.format}', style: TextStyle(fontSize: 22)),
                                            Text('id : ${poolkadai.id}', style: TextStyle(fontSize: 12))
                                          ],
                                        ),
                                      )
                                    );
                                  }
                                );
                            },

                          child:
                          Container(
                              decoration: BoxDecoration( // BoxDecorationで角丸に
                              border: Border.all(color: Colors.black26, width: 3),
                              borderRadius: BorderRadius.circular(10),
                              color: (index%2==0)?Colors.white10:Colors.black12 // 偶数：白　奇数：灰色
                            ),
                            height: 96,
                              padding: const EdgeInsets.only(top:10),

                              child: Column(
                                children: [
                                  Text(
                                    poolkadai.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis, // [textmaxsize]... ← this one
                                    style: TextStyle(
                                      fontSize: 21,
                                      color: kadainameColor
                                    ),
                                  ),

                                  Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          ('提出日:${poolkadai.datetime}'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: datetimeColor
                                        ),
                                      ),
                                        TextButton(
                                            onPressed: (){
                                              showDialog(
                                                context: context,
                                                builder: (context){
                                                    return AlertDialog(
                                                    title: const Text(
                                                      '課題を完了しましたか？',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        child:const Text('まだです', style: TextStyle(fontSize: 18)),
                                                        onPressed: () => Navigator.pop(context),
                                                      ),
                                                      TextButton(
                                                        child:const Text('しました！', style: TextStyle(fontSize: 18)),
                                                        onPressed: (){
                                                          Navigator.pop(context);
                                                          poolkadai=kadaiList[index];
                                                          kadaiList.removeAt(index); // Delete the kadai
                                                          deleteLocalData(poolkadai.id); // Delete kadai from the DB
                                                        },
                                                      ),
                                                    ],
                                                  );
                                                }
                                              );
                                            },
                                            child: const Text(
                                                'done!',
                                                style: TextStyle(
                                                    color: Colors.indigo,
                                                    fontSize: 18
                                                )
                                            ),
                                        ),
                                        IconButton(
                                            onPressed: (){
                                              poolkadai=kadaiList[index];
                                              showEditDialog(context, poolkadai);
                                        },
                                            icon: const Icon(Icons.edit))
                                      ]
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

              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child:Text(
                  '©2024 v_tnta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black54
                  ),
                ),
              )
            ],
          ),
        ),
      )
    );
  }
}

