import 'package:anx_reader/page/book_shelf_page.dart';
import 'package:anx_reader/page/notes_page.dart';
import 'package:anx_reader/page/settings_page.dart';
import 'package:anx_reader/page/statistics_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const BookShelf(),
    const NotesPage(),
    const StatisticPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomBarItems(),
        currentIndex: _currentIndex,
        onTap: _onBottomTap,
      ),
    );
  }

  void _onBottomTap(index){
    setState(() {
      _currentIndex = index;
    });
  }

  List<BottomNavigationBarItem> _bottomBarItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.book,),
        label: 'Bookshelf',

      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.show_chart),
        label: 'Statistics',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.note),
        label: 'Notes',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];
  }


}
