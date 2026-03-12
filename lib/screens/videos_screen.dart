import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../providers/media_provider.dart';
import '../models/video_model.dart';
import '../utils/app_theme.dart';
import '../widgets/video_card.dart';
import '../widgets/video_list_tile.dart';
import 'player_screen.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isGridView = true;
  String _sortBy = 'name';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(innerBoxIsScrolled),
        ],
        body: _buildBody(),
      ),
    );
  }

  Widget _buildAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppTheme.darkSurface,
      title: const Text(
        'MX Player Pro',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: _showSearch,
        ),
        IconButton(
          icon: Icon(
            _isGridView ? Icons.list : Icons.grid_view,
            color: Colors.white,
          ),
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort, color: Colors.white),
          color: AppTheme.darkCard,
          onSelected: (value) => setState(() => _sortBy = value),
          itemBuilder: (_) => [
            _buildPopupItem('name', 'Sort by Name'),
            _buildPopupItem('date', 'Sort by Date'),
            _buildPopupItem('size', 'Sort by Size'),
            _buildPopupItem('duration', 'Sort by Duration'),
          ],
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: _buildTabBar(),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, String title) {
    return PopupMenuItem(
      value: value,
      child: Text(title, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.darkSurface,
      child: Row(
        children: [
          _buildTab('All Videos', true),
          _buildTab('Folders', false),
          _buildTab('Recent', false),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        if (mediaProvider.isScanning) {
          return _buildLoading();
        }

        if (mediaProvider.videos.isEmpty) {
          return _buildEmpty();
        }

        final filtered = _filterVideos(mediaProvider.videos);

        return Column(
          children: [
            if (_searchQuery.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${filtered.length} results for "$_searchQuery"',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            Expanded(
              child: _isGridView
                  ? _buildGridView(filtered)
                  : _buildListView(filtered),
            ),
          ],
        );
      },
    );
  }

  List<VideoModel> _filterVideos(List<VideoModel> videos) {
    var filtered = videos;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((v) =>
              v.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    switch (_sortBy) {
      case 'date':
        filtered.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case 'size':
        filtered.sort((a, b) => b.size.compareTo(a.size));
        break;
      case 'duration':
        filtered.sort((a, b) => b.duration.compareTo(a.duration));
        break;
      default:
        filtered.sort((a, b) => a.title.compareTo(b.title));
    }
    return filtered;
  }

  Widget _buildGridView(List<VideoModel> videos) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return VideoCard(
          video: videos[index],
          onTap: () => _openPlayer(videos[index], videos, index),
        );
      },
    );
  }

  Widget _buildListView(List<VideoModel> videos) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return VideoListTile(
          video: videos[index],
          onTap: () => _openPlayer(videos[index], videos, index),
        );
      },
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Scanning media...',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.film,
            size: 60,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No videos found',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Videos on your device will appear here',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                context.read<MediaProvider>().scanMedia(forceRefresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Scan Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPlayer(
      VideoModel video, List<VideoModel> playlist, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          video: video,
          playlist: playlist,
          initialIndex: index,
        ),
      ),
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: VideoSearchDelegate(
        videos: context.read<MediaProvider>().videos,
        onVideoTap: (video, playlist, index) =>
            _openPlayer(video, playlist, index),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Search Delegate
class VideoSearchDelegate extends SearchDelegate<VideoModel?> {
  final List<VideoModel> videos;
  final Function(VideoModel, List<VideoModel>, int) onVideoTap;

  VideoSearchDelegate({required this.videos, required this.onVideoTap});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTheme.darkSurface,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final results = videos
        .where((v) => v.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Container(
      color: AppTheme.darkBg,
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          return VideoListTile(
            video: results[index],
            onTap: () {
              onVideoTap(results[index], results, index);
            },
          );
        },
      ),
    );
  }
}
