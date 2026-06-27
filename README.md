<!-- AUTO-GENERATED from qtm01.scad by build_docs.py — do not edit by hand. -->

# QTM01 — Garmin / Wahoo Quarter-Turn Mount

```
 QTM01 / Garmin–Wahoo quarter-turn mount  —  MALE + FEMALE pair
 Two interlocking parts:
   - MALE   : the cleat (central post + two ears / tabs)
   - FEMALE : the receptacle (slotted lip that captures the ears)

 Insert the male tabs through the two entry slots in the female lip,
 push down into the chamber, then twist 90 deg -> tabs are trapped
 under the solid lip sections.  Classic quarter-turn bayonet.

 Geometry is reverse-engineered from the community reference
 (chadkirby/quarter-turn-mount) and matches the verified table:

   post / body dia ...... 24.9   (26 clearance hole)
   tab span tip-to-tip .. 28.6
   tab width ............ 11
   tab thickness ........ 1.5
   lip / gap under tab .. 1.25
   entry slot width ..... 12.5   (= 11 + 1.5)
   overall body dia ..... 36

 Render one part at a time for printing, or preview the fit.
```

## Parts

### female

The receptacle: a capture lip with two entry slots over a tab chamber.

![female](images/female.png)

Print: `openscad -o female.stl -D 'part="female"' qtm01.scad`

### male

The cleat: a central post carrying two locking ears.

![male](images/male.png)

Print: `openscad -o male.stl -D 'part="male"' qtm01.scad`

## Preview

### assembled

The seated, locked fit (static preview).

![assembled](images/assembled.png)

## Assembly

### animate

Quarter-turn assembly — drop in, then twist 90 deg to lock.

![animate](images/animate.gif)

## Parameters


**What to render**

| Parameter | Value | Description |
|---|---|---|
| `part` | `"both"` | one of: male, female, both, assembled, animate |

**Verified quarter-turn geometry (mm) — do not change**

| Parameter | Value | Description |
|---|---|---|
| `post_d` | `24.9` | central post / body diameter |
| `tab_span` | `28.6` | tab tip-to-tip |
| `tab_w` | `11` | tab width (across the ears) |
| `tab_th` | `1.5` | tab thickness |
| `lip` | `1.25` | lip / capture gap under the tab |
| `hole_d` | `26` | female central clearance hole |
| `cavity_d` | `30` | female inner chamber diameter |
| `body_d` | `36` | overall body diameter |
| `slot_w` | `12.5` | tab entry slot width |

**Print tuning**

| Parameter | Value | Description |
|---|---|---|
| `clr` | `0.4` | clearance added to ALL female openings (tune the click) |
| `base_h` | `4` | male grip flange thickness |
| `post_h` | `4` | male post length above the flange (ears live on its tip) |
| `floor_th` | `2` | female solid floor under the chamber |
| `$fn` | `120` |  |
| `eps` | `0.01` |  |
