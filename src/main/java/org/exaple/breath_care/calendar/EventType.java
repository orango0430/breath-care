package org.exaple.breath_care.calendar;

/**
 * 일정 종류. 사용자가 직접 고른다.
 * 호흡 추천에서 어떤 프리셋을 쓸지 고르는 입력값이므로, 제목에서 추측하지 않고 명시적으로 받는다.
 * (제목은 "김교수님 수업 PT"처럼 키워드가 없는 경우가 많다)
 *
 * <p>시안의 카테고리 칩은 발표·시험·면접 셋이고, "+"로 직접 만든 이름은
 * {@link CalendarEvent#getCustomCategory()}에 들어간다. 그 경우 종류는 {@link #ETC}다.
 */
public enum EventType {

    /** 시험·중간고사·기말고사 */
    EXAM("시험"),
    /** 발표 */
    PRESENTATION("발표"),
    /** 면접 */
    INTERVIEW("면접"),
    /** 마감·데드라인 */
    DEADLINE("마감"),
    /** 위 어디에도 해당하지 않음 */
    ETC("일정");

    private final String label;

    EventType(String label) {
        this.label = label;
    }

    /** 알림 문구에 쓰는 이름. "내일 시험이 있어요"의 "시험". */
    public String getLabel() {
        return label;
    }
}
