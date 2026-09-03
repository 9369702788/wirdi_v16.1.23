
class IslamicHistoryEvent {
  final int year;
  final String yearAH;
  final String event;
  final String description;
  
  const IslamicHistoryEvent({
    required this.year,
    required this.yearAH,
    required this.event,
    required this.description,
  });
}

class IslamicHistoryService {
  static const List<IslamicHistoryEvent> timeline = [
    IslamicHistoryEvent(
      year: 610,
      yearAH: '1 AH',
      event: 'Beginning of Revelation',
      description: 'Prophet Muhammad (PBUH) receives first revelation',
    ),
    IslamicHistoryEvent(
      year: 622,
      yearAH: '1 AH',
      event: 'Hijra',
      description: 'Migration from Mecca to Medina',
    ),
    IslamicHistoryEvent(
      year: 625,
      yearAH: '4 AH',
      event: 'Battle of Uhud',
      description: 'Second major battle between Muslims and Quraysh',
    ),
    IslamicHistoryEvent(
      year: 627,
      yearAH: '5 AH',
      event: 'Battle of the Trench',
      description: 'Siege of Medina by Quraysh coalition',
    ),
    IslamicHistoryEvent(
      year: 629,
      yearAH: '7 AH',
      event: 'Treaty of Hudaybiyyah',
      description: 'Peace treaty between Muslims and Quraysh',
    ),
    IslamicHistoryEvent(
      year: 632,
      yearAH: '11 AH',
      event: 'Farewell Pilgrimage',
      description: 'Last pilgrimage of Prophet Muhammad (PBUH)',
    ),
  ];
  
  static List<IslamicHistoryEvent> getTimelineEvents() {
    return timeline;
  }
}
