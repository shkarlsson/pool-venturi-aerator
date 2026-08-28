#!/usr/bin/env python3
"""
Publish 3D models, metadata, and preview renders to Thingiverse via REST API.
Reads secrets from THINGIVERSE_TOKEN environment variable.
"""

import os
import sys
import json
import glob
import urllib.request
import urllib.error

API_BASE = "https://api.thingiverse.com"

def get_token():
    token = os.environ.get("THINGIVERSE_TOKEN")
    if not token:
        print("[SKIP] THINGIVERSE_TOKEN secret not configured. Skipping Thingiverse publishing.")
        sys.exit(0)
    return token.strip()

def make_request(endpoint, token, method="GET", data=None):
    url = f"{API_BASE}{endpoint}"
    headers = {
        "Authorization": f"Bearer {token}",
        "User-Agent": "Pool-Venturi-Aerator-Bot/1.0",
        "Accept": "application/json",
    }
    body = None
    if data is not None:
        headers["Content-Type"] = "application/json"
        body = json.dumps(data).encode("utf-8")
        
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            if resp.status in (200, 201):
                return json.loads(resp.read().decode("utf-8"))
            return None
    except urllib.error.HTTPError as e:
        print(f"[ERROR] HTTP {e.code} on {endpoint}: {e.read().decode('utf-8', errors='ignore')}")
        return None

def upload_file_to_thing(thing_id, file_path, token):
    filename = os.path.basename(file_path)
    print(f"  Uploading {filename}...")
    
    # 1. Initialize file upload on Thingiverse
    init_res = make_request(f"/things/{thing_id}/files", token, method="POST", data={"filename": filename})
    if not init_res:
        print(f"  [FAIL] Could not initiate upload for {filename}")
        return False
        
    action_url = init_res.get("action")
    fields = init_res.get("fields", {})
    
    # 2. Upload file to S3 storage via multipart form-data
    boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
    body_bytes = bytearray()
    
    for k, v in fields.items():
        body_bytes.extend(f"--{boundary}\r\nContent-Disposition: form-data; name=\"{k}\"\r\n\r\n{v}\r\n".encode("utf-8"))
        
    with open(file_path, "rb") as f:
        file_data = f.read()
        
    body_bytes.extend(f"--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"{filename}\"\r\nContent-Type: application/octet-stream\r\n\r\n".encode("utf-8"))
    body_bytes.extend(file_data)
    body_bytes.extend(f"\r\n--{boundary}--\r\n".encode("utf-8"))
    
    s3_req = urllib.request.Request(
        action_url,
        data=bytes(body_bytes),
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
        method="POST"
    )
    
    try:
        with urllib.request.urlopen(s3_req) as resp:
            # 3. Finalize upload
            finalize_res = make_request(f"/things/{thing_id}/files/{init_res.get('id')}/finalize", token, method="POST")
            print(f"  [PASS] {filename} successfully uploaded!")
            return True
    except Exception as e:
        print(f"  [FAIL] S3 upload error for {filename}: {e}")
        return False

def main():
    token = get_token()
    
    readme_path = "README.md"
    description = "Parametric Pool Venturi Aerator for Intex, Bestway, and standard pool hoses."
    if os.path.exists(readme_path):
        with open(readme_path, "r") as f:
            description = f.read()
            
    payload = {
        "name": "Parametric Pool Venturi Aerator (Intex / Bestway)",
        "description": description,
        "license": "cc-sa",
        "category": "Outdoor & Garden",
        "tags": ["pool", "intex", "bestway", "venturi", "aerator", "openscad", "parametric"],
        "is_wip": False
    }
    
    print("[1/3] Creating Thing on Thingiverse...")
    thing = make_request("/things", token, method="POST", data=payload)
    if not thing or "id" not in thing:
        print("[FAIL] Failed to create thing on Thingiverse.")
        sys.exit(1)
        
    thing_id = thing["id"]
    thing_url = thing.get("public_url", f"https://www.thingiverse.com/thing:{thing_id}")
    print(f"[PASS] Created Thing ID: {thing_id} -> {thing_url}")
    
    # Upload all generated STLs & PNG previews
    files_to_upload = glob.glob("dist/*.stl") + glob.glob("dist/*.png")
    print(f"[2/3] Uploading {len(files_to_upload)} files...")
    
    for fp in sorted(files_to_upload):
        upload_file_to_thing(thing_id, fp, token)
        
    print(f"[3/3] Publishing Thing {thing_id}...")
    make_request(f"/things/{thing_id}/publish", token, method="POST")
    
    print(f"\n🎉 Successfully published to Thingiverse: {thing_url}")

if __name__ == "__main__":
    main()
