import 'package:flutter/material.dart';

class AuthLinkErrorPage extends StatelessWidget {
  const AuthLinkErrorPage({
    super.key,
    required this.expired,
    required this.onContinue,
  });
  final bool expired;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.link_off,
                      size: 44,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ar
                          ? 'تعذّر استخدام رابط الاستعادة'
                          : 'Unable to use the recovery link',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      expired
                          ? (ar
                                ? 'الرابط غير صالح أو انتهت صلاحيته. اطلب رسالة استعادة جديدة، وافتح الرابط الموجود في أحدث رسالة مرة واحدة.'
                                : 'This link is invalid or has expired. Request a new recovery email and open the latest link once.')
                          : (ar
                                ? 'تعذّر التحقق من الرابط. تأكد من اتصال الإنترنت، ثم اطلب رسالة استعادة جديدة وافتح أحدث رابط.'
                                : 'The link could not be verified. Check your connection, then request a new recovery email and open the latest link.'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: onContinue,
                      child: Text(
                        ar ? 'متابعة إلى التطبيق' : 'Continue to the app',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
