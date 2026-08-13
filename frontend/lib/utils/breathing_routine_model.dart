/// 3대 호흡 루틴 타입
enum BreathingRoutineType {
  /// 1. 교감신경 매우 우세 (HRV 극저) -> 4-7-8 호흡 (들숨 4초 - 참기 7초 - 날숨 8초)
  calm478,

  /// 2. 교감신경 약간 우세 (HRV 보통) -> 4-4-4-4 박스 호흡 (들숨 4초 - 참기 4초 - 날숨 4초 - 참기 4초)
  box4444,

  /// 3. 자율신경 균형 상태 (HRV 정상) -> 5-5 공진 호흡 (들숨 5초 - 날숨 5초)
  resonance55,
}

/// 호흡 루틴 정보 데이터 모델
class BreathingRoutineModel {
  final BreathingRoutineType type;
  final String title;
  final String conditionTitle;
  final String hrvStatusText;
  final String recommendedSituation;
  final String effectTag;
  final String effectDescription;
  
  // 목표 호흡 템포 (초 단위)
  final double targetInhale;
  final double targetHold1;
  final double targetExhale;
  final double targetHold2;

  const BreathingRoutineModel({
    required this.type,
    required this.title,
    required this.conditionTitle,
    required this.hrvStatusText,
    required this.recommendedSituation,
    required this.effectTag,
    required this.effectDescription,
    required this.targetInhale,
    required this.targetHold1,
    required this.targetExhale,
    required this.targetHold2,
  });

  // 초당 총 호흡 1주기 시간 (초 단위)
  double get cycleDurationSec => targetInhale + targetHold1 + targetExhale + targetHold2;

  // 권장 루틴 수행 시간 (분 단위, 기본 5분)
  int get totalDurationMinutes => 5;

  // 루틴 강도 텍스트
  String get intensity {
    switch (type) {
      case BreathingRoutineType.calm478:
        return '높은 이완';
      case BreathingRoutineType.box4444:
        return '중간';
      case BreathingRoutineType.resonance55:
        return '기본';
    }
  }

  /// HRV 측정 결과(SDNNms) 기반 3대 호흡 루틴 자동 매핑
  factory BreathingRoutineModel.fromHrv(double hrvSdnn) {
    if (hrvSdnn < 30.0) {
      // 1. 교감신경 매우 우세 (HRV < 30ms) -> 4-7-8 호흡
      return const BreathingRoutineModel(
        type: BreathingRoutineType.calm478,
        title: '4-7-8 안심 진정 호흡',
        conditionTitle: '교감신경 매우 우세',
        hrvStatusText: 'HRV 극저 (고스트레스 / 긴장)',
        recommendedSituation: '시험 D-Day, 면접 직전, 극심한 불안, 불면',
        effectTag: '진정 / 불면 완화',
        effectDescription: '급성 긴장을 신속히 진정시키고 깊은 수면을 유도합니다.',
        targetInhale: 4.0,
        targetHold1: 7.0,
        targetExhale: 8.0,
        targetHold2: 0.0,
      );
    } else if (hrvSdnn < 55.0) {
      // 2. 교감신경 약간 우세 (30ms <= HRV < 55ms) -> 4-4-4-4 박스 호흡
      return const BreathingRoutineModel(
        type: BreathingRoutineType.box4444,
        title: '4-4-4-4 박스 몰입 호흡',
        conditionTitle: '교감신경 약간 우세',
        hrvStatusText: 'HRV 보통 (약한 긴장 / 업무)',
        recommendedSituation: '공부·업무 직전, 과제 데드라인 임박',
        effectTag: '집중 / 몰입 강화',
        effectDescription: '복잡한 뇌를 정돈하고 마인드 몰입도를 최고조로 높입니다.',
        targetInhale: 4.0,
        targetHold1: 4.0,
        targetExhale: 4.0,
        targetHold2: 4.0,
      );
    } else {
      // 3. 자율신경 균형 상태 (HRV >= 55ms) -> 5-5 공진 호흡
      return const BreathingRoutineModel(
        type: BreathingRoutineType.resonance55,
        title: '5-5 편안한 공진 호흡',
        conditionTitle: '자율신경 균형 상태',
        hrvStatusText: 'HRV 정상 (안정 / 리프레시)',
        recommendedSituation: '일상 리프레시, 휴식 시간, 명상 시간',
        effectTag: '자율신경계 안정',
        effectDescription: '심박 변이와 호흡 주기를 공진시켜 깊은 이완을 도옵니다.',
        targetInhale: 5.0,
        targetHold1: 0.0,
        targetExhale: 5.0,
        targetHold2: 0.0,
      );
    }
  }
}
