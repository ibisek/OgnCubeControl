
import 'dart:typed_data';

class Firmware {
  final String type;
  final String date;
  final String title;
  final String notes;
  final String filename;
  final String url;

  int timestamp;  // unix ts [s]
  bool isStoredLocally = false; // indicates this file needs to be downloaded
  Uint8List bytes;  // firmware bytes

  Firmware({this.type, this.date, this.title,  this.notes, this.filename, this.url});

  factory Firmware.fromJson(Map<String, dynamic> json) {
    return Firmware(
      type: json['type'],
      date: json['date'],
      title: json['title'],
      notes: json['notes'],
      filename: json['filename'],
      url: json['url'],
    );
  }

  int getTs() {
    if (timestamp == null)
      timestamp = DateTime.parse("$date 00:00:01Z").toUtc().millisecondsSinceEpoch; // ~/ 1000;

    return timestamp;
  }

  String toString() {
    return "#Firmware type: $type; date: $date; title: $title";
  }
}
