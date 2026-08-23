from app.behavior.model import predict_l2_batch


class Window:
    def __init__(self, window_id, features):
        self.window_id = window_id
        self.feature_version = "v1"
        self.feature_schema_hash = (
            "ed681cb289c0d9c7eb90d7e7a69e52663618af2f3004b71b4aa17db4ba95bfbc"
        )
        self.input_quality = "FULL_0X40"
        self.sampling_mode = "PROTOCOL_SUMMARY"
        self.features = features


def test_batch_prediction_rejects_entire_batch_on_invalid_window():
    import pytest

    from tests.behavior.test_model import features

    with pytest.raises((ValueError, KeyError, AttributeError)):
        predict_l2_batch(
            {"dominant_classes": [], "dominant_model": None, "facets": {}},
            [Window("w", features("LYING"))],
            "behavior-l2",
            "v1",
        )
