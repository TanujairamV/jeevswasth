import 'package:flutter/material.dart';

class SurveyField extends StatelessWidget {
  const SurveyField({super.key, required this.controller, required this.label, this.keyboardType, this.maxLines = 1});
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
      );
}
