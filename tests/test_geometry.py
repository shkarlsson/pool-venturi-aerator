#!/usr/bin/env python3
"""
Automated geometric validation test for pool-venturi-aerator.
Tests OpenSCAD parameter injection, renders STLs, and validates:
1. Watertight / manifold status (no unclosed surfaces or open holes).
2. Proper volume and positive bounding boxes.
"""

import os
import json
import subprocess
import tempfile
import sys

def test_variant(scad_path, variant):
    name = variant["name"]
    params = variant["params"]
    
    print(f"\n[TEST] Running validation for variant: {name}")
    
    # Build -D CLI parameter arguments for OpenSCAD
    cmd_params = []
    for k, v in params.items():
        cmd_params.extend(["-D", f"{k}={v}"])
        
    with tempfile.TemporaryDirectory() as tmpdir:
        stl_path = os.path.join(tmpdir, f"{name}.stl")
        
        # 1. Compile with headless OpenSCAD
        cmd = ["openscad", "-o", stl_path, scad_path] + cmd_params
        res = subprocess.run(cmd, capture_output=True, text=True)
        
        if res.returncode != 0:
            print(f"[FAIL] OpenSCAD failed to render {name}:\n{res.stderr}")
            return False
            
        if not os.path.exists(stl_path) or os.path.getsize(stl_path) == 0:
            print(f"[FAIL] Output STL empty or missing for {name}")
            return False
            
        print(f"[PASS] Successfully rendered {name}.stl ({os.path.getsize(stl_path)} bytes)")
        
        # 2. Check manifoldness / volume via trimesh if available
        try:
            import trimesh
            mesh = trimesh.load(stl_path)
            
            if not mesh.is_watertight:
                print(f"[FAIL] Mesh {name} is NOT watertight / has non-manifold edges!")
                return False
                
            if mesh.volume <= 0:
                print(f"[FAIL] Mesh {name} has invalid or inverted volume: {mesh.volume}")
                return False
                
            print(f"[PASS] Mesh is 100% watertight! (Volume: {mesh.volume/1000:.2f} cm³, Bounding Box: {mesh.extents.round(1).tolist()} mm)")
        except ImportError:
            print("[INFO] trimesh not installed, skipping advanced mesh checks.")
            
    return True

def main():
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    scad_path = os.path.join(repo_root, "src", "pool_venturi_aerator.scad")
    matrix_path = os.path.join(repo_root, "configs", "matrix.json")
    
    if not os.path.exists(matrix_path):
        print(f"[FAIL] matrix.json missing at {matrix_path}")
        sys.exit(1)
        
    with open(matrix_path) as f:
        data = json.load(f)
        
    variants = data.get("variants", [])
    print(f"Loaded {len(variants)} variants from matrix.json")
    
    all_passed = True
    for v in variants:
        if not test_variant(scad_path, v):
            all_passed = False
            
    if not all_passed:
        print("\n❌ SOME TESTS FAILED")
        sys.exit(1)
    else:
        print(f"\n✅ ALL {len(variants)} MATRIX VARIANTS PASSED VALIDATION!")

if __name__ == "__main__":
    main()
