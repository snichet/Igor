#pragma rtGlobals=1		// Use modern global access method.

/// From Wien2k menu : creates a window allowing to make a klist for a given list of points (see CreateKlistPath_Points)
//  Can be saved as text file (which should then be pasted in *.klist_band). Just typing SaveAsKlist in command window also works.
// WARNING : this file does not give a good spaghetti scale. Use XYZ_spaghetti instead.
// Can also define a loop (see CreateKlistPath_loop), typically for a Fermi Surface or as a function of Kz
// Not yet linked to window, but should be quite easy to do

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////// Klist procedures    ////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Macro CreateKlistPath_window()
	DoWindow/F KlistPanel
	if (v_flag==0)
		SetDataFolder "root:"
		variable/G a,b,c,Nb_path,Nb_loopGal
		string/G Filename,ContourType
		NewPanel /W=(20,50,530,250)
		DoWindow/C KlistPanel
		DoWindow/T KlistPanel "Create klist path"
		//PopupMenu popup_mode,pos={50,10},size={200,16},proc=Select_Mode,title="Mode : ",value="Points;Loop"
		
		//abc
		DrawText 10,20,"Unit cell :"
		SetVariable set_a,pos={10,30},size={90,16},proc=SetVarProcedure,title="a",value= root:a
		SetVariable set_b,pos={10,50},size={90,16},proc=SetVarProcedure,title="b",value=root:b
       	SetVariable set_c,pos={10,70},size={90,16},proc=SetVarProcedure,title="c",value= root:c
       	// 
       	PopupMenu popup_mode,pos={200,10},size={200,16},proc=Select_ContourType,title="Mode : ",value="Points;Loop"
       	Select_ContourType("",0,"Points")
       	SetVariable set_NbLoop,pos={200,50},size={200,16},proc=SetVarProcedure,title="Nb of loops ( loop mode)",value= root:Nb_loopGal
       	//
       	SetVariable set_Nb,pos={10,120},size={200,16},proc=SetVarProcedure,title="Nb of points in path : ",value= root:Nb_path
		Button CalculateButton,pos={290,115},size={160,25},proc=CreateKlistPath,title="Calculate "
		//
		SetVariable set_FileName,pos={10, 150},size={220,16},proc=SetVarProcedure,title="File to save klist : ",value=root:FileName
		Button SaveButton,pos={290,145},size={160,25},proc=SaveAsKlistButton,title="Save klist "
		//
		if (exists("a_rec")==0)
			Make/O/N=3 a_rec,b_rec,c_rec
			a_rec=0
			a_rec[0]=1
			b_rec=0
			b_rec[1]=1
			c_rec=0
			c_rec[2]=1
		endif
		//
		if (exists("X_pnts")==0)
			Make/O/N=10 X_pnts,Y_pnts,Z_pnts,XYZ_distance,XYZ_spaghetti
		endif
				
	endif	
	
	// Edit tables for unit cell and XYZ points of path
	
	// Unit cell useful only for primitive cell. Use default values instead.
	//DoWindow/F UnitCell
	//if (v_flag==0)
	//		Edit/W=(450,50,800,150) a_rec,b_rec,c_rec
	//		DoWindow/C UnitCell
	//		DoWindow/T UnitCell "Unit cell"
	//endif	
	//
	DoWindow/F XYZcontour
	if (v_flag==0)
			Edit/W=(450,50,1000,450) X_pnts,Y_pnts,Z_pnts,XYZ_distance,XYZ_spaghetti	
			DoWindow/C XYZcontour
			DoWindow/T XYZcontour "XYZ contour"
		endif	
end

Function SetVarProcedure(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	//varName
	
End

Proc Select_ContourType(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
  
  SetDataFolder "root:"
  string/G ContourType
   ContourType=popstr
end

function CreateKlistPath(ctrlname):ButtonControl
string ctrlname
SetDataFolder "root:"
String/G ContourType
   if (cmpstr(ContourType,"Points")==0)
	CreateKlistPath_Points()
   endif	
   if (cmpstr(ContourType,"Loop")==0)
	CreateKlistPath_Loop()
   endif		
end

////////////////////////////////

function CreateKlistPath_Points()
// Called by menu
// (X,Y,Z) coordinates of points in the wanted contour must be in X_pnts, Y_pnts, Z_pnts waves
// in units of reciprocal vectors of the conventional cell a*=2pi/a etc... (!!! not the primitive one)
// Coordinate of reciprocal vectors must be in a_rec,b_rec,c_rec   

// Creates a wave XYZ_distance with distance from one point to the next. Useful to check it's the correct path !
// Check all coordinates are integer values before saving !!

SetDataFolder "root:"
nvar a,b,c,Nb_path
wave X_pnts,Y_pnts,Z_pnts,XYZ_distance,XYZ_spaghetti
wave a_rec,b_rec,c_rec  // Useful for primitive unit cell. Not that much here but keep as it is with default values (1 0 0) (0 1 0) (0 0 1)

XYZ_distance=0
variable i=1
do
XYZ_distance[i]=((X_pnts[i]-X_pnts[i-1])*a_rec[0]+(Y_pnts[i]-Y_pnts[i-1])*b_rec[0]+(Z_pnts[i]-Z_pnts[i-1])*c_rec[0])^2*(2*pi/a)^2
XYZ_distance[i]+=((X_pnts[i]-X_pnts[i-1])*a_rec[1]+(Y_pnts[i]-Y_pnts[i-1])*b_rec[1]+(Z_pnts[i]-Z_pnts[i-1])*c_rec[1])^2*(2*pi/b)^2
XYZ_distance[i]+=((X_pnts[i]-X_pnts[i-1])*a_rec[2]+(Y_pnts[i]-Y_pnts[i-1])*b_rec[2]+(Z_pnts[i]-Z_pnts[i-1])*c_rec[2])^2*(2*pi/c)^2
XYZ_distance[i]=sqrt(XYZ_distance[i])
i+=1
while (i<dimsize(XYZ_distance,0))
XYZ_spaghetti[]=XYZ_distance[p]+XYZ_spaghetti[p-1]

WaveStats/Q/R=[1,DimSize(XYZ_distance,0)-1] XYZ_distance
variable distance_totale=V_sum

Make/O/N=(Nb_path) klist_x,klist_y,klist_z,klist_m  
variable Nb_segment,p_start,p_stop
variable step_x,step_y,step_z,m
p_start=0
p_stop=-1
i=1
do
Nb_segment=trunc(XYZ_distance[i]/distance_totale*Nb_path)   

// Find m
step_x=(X_pnts[i]-X_pnts[i-1])/Nb_segment
step_y=(Y_pnts[i]-Y_pnts[i-1])/Nb_segment
step_z=(Z_pnts[i]-Z_pnts[i-1])/Nb_segment
m=1
if (abs(step_x)>0)	      /// exclude case where there is no variation in this direction 
	m=1/abs(step_x)
endif	
if (abs(step_y)>0)	       
	m=PPCM(max(m,1/abs(step_y)) ,m)
endif
if (abs(step_z)>0)	       
	m=PPCM(max(m,1/abs(step_z)),m )
endif
// Sometimes the previous coordinates are not integer anymore
// Change m to get integer again (assumes multiple of 2 will do it -- is that sure ?)
//print X_pnts[i-1]*m
variable eps=0.05
if ((abs(X_pnts[i-1]*m)-floor(abs(X_pnts[i-1]*m)))>eps)
	do
		m*=2
	while (abs(X_pnts[i-1]*m)-floor(abs(X_pnts[i-1]*m))>eps)	
endif
if ((abs(Y_pnts[i-1]*m)-trunc(abs(Y_pnts[i-1]*m)))>eps)
	do
		m*=2
	while (abs(Y_pnts[i-1]*m)-trunc(abs(Y_pnts[i-1]*m))>eps)	
endif
if ((abs(Z_pnts[i-1]*m)-trunc(abs(Z_pnts[i-1]*m)))>eps)
	do
		print Z_pnts[i-1],m,abs(Z_pnts[i-1]*m),trunc(abs(Z_pnts[i-1]*m)),(abs(Z_pnts[i-1]*m)-trunc(abs(Z_pnts[i-1]*m)))
		m*=2
	while (abs(Z_pnts[i-1]*m)-trunc(abs(Z_pnts[i-1]*m))>eps)	
endif
print "p_start,Nb_segment,1/step_x,1/step_y,1/step_z,m",p_start,Nb_segment,1/step_x,1/step_y,1/step_z,m
//

p_start=p_stop+1
p_stop=p_start+Nb_segment-1
print "i,p_start,p_stop,Nb_segment",i,p_start,p_stop,Nb_segment

klist_m[p_start,p_stop]=m
klist_x[p_start,p_stop]=(X_pnts[i-1]+(X_pnts[i]-X_pnts[i-1])/Nb_segment*(p-p_start))*m
klist_y[p_start,p_stop]=(Y_pnts[i-1]+(Y_pnts[i]-Y_pnts[i-1])/Nb_segment*(p-p_start))*m
klist_z[p_start,p_stop]=(Z_pnts[i-1]+(Z_pnts[i]-Z_pnts[i-1])/Nb_segment*(p-p_start))*m
i+=1
while (i<dimsize(X_pnts,0))

Redimension/N=(p_stop+2) klist_x,klist_y,klist_z,klist_m   // might be a little different due to rounding

//last point
klist_m[p_stop+1]=m
klist_x[p_stop+1]=(X_pnts[i-1]+(X_pnts[i]-X_pnts[i-1])/Nb_segment*(p-p_start))*m
klist_y[p_stop+1]=(Y_pnts[i-1]+(Y_pnts[i]-Y_pnts[i-1])/Nb_segment*(p-p_start))*m
klist_z[p_stop+1]=(Z_pnts[i-1]+(Z_pnts[i]-Z_pnts[i-1])/Nb_segment*(p-p_start))*m



DoWindow/F Klist
if (v_flag==0)
	Edit/W=(50,200,500,500) klist_x,klist_y,klist_z,klist_m
	DoWindow/C Klist
	DoWindow/T Klist "Klist"
endif

end

/////////////////////

Function CreateKlistPath_Loop()

// For one primary path repeated N times at different values
//Enter start and stop points of primary path in first 2 rows of X_pnts,Y_pnts,Z_pnts
// After a blank line, enter start and stop points of  loops
wave X_pnts,Y_pnts,Z_pnts
nvar Nb_path,Nb_loopGal

// Primary path from (start_x,start_y,start_z) to (stop_x,stop_y,stop_z) 
// Coordinate in units of a*=2pi/a etc...
variable start_X,start_Y,start_Z
variable stop_X,stop_Y,stop_Z
variable step_x,step_y,step_z
variable Nb,m   // m is Wien2k multiplier thing to get integer numbers
start_X=X_pnts[0]
start_Y=Y_pnts[0]
start_Z=Z_pnts[0]

stop_X=X_pnts[1]
stop_Y=Y_pnts[1]
stop_Z=Z_pnts[1]

Nb=Nb_path // Nb of points wanted along the path (1 is added to start from zero)

// Then loop in one direction
variable Loop_start_X,Loop_start_Y,Loop_start_Z,Loop_stop_X,Loop_stop_Y,Loop_stop_Z
variable Loop_step_x,Loop_step_y,Loop_step_z,Nb_loop

Loop_start_X=X_pnts[3]
Loop_start_Y=Y_pnts[3]
Loop_start_Z=Z_pnts[3]

Loop_stop_X=X_pnts[4]
Loop_stop_Y=Y_pnts[4]
Loop_stop_Z=Z_pnts[4]

Nb_loop=Nb_loopGal

////
step_x=(stop_x-start_x)/Nb
if (abs(step_x)>0)	       
	m=1/abs(step_x)
endif	
step_y=(stop_y-start_y)/Nb
if (abs(step_y)>0)	       
	m=PPCM(max(m,1/abs(step_y)) ,m)
endif
step_z=(stop_z-start_z)/Nb
if (abs(step_z)>0)	       
	m=PPCM(max(m,1/abs(step_z)),m )
endif

loop_step_x=(loop_stop_x-loop_start_x)/Nb_loop
if (abs(loop_step_x)>0)	       
	m=PPCM(max(m,1/abs(loop_step_x)),m )
endif
loop_step_y=(loop_stop_y-loop_start_y)/Nb_loop
if (abs(loop_step_y)>0)	       
	m=PPCM(max(m,1/abs(loop_step_y)),m )
endif
loop_step_z=(loop_stop_z-loop_start_z)/Nb_loop
if (abs(loop_step_z)>0)	       
	m=PPCM(max(m,1/abs(loop_step_z)) ,m)
endif

// To avoid problem below could, I could take m as the smallest multiple of both, but I don't think it will be evry useful
if (step_x*m>trunc(step_x*m))
	
	print "incompatible nb of points !!"
endif
if (step_y*m>trunc(step_y*m))
	print "incompatible nb of points !!"
endif
if (step_z*m>trunc(step_z*m))
	print "incompatible nb of points !!"
endif
if (loop_step_x*m>trunc(loop_step_x*m))
	print "incompatible nb of points !!"
endif
if (loop_step_y*m>trunc(loop_step_y*m))
	print "incompatible nb of points !!"
endif
if (loop_step_z*m>trunc(loop_step_z*m))
	print "incompatible nb of points !!"
endif

////////
Nb+=1
Nb_loop+=1
print Nb*Nb_loop,"points"

//// create klist waves

Make/O/N=(Nb*Nb_loop) klist_x,klist_y,klist_z,klist_m

variable indice_loop=0

	do
		klist_x[indice_loop*Nb,indice_loop*Nb+Nb-1]=start_x+ step_x*(p-indice_loop*Nb)+loop_step_x*indice_loop
		klist_y[indice_loop*Nb,indice_loop*Nb+Nb-1]=start_y+ step_y*(p-indice_loop*Nb)+loop_step_y*indice_loop
		klist_z[indice_loop*Nb,indice_loop*Nb+Nb-1]=start_z+ step_z*(p-indice_loop*Nb)+loop_step_z*indice_loop
		indice_loop+=1
	while (indice_loop<Nb_Loop)

klist_x=round(klist_x[p]*m)
klist_y=round(klist_y[p]*m)
klist_z=round(klist_z[p]*m)
klist_m=m  // consider only one path : the density of points is always the same along it

DoWindow/F Klist
if (v_flag==0)
	Edit/W=(50,200,500,500) klist_x,klist_y,klist_z,klist_m
	DoWindow/C Klist
	DoWindow/T Klist "Klist"
endif

end

////////////////////////////////////////////////////////////////


function PPCM(a,b)
variable a,b
// return the smallest common multipler of a and b
	 return a*b/gcd(a,b)
end

////

Function RewriteKlist()
// Rewrite klist in another coordinate system
wave klist_x,klist_y,klist_z   // Need to be called this way to be transformed in this units by make 2D maps

Duplicate/O klist_x Wien2k_klist_x
Duplicate/O klist_y Wien2k_klist_y
Duplicate/O klist_z Wien2k_klist_z

variable choix=2
variable a,b,c,angle
if (choix==1)
	// CuV2S4 primitive unit cell  
	a=12.756
	b=5.834
	c=3.2933
	angle=26.06*pi/180
	variable NewA_x=2*pi/a/cos(angle)
	variable NewA_y=2*pi*tan(angle)/b
	variable NewA_z=2*pi/a/cos(angle)

	variable NewB_x=0
	variable NewB_y=2*pi/b
	variable NewB_z=0

	variable NewC_x=-2*pi/c
	variable NewC_y=0
	variable NewC_z=2*pi/c
endif

if (choix==2)
	// Hexagonal BZ
	//a=2.82
	//a=3.38
	a=3.93 //IrTe2
	NewA_x=4*pi/sqrt(3)/a
	NewA_y=2*pi/sqrt(3)/a
	NewA_z=0

	NewB_x=0
	NewB_y=2*pi/a
	NewB_z=0

	NewC_x=0
	NewC_y=0
	NewC_z=1
endif	


klist_x=NewA_x*Wien2k_klist_x+NewA_y*Wien2k_klist_y+NewA_z*Wien2k_klist_z
klist_y=NewB_x*Wien2k_klist_x+NewB_y*Wien2k_klist_y+NewB_z*Wien2k_klist_z
klist_z=NewC_x*Wien2k_klist_x+NewC_y*Wien2k_klist_y+NewC_z*Wien2k_klist_z
end

////
Function ReturnToOriginalKlist()
wave Wien2K_klist_x,Wien2K_klist_y,Wien2K_klist_z   // Need to be called this way to be transformed in this units by make 2D maps

Duplicate/O  Wien2k_klist_x klist_x
Duplicate/O  Wien2k_klist_y klist_y
Duplicate/O  Wien2k_klist_z klist_z
end

/////////////////////////////////////////////////////////////////////////////////////
Function SaveAsKlistButton(ctrlname):ButtonControl
string ctrlname
SetDataFolder "root:"
string/G filename
SaveAsKlist(filename)
end

Function SaveAsKlist(filename)
string filename

wave klist_x,klist_y,klist_z,klist_m
//string pathname,filename
variable refnum

//pathname="Aout2011"
//filename="klist_try2"
//Open/C="IGRO" /P=$pathname refnum filename
Open refnum filename
string line,kx,ky,kz,m
variable i=0
//First line
	kx=num2str(klist_x[i])
	kx=CompleteWithBlank(kx)
	ky=num2str(klist_y[i])
	ky=CompleteWithBlank(ky)
	kz=num2str(klist_z[i])
	kz=CompleteWithBlank(kz)
	m=num2str(klist_m[i])
	m=CompleteWithBlank(m)
	line="G         "+kx+ky+kz+m+"  2.0-8.00 8.00\n"
	fprintf refnum, line
	//print line
i=1
do
	kx=num2str(klist_x[i])
	kx=CompleteWithBlank(kx)
	ky=num2str(klist_y[i])
	ky=CompleteWithBlank(ky)
	kz=num2str(klist_z[i])
	kz=CompleteWithBlank(kz)
	m=num2str(klist_m[i])
	m=CompleteWithBlank(m)
	line="          "+kx+ky+kz+m+"  2.0\n"
	fprintf refnum, line
	//print line
	i+=1
while (i<DimSize(klist_x,0))

line="END\n"
fprintf refnum, line	
//print line
close refnum
end

////
Function/S CompleteWithBlank(s)
string s
do
	s=" "+s
while (strlen(s)<5)
//print s
return s
end

//////////////////////   End klist procedures ///////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
