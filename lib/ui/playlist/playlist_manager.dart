import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/song.dart';

final playlistProvider =
StateNotifierProvider<PlaylistNotifier, Map<String, List<Song>>>(
        (ref) => PlaylistNotifier());

class PlaylistNotifier extends StateNotifier<Map<String, List<Song>>> {
  PlaylistNotifier() : super({});

  void add(String name) {
    if (!state.containsKey(name)) {
      state = {
        ...state,
        name: [],
      };
    }
  }

  void addSongToPlaylist(String name, Song song) {
    if (!state.containsKey(name)) return;

    final songs = List<Song>.from(state[name]!);
    if (!songs.any((s) => s.source == song.source)) {
      songs.add(song);
      state = {
        ...state,
        name: songs,
      };
    }
  }

  void removePlaylist(String name) {
    state = {...state}..remove(name);
  }

  void removeSongFromPlaylist(String name, Song song) {
    if (!state.containsKey(name)) return;
    final songs = List<Song>.from(state[name]!);
    songs.removeWhere((s) => s.source == song.source);
    state = {
      ...state,
      name: songs,
    };
  }
}
