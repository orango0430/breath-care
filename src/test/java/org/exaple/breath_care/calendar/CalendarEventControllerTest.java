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

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class CalendarEventControllerTest {

    private static final String EVENTS = "/api/calendar/events";

    @Autowired
    MockMvc mockMvc;

    private String token;

    @BeforeEach
    void signupAndLogin() throws Exception {
        token = tokenFor("owner@test.com");
    }

    private String tokenFor(String email) throws Exception {
        mockMvc.perform(post("/api/auth/signup").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"password123","nickname":"tester"}
                                """.formatted(email)))
                .andExpect(status().isCreated());

        String body = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"password123"}
                                """.formatted(email)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        int start = body.indexOf("\"accessToken\":\"") + "\"accessToken\":\"".length();
        return body.substring(start, body.indexOf('"', start));
    }

    private String eventBody(String title, String type, String startAt) {
        return """
                {"title":"%s","eventType":"%s","startAt":"%s"}
                """.formatted(title, type, startAt);
    }

    private Long createEvent(String token, String title, String type, String startAt) throws Exception {
        String body = mockMvc.perform(post(EVENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(eventBody(title, type, startAt)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        int start = body.indexOf("\"id\":") + "\"id\":".length();
        return Long.parseLong(body.substring(start, body.indexOf(',', start)));
    }

    @Test
    @DisplayName("일정을 등록하면 입력한 종류와 시각이 그대로 저장된다")
    void create() throws Exception {
        mockMvc.perform(post(EVENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(eventBody("중간고사", "EXAM", "2026-09-15T14:00:00+09:00")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.title").value("중간고사"))
                .andExpect(jsonPath("$.data.eventType").value("EXAM"))
                // +09:00로 보낸 값이 UTC로 저장된다 (14:00 KST = 05:00 UTC)
                .andExpect(jsonPath("$.data.startAt").value("2026-09-15T05:00:00Z"));
    }

    @Test
    @DisplayName("카테고리를 직접 지으면 그 이름이 표시명이 된다")
    void createWithCustomCategory() throws Exception {
        mockMvc.perform(post(EVENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"title":"정기 공연","eventType":"ETC","customCategory":"동아리",
                                 "startAt":"2026-09-15T14:00:00+09:00"}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.customCategory").value("동아리"))
                // 앱이 분기를 다시 짜지 않도록 서버가 표시명을 계산해 준다
                .andExpect(jsonPath("$.data.displayCategory").value("동아리"))
                // 이름만 바뀐다. 호흡 추천의 근거인 종류는 그대로 남는다
                .andExpect(jsonPath("$.data.eventType").value("ETC"));
    }

    @Test
    @DisplayName("카테고리를 안 지으면 종류의 기본 이름이 표시명이 된다")
    void displayCategoryFallsBackToEventType() throws Exception {
        mockMvc.perform(post(EVENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(eventBody("중간고사", "EXAM", "2026-09-15T14:00:00+09:00")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.customCategory").doesNotExist())
                .andExpect(jsonPath("$.data.displayCategory").value("시험"));
    }

    @Test
    @DisplayName("카테고리 이름이 20자를 넘으면 400")
    void rejectsTooLongCustomCategory() throws Exception {
        mockMvc.perform(post(EVENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"title":"공연","eventType":"ETC","customCategory":"%s",
                                 "startAt":"2026-09-15T14:00:00+09:00"}
                                """.formatted("가".repeat(21))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_INPUT"));
    }

    @Test
    @DisplayName("일정명이 비면 400")
    void create_blankTitle() throws Exception {
        mockMvc.perform(post(EVENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(eventBody("", "EXAM", "2026-09-15T14:00:00+09:00")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_INPUT"));
    }

    @Test
    @DisplayName("없는 일정 종류를 보내면 500이 아니라 400")
    void create_unknownEventType() throws Exception {
        mockMvc.perform(post(EVENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(eventBody("낮잠", "SLEEP", "2026-09-15T14:00:00+09:00")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_INPUT"));
    }

    @Test
    @DisplayName("토큰 없이 일정을 등록하면 401")
    void create_withoutToken() throws Exception {
        mockMvc.perform(post(EVENTS)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(eventBody("중간고사", "EXAM", "2026-09-15T14:00:00+09:00")))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("기간으로 조회하면 범위 안의 일정만 시각순으로 나온다")
    void findInRange() throws Exception {
        createEvent(token, "9월 발표", "PRESENTATION", "2026-09-10T10:00:00+09:00");
        createEvent(token, "9월 시험", "EXAM", "2026-09-20T10:00:00+09:00");
        createEvent(token, "10월 면접", "INTERVIEW", "2026-10-05T10:00:00+09:00");

        mockMvc.perform(get(EVENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .param("from", "2026-09-01T00:00:00Z")
                        .param("to", "2026-10-01T00:00:00Z"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(2))
                .andExpect(jsonPath("$.data[0].title").value("9월 발표"))
                .andExpect(jsonPath("$.data[1].title").value("9월 시험"));
    }

    @Test
    @DisplayName("기간을 생략하면 내 일정 전체가 나온다")
    void findAll_withoutRange() throws Exception {
        createEvent(token, "발표", "PRESENTATION", "2026-09-10T10:00:00+09:00");
        createEvent(token, "시험", "EXAM", "2026-09-20T10:00:00+09:00");

        mockMvc.perform(get(EVENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(2));
    }

    @Test
    @DisplayName("from 형식이 잘못되면 400")
    void findInRange_badFrom() throws Exception {
        mockMvc.perform(get(EVENTS)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .param("from", "어제"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_INPUT"));
    }

    @Test
    @DisplayName("일정을 수정할 수 있다")
    void update() throws Exception {
        Long id = createEvent(token, "중간고사", "EXAM", "2026-09-15T14:00:00+09:00");

        mockMvc.perform(put(EVENTS + "/" + id)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(eventBody("기말고사", "EXAM", "2026-12-15T09:00:00+09:00")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("기말고사"))
                .andExpect(jsonPath("$.data.startAt").value("2026-12-15T00:00:00Z"));
    }

    @Test
    @DisplayName("일정을 삭제하면 조회되지 않는다")
    void delete_event() throws Exception {
        Long id = createEvent(token, "면접", "INTERVIEW", "2026-09-15T14:00:00+09:00");

        mockMvc.perform(delete(EVENTS + "/" + id)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk());

        mockMvc.perform(get(EVENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(jsonPath("$.data.length()").value(0));
    }

    @Test
    @DisplayName("없는 일정을 수정하면 404")
    void update_notFound() throws Exception {
        mockMvc.perform(put(EVENTS + "/99999")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(eventBody("없음", "ETC", "2026-09-15T14:00:00+09:00")))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("남의 일정은 조회·수정·삭제 모두 막힌다")
    void otherUsersEvent_isInaccessible() throws Exception {
        Long myEventId = createEvent(token, "내 시험", "EXAM", "2026-09-15T14:00:00+09:00");
        String otherToken = tokenFor("other@test.com");

        // 목록에 남의 일정이 섞이지 않는다
        mockMvc.perform(get(EVENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + otherToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(0));

        // 존재 여부가 새지 않도록 403이 아니라 404
        mockMvc.perform(put(EVENTS + "/" + myEventId)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + otherToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(eventBody("가로채기", "ETC", "2026-09-15T14:00:00+09:00")))
                .andExpect(status().isNotFound());

        mockMvc.perform(delete(EVENTS + "/" + myEventId)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + otherToken))
                .andExpect(status().isNotFound());

        // 원래 주인에게는 그대로 남아 있다
        mockMvc.perform(get(EVENTS).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(jsonPath("$.data.length()").value(1));
    }
}
