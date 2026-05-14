// lib/data/phone_codes.dart

class PhoneCountry {
  final String name;     // Display name
  final String isoCode;  // ISO 3166-1 alpha-2 (e.g., KR, FR, DE)
  final String dialCode; // E.164 country calling code (e.g., +82, +33)
  final int minLength;   // local/national significant number length (approx for MVP)
  final int maxLength;

  const PhoneCountry({
    required this.name,
    required this.isoCode,
    required this.dialCode,
    required this.minLength,
    required this.maxLength,
  });

  String get label => '$name $dialCode';
}

///
/// NOTE (MVP):
/// - min/max are approximate for “basic validity feedback”.
/// - Many countries have multiple valid lengths; we use a reasonable range.
/// - For production-grade validation, integrate libphonenumber.
///
const List<PhoneCountry> kPhoneCountries = [
  // -------------------------
  // North America
  // -------------------------
  PhoneCountry(name: 'United States', isoCode: 'US', dialCode: '+1', minLength: 10, maxLength: 10),
  PhoneCountry(name: 'Canada', isoCode: 'CA', dialCode: '+1', minLength: 10, maxLength: 10),
  PhoneCountry(name: 'Mexico', isoCode: 'MX', dialCode: '+52', minLength: 10, maxLength: 10),

  // -------------------------
  // South America
  // -------------------------
  PhoneCountry(name: 'Brazil', isoCode: 'BR', dialCode: '+55', minLength: 10, maxLength: 11),
  PhoneCountry(name: 'Argentina', isoCode: 'AR', dialCode: '+54', minLength: 10, maxLength: 11),
  PhoneCountry(name: 'Chile', isoCode: 'CL', dialCode: '+56', minLength: 9, maxLength: 9),
  PhoneCountry(name: 'Colombia', isoCode: 'CO', dialCode: '+57', minLength: 10, maxLength: 10),
  PhoneCountry(name: 'Peru', isoCode: 'PE', dialCode: '+51', minLength: 9, maxLength: 9),

  // -------------------------
  // Oceania
  // -------------------------
  PhoneCountry(name: 'Australia', isoCode: 'AU', dialCode: '+61', minLength: 9, maxLength: 9),
  PhoneCountry(name: 'New Zealand', isoCode: 'NZ', dialCode: '+64', minLength: 8, maxLength: 10),

  // -------------------------
  // Asia
  // -------------------------
  PhoneCountry(name: 'South Korea', isoCode: 'KR', dialCode: '+82', minLength: 9, maxLength: 11),
  PhoneCountry(name: 'Japan', isoCode: 'JP', dialCode: '+81', minLength: 9, maxLength: 10),
  PhoneCountry(name: 'China', isoCode: 'CN', dialCode: '+86', minLength: 11, maxLength: 11),
  PhoneCountry(name: 'Hong Kong', isoCode: 'HK', dialCode: '+852', minLength: 8, maxLength: 8),
  PhoneCountry(name: 'Taiwan', isoCode: 'TW', dialCode: '+886', minLength: 9, maxLength: 10),
  PhoneCountry(name: 'Singapore', isoCode: 'SG', dialCode: '+65', minLength: 8, maxLength: 8),
  PhoneCountry(name: 'Malaysia', isoCode: 'MY', dialCode: '+60', minLength: 9, maxLength: 10),
  PhoneCountry(name: 'Thailand', isoCode: 'TH', dialCode: '+66', minLength: 9, maxLength: 10),
  PhoneCountry(name: 'Vietnam', isoCode: 'VN', dialCode: '+84', minLength: 9, maxLength: 10),
  PhoneCountry(name: 'Philippines', isoCode: 'PH', dialCode: '+63', minLength: 10, maxLength: 10),
  PhoneCountry(name: 'Indonesia', isoCode: 'ID', dialCode: '+62', minLength: 9, maxLength: 12),
  PhoneCountry(name: 'India', isoCode: 'IN', dialCode: '+91', minLength: 10, maxLength: 10),
  PhoneCountry(name: 'Israel', isoCode: 'IL', dialCode: '+972', minLength: 9, maxLength: 9),
  PhoneCountry(name: 'United Arab Emirates', isoCode: 'AE', dialCode: '+971', minLength: 8, maxLength: 9),
  PhoneCountry(name: 'Saudi Arabia', isoCode: 'SA', dialCode: '+966', minLength: 9, maxLength: 9),
  PhoneCountry(name: 'Turkey', isoCode: 'TR', dialCode: '+90', minLength: 10, maxLength: 10),

  // -------------------------
  // Europe (major + widely used)
  // -------------------------
  PhoneCountry(name: 'United Kingdom', isoCode: 'GB', dialCode: '+44', minLength: 9, maxLength: 10),
  PhoneCountry(name: 'Ireland', isoCode: 'IE', dialCode: '+353', minLength: 9, maxLength: 9),

  PhoneCountry(name: 'France', isoCode: 'FR', dialCode: '+33', minLength: 9, maxLength: 9),
  PhoneCountry(name: 'Germany', isoCode: 'DE', dialCode: '+49', minLength: 10, maxLength: 11),
  PhoneCountry(name: 'Spain', isoCode: 'ES', dialCode: '+34', minLength: 9, maxLength: 9),
  PhoneCountry(name: 'Italy', isoCode: 'IT', dialCode: '+39', minLength: 9, maxLength: 10),
  PhoneCountry(name: 'Portugal', isoCode: 'PT', dialCode: '+351', minLength: 9, maxLength: 9),
  PhoneCountry(name: 'Netherlands', isoCode: 'NL', dialCode: '+31', minLength: 9, maxLength: 9),
  PhoneCountry(name: 'Belgium', isoCode: 'BE', dialCode: '+32', minLength: 9, maxLength: 9),
  PhoneCountry(name: 'Switzerland', isoCode: 'CH', dialCode: '+41', minLength: 9, maxLength: 9),
  PhoneCountry(name: 'Austria', isoCode: 'AT', dialCode: '+43', minLength: 10, maxLength: 13), // variable
  PhoneCountry(name: 'Sweden', isoCode: 'SE', dialCode: '+46', minLength: 7, maxLength: 10),
  PhoneCountry(name: 'Norway', isoCode: 'NO', dialCode: '+47', minLength: 8, maxLength: 8),
  PhoneCountry(name: 'Denmark', isoCode: 'DK', dialCode: '+45', minLength: 8, maxLength: 8),
  PhoneCountry(name: 'Finland', isoCode: 'FI', dialCode: '+358', minLength: 9, maxLength: 10),
  PhoneCountry(name: 'Iceland', isoCode: 'IS', dialCode: '+354', minLength: 7, maxLength: 7),

  PhoneCountry(name: 'Poland', isoCode: 'PL', dialCode: '+48', minLength: 9, maxLength: 9),
  PhoneCountry(name: 'Czechia', isoCode: 'CZ', dialCode: '+420', minLength: 9, maxLength: 9),
  PhoneCountry(name: 'Slovakia', isoCode: 'SK', dialCode: '+421', minLength: 9, maxLength: 9),
  PhoneCountry(name: 'Hungary', isoCode: 'HU', dialCode: '+36', minLength: 9, maxLength: 9),
  PhoneCountry(name: 'Romania', isoCode: 'RO', dialCode: '+40', minLength: 9, maxLength: 9),
  PhoneCountry(name: 'Bulgaria', isoCode: 'BG', dialCode: '+359', minLength: 8, maxLength: 9),

  PhoneCountry(name: 'Greece', isoCode: 'GR', dialCode: '+30', minLength: 10, maxLength: 10),
  PhoneCountry(name: 'Croatia', isoCode: 'HR', dialCode: '+385', minLength: 8, maxLength: 9),
  PhoneCountry(name: 'Slovenia', isoCode: 'SI', dialCode: '+386', minLength: 8, maxLength: 8),
  PhoneCountry(name: 'Serbia', isoCode: 'RS', dialCode: '+381', minLength: 8, maxLength: 9),
  PhoneCountry(name: 'Bosnia and Herzegovina', isoCode: 'BA', dialCode: '+387', minLength: 8, maxLength: 8),
  PhoneCountry(name: 'Montenegro', isoCode: 'ME', dialCode: '+382', minLength: 8, maxLength: 8),
  PhoneCountry(name: 'North Macedonia', isoCode: 'MK', dialCode: '+389', minLength: 8, maxLength: 8),
  PhoneCountry(name: 'Albania', isoCode: 'AL', dialCode: '+355', minLength: 9, maxLength: 9),

  PhoneCountry(name: 'Lithuania', isoCode: 'LT', dialCode: '+370', minLength: 8, maxLength: 8),
  PhoneCountry(name: 'Latvia', isoCode: 'LV', dialCode: '+371', minLength: 8, maxLength: 8),
  PhoneCountry(name: 'Estonia', isoCode: 'EE', dialCode: '+372', minLength: 7, maxLength: 8),

  PhoneCountry(name: 'Ukraine', isoCode: 'UA', dialCode: '+380', minLength: 9, maxLength: 9),
  PhoneCountry(name: 'Russia', isoCode: 'RU', dialCode: '+7', minLength: 10, maxLength: 10),
  PhoneCountry(name: 'Belarus', isoCode: 'BY', dialCode: '+375', minLength: 9, maxLength: 9),

  // -------------------------
  // Africa (some commonly used)
  // -------------------------
  PhoneCountry(name: 'South Africa', isoCode: 'ZA', dialCode: '+27', minLength: 9, maxLength: 9),
  PhoneCountry(name: 'Egypt', isoCode: 'EG', dialCode: '+20', minLength: 10, maxLength: 10),
  PhoneCountry(name: 'Nigeria', isoCode: 'NG', dialCode: '+234', minLength: 10, maxLength: 11),
  PhoneCountry(name: 'Kenya', isoCode: 'KE', dialCode: '+254', minLength: 9, maxLength: 9),
  PhoneCountry(name: 'Morocco', isoCode: 'MA', dialCode: '+212', minLength: 9, maxLength: 9),
];