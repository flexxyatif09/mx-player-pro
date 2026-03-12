import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/app_theme.dart';

// ─────────────── AUDIO SCREEN ───────────────
class AudioScreen extends StatelessWidget {
  const AudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Audio'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.sort), onPressed: () {}),
        ],
      ),
      body: ListView(
        children: [
          _SectionHeader(title: 'Songs', count: 0),
          const _EmptyState(
            icon: FontAwesomeIcons.music,
            message: 'No audio files found',
            subtitle: 'Music on your device will appear here',
          ),
        ],
      ),
    );
  }
}

// ─────────────── FILES SCREEN ───────────────
class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Files'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.create_new_folder_outlined),
              onPressed: () {}),
        ],
      ),
      body: ListView(
        children: [
          _FileBrowserHeader(),
          _StorageCard(
            icon: Icons.phone_android,
            label: 'Internal Storage',
            path: '/storage/emulated/0',
            usedGB: 12.4,
            totalGB: 64.0,
          ),
          const SizedBox(height: 8),
          _QuickAccessSection(),
        ],
      ),
    );
  }
}

// ─────────────── STREAM SCREEN ───────────────
class StreamScreen extends StatelessWidget {
  const StreamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('Stream')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StreamInput(),
          const SizedBox(height: 24),
          const Text(
            'Recent Streams',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const _EmptyState(
            icon: FontAwesomeIcons.wifi,
            message: 'No recent streams',
            subtitle: 'Your streamed URLs will appear here',
          ),
        ],
      ),
    );
  }
}

// ─────────────── MORE SCREEN ───────────────
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          _ProfileCard(),
          const SizedBox(height: 8),
          _SettingsSection(title: 'Player', items: [
            _SettingItem(icon: Icons.subtitles, title: 'Subtitles', subtitle: 'Auto-load, font size, style'),
            _SettingItem(icon: Icons.audiotrack, title: 'Audio', subtitle: 'Audio track, equalizer'),
            _SettingItem(icon: Icons.speed, title: 'Playback Speed', subtitle: 'Default: 1x'),
            _SettingItem(icon: Icons.screen_rotation, title: 'Screen Orientation', subtitle: 'Auto rotate'),
            _SettingItem(icon: Icons.fit_screen, title: 'Zoom Mode', subtitle: 'Fit to screen'),
          ]),
          _SettingsSection(title: 'App', items: [
            _SettingItem(icon: Icons.dark_mode, title: 'Theme', subtitle: 'Dark'),
            _SettingItem(icon: Icons.folder_open, title: 'Scan Folders', subtitle: 'Manage scan paths'),
            _SettingItem(icon: Icons.lock_open, title: 'Private Mode', subtitle: 'Hide content from gallery'),
            _SettingItem(icon: Icons.storage, title: 'Storage & Cache', subtitle: 'Clear cache'),
          ]),
          _SettingsSection(title: 'About', items: [
            _SettingItem(icon: Icons.info_outline, title: 'Version', subtitle: '1.0.0'),
            _SettingItem(icon: Icons.rate_review_outlined, title: 'Rate App', subtitle: ''),
            _SettingItem(icon: Icons.share, title: 'Share App', subtitle: ''),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: const TextStyle(
                    color: AppTheme.primaryColor, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(icon,
              size: 56, color: AppTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FileBrowserHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.home, color: AppTheme.primaryColor, size: 18),
          const SizedBox(width: 4),
          const Text('Home',
              style: TextStyle(color: AppTheme.primaryColor, fontSize: 14)),
        ],
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final double usedGB;
  final double totalGB;

  const _StorageCard({
    required this.icon,
    required this.label,
    required this.path,
    required this.usedGB,
    required this.totalGB,
  });

  @override
  Widget build(BuildContext context) {
    final percent = usedGB / totalGB;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: AppTheme.darkCardElevated,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${usedGB.toStringAsFixed(1)} GB / ${totalGB.toStringAsFixed(0)} GB',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.download, 'label': 'Downloads'},
      {'icon': Icons.photo_camera, 'label': 'DCIM'},
      {'icon': Icons.movie, 'label': 'Movies'},
      {'icon': Icons.music_note, 'label': 'Music'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Access',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: items
                .map((item) => _QuickAccessItem(
                      icon: item['icon'] as IconData,
                      label: item['label'] as String,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickAccessItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 11),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _StreamInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Open Network Stream',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 4),
          Text('Enter URL to stream video directly',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'https://example.com/video.m3u8',
              hintStyle: TextStyle(
                  color: AppTheme.textSecondary.withOpacity(0.5),
                  fontSize: 13),
              filled: true,
              fillColor: AppTheme.darkCardElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.link, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Stream',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0044CC), Color(0xFF00B4FF)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Guest User',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text('Sign in for sync & more features',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Sign In',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingItem> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: items.map((item) {
                final isLast = items.last == item;
                return Column(
                  children: [
                    item,
                    if (!isLast)
                      const Divider(
                          color: AppTheme.darkCardElevated,
                          height: 1,
                          indent: 52),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor, size: 20),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11))
          : null,
      trailing: const Icon(Icons.chevron_right,
          color: AppTheme.textSecondary, size: 18),
      onTap: () {},
      dense: true,
    );
  }
}
