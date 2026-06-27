#!/usr/bin/env python3
"""Generate README.md + renders (PNG/STL) + assembly GIFs for a SCAD project.

Everything in the README is derived from the .scad file:
  - title / overview  : the @doc-title directive + the header comment block
  - parts/views/anim  : the @doc-part / @doc-view / @doc-gif directives
  - parameter table   : the OpenSCAD Customizer groups + variables

Usage:  python3 build_docs.py [path/to/file.scad]
        (defaults to the single .scad file next to this script)
"""

import os
import re
import sys
import glob
import shutil
import tempfile
import subprocess

# --- render settings -------------------------------------------------------
PART_IMG   = "640,512"
PART_CAM   = "0,0,0,58,0,25,0"          # gimbal rot; distance set by --viewall
GIF_IMG    = "480,480"
GIF_CAM    = "0,0,14,68,0,30,160"       # fixed cam (override: // @doc-gif-camera ...)
GIF_FRAMES = 48
GIF_FPS    = 20
COLORS     = "Tomorrow"


def run(cmd):
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def need(tool):
    if shutil.which(tool) is None:
        sys.exit(f"error: required tool '{tool}' not found on PATH")


# --- parse the scad --------------------------------------------------------
def parse_scad(path):
    lines = open(path, encoding="utf-8").read().splitlines()

    doc = {"title": None, "parts": [], "views": [], "gifs": [],
           "gif_camera": GIF_CAM, "overview": [], "params": []}

    # manifest directives
    for ln in lines:
        m = re.match(r"\s*//\s*@doc-(\w[\w-]*)\s+(.*)$", ln)
        if not m:
            continue
        key, rest = m.group(1), m.group(2).strip()
        if key == "title":
            doc["title"] = rest
        elif key == "gif-camera":
            doc["gif_camera"] = rest
        elif key in ("part", "view", "gif"):
            name, _, desc = rest.partition(" ")
            entry = {"name": name.strip(), "desc": desc.strip()}
            doc[{"part": "parts", "view": "views", "gif": "gifs"}[key]].append(entry)

    # overview = the leading contiguous // comment block (header), minus borders
    for ln in lines:
        s = ln.strip()
        if s.startswith("//"):
            body = s[2:].rstrip()
            if set(body.strip()) <= {"=", "-", " "} and body.strip():
                continue  # skip pure border rules
            doc["overview"].append(body[1:] if body.startswith(" ") else body)
        else:
            if s == "":
                break  # first blank line ends the header block
    # trim leading/trailing blanks
    while doc["overview"] and not doc["overview"][0].strip():
        doc["overview"].pop(0)
    while doc["overview"] and not doc["overview"][-1].strip():
        doc["overview"].pop()

    # parameters: Customizer groups + `name = value; // comment`, until first module
    group = None
    for ln in lines:
        if re.match(r"\s*module\b", ln):
            break
        g = re.match(r"\s*/\*\s*\[(.+?)\]\s*\*/", ln)
        if g:
            group = g.group(1).strip()
            continue
        p = re.match(r"\s*([\$A-Za-z_]\w*)\s*=\s*(.+?);\s*(?://\s*(.*))?$", ln)
        if p:
            name, value, comment = p.group(1), p.group(2).strip(), (p.group(3) or "").strip()
            em = re.match(r"\[(.*)\]$", comment)        # dropdown enum, e.g. part
            if em:
                comment = "one of: " + ", ".join(x.strip() for x in em.group(1).split(","))
            doc["params"].append({"group": group, "name": name,
                                  "value": value, "comment": comment})
    return doc


# --- rendering -------------------------------------------------------------
def render_png(scad, part, out):
    run(["openscad", "-o", out, "-D", f'part="{part}"', f"--imgsize={PART_IMG}",
         "--viewall", "--autocenter", f"--camera={PART_CAM}",
         f"--colorscheme={COLORS}", scad])


def render_stl(scad, part, out):
    run(["openscad", "-o", out, "-D", f'part="{part}"', scad])


def render_gif(scad, part, out, camera):
    need("ffmpeg")
    with tempfile.TemporaryDirectory() as tmp:
        frame = os.path.join(tmp, "frame.png")
        # fillet_r=0 keeps the many animation frames fast (fillets are invisible here)
        run(["openscad", "-o", frame, "-D", f'part="{part}"', "-D", "fillet_r=0",
             f"--animate={GIF_FRAMES}", f"--imgsize={GIF_IMG}",
             f"--camera={camera}", f"--colorscheme={COLORS}", scad])
        pat = os.path.join(tmp, "frame%05d.png")
        pal = os.path.join(tmp, "pal.png")
        run(["ffmpeg", "-y", "-framerate", str(GIF_FPS), "-i", pat,
             "-vf", "palettegen=stats_mode=full", pal])
        run(["ffmpeg", "-y", "-framerate", str(GIF_FPS), "-i", pat, "-i", pal,
             "-lavfi", "paletteuse=dither=bayer:bayer_scale=3", "-loop", "0", out])


# --- README ----------------------------------------------------------------
def build_readme(doc, scad_name, img_dir):
    L = []
    L.append("<!-- AUTO-GENERATED from %s by build_docs.py — do not edit by hand. -->"
             % scad_name)
    L.append("")
    L.append("# " + (doc["title"] or os.path.splitext(scad_name)[0]))
    L.append("")
    if doc["overview"]:
        L.append("```")
        L.extend(doc["overview"])
        L.append("```")
        L.append("")

    def section(title, entries, with_stl):
        if not entries:
            return
        L.append("## " + title)
        L.append("")
        for e in entries:
            n = e["name"]
            L.append("### " + n)
            L.append("")
            if e["desc"]:
                L.append(e["desc"])
                L.append("")
            img = ("%s/%s.gif" if with_stl == "gif" else "%s/%s.png") % (img_dir, n)
            L.append("![%s](%s)" % (n, img))
            L.append("")
            if with_stl is True:
                L.append("Print: `openscad -o %s.stl -D 'part=\"%s\"' %s`" % (n, n, scad_name))
                L.append("")

    section("Parts", doc["parts"], True)
    section("Preview", doc["views"], False)
    section("Assembly", doc["gifs"], "gif")

    if doc["params"]:
        L.append("## Parameters")
        L.append("")
        cur = object()
        for p in doc["params"]:
            if p["group"] != cur:
                cur = p["group"]
                L.append("")
                L.append("**%s**" % (cur or "General"))
                L.append("")
                L.append("| Parameter | Value | Description |")
                L.append("|---|---|---|")
            L.append("| `%s` | `%s` | %s |" % (p["name"], p["value"], p["comment"]))
        L.append("")
    return "\n".join(L).rstrip() + "\n"


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    if len(sys.argv) > 1:
        scad = os.path.abspath(sys.argv[1])
    else:
        scads = [s for s in glob.glob(os.path.join(here, "*.scad"))]
        if len(scads) != 1:
            sys.exit("error: specify a .scad file (found %d in %s)" % (len(scads), here))
        scad = scads[0]

    need("openscad")
    scad_dir = os.path.dirname(scad)
    scad_name = os.path.basename(scad)
    img_dir = "images"
    img_abs = os.path.join(scad_dir, img_dir)
    os.makedirs(img_abs, exist_ok=True)

    doc = parse_scad(scad)
    print("project: %s" % scad_name)

    for e in doc["parts"]:
        n = e["name"]
        print("  part   %-10s -> images/%s.png, %s.stl" % (n, n, n))
        render_png(scad, n, os.path.join(img_abs, n + ".png"))
        render_stl(scad, n, os.path.join(scad_dir, n + ".stl"))
    for e in doc["views"]:
        n = e["name"]
        print("  view   %-10s -> images/%s.png" % (n, n))
        render_png(scad, n, os.path.join(img_abs, n + ".png"))
    for e in doc["gifs"]:
        n = e["name"]
        print("  gif    %-10s -> images/%s.gif" % (n, n))
        render_gif(scad, n, os.path.join(img_abs, n + ".gif"), doc["gif_camera"])

    readme = build_readme(doc, scad_name, img_dir)
    open(os.path.join(scad_dir, "README.md"), "w", encoding="utf-8").write(readme)
    print("  wrote  README.md")


if __name__ == "__main__":
    main()
