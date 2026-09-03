package com.smartlivestock.licensing.infrastructure.config;

import com.smartlivestock.licensing.infrastructure.CanonicalJsonSerializer;
import com.smartlivestock.licensing.infrastructure.ClasspathLicensePublicKeyRegistry;
import com.smartlivestock.licensing.infrastructure.Ed25519LicenseVerifier;
import com.smartlivestock.licensing.infrastructure.HostFingerprintReader;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.DefaultResourceLoader;
import org.springframework.core.io.Resource;

import java.nio.file.Paths;

/**
 * Bean wiring for the licensing signature infrastructure. The public key
 * registry loads eagerly so a missing or malformed trust root fails application
 * startup (fail fast) instead of failing the first license import.
 */
@Configuration
public class LicenseInfrastructureConfig {

    @Bean
    public CanonicalJsonSerializer licenseCanonicalJsonSerializer() {
        return new CanonicalJsonSerializer();
    }

    @Bean
    public ClasspathLicensePublicKeyRegistry licensePublicKeyRegistry(LicenseProperties properties) {
        Resource location = new DefaultResourceLoader().getResource(properties.getPublicKeyFile());
        return new ClasspathLicensePublicKeyRegistry(location);
    }

    @Bean
    public Ed25519LicenseVerifier licenseValidator(ClasspathLicensePublicKeyRegistry registry,
                                                   CanonicalJsonSerializer canonicalJsonSerializer,
                                                   LicenseProperties properties) {
        return new Ed25519LicenseVerifier(registry, canonicalJsonSerializer, properties.getTimeTolerance());
    }

    @Bean
    public HostFingerprintReader hostFingerprintReader(LicenseProperties properties) {
        // Lazily reads the source file: HOSTED deployments may legitimately have
        // no machine-id mounted, so only ONPREM usage triggers the fail-fast.
        return new HostFingerprintReader(Paths.get(properties.getHostFingerprintFile()));
    }
}
