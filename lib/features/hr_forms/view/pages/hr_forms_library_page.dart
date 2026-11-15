import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../domain/models/hr_form_template_def.dart';

class HrFormsLibraryPage extends StatefulWidget {
  const HrFormsLibraryPage({super.key, this.onOpen});
  final void Function(String)? onOpen;
  @override
  State<HrFormsLibraryPage> createState() => _HrFormsLibraryPageState();
}

class _HrFormsLibraryPageState extends State<HrFormsLibraryPage> {
  String search = '';
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final items = hrFormTemplates
        .where(
          (f) => '${f.titleAr} ${f.titleEn}'.toLowerCase().contains(
            search.toLowerCase().trim(),
          ),
        )
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ar ? 'مكتبة نماذج الموارد البشرية' : 'HR forms library',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF21194E),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ar
                ? 'اختر النموذج، عبّئ البيانات ثم عاين واطبع النسخة. النماذج الأولية لا تنشئ موافقات تلقائية.'
                : 'Choose a form, fill its fields, then preview and print. Prototypes do not submit automatic approvals.',
          ),
          const SizedBox(height: 20),
          TextField(
            key: const ValueKey('hr-library-search'),
            onChanged: (v) => setState(() => search = v),
            decoration: InputDecoration(
              labelText: ar ? 'ابحث عن نموذج' : 'Search forms',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(ar ? '${items.length} نموذج' : '${items.length} forms'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final item in items)
                  SizedBox(
                    width: constraints.maxWidth >= 900
                        ? (constraints.maxWidth - 32) / 3
                        : constraints.maxWidth >= 600
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(item.icon, color: item.color, size: 30),
                            const SizedBox(height: 12),
                            Text(
                              item.title(ar),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(item.subtitle(ar)),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              key: ValueKey('open-${item.id}'),
                              onPressed: () {
                                if (widget.onOpen != null) {
                                  widget.onOpen!(item.id);
                                } else {
                                  context.push(
                                    AppRoutes.hrFormTemplate.replaceFirst(
                                      ':templateId',
                                      item.id,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.edit_document),
                              label: Text(ar ? 'تعبئة النموذج' : 'Fill form'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(ar ? 'لا توجد نماذج مطابقة' : 'No matching forms'),
            ),
        ],
      ),
    );
  }
}
