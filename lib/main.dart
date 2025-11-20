import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection'; // 用於 LinkedHashMap
import 'package:intl/date_symbol_data_local.dart'; // 1. 導入 intl 套件
import 'package:image_picker/image_picker.dart'; // 導入圖片選擇套件
import 'dart:io'; // 用於處理檔案 (File)

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

  // 使用 Map 來儲存每個月的圖片
  final Map<int, File> _monthlyImages = {};

  // 儲存每個月圖片的對齊位置 (Alignment)
  final Map<int, Alignment> _monthlyImageAlignments = {};

  // 定義 2026 年台灣國定假日
  final Map<DateTime, String> _holidays = {
    DateTime.utc(2026, 1, 1): '元旦',
    DateTime.utc(2026, 2, 15): '小年夜',
    DateTime.utc(2026, 2, 16): '除夕',
    DateTime.utc(2026, 2, 17): '春節初一',
    DateTime.utc(2026, 2, 18): '春節初二',
    DateTime.utc(2026, 2, 19): '春節初三',
    DateTime.utc(2026, 2, 20): '春節補假',
    DateTime.utc(2026, 2, 27): '和平紀念日補假',
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

    _holidays.forEach((day, name) {
      if (_events[day] != null) {
        _events[day]!.add(name);
      } else {
        _events[day] = [name];
      }
    });

    // 範例事件
    _events[DateTime.utc(2026, 1, 1)]!.add('開始寫日記');
    _events[DateTime.utc(2026, 10, 31)] = ['萬聖節派對'];
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

  // 選擇圖片並開啟調整視窗
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File imageFile = File(image.path);

      // 計算目標寬高比 (與主畫面圖片區塊一致)
      // 主畫面寬度 = 螢幕寬度 - 32 (margin)
      // 主畫面高度 = 150
      double screenWidth = MediaQuery.of(context).size.width;
      double targetAspectRatio = (screenWidth - 32.0) / 150.0;

      // 開啟調整視窗
      final Alignment? newAlignment = await showDialog<Alignment>(
        context: context,
        builder: (context) => ImageAdjustmentDialog(
          image: imageFile,
          aspectRatio: targetAspectRatio,
        ),
      );

      // 如果使用者按下確認 (有回傳 Alignment)
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
    Alignment imageAlignment = _monthlyImageAlignments[currentMonth] ?? Alignment.center;

    double containerHeight = 150.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('2026 年曆'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: Icon(Icons.add),
        tooltip: '新增事件',
      ),
      body: Column(
        children: [
          // 自訂圖片區塊
          GestureDetector(
            onTap: _pickImage, // 點擊開啟選擇與調整視窗
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
                  alignment: imageAlignment, // 套用調整後的對齊
                )
                    : DecorationImage(
                  image: NetworkImage('https://placehold.co/600x150/e0e0e0/757575?text=Select+Image+for+Month+$currentMonth'),
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

          // 2026 年曆
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

            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
            calendarStyle: CalendarStyle(
              holidayTextStyle: TextStyle(color: Colors.red),
              markerDecoration: BoxDecoration(
                color: Colors.red[400],
                shape: BoxShape.circle,
              ),
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
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ListTile(
                    title: Text(event),
                    onTap: () {
                      print('點擊了事件: $event');
                    },
                    onLongPress: () {
                      _showDeleteEventDialog(event);
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

// 新增：圖片位置調整對話框
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
      // 修正：使用 SizedBox(width: double.maxFinite) 包裹 content
      // 這確保了 Dialog 的內容有明確的寬度限制，解決 "RenderBox was not laid out" 錯誤
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('請拖曳圖片以調整顯示位置', style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 10),

            // 預覽區塊
            AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    // 拖曳手勢
                    onPanUpdate: (details) {
                      setState(() {
                        // 計算移動量
                        double deltaX = details.delta.dx / (constraints.maxWidth / 2.5);
                        double deltaY = details.delta.dy / (constraints.maxHeight / 2.5);

                        double newX = (_currentAlignment.x - deltaX).clamp(-1.0, 1.0);
                        double newY = (_currentAlignment.y - deltaY).clamp(-1.0, 1.0);

                        _currentAlignment = Alignment(newX, newY);
                      });
                    },
                    child: Container(
                      // 修正：明確使用 constraints 寬高，而非 double.infinity
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2), // 藍色框框表示預覽範圍
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
          onPressed: () => Navigator.of(context).pop(null), // 回傳 null (不變更)
        ),
        ElevatedButton(
          child: Text('確認'),
          onPressed: () {
            Navigator.of(context).pop(_currentAlignment); // 回傳調整後的對齊位置
          },
        ),
      ],
    );
  }
}