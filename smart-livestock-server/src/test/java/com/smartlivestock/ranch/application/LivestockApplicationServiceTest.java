package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.application.command.CreateLivestockCommand;
import com.smartlivestock.ranch.application.command.UpdateLivestockCommand;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.port.HealthQueryPort;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.domain.port.IoTCommandPort;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class LivestockApplicationServiceTest {

    @Mock
    private LivestockRepository livestockRepository;

    @Mock
    private HealthQueryPort healthQueryPort;

    @Mock
    private IoTQueryPort iotQueryPort;

    @Mock
    private IoTCommandPort iotCommandPort;

    @InjectMocks
    private LivestockApplicationService service;

    private CreateLivestockCommand createCommand() {
        return new CreateLivestockCommand(1L, "COW-001", "安格斯", "MALE",
                LocalDate.of(2024, 3, 15), new BigDecimal("450.5"));
    }

    @Test
    void shouldCreateLivestockWithAllFields() {
        when(livestockRepository.findByLivestockCode("COW-001")).thenReturn(Optional.empty());
        when(livestockRepository.save(any(Livestock.class))).thenAnswer(inv -> {
            Livestock l = inv.getArgument(0);
            l.setId(10L);
            return l;
        });

        var result = service.createLivestock(createCommand());

        assertThat(result.livestockCode()).isEqualTo("COW-001");
        assertThat(result.breed()).isEqualTo("安格斯");
        assertThat(result.gender()).isEqualTo("MALE");
        assertThat(result.weight()).isEqualByComparingTo(new BigDecimal("450.5"));
    }

    @Test
    void shouldRejectDuplicateLivestockCode() {
        Livestock existing = new Livestock();
        existing.setId(99L);
        when(livestockRepository.findByLivestockCode("COW-001")).thenReturn(Optional.of(existing));

        assertThatThrownBy(() -> service.createLivestock(createCommand()))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.DUPLICATE_RESOURCE);
                });
    }

    @Test
    void shouldUpdateLivestockFields() {
        Livestock existing = new Livestock(1L, "COW-001", "安格斯", "MALE",
                LocalDate.of(2024, 3, 15), new BigDecimal("450"));
        existing.setId(10L);
        when(livestockRepository.findById(10L)).thenReturn(Optional.of(existing));
        when(livestockRepository.save(any(Livestock.class))).thenAnswer(inv -> inv.getArgument(0));

        var cmd = new UpdateLivestockCommand("COW-001", "和牛", "FEMALE",
                LocalDate.of(2024, 5, 1), new BigDecimal("500"));
        var result = service.updateLivestock(10L, cmd);

        assertThat(result.breed()).isEqualTo("和牛");
        assertThat(result.gender()).isEqualTo("FEMALE");
        assertThat(result.weight()).isEqualByComparingTo(new BigDecimal("500"));
    }

    @Test
    void shouldRejectUpdateWithDuplicateCode() {
        Livestock existing = new Livestock(1L, "COW-001", "安格斯", "MALE",
                LocalDate.of(2024, 3, 15), new BigDecimal("450"));
        existing.setId(10L);
        Livestock other = new Livestock(2L, "COW-002", "和牛", "FEMALE",
                LocalDate.of(2024, 5, 1), new BigDecimal("500"));
        other.setId(20L);

        when(livestockRepository.findById(10L)).thenReturn(Optional.of(existing));
        when(livestockRepository.findByLivestockCode("COW-002")).thenReturn(Optional.of(other));

        var cmd = new UpdateLivestockCommand("COW-002", "和牛", "FEMALE",
                LocalDate.of(2024, 5, 1), new BigDecimal("500"));
        assertThatThrownBy(() -> service.updateLivestock(10L, cmd))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.DUPLICATE_RESOURCE);
                });
    }

    @Test
    void shouldCascadeUninstallDevicesOnDelete() {
        Livestock existing = new Livestock(1L, "COW-001", "安格斯", "MALE",
                LocalDate.of(2024, 3, 15), new BigDecimal("450"));
        existing.setId(10L);
        when(livestockRepository.findById(10L)).thenReturn(Optional.of(existing));
        // No exception expected — cascade uninstall should happen silently
        service.deleteLivestock(10L);
        verify(iotCommandPort).removeAllActiveInstallations(10L);
        verify(livestockRepository).deleteById(10L);
    }
}
