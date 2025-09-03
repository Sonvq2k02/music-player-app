import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/model/song.dart';
import '../home/song_items.dart';
import '../now_playing/playing.dart';

import 'playlist_manager.dart';

class PlayListTab extends ConsumerWidget {
  PlayListTab({super.key});

  final TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);
    final notifier = ref.read(playlistProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Playlists"),
      ),
      body: playlists.isEmpty
          ? const Center(child: Text("Chưa có playlist nào"))
          : ListView(
        children: playlists.entries.map((entry) {
          final playlistName = entry.key;
          final songs = entry.value;

          return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
          child:  ExpansionTile(
            title: Text(playlistName),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Xoá playlist"),
                    content: Text("Bạn có chắc muốn xoá playlist '$playlistName'?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          notifier.removePlaylist(playlistName);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Đã xoá playlist $playlistName")),
                          );
                        },
                        child: const Text("Delete"),
                      ),
                    ],
                  ),
                );
              },
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide.none,
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide.none,
            ),

            children: songs.map((song) {
              return SongItemTile(
                song: song,

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NowPlaying(
                        songs: songs,
                        playingSong: song,
                      ),
                    ),
                  );
                },
                onMorePressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return SizedBox(
                        height: 120,
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.delete),
                              title: const Text("Xoá khỏi playlist"),
                              onTap: () {
                                notifier.removeSongFromPlaylist(
                                    playlistName, song);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            }).toList(),
          ));
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addItemDialog(context, notifier),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addItemDialog(BuildContext context, PlaylistNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nhập tên playlist"),
        content: TextField(
          controller: textEditingController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Nhập tên playlist",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (textEditingController.text.trim().isNotEmpty) {
                notifier.add(textEditingController.text.trim());
                textEditingController.clear();
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
