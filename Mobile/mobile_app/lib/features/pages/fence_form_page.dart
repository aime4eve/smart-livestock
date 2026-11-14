import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/map/map_constants.dart';
import 'package:hkt_livestock_agentic/core/map/coord_transform.dart';
import 'package:hkt_livestock_agentic/core/map/map_config.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_factory.dart';
import 'package:hkt_livestock_agentic/core/permissions/role_permission.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/farm_switcher/farm_switcher_controller.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/fence_item.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/fence_analytics.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/fence_controller.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/track_collect_page.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/track_draft_controller.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/track_draft_desktop_panel.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/track_draft_offline_probe.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/fence_template_picker.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/fence_track_import_dialog.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class FenceFormPage extends ConsumerStatefulWidget {
  const FenceFormPage({super.key, this.fenceId});

  final String? fenceId;

  @override
  ConsumerState<FenceFormPage> createState() => _FenceFormPageState();
}

class _FenceFormPageState extends ConsumerState<FenceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _formMapController = MapController();
  SmartTileProvider? _tileProvider;
  /// Form shape default. Deliberately `polygon` (NIX-415): it matches the
  /// API/parse default, and a `rectangle` default here used to mislabel any
  /// fence whose real shape had not loaded yet (deep-link edit window) and
  /// could even persist `shape: "rectangle"` onto a polygon fence saved
  /// through that window.
  FenceType _type = FenceType.polygon;
  FenceTemplate? _selectedTemplate;
  bool _alarmEnabled = true;
  bool _active = true;
  bool _saving = false;
  bool _initialized = false;

  /// NIX-415: the page only `read`s the fence controller, so fences arriving
  /// after mount (deep link straight into the edit form) never rebuild it —
  /// the subscription re-runs the edit init once the data lands.
  ProviderSubscription? _fenceStateSub;
  bool _tileProviderInitialized = false;
  bool _drawMode = false;

  /// Vertex editing tool (integration-test feedback 2026-11-12 #3): touch
  /// screens can't reliably disambiguate "tap = delete" from an attempted
  /// pan, so deletion happens only in the explicit delete tool. Edge
  /// midpoint insertion is tool-independent (fence_page editor pattern).
  _VertexTool _vertexTool = _VertexTool.move;
  List<LatLng> _drawingPoints = [];
  LatLng? _dragStart;
  LatLng? _dragCurrent;
  LatLng? _cursorLatLng;

  /// Index of the polygon vertex currently being dragged (integration-test
  /// feedback 2026-11-12 #2: loaded vertices could be deleted but not
  /// moved). Null when no drag is in progress; while set, map drag flags
  /// are dropped so the marker wins the gesture arena (NIX-192 pattern).
  int? _draggingVertexIndex;

  /// RenderBox anchor for converting a drag's global position into the
  /// map-local offset (same role as fence_page's _gestureKey).
  final GlobalKey _mapListenerKey = GlobalKey();
  Offset? _polygonPointerDownLocal;
  Duration? _polygonPointerDownTime;
  Offset? _lastPolygonCursorLocal;

  /// Track-draft wizard provenance (spec §4.3). Single immutable field —
  /// the wizard state machine stays in trackDraftControllerProvider and is
  /// never imported into this page's setState scope. Sent only on create;
  /// edits must not carry it (backend keeps the column on PUT).
  Map<String, dynamic>? _draftMetadata;

  bool get _isEdit => widget.fenceId != null;

  /// 新建围栏的锚点：当前牧场登记坐标（转为屏幕坐标系）；未登记时退回演示默认点
  LatLng get _farmAnchor {
    final center = ref.read(farmSwitcherControllerProvider).activeFarmCenter;
    if (center == null) return MapConstants.mapCenter;
    final shouldTransform = _tileProvider?.shouldTransformCoordinates() ?? false;
    return shouldTransform ? CoordTransform.wgs84ToGcj02(center) : center;
  }

  @override
  void initState() {
    super.initState();
    // NIX-415: deep links mount this page before the fence controller has
    // loaded its list; re-run the edit init when the fences land.
    _fenceStateSub = ref.listenManual(fenceControllerProvider, (_, __) {
      if (!mounted) return;
      setState(_initForEdit);
    });
  }

  @override
  void dispose() {
    _fenceStateSub?.close();
    _tileProvider?.dispose();
    _nameController.dispose();
    _formMapController.dispose();
    super.dispose();
  }

  Future<void> _initTileProvider() async {
    _tileProvider = await loadSmartTileProvider(
      ref,
      onSourceChanged: () { if (mounted) setState(() {}); },
    );
    if (mounted) setState(() {});
  }

  /// Safe exit (integration-test feedback 2026-11-12 #2): after a browser
  /// refresh / deep link the form sits at the bottom of the go_router stack,
  /// and a bare `context.pop()` throws GoError ("There is nothing to pop")
  /// which kills all further pointer handling on Web — the page freezes.
  /// Fall back to navigating to the fence list instead.
  void _exitForm(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoute.fence.path);
    }
  }

  /// Remove a polygon vertex by tapping its numbered marker (integration-
  /// test feedback 2026-11-12 #1: loaded track vertices could not be edited
  /// or deleted in the form). Rectangle/circle anchors are structural (two
  /// defining points) and stay non-deletable; polygon keeps >= 3 points.
  /// Insert a new vertex at the midpoint of edge [edgeIndex] (tap the edge
  /// midpoint dot — fence_page editor pattern, touch friendly).
  void _insertVertexAtEdgeMid(int edgeIndex) {
    if (!mounted || _type != FenceType.polygon) return;
    final n = _drawingPoints.length;
    if (n < 3) return;
    if (edgeIndex < 0 || edgeIndex >= n) return;
    final a = _drawingPoints[edgeIndex];
    final b = _drawingPoints[(edgeIndex + 1) % n];
    setState(() {
      _drawingPoints.insert(
        edgeIndex + 1,
        LatLng(
          (a.latitude + b.latitude) / 2,
          (a.longitude + b.longitude) / 2,
        ),
      );
    });
  }

  /// Edge midpoint markers for polygon vertex insertion (hidden while free
  /// drawing — the whole map is an insertion surface there already).
  List<Marker> _buildEdgeMidpointMarkers() {
    final n = _drawingPoints.length;
    return [
      for (var i = 0; i < n; i++)
        () {
          final a = _drawingPoints[i];
          final b = _drawingPoints[(i + 1) % n];
          return Marker(
            key: Key('fence-form-edge-mid-$i'),
            point: LatLng(
              (a.latitude + b.latitude) / 2,
              (a.longitude + b.longitude) / 2,
            ),
            width: 28,
            height: 28,
            alignment: Alignment.center,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _insertVertexAtEdgeMid(i),
              child: Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ),
          );
        }(),
    ];
  }

  Widget _vertexToolButton({
    required Key key,
    required IconData icon,
    required _VertexTool tool,
  }) {
    final selected = _vertexTool == tool;
    return InkWell(
      key: key,
      onTap: () {
        if (!mounted || _vertexTool == tool) return;
        setState(() {
          _vertexTool = tool;
          _draggingVertexIndex = null;
        });
      },
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }

  void _removeVertexAt(int index) {
    if (!mounted || _type != FenceType.polygon) return;
    if (index < 0 || index >= _drawingPoints.length) return;
    if (_drawingPoints.length <= 3) return;
    setState(() {
      _drawingPoints.removeAt(index);
      _clearTransientGesture();
    });
  }

  /// Move a polygon vertex by dragging its marker (integration-test
  /// feedback 2026-11-12 #2 follow-up). Form state stores screen
  /// coordinates (GCJ-02 under AMap tiles) and the marker renders them
  /// directly, so the raw screen lat/lng from the drag is written back
  /// verbatim — no coordinate transform here; the save path already
  /// converts screen → WGS-84 as a whole.
  void _handleFormVertexPanUpdate(int index, Offset globalPosition) {
    final context = _mapListenerKey.currentContext;
    if (context == null) return;
    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox) return;
    final local = renderBox.globalToLocal(globalPosition);
    final p = _latLngFromLocal(local);
    if (p == null) return;
    if (index < 0 || index >= _drawingPoints.length) return;
    setState(() {
      _drawingPoints[index] = p;
    });
  }

  void _clearTransientGesture() {
    _dragStart = null;
    _dragCurrent = null;
    _cursorLatLng = null;
    _polygonPointerDownLocal = null;
    _polygonPointerDownTime = null;
    _lastPolygonCursorLocal = null;
  }

  void _initForEdit() {
    if (_initialized || !_isEdit) return;
    final fenceState = ref.read(fenceControllerProvider);
    FenceItem? fence;
    for (final f in fenceState.fences) {
      if (f.id == widget.fenceId) {
        fence = f;
        break;
      }
    }
    // NIX-415: stay uninitialized until the fence actually arrives so the
    // build-driven retry (and the controller subscription) can fill the
    // form later — deep links mount before the controller has loaded.
    if (fence == null) return;
    _initialized = true;
    _nameController.text = fence.name;
    _type = fence.type;
    _alarmEnabled = fence.alarmEnabled;
    _active = fence.active;
    if (fence.type == FenceType.rectangle) {
      if (fence.points.length >= 4) {
        _drawingPoints = [fence.points[0], fence.points[2]];
      }
    } else if (fence.type == FenceType.circle) {
      if (fence.points.isNotEmpty) {
        final n = fence.points.length;
        double lat = 0, lng = 0;
        for (final p in fence.points) {
          lat += p.latitude;
          lng += p.longitude;
        }
        _drawingPoints = [LatLng(lat / n, lng / n), fence.points[0]];
      }
    } else {
      _drawingPoints = List.from(fence.points);
    }
  }

  List<LatLng> _getPreviewPoints() {
    if (_drawMode &&
        _dragStart != null &&
        _dragCurrent != null &&
        (_type == FenceType.rectangle || _type == FenceType.circle)) {
      return switch (_type) {
        FenceType.rectangle =>
          _buildRectanglePoints(_dragStart!, _dragCurrent!),
        FenceType.circle => _buildCirclePoints(_dragStart!, _dragCurrent!),
        FenceType.polygon => [],
      };
    }
    if (_drawingPoints.isEmpty) return [];
    return switch (_type) {
      FenceType.rectangle => _drawingPoints.length >= 2
          ? _buildRectanglePoints(_drawingPoints[0], _drawingPoints[1])
          : [],
      FenceType.circle => _drawingPoints.length >= 2
          ? _buildCirclePoints(_drawingPoints[0], _drawingPoints[1])
          : [],
      FenceType.polygon =>
        _drawingPoints.length >= 3 ? List.from(_drawingPoints) : [],
    };
  }

  List<LatLng> _buildRectanglePoints(LatLng p1, LatLng p2) {
    return [
      LatLng(p1.latitude, p1.longitude),
      LatLng(p1.latitude, p2.longitude),
      LatLng(p2.latitude, p2.longitude),
      LatLng(p2.latitude, p1.longitude),
    ];
  }

  List<LatLng> _buildCirclePoints(LatLng center, LatLng boundary) {
    final dLat = boundary.latitude - center.latitude;
    final dLng = boundary.longitude - center.longitude;
    final radius = sqrt(dLat * dLat + dLng * dLng);
    return [
      for (var i = 0; i < 12; i++)
        LatLng(
          center.latitude + radius * cos(i * pi / 6),
          center.longitude + radius * sin(i * pi / 6),
        ),
    ];
  }

  List<LatLng> _markerPoints() {
    if (_drawMode &&
        _dragStart != null &&
        _dragCurrent != null &&
        (_type == FenceType.rectangle || _type == FenceType.circle)) {
      return [_dragStart!, _dragCurrent!];
    }
    return _drawingPoints;
  }

  bool _isDrawingComplete() {
    return switch (_type) {
      FenceType.rectangle => _drawingPoints.length >= 2,
      FenceType.circle => _drawingPoints.length >= 2,
      FenceType.polygon => _drawingPoints.length >= 3,
    };
  }

  String _overlayBannerText(AppLocalizations l10n) {
   if (!_drawMode) return '';
   return switch (_type) {
     FenceType.rectangle ||
     FenceType.circle =>
       _dragStart != null && _dragCurrent != null
            ? l10n.fenceFormBannerDragHint
            : l10n.fenceFormBannerStartHint,
     FenceType.polygon => _drawingPoints.length >= 3
          ? l10n.fenceFormBannerPolyContinue
          : l10n.fenceFormBannerPolyStart,
   };
 }

 String _footerHintText(AppLocalizations l10n) {
  if (!_drawMode) {
      return l10n.fenceFormFooterHint;
   }
   return switch (_type) {
     FenceType.rectangle ||
     FenceType.circle =>
        l10n.fenceFormFooterDrag,
     FenceType.polygon =>
        l10n.fenceFormFooterPoly,
   };
 }

  LatLng? _latLngFromLocal(Offset local) {
    try {
      final cam = _formMapController.camera;
      if (cam.size.width == 0 || cam.size.height == 0) return null;
      return cam.screenOffsetToLatLng(local);
    } catch (_) {
      return null;
    }
  }

  void _handleMapPointerDown(PointerDownEvent e) {
    if (!_drawMode || !mounted) return;
    if (_type == FenceType.polygon) {
      _polygonPointerDownLocal = e.localPosition;
      _polygonPointerDownTime = e.timeStamp;
      return;
    }
    final p = _latLngFromLocal(e.localPosition);
    if (p == null) return;
    if (!mounted) return;
    setState(() {
      _dragStart = p;
      _dragCurrent = p;
    });
  }

  void _handleMapPointerMove(PointerMoveEvent e) {
    if (!_drawMode || !mounted) return;
    final p = _latLngFromLocal(e.localPosition);
    if (p == null) return;
    if (_type == FenceType.polygon) {
      if (_drawingPoints.isNotEmpty) {
        final last = _lastPolygonCursorLocal;
        if (last != null && (e.localPosition - last).distance < 2.5) {
          return;
        }
        _lastPolygonCursorLocal = e.localPosition;
        if (!mounted) return;
        setState(() => _cursorLatLng = p);
      }
    } else if (_dragStart != null) {
      if (!mounted) return;
      setState(() => _dragCurrent = p);
    }
  }

  void _handleMapPointerUp(PointerUpEvent e) {
    if (!_drawMode || !mounted) return;
    if (_type == FenceType.polygon) {
      final down = _polygonPointerDownLocal;
      final downTs = _polygonPointerDownTime;
      _polygonPointerDownTime = null;
      if (down == null) return;
      final dist = (e.localPosition - down).distance;
      final held = downTs != null ? e.timeStamp - downTs : const Duration(days: 1);
      final tap = dist <= 88 ||
          (held <= const Duration(milliseconds: 400) && dist <= 130);
      if (!tap) {
        _polygonPointerDownLocal = null;
        return;
      }
      final p = _latLngFromLocal(e.localPosition);
      if (p == null) {
        _polygonPointerDownLocal = null;
        return;
      }
      _onPolygonTap(p);
      return;
    }
    final p = _latLngFromLocal(e.localPosition);
    if (p == null || _dragStart == null) return;
    const th = 1e-12;
    final dLat = p.latitude - _dragStart!.latitude;
    final dLng = p.longitude - _dragStart!.longitude;
    if (dLat * dLat + dLng * dLng < th) {
      setState(_clearTransientGesture);
      return;
    }
    setState(() {
      _drawingPoints = [_dragStart!, p];
      _clearTransientGesture();
    });
  }

  void _handleMapPointerCancel(PointerCancelEvent e) {
    if (!_drawMode || !mounted) return;
    if (_type == FenceType.polygon) {
      _polygonPointerDownLocal = null;
      _polygonPointerDownTime = null;
      return;
    }
    setState(_clearTransientGesture);
  }

  void _onPolygonTap(LatLng point) {
    if (!mounted) return;
    setState(() {
      _polygonPointerDownLocal = null;
      _polygonPointerDownTime = null;
      _drawingPoints = [..._drawingPoints, point];
    });
  }

  void _toggleDrawMode() {
    if (!mounted) return;
    setState(() {
      _drawMode = !_drawMode;
      _clearTransientGesture();
    });
  }

  void _finishPolygonDraw() {
    if (!mounted) return;
    setState(() {
      _drawMode = false;
      _cursorLatLng = null;
      _polygonPointerDownLocal = null;
      _polygonPointerDownTime = null;
    });
  }

  void _resetDrawing() {
    setState(() {
      _selectedTemplate = null;
      _drawingPoints = [];
      _clearTransientGesture();
    });
  }

  void _applyTemplate(FenceTemplate template) {
    final preset = fenceTemplatePresetFor(template, anchor: _farmAnchor);
    setState(() {
      _selectedTemplate = template;
      _type = preset.type;
      _drawingPoints = List<LatLng>.from(preset.drawingPoints);
      _drawMode = true;
      _clearTransientGesture();
    });
    _formMapController.move(preset.focusPoint, 15.0);
  }

  double _calcAreaHectares() {
    final pts = _getPreviewPoints();
    if (pts.length < 3) return 1.0;
    double area = 0;
    final n = pts.length;
    for (var i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += pts[i].longitude * pts[j].latitude;
      area -= pts[j].longitude * pts[i].latitude;
    }
    final avgLat = pts.fold(0.0, (s, p) => s + p.latitude) / n;
    final cosLat = cos(avgLat * pi / 180);
    final areaM2 = (area.abs() / 2) * 111320 * 111320 * cosLat;
    final ha = areaM2 / 10000;
    if (!ha.isFinite) return 1.0;
    final clamped = ha.clamp(0.01, 99999);
    final parsed = double.tryParse(clamped.toStringAsFixed(2));
    return parsed ?? 1.0;
  }

  Future<void> _showManualEntryDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final previewPoints = _getPreviewPoints();
    final initialText = previewPoints.isEmpty
        ? ''
        : previewPoints
            .map((p) =>
                '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}')
            .join('\n');

    await showDialog<void>(
      context: context,
      builder: (ctx) => _ManualEntryDialog(
        fenceType: _type,
        initialText: initialText,
        // Invoked after the dialog has fully closed (controller lifetime is
        // owned by the dialog State), so this runs post-pop safely.
        onApply: (usedPoints) {
          setState(() {
            _selectedTemplate = null;
            _drawingPoints = usedPoints;
            _drawMode = false;
            _clearTransientGesture();
          });
          if (usedPoints.isNotEmpty) {
            _formMapController.move(usedPoints.first, 15.0);
          }
        },
        l10n: l10n,
      ),
    );
  }

  /// 轨迹采集 / GPX 导入的顶点回传（NIX-213）。
  ///
  /// 两个来源都是 WGS-84；表单 state 存屏幕坐标（高德瓦片下为 GCJ-02），
  /// 与手绘多边形一致，保存链路的 GCJ→WGS 转换零改动复用。
  void _applyCollectedVertices(List<LatLng> wgsPoints, {String? defaultName}) {
    if (wgsPoints.length < 3 || !mounted) return;
    final shouldTransform =
        _tileProvider?.shouldTransformCoordinates() ?? false;
    final screen = shouldTransform
        ? CoordTransform.wgs84ToGcj02All(wgsPoints)
        : List<LatLng>.from(wgsPoints);
    setState(() {
      _selectedTemplate = null;
      _type = FenceType.polygon;
      _drawingPoints = screen;
      // Loaded tracks start in the (touch-safe) move tool; free drawing is
      // hidden for this scenario and deletion requires the delete tool.
      _vertexTool = _VertexTool.move;
      _drawMode = false;
      _clearTransientGesture();
    });
    _formMapController.move(screen.first, 15.0);
    if (defaultName != null &&
        defaultName.isNotEmpty &&
        _nameController.text.trim().isEmpty) {
      _nameController.text = defaultName;
    }
  }

  Future<void> _openTrackCollect() async {
    final result = await Navigator.of(context).push<TrackCollectResult>(
      MaterialPageRoute(builder: (_) => const TrackCollectPage()),
    );
    if (result != null) {
      _applyCollectedVertices(result.vertices);
    }
  }

  /// Entry → track-draft wizard (spec §3.1). Not gated on kIsWeb: the flow
  /// adapts internally at the 900px breakpoint (mobile wizard / desktop
  /// panel share trackDraftControllerProvider).
  Future<void> _openTrackDraft() async {
    final l10n = AppLocalizations.of(context)!;
    ref
        .read(fenceAnalyticsSinkProvider)
        .emitEvent(FenceAnalyticsEvent.trackDraftWizardEnter());
    // Offline pre-flight: the project has no connectivity_plus infra, so we
    // probe the candidates endpoint (1-day window, tiny payload) and treat
    // a transport-level failure as offline. Server-side errors still let
    // the wizard open — it has its own failure branch with retry.
    try {
      await ApiClient.instance
          .farmGet('/fences/track-draft/candidates?days=1');
    } on http.ClientException {
      _showOfflineHint(l10n);
      return;
    } catch (e) {
      // Mobile transport failures throw SocketException (dart:io), which
      // http.ClientException does not cover (review 中1); other errors keep
      // propagating as before.
      if (!isOfflineTransportFailure(e)) rethrow;
      _showOfflineHint(l10n);
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeContext) => TrackDraftFlow(
          onBack: () => Navigator.of(routeContext).pop(),
          onConfirmed: (completion) {
            _handleTrackDraftConfirmed(completion);
            Navigator.of(routeContext).pop();
          },
        ),
      ),
    );
  }

  /// Shared offline branch of the pre-flight probe (spec §8 hint copy).
  void _showOfflineHint(AppLocalizations l10n) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.fenceTrackDraftOffline)),
    );
  }

  /// Wizard confirm: stash the provenance (sent with the create body) and
  /// load the envelope vertices onto the form map.
  void _handleTrackDraftConfirmed(TrackDraftCompletion completion) {
    final metadata = <String, dynamic>{
      ...completion.metadata,
      // Stamped at confirmation time; the wizard payload (spec §4.3) has
      // no generatedAt and the detail source card displays it.
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    _draftMetadata = metadata;
    final sink = ref.read(fenceAnalyticsSinkProvider);
    final l10n = AppLocalizations.of(context)!;
    _applyCollectedVertices(
      completion.vertices,
      defaultName: l10n.fenceTrackDraftSuggestedName(
        DateFormat('MM-dd').format(DateTime.now()),
      ),
    );
    // Generate-success is emitted where it happens — in the wizard
    // controller when the preview lands (review 低2); confirmation only
    // reports the form load.
    sink.emitEvent(
      FenceAnalyticsEvent.trackDraftLoadedIntoForm(
        completion.vertices.length,
      ),
    );
  }

  /// Fifth entry card (spec §3.1, prototype .entry-card): 34×34 primary-soft
  /// icon + 11.5/800 title + NEW pill + 2-line subtitle + chevron.
  Widget _buildTrackDraftEntryCard(AppLocalizations l10n) {
    return Material(
      color: AppColors.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      child: InkWell(
        key: const Key('fence-form-track-draft-entry'),
        borderRadius: BorderRadius.circular(12),
        onTap: _openTrackDraft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.route,
                  size: 17,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            l10n.fenceTrackDraftEntryTitle,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.fenceTrackDraftNewTag,
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.fenceTrackDraftEntryDesc,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 9,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openGpxImport() async {
    final result = await showDialog<FenceTrackImportResult>(
      context: context,
      builder: (_) => const FenceTrackImportDialog(),
    );
    if (result == null) return;
    _applyCollectedVertices(result.vertices, defaultName: result.defaultName);
    if (result.multiArea && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.fenceTrackMultiArea),
        ),
      );
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final controller = ref.read(fenceControllerProvider.notifier);

    {
      final coords = _getFinalPointsForSave();
      final vertices = coords
          .map((c) => <String, double>{'lat': c[1], 'lng': c[0]})
          .toList();
      final body = <String, dynamic>{
        'name': _nameController.text.trim(),
        'vertices': vertices,
        // NIX-410: persist the form shape so an edit reopens with the
        // rectangle/circle template semantics (anchor protection) intact.
        'shape': _type.name,
      };
      if (_isEdit) {
        body['status'] = _active ? 'active' : 'inactive';
      } else if (_draftMetadata != null) {
        // Create-only provenance (spec §4.3); the edit branch never sends
        // it so a normal rename/vertex tweak keeps the stored metadata.
        body['generationMetadata'] = _draftMetadata;
      }
      try {
        if (_isEdit) {
          await ApiClient.instance.farmPut('/fences/${widget.fenceId!}', body: body);
        } else {
          await ApiClient.instance.farmPost('/fences', body: body);
        }
      } on ConflictException {
        if (mounted) {
          setState(() => _saving = false);
          final force = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.fenceFormVersionConflict),
              content: Text(l10n.fenceFormVersionConflictDesc),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.fenceFormForceUpdate)),
              ],
            ),
          );
          if (force == true) {
            setState(() => _saving = true);
            try {
              await ApiClient.instance.farmPut('/fences/${widget.fenceId!}/force', body: body);
            } catch (e2) {
              if (mounted) {
                setState(() => _saving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.fenceFormForceUpdateFailed(e2.toString()))),
                );
              }
              return;
            }
          } else {
            return;
          }
        }
      } on QuotaExceededException {
        // Save-time quota race (spec §5.5 兜底): the fence quota was
        // consumed between the wizard pre-check and the POST.
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.fenceTrackDraftQuotaExceeded)),
          );
        }
        return;
      } catch (e) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.fenceFormSaveFailed(e.toString()))),
          );
        }
        return;
      }
      controller.reloadFromRepository();
      if (mounted) {
        setState(() => _saving = false);
        _exitForm(context);
      }
      return;
    }
  }

  List<List<double>> _getFinalPointsForSave() {
    var pts = _getPreviewPoints().isNotEmpty
        ? _getPreviewPoints()
        : FenceItem.defaultPointsForType(_type, _farmAnchor);
    if (_tileProvider?.shouldTransformCoordinates() ?? false) {
      pts = CoordTransform.gcj02ToWgs84All(pts);
    }
    return pts.map((p) => [p.longitude, p.latitude]).toList();
  }

  // _sessionTokens removed — ApiClient handles auth headers internally.

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _initForEdit();
    // Track-draft entry is owner-only (spec §4.1, RolePermission.canEditFence).
    final role = ref.watch(sessionControllerProvider).role;
    final canManage = role != null && RolePermission.canEditFence(role);
    if (!_tileProviderInitialized) {
      _tileProviderInitialized = true;
      _initTileProvider();
    }
    final previewPoints = _getPreviewPoints();
    final complete = _isDrawingComplete();
    final area = complete ? _calcAreaHectares() : 1.0;
    final markerPts = _markerPoints();
    final banner = _overlayBannerText(l10n);
    final mapCore = FlutterMap(
      key: const ValueKey<String>('fence-form-flutter-map'),
      mapController: _formMapController,
      options: MapOptions(
        initialCenter: _drawingPoints.isNotEmpty
            ? _drawingPoints.first
            : _farmAnchor,
        initialZoom: 15.0,
        interactionOptions: InteractionOptions(
          // Freeze gestures only while a rect/circle drag-draw is in progress
          // (drag start flips this via setState); otherwise keep the map
          // pannable/zoomable. Polygon taps are disambiguated from pan by the
          // pointer-up distance/time thresholds in _handleMapPointerUp.
          flags: (_drawMode && _type != FenceType.polygon && _dragStart != null) ||
                  _draggingVertexIndex != null
              ? InteractiveFlag.none
              : InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
         key: ValueKey(_tileProvider?.activeSourceName),
         urlTemplate: _tileProvider == null ? MapConfig.tileUrlTemplate : null,
         tileProvider: _tileProvider,
         userAgentPackageName: 'com.smartlivestock.demo',
       ),
        if (previewPoints.length >= 3)
          PolygonLayer(
            polygons: [
              Polygon(
                points: previewPoints,
                color: AppColors.primary.withValues(alpha: 0.2),
                borderColor: AppColors.primary,
                borderStrokeWidth: 2,
              ),
            ],
          ),
        if (_type == FenceType.polygon &&
            _drawingPoints.length >= 2 &&
            _drawingPoints.length < 3)
          PolylineLayer(
            polylines: [
              Polyline(
                points: List.from(_drawingPoints),
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ],
          ),
        if (_drawMode &&
            _type == FenceType.polygon &&
            _cursorLatLng != null &&
            _drawingPoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [_drawingPoints.last, _cursorLatLng!],
                color: AppColors.primary,
                strokeWidth: 2,
                pattern: StrokePattern.dashed(segments: const [10, 6, 4, 6]),
              ),
            ],
          ),
        // Edge midpoint dots: tap to insert a vertex on that edge (hidden
        // while free drawing — the whole map inserts there already).
        if (_type == FenceType.polygon &&
            _drawingPoints.length >= 3 &&
            !_drawMode)
          MarkerLayer(markers: _buildEdgeMidpointMarkers()),
        MarkerLayer(
          markers: [
            for (var i = 0; i < markerPts.length; i++)
              Marker(
                key: Key('fence-form-map-point-$i'),
                point: markerPts[i],
                // 56px hit area so a finger can grab and drag the vertex;
                // the visual dot stays 28px (fence_page editor pattern).
                width: 56,
                height: 56,
                alignment: Alignment.center,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // Delete only in the explicit delete tool — a bare tap on
                  // the move tool (the default) must never destroy a vertex
                  // (touch-screen safety, integration-test feedback #3).
                  onTap: _vertexTool == _VertexTool.delete
                      ? () => _removeVertexAt(i)
                      : null,
                  // Drag-to-move, move tool + polygon vertices only
                  // (rect/circle anchors are structural two-point
                  // definitions).
                  onPanStart: _type == FenceType.polygon &&
                          _vertexTool == _VertexTool.move
                      ? (_) {
                          if (!mounted) return;
                          setState(() => _draggingVertexIndex = i);
                        }
                      : null,
                  onPanUpdate: _type == FenceType.polygon &&
                          _vertexTool == _VertexTool.move
                      ? (details) {
                          if (_draggingVertexIndex != i) return;
                          _handleFormVertexPanUpdate(i, details.globalPosition);
                        }
                      : null,
                  onPanEnd: _type == FenceType.polygon &&
                          _vertexTool == _VertexTool.move
                      ? (_) {
                          if (!mounted) return;
                          setState(() => _draggingVertexIndex = null);
                        }
                      : null,
                  onPanCancel: _type == FenceType.polygon &&
                          _vertexTool == _VertexTool.move
                      ? () {
                          if (!mounted) return;
                          setState(() => _draggingVertexIndex = null);
                        }
                      : null,
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: i == 0
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    final mapWrapped = Listener(
      key: _mapListenerKey,
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleMapPointerDown,
      onPointerMove: _handleMapPointerMove,
      onPointerUp: _handleMapPointerUp,
      onPointerCancel: _handleMapPointerCancel,
      child: mapCore,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.fenceFormEditTitle : l10n.fenceFormNewTitle),
        leading: IconButton(
          key: const Key('fence-form-back'),
          onPressed: () => _exitForm(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        key: const Key('page-fence-form'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isEdit) ...[
                FenceTemplatePicker(
                  selectedTemplate: _selectedTemplate,
                  onSelected: _applyTemplate,
                ),
                if (!kIsWeb) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    key: const Key('fence-form-track-collect'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: _openTrackCollect,
                    child: Row(
                      children: [
                        const Icon(Icons.route, size: 22),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.fenceTrackMode,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              Text(
                                l10n.fenceTrackModeDesc,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ],
                if (canManage) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildTrackDraftEntryCard(l10n),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
             TextFormField(
               key: const Key('fence-form-name'),
               controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.fenceFormName,
                 border: const OutlineInputBorder(),
               ),
               validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.fenceFormNameRequired : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              KeyedSubtree(
                key: const Key('fence-form-type'),
               child: DropdownButtonFormField<FenceType>(
                 key: ValueKey<FenceType>(_type),
                 initialValue: _type,
                  decoration: InputDecoration(
                    labelText: l10n.fenceFormType,
                   border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: FenceType.rectangle,
                      child: Text(l10n.fenceFormRectangle),
                    ),
                    DropdownMenuItem(
                      value: FenceType.circle,
                      child: Text(l10n.fenceFormCircle),
                    ),
                    DropdownMenuItem(
                      value: FenceType.polygon,
                      child: Text(l10n.fenceFormPolygon),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _selectedTemplate = null;
                        _type = v;
                        _drawingPoints = [];
                        _drawMode = false;
                        _clearTransientGesture();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
             Text(
                l10n.fenceFormArea('$area'),
               key: const Key('fence-form-area'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.lg),
                child: SizedBox(
                  key: const Key('fence-form-map'),
                  height: 260,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(child: mapWrapped),
                      if (_drawMode && banner.isNotEmpty)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Material(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.92),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.sm,
                                right: AppSpacing.xxl * 3,
                                top: AppSpacing.xs,
                                bottom: AppSpacing.xs,
                              ),
                              child: Text(
                                banner,
                                key: const Key('fence-form-draw-hint'),
                                maxLines: 3,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      if (_drawMode &&
                          _type == FenceType.polygon &&
                          _drawingPoints.length >= 3)
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: FilledButton.tonal(
                              key: const Key('fence-form-polygon-done'),
                             onPressed: _finishPolygonDraw,
                             child: Text(
                                l10n.fenceFormFinishDraw('${_drawingPoints.length}'),
                              ),
                            ),
                          ),
                        ),
                      // Vertex tools (move/delete), polygon with vertices
                      // only; hidden while free drawing. Touch safety:
                      // deletion requires switching to the delete tool.
                      if (_type == FenceType.polygon &&
                          _drawingPoints.length >= 3 &&
                          !_drawMode)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(AppSpacing.sm),
                            color: Theme.of(context).colorScheme.surface,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _vertexToolButton(
                                  key: const Key('fence-form-tool-move'),
                                  icon: Icons.open_with,
                                  tool: _VertexTool.move,
                                ),
                                _vertexToolButton(
                                  key: const Key('fence-form-tool-delete'),
                                  icon: Icons.delete_outline,
                                  tool: _VertexTool.delete,
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_draftMetadata == null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                          color: Theme.of(context).colorScheme.surface,
                          child: InkWell(
                            key: const Key('fence-form-draw-toggle'),
                            onTap: _toggleDrawMode,
                            borderRadius: BorderRadius.circular(AppSpacing.sm),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _drawMode
                                        ? Icons.check
                                        : Icons.edit_location_alt,
                                    size: 20,
                                    color: _drawMode
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                 Text(
                                    _drawMode ? l10n.fenceFormDrawEnd : l10n.fenceFormDrawStart,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: _drawMode
                                              ? AppColors.primary
                                              : null,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _footerHintText(l10n),
                      key: const Key('fence-form-map-hint'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: complete
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                    ),
                  ),
                  TextButton(
                    key: const Key('fence-form-map-reset'),
                    onPressed: _drawingPoints.isEmpty ? null : _resetDrawing,
                    child: Text(l10n.fenceFormReset),
                  ),
                  TextButton(
                    key: const Key('fence-form-map-manual'),
                    onPressed: () => _showManualEntryDialog(context),
                    child: Text(l10n.fenceFormManualInput),
                  ),
                  TextButton(
                    key: const Key('fence-form-import-gpx'),
                    onPressed: _openGpxImport,
                    child: Text(l10n.fenceImportGpxButton),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                key: const Key('fence-form-alarm'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.fenceFormEnableAlarm),
                value: _alarmEnabled,
                onChanged: (v) => setState(() => _alarmEnabled = v),
              ),
              SwitchListTile(
                key: const Key('fence-form-active'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.fenceFormEnableStatus),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('fence-form-cancel'),
                      onPressed: () => _exitForm(context),
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      key: const Key('fence-form-save'),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.fenceFormSaveFence),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vertex editing tool for the polygon form (touch-safe: delete is an
/// explicit mode, never a bare tap).
enum _VertexTool { move, delete }

/// Manual coordinate-entry dialog (extracted from a StatefulBuilder +
/// outer-scope controller: the controller was disposed right after
/// `showDialog` resolved, while the exit transition was still building the
/// TextField — "used after being disposed". The controller now lives in a
/// State and is released when the dialog tree is truly unmounted.)
class _ManualEntryDialog extends StatefulWidget {
  const _ManualEntryDialog({
    required this.fenceType,
    required this.initialText,
    required this.onApply,
    required this.l10n,
  });

  final FenceType fenceType;
  final String initialText;
  final ValueChanged<List<LatLng>> onApply;
  final AppLocalizations l10n;

  @override
  State<_ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<_ManualEntryDialog> {
  final TextEditingController _inputController = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _inputController.text = widget.initialText;
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _apply() {
    final lines = _inputController.text.trim().split('\n');
    final points = <LatLng>[];
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.trim().split(RegExp(r'[,，\s]+'));
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          points.add(LatLng(lat, lng));
        }
      }
    }
    final minRequired = switch (widget.fenceType) {
      FenceType.rectangle => 2,
      FenceType.circle => 2,
      FenceType.polygon => 3,
    };
    if (points.length < minRequired) {
      setState(() =>
          _errorText = widget.l10n.fenceFormManualMinPoints('$minRequired'));
      return;
    }
    final usedPoints = switch (widget.fenceType) {
      FenceType.rectangle => points.take(2).toList(),
      FenceType.circle => points.take(2).toList(),
      FenceType.polygon => points,
    };
    Navigator.of(context).pop();
    widget.onApply(usedPoints);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.fenceFormManualEntry),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.fenceType == FenceType.rectangle
                  ? l10n.fenceFormManualRectHint
                  : widget.fenceType == FenceType.circle
                      ? l10n.fenceFormManualCircleHint
                      : l10n.fenceFormManualPolyHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('fence-form-manual-input'),
              controller: _inputController,
              maxLines: 8,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: '28.234000,112.940000\n28.230000,112.944000',
                errorText: _errorText,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('fence-form-manual-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('fence-form-manual-apply'),
          onPressed: _apply,
          child: Text(l10n.fenceFormApply),
        ),
      ],
    );
  }
}
