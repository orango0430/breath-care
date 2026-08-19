package org.exaple.breath_care.measurement.signal;

import org.exaple.breath_care.measurement.MeasurementQuality;
import org.exaple.breath_care.measurement.score.ConditionScoreCalculator;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.json.JsonMapper;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 실측 파형으로 {@link PpgSignalProcessor}를 검증하고 상수를 맞추는 자리.
 *
 * <p><b>지금 이 프로젝트의 모든 신호처리 상수는 합성 신호 기준이다.</b>
 * {@code PpgSignalProcessorTest}는 내가 만든 파형을 내가 되찾는지만 본다. 그래서 알고리즘이
 * 스스로 모순되지 않는다는 것까지만 증명하고, 실제 손가락과 실제 카메라에서 맞는지는 말해주지 않는다.
 * 그 간극을 메우는 것이 이 테스트다.
 *
 * <h2>파형이 없으면 조용히 건너뛴다</h2>
 * {@code src/test/resources/calibration/}에 파일이 없으면 테스트를 만들지 않는다.
 * 실측 데이터가 들어오기 전까지 빌드를 빨갛게 만들지 않기 위해서다. 파일을 넣는 순간부터
 * 게이트로 동작한다.
 *
 * <h2>파형을 얻는 방법</h2>
 * 따로 추출을 부탁할 필요가 없다. {@code POST /api/measurements}는 원시 파형을
 * {@code measurement_signal} 테이블에 그대로 저장한다. 앱 연동만 붙으면 실측이 쌓인다.
 * README에 꺼내는 SQL이 있다.
 *
 * <h2>파일 형식</h2>
 * 두 가지를 모두 읽는다. 프론트가 주는 형식을 손보지 않고 그대로 넣을 수 있어야 하기 때문이다.
 * 자세한 것은 {@code src/test/resources/calibration/README.md}.
 */
class PpgCalibrationTest {

    /** 파형을 놓는 곳. 시스템 속성으로 다른 폴더를 가리킬 수 있다. */
    private static final Path DIRECTORY =
            Paths.get(System.getProperty("calibration.dir", "src/test/resources/calibration"));

    /**
     * 기준 심박수와 이만큼까지 벌어져도 통과로 본다.
     *
     * <p>스마트워치와 카메라 PPG는 같은 심장을 재도 값이 정확히 같지 않다. 측정 구간이 다르고
     * 워치는 대개 몇 초 평균을 보여준다. 임상 검증에서 쓰는 기준(평균 오차 ±5bpm)을 그대로 가져왔다.
     * [튜닝 대상]
     */
    private static final double TOLERANCE_BPM = 5.0;

    @TestFactory
    Stream<DynamicTest> replaysRecordedWaveforms() throws IOException {
        List<Path> files = findWaveformFiles();
        if (files.isEmpty()) {
            // 빈 스트림을 돌려주면 그레이들이 "테스트 없음"으로 빌드를 실패시킨다.
            // 건너뛴 테스트 하나를 남겨 두면 실측이 아직 없다는 사실이 결과에 계속 보인다.
            return Stream.of(DynamicTest.dynamicTest("실측 파형 없음",
                    () -> org.junit.jupiter.api.Assumptions.abort(
                            "%s 가 비어 있다. 신호처리 상수가 아직 합성 신호 기준이라는 뜻이다."
                                    .formatted(DIRECTORY.toAbsolutePath()))));
        }

        PpgSignalProcessor processor = new PpgSignalProcessor();
        printHeader();

        return files.stream().map(file -> DynamicTest.dynamicTest(file.getFileName().toString(),
                () -> verify(processor, Waveform.read(file))));
    }

    private void verify(PpgSignalProcessor processor, Waveform waveform) {
        SignalResult result = processor.process(waveform.samples(), waveform.fps());
        Double conditionScore = ConditionScoreCalculator.score(result.hrvSdnn());
        printRow(waveform, result, conditionScore);

        if (waveform.expectPoor()) {
            // 일부러 못 잰 파형이다. 품질 게이트가 걸러내지 못하면 사용자는 엉터리 값을 진짜로 받는다.
            assertThat(result.quality())
                    .as("%s: 걸러내야 할 파형인데 통과했다 (hr=%s)", waveform.label(), result.hr())
                    .isEqualTo(MeasurementQuality.POOR);
            return;
        }

        assertThat(result.quality())
                .as("%s: 정상 파형인데 품질 게이트에 걸렸다", waveform.label())
                .isNotEqualTo(MeasurementQuality.POOR);

        if (waveform.expectedBpm() == null) {
            // 기준 심박수 없이 찍힌 파형. 품질 판정까지만 보고 정확도는 못 본다.
            return;
        }

        assertThat(result.hr())
                .as("%s: 기준 %.0fbpm 대비 오차가 %.1fbpm를 넘는다",
                        waveform.label(), waveform.expectedBpm(), TOLERANCE_BPM)
                .isCloseTo(waveform.expectedBpm(), org.assertj.core.data.Offset.offset(TOLERANCE_BPM));
    }

    private List<Path> findWaveformFiles() throws IOException {
        if (!Files.isDirectory(DIRECTORY)) {
            return List.of();
        }
        try (Stream<Path> entries = Files.list(DIRECTORY)) {
            return entries.filter(p -> p.getFileName().toString().endsWith(".json"))
                    .sorted(Comparator.comparing(Path::getFileName))
                    .toList();
        }
    }

    private void printHeader() {
        System.out.printf("%n[보정] %s%n", DIRECTORY.toAbsolutePath());
        System.out.printf("%-24s %5s %4s %6s %7s %7s %7s %7s %6s %7s%n",
                "파일", "샘플", "fps", "품질", "심박", "기준", "오차", "RMSSD", "SDNN", "컨디션");
        System.out.println("-".repeat(92));
    }

    private void printRow(Waveform waveform, SignalResult result, Double conditionScore) {
        String expected = waveform.expectedBpm() == null ? "-" : "%.0f".formatted(waveform.expectedBpm());
        String error = (waveform.expectedBpm() == null || result.hr() == null)
                ? "-" : "%+.1f".formatted(result.hr() - waveform.expectedBpm());

        System.out.printf("%-24s %5d %4d %6s %7s %7s %7s %7s %6s %7s%n",
                trim(waveform.label()), waveform.samples().length, waveform.fps(), result.quality(),
                format(result.hr()), expected, error,
                format(result.hrv()), format(result.hrvSdnn()), format(conditionScore));
    }

    private static String trim(String label) {
        return label.length() <= 24 ? label : label.substring(0, 21) + "...";
    }

    private static String format(Double value) {
        return value == null ? "-" : "%.1f".formatted(value);
    }

    /**
     * 파형 파일 하나. 프론트가 주는 형식과 API 요청 형식을 모두 읽는다.
     *
     * @param expectedBpm 스마트워치·산소포화도계로 잰 정답. 없으면 null이고 정확도는 검증하지 않는다
     * @param expectPoor  일부러 못 잰 파형이면 true. 품질 게이트가 걸러내는지 본다
     */
    private record Waveform(String label, double[] samples, int fps, Double expectedBpm, boolean expectPoor) {

        private static final ObjectMapper MAPPER = JsonMapper.builder().build();

        static Waveform read(Path file) throws IOException {
            JsonNode root = MAPPER.readTree(file.toFile());
            String name = file.getFileName().toString().replace(".json", "");

            return new Waveform(
                    root.path("label").asString(name),
                    samples(root),
                    fps(root),
                    expectedBpm(root),
                    expectPoor(root, name));
        }

        /**
         * 샘플 배열. 두 형식을 받는다.
         * <ul>
         *   <li>{@code "samples": [218.4, 221.8, ...]} — API 요청과 같은 형식</li>
         *   <li>{@code "raw_signal_samples": [{"t_ms":0,"red_avg":218.4}, ...]} — 프론트가 주는 형식</li>
         * </ul>
         */
        private static double[] samples(JsonNode root) {
            JsonNode flat = root.path("samples");
            if (flat.isArray() && !flat.isEmpty()) {
                double[] values = new double[flat.size()];
                for (int i = 0; i < values.length; i++) {
                    values[i] = flat.get(i).asDouble();
                }
                return values;
            }

            JsonNode nested = root.path("raw_signal_samples");
            if (!nested.isArray() || nested.isEmpty()) {
                throw new IllegalArgumentException(
                        "samples 또는 raw_signal_samples가 없다. README의 형식을 보라");
            }

            List<Double> values = new ArrayList<>(nested.size());
            for (JsonNode sample : nested) {
                // 카메라 PPG는 빨강 채널을 쓴다. 프론트가 avgY(휘도)를 보내면 그쪽을 읽는다
                JsonNode value = sample.has("red_avg") ? sample.get("red_avg") : sample.path("y_avg");
                if (value.isMissingNode()) {
                    throw new IllegalArgumentException("raw_signal_samples 항목에 red_avg도 y_avg도 없다");
                }
                values.add(value.asDouble());
            }
            return values.stream().mapToDouble(Double::doubleValue).toArray();
        }

        /** fps는 명시값을 우선하고, 없으면 {@code t_ms} 간격에서 되찾는다. */
        private static int fps(JsonNode root) {
            if (root.hasNonNull("fps")) {
                return root.get("fps").asInt();
            }

            JsonNode nested = root.path("raw_signal_samples");
            if (nested.isArray() && nested.size() >= 2) {
                long first = nested.get(0).path("t_ms").asLong(-1);
                long last = nested.get(nested.size() - 1).path("t_ms").asLong(-1);
                if (first >= 0 && last > first) {
                    double stepMs = (double) (last - first) / (nested.size() - 1);
                    return (int) Math.round(1000.0 / stepMs);
                }
            }

            // 안드로이드 카메라 미리보기 기본값. 파일에 아무 단서가 없을 때만 쓴다
            return 30;
        }

        /**
         * 정답 심박수. {@code expectedBpm}을 먼저 보고, 없으면 프론트가 계산해 넣은
         * {@code calculated_metrics.bpm}을 쓴다.
         *
         * <p><b>후자는 정답이 아니다.</b> 같은 파형을 프론트 알고리즘이 어떻게 읽었는지일 뿐이라,
         * 둘이 함께 틀려도 통과한다. 스마트워치로 잰 값을 {@code expectedBpm}에 적는 편이 낫다.
         */
        private static Double expectedBpm(JsonNode root) {
            if (root.hasNonNull("expectedBpm")) {
                return root.get("expectedBpm").asDouble();
            }
            JsonNode metrics = root.path("calculated_metrics");
            return metrics.hasNonNull("bpm") ? metrics.get("bpm").asDouble() : null;
        }

        /** 파일명에 bad/poor가 들어가도 못 잰 파형으로 본다. 매번 플래그를 적지 않아도 되게. */
        private static boolean expectPoor(JsonNode root, String name) {
            if (root.hasNonNull("expectPoor")) {
                return root.get("expectPoor").asBoolean();
            }
            String lower = name.toLowerCase();
            return lower.contains("bad") || lower.contains("poor");
        }
    }
}
