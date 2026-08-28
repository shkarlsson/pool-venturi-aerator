// ====================================================================
// Parametric In-Line Venturi Pool Aerator (External Hose Mount)
// Upstream Source: https://github.com/shkarlsson/pool-venturi-aerator
// License: CERN-OHL-S v2 (Source) / CC-BY-SA 4.0 (Mesh Exports)
//
// Default orientation: Vertical standing on inlet hose barb (+Z).
// Tilted downstream air intake and 45° double-taper ridges require 0 supports.
// ====================================================================

$fn = 90;

// [Main Pool Hose Barb (Water In / Water Out)]
// Inside diameter of your flexible pool hose (e.g. 32mm / 1.25" or 38mm / 1.5")
mating_hose_id      = 32.0; 
// Wall thickness of the printed part (ensure 100% watertightness)
wall_thick          = 3.5;  
// Length of each hose barb end
barb_length         = 25.0; 
// Extra outer radius expansion on retention ridges
barb_ridge_extra    = 0.5;  

// [Hydraulic Venturi Core]
// Constricted venturi throat ID (accelerates water velocity to create vacuum)
// Recommended: 12-14mm for small pumps (<3m3/h), 14-16mm for medium (3-6m3/h), 18-20mm for large (>6m3/h)
throat_id           = 12.0; 
// Length of converging cone
converge_len        = 20.0; 
// Length of diverging expansion cone (diffuser)
diverge_len         = 25.0; 

// [Air Suction Intake Nipple]
// Inside diameter of your ambient air / silicone tube (nipple OD matches this)
air_tube_id         = 6.0;  
// Wall thickness of the air nipple
air_nipple_wall     = 2.0;  
// Height of the air intake stem
air_nipple_protrude = 22.0;
 
// [Inlet Barb Clearance Spacer]
// Smooth barb-less straight tube distance before barb starts (clears air tube clamp/access)
spacer_len          = 12.0; 

// [Bed Adhesion & Structural Support Ridge (Bottom)]
// Width of the flat contact foot on the build plate (stops cylindrical rolling/warping)
foot_width          = 5.0; 

// --- CALCULATED VALUES ---
air_nipple_height   = air_nipple_protrude + 31;
air_nipple_od       = air_tube_id + (2 * air_nipple_wall);
air_bore_id         = max(3.0, air_tube_id - 1.5);
main_id             = mating_hose_id - (2 * wall_thick);
total_length        = (2 * barb_length) + spacer_len + converge_len + diverge_len;
max_outer_r         = (mating_hose_id / 2) + barb_ridge_extra;

// --- MODULES ---

module hose_barb(od, len, wall) {
    id = od - (2 * wall);
    num_ridges = 3;
    ridge_spacing = len / (num_ridges + 1);
    ridge_h = 4.0;
    
    difference() {
        union() {
            // Main cylindrical barb body
            cylinder(r = od/2, h = len, center = false);
            // Symmetrical double-taper ridges (steep bidirectional taper, 100% printable standing without support)
            for (i = [1 : num_ridges]) {
                translate([0, 0, i * ridge_spacing - (ridge_h / 2)]) {
                    // Lower taper ramping up (45° angle)
                    cylinder(r1 = od/2, r2 = (od/2) + barb_ridge_extra, h = ridge_h / 2, center = false);
                    // Upper taper ramping down (45° angle)
                    translate([0, 0, ridge_h / 2])
                        cylinder(r1 = (od/2) + barb_ridge_extra, r2 = od/2, h = ridge_h / 2, center = false);
                }
            }
        }
        // Inner bore
        translate([0, 0, -1])
            cylinder(r = id/2, h = len + 2, center = false);
    }
}

module air_nipple_outer(base_r, stem_h, nipple_r) {
    tip_taper_len = 3.0;
    cyl_h = stem_h - tip_taper_len;
    
    // Main stem cylinder
    cylinder(r = nipple_r, h = base_r + cyl_h, center = false);
    // Tapered "tippy" lead-in cone at the top for easy tube sliding
    translate([0, 0, base_r + cyl_h])
        cylinder(r1 = nipple_r, r2 = (air_tube_id / 2) * 0.75, h = tip_taper_len, center = false);
}

module venturi_core() {
    inlet_ir  = main_id / 2;
    throat_ir = throat_id / 2;
    
    inlet_or  = mating_hose_id / 2;
    throat_or = throat_ir + wall_thick;
    
    // Angle of the diverging diffuser cone wall relative to the central Z axis
    // Matches the downstream expansion slope that the air intake stem runs alongside
    diverge_angle = atan2(inlet_or - throat_or, diverge_len);
    
    air_nipple_offset = (throat_or * cos(diverge_angle)) + (air_bore_id / 2);

    
    difference() {
        union() {
            // Converging outer cone
            cylinder(r1 = inlet_or, r2 = throat_or, h = converge_len, center = false);
            // Diverging outer cone
            translate([0, 0, converge_len])
                cylinder(r1 = throat_or, r2 = inlet_or, h = diverge_len, center = false);
            // Tapered air suction nipple tilted to match the diverging expansion cone slope
            // and pointing downstream towards the expansion chamber (+Z)
            translate([0, 0, converge_len])
                rotate([0, diverge_angle, 0])
                    translate([air_nipple_offset,0,-15])
                        air_nipple_outer(inlet_or, air_nipple_height + 5, air_nipple_od / 2);
        }
        
        // Internal Flow Path (The Venturi)
        // Entry & exit margins for clean CGAL manifold subtractions without altering boundary diameters
        conv_slope = (inlet_ir - throat_ir) / converge_len;
        div_slope  = (inlet_ir - throat_ir) / diverge_len;
        eps = 0.5;
        
        // 1. Converging cone
        translate([0, 0, -eps])
            cylinder(r1 = inlet_ir + (conv_slope * eps), r2 = throat_ir, h = converge_len + eps, center = false);
            
        // 2. Diverging expansion cone
        translate([0, 0, converge_len])
            cylinder(r1 = throat_ir, r2 = inlet_ir + (div_slope * eps), h = diverge_len + eps, center = false);
            
        // 3. Air suction hole drilled through the tilted nipple into the start of the expansion chamber
        translate([0, 0, converge_len])
            rotate([0, diverge_angle, 0])
                translate([air_nipple_offset,0,-20])
                    cylinder(r = air_bore_id / 2, h = inlet_or + air_nipple_height + 30, center = false);
    }
}



module straight_pipe(od, len, wall) {
    id = od - (2 * wall);
    difference() {
        cylinder(r = od/2, h = len, center = false);
        translate([0, 0, -1])
            cylinder(r = id/2, h = len + 2, center = false);
    }
}

// --- VERTICAL ASSEMBLY PRIMITIVE ---
module aerator() {
    // 1. Inlet Hose Barb
    hose_barb(mating_hose_id, barb_length, wall_thick);
        
    // 2. Venturi Core
    translate([0, 0, barb_length])
        venturi_core();
        
    // 3. Smooth barb-less straight spacer tube after the venturi core
    translate([0, 0, barb_length + converge_len + diverge_len])
        straight_pipe(mating_hose_id, spacer_len, wall_thick);
        
    // 4. Outlet Hose Barb
    translate([0, 0, barb_length + converge_len + diverge_len + spacer_len])
        hose_barb(mating_hose_id, barb_length, wall_thick);
}

// --- COMPLETE PRINT-READY ORIENTATION ---

// Render
aerator();
