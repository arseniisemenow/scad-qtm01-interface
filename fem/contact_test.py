import sys, os, re
import FreeCAD as App, Part, ObjectsFem
from femmesh.gmshtools import GmshTools
from femtools import ccxtools
def log(*a): print("[fem]", *a); sys.stdout.flush()

SCAD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "qtm01.scad")
_t = open(SCAD).read()
def scad(n): return float(re.search(r"^\s*%s\s*=\s*([0-9.]+)\s*;" % n, _t, re.M).group(1))
bump_w=scad("bump_w"); bump_h=scad("bump_h"); tab_th=scad("tab_th")
tab_span=scad("tab_span"); cavity_d=scad("cavity_d")
INTERF = tab_span/2 - (cavity_d/2 - bump_h)
log("from scad: bump_w=%.2f bump_h=%.2f tab_th=%.2f INTERF=%.2f" % (bump_w,bump_h,tab_th,INTERF))
E=3500.0; NU=0.36; YIELD=55

doc = App.newDocument("contact")
base = Part.makeBox(8,8,2); base.translate(App.Vector(-4,-4,-2))
bump = Part.makeCylinder(bump_w/2, bump_h)
fobj = doc.addObject("Part::Feature","Female"); fobj.Shape = base.fuse(bump)
ear = Part.makeBox(8, tab_th, 4); ear.translate(App.Vector(-4, -tab_th/2, bump_h))
mobj = doc.addObject("Part::Feature","Ear"); mobj.Shape = ear
doc.recompute()

def faces_at(shape,key,val,tol=1e-3):
    r=[]
    for i,f in enumerate(shape.Faces):
        c=f.CenterOfMass; v={'x':c.x,'y':c.y,'z':c.z}[key]
        if abs(v-val)<tol: r.append((i+1,f.Area))
    return r
bump_top = min(faces_at(fobj.Shape,'z',bump_h), key=lambda t:t[1])[0]
base_bot = max(faces_at(fobj.Shape,'z',-2), key=lambda t:t[1])[0]
ear_bot  = faces_at(ear,'z',bump_h)[0][0]
ear_top  = faces_at(ear,'z',bump_h+4)[0][0]
log("faces: bump_top=%d base_bot=%d ear_bot=%d ear_top=%d"%(bump_top,base_bot,ear_bot,ear_top))

an = ObjectsFem.makeAnalysis(doc,"A")
sol = ObjectsFem.makeSolverCalculiXCcxTools(doc); sol.GeometricalNonlinearity="nonlinear"; an.addObject(sol)

matf=ObjectsFem.makeMaterialSolid(doc,"PLAf"); d=matf.Material
d["Name"]="PLAf"; d["YoungsModulus"]="3500 MPa"; d["PoissonRatio"]="0.36"; matf.Material=d
matf.References=[(fobj,"Solid1")]; an.addObject(matf)
matm=ObjectsFem.makeMaterialSolid(doc,"PLAm"); d=matm.Material
d["Name"]="PLAm"; d["YoungsModulus"]="3500 MPa"; d["PoissonRatio"]="0.36"; matm.Material=d
matm.References=[(mobj,"Solid1")]; an.addObject(matm)

fix=ObjectsFem.makeConstraintFixed(doc,"Fix"); fix.References=[(fobj,"Face%d"%base_bot)]; an.addObject(fix)
dsp=ObjectsFem.makeConstraintDisplacement(doc,"Push"); dsp.References=[(mobj,"Face%d"%ear_top)]
dsp.zFree=False; dsp.zDisplacement=-INTERF; an.addObject(dsp)
ct=ObjectsFem.makeConstraintContact(doc,"Contact")
ct.References=[(fobj,"Face%d"%bump_top),(mobj,"Face%d"%ear_bot)]; an.addObject(ct)
log("materials + constraints + contact set")

comp=doc.addObject("Part::Compound","Asm"); comp.Links=[fobj,mobj]; doc.recompute()
msh=ObjectsFem.makeMeshGmsh(doc,"Mesh"); msh.Shape=comp
try: msh.CharacteristicLengthMax=1.0
except: pass
GmshTools(msh).create_mesh(); an.addObject(msh); doc.recompute()
log("single mesh: %d nodes, %d elems"%(msh.FemMesh.NodeCount, msh.FemMesh.VolumeCount))

fea=ccxtools.FemToolsCcx(an,sol); fea.purge_results(); fea.update_objects()
fea.setup_working_dir("/home/arseni/Documents/3d/fem/work"); fea.setup_ccx()
log("prereq:", repr(fea.check_prerequisites()))
fea.run(); fea.load_results()
res=[o for o in doc.Objects if o.isDerivedFrom("Fem::FemResultObject")]
if res:
    r=res[0]
    log("==== CONTACT OK ===="); log("max von Mises: %.1f MPa (yield ~%d)"%(max(r.vonMises),YIELD))
    log("max displacement: %.3f mm"%max(r.DisplacementLengths))
else:
    log("NO RESULT — contact/convergence failed")
