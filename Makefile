# Regenerate README.md, renders (PNG/STL) and assembly GIFs from the .scad.
# All docs are derived from the .scad file by build_docs.py.

.PHONY: docs clean

docs:
	python3 build_docs.py

clean:
	rm -rf images README.md *.stl
