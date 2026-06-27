#!/bin/bash
# Run the snap-fit FEM test (headless FreeCAD + CalculiX) and print results.
HERE="$(cd "$(dirname "$0")" && pwd)"
echo "Running FEM (CalculiX)... this takes ~20-40 s"
flatpak run --command=freecadcmd org.freecad.FreeCAD "$HERE/snap_test.py" 2>&1 \
  | grep -E '\[fem\]' | sed 's/\[fem\] //'
