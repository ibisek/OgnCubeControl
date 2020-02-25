
import 'dart:typed_data';

class Firmware {
  final String type;
  final String date;
  final String title;
  final String notes;
  final String filename;
  final String url;
  final int crc;
  final int len;

  int timestamp;  // unix ts [s]
  bool isStoredLocally = false; // indicates this file needs to be downloaded
  Uint8List bytes;  // firmware bytes

  Firmware({this.type, this.date, this.title,  this.notes, this.filename, this.url, this.crc, this.len});

  factory Firmware.fromJson(Map<String, dynamic> json) {
    return Firmware(
      type: json['type'],
      date: json['date'],
      title: json['title'],
      notes: json['notes'],
      filename: json['filename'],
      url: json['url'],
      crc: json['crc'],
      len: json['len'],
    );
  }

  /// @return CRC as XOR of the bytes
  int calcCrc(Uint8List bytes) {
    int crc = 0;
    for (int i=0; i<bytes.lengthInBytes; i++) {
      crc = crc ^ bytes[i];
    }

    return crc;
  }

  /// @param bytes of the firmware's .bin file
  void setBytes(Uint8List bytes) {
    this.bytes = bytes;

    int calculatedCrc = calcCrc(bytes);

    if(crc != calculatedCrc || len != bytes.lengthInBytes) {
      throw Exception("CRC ($crc vs. $calculatedCrc}) or LEN ($len vs. ${bytes.lengthInBytes}) do not match!");
    }
  }

  /// @return unix timestamp in [ms]
  int getTs() {
    if (timestamp == null)
      timestamp = DateTime.parse("$date 00:00:01Z").toUtc().millisecondsSinceEpoch; // ~/ 1000;

    return timestamp;
  }

  String toString() {
    return "#Firmware type: $type; date: $date; title: $title";
  }
}
