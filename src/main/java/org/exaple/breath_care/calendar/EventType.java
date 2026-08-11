package org.exaple.breath_care.calendar;

/**
 * 일정 종류. 사용자가 직접 고른다.
 * 호흡 추천에서 어떤 프리셋을 쓸지 고르는 입력값이므로, 제목에서 추측하지 않고 명시적으로 받는다.
 * (제목은 "김교수님 수업 PT"처럼 키워드가 없는 경우가 많다)
 */
public enum EventType {

    /** 시험·중간고사·기말고사 */
    EXAM,
    /** 발표 */
    PRESENTATION,
    /** 면접 */
    INTERVIEW,
    /** 마감·데드라인 */
    DEADLINE,
    /** 위 어디에도 해당하지 않음 */
    ETC
}
