import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/utils/ensure_visible_when_focused.dart';
// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0


class CustomInputForm extends StatelessWidget {
  String? Function(String?)? validator;
  late FocusNode focusNode;
  TextInputType? type;
  String keyField;
  Function(String?)? onPressed;


  CustomInputForm({
    Key? key,
    required this.validator,
    required this.focusNode,
    this.type,
    required this.keyField,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: EnsureVisibleWhenFocused(
        focusNode: focusNode,
        child: TextFormField(
          key: Key(keyField),
          keyboardType: type ?? TextInputType.text,
          decoration: InputDecoration(
            fillColor: CustomColors().getAppFundoImput(),
            filled: true,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(8.0),
              ),
              borderSide: BorderSide(
                color: Colors.yellow,
                width: 3.0,
              ),
            ),
            labelStyle: TextStyle(color: CustomColors().getAppFundoImput(), fontSize: 16.0),
            hintText: keyField,
          ),
          onChanged:onPressed,
      //    onChanged: (value) => title = value,
          validator: validator,
        ),
      ),
    );
  }
}
