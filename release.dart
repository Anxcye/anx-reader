// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';

void main() async {
  print('📦 Release Tool 📦');

  // Check if git is initialized
  if (!await _isGitRepo()) {
    print('Error: Not a git repository.');
    exit(1);
  }

  // Get current branch
  final currentBranch = await _getCurrentBranch();
  print('Current branch: $currentBranch');
  if (currentBranch != 'develop') {
    print('Error: Releases must start from develop branch.');
    exit(1);
  }
  // Display release options
  print('\nSelect release type:');
  print('1. Stable (main branch)');
  print('2. Beta (develop branch)');
  print('3. Alpha (develop branch)');

  final selection = stdin.readLineSync()?.trim();
  String releaseType;

  switch (selection) {
    case '1':
      releaseType = 'stable';
      break;
    case '2':
      releaseType = 'beta';
      break;
    case '3':
      releaseType = 'alpha';
      break;
    default:
      print('Invalid selection.');
      exit(1);
  }

  // Read pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found.');
    exit(1);
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final versionRegExp = RegExp(r'version:\s*(\d+\.\d+\.\d+)(\+(\d+))?');
  final match = versionRegExp.firstMatch(pubspecContent);

  if (match == null) {
    print('Error: Could not find version in pubspec.yaml.');
    exit(1);
  }

  final currentVersion = match.group(1);
  final currentBuild = match.group(3) != null ? int.parse(match.group(3)!) : 0;

  print('\nCurrent version in pubspec.yaml: $currentVersion+$currentBuild');

  // Get previous tags to suggest next version
  final allTags = await _getAllTags();
  final tags = await _getTagsByPattern(releaseType);

  String suggestedVersion = currentVersion!;
  // For pubspec build number - always increment
  int suggestedPubspecBuild = currentBuild + 1;
  // For tag build number - reset to 1 for each new version
  int suggestedTagBuild = 1;

  // For stable version, check if we need to increment the version
    final stableTags = await _getTagsByPattern('stable');
    final lastStableVersion = _extractLatestVersionFromTags(stableTags);

    // If current version matches last stable version, suggest a new version
    if (lastStableVersion == currentVersion) {
      final parts = currentVersion.split('.');
      if (parts.length == 3) {
        final major = int.parse(parts[0]);
        final minor = int.parse(parts[1]);
        final patch = int.parse(parts[2]);

        // Suggest incrementing the patch version
        suggestedVersion = '$major.$minor.${patch + 1}';
        print('\nCurrent version matches the latest stable release.');
        print('Suggesting a new version: $suggestedVersion');
      }
    }
    // For beta/alpha, check for existing builds of the current version in tags
    final versionTags =
        tags.where((tag) => tag.contains(suggestedVersion)).toList();
    if (versionTags.isNotEmpty) {
      suggestedTagBuild =
          _findHighestBuildNumber(versionTags, suggestedVersion) + 1;
    }
  

  if (allTags.isNotEmpty) {
    print('\nRecent tags:');
    for (int i = 0; i < allTags.length && i < 5; i++) {
      print('  ${allTags[i]}');
    }

    if (allTags.length > 5) {
      print('  ... and ${allTags.length - 5} more');
    }
  }

  if (tags.isNotEmpty) {
    print('\nPrevious $releaseType tags:');
    for (int i = 0; i < tags.length && i < 5; i++) {
      print('  ${tags[i]}');
    }

    if (tags.length > 5) {
      print('  ... and ${tags.length - 5} more');
    }
  }

  String tagPrefix = '';
  if (releaseType == 'stable') {
    tagPrefix = 'v';
  } else {
    tagPrefix = '$releaseType-';
  }

  String suggestedTag = '';
  if (releaseType == 'stable') {
    suggestedTag = '$tagPrefix$suggestedVersion';
  } else {
    suggestedTag = '$tagPrefix$suggestedVersion-$suggestedTagBuild';
  }

  print('\nSuggested tag: $suggestedTag');
  print('Suggested pubspec version: $suggestedVersion+$suggestedPubspecBuild');

  print('\nEnter new version (or press Enter to use $suggestedVersion):');
  final newVersion = stdin.readLineSync()?.trim();

  final version =
      newVersion?.isNotEmpty == true ? newVersion! : suggestedVersion;

  print('Enter new pubspec build number (or press Enter to use $suggestedPubspecBuild):');
  final newPubspecBuildStr = stdin.readLineSync()?.trim();
  final pubspecBuild = newPubspecBuildStr?.isNotEmpty == true
      ? int.parse(newPubspecBuildStr!)
      : suggestedPubspecBuild;

  if (releaseType != 'stable') {
    print('Enter new tag build number (or press Enter to use $suggestedTagBuild):');
    final newTagBuildStr = stdin.readLineSync()?.trim();
    suggestedTagBuild = newTagBuildStr?.isNotEmpty == true
        ? int.parse(newTagBuildStr!)
        : suggestedTagBuild;
  }

  // Confirm new version
  print('\nUpdate pubspec version to $version+$pubspecBuild? (y/n)');
  final confirmVersion = stdin.readLineSync()?.trim().toLowerCase();

  if (confirmVersion != 'y') {
    print('Release cancelled.');
    exit(0);
  }

  // Update pubspec.yaml
  final updatedPubspec =
      pubspecContent.replaceFirst(versionRegExp, 'version: $version+$pubspecBuild');

  pubspecFile.writeAsStringSync(updatedPubspec);
  print('Updated pubspec.yaml version to $version+$pubspecBuild');

  // Create git tag
  String tag = '';
  if (releaseType == 'stable') {
    tag = 'v$version';
  } else {
    tag = '$releaseType-$version-$suggestedTagBuild';
  }

  print('\nTag to create: $tag');
  print('Confirm? (y/n)');
  final confirmTag = stdin.readLineSync()?.trim().toLowerCase();

  if (confirmTag != 'y') {
    print('Tag creation cancelled. Version update is still applied.');
    exit(0);
  }

  // Git operations
  print('\nExecuting git commands...');

  try {
    // Add and commit changes in develop branch
    await _runCommand('git', ['add', '.']);
    print('✅ git add .');

    await _runCommand('git', ['commit', '-m', 'release: $tag']);
    print('✅ git commit -m "release: $tag"');

    await _runCommand('git', ['push']);
    print('✅ git push');

    if (releaseType == 'stable') {
      // For stable releases, merge to main, tag, then back to develop
      print('\nMerging to main branch for stable release...');
      await _runCommand('git', ['checkout', 'main']);
      print('✅ Switched to main branch');

      await _runCommand('git', ['merge', 'develop']);
      print('✅ Merged develop into main');

      await _runCommand('git', ['push']);
      print('✅ Pushed main branch');

      await _runCommand('git', ['tag', tag]);
      print('✅ git tag $tag');

      await _runCommand('git', ['push', 'origin', tag]);
      print('✅ git push origin $tag');

      // Return to develop branch
      await _runCommand('git', ['checkout', 'develop']);
      print('✅ Returned to develop branch');

      print('\n🎉 Stable release $tag completed successfully!');
    } else {
      // For beta/alpha, just tag on develop
      await _runCommand('git', ['tag', tag]);
      print('✅ git tag $tag');

      await _runCommand('git', ['push', 'origin', tag]);
      print('✅ git push origin $tag');

      print(
          '\n🎉 ${releaseType.capitalize()} release $tag completed successfully!');
    }
  } catch (e) {
    print('\n❌ Error during git operations: $e');
    exit(1);
  }
}

// Helper method to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

Future<bool> _isGitRepo() async {
  try {
    final result =
        await Process.run('git', ['rev-parse', '--is-inside-work-tree']);
    return result.exitCode == 0 && result.stdout.toString().trim() == 'true';
  } catch (e) {
    return false;
  }
}

Future<String> _getCurrentBranch() async {
  final result =
      await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
  return result.stdout.toString().trim();
}

Future<List<String>> _getAllTags() async {
  final result = await Process.run('git', ['tag', '--sort=-v:refname']);

  if (result.exitCode != 0) {
    return [];
  }

  final output = result.stdout.toString().trim();
  if (output.isEmpty) {
    return [];
  }

  return LineSplitter.split(output).toList();
}

Future<List<String>> _getTagsByPattern(String releaseType) async {
  String pattern;

  if (releaseType == 'stable') {
    pattern = 'v[0-9]*';
  } else {
    pattern = '$releaseType-*';
  }

  final result =
      await Process.run('git', ['tag', '-l', pattern, '--sort=-v:refname']);

  if (result.exitCode != 0) {
    return [];
  }

  final output = result.stdout.toString().trim();
  if (output.isEmpty) {
    return [];
  }

  return LineSplitter.split(output).toList();
}

String? _extractLatestVersionFromTags(List<String> tags) {
  if (tags.isEmpty) return null;

  // Extract version from a tag like v1.2.3
  final versionRegExp = RegExp(r'v(\d+\.\d+\.\d+)');
  final match = versionRegExp.firstMatch(tags.first);

  return match?.group(1);
}

int _findHighestBuildNumber(List<String> tags, String version) {
  int highestBuild = 0;

  // For alpha/beta tags like alpha-1.2.3-5
  final buildRegExp =
      RegExp(r'(?:alpha|beta)-' + version.replaceAll('.', '\\.') + r'-(\d+)');

  for (final tag in tags) {
    final match = buildRegExp.firstMatch(tag);
    if (match != null) {
      final buildNum = int.parse(match.group(1)!);
      if (buildNum > highestBuild) {
        highestBuild = buildNum;
      }
    }
  }

  return highestBuild;
}

Future<ProcessResult> _runCommand(
    String command, List<String> arguments) async {
  final result = await Process.run(command, arguments);

  if (result.exitCode != 0) {
    final error = result.stderr.toString().trim();
    throw Exception('Command failed: $command ${arguments.join(' ')}\n$error');
  }

  return result;
}
