import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/home_list_item.dart';
import 'package:task_manager_flutter/ui/widgets/home_list_model.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';

// class HomePageContent extends StatelessWidget {
//   List<HomeListModel> listModels;
//   const HomePageContent({
//     Key? key,
//     required this.listModels,
//   }) : super(key: key);

class HomePageContent extends StatefulWidget {
  List<HomeListModel> listModels;
  HomePageContent({super.key, required this.listModels});

  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CustomColors().getGradientMainColor(),
            CustomColors().getGradientSecondaryColor(),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: 20,
      ),
      child: ListView.builder(
        itemCount: widget.listModels.length,
        itemBuilder: (context, index) {
          return HomeListItem(
            homeListModel: widget.listModels[index],
          );
        },
      ),
    );
  }
}
