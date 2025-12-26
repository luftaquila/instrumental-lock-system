// =========================================================
// SENSOR HOUSING - Minimal Volume Design
// - Sensor exposed through angled diagonal wall
// - Base (bottom plate) + Lid (walls + top) assembly
// - 3D printing optimized
// =========================================================
$fn = 120;

// -------------------- View Mode --------------------
show = "exploded"; // "assembly" | "base" | "lid" | "exploded"

// -------------------- Sensor Parameters --------------------
sensor_d = 10.0;           // Sensor exposed diameter
sensor_flange_d = 11.0;    // Flange diameter (retention lip)
sensor_pcb_len = 25.0;     // PCB length behind sensor
sensor_clearance = 0.3;    // Fit clearance

// -------------------- Diagonal Wall Angle --------------------
diagonal_angle = 45;       // Angle of diagonal wall (degrees from vertical)

// -------------------- Wall Thicknesses --------------------
wall_t = 2.0;              // Wall thickness
base_t = 2.0;              // Base plate thickness
top_t = 2.0;               // Top plate thickness

// -------------------- Fastening (M3 self-tapping) --------------------
screw_d = 3.0;             // M3 screw
screw_clear_d = 3.4;       // Clearance hole in lid (M3 + clearance)
screw_tap_d = 2.5;         // Tap hole for M3 self-tapping into plastic
boss_d = 6.0;              // Screw boss diameter (needs to be larger for M3)
// boss_h will be calculated later to reach ceiling

// -------------------- Fit Tolerance --------------------
fit_gap = 0.25;            // Gap between base and lid for printing tolerance

// -------------------- Relay Parameters --------------------
relay_w = 7.3;             // Relay width
relay_l = 14.8;            // Relay length
relay_h = 12.5;            // Relay height
relay_fence_t = 0.8;       // Fence wall thickness
relay_fence_h = 3.0;       // Fence height (just enough to hold relay)
relay_clearance = 0.3;     // Clearance for relay fit

// -------------------- Base Holes (Toggle Switch & Wiring) --------------------
toggle_hole_d = 5.3;       // M5 clearance hole for toggle switch
wiring_hole_d = 3.4;       // M3 clearance hole for wiring

// -------------------- Derived Dimensions --------------------
// Sensor hole dimensions
sensor_hole_d = sensor_d + sensor_clearance;
sensor_flange_hole_d = sensor_flange_d + sensor_clearance;

// Calculate minimum internal dimensions based on sensor + PCB
// The sensor sits in diagonal wall, PCB extends inward
// PCB projection into box: pcb_len * cos(angle) in X, pcb_len * sin(angle) in Y
pcb_proj_x = sensor_pcb_len * cos(diagonal_angle);
pcb_proj_y = sensor_pcb_len * sin(diagonal_angle);

// Sensor offsets
sensor_offset_z = 7.0;        // Move sensor up from default position
sensor_offset_outward = 4.0;  // Move sensor outward - achieved by reducing diag_cut

// Minimum internal space needed
// Add margin for sensor flange and clearance
internal_margin = 3.0;
inner_w = pcb_proj_x + sensor_flange_d / 2 + internal_margin;
inner_h = pcb_proj_y + sensor_flange_d / 2 + internal_margin;

// Calculate sensor center Z first, then determine inner_z to fit exactly
// Sensor needs: base_t + clearance below + sensor_d/2 + offset
sensor_bottom_clearance = 3.0;  // Minimum clearance below sensor
sensor_z = base_t + sensor_bottom_clearance + sensor_flange_d / 2 + sensor_offset_z;

// Inner height: sensor top must be 2mm below ceiling (lid skirt top)
sensor_top_clearance = 3.0;  // Gap between sensor top and ceiling
inner_z = sensor_z + sensor_flange_d / 2 + sensor_top_clearance - base_t;

// Outer dimensions
outer_w = inner_w + 2 * wall_t;
outer_h = inner_h + 2 * wall_t;
outer_z = inner_z + base_t + top_t;

// Diagonal cut size (how much to cut from corner)
// diag_cut is the length of the diagonal edge (the cut distance along each axis)
// Smaller diag_cut = sensor moves forward (outward)
diag_cut = 10.0;

// Sensor position on diagonal wall (center of diagonal edge)
// Diagonal wall runs from (outer_w, outer_h - diag_cut) to (outer_w - diag_cut, outer_h)
diag_center_x = outer_w - diag_cut / 2;
diag_center_y = outer_h - diag_cut / 2;

// Lid skirt height (walls go from Z=0 to this height, then top plate)
lid_skirt_h = inner_z;

// Boss height: extends from base_t to ceiling (lid_skirt_h)
boss_h = lid_skirt_h - base_t;

// -------------------- Utility Modules --------------------
// 2D profile with one corner cut diagonally
module diag_profile_2d(w, h, d) {
    polygon(points = [
        [0, 0],
        [w, 0],
        [w, h - d],
        [w - d, h],
        [0, h]
    ]);
}

// Rounded rectangle 2D
module rounded_rect_2d(w, h, r) {
    rr = min(r, min(w, h) / 2);
    offset(r = rr)
        translate([rr, rr])
            square([w - 2 * rr, h - 2 * rr]);
}

// -------------------- Sensor Hole Module --------------------
// Creates the sensor mounting hole in the diagonal wall
// Simple 10mm hole through the wall
module sensor_hole_cutter() {
    // Position at center of diagonal wall
    cx = diag_center_x;
    cy = diag_center_y;
    
    // Direction perpendicular to diagonal wall (pointing outward)
    // Diagonal wall angle is 45° in XY plane
    dir_angle = 45; // Diagonal runs at 45° in XY
    
    translate([cx, cy, sensor_z]) {
        rotate([0, 0, dir_angle])
        rotate([0, 90, 0]) {
            // Single 10mm hole through the wall
            cylinder(h = wall_t * 3, d = sensor_hole_d, center = true);
        }
    }
}

// -------------------- Screw Boss Positions --------------------
// 2-point fastening to avoid sensor PCB interference
// Bosses integrated into corner walls - screw hole as close to walls as possible
// Minimum wall around screw hole (only needed on inner side, outer wall provides strength)
boss_wall_min = 2.0;  // Minimum plastic around screw hole on inner side
screw_to_wall = boss_d / 2 + boss_wall_min;  // Distance from screw center to inner edge

// Screw positions: inside lid inner boundary (wall_t + fit_gap)
lid_inner_offset = wall_t + fit_gap;
boss_positions = [
    [outer_w - lid_inner_offset - screw_to_wall / 2, lid_inner_offset + screw_to_wall / 2],  // Bottom-right corner
    [lid_inner_offset + screw_to_wall / 2, outer_h - lid_inner_offset - screw_to_wall / 2]   // Top-left corner
];

// -------------------- Relay Fence Position --------------------
// Relay fence with 4 walls
// Relay fence inner dimensions (with clearance)
relay_fence_inner_w = relay_w + relay_clearance;
relay_fence_inner_l = relay_l + relay_clearance;

// Position relay fence - with small gap from lid walls
fence_lid_gap = 0.3;  // Gap between fence and lid inner wall
relay_fence_x = lid_inner_offset + fence_lid_gap;  // With gap from lid
relay_fence_y = lid_inner_offset + fence_lid_gap;  // With gap from lid

// Full 4-wall fence
relay_fence_outer_w = relay_fence_inner_w + 2 * relay_fence_t;
relay_fence_outer_l = relay_fence_inner_l + 2 * relay_fence_t;

// Toggle switch and wiring hole positions (on base plate)
// Place them exactly between relay fence right edge and bottom-right boss wall
relay_fence_right_x = relay_fence_x + relay_fence_outer_w;
boss_wall_left_x = outer_w - lid_inner_offset - screw_to_wall;  // Boss wall left edge
holes_center_x = (relay_fence_right_x + boss_wall_left_x) / 2;

// Wiring hole as close to bottom wall as possible
wiring_hole_x = holes_center_x;
wiring_hole_y = lid_inner_offset + wiring_hole_d / 2 + 1;  // Close to bottom wall

// Toggle hole above wiring hole, with more spacing
toggle_hole_x = holes_center_x;
toggle_hole_y = wiring_hole_y + wiring_hole_d / 2 + 5 + toggle_hole_d / 2;

// -------------------- Relay Fence Module --------------------
// Relay fence with all 4 walls
module relay_fence() {
    translate([relay_fence_x, relay_fence_y, base_t]) {
        difference() {
            // Outer fence box
            cube([relay_fence_outer_w, relay_fence_outer_l, relay_fence_h]);
            
            // Inner cutout for relay
            translate([relay_fence_t, relay_fence_t, -0.1])
                cube([relay_fence_inner_w, relay_fence_inner_l, relay_fence_h + 0.2]);
        }
    }
}

// -------------------- Corner Boss Module --------------------
// Boss attached to lid (ceiling), screw inserted from base (bottom)
// Screw hole is flush against outer walls - outer walls provide strength
// Only inner sides need thick boss wall
boss_base_clearance = 0.5; // Gap between boss bottom and base plate top

// Distance from screw center to outer wall (just clearance for screw hole)
screw_to_outer_wall = screw_d / 2 + 0.5;  // Minimal distance to outer wall
// Distance from screw center to inner side (needs boss wall thickness)
screw_to_inner = screw_d / 2 + boss_wall_min;

// Lid boss module - attached to lid, hangs down from ceiling
module lid_corner_boss(corner) {
    // Boss hangs from ceiling (lid_skirt_h) down to just above base plate
    // Base plate top is at Z=0 in lid coordinate system (lid sits on base)
    // Boss bottom should be boss_base_clearance above Z=0
    boss_bottom_z = boss_base_clearance;
    boss_actual_h = lid_skirt_h - boss_bottom_z;  // Height from bottom to ceiling
    
    // Screw hole close to outer walls, thick wall only on inner sides
    boss_w = screw_to_outer_wall + screw_to_inner;  // X direction
    boss_l = screw_to_outer_wall + screw_to_inner;  // Y direction
    
    if (corner == "bottom_right") {
        // Boss in bottom-right corner: outer walls are +X and -Y (bottom)
        screw_x = screw_to_inner;  // From left edge of boss
        screw_y = screw_to_outer_wall;  // Close to bottom wall
        
        translate([outer_w - wall_t - boss_w, wall_t, boss_bottom_z])
            difference() {
                cube([boss_w, boss_l, boss_actual_h]);
                translate([screw_x, screw_y, -0.1])
                    cylinder(h = boss_actual_h + 0.2, d = screw_tap_d);
            }
    } else if (corner == "top_left") {
        // Boss in top-left corner: outer walls are -X (left) and +Y (top)
        screw_x = screw_to_outer_wall;  // Close to left wall
        screw_y = screw_to_inner;  // From bottom edge of boss
        
        translate([wall_t, outer_h - wall_t - boss_l, boss_bottom_z])
            difference() {
                cube([boss_w, boss_l, boss_actual_h]);
                translate([screw_x, screw_y, -0.1])
                    cylinder(h = boss_actual_h + 0.2, d = screw_tap_d);
            }
    }
}

// -------------------- Base Part --------------------
// Bottom plate with relay fence and screw clearance holes (screws insert from bottom)
module base_part() {
    // Screw positions must match lid boss screw positions
    // Bottom-right: screw at (outer_w - wall_t - screw_to_inner, wall_t + screw_to_outer_wall)
    // Top-left: screw at (wall_t + screw_to_outer_wall, outer_h - wall_t - screw_to_inner)
    
    difference() {
        union() {
            // Base plate
            linear_extrude(height = base_t)
                diag_profile_2d(outer_w, outer_h, diag_cut);
            
            // Relay fence
            relay_fence();
        }
        
        // Toggle switch hole (M5 clearance)
        translate([toggle_hole_x, toggle_hole_y, -0.1])
            cylinder(h = base_t + 0.2, d = toggle_hole_d);
        
        // Wiring hole (M3 clearance)
        translate([wiring_hole_x, wiring_hole_y, -0.1])
            cylinder(h = base_t + 0.2, d = wiring_hole_d);
        
        // Screw clearance holes (screws insert from bottom into lid bosses)
        // Must match lid boss screw positions exactly
        // Bottom-right corner: boss starts at (outer_w - wall_t - boss_w, wall_t), screw offset (screw_to_inner, screw_to_outer_wall)
        translate([outer_w - wall_t - screw_to_outer_wall, wall_t + screw_to_outer_wall, -0.1])
            cylinder(h = base_t + 0.2, d = screw_clear_d);
        
        // Top-left corner: boss starts at (wall_t, outer_h - wall_t - boss_l), screw offset (screw_to_outer_wall, screw_to_inner)
        translate([wall_t + screw_to_outer_wall, outer_h - wall_t - screw_to_outer_wall, -0.1])
            cylinder(h = base_t + 0.2, d = screw_clear_d);
    }
}

// -------------------- Lid Part --------------------
// Walls + top plate + sensor hole + screw bosses (hanging from ceiling)
module lid_part() {
    union() {
        difference() {
            union() {
                // Top plate
                translate([0, 0, lid_skirt_h])
                    linear_extrude(height = top_t)
                        diag_profile_2d(outer_w, outer_h, diag_cut);
                
                // Skirt walls (hollow shell)
                linear_extrude(height = lid_skirt_h)
                    difference() {
                        diag_profile_2d(outer_w, outer_h, diag_cut);
                        // Inner cutout with fit gap
                        offset(delta = -(wall_t + fit_gap))
                            diag_profile_2d(outer_w, outer_h, diag_cut);
                    }
            }
            
            // Sensor hole through diagonal wall
            sensor_hole_cutter();
        }
        
        // Corner bosses hanging from ceiling (with tap holes)
        lid_corner_boss("bottom_right");
        lid_corner_boss("top_left");
    }
}

// -------------------- Assembly Views --------------------
module assembly_view() {
    base_part();
    lid_part();
}

module exploded_view() {
    base_part();
    translate([0, 0, 15])
        lid_part();
}

// -------------------- Render Selection --------------------
if (show == "base") {
    base_part();
} else if (show == "lid") {
    lid_part();
} else if (show == "exploded") {
    exploded_view();
} else {
    assembly_view();
}

// -------------------- Debug Info --------------------
echo("=== Housing Dimensions ===");
echo(str("Outer: ", outer_w, " x ", outer_h, " x ", outer_z, " mm"));
echo(str("Inner: ", inner_w, " x ", inner_h, " x ", inner_z, " mm"));
echo(str("Diagonal cut: ", diag_cut, " mm"));
echo(str("Sensor center Z: ", sensor_z, " mm"));
echo(str("Relay fence at: (", relay_fence_x, ", ", relay_fence_y, ")"));
echo(str("Relay top Z: ", base_t + relay_h, " mm (sensor PCB should be above this)"));
