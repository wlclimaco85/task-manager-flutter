import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/models/task_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';
import 'package:task_manager_flutter/ui/widgets/custom_task_card.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';

class CompleteTaskScreen extends StatefulWidget {
  const CompleteTaskScreen({super.key});

  @override
  State<CompleteTaskScreen> createState() => _CompleteTaskScreenState();
}

class _CompleteTaskScreenState extends State<CompleteTaskScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getAllCompletedTaskFunction();
    });
  }

  TaskListModel _completedTaskModel = TaskListModel();
  bool _loaderForCompletedTaskScreen = false;

  Future<void> getAllCompletedTaskFunction() async {
    _loaderForCompletedTaskScreen = true;
    if (mounted) {
      setState(() {});
    }

    NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.completedTaskStatus);
    if (response.isSuccess) {
      _completedTaskModel = TaskListModel.fromJson(response.body!);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to load data"),
          ),
        );
      }
    }
    _loaderForCompletedTaskScreen = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: userBanner(context,onTapped: () {
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
                  getAllCompletedTaskFunction();
                },
                child: _loaderForCompletedTaskScreen
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : ListView.builder(
                        itemBuilder: (context, int index) {
                          return CustomTaskCard(
                            title: _completedTaskModel.data?[index].title ?? "unknown",
                            description:
                                _completedTaskModel.data?[index].description ?? "",
                            createdDate:
                                _completedTaskModel.data?[index].createdDate ?? "",
                            status: _completedTaskModel.data?[index].status ?? "New",
                            onEditPressed: () {},
                            onDeletePressed: () {}, chipColor: Colors.green,
                          );
                        },
                        itemCount: _completedTaskModel.data?.length ?? 0),
              ),
            ))
          ],
        ),
      ),
    );
  }
}
