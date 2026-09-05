package com.smartlivestock.licensing.interfaces;

import com.smartlivestock.licensing.domain.DeploymentLicenseState;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseStateRepository;
import com.smartlivestock.licensing.infrastructure.config.LicenseProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Optional;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Unit tests for the public deployment-info endpoint (login-screen badge).
 */
class DeploymentInfoControllerTest {

    private final DeploymentLicenseStateRepository stateRepository = mock(DeploymentLicenseStateRepository.class);
    private LicenseProperties properties;
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        properties = new LicenseProperties();
        mockMvc = MockMvcBuilders.standaloneSetup(
                        new DeploymentInfoController(properties, stateRepository))
                .build();
    }

    @Test
    void hostedModeReportsNullRuntimeStatus() throws Exception {
        mockMvc.perform(get("/api/v1/deployment-info"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value("OK"))
                .andExpect(jsonPath("$.data.mode").value("HOSTED"))
                .andExpect(jsonPath("$.data.runtimeStatus").doesNotExist());
    }

    @Test
    void onpremModeReportsLatestRuntimeStatus() throws Exception {
        properties.setMode(LicenseProperties.LicenseMode.ONPREM);
        DeploymentLicenseState state = new DeploymentLicenseState();
        state.setRuntimeStatus(com.smartlivestock.licensing.domain.LicenseRuntimeStatus.PENDING_ACTIVATION);
        when(stateRepository.findLatest()).thenReturn(Optional.of(state));

        mockMvc.perform(get("/api/v1/deployment-info"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.mode").value("ONPREM"))
                .andExpect(jsonPath("$.data.runtimeStatus").value("PENDING_ACTIVATION"));
    }

    @Test
    void onpremModeWithoutStateReportsNullRuntimeStatus() throws Exception {
        properties.setMode(LicenseProperties.LicenseMode.ONPREM);
        when(stateRepository.findLatest()).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/v1/deployment-info"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.mode").value("ONPREM"))
                .andExpect(jsonPath("$.data.runtimeStatus").doesNotExist());
    }
}
