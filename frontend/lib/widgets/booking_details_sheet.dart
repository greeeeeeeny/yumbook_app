import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'package:yumbook_app/widgets/payment_methods_widget.dart';
import 'package:yumbook_app/screens/booking/complete_reservation_screen.dart';
import 'package:yumbook_app/models/reservation_data.dart';
import 'package:yumbook_app/models/restaurant.dart';

import 'package:yumbook_app/state/reservation_store.dart';


class BottomSheetPopupReservationCalender extends StatefulWidget {
  final Restaurant restaurant;

  const BottomSheetPopupReservationCalender({
    super.key,
    required this.restaurant,
  });
  

  @override
  State<BottomSheetPopupReservationCalender> createState() => _BottomSheetPopupReservationCalenderState();
}

class _BottomSheetPopupReservationCalenderState extends State<BottomSheetPopupReservationCalender> {
  // 1. 상태 관리 변수들
  DateTime _focusedDay = DateTime(2026, 1, 1);  
  DateTime? _selectedDay;
  DateTime _selectedTime = DateTime(2026, 1, 1, 17, 30);  
  int _partySize = 4; // 기본 인원수

// 2. 시간 휠(Picker) 호출 함수 수정
  void _showTimePicker(BuildContext context) {
    showDialog( // showCupertinoModalPopup 대신 showDialog를 사용하여 중앙에 띄움
      context: context,
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8, // 창 너비 조절
            height: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // 상단 완료 버튼 바
                Padding(
                      padding: const EdgeInsets.only(top: 8.0, right: 16.0), // 1. 여백 수정
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero, // 2. 버튼 기본 패딩 제거
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Done',
                              textAlign: TextAlign.right,
                                style: TextStyle(
            fontFamily: 'Pretendard',    // 직접 입력
            fontSize: 18,               // 직접 입력
            fontWeight: FontWeight.w600, // SemiBold
                                color: const Color(0xFFD45425), // 3. 테마 스타일 적용 + 색상만 변경
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                // 시간 선택 휠
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: _selectedTime,
                    use24hFormat: false,
                    minuteInterval: 30, // 💡 이 코드가 30분 단위로 설정해줍니다.
                    onDateTimeChanged: (DateTime newTime) {
                      setState(() {
                        _selectedTime = DateTime(
                          _selectedTime.year,
                          _selectedTime.month,
                          _selectedTime.day,
                          newTime.hour,
                          newTime.minute,
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 3. 시간 포맷 변환 함수 (오류 수정: .hours 대신 .inHours 사용)
  static String _formatTime(DateTime time) {
  int hours = time.hour;
  int minutes = time.minute;
  String period = hours >= 12 ? 'PM' : 'AM';
  int displayHours = hours > 12 ? hours - 12 : (hours == 0 ? 12 : hours);
  return '$displayHours:${minutes.toString().padLeft(2, '0')} $period';
}
  bool _isNotifyRequested(String time) {
    final selectedDate = _selectedDay ?? _focusedDay;
    final parsed = DateFormat('h:mm a').parse(time);

    final slotTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      parsed.hour,
      parsed.minute,
    );

    return ReservationStore.instance.notifyRequests.any(
      (e) =>
          e.restaurantId == widget.restaurant.id &&
          e.date.year == selectedDate.year &&
          e.date.month == selectedDate.month &&
          e.date.day == selectedDate.day &&
          e.time.hour == slotTime.hour &&
          e.time.minute == slotTime.minute &&
          e.partySize == _partySize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Booking Details', style: TextStyle(color: Color(0xFF383838), fontSize: 24, fontWeight: FontWeight.w600)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text('Done', style: TextStyle(color: Color(0xFF6E6E6E), fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // 달력
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD9D9D9)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2040, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF383838), // grey800
                          ),
                        ),
                        calendarStyle: const CalendarStyle(
                          // --- 선택된 날짜: YumColors.orange (0xFFD45425) 적용 ---
                          selectedDecoration: BoxDecoration(
                            color: Color(0xFFD45425), 
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: TextStyle(color: Colors.white),

                          // --- 오늘 날짜: 연한 주황색으로 강조 ---
                          todayDecoration: BoxDecoration(
                            color: Color(0x26D45425), // 0xFFD45425에 투명도 15% 적용
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: TextStyle(
                            color: Color(0xFFD45425),
                            fontWeight: FontWeight.bold,
                          ),

                          // --- 평일 및 주말 글자색 ---
                          defaultTextStyle: TextStyle(color: Color(0xFF383838)),
                          weekendTextStyle: TextStyle(color: Color(0xFFBF331B)), // logoColor(레드계열)
                        ),
                      onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Time 설정
                  _buildSettingRow(
                    'Time', 
                    _formatTime(_selectedTime), 
                    onTap: () => _showTimePicker(context),
                  ),

                  const SizedBox(height: 16),

                  // Party Size 설정 (인원 조절 버튼 추가)
                  _buildPartySizeRow(),

                  const SizedBox(height: 24),


                    // BOOK 버튼 Container 부분을 GestureDetector로 감쌉니다.
                    GestureDetector(
                          onTap: () {
                            final now = DateTime.now();
                            final confirmationCode =
                                'Yumbook-B-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-'
                                '${(now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';

                            final baseData = ReservationData(
                              restaurantName: widget.restaurant.name,
                              restaurantId: widget.restaurant.id,
                              date: _selectedDay ?? _focusedDay,
                              time: _selectedTime,
                              partySize: _partySize,
                              guestName: 'Kim',
                              seatType: 'Counter',
                              confirmationCode: confirmationCode,
                            );

                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              barrierColor: Colors.black54,
                              builder: (_) => PaymentMethodsWidget(
                                onMethodSelected: (selectedMethod) {
                                  Navigator.pop(context); // payment widget 닫기

                                  final reservationWithPayment = baseData.copyWith(
                                    paymentMethodId: selectedMethod.id,
                                    paymentMethodLabel: '${selectedMethod.brand} •••• ${selectedMethod.last4}',
                                  );

                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CompleteReservationScreen(
                                          data: reservationWithPayment,
                                        ),
                                      ),
                                    );
                                  });
                                },
                              ),
                            );
                          },//ontap
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD45425), 
                          borderRadius: BorderRadius.circular(14)
                        ),
                        child: const Center(
                          child: Text('BOOK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                        ),
                      ),
                    ),
                  
                    const SizedBox(height: 20),
                    const Divider(thickness: 8, color: Color(0xFFF2F2F7)),
                    const SizedBox(height: 16),
                    _buildTimeSlot('6:00 PM'), 
                    _buildTimeSlot('6:30 PM'), 
                    _buildTimeSlot('7:00 PM'),
                    const SizedBox(height: 40),
                  ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 인원 조절 전용 행 위젯
Widget _buildPartySizeRow() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Party Size',
        style: TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.w600,
          color: Color(0xFF383838), // 텍스트 색상 디테일
        ),
      ),
      Container(
        // 두 번째 이미지 스타일: 연한 배경색과 더 둥근 모서리
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7), // iOS 시스템 그레이 느낌의 연한 회색
          borderRadius: BorderRadius.circular(100), // 완전한 캡슐 모양
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 마이너스 버튼: InkWell을 사용해 불필요한 패딩 제거
            _buildCustomIconButton(
              icon: Icons.remove,
              onTap: () => setState(() { if (_partySize > 1) _partySize--; }),
            ),
            
            // 숫자: 간격을 조절하기 위해 Padding 사용
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '$_partySize',
                style: const TextStyle(
                  fontSize: 17, // 이미지와 비슷한 크기
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            
            // 플러스 버튼
            _buildCustomIconButton(
              icon: Icons.add,
              onTap: () => setState(() => _partySize++),
            ),
          ],
        ),
      ),
    ],
  );
}

// 버튼의 크기와 클릭 영역을 세밀하게 조정하기 위한 보조 위젯
Widget _buildCustomIconButton({required IconData icon, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      padding: const EdgeInsets.all(10), // 클릭 영역 확보
      child: Icon(
        icon,
        size: 18,
        color: Colors.black.withOpacity(0.8),
      ),
    ),
  );
}

  // 공통 UI 위젯
  Widget _buildSettingRow(String title, String value, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

      Widget _buildTimeSlot(String time) {
    final isRequested = _isNotifyRequested(time);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E5EA)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            time,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          GestureDetector(
            onTap: () {
              if (isRequested) return;

              final selectedDate = _selectedDay ?? _focusedDay;
              final parsed = DateFormat('h:mm a').parse(time);

              final notifyTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                parsed.hour,
                parsed.minute,
              );

              ReservationStore.instance.addNotifyRequest(
                NotifyRequest(
                  restaurantId: widget.restaurant.id,
                  restaurantName: widget.restaurant.name,
                  date: selectedDate,
                  time: notifyTime,
                  partySize: _partySize,
                ),
              );

              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$time notification request saved.'),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isRequested ? const Color(0xFFD45425) : Colors.white,
                border: Border.all(
                  color: isRequested
                      ? const Color(0xFFD45425)
                      : const Color(0xFFD9D9D9),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isRequested) ...[
                    const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    isRequested ? 'Notified' : 'Notify',
                    style: TextStyle(
                      color: isRequested
                          ? Colors.white
                          : const Color(0xFFB4B4B4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}