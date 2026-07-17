import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Video;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cinema/core/constants/app_constants.dart';
import 'package:cinema/core/constants/api_constants.dart';
import 'package:cinema/data/model/cast.dart';
import 'package:cinema/presentation/screens/detail/movie_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:cinema/providers/detail_provider.dart';
import 'package:cinema/data/repository/movie_repository.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final MovieDetail detail;
  final bool isTrailer;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.detail,
    this.isTrailer = false,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  
  bool _isPlaying = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _showControls = true;
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);

    _initPlayer();

    _player.stream.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });

    _player.stream.position.listen((position) {
      if (mounted) setState(() => _position = position);
    });

    _player.stream.duration.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });
  }

  Future<void> _initPlayer() async {
    try {
      if (widget.isTrailer && widget.detail.trailerId != null && widget.detail.trailerId!.isNotEmpty) {
        final yt = YoutubeExplode();
        final manifest = await yt.videos.streamsClient.getManifest(widget.detail.trailerId!);
        
        if (manifest.muxed.isNotEmpty) {
          final streamInfo = manifest.muxed.withHighestBitrate();
          _player.open(Media(streamInfo.url.toString()));
        } else {
          throw Exception('No playable video stream found for this trailer.');
        }
        yt.close();
      } else {
        _player.open(Media(widget.videoUrl));
      }
      _player.play();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildVideoPlayer(),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetadata(),
                    Divider(color: Theme.of(context).dividerColor, thickness: 1, height: 1),
                    _buildRelatedTab(),
                    _buildRelatedContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.4, // Prevents overflow on desktop
      ),
      color: Colors.black,
      child: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video Layer
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                        : _isError
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    _errorMessage.isNotEmpty ? _errorMessage : 'Failed to load YouTube stream.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                                  ),
                                ),
                              )
                        : Video(
                            controller: _controller,
                            controls: NoVideoControls, // We use custom controls
                          ),
              ),
            ),
            
            // Full Width Custom Controls Overlay
            if (_showControls) _buildControlsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      color: Colors.black45,
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Top Row (Back and Icons)
          Positioned(
            top: 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // Center Controls (Rewind, Play/Pause)
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10, color: Colors.white, size: 48),
                  onPressed: () {
                    final newPosition = _position - const Duration(seconds: 10);
                    _player.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
                  },
                ),
                const SizedBox(width: 32),
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 56,
                  ),
                  onPressed: () {
                    _isPlaying ? _player.pause() : _player.play();
                  },
                ),
                const SizedBox(width: 32),
                IconButton(
                  icon: const Icon(Icons.forward_10, color: Colors.white, size: 48),
                  onPressed: () {
                    final newPosition = _position + const Duration(seconds: 10);
                    _player.seek(newPosition > _duration ? _duration : newPosition);
                  },
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildProgressBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    double progress = 0.0;
    if (_duration.inMilliseconds > 0) {
      progress = _position.inMilliseconds / _duration.inMilliseconds;
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Container(
              height: 4,
              width: constraints.maxWidth,
              color: Colors.white24,
            ),
            Container(
              height: 4,
              width: constraints.maxWidth * progress,
              color: Colors.red,
            ),
          ],
        );
      }
    );
  }

  Widget _buildMetadata() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.detail.title,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.detail.genres.isNotEmpty ? widget.detail.genres.first.name : 'Movie'} | ${widget.detail.year}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            widget.detail.overview,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }




  Widget _buildRelatedTab() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RELATED', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(height: 2, width: 40, color: Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildRelatedContent() {
    if (widget.detail.similar.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'More Like This',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.detail.similar.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final s = widget.detail.similar[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider(
                          create: (_) => DetailProvider(GetIt.I<MovieRepository>()),
                          child: MovieDetailScreen(movieId: s.id),
                        ),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 220,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (s.posterPath != null)
                                  CachedNetworkImage(
                                    imageUrl: ApiConstants.backdropUrl(s.posterPath),
                                    fit: BoxFit.cover,
                                  )
                                else
                                  Container(color: Theme.of(context).cardColor),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${s.voteAverage.toStringAsFixed(1)} ⭐',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
