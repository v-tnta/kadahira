import 'dart:async';
import 'package:flutter/services.dart';
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
import 'package:kadahira/responsive_helper.dart';

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
        await NotificationService.scheduleNotification(kadai, -1);
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

// ★ 引数をなくし、Future<List<kadaidata>> を返すように変更
Future<List<kadaidata>> loadLocalData() async {
  DatabaseHelper dbHelper = DatabaseHelper();
  List<kadaidata> kadaiList = []; // この関数内でリストを作成
  try {
    List<Map<String, dynamic>> records = await dbHelper.getAllRecords();
    for (var record in records) {
      kadaiList.add(kadaidata.fromMap(record));
    }
    kadaiList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return kadaiList; // データを返す
  } catch (error) {
    debugPrint('Error loading records: $error');
    return []; // エラーの場合は空のリストを返す
  }
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
  State<MyHomePage> createState() => _MyHomePageState(); // ★ kadaidataの初期化を削除
}


class _MyHomePageState extends State<MyHomePage>{

  // kadaidata instance for data adding
  kadaidata? new_kadai = kadaidata(0, '', '', '', '', 0);

  // ★ このリストはFutureBuilderが管理するので、ここでは宣言のみ
  List<kadaidata> kadaiList = [];
  kadaidata poolkadai = kadaidata(0, '', '', '', '', 0);

  // ★ このStateで非同期処理を管理するためのFutureを定義
  late Future<List<kadaidata>> _kadaiListFuture;


  @override
  void initState() { // execute when app wakeup
    super.initState();
    // ★ initStateでは、Futureをセットするだけ
    _kadaiListFuture = loadLocalData();
    // Timer.periodicはUI更新のためそのまま
    Timer.periodic(const Duration(seconds: 1), _onTimer);
  }

  void _onTimer(Timer timer) {
    // 1秒ごとにsetStateを呼び出し、時計を更新する
    if (mounted) { // ★ Stateが存在する場合のみsetStateを呼ぶように修正
      setState((){});
    }
  }

  // Edit Dialog
  Future<void> showEditDialog(BuildContext context, kadaidata poolkadai) async {
    kadaidata tmpKadai = kadaidata(
        poolkadai.id, poolkadai.name,
        poolkadai.datetime, poolkadai.area,
        poolkadai.format, poolkadai.timestamp
    );

    kadaidata editedKadai = new kadaidata(tmpKadai.id, tmpKadai.name, tmpKadai.datetime, tmpKadai.area, tmpKadai.format, tmpKadai.timestamp);


    DateTime currentDT = DateTime.fromMillisecondsSinceEpoch(poolkadai.timestamp);

    TextEditingController EditFormController = TextEditingController();


    int edited_noti_time = -1;
    final prefs = await SharedPreferences.getInstance();

    int? notiTimeRaw = prefs.getInt('notification_time');
    String notiTime = "10"; // init value
    if (notiTimeRaw != null){
      notiTime = notiTimeRaw.toString(); // for editForm
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
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

                        Row(
                          children: [
                            SizedBox(
                              height: 50,
                              width: 150,
                              child: TextField(
                                enabled: false,
                                controller: EditFormController,
                                style: const TextStyle(
                                    color: Colors.black
                                ),
                                decoration: const InputDecoration(
                                    labelText: '〆切'
                                ),
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
                                    tmpKadai.datetime = formatter.format(val);
                                    tmpKadai.timestamp = val.millisecondsSinceEpoch;
                                  },
                                );
                              },
                              icon: const Icon(
                                Icons.calendar_month_outlined, size: 30,
                              ),
                            ),
                          ],
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "提出〆切の",
                                style: TextStyle(fontSize: getResponsiveFontSize(context, baseFontSize: 14)),
                              ),
                              SizedBox(
                                width: 80,
                                child: TextFormField(
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  style: TextStyle(fontSize: getResponsiveFontSize(context, baseFontSize:16), fontWeight: FontWeight.bold),
                                  decoration:  InputDecoration(hintText: '($notiTime)', hintStyle: const TextStyle(color: Colors.grey)),
                                  onChanged:(val){
                                    if (val.isNotEmpty){
                                      edited_noti_time = int.parse(val);
                                    }else{
                                      edited_noti_time = -1;
                                    }
                                    debugPrint(' edited_noti_time=$edited_noti_time -- EditForm --');
                                  },
                                ),
                              ),
                              Text(
                                "分前",
                                style: TextStyle(fontSize: getResponsiveFontSize(context, baseFontSize:14), fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "に通知",
                                style: TextStyle(fontSize: getResponsiveFontSize(context, baseFontSize:14)),
                              ),
                            ]
                        )
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

                    bool isDateTimeChanged = false;
                    if (editedKadai.timestamp != poolkadai.timestamp){
                      isDateTimeChanged=true;
                    }

                    // updating editedKadai
                    editedKadai.name = tmpKadai.name.isEmpty ? poolkadai.name : tmpKadai.name;
                    editedKadai.area = tmpKadai.area.isEmpty ? poolkadai.area : tmpKadai.area;
                    editedKadai.format = tmpKadai.format.isEmpty ? poolkadai.format : tmpKadai.format;
                    editedKadai.datetime = tmpKadai.datetime.isEmpty ? poolkadai.datetime : tmpKadai.datetime;
                    editedKadai.timestamp = tmpKadai.timestamp == 0 ? poolkadai.timestamp : tmpKadai.timestamp;

                    String dialogmsg = "通知がオフです。ご確認を⚙️\n";

                    await editLocalData(editedKadai.id, editedKadai); // updating KadaiList

                    if (prefs.getInt('notification_time') == edited_noti_time){ // edited_noti 変更なしなら
                      edited_noti_time = -1;
                    }

                    if (isDateTimeChanged || (prefs.getInt('notification_time') != edited_noti_time)){ // 日時が変更 OR 通知時間が変更された場合
                      if (prefs.getBool('notification_tf')==true){
                        await NotificationService.cancelNotification(editedKadai.id);
                        await NotificationService.scheduleNotification(editedKadai, edited_noti_time);

                        if (isDateTimeChanged){
                          dialogmsg = "連動して通知時間も変更しました\n";
                        }
                        if (prefs.getInt('notification_time') != edited_noti_time){
                          dialogmsg = "通知を$edited_noti_time分前に変更しました\n";
                        }

                        if (isDateTimeChanged){
                          dialogmsg = "通知時間を変更しました\n通知を$edited_noti_time分前に変更しました";
                        }
                      }
                    }


                    debugPrint('edited_noti_time: $edited_noti_time -- showDialog? --');

                    if (edited_noti_time!=-1){
                      await showDialog(context: context, builder: (BuildContext context) {
                        return SimpleDialog(
                            alignment: Alignment.center,
                            title: Text(
                                style: TextStyle(
                                    fontSize: getResponsiveFontSize(context, baseFontSize:20)
                                ),
                                dialogmsg
                            )
                        );
                      });
                    }

                    // ★ データを再読み込みしてUIを更新
                    setState((){
                      _kadaiListFuture = loadLocalData();
                      Navigator.of(context).pop();
                    });
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
    // MediaQueryで画面情報を取得
    final Size screenSize = MediaQuery.of(context).size;
    final EdgeInsets padding = MediaQuery.of(context).padding;

    // 画面の横幅
    final double screenWidth = screenSize.width;
    // 画面の縦幅（セーフエリアを除く）
    final double safeAreaHeight = screenSize.height - padding.top - padding.bottom;

    return Scaffold(
        appBar: AppBar(
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
                onPressed: ()async {
                  debugPrint('pushed');

                  final prefs = await SharedPreferences.getInstance();
                  bool bfrnoti_tf = prefs.getBool('notification_tf') ?? false;
                  int bfrnoti_time = prefs.getInt('notification_time') ?? 10;

                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const KdSettings()));

                  bool aftnoti_tf = prefs.getBool('notification_tf') ?? false;
                  int aftnoti_time = prefs.getInt('notification_time') ?? 10;

                  if (
                        (bfrnoti_tf == false && aftnoti_tf == true) ||
                        (bfrnoti_tf == true && aftnoti_tf == false) ||
                        ((bfrnoti_tf == true && aftnoti_tf == true) && (bfrnoti_time != aftnoti_time))
                  ){
                    await setupAllNotifications(kadaiList); // ★ kadaiListはFutureBuilderから渡されたものを使用
                  }
                }
            )
          ],
        ),
        // ★ ここからbodyをFutureBuilderでラップ
        body: FutureBuilder<List<kadaidata>>(
          future: _kadaiListFuture,
          builder: (context, snapshot) {
            // 1. 読み込み中の処理
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            // 2. エラーが発生した場合の処理
            if (snapshot.hasError) {
              return Center(
                child: Text('エラーが発生しました: ${snapshot.error}'),
              );
            }
            // 3. 読み込みが成功した場合の処理
            if (snapshot.hasData) {
              // Futureから取得した最新のデータをStateのkadaiListに反映
              kadaiList = snapshot.data!;

              // ---- ここから下が、元の body の中身 ----
              return SingleChildScrollView(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                          padding: EdgeInsets.only(top:(screenWidth < 400) ? 30 : 50, bottom:15),
                          child: Column(
                              children: [
                                Text(
                                  DateFormat.yMMMMEEEEd('ja_JP').format(DateTime.now()),
                                  style: TextStyle(
                                    fontSize: (screenWidth < 400) ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat('HH:mm:ss').format(DateTime.now()),
                                  style: TextStyle(
                                    fontSize:(screenWidth < 400) ? 26 : 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ])
                      ),
                      Material(
                        child: Ink.image(
                          height: getResponsiveLogoPic(context, screenWidth: screenWidth),
                          width: getResponsiveLogoPic(context, screenWidth: screenWidth),
                          image: const AssetImage('assets/images/kadahira-logo-v2.png'),
                          fit: BoxFit.cover,
                          child: InkWell(
                              onTap:() async {
                                new_kadai = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context)=> const Submit())
                                );

                                if(new_kadai!=null){
                                  final prefs = await SharedPreferences.getInstance();
                                  if (prefs.getBool('notification_tf')==true) {
                                    NotificationService.scheduleNotification(new_kadai!,-1);
                                  }
                                  // ★ データを再読み込みしてUIを更新
                                  setState((){
                                    _kadaiListFuture = loadLocalData();
                                  });
                                }},
                              splashColor: Colors.white.withOpacity(0.2)
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top:15, bottom:5),
                        child:Text(
                          '▲ 課題の登録はここから ▲',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: getResponsiveFontSize(context, baseFontSize:16)
                          ),
                        ),
                      ),
                      Container(
                        width: screenWidth * 0.9,
                        height: safeAreaHeight * 0.46,
                        padding: const EdgeInsets.all(4),
                        child: ListView(
                          children:List<Widget>.generate ( kadaiList.length, (int index) {
                            poolkadai = kadaiList.elementAt(index);
                            Color datetimeColor = Colors.black;
                            Color kadainameColor = Colors.black;
                            String nowDateTime = DateFormat('yyyy-MM-dd').format(DateTime.now());
                            String poolDateTime = DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(poolkadai.timestamp));

                            if ( nowDateTime == poolDateTime){
                              if (DateTime.now().millisecondsSinceEpoch < poolkadai.timestamp) {
                                datetimeColor = Colors.redAccent;
                              }else{
                                datetimeColor = Colors.black26;
                                kadainameColor = Colors.black26;
                              }
                            }else if ( DateTime.now().millisecondsSinceEpoch > poolkadai.timestamp ){
                              datetimeColor = Colors.black26;
                              kadainameColor = Colors.black26;
                            }
                            return Padding(
                              padding: EdgeInsets.all((screenWidth < 400) ? 6 : 10),
                              child:
                              InkWell(
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
                                                children: [
                                                  Text('提出先 : ${poolkadai.area}', style: TextStyle(fontSize: getResponsiveFontSize(context, baseFontSize:22))),
                                                  Text('形式 : ${poolkadai.format}', style: TextStyle(fontSize: getResponsiveFontSize(context, baseFontSize:22))),
                                                ],
                                              ),
                                            )
                                        );
                                      }
                                  );
                                },
                                child:
                                Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(color: const Color.fromRGBO(0, 0, 0, 90), width: 3),
                                      borderRadius: BorderRadius.circular(10),
                                      color: (index % 2 == 0) ? Colors.white10 : Colors.black12
                                  ),
                                  height: (screenWidth < 400) ? 84 : 96, // 画面はばが小さければ縦幅を小さく、大きければ通常サイズに
                                  padding: const EdgeInsets.only(top:10),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        poolkadai.name,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: getResponsiveFontSize(context, baseFontSize:21),
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
                                                  fontSize: getResponsiveFontSize(context, baseFontSize:17),
                                                  fontWeight: FontWeight.bold,
                                                  color: datetimeColor
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                    icon: const Icon(Icons.edit),
                                                    onPressed: (){
                                                      poolkadai = kadaiList[index];
                                                      showEditDialog(context, poolkadai);
                                                    }
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.check_box_sharp),
                                                  iconSize: 30,
                                                  color: Colors.green,
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
                                                                child: Text('まだ', style: TextStyle(fontSize: getResponsiveFontSize(context, baseFontSize:18), color: Colors.black54)),
                                                                onPressed: () => Navigator.pop(context),
                                                              ),
                                                              TextButton(
                                                                child: Text('できた！', style: TextStyle(fontSize: getResponsiveFontSize(context, baseFontSize:18), color: Colors.indigo)),
                                                                onPressed: () async{
                                                                  _count_done();

                                                                  poolkadai = kadaiList[index];

                                                                  try {
                                                                    await NotificationService.cancelNotification(poolkadai.id);
                                                                    await deleteLocalData(poolkadai.id);
                                                                    debugPrint("Clearing the notification: Safely done!");
                                                                  }catch (error){
                                                                    debugPrint("ERROR: During clearing the notification → ${error} ");
                                                                  }


                                                                  // ★ データを再読み込みしてUIを更新
                                                                  setState(() {
                                                                    _kadaiListFuture = loadLocalData();
                                                                  });

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
                                                )
                                              ],
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
              );
            }
            // 4. データが空の場合 (念のため)
            return const Center(child: Text('課題データがありません。'));
          },
        )
    );
  }
}