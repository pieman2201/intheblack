import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/spending/month.dart';

class SpendingPage extends StatelessWidget {
  final BackendController backendController;

  const SpendingPage({super.key, required this.backendController});

  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController();

    return PageView.builder(
        controller: controller,
        reverse: true,
        itemBuilder: (BuildContext context, int index) {
          return MonthSpendingPage(
              backendController: backendController,
              nthPreviousMonthToShow: index);
        });
  }
}
