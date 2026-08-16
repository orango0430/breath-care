import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AddScheduleModal extends StatefulWidget {
  final DateTime? initialDate;
  final Function(Map<String, dynamic>)? onScheduleAdded;

  const AddScheduleModal({
    super.key,
    this.initialDate,
    this.onScheduleAdded,
  });

  static Future<void> show(
    BuildContext context, {
    DateTime? initialDate,
    Function(Map<String, dynamic>)? onScheduleAdded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddScheduleModal(
        initialDate: initialDate,
        onScheduleAdded: onScheduleAdded,
      ),
    );
  }

  @override
  State<AddScheduleModal> createState() => _AddScheduleModalState();
}

class _AddScheduleModalState extends State<AddScheduleModal> {
  final TextEditingController _titleController =
      TextEditingController(text: '프로젝트 최종 발표');

  DateTime _selectedDate = DateTime(2026, 8, 25);
  DateTime _currentDisplayMonth = DateTime(2026, 8, 1);
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 30);

  bool _isDateExpanded = false;
  bool _isTimeExpanded = false;

  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['발표', '시험', '면접'];

  final List<String> _monthNames = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<String> _koreanWeekdays = const [
    '월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
      _currentDisplayMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('일정 제목을 입력해 주세요.'),
          backgroundColor: AppColors.coralRed,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final newSchedule = {
      'title': title,
      'category': _categories[_selectedCategoryIndex],
      'date': _selectedDate,
      'time': _formattedTimeString,
      'isCompleted': false,
    };

    if (widget.onScheduleAdded != null) {
      widget.onScheduleAdded!(newSchedule);
    }

    Navigator.of(context).pop();
  }

  void _addCustomCategory() {
    showDialog(
      context: context,
      builder: (context) {
        final categoryController = TextEditingController();
        return AlertDialog(
          backgroundColor: AppColors.darkCharcoal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '새 카테고리 추가',
            style: TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 16,
              color: AppColors.white,
            ),
          ),
          content: TextField(
            controller: categoryController,
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(
              hintText: '카테고리명 입력 (예: 미팅)',
              hintStyle: TextStyle(color: AppColors.slateGray),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: AppColors.slateGray)),
            ),
            TextButton(
              onPressed: () {
                final text = categoryController.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _categories.add(text);
                    _selectedCategoryIndex = _categories.length - 1;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('추가', style: TextStyle(color: AppColors.lightMint)),
            ),
          ],
        );
      },
    );
  }

  String get _formattedDateString {
    final weekdayStr = _koreanWeekdays[_selectedDate.weekday - 1];
    return '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일 $weekdayStr';
  }

  String get _formattedTimeString {
    final period = _selectedTime.hour < 12 ? '오전' : '오후';
    final hour = _selectedTime.hour == 0
        ? 12
        : (_selectedTime.hour > 12 ? _selectedTime.hour - 12 : _selectedTime.hour);
    final minuteStr = _selectedTime.minute.toString().padLeft(2, '0');
    return '$period $hour:$minuteStr';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
      decoration: const BoxDecoration(
        color: Color(0xFF232426),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle Pill
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slateGray.withAlpha(120),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Header Bar: [ X ]    Plan    [ Check ]
              _buildHeaderBar(),
              const SizedBox(height: 16),

              // Scrollable Content Form
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Title Input Box with Clear 'X' Button
                      _buildTitleInputBox(),
                      const SizedBox(height: 24),

                      // 2. Category Chips Section
                      const Text(
                        '카테고리',
                        style: TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.lightGray,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildCategoryChips(),
                      const SizedBox(height: 24),

                      // 3. Date Selection Row & Accordion Calendar
                      const Text(
                        '날짜',
                        style: TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.lightGray,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildDateSelectorRow(),
                      if (_isDateExpanded) ...[
                        const SizedBox(height: 10),
                        _buildInlineCalendarPicker(),
                      ],
                      const SizedBox(height: 24),

                      // 4. Time Selection Row & Accordion Time Picker
                      const Text(
                        '시간',
                        style: TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.lightGray,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildTimeSelectorRow(),
                      if (_isTimeExpanded) ...[
                        const SizedBox(height: 10),
                        _buildInlineTimePicker(),
                      ],
                      const SizedBox(height: 32),

                      // 5. Bottom Crystal Polygon Icon & Subtext
                      _buildBottomHintSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Top Header Bar: [ (X) ]   Plan   [ (✓) ]
  Widget _buildHeaderBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close (X) Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1F21),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.white,
                size: 22,
              ),
            ),
          ),

          // Modal Title: Plan
          Text(
            'Plan',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: AppColors.white,
              letterSpacing: 0.3,
            ),
          ),

          // Confirm (✓) Button
          GestureDetector(
            onTap: _onSavePressed,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1F21),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Schedule Title Input Box with Clear X Button
  Widget _buildTitleInputBox() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _titleController,
        style: const TextStyle(
          fontFamily: AppFonts.pretendard,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
        decoration: InputDecoration(
          hintText: '일정 제목을 입력하세요',
          hintStyle: const TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 15,
            color: AppColors.slateGray,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _titleController,
            builder: (context, value, child) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                onPressed: () => _titleController.clear(),
                icon: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.slateGray.withAlpha(150),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.darkBg,
                    size: 14,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 3. Category Chips Row (발표, 시험, 면접, +)
  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          ...List.generate(_categories.length, (index) {
            final isSelected = _selectedCategoryIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.lightMint
                        : const Color(0xFF1B1C1E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _categories[index],
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.darkBg : AppColors.lightGray,
                    ),
                  ),
                ),
              ),
            );
          }),

          // Plus (+) Add Category Button
          GestureDetector(
            onTap: _addCustomCategory,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1C1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.lightGray,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Date Selection Box Row
  Widget _buildDateSelectorRow() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isDateExpanded = !_isDateExpanded;
          if (_isDateExpanded) _isTimeExpanded = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1C1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.lightGray,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Text(
                  _formattedDateString,
                  style: const TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
            Icon(
              _isDateExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.lightGray,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  /// 4-1. Inline Calendar Picker (August 2026 Grid matching image 2)
  Widget _buildInlineCalendarPicker() {
    final monthName =
        '${_monthNames[_currentDisplayMonth.month - 1]} ${_currentDisplayMonth.year}';
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final firstDay =
        DateTime(_currentDisplayMonth.year, _currentDisplayMonth.month, 1);
    final daysInMonth =
        DateTime(_currentDisplayMonth.year, _currentDisplayMonth.month + 1, 0).day;
    final offset = firstDay.weekday - 1;
    final totalCells = offset + daysInMonth;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentDisplayMonth = DateTime(
                      _currentDisplayMonth.year,
                      _currentDisplayMonth.month - 1,
                      1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left_rounded,
                    color: AppColors.lightGray, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                monthName,
                style: const TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentDisplayMonth = DateTime(
                      _currentDisplayMonth.year,
                      _currentDisplayMonth.month + 1,
                      1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.lightGray, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((day) {
              return SizedBox(
                width: 34,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 12,
                    color: AppColors.slateGray,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 4,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < offset) return const SizedBox.shrink();

              final dayNum = index - offset + 1;
              final date = DateTime(
                _currentDisplayMonth.year,
                _currentDisplayMonth.month,
                dayNum,
              );
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.lightMint : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected ? AppColors.darkBg : AppColors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 5. Time Selection Box Row
  Widget _buildTimeSelectorRow() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isTimeExpanded = !_isTimeExpanded;
          if (_isTimeExpanded) _isDateExpanded = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1C1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.access_time_outlined,
                  color: AppColors.lightGray,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Text(
                  _formattedTimeString,
                  style: const TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
            Icon(
              _isTimeExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.lightGray,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  /// 5-1. Inline Time Wheel Picker matching image 2
  Widget _buildInlineTimePicker() {
    int isPm = _selectedTime.hour >= 12 ? 1 : 0;
    int hour12 = _selectedTime.hour == 0
        ? 12
        : (_selectedTime.hour > 12 ? _selectedTime.hour - 12 : _selectedTime.hour);
    int minuteIndex = (_selectedTime.minute / 5).round().clamp(0, 11);

    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Selected Row Background Pill
          Center(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D31),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          Row(
            children: [
              // AM / PM Column
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController: FixedExtentScrollController(initialItem: isPm),
                  onSelectedItemChanged: (index) {
                    final newHour = index == 1
                        ? (hour12 == 12 ? 12 : hour12 + 12)
                        : (hour12 == 12 ? 0 : hour12);
                    setState(() {
                      _selectedTime = TimeOfDay(hour: newHour, minute: _selectedTime.minute);
                    });
                  },
                  children: const [
                    Center(
                      child: Text(
                        '오전',
                        style: TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 15,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '오후',
                        style: TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 15,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Hour Column (01 - 12)
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController:
                      FixedExtentScrollController(initialItem: hour12 - 1),
                  onSelectedItemChanged: (index) {
                    final newHour12 = index + 1;
                    final isCurrentlyPm = _selectedTime.hour >= 12;
                    final newHour = isCurrentlyPm
                        ? (newHour12 == 12 ? 12 : newHour12 + 12)
                        : (newHour12 == 12 ? 0 : newHour12);
                    setState(() {
                      _selectedTime = TimeOfDay(hour: newHour, minute: _selectedTime.minute);
                    });
                  },
                  children: List.generate(12, (index) {
                    final hStr = (index + 1).toString().padLeft(2, '0');
                    return Center(
                      child: Text(
                        hStr,
                        style: const TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 15,
                          color: AppColors.white,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Minute Column (00, 05, 10, ... 55)
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController:
                      FixedExtentScrollController(initialItem: minuteIndex),
                  onSelectedItemChanged: (index) {
                    final newMin = index * 5;
                    setState(() {
                      _selectedTime = TimeOfDay(hour: _selectedTime.hour, minute: newMin);
                    });
                  },
                  children: List.generate(12, (index) {
                    final mStr = (index * 5).toString().padLeft(2, '0');
                    return Center(
                      child: Text(
                        mStr,
                        style: const TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 15,
                          color: AppColors.white,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 6. Bottom Hint Graphic & Subtext
  Widget _buildBottomHintSection() {
    return const Column(
      children: [
        // Mint Crystal Geometric Polyhedron
        _MintCrystalGraphic(size: 52),
        SizedBox(height: 14),

        Text(
          '선택한 일정 전, 맞춤 호흡 타이밍을\n자동으로 제안해드려요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.slateGray,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Custom CustomPainter rendering the 3D Light Mint Crystal Gem Polyhedron in the screenshot
class _MintCrystalGraphic extends StatelessWidget {
  final double size;

  const _MintCrystalGraphic({this.size = 50});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(
        painter: _CrystalPainter(),
      ),
    );
  }
}

class _CrystalPainter extends CustomPainter {
  const _CrystalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Light mint facet colors
    final topFacetPaint = Paint()
      ..color = const Color(0xFFD6F6CB)
      ..style = PaintingStyle.fill;

    final leftFacetPaint = Paint()
      ..color = const Color(0xFFB8E6AB)
      ..style = PaintingStyle.fill;

    final rightFacetPaint = Paint()
      ..color = const Color(0xFF99C98C)
      ..style = PaintingStyle.fill;

    final bottomFacetPaint = Paint()
      ..color = const Color(0xFF82B075)
      ..style = PaintingStyle.fill;

    // Vertices for polygon crystal
    final center = Offset(w * 0.5, h * 0.45);
    final top = Offset(w * 0.5, h * 0.05);
    final leftTop = Offset(w * 0.15, h * 0.3);
    final rightTop = Offset(w * 0.85, h * 0.3);
    final leftBottom = Offset(w * 0.18, h * 0.72);
    final rightBottom = Offset(w * 0.82, h * 0.72);
    final bottom = Offset(w * 0.5, h * 0.95);

    // Draw Top Facet
    final topPath = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(rightTop.dx, rightTop.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(leftTop.dx, leftTop.dy)
      ..close();
    canvas.drawPath(topPath, topFacetPaint);

    // Draw Left Facet
    final leftPath = Path()
      ..moveTo(leftTop.dx, leftTop.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(leftBottom.dx, leftBottom.dy)
      ..close();
    canvas.drawPath(leftPath, leftFacetPaint);

    // Draw Right Facet
    final rightPath = Path()
      ..moveTo(rightTop.dx, rightTop.dy)
      ..lineTo(rightBottom.dx, rightBottom.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(rightPath, rightFacetPaint);

    // Draw Bottom Facet
    final bottomPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(rightBottom.dx, rightBottom.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..close();
    canvas.drawPath(bottomPath, bottomFacetPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
