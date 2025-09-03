import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/model/song.dart';
import '../now_playing/audio_player_manager.dart';
import '../playlist/playlist_manager.dart';


class NowPlaying extends ConsumerStatefulWidget {
  const NowPlaying({super.key, required this.songs, required this.playingSong});

  final List<Song> songs;
  final Song playingSong;

  @override
  ConsumerState<NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends ConsumerState<NowPlaying>
    with SingleTickerProviderStateMixin {
  late AnimationController _imageAnimationController;
  late AudioPlayerManager _audioPlayerManager;
  late int _selectedItemIndex;
  late Song _song;
  late double _curentAnimationPosition;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _song = widget.playingSong;
    _selectedItemIndex = widget.songs.indexOf(widget.playingSong);

    _imageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );

    _audioPlayerManager = AudioPlayerManager(songUrl: _song.source);
    _audioPlayerManager.init();

    _audioPlayerManager.player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _setNextSong();
      }
    });

    _curentAnimationPosition = 0.0;
  }

  @override
  void dispose() {
    _imageAnimationController.dispose();
    _audioPlayerManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Now Playing'),
        trailing: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_horiz),
        ),
      ),
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_song.album),
              const SizedBox(height: 16),
              const Text('_ ___ _'),
              const SizedBox(height: 32),
              _rotatingImage(),
              Padding(
                padding: const EdgeInsets.only(top: 64, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.share_outlined),
                    ),
                    Column(
                      children: [
                        Text(
                          _song.title,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _song.artist,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        _showPlaylistDialog(context);
                      },
                      icon: const Icon(Icons.favorite_border_outlined),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _progressBar(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _mediaButtons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressBar() {
    return StreamBuilder<DurationState>(
      stream: _audioPlayerManager.durationState,
      builder: (context, snapshot) {
        final durationState = snapshot.data;
        return ProgressBar(
          progress: durationState?.progress ?? Duration.zero,
          total: durationState?.total ?? Duration.zero,
          buffered: durationState?.buffered ?? Duration.zero,
          onSeek: _audioPlayerManager.player.seek,
        );
      },
    );
  }

  Widget _playButton() {
    return StreamBuilder<PlayerState>(
      stream: _audioPlayerManager.player.playerStateStream,
      builder: (context, snapshot) {
        final playState = snapshot.data;
        final playing = playState?.playing ?? false;
        final processing = playState?.processingState;

        if ((processing == ProcessingState.loading || processing == ProcessingState.buffering) &&
            !_hasStarted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _audioPlayerManager.player.play();
            _imageAnimationController.forward(from: _curentAnimationPosition);
            _imageAnimationController.repeat();
            _hasStarted = true;
          });

          return const MediaButtonControl(
            function: null,
            icon: Icons.pause,
            color: null,
            size: 48,
          );
        }

        if (!playing) {
          return MediaButtonControl(
            function: () {
              _audioPlayerManager.player.play();
              _imageAnimationController.forward(from: _curentAnimationPosition);
              _imageAnimationController.repeat();
            },
            icon: Icons.play_arrow,
            color: null,
            size: 48,
          );
        }

        return MediaButtonControl(
          function: () {
            _audioPlayerManager.player.pause();
            _imageAnimationController.stop();
            _curentAnimationPosition = _imageAnimationController.value;
          },
          icon: Icons.pause,
          color: null,
          size: 48,
        );
      },
    );
  }

  Widget _mediaButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const MediaButtonControl(
          function: null,
          icon: Icons.shuffle,
          color: Colors.deepPurpleAccent,
          size: 24,
        ),
        MediaButtonControl(
          function: _setPrevSong,
          icon: Icons.skip_previous,
          color: Colors.deepPurpleAccent,
          size: 48,
        ),
        _playButton(),
        MediaButtonControl(
          function: _setNextSong,
          icon: Icons.skip_next,
          color: Colors.deepPurpleAccent,
          size: 48,
        ),
        const MediaButtonControl(
          function: null,
          icon: Icons.repeat,
          color: Colors.deepPurpleAccent,
          size: 24,
        ),
      ],
    );
  }

  Widget _rotatingImage() {
    final screenWidth = MediaQuery.of(context).size.width;
    const delta = 64.0;
    final radius = (screenWidth - delta) / 2;

    return StreamBuilder<PlayerState>(
      stream: _audioPlayerManager.player.playerStateStream,
      builder: (context, snapshot) {
        final processing = snapshot.data?.processingState;

        if (processing == ProcessingState.loading || processing == ProcessingState.buffering) {
          return Image.asset(
            'assets/img/iconload.png',
            width: screenWidth - delta,
            height: screenWidth - delta,
          );
        }

        return RotationTransition(
          turns: Tween(begin: 0.0, end: 1.0).animate(_imageAnimationController),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: FadeInImage.assetNetwork(
              placeholder: 'assets/img/musicload.png',
              image: _song.image,
              width: screenWidth - delta,
              height: screenWidth - delta,
              imageErrorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/img/musicload.png',
                  width: screenWidth - delta,
                  height: screenWidth - delta,
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _setNextSong() {
    if (_selectedItemIndex + 1 < widget.songs.length) {
      _selectedItemIndex++;
      final nextSong = widget.songs[_selectedItemIndex];
      _audioPlayerManager.updateSongUrl(nextSong.source);
      setState(() {
        _song = nextSong;
        _hasStarted = false;
      });
    }
  }

  void _setPrevSong() {
    if (_selectedItemIndex > 0) {
      _selectedItemIndex--;
      final prevSong = widget.songs[_selectedItemIndex];
      _audioPlayerManager.updateSongUrl(prevSong.source);
      setState(() {
        _song = prevSong;
        _hasStarted = false;
      });
    }
  }

  void _showPlaylistDialog(BuildContext rootContext) {
    final playlists = ref.read(playlistProvider).keys.toList();
    final notifier = ref.read(playlistProvider.notifier);
    final textController = TextEditingController();

    showDialog(
      context: rootContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Chọn danh sách bài hát"),
          content: SizedBox(
            width: double.maxFinite,
            child: playlists.isEmpty
                ? const Center(child: Text("Chưa có playlist nào"))
                : ListView.builder(
              shrinkWrap: true,
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final name = playlists[index];
                return ListTile(
                  title: Text(name),
                  onTap: () {
                    ref.read(playlistProvider.notifier).addSongToPlaylist(name, _song);

                    Navigator.pop(dialogContext); // đóng dialog chọn
                    // ✅ dùng rootContext để show SnackBar
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      SnackBar(
                        content: Text("Đã thêm '${_song.title}' vào $name"),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // tạo playlist mới
                showDialog(
                  context: rootContext, // dùng rootContext thay vì dialogContext
                  builder: (context) => AlertDialog(
                    title: const Text("Nhập tên playlist mới"),
                    content: TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Tên playlist",
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          final newName = textController.text.trim();
                          if (newName.isNotEmpty) {
                            notifier.add(newName);
                            notifier.addSongToPlaylist(newName, _song);
                            textController.clear();

                            Navigator.pop(context); // đóng dialog nhập tên
                            Navigator.pop(dialogContext); // đóng dialog chọn playlist

                          }
                        },
                        child: const Text("Tạo"),
                      ),
                    ],
                  ),
                );
              },
              child: const Text("Tạo playlist mới"),
            ),
          ],
        );
      },
    );
  }

}

class MediaButtonControl extends StatelessWidget {
  const MediaButtonControl({
    super.key,
    required this.function,
    required this.icon,
    required this.color,
    required this.size,
  });

  final void Function()? function;
  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: function,
      icon: Icon(icon),
      iconSize: size,
      color: color ?? Theme.of(context).colorScheme.primary,
    );
  }
}
