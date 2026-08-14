package org.exaple.breath_care.calendar;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 폰 캘린더 동기화.
 *
 * <p>지켜야 할 두 가지를 중심으로 본다.
 * 여러 번 실행해도 결과가 같을 것, 그리고 직접 입력한 일정을 건드리지 않을 것.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class CalendarSyncControllerTest {

    private static final String SYNC = "/api/calendar/sync";
    private static final String EVENTS = "/api/calendar/events";

    private static final String FROM = "2026-09-01T00:00:00Z";
    private static final String TO = "2026-10-01T00:00:00Z";

    @Autowired
    MockMvc mockMvc;
    @Autowired
    CalendarEventRepository eventRepository;

    private String token;

    @BeforeEach
    void login() throws Exception {
        mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"sync@test.com","password":"password123","nickname":"sync"}
                                """))
                .andExpect(status().isCreated());

        String body = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"sync@test.com","password":"password123"}
                                """))
                .andReturn().getResponse().getContentAsString();

        int start = body.indexOf("\"accessToken\":\"") + "\"accessToken\":\"".length();
        token = body.substring(start, body.indexOf('"', start));
    }

    /** events 부분만 넣어 동기화 본문을 만든다. */
    private String syncBody(String events) {
        return """
                {"from":"%s","to":"%s","events":[%s]}
                """.formatted(FROM, TO, events);
    }

    private static String event(String externalId, String title, String startAt) {
        return """
                {"externalId":"%s","title":"%s","startAt":"%s"}
                """.formatted(externalId, title, startAt);
    }

    private org.springframework.test.web.servlet.ResultActions sync(String events) throws Exception {
        return mockMvc.perform(post(SYNC)
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(syncBody(events)));
    }

    @Test
    @DisplayName("폰 일정을 가져와 저장한다")
    void importsPhoneEvents() throws Exception {
        sync(event("phone-1", "중간고사", "2026-09-10T01:00:00Z") + ","
                + event("phone-2", "팀 발표", "2026-09-12T05:00:00Z"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.created").value(2))
                .andExpect(jsonPath("$.data.updated").value(0))
                .andExpect(jsonPath("$.data.deleted").value(0));

        mockMvc.perform(get(EVENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(jsonPath("$.data.length()").value(2))
                .andExpect(jsonPath("$.data[0].source").value("PHONE"))
                // 폰 일정에는 종류 정보가 없다
                .andExpect(jsonPath("$.data[0].eventType").doesNotExist());
    }

    @Test
    @DisplayName("같은 내용으로 다시 동기화해도 일정이 늘지 않는다")
    void isIdempotent() throws Exception {
        String events = event("phone-1", "중간고사", "2026-09-10T01:00:00Z");

        sync(events).andExpect(jsonPath("$.data.created").value(1));
        long afterFirst = eventRepository.count();

        sync(events)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.created").value(0))
                // 바뀐 게 없으므로 갱신도 0이다
                .andExpect(jsonPath("$.data.updated").value(0));

        assertThat(eventRepository.count()).isEqualTo(afterFirst);
    }

    @Test
    @DisplayName("폰에서 제목이나 시각을 고치면 갱신된다")
    void updatesChangedEvent() throws Exception {
        sync(event("phone-1", "중간고사", "2026-09-10T01:00:00Z"));

        sync(event("phone-1", "중간고사 (강의실 변경)", "2026-09-10T03:00:00Z"))
                .andExpect(jsonPath("$.data.created").value(0))
                .andExpect(jsonPath("$.data.updated").value(1));

        mockMvc.perform(get(EVENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].title").value("중간고사 (강의실 변경)"));
    }

    @Test
    @DisplayName("폰에서 지운 일정은 서버에서도 지운다")
    void removesVanishedEvents() throws Exception {
        sync(event("phone-1", "중간고사", "2026-09-10T01:00:00Z") + ","
                + event("phone-2", "취소된 발표", "2026-09-12T05:00:00Z"));

        // phone-2가 빠진 채로 다시 동기화
        sync(event("phone-1", "중간고사", "2026-09-10T01:00:00Z"))
                .andExpect(jsonPath("$.data.deleted").value(1));

        mockMvc.perform(get(EVENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].title").value("중간고사"));
    }

    @Test
    @DisplayName("직접 입력한 일정은 동기화가 건드리지 않는다")
    void neverTouchesManualEvents() throws Exception {
        mockMvc.perform(post(EVENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"title":"직접 넣은 면접","eventType":"INTERVIEW","startAt":"2026-09-15T02:00:00Z"}
                                """))
                .andExpect(status().isCreated());

        // 폰 일정이 하나도 없는 상태로 동기화 → 직접 입력한 것은 살아남아야 한다
        sync("")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.deleted").value(0));

        mockMvc.perform(get(EVENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].title").value("직접 넣은 면접"))
                .andExpect(jsonPath("$.data[0].source").value("MANUAL"));
    }

    @Test
    @DisplayName("사용자가 고른 일정 종류는 다시 동기화해도 남는다")
    void keepsUserChosenEventType() throws Exception {
        sync(event("phone-1", "중간고사", "2026-09-10T01:00:00Z"));

        String list = mockMvc.perform(get(EVENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andReturn().getResponse().getContentAsString();
        int idStart = list.indexOf("\"id\":") + "\"id\":".length();
        String eventId = list.substring(idStart, list.indexOf(',', idStart));

        // 사용자가 앱에서 "시험"으로 지정
        mockMvc.perform(put(EVENTS + "/" + eventId).header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"title":"중간고사","eventType":"EXAM","startAt":"2026-09-10T01:00:00Z"}
                                """))
                .andExpect(status().isOk());

        // 폰에서 제목이 바뀌어 다시 동기화되어도 종류는 유지돼야 한다
        sync(event("phone-1", "중간고사 (2교시)", "2026-09-10T01:00:00Z"))
                .andExpect(jsonPath("$.data.updated").value(1));

        mockMvc.perform(get(EVENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(jsonPath("$.data[0].title").value("중간고사 (2교시)"))
                .andExpect(jsonPath("$.data[0].eventType").value("EXAM"));
    }

    @Test
    @DisplayName("동기화 구간 밖의 폰 일정은 지우지 않는다")
    void onlyDeletesInsideScannedRange() throws Exception {
        // 9월 일정을 넣어 둔다
        sync(event("phone-1", "9월 시험", "2026-09-10T01:00:00Z"));

        // 앱이 10월만 훑은 경우
        mockMvc.perform(post(SYNC).header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"from":"2026-10-01T00:00:00Z","to":"2026-11-01T00:00:00Z","events":[]}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.deleted").value(0));

        mockMvc.perform(get(EVENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(jsonPath("$.data.length()").value(1));
    }

    @Test
    @DisplayName("같은 externalId가 중복으로 와도 실패하지 않는다")
    void toleratesDuplicateExternalIds() throws Exception {
        sync(event("phone-1", "먼저 온 것", "2026-09-10T01:00:00Z") + ","
                + event("phone-1", "나중 것", "2026-09-10T01:00:00Z"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.created").value(1));

        mockMvc.perform(get(EVENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].title").value("나중 것"));
    }

    @Test
    @DisplayName("남의 일정은 동기화에 영향받지 않는다")
    void isScopedToUser() throws Exception {
        sync(event("phone-1", "내 시험", "2026-09-10T01:00:00Z"));

        mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"email":"sync-other@test.com","password":"password123","nickname":"o"}
                        """));
        String login = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"sync-other@test.com","password":"password123"}
                                """))
                .andReturn().getResponse().getContentAsString();
        int start = login.indexOf("\"accessToken\":\"") + "\"accessToken\":\"".length();
        String otherToken = login.substring(start, login.indexOf('"', start));

        // 다른 사용자가 빈 동기화를 해도 내 일정은 그대로다
        mockMvc.perform(post(SYNC).header(HttpHeaders.AUTHORIZATION, "Bearer " + otherToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(syncBody("")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.deleted").value(0));

        mockMvc.perform(get(EVENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(jsonPath("$.data.length()").value(1));
    }

    @Test
    @DisplayName("구간이 뒤집혀 있으면 400")
    void rejectsInvertedRange() throws Exception {
        mockMvc.perform(post(SYNC).header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"from":"2026-10-01T00:00:00Z","to":"2026-09-01T00:00:00Z","events":[]}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_INPUT"));
    }

    @Test
    @DisplayName("externalId가 없으면 400")
    void requiresExternalId() throws Exception {
        mockMvc.perform(post(SYNC).header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(syncBody("""
                                {"externalId":"","title":"제목","startAt":"2026-09-10T01:00:00Z"}
                                """)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_INPUT"));
    }

    @Test
    @DisplayName("토큰 없이 동기화하면 401")
    void requiresAuth() throws Exception {
        mockMvc.perform(post(SYNC).contentType(MediaType.APPLICATION_JSON).content(syncBody("")))
                .andExpect(status().isUnauthorized());
    }
}
