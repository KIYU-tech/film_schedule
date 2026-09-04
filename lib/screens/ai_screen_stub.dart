import 'dart:typed_data';

class FilePickResult {
  final String name;
  final Uint8List bytes;
  final bool isPdf;
  const FilePickResult({required this.name, required this.bytes, required this.isPdf});
}

Future<FilePickResult?> pickFileForAi() async {
  // モバイル・デスクトップではfile_pickerを使う予定
  return null;
}
