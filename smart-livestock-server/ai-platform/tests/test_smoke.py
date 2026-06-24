import pytest
from app.config import settings


def test_settings_weights_sum_to_one():
    assert settings.w_stl + settings.w_cusum + settings.w_joint == pytest.approx(1.0)


def test_settings_defaults():
    assert settings.neff_mahalanobis_min == 30
    assert settings.slot_minutes == 30
