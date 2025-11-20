import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_TW', null);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2026 年曆',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Calendar2026Page(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Calendar2026Page extends StatefulWidget {
  @override
  _Calendar2026PageState createState() => _Calendar2026PageState();
}

class _Calendar2026PageState extends State<Calendar2026Page> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final DateTime _firstDay = DateTime.utc(2026, 1, 1);
  final DateTime _lastDay = DateTime.utc(2026, 12, 31);
  DateTime _focusedDay = DateTime.utc(2026, 1, 1);
  DateTime? _selectedDay;

  final Map<int, File> _monthlyImages = {};
  final Map<int, Alignment> _monthlyImageAlignments = {};

  final Map<DateTime, String> _holidays = {
    DateTime.utc(2026, 1, 1): '元旦',
    DateTime.utc(2026, 2, 15): '小年夜',
    DateTime.utc(2026, 2, 16): '除夕',
    DateTime.utc(2026, 2, 17): '春節初一',
    DateTime.utc(2026, 2, 18): '春節初二',
    DateTime.utc(2026, 2, 19): '春節初三',
    DateTime.utc(2026, 2, 20): '春節補假',
    DateTime.utc(2026, 2, 27): '補假',
    DateTime.utc(2026, 2, 28): '和平紀念日',
    DateTime.utc(2026, 4, 3): '兒童節補假',
    DateTime.utc(2026, 4, 4): '兒童節',
    DateTime.utc(2026, 4, 5): '清明節',
    DateTime.utc(2026, 4, 6): '清明節補假',
    DateTime.utc(2026, 5, 1): '勞動節',
    DateTime.utc(2026, 6, 19): '端午節',
    DateTime.utc(2026, 9, 25): '中秋節',
    DateTime.utc(2026, 9, 28): '教師節',
    DateTime.utc(2026, 10, 9): '國慶日補假',
    DateTime.utc(2026, 10, 10): '國慶日',
    DateTime.utc(2026, 10, 25): '臺灣光復節',
    DateTime.utc(2026, 10, 26): '光復節補假',
    DateTime.utc(2026, 12, 25): '行憲紀念日',
  };

  late final Map<DateTime, List<String>> _events;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    _events = LinkedHashMap(
      equals: isSameDay,
      hashCode: getHashCode,
    );
  }

  int getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  String? _getHolidayName(DateTime day) {
    for (var key in _holidays.keys) {
      if (isSameDay(key, day)) {
        return _holidays[key];
      }
    }
    return null;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File imageFile = File(image.path);
      double screenWidth = MediaQuery.of(context).size.width;
      double targetAspectRatio = (screenWidth - 32.0) / 150.0;

      final Alignment? newAlignment = await showDialog<Alignment>(
        context: context,
        builder: (context) => ImageAdjustmentDialog(
          image: imageFile,
          aspectRatio: targetAspectRatio,
        ),
      );

      if (newAlignment != null) {
        setState(() {
          int currentMonth = _focusedDay.month;
          _monthlyImages[currentMonth] = imageFile;
          _monthlyImageAlignments[currentMonth] = newAlignment;
        });
      }
    }
  }

  void _showAddEventDialog() async {
    final TextEditingController _eventController = TextEditingController();
    final String? newEvent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('新增事件'),
        content: TextField(
          controller: _eventController,
          autofocus: true,
          decoration: InputDecoration(hintText: '輸入事件內容'),
        ),
        actions: [
          TextButton(
            child: Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('儲存'),
            onPressed: () {
              if (_eventController.text.isNotEmpty) {
                Navigator.pop(context, _eventController.text);
              }
            },
          ),
        ],
      ),
    );

    if (newEvent != null && newEvent.isNotEmpty) {
      setState(() {
        if (_events[_selectedDay!] != null) {
          _events[_selectedDay!]!.add(newEvent);
        } else {
          _events[_selectedDay!] = [newEvent];
        }
      });
    }
  }

  Future<void> _showEventActionMenu(
      BuildContext context, String event, int index) async {
    final action = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: Text('選擇操作'),
        children: <Widget>[
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, 'edit');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('編輯'),
                ],
              ),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, 'delete');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 12),
                  Text('刪除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (action == 'edit') {
      _showEditEventDialog(index);
    } else if (action == 'delete') {
      _showDeleteEventDialog(event);
    }
  }

  void _showEditEventDialog(int index) async {
    final selectedEvents = _events[_selectedDay!]!;
    final oldText = selectedEvents[index];
    final TextEditingController _eventController =
    TextEditingController(text: oldText);

    final String? editedEvent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('編輯事件'),
        content: TextField(
          controller: _eventController,
          autofocus: true,
          decoration: InputDecoration(hintText: '輸入事件內容'),
        ),
        actions: [
          TextButton(
            child: Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('儲存'),
            onPressed: () {
              if (_eventController.text.isNotEmpty) {
                Navigator.pop(context, _eventController.text);
              }
            },
          ),
        ],
      ),
    );

    if (editedEvent != null && editedEvent.isNotEmpty) {
      setState(() {
        selectedEvents[index] = editedEvent;
      });
    }
  }

  void _showDeleteEventDialog(String event) async {
    final bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('刪除事件'),
        content: Text('您確定要刪除「$event」嗎？'),
        actions: [
          TextButton(
            child: Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text('刪除', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      setState(() {
        _events[_selectedDay!]?.remove(event);
        if (_events[_selectedDay!]?.isEmpty ?? false) {
          _events.remove(_selectedDay!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int currentMonth = _focusedDay.month;
    File? currentMonthImage = _monthlyImages[currentMonth];
    Alignment imageAlignment =
        _monthlyImageAlignments[currentMonth] ?? Alignment.center;

    double containerHeight = 150.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('年曆'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: Icon(Icons.add),
        tooltip: '新增事件',
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: containerHeight,
              width: double.infinity,
              margin: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                image: currentMonthImage != null
                    ? DecorationImage(
                  image: FileImage(currentMonthImage),
                  fit: BoxFit.cover,
                  alignment: imageAlignment,
                )
                    : DecorationImage(
                  image: NetworkImage(
                      'https://placehold.co/600x150/e0e0e0/757575?text=Select+Image+for+Month+$currentMonth'),
                  fit: BoxFit.cover,
                ),
              ),
              child: currentMonthImage == null
                  ? Center(
                child: Text(
                  '點擊設定 $currentMonth 月圖片',
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
              )
                  : null,
            ),
          ),
          TableCalendar<String>(
            locale: 'zh_TW',
            firstDay: _firstDay,
            lastDay: _lastDay,
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            eventLoader: _getEventsForDay,
            holidayPredicate: (day) {
              return _holidays.containsKey(day);
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            rowHeight: 70.0,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
            calendarStyle: CalendarStyle(
              weekendTextStyle: TextStyle(color: Colors.red),
              holidayTextStyle: TextStyle(color: Colors.red),
              holidayDecoration: const BoxDecoration(),
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final holidayName = _getHolidayName(day);
                final hasEvents = events.isNotEmpty;

                if (holidayName == null && !hasEvents) return null;

                return Positioned(
                  bottom: 4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (holidayName != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            holidayName,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (hasEvents)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: events.take(3).map((_) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              width: 5.0,
                              height: 5.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              itemCount: _getEventsForDay(_selectedDay!).length,
              itemBuilder: (context, index) {
                final event = _getEventsForDay(_selectedDay!)[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ListTile(
                    title: Text(event),
                    onLongPress: () {
                      _showEventActionMenu(context, event, index);
                    },
                    onTap: () {
                      print('點擊了事件: $event');
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ImageAdjustmentDialog extends StatefulWidget {
  final File image;
  final double aspectRatio;

  const ImageAdjustmentDialog({
    Key? key,
    required this.image,
    required this.aspectRatio,
  }) : super(key: key);

  @override
  _ImageAdjustmentDialogState createState() => _ImageAdjustmentDialogState();
}

class _ImageAdjustmentDialogState extends State<ImageAdjustmentDialog> {
  Alignment _currentAlignment = Alignment.center;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('調整圖片顯示範圍'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('請拖曳圖片以調整顯示位置',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 10),
            AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        double deltaX =
                            details.delta.dx / (constraints.maxWidth / 2.5);
                        double deltaY =
                            details.delta.dy / (constraints.maxHeight / 2.5);

                        double newX =
                        (_currentAlignment.x - deltaX).clamp(-1.0, 1.0);
                        double newY =
                        (_currentAlignment.y - deltaY).clamp(-1.0, 1.0);

                        _currentAlignment = Alignment(newX, newY);
                      });
                    },
                    child: Container(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white10, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          widget.image,
                          fit: BoxFit.cover,
                          alignment: _currentAlignment,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('取消'),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        ElevatedButton(
          child: Text('確認'),
          onPressed: () {
            Navigator.of(context).pop(_currentAlignment);
          },
        ),
      ],
    );
  }
}