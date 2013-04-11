movi.f r8 0.0f
pushmatrix
loadidentity
vcompmovi v1 1 -1.5f
vcompmovi v1 2 0.0f
translate v1
vcompmov v0 0 r8
vcompmovi v0 1 0.0f
vcompmovi v0 2 0.0f
vcompmovi v0 3 1.0f
rotate v0
vcompmovi v2 0 255
vcompmovi v2 1 255
vcompmovi v2 2 255
setcolor v2
beginprimitive 3
vcompmovi v3 1 -1.0f
vcompmovi v3 2 1.0f
vcompmovi v3 3 0.0f
setvertex v3
vcompmovi v3 1 1.0f
vcompmovi v3 2 1.0f
vcompmovi v3 3 0.0f
setvertex v3
vcompmovi v3 1 0.0f
vcompmovi v3 2 -1.0f
vcompmovi v3 3 0.0f
setvertex v3		
endprimitive
addi.f r8 r8 20.0f	
popmatrix	
draw
