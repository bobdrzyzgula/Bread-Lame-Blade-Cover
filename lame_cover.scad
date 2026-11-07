// lame_cover.scad — folding, snap-shut blade cover for a bread lame
// (double-edged razor blade on a flat 8 mm strip).
// Written by Claude (Anthropic) at Bob Drzyzgula's direction, Nov 2026.
// https://github.com/bobdrzyzgula/Bread-Lame-Blade-Cover
// SPDX-License-Identifier: MIT
//
// Clamshell with a print-in-place pin hinge at the blade-tip end.
// Prints flat, fully open (both halves cavity-up), no supports.
// Two side snap latches near the handle end; a thumb lip on the
// top half for flipping it open. The strip exits through a notch
// in the handle-end wall.
//
// Coordinates (closed): x = along the lame (hinge at x=0, handle
// end at +x), y = across the blade, z = thickness. Bottom half B
// is z 0..H, top half A is z H..2H, mating plane at z = H, hinge
// axis along y at (x=0, z=H).

/* [View] */
// 0 = print layout (open flat), 180 = closed
fold_angle = 0; // [0:5:180]

/* [Blade and strip] */
// Blade pocket length (DE blade is 43 mm)
blade_len = 44.5;  // [40:0.1:50]
// Blade pocket width (DE blade is 22 mm)
blade_wid = 24.0;  // [20:0.1:30]
// Total cavity thickness, both halves (blade bow / strip ~2 mm)
cavity_t  = 3.0;   // [2:0.1:5]
// How far the strip tip sticks out past the blade end
tip_len   = 7.0;   // [0:0.5:15]
// Width of the tip pocket
tip_wid   = 10.0;  // [5:0.5:20]
// Width of the strip exit notch (strip is ~8 mm)
shaft_wid = 9.5;   // [8:0.1:14]

/* [Shell] */
// Height of each half (also the hinge knuckle radius)
H        = 3.5;   // [3:0.1:5]
// Side wall thickness
wall     = 2.0;   // [1.2:0.1:3]
// End wall thickness
end_wall = 2.0;   // [1.2:0.1:3]
// Corner radius at the handle end
corner_r = 3.0;   // [0.5:0.5:5]

/* [Hinge] */
// Number of knuckles (odd: top half gets both ends)
n_knuckles = 5;    // [3:2:9]
// Pin radius
pin_r      = 1.6;  // [1:0.1:2.5]
// Radial clearance around the pin
pin_clear  = 0.4;  // [0.2:0.05:0.7]
// Axial gap between knuckles
knuckle_gap = 0.4; // [0.2:0.05:0.8]
// Clearance between a knuckle and the other half's end face
hinge_clear = 0.4; // [0.2:0.05:0.8]

/* [Latch] */
// Latch tab length along the case
tab_len   = 12;    // [6:0.5:20]
// Latch tab thickness (thinner = easier snap)
tab_t     = 1.0;   // [0.6:0.1:2]
// Slot between tab and the top half's side wall
tab_slot  = 0.6;   // [0.4:0.05:1]
// Snap interference (how far the bead rides over the wall)
snap_intf = 0.4;   // [0.1:0.05:0.8]
// Extra depth of the catch recess beyond the interference
recess_extra = 0.15; // [0:0.05:0.5]
// Thickness of the tab root (top skin)
tab_root  = 1.2;   // [0.8:0.1:2]
// Thumb lip length past the handle end (0 = none)
lip_len   = 3.0;   // [0:0.5:6]
// Thumb lip width
lip_wid   = 12;    // [4:1:25]

/* [Hidden] */
$fn = 64;
eps = 0.01;

// ---------- derived ----------
cd   = cavity_t / 2;                 // cavity depth per half
W    = blade_wid + 2*wall;           // outer width
g    = H + hinge_clear;              // hinge axis to body face
x_tip0 = g + end_wall;               // start of tip pocket
x_bl0  = x_tip0 + tip_len;           // start of blade pocket
Lc   = x_bl0 + blade_len + end_wall; // handle-end face
seg  = (W - (n_knuckles-1)*knuckle_gap) / n_knuckles;
xt1  = Lc - corner_r - 0.5;          // latch window
xt0  = xt1 - tab_len;
zb   = 0.3;                          // tab bottom, closed frame
e    = tab_slot + snap_intf;         // bead protrusion
d    = snap_intf + recess_extra;     // recess depth into B wall
zr   = zb + e + 0.1 - (d - snap_intf); // recess top (before chamfer)

function seg_y0(i) = -W/2 + i*(seg + knuckle_gap);

// ---------- shared shell (bottom-half orientation) ----------
module footprint() {
    hull() {
        translate([g, -W/2]) square([eps, W]);
        for (s = [-1, 1])
            translate([Lc - corner_r, s*(W/2 - corner_r)]) circle(r = corner_r);
    }
}

module cavities() {
    // blade pocket
    translate([x_bl0, -blade_wid/2, H - cd]) cube([blade_len, blade_wid, cd + 1]);
    // strip tip pocket
    translate([x_tip0, -tip_wid/2, H - cd]) cube([tip_len + eps, tip_wid, cd + 1]);
    // strip exit notch
    translate([x_bl0 + blade_len - 1, -shaft_wid/2, H - cd])
        cube([end_wall + 2 + corner_r, shaft_wid, cd + 1]);
}

module shell_bottom() {
    difference() {
        linear_extrude(H) footprint();
        cavities();
    }
}

module knuckle(i) {
    translate([0, seg_y0(i), H]) rotate([-90, 0, 0]) cylinder(r = H, h = seg);
}

// ---------- bottom half B (stationary) ----------
module half_B() {
    difference() {
        union() {
            shell_bottom();
            for (i = [1 : 2 : n_knuckles - 1]) {
                knuckle(i);
                translate([0, seg_y0(i), 0]) cube([g + eps, seg, H]);
            }
        }
        // pin bore
        translate([0, -W/2 - 1, H]) rotate([-90, 0, 0])
            cylinder(r = pin_r + pin_clear, h = W + 2);
        // latch catch recesses + lead-in chamfer on top outer edge
        for (s = [-1, 1]) mirror([0, s < 0 ? 1 : 0, 0]) {
            translate([xt0 - 0.5, 0, 0]) rotate([90, 0, 90])
                linear_extrude(tab_len + 1)
                    polygon([[W/2 - d, -1], [W/2 + 1, -1],
                             [W/2 + 1, zr + d + 1], [W/2 - d, zr]]);
            c = 0.6;
            translate([xt0 - 0.5, 0, 0]) rotate([90, 0, 90])
                linear_extrude(tab_len + 1)
                    polygon([[W/2 - c, H + 1], [W/2 - c, H],
                             [W/2, H - c], [W/2 + 1, H - c], [W/2 + 1, H + 1]]);
        }
    }
}

// ---------- top half A, in its closed position ----------
module half_A_closed() {
    union() {
        // shell = mirror of the bottom shell about the mating plane
        translate([0, 0, 2*H]) mirror([0, 0, 1]) shell_bottom();
        // knuckles + webs
        for (i = [0 : 2 : n_knuckles - 1]) {
            knuckle(i);
            translate([0, seg_y0(i), H]) cube([g + eps, seg, H]);
        }
        // pin, fused to this half's knuckles
        translate([0, -W/2, H]) rotate([-90, 0, 0]) cylinder(r = pin_r, h = W);
        // latch tabs
        for (s = [-1, 1]) mirror([0, s < 0 ? 1 : 0, 0]) {
            // root bridge in the top skin
            translate([xt0, W/2 - eps, 2*H - tab_root])
                cube([tab_len, tab_slot + tab_t + eps, tab_root]);
            // tab plate
            translate([xt0, W/2 + tab_slot, zb]) cube([tab_len, tab_t, 2*H - zb]);
            // bead (45/45 profile)
            translate([xt0, 0, 0]) rotate([90, 0, 90]) linear_extrude(tab_len)
                polygon([[W/2 + tab_slot + eps, zb],
                         [W/2 + tab_slot - e, zb + e],
                         [W/2 + tab_slot + eps, zb + 2*e]]);
        }
        // thumb lip
        if (lip_len > 0)
            translate([0, 0, 2*H - 1.6]) linear_extrude(1.6) hull() {
                translate([Lc - corner_r, -lip_wid/2]) square([eps, lip_wid]);
                for (s = [-1, 1])
                    translate([Lc + lip_len - 1.5, s*(lip_wid/2 - 1.5)]) circle(r = 1.5);
            }
    }
}

// rotate A about the hinge axis; fold_angle 0 = open, 180 = closed
module half_A(angle) {
    translate([0, 0, H]) rotate([0, angle - 180, 0]) translate([0, 0, -H])
        half_A_closed();
}

color("SteelBlue") half_B();
color("Goldenrod") half_A(fold_angle);
