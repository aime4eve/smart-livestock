/// Curated IANA timezone options for tenant/farm forms (ruling 2026-10-12).
/// Sorted roughly by offset for a readable dropdown; the entry matching the
/// device's current offset is preselected by the form.
library;

import 'package:flutter/material.dart';

class TimezoneOption {
  const TimezoneOption(this.name, this.offsetMinutes, this.label);
  final String name; // IANA id sent to the backend
  final int offsetMinutes; // standard offset (display hint only)
  final String label; // dropdown text
}

const List<TimezoneOption> kTimezoneOptions = [
  TimezoneOption('UTC', 0, 'UTC'),
  TimezoneOption('Europe/London', 0, 'London (UTC+0)'),
  TimezoneOption('Europe/Paris', 60, 'Paris (UTC+1)'),
  TimezoneOption('Europe/Berlin', 60, 'Berlin (UTC+1)'),
  TimezoneOption('Africa/Lagos', 60, 'Lagos (UTC+1)'),
  TimezoneOption('Africa/Johannesburg', 120, 'Johannesburg (UTC+2)'),
  TimezoneOption('Africa/Nairobi', 180, 'Nairobi (UTC+3)'),
  TimezoneOption('Asia/Dubai', 240, 'Dubai (UTC+4)'),
  TimezoneOption('Asia/Kolkata', 330, 'Mumbai (UTC+5:30)'),
  TimezoneOption('Asia/Shanghai', 480, 'Shanghai (UTC+8)'),
  TimezoneOption('Asia/Hong_Kong', 480, 'Hong Kong (UTC+8)'),
  TimezoneOption('Asia/Taipei', 480, 'Taipei (UTC+8)'),
  TimezoneOption('Asia/Singapore', 480, 'Singapore (UTC+8)'),
  TimezoneOption('Asia/Tokyo', 540, 'Tokyo (UTC+9)'),
  TimezoneOption('Asia/Seoul', 540, 'Seoul (UTC+9)'),
  TimezoneOption('Australia/Sydney', 600, 'Sydney (UTC+10)'),
  TimezoneOption('America/Sao_Paulo', -180, 'São Paulo (UTC-3)'),
  TimezoneOption('America/New_York', -300, 'New York (UTC-5)'),
  TimezoneOption('America/Chicago', -360, 'Chicago (UTC-6)'),
  TimezoneOption('America/Los_Angeles', -480, 'Los Angeles (UTC-8)'),
];

/// First curated option whose standard offset matches [offsetMinutes], if any.
TimezoneOption? optionForOffset(int offsetMinutes) {
  for (final option in kTimezoneOptions) {
    if (option.offsetMinutes == offsetMinutes) return option;
  }
  return null;
}

/// Dropdown items with the given preselection (device offset when null).
List<DropdownMenuItem<String>> timezoneDropdownItems({String? selected}) {
  return kTimezoneOptions.map((option) {
    return DropdownMenuItem<String>(
      value: option.name,
      child: Text(option.label,
          style: TextStyle(
              fontWeight: option.name == selected ? FontWeight.w600 : null)),
    );
  }).toList();
}
