// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نظام ديما ERP';

  @override
  String get myProfile => 'ملفي الشخصي';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get language => 'اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'الإنجليزية';

  @override
  String get downloadReport => 'تنزيل التقرير';

  @override
  String get downloadPdf => 'تنزيل PDF';

  @override
  String get downloadHtml => 'تنزيل HTML';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get refresh => 'تحديث';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String saveFailed(Object error) {
    return 'فشل الحفظ: $error';
  }

  @override
  String get hrAlertsTitle => 'تنبيهات انتهاء الموارد البشرية';

  @override
  String get hrAlertsLoadFailed => 'فشل تحميل تنبيهات الموارد البشرية';

  @override
  String get hrAlertsSettings => 'إعدادات التنبيه';

  @override
  String get hrAlertsSettingsTitle => 'إعدادات التنبيه (بالأيام)';

  @override
  String get hrAlertsContractDays => 'أيام تنبيه العقد';

  @override
  String get hrAlertsResidencyDays => 'أيام تنبيه الإقامة';

  @override
  String get hrAlertsInsuranceDays => 'أيام تنبيه التأمين';

  @override
  String get hrAlertsDocumentsDays => 'أيام تنبيه المستندات';

  @override
  String get hrAlertsSettingsSaved => 'تم حفظ إعدادات التنبيه';

  @override
  String get hrAlertsNoRows => 'لا توجد تنبيهات انتهاء.';

  @override
  String get hrAlertsTotal => 'إجمالي التنبيهات';

  @override
  String get hrAlertsColEmployee => 'الموظف';

  @override
  String get hrAlertsColType => 'النوع';

  @override
  String get hrAlertsColExpiryDate => 'تاريخ الانتهاء';

  @override
  String get hrAlertsColDaysLeft => 'الأيام المتبقية';

  @override
  String get hrAlertsColStatus => 'الحالة';

  @override
  String get hrBandExpired => 'منتهي';

  @override
  String get hrBandUrgent => 'عاجل';

  @override
  String get hrBandWarning => 'تحذير';

  @override
  String get hrBandUpcoming => 'قريب';

  @override
  String get hrBandSafe => 'آمن';

  @override
  String get hrTypeContract => 'عقد';

  @override
  String get hrTypeResidency => 'إقامة';

  @override
  String get hrTypeInsurance => 'تأمين';

  @override
  String get hrTypeDocument => 'مستند';

  @override
  String get validationRange1To365 => 'أدخل رقمًا بين 1 و 365';

  @override
  String get menuDashboard => 'الرئيسية';

  @override
  String get menuDepartments => 'الأقسام';

  @override
  String get menuJobTitles => 'المسميات الوظيفية';

  @override
  String get menuEmployees => 'الموظفون';

  @override
  String get menuAttendance => 'الحضور';

  @override
  String get menuLeaves => 'الإجازات';

  @override
  String get menuPayroll => 'الرواتب';

  @override
  String get menuEmployeeDocs => 'مستندات الموظفين';

  @override
  String get menuHrAlerts => 'تنبيهات الموارد البشرية';

  @override
  String get menuApprovals => 'الموافقات';

  @override
  String get menuMyPortal => 'بوابتي';

  @override
  String get menuAccounts => 'الحسابات';

  @override
  String get menuJournal => 'القيود اليومية';

  @override
  String get menuSectionGeneral => 'عام';

  @override
  String get menuSectionHr => 'الموارد البشرية';

  @override
  String get menuSectionEmployee => 'الموظف';

  @override
  String get menuSectionAccounting => 'المحاسبة';

  @override
  String get menuSectionAccount => 'الحساب';

  @override
  String get sessionMissing => 'الجلسة غير متوفرة.';

  @override
  String get tooltipApprovals => 'الموافقات';

  @override
  String get tooltipSearch => 'بحث';

  @override
  String get searchInSystem => 'ابحث في النظام...';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get pageCreateEmployee => 'إضافة موظف';

  @override
  String get dimahErp => 'ديما ERP';

  @override
  String get expand => 'توسيع';

  @override
  String get collapse => 'طي';

  @override
  String get expandSidebar => 'توسيع القائمة الجانبية';

  @override
  String get collapseSidebar => 'طي القائمة الجانبية';

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String get roleAdmin => 'مدير النظام';

  @override
  String get roleHr => 'الموارد البشرية';

  @override
  String get roleManager => 'مدير مباشر';

  @override
  String get roleAccountant => 'محاسب';

  @override
  String get roleEmployee => 'موظف';

  @override
  String get clear => 'مسح';

  @override
  String get back => 'رجوع';

  @override
  String get employeeProfileNotLinked => 'ملف الموظف غير مرتبط.';

  @override
  String get myTasks => 'مهامي';

  @override
  String get myAttendance => 'حضوري';

  @override
  String get myLeaves => 'إجازاتي';

  @override
  String get myRequests => 'طلباتي';

  @override
  String failedToLoadTasks(Object error) {
    return 'فشل تحميل المهام: $error';
  }

  @override
  String get noTasksAssigned => 'لا توجد مهام مسندة بعد.';

  @override
  String get status => 'الحالة';

  @override
  String get statusTodo => 'للعمل';

  @override
  String get statusInProgress => 'قيد التنفيذ';

  @override
  String get statusDone => 'مكتمل';

  @override
  String progressLabel(int progress) {
    return 'التقدم: $progress%';
  }

  @override
  String get finish => 'إنهاء';

  @override
  String get next => 'التالي';

  @override
  String get stepPersonalInfo => 'البيانات الشخصية';

  @override
  String get stepJobInfo => 'بيانات الوظيفة';

  @override
  String get stepCompensation => 'الراتب';

  @override
  String get department => 'القسم';

  @override
  String get departmentRequired => 'القسم مطلوب';

  @override
  String get directManagerOptional => 'المدير المباشر (اختياري)';

  @override
  String get noDirectManager => 'لا يوجد مدير مباشر';

  @override
  String get jobTitleRequired => 'المسمى الوظيفي مطلوب';

  @override
  String get selectDepartmentFirst => 'اختر القسم أولًا.';

  @override
  String get noJobTitlesForDepartment => 'لا توجد مسميات لهذا القسم';

  @override
  String get hireDate => 'تاريخ التعيين';

  @override
  String get hireDateRequired => 'تاريخ التعيين مطلوب';

  @override
  String get contractType => 'نوع العقد';

  @override
  String get contractFullTime => 'دوام كامل';

  @override
  String get contractPartTime => 'دوام جزئي';

  @override
  String get contractContractor => 'متعاقد';

  @override
  String get contractIntern => 'متدرب';

  @override
  String get contractStart => 'بداية العقد';

  @override
  String get contractEnd => 'نهاية العقد';

  @override
  String get probationMonths => 'أشهر التجربة';

  @override
  String get selectDate => 'اختر التاريخ';

  @override
  String get basicSalaryRequired => 'الراتب الأساسي *';

  @override
  String get basicSalaryValidationRequired => 'الراتب الأساسي مطلوب';

  @override
  String get housingAllowance => 'بدل السكن';

  @override
  String get transportAllowance => 'بدل النقل';

  @override
  String get otherAllowance => 'بدلات أخرى';

  @override
  String get bankName => 'اسم البنك';

  @override
  String get iban => 'رقم الآيبان';

  @override
  String get accountNumber => 'رقم الحساب';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get paymentMethodBank => 'بنك';

  @override
  String get paymentMethodCash => 'كاش';

  @override
  String get total => 'الإجمالي';

  @override
  String amountSar(Object amount) {
    return '$amount ريال';
  }

  @override
  String get searchEmployeesHint => 'ابحث بالاسم أو البريد أو الجوال...';

  @override
  String get all => 'الكل';

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'غير نشط';

  @override
  String get nameAsc => 'الاسم ↑';

  @override
  String get nameDesc => 'الاسم ↓';

  @override
  String get sortName => 'ترتيب الاسم';

  @override
  String get createdAsc => 'الأحدث ↑';

  @override
  String get createdDesc => 'الأقدم ↓';

  @override
  String get sortCreated => 'ترتيب الإنشاء';

  @override
  String get addEmployee => 'إضافة موظف';

  @override
  String get name => 'الاسم';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get phone => 'الجوال';

  @override
  String get created => 'تاريخ الإنشاء';

  @override
  String get actions => 'الإجراءات';

  @override
  String get openProfile => 'فتح الملف';

  @override
  String get noEmployeesFound => 'لم يتم العثور على موظفين.';

  @override
  String totalWithValue(int total) {
    return 'الإجمالي: $total';
  }

  @override
  String pageWithValue(int page, int totalPages) {
    return 'الصفحة: $page / $totalPages';
  }

  @override
  String get previous => 'السابق';

  @override
  String get personalInformation => 'المعلومات الشخصية';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get fullNameRequired => 'الاسم الكامل مطلوب';

  @override
  String get fullNameTooShort => 'الاسم الكامل قصير جدًا';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get enterValidEmail => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get phoneRequired => 'رقم الجوال مطلوب';

  @override
  String get phoneTooShort => 'رقم الجوال قصير جدًا';

  @override
  String get nationalId => 'رقم الهوية';

  @override
  String get nationalIdRequired => 'رقم الهوية مطلوب';

  @override
  String get nationalIdTooShort => 'رقم الهوية قصير جدًا';

  @override
  String get nationality => 'الجنسية';

  @override
  String get maritalStatus => 'الحالة الاجتماعية';

  @override
  String get single => 'أعزب';

  @override
  String get married => 'متزوج';

  @override
  String get divorced => 'مطلق';

  @override
  String get widowed => 'أرمل';

  @override
  String get address => 'العنوان';

  @override
  String get city => 'المدينة';

  @override
  String get country => 'الدولة';

  @override
  String get passportNumber => 'رقم جواز السفر';

  @override
  String get educationLevel => 'المؤهل العلمي';

  @override
  String get highSchool => 'ثانوية';

  @override
  String get diploma => 'دبلوم';

  @override
  String get bachelor => 'بكالوريوس';

  @override
  String get master => 'ماجستير';

  @override
  String get phd => 'دكتوراه';

  @override
  String get major => 'التخصص';

  @override
  String get university => 'الجامعة';

  @override
  String get gender => 'الجنس';

  @override
  String get male => 'ذكر';

  @override
  String get female => 'أنثى';

  @override
  String get genderRequired => 'الجنس مطلوب';

  @override
  String get picking => 'جاري الاختيار...';

  @override
  String get selectEmployeePhoto => 'اختيار صورة الموظف';

  @override
  String get photoTooLargeMax5Mb => 'الصورة كبيرة جدًا. الحد الأقصى 5 ميجا.';

  @override
  String get unableAccessSelectedFilePath =>
      'تعذر الوصول إلى مسار الملف المحدد على هذه المنصة.';

  @override
  String get photoSelectedUploadAfterCreate =>
      'تم اختيار الصورة. يمكنك رفعها بعد إنشاء الموظف من تعديل الملف.';

  @override
  String photoUploadFailed(Object error) {
    return 'فشل رفع الصورة: $error';
  }

  @override
  String get dateOfBirth => 'تاريخ الميلاد';

  @override
  String get passportExpiry => 'تاريخ انتهاء جواز السفر';

  @override
  String get searchEmployeeHint => 'ابحث عن موظف...';

  @override
  String get attendancePresent => 'حضور';

  @override
  String get attendanceLate => 'تأخير';

  @override
  String get attendanceAbsent => 'غياب';

  @override
  String get attendanceOnLeave => 'إجازة';

  @override
  String get filterDate => 'تصفية بالتاريخ';

  @override
  String get dateAsc => 'التاريخ (تصاعدي)';

  @override
  String get dateDesc => 'التاريخ (تنازلي)';

  @override
  String get sortDate => 'ترتيب التاريخ';

  @override
  String get importCsv => 'استيراد CSV';

  @override
  String get addAttendance => 'إضافة حضور';

  @override
  String get noAttendanceRecordsFound => 'لا توجد سجلات حضور.';

  @override
  String get employee => 'الموظف';

  @override
  String get date => 'التاريخ';

  @override
  String get checkIn => 'الحضور';

  @override
  String get checkOut => 'الانصراف';

  @override
  String get overtime => 'ساعات إضافية';

  @override
  String get notes => 'ملاحظات';

  @override
  String get requestCorrection => 'طلب تصحيح';

  @override
  String entitlementWithValue(Object value) {
    return 'الاستحقاق: $value';
  }

  @override
  String usedWithValue(Object value) {
    return 'المستخدم: $value';
  }

  @override
  String remainingWithValue(Object value) {
    return 'المتبقي: $value';
  }

  @override
  String get statusPending => 'معلق';

  @override
  String get statusApproved => 'موافق عليه';

  @override
  String get statusRejected => 'مرفوض';

  @override
  String get allTypes => 'كل الأنواع';

  @override
  String get leaveTypeAnnual => 'سنوية';

  @override
  String get leaveTypeSick => 'مرضية';

  @override
  String get leaveTypeUnpaid => 'بدون راتب';

  @override
  String get leaveTypeOther => 'أخرى';

  @override
  String get startFrom => 'البداية من';

  @override
  String get endTo => 'النهاية إلى';

  @override
  String get startAsc => 'البداية (تصاعدي)';

  @override
  String get startDesc => 'البداية (تنازلي)';

  @override
  String get sortStart => 'ترتيب البداية';

  @override
  String get addLeave => 'إضافة إجازة';

  @override
  String get noLeaveRequestsFound => 'لا توجد طلبات إجازة.';

  @override
  String get type => 'النوع';

  @override
  String get start => 'البداية';

  @override
  String get end => 'النهاية';

  @override
  String get action => 'الإجراء';

  @override
  String get resubmit => 'إعادة إرسال';

  @override
  String get unknown => 'غير معروف';

  @override
  String get noApprovalsFound => 'لا توجد موافقات.';

  @override
  String get pendingWith => 'معلق لدى';

  @override
  String get details => 'التفاصيل';

  @override
  String get view => 'عرض';

  @override
  String get approve => 'موافقة';

  @override
  String get reject => 'رفض';

  @override
  String get processedApproved => 'تمت المعالجة (موافقة)';

  @override
  String get processedRejected => 'تمت المعالجة (رفض)';

  @override
  String get directManager => 'المدير المباشر';

  @override
  String get rejectRequest => 'رفض الطلب';

  @override
  String get reasonOptional => 'السبب (اختياري)';

  @override
  String get requestDetails => 'تفاصيل الطلب';

  @override
  String get reason => 'السبب';

  @override
  String get file => 'الملف';

  @override
  String get openAttachment => 'فتح المرفق';

  @override
  String get openDocument => 'فتح المستند';

  @override
  String get close => 'إغلاق';

  @override
  String get invalidAttachmentUrl => 'رابط المرفق غير صالح';

  @override
  String get unableOpenAttachment => 'تعذر فتح المرفق';

  @override
  String get leave => 'إجازة';

  @override
  String get assignedToMe => 'موجه لي';

  @override
  String get draft => 'مسودة';

  @override
  String get finalized => 'معتمد';

  @override
  String get posted => 'مرحل';

  @override
  String get newPayrollRun => 'تشغيل رواتب جديد';

  @override
  String get noPayrollRunsFound => 'لا توجد تشغيلات رواتب.';

  @override
  String get periodStart => 'بداية الفترة';

  @override
  String get periodEnd => 'نهاية الفترة';

  @override
  String get employeesCount => 'عدد الموظفين';

  @override
  String get totalAmount => 'إجمالي المبلغ';

  @override
  String get finalize => 'اعتماد';

  @override
  String get exportCsv => 'تصدير CSV';

  @override
  String get payrollRunItems => 'عناصر تشغيل الرواتب';

  @override
  String get payrollRunFinalized => 'تم اعتماد تشغيل الرواتب';

  @override
  String get basic => 'أساسي';

  @override
  String get housing => 'سكن';

  @override
  String get transport => 'نقل';

  @override
  String get other => 'أخرى';

  @override
  String get totalAllCaps => 'الإجمالي';

  @override
  String csvSavedTo(Object path) {
    return 'تم حفظ CSV في $path';
  }

  @override
  String exportFailed(Object error) {
    return 'فشل التصدير: $error';
  }

  @override
  String get noPayrollItemsFound => 'لا توجد عناصر رواتب.';

  @override
  String get create => 'إنشاء';

  @override
  String get add => 'إضافة';

  @override
  String get startEndDatesRequired => 'تاريخ البداية والنهاية مطلوبان';

  @override
  String get endDateAfterStart => 'يجب أن يكون تاريخ النهاية بعد البداية';

  @override
  String get pickStartDate => 'اختر تاريخ البداية';

  @override
  String get pickEndDate => 'اختر تاريخ النهاية';

  @override
  String get searchCodeOrName => 'ابحث بالكود أو الاسم...';

  @override
  String get accountTypeAsset => 'أصل';

  @override
  String get accountTypeLiability => 'التزام';

  @override
  String get accountTypeEquity => 'حقوق ملكية';

  @override
  String get accountTypeIncome => 'إيراد';

  @override
  String get accountTypeExpense => 'مصروف';

  @override
  String get codeAsc => 'الكود (تصاعدي)';

  @override
  String get codeDesc => 'الكود (تنازلي)';

  @override
  String get sortCode => 'ترتيب الكود';

  @override
  String get addAccount => 'إضافة حساب';

  @override
  String get noAccountsFound => 'لا توجد حسابات.';

  @override
  String get code => 'الكود';

  @override
  String get codeRequired => 'الكود مطلوب';

  @override
  String get nameRequired => 'الاسم مطلوب';

  @override
  String get newEntry => 'قيد جديد';

  @override
  String get noJournalEntriesFound => 'لا توجد قيود يومية.';

  @override
  String get memo => 'البيان';

  @override
  String get debit => 'مدين';

  @override
  String get credit => 'دائن';

  @override
  String get account => 'الحساب';

  @override
  String get debitOrCreditRequired => 'يجب إدخال مدين أو دائن';

  @override
  String get dateRequired => 'التاريخ مطلوب';

  @override
  String get addAtLeastOneLine => 'أضف سطرًا واحدًا على الأقل';

  @override
  String get debitsMustEqualCredits => 'يجب أن يتساوى المدين مع الدائن';

  @override
  String get newJournalEntry => 'قيد يومية جديد';

  @override
  String get pickDate => 'اختر التاريخ';

  @override
  String get employeeProfileTitle => 'ملف الموظف';

  @override
  String get failedToLoadEmployeeProfile => 'فشل تحميل ملف الموظف';

  @override
  String get editProfile => 'تعديل الملف';

  @override
  String get personal => 'شخصي';

  @override
  String get passportNo => 'رقم الجواز';

  @override
  String get residencyIssueDate => 'تاريخ إصدار الإقامة';

  @override
  String get residencyExpiryDate => 'تاريخ انتهاء الإقامة';

  @override
  String get insuranceStartDate => 'تاريخ بداية التأمين';

  @override
  String get insuranceExpiryDate => 'تاريخ انتهاء التأمين';

  @override
  String get insuranceProvider => 'مقدم التأمين';

  @override
  String get insurancePolicyNo => 'رقم وثيقة التأمين';

  @override
  String get basicInfo => 'أساسي';

  @override
  String get basicSalary => 'الراتب الأساسي';

  @override
  String get totalCompensation => 'إجمالي الراتب';

  @override
  String get compensationHistory => 'سجل الرواتب';

  @override
  String get noCompensationHistory => 'لا يوجد سجل رواتب';

  @override
  String get financial => 'مالي';

  @override
  String get contract => 'العقد';

  @override
  String get addCompensationVersion => 'إضافة نسخة راتب';

  @override
  String get addContractVersion => 'إضافة نسخة عقد';

  @override
  String get startDate => 'تاريخ البداية';

  @override
  String get endDate => 'تاريخ النهاية';

  @override
  String get probationMonthsLabel => 'فترة التجربة (بالأشهر)';

  @override
  String get openContractFile => 'فتح ملف العقد';

  @override
  String get contractHistory => 'سجل العقود';

  @override
  String get noContractHistory => 'لا يوجد سجل عقود';

  @override
  String get open => 'فتح';

  @override
  String get preview => 'معاينة';

  @override
  String get documents => 'وثائق';

  @override
  String get noDocumentsUploaded => 'لا توجد مستندات مرفوعة';

  @override
  String get invalidUrl => 'رابط غير صالح';

  @override
  String get unableOpenFile => 'تعذر فتح الملف';

  @override
  String htmlSavedTo(Object path) {
    return 'تم حفظ HTML في $path';
  }

  @override
  String get editEmployeeProfile => 'تعديل ملف الموظف';

  @override
  String get pickingPhoto => 'جاري اختيار الصورة...';

  @override
  String get selectPhoto => 'اختيار صورة';

  @override
  String get uploadingPhoto => 'جاري رفع الصورة...';

  @override
  String get residencyIssue => 'إصدار الإقامة';

  @override
  String get residencyExpiry => 'انتهاء الإقامة';

  @override
  String get insuranceStart => 'بداية التأمين';

  @override
  String get insuranceExpiry => 'انتهاء التأمين';

  @override
  String get contractFileUrl => 'رابط ملف العقد';

  @override
  String get saving => 'جاري الحفظ...';

  @override
  String get photoUploadedSuccessfully => 'تم رفع الصورة بنجاح';

  @override
  String get contractTypeRequired => 'نوع العقد مطلوب';

  @override
  String get contractFileUrlOptional => 'رابط ملف العقد (اختياري)';

  @override
  String get startDateRequired => 'تاريخ البداية مطلوب';

  @override
  String get effectiveDate => 'تاريخ السريان';

  @override
  String get noteOptional => 'ملاحظة (اختياري)';

  @override
  String fieldRequired(Object field) {
    return '$field مطلوب';
  }

  @override
  String get invalidNumber => 'رقم غير صالح';

  @override
  String pdfSavedTo(Object path) {
    return 'تم حفظ PDF في $path';
  }

  @override
  String get employeeFullReport => 'تقرير الموظف الكامل';

  @override
  String reportGenerated(Object value) {
    return 'تاريخ الإنشاء: $value';
  }

  @override
  String get employeeId => 'رقم الموظف';

  @override
  String get issued => 'الإصدار';

  @override
  String get expires => 'الانتهاء';

  @override
  String get urlLabel => 'الرابط';

  @override
  String get failedToLoadHrDashboard => 'فشل تحميل لوحة الموارد البشرية';

  @override
  String get hrDashboard => 'لوحة الموارد البشرية';

  @override
  String get activeEmployeesKpi => 'الموظفون النشطون';

  @override
  String get currentHeadcount => 'عدد الموظفين الحالي';

  @override
  String get pendingApprovalsKpi => 'الموافقات المعلقة';

  @override
  String get expiryAlertsKpi => 'تنبيهات الانتهاء';

  @override
  String get expiredDocumentsKpi => 'المستندات المنتهية';

  @override
  String get urgentAlertsKpi => 'التنبيهات العاجلة';

  @override
  String get waitingHrAction => 'بانتظار إجراء الموارد البشرية';

  @override
  String get documentExpiryNeedsAction =>
      'مستندات تحتاج إجراء من الموارد البشرية';

  @override
  String get onLeaveTodayKpi => 'إجازات اليوم';

  @override
  String get approvedLeaveToday => 'إجازات موافق عليها اليوم';

  @override
  String get noCheckInTodayKpi => 'بدون تسجيل حضور اليوم';

  @override
  String get activeStaffNotCheckedIn => 'موظفون نشطون لم يسجلوا حضورًا';

  @override
  String get leavesThisMonthKpi => 'إجازات هذا الشهر';

  @override
  String get approvedLeaveRequests => 'طلبات إجازة موافق عليها';

  @override
  String get pendingRequestsTop10 => 'الطلبات المعلقة (أعلى 10)';

  @override
  String get noPendingRequests => 'لا توجد طلبات معلقة.';

  @override
  String get expiringDocuments30Days => 'مستندات تنتهي خلال 30 يومًا';

  @override
  String get noDocumentExpiries30Days =>
      'لا توجد مستندات منتهية خلال 30 يومًا القادمة.';

  @override
  String get documentLabel => 'مستند';

  @override
  String get productivity => 'الإنتاجية';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get hrWorkflowBoard => 'لوحة سير عمل الموارد البشرية';

  @override
  String get reviewPendingApprovals => 'مراجعة الموافقات المعلقة';

  @override
  String get resolveExpiryAlerts => 'معالجة تنبيهات الانتهاء';

  @override
  String get completeEmployeeDocuments => 'استكمال مستندات الموظفين';

  @override
  String get documentCompliance => 'التوافق في المستندات';

  @override
  String get expiringDocumentsByType => 'المستندات المنتهية حسب النوع';

  @override
  String get expiringWithin30Days => 'تنتهي خلال 30 يومًا';

  @override
  String get todayAttendanceInsights => 'ملخص حضور اليوم';

  @override
  String get attendanceAlertsToday => 'تنبيهات الحضور اليوم';

  @override
  String get noAttendanceInsightsToday => 'لا توجد مؤشرات حضور لليوم.';

  @override
  String get noAttendanceAlertsToday => 'لا توجد تنبيهات حضور لليوم.';

  @override
  String get checkedInTodayLabel => 'سجلوا حضور اليوم';

  @override
  String get absentTodayLabel => 'غائبون اليوم';

  @override
  String pendingWithValue(int value) {
    return 'معلق: $value';
  }

  @override
  String doneWithValue(int value) {
    return 'مكتمل: $value';
  }

  @override
  String get recentTasks => 'المهام الأخيرة';

  @override
  String get noTasksAssignedYet => 'لا توجد مهام مسندة بعد.';

  @override
  String get teamProductivity => 'إنتاجية الفريق';

  @override
  String tasksWithValue(int value) {
    return 'المهام: $value';
  }

  @override
  String get assignTask => 'إسناد مهمة';

  @override
  String get taskTitle => 'عنوان المهمة';

  @override
  String get dueDateLabel => 'تاريخ الاستحقاق';

  @override
  String get dueDateOptional => 'تاريخ الاستحقاق (اختياري)';

  @override
  String get assigning => 'جارٍ الإسناد...';

  @override
  String get taskAssigned => 'تم إسناد المهمة';

  @override
  String assignFailed(Object error) {
    return 'فشل الإسناد: $error';
  }

  @override
  String get searchNameOrCodeHint => 'ابحث بالاسم أو الكود...';

  @override
  String get addDepartment => 'إضافة قسم';

  @override
  String get noManagerChangesNeeded => 'لا توجد تغييرات مطلوبة على المديرين.';

  @override
  String assignedUpdatedManagers(int count) {
    return 'تم تعيين/تحديث المديرين لعدد $count قسم.';
  }

  @override
  String autoAssignFailed(Object error) {
    return 'فشل التعيين التلقائي: $error';
  }

  @override
  String get autoAssignManagers => 'تعيين المديرين تلقائيًا';

  @override
  String get manager => 'المدير';

  @override
  String get edit => 'تعديل';

  @override
  String get download => 'تنزيل';

  @override
  String get delete => 'حذف';

  @override
  String get disable => 'تعطيل';

  @override
  String get enable => 'تفعيل';

  @override
  String get noDepartmentsFound => 'لا توجد أقسام.';

  @override
  String get noJobTitlesFound => 'لا توجد مسميات وظيفية.';

  @override
  String get editJobTitle => 'تعديل المسمى الوظيفي';

  @override
  String get requiredField => 'مطلوب';

  @override
  String get codeOptional => 'الكود (اختياري)';

  @override
  String get levelOptional => 'المستوى (اختياري)';

  @override
  String get descriptionOptional => 'الوصف (اختياري)';

  @override
  String get addJobTitle => 'إضافة مسمى وظيفي';

  @override
  String get sortLevel => 'ترتيب المستوى';

  @override
  String get levelAsc => 'المستوى ↑';

  @override
  String get levelDesc => 'المستوى ↓';

  @override
  String get id => 'الهوية';

  @override
  String get passport => 'جواز السفر';

  @override
  String get addDocument => 'إضافة مستند';

  @override
  String get noDocumentsFound => 'لا توجد مستندات.';

  @override
  String get invalidFileUrl => 'رابط ملف غير صالح';

  @override
  String get editDepartment => 'تعديل القسم';

  @override
  String get unableToLoadManagers => 'تعذر تحميل المديرين';

  @override
  String get departmentManager => 'مدير القسم';

  @override
  String get noManager => 'بدون مدير';

  @override
  String get employeeRequired => 'الموظف مطلوب';

  @override
  String get documentType => 'نوع المستند';

  @override
  String get documentTypeRequired => 'نوع المستند مطلوب';

  @override
  String get fileUrl => 'رابط الملف';

  @override
  String get fileUrlRequired => 'رابط الملف مطلوب';

  @override
  String get fileRequired => 'الملف مطلوب';

  @override
  String get uploading => 'جارٍ الرفع...';

  @override
  String get uploadPdf => 'رفع PDF';

  @override
  String get uploadingDocument => 'جارٍ رفع المستند...';

  @override
  String get savingDocument => 'جارٍ حفظ المستند...';

  @override
  String get issuedDate => 'تاريخ الإصدار';

  @override
  String get expiresDate => 'تاريخ الانتهاء';

  @override
  String get fileUploadedSuccessfully => 'تم رفع الملف بنجاح';

  @override
  String fileUploadFailed(Object error) {
    return 'فشل رفع الملف: $error';
  }

  @override
  String get employeeDocsStorageUnauthorized =>
      'مستودع مستندات الموظفين غير مهيأ بعد. شغّل SQL الخاص بـ employee_docs أولًا.';

  @override
  String get editDocument => 'تعديل المستند';

  @override
  String get deleteDocument => 'حذف المستند';

  @override
  String get deleteDocumentConfirm => 'هل أنت متأكد من حذف هذا المستند؟';

  @override
  String get documentUpdated => 'تم تحديث المستند بنجاح';

  @override
  String get documentDeleted => 'تم حذف المستند بنجاح';

  @override
  String fileSavedTo(Object path) {
    return 'تم حفظ الملف في: $path';
  }

  @override
  String fileDownloadFailed(Object error) {
    return 'فشل تنزيل الملف: $error';
  }

  @override
  String get notAuthenticated => 'غير مسجل الدخول';

  @override
  String get level => 'المستوى';

  @override
  String get checkInCoverage => 'نسبة تسجيل الحضور';

  @override
  String get approvalLoad => 'عبء الموافقات';

  @override
  String get teamMembers => 'أعضاء الفريق';

  @override
  String get openTasks => 'المهام المفتوحة';

  @override
  String get overdueTasks => 'المهام المتأخرة';

  @override
  String get completionRate => 'نسبة الإنجاز';

  @override
  String get dueSoonTasks => 'المهام المستحقة قريبًا (7 أيام)';

  @override
  String get noDueSoonTasks => 'لا توجد مهام مستحقة خلال 7 أيام قادمة.';

  @override
  String get topPerformers => 'أفضل 5 أداء';

  @override
  String get needsAttention => 'بحاجة إلى متابعة';

  @override
  String get noTeamDataYet => 'لا توجد بيانات فريق بعد.';

  @override
  String get taskTimeline => 'سجل المهام';

  @override
  String get assignedToEmployeeAt => 'وقت إرسال المهمة للموظف';

  @override
  String get employeeReceivedAt => 'وقت استلام الموظف للمهمة';

  @override
  String get employeeStartedAt => 'وقت بدء الموظف في تنفيذ المهمة';

  @override
  String get completedAtLabel => 'وقت الإكمال';

  @override
  String get lastUpdateAt => 'آخر تحديث';

  @override
  String get updatesTimeline => 'سجل التحديثات';

  @override
  String get taskEventAssigned => 'تم الإسناد';

  @override
  String get taskEventStatusChanged => 'تم تغيير الحالة';

  @override
  String get taskEventProgressUpdated => 'تم تحديث نسبة الإنجاز';

  @override
  String get estimateHours => 'الساعات التقديرية';

  @override
  String get priority => 'الأولوية';

  @override
  String get priorityLow => 'منخفضة';

  @override
  String get priorityMedium => 'متوسطة';

  @override
  String get priorityHigh => 'مرتفعة';

  @override
  String get taskWeight => 'وزن المهمة';

  @override
  String get invalidEstimateHours =>
      'من فضلك أدخل قيمة صحيحة للساعات التقديرية.';

  @override
  String get taskType => 'نوع المهمة';

  @override
  String get taskCatalog => 'قائمة مهام القسم';

  @override
  String taskCatalogForDepartment(Object department) {
    return 'قائمة مهام قسم $department';
  }

  @override
  String get taskTypeGeneral => 'عام';

  @override
  String get taskTypeDevelopment => 'تطوير';

  @override
  String get taskTypeBugFix => 'إصلاح أعطال';

  @override
  String get taskTypeTesting => 'اختبارات';

  @override
  String get taskTypeSupport => 'دعم فني';

  @override
  String get taskTypeTransfer => 'تحويل';

  @override
  String get taskTypeReport => 'تقرير';

  @override
  String get taskTypeTax => 'ضريبة';

  @override
  String get taskTypePayroll => 'رواتب';

  @override
  String get taskTypeReconciliation => 'تسوية';

  @override
  String get taskTypeRecruitment => 'توظيف';

  @override
  String get taskTypeOnboarding => 'تهيئة موظف';

  @override
  String get taskTypeEmployeeDocs => 'مستندات موظف';

  @override
  String get allStatuses => 'كل الحالات';

  @override
  String get uploadNewDocument => 'رفع وثيقة جديدة';

  @override
  String get idCard => 'بطاقة الهوية';

  @override
  String get graduationCert => 'شهادة التخرج';

  @override
  String get nationalAddress => 'العنوان الوطني';

  @override
  String get bankIbanCertificate => 'شهادة الآيبان البنكي';

  @override
  String get salaryCertificate => 'شهادة الأجور';

  @override
  String get identityDocuments => 'وثائق الهوية';

  @override
  String get educationAndCareerDocuments => 'الوثائق التعليمية والمهنية';

  @override
  String get financialDocuments => 'الوثائق المالية';

  @override
  String get medicalAndInsuranceDocuments => 'الوثائق الطبية والتأمينية';

  @override
  String get otherDocuments => 'وثائق أخرى';

  @override
  String get residencyDocument => 'الإقامة';

  @override
  String get drivingLicense => 'رخصة القيادة';

  @override
  String get offerLetter => 'عرض العمل';

  @override
  String get salaryDefinition => 'تعريف بالراتب';

  @override
  String get medicalInsurance => 'التأمين الطبي';

  @override
  String get medicalReport => 'تقرير طبي';

  @override
  String get expired => 'منتهي';

  @override
  String get expiringSoon => 'ينتهي قريبًا';

  @override
  String get valid => 'ساري';

  @override
  String get noExpiry => 'بدون انتهاء';

  @override
  String get documentFile => 'مستند';

  @override
  String get uploadFile => 'رفع ملف';

  @override
  String get noFileSelected => 'لم يتم اختيار ملف';
}
