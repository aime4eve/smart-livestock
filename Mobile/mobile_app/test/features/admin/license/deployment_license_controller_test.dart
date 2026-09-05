import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/admin/license/domain/deployment_license_models.dart';
import 'package:hkt_livestock_agentic/features/admin/license/presentation/deployment_license_controller.dart';

import 'fake_license_repo.dart';

void main() {
  late FakeLicenseRepo repo;

  ProviderContainer setup() {
    repo = FakeLicenseRepo();
    return ProviderContainer(
      overrides: [deploymentLicenseRepositoryProvider.overrideWithValue(repo)],
    );
  }

  group('DeploymentLicenseController — build', () {
    test('ONPREM: loads mode + tenants and preselects first tenant', () async {
      final container = setup();
      addTearDown(container.dispose);

      final view = await container.read(deploymentLicenseControllerProvider.future);

      expect(repo.modeCalls, 1);
      expect(repo.tenantsCalls, 1);
      expect(view.mode!.isOnprem, isTrue);
      expect(view.tenants.length, 2);
      expect(view.selectedTenantId, 1);
      expect(view.enrollment!.installationId, 'inst-1');
      expect(view.current!.licenseId, 'lic-1');
      expect(repo.lastEnrollmentTenantId, 1);
      expect(repo.lastCurrentTenantId, 1);
    });

    test('HOSTED: loads mode but no tenant detail', () async {
      final container = setup();
      addTearDown(container.dispose);
      repo.mode = const LicenseModeInfo(mode: 'HOSTED', pilotLicenseEnabled: true);

      final view = await container.read(deploymentLicenseControllerProvider.future);

      expect(view.isHosted, isTrue);
      expect(repo.enrollmentCalls, 0);
      expect(repo.currentCalls, 0);
      expect(view.enrollment, isNull);
    });
  });

  group('DeploymentLicenseController — selectTenant', () {
    test('reloads enrollment + current for the picked tenant', () async {
      final container = setup();
      addTearDown(container.dispose);

      await container.read(deploymentLicenseControllerProvider.future);
      await container
          .read(deploymentLicenseControllerProvider.notifier)
          .selectTenant(2);

      final view = container.read(deploymentLicenseControllerProvider).value!;
      expect(view.selectedTenantId, 2);
      expect(repo.lastEnrollmentTenantId, 2);
      expect(repo.lastCurrentTenantId, 2);
      expect(repo.enrollmentCalls, 2);
      expect(repo.currentCalls, 2);
    });
  });

  group('DeploymentLicenseController — importLicense', () {
    test('calls the repository with the selected tenant + picked file and refreshes', () async {
      final container = setup();
      addTearDown(container.dispose);

      await container.read(deploymentLicenseControllerProvider.future);
      final before = repo.currentCalls;

      final result = await container
          .read(deploymentLicenseControllerProvider.notifier)
          .importLicense([1, 2, 3], 'tenant-1.sllicense');

      expect(result.licenseId, 'lic-9');
      expect(repo.lastImportCall, isNotNull);
      expect(repo.lastImportCall!.tenantId, 1);
      expect(repo.lastImportCall!.bytes, [1, 2, 3]);
      expect(repo.lastImportCall!.fileName, 'tenant-1.sllicense');

      final view = container.read(deploymentLicenseControllerProvider).value!;
      expect(view.lastImport!.licenseId, 'lic-9');
      // Import triggers a status refresh for the same tenant.
      expect(repo.currentCalls, greaterThan(before));
      expect(repo.lastCurrentTenantId, 1);
    });
  });
}
