
import os

body_part_1 = r"""
        return AlertDialog(
          title: const Text(" Save Link"),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _sharedUrl!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              if ((_sharedCaption ?? '').trim().isNotEmpty) ...[
                const Text("Caption:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _sharedCaption!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              const Text("Suggestions:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              FutureBuilder<List<FolderSuggestion>>(
                future: () async {
                  if (_sharedUrl == null) return <FolderSuggestion>[];

                  // 1. Fetch AI Suggestions
                  var promptText = _sharedCaption ?? '';
                  if (promptText.trim().isEmpty) {
                     try {
                        final meta = await MetadataService.fetchMetadata(_ensureHttpScheme(_sharedUrl!));
                        promptText = meta.title ?? '';
                     } catch (e) {
                        print('Error fetching metadata for AI fallback: $e');
                     }
                  }

                  if (promptText.trim().isEmpty) return <FolderSuggestion>[];

                  final aiSuggestions = await SuggestionService.fetchAiSuggestions(promptText);
                  
                  final suggestions = <FolderSuggestion>[];
                  for (final name in aiSuggestions) {
                    final normalizedName = name.trim().toLowerCase();
                    final existing = _folders.firstWhere(
                      (f) => (f['name'] as String).trim().toLowerCase() == normalizedName,
                      orElse: () => {},
                    );
                    
                    suggestions.add(FolderSuggestion(
                      name: existing.isNotEmpty ? existing['name'] : name,
                      isExisting: existing.isNotEmpty,
                      reason: existing.isNotEmpty ? 'Deep match' : 'AI Recommendation',
                    ));
                  }
                  return suggestions;
                }(),
                builder: (context, snapshot) {
                   if (!snapshot.hasData || snapshot.data!.isEmpty) {
                     return const SizedBox.shrink(); 
                   }
                   final suggestions = snapshot.data!;

                   print("Suggestions in UI: $suggestions");
                   SuggestionService.logDebugEvent('ui_render', {'suggestions': suggestions.map((e) => e.name).toList()});
                   return Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text("Recommended:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6E8EF5))),
                       const SizedBox(height: 8),
                       Wrap(
                         spacing: 8,
                         runSpacing: 8,
                         children: suggestions.map((suggestion) {
                           return ActionChip(
                               avatar: Icon(
                                 suggestion.isExisting ? Icons.folder : Icons.auto_awesome,
                                 size: 16,
                                 color: suggestion.isExisting ? const Color(0xFF6EC1FF) : const Color(0xFFFFC107)
                               ),
                               label: Text(suggestion.name),
                               tooltip: suggestion.reason,
                               backgroundColor: Colors.blue.withOpacity(0.05),
                               side: BorderSide.none,
                               onPressed: () async {
                                   if (suggestion.isExisting) {
                                     final normalized = suggestion.name.trim().toLowerCase();
                                     final folder = _folders.firstWhere(
                                       (f) => (f['name'] as String).trim().toLowerCase() == normalized,
                                       orElse: () => {},
                                     );
                                     if (folder.isNotEmpty) {
                                        await _saveLinkToFolder(folder['id'], _sharedUrl!, overrideTitle: _sharedCaption);
                                     }
                                   } else {
                                     final mappedUserId = await _getMappedUserId();
                                     if (mappedUserId != null) {
                                       try {
                                          final newFolder = await supabase
                                           .from('folders')
                                           .insert({'name': suggestion.name, 'user_id': mappedUserId})
                                           .select()
                                           .single();
                                          await _saveLinkToFolder(newFolder['id'], _sharedUrl!, overrideTitle: _sharedCaption);
                                       } catch (e) {
                                          print('Error auto-creating suggestion: $e');
                                          return;
                                       }
                                     }
                                   }
                                   Navigator.pop(context);
                                   _sharedUrl = null;
                                   _sharedCaption = null;
                                   _isFromShare = false;
                                   try { const MethodChannel('share_receiver').invokeMethod('clearSharedText'); } catch (_) {}
                               },
                            );
                         }).toList(),
                       ),
                       const SizedBox(height: 16),
                       const Divider(), 
                       const SizedBox(height: 8),
                     ],
                   );
                },
              ),
              
              const Text("All Folders:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_folders.isEmpty) ...[
                const Text("No folders found yet.", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                const Text("Tip: Create a folder to save your link into.", style: TextStyle(fontSize: 12, color: Colors.black54)),
              ] else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _folders.length,
                      itemBuilder: (context, index) {
                        final folder = _folders[index];
                        return ListTile(
                          leading: const Icon(Icons.folder, color: Color(0xFF6EC1FF)),
                          title: Text(folder['name']),
                          onTap: () async {
                            await _saveLinkToFolder(folder['id'], _sharedUrl!, overrideTitle: _sharedCaption);
                            Navigator.pop(context);
                            _sharedUrl = null;
                            _sharedCaption = null;
                            _isFromShare = false;
                            try {
                              const MethodChannel('share_receiver').invokeMethod('clearSharedText');
                            } catch (_) {}
                          },
                        );
                      }),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.create_new_folder, color: Color(0xFF8D6E63)),
                title: const Text("Create New Folder"),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateFolderWhileSharingDialog();
                },
              ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("CANCEL"),
              onPressed: () async {
                Navigator.pop(context);
                _sharedUrl = null;
                _sharedCaption = null;
                _isFromShare = false;
                try {
                  const MethodChannel('share_receiver').invokeMethod('clearSharedText');
                } catch (_) {}
              },
            ),
          ],
        );
      },
    );
  }
"""

target_file = r"c:\Users\misal\Documents\link_saver_app\lib\main.dart"

with open(target_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the insertion point: builder: (context) {
# Logic: Find the line with "builder: (context) {" inside _showSaveLinkDialog (the broken one)
# We know it's around line 2173 in the current file.
# And it currently looks like it is followed by 3 empty lines and then @override.

for i, line in enumerate(lines):
    if "builder: (context) {" in line:
        # Verify it's the right one (not _showCreateFolderWhileSharingDialog)
        # Check context: lines before should refer to barrierColor
        if "barrierColor: Colors.black54" in lines[i-1]:
            print(f"Found insertion point at line {i+1}")
            # We will replacing from this line... wait, this line is "builder: (context) {"
            # The body_part_1 starts with "        return AlertDialog("
            # So we keep the current line. We append body_part_1 AFTER it.
            # But the current file might have "builder: (context) {" followed by nothing.
            
            # Actually, I'll clear 5 lines after it just in case there's junk, but Step 475 showed empty lines.
            
            # Insert logic:
            # Keep lines[:i+1]
            # Insert body_part_1
            # Keep lines[i+4:] (Assuming 3 empty lines to skip)
            
            # Wait, let's be safer.
            # The broken method ends at "builder: (context) {".
            # The rest of the Body is missing.
            # So I should APPEND body_part_1 after "builder: (context) {"
            # AND I need to make sure I am not duplicating if there is partial content??
            # Step 475 showed nothing.
            
            new_content = "".join(lines[:i+1]) + body_part_1 + "".join(lines[i+4:]) 
            
            with open(target_file, 'w', encoding='utf-8') as f_out:
                f_out.write(new_content)
            
            print("Successfully patched file.")
            break
else:
    print("Could not find insertion point!")
