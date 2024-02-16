import 'dart:convert';
import 'dart:convert';
import 'dart:io' as io;
import 'form_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/utils/personal_validation.dart';
import 'package:task_manager_flutter/ui/widgets/custom_plano_box_form.dart';
import 'package:task_manager_flutter/ui/widgets/custom_check_box_form.dart';
import 'package:task_manager_flutter/ui/widgets/custom_horario_box_form.dart';
import 'package:task_manager_flutter/ui/widgets/custom_input_dynamic_form.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/login_screen.dart';

final List<Map<String, dynamic>> _dataArray = []; //add this

class AcademiaDynamicForm extends StatefulWidget {
  const AcademiaDynamicForm({super.key});

  @override
  State<AcademiaDynamicForm> createState() => _AcademiaDynamicFormState();
}

class GetAcademiaDynamicForm {
  test() {
    return _dataArray;
  }
}

class _AcademiaDynamicFormState extends State<AcademiaDynamicForm> {
  List<ResponseForm> formResponse = [];
  bool isLoading = true;
  late FocusNode _focusNode;
  var dropdownvalue;
  var dateController = TextEditingController();
  bool switchValue = false;
  String? _data = ""; //add this
  XFile? pickImage;
  String? base64Image;

  void _onUpdate(int key, String value, chave) {
    void addData() {
      Map<String, dynamic> json = {
        'id': key,
        chave: value,
        chave: value,
        chave: value,
        chave: value
      };
      _dataArray.add(json);
      setState(() {
        _data = _dataArray.toString();
      });
    }

    if (_dataArray.isEmpty) {
      addData();
    } else {
      _dataArray.asMap().entries.map((entry) {
        if (entry.key == key && entry.value == chave) {
          _dataArray[key][chave] = value;
        }
        print(entry.key);
        print(entry.value);
      });

      for (var map in _dataArray) {
        if (map["id"] == key) {
          _dataArray[key][chave] = value;
          setState(() {
            _data = _dataArray.toString();
          });
          break;
        }
      }

      for (var map in _dataArray) {
        if (map["id"] == key) {
          return;
        }
      }
      addData();
    }
  }

  String MapToJson(List<Map<String, dynamic>> map) {
    String res = "";
    bool isEntrou = false;
    for (var s in map) {
      res += "{";

      for (String k in s.keys) {
        //"[{"id":"0","diaAtene":"Segunda,Segunda,Terça","dtInicio":"10:00"
        res += '"';
        res += k;
        res += '":"';
        res += s[k].toString();
        res += '",';
      }
      res = res.substring(0, res.length - 1);

      res += "},";
      isEntrou = true;
    }
    if (isEntrou) {
      res = res.substring(0, res.length - 1);
    } else {
      res = "";
    }

    return res;
  }

  Future<void> insertAluno() async {
    isLoading = true;
    if (mounted) {
      setState(() {});
    }
    GetAcademiaDynamicForm myObjectInstance = GetAcademiaDynamicForm();
    List<Map<String, dynamic>> dayName = myObjectInstance.test();

    String aa = MapToJson(dayName);

    Map<String, dynamic> requestBody = {
      "aluno": jsonDecode(aa),
    };
    print(jsonEncode(requestBody));
    final NetworkResponse response =
        await NetworkCaller().postRequest(ApiLinks.insertAluno, requestBody);
    isLoading = false;
    if (mounted) {
      setState(() {});
    }
    if (response.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile update Successful"),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile update Failed"),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    _focusNode = FocusNode();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getFromJson();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  getFromJson() async {
    String data = await DefaultAssetBundle.of(context)
        .loadString("assets/json/academia_form.json");
    final jsonResult = jsonDecode(data);

    setState(() {
      jsonResult.forEach(
          (element) => formResponse.add(ResponseForm.fromJson(element)));

      isLoading = false;
    });

    print(formResponse.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Academia"),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
            clipBehavior: Clip.antiAlias,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ListView(
              shrinkWrap: true,
              children: <Widget>[
                    Container(
                      color: CustomColors().getAppFundoPage(),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListView.builder(
                            itemCount: formResponse.length,
                            physics: const AlwaysScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formResponse[index].title!,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 20),
                                  myFormType(index),
                                ],
                              );
                            }),
                      ),
                    )]),
                  ]),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor : CustomColors().getAppBotton(),
        onPressed: () {
          insertAluno();
        },
        child: const Icon(Icons.check),
      ),
    );
  }

  String? Function(String?)? validatord(String nameValidation) {
    switch (nameValidation) {
      case 'EMAIL':
        return EmailValidator.validate;
        break;
      case 'TELEFONE':
        return EmailValidator.validate;
        break;
      case 'CPF':
        return EmailValidator.validate;
        break;
      case 'OBRIGATORIO':
        return EmailValidator.validate;
        break;
      case 'NADA':
        return EmailValidator.validate;
        break;
    }
    return null;
  }

  TextInputType? textInputType(String nameValidation) {
    switch (nameValidation) {
      case 'string':
        return TextInputType.text;
        break;
      case 'email':
        return TextInputType.emailAddress;
        break;
      case 'number':
        return TextInputType.number;
        break;
    }
    return null;
  }

  myFormType(index) {
    return ListView.separated(
      itemCount: formResponse[index].fields!.length,
      shrinkWrap: true,
      itemBuilder: (context, innerIndex) {
        return formResponse[index].fields![innerIndex].fieldType ==
                "DatetimePicker"
            ? myDatePicker(
                formResponse[index].fields![innerIndex].jsonName ?? "Field")
            : formResponse[index].fields![innerIndex].fieldType == "TextInput"
                ? CustomInputForm(
                    validator: validatord(
                        formResponse[index].fields![innerIndex].label ??
                            "NADA"),
                    onPressed: (vale) => _onUpdate(
                        0,
                        vale ?? "Field",
                        formResponse[index].fields![innerIndex].jsonName ??
                            "Field"),
                    focusNode: _focusNode,
                    type: textInputType(
                        formResponse[index].fields![innerIndex].type ?? "NADA"),
                    keyField: formResponse[index].fields![innerIndex].label ??
                        "Field")
                : formResponse[index].fields![innerIndex].fieldType ==
                        "SelectList"
                    ? dropDownWidget(
                        formResponse[index].fields![innerIndex].options,
                        formResponse[index].fields![innerIndex].jsonName ??
                            "Field")
                : formResponse[index].fields![innerIndex].fieldType ==
                        "foto"
                    ? fotoWidget(
                        formResponse[index].fields![innerIndex].options,
                        formResponse[index].fields![innerIndex].jsonName ??
                            "Field")
                : formResponse[index].fields![innerIndex].fieldType ==
                        "Plano"
                    ? myComboPlanos(
                        formResponse[index].fields![innerIndex].options,
                        formResponse[index].fields![innerIndex].jsonName ??
                            "Field")
                : formResponse[index].fields![innerIndex].fieldType ==
                        "Agenda"
                    ? myComboCalendario(
                        formResponse[index].fields![innerIndex].options,
                        formResponse[index].fields![innerIndex].jsonName ??
                            "Field")
                    : formResponse[index].fields![innerIndex].fieldType ==
                            "SwitchInput"
                        ? SwitchListTile(
                            value: switchValue,
                            title: Text(
                                formResponse[index].fields![innerIndex].label!),
                            onChanged: (value) {
                              setState(() {
                                switchValue = !switchValue;
                                _onUpdate(
                                    0,
                                    switchValue.toString(),
                                    formResponse[index]
                                            .fields![innerIndex]
                                            .jsonName ??
                                        "Field");
                              });
                            })
                        : const Text("Other type");
      },
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 10);
      },
    );
  }

  Widget myComboPlanos(List<Options>? items, String value) {
     return CustomComboBoxForm();
  }

  Widget myComboCalendario(List<Options>? items, String value) {
     return CustomDiasBoxForm();
  }

  Widget myDatePicker(String field) {
    return GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
          _selectDate(context);
        },
        child: AbsorbPointer(
          child: TextFormField(
            onChanged: (value) {
              _onUpdate(0, value, field);
            },
            controller: dateController,
            obscureText: false,
            cursorColor: Theme.of(context).primaryColor,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 14.0,
            ),
            decoration: InputDecoration(
              labelStyle: TextStyle(color: Theme.of(context).primaryColor),
              focusColor: Theme.of(context).primaryColor,
              filled: true,
              enabledBorder: UnderlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              labelText: "Date select",
              prefixIcon: const Icon(
                Icons.calendar_today,
                size: 18,
              ),
            ),
          ),
        ));
  }

  DateTime selectedDate = DateTime.now();

  Future _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(1970),
        lastDate: DateTime.now());
    if (picked != null && picked != selectedDate) {
      setState(() {
        var date = DateTime.parse(picked.toString());
        var formatted = "${date.year}-${date.month}-${date.day}";
        dateController = TextEditingController();
        dateController = TextEditingController(text: formatted.toString());
      });
    }
  }

  dropDownWidget(List<Options>? items, String value) {
    return DropdownButtonFormField<Options>(
      // Initial Value
      value: dropdownvalue,
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10.0),
          ),
        ),
        filled: true,
        hintStyle: TextStyle(color: Colors.grey[800]),
        hintText: items!.first.optionLabel!,
      ),
      borderRadius: BorderRadius.circular(10),

      // Down Arrow Icon
      icon: const Icon(Icons.keyboard_arrow_down),

      // Array list of items
      items: items.map((Options items) {
        return DropdownMenuItem<Options>(
          value: items,
          child: Text(items.optionValue!),
        );
      }).toList(),
      // After selecting the desired option,it will
      // change button value to selected value
      onChanged: (newValue) {
        setState(() {
          dropdownvalue = newValue!;
          _onUpdate(0, dropdownvalue.optionValue, value);
        });
      },
    );
  }

  fotoWidget(List<Options>? items, String value) {
    return InkWell(
                    onTap: () {
                      imagePicked();
                    },
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: const Text("Foto"),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: CustomColors().getAppFundoImput(),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            pickImage?.name ?? "",
                            maxLines: 1,
                            style: const TextStyle(
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    ]),
                  );
  }

    void imagePicked() async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Pick Image From:'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  onTap: () async {
                    pickImage = await ImagePicker()
                        .pickImage(source: ImageSource.camera);
                    if (pickImage != null) {
                      setState(() {});
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } else {}
                  },
                  leading: const Icon(Icons.camera),
                  title: const Text('Camera'),
                ),
                ListTile(
                  leading: const Icon(Icons.image),
                  onTap: () async {
                    pickImage = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);
                    if (pickImage != null) {
                      setState(() {});
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } else {}
                  },
                  title: const Text('Gallery'),
                )
              ],
            ),
          );
        });
  }
}
