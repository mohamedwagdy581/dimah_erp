import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Dimah ERP SYS'**
  String get appTitle;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @downloadReport.
  ///
  /// In en, this message translates to:
  /// **'Download Report'**
  String get downloadReport;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @downloadHtml.
  ///
  /// In en, this message translates to:
  /// **'Download HTML'**
  String get downloadHtml;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(Object error);

  /// No description provided for @hrAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'HR Expiry Alerts'**
  String get hrAlertsTitle;

  /// No description provided for @hrAlertsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load HR alerts'**
  String get hrAlertsLoadFailed;

  /// No description provided for @hrAlertsSettings.
  ///
  /// In en, this message translates to:
  /// **'Alert Settings'**
  String get hrAlertsSettings;

  /// No description provided for @hrAlertsSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert Settings (Days)'**
  String get hrAlertsSettingsTitle;

  /// No description provided for @hrAlertsContractDays.
  ///
  /// In en, this message translates to:
  /// **'Contract alert days'**
  String get hrAlertsContractDays;

  /// No description provided for @hrAlertsResidencyDays.
  ///
  /// In en, this message translates to:
  /// **'Residency alert days'**
  String get hrAlertsResidencyDays;

  /// No description provided for @hrAlertsInsuranceDays.
  ///
  /// In en, this message translates to:
  /// **'Insurance alert days'**
  String get hrAlertsInsuranceDays;

  /// No description provided for @hrAlertsDocumentsDays.
  ///
  /// In en, this message translates to:
  /// **'Document alert days'**
  String get hrAlertsDocumentsDays;

  /// No description provided for @hrAlertsSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Alert settings saved'**
  String get hrAlertsSettingsSaved;

  /// No description provided for @hrAlertsNoRows.
  ///
  /// In en, this message translates to:
  /// **'No expiry alerts found.'**
  String get hrAlertsNoRows;

  /// No description provided for @hrAlertsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Alerts'**
  String get hrAlertsTotal;

  /// No description provided for @hrAlertsColEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get hrAlertsColEmployee;

  /// No description provided for @hrAlertsColType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get hrAlertsColType;

  /// No description provided for @hrAlertsColExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get hrAlertsColExpiryDate;

  /// No description provided for @hrAlertsColDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'Days Left'**
  String get hrAlertsColDaysLeft;

  /// No description provided for @hrAlertsColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get hrAlertsColStatus;

  /// No description provided for @hrBandExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get hrBandExpired;

  /// No description provided for @hrBandUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get hrBandUrgent;

  /// No description provided for @hrBandWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get hrBandWarning;

  /// No description provided for @hrBandUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get hrBandUpcoming;

  /// No description provided for @hrBandSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get hrBandSafe;

  /// No description provided for @hrTypeContract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get hrTypeContract;

  /// No description provided for @hrTypeResidency.
  ///
  /// In en, this message translates to:
  /// **'Residency'**
  String get hrTypeResidency;

  /// No description provided for @hrTypeInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get hrTypeInsurance;

  /// No description provided for @hrTypeDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get hrTypeDocument;

  /// No description provided for @validationRange1To365.
  ///
  /// In en, this message translates to:
  /// **'Enter a number between 1 and 365'**
  String get validationRange1To365;

  /// No description provided for @menuDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get menuDashboard;

  /// No description provided for @menuDepartments.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get menuDepartments;

  /// No description provided for @menuJobTitles.
  ///
  /// In en, this message translates to:
  /// **'Job Titles'**
  String get menuJobTitles;

  /// No description provided for @menuEmployees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get menuEmployees;

  /// No description provided for @menuAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get menuAttendance;

  /// No description provided for @menuLeaves.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get menuLeaves;

  /// No description provided for @menuPayroll.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get menuPayroll;

  /// No description provided for @menuEmployeeDocs.
  ///
  /// In en, this message translates to:
  /// **'Employee Documents'**
  String get menuEmployeeDocs;

  /// No description provided for @menuHrAlerts.
  ///
  /// In en, this message translates to:
  /// **'HR Alerts'**
  String get menuHrAlerts;

  /// No description provided for @menuApprovals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get menuApprovals;

  /// No description provided for @menuMyPortal.
  ///
  /// In en, this message translates to:
  /// **'My Portal'**
  String get menuMyPortal;

  /// No description provided for @menuAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get menuAccounts;

  /// No description provided for @menuJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get menuJournal;

  /// No description provided for @menuSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get menuSectionGeneral;

  /// No description provided for @menuSectionHr.
  ///
  /// In en, this message translates to:
  /// **'Human Resources'**
  String get menuSectionHr;

  /// No description provided for @menuSectionEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get menuSectionEmployee;

  /// No description provided for @menuSectionAccounting.
  ///
  /// In en, this message translates to:
  /// **'Accounting'**
  String get menuSectionAccounting;

  /// No description provided for @menuSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get menuSectionAccount;

  /// No description provided for @sessionMissing.
  ///
  /// In en, this message translates to:
  /// **'Session missing.'**
  String get sessionMissing;

  /// No description provided for @tooltipApprovals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get tooltipApprovals;

  /// No description provided for @tooltipSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tooltipSearch;

  /// No description provided for @searchInSystem.
  ///
  /// In en, this message translates to:
  /// **'Search in system...'**
  String get searchInSystem;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @pageCreateEmployee.
  ///
  /// In en, this message translates to:
  /// **'Create Employee'**
  String get pageCreateEmployee;

  /// No description provided for @dimahErp.
  ///
  /// In en, this message translates to:
  /// **'Dimah ERP'**
  String get dimahErp;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @expandSidebar.
  ///
  /// In en, this message translates to:
  /// **'Expand Sidebar'**
  String get expandSidebar;

  /// No description provided for @collapseSidebar.
  ///
  /// In en, this message translates to:
  /// **'Collapse Sidebar'**
  String get collapseSidebar;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleHr.
  ///
  /// In en, this message translates to:
  /// **'HR'**
  String get roleHr;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleAccountant.
  ///
  /// In en, this message translates to:
  /// **'Accountant'**
  String get roleAccountant;

  /// No description provided for @roleEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get roleEmployee;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @employeeProfileNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Employee profile is not linked.'**
  String get employeeProfileNotLinked;

  /// No description provided for @myTasks.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get myTasks;

  /// No description provided for @myAttendance.
  ///
  /// In en, this message translates to:
  /// **'My Attendance'**
  String get myAttendance;

  /// No description provided for @myLeaves.
  ///
  /// In en, this message translates to:
  /// **'My Leaves'**
  String get myLeaves;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @failedToLoadTasks.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tasks: {error}'**
  String failedToLoadTasks(Object error);

  /// No description provided for @noTasksAssigned.
  ///
  /// In en, this message translates to:
  /// **'No tasks assigned yet.'**
  String get noTasksAssigned;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @statusTodo.
  ///
  /// In en, this message translates to:
  /// **'To Do'**
  String get statusTodo;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @progressLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress: {progress}%'**
  String progressLabel(int progress);

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @stepPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get stepPersonalInfo;

  /// No description provided for @stepJobInfo.
  ///
  /// In en, this message translates to:
  /// **'Job Info'**
  String get stepJobInfo;

  /// No description provided for @stepCompensation.
  ///
  /// In en, this message translates to:
  /// **'Compensation'**
  String get stepCompensation;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @departmentRequired.
  ///
  /// In en, this message translates to:
  /// **'Department is required'**
  String get departmentRequired;

  /// No description provided for @directManagerOptional.
  ///
  /// In en, this message translates to:
  /// **'Direct Manager (optional)'**
  String get directManagerOptional;

  /// No description provided for @noDirectManager.
  ///
  /// In en, this message translates to:
  /// **'No direct manager'**
  String get noDirectManager;

  /// No description provided for @jobTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Job title is required'**
  String get jobTitleRequired;

  /// No description provided for @selectDepartmentFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a department first.'**
  String get selectDepartmentFirst;

  /// No description provided for @noJobTitlesForDepartment.
  ///
  /// In en, this message translates to:
  /// **'No job titles for this department'**
  String get noJobTitlesForDepartment;

  /// No description provided for @hireDate.
  ///
  /// In en, this message translates to:
  /// **'Hire Date'**
  String get hireDate;

  /// No description provided for @hireDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Hire date is required'**
  String get hireDateRequired;

  /// No description provided for @contractType.
  ///
  /// In en, this message translates to:
  /// **'Contract Type'**
  String get contractType;

  /// No description provided for @contractFullTime.
  ///
  /// In en, this message translates to:
  /// **'Full Time'**
  String get contractFullTime;

  /// No description provided for @contractPartTime.
  ///
  /// In en, this message translates to:
  /// **'Part Time'**
  String get contractPartTime;

  /// No description provided for @contractContractor.
  ///
  /// In en, this message translates to:
  /// **'Contractor'**
  String get contractContractor;

  /// No description provided for @contractIntern.
  ///
  /// In en, this message translates to:
  /// **'Intern'**
  String get contractIntern;

  /// No description provided for @contractStart.
  ///
  /// In en, this message translates to:
  /// **'Contract Start'**
  String get contractStart;

  /// No description provided for @contractEnd.
  ///
  /// In en, this message translates to:
  /// **'Contract End'**
  String get contractEnd;

  /// No description provided for @probationMonths.
  ///
  /// In en, this message translates to:
  /// **'Probation Months'**
  String get probationMonths;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @basicSalaryRequired.
  ///
  /// In en, this message translates to:
  /// **'Basic Salary *'**
  String get basicSalaryRequired;

  /// No description provided for @basicSalaryValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Basic salary is required'**
  String get basicSalaryValidationRequired;

  /// No description provided for @housingAllowance.
  ///
  /// In en, this message translates to:
  /// **'Housing Allowance'**
  String get housingAllowance;

  /// No description provided for @transportAllowance.
  ///
  /// In en, this message translates to:
  /// **'Transport Allowance'**
  String get transportAllowance;

  /// No description provided for @otherAllowance.
  ///
  /// In en, this message translates to:
  /// **'Other Allowance'**
  String get otherAllowance;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankName;

  /// No description provided for @iban.
  ///
  /// In en, this message translates to:
  /// **'IBAN'**
  String get iban;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get accountNumber;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @paymentMethodBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get paymentMethodBank;

  /// No description provided for @paymentMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentMethodCash;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @amountSar.
  ///
  /// In en, this message translates to:
  /// **'{amount} SAR'**
  String amountSar(Object amount);

  /// No description provided for @searchEmployeesHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, email, or phone...'**
  String get searchEmployeesHint;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @nameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name ↑'**
  String get nameAsc;

  /// No description provided for @nameDesc.
  ///
  /// In en, this message translates to:
  /// **'Name ↓'**
  String get nameDesc;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Sort Name'**
  String get sortName;

  /// No description provided for @createdAsc.
  ///
  /// In en, this message translates to:
  /// **'Created ↑'**
  String get createdAsc;

  /// No description provided for @createdDesc.
  ///
  /// In en, this message translates to:
  /// **'Created ↓'**
  String get createdDesc;

  /// No description provided for @sortCreated.
  ///
  /// In en, this message translates to:
  /// **'Sort Created'**
  String get sortCreated;

  /// No description provided for @addEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add Employee'**
  String get addEmployee;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @openProfile.
  ///
  /// In en, this message translates to:
  /// **'Open Profile'**
  String get openProfile;

  /// No description provided for @noEmployeesFound.
  ///
  /// In en, this message translates to:
  /// **'No employees found.'**
  String get noEmployeesFound;

  /// No description provided for @totalWithValue.
  ///
  /// In en, this message translates to:
  /// **'Total: {total}'**
  String totalWithValue(int total);

  /// No description provided for @pageWithValue.
  ///
  /// In en, this message translates to:
  /// **'Page: {page} / {totalPages}'**
  String pageWithValue(int page, int totalPages);

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @fullNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Full name is too short'**
  String get fullNameTooShort;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone is required'**
  String get phoneRequired;

  /// No description provided for @phoneTooShort.
  ///
  /// In en, this message translates to:
  /// **'Phone number is too short'**
  String get phoneTooShort;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @nationalIdRequired.
  ///
  /// In en, this message translates to:
  /// **'National ID is required'**
  String get nationalIdRequired;

  /// No description provided for @nationalIdTooShort.
  ///
  /// In en, this message translates to:
  /// **'National ID is too short'**
  String get nationalIdTooShort;

  /// No description provided for @nationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get nationality;

  /// No description provided for @maritalStatus.
  ///
  /// In en, this message translates to:
  /// **'Marital Status'**
  String get maritalStatus;

  /// No description provided for @single.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get single;

  /// No description provided for @married.
  ///
  /// In en, this message translates to:
  /// **'Married'**
  String get married;

  /// No description provided for @divorced.
  ///
  /// In en, this message translates to:
  /// **'Divorced'**
  String get divorced;

  /// No description provided for @widowed.
  ///
  /// In en, this message translates to:
  /// **'Widowed'**
  String get widowed;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @passportNumber.
  ///
  /// In en, this message translates to:
  /// **'Passport Number'**
  String get passportNumber;

  /// No description provided for @educationLevel.
  ///
  /// In en, this message translates to:
  /// **'Education Level'**
  String get educationLevel;

  /// No description provided for @highSchool.
  ///
  /// In en, this message translates to:
  /// **'High School'**
  String get highSchool;

  /// No description provided for @diploma.
  ///
  /// In en, this message translates to:
  /// **'Diploma'**
  String get diploma;

  /// No description provided for @bachelor.
  ///
  /// In en, this message translates to:
  /// **'Bachelor'**
  String get bachelor;

  /// No description provided for @master.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get master;

  /// No description provided for @phd.
  ///
  /// In en, this message translates to:
  /// **'PhD'**
  String get phd;

  /// No description provided for @major.
  ///
  /// In en, this message translates to:
  /// **'Major'**
  String get major;

  /// No description provided for @university.
  ///
  /// In en, this message translates to:
  /// **'University'**
  String get university;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @genderRequired.
  ///
  /// In en, this message translates to:
  /// **'Gender is required'**
  String get genderRequired;

  /// No description provided for @picking.
  ///
  /// In en, this message translates to:
  /// **'Picking...'**
  String get picking;

  /// No description provided for @selectEmployeePhoto.
  ///
  /// In en, this message translates to:
  /// **'Select Employee Photo'**
  String get selectEmployeePhoto;

  /// No description provided for @photoTooLargeMax5Mb.
  ///
  /// In en, this message translates to:
  /// **'Photo is too large. Max size is 5 MB.'**
  String get photoTooLargeMax5Mb;

  /// No description provided for @unableAccessSelectedFilePath.
  ///
  /// In en, this message translates to:
  /// **'Unable to access selected file path on this platform.'**
  String get unableAccessSelectedFilePath;

  /// No description provided for @photoSelectedUploadAfterCreate.
  ///
  /// In en, this message translates to:
  /// **'Photo selected. You can upload it after employee creation from profile edit.'**
  String get photoSelectedUploadAfterCreate;

  /// No description provided for @photoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo upload failed: {error}'**
  String photoUploadFailed(Object error);

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @passportExpiry.
  ///
  /// In en, this message translates to:
  /// **'Passport Expiry'**
  String get passportExpiry;

  /// No description provided for @searchEmployeeHint.
  ///
  /// In en, this message translates to:
  /// **'Search employee...'**
  String get searchEmployeeHint;

  /// No description provided for @attendancePresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attendancePresent;

  /// No description provided for @attendanceLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get attendanceLate;

  /// No description provided for @attendanceAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get attendanceAbsent;

  /// No description provided for @attendanceOnLeave.
  ///
  /// In en, this message translates to:
  /// **'On Leave'**
  String get attendanceOnLeave;

  /// No description provided for @filterDate.
  ///
  /// In en, this message translates to:
  /// **'Filter Date'**
  String get filterDate;

  /// No description provided for @dateAsc.
  ///
  /// In en, this message translates to:
  /// **'Date (Asc)'**
  String get dateAsc;

  /// No description provided for @dateDesc.
  ///
  /// In en, this message translates to:
  /// **'Date (Desc)'**
  String get dateDesc;

  /// No description provided for @sortDate.
  ///
  /// In en, this message translates to:
  /// **'Sort Date'**
  String get sortDate;

  /// No description provided for @importCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get importCsv;

  /// No description provided for @addAttendance.
  ///
  /// In en, this message translates to:
  /// **'Add Attendance'**
  String get addAttendance;

  /// No description provided for @noAttendanceRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No attendance records found.'**
  String get noAttendanceRecordsFound;

  /// No description provided for @employee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employee;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check Out'**
  String get checkOut;

  /// No description provided for @overtime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get overtime;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @requestCorrection.
  ///
  /// In en, this message translates to:
  /// **'Request Correction'**
  String get requestCorrection;

  /// No description provided for @entitlementWithValue.
  ///
  /// In en, this message translates to:
  /// **'Entitlement: {value}'**
  String entitlementWithValue(Object value);

  /// No description provided for @usedWithValue.
  ///
  /// In en, this message translates to:
  /// **'Used: {value}'**
  String usedWithValue(Object value);

  /// No description provided for @remainingWithValue.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {value}'**
  String remainingWithValue(Object value);

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get allTypes;

  /// No description provided for @leaveTypeAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get leaveTypeAnnual;

  /// No description provided for @leaveTypeSick.
  ///
  /// In en, this message translates to:
  /// **'Sick'**
  String get leaveTypeSick;

  /// No description provided for @leaveTypeUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get leaveTypeUnpaid;

  /// No description provided for @leaveTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get leaveTypeOther;

  /// No description provided for @startFrom.
  ///
  /// In en, this message translates to:
  /// **'Start From'**
  String get startFrom;

  /// No description provided for @endTo.
  ///
  /// In en, this message translates to:
  /// **'End To'**
  String get endTo;

  /// No description provided for @startAsc.
  ///
  /// In en, this message translates to:
  /// **'Start (Asc)'**
  String get startAsc;

  /// No description provided for @startDesc.
  ///
  /// In en, this message translates to:
  /// **'Start (Desc)'**
  String get startDesc;

  /// No description provided for @sortStart.
  ///
  /// In en, this message translates to:
  /// **'Sort Start'**
  String get sortStart;

  /// No description provided for @addLeave.
  ///
  /// In en, this message translates to:
  /// **'Add Leave'**
  String get addLeave;

  /// No description provided for @noLeaveRequestsFound.
  ///
  /// In en, this message translates to:
  /// **'No leave requests found.'**
  String get noLeaveRequestsFound;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @resubmit.
  ///
  /// In en, this message translates to:
  /// **'Resubmit'**
  String get resubmit;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @noApprovalsFound.
  ///
  /// In en, this message translates to:
  /// **'No approvals found.'**
  String get noApprovalsFound;

  /// No description provided for @pendingWith.
  ///
  /// In en, this message translates to:
  /// **'Pending With'**
  String get pendingWith;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @processedApproved.
  ///
  /// In en, this message translates to:
  /// **'Processed (Approved)'**
  String get processedApproved;

  /// No description provided for @processedRejected.
  ///
  /// In en, this message translates to:
  /// **'Processed (Rejected)'**
  String get processedRejected;

  /// No description provided for @directManager.
  ///
  /// In en, this message translates to:
  /// **'Direct Manager'**
  String get directManager;

  /// No description provided for @rejectRequest.
  ///
  /// In en, this message translates to:
  /// **'Reject Request'**
  String get rejectRequest;

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reasonOptional;

  /// No description provided for @requestDetails.
  ///
  /// In en, this message translates to:
  /// **'Request Details'**
  String get requestDetails;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @openAttachment.
  ///
  /// In en, this message translates to:
  /// **'Open Attachment'**
  String get openAttachment;

  /// No description provided for @openDocument.
  ///
  /// In en, this message translates to:
  /// **'Open Document'**
  String get openDocument;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @invalidAttachmentUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid attachment URL'**
  String get invalidAttachmentUrl;

  /// No description provided for @unableOpenAttachment.
  ///
  /// In en, this message translates to:
  /// **'Unable to open attachment'**
  String get unableOpenAttachment;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @assignedToMe.
  ///
  /// In en, this message translates to:
  /// **'Assigned To Me'**
  String get assignedToMe;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @finalized.
  ///
  /// In en, this message translates to:
  /// **'Finalized'**
  String get finalized;

  /// No description provided for @posted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get posted;

  /// No description provided for @newPayrollRun.
  ///
  /// In en, this message translates to:
  /// **'New Payroll Run'**
  String get newPayrollRun;

  /// No description provided for @noPayrollRunsFound.
  ///
  /// In en, this message translates to:
  /// **'No payroll runs found.'**
  String get noPayrollRunsFound;

  /// No description provided for @periodStart.
  ///
  /// In en, this message translates to:
  /// **'Period Start'**
  String get periodStart;

  /// No description provided for @periodEnd.
  ///
  /// In en, this message translates to:
  /// **'Period End'**
  String get periodEnd;

  /// No description provided for @employeesCount.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employeesCount;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @finalize.
  ///
  /// In en, this message translates to:
  /// **'Finalize'**
  String get finalize;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @payrollRunItems.
  ///
  /// In en, this message translates to:
  /// **'Payroll Run Items'**
  String get payrollRunItems;

  /// No description provided for @payrollRunFinalized.
  ///
  /// In en, this message translates to:
  /// **'Payroll run finalized'**
  String get payrollRunFinalized;

  /// No description provided for @basic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get basic;

  /// No description provided for @housing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get housing;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @totalAllCaps.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get totalAllCaps;

  /// No description provided for @csvSavedTo.
  ///
  /// In en, this message translates to:
  /// **'CSV saved to {path}'**
  String csvSavedTo(Object path);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(Object error);

  /// No description provided for @noPayrollItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No payroll items found.'**
  String get noPayrollItemsFound;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @startEndDatesRequired.
  ///
  /// In en, this message translates to:
  /// **'Start and end dates are required'**
  String get startEndDatesRequired;

  /// No description provided for @endDateAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End date must be after start date'**
  String get endDateAfterStart;

  /// No description provided for @pickStartDate.
  ///
  /// In en, this message translates to:
  /// **'Pick start date'**
  String get pickStartDate;

  /// No description provided for @pickEndDate.
  ///
  /// In en, this message translates to:
  /// **'Pick end date'**
  String get pickEndDate;

  /// No description provided for @searchCodeOrName.
  ///
  /// In en, this message translates to:
  /// **'Search code or name...'**
  String get searchCodeOrName;

  /// No description provided for @accountTypeAsset.
  ///
  /// In en, this message translates to:
  /// **'Asset'**
  String get accountTypeAsset;

  /// No description provided for @accountTypeLiability.
  ///
  /// In en, this message translates to:
  /// **'Liability'**
  String get accountTypeLiability;

  /// No description provided for @accountTypeEquity.
  ///
  /// In en, this message translates to:
  /// **'Equity'**
  String get accountTypeEquity;

  /// No description provided for @accountTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get accountTypeIncome;

  /// No description provided for @accountTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get accountTypeExpense;

  /// No description provided for @codeAsc.
  ///
  /// In en, this message translates to:
  /// **'Code (Asc)'**
  String get codeAsc;

  /// No description provided for @codeDesc.
  ///
  /// In en, this message translates to:
  /// **'Code (Desc)'**
  String get codeDesc;

  /// No description provided for @sortCode.
  ///
  /// In en, this message translates to:
  /// **'Sort Code'**
  String get sortCode;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// No description provided for @noAccountsFound.
  ///
  /// In en, this message translates to:
  /// **'No accounts found.'**
  String get noAccountsFound;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @codeRequired.
  ///
  /// In en, this message translates to:
  /// **'Code is required'**
  String get codeRequired;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @newEntry.
  ///
  /// In en, this message translates to:
  /// **'New Entry'**
  String get newEntry;

  /// No description provided for @noJournalEntriesFound.
  ///
  /// In en, this message translates to:
  /// **'No journal entries found.'**
  String get noJournalEntriesFound;

  /// No description provided for @memo.
  ///
  /// In en, this message translates to:
  /// **'Memo'**
  String get memo;

  /// No description provided for @debit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get debit;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @debitOrCreditRequired.
  ///
  /// In en, this message translates to:
  /// **'Debit or Credit is required'**
  String get debitOrCreditRequired;

  /// No description provided for @dateRequired.
  ///
  /// In en, this message translates to:
  /// **'Date is required'**
  String get dateRequired;

  /// No description provided for @addAtLeastOneLine.
  ///
  /// In en, this message translates to:
  /// **'Add at least one line'**
  String get addAtLeastOneLine;

  /// No description provided for @debitsMustEqualCredits.
  ///
  /// In en, this message translates to:
  /// **'Debits must equal credits'**
  String get debitsMustEqualCredits;

  /// No description provided for @newJournalEntry.
  ///
  /// In en, this message translates to:
  /// **'New Journal Entry'**
  String get newJournalEntry;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get pickDate;

  /// No description provided for @employeeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Employee Profile'**
  String get employeeProfileTitle;

  /// No description provided for @failedToLoadEmployeeProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load employee profile'**
  String get failedToLoadEmployeeProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @passportNo.
  ///
  /// In en, this message translates to:
  /// **'Passport No'**
  String get passportNo;

  /// No description provided for @residencyIssueDate.
  ///
  /// In en, this message translates to:
  /// **'Residency Issue Date'**
  String get residencyIssueDate;

  /// No description provided for @residencyExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Residency Expiry Date'**
  String get residencyExpiryDate;

  /// No description provided for @insuranceStartDate.
  ///
  /// In en, this message translates to:
  /// **'Insurance Start Date'**
  String get insuranceStartDate;

  /// No description provided for @insuranceExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Insurance Expiry Date'**
  String get insuranceExpiryDate;

  /// No description provided for @insuranceProvider.
  ///
  /// In en, this message translates to:
  /// **'Insurance Provider'**
  String get insuranceProvider;

  /// No description provided for @insurancePolicyNo.
  ///
  /// In en, this message translates to:
  /// **'Insurance Policy No'**
  String get insurancePolicyNo;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get basicInfo;

  /// No description provided for @basicSalary.
  ///
  /// In en, this message translates to:
  /// **'Basic Salary'**
  String get basicSalary;

  /// No description provided for @totalCompensation.
  ///
  /// In en, this message translates to:
  /// **'Total Compensation'**
  String get totalCompensation;

  /// No description provided for @compensationHistory.
  ///
  /// In en, this message translates to:
  /// **'Compensation History'**
  String get compensationHistory;

  /// No description provided for @noCompensationHistory.
  ///
  /// In en, this message translates to:
  /// **'No compensation history'**
  String get noCompensationHistory;

  /// No description provided for @financial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get financial;

  /// No description provided for @contract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contract;

  /// No description provided for @addCompensationVersion.
  ///
  /// In en, this message translates to:
  /// **'Add Compensation Version'**
  String get addCompensationVersion;

  /// No description provided for @addContractVersion.
  ///
  /// In en, this message translates to:
  /// **'Add Contract Version'**
  String get addContractVersion;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @probationMonthsLabel.
  ///
  /// In en, this message translates to:
  /// **'Probation (months)'**
  String get probationMonthsLabel;

  /// No description provided for @openContractFile.
  ///
  /// In en, this message translates to:
  /// **'Open Contract File'**
  String get openContractFile;

  /// No description provided for @contractHistory.
  ///
  /// In en, this message translates to:
  /// **'Contract History'**
  String get contractHistory;

  /// No description provided for @noContractHistory.
  ///
  /// In en, this message translates to:
  /// **'No contract history'**
  String get noContractHistory;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @noDocumentsUploaded.
  ///
  /// In en, this message translates to:
  /// **'No documents uploaded'**
  String get noDocumentsUploaded;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get invalidUrl;

  /// No description provided for @unableOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Unable to open file'**
  String get unableOpenFile;

  /// No description provided for @htmlSavedTo.
  ///
  /// In en, this message translates to:
  /// **'HTML saved to {path}'**
  String htmlSavedTo(Object path);

  /// No description provided for @editEmployeeProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Employee Profile'**
  String get editEmployeeProfile;

  /// No description provided for @pickingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Picking photo...'**
  String get pickingPhoto;

  /// No description provided for @selectPhoto.
  ///
  /// In en, this message translates to:
  /// **'Select Photo'**
  String get selectPhoto;

  /// No description provided for @uploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo...'**
  String get uploadingPhoto;

  /// No description provided for @residencyIssue.
  ///
  /// In en, this message translates to:
  /// **'Residency Issue'**
  String get residencyIssue;

  /// No description provided for @residencyExpiry.
  ///
  /// In en, this message translates to:
  /// **'Residency Expiry'**
  String get residencyExpiry;

  /// No description provided for @insuranceStart.
  ///
  /// In en, this message translates to:
  /// **'Insurance Start'**
  String get insuranceStart;

  /// No description provided for @insuranceExpiry.
  ///
  /// In en, this message translates to:
  /// **'Insurance Expiry'**
  String get insuranceExpiry;

  /// No description provided for @contractFileUrl.
  ///
  /// In en, this message translates to:
  /// **'Contract File URL'**
  String get contractFileUrl;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @photoUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Photo uploaded successfully'**
  String get photoUploadedSuccessfully;

  /// No description provided for @contractTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Contract type is required'**
  String get contractTypeRequired;

  /// No description provided for @contractFileUrlOptional.
  ///
  /// In en, this message translates to:
  /// **'Contract File URL (optional)'**
  String get contractFileUrlOptional;

  /// No description provided for @startDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Start date is required'**
  String get startDateRequired;

  /// No description provided for @effectiveDate.
  ///
  /// In en, this message translates to:
  /// **'Effective Date'**
  String get effectiveDate;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String fieldRequired(Object field);

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @pdfSavedTo.
  ///
  /// In en, this message translates to:
  /// **'PDF saved to {path}'**
  String pdfSavedTo(Object path);

  /// No description provided for @employeeFullReport.
  ///
  /// In en, this message translates to:
  /// **'Employee Full Report'**
  String get employeeFullReport;

  /// No description provided for @reportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated: {value}'**
  String reportGenerated(Object value);

  /// No description provided for @employeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get employeeId;

  /// No description provided for @issued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get issued;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @urlLabel.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get urlLabel;

  /// No description provided for @failedToLoadHrDashboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to load HR dashboard'**
  String get failedToLoadHrDashboard;

  /// No description provided for @hrDashboard.
  ///
  /// In en, this message translates to:
  /// **'HR Dashboard'**
  String get hrDashboard;

  /// No description provided for @activeEmployeesKpi.
  ///
  /// In en, this message translates to:
  /// **'Active Employees'**
  String get activeEmployeesKpi;

  /// No description provided for @currentHeadcount.
  ///
  /// In en, this message translates to:
  /// **'Current headcount'**
  String get currentHeadcount;

  /// No description provided for @pendingApprovalsKpi.
  ///
  /// In en, this message translates to:
  /// **'Pending Approvals'**
  String get pendingApprovalsKpi;

  /// No description provided for @expiryAlertsKpi.
  ///
  /// In en, this message translates to:
  /// **'Expiry Alerts'**
  String get expiryAlertsKpi;

  /// No description provided for @expiredDocumentsKpi.
  ///
  /// In en, this message translates to:
  /// **'Expired Documents'**
  String get expiredDocumentsKpi;

  /// No description provided for @urgentAlertsKpi.
  ///
  /// In en, this message translates to:
  /// **'Urgent Alerts'**
  String get urgentAlertsKpi;

  /// No description provided for @waitingHrAction.
  ///
  /// In en, this message translates to:
  /// **'Waiting HR action'**
  String get waitingHrAction;

  /// No description provided for @documentExpiryNeedsAction.
  ///
  /// In en, this message translates to:
  /// **'Documents need HR action'**
  String get documentExpiryNeedsAction;

  /// No description provided for @onLeaveTodayKpi.
  ///
  /// In en, this message translates to:
  /// **'On Leave Today'**
  String get onLeaveTodayKpi;

  /// No description provided for @approvedLeaveToday.
  ///
  /// In en, this message translates to:
  /// **'Approved leave today'**
  String get approvedLeaveToday;

  /// No description provided for @noCheckInTodayKpi.
  ///
  /// In en, this message translates to:
  /// **'No Check-in Today'**
  String get noCheckInTodayKpi;

  /// No description provided for @activeStaffNotCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Active staff not checked in'**
  String get activeStaffNotCheckedIn;

  /// No description provided for @leavesThisMonthKpi.
  ///
  /// In en, this message translates to:
  /// **'Leaves This Month'**
  String get leavesThisMonthKpi;

  /// No description provided for @approvedLeaveRequests.
  ///
  /// In en, this message translates to:
  /// **'Approved leave requests'**
  String get approvedLeaveRequests;

  /// No description provided for @pendingRequestsTop10.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests (Top 10)'**
  String get pendingRequestsTop10;

  /// No description provided for @noPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests.'**
  String get noPendingRequests;

  /// No description provided for @expiringDocuments30Days.
  ///
  /// In en, this message translates to:
  /// **'Expiring Documents (30 days)'**
  String get expiringDocuments30Days;

  /// No description provided for @noDocumentExpiries30Days.
  ///
  /// In en, this message translates to:
  /// **'No document expiries in next 30 days.'**
  String get noDocumentExpiries30Days;

  /// No description provided for @documentLabel.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentLabel;

  /// No description provided for @productivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get productivity;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @hrWorkflowBoard.
  ///
  /// In en, this message translates to:
  /// **'HR Workflow Board'**
  String get hrWorkflowBoard;

  /// No description provided for @reviewPendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Review Pending Approvals'**
  String get reviewPendingApprovals;

  /// No description provided for @pendingTaskReviews.
  ///
  /// In en, this message translates to:
  /// **'Pending Task Reviews'**
  String get pendingTaskReviews;

  /// No description provided for @pendingTaskQa.
  ///
  /// In en, this message translates to:
  /// **'Pending Final QA'**
  String get pendingTaskQa;

  /// No description provided for @noPendingTaskReviews.
  ///
  /// In en, this message translates to:
  /// **'No pending task reviews.'**
  String get noPendingTaskReviews;

  /// No description provided for @noPendingTaskQa.
  ///
  /// In en, this message translates to:
  /// **'No tasks pending final QA.'**
  String get noPendingTaskQa;

  /// No description provided for @requestManagerReview.
  ///
  /// In en, this message translates to:
  /// **'Request Manager Review'**
  String get requestManagerReview;

  /// No description provided for @reviewPending.
  ///
  /// In en, this message translates to:
  /// **'Review Pending'**
  String get reviewPending;

  /// No description provided for @reviewApproved.
  ///
  /// In en, this message translates to:
  /// **'Review Approved'**
  String get reviewApproved;

  /// No description provided for @reviewRejected.
  ///
  /// In en, this message translates to:
  /// **'Review Rejected'**
  String get reviewRejected;

  /// No description provided for @noActiveReview.
  ///
  /// In en, this message translates to:
  /// **'No Active Review'**
  String get noActiveReview;

  /// No description provided for @reviewNote.
  ///
  /// In en, this message translates to:
  /// **'Review Note'**
  String get reviewNote;

  /// No description provided for @reviewNoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Review note is required'**
  String get reviewNoteRequired;

  /// No description provided for @reviewRequestedAt.
  ///
  /// In en, this message translates to:
  /// **'Review requested at'**
  String get reviewRequestedAt;

  /// No description provided for @yourReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Your note'**
  String get yourReviewNote;

  /// No description provided for @managerResponseNote.
  ///
  /// In en, this message translates to:
  /// **'Manager response'**
  String get managerResponseNote;

  /// No description provided for @reviewRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Review request sent'**
  String get reviewRequestSent;

  /// No description provided for @approveAndUpdate.
  ///
  /// In en, this message translates to:
  /// **'Approve and Update'**
  String get approveAndUpdate;

  /// No description provided for @rejectReviewRequest.
  ///
  /// In en, this message translates to:
  /// **'Reject Review Request'**
  String get rejectReviewRequest;

  /// No description provided for @reviewApprovedAndTaskUpdated.
  ///
  /// In en, this message translates to:
  /// **'Review approved and task updated'**
  String get reviewApprovedAndTaskUpdated;

  /// No description provided for @reviewRejectedAndReturned.
  ///
  /// In en, this message translates to:
  /// **'Review rejected and task returned'**
  String get reviewRejectedAndReturned;

  /// No description provided for @taskEventReviewRequested.
  ///
  /// In en, this message translates to:
  /// **'Review requested'**
  String get taskEventReviewRequested;

  /// No description provided for @taskEventReviewApproved.
  ///
  /// In en, this message translates to:
  /// **'Review approved'**
  String get taskEventReviewApproved;

  /// No description provided for @taskEventReviewRejected.
  ///
  /// In en, this message translates to:
  /// **'Review rejected'**
  String get taskEventReviewRejected;

  /// No description provided for @taskEventQaAccepted.
  ///
  /// In en, this message translates to:
  /// **'QA accepted'**
  String get taskEventQaAccepted;

  /// No description provided for @taskEventQaRework.
  ///
  /// In en, this message translates to:
  /// **'QA sent for rework'**
  String get taskEventQaRework;

  /// No description provided for @taskEventQaRejected.
  ///
  /// In en, this message translates to:
  /// **'QA rejected'**
  String get taskEventQaRejected;

  /// No description provided for @taskEventAttachmentAdded.
  ///
  /// In en, this message translates to:
  /// **'Attachment added'**
  String get taskEventAttachmentAdded;

  /// No description provided for @taskEventTimeLogged.
  ///
  /// In en, this message translates to:
  /// **'Time logged'**
  String get taskEventTimeLogged;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @attachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach File'**
  String get attachFile;

  /// No description provided for @logHours.
  ///
  /// In en, this message translates to:
  /// **'Log Hours'**
  String get logHours;

  /// No description provided for @logHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Hours'**
  String get logHoursTitle;

  /// No description provided for @loggedHours.
  ///
  /// In en, this message translates to:
  /// **'Logged Hours'**
  String get loggedHours;

  /// No description provided for @invalidLoggedHours.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid logged hours value.'**
  String get invalidLoggedHours;

  /// No description provided for @hoursLoggedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Hours logged successfully'**
  String get hoursLoggedSuccessfully;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @attachmentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} attachments'**
  String attachmentsCount(int count);

  /// No description provided for @allTasks.
  ///
  /// In en, this message translates to:
  /// **'All Tasks'**
  String get allTasks;

  /// No description provided for @attachmentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Attachment uploaded'**
  String get attachmentUploaded;

  /// No description provided for @qaPending.
  ///
  /// In en, this message translates to:
  /// **'QA Pending'**
  String get qaPending;

  /// No description provided for @qaAccepted.
  ///
  /// In en, this message translates to:
  /// **'QA Accepted'**
  String get qaAccepted;

  /// No description provided for @qaRework.
  ///
  /// In en, this message translates to:
  /// **'Needs Rework'**
  String get qaRework;

  /// No description provided for @qaRejected.
  ///
  /// In en, this message translates to:
  /// **'QA Rejected'**
  String get qaRejected;

  /// No description provided for @qaApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get qaApprove;

  /// No description provided for @qaSendRework.
  ///
  /// In en, this message translates to:
  /// **'Send Rework'**
  String get qaSendRework;

  /// No description provided for @qaReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get qaReject;

  /// No description provided for @qaApprovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Task approved in final QA'**
  String get qaApprovedMessage;

  /// No description provided for @qaReworkMessage.
  ///
  /// In en, this message translates to:
  /// **'Task sent back for rework'**
  String get qaReworkMessage;

  /// No description provided for @qaRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Task rejected in final QA'**
  String get qaRejectedMessage;

  /// No description provided for @qaLabel.
  ///
  /// In en, this message translates to:
  /// **'QA: {status}'**
  String qaLabel(Object status);

  /// No description provided for @employeeActionCenter.
  ///
  /// In en, this message translates to:
  /// **'Action Center'**
  String get employeeActionCenter;

  /// No description provided for @employeeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get employeeNotifications;

  /// No description provided for @noEmployeeNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications right now.'**
  String get noEmployeeNotifications;

  /// No description provided for @taskDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Task due soon'**
  String get taskDueSoon;

  /// No description provided for @reviewPendingWithValue.
  ///
  /// In en, this message translates to:
  /// **'Review pending: {value}'**
  String reviewPendingWithValue(int value);

  /// No description provided for @qaPendingWithValue.
  ///
  /// In en, this message translates to:
  /// **'QA pending: {value}'**
  String qaPendingWithValue(int value);

  /// No description provided for @dueSoonWithValue.
  ///
  /// In en, this message translates to:
  /// **'Due soon: {value}'**
  String dueSoonWithValue(int value);

  /// No description provided for @resolveExpiryAlerts.
  ///
  /// In en, this message translates to:
  /// **'Resolve Expiry Alerts'**
  String get resolveExpiryAlerts;

  /// No description provided for @completeEmployeeDocuments.
  ///
  /// In en, this message translates to:
  /// **'Complete Employee Documents'**
  String get completeEmployeeDocuments;

  /// No description provided for @documentCompliance.
  ///
  /// In en, this message translates to:
  /// **'Document Compliance'**
  String get documentCompliance;

  /// No description provided for @expiringDocumentsByType.
  ///
  /// In en, this message translates to:
  /// **'Expiring Documents by Type'**
  String get expiringDocumentsByType;

  /// No description provided for @expiringWithin30Days.
  ///
  /// In en, this message translates to:
  /// **'Expiring within 30 days'**
  String get expiringWithin30Days;

  /// No description provided for @todayAttendanceInsights.
  ///
  /// In en, this message translates to:
  /// **'Today Attendance Insights'**
  String get todayAttendanceInsights;

  /// No description provided for @attendanceAlertsToday.
  ///
  /// In en, this message translates to:
  /// **'Attendance Alerts Today'**
  String get attendanceAlertsToday;

  /// No description provided for @noAttendanceInsightsToday.
  ///
  /// In en, this message translates to:
  /// **'No attendance insights for today.'**
  String get noAttendanceInsightsToday;

  /// No description provided for @noAttendanceAlertsToday.
  ///
  /// In en, this message translates to:
  /// **'No attendance alerts for today.'**
  String get noAttendanceAlertsToday;

  /// No description provided for @checkedInTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Checked In Today'**
  String get checkedInTodayLabel;

  /// No description provided for @absentTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Absent Today'**
  String get absentTodayLabel;

  /// No description provided for @pendingWithValue.
  ///
  /// In en, this message translates to:
  /// **'Pending: {value}'**
  String pendingWithValue(int value);

  /// No description provided for @doneWithValue.
  ///
  /// In en, this message translates to:
  /// **'Done: {value}'**
  String doneWithValue(int value);

  /// No description provided for @recentTasks.
  ///
  /// In en, this message translates to:
  /// **'Recent Tasks'**
  String get recentTasks;

  /// No description provided for @noTasksAssignedYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks assigned yet.'**
  String get noTasksAssignedYet;

  /// No description provided for @teamProductivity.
  ///
  /// In en, this message translates to:
  /// **'Team Productivity'**
  String get teamProductivity;

  /// No description provided for @tasksWithValue.
  ///
  /// In en, this message translates to:
  /// **'Tasks: {value}'**
  String tasksWithValue(int value);

  /// No description provided for @assignTask.
  ///
  /// In en, this message translates to:
  /// **'Assign Task'**
  String get assignTask;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Title'**
  String get taskTitle;

  /// No description provided for @dueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDateLabel;

  /// No description provided for @dueDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Due Date (optional)'**
  String get dueDateOptional;

  /// No description provided for @assigning.
  ///
  /// In en, this message translates to:
  /// **'Assigning...'**
  String get assigning;

  /// No description provided for @taskAssigned.
  ///
  /// In en, this message translates to:
  /// **'Task assigned'**
  String get taskAssigned;

  /// No description provided for @assignFailed.
  ///
  /// In en, this message translates to:
  /// **'Assign failed: {error}'**
  String assignFailed(Object error);

  /// No description provided for @searchNameOrCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Search name or code...'**
  String get searchNameOrCodeHint;

  /// No description provided for @addDepartment.
  ///
  /// In en, this message translates to:
  /// **'Add Department'**
  String get addDepartment;

  /// No description provided for @noManagerChangesNeeded.
  ///
  /// In en, this message translates to:
  /// **'No manager changes were needed.'**
  String get noManagerChangesNeeded;

  /// No description provided for @assignedUpdatedManagers.
  ///
  /// In en, this message translates to:
  /// **'Assigned/updated managers for {count} department(s).'**
  String assignedUpdatedManagers(int count);

  /// No description provided for @autoAssignFailed.
  ///
  /// In en, this message translates to:
  /// **'Auto assign failed: {error}'**
  String autoAssignFailed(Object error);

  /// No description provided for @autoAssignManagers.
  ///
  /// In en, this message translates to:
  /// **'Auto Assign Managers'**
  String get autoAssignManagers;

  /// No description provided for @manager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get manager;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @noDepartmentsFound.
  ///
  /// In en, this message translates to:
  /// **'No departments found.'**
  String get noDepartmentsFound;

  /// No description provided for @noJobTitlesFound.
  ///
  /// In en, this message translates to:
  /// **'No job titles found.'**
  String get noJobTitlesFound;

  /// No description provided for @editJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Job Title'**
  String get editJobTitle;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @codeOptional.
  ///
  /// In en, this message translates to:
  /// **'Code (optional)'**
  String get codeOptional;

  /// No description provided for @levelOptional.
  ///
  /// In en, this message translates to:
  /// **'Level (optional)'**
  String get levelOptional;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @addJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Job Title'**
  String get addJobTitle;

  /// No description provided for @sortLevel.
  ///
  /// In en, this message translates to:
  /// **'Sort Level'**
  String get sortLevel;

  /// No description provided for @levelAsc.
  ///
  /// In en, this message translates to:
  /// **'Level ?'**
  String get levelAsc;

  /// No description provided for @levelDesc.
  ///
  /// In en, this message translates to:
  /// **'Level ?'**
  String get levelDesc;

  /// No description provided for @id.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @passport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get passport;

  /// No description provided for @addDocument.
  ///
  /// In en, this message translates to:
  /// **'Add Document'**
  String get addDocument;

  /// No description provided for @noDocumentsFound.
  ///
  /// In en, this message translates to:
  /// **'No documents found.'**
  String get noDocumentsFound;

  /// No description provided for @invalidFileUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid file URL'**
  String get invalidFileUrl;

  /// No description provided for @editDepartment.
  ///
  /// In en, this message translates to:
  /// **'Edit Department'**
  String get editDepartment;

  /// No description provided for @unableToLoadManagers.
  ///
  /// In en, this message translates to:
  /// **'Unable to load managers'**
  String get unableToLoadManagers;

  /// No description provided for @departmentManager.
  ///
  /// In en, this message translates to:
  /// **'Department Manager'**
  String get departmentManager;

  /// No description provided for @noManager.
  ///
  /// In en, this message translates to:
  /// **'No manager'**
  String get noManager;

  /// No description provided for @employeeRequired.
  ///
  /// In en, this message translates to:
  /// **'Employee is required'**
  String get employeeRequired;

  /// No description provided for @documentType.
  ///
  /// In en, this message translates to:
  /// **'Document Type'**
  String get documentType;

  /// No description provided for @documentTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Document type is required'**
  String get documentTypeRequired;

  /// No description provided for @fileUrl.
  ///
  /// In en, this message translates to:
  /// **'File URL'**
  String get fileUrl;

  /// No description provided for @fileUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'File URL is required'**
  String get fileUrlRequired;

  /// No description provided for @fileRequired.
  ///
  /// In en, this message translates to:
  /// **'File is required'**
  String get fileRequired;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @uploadPdf.
  ///
  /// In en, this message translates to:
  /// **'Upload PDF'**
  String get uploadPdf;

  /// No description provided for @uploadingDocument.
  ///
  /// In en, this message translates to:
  /// **'Uploading document...'**
  String get uploadingDocument;

  /// No description provided for @savingDocument.
  ///
  /// In en, this message translates to:
  /// **'Saving document...'**
  String get savingDocument;

  /// No description provided for @issuedDate.
  ///
  /// In en, this message translates to:
  /// **'Issued Date'**
  String get issuedDate;

  /// No description provided for @expiresDate.
  ///
  /// In en, this message translates to:
  /// **'Expires Date'**
  String get expiresDate;

  /// No description provided for @fileUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'File uploaded successfully'**
  String get fileUploadedSuccessfully;

  /// No description provided for @fileUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'File upload failed: {error}'**
  String fileUploadFailed(Object error);

  /// No description provided for @employeeDocsStorageUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Employee documents storage is not configured yet. Run the employee docs bucket SQL first.'**
  String get employeeDocsStorageUnauthorized;

  /// No description provided for @editDocument.
  ///
  /// In en, this message translates to:
  /// **'Edit Document'**
  String get editDocument;

  /// No description provided for @deleteDocument.
  ///
  /// In en, this message translates to:
  /// **'Delete Document'**
  String get deleteDocument;

  /// No description provided for @deleteDocumentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this document?'**
  String get deleteDocumentConfirm;

  /// No description provided for @documentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Document updated successfully'**
  String get documentUpdated;

  /// No description provided for @documentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Document deleted successfully'**
  String get documentDeleted;

  /// No description provided for @fileSavedTo.
  ///
  /// In en, this message translates to:
  /// **'File saved to: {path}'**
  String fileSavedTo(Object path);

  /// No description provided for @fileDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'File download failed: {error}'**
  String fileDownloadFailed(Object error);

  /// No description provided for @notAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated'**
  String get notAuthenticated;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @checkInCoverage.
  ///
  /// In en, this message translates to:
  /// **'Check-in Coverage'**
  String get checkInCoverage;

  /// No description provided for @approvalLoad.
  ///
  /// In en, this message translates to:
  /// **'Approval Load'**
  String get approvalLoad;

  /// No description provided for @teamMembers.
  ///
  /// In en, this message translates to:
  /// **'Team Members'**
  String get teamMembers;

  /// No description provided for @openTasks.
  ///
  /// In en, this message translates to:
  /// **'Open Tasks'**
  String get openTasks;

  /// No description provided for @overdueTasks.
  ///
  /// In en, this message translates to:
  /// **'Overdue Tasks'**
  String get overdueTasks;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get completionRate;

  /// No description provided for @dueSoonTasks.
  ///
  /// In en, this message translates to:
  /// **'Due Soon (7 days)'**
  String get dueSoonTasks;

  /// No description provided for @noDueSoonTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks due in the next 7 days.'**
  String get noDueSoonTasks;

  /// No description provided for @topPerformers.
  ///
  /// In en, this message translates to:
  /// **'Top 5 Performers'**
  String get topPerformers;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get needsAttention;

  /// No description provided for @noTeamDataYet.
  ///
  /// In en, this message translates to:
  /// **'No team data yet.'**
  String get noTeamDataYet;

  /// No description provided for @taskTimeline.
  ///
  /// In en, this message translates to:
  /// **'Task Timeline'**
  String get taskTimeline;

  /// No description provided for @assignedToEmployeeAt.
  ///
  /// In en, this message translates to:
  /// **'Assigned to employee at'**
  String get assignedToEmployeeAt;

  /// No description provided for @employeeReceivedAt.
  ///
  /// In en, this message translates to:
  /// **'Employee received task at'**
  String get employeeReceivedAt;

  /// No description provided for @employeeStartedAt.
  ///
  /// In en, this message translates to:
  /// **'Employee started task at'**
  String get employeeStartedAt;

  /// No description provided for @completedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed at'**
  String get completedAtLabel;

  /// No description provided for @lastUpdateAt.
  ///
  /// In en, this message translates to:
  /// **'Last update at'**
  String get lastUpdateAt;

  /// No description provided for @updatesTimeline.
  ///
  /// In en, this message translates to:
  /// **'Updates Timeline'**
  String get updatesTimeline;

  /// No description provided for @taskEventAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get taskEventAssigned;

  /// No description provided for @taskEventStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status changed'**
  String get taskEventStatusChanged;

  /// No description provided for @taskEventProgressUpdated.
  ///
  /// In en, this message translates to:
  /// **'Progress updated'**
  String get taskEventProgressUpdated;

  /// No description provided for @estimateHours.
  ///
  /// In en, this message translates to:
  /// **'Estimated Hours'**
  String get estimateHours;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @taskWeight.
  ///
  /// In en, this message translates to:
  /// **'Task Weight'**
  String get taskWeight;

  /// No description provided for @invalidEstimateHours.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid estimated hours value.'**
  String get invalidEstimateHours;

  /// No description provided for @taskType.
  ///
  /// In en, this message translates to:
  /// **'Task Type'**
  String get taskType;

  /// No description provided for @taskCatalog.
  ///
  /// In en, this message translates to:
  /// **'Task Catalog'**
  String get taskCatalog;

  /// No description provided for @taskCatalogForDepartment.
  ///
  /// In en, this message translates to:
  /// **'{department} task catalog'**
  String taskCatalogForDepartment(Object department);

  /// No description provided for @taskTemplate.
  ///
  /// In en, this message translates to:
  /// **'Task Template'**
  String get taskTemplate;

  /// No description provided for @taskTypeGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get taskTypeGeneral;

  /// No description provided for @taskTypeDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Development'**
  String get taskTypeDevelopment;

  /// No description provided for @taskTypeBugFix.
  ///
  /// In en, this message translates to:
  /// **'Bug Fix'**
  String get taskTypeBugFix;

  /// No description provided for @taskTypeTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing'**
  String get taskTypeTesting;

  /// No description provided for @taskTypeSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get taskTypeSupport;

  /// No description provided for @taskTypeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get taskTypeTransfer;

  /// No description provided for @taskTypeReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get taskTypeReport;

  /// No description provided for @taskTypeTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get taskTypeTax;

  /// No description provided for @taskTypePayroll.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get taskTypePayroll;

  /// No description provided for @taskTypeReconciliation.
  ///
  /// In en, this message translates to:
  /// **'Reconciliation'**
  String get taskTypeReconciliation;

  /// No description provided for @taskTypeRecruitment.
  ///
  /// In en, this message translates to:
  /// **'Recruitment'**
  String get taskTypeRecruitment;

  /// No description provided for @taskTypeOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get taskTypeOnboarding;

  /// No description provided for @taskTypeEmployeeDocs.
  ///
  /// In en, this message translates to:
  /// **'Employee Documents'**
  String get taskTypeEmployeeDocs;

  /// No description provided for @templateLoginSignup.
  ///
  /// In en, this message translates to:
  /// **'Login and signup delivery'**
  String get templateLoginSignup;

  /// No description provided for @templateLoginSignupDesc.
  ///
  /// In en, this message translates to:
  /// **'Build and complete the login and signup flow with validation, state handling, and final QA.'**
  String get templateLoginSignupDesc;

  /// No description provided for @templateBugFixRelease.
  ///
  /// In en, this message translates to:
  /// **'Release blocker bug fix'**
  String get templateBugFixRelease;

  /// No description provided for @templateBugFixReleaseDesc.
  ///
  /// In en, this message translates to:
  /// **'Investigate the blocker, apply the fix, validate affected flows, and prepare the release notes.'**
  String get templateBugFixReleaseDesc;

  /// No description provided for @templateRegressionTesting.
  ///
  /// In en, this message translates to:
  /// **'Regression testing cycle'**
  String get templateRegressionTesting;

  /// No description provided for @templateRegressionTestingDesc.
  ///
  /// In en, this message translates to:
  /// **'Run the assigned regression checklist, document findings, and retest the resolved issues.'**
  String get templateRegressionTestingDesc;

  /// No description provided for @templateTransferBatch.
  ///
  /// In en, this message translates to:
  /// **'Transfer batch processing'**
  String get templateTransferBatch;

  /// No description provided for @templateTransferBatchDesc.
  ///
  /// In en, this message translates to:
  /// **'Process the assigned transfers, verify amounts, and log completion status for each transaction.'**
  String get templateTransferBatchDesc;

  /// No description provided for @templateMonthlyFinanceReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly finance report'**
  String get templateMonthlyFinanceReport;

  /// No description provided for @templateMonthlyFinanceReportDesc.
  ///
  /// In en, this message translates to:
  /// **'Prepare the monthly finance report, review the source numbers, and submit the final summary.'**
  String get templateMonthlyFinanceReportDesc;

  /// No description provided for @templateTaxSubmission.
  ///
  /// In en, this message translates to:
  /// **'Tax submission package'**
  String get templateTaxSubmission;

  /// No description provided for @templateTaxSubmissionDesc.
  ///
  /// In en, this message translates to:
  /// **'Prepare tax data, validate required documents, and submit the filing package before the deadline.'**
  String get templateTaxSubmissionDesc;

  /// No description provided for @templateOnboardingPack.
  ///
  /// In en, this message translates to:
  /// **'Employee onboarding pack'**
  String get templateOnboardingPack;

  /// No description provided for @templateOnboardingPackDesc.
  ///
  /// In en, this message translates to:
  /// **'Collect, review, and complete the onboarding checklist and required employee documents.'**
  String get templateOnboardingPackDesc;

  /// No description provided for @templateDocumentAudit.
  ///
  /// In en, this message translates to:
  /// **'Employee document audit'**
  String get templateDocumentAudit;

  /// No description provided for @templateDocumentAuditDesc.
  ///
  /// In en, this message translates to:
  /// **'Review the employee document set, flag missing items, and update expiry-sensitive files.'**
  String get templateDocumentAuditDesc;

  /// No description provided for @templateRecruitmentFollowup.
  ///
  /// In en, this message translates to:
  /// **'Recruitment follow-up'**
  String get templateRecruitmentFollowup;

  /// No description provided for @templateRecruitmentFollowupDesc.
  ///
  /// In en, this message translates to:
  /// **'Follow up on the assigned candidates, update statuses, and move the pipeline forward.'**
  String get templateRecruitmentFollowupDesc;

  /// No description provided for @templateGeneralFollowup.
  ///
  /// In en, this message translates to:
  /// **'General follow-up task'**
  String get templateGeneralFollowup;

  /// No description provided for @templateGeneralFollowupDesc.
  ///
  /// In en, this message translates to:
  /// **'Track the assigned work item, update the status, and close the task on time.'**
  String get templateGeneralFollowupDesc;

  /// No description provided for @monthDepartmentOverview.
  ///
  /// In en, this message translates to:
  /// **'Monthly Department Overview'**
  String get monthDepartmentOverview;

  /// No description provided for @monthTasksCreated.
  ///
  /// In en, this message translates to:
  /// **'Tasks created this month'**
  String get monthTasksCreated;

  /// No description provided for @monthTasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'Tasks completed this month'**
  String get monthTasksCompleted;

  /// No description provided for @monthOnTimeRate.
  ///
  /// In en, this message translates to:
  /// **'On-time completion'**
  String get monthOnTimeRate;

  /// No description provided for @monthDepartmentProductivity.
  ///
  /// In en, this message translates to:
  /// **'Department productivity'**
  String get monthDepartmentProductivity;

  /// No description provided for @monthCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get monthCompletionRate;

  /// No description provided for @monthlyCompletionTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly Completion Trend'**
  String get monthlyCompletionTrend;

  /// No description provided for @lastSixMonths.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get lastSixMonths;

  /// No description provided for @onTimeVsDelayed.
  ///
  /// In en, this message translates to:
  /// **'On-time vs Delayed'**
  String get onTimeVsDelayed;

  /// No description provided for @taskTypeDistribution.
  ///
  /// In en, this message translates to:
  /// **'Task Type Distribution'**
  String get taskTypeDistribution;

  /// No description provided for @employeeWorkload.
  ///
  /// In en, this message translates to:
  /// **'Employee Workload'**
  String get employeeWorkload;

  /// No description provided for @currentMonthBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Current month breakdown'**
  String get currentMonthBreakdown;

  /// No description provided for @onTime.
  ///
  /// In en, this message translates to:
  /// **'On-time'**
  String get onTime;

  /// No description provided for @delayed.
  ///
  /// In en, this message translates to:
  /// **'Delayed'**
  String get delayed;

  /// No description provided for @monthTasksWithValue.
  ///
  /// In en, this message translates to:
  /// **'Month tasks: {value}'**
  String monthTasksWithValue(int value);

  /// No description provided for @completedThisMonthWithValue.
  ///
  /// In en, this message translates to:
  /// **'Completed this month: {value}'**
  String completedThisMonthWithValue(int value);

  /// No description provided for @avgTaskProgressWithValue.
  ///
  /// In en, this message translates to:
  /// **'Avg progress: {value}%'**
  String avgTaskProgressWithValue(Object value);

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// No description provided for @uploadNewDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload New Document'**
  String get uploadNewDocument;

  /// No description provided for @idCard.
  ///
  /// In en, this message translates to:
  /// **'ID Card'**
  String get idCard;

  /// No description provided for @graduationCert.
  ///
  /// In en, this message translates to:
  /// **'Graduation Certificate'**
  String get graduationCert;

  /// No description provided for @nationalAddress.
  ///
  /// In en, this message translates to:
  /// **'National Address'**
  String get nationalAddress;

  /// No description provided for @bankIbanCertificate.
  ///
  /// In en, this message translates to:
  /// **'Bank IBAN Certificate'**
  String get bankIbanCertificate;

  /// No description provided for @salaryCertificate.
  ///
  /// In en, this message translates to:
  /// **'Salary Certificate'**
  String get salaryCertificate;

  /// No description provided for @identityDocuments.
  ///
  /// In en, this message translates to:
  /// **'Identity Documents'**
  String get identityDocuments;

  /// No description provided for @educationAndCareerDocuments.
  ///
  /// In en, this message translates to:
  /// **'Education and Career Documents'**
  String get educationAndCareerDocuments;

  /// No description provided for @financialDocuments.
  ///
  /// In en, this message translates to:
  /// **'Financial Documents'**
  String get financialDocuments;

  /// No description provided for @medicalAndInsuranceDocuments.
  ///
  /// In en, this message translates to:
  /// **'Medical and Insurance Documents'**
  String get medicalAndInsuranceDocuments;

  /// No description provided for @otherDocuments.
  ///
  /// In en, this message translates to:
  /// **'Other Documents'**
  String get otherDocuments;

  /// No description provided for @residencyDocument.
  ///
  /// In en, this message translates to:
  /// **'Residency'**
  String get residencyDocument;

  /// No description provided for @drivingLicense.
  ///
  /// In en, this message translates to:
  /// **'Driving License'**
  String get drivingLicense;

  /// No description provided for @offerLetter.
  ///
  /// In en, this message translates to:
  /// **'Offer Letter'**
  String get offerLetter;

  /// No description provided for @salaryDefinition.
  ///
  /// In en, this message translates to:
  /// **'Salary Definition'**
  String get salaryDefinition;

  /// No description provided for @medicalInsurance.
  ///
  /// In en, this message translates to:
  /// **'Medical Insurance'**
  String get medicalInsurance;

  /// No description provided for @medicalReport.
  ///
  /// In en, this message translates to:
  /// **'Medical Report'**
  String get medicalReport;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @expiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get expiringSoon;

  /// No description provided for @valid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get valid;

  /// No description provided for @noExpiry.
  ///
  /// In en, this message translates to:
  /// **'No Expiry'**
  String get noExpiry;

  /// No description provided for @documentFile.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentFile;

  /// No description provided for @uploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload File'**
  String get uploadFile;

  /// No description provided for @noFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get noFileSelected;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @failedToLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get failedToLoadNotifications;

  /// No description provided for @noNotificationsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No notifications available.'**
  String get noNotificationsAvailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
