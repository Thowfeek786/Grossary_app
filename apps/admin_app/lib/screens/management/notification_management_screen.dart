import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:repository/repository.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  State<NotificationManagementScreen> createState() => _NotificationManagementScreenState();
}

class _NotificationManagementScreenState extends State<NotificationManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedTopic = NotificationTopics.all;
  bool _isLoading = false;

  final _topics = [
    {'label': 'All Apps', 'value': NotificationTopics.all},
    {'label': 'Customer App', 'value': NotificationTopics.users},
    {'label': 'Dealer App', 'value': NotificationTopics.dealers},
    {'label': 'Delivery Partner App', 'value': NotificationTopics.deliveryPartners},
  ];

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await NotificationRepository().sendBroadcastNotification(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        topic: _selectedTopic,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Push Notification sent successfully!')),
        );
        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast Notifications')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Send a push notification to specific users or all apps.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              
              // Target Selection
              DropdownButtonFormField<String>(
                value: _selectedTopic,
                decoration: const InputDecoration(
                  labelText: 'Target Audience',
                  border: OutlineInputBorder(),
                ),
                items: _topics.map((t) {
                  return DropdownMenuItem(
                    value: t['value'],
                    child: Text(t['label']!),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedTopic = val!),
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Notification Title',
                  hintText: 'e.g. Flash Sale Alert!',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // Body
              TextFormField(
                controller: _bodyController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message Body',
                  hintText: 'e.g. Get 50% off on all organic vegetables today.',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'Please enter message content' : null,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _sendNotification,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator()
                  : const Text('Send Broadcast Notification'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
