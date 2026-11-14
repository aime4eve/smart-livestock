package com.smartlivestock.shared.security;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.config.BeanDefinition;
import org.springframework.context.annotation.ClassPathScanningCandidateComponentProvider;
import org.springframework.core.type.filter.AnnotationTypeFilter;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.util.ClassUtils;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * NIX-416 workspace-wide backstop: SecurityConfig only requires
 * "authenticated" for /api/v1/admin/** (no path-level role rule), so role
 * enforcement lives entirely at the controllers. Every controller mounted
 * under /api/v1/admin must therefore carry a declarative guard.
 *
 * <p>Rule per controller:
 * <ul>
 *   <li>a class-level @PreAuthorize and NO per-method @PreAuthorize — a
 *       method annotation would REPLACE the class-level guard, not AND
 *       with it, silently unprotecting every sibling endpoint; or</li>
 *   <li>no class-level guard and every endpoint method annotated
 *       individually (DataGenAdminController style).</li>
 * </ul>
 *
 * <p>Exempt: {@code DeploymentLicenseAdminController} — NIX-191's
 * first-certificate window makes enrollment/import reachable anonymously,
 * so its platform-admin checks are conditional in-body guards.
 *
 * <p>A blanket {@code requestMatchers("/api/v1/admin/**")} rule in
 * SecurityConfig is deliberately NOT the fix: TileAdminController and the
 * drinking/baseline admin controllers legitimately serve B2B_ADMIN, and the
 * license window needs anonymous POST — a path rule would need its own
 * carve-out list kept in sync with the annotations. This scan is the single
 * enforcement point instead.
 */
class AdminControllerPreAuthorizeCoverageTest {

    /** Structural exemptions, each with its reason pinned at the class. */
    private static final Set<Class<?>> EXEMPT = Set.of(
            com.smartlivestock.licensing.interfaces.admin.DeploymentLicenseAdminController.class);

    @Test
    void everyAdminController_hasDeclarativeGuard() throws ClassNotFoundException {
        List<Class<?>> controllers = scanAdminControllers();

        assertTrue(controllers.size() >= 30,
                () -> "expected the full /api/v1/admin controller family (>=30), the scan "
                        + "found only " + controllers.size() + " — did it silently degrade?");

        for (Class<?> controller : controllers) {
            if (EXEMPT.contains(controller)) {
                continue;
            }
            PreAuthorize classLevel = controller.getAnnotation(PreAuthorize.class);
            if (classLevel != null) {
                assertNoPerMethodOverride(controller);
            } else {
                assertEveryEndpointAnnotated(controller);
            }
        }
    }

    private static void assertNoPerMethodOverride(Class<?> controller) {
        for (Method method : controller.getDeclaredMethods()) {
            assertTrue(method.getAnnotation(PreAuthorize.class) == null,
                    () -> controller.getSimpleName() + "." + method.getName()
                            + "() declares a per-method @PreAuthorize that would REPLACE the "
                            + "class-level guard instead of narrowing it");
        }
    }

    private static void assertEveryEndpointAnnotated(Class<?> controller) {
        for (Method method : controller.getDeclaredMethods()) {
            if (!isEndpoint(method)) {
                continue;
            }
            assertTrue(method.getAnnotation(PreAuthorize.class) != null,
                    () -> controller.getSimpleName() + "." + method.getName()
                            + "() is an admin endpoint with neither class-level nor "
                            + "per-method @PreAuthorize (NIX-416 rule)");
        }
    }

    private static boolean isEndpoint(Method method) {
        if (method.getAnnotation(GetMapping.class) != null
                || method.getAnnotation(PostMapping.class) != null
                || method.getAnnotation(PutMapping.class) != null
                || method.getAnnotation(DeleteMapping.class) != null
                || method.getAnnotation(PatchMapping.class) != null) {
            return true;
        }
        return method.getAnnotation(RequestMapping.class) != null;
    }

    /** All @RestController classes whose class-level mapping sits under /api/v1/admin. */
    private static List<Class<?>> scanAdminControllers() throws ClassNotFoundException {
        ClassPathScanningCandidateComponentProvider scanner =
                new ClassPathScanningCandidateComponentProvider(false);
        scanner.addIncludeFilter(new AnnotationTypeFilter(RestController.class));

        List<Class<?>> adminControllers = new ArrayList<>();
        for (BeanDefinition bean : scanner.findCandidateComponents("com.smartlivestock")) {
            Class<?> type = ClassUtils.forName(bean.getBeanClassName(), null);
            RequestMapping mapping = type.getAnnotation(RequestMapping.class);
            if (mapping == null) {
                continue;
            }
            for (String path : mapping.path().length > 0 ? mapping.path() : mapping.value()) {
                if (path.startsWith("/api/v1/admin")) {
                    adminControllers.add(type);
                    break;
                }
            }
        }
        return adminControllers;
    }
}
