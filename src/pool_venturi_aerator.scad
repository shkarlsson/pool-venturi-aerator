// ====================================================================
// Parametric In-Line Venturi Pool Aerator (External Hose Mount)
// Upstream Source: https://github.com/shkarlsson/pool-venturi-aerator
// License: CERN-OHL-S v2 (Source) / CC-BY-SA 4.0 (Mesh Exports)
// ====================================================================

$fn = 90;

// [Main Pool Hose Barb (Water In / Water Out)]
// Inside diameter of your flexible pool hose (e.g. 32mm / 1.25" or 38mm / 1.5")
mating_hose_id      = 38.0; 
// Wall thickness of the printed part (ensure 100% watertightness)
wall_thick          = 3.5;  
// Length of each hose barb end
barb_length         = 25.0; 
// Extra outer radius expansion on retention ridges
barb_ridge_extra    = 0.5;  

// [Hydraulic Venturi Core]
// Constricted venturi throat ID (accelerates water velocity to create vacuum)
// Recommended: 12-14mm for small pumps (<3m3/h), 14-16mm for medium (3-6m3/h), 18-20mm for large (>6m3/h)
throat_id           = 16.0; 
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
air_nipple_height   = 12.0; 

// --- CALCULATED VALUES ---
air_nipple_od       = air_tube_id + (2 * air_nipple_wall);
air_bore_id         = max(3.0, air_tube_id - 1.5);
main_id             = mating_hose_id - (2 * wall_thick);

// --- MODULES ---

module hose_barb(od, len, wall) {
    id = od - (2 * wall);
    num_ridges = 3;
    ridge_spacing = len / (num_ridges + 1);
    
    difference() {
        union() {
            // Main cylindrical barb body (outer diameter matches hose ID)
            cylinder(r = od/2, h = len, center = false);
            // Retention ridges for hose clamp sealing
            for (i = [1 : num_ridges]) {
                translate([0, 0, i * ridge_spacing])
                    cylinder(r1 = (od/2) + barb_ridge_extra, r2 = od/2, h = 2.5, center = false);
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
    inlet_r  = main_id / 2;
    throat_r = throat_id / 2;
    
    inlet_od_r  = mating_hose_id / 2;
    throat_od_r = throat_r + wall_thick;
    
    difference() {
        union() {
            // Converging outer cone
            cylinder(r1 = inlet_od_r, r2 = throat_od_r, h = converge_len, center = false);
            // Diverging outer cone
            translate([0, 0, converge_len])
                cylinder(r1 = throat_od_r, r2 = inlet_od_r, h = diverge_len, center = false);
            // Tapered air suction nipple on the outside of the throat
            translate([0, 0, converge_len])
                rotate([0, 90, 0])
                    air_nipple_outer(inlet_od_r, air_nipple_height, air_nipple_od / 2);
        }
        
        // Internal Flow Path (The Venturi)
        // 1. Converging cone
        translate([0, 0, -0.01])
            cylinder(r1 = inlet_r, r2 = throat_r, h = converge_len + 0.02, center = false);
            
        // 2. Diverging expansion cone
        translate([0, 0, converge_len])
            cylinder(r1 = throat_r, r2 = inlet_r, h = diverge_len + 0.01, center = false);
            
        // 3. Air suction hole drilled straight through the nipple into the throat center
        translate([0, 0, converge_len])
            rotate([0, 90, 0])
                cylinder(r = air_bore_id / 2, h = inlet_od_r + air_nipple_height + 5, center = false);
    }
}

// --- COMPLETE ASSEMBLY ---
module full_aerator() {
    // 1. Inlet Hose Barb (From Pump)
    hose_barb(mating_hose_id, barb_length, wall_thick);
    
    // 2. Venturi Aeration Core
    translate([0, 0, barb_length])
        venturi_core();
        
    // 3. Outlet Hose Barb (To Pool Inlet)
    translate([0, 0, barb_length + converge_len + diverge_len])
        hose_barb(mating_hose_id, barb_length, wall_thick);
}

// Render
full_aerator();
