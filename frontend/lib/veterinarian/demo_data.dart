/// Fictional records for the veterinarian reference screen. Never live data.
class DemoMetric {
  final String label;
  final String value;
  final String detail;
  const DemoMetric(this.label, this.value, this.detail);
}

class DemoCase {
  final String severity, animal, tag, elapsed, speciesSexAge, village, farmer, details;
  final List<String> symptoms;
  const DemoCase({required this.severity, required this.animal, required this.tag, required this.elapsed, required this.speciesSexAge, required this.village, required this.farmer, required this.details, required this.symptoms});
}

class DemoFollowup {
  final String id, title, detail;
  const DemoFollowup(this.id, this.title, this.detail);
}

const demoVetName = 'Dr. Ananya Rao';
const demoCredentials = 'DVM · Field veterinarian';
const demoAssignedArea = 'Assigned area: Kalyan block · Demo sector';
const demoPerimeter = 'Sector 4 · sample FMD & LSD buffer zone';
const demoMetrics = <DemoMetric>[DemoMetric('URGENT', '02', 'priority cases'), DemoMetric('QUEUE', '07', 'awaiting triage'), DemoMetric('VISITS', '2/4', 'demo route today')];
const demoCases = <DemoCase>[
  DemoCase(severity: 'Critical suspect', animal: 'Murrah buffalo', tag: 'BUF-204', elapsed: '18 min since sample', speciesSexAge: 'Female · 5 years', village: 'Kalyan hamlet (demo)', farmer: 'Farmer: Meera Devi (demo)', details: 'Reduced rumination with mild lameness; requires clinical review.', symptoms: ['Lameness', 'Low appetite', 'Warm muzzle']),
  DemoCase(severity: 'High contagion risk', animal: 'Crossbred heifer', tag: 'HFR-118', elapsed: '42 min since sample', speciesSexAge: 'Female · 2 years', village: 'Basant village (demo)', farmer: 'Farmer: Rakesh Kumar (demo)', details: 'Fever reported after transport; isolate pending examination.', symptoms: ['Fever', 'Tiredness', 'Nasal discharge']),
];
const demoRoutineVisit = 'Black Bengal goat · GOT-077\nKalyan hamlet · Sample visit: 3:30 PM';
const demoAnimals = <String>['BUF-204 · Murrah buffalo', 'HFR-118 · Crossbred heifer', 'GOT-077 · Black Bengal goat'];
const demoFollowups = <DemoFollowup>[DemoFollowup('mastitis', 'Mastitis Post-Antibiotic Check', 'BUF-204 · review response after treatment'), DemoFollowup('vaccination', 'Post-Vaccination Surveillance', 'GOT-077 · observe for routine signs')];
const demoHotspots = 2;
const demoNextStop = 'Next stop: Kalyan hamlet (demo)';
