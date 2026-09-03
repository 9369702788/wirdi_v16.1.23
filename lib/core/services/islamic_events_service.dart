
class IslamicHistoricalEvent {
  final String name;
  final String nameAr;
  final String hijriDate;
  final String description;
  
  const IslamicHistoricalEvent({
    required this.name,
    required this.nameAr,
    required this.hijriDate,
    required this.description,
  });
}

class IslamicEventsService {
  static const List<IslamicHistoricalEvent> events = [
    IslamicHistoricalEvent(
      name: 'Ashura',
      nameAr: 'عاشوراء',
      hijriDate: '10 Muharram',
      description: 'The 10th day of Muharram',
    ),
    IslamicHistoricalEvent(
      name: 'Hijra',
      nameAr: 'الهجرة',
      hijriDate: '1 Muharram',
      description: 'Migration of Prophet to Medina',
    ),
  ];
}
