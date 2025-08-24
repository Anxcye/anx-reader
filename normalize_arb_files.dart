import 'dart:io';
import 'dart:convert';

void main() async {
  final l10nDir = Directory('lib/l10n');
  
  final enFile = File('lib/l10n/app_en.arb');
  if (!await enFile.exists()) {
    print('Error: English ARB file not found');
    return;
  }
  
  final enContent = await enFile.readAsString();
  final Map<String, dynamic> enMap = json.decode(enContent);
  
  final orderedKeys = <String>[];
  for (final key in enMap.keys) {
    if (!key.startsWith('@@')) {
      orderedKeys.add(key);
    }
  }
  
  print('Found ${orderedKeys.length} translation keys in English file');
  
  final files = await l10nDir
      .list()
      .where((entity) => entity is File && 
             entity.path.endsWith('.arb') && 
             !entity.path.endsWith('app_en.arb'))
      .cast<File>()
      .toList();
  
  for (final file in files) {
    await normalizeArbFile(file, orderedKeys, enMap);
  }
  
  print('\nNormalization completed for ${files.length} files');
}

Future<void> normalizeArbFile(File file, List<String> orderedKeys, Map<String, dynamic> enMap) async {
  final fileName = file.path.split('/').last;
  print('Processing $fileName...');
  
  try {
    final content = await file.readAsString();
    final Map<String, dynamic> currentMap = json.decode(content);
    
    final Map<String, dynamic> normalizedMap = <String, dynamic>{};
    
    for (final key in currentMap.keys) {
      if (key.startsWith('@@')) {
        normalizedMap[key] = currentMap[key];
      }
    }
    
    int missingKeys = 0;
    int foundKeys = 0;
    
    for (final key in orderedKeys) {
      if (currentMap.containsKey(key)) {
        normalizedMap[key] = currentMap[key];
        foundKeys++;
      } else {
        print('  Warning: Missing key "$key", using English text as placeholder');
      }
    }
    
    final extraKeys = <String>[];
    for (final key in currentMap.keys) {
      if (!key.startsWith('@@') && !orderedKeys.contains(key)) {
        extraKeys.add(key);
        print('  Warning: Extra key found "$key" (will be removed)');
      }
    }
    
    const encoder = JsonEncoder.withIndent('  ');
    final normalizedContent = encoder.convert(normalizedMap);
    
    await file.writeAsString(normalizedContent + '\n');
    
    print('  ✓ Normalized $fileName: $foundKeys keys found, $missingKeys missing, ${extraKeys.length} extra removed');
    
  } catch (e) {
    print('  ✗ Error processing $fileName: $e');
  }
}