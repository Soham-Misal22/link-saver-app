
import 'package:flutter/material.dart';

const Map<String, IconData> kFolderIcons = {
  // Essentials
  'folder': Icons.folder,
  'star': Icons.star,
  'favorite': Icons.favorite,
  'work': Icons.work,
  'person': Icons.person,
  'home': Icons.home,
  'school': Icons.school,
  'settings': Icons.settings,
  
  // Media
  'music': Icons.music_note,
  'video': Icons.movie,
  'image': Icons.image,
  'camera': Icons.camera_alt,
  'game': Icons.sports_esports,
  'book': Icons.book,
  
  // Lifestyle
  'fitness': Icons.fitness_center,
  'shopping': Icons.shopping_cart,
  'restaurant': Icons.restaurant,
  'cafe': Icons.local_cafe,
  'travel': Icons.flight,
  'car': Icons.directions_car,
  'money': Icons.attach_money,
  
  // Tech
  'computer': Icons.computer,
  'phone': Icons.smartphone,
  'code': Icons.code,
  'bug': Icons.pest_control,
  'cloud': Icons.cloud,
  'lock': Icons.lock,
  
  // Misc
  'idea': Icons.lightbulb,
  'gift': Icons.card_giftcard,
  'pet': Icons.pets,
  'art': Icons.palette,
  'map': Icons.map,
  'chat': Icons.chat,
  'mail': Icons.mail,
  'calendar': Icons.calendar_today,
};

class IconPicker extends StatefulWidget {
  final ValueChanged<String> onIconSelected;
  final String? initialIconKey;

  const IconPicker({
    super.key,
    required this.onIconSelected,
    this.initialIconKey,
  });

  @override
  State<IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<IconPicker> {
  String? _selectedKey;
  String _searchQuery = '';
  late List<String> _filteredKeys;

  @override
  void initState() {
    super.initState();
    _selectedKey = widget.initialIconKey;
    _filteredKeys = kFolderIcons.keys.toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredKeys = kFolderIcons.keys.toList();
      } else {
        _filteredKeys = kFolderIcons.keys
            .where((key) => key.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search Icon',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        SizedBox(
          height: 200,
          width: double.maxFinite,
          child: _filteredKeys.isEmpty
              ? const Center(child: Text("No icons found"))
              : GridView.builder(
            itemCount: _filteredKeys.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final key = _filteredKeys[index];
              final icon = kFolderIcons[key];
              final isSelected = _selectedKey == key;
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedKey = key;
                  });
                  widget.onIconSelected(key);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
                    border: isSelected 
                        ? Border.all(color: Theme.of(context).primaryColor, width: 2) 
                        : Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
