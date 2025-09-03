import 'package:flutter/material.dart';
import '../../data/model/song.dart';
import '../../data/source/source.dart';
import '../now_playing/playing.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  List<Song> _allSongs = []; // To be passed in constructor or loaded
  List<Song> _filteredSongs = [];

  @override
  void initState() {
    super.initState();
    // TODO: Replace with your actual source
    loadSongs();
    _searchController.addListener(_onSearchChanged);
  }

  void loadSongs() async {
    // Giả sử bạn dùng LocalDataSource ở đây để demo
    final songs = await LocalDataSource().loadData(); // hoặc RemoteDataSource
    if (songs != null) {
      setState(() {
        _allSongs = songs;
        _filteredSongs = songs;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSongs = _allSongs
          .where((song) =>
      song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query))
          .toList();
    });
  }

  void _navigateToNowPlaying(Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NowPlaying(songs: _filteredSongs, playingSong: song),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Tìm bài hát...',
            border: InputBorder.none,
            icon: Icon(Icons.search),
          ),
        ),
      ),
      body: _filteredSongs.isEmpty
          ? const Center(child: Text('Không tìm thấy bài hát'))
          : ListView.builder(
        itemCount: _filteredSongs.length,
        itemBuilder: (context, index) {
          final song = _filteredSongs[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/img/musicload.png',
                image: song.image,
                width: 48,
                height: 48,
                imageErrorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/img/musicload.png',
                    width: 48,
                    height: 48,
                  );
                },
              ),
            ),
            title: Text(song.title),
            subtitle: Text(song.artist),
            onTap: () => _navigateToNowPlaying(song),
          );
        },
      ),
    );
  }
}
