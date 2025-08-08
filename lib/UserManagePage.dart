import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserManagePage extends StatefulWidget {
  final String userType; // "pending" or "approved"

  const UserManagePage({super.key, required this.userType});

  @override
  State<UserManagePage> createState() => _UserManagePageState();
}

class _UserManagePageState extends State<UserManagePage> {
  List<Map<String, dynamic>> userList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserList();
  }

  Future<void> fetchUserList() async {
    final url = Uri.parse(
      widget.userType == "pending"
          ? "https://sonjobdamd.com/func/hcgetpendinglist.php"
          : "https://sonjobdamd.com/func/hcgetuserlist.php",
    );

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data["users"] is List) {
        setState(() {
          userList = List<Map<String, dynamic>>.from(data["users"]);
          isLoading = false;
        });
      }
    } catch (e) {
      print("불러오기 오류: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> handleAction(String userid, String action) async {
    final url = Uri.parse("https://sonjobdamd.com/func/hcaccountmanage.php");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userid": userid, "action": action}),
    );

    final data = jsonDecode(response.body);
    if (data["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "처리 완료")),
      );
      fetchUserList();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "오류 발생")),
      );
    }
  }

  void showUserDetail(Map<String, dynamic> user) {
    final filtered = Map.of(user)..remove("pwd");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${user["company_name"] ?? ""}${user["name"]} - ${user["userType"]}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: filtered.entries
              .map((e) => Row(
            children: [
              Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text('${e.value}')),
            ],
          ))
              .toList(),
        ),
        actions: [
          if (widget.userType == "pending") ...[
            TextButton(
              onPressed: () {
                handleAction(user["userid"], "accept");
                Navigator.pop(context);
              },
              child: const Text("수락"),
            ),
            TextButton(
              onPressed: () {
                handleAction(user["userid"], "reject");
                Navigator.pop(context);
              },
              child: const Text("거절"),
            ),
          ] else ...[
            TextButton(
              onPressed: () {
                handleAction(user["userid"], "remove");
                Navigator.pop(context);
              },
              child: const Text("제거"),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("닫기"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.userType == "pending" ? "가입 대기중 회원" : "정회원";

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userList.isEmpty
          ? const Center(child: Text("표시할 사용자가 없습니다."))
          : ListView.builder(
        itemCount: userList.length,
        itemBuilder: (_, index) {
          final user = userList[index];
          final display =
              '(${user["company_name"] ?? ""})${user["name"]} - ${user["userType"]}';

          return ListTile(
            title: Text(display),
            onTap: () => showUserDetail(user),
            trailing: const Icon(Icons.chevron_right),
          );
        },
      ),
    );
  }
}
