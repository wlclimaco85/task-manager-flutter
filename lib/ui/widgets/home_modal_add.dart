import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/custom_button.dart';
import 'package:task_manager_flutter/ui/widgets/custom_text_form_field.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
import 'home_list_model.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';

class HomeModalAdd extends StatefulWidget {
  List<HomeListModel> listModels = [];
  Function fncRefresh;

  HomeModalAdd({super.key, required this.listModels, required this.fncRefresh});
  @override
  State<HomeModalAdd> createState() => _HomeModalAddState();
}

class _HomeModalAddState extends State<HomeModalAdd> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _taskNameController = TextEditingController();

  final TextEditingController _taskDescriptionController =
      TextEditingController();
  bool _addNewTaskLoading = false;
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
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  color: Colors.red,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 30,
                    ),
                    const Text(
                      "Add Task",
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            // The validator receives the text that the user has entered.
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter some text';
                              }
                              return null;
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: ElevatedButton(
                              onPressed: () {
                                // Validate returns true if the form is valid, or false otherwise.
                                if (_formKey.currentState!.validate()) {
                                  // If the form is valid, display a snackbar. In the real world,
                                  // you'd often call a server or save the information in a database.
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Processing Data')),
                                  );
                                }
                              },
                              child: const Text('Submit'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CustomTextFormField(
                      hintText: "Task Title",
                      controller: _taskNameController,
                      textInputType: TextInputType.text,
                      // validator: (value) {
                      //   if (value?.isEmpty ?? true) {
                      //     return "Please enter task title";
                      //   }
                      //   return null;
                      // },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    CustomTextFormField(
                      maxLines: 4,
                      hintText: "Description",
                      controller: _taskDescriptionController,
                      textInputType: TextInputType.text,
                      // validator: (value) {
                      //   if (value?.isEmpty ?? true) {
                      //     return "Please enter task description";
                      //   }
                      //   return null;
                      // },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Visibility(
                        visible: _addNewTaskLoading == false,
                        replacement: const Center(
                          child: CircularProgressIndicator(),
                        ),
                        child: CustomButton(
                            onPresse: () {
                              print("ddd");
                            },
                            labels: "teste")),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  addInList() {
    HomeListModel hml = HomeListModel(
      title: _nameController.text,
      assetIcon: "assets/icons/gym_icon.png",
    );
    setState(() {
      widget.listModels.add(hml);
    });

    widget.fncRefresh();

    Navigator.pop(context);
  }
}
