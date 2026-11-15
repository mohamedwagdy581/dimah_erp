enum HrPrototypeFieldType { text, notes, date, time, number, check }

class HrPrototypeField {
  const HrPrototypeField(
    this.id,
    this.ar,
    this.en, {
    this.type = HrPrototypeFieldType.text,
    this.required = true,
  });
  final String id, ar, en;
  final HrPrototypeFieldType type;
  final bool required;
  String label(bool arabic) => arabic ? ar : en;
}

class HrPrototypeDef {
  const HrPrototypeDef(
    this.id,
    this.code,
    this.ar,
    this.en,
    this.fields, {
    this.employeeRequired = true,
  });
  final String id, code, ar, en;
  final List<HrPrototypeField> fields;
  final bool employeeRequired;
  String title(bool arabic) => arabic ? ar : en;
}

const hrPrototypes = <HrPrototypeDef>[
  HrPrototypeDef(
    'early-exit',
    'HR-EXIT',
    'طلب إذن خروج مبكر',
    'Early Exit Permission',
    [
      HrPrototypeField(
        'date',
        'تاريخ الخروج',
        'Exit date',
        type: HrPrototypeFieldType.date,
      ),
      HrPrototypeField(
        'departure',
        'وقت الخروج المطلوب',
        'Requested departure',
        type: HrPrototypeFieldType.time,
      ),
      HrPrototypeField(
        'shiftEnd',
        'نهاية الدوام المعتادة',
        'Normal shift end',
        type: HrPrototypeFieldType.time,
      ),
      HrPrototypeField(
        'reason',
        'سبب الخروج المبكر',
        'Reason for early exit',
        type: HrPrototypeFieldType.notes,
      ),
    ],
  ),
  HrPrototypeDef(
    'hiring-request',
    'HR-HIR',
    'طلب توظيف موظف جديد',
    'Hiring request',
    [
      HrPrototypeField('position', 'الوظيفة المطلوبة', 'Requested position'),
      HrPrototypeField('department', 'القسم المطلوب', 'Requested department'),
      HrPrototypeField(
        'headcount',
        'عدد الوظائف',
        'Number of positions',
        type: HrPrototypeFieldType.number,
      ),
      HrPrototypeField(
        'reason',
        'مبررات التوظيف',
        'Hiring justification',
        type: HrPrototypeFieldType.notes,
      ),
      HrPrototypeField(
        'salary',
        'الراتب المقترح (ريال)',
        'Proposed salary (SAR)',
        type: HrPrototypeFieldType.number,
        required: false,
      ),
      HrPrototypeField(
        'start',
        'تاريخ البدء المقترح',
        'Proposed start date',
        type: HrPrototypeFieldType.date,
      ),
    ],
    employeeRequired: false,
  ),
  HrPrototypeDef(
    'onboarding',
    'HR-ONB',
    'قائمة تهيئة الموظف الجديد',
    'Onboarding checklist',
    [
      HrPrototypeField(
        'start',
        'تاريخ المباشرة',
        'Start date',
        type: HrPrototypeFieldType.date,
      ),
      HrPrototypeField('owner', 'المسؤول عن التهيئة', 'Onboarding coordinator'),
      HrPrototypeField(
        'documents',
        'استلام المستندات',
        'Documents received',
        type: HrPrototypeFieldType.check,
        required: false,
      ),
      HrPrototypeField(
        'equipment',
        'تسليم المعدات والعهد',
        'Equipment issued',
        type: HrPrototypeFieldType.check,
        required: false,
      ),
      HrPrototypeField(
        'accounts',
        'تجهيز حسابات الأنظمة',
        'System accounts prepared',
        type: HrPrototypeFieldType.check,
        required: false,
      ),
      HrPrototypeField(
        'orientation',
        'إتمام التعريف بالعمل',
        'Orientation completed',
        type: HrPrototypeFieldType.check,
        required: false,
      ),
      HrPrototypeField(
        'notes',
        'ملاحظات التهيئة',
        'Onboarding notes',
        type: HrPrototypeFieldType.notes,
        required: false,
      ),
    ],
  ),
  HrPrototypeDef(
    'probation-review',
    'HR-PRB',
    'تقييم فترة التجربة',
    'Probation review',
    [
      HrPrototypeField(
        'from',
        'بداية فترة التقييم',
        'Review period start',
        type: HrPrototypeFieldType.date,
      ),
      HrPrototypeField(
        'to',
        'نهاية فترة التقييم',
        'Review period end',
        type: HrPrototypeFieldType.date,
      ),
      HrPrototypeField(
        'performance',
        'تقييم الأداء',
        'Performance assessment',
        type: HrPrototypeFieldType.notes,
      ),
      HrPrototypeField(
        'attendance',
        'تقييم الالتزام والحضور',
        'Attendance and reliability assessment',
        type: HrPrototypeFieldType.notes,
      ),
      HrPrototypeField(
        'recommendation',
        'توصية المدير',
        'Manager recommendation',
        type: HrPrototypeFieldType.notes,
      ),
    ],
  ),
  HrPrototypeDef(
    'information-update',
    'HR-UPD',
    'طلب تحديث بيانات الموظف',
    'Employee information update',
    [
      HrPrototypeField(
        'field',
        'البيانات المطلوب تعديلها',
        'Information to update',
      ),
      HrPrototypeField(
        'old',
        'البيانات الحالية',
        'Current details',
        type: HrPrototypeFieldType.notes,
      ),
      HrPrototypeField(
        'new',
        'البيانات الجديدة',
        'New details',
        type: HrPrototypeFieldType.notes,
      ),
      HrPrototypeField(
        'reason',
        'سبب التعديل',
        'Reason for change',
        type: HrPrototypeFieldType.notes,
      ),
      HrPrototypeField(
        'effective',
        'تاريخ السريان',
        'Effective date',
        type: HrPrototypeFieldType.date,
      ),
    ],
  ),
  HrPrototypeDef(
    'transfer-promotion',
    'HR-TRF',
    'طلب نقل أو ترقية',
    'Transfer or promotion request',
    [
      HrPrototypeField(
        'kind',
        'نوع الطلب: نقل / ترقية',
        'Request type: transfer / promotion',
      ),
      HrPrototypeField('department', 'القسم المقترح', 'Proposed department'),
      HrPrototypeField(
        'position',
        'المسمى الوظيفي المقترح',
        'Proposed job title',
      ),
      HrPrototypeField(
        'level',
        'المستوى الوظيفي المقترح',
        'Proposed job level',
      ),
      HrPrototypeField(
        'effective',
        'تاريخ السريان',
        'Effective date',
        type: HrPrototypeFieldType.date,
      ),
      HrPrototypeField(
        'reason',
        'مبررات الطلب',
        'Justification',
        type: HrPrototypeFieldType.notes,
      ),
    ],
  ),
  HrPrototypeDef(
    'salary-adjustment',
    'HR-SAL',
    'طلب تعديل الراتب',
    'Salary adjustment request',
    [
      HrPrototypeField(
        'current',
        'الراتب الحالي (ريال)',
        'Current salary (SAR)',
        type: HrPrototypeFieldType.number,
      ),
      HrPrototypeField(
        'proposed',
        'الراتب المقترح (ريال)',
        'Proposed salary (SAR)',
        type: HrPrototypeFieldType.number,
      ),
      HrPrototypeField(
        'effective',
        'تاريخ السريان المقترح',
        'Proposed effective date',
        type: HrPrototypeFieldType.date,
      ),
      HrPrototypeField(
        'reason',
        'مبررات التعديل',
        'Adjustment justification',
        type: HrPrototypeFieldType.notes,
      ),
    ],
  ),
  HrPrototypeDef(
    'training-request',
    'HR-TRN',
    'طلب تدريب',
    'Training request',
    [
      HrPrototypeField('course', 'الدورة التدريبية', 'Training course'),
      HrPrototypeField('provider', 'الجهة المقدمة', 'Training provider'),
      HrPrototypeField(
        'from',
        'بداية التدريب',
        'Training start',
        type: HrPrototypeFieldType.date,
      ),
      HrPrototypeField(
        'to',
        'نهاية التدريب',
        'Training end',
        type: HrPrototypeFieldType.date,
      ),
      HrPrototypeField(
        'cost',
        'التكلفة المتوقعة (ريال)',
        'Estimated cost (SAR)',
        type: HrPrototypeFieldType.number,
      ),
      HrPrototypeField(
        'benefit',
        'الفائدة المتوقعة',
        'Expected benefit',
        type: HrPrototypeFieldType.notes,
      ),
    ],
  ),
  HrPrototypeDef(
    'business-trip',
    'HR-TRP',
    'طلب انتداب / مهمة عمل',
    'Business trip authorization',
    [
      HrPrototypeField('destination', 'الوجهة', 'Destination'),
      HrPrototypeField(
        'purpose',
        'غرض المهمة',
        'Trip purpose',
        type: HrPrototypeFieldType.notes,
      ),
      HrPrototypeField(
        'from',
        'تاريخ المغادرة',
        'Departure date',
        type: HrPrototypeFieldType.date,
      ),
      HrPrototypeField(
        'to',
        'تاريخ العودة',
        'Return date',
        type: HrPrototypeFieldType.date,
      ),
      HrPrototypeField(
        'cost',
        'المصروفات المتوقعة (ريال)',
        'Estimated expenses (SAR)',
        type: HrPrototypeFieldType.number,
      ),
      HrPrototypeField(
        'notes',
        'ملاحظات',
        'Notes',
        type: HrPrototypeFieldType.notes,
        required: false,
      ),
    ],
  ),
  HrPrototypeDef(
    'leave-change',
    'HR-LCH',
    'تعديل أو إلغاء إجازة',
    'Leave amendment or cancellation',
    [
      HrPrototypeField(
        'reference',
        'مرجع الطلب الأصلي',
        'Original request reference',
      ),
      HrPrototypeField(
        'kind',
        'نوع التغيير: تعديل / إلغاء',
        'Change type: amend / cancel',
      ),
      HrPrototypeField(
        'original',
        'تفاصيل الإجازة الأصلية',
        'Original leave details',
        type: HrPrototypeFieldType.notes,
      ),
      HrPrototypeField(
        'changes',
        'التعديلات المطلوبة',
        'Requested changes',
        type: HrPrototypeFieldType.notes,
      ),
      HrPrototypeField(
        'reason',
        'سبب التغيير',
        'Reason for change',
        type: HrPrototypeFieldType.notes,
      ),
    ],
  ),
  HrPrototypeDef(
    'overtime-authorization',
    'HR-OT',
    'طلب تكليف عمل إضافي',
    'Overtime authorization',
    [
      HrPrototypeField(
        'date',
        'تاريخ العمل الإضافي',
        'Overtime date',
        type: HrPrototypeFieldType.date,
      ),
      HrPrototypeField(
        'fromTime',
        'وقت البداية',
        'Start time',
        type: HrPrototypeFieldType.time,
      ),
      HrPrototypeField(
        'toTime',
        'وقت النهاية',
        'End time',
        type: HrPrototypeFieldType.time,
      ),
      HrPrototypeField(
        'hours',
        'عدد الساعات المطلوبة',
        'Requested hours',
        type: HrPrototypeFieldType.number,
      ),
      HrPrototypeField(
        'work',
        'الأعمال المكلف بها',
        'Assigned work',
        type: HrPrototypeFieldType.notes,
      ),
    ],
  ),
  HrPrototypeDef(
    'performance-appraisal',
    'HR-APP',
    'تقييم الأداء الوظيفي',
    'Performance appraisal',
    [
      HrPrototypeField(
        'from',
        'بداية فترة التقييم',
        'Assessment period start',
        type: HrPrototypeFieldType.date,
      ),
      HrPrototypeField(
        'to',
        'نهاية فترة التقييم',
        'Assessment period end',
        type: HrPrototypeFieldType.date,
      ),
      HrPrototypeField(
        'goals',
        'الأهداف والنتائج',
        'Goals and results',
        type: HrPrototypeFieldType.notes,
      ),
      HrPrototypeField(
        'achievements',
        'الإنجازات',
        'Achievements',
        type: HrPrototypeFieldType.notes,
      ),
      HrPrototypeField(
        'assessment',
        'التقييم العام وملاحظات المدير',
        'Overall assessment and manager feedback',
        type: HrPrototypeFieldType.notes,
      ),
      HrPrototypeField(
        'development',
        'خطة التطوير',
        'Development plan',
        type: HrPrototypeFieldType.notes,
      ),
    ],
  ),
  HrPrototypeDef(
    'resignation-exit',
    'HR-EXT',
    'طلب استقالة ومقابلة خروج',
    'Resignation and exit interview',
    [
      HrPrototypeField(
        'submitted',
        'تاريخ تقديم الطلب',
        'Submission date',
        type: HrPrototypeFieldType.date,
      ),
      HrPrototypeField(
        'lastDay',
        'آخر يوم عمل مقترح',
        'Proposed last working day',
        type: HrPrototypeFieldType.date,
      ),
      HrPrototypeField(
        'reason',
        'سبب الاستقالة',
        'Reason for resignation',
        type: HrPrototypeFieldType.notes,
      ),
      HrPrototypeField(
        'handover',
        'خطة تسليم الأعمال',
        'Work handover plan',
        type: HrPrototypeFieldType.notes,
      ),
      HrPrototypeField(
        'feedback',
        'ملاحظات مقابلة الخروج',
        'Exit interview feedback',
        type: HrPrototypeFieldType.notes,
        required: false,
      ),
    ],
  ),
];

HrPrototypeDef? findHrPrototype(String id) {
  for (final item in hrPrototypes) {
    if (item.id == id) return item;
  }
  return null;
}
