package org.exaple.breath_care.global.persistence;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.json.JsonMapper;

import java.util.List;

/**
 * 문자열 목록을 JSON 배열 한 칸에 담는다.
 *
 * <p>목록을 별도 테이블로 빼면 조인이 늘고 순서를 지키려 정렬 컬럼까지 붙여야 한다.
 * 리포트의 insights·advice는 통째로 읽고 통째로 쓰기만 하므로 한 칸에 넣는 편이 단순하다.
 */
@Converter
public class StringListConverter implements AttributeConverter<List<String>, String> {

    private static final ObjectMapper MAPPER = JsonMapper.builder().build();
    private static final String EMPTY = "[]";

    @Override
    public String convertToDatabaseColumn(List<String> attribute) {
        return (attribute == null || attribute.isEmpty()) ? EMPTY : MAPPER.writeValueAsString(attribute);
    }

    @Override
    public List<String> convertToEntityAttribute(String dbData) {
        if (dbData == null || dbData.isBlank()) {
            return List.of();
        }
        return List.of(MAPPER.readValue(dbData, String[].class));
    }
}
