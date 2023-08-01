import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/models/task_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';
import 'package:task_manager_flutter/ui/widgets/custom_task_card.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';

class CancelledTaskScreen extends StatefulWidget {
  const CancelledTaskScreen({super.key});

  @override
  State<CancelledTaskScreen> createState() => _CancelledTaskScreenState();
}

class _CancelledTaskScreenState extends State<CancelledTaskScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getInProgressTaskFunction();
    });
  }

  TaskListModel _cancelledTaskModel = TaskListModel();
  bool _loadingScreenForCancelledTaskScreen = false;

  Future<void> getInProgressTaskFunction() async {
    _loadingScreenForCancelledTaskScreen = true;
    if (mounted) {
      setState(() {});
    }

    NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.cancelledTaskStatus);
    if (response.isSuccess) {
      _cancelledTaskModel = TaskListModel.fromJson(response.body!);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to load data"),
          ),
        );
      }
    }
    _loadingScreenForCancelledTaskScreen = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: userBanner(context, onTapped: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const UpdateProfileScreen()));
      }),
      body: ScreenBackground(
        child: Column(
          children: [
            Expanded(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: RefreshIndicator(
                onRefresh: () async {
                  getInProgressTaskFunction();
                },
                child: _loadingScreenForCancelledTaskScreen
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : ListView.builder(
                        itemBuilder: (context, int index) {
                          return CustomTaskCard(
                            title: _cancelledTaskModel.data?[index].title ??
                                "unknown",
                            description:
                                _cancelledTaskModel.data?[index].description ??
                                    "",
                            createdDate:
                                _cancelledTaskModel.data?[index].createdDate ??
                                    "",
                            status: _cancelledTaskModel.data?[index].status ??
                                "New",
                            onEditPressed: () {},
                            onDeletePressed: () {},
                            chipColor: Colors.red,
                          );
                        },
                        itemCount: _cancelledTaskModel.data?.length ?? 0),
              ),
            ))
          ],
        ),
      ),
    );
  }
}
