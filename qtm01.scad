// =====================================================================
//  QTM01 / Garmin–Wahoo quarter-turn mount  —  MALE + FEMALE pair
// =====================================================================
//  Two interlocking parts:
//    - MALE   : the cleat (central post + two ears / tabs)
//    - FEMALE : the receptacle (slotted lip that captures the ears)
//
//  Insert the male tabs through the two entry slots in the female lip,
//  push down into the chamber, then twist 90 deg -> tabs are trapped
//  under the solid lip sections.  Classic quarter-turn bayonet.
//
//  Geometry is reverse-engineered from the community reference
//  (chadkirby/quarter-turn-mount) and matches the verified table:
//
//    post / body dia ...... 24.9   (26 clearance hole)
//    tab span tip-to-tip .. 28.6
//    tab width ............ 11
//    tab thickness ........ 1.5
//    lip / gap under tab .. 1.25
//    entry slot width ..... 12.5   (= 11 + 1.5)
//    overall body dia ..... 36
//
//  Render one part at a time for printing, or preview the fit.
// =====================================================================

// ---- README manifest (consumed by build_docs.py — drives the docs) ----
// @doc-title  QTM01 — Garmin / Wahoo Quarter-Turn Mount
// @doc-part   female     The receptacle: a capture lip with two entry slots over a tab chamber.
// @doc-part   male       The cleat: a central post carrying two locking ears.
// @doc-view   assembled  The seated, locked fit (static preview).
// @doc-gif    animate    Quarter-turn assembly — drop in, then twist 90 deg to lock.

/* [What to render] */
// male  = the cleat, female = the receptacle, both = print layout,
// assembled = static fit preview, animate = quarter-turn animation ($t)
part = "both";   // [male, female, both, assembled, animate, section]

/* [Verified quarter-turn geometry (mm) — do not change] */
post_d    = 24.9;   // central post / body diameter
tab_span  = 28.5;   // tab tip-to-tip (across the ears)
tab_w     = 11;     // tab width (across the ears)
tab_th    = 1.8;    // tab thickness (the male feature that engages the female)
lip       = 2;      // lip / "губка" thickness on top
hole_d    = 25.15;  // female central hole diameter
cavity_d  = 29.5;   // female inner chamber diameter ("тубус")
body_d    = 33.5;   // overall body diameter
slot_w    = 12.5;   // tab entry slot width

/* [Print tuning] */
clr      = 0;       // 0 = exact replica; raise (e.g. 0.3) for a printed sliding fit
ear_oval = 0.8;     // ear shape: 1 = circle, <1 = elongated oval along the span, >1 = flatter
post_h   = 3.75;    // MALE HEIGHT: the whole cleat (post + ears at its tip)
base_h   = 0;       // optional grip flange under the cleat (0 = bare cleat)
total_h  = 5.5;     // FEMALE overall height (the floor is derived to match)
fillet_r = 0.2;     // chamfer size on the lock features (pockets + ramps); 0 = sharp
$fn      = 120;

eps = 0.01;

/* [Preview colors] */
male_color   = "DarkBlue";   // male part colour in previews / animation
female_color = "DarkRed";    // female part colour in previews / animation

/* [Fixator — edge notch on the ears that locks the 90 deg position] */
detent     = true;   // cut the edge notch (fixator)
notch_dia  = 27.5;   // deepened so the 1 mm female bump seats (was 28.3)
notch_w    = 3.0;    // width of the notch along the ear edge  (TODO: уточнить)

pocket_play = 0.4;              // vertical headroom for the ear in the chamber
pocket_h    = tab_th + pocket_play;
floor_th    = total_h - pocket_h - lip;   // derived so the female height = total_h

/* [Female fixator — bumps that catch the ear notches] */
bump_h = 1.0;    // how far each bump stands proud of the chamber wall
bump_w = 1.5;    // bump width (looks like part of a tube)

/* [Clearance scoops — spheres on the male, sides without ears (±Y)] */
scoop_d     = 2 * post_d;   // sphere diameter ~ 2x the male main diameter (≈49.8)
scoop_min_h = 2.45;         // remaining male height at the deepest point (depth 1.3)

/* [Through-holes on the male — in the scoop regions (±Y)] */
side_hole_d  = 3.45;   // through-hole diameter
side_hole_ed = 2.5;    // gap from the outer edge to the NEAR edge of the hole
head_d       = 5.25;   // bolt-head recess diameter (top cylinder + cone wide end)
hole_remain  = 0.3;    // plain through-hole left at the very bottom

/* [Trapezoid lock — pockets on the male leading (mating) face] */
trap_offset = 2.05;  // gap from the outer edge to the pocket (outer end R=12.2)
trap_len    = 5.95;  // pocket length: outer R=12.2 -> inner R=6.25
trap_w_out  = 3.0;   // pocket width at the outer (wide) end
trap_w_in   = 2.0;   // pocket width at the centre (narrow) end
trap_depth  = 1.5;   // pocket depth

/* [Trapezoid lock — ramps on the female floor] */
ramp_len   = 4.9;   // ramp length (radial)
ramp_r_in  = 6.7;   // inner-end radius (the two inner ends are 13.4 mm apart)
ramp_w_out = 2.7;   // ramp width at the outer (wide) end
ramp_w_in  = 1.0;   // ramp width at the inner (narrow) end
ramp_h     = 1.0;   // ramp height at the outer edge
ramp_h_in  = 0.2;   // ramp height toward the centre (lower)

// ---------------------------------------------------------------------
//  Fixator — a shallow notch shaved into the OUTER EDGE of each ear,
//  reducing the diameter there from tab_span (28.5) to notch_dia (28.3).
//  A matching bump on the female will drop into it at the 90 deg lock.
// ---------------------------------------------------------------------
module ear_notches() {
    notch_depth = (tab_span - notch_dia) / 2;            // 0.1 mm on the radius
    Rc = (notch_w*notch_w/4 + notch_depth*notch_depth) / (2*notch_depth);
    Dc = notch_dia/2 + Rc;                               // cutter centre distance
    for (a = [0, 180])                                   // both ears (+/-X)
        rotate([0, 0, a])
        translate([Dc, 0, base_h + post_h - tab_th - eps])
            cylinder(r = Rc, h = tab_th + 2*eps);
}

// two vertical through-holes in the scoop regions (+/-Y); 2.5 mm gap
// between the part edge and the near edge of each hole
// one bolt recess as a SINGLE revolved solid (hole + cone + cylinder) — the
// sections share no coincident faces, so the cut renders cleanly
module bolt_recess() {
    rotate_extrude()
        polygon([
            [0,             -1],
            [side_hole_d/2, -1],
            [side_hole_d/2, hole_remain],   // straight hole at the bottom
            [head_d/2,      scoop_min_h],   // cone up to the scoop floor
            [head_d/2,      post_h + 1],    // cylinder up through the top
            [0,             post_h + 1]
        ]);
}

module side_holes() {
    r = post_d/2 - side_hole_ed - side_hole_d/2;   // hole centre radius
    for (sy = [1, -1])
        translate([0, sy*r, 0]) bolt_recess();
}

// large shallow spherical scoops on the sides without ears (+/-Y),
// deepest near the outer edge — clearance for the female ramps at the
// start of the twist.  Subtracted from the male.
module clearance_spheres() {
    R  = scoop_d/2;
    Zc = scoop_min_h + R;             // sphere bottom sits at scoop_min_h
    for (sy = [1, -1])
        translate([0, sy*post_d/2, Zc]) sphere(d = scoop_d);
}

// single-segment (chamfer) transition on a convex feature's edges — fast.
// Uses an octahedron as the minkowski element -> flat bevels, not round fillets.
module fil() {
    if (fillet_r > 0)
        minkowski() {
            children();
            hull() for (p = [[1,0,0],[-1,0,0],[0,1,0],[0,-1,0],[0,0,1],[0,0,-1]])
                translate(p * fillet_r) cube(0.002, center = true);
        }
    else children();
}

// two trapezoidal pockets on the leading (mating) face, one at each ear (+/-X)
module trap_pockets() {
    r_out = tab_span/2 - trap_offset;   // outer end, set in from the edge
    r_in  = r_out - trap_len;           // inner end, toward the centre
    for (a = [0, 180])
        rotate([0, 0, a])
        translate([0, 0, base_h + post_h - trap_depth])
            fil() linear_extrude(trap_depth + eps)
                polygon([[r_in, -trap_w_in/2],  [r_out, -trap_w_out/2],
                         [r_out, trap_w_out/2],  [r_in,  trap_w_in/2]]);
}

// vertical "tube-part" ribs on the chamber wall that catch the ear notches
module fixator_bumps() {
    Rw = (cavity_d + clr) / 2;              // chamber wall radius
    cr = Rw - bump_h + bump_w/2;            // centre radius of the rib cylinder
    for (a = [90, 270])                     // +/-Y: where the locked notches sit
        rotate([0, 0, a])
        translate([cr, 0, floor_th])
            cylinder(d = bump_w, h = pocket_h);
}

// two trapezoidal ramps on the chamber floor (+/-Y) that seat into the
// male pockets at lock — taller at the outer edge, lower toward the centre
module trap_ramps() {
    r_in  = ramp_r_in;                      // inner end (13.4 mm between the two)
    r_out = r_in + ramp_len;
    for (a = [90, 270])
        rotate([0, 0, a])
        translate([0, 0, floor_th])
        fil() hull() {
            translate([r_out, -ramp_w_out/2, 0]) cube([0.01, ramp_w_out, ramp_h]);
            translate([r_in,  -ramp_w_in/2,  0]) cube([0.01, ramp_w_in,  ramp_h_in]);
        }
}

// ---------------------------------------------------------------------
//  MALE  —  cleat: grip flange + post + two ears (with detent notches)
// ---------------------------------------------------------------------
module qtm_male() {
    difference() {
        union() {
            // optional grip flange (prints face-down, stays outside the female)
            if (base_h > 0) cylinder(d = body_d, h = base_h);

            translate([0, 0, base_h]) {
                // central post
                cylinder(d = post_d, h = post_h);

                // two ears at the leading tip: an OVAL (ellipse) trimmed to
                // 11 wide, so the outer edge is flatter than a plain circle
                translate([0, 0, post_h - tab_th])
                    intersection() {
                        scale([1, ear_oval, 1]) cylinder(d = tab_span, h = tab_th);
                        cube([tab_span + 2, tab_w, 100], center = true);
                    }
            }
        }
        // edge notch (fixator) shaved into each ear
        if (detent) ear_notches();
        // trapezoidal pockets on the mating face, one per ear
        trap_pockets();
        // large spherical scoops on the sides without ears (+/-Y)
        clearance_spheres();
        // two through-holes in the scoop regions
        side_holes();
    }
}

// ---------------------------------------------------------------------
//  FEMALE  —  receptacle: closed floor + tab chamber + slotted lip
// ---------------------------------------------------------------------
module qtm_female() {
    pocket_d = cavity_d + clr;          // chamber the ears rotate in
    lip_id   = hole_d  + clr;           // bore through the lip (post clears)
    H        = floor_th + pocket_h + lip;

    difference() {
        cylinder(d = body_d, h = H);                    // solid body

        // tab chamber, open upward, stops under the lip
        translate([0, 0, floor_th])
            cylinder(d = pocket_d, h = pocket_h + eps);

        // central bore through the lip (post clearance)
        translate([0, 0, floor_th + pocket_h - eps])
            cylinder(d = lip_id, h = lip + 2*eps);

        // two entry slots cut through the lip, aligned on X
        translate([0, 0, floor_th + pocket_h - eps])
            intersection() {
                cylinder(d = pocket_d, h = lip + 2*eps);
                cube([body_d*2, slot_w + clr, lip*4], center = true);
            }
    }
    // trapezoidal ramps on the floor that seat into the male pockets at 90 deg
    trap_ramps();
    // fixator bump (detent) that clicks into the deepened ear notch
    if (detent) fixator_bumps();
}

// ---------------------------------------------------------------------
//  Layout
// ---------------------------------------------------------------------
module print_both() {
    translate([-(body_d/2 + 3), 0, 0]) color(female_color) qtm_female();
    translate([ (body_d/2 + 3), 0, 0]) color(male_color) qtm_male();
}

module assembled() {
    // male flipped tabs-down, ears seated on the floor, turned 90 deg (locked)
    color(female_color) qtm_female();
    color(male_color)
        translate([0, 0, base_h + post_h + floor_th])
        rotate([180, 0, 90])
        qtm_male();
}

// ---------------------------------------------------------------------
//  Assembly animation (uses the built-in $t, looping 0 -> 1)
//    t 0.00 .. 0.50 : male descends, ears aligned with the entry slots
//    t 0.50 .. 1.00 : male twists 90 deg -> ears lock under the lip
//  Enable in OpenSCAD: View > Animate, then set FPS + Steps (e.g. 25 / 100).
// ---------------------------------------------------------------------
module assembly_anim() {
    seat_z   = base_h + post_h + floor_th;   // locked depth (ear on the floor)
    lift     = 22;                            // start height above the female

    descend = ($t < 0.5) ? seat_z + lift * (1 - $t/0.5) : seat_z;
    twist   = ($t < 0.5) ? 0 : 90 * ($t - 0.5)/0.5;

    color(female_color) qtm_female();
    color(male_color)
        translate([0, 0, descend])
        rotate([180, 0, twist])
        qtm_male();
}

// male sliced at X=0 (through both bolt holes) — reveals the internal cone in 3D
module male_section() {
    difference() {
        color(male_color) qtm_male();
        translate([0, -100, -50]) cube([100, 200, 200]);   // remove X>0
    }
}

if      (part == "male")      color(male_color) qtm_male();
else if (part == "female")    color(female_color) qtm_female();
else if (part == "assembled") assembled();
else if (part == "animate")   assembly_anim();
else if (part == "section")   male_section();
else                          print_both();
