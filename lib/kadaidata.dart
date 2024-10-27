class kadaidata{

  int id;
  String name;
  String datetime;
  String area;
  String format;
  int timestamp;

  kadaidata(this.id, this.name,this.datetime,this.area,this.format, this.timestamp);

  factory kadaidata.fromMap(Map<String, dynamic> map) {
    return kadaidata(
      map['id'],
      map['name'],
      map['datetime'],
      map['area'],
      map['format'],
      map['timestamp'],
    );
  }
}