import 'dart:async';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class FilePickResult {
  final String name;
  final Uint8List bytes;
  final bool isPdf;
  const FilePickResult({required this.name, required this.bytes, required this.isPdf});
}

Future<FilePickResult?> pickFileForAi() async {
  final completer = Completer<FilePickResult?>();
  final input = html.FileUploadInputElement();
  input.accept = '.pdf,.txt,.md,.fountain,.fdx';
  input.click();

  input.onChange.listen((event) {
    final file = input.files?.first;
    if (file == null) { completer.complete(null); return; }
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoad.listen((_) {
      final bytes = Uint8List.fromList(reader.result as List<int>);
      final isPdf = file.name.toLowerCase().endsWith('.pdf');
      completer.complete(FilePickResult(name: file.name, bytes: bytes, isPdf: isPdf));
    });
    reader.onError.listen((_) => completer.complete(null));
  });

  // キャンセル時
  html.window.addEventListener('focus', (_) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!completer.isCompleted) completer.complete(null);
    });
  }, false);

  return completer.future;
}
