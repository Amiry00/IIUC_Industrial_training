import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  // list of trailer ids, e.g. from popular movies
  final ids = ['8Qn_spdM5Zg', 'KVK586ZlY_Q', 'tMEleiTwZvY', 'yoLQCEhxcgI'];
  for (final id in ids) {
    try {
      final manifest = await yt.videos.streamsClient.getManifest(id);
      print('Video $id:');
      print('  muxed: ${manifest.muxed.length}');
      print('  videoOnly: ${manifest.videoOnly.length}');
    } catch (e) {
      print('Video $id failed: $e');
    }
  }
  yt.close();
}
