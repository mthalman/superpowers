from src.pagination import paginate


def test_empty_items():
    p = paginate([], 1, 10)
    assert p.items == []


def test_invalid_page_raises():
    import pytest
    with pytest.raises(ValueError):
        paginate([1, 2, 3], 0, 10)
