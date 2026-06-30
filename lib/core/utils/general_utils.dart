import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class GeneralUtils {
  static Future<void> downloadAndOpen(BuildContext context, String url) async {
    final dir = await getTemporaryDirectory();
    final segs = Uri.parse(url).pathSegments;
    final name = segs.isNotEmpty
        ? segs.last
        : 'file_${DateTime.now().millisecondsSinceEpoch}';
    final path = '${dir.path}/$name';
    await Dio().download(url, path);
    await OpenFile.open(path);
  }
}
