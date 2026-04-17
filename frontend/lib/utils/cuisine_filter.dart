// lib/utils/cuisine_filter.dart
enum CuisineTag {
  korean,
  italian,
  japanese,
  chinese,
  mexican,
  spanish,
  american,
  bbq,
  steakhouse,
  european,
  asian,
  brunch,
  cafe,
  bar,
  vegan,
  fineDining,
  fusion,
  western,
}

class CuisineParseResult {
  final Set<CuisineTag> tags;
  final Set<String> badges; // Michelin guide 같은 표시용
  const CuisineParseResult(this.tags, this.badges);
}

CuisineParseResult parseCuisine(String raw) {
  final s = raw.toLowerCase();

  final tags = <CuisineTag>{};
  final badges = <String>{};

  if (s.contains('michelin')) badges.add('Michelin guide');

  if (s.contains('korean')) tags.add(CuisineTag.korean);
  if (s.contains('italian') || s.contains('neapolitan') || s.contains('trattoria') || s.contains('osteria')) {
    tags.add(CuisineTag.italian);
  }
  if (s.contains('japanese') || s.contains('gyukatsu')) tags.add(CuisineTag.japanese);
  if (s.contains('chinese')) tags.add(CuisineTag.chinese);
  if (s.contains('mexican')) tags.add(CuisineTag.mexican);
  if (s.contains('spanish') || s.contains('tapas')) tags.add(CuisineTag.spanish);
  if (s.contains('american')) tags.add(CuisineTag.american);

  if (s.contains('bbq')) tags.add(CuisineTag.bbq);
  if (s.contains('steak')) tags.add(CuisineTag.steakhouse);
  if (s.contains('european') || s.contains('french') || s.contains('bistro')) tags.add(CuisineTag.european);
  if (s.contains('asian')) tags.add(CuisineTag.asian);

  if (s.contains('brunch')) tags.add(CuisineTag.brunch);
  if (s.contains('café') || s.contains('cafe')) tags.add(CuisineTag.cafe);
  if (s.contains('bar') || s.contains('lounge')) tags.add(CuisineTag.bar);

  if (s.contains('vegan') || s.contains('plant-forward') || s.contains('plant forward')) tags.add(CuisineTag.vegan);
  if (s.contains('fine dining')) tags.add(CuisineTag.fineDining);

  if (s.contains('fusion') || s.contains('korean-italian') || s.contains('italian-american') || s.contains('korean-european')) {
    tags.add(CuisineTag.fusion);
  }
  if (s.contains('western-style') || s.contains('western style') || s.contains('western')) tags.add(CuisineTag.western);

  return CuisineParseResult(tags, badges);
}

CuisineTag? cuisineTagFromLabel(String label) {
  switch (label) {
    case 'Korean': return CuisineTag.korean;
    case 'Italian': return CuisineTag.italian;
    case 'Japanese': return CuisineTag.japanese;
    case 'Chinese': return CuisineTag.chinese;
    case 'Mexican': return CuisineTag.mexican;
    case 'Spanish': return CuisineTag.spanish;
    case 'American': return CuisineTag.american;
    case 'BBQ': return CuisineTag.bbq;
    case 'Steakhouse': return CuisineTag.steakhouse;
    case 'European': return CuisineTag.european;
    case 'Asian': return CuisineTag.asian;
    case 'Brunch': return CuisineTag.brunch;
    case 'Cafe': return CuisineTag.cafe;
    case 'Bar': return CuisineTag.bar;
    case 'Vegan': return CuisineTag.vegan;
    case 'Fine Dining': return CuisineTag.fineDining;
    case 'Fusion': return CuisineTag.fusion;
    case 'Western-style': return CuisineTag.western;
    default: return null; // All 등
  }
}