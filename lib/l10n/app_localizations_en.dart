// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dimah ERP SYS';

  @override
  String get myProfile => 'My Profile';

  @override
  String get changePassword => 'Change Password';

  @override
  String get logout => 'Logout';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get languageEnglish => 'English';

  @override
  String get downloadReport => 'Download Report';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get downloadHtml => 'Download HTML';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String saveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String get hrAlertsTitle => 'HR Expiry Alerts';

  @override
  String get hrAlertsLoadFailed => 'Failed to load HR alerts';

  @override
  String get hrAlertsSettings => 'Alert Settings';

  @override
  String get hrAlertsSettingsTitle => 'Alert Settings (Days)';

  @override
  String get hrAlertsContractDays => 'Contract alert days';

  @override
  String get hrAlertsResidencyDays => 'Residency alert days';

  @override
  String get hrAlertsInsuranceDays => 'Insurance alert days';

  @override
  String get hrAlertsDocumentsDays => 'Document alert days';

  @override
  String get hrAlertsSettingsSaved => 'Alert settings saved';

  @override
  String get hrAlertsNoRows => 'No expiry alerts found.';

  @override
  String get hrAlertsTotal => 'Total Alerts';

  @override
  String get hrAlertsColEmployee => 'Employee';

  @override
  String get hrAlertsColType => 'Type';

  @override
  String get hrAlertsColExpiryDate => 'Expiry Date';

  @override
  String get hrAlertsColDaysLeft => 'Days Left';

  @override
  String get hrAlertsColStatus => 'Status';

  @override
  String get hrBandExpired => 'Expired';

  @override
  String get hrBandUrgent => 'Urgent';

  @override
  String get hrBandWarning => 'Warning';

  @override
  String get hrBandUpcoming => 'Upcoming';

  @override
  String get hrBandSafe => 'Safe';

  @override
  String get hrTypeContract => 'Contract';

  @override
  String get hrTypeResidency => 'Residency';

  @override
  String get hrTypeInsurance => 'Insurance';

  @override
  String get hrTypeDocument => 'Document';

  @override
  String get validationRange1To365 => 'Enter a number between 1 and 365';

  @override
  String get menuDashboard => 'Dashboard';

  @override
  String get menuDepartments => 'Departments';

  @override
  String get menuJobTitles => 'Job Titles';

  @override
  String get menuEmployees => 'Employees';

  @override
  String get menuAttendance => 'Attendance';

  @override
  String get menuLeaves => 'Leaves';

  @override
  String get menuPayroll => 'Payroll';

  @override
  String get menuEmployeeDocs => 'Employee Documents';

  @override
  String get menuHrAlerts => 'HR Alerts';

  @override
  String get menuApprovals => 'Approvals';

  @override
  String get menuMyPortal => 'My Portal';

  @override
  String get menuAccounts => 'Accounts';

  @override
  String get menuJournal => 'Journal';

  @override
  String get menuSectionGeneral => 'General';

  @override
  String get menuSectionHr => 'Human Resources';

  @override
  String get menuSectionEmployee => 'Employee';

  @override
  String get menuSectionAccounting => 'Accounting';

  @override
  String get menuSectionAccount => 'Account';

  @override
  String get sessionMissing => 'Session missing.';

  @override
  String get tooltipApprovals => 'Approvals';

  @override
  String get tooltipSearch => 'Search';

  @override
  String get searchInSystem => 'Search in system...';

  @override
  String get noResults => 'No results found';

  @override
  String get pageCreateEmployee => 'Create Employee';

  @override
  String get dimahErp => 'Dimah ERP';

  @override
  String get expand => 'Expand';

  @override
  String get collapse => 'Collapse';

  @override
  String get expandSidebar => 'Expand Sidebar';

  @override
  String get collapseSidebar => 'Collapse Sidebar';

  @override
  String get homeTitle => 'Home';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleHr => 'HR';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleAccountant => 'Accountant';

  @override
  String get roleEmployee => 'Employee';

  @override
  String get clear => 'Clear';

  @override
  String get back => 'Back';

  @override
  String get employeeProfileNotLinked => 'Employee profile is not linked.';

  @override
  String get myTasks => 'My Tasks';

  @override
  String get myAttendance => 'My Attendance';

  @override
  String get myLeaves => 'My Leaves';

  @override
  String get myRequests => 'My Requests';

  @override
  String failedToLoadTasks(Object error) {
    return 'Failed to load tasks: $error';
  }

  @override
  String get noTasksAssigned => 'No tasks assigned yet.';

  @override
  String get status => 'Status';

  @override
  String get statusTodo => 'To Do';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusDone => 'Done';

  @override
  String progressLabel(int progress) {
    return 'Progress: $progress%';
  }

  @override
  String get finish => 'Finish';

  @override
  String get next => 'Next';

  @override
  String get stepPersonalInfo => 'Personal Info';

  @override
  String get stepJobInfo => 'Job Info';

  @override
  String get stepCompensation => 'Compensation';

  @override
  String get department => 'Department';

  @override
  String get departmentRequired => 'Department is required';

  @override
  String get directManagerOptional => 'Direct Manager (optional)';

  @override
  String get noDirectManager => 'No direct manager';

  @override
  String get jobTitleRequired => 'Job title is required';

  @override
  String get selectDepartmentFirst => 'Select a department first.';

  @override
  String get noJobTitlesForDepartment => 'No job titles for this department';

  @override
  String get hireDate => 'Hire Date';

  @override
  String get hireDateRequired => 'Hire date is required';

  @override
  String get contractType => 'Contract Type';

  @override
  String get contractFullTime => 'Full Time';

  @override
  String get contractPartTime => 'Part Time';

  @override
  String get contractContractor => 'Contractor';

  @override
  String get contractIntern => 'Intern';

  @override
  String get contractStart => 'Contract Start';

  @override
  String get contractEnd => 'Contract End';

  @override
  String get probationMonths => 'Probation Months';

  @override
  String get selectDate => 'Select date';

  @override
  String get basicSalaryRequired => 'Basic Salary *';

  @override
  String get basicSalaryValidationRequired => 'Basic salary is required';

  @override
  String get housingAllowance => 'Housing Allowance';

  @override
  String get transportAllowance => 'Transport Allowance';

  @override
  String get otherAllowance => 'Other Allowance';

  @override
  String get bankName => 'Bank Name';

  @override
  String get iban => 'IBAN';

  @override
  String get accountNumber => 'Account Number';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get paymentMethodBank => 'Bank';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get total => 'Total';

  @override
  String amountSar(Object amount) {
    return '$amount SAR';
  }

  @override
  String get searchEmployeesHint => 'Search name, email, or phone...';

  @override
  String get all => 'All';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get nameAsc => 'Name ↑';

  @override
  String get nameDesc => 'Name ↓';

  @override
  String get sortName => 'Sort Name';

  @override
  String get createdAsc => 'Created ↑';

  @override
  String get createdDesc => 'Created ↓';

  @override
  String get sortCreated => 'Sort Created';

  @override
  String get addEmployee => 'Add Employee';

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get created => 'Created';

  @override
  String get actions => 'Actions';

  @override
  String get openProfile => 'Open Profile';

  @override
  String get noEmployeesFound => 'No employees found.';

  @override
  String totalWithValue(int total) {
    return 'Total: $total';
  }

  @override
  String pageWithValue(int page, int totalPages) {
    return 'Page: $page / $totalPages';
  }

  @override
  String get previous => 'Previous';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get fullNameTooShort => 'Full name is too short';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get phoneRequired => 'Phone is required';

  @override
  String get phoneTooShort => 'Phone number is too short';

  @override
  String get nationalId => 'National ID';

  @override
  String get nationalIdRequired => 'National ID is required';

  @override
  String get nationalIdTooShort => 'National ID is too short';

  @override
  String get nationality => 'Nationality';

  @override
  String get maritalStatus => 'Marital Status';

  @override
  String get single => 'Single';

  @override
  String get married => 'Married';

  @override
  String get divorced => 'Divorced';

  @override
  String get widowed => 'Widowed';

  @override
  String get address => 'Address';

  @override
  String get city => 'City';

  @override
  String get country => 'Country';

  @override
  String get passportNumber => 'Passport Number';

  @override
  String get educationLevel => 'Education Level';

  @override
  String get highSchool => 'High School';

  @override
  String get diploma => 'Diploma';

  @override
  String get bachelor => 'Bachelor';

  @override
  String get master => 'Master';

  @override
  String get phd => 'PhD';

  @override
  String get major => 'Major';

  @override
  String get university => 'University';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get genderRequired => 'Gender is required';

  @override
  String get picking => 'Picking...';

  @override
  String get selectEmployeePhoto => 'Select Employee Photo';

  @override
  String get photoTooLargeMax5Mb => 'Photo is too large. Max size is 5 MB.';

  @override
  String get unableAccessSelectedFilePath =>
      'Unable to access selected file path on this platform.';

  @override
  String get photoSelectedUploadAfterCreate =>
      'Photo selected. You can upload it after employee creation from profile edit.';

  @override
  String photoUploadFailed(Object error) {
    return 'Photo upload failed: $error';
  }

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get passportExpiry => 'Passport Expiry';

  @override
  String get searchEmployeeHint => 'Search employee...';

  @override
  String get attendancePresent => 'Present';

  @override
  String get attendanceLate => 'Late';

  @override
  String get attendanceAbsent => 'Absent';

  @override
  String get attendanceOnLeave => 'On Leave';

  @override
  String get filterDate => 'Filter Date';

  @override
  String get dateAsc => 'Date (Asc)';

  @override
  String get dateDesc => 'Date (Desc)';

  @override
  String get sortDate => 'Sort Date';

  @override
  String get importCsv => 'Import CSV';

  @override
  String get addAttendance => 'Add Attendance';

  @override
  String get noAttendanceRecordsFound => 'No attendance records found.';

  @override
  String get employee => 'Employee';

  @override
  String get date => 'Date';

  @override
  String get checkIn => 'Check In';

  @override
  String get checkOut => 'Check Out';

  @override
  String get overtime => 'Overtime';

  @override
  String get notes => 'Notes';

  @override
  String get requestCorrection => 'Request Correction';

  @override
  String entitlementWithValue(Object value) {
    return 'Entitlement: $value';
  }

  @override
  String usedWithValue(Object value) {
    return 'Used: $value';
  }

  @override
  String remainingWithValue(Object value) {
    return 'Remaining: $value';
  }

  @override
  String get statusPending => 'Pending';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get allTypes => 'All Types';

  @override
  String get leaveTypeAnnual => 'Annual';

  @override
  String get leaveTypeSick => 'Sick';

  @override
  String get leaveTypeUnpaid => 'Unpaid';

  @override
  String get leaveTypeOther => 'Other';

  @override
  String get startFrom => 'Start From';

  @override
  String get endTo => 'End To';

  @override
  String get startAsc => 'Start (Asc)';

  @override
  String get startDesc => 'Start (Desc)';

  @override
  String get sortStart => 'Sort Start';

  @override
  String get addLeave => 'Add Leave';

  @override
  String get noLeaveRequestsFound => 'No leave requests found.';

  @override
  String get type => 'Type';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get action => 'Action';

  @override
  String get resubmit => 'Resubmit';

  @override
  String get unknown => 'Unknown';

  @override
  String get noApprovalsFound => 'No approvals found.';

  @override
  String get pendingWith => 'Pending With';

  @override
  String get details => 'Details';

  @override
  String get view => 'View';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get processedApproved => 'Processed (Approved)';

  @override
  String get processedRejected => 'Processed (Rejected)';

  @override
  String get directManager => 'Direct Manager';

  @override
  String get rejectRequest => 'Reject Request';

  @override
  String get reasonOptional => 'Reason (optional)';

  @override
  String get requestDetails => 'Request Details';

  @override
  String get reason => 'Reason';

  @override
  String get file => 'File';

  @override
  String get openAttachment => 'Open Attachment';

  @override
  String get openDocument => 'Open Document';

  @override
  String get close => 'Close';

  @override
  String get invalidAttachmentUrl => 'Invalid attachment URL';

  @override
  String get unableOpenAttachment => 'Unable to open attachment';

  @override
  String get leave => 'Leave';

  @override
  String get assignedToMe => 'Assigned To Me';

  @override
  String get draft => 'Draft';

  @override
  String get finalized => 'Finalized';

  @override
  String get posted => 'Posted';

  @override
  String get newPayrollRun => 'New Payroll Run';

  @override
  String get noPayrollRunsFound => 'No payroll runs found.';

  @override
  String get periodStart => 'Period Start';

  @override
  String get periodEnd => 'Period End';

  @override
  String get employeesCount => 'Employees';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get finalize => 'Finalize';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get payrollRunItems => 'Payroll Run Items';

  @override
  String get payrollRunFinalized => 'Payroll run finalized';

  @override
  String get basic => 'Basic';

  @override
  String get housing => 'Housing';

  @override
  String get transport => 'Transport';

  @override
  String get other => 'Other';

  @override
  String get totalAllCaps => 'TOTAL';

  @override
  String csvSavedTo(Object path) {
    return 'CSV saved to $path';
  }

  @override
  String exportFailed(Object error) {
    return 'Export failed: $error';
  }

  @override
  String get noPayrollItemsFound => 'No payroll items found.';

  @override
  String get create => 'Create';

  @override
  String get add => 'Add';

  @override
  String get startEndDatesRequired => 'Start and end dates are required';

  @override
  String get endDateAfterStart => 'End date must be after start date';

  @override
  String get pickStartDate => 'Pick start date';

  @override
  String get pickEndDate => 'Pick end date';

  @override
  String get searchCodeOrName => 'Search code or name...';

  @override
  String get accountTypeAsset => 'Asset';

  @override
  String get accountTypeLiability => 'Liability';

  @override
  String get accountTypeEquity => 'Equity';

  @override
  String get accountTypeIncome => 'Income';

  @override
  String get accountTypeExpense => 'Expense';

  @override
  String get codeAsc => 'Code (Asc)';

  @override
  String get codeDesc => 'Code (Desc)';

  @override
  String get sortCode => 'Sort Code';

  @override
  String get addAccount => 'Add Account';

  @override
  String get noAccountsFound => 'No accounts found.';

  @override
  String get code => 'Code';

  @override
  String get codeRequired => 'Code is required';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get newEntry => 'New Entry';

  @override
  String get noJournalEntriesFound => 'No journal entries found.';

  @override
  String get memo => 'Memo';

  @override
  String get debit => 'Debit';

  @override
  String get credit => 'Credit';

  @override
  String get account => 'Account';

  @override
  String get debitOrCreditRequired => 'Debit or Credit is required';

  @override
  String get dateRequired => 'Date is required';

  @override
  String get addAtLeastOneLine => 'Add at least one line';

  @override
  String get debitsMustEqualCredits => 'Debits must equal credits';

  @override
  String get newJournalEntry => 'New Journal Entry';

  @override
  String get pickDate => 'Pick date';

  @override
  String get employeeProfileTitle => 'Employee Profile';

  @override
  String get failedToLoadEmployeeProfile => 'Failed to load employee profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get personal => 'Personal';

  @override
  String get passportNo => 'Passport No';

  @override
  String get residencyIssueDate => 'Residency Issue Date';

  @override
  String get residencyExpiryDate => 'Residency Expiry Date';

  @override
  String get insuranceStartDate => 'Insurance Start Date';

  @override
  String get insuranceExpiryDate => 'Insurance Expiry Date';

  @override
  String get insuranceProvider => 'Insurance Provider';

  @override
  String get insurancePolicyNo => 'Insurance Policy No';

  @override
  String get basicInfo => 'Basic';

  @override
  String get basicSalary => 'Basic Salary';

  @override
  String get totalCompensation => 'Total Compensation';

  @override
  String get compensationHistory => 'Compensation History';

  @override
  String get noCompensationHistory => 'No compensation history';

  @override
  String get financial => 'Financial';

  @override
  String get contract => 'Contract';

  @override
  String get addCompensationVersion => 'Add Compensation Version';

  @override
  String get addContractVersion => 'Add Contract Version';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get probationMonthsLabel => 'Probation (months)';

  @override
  String get openContractFile => 'Open Contract File';

  @override
  String get contractHistory => 'Contract History';

  @override
  String get noContractHistory => 'No contract history';

  @override
  String get open => 'Open';

  @override
  String get preview => 'Preview';

  @override
  String get documents => 'Documents';

  @override
  String get noDocumentsUploaded => 'No documents uploaded';

  @override
  String get invalidUrl => 'Invalid URL';

  @override
  String get unableOpenFile => 'Unable to open file';

  @override
  String htmlSavedTo(Object path) {
    return 'HTML saved to $path';
  }

  @override
  String get editEmployeeProfile => 'Edit Employee Profile';

  @override
  String get pickingPhoto => 'Picking photo...';

  @override
  String get selectPhoto => 'Select Photo';

  @override
  String get uploadingPhoto => 'Uploading photo...';

  @override
  String get residencyIssue => 'Residency Issue';

  @override
  String get residencyExpiry => 'Residency Expiry';

  @override
  String get insuranceStart => 'Insurance Start';

  @override
  String get insuranceExpiry => 'Insurance Expiry';

  @override
  String get contractFileUrl => 'Contract File URL';

  @override
  String get saving => 'Saving...';

  @override
  String get photoUploadedSuccessfully => 'Photo uploaded successfully';

  @override
  String get contractTypeRequired => 'Contract type is required';

  @override
  String get contractFileUrlOptional => 'Contract File URL (optional)';

  @override
  String get startDateRequired => 'Start date is required';

  @override
  String get effectiveDate => 'Effective Date';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String fieldRequired(Object field) {
    return '$field is required';
  }

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String pdfSavedTo(Object path) {
    return 'PDF saved to $path';
  }

  @override
  String get employeeFullReport => 'Employee Full Report';

  @override
  String reportGenerated(Object value) {
    return 'Generated: $value';
  }

  @override
  String get employeeId => 'Employee ID';

  @override
  String get issued => 'Issued';

  @override
  String get expires => 'Expires';

  @override
  String get urlLabel => 'URL';

  @override
  String get failedToLoadHrDashboard => 'Failed to load HR dashboard';

  @override
  String get hrDashboard => 'HR Dashboard';

  @override
  String get activeEmployeesKpi => 'Active Employees';

  @override
  String get currentHeadcount => 'Current headcount';

  @override
  String get pendingApprovalsKpi => 'Pending Approvals';

  @override
  String get expiryAlertsKpi => 'Expiry Alerts';

  @override
  String get expiredDocumentsKpi => 'Expired Documents';

  @override
  String get urgentAlertsKpi => 'Urgent Alerts';

  @override
  String get waitingHrAction => 'Waiting HR action';

  @override
  String get documentExpiryNeedsAction => 'Documents need HR action';

  @override
  String get onLeaveTodayKpi => 'On Leave Today';

  @override
  String get approvedLeaveToday => 'Approved leave today';

  @override
  String get noCheckInTodayKpi => 'No Check-in Today';

  @override
  String get activeStaffNotCheckedIn => 'Active staff not checked in';

  @override
  String get leavesThisMonthKpi => 'Leaves This Month';

  @override
  String get approvedLeaveRequests => 'Approved leave requests';

  @override
  String get pendingRequestsTop10 => 'Pending Requests (Top 10)';

  @override
  String get noPendingRequests => 'No pending requests.';

  @override
  String get expiringDocuments30Days => 'Expiring Documents (30 days)';

  @override
  String get noDocumentExpiries30Days =>
      'No document expiries in next 30 days.';

  @override
  String get documentLabel => 'Document';

  @override
  String get productivity => 'Productivity';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get hrWorkflowBoard => 'HR Workflow Board';

  @override
  String get reviewPendingApprovals => 'Review Pending Approvals';

  @override
  String get pendingTaskReviews => 'Pending Task Reviews';

  @override
  String get pendingTaskQa => 'Pending Final QA';

  @override
  String get noPendingTaskReviews => 'No pending task reviews.';

  @override
  String get noPendingTaskQa => 'No tasks pending final QA.';

  @override
  String get requestManagerReview => 'Request Manager Review';

  @override
  String get reviewPending => 'Review Pending';

  @override
  String get reviewApproved => 'Review Approved';

  @override
  String get reviewRejected => 'Review Rejected';

  @override
  String get noActiveReview => 'No Active Review';

  @override
  String get reviewNote => 'Review Note';

  @override
  String get reviewNoteRequired => 'Review note is required';

  @override
  String get reviewRequestedAt => 'Review requested at';

  @override
  String get yourReviewNote => 'Your note';

  @override
  String get managerResponseNote => 'Manager response';

  @override
  String get reviewRequestSent => 'Review request sent';

  @override
  String get approveAndUpdate => 'Approve and Update';

  @override
  String get rejectReviewRequest => 'Reject Review Request';

  @override
  String get reviewApprovedAndTaskUpdated => 'Review approved and task updated';

  @override
  String get reviewRejectedAndReturned => 'Review rejected and task returned';

  @override
  String get taskEventReviewRequested => 'Review requested';

  @override
  String get taskEventReviewApproved => 'Review approved';

  @override
  String get taskEventReviewRejected => 'Review rejected';

  @override
  String get taskEventQaAccepted => 'QA accepted';

  @override
  String get taskEventQaRework => 'QA sent for rework';

  @override
  String get taskEventQaRejected => 'QA rejected';

  @override
  String get taskEventAttachmentAdded => 'Attachment added';

  @override
  String get taskEventTimeLogged => 'Time logged';

  @override
  String get send => 'Send';

  @override
  String get attachFile => 'Attach File';

  @override
  String get logHours => 'Log Hours';

  @override
  String get logHoursTitle => 'Log Hours';

  @override
  String get loggedHours => 'Logged Hours';

  @override
  String get invalidLoggedHours => 'Please enter a valid logged hours value.';

  @override
  String get hoursLoggedSuccessfully => 'Hours logged successfully';

  @override
  String get attachments => 'Attachments';

  @override
  String attachmentsCount(int count) {
    return '$count attachments';
  }

  @override
  String get allTasks => 'All Tasks';

  @override
  String get attachmentUploaded => 'Attachment uploaded';

  @override
  String get qaPending => 'QA Pending';

  @override
  String get qaAccepted => 'QA Accepted';

  @override
  String get qaRework => 'Needs Rework';

  @override
  String get qaRejected => 'QA Rejected';

  @override
  String get qaApprove => 'Approve';

  @override
  String get qaSendRework => 'Send Rework';

  @override
  String get qaReject => 'Reject';

  @override
  String get qaApprovedMessage => 'Task approved in final QA';

  @override
  String get qaReworkMessage => 'Task sent back for rework';

  @override
  String get qaRejectedMessage => 'Task rejected in final QA';

  @override
  String qaLabel(Object status) {
    return 'QA: $status';
  }

  @override
  String get employeeActionCenter => 'Action Center';

  @override
  String get employeeNotifications => 'Notifications';

  @override
  String get noEmployeeNotifications => 'No notifications right now.';

  @override
  String get taskDueSoon => 'Task due soon';

  @override
  String reviewPendingWithValue(int value) {
    return 'Review pending: $value';
  }

  @override
  String qaPendingWithValue(int value) {
    return 'QA pending: $value';
  }

  @override
  String dueSoonWithValue(int value) {
    return 'Due soon: $value';
  }

  @override
  String get resolveExpiryAlerts => 'Resolve Expiry Alerts';

  @override
  String get completeEmployeeDocuments => 'Complete Employee Documents';

  @override
  String get documentCompliance => 'Document Compliance';

  @override
  String get expiringDocumentsByType => 'Expiring Documents by Type';

  @override
  String get expiringWithin30Days => 'Expiring within 30 days';

  @override
  String get todayAttendanceInsights => 'Today Attendance Insights';

  @override
  String get attendanceAlertsToday => 'Attendance Alerts Today';

  @override
  String get noAttendanceInsightsToday => 'No attendance insights for today.';

  @override
  String get noAttendanceAlertsToday => 'No attendance alerts for today.';

  @override
  String get checkedInTodayLabel => 'Checked In Today';

  @override
  String get absentTodayLabel => 'Absent Today';

  @override
  String pendingWithValue(int value) {
    return 'Pending: $value';
  }

  @override
  String doneWithValue(int value) {
    return 'Done: $value';
  }

  @override
  String get recentTasks => 'Recent Tasks';

  @override
  String get noTasksAssignedYet => 'No tasks assigned yet.';

  @override
  String get teamProductivity => 'Team Productivity';

  @override
  String tasksWithValue(int value) {
    return 'Tasks: $value';
  }

  @override
  String get assignTask => 'Assign Task';

  @override
  String get taskTitle => 'Task Title';

  @override
  String get dueDateLabel => 'Due Date';

  @override
  String get dueDateOptional => 'Due Date (optional)';

  @override
  String get assigning => 'Assigning...';

  @override
  String get taskAssigned => 'Task assigned';

  @override
  String assignFailed(Object error) {
    return 'Assign failed: $error';
  }

  @override
  String get searchNameOrCodeHint => 'Search name or code...';

  @override
  String get addDepartment => 'Add Department';

  @override
  String get noManagerChangesNeeded => 'No manager changes were needed.';

  @override
  String assignedUpdatedManagers(int count) {
    return 'Assigned/updated managers for $count department(s).';
  }

  @override
  String autoAssignFailed(Object error) {
    return 'Auto assign failed: $error';
  }

  @override
  String get autoAssignManagers => 'Auto Assign Managers';

  @override
  String get manager => 'Manager';

  @override
  String get edit => 'Edit';

  @override
  String get download => 'Download';

  @override
  String get delete => 'Delete';

  @override
  String get disable => 'Disable';

  @override
  String get enable => 'Enable';

  @override
  String get noDepartmentsFound => 'No departments found.';

  @override
  String get noJobTitlesFound => 'No job titles found.';

  @override
  String get editJobTitle => 'Edit Job Title';

  @override
  String get requiredField => 'Required';

  @override
  String get codeOptional => 'Code (optional)';

  @override
  String get levelOptional => 'Level (optional)';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get addJobTitle => 'Add Job Title';

  @override
  String get sortLevel => 'Sort Level';

  @override
  String get levelAsc => 'Level ?';

  @override
  String get levelDesc => 'Level ?';

  @override
  String get id => 'ID';

  @override
  String get passport => 'Passport';

  @override
  String get addDocument => 'Add Document';

  @override
  String get noDocumentsFound => 'No documents found.';

  @override
  String get invalidFileUrl => 'Invalid file URL';

  @override
  String get editDepartment => 'Edit Department';

  @override
  String get unableToLoadManagers => 'Unable to load managers';

  @override
  String get departmentManager => 'Department Manager';

  @override
  String get noManager => 'No manager';

  @override
  String get employeeRequired => 'Employee is required';

  @override
  String get documentType => 'Document Type';

  @override
  String get documentTypeRequired => 'Document type is required';

  @override
  String get fileUrl => 'File URL';

  @override
  String get fileUrlRequired => 'File URL is required';

  @override
  String get fileRequired => 'File is required';

  @override
  String get uploading => 'Uploading...';

  @override
  String get uploadPdf => 'Upload PDF';

  @override
  String get uploadingDocument => 'Uploading document...';

  @override
  String get savingDocument => 'Saving document...';

  @override
  String get issuedDate => 'Issued Date';

  @override
  String get expiresDate => 'Expires Date';

  @override
  String get fileUploadedSuccessfully => 'File uploaded successfully';

  @override
  String fileUploadFailed(Object error) {
    return 'File upload failed: $error';
  }

  @override
  String get employeeDocsStorageUnauthorized =>
      'Employee documents storage is not configured yet. Run the employee docs bucket SQL first.';

  @override
  String get editDocument => 'Edit Document';

  @override
  String get deleteDocument => 'Delete Document';

  @override
  String get deleteDocumentConfirm =>
      'Are you sure you want to delete this document?';

  @override
  String get documentUpdated => 'Document updated successfully';

  @override
  String get documentDeleted => 'Document deleted successfully';

  @override
  String fileSavedTo(Object path) {
    return 'File saved to: $path';
  }

  @override
  String fileDownloadFailed(Object error) {
    return 'File download failed: $error';
  }

  @override
  String get notAuthenticated => 'Not authenticated';

  @override
  String get level => 'Level';

  @override
  String get checkInCoverage => 'Check-in Coverage';

  @override
  String get approvalLoad => 'Approval Load';

  @override
  String get teamMembers => 'Team Members';

  @override
  String get openTasks => 'Open Tasks';

  @override
  String get overdueTasks => 'Overdue Tasks';

  @override
  String get completionRate => 'Completion Rate';

  @override
  String get dueSoonTasks => 'Due Soon (7 days)';

  @override
  String get noDueSoonTasks => 'No tasks due in the next 7 days.';

  @override
  String get topPerformers => 'Top 5 Performers';

  @override
  String get needsAttention => 'Needs Attention';

  @override
  String get noTeamDataYet => 'No team data yet.';

  @override
  String get taskTimeline => 'Task Timeline';

  @override
  String get assignedToEmployeeAt => 'Assigned to employee at';

  @override
  String get employeeReceivedAt => 'Employee received task at';

  @override
  String get employeeStartedAt => 'Employee started task at';

  @override
  String get completedAtLabel => 'Completed at';

  @override
  String get lastUpdateAt => 'Last update at';

  @override
  String get updatesTimeline => 'Updates Timeline';

  @override
  String get taskEventAssigned => 'Assigned';

  @override
  String get taskEventStatusChanged => 'Status changed';

  @override
  String get taskEventProgressUpdated => 'Progress updated';

  @override
  String get estimateHours => 'Estimated Hours';

  @override
  String get priority => 'Priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get taskWeight => 'Task Weight';

  @override
  String get invalidEstimateHours =>
      'Please enter a valid estimated hours value.';

  @override
  String get taskType => 'Task Type';

  @override
  String get taskCatalog => 'Task Catalog';

  @override
  String taskCatalogForDepartment(Object department) {
    return '$department task catalog';
  }

  @override
  String get taskTemplate => 'Task Template';

  @override
  String get taskTypeGeneral => 'General';

  @override
  String get taskTypeDevelopment => 'Development';

  @override
  String get taskTypeBugFix => 'Bug Fix';

  @override
  String get taskTypeTesting => 'Testing';

  @override
  String get taskTypeSupport => 'Support';

  @override
  String get taskTypeTransfer => 'Transfer';

  @override
  String get taskTypeReport => 'Report';

  @override
  String get taskTypeTax => 'Tax';

  @override
  String get taskTypePayroll => 'Payroll';

  @override
  String get taskTypeReconciliation => 'Reconciliation';

  @override
  String get taskTypeRecruitment => 'Recruitment';

  @override
  String get taskTypeOnboarding => 'Onboarding';

  @override
  String get taskTypeEmployeeDocs => 'Employee Documents';

  @override
  String get templateLoginSignup => 'Login and signup delivery';

  @override
  String get templateLoginSignupDesc =>
      'Build and complete the login and signup flow with validation, state handling, and final QA.';

  @override
  String get templateBugFixRelease => 'Release blocker bug fix';

  @override
  String get templateBugFixReleaseDesc =>
      'Investigate the blocker, apply the fix, validate affected flows, and prepare the release notes.';

  @override
  String get templateRegressionTesting => 'Regression testing cycle';

  @override
  String get templateRegressionTestingDesc =>
      'Run the assigned regression checklist, document findings, and retest the resolved issues.';

  @override
  String get templateTransferBatch => 'Transfer batch processing';

  @override
  String get templateTransferBatchDesc =>
      'Process the assigned transfers, verify amounts, and log completion status for each transaction.';

  @override
  String get templateMonthlyFinanceReport => 'Monthly finance report';

  @override
  String get templateMonthlyFinanceReportDesc =>
      'Prepare the monthly finance report, review the source numbers, and submit the final summary.';

  @override
  String get templateTaxSubmission => 'Tax submission package';

  @override
  String get templateTaxSubmissionDesc =>
      'Prepare tax data, validate required documents, and submit the filing package before the deadline.';

  @override
  String get templateOnboardingPack => 'Employee onboarding pack';

  @override
  String get templateOnboardingPackDesc =>
      'Collect, review, and complete the onboarding checklist and required employee documents.';

  @override
  String get templateDocumentAudit => 'Employee document audit';

  @override
  String get templateDocumentAuditDesc =>
      'Review the employee document set, flag missing items, and update expiry-sensitive files.';

  @override
  String get templateRecruitmentFollowup => 'Recruitment follow-up';

  @override
  String get templateRecruitmentFollowupDesc =>
      'Follow up on the assigned candidates, update statuses, and move the pipeline forward.';

  @override
  String get templateGeneralFollowup => 'General follow-up task';

  @override
  String get templateGeneralFollowupDesc =>
      'Track the assigned work item, update the status, and close the task on time.';

  @override
  String get monthDepartmentOverview => 'Monthly Department Overview';

  @override
  String get monthTasksCreated => 'Tasks created this month';

  @override
  String get monthTasksCompleted => 'Tasks completed this month';

  @override
  String get monthOnTimeRate => 'On-time completion';

  @override
  String get monthDepartmentProductivity => 'Department productivity';

  @override
  String get monthCompletionRate => 'Completion rate';

  @override
  String get monthlyCompletionTrend => 'Monthly Completion Trend';

  @override
  String get lastSixMonths => 'Last 6 months';

  @override
  String get onTimeVsDelayed => 'On-time vs Delayed';

  @override
  String get taskTypeDistribution => 'Task Type Distribution';

  @override
  String get employeeWorkload => 'Employee Workload';

  @override
  String get currentMonthBreakdown => 'Current month breakdown';

  @override
  String get onTime => 'On-time';

  @override
  String get delayed => 'Delayed';

  @override
  String monthTasksWithValue(int value) {
    return 'Month tasks: $value';
  }

  @override
  String completedThisMonthWithValue(int value) {
    return 'Completed this month: $value';
  }

  @override
  String avgTaskProgressWithValue(Object value) {
    return 'Avg progress: $value%';
  }

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get uploadNewDocument => 'Upload New Document';

  @override
  String get idCard => 'ID Card';

  @override
  String get graduationCert => 'Graduation Certificate';

  @override
  String get nationalAddress => 'National Address';

  @override
  String get bankIbanCertificate => 'Bank IBAN Certificate';

  @override
  String get salaryCertificate => 'Salary Certificate';

  @override
  String get identityDocuments => 'Identity Documents';

  @override
  String get educationAndCareerDocuments => 'Education and Career Documents';

  @override
  String get financialDocuments => 'Financial Documents';

  @override
  String get medicalAndInsuranceDocuments => 'Medical and Insurance Documents';

  @override
  String get otherDocuments => 'Other Documents';

  @override
  String get residencyDocument => 'Residency';

  @override
  String get drivingLicense => 'Driving License';

  @override
  String get offerLetter => 'Offer Letter';

  @override
  String get salaryDefinition => 'Salary Definition';

  @override
  String get medicalInsurance => 'Medical Insurance';

  @override
  String get medicalReport => 'Medical Report';

  @override
  String get expired => 'Expired';

  @override
  String get expiringSoon => 'Expiring Soon';

  @override
  String get valid => 'Valid';

  @override
  String get noExpiry => 'No Expiry';

  @override
  String get documentFile => 'Document';

  @override
  String get uploadFile => 'Upload File';

  @override
  String get noFileSelected => 'No file selected';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get failedToLoadNotifications => 'Failed to load notifications';

  @override
  String get noNotificationsAvailable => 'No notifications available.';
}
