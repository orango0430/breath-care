# 실측 파형 보정용 폴더

여기에 `.json` 파형을 넣으면 `PpgCalibrationTest`가 자동으로 읽어서
`PpgSignalProcessor`에 통과시키고 결과를 표로 찍는다. **폴더가 비어 있으면 조용히 건너뛴다.**

지금 신호처리 상수는 전부 합성 신호 기준이다. 실측이 들어와야 확정된다.

| 파일 | 상수 |
|---|---|
| `PpgSignalProcessor` | 통과 대역, 관류 하한, 피크 임계 비율, RR 이상치 허용폭 |
| `ConditionScoreCalculator` | 기울기 1.4, 절편 40, 하한 50, **상한 96** |

특히 상한이 급하다. 지금 공식은 **SDNN 40ms 위가 전부 96점**이라 건강한 사람끼리 구별이 안 된다.
20초 측정에서 SDNN이 실제로 어느 대역에 떨어지는지 봐야 고칠 수 있다.

## 돌리는 법

```bash
./gradlew test --tests '*PpgCalibrationTest' -i
```

```
[보정] .../src/test/resources/calibration
파일                       샘플  fps   품질     심박     기준     오차   RMSSD   SDNN    컨디션
--------------------------------------------------------------------------------------------
good-01-rest              900   30   GOOD    68.2     68     +0.2    41.3   31.5    84.1
good-02-after-stairs      900   30   GOOD    97.4     94     +3.4    22.1   17.9    65.1
bad-01-finger-lifted      900   30   POOR       -      -        -       -      -       -
```

다른 폴더를 보게 하려면 `-Dcalibration.dir=경로`.

## 판정 기준

- `expectedBpm`이 있으면 **±5bpm** 안에 들어야 한다 (임상 검증에서 쓰는 기준)
- 파일명에 `bad` 또는 `poor`가 들어가면 **품질이 POOR로 나와야** 통과한다
- `expectedBpm`이 없으면 품질만 보고 정확도는 검증하지 않는다

## 파일 형식

두 가지를 다 읽는다. 프론트가 주는 걸 손보지 않고 그대로 넣을 수 있게 해뒀다.

### 형식 A — API 요청과 동일 (권장)

```json
{
  "label": "good-01-rest",
  "expectedBpm": 68,
  "note": "갤럭시워치 68bpm, 앉아서 안정 상태, 조명 실내등",
  "fps": 30,
  "samples": [218.4, 221.8, 224.1, ...]
}
```

### 형식 B — 프론트가 주는 형식

```json
{
  "device_info": "Samsung Galaxy Z Flip4 (SM-F721N)",
  "expectedBpm": 68,
  "raw_signal_samples": [
    {"t_ms": 0,  "red_avg": 218.4},
    {"t_ms": 33, "red_avg": 221.8}
  ]
}
```

- `fps`가 없으면 `t_ms` 간격에서 되찾는다
- `red_avg`가 없으면 `y_avg`를 읽는다
- `expectedBpm`이 없으면 `calculated_metrics.bpm`을 쓰지만, **그건 정답이 아니다.**
  같은 파형을 프론트 알고리즘이 어떻게 읽었는지일 뿐이라 둘이 함께 틀려도 통과한다.
  **스마트워치나 산소포화도계로 잰 값을 `expectedBpm`에 적어라.**

## 파형 얻는 법 — 따로 추출을 부탁하지 않아도 된다

`POST /api/measurements`는 원시 파형을 `measurement_signal` 테이블에 그대로 저장한다.
앱 연동만 붙으면 실측이 알아서 쌓인다.

```sql
SELECT s.measurement_id,
       s.fps,
       s.duration_sec,
       m.hr,
       m.hrv,
       m.hrv_sdnn,
       m.condition_score,
       m.quality,
       m.measured_at,
       s.samples
FROM measurement_signal s
JOIN measurement m ON m.id = s.measurement_id
ORDER BY s.measurement_id DESC
LIMIT 20;
```

`samples`는 쉼표로 이어 붙인 문자열이라 대괄호만 씌우면 형식 A의 `samples` 배열이 된다.

## 무엇을 모아야 하나

최소 6개. 좋은 것과 나쁜 것이 **둘 다** 있어야 한다.
좋은 것만 모으면 품질 게이트가 아무것도 안 걸러도 테스트가 통과한다.

**좋은 것 3개** — 파일명 `good-*`, `expectedBpm` 필수

1. 안정 상태 (앉아서, 실내등)
2. 심박 올린 뒤 (계단 오르내리고 바로)
3. 다른 사람 / 다른 기기

**나쁜 것 3개** — 파일명 `bad-*`, `expectedBpm` 없어도 됨

1. 손가락을 도중에 뗀 것
2. 손을 흔든 것 (움직임 잡음)
3. 손가락과 렌즈 사이로 빛이 샌 것

측정할 때마다 **스마트워치나 산소포화도계 심박수를 같이 적어야 한다.**
정답이 없으면 알고리즘이 맞는지 틀리는지 알 방법이 없다.

## 주의 — 프론트가 계산한 값은 정답이 아니다

전에 받은 `ppg_guided_measurement_sample.json`은 `hrv_sdnn_ms: 32.8`이라고 적혀 있는데,
같은 파일 안의 `inter_beat_intervals_ms` 8개로 직접 계산하면 **6.0**이 나온다.
파형은 0.33초(10샘플)뿐인데 IBI 배열은 6.5초를 덮고, 파형 주기로는 약 230bpm인데 74라고 적혀 있다.
손으로 만든 형식 예시지 기기에서 뽑은 기록이 아니다.

그래서 이 폴더에는 **기기에서 그대로 나온 파형**만 넣는다.
