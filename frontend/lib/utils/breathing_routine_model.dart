/// 5대 카테고리 호흡 루틴 타입
enum BreathingRoutineType {
  /// 1. 긴급 대처: 교감신경 극단적 우세 (BPM 95 이상) -> 생리학적 한숨
  physiologicalSigh,

  /// 2. 심리 이완: 교감신경 매우 우세 (HRV < 30ms) -> 4-7-8 호흡
  calm478,

  /// 3. 집중·몰입: 교감신경 약간 우세 (30ms <= HRV < 55ms) -> 4-4-4-4 박스 호흡
  box4444,

  /// 4. 회복·밸런스: 자율신경 균형 상태 (HRV >= 55ms) -> 5.5-5.5 공진 호흡
  resonance55,

  /// 5. 에너지 각성: 부교감 과우세 / 저각성 (BPM < 60) -> 4-1-2-1 각성 호흡
  awakening4121,
}

/// 호흡 루틴 정보 데이터 모델
class BreathingRoutineModel {
  final BreathingRoutineType type;
  final String title;
  final String categoryTag;
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
    required this.categoryTag,
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
      case BreathingRoutineType.physiologicalSigh:
        return '응급 강하';
      case BreathingRoutineType.calm478:
        return '높은 이완';
      case BreathingRoutineType.box4444:
        return '중간 몰입';
      case BreathingRoutineType.resonance55:
        return '기본 밸런스';
      case BreathingRoutineType.awakening4121:
        return '에너지 부스팅';
    }
  }

  /// 평균 심박수(BPM) 및 심박변이도(HRV ms) 기반 5대 카테고리 자동 분기 매핑
  factory BreathingRoutineModel.fromMeasurement({
    required int bpm,
    required double hrvSdnn,
  }) {
    // 1. 교감신경 극단적 우세 (심박 급상승: BPM 95 이상) -> [🚨 긴급 대처] 생리학적 한숨
    if (bpm >= 95) {
      return const BreathingRoutineModel(
        type: BreathingRoutineType.physiologicalSigh,
        title: '생리학적 한숨',
        categoryTag: '🚨 긴급 대처',
        conditionTitle: '교감신경 극단적 우세 (심박 급상승)',
        hrvStatusText: '심박 급증 / 패닉 / 과호흡',
        recommendedSituation: '발표 직전 과호흡, 패닉, 극심한 분노/스트레스',
        effectTag: '급속 CO₂ 배출 / 즉각 심박 강하',
        effectDescription: '이중 들숨과 긴 날숨으로 CO₂를 급속 배출하고 심박수를 즉각 낮춥니다.',
        targetInhale: 2.0,
        targetHold1: 0.0,
        targetExhale: 6.0,
        targetHold2: 0.0,
      );
    }
    // 2. 부교감 과우세 / 저각성 (서맥/저각성: BPM 60 미만) -> [⚡ 에너지 각성] 4-1-2-1 각성 호흡
    else if (bpm < 60) {
      return const BreathingRoutineModel(
        type: BreathingRoutineType.awakening4121,
        title: '4-1-2-1 각성 호흡',
        categoryTag: '⚡ 에너지 각성',
        conditionTitle: '부교감 과우세 / 저각성',
        hrvStatusText: 'HRV 정체 (식곤증 / 브레인 포그)',
        recommendedSituation: '아침 기상 직후, 점심 식곤증, 오후 브레인 포그',
        effectTag: '산소 순환 촉진 / 두뇌 부스팅',
        effectDescription: '산소 순환을 촉진하고 두뇌 에너지를 빠르게 부스팅합니다.',
        targetInhale: 4.0,
        targetHold1: 1.0,
        targetExhale: 2.0,
        targetHold2: 1.0,
      );
    }
    // 3. 교감신경 매우 우세 (HRV < 30ms) -> [🌿 심리 이완] 4-7-8 호흡
    else if (hrvSdnn < 30.0) {
      return const BreathingRoutineModel(
        type: BreathingRoutineType.calm478,
        title: '4-7-8 호흡',
        categoryTag: '🌿 심리 이완',
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
    }
    // 4. 교감신경 약간 우세 (30ms <= HRV < 55ms) -> [🔥 집중·몰입] 4-4-4-4 박스 호흡
    else if (hrvSdnn < 55.0) {
      return const BreathingRoutineModel(
        type: BreathingRoutineType.box4444,
        title: '4-4-4-4 박스 호흡',
        categoryTag: '🔥 집중·몰입',
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
    }
    // 5. 자율신경 균형 상태 (HRV >= 55ms) -> [☯️ 회복·밸런스] 5-5 공진 호흡
    else {
      return const BreathingRoutineModel(
        type: BreathingRoutineType.resonance55,
        title: '5-5 공진 호흡',
        categoryTag: '☯️ 회복·밸런스',
        conditionTitle: '자율신경 균형 상태',
        hrvStatusText: 'HRV 정상 (안정 / 리프레시)',
        recommendedSituation: '일상 리프레시, 휴식 시간, 명상 시간',
        effectTag: '자율신경계 안정 / HRV 극대화',
        effectDescription: '심박 변이와 호흡 주기를 공진시켜 깊은 이완을 돕습니다.',
        targetInhale: 5.0,
        targetHold1: 0.0,
        targetExhale: 5.0,
        targetHold2: 0.0,
      );
    }
  }

  /// 하위 호환용 HRV SDNN 기반 생성자
  factory BreathingRoutineModel.fromHrv(double hrvSdnn) {
    return BreathingRoutineModel.fromMeasurement(bpm: 75, hrvSdnn: hrvSdnn);
  }
}
