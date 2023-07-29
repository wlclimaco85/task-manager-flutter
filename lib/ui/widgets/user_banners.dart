import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/login_screen.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';

AppBar userBanner(context) {
  return AppBar(
    actions: [
      IconButton(
        icon: const Icon(FontAwesomeIcons.powerOff),
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Are you sure you want to logout?"),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("No")),
                    TextButton(
                        onPressed: () {
                          AuthUtility.clearUserInfo();
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()),
                              (route) => false);
                        },
                        child: const Text("Yes")),
                  ],
                );
              });
        },
      ),
    ],
    flexibleSpace: Container(
      margin: const EdgeInsets.fromLTRB(10, 30, 10, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UpdateProfileScreen()));
            },
            child: CircleAvatar(
              radius: 25,
              backgroundImage: const NetworkImage(
                  "https://lh3.googleusercontent.com/a/AAcHTtcDcIjcAxYbE61EV4D7MPqUxP8TAu7elGBuYFxdmRYAa9M=s288-c-no"),
              onBackgroundImageError: (_, __) {
                const Icon(FontAwesomeIcons.solidCircleUser);
              },
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${AuthUtility.userInfo.data?.firstName ?? " "} ${AuthUtility.userInfo.data?.lastName}",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(AuthUtility.userInfo.data?.email ?? "",
                  style: const TextStyle(fontSize: 14, color: Colors.white)),
            ],
          ),
        ],
      ),
    ),
  );
}
