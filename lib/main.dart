import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;


import 'package:kadahira/settings.dart';
import 'package:kadahira/dbhelper.dart';
import 'package:kadahira/kadaidata.dart';
import 'package:kadahira/submit.dart';
import 'package:kadahira/notificationservice.dart';


//// notification  ////

Future<void> setupAllNotifications(List<kadaidata> kadaiList) async {
  final prefs = await SharedPreferences.getInstance();
  final notification_tf = await prefs.getBool('notification_tf') ?? false; // teinei coding (null→false)

  try{
    await NotificationService.cancelAllNotifications();
    // anyway delete all notification at first

    if (notification_tf){ // set notifications by prefs val
      for (final kadai in kadaiList) {
        debugPrint('Setting up notification for: ${kadai.name} (ID: ${kadai.id})');
        await NotificationService.scheduleNotification(kadai);
      }
    }else{
      debugPrint('Notifications are disabled');
    }
  }catch (e){
    debugPrint('ERROR: setupAllNotifications');
  }
}

// must need for Android13 or later
Future<void> requestPermissions() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }else{
    debugPrint('permitted! - notification -');
  }
  if (await Permission.scheduleExactAlarm.isDenied){
    await Permission.scheduleExactAlarm.request();
  }else{
    debugPrint('permitted! - exact alarm-');
  }
}

Future<void> configureLocalTimeZone() async {
  debugPrint('Configuring timezone');
  tzdata.initializeTimeZones();
  final String timeZoneName = 'Asia/Tokyo'; // 日本のタイムゾーンを使用
  tz.setLocalLocation(tz.getLocation(timeZoneName));
  debugPrint('Timezone set to: $timeZoneName');
}

////  DB  /////

Future<void> editLocalData(int id, kadaidata editedKadai) async {
  DatabaseHelper dbHelper = DatabaseHelper();
  Map<String, dynamic> record = {
    'name': editedKadai.name,
    'datetime': editedKadai.datetime,
    'area': editedKadai.area,
    'format': editedKadai.format,
    'timestamp': editedKadai.timestamp,
  };
  await dbHelper.editRecord(id, record).then((rowsDeleted) {}).catchError((error) {
    debugPrint('----debugPrint----Error deleting record: $error----');
  });
}

Future<void> deleteLocalData(int id) async {
  DatabaseHelper dbHelper = DatabaseHelper();
  await dbHelper.deleteRecord(id).then((rowsDeleted) {}).catchError((error) {
    debugPrint('----debugPrint----Error deleting record: $error----');
  });
}

Future<void> loadLocalData(List<kadaidata> kadaiList) async {
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

////   others   ////

void _count_done() async{
  int cnt=1;
  final shprefs = await SharedPreferences.getInstance();
  if (shprefs.getInt('count_easter_egg') == null){ // 値がなければ
    shprefs.setInt('count_easter_egg', cnt); // カウントを１としてSharedPreferencesに登録
  }else{
    cnt = shprefs.getInt('count_easter_egg')!; // cntに読み出し
    shprefs.setInt('count_easter_egg', ++cnt); // インクリメントした値で更新
  }
}


////   main   ////

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP', '');
  await configureLocalTimeZone();
  await requestPermissions();
  await NotificationService.init(); // async --<< if not, cannot trigger Notification Service Functions

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

  // kadaidata instance for data adding
  kadaidata? new_kadai = kadaidata(0, '', '', '', '', 0);

  // List for kadai list below the button
  List<kadaidata> kadaiList = [];
  kadaidata poolkadai = kadaidata(0, '', '', '', '', 0);


  @override
  void initState() { // execute when app wakeup
    super.initState();
    loadLocalData(kadaiList);
    setupAllNotifications(kadaiList); // set up notification for the kadai on kadaiList
    Timer.periodic(const Duration(seconds: 1), _onTimer); // execute _onTimer for each one second
  }

  void _onTimer(Timer timer) {
    DateFormat('HH:mm:ss').format(DateTime.now()); // Substitute new_Time for the value of current Date and Time()
    setState((){}); // every one second, trigger setState
  }

  // Edit Dialog
  Future<void> showEditDialog(BuildContext context, kadaidata poolkadai) async {
    // kadailist class
    kadaidata tmpKadai = kadaidata(
        poolkadai.id, poolkadai.name,
        poolkadai.datetime, poolkadai.area,
        poolkadai.format, poolkadai.timestamp); // otherwise not to set the address of poolkadai

    kadaidata editedKadai = tmpKadai;

    DateTime currentDT = DateTime.fromMillisecondsSinceEpoch(poolkadai.timestamp); // for datetime picker (automatically set current datetime settings)

    //controller
    TextEditingController EditFormController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus(); // close keyboard etc when tap on un focus area
            },
            child:AlertDialog(
                title: const Text('データを編集'),
                  content: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          TextFormField(
                            decoration: InputDecoration(labelText: 'カダイの名前', hintText: '${poolkadai.name} (変更なし)'),
                            onChanged: (val){
                              tmpKadai.name=val;
                            },
                          ),

                          TextFormField(
                            decoration: InputDecoration(labelText: '提出サキ', hintText: '${poolkadai.area} (変更なし)'),
                            onChanged: (val){
                              tmpKadai.area=val;
                            },
                          ),

                          TextFormField(
                              decoration: InputDecoration(labelText: '提出ケイシキ', hintText: '${poolkadai.format} (変更なし)'),
                              onChanged: (val) {
                                tmpKadai.format = val;
                              }
                          ),

                          const SizedBox(height: 20),


                          TextField(
                            enabled: false, // prohibit input
                            controller: EditFormController,
                            style: const TextStyle(
                                color: Colors.black
                            ),
                            decoration: const InputDecoration(
                                labelText: '〆切'
                            ),
                          ),

                          IconButton(
                            alignment: Alignment.topCenter,
                            onPressed: () {
                              DatePicker.showDateTimePicker(
                                context,
                                showTitleActions: true,
                                minTime: DateTime(2024, 4, 1),
                                currentTime: currentDT,
                                locale: LocaleType.jp,
                                onChanged: (val) {
                                  debugPrint('change $val');
                                },
                                onConfirm: (val){
                                  currentDT=val;
                                  DateFormat formatter = DateFormat('yyyy-M-d HH:mm');
                                  EditFormController.text = formatter.format(val);
                                  // give controller a formatted text as String
                                  tmpKadai.datetime = EditFormController.text;
                                  tmpKadai.timestamp = val.millisecondsSinceEpoch; // DateTime
                                },
                              );
                            },
                            icon: const Icon(
                              Icons.calendar_month_outlined, size: 30, // I set the icon but the app doesn't show it!!!!!!WHAT!?
                            ),
                          ),
                        ]
                    )
                  ),

                actions: <Widget>[
                  TextButton(
                    child: const Text('キャンセル'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      },
                  ),

                  TextButton(
                    child: const Text('OK'),
                    onPressed: () async{

                      editedKadai.name = tmpKadai.name;
                      editedKadai.area = tmpKadai.area;
                      editedKadai.format = tmpKadai.format;
                      editedKadai.datetime = tmpKadai.datetime;
                      editedKadai.timestamp = tmpKadai.timestamp;

                      await editLocalData(editedKadai.id, editedKadai);

                      await NotificationService.cancelAllNotifications(); // cancel notification
                      await NotificationService.scheduleNotification(editedKadai); // set new notification
                      // setup new notification
                      setState((){
                        kadaiList = [];
                        loadLocalData(kadaiList);
                        kadaiList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                        // reset KadaiList to show updated list
                        Navigator.of(context).pop();
                      });},
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
              onPressed: ()async{
               debugPrint('pushed');
               await Navigator.push(context,MaterialPageRoute(builder: (context) => const KdSettings()));
               await setupAllNotifications(kadaiList);
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
                padding: const EdgeInsets.only(top:50, bottom:15),
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
                  height: 180,
                  width: 180,
                  image: const AssetImage('assets/images/kadahira-logo-v2.png'),
                  fit: BoxFit.cover,
                  child: InkWell(
                      onTap:() async {
                        new_kadai = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context)=> const Submit())
                        );

                        if(new_kadai!=null){
                          await NotificationService.scheduleNotification(new_kadai!);
                          // set notification

                          setState((){
                            kadaiList.add(new_kadai!);
                            // push new kadai for the Lists
                            kadaiList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                            // sort by date time at here
                          });
                        }},
                      splashColor: Colors.white.withOpacity(0.2)//withOpacity:add opacity
                    ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(top:15, bottom:5),
                child:Text(
                  '▲ 課題の登録はここから ▲',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18
                  ),
                ),
              ),

              Container(
                height: 400,
                padding: const EdgeInsets.all(4),
                // childrenを指定してリスト表示

                child: ListView(
                  children:List<Widget>.generate ( kadaiList.length, (int index) { // gererate(number of kadai ( value of index () {
                    poolkadai = kadaiList.elementAt(index); // extract kadai of index
                    Color datetimeColor = Colors.black;
                    Color kadainameColor = Colors.black;
                    String nowDateTime = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    String poolDateTime = DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(poolkadai.timestamp));

                    if ( nowDateTime == poolDateTime){ // if the due of the kadai is today
                      if (DateTime.now().millisecondsSinceEpoch < poolkadai.timestamp) { // && now < the due
                        datetimeColor = Colors.redAccent; // set text color red
                      }else{
                        datetimeColor = Colors.black26; // now > the due (but same day)
                        kadainameColor = Colors.black26;
                      }
                    }else if ( DateTime.now().millisecondsSinceEpoch > poolkadai.timestamp ){
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
                                            Text('提出先 : ${poolkadai.area}', style: const TextStyle(fontSize: 22)),
                                            Text('形式 : ${poolkadai.format}', style: const TextStyle(fontSize: 22)),
                                            //Text('id : ${poolkadai.id}', style: const TextStyle(fontSize: 12))
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
                              border: Border.all(color: const Color.fromRGBO(0, 0, 0, 90), width: 3),
                              borderRadius: BorderRadius.circular(10),
                              color: (index % 2 == 0) ? Colors.white10 : Colors.black12 // 偶数：白　奇数：灰色
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
                                      fontWeight: FontWeight.bold,
                                      color: kadainameColor
                                    ),
                                  ),

                                  Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          ('〆切:${poolkadai.datetime}'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: datetimeColor
                                        ),
                                      ),
                                        TextButton(
                                          child: const Text(
                                              '[ 提出完了! ]',
                                              style: TextStyle(
                                                  color: Colors.indigo,
                                                  fontSize: 18
                                              )
                                          ),
                                            onPressed: (){
                                              showDialog(
                                                context: context,
                                                builder: (context){
                                                    return AlertDialog(
                                                    title: const Text(
                                                      '提出できましたか？',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        child:const Text('まだ', style: TextStyle(fontSize: 18, color: Colors.black54)),
                                                        onPressed: () => Navigator.pop(context),
                                                      ),
                                                      TextButton(
                                                        child:const Text('できた！', style: TextStyle(fontSize: 18, color: Colors.indigo)),
                                                        onPressed: () async{
                                                          _count_done();
                                                          // count finished ones for easter_egg (prefs)

                                                          poolkadai = kadaiList[index];
                                                          kadaiList.removeAt(index);
                                                          // Delete the kadai

                                                          await NotificationService.cancelNotification(poolkadai.id);
                                                          // cancel notification

                                                          deleteLocalData(poolkadai.id);
                                                          // Delete kadai from the DB

                                                          Navigator.pop(context);
                                                          showDialog(
                                                              context: context,
                                                              builder: (context) {
                                                                return const AlertDialog(
                                                                    title: Text('お疲れ様でした🥳'));
                                                              });
                                                          },
                                                      ),
                                                    ],
                                                  );
                                                });
                                              },
                                        ),
                                        IconButton(
                                            onPressed: (){
                                              poolkadai = kadaiList[index];
                                              showEditDialog(context, poolkadai);
                                            },
                                            icon: const Icon(Icons.edit)
                                        )
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