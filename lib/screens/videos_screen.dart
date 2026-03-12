import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';
import '../models/video_model.dart';
import '../utils/app_theme.dart';
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
  String _activeTab = 'all';
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
        headerSliverBuilder: (context, _) => [_buildAppBar()],
        body: _buildBody(),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppTheme.darkSurface,
      titleSpacing: 16,
      title: _searchQuery.isNotEmpty
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search videos...',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                border: InputBorder.none,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            )
          : const Text('FlexX Player',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
      actions: [
        IconButton(
          icon: Icon(_searchQuery.isNotEmpty ? Icons.close : Icons.search, color: Colors.white),
          onPressed: () => setState(() {
            _searchQuery = _searchQuery.isNotEmpty ? '' : ' ';
            if (_searchQuery == ' ') _searchQuery = '';
            _searchController.clear();
          }),
        ),
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: Colors.white),
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort, color: Colors.white),
          color: AppTheme.darkCard,
          onSelected: (v) => setState(() => _sortBy = v),
          itemBuilder: (_) => [
            _popItem('name', Icons.sort_by_alpha, 'Name'),
            _popItem('date', Icons.calendar_today, 'Date'),
            _popItem('size', Icons.storage, 'Size'),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppTheme.darkSurface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _tabChip('all', 'All Videos'),
              const SizedBox(width: 8),
              _tabChip('folders', 'Folders'),
              const SizedBox(width: 8),
              _tabChip('recent', 'Recent'),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _popItem(String val, IconData icon, String title) {
    return PopupMenuItem(
      value: val,
      child: Row(children: [
        Icon(icon, color: _sortBy == val ? AppTheme.primaryColor : AppTheme.textSecondary, size: 18),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(color: _sortBy == val ? AppTheme.primaryColor : Colors.white)),
      ]),
    );
  }

  Widget _tabChip(String id, String label) {
    final sel = _activeTab == id;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? AppTheme.primaryColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? AppTheme.primaryColor : AppTheme.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: sel ? AppTheme.primaryColor : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
            )),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<MediaProvider>(
      builder: (context, mp, _) {
        if (mp.isScanning) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const CircularProgressIndicator(color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text('Scanning media...', style: TextStyle(color: AppTheme.textSecondary)),
            ]),
          );
        }

        if (_activeTab == 'folders') return _buildFoldersView(mp.videos);

        final videos = _filtered(mp.videos);
        if (videos.isEmpty) return _buildEmpty();

        return _isGridView ? _buildGrid(videos) : _buildList(videos);
      },
    );
  }

  List<VideoModel> _filtered(List<VideoModel> all) {
    var list = all;
    if (_searchQuery.isNotEmpty) {
      list = list.where((v) => v.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_activeTab == 'recent') {
      list = List.from(list)..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      return list.take(20).toList();
    }
    switch (_sortBy) {
      case 'date': list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded)); break;
      case 'size': list.sort((a, b) => b.size.compareTo(a.size)); break;
      default: list.sort((a, b) => a.title.compareTo(b.title));
    }
    return list;
  }

  // ── FOLDER VIEW ──
  Widget _buildFoldersView(List<VideoModel> all) {
    final Map<String, List<VideoModel>> folders = {};
    for (final v in all) {
      folders.putIfAbsent(v.folderName, () => []).add(v);
    }
    if (folders.isEmpty) return _buildEmpty();

    final keys = folders.keys.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: keys.length,
      itemBuilder: (ctx, i) {
        final folder = keys[i];
        final items = folders[folder]!;
        return GestureDetector(
          onTap: () {
            setState(() {
              _activeTab = 'all';
              _searchQuery = folder;
              _searchController.text = folder;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.darkCardElevated),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder, color: AppTheme.primaryColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(folder,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${items.length} videos',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ]),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── GRID VIEW ──
  Widget _buildGrid(List<VideoModel> videos) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.72,
        crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: videos.length,
      itemBuilder: (ctx, i) => _GridCard(
        video: videos[i],
        onTap: () => _open(videos[i], videos, i),
      ),
    );
  }

  // ── LIST VIEW ──
  Widget _buildList(List<VideoModel> videos) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: videos.length,
      itemBuilder: (ctx, i) => _ListTile(
        video: videos[i],
        onTap: () => _open(videos[i], videos, i),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.movie_creation_outlined, size: 72,
            color: AppTheme.textSecondary.withOpacity(0.25)),
        const SizedBox(height: 16),
        const Text('No videos found',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Videos on your device will appear here',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => context.read<MediaProvider>().scanMedia(forceRefresh: true),
          icon: const Icon(Icons.refresh),
          label: const Text('Scan Now'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    );
  }

  void _open(VideoModel v, List<VideoModel> list, int idx) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PlayerScreen(video: v, playlist: list, initialIndex: idx),
    ));
  }
}

// ── GRID CARD ──
class _GridCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;
  const _GridCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Stack(fit: StackFit.expand, children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _colorFromName(video.title).withOpacity(0.3),
                          AppTheme.darkCardElevated,
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 1.5),
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 26),
                    ),
                  ),
                  if (video.resolution.isNotEmpty)
                    Positioned(
                      top: 7, left: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(video.resolution,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  Positioned(
                    bottom: 7, right: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(video.durationFormatted,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(video.title,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(video.sizeFormatted,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                    ]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 18),
                    onPressed: () => _showOptions(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFromName(String name) {
    final colors = [Colors.blue, Colors.purple, Colors.teal, Colors.indigo, Colors.cyan];
    return colors[name.hashCode.abs() % colors.length];
  }

  void _showOptions(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _OptionsSheet(video: video),
    );
  }
}

// ── LIST TILE ──
class _ListTile extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;
  const _ListTile({required this.video, required this.onTap});

  Color _colorFromName(String name) {
    final colors = [Colors.blue, Colors.purple, Colors.teal, Colors.indigo, Colors.cyan];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 70,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_colorFromName(video.title).withOpacity(0.4), AppTheme.darkCardElevated],
                  ),
                ),
                child: const Icon(Icons.play_circle_fill, color: AppTheme.primaryColor, size: 30),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(video.title,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Row(children: [
                  if (video.resolution.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(video.resolution,
                          style: const TextStyle(color: AppTheme.primaryColor, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(video.durationFormatted,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  const SizedBox(width: 6),
                  Text('• ${video.sizeFormatted}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ]),
              ]),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 20),
              onPressed: () => showModalBottomSheet(
                context: context,
                backgroundColor: AppTheme.darkCard,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => _OptionsSheet(video: video),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── OPTIONS SHEET ──
class _OptionsSheet extends StatelessWidget {
  final VideoModel video;
  const _OptionsSheet({required this.video});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.movie, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(video.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${video.sizeFormatted} • ${video.durationFormatted}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ])),
        ]),
        const SizedBox(height: 16),
        const Divider(color: AppTheme.darkCardElevated),
        const SizedBox(height: 8),
        _opt(context, Icons.play_arrow, 'Play', AppTheme.primaryColor),
        _opt(context, Icons.info_outline, 'Properties', Colors.white),
        _opt(context, Icons.share, 'Share', Colors.white),
        _opt(context, Icons.favorite_border, 'Add to Favorites', Colors.white),
        _opt(context, Icons.playlist_add, 'Add to Playlist', Colors.white),
        _opt(context, Icons.delete_outline, 'Delete', AppTheme.errorColor),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _opt(BuildContext ctx, IconData icon, String title, Color color) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 20),
      title: Text(title, style: TextStyle(color: color, fontSize: 14)),
      onTap: () => Navigator.pop(ctx),
    );
  }
}
