# Parametric In-Line Venturi Pool Aerator

[![3D Model Validation & Build](https://github.com/shkarlsson/pool-venturi-aerator/actions/workflows/build-and-release.yml/badge.svg)](https://github.com/shkarlsson/pool-venturi-aerator/actions/workflows/build-and-release.yml)
[![License: CERN-OHL-S v2](https://img.shields.io/badge/License-CERN--OHL--S--v2-blue.svg)](LICENSE)
[![Downstream Mesh License: CC-BY-SA 4.0](https://img.shields.io/badge/Meshes-CC--BY--SA--4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)

A fully parametric, hydraulic in-line Venturi aerator for above-ground pool return lines (Bestway, Intex, etc.). Spliced externally into the return hose between the pump/sand filter and the pool inlet. 

It uses the Venturi effect to create a localized low-pressure zone at the constricted throat, drawing ambient air through a snorkel tube and injecting micro-bubbles into the pool to raise pH, cool water in hot weather, and create a spa jet stream without external air pumps.

---

## ⚖️ Licensing & Open Source Terms

* **Upstream CAD Source (`.scad`, Python tests):** Licensed under **[CERN-OHL-S v2 (Strongly Reciprocal)](LICENSE)**. If you modify or distribute physical prints manufactured from this source, you must make your modified source files available under the same license.
* **Platform Mesh Exports (`.stl`, `.3mf` on Printables/MakerWorld):** Distributed under **CC-BY-SA 4.0** for platform compatibility.

---

## 📐 Pre-Compiled Release Matrix

The automated CI pipeline compiles and verifies 12 standard size combinations ($2 \times 2 \times 3$ matrix):

| Variant File | Pool Hose ID | Air Tube ID | Pump Flow Rating | Throat ID |
| :--- | :--- | :--- | :--- | :--- |
| `aerator_32mm_air6mm_pumpSmall.stl` | **32 mm** (1.25") | **6 mm** | Small (<3.0 m³/h / <800 GPH) | 12.0 mm |
| `aerator_32mm_air6mm_pumpMed.stl`   | **32 mm** (1.25") | **6 mm** | Med (3.0–6.0 m³/h / Sand) | 14.0 mm |
| `aerator_32mm_air6mm_pumpLarge.stl` | **32 mm** (1.25") | **6 mm** | Large (>6.0 m³/h / >1500 GPH) | 16.0 mm |
| `aerator_32mm_air8mm_pumpSmall.stl` | **32 mm** (1.25") | **8 mm** | Small (<3.0 m³/h) | 12.0 mm |
| `aerator_32mm_air8mm_pumpMed.stl`   | **32 mm** (1.25") | **8 mm** | Med (3.0–6.0 m³/h / Sand) | 14.0 mm |
| `aerator_32mm_air8mm_pumpLarge.stl` | **32 mm** (1.25") | **8 mm** | Large (>6.0 m³/h) | 16.0 mm |
| `aerator_38mm_air6mm_pumpSmall.stl` | **38 mm** (1.50") | **6 mm** | Small (<3.0 m³/h) | 14.0 mm |
| `aerator_38mm_air6mm_pumpMed.stl`   | **38 mm** (1.50") | **6 mm** | Med (3.0–6.0 m³/h / Sand) | 16.0 mm |
| `aerator_38mm_air6mm_pumpLarge.stl` | **38 mm** (1.50") | **6 mm** | Large (>6.0 m³/h) | 18.0 mm |
| `aerator_38mm_air8mm_pumpSmall.stl` | **38 mm** (1.50") | **8 mm** | Small (<3.0 m³/h) | 14.0 mm |
| `aerator_38mm_air8mm_pumpMed.stl`   | **38 mm** (1.50") | **8 mm** | Med (3.0–6.0 m³/h / Sand) | 16.0 mm |
| `aerator_38mm_air8mm_pumpLarge.stl` | **38 mm** (1.50") | **8 mm** | Large (>6.0 m³/h) | 18.0 mm |

---

## 🖨️ Recommended Print Settings

* **Filament:** **PETG** or **ASA** (Chlorine, water pressure, and UV resistance are mandatory; do not use PLA).
* **Orientation:** Print vertically standing on one of the hose barbs.
* **Perimeters / Walls:** Set to **5–6 walls** (or 100% infill) so the part is solid and completely watertight under backpressure.
* **Supports:** None needed if printed vertically.
* **Layer Height:** 0.20 mm.

---

## 🛠️ Customizing Parameters

Open `src/pool_venturi_aerator.scad` in OpenSCAD or use the Customizer pane:
* `mating_hose_id`: Inside diameter of your flexible pool hose.
* `air_tube_id`: Inside diameter of your silicone intake tube.
* `throat_id`: Constricted diameter (adjust based on pump velocity).

---

## 🧪 Automated Testing

To run the geometric validation test suite locally:

```bash
python3 tests/test_geometry.py
```
