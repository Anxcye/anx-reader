import 'package:flutter/material.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Changelog screen for showing app updates
/// Displays version history and new features
class ChangelogScreen extends StatefulWidget {
  final String lastVersion;
  final String currentVersion;
  final VoidCallback onComplete;

  const ChangelogScreen({
    super.key,
    required this.lastVersion,
    required this.currentVersion,
    required this.onComplete,
  });

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen> {
  String _changelogContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChangelog();
  }

  Future<void> _loadChangelog() async {
    try {
      // Try to load changelog from assets
      // You can create markdown files for different versions
      _changelogContent = _getDefaultChangelog();
    } catch (e) {
      AnxLog.warning('Failed to load changelog: $e');
      _changelogContent = _getDefaultChangelog();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getDefaultChangelog() {
    return '''
# What's New in ${widget.currentVersion}

## 🎉 New Features
- Enhanced WebDAV synchronization with improved safety mechanisms
- Better database backup and recovery system
- Improved sync architecture for easier maintenance

## 🔧 Improvements
- Refactored sync client architecture for better modularity
- Enhanced error handling and user feedback
- Performance optimizations for large libraries

## 🐛 Bug Fixes
- Fixed various sync-related issues
- Improved stability and reliability
- Better error messages and recovery options

## 📖 Reading Experience
- Continued improvements to the reading interface
- Better support for various e-book formats
- Enhanced AI integration features

---

Thank you for using Anx Reader! We're constantly working to improve your reading experience.
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('What\'s New'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _onComplete,
            child: Text(
              'Continue',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.update,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Updated from ${widget.lastVersion}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome to Anx Reader ${widget.currentVersion}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: MarkdownBody(
                      data: _changelogContent,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        h1: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        h2: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                        p: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          height: 1.5,
                        ),
                        listBullet: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: _onComplete,
                    child: const Text('Continue to App'),
                  ),
                ),
              ],
            ),
    );
  }

  void _onComplete() async {
    try {      
      // Call the completion callback
      widget.onComplete();
    } catch (e) {
      AnxLog.severe('Failed to mark version update as handled: $e');
      // Still proceed to complete even if there's an error
      widget.onComplete();
    }
  }
}