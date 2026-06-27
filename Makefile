# Regenerate README.md, renders (PNG/STL) and assembly GIFs from the .scad.
# All docs are derived from the .scad file by build_docs.py.

.PHONY: docs fem fem-contact clean clean-fem

docs:
	python3 build_docs.py

# Snap-fit FEM (headless FreeCAD + CalculiX). Geometry is read from qtm01.scad.
#   fem         = simplified single-body (ear), fast & conservative
#   fem-contact = real 2-body contact (ear vs female bump)
fem:
	./fem/run.sh

fem-contact:
	flatpak run --command=freecadcmd org.freecad.FreeCAD $(CURDIR)/fem/contact_test.py 2>&1 \
	  | grep -E '\[fem\]' | sed 's/\[fem\] //'

clean:
	rm -rf images README.md *.stl

clean-fem:
	rm -rf fem/work fem/__pycache__
