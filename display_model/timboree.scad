// ═══════════════════════════════════════════════════════════════════
//  HDMI Display Desk Stand
//  Adafruit 800×480 5" HDMI Display  (~PID 2232)
//  Raspberry Pi Zero 2 W  (65 × 30 mm)  — mounted flat on base
//  Adafruit Snap-In Panel-Mount USB-C Jack  (PID 4052) — in back ridge
// ═══════════════════════════════════════════════════════════════════

/* [HDMI Display PCB] */
pcb_w     = 120.7;  // PCB width  (mm)
pcb_h     =  75.9;  // PCB height (mm)
pcb_t     =   1.6;  // PCB thickness

/* [Display Window] */
disp_w     = 108.0;  // cutout width  (active area ≈ 108 mm)
disp_h     =  65.0;  // cutout height (active area ≈ 64.8 mm)
disp_x_pcb =   6.35; // display left offset from PCB left  ≈ (120.7-108)/2
disp_y_pcb =   5.45; // display bottom offset from PCB bottom ≈ (75.9-65)/2

/* [Face Plate] */
margin_side  =  6;   // clearance left / right of PCB
margin_top   =  6;   // clearance above PCB
margin_bot   = 12;   // clearance below PCB
face_wall    =  6;   // total face plate thickness
pocket_depth =  2.2; // PCB recess depth on back face  (≥ pcb_t + tolerance)
pocket_tol   =  0.4; // fit clearance around PCB in pocket

/* [Stand Geometry] */
tilt = 60;   // face angle from horizontal (degrees)

/* [Base] */
base_w   = 148;
base_d   = 150;  // deep enough for RPi footprint behind face plate
base_t   =   5;
corner_r =   8;

/* [Side Supports] */
sup_t = 4;

/* [Back Ridge] */
// The ridge is formed by extending the base's back-corner cylinders upward.
// Its front-to-back depth = 2 × corner_r = 16 mm.
ridge_h  = 20;   // height of ridge above base top surface

/* [Raspberry Pi Zero 2 W  — on base, in front of face plate] */
// PCB: 65 × 30 mm; holes at 3.5 mm from each edge (58 × 23 mm grid)
rpi_w       = 65.0;
rpi_h       = 30.0;
rpi_hole_x  = [3.5, 61.5];  // X positions from RPi left edge
rpi_hole_y  = [3.5, 26.5];  // Y positions from RPi front edge
rpi_margin_back  = 3.0;     // gap from face plate back edge to RPi front edge
standoff_h  =  5.0;         // standoff height above base top surface
standoff_od =  6.0;         // standoff outer diameter
standoff_id =  2.7;         // M2.5 screw clearance hole diameter

/* [USB-C panel-mount jack  (Adafruit PID 4052, snap-in)] */
// Snap-in rectangular cutout: 21.8 × 10.9 mm
usbc_cut_w  = 22.0;  // + 0.2 mm print clearance
usbc_cut_h  = 11.2;
usbc_cr     =  1.0;  // cutout corner radius

$fn = 64;

// ── derived ──────────────────────────────────────────────────────
face_w = pcb_w + margin_side * 2;          // ≈ 132.7 mm
face_h = margin_bot + pcb_h + margin_top;  // ≈  93.9 mm

proj_y = face_h * cos(tilt);   // base footprint depth of the tilted face
proj_z = face_h * sin(tilt);   // face top height above base

face_x0 = (base_w - face_w) / 2;  // centre face plate on base in X
face_y0 = 0;                       // face plate flush with front of base

// PCB bottom-left in face-plate local coords (X = width, Y = depth, Z = height)
pcb_x0 = margin_side;
pcb_z0 = margin_bot;

// RPi Zero 2 W: centred in X on base, behind face plate (Y > face_y0 + proj_y)
rpi_base_x0 = (base_w - rpi_w) / 2;
rpi_base_y0 = face_y0 + proj_y + rpi_margin_back;

// Ridge depth = 2 × corner_r; front face of ridge at y = base_d - 2*corner_r
ridge_depth = 2 * corner_r;   // 16 mm
ridge_y0    = base_d - ridge_depth;  // front face of ridge

// USB-C cutout: centred in X on ridge, centred vertically in ridge
usbc_base_x = base_w / 2 - usbc_cut_w / 2;
usbc_base_z = base_t + (ridge_h - usbc_cut_h) / 2;

// ── assembly ─────────────────────────────────────────────────────
union() {
    base();
    back_ridge();
    face_plate();
    translate([face_x0 - sup_t, face_y0, base_t]) side_triangle();
    translate([face_x0 + face_w, face_y0, base_t]) side_triangle();
    rpi_standoffs();
}

// ── modules ──────────────────────────────────────────────────────

module base() {
    hull()
        for (x = [corner_r, base_w - corner_r],
             y = [corner_r, base_d - corner_r])
            translate([x, y, 0])
                cylinder(r = corner_r, h = base_t);
}

// Back ridge – same corner geometry as the base but extended to ridge_h.
// Naturally blends with the base because it shares the back-corner cylinders.
// USB-C snap-in cutout goes through the ridge from back to front (in Y).
module back_ridge() {
    difference() {
        hull()
            for (x = [corner_r, base_w - corner_r])
                translate([x, base_d - corner_r, 0])
                    cylinder(r = corner_r, h = base_t + ridge_h);

        // USB-C snap-in cutout – accessible from behind the stand
        translate([usbc_base_x, ridge_y0 - 1, usbc_base_z])
            rounded_rect_y(usbc_cut_w, usbc_cut_h, usbc_cr, ridge_depth + 2);
    }
}

// Four M2.5 standoff posts on the base top surface, matching RPi Zero 2 W hole pattern.
module rpi_standoffs() {
    for (xi = rpi_hole_x, yi = rpi_hole_y)
        translate([rpi_base_x0 + xi, rpi_base_y0 + yi, base_t])
            rpi_standoff();
}

module rpi_standoff() {
    difference() {
        cylinder(d = standoff_od, h = standoff_h);
        translate([0, 0, -1])
            cylinder(d = standoff_id, h = standoff_h + 2);
    }
}

// Face plate with display window and PCB pocket.
module face_plate() {
    translate([face_x0, face_y0, base_t])
    rotate([-(90 - tilt), 0, 0])
    difference() {
        // Solid face slab
        cube([face_w, face_wall, face_h]);

        // ① Display window – full through-hole so the LCD is visible
        translate([pcb_x0 + disp_x_pcb, -1, pcb_z0 + disp_y_pcb])
            cube([disp_w, face_wall + 2, disp_h]);

        // ② PCB pocket – channel recessed into back face, open at top
        //    PCB slides straight down and rests on the solid ledge at z = pcb_z0.
        translate([pcb_x0 - pocket_tol - 6,
                   face_wall - pocket_depth,
                   pcb_z0])
            cube([pcb_w + pocket_tol * 2 + 5,
                  pocket_depth + 1,       // +1 opens flush with back face
                  face_h - pcb_z0 + 1]);  // extends past top → open slot
    }
}

// Rounded rectangle extruded in +Y.
// w × h footprint in X-Z plane, depth along Y.
module rounded_rect_y(w, h, r, depth) {
    hull()
        for (dx = [r, w - r], dz = [r, h - r])
            translate([dx, 0, dz])
                rotate([-90, 0, 0])
                    cylinder(r = r, h = depth);
}

// Right-triangle side-support brace.
// Profile in the Y-Z plane; extruded sup_t along X.
module side_triangle() {
    multmatrix([
        [0, 0, 1, 0],   // world X ← local Z  (extrusion)
        [1, 0, 0, 0],   // world Y ← local X
        [0, 1, 0, 0],   // world Z ← local Y
        [0, 0, 0, 1]
    ])
    linear_extrude(sup_t)
    polygon([[0, 0], [proj_y, 0], [proj_y, proj_z]]);
}
