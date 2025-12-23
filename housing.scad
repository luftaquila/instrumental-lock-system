// =========================================================
// BASE = bottom plate only (+ PCB plate + PCB bosses + 2 base lugs)
// LID  = walls(skirt) + top (one piece) + diagonal sensor hole
// Fastening: SIDE screws through LID walls into BASE lugs (2 walls only: TOP + RIGHT)
// =========================================================
$fn = 120;

// -------------------- View --------------------
show = "assembly"; // "assembly" | "base" | "lid"

// -------------------- PCB / internal mounting plate --------------------
pcb_w = 48;
pcb_h = 36.5;
pcb_r = 3.5;
pcb_thk = 1.6;

plate_t = 2; // PCB plate thickness (on BASE)
plate_w = pcb_w;
plate_h = pcb_h;
plate_r = pcb_r;

floor_extra_shift = [-3.5, -3.5];

// -------------------- PCB bosses --------------------
boss_h = 5;
boss_od = 5;

m2_hole_d = 1.7;
cut_extra = 0.3;

// -------------------- Sensor (hole only, on LID diagonal wall) --------------------
sensor_yaw_deg = 45;
sensor_d = 18.0;
sensor_clear = 0.4;
sensor_hole_d = sensor_d + sensor_clear;

sensor_in_len = 43;
sensor_run_clear = 1.0;

// nut tightens outside => diagonal face must be wide enough
nut_d = 23.5;
nut_face_margin = 2.0;

// -------------------- Case sizing --------------------
wall_t = 3;

// BASE
base_t = 3; // bottom plate thickness

// LID
top_t = 3; // top thickness
fit_gap = 0.25; // clearance between lid inner and base outer edge (print fit)

// Height safety
top_clear = 3.0;

// -------------------- Fastening (side screws, only TOP + RIGHT walls) --------------------
side_clear_d = 2.4; // clearance in LID wall for M2
side_tap_d = 1.7; // tap/pilot in BASE lug for M2 (plastic)

// BASE lug (small block on base plate only)
lug_w = 10; // along wall direction
lug_t = 5; // thickness (depth toward inside)
lug_h = 8; // height above base plate (small)
lug_inset_extra = 0.5; // inset from outer edge

screw_offset = 14; // distance from top-right corner along each wall
screw_z = lug_h / 2; // height of screw axis from BASE bottom (must hit BASE lug)

// -------------------- Derived geometry (minimal-ish) --------------------
// diagonal wall size
diag_cut = ceil((nut_d + 2 * nut_face_margin) / sqrt(2));

// sensor height constraint: sensor lowest point = boss_top + 15
boss_top_z = plate_t + boss_h;
sensor_center_z = (boss_top_z + 15) + sensor_d / 2 - 4;

// internal height required (THIS MUST EXIST BEFORE ANYTHING USES IT)
hole_top_clear = 4.0;
house_inner_z = sensor_center_z + sensor_hole_d / 2 + hole_top_clear;

// footprint margin for sensor-in length
side_clear = 1.0;
m_sensor = max(
  0,
  (2 * (sensor_in_len + sensor_run_clear) + diag_cut - (plate_w + plate_h)) / 4
);
m = max(side_clear, m_sensor);

// inner footprint (clear cavity inside LID)
inner_w = plate_w + 2 * m;
inner_h = plate_h + 2 * m;

// LID outer footprint
outer_w = inner_w + 2 * wall_t;
outer_h = inner_h + 2 * wall_t;

// LID skirt height: walls go down to cover the internal height and overlap the base thickness
// (Skirt starts at Z=0 and top plate sits at Z=lid_skirt_h)
lid_skirt_h = house_inner_z;

// PCB plate placement on BASE (shifted)
inner_ll = [wall_t, wall_t];
floor_xy = [
  inner_ll[0] + m + floor_extra_shift[0],
  inner_ll[1] + m + floor_extra_shift[1],
];

// -------------------- Utilities --------------------
module rounded_rect_2d(w, h, r) {
  rr = min(r, min(w, h) / 2);
  offset(r=rr)
    translate([rr, rr])
      square([w - 2 * rr, h - 2 * rr], center=false);
}

module diag_profile_2d(w, h, d) {
  polygon(
    points=[
      [0, 0],
      [w, 0],
      [w, h - d],
      [w - d, h],
      [0, h],
    ]
  );
}

// -------------------- PCB hole coordinates (PCB local) --------------------
tr = [pcb_w - pcb_r, pcb_h - pcb_r];
tl = [tr[0] - 31.5, tr[1]];
br = [tr[0] - 15, tr[1] - 28];
bl = [br[0] - 25.5, br[1]];
hole_pts = [tr, tl, br, bl];

module pcb_boss_with_hole(x, y) {
  translate([x, y, plate_t])
    difference() {
      cylinder(h=boss_h, d=boss_od);
      translate([0, 0, -cut_extra])
        cylinder(h=boss_h + 2 * cut_extra, d=m2_hole_d);
    }
}

// =========================================================
// FASTENING: BASE lugs (tap) + LID side holes (clearance)
// Only TOP wall (+Y) and RIGHT wall (+X)
// =========================================================
function clamp(v, lo, hi) = max(lo, min(hi, v));

// screw positions in XY (global)
top_x = clamp(outer_w - diag_cut - screw_offset, wall_t + 10, outer_w - diag_cut - 10);
right_y = clamp(outer_h - diag_cut - screw_offset, wall_t + 10, outer_h - diag_cut - 10);

// BASE lug centers (just inside outer edges)
lug_inset = wall_t + fit_gap + lug_t / 2 + lug_inset_extra;

base_top_lug_c = [top_x, outer_h - lug_inset];
base_right_lug_c = [outer_w - lug_inset, right_y];

// keep-out: PCB plate rectangle on BASE
keep_x0 = floor_xy[0];
keep_y0 = floor_xy[1];
keep_x1 = floor_xy[0] + plate_w;
keep_y1 = floor_xy[1] + plate_h;

function in_keepout(x, y) = (x > keep_x0 && x < keep_x1 && y > keep_y0 && y < keep_y1);

// If lug center falls inside PCB keepout, nudge it along wall direction
function nudge_if_keepout(p, dir) =
  in_keepout(p[0], p[1]) ? [p[0] + dir[0] * (lug_w / 2 + 2), p[1] + dir[1] * (lug_w / 2 + 2)] : p;

base_top_lug = nudge_if_keepout(base_top_lug_c, [1, 0]); // slide along X
base_right_lug = nudge_if_keepout(base_right_lug_c, [0, 1]); // slide along Y

// BASE lug: small block on base plate, with horizontal tap hole
module base_lug_at(cx, cy, rot_deg) {
  translate([cx, cy, base_t])
    rotate([0, 0, rot_deg])
      difference() {
        translate([-lug_w / 2, -lug_t / 2, 0])
          cube([lug_w, lug_t, lug_h], center=false);

        // horizontal tap hole: axis along local +Y (after rotate)
        translate([0, 0, screw_z])
          rotate([90, 0, 0])
            cylinder(h=lug_t + 1.0, d=side_tap_d, center=true);
      }
}

// LID wall side clearance holes (horizontal)
module lid_side_clear_holes() {
  wall_eff = wall_t + fit_gap; // lid skirt wall effective thickness
  hole_len = wall_eff + 6;

  // TOP wall
  translate([top_x, outer_h - wall_eff / 2, screw_z])
    rotate([90, 0, 0])
      cylinder(h=hole_len, d=side_clear_d, center=true);

  // RIGHT wall
  translate([outer_w - wall_eff / 2, right_y, screw_z])
    rotate([0, 90, 0])
      cylinder(h=hole_len, d=side_clear_d, center=true);
}

// =========================================================
// SENSOR HOLE (on LID diagonal wall only, short cut)
// =========================================================
t_on_diag = 0.50;

module sensor_hole_cutter() {
  ax = outer_w;
  ay = outer_h - diag_cut;
  bx = outer_w - diag_cut;
  by = outer_h;

  cx = ax * (1 - t_on_diag) + bx * t_on_diag;
  cy = ay * (1 - t_on_diag) + by * t_on_diag;

  hole_h_short = 2 * wall_t + 2;

  translate([cx, cy, sensor_center_z])
    rotate([0, 0, sensor_yaw_deg])
      rotate([0, 90, 0])
        cylinder(h=hole_h_short, d=sensor_hole_d, center=true);
}

// =========================================================
// BASE PART (bottom only) + PCB plate+bosses + 2 lugs
// =========================================================
module base_part() {
  union() {
    // Base bottom plate: match outer footprint (diagonal included)
    linear_extrude(height=base_t)
      diag_profile_2d(outer_w, outer_h, diag_cut);

    // Internal PCB mounting plate + bosses (shifted)
    translate([floor_xy[0], floor_xy[1], 0]) {
      linear_extrude(height=plate_t)
        rounded_rect_2d(plate_w, plate_h, plate_r);

      for (p = hole_pts)
        pcb_boss_with_hole(p[0], p[1]);
    }

    // Two lugs only (TOP and RIGHT)
    // TOP lug: accepts screw from TOP wall toward -Y
    base_lug_at(base_top_lug[0], base_top_lug[1], 0);

    // RIGHT lug: accepts screw from RIGHT wall toward -X (rotate 90)
    base_lug_at(base_right_lug[0], base_right_lug[1], 90);
  }
}

// =========================================================
// LID PART (walls + top as one piece)
// - skirt walls start at Z=0 and go up to Z=lid_skirt_h
// - top plate sits at Z=lid_skirt_h..lid_skirt_h+top_t
// - has diagonal wall and sensor hole
// - has side clearance holes (top+right walls)
// =========================================================
module lid_part() {
  difference() {
    union() {
      // TOP plate at the top of skirt
      translate([0, 0, lid_skirt_h])
        linear_extrude(height=top_t)
          diag_profile_2d(outer_w, outer_h, diag_cut);

      // SKIRT walls (ring shell)
      linear_extrude(height=lid_skirt_h)
        difference() {
          diag_profile_2d(outer_w, outer_h, diag_cut);
          // inner boundary: slightly larger clearance so it can slip over base outer
          offset(delta=-(wall_t) - fit_gap)
            diag_profile_2d(outer_w, outer_h, diag_cut);
        }
    }

    // Sensor hole (diagonal wall thickness region)
    sensor_hole_cutter();

    // Side clearance holes (2 walls only)
    lid_side_clear_holes();
  }
}

// =========================================================
// Assembly
// =========================================================
module assembly_view() {
  base_part();
  lid_part();
}

if (show == "base") {
  base_part();
} else if (show == "lid") {
  translate([0, 0, 5]) lid_part();
} else {
  assembly_view();
}
