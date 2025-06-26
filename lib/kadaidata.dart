class kadaidata{

  int id;
  String name;
  String datetime;
  String area;
  String format;
  int timestamp;
  int notibefore; // ★ 追加

  kadaidata(this.id, this.name,this.datetime,this.area,this.format, this.timestamp, this.notibefore); // ★ 追加

  factory kadaidata.fromMap(Map<String, dynamic> map) {
    return kadaidata(
      map['id'],
      map['name'],
      map['datetime'],
      map['area'],
      map['format'],
      map['timestamp'],
      map['notibefore'] ?? 10, // ★ 追加 (nullの場合は10をデフォルト値とする)
    );
  }
}