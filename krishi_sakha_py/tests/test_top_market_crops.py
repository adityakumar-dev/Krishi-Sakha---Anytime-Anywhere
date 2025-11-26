import sys
import os
from fastapi.testclient import TestClient

# Ensure project root is on path so `import main` works when pytest runs from a different CWD
from fastapi import FastAPI
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
# Create lightweight stubs for heavy brain modules so importing routes.crop doesn't pull
# in large external dependencies during unit tests.
import types

brain_model_run = types.ModuleType('brain.model_run')
brain_model_run.model_runner = object()  # not used by /top_market_crops

brain_context_prioritizer = types.ModuleType('brain.context_prioritizer')
async def _dummy_get_prioritized_context(*args, **kwargs):
    return ""
brain_context_prioritizer.get_prioritized_context = _dummy_get_prioritized_context

brain_market_analyzer = types.ModuleType('brain.market_analyzer')
async def _dummy_market_analysis(crops, region):
    return ""
async def _dummy_cultivation_patterns(crops):
    return ""
brain_market_analyzer.get_market_analysis_for_crops = _dummy_market_analysis
brain_market_analyzer.get_uttarakhand_cultivation_patterns = _dummy_cultivation_patterns

import sys as _sys
_sys.modules['brain.model_run'] = brain_model_run
_sys.modules['brain.context_prioritizer'] = brain_context_prioritizer
_sys.modules['brain.market_analyzer'] = brain_market_analyzer

# Import only the crop router to avoid loading heavy global dependencies from main
from routes.crop import router as crop_router

app = FastAPI()
app.include_router(crop_router)

client = TestClient(app)


def test_top_market_crops_basic():
    payload = {
        "crops": [
            {"name": "Wheat", "quantity_quintals": 10},
            {"name": "Tomato", "quantity_quintals": 5},
            {"name": "Potato", "quantity_quintals": 20}
        ]
    }

    resp = client.post("/top_market_crops", json=payload)
    assert resp.status_code == 200
    data = resp.json()
    assert 'top_crops' in data
    assert 'requested' in data
    # requested should have three entries
    assert len(data['requested']) == 3

    # Check that known crop has a price_per_quintal > 0
    for r in data['requested']:
        if r['requested_name'].lower() == 'wheat':
            assert r['price_per_quintal'] > 0
            assert r['total_value'] == r['price_per_quintal'] * r['quantity_quintals']
