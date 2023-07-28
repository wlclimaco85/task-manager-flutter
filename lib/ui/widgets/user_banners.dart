import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';

class UserBanners extends StatelessWidget {
  const UserBanners({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_outlined),
          onPressed: () {},
        ),
      ],
      flexibleSpace: Padding(
        padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UpdateProfileScreen()));
              },
              child: const CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(
                    "https://lh3.googleusercontent.com/a/AAcHTtcDcIjcAxYbE61EV4D7MPqUxP8TAu7elGBuYFxdmRYAa9M=s288-c-no"),
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
}
