import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/physiology/domain/physiology_models.dart';
import 'package:hkt_livestock_agentic/features/physiology/domain/physiology_repository.dart';
import 'package:hkt_livestock_agentic/features/physiology/presentation/physiology_controller.dart';

class _FakePhysiologyRepository implements PhysiologyRepository {
  int listCallCount = 0;
  final List<int> updatedEventIds = [];
  final List<int> deletedEventIds = [];
  String? lastUpdateNote;
  DateTime? lastUpdateOccurredAt;

  @override
  Future<PhysiologyEventListResponse> listEvents(String livestockId) async {
    listCallCount++;
    return PhysiologyEventListResponse(
      items: [
        PhysiologyEventItem(
          id: 31,
          livestockId: livestockId,
          eventType: PhysiologyEventType.illness,
          source: PhysiologySource.manual,
          occurredAt: DateTime.utc(2026, 10, 1, 3),
          active: false,
        ),
      ],
    );
  }

  @override
  Future<PhysiologyEventItem> createEvent({
    required String livestockId,
    required PhysiologyEventType eventType,
    required DateTime occurredAt,
    String? note,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<PhysiologyEventItem> updateEvent({
    required String livestockId,
    required int eventId,
    required DateTime occurredAt,
    String? note,
  }) async {
    updatedEventIds.add(eventId);
    lastUpdateNote = note;
    lastUpdateOccurredAt = occurredAt;
    return PhysiologyEventItem(
      id: eventId,
      livestockId: livestockId,
      eventType: PhysiologyEventType.illness,
      source: PhysiologySource.manual,
      occurredAt: occurredAt,
      active: false,
    );
  }

  @override
  Future<void> deleteEvent({
    required String livestockId,
    required int eventId,
  }) async {
    deletedEventIds.add(eventId);
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  ProviderContainer setup(_FakePhysiologyRepository repo) {
    return ProviderContainer(
      overrides: [
        physiologyRepositoryProvider.overrideWithValue(repo),
        initialSessionProvider.overrideWithValue(
          const AppSession.authenticated(
            role: UserRole.owner,
            accessToken: 'token',
            activeFarmId: 'farm-1',
          ),
        ),
      ],
    );
  }

  group('PhysiologyEventListController row-level edit/delete (M7)', () {
    test('updateEvent delegates to the repository then refreshes the list',
        () async {
      final repo = _FakePhysiologyRepository();
      final container = setup(repo);
      addTearDown(container.dispose);

      container.read(physiologyEventsControllerProvider('12'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final listCallsBefore = repo.listCallCount;

      await container
          .read(physiologyEventsControllerProvider('12').notifier)
          .updateEvent(
            eventId: 31,
            occurredAt: DateTime(2026, 10, 2),
            note: 'moved date',
          );

      expect(repo.updatedEventIds, [31]);
      expect(repo.lastUpdateNote, 'moved date');
      // invalidateSelf is lazy: re-reading re-runs the list build.
      container.read(physiologyEventsControllerProvider('12'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repo.listCallCount, greaterThan(listCallsBefore));
    });

    test('deleteEvent delegates to the repository then refreshes the list',
        () async {
      final repo = _FakePhysiologyRepository();
      final container = setup(repo);
      addTearDown(container.dispose);

      container.read(physiologyEventsControllerProvider('12'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final listCallsBefore = repo.listCallCount;

      await container
          .read(physiologyEventsControllerProvider('12').notifier)
          .deleteEvent(eventId: 31);

      expect(repo.deletedEventIds, [31]);
      container.read(physiologyEventsControllerProvider('12'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repo.listCallCount, greaterThan(listCallsBefore));
    });
  });

  group('PhysiologyApiRepository note clearing (N17)', () {
    // The wire contract (backend c836b14e): null/omitted keeps the old
    // note, an empty string clears it. This locks in the request body the
    // real repository builds, one layer below the fake-repo tests above.
    test('updateEvent(note: "") puts an explicit empty note on the wire',
        () async {
      // Stub backend: captures PUT bodies and answers the
      // {code:'OK', data:{...}} envelope ApiClient expects.
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      const okEvent = {
        'code': 'OK',
        'data': {
          'id': 31,
          'livestockId': '12',
          'eventType': 'ILLNESS',
          'source': 'MANUAL',
          'occurredAt': '2026-10-02T00:00:00Z',
          'active': false,
        },
      };
      const okEmptyList = {
        'code': 'OK',
        'data': {'items': <dynamic>[]},
      };

      final putBodies = <Map<String, dynamic>>[];
      () async {
        await for (final request in server) {
          final raw = await utf8.decoder.bind(request).join();
          if (request.method == 'PUT') {
            putBodies.add(jsonDecode(raw) as Map<String, dynamic>);
          }
          request.response.statusCode = 200;
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode(request.method == 'PUT' ? okEvent : okEmptyList),
          );
          await request.response.close();
        }
      }();

      final previousBaseUrl = ApiClient.instance.baseUrl;
      ApiClient.instance.setBaseUrl('http://127.0.0.1:${server.port}');
      ApiClient.instance.setActiveFarmId('farm-1');
      addTearDown(() {
        ApiClient.instance.setBaseUrl(previousBaseUrl);
        ApiClient.instance.setActiveFarmId(null);
      });

      // Real repository this time — no physiologyRepositoryProvider override.
      final container = ProviderContainer(
        overrides: [
          initialSessionProvider.overrideWithValue(
            const AppSession.authenticated(
              role: UserRole.owner,
              accessToken: 'token',
              activeFarmId: 'farm-1',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(physiologyEventsControllerProvider('12'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container
          .read(physiologyEventsControllerProvider('12').notifier)
          .updateEvent(
            eventId: 31,
            occurredAt: DateTime(2026, 10, 2),
            note: '',
          );

      expect(putBodies, hasLength(1));
      // The empty note must be sent, not omitted: an omitted field would
      // silently keep the old value server-side.
      expect(putBodies.single, containsPair('note', ''));
    });
  });
}
