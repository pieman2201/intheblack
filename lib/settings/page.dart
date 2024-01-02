import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/backend/types.dart';
import 'package:pfm/editors/budgeteditor.dart';
import 'package:pfm/widgets/budget.dart';

class SettingsPage extends StatefulWidget {
  final BackendController backendController;

  const SettingsPage({super.key, required this.backendController});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  Map<String, String> _accessTokenCursors = <String, String>{};
  Iterable<Budget> _budgets = [];

  late TextEditingController _editDialogTextController;

  Map<SettingsType, String> _settings = <SettingsType, String>{};

  @override
  void initState() {
    super.initState();

    // Trigger first-time 'refresh'
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshIndicatorKey.currentState?.show();
    });

    _editDialogTextController = TextEditingController();
  }

  Future<String?> showEditDialog(String dialogTitle, String valueTitle,
      [String? defaultValue]) {
    return showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          var dialog = AlertDialog(
            title: Text(dialogTitle),
            content: TextField(
              controller: _editDialogTextController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: valueTitle,
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(_editDialogTextController.value.text);
                  },
                  child: const Text('Submit'))
            ],
          );
          if (defaultValue != null) {
            _editDialogTextController.text = defaultValue;
          } else {
            _editDialogTextController.text = '';
          }
          return dialog;
        });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: () async {
        _accessTokenCursors =
            await widget.backendController.getAccessTokenCursors();
        _settings = await widget.backendController.getSettings();
        _budgets = await widget.backendController.getBudgets();
        setState(() {});
      },
      child: Theme(
        data: Theme.of(context).copyWith(
            textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size.square(0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ))),
        child: ListView(
          //padding: EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  const ListTile(
                    title: Text("API Settings"),
                  ),
                  ListTile(
                    title: Text(_settings[SettingsType.apiClientId].toString()),
                    subtitle: const Text("client_id"),
                    trailing: TextButton(
                      onPressed: () async {
                        String? newClientId = await showEditDialog(
                            'Edit client id',
                            'client_id',
                            _settings[SettingsType.apiClientId]);
                        if (newClientId != null) {
                          await widget.backendController.changeSetting(
                              SettingsType.apiClientId, newClientId.trim());
                        }
                        widget.backendController.openApiClient();
                        _refreshIndicatorKey.currentState?.show();
                      },
                      child: const Text("Edit"),
                    ),
                  ),
                  ListTile(
                    title: Text(_settings[SettingsType.apiSecret].toString()),
                    subtitle: const Text("secret"),
                    trailing: TextButton(
                      onPressed: () async {
                        String? newSecret = await showEditDialog('Edit secret',
                            'secret', _settings[SettingsType.apiSecret]);
                        if (newSecret != null) {
                          await widget.backendController.changeSetting(
                              SettingsType.apiSecret, newSecret.trim());
                        }
                        widget.backendController.openApiClient();
                        _refreshIndicatorKey.currentState?.show();
                      },
                      child: const Text("Edit"),
                    ),
                  )
                ],
              ),
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text(
                      "Access tokens",
                    ),
                    trailing: TextButton(
                        onPressed: () async {
                          String? newAccessToken = await showEditDialog(
                              'Add access token', 'access_token');
                          if (newAccessToken != null) {
                            await widget.backendController
                                .addNewAccessToken(newAccessToken.trim());
                          }
                          _refreshIndicatorKey.currentState?.show();
                        },
                        child: const Text('Add')),
                  ),
                  ...(_accessTokenCursors.keys.map((key) => ListTile(
                        title: Text(key),
                        subtitle: Text(_accessTokenCursors[key]!),
                      ))),
                  _accessTokenCursors.keys.isNotEmpty
                      ? ListTile(
                          trailing: TextButton(
                              onPressed: () async {
                                await widget.backendController
                                    .clearAccessTokens();
                                _refreshIndicatorKey.currentState?.show();
                              },
                              child: const Text('Clear')),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
            Card(
                child: Padding(
                    padding: EdgeInsets.only(bottom: _budgets.isEmpty ? 0 : 12),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text(
                            "Budgets",
                          ),
                          //style: Theme.of(context).textTheme.titleLarge),,
                          trailing: TextButton(
                            onPressed: () async {
                              Budget? newBudget = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => BudgetPage(
                                            backendController:
                                                widget.backendController,
                                            budget: null,
                                          )));
                              if (newBudget != null) {
                                widget.backendController
                                    .upsertBudget(newBudget);
                              }
                              _refreshIndicatorKey.currentState?.show();
                            },
                            child: const Text('Add'),
                          ),
                        ),
                        ...(_budgets.map((e) => BudgetListItem(
                            backendController: widget.backendController,
                            budget: e)))
                      ],
                    )))
          ],
        ),
      ),
    );
  }
}
