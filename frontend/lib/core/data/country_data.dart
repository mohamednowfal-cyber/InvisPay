class Country {
  final String name;
  final String flag;
  final String code;
  final List<int> validLengths;

  const Country({
    required this.name,
    required this.flag,
    required this.code,
    required this.validLengths,
  });
}

const List<Country> topCountries = [
  // Pinned Top 10
  Country(name: 'India', flag: '🇮🇳', code: '+91', validLengths: [10]),
  Country(name: 'United States', flag: '🇺🇸', code: '+1', validLengths: [10]),
  Country(
      name: 'United Kingdom',
      flag: '🇬🇧',
      code: '+44',
      validLengths: [10, 11]),
  Country(name: 'Canada', flag: '🇨🇦', code: '+1', validLengths: [10]),
  Country(name: 'Australia', flag: '🇦🇺', code: '+61', validLengths: [9]),
  Country(
      name: 'United Arab Emirates',
      flag: '🇦🇪',
      code: '+971',
      validLengths: [9]),
  Country(name: 'Saudi Arabia', flag: '🇸🇦', code: '+966', validLengths: [9]),
  Country(name: 'Singapore', flag: '🇸🇬', code: '+65', validLengths: [8]),
  Country(name: 'Malaysia', flag: '🇲🇾', code: '+60', validLengths: [9, 10]),
  Country(name: 'Germany', flag: '🇩🇪', code: '+49', validLengths: [10, 11]),

  // Additional Major Countries
  Country(name: 'France', flag: '🇫🇷', code: '+33', validLengths: [9]),
  Country(name: 'Italy', flag: '🇮🇹', code: '+39', validLengths: [10]),
  Country(name: 'Spain', flag: '🇪🇸', code: '+34', validLengths: [9]),
  Country(name: 'Netherlands', flag: '🇳🇱', code: '+31', validLengths: [9]),
  Country(name: 'Sweden', flag: '🇸🇪', code: '+46', validLengths: [7, 9]),
  Country(name: 'Norway', flag: '🇳🇴', code: '+47', validLengths: [8]),
  Country(name: 'Denmark', flag: '🇩🇰', code: '+45', validLengths: [8]),
  Country(name: 'Switzerland', flag: '🇨🇭', code: '+41', validLengths: [9]),
  Country(name: 'Japan', flag: '🇯🇵', code: '+81', validLengths: [10, 11]),
  Country(
      name: 'South Korea',
      flag: '🇰🇷',
      code: '+82',
      validLengths: [9, 10, 11]),
  Country(name: 'China', flag: '🇨🇳', code: '+86', validLengths: [11]),
  Country(name: 'Hong Kong', flag: '🇭🇰', code: '+852', validLengths: [8]),
  Country(name: 'Thailand', flag: '🇹🇭', code: '+66', validLengths: [9]),
  Country(
      name: 'Indonesia',
      flag: '🇮🇩',
      code: '+62',
      validLengths: [9, 10, 11, 12]),
  Country(name: 'Philippines', flag: '🇵🇭', code: '+63', validLengths: [10]),
  Country(name: 'Vietnam', flag: '🇻🇳', code: '+84', validLengths: [9]),
  Country(name: 'Sri Lanka', flag: '🇱🇰', code: '+94', validLengths: [9]),
  Country(name: 'Bangladesh', flag: '🇧🇩', code: '+880', validLengths: [10]),
  Country(name: 'Pakistan', flag: '🇵🇰', code: '+92', validLengths: [10]),
  Country(name: 'Nepal', flag: '🇳🇵', code: '+977', validLengths: [10]),
  Country(
      name: 'New Zealand', flag: '🇳🇿', code: '+64', validLengths: [8, 9, 10]),
  Country(name: 'South Africa', flag: '🇿🇦', code: '+27', validLengths: [9]),
  Country(name: 'Nigeria', flag: '🇳🇬', code: '+234', validLengths: [10]),
  Country(name: 'Kenya', flag: '🇰🇪', code: '+254', validLengths: [9]),
  Country(name: 'Egypt', flag: '🇪🇬', code: '+20', validLengths: [10]),
  Country(name: 'Qatar', flag: '🇶🇦', code: '+974', validLengths: [8]),
  Country(name: 'Kuwait', flag: '🇰🇼', code: '+965', validLengths: [8]),
  Country(name: 'Oman', flag: '🇴🇲', code: '+968', validLengths: [8]),
  Country(name: 'Bahrain', flag: '🇧🇭', code: '+973', validLengths: [8]),
];
