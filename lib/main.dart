import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection'; // 用於 LinkedHashMap
import 'package:intl/date_symbol_data_local.dart'; // 1. 導入 intl 套件
import 'package:image_picker/image_picker.dart'; // 導入圖片選擇套件
import 'dart:io'; // 用於處理檔案 (File)

void main() async { // 2. 將 main 函數改為 async
  // 3. 確保 Flutter 綁定已初始化
  WidgetsFlutterBinding.ensureInitialized();
  // 4. 初始化 'zh_TW' (繁體中文) 的日期格式
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
  // 注意：Dart 的 DateTime.utc() 月份是從 1 (一月) 開始
  final DateTime _firstDay = DateTime.utc(2026, 1, 1);
  final DateTime _lastDay = DateTime.utc(2026, 12, 31);
  DateTime _focusedDay = DateTime.utc(2026, 1, 1);
  DateTime? _selectedDay;

  // 新增：用於儲存使用者選擇的圖片
  File? _customImage;

  // 1. 定義 2026 年台灣國定假日 (使用 UTC 日期以匹配 table_calendar)
  final Map<DateTime, String> _holidays = {
    DateTime.utc(2026, 1, 1): '元旦',
    DateTime.utc(2026, 2, 15): '小年夜', // 新增假日
    DateTime.utc(2026, 2, 16): '除夕',
    DateTime.utc(2026, 2, 17): '春節初一',
    DateTime.utc(2026, 2, 18): '春節初二',
    DateTime.utc(2026, 2, 19): '春節初三',
    DateTime.utc(2026, 2, 20): '春節補假', // 2/15 補假
    DateTime.utc(2026, 2, 27): '和平紀念日補假', // 2/28 補假
    DateTime.utc(2026, 2, 28): '和平紀念日',
    DateTime.utc(2026, 4, 3): '兒童節補假', // 4/4 補假
    DateTime.utc(2026, 4, 4): '兒童節',
    DateTime.utc(2026, 4, 5): '清明節',
    DateTime.utc(2026, 4, 6): '清明節補假', // 4/5 補假
    DateTime.utc(2026, 5, 1): '勞動節', // 新增全國假日
    DateTime.utc(2026, 6, 19): '端午節',
    DateTime.utc(2026, 9, 25): '中秋節',
    DateTime.utc(2026, 9, 28): '教師節', // 新增全國假日
    DateTime.utc(2026, 10, 9): '國慶日補假', // 10/10 補假
    DateTime.utc(2026, 10, 10): '國慶日',
    DateTime.utc(2026, 10, 25): '臺灣光復節', // 新增假日
    DateTime.utc(2026, 10, 26): '光復節補假', // 10/25 補假
    DateTime.utc(2026, 12, 25): '行憲紀念日', // 新增假日
  };

  // 用於儲存事件的資料結構
  // 使用 LinkedHashMap 來維持事件的順序
  late final Map<DateTime, List<String>> _events;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // 將 _events 的初始化移到這裡
    _events = LinkedHashMap(
      equals: isSameDay,
      hashCode: getHashCode,
    );

    // 2. 將國定假日載入到事件列表中
    _holidays.forEach((day, name) {
      // 確保即使已有用戶事件，也能添加假日
      if (_events[day] != null) {
        _events[day]!.add(name);
      } else {
        _events[day] = [name];
      }
    });

    // 範例事件 (您可以保留或移除)
    _events[DateTime.utc(2026, 1, 1)]!.add('開始寫日記');
    _events[DateTime.utc(2026, 10, 31)] = ['萬聖節派對'];
  }

  // 用於 table_calendar 判斷 'day' 是否相等的函數
  int getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }

  // 獲取選定日期的事件列表
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

  // 新增：選擇圖片的方法
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // 讓使用者從相簿選擇圖片
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _customImage = File(image.path);
      });
    }
  }

  // 顯示新增事件的對話框
  void _showAddEventDialog() async {
    final TextEditingController _eventController = TextEditingController();
    final String? newEvent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('新增事件'),
        content: TextField(
          controller: _eventController,
          autofocus: true, // 自動彈出鍵盤
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
              // 確保有輸入才回傳
              if (_eventController.text.isNotEmpty) {
                Navigator.pop(context, _eventController.text);
              }
            },
          ),
        ],
      ),
    );

    // 如果使用者儲存了新事件
    if (newEvent != null && newEvent.isNotEmpty) {
      setState(() {
        if (_events[_selectedDay!] != null) {
          // 如果這天已經有事件，就加到列表中
          _events[_selectedDay!]!.add(newEvent);
        } else {
          // 否則，建立一個新列表
          _events[_selectedDay!] = [newEvent];
        }
      });
    }
  }

  // 顯示刪除事件的確認對話框
  void _showDeleteEventDialog(String event) async {
    final bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('刪除事件'),
        content: Text('您確定要刪除「$event」嗎？'),
        actions: [
          TextButton(
            child: Text('取消'),
            onPressed: () => Navigator.pop(context, false), // 回傳 false
          ),
          TextButton(
            child: Text('刪除', style: TextStyle(color: Colors.red)), // 標示為紅色
            onPressed: () => Navigator.pop(context, true), // 回傳 true
          ),
        ],
      ),
    );

    // 如果使用者確認刪除 (confirmDelete == true)
    if (confirmDelete == true) {
      setState(() {
        // 從 _events 映射中找到該天的列表並移除該事件
        _events[_selectedDay!]?.remove(event);
        // 可選：如果該天已無事件，可以移除該鍵 (確保列表刷新)
        if (_events[_selectedDay!]?.isEmpty ?? false) {
          _events.remove(_selectedDay!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // 自訂圖片區塊 (修改過)
          GestureDetector(
            onTap: _pickImage, // 點擊時觸發選擇圖片
            child: Container(
              height: 150,
              width: double.infinity,
              margin: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                image: _customImage != null
                    ? DecorationImage(
                  image: FileImage(_customImage!), // 顯示使用者選擇的圖片
                  fit: BoxFit.cover,
                )
                    : DecorationImage(
                  // 顯示預設圖片
                  image: NetworkImage('https://placehold.co/600x150/e0e0e0/757575?text=Tap+to+Select+Image'),
                  fit: BoxFit.cover,
                ),
              ),
              child: _customImage == null
                  ? Center(
                child: Text(
                  '點擊此處選擇圖片',
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
              )
                  : null,
            ),
          ),

          // 2026 年曆
          TableCalendar<String>(
            locale: 'zh_TW', // 可選：設定為繁體中文 (需額外設定)
            firstDay: _firstDay,
            lastDay: _lastDay,
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            eventLoader: _getEventsForDay, // 載入事件標記

            // 3. 告訴日曆哪些是假日
            holidayPredicate: (day) {
              // 檢查日期是否在我們的 _holidays Map 中
              // isSameDay 預設會忽略時間，但為保險起見，我們這裡也檢查 UTC
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
              _focusedDay = focusedDay;
            },
            // 日曆標頭樣式
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false, // 隱藏 "2 weeks", "week", "month" 切換
            ),
            // 日曆內容樣式
            calendarStyle: CalendarStyle(
              // 4. 設定假日文字為紅色
              holidayTextStyle: TextStyle(color: Colors.red),

              // 標記有事件的日子
              markerDecoration: BoxDecoration(
                color: Colors.red[400],
                shape: BoxShape.circle,
              ),
            ),
          ),

          const SizedBox(height: 8.0),

          // 顯示選定日期的事件列表
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
                      // TODO: 點擊事件進行編輯
                      print('點擊了事件: $event');
                    },
                    onLongPress: () { // 新增：長按刪除
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