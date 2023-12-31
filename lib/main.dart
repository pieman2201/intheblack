import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/settings/page.dart';
import 'package:pfm/spending/page.dart';

void main() {
  runApp(MyApp());
}

class DestinationPage {
  final Widget page;
  final NavigationDestination navigationIcon;

  DestinationPage({required this.page, required this.navigationIcon});
}

class MyApp extends StatelessWidget {
  final BackendController _backendController = BackendController();

  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (lightTheme, darkTheme) {
      return MaterialApp(
        title: 'Budgeting',
        theme: ThemeData(
            colorScheme:
                lightTheme ?? ColorScheme.fromSeed(seedColor: Colors.white)),
        darkTheme: ThemeData(
          colorScheme:
              darkTheme ?? ColorScheme.fromSeed(seedColor: Colors.white),
          useMaterial3: true,
        ),
        home: BottomNavigationPage(destinationPages: [
          DestinationPage(
            page: FutureBuilder(
              future: () async {
                await _backendController.open();
                return 0;
              }(),
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                // Don't show anything until the controller is initialized
                if (snapshot.hasData) {
                  return SpendingPage(backendController: _backendController);
                }
                return const SizedBox.shrink();
              },
            ),
            navigationIcon: const NavigationDestination(
                icon: Icon(Icons.monetization_on_outlined), label: 'Spending'),
          ),
          DestinationPage(
              page: Container(),
              navigationIcon: const NavigationDestination(
                  icon: Icon(Icons.search), label: 'Transactions')),
          DestinationPage(
            page: FutureBuilder(
              future: () async {
                await _backendController.open();
                return 0;
              }(),
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                // Don't show anything until the controller is initialized
                if (snapshot.hasData) {
                  return SettingsPage(backendController: _backendController);
                }
                return const SizedBox.shrink();
              },
            ),
            navigationIcon: const NavigationDestination(
                icon: Icon(Icons.settings), label: 'Settings'),
          )
        ]),
      );
    });
  }
}

class BottomNavigationPage extends StatefulWidget {
  final List<DestinationPage> destinationPages;

  const BottomNavigationPage({super.key, required this.destinationPages});

  @override
  State<BottomNavigationPage> createState() => _BottomNavigationPageState();
}

class _BottomNavigationPageState extends State<BottomNavigationPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.destinationPages[_selectedIndex].page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations:
            widget.destinationPages.map((e) => e.navigationIcon).toList(),
      ),
    );
  }
}
