package com.ai.openapi;

import com.ai.openapi.entity.OpenApp;
import com.ai.openapi.mapper.OpenAppMapper;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/debug")
public class DebugController {

    private final BCryptPasswordEncoder passwordEncoder;
    private final OpenAppMapper openAppMapper;

    public DebugController(BCryptPasswordEncoder passwordEncoder, OpenAppMapper openAppMapper) {
        this.passwordEncoder = passwordEncoder;
        this.openAppMapper = openAppMapper;
    }

    @GetMapping("/hash")
    public Map<String, Object> generateHash(@RequestParam String plainText) {
        String hash = passwordEncoder.encode(plainText);
        boolean matches = passwordEncoder.matches(plainText, hash);
        Map<String, Object> result = new HashMap<>();
        result.put("plainText", plainText);
        result.put("hash", hash);
        result.put("hashLength", hash.length());
        result.put("matches", matches);
        return result;
    }

    @GetMapping("/verify")
    public Map<String, Object> verifyHash(@RequestParam String plainText, @RequestParam String hash) {
        boolean matches = passwordEncoder.matches(plainText, hash);
        Map<String, Object> result = new HashMap<>();
        result.put("plainText", plainText);
        result.put("hash", hash);
        result.put("hashLength", hash.length());
        result.put("matches", matches);
        return result;
    }

    @GetMapping("/app")
    public Map<String, Object> checkApp() {
        OpenApp app = openAppMapper.selectById(1L);
        Map<String, Object> result = new HashMap<>();
        if (app != null) {
            result.put("appId", app.getAppId());
            result.put("hash", app.getAppSecretHash());
            result.put("hashLength", app.getAppSecretHash().length());
            boolean matches = passwordEncoder.matches("secret", app.getAppSecretHash());
            result.put("matchesSecret", matches);
        } else {
            result.put("error", "未找到应用记录");
        }
        return result;
    }
}
