import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// International dial-code picker + local-number field (ruling 2026-10-15).
///
/// The dial code is ALWAYS visible and user-selected — the system never
/// guesses a country from the raw digits (791472501 alone is ambiguous:
/// Kenya +254, Vietnam +84, …). The last successful phone login is
/// remembered locally and used as the default preselection.

class DialCodeOption {
  const DialCodeOption(this.iso2, this.dial, this.zh, this.en);
  final String iso2;
  final String dial; // without '+'
  final String zh;
  final String en;

  String get flag => String.fromCharCodes(
      iso2.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41));

  String label(Locale? locale) =>
      '$flag +$dial  ${locale?.languageCode == 'en' ? en : zh}';
}

/// Curated ITU dial codes (common markets first, then alphabetical-ish).
const List<DialCodeOption> kDialCodeOptions = [
  DialCodeOption('CN', '86', '中国', 'China'),
  DialCodeOption('KE', '254', '肯尼亚', 'Kenya'),
  DialCodeOption('HK', '852', '香港', 'Hong Kong'),
  DialCodeOption('TW', '886', '台湾', 'Taiwan'),
  DialCodeOption('SG', '65', '新加坡', 'Singapore'),
  DialCodeOption('JP', '81', '日本', 'Japan'),
  DialCodeOption('KR', '82', '韩国', 'South Korea'),
  DialCodeOption('IN', '91', '印度', 'India'),
  DialCodeOption('AE', '971', '阿联酋', 'UAE'),
  DialCodeOption('SA', '966', '沙特', 'Saudi Arabia'),
  DialCodeOption('TH', '66', '泰国', 'Thailand'),
  DialCodeOption('VN', '84', '越南', 'Vietnam'),
  DialCodeOption('MY', '60', '马来西亚', 'Malaysia'),
  DialCodeOption('ID', '62', '印尼', 'Indonesia'),
  DialCodeOption('PH', '63', '菲律宾', 'Philippines'),
  DialCodeOption('AU', '61', '澳大利亚', 'Australia'),
  DialCodeOption('GB', '44', '英国', 'United Kingdom'),
  DialCodeOption('DE', '49', '德国', 'Germany'),
  DialCodeOption('FR', '33', '法国', 'France'),
  DialCodeOption('IT', '39', '意大利', 'Italy'),
  DialCodeOption('ES', '34', '西班牙', 'Spain'),
  DialCodeOption('RU', '7', '俄罗斯', 'Russia'),
  DialCodeOption('BR', '55', '巴西', 'Brazil'),
  DialCodeOption('MX', '52', '墨西哥', 'Mexico'),
  DialCodeOption('ZA', '27', '南非', 'South Africa'),
  DialCodeOption('NG', '234', '尼日利亚', 'Nigeria'),
  DialCodeOption('EG', '20', '埃及', 'Egypt'),
];

/// In-process cache of the remembered dial code (warmed at boot from
/// SharedPreferences; written on successful phone login).
String? dialCodeMemoryCache;

const String _dialCodePrefsKey = 'last_login_dial_code';

Future<void> loadDialCodeMemory() async {
  final prefs = await SharedPreferences.getInstance();
  dialCodeMemoryCache = prefs.getString(_dialCodePrefsKey);
}

Future<void> saveDialCodeMemory(String dial) async {
  dialCodeMemoryCache = dial;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_dialCodePrefsKey, dial);
}

/// Best-effort preselection from the device timezone when nothing is
/// remembered. Falls back to +254 (current primary market).
String guessDialCode() {
  if (dialCodeMemoryCache != null) return dialCodeMemoryCache!;
  final hours = DateTime.now().timeZoneOffset.inHours;
  // 2 → +27 (South Africa, ruling 2026-10-19): UTC+2 had no entry so SA
  // devices fell through to the +254 fallback and phone logins 401'd.
  const byOffset = {3: '254', 8: '86', 4: '971', 2: '27', 0: '44', -5: '1', -3: '55', 9: '81', 10: '61', 7: '66', 5: '91'};
  return byOffset[hours] ?? '254';
}

DialCodeOption? dialOptionOf(String dial) {
  for (final o in kDialCodeOptions) {
    if (o.dial == dial) return o;
  }
  return null;
}

/// Longest dial-code prefix match from an E.164 string (without +), null if
/// none of the curated options match.
String? dialFromE164(String e164) {
  final noPlus = e164.startsWith('+') ? e164.substring(1) : e164;
  DialCodeOption? best;
  for (final o in kDialCodeOptions) {
    if (noPlus.startsWith(o.dial) &&
        (best == null || o.dial.length > best.dial.length)) {
      best = o;
    }
  }
  return best?.dial;
}

/// Merges dial code + local number into E.164. Numbers the user typed WITH
/// a leading + (or 00) are treated as already international and returned
/// as-is; a single leading trunk zero is dropped (e.g. KE 0712→712).
String mergeE164(String dial, String raw) {
  final v = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
  if (v.startsWith('+') || v.startsWith('00')) {
    return v.startsWith('+') ? v : '+${v.substring(2)}';
  }
  // Local number already begins with the selected dial (e.g. user types the
  // full 254791… under +254): only prepend the plus — never double the dial.
  if (dial.isNotEmpty && v.startsWith(dial)) {
    return '+$v';
  }
  var digits = v;
  while (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  return '+$dial$digits';
}

/// Login-identifier routing hint: pure digits (after separator removal) are
/// a phone number; anything starting with a letter or containing @ is not.
bool looksLikePhoneNumber(String raw) {
  final v = raw.trim();
  if (v.isEmpty) return false;
  if (v.contains('@')) return false;
  if (v.startsWith('+') || v.startsWith('00')) return true;
  if (RegExp(r'^[A-Za-z]').hasMatch(v)) return false; // account
  return RegExp(r'^[0-9][0-9 \-()]*$').hasMatch(v);
}

/// Dial-code picker + local number field. Stores the RAW local input in
/// [controller]; callers merge with [mergeE164] on submit.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    required this.dialCode,
    required this.onDialChanged,
    this.labelText,
    this.hintText,
    this.required_ = false,
    this.isDense = true,
  });

  final TextEditingController controller;
  final String dialCode;
  final ValueChanged<String> onDialChanged;
  final String? labelText;
  final String? hintText;
  final bool required_;
  final bool isDense;

  void _pickDialCode(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final o in kDialCodeOptions)
              ListTile(
                dense: true,
                title: Text(o.label(Localizations.localeOf(ctx))),
                trailing: o.dial == dialCode ? const Icon(Icons.check) : null,
                onTap: () {
                  onDialChanged(o.dial);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final option = dialOptionOf(dialCode);
    final dialLabel = option == null ? '+$dialCode' : option.label(Localizations.maybeLocaleOf(context));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: const Key('phone-dial-code'),
          onTap: () => _pickDialCode(context),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: 10, vertical: isDense ? 14 : 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Text(dialLabel, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 \-()+]')),
            ],
            decoration: InputDecoration(
              labelText: labelText,
              hintText: hintText,
              isDense: isDense,
              border: const OutlineInputBorder(),
            ),
            validator: required_
                ? (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入手机号' : null
                : null,
          ),
        ),
      ],
    );
  }
}
