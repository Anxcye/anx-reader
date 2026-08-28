import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/dictionary/local_dictionary.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class DictionarySettings extends StatefulWidget {
  const DictionarySettings({super.key});

  @override
  State<DictionarySettings> createState() => _DictionarySettingsState();
}

class _DictionarySettingsState extends State<DictionarySettings> {
  bool _importing = false;

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mdx'],
    );
    final sourcePath = result?.files.single.path;
    if (sourcePath == null) return;
    setState(() => _importing = true);
    try {
      await LocalDictionaryService.importMdx(sourcePath);
      if (!mounted) return;
      setState(() => _importing = false);
      AnxToast.show(L10n.of(context).dictionaryImportSuccess);
    } catch (_) {
      if (!mounted) return;
      setState(() => _importing = false);
      AnxToast.show(L10n.of(context).dictionaryImportFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dictionaries = LocalDictionaryService.dictionaryPaths;
    return ListView(
      children: [
        ListTile(
          leading: _importing
              ? const CircularProgressIndicator()
              : const Icon(Icons.file_download_outlined),
          title: Text(L10n.of(context).dictionaryImport),
          subtitle: Text(L10n.of(context).dictionaryImportHint),
          onTap: _importing ? null : _import,
        ),
        const Divider(),
        if (dictionaries.isEmpty)
          ListTile(title: Text(L10n.of(context).dictionaryEmpty)),
        for (final dictionaryPath in dictionaries.reversed)
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(path.basenameWithoutExtension(dictionaryPath)),
            subtitle: Text(dictionaryPath),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await LocalDictionaryService.remove(dictionaryPath);
                if (mounted) setState(() {});
              },
            ),
          ),
      ],
    );
  }
}
