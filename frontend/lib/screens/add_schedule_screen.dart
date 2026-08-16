import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

class AddScheduleScreen extends StatefulWidget {
  final DateTime? initialDate;

  const AddScheduleScreen({
    super.key,
    this.initialDate,
  });

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final TextEditingController _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 30);
  int _selectedCategoryIndex = 0;
  int _selectedReminderIndex = 1; // 0: 10분 전, 1: 30분 전, 2: 1시간 전, 3: 없음

  final List<String> _koreanWeekdays = const [
    '월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'
  ];

  final List<Map<String, String>> _categories = const [
    {'icon': '🌿', 'name': '발표/면접 긴장 완화'},
    {'icon': '⚡', 'name': '집중력 몰입'},
    {'icon': '🌙', 'name': '스트레스 해소'},
    {'icon': '🧘', 'name': '자율 호흡'},
  ];

  final List<String> _reminders = const [
    '10분 전',
    '30분 전',
    '1시간 전',
    '설정 안 함',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.lightMint,
              onPrimary: AppColors.darkBg,
              surface: AppColors.darkCharcoal,
              onSurface: AppColors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: AppColors.darkBg),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.lightMint,
              onPrimary: AppColors.darkBg,
              surface: AppColors.darkCharcoal,
              onSurface: AppColors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: AppColors.darkBg),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
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

    // Save success feedback and return
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('\'$title\' 일정이 추가되었습니다.'),
        backgroundColor: AppColors.darkGreenishGray,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
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
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              // Top Navigation Header
              const SizedBox(height: 12),
              _buildTopHeader(),
              const SizedBox(height: 16),

              // Scrollable Input Form
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        '새로운 일정 등록',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: AppColors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '일정 전 마음을 다잡을 호흡 루틴을 함께 준비해보세요.',
                        style: TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.lightGray,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 1. Schedule Title Input
                      const Text(
                        '일정 이름',
                        style: TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.darkCharcoal,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.slateDarkGray.withAlpha(80),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontFamily: AppFonts.pretendard,
                            fontSize: 15,
                            color: AppColors.white,
                          ),
                          decoration: const InputDecoration(
                            hintText: '예: 중앙해커톤 본선 피칭, 전공 발표',
                            hintStyle: TextStyle(
                              fontFamily: AppFonts.pretendard,
                              fontSize: 14,
                              color: AppColors.slateGray,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 2. Date & Time Selection Cards
                      const Text(
                        '일시 설정',
                        style: TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Date Picker Card
                          Expanded(
                            flex: 3,
                            child: GestureDetector(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.darkCharcoal,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.slateDarkGray.withAlpha(80),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      color: AppColors.lightMint,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _formattedDateString,
                                        style: const TextStyle(
                                          fontFamily: AppFonts.pretendard,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Time Picker Card
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: _selectTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.darkCharcoal,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.slateDarkGray.withAlpha(80),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      color: AppColors.lightMint,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _formattedTimeString,
                                        style: const TextStyle(
                                          fontFamily: AppFonts.pretendard,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 3. Category Ritual Selection
                      const Text(
                        '추천 호흡 루틴 선택',
                        style: TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(_categories.length, (index) {
                          final isSelected = _selectedCategoryIndex == index;
                          final category = _categories[index];

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategoryIndex = index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.lightMint
                                    : AppColors.darkCharcoal,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.lightMint
                                      : AppColors.slateDarkGray.withAlpha(80),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    category['icon']!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    category['name']!,
                                    style: TextStyle(
                                      fontFamily: AppFonts.pretendard,
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? AppColors.darkBg : AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 24),

                      // 4. Reminder Notification Option
                      const Text(
                        '사전 준비 알림',
                        style: TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(_reminders.length, (index) {
                          final isSelected = _selectedReminderIndex == index;

                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: index == _reminders.length - 1 ? 0 : 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedReminderIndex = index;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.white.withAlpha(40)
                                        : AppColors.darkCharcoal,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.lightMint
                                          : AppColors.slateDarkGray.withAlpha(60),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _reminders[index],
                                    style: TextStyle(
                                      fontFamily: AppFonts.pretendard,
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                      color: isSelected ? AppColors.lightMint : AppColors.lightGray,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Fixed Save Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _onSavePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightMint,
                      foregroundColor: AppColors.darkBg,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      '일정 등록하기',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBg,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.darkCharcoal,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.slateDarkGray.withAlpha(80),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.white,
              size: 20,
            ),
          ),
        ),
        const Text(
          '일정 추가',
          style: TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        GestureDetector(
          onTap: _onSavePressed,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              '저장',
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.lightMint,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
