import 'package:flutter/material.dart';
import '../../shared/widgets/stub_screen.dart';

class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({required this.idOrSlug, super.key});

  final String idOrSlug;

  @override
  Widget build(BuildContext context) => StubScreen(
        title: 'Course',
        section: '§05 Flutter screens',
        subtitle: 'Course: $idOrSlug',
      );
}
