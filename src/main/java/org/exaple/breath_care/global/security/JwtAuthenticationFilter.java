package org.exaple.breath_care.global.security;

import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

// 일부러 @Component를 붙이지 않는다. 빈으로 두면 Spring Boot가 서블릿 필터로도 자동 등록해
// 시큐리티 체인과 합쳐 두 번 실행된다. SecurityConfig에서 직접 생성해 등록한다.
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    /** 파싱된 claims를 컨트롤러에서 재사용하기 위한 요청 속성 키. (로그아웃에서 jti가 필요) */
    public static final String CLAIMS_ATTRIBUTE = "jwtClaims";

    private final JwtTokenProvider tokenProvider;
    private final TokenRevocationService revocationService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        BearerTokens.resolve(request)
                .flatMap(tokenProvider::parse)
                .filter(claims -> !revocationService.isRevoked(claims.getId()))
                .ifPresent(claims -> authenticate(request, claims));

        filterChain.doFilter(request, response);
    }

    private void authenticate(HttpServletRequest request, Claims claims) {
        Long userId = Long.valueOf(claims.getSubject());

        var authentication = new UsernamePasswordAuthenticationToken(userId, null, List.of());
        authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

        SecurityContextHolder.getContext().setAuthentication(authentication);
        request.setAttribute(CLAIMS_ATTRIBUTE, claims);
    }
}
