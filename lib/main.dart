import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/configuration/page.dart';
import 'package:pfm/settings/page.dart';
import 'package:pfm/spending/page.dart';

final BackendController _backendController = BackendController();

void main() {
  runApp(const MyApp());
}

class DestinationPage {
  final Widget page;
  final NavigationDestination navigationIcon;

  DestinationPage({required this.page, required this.navigationIcon});
}

class BackendDestinationPage extends DestinationPage {
  BackendDestinationPage({required Widget page, required super.navigationIcon})
    : super(
        page: FutureBuilder(
          future: () async {
            await _backendController.open();
            return 0;
          }(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            // Don't show anything until the controller is initialized
            if (snapshot.hasData) {
              return page;
            }
            return const SizedBox.shrink();
          },
        ),
      );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const cardThemeData = CardThemeData(
      elevation: 0,
    );

    return DynamicColorBuilder(
      builder: (lightTheme, darkTheme) {
        return MaterialApp(
          title: 'Budgeting',
          theme: ThemeData(
            useSystemColors: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: (lightTheme != null) ? lightTheme.primary : Colors.white,
              brightness: Brightness.light,
              dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
            ),
            brightness: Brightness.light,
            useMaterial3: true,

            cardTheme: cardThemeData,
          ),
          darkTheme: ThemeData(
            useSystemColors: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: (darkTheme != null) ? darkTheme.primary :Colors.white,
              brightness: Brightness.dark,
              dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
            ),
            brightness: Brightness.dark,
            useMaterial3: true,

            cardTheme: cardThemeData,
          ),

          home: BottomNavigationPage(
            destinationPages: [
              BackendDestinationPage(
                page: SpendingPage(backendController: _backendController),
                navigationIcon: const NavigationDestination(
                  icon: Icon(Icons.local_atm),
                  label: 'Spending',
                ),
              ),
              BackendDestinationPage(
                page: ConfigurationPage(backendController: _backendController),
                navigationIcon: const NavigationDestination(
                  icon: Icon(Icons.filter_list),
                  label: "Categories",
                ),
              ),
              DestinationPage(
                page: Container(),
                navigationIcon: const NavigationDestination(
                  icon: Icon(Icons.search),
                  label: 'Transactions',
                ),
              ),
              BackendDestinationPage(
                page: SettingsPage(backendController: _backendController),
                navigationIcon: const NavigationDestination(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ),
            ],
          ),
        );
      },
    );
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
        destinations: widget.destinationPages
            .map((e) => e.navigationIcon)
            .toList(),
      ),
    );
  }
}
