import os
import hashlib
import json
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, "..", "cod4x-server"))
MANIFEST_PATH = os.path.abspath(os.path.join(SCRIPT_DIR, "..", "update"))
MANIFEST_FILE = "manifest.json"

BASE_URL = "https://raw.githubusercontent.com/VikingKampfsau/tranzit/main/cod4x-server"

os.makedirs(MANIFEST_PATH, exist_ok=True)

def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            h.update(chunk)
    return h.hexdigest()

files_dict = {}

for root, _, files in os.walk(BASE_DIR):
    for name in files:
        filepath = os.path.join(root, name)

        rel_path = os.path.relpath(filepath, BASE_DIR).replace("\\", "/")
        target_path = f"cod4x-server/{rel_path}"

        file_hash = sha256_file(filepath)

        # JSON-Format: "pfad": "hash"
        files_dict[target_path] = file_hash

manifest = {
    "comment": "CoD4x TranZit SHA256 File Integrity Manifest",
    "generated": datetime.utcnow().isoformat() + "Z",
    "file_count": len(files_dict),
    "files": files_dict
}

with open(os.path.join(MANIFEST_PATH, MANIFEST_FILE), "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2)

print(MANIFEST_FILE + f" generated with {len(files_dict)} files")
