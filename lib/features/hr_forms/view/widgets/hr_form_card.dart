import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../domain/models/hr_form_template_def.dart';

class HrFormCard extends StatelessWidget {
  const HrFormCard({super.key, required this.template});

  final HrFormTemplateDef template;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final color = template.color;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.go('${AppRoutes.hrForms}/${template.id}'),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(template.icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                template.title(isArabic),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                template.subtitle(isArabic),
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    isArabic ? 'فتح النموذج' : 'Open Template',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_rounded, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
