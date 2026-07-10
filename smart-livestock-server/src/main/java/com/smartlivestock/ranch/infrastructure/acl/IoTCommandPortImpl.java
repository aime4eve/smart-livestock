package com.smartlivestock.ranch.infrastructure.acl;

import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.ranch.domain.port.IoTCommandPort;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class IoTCommandPortImpl implements IoTCommandPort {

    private final InstallationRepository installationRepository;

    public IoTCommandPortImpl(InstallationRepository installationRepository) {
        this.installationRepository = installationRepository;
    }

    @Override
    public void removeAllActiveInstallations(Long livestockId) {
        List<Installation> active = installationRepository.findAllActiveByLivestockId(livestockId);
        for (Installation installation : active) {
            installation.remove();
            installationRepository.save(installation);
        }
    }
}
