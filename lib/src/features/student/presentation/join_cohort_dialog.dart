import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/student_cohort_controller.dart';

class JoinCohortDialog extends ConsumerStatefulWidget {
  const JoinCohortDialog({super.key});

  @override
  ConsumerState<JoinCohortDialog> createState() => _JoinCohortDialogState();
}

class _JoinCohortDialogState extends ConsumerState<JoinCohortDialog> {
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await ref.read(studentCohortsProvider.notifier).joinCohort(token);

    if (mounted) {
      if (error == null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the cohort!')),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join New Cohort'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter the invitation token provided by your instructor.'),
          const SizedBox(height: 16),
          TextField(
            controller: _tokenController,
            decoration: InputDecoration(
              labelText: 'Invitation Token',
              hintText: 'e.g. AB12CD',
              border: const OutlineInputBorder(),
              errorText: _errorMessage,
            ),
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Join'),
        ),
      ],
    );
  }
}
