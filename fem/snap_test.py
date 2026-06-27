import sys, os, re
import FreeCAD as App
import Part, ObjectsFem
from femmesh.gmshtools import GmshTools
from femtools import ccxtools

def log(*a): print("[fem]", *a); sys.stdout.flush()

# ---- read geometry straight from qtm01.scad (single source of truth) ----
SCAD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "qtm01.scad")
_txt = open(SCAD).read()
def scad(name):
    m = re.search(r"^\s*%s\s*=\s*([0-9.]+)\s*;" % re.escape(name), _txt, re.M)
    if not m: raise RuntimeError("param '%s' not found in qtm01.scad" % name)
    return float(m.group(1))

tab_w    = scad("tab_w")
tab_th   = scad("tab_th")
tab_span = scad("tab_span")
post_d   = scad("post_d")
cavity_d = scad("cavity_d")
bump_h   = scad("bump_h")

# ear (simplified as a block) + the detent interference, derived from the scad
W = tab_w                                   # ear width
T = tab_th                                  # ear thickness
L = (tab_span - post_d) / 2                 # ear radial protrusion (tip - post)
INTERF = tab_span/2 - (cavity_d/2 - bump_h) # ear tip vs female bump reach
log("from qtm01.scad -> W=%.2f  T=%.2f  L=%.2f  INTERF=%.2f mm" % (W, T, L, INTERF))

# ---- material (analysis choice, not in the .scad) ----
E_MPa = 3500  # PLA Young's modulus
NU    = 0.36
YIELD = 55    # PLA approx yield (MPa) for interpretation

doc = App.newDocument("snap")
box = Part.makeBox(L, W, T)
obj = doc.addObject("Part::Feature", "Ear"); obj.Shape = box
doc.recompute()
log("geometry OK, faces:", len(box.Faces))

def face_named_at_x(xval, tol=1e-4):
    for i, f in enumerate(box.Faces):
        if abs(f.CenterOfMass.x - xval) < tol:
            return "Face%d" % (i+1)
    return None
root = face_named_at_x(0.0); tip = face_named_at_x(L)
log("root face:", root, " tip face:", tip)

an = ObjectsFem.makeAnalysis(doc, "A")
solver = ObjectsFem.makeSolverCalculiXCcxTools(doc); an.addObject(solver)

mat = ObjectsFem.makeMaterialSolid(doc, "PLA"); md = mat.Material
md["Name"]="PLA"; md["YoungsModulus"]="%d MPa"%E_MPa; md["PoissonRatio"]="%g"%NU; md["Density"]="1240 kg/m^3"
mat.Material = md; an.addObject(mat)
log("material set")

fix = ObjectsFem.makeConstraintFixed(doc, "Fixed"); fix.References=[(obj, root)]; an.addObject(fix)
disp = ObjectsFem.makeConstraintDisplacement(doc, "Disp"); disp.References=[(obj, tip)]
disp.xFree=False; disp.xDisplacement=-INTERF; an.addObject(disp)
log("constraints set")

mesh = ObjectsFem.makeMeshGmsh(doc, "Mesh"); mesh.Shape=obj
try: mesh.CharacteristicLengthMax = 0.4
except Exception as e: log("mesh param warn:", e)
gm = GmshTools(mesh); err = gm.create_mesh()
log("mesh:", mesh.FemMesh.NodeCount, "nodes,", mesh.FemMesh.VolumeCount, "elems")
an.addObject(mesh)
doc.recompute()

fea = ccxtools.FemToolsCcx(an, solver)
fea.purge_results(); fea.update_objects()
fea.setup_working_dir("/home/arseni/Documents/3d/fem/work")
fea.setup_ccx()
ok = fea.check_prerequisites()
log("prereq:", repr(ok))
fea.run()
fea.load_results()

res = [o for o in doc.Objects if o.isDerivedFrom("Fem::FemResultObject")]
if not res:
    log("NO RESULT OBJECT"); sys.exit()
r = res[0]
vm = list(r.vonMises); dl = list(r.DisplacementLengths)
log("==== RESULTS ====")
log("max von Mises stress: %.1f MPa  (PLA yield ~%d MPa)" % (max(vm), YIELD))
log("max displacement:     %.3f mm" % max(dl))
# reaction force = the snap/insertion force
fmag = None
try:
    nf = r.NodeForces
    if nf:
        tot = App.Vector(0,0,0)
        for v in nf.values(): tot = tot + App.Vector(v[0],v[1],v[2]) if not hasattr(v,"x") else tot + v
        fmag = tot.Length
        log("reaction force (N): |F|=%.0f  Fx=%.0f" % (tot.Length, tot.x))
except Exception as e:
    log("NodeForces n/a:", e)
if fmag is None:
    # estimate: axial stress over the ear cross-section
    area = W*T
    log("reaction force estimate (N): ~%.0f  (= sigma_axial * area)" % (E_MPa*(INTERF/L)*area))
log("verdict:", "ELASTIC (ok)" if max(vm) < YIELD else "EXCEEDS YIELD -> not an elastic snap (rigid press / yields)")
log("over-yield factor: %.0fx" % (max(vm)/YIELD))
