import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/song.dart';

final playlistProvider = StateNotifierProvider<PlaylistNotifier, Map<String, List<Song>>>((ref) {
  return PlaylistNotifier();
});

class PlaylistNotifier extends StateNotifier<Map<String, List<Song>>> {
  PlaylistNotifier() : super({});

  void addPlaylist(String name) {
    if (!state.containsKey(name)) {
      state = {...state, name: []};
    }
  }

  void addSongToPlaylist(String playlistName, Song song) {
    final updated = [...?state[playlistName]];
    if (!updated.contains(song)) {
      updated.add(song);
    }
    state = {...state, playlistName: updated};
  }

  void removeSongFromPlaylist(String playlistName, Song song) {
    final updated = [...?state[playlistName]]..remove(song);
    state = {...state, playlistName: updated};
  }

  void removePlaylist(String name) {
    final newState = {...state};
    newState.remove(name);
    state = newState;
  }
}
