import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/spending/month.dart';

class SpendingPage extends StatelessWidget {
  final BackendController backendController;

  const SpendingPage({super.key, required this.backendController});

  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController();
    final DateTime currentTime = DateTime.now();

    return PageView.builder(
        controller: controller,
        reverse: true,
        itemBuilder: (BuildContext context, int index) {
          int currentMonth = currentTime.month;
          int currentYear = currentTime.year;

          int monthToShowMonth = currentMonth - index;
          int monthToShowYear = currentYear;
          while (monthToShowMonth <= 0) {
            monthToShowMonth += 12;
            monthToShowYear--;
          }
          DateTime monthToShow = DateTime(monthToShowYear, monthToShowMonth);
          return MonthSpendingPage(
              backendController: backendController, monthToShow: monthToShow);
        });
  }
}
