import sys
from pathlib import Path

# project root = backend/ (contains apps/ and train_kmeans_domain_weighted.py)
_PROJECT_ROOT = Path(__file__).resolve().parents[3]
if str(_PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(_PROJECT_ROOT))
