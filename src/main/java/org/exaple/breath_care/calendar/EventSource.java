package org.exaple.breath_care.calendar;

/**
 * 일정이 어디서 들어왔는지.
 *
 * <p>동기화가 <b>직접 입력한 일정을 건드리지 않도록</b> 구분해 둔다.
 * 이 값이 없으면 폰 캘린더를 동기화할 때마다 손으로 넣은 일정이 사라진다.
 */
public enum EventSource {

    /** 앱에서 사용자가 직접 입력. */
    MANUAL,

    /** 폰 캘린더(구글·삼성 등)에서 동기화됨. 안드로이드는 이들을 한 창구로 읽어 온다. */
    PHONE
}
