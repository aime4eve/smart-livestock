package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.ranch.application.signal.SignalDtos.LivestockSignalResponse;
import com.smartlivestock.ranch.application.signal.SignalDtos.MapSignalResponse;
import com.smartlivestock.ranch.application.signal.SignalQueryService;
import com.smartlivestock.ranch.application.signal.SignalStreamTicketService;
import com.smartlivestock.ranch.application.signal.SignalStreamTicketService.TicketGrant;
import com.smartlivestock.ranch.infrastructure.signal.SignalStreamHub;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.time.Duration;
import java.util.List;

@RestController
@RequestMapping("/api/v1/farms/{farmId}/signals")
@RequiredArgsConstructor
public class SignalController {

    private static final String STREAM_TOKEN_COOKIE = "sl_signal_stream";

    private final SignalQueryService signalQueryService;
    private final SignalStreamTicketService streamTicketService;
    private final SignalStreamHub signalStreamHub;
    private final UserFarmAssignmentRepository userFarmAssignmentRepository;

    @GetMapping("/livestock")
    public ResponseEntity<ApiResponse<LivestockSignalResponse>> livestockSignals(
            @PathVariable Long farmId,
            @RequestParam List<Long> livestockIds,
            @RequestParam(defaultValue = "0") String cursor) {
        return ResponseEntity.ok(ApiResponse.ok(signalQueryService.getLivestockSignals(
                farmId, livestockIds, cursor, currentUserId()
        )));
    }

    @GetMapping("/map")
    public ResponseEntity<ApiResponse<MapSignalResponse>> mapSignals(
            @PathVariable Long farmId,
            @RequestParam(defaultValue = "0:0:0") String cursor,
            @RequestParam(defaultValue = "false") boolean includeGeometry) {
        return ResponseEntity.ok(ApiResponse.ok(signalQueryService.getMapSignals(
                farmId, cursor, includeGeometry, currentUserId()
        )));
    }

    @PostMapping("/stream-ticket")
    public ResponseEntity<ApiResponse<TicketResponse>> streamTicket(
            @PathVariable Long farmId,
            HttpServletRequest request
    ) {
        Long userId = currentUserId();
        Long tenantId = TenantContext.getCurrentTenant();
        if (userId == null || tenantId == null
                || !userFarmAssignmentRepository.existsByUserIdAndFarmIdAndStatus(
                        userId, farmId, "ACTIVE")) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权访问该牧场信号");
        }

        TicketGrant grant = streamTicketService.issue(userId, tenantId, farmId);
        boolean secureRequest = request.isSecure()
                || "https".equalsIgnoreCase(request.getHeader("X-Forwarded-Proto"));
        ResponseCookie cookie = ResponseCookie.from(
                        streamCookieName(grant.ticket()), grant.streamToken()
                )
                .httpOnly(true)
                .secure(secureRequest)
                .sameSite("Lax")
                .path("/api/v1/farms/" + farmId + "/signals/stream")
                .maxAge(Duration.ofMinutes(10))
                .build();
        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, cookie.toString())
                .body(ApiResponse.ok(new TicketResponse(grant.ticket())));
    }

    @GetMapping(path = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter stream(
            @PathVariable Long farmId,
            @RequestParam String ticket,
            @RequestParam(defaultValue = "0:0:0") String cursor,
            @RequestHeader(value = "Last-Event-ID", required = false) String lastEventId,
            HttpServletRequest request
    ) {
        TicketGrant grant = streamTicketService.consume(
                ticket, farmId, streamCookie(request, ticket),
                lastEventId != null && !lastEventId.isBlank()
        );
        return signalStreamHub.connect(
                grant,
                cursor,
                lastEventId,
                signalStreamHub.countUserFarmConnections(grant.userId(), farmId)
        );
    }

    private String streamCookie(HttpServletRequest request, String ticket) {
        Cookie[] cookies = request.getCookies();
        if (cookies == null) return null;
        String expectedName = streamCookieName(ticket);
        for (Cookie cookie : cookies) {
            if (expectedName.equals(cookie.getName())) {
                return cookie.getValue();
            }
        }
        return null;
    }

    private String streamCookieName(String ticket) {
        return STREAM_TOKEN_COOKIE + "_" + ticket;
    }

    private Long currentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof Long userId)) {
            return null;
        }
        return userId;
    }

    public record TicketResponse(String ticket) {}
}
