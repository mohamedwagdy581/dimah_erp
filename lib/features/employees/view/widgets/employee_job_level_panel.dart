import 'package:material_ui/material_ui.dart';
import '../../../../core/di/app_di.dart';
import '../../domain/job_level.dart';

class EmployeeJobLevelPanel extends StatefulWidget {
  const EmployeeJobLevelPanel({
    super.key,
    required this.employeeId,
    required this.canEdit,
  });
  final String employeeId;
  final bool canEdit;
  @override
  State<EmployeeJobLevelPanel> createState() => _EmployeeJobLevelPanelState();
}

class _EmployeeJobLevelPanelState extends State<EmployeeJobLevelPanel> {
  bool loading = true, saving = false, editing = false;
  String? level, draft;
  Object? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant EmployeeJobLevelPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.employeeId != widget.employeeId) {
      editing = false;
      load();
    }
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    final id = widget.employeeId;
    try {
      final value = await AppDI.supabase.rpc(
        'employee_job_level',
        params: {'p_employee_id': id},
      );
      if (mounted && widget.employeeId == id) {
        setState(() {
          level = value as String?;
          draft = level;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted && widget.employeeId == id) {
        setState(() {
          error = e;
          loading = false;
        });
      }
    }
  }

  Future<void> save() async {
    if (saving || !widget.canEdit) return;
    setState(() {
      saving = true;
      error = null;
    });
    final employeeId = widget.employeeId;
    final savedLevel = draft;
    try {
      await AppDI.supabase.rpc(
        'set_employee_job_level',
        params: {'p_employee_id': employeeId, 'p_level': savedLevel},
      );
      if (mounted && widget.employeeId == employeeId) {
        setState(() {
          level = savedLevel;
          editing = false;
        });
      }
    } catch (e) {
      if (mounted && widget.employeeId == employeeId) {
        setState(() {
          error = e;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String a, String e) => ar ? a : e;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5DDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                color: Color(0xFF8659BB),
              ),
              Text(
                tr('المستوى الوظيفي', 'Job level'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF21194E),
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (error == null || editing)
                Chip(label: Text(jobLevelLabel(level, isArabic: ar))),
              if (widget.canEdit && !loading && !editing && error == null)
                TextButton.icon(
                  onPressed: () => setState(() {
                    editing = true;
                    draft = level;
                  }),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(tr('تعديل المستوى', 'Edit level')),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tr(
              'المستوى يوضح الخبرة ولا يغيّر صلاحيات الحساب أو يمنح صلاحيات مدير.',
              'This describes experience and does not change account permissions or grant manager access.',
            ),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF77709A),
              height: 1.6,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              tr(
                'تعذر تحميل أو حفظ المستوى الوظيفي. أعد المحاولة، وإذا استمرت المشكلة تواصل مع مسؤول النظام.',
                'Could not load or save the job level. Retry, or contact your administrator if the problem continues.',
              ),
              style: const TextStyle(color: Colors.red),
            ),
            if (!editing)
              TextButton(
                onPressed: load,
                child: Text(tr('إعادة المحاولة', 'Retry')),
              ),
          ],
          if (editing) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: draft ?? 'none',
              decoration: InputDecoration(
                labelText: tr('اختر المستوى', 'Select level'),
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final value in ['none', 'junior', 'mid', 'senior'])
                  DropdownMenuItem(
                    value: value,
                    child: Text(jobLevelLabel(value, isArabic: ar)),
                  ),
              ],
              onChanged: saving
                  ? null
                  : (value) => setState(() {
                      draft = value == 'none' ? null : value;
                    }),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                FilledButton(
                  onPressed: saving ? null : save,
                  child: Text(
                    tr(
                      saving ? 'جارٍ الحفظ...' : 'حفظ المستوى',
                      saving ? 'Saving...' : 'Save level',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: saving
                      ? null
                      : () => setState(() {
                          editing = false;
                          error = null;
                        }),
                  child: Text(tr('إلغاء', 'Cancel')),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
