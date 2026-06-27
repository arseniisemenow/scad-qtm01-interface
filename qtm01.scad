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
part = "both";   // [male, female, both, assembled, animate]

/* [Verified quarter-turn geometry (mm) — do not change] */
post_d    = 24.9;   // central post / body diameter
tab_span  = 28.6;   // tab tip-to-tip
tab_w     = 11;     // tab width (across the ears)
tab_th    = 1.5;    // tab thickness
lip       = 1.25;   // lip / capture gap under the tab
hole_d    = 26;     // female central clearance hole
cavity_d  = 30;     // female inner chamber diameter
body_d    = 36;     // overall body diameter
slot_w    = 12.5;   // tab entry slot width

/* [Print tuning] */
clr      = 0.4;     // clearance added to ALL female openings (tune the click)
base_h   = 4;       // male grip flange thickness
post_h   = 4;       // male post length above the flange (ears live on its tip)
floor_th = 2;       // female solid floor under the chamber
$fn      = 120;

eps = 0.01;

// ---------------------------------------------------------------------
//  MALE  —  cleat: grip flange + post + two ears at the tip
// ---------------------------------------------------------------------
module qtm_male() {
    // grip flange (prints face-down, stays outside the female)
    cylinder(d = body_d, h = base_h);

    translate([0, 0, base_h]) {
        // central post
        cylinder(d = post_d, h = post_h);

        // two ears at the leading tip (a 28.6 disc trimmed to 11 wide)
        translate([0, 0, post_h - tab_th])
            intersection() {
                cylinder(d = tab_span, h = tab_th);
                cube([tab_span + 2, tab_w, 100], center = true);
            }
    }
}

// ---------------------------------------------------------------------
//  FEMALE  —  receptacle: closed floor + tab chamber + slotted lip
// ---------------------------------------------------------------------
module qtm_female() {
    pocket_d = cavity_d + clr;          // chamber the ears rotate in
    lip_id   = hole_d  + clr;           // bore through the lip (post clears)
    pocket_h = tab_th + 1.0;            // headroom for the ears below the lip
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
}

// ---------------------------------------------------------------------
//  Layout
// ---------------------------------------------------------------------
module print_both() {
    translate([-(body_d/2 + 3), 0, 0]) qtm_female();
    translate([ (body_d/2 + 3), 0, 0]) qtm_male();
}

module assembled() {
    pocket_h = tab_th + 1.0;
    H = floor_th + pocket_h + lip;
    // male flipped tabs-down, ears seated in the chamber, turned 90 deg (locked)
    color("SteelBlue") qtm_female();
    color("Goldenrod")
        translate([0, 0, base_h + post_h + floor_th + 0.5])
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
    pocket_h = tab_th + 1.0;
    H        = floor_th + pocket_h + lip;
    seat_z   = base_h + post_h + floor_th + 0.5;   // locked depth (from assembled)
    lift     = 22;                                  // start height above the female

    descend = ($t < 0.5) ? seat_z + lift * (1 - $t/0.5) : seat_z;
    twist   = ($t < 0.5) ? 0 : 90 * ($t - 0.5)/0.5;

    color("SteelBlue") qtm_female();
    color("Goldenrod")
        translate([0, 0, descend])
        rotate([180, 0, twist])
        qtm_male();
}

if      (part == "male")      qtm_male();
else if (part == "female")    qtm_female();
else if (part == "assembled") assembled();
else if (part == "animate")   assembly_anim();
else                          print_both();
