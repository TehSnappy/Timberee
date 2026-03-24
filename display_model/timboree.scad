// ═══════════════════════════════════════════════════════════════════
//  Inky wHAT Desk Stand
//  Pimoroni Inky wHAT (4.2" ePaper, 400×300 px)
//  Inky wHAT PCB : 91 × 77 mm
//  Raspberry Pi Zero PCB : 65 × 30 mm  (stacks behind via GPIO header)
// ═══════════════════════════════════════════════════════════════════

/* [Inky wHAT PCB] */
pcb_w     = 91;    // PCB width  (mm)
pcb_h     = 77;    // PCB height (mm)
pcb_t     = 1.6;   // PCB thickness

/* [Display Window] */
disp_w     = 85;   // cutout width   (active area 84.8 mm, rounded up)
disp_h     = 64;   // cutout height  (active area 63.6 mm, rounded up)
disp_x_pcb = 3.0;  // display left edge offset from PCB left edge  ≈ (91-85)/2
disp_y_pcb = 6.5;  // display bottom edge offset from PCB bottom   ≈ (77-64)/2

/* [Face Plate] */
margin_side  = 5;    // clearance left / right of PCB
margin_top   = 5;    // clearance above PCB
margin_bot   = 12;   // clearance below PCB  ← keeps RPi Zero clear of base
face_wall    = 5;    // total face plate thickness  (front skin + pocket)
pocket_depth = 2.2;  // PCB recess depth on back face  (≥ pcb_t + tolerance)
pocket_tol   = 0.4;  // fit clearance around PCB in pocket

/* [Stand Geometry] */
tilt      = 60;   // face angle from horizontal (degrees)

/* [Base] */
base_w    = 115;
base_d    = 90;
base_t    = 5;
corner_r  = 8;

/* [Side Supports] */
sup_t     = 3;

$fn = 64;

// ── derived ──────────────────────────────────────────────────────
face_w = pcb_w + margin_side * 2;          // 101 mm
face_h = margin_bot + pcb_h + margin_top;  // 94 mm

proj_y = face_h * cos(tilt);
proj_z = face_h * sin(tilt);

face_x0 = (base_w - face_w) / 2;
face_y0 = (base_d - proj_y) / 2;

// PCB bottom-left corner in face-plate local coords
pcb_x0 = margin_side;
pcb_z0 = margin_bot;

// ── assembly ─────────────────────────────────────────────────────
union() {
    base();
    face_plate();
    translate([face_x0 - sup_t, face_y0, base_t]) side_triangle();
    translate([face_x0 + face_w, face_y0, base_t]) side_triangle();
}

// ── modules ──────────────────────────────────────────────────────

module base() {
    hull()
        for (x = [corner_r, base_w - corner_r],
             y = [corner_r, base_d - corner_r])
            translate([x, y, 0])
                cylinder(r = corner_r, h = base_t);
}

// Face plate with:
//   • Through-hole display window — viewer sees ePaper through front face
//   • Back-face PCB pocket — Inky wHAT slides in from the top
//     The solid material below pcb_z0 forms the retaining ledge.
//   • RPi Zero hangs freely behind Inky wHAT on the GPIO header;
//     margin_bot is sized so it clears the base at 60° tilt.
module face_plate() {
    translate([face_x0, face_y0, base_t])
    rotate([-(90 - tilt), 0, 0])
    difference() {
        // Solid face slab
        cube([face_w, face_wall, face_h]);

        // ① Display window — full through-hole so the ePaper is visible
        translate([pcb_x0 + disp_x_pcb, -1, pcb_z0 + disp_y_pcb])
            cube([disp_w, face_wall + 2, disp_h]);

        // ② PCB pocket — channel recessed into the back face, open at top
        //    PCB slides straight down and rests on the solid ledge at z = pcb_z0.
        //    Uncut material below pcb_z0 (margin_bot) is the retaining ledge.
        translate([pcb_x0 - pocket_tol,
                   face_wall - pocket_depth,
                   pcb_z0])
            cube([pcb_w + pocket_tol * 2,
                  pocket_depth + 1,       // +1 opens the back face flush
                  face_h - pcb_z0 + 1]); // extends past top → open slot
    }
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
