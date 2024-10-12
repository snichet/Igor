#pragma rtGlobals=1		// Use modern global access method.

// Heart of the conversion procedure :  Calculate_NewBase(Rtheta,Rtilt,Rphi,Rsample_tilt,Rphi_tilt) 
	//Scienta slits are taken along kx
	// Hence :     rotation around kx = theta angle
	//			rotation around ky = tilt
	// 			rotation around kz = azimuthal angle 
	// NB : the last 2 rotation are linked to the sample axis (=they move with theta).
	// Sample-tlt can be added. phi-tilt is the direction of the tilt rotation axis with respect to kx
	// In this case, phi is still a rotation in the plane of the sample (i.e. tilted with respect to kz)

// It is used for various conversions proposed in ARPES_menu
//     "Convert one point [theta,tilt,phi] ",Transform_point()  
//	"Convert one list of points [theta,tilt,phi]",Transform_List()
//	"Convert one dispersion ",Transform_disp()
//	"Convert one image ",Ask_Transform_image_true()

// It is used to do true conversion for Fermi Surface (called from Theta window)
//              Correct_FermiSurface(FSimage,phi_cur,delta)



// At end : BZ  cuts is meant to visualize the slits in reciprocal space.
// Available from menu : draw cuts


//The one from ARPES menu : Img_conv
//Les offsets sont par convention ceux de la Fermi map
//correction_phi est pour centrer l'image a phi=0
//Proc ThetaPhi : Conversion d'un couple (kx,ky) en (theta, phi)
//Proc KxKy : Conversion d'un couple (theta,phi) en (kx,ky)
//Proc cut : Conversion des valeurs extremes (a regler par phi_min, phi_max) d'une image (theta,phi) en (kx,ky)
//			(les stocke dans une wave pour plotter sur graphe BZ)
// Proc Mise_en_forme : Conversion de deux waves theta et phi en wave Kx et Ky
//Proc Img_conv : rescale an image with angle x scale as k scale (not correct, rectangular)

//Menu "Conversions"
//	"-"
//	"1 point (kx,ky)->(phi,theta)",Thetaphi(kx,ky,angle)
//	"1 point (phi,theta)->(kx,ky)", kxky(phi,theta,angle)
//	"1 file  (phi,theta)->(kx,ky)",mise_en_forme(w_phi,w_theta,angle)
//	"Map (phi,theta)->(kx,ky) (with large angle correction)",correct_conversion()
//	"Draw one cut",cut(phi0,theta,energy,cut)
//End


Function Calculate_NewBase(Rtheta,Rtilt,Rphi,Rsample_tilt,Rphi_tilt)
variable Rtheta,Rtilt,Rphi,Rsample_tilt,Rphi_tilt    // angles in radian

make/O Base={ {1,0,0} , {0,1,0} , {0,0,1} }  // NB : { {colonne 1} , {colonne 2} , {colonne 3} }


//Rotate by sample_tilt around axis of rotation [ which is in the (kx,ky) plane and rotated by phi_tilt from phi ]
	//First align kx with axis of rotation by rotating by phi_tilt around kz
	make/O Rot={  {cos(Rphi_tilt),sin(Rphi_tilt),0}  ,  {-sin(Rphi_tilt),cos(Rphi_tilt),0}  ,  {0,0,1}  }
	MatrixMultiply Rot,Base
	wave M_product
	Base=M_product
	//Check_repere()
	
	// Then rotate by sample_tilt around kx
	make/O Rot={  {1,0,0}  ,  {0,cos(Rsample_tilt),sin(Rsample_tilt)}  ,  {0,-sin(Rsample_tilt),cos(Rsample_tilt)}  }
	MatrixMultiply Rot,Base
	Base=M_product
	//Check_repere()
	
	//Rotate back to original position (i.e. keep kx aligned with Scienta slits)
	make/O Rot={  {cos(Rphi_tilt),-sin(Rphi_tilt),0}  ,  {sin(Rphi_tilt),cos(Rphi_tilt),0}  ,  {0,0,1}  }
	MatrixMultiply Rot,Base
	Base=M_product
	//Check_repere()

//Rotation by phi around kz = phi is in the plane of the sample (which might be tilted)
	make/O Rot={  {cos(Rphi),-sin(Rphi),0}  ,  {sin(Rphi),cos(Rphi),0}  ,  {0,0,1}  }
	MatrixMultiply Rot,Base
	//wave M_product
	Base=M_product
	//Check_repere()
	
//Rotation by tilt around ky
make/O Rot={  {cos(Rtilt),0,sin(Rtilt)}  ,  {0,1,0}  ,  {-sin(Rtilt),0,cos(Rtilt)}  }
MatrixMultiply Rot,Base
Base=M_product
//Check_repere()

//Rotation by theta around kx 
make/O Rot={  {1,0,0}  ,  {0,cos(Rtheta),sin(Rtheta)}  ,  {0,-sin(Rtheta),cos(Rtheta)}  }
MatrixMultiply Rot,Base
Base=M_product
//execute "Check_repere()"

//print "Normale à l'échantillon :", Base[0][2],Base[1][2],Base[2][2] 

end

Macro check_repere()
	print "ex : ", Base[0][0],Base[1][0],Base[2][0]
	print "ey : ", Base[0][1],Base[1][1],Base[2][1]
	print "ez : ", Base[0][2],Base[1][2],Base[2][2]
	print "ex.ey, ex.ez, ey.ez = ", Base[0][0]*Base[0][1]+Base[1][0]*Base[1][1]+Base[2][0]*Base[2][1] , Base[0][0]*Base[0][2]+Base[1][0]*Base[1][2]+Base[2][0]*Base[2][2] , Base[0][1]*Base[0][2]+Base[1][1]*Base[1][2]+Base[2][1]*Base[2][2]
	print "ex.ex,ey.ey,ez.ez =", Base[0][0]*Base[0][0]+Base[1][0]*Base[1][0]+Base[2][0]*Base[2][0] , Base[0][1]*Base[0][1]+Base[1][1]*Base[1][1]+Base[2][1]*Base[2][1] , Base[0][2]*Base[0][2]+Base[1][2]*Base[1][2]+Base[2][2]*Base[2][2]
	print " "
end

//////////////////
function Calculate_kx(scienta,base)
variable scienta  // position on slits, angle in degree
wave base  // must have been calculated by CalculateNewBase
nvar photon, lattice
	return 0.512 * sqrt (photon) * ( sin(scienta*pi/180) * Base[0][0] + cos(scienta*pi/180) * Base[2][0] )/ (pi/lattice)
end
/////////////////
function Calculate_ky(scienta,base)
variable scienta  // position on slits, angle in degree
wave base  // must have been calculated by CalculateNewBase
nvar photon, lattice
	return 0.512 * sqrt (photon) * ( sin(scienta*pi/180) * Base[0][1] + cos(scienta*pi/180) * Base[2][1] )/ (pi/lattice)
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////-------------------------- ThetaPhi_conversions

Function Transform_point()
variable kx,ky
//Gives kx and ky corresponding to these angle value and tilt of sample from BZcutswindow

string curr=GetDataFolder(1)
SetDataFolder root:

nvar sample_tilt,phi_tilt,photon,lattice

variable Rsample_tilt=sample_tilt*pi/180
variable Rphi_tilt=phi_tilt*pi/180

variable theta=0,tilt=0,phi=0
prompt theta, "Theta"
prompt tilt, "Tilt"
prompt phi, "Phi"
variable photon2=photon
prompt photon2, "Photon energy (eV)"
DoPrompt "Convert..." theta,tilt,phi,photon2
photon=photon2

	make/O Base={ {1,0,0} , {0,1,0} , {0,0,1} }  // NB : { {colonne 1} , {colonne 2} , {colonne 3} }
	Calculate_NewBase(Theta*pi/180,Tilt*pi/180,Phi*pi/180,Rsample_tilt,Rphi_tilt)
	kx = 0.512 * sqrt (photon) * Base[2][0] / (pi/lattice)
	ky = 0.512 * sqrt (photon) * Base[2][1] / (pi/lattice)
	
	print "kx,ky=",kx,ky

SetDataFolder curr

end

Function Transform_point_kx(theta,tilt,phi,energy)
variable theta,tilt,phi,energy
//Returns kx corresponding to these angle value and tilt of sample from current floder

nvar sample_tilt,phi_tilt,lattice

variable Rsample_tilt=sample_tilt*pi/180
variable Rphi_tilt=phi_tilt*pi/180
variable kx
	make/O Base={ {1,0,0} , {0,1,0} , {0,0,1} }  // NB : { {colonne 1} , {colonne 2} , {colonne 3} }
	Calculate_NewBase(Theta*pi/180,Tilt*pi/180,Phi*pi/180,Rsample_tilt,Rphi_tilt)
	kx = 0.512 * sqrt (energy) * Base[2][0] / (pi/lattice)

Return kx

end

Function Transform_point_ky(theta,tilt,phi,energy)
variable theta,tilt,phi,energy
//Returns kx corresponding to these angle value and tilt of sample from current floder

nvar sample_tilt,phi_tilt,lattice

variable Rsample_tilt=sample_tilt*pi/180
variable Rphi_tilt=phi_tilt*pi/180
variable ky
	make/O Base={ {1,0,0} , {0,1,0} , {0,0,1} }  // NB : { {colonne 1} , {colonne 2} , {colonne 3} }
	Calculate_NewBase(Theta*pi/180,Tilt*pi/180,Phi*pi/180,Rsample_tilt,Rphi_tilt)
	ky = 0.512 * sqrt (energy) * Base[2][1] / (pi/lattice)

Return ky

end

//////////////////////////////////

Function Transform_List()
// Output : kx_suffixe, ky_suffixe

string curr=GetDataFolder(1)

string suffixeL,ThetaNameL,TiltNameL,PhiNameL
string/G suffixe,ThetaName,TiltName,PhiName
suffixeL=suffixe
ThetaNameL=ThetaName
TiltNameL=TiltName
PhiNameL=PhiName

string choix
choix=WaveList("*",";","DIMS:1")
prompt ThetaNameL,"Wave for theta ", popup,choix
prompt TiltNameL,"Wave for tilt ", popup,choix
choix="Create a wave;"+WaveList("*",";","DIMS:1")
prompt PhiNameL,"Wave for phi ", popup,choix
prompt suffixeL,"Suffixe (to save results) "
DoPrompt "Convert..." ThetaNameL,TiltNameL,PhiNameL,suffixeL

suffixe=suffixeL
ThetaName=ThetaNameL
TiltName=TiltNameL
PhiName=PhiNameL

if (cmpstr(PhiName,"Create a wave")==0)
	variable phi
	prompt phi,"Constant value for phi"
	DoPrompt "Create Phi wave" phi
	PhiName="PhiWave"
	Duplicate/O $ThetaName bidon
	bidon=phi
	Duplicate/O bidon  $PhiName
	Killwaves bidon
endif

//Take parameters from current folder 
string namekx,nameky,name
nvar offset_slits,offset_theta,photon,lattice
variable offset_phi
offset_phi=0 

if (v_flag==0) // not cancelled
	 if (waveexists($ThetaName)==0)
       		 	abort "There is no such theta list"
    	endif	 
    	 if (waveexists($TiltName)==0)
       		 	abort "There is no such tilt list"
    	endif  
    	 if (waveexists($PhiName)==0)
       		 	abort "There is no such phi list"
    	endif
       Execute_Transform_List($ThetaName,$TiltName,$PhiName)
	namekx=suffixe+"_kx"
	Duplicate/O list_kx $namekx
	nameky=suffixe+"_ky"
	Duplicate/O list_ky $nameky
	Killwaves list_kx,list_ky
	//Plot results in FS if exists
	string path
	path=GetDataFolder(1)
	name="FS_k_"+path[5,strlen(path)-2]
 	DoWindow/F $name
      if (v_flag>0) //i.e FS window exist s
      		AppendToGraph $nameky vs $namekx
      		ModifyGraph mode($nameky)=3,marker($nameky)=19
      endif
endif
end



Function Execute_Transform_List( ThetaName,TiltName,PhiName)
wave ThetaName,TiltName,PhiName
//variable offset_theta,offset_tilt,offset_phi
//ThetaName,TiltName,PhiName are the names of waves containing theta, tilt and phi values for a list of points
//The macro calculates kx and ky (using sample_tilt and phi_tilt from the current folder)
//Stores them in waves List_kx, List_ky (temporary waves)

string curr=GetDataFolder(1)
//SetDataFolder root:
Duplicate/O ThetaName list_kx,list_ky
nvar sample_tilt,phi_tilt,photon,lattice
//print "     offset_theta, offset_tilt, offset_phi = ",offset_theta,",", offset_tilt,",",offset_phi
print "     photon, lattice = ",photon,",",lattice
print "     sample_tilt, phi_tilt = ",sample_tilt,",",phi_tilt
variable Rsample_tilt=sample_tilt*pi/180
variable Rphi_tilt=phi_tilt*pi/180
variable i=0
variable Nb=Dimsize(ThetaName,0)
do
	make/O Base={ {1,0,0} , {0,1,0} , {0,0,1} }  // NB : { {colonne 1} , {colonne 2} , {colonne 3} }
	//Calculate_NewBase((ThetaName[i]-offset_theta)*pi/180,(TiltName[i]-offset_tilt)*pi/180,(PhiName[i]-offset_phi)*pi/180,Rsample_tilt,Rphi_tilt)
	Calculate_NewBase((ThetaName[i])*pi/180,(TiltName[i])*pi/180,(PhiName[i])*pi/180,Rsample_tilt,Rphi_tilt)
	list_kx[i] = 0.512 * sqrt (photon) * Base[2][0] / (pi/lattice)
	list_ky[i] = 0.512 * sqrt (photon) * Base[2][1] / (pi/lattice)
	i+=1
while (i<Nb)
//SetDataFolder curr
end

///////////////////////////////////////

Function Transform_Disp()
// uses : a wave containing dispersion (either angle vs energy / energy vs angle or 2 waves)
// 		theta and phi, the angles for measuring this disp (corrected by offsets, if necessary).
// (we assume that the disp comes from one window, i.e. there is one set of angles for the Scienta per disp)

// Angle is taken as Tilt+Scienta    (Tilt should be the center of the scienta window)
// Orientation of the sample is taken from BZcuts window

//Output : Disp_E, Disp_K, Disp_KvsE, Disp_EvsK 
//			K is the wave vector in the direction of the slit with respect to the crossing with Ky axis
//			Prints in command window the angle of the measured slit with respect to Ky

//Warning : All k are calculated at Ef (not Ef-BE as it should)


string Disp_Angle,Disp_Energy,choix
choix="none;"+WaveList("*",";","DIMS:1")
prompt Disp_Angle,"Wave of position (degree) ", popup,choix
prompt Disp_Energy,"Wave of energy (eV) ", popup,choix
variable p_min,p_max,nb
p_min=0
p_max=dimsize(QPpos,0)-1
prompt p_min,"From index p= "
prompt p_max,"To index p= "
variable theta=0,tilt=0,phi=0
prompt theta, "Theta"
prompt tilt, "Tilt"
prompt phi, "Phi"
choix="E vs k (1 wave); k vs E (1 wave); E vs k (2 waves); k vs E (2 waves)"  
string PlotType="E vs k (1 wave)"
prompt PlotType, "Plot", popup,choix
string name="disp"
prompt name, "Name for output wave(s)"
DoPrompt "Convert..." Disp_Angle,Disp_Energy,p_min,p_max,theta,tilt,phi,PlotType,name
nb=p_max-p_min+1

if (v_flag==0)
nvar sample_tilt=root:sample_tilt,phi_tilt=root:sample_tilt,photon=root:photon,lattice=root:lattice
variable Rsample_tilt=sample_tilt*pi/180
variable Rphi_tilt=phi_tilt*pi/180
variable win=14*pi/180

variable indice,kx_start,kx_stop,ky_start,ky_stop,ky0,kx,ky
variable Rangle_slit,Rangle

	make/O Base={ {1,0,0} , {0,1,0} , {0,0,1} }  // NB : { {colonne 1} , {colonne 2} , {colonne 3} }
	Calculate_NewBase(theta*pi/180,Tilt*pi/180,Phi*pi/180,Rsample_tilt,Rphi_tilt)
	//Calculate the direction of cut (neglects the curvature)
	kx_start= 0.512 * sqrt (photon) * ( sin(-win/4) * Base[0][0] + cos(-win/4) * Base[2][0] )/ (pi/lattice)
	ky_start = 0.512 * sqrt (photon) * ( sin(-win/4) * Base[0][1] + cos(-win/4) * Base[2][1] )/ (pi/lattice)
	kx_stop= 0.512 * sqrt (photon) * ( sin(win/4) * Base[0][0] + cos(win/4) * Base[2][0] )/ (pi/lattice)
	ky_stop = 0.512 * sqrt (photon) * ( sin(win/4) * Base[0][1] + cos(win/4) * Base[2][1] )/ (pi/lattice)
	ky0=ky_start-kx_start/(kx_stop-kx_start)*(ky_stop-ky_start)  // value of intercept of slit direction and y axis
	Rangle_slit=atan((ky_stop-ky_start)/(kx_stop-kx_start))
	//print "kx_start,kx_stop,ky_start,ky_stop",kx_start,kx_stop,ky_start,ky_stop
	//print "angle, intercept", Rangle_slit*180/pi,ky0
	
Make/O /N=(nb) temp_angle
if (cmpstr(Disp_angle,"none")==0)
	temp_angle=Dimoffset($Disp_Energy,0)+(p+p_min)*DimDelta($Disp_Energy,0)
else
	duplicate/o $disp_angle temp
	temp_angle=temp[p+p_min]
endif

Duplicate/O temp_angle Disp_K

indice=0   //  
do
	
	Rangle=(temp_angle[indice]-tilt)*pi/180
	kx = 0.512 * sqrt (photon) * ( sin(Rangle) * Base[0][0] + cos(Rangle) * Base[2][0] )/ (pi/lattice)
	ky = 0.512 * sqrt (photon) * ( sin(Rangle) * Base[0][1] + cos(Rangle) * Base[2][1] )/ (pi/lattice)

	Disp_K[indice]= (kx/abs(kx)) * sqrt( kx^2 +(ky-ky0)^2)
	
	indice+=1
	
while (indice<=nb )
Killwaves temp_angle

//Wave for energy
Make/O /N=(nb) disp_E
if (cmpstr(Disp_energy,"none")==0)
	Disp_E=Dimoffset($Disp_angle,0)+(p+p_min)*DimDelta($Disp_angle,0)
else
	Duplicate/O $disp_energy temp
	Disp_E=temp[p+p_min]
endif

execute "Interpolate/T=1/N="+num2str(Dimsize(Disp_K,0))+"/Y=Disp_KvsE Disp_K /X=disp_E"
execute "Interpolate/T=1/N="+num2str(Dimsize(Disp_K,0))+"/Y=Disp_EvsK Disp_E /X=disp_K"


DoWindow/K Disp_

string name2
if (cmpstr(PlotType,"E vs k (1 wave)")==0)
	Duplicate/O Disp_EvsK $name
	Display $name
	ModifyGraph zero(left)=1
endif
if (cmpstr(PlotType,"K vs E (1 wave)")==0)
	Duplicate/O Disp_KvsE $name
	Display $name
	ModifyGraph zero(bottom)=1
endif
if (cmpstr(PlotType,"E vs k (2 waves)")==0)
	name2=name+"_k"
	Duplicate/O Disp_E $name2
	name=name+"_E"
	Duplicate/O Disp_k $name
	Display $name vs $name2
	ModifyGraph zero(left)=1
endif
if (cmpstr(PlotType,"k vs E (2 waves)")==0)
	name2=name+"_E"
	Duplicate/O Disp_E $name2
	name=name+"_k"
	Duplicate/O Disp_k $name
	Display $name vs $name2
	ModifyGraph zero(bottom)=1
endif

DoWindow/C Disp_
DoWindow/T Disp_,"Disp_"
ModifyGraph mode=3,marker=19
ShowInfo
variable deb,fin
deb=leftx($name)        
fin=deb+deltax($name)*(numpnts($name)-1)
Cursor A, $name, deb
Cursor B, $name, fin
DoUpdate  	
endif

end

////////////////////////////////////////////////

Function Ask_Transform_Image_True(origin)
variable origin // 0 from menu, 1 from ImageTool

//True conversion : uses sin(theta) and not a linear scale but has to extrapolate so changes raw data

string/G NameOfImage,TypeOfImage
variable/G tilt,photon2,lattice2
string NameOfImageL,TypeOfImageL
variable tiltL,photon2L,lattice2L,thetaL
string ListOfNames,choix,name

NameOfImageL=NameOfImage
TypeOfImageL=TypeOfImage
tiltL=tilt
photon2L=photon2
lattice2L=lattice2
if (lattice2L==0)
   lattice2L=pi
endif

if (origin==0)
	NameOfImage=Find_TopImageName()
	ListOfnames="none;"+WaveList("*",";","DIMS:2")
else
	ListOfnames="Image"
	NameOfImage="root:IMG:Image"
endif	



prompt NameOFImageL," Name of image ", popup,ListOfnames
choix="E vs angle; Angle vs E"
prompt TypeOfImageL,"Type of image ", popup,choix
prompt TiltL, " True angle value for zero (tilt) "
prompt ThetaL, " Theta angle for the image "
prompt photon2L, "Photon energy-W (eV)"
prompt lattice2L, "Lattice value (for pi/a units)"

//DoPrompt "Convert..." NameOfImage,TypeOfImage,theta,phi,photon2,lattice2
DoPrompt "Convert..." NameOfImageL,TypeOfImageL,TiltL,thetaL,photon2L,lattice2L

NameOfImage=NameOfImageL
TypeOfImage=TypeOfImageL
Tilt=TiltL
photon2=photon2L
lattice2=Lattice2L

////
if (v_flag==0)
     Transform_Image_True(NameOfImage,TypeOfImage,tilt,thetaL,photon2,lattice2)
endif	

end

Function Transform_Image_True(NameOfImage,TypeOfImage,tilt,theta,photon,lattice)
// For a dispersion taken in the slits direction. 
// Uses the center of the image as tilt value (Warning : this will be wrong if images at different tilt are combined).
// (Remark : the parameter called tilt above is like an offset for this tilt)
// Applies k=sin(angle-tilt)*cos(tilt)+cos(angle-tilt)*cos(theta)*sin(tilt)
// NB : the correction of cos(theta) is independent of phi


string NameOfImage,TypeOfImage // TypeOfImage="E vs angle" ou "Angle vs E"
variable tilt,theta,photon,lattice

	DuplicateForUndo(NameOfImage)
	wave Image_backup
	variable angle_start,angle_stop,k_start,k_stop,indice,delta_k

	if (cmpstr(TypeOfImage,"E vs Angle")==0)
		indice=0
	else
		indice=1
	endif	
	
	if (tilt==tilt)
		// Shift NameOfImage by tilt
		if (indice==0)
			SetScale/P x dimOffset($NameOfImage,0)+tilt,DimDelta($NameOfImage,0), $NameOfImage
		else
			SetScale/P y dimOffset($NameOfImage,1)+tilt,DimDelta($NameOfImage,1), $NameOfImage
		endif
	endif	
	
	FindCorrectk($NameOfImage,indice,theta,photon,lattice)
	wave index_k 
	k_start=DimOffset(index_k,0)
	delta_k=DimDelta(index_k,0)
	
	if (cmpstr(TypeOfImage,"E vs Angle")==0)
		SetScale/P x k_start,delta_k,$NameOfImage
		Duplicate/O $NameOfImage temp1
		//temp1[][]=Image_backup[ (asin( (dimoffset(temp1,0)+p*dimdelta(temp1,0) )/C)*180/pi-tilt-Dimoffset(Image_backup,0))/dimdelta(Image_backup,0) ][q]
		temp1[][]=Image_backup[ index_k(k_start+p*delta_k )][q]
		Duplicate/O temp1  $NameOfImage
		Killwaves temp1
	else
		SetScale/P y k_start,delta_k,$NameOfImage
		Duplicate/O $NameOfImage temp1
		// temp1 (energy) (k) = Image_backup (energy) ( theta(k)-phi)
		//temp1[][]=Image_backup[p][ (asin( (dimoffset(temp1,1)+q*dimdelta(temp1,1) )/C)*180/pi-tilt-Dimoffset(Image_backup,1))/dimdelta(Image_backup,1) ]
		temp1[][]=Image_backup[p][ index_k(k_start+q*delta_k) ]
		Duplicate/O temp1  $NameOfImage
		Killwaves temp1
	endif
	
end

function FindCorrectk(Image,indice,theta,photon,lattice)
wave Image
variable indice,theta,photon,lattice
//returns a wave index_k containing the index in the image corresponding to the angle for one k value
	// On utilise k=sin(alpha-tilt)*cos(tilt)+cos(alpha-tilt)*cos(theta)*sin(tilt)
	// La difficulté est qu'il n'y a pas de formule facile pour retrouver alpha à partir de k. 
	// On tourne la difficulté en calculant k en fonction de alpha puis en interpolant alpha(k) avec une échelle linéaire en k
	// On calcule ensuite le numéro du point auquel correspond alpha(k) : c'est index_k(k)

variable angle_start,angle_stop,k_start,k_stop,delta_k,tilt
	angle_start=Dimoffset(Image,indice)
	angle_stop=Dimoffset(Image,indice)+DimDelta(Image,indice)*(DimSize(Image,indice)-1)
	tilt=(angle_stop+angle_start)/2 // tilt is the center of the detector window
	Make/O/N=(dimsize(Image,indice)) k_value,angle_value
	angle_value=angle_start+p*dimDelta(Image,indice)-tilt // angle_value is the angle on the detector

	variable C=0.512*sqrt(photon)/(pi/lattice)
	k_value=C*(sin(angle_value[p]*pi/180)*cos(tilt*pi/180)+cos(angle_value[p]*pi/180)*cos(theta*pi/180)*sin(tilt*pi/180))
	k_start=k_value[0]
	k_stop=k_value[DimSize(Image,indice)-1]
	delta_k=(k_stop-k_start)/(DimSize(k_value,0)-1)
	Interpolate2/T=1/N=(Dimsize(angle_value,0))/Y=index_k k_value, angle_value
      wave index_k
	index_k=(index_k-angle_value[0])/DimDelta(Image,indice)  // = index of angle(k)

end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////-------------------------- Correct_FS
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function Correct_FermiSurface(FSimage,phi_cur,delta)
wave FSimage
variable phi_cur  //phi_cur : real phi value to apply to FS
variable delta   // angle step in degree to calculate the FS
//For a Fermi Surface done by a serie of theta values for one phi and tilt 
//NB : we assume tilt value is the middle of the scienta window

nvar sample_tilt,phi_tilt
nvar photon,lattice
variable Rsample_tilt,Rphi_tilt,RScienta
	Rsample_tilt=sample_tilt*pi/180
	Rphi_tilt=phi_tilt*pi/180

variable indice_scienta,indice_theta,indice,Nb
variable kx,ky,indice_kx,indice_ky
wave FS_2D

//creation of Correct_FS
variable kx_start,kx_stop,ky_start,ky_stop
variable Nb_kx,Nb_ky
variable RScientaStart,RScientaStop,Rdelta_scienta,RTilt_cur,theta_cur

if (DimDelta(FS_2D,0)>0)
RScientaStart=DimOffset(FS_2D,0)
RScientaStop=DimOffset(FS_2D,0)+(DimSize(FS_2D,0)-1)*DimDelta(FS_2D,0)
else
RScientaStop=DimOffset(FS_2D,0)
RScientaStart=DimOffset(FS_2D,0)+(DimSize(FS_2D,0)-1)*DimDelta(FS_2D,0)
endif
RTilt_cur=(RScientaStart+RScientaStop)/2
RScientaStart=RScientaStart-RTilt_cur
RScientaStop=RScientaStop-RTilt_cur
RTilt_cur*=pi/180

//look for min and max
	theta_cur=DimOffset(FS_2D,1)
	Calculate_NewBase(theta_cur*pi/180,Rtilt_cur,phi_cur*pi/180,Rsample_tilt,Rphi_tilt)
	wave Base
	kx_start= Calculate_kx(RScientaStart,base)
	//print kx_start
	kx=Calculate_kx(RScientaStop,base)
	if (kx<kx_start)
		kx_stop=kx_start
		kx_start=kx
		else
		kx_stop=kx
	endif
	ky_start = Calculate_ky(RScientaStart,base)
	ky=Calculate_ky(RScientaStop,base)
	if (ky<ky_start)
		ky_stop=ky_start
		ky_start=ky
		else
		ky_stop=ky
	endif
	//print "kx_start,kx_stop,ky_start,ky_stop",kx_start,kx_stop,ky_start,ky_stop
	
	theta_cur=DimOffset(FS_2D,1)+DimDelta(FS_2D,1)*(DimSize(FS_2D,1)-1)
	Calculate_NewBase(theta_cur*pi/180,Rtilt_cur,phi_cur*pi/180,Rsample_tilt,Rphi_tilt)
	kx= Calculate_kx(RScientaStart,base)
	if (kx<kx_start)
			kx_start=kx
		endif
		if (kx>kx_stop)
			kx_stop=kx
		endif	
	kx=Calculate_kx(RScientaStop,base)
	if (kx<kx_start)
			kx_start=kx
		endif
		if (kx>kx_stop)
			kx_stop=kx
		endif	
	ky = Calculate_ky(RScientaStart,base)
	if (ky<ky_start)
			ky_start=ky
		endif
		if (ky>ky_stop)
			ky_stop=ky
		endif		
	ky=Calculate_ky(RScientaStop,base)
	if (ky<ky_start)
			ky_start=ky
	endif
	if (ky>ky_stop)
			ky_stop=ky
	endif		
	//print "kx_start,kx_stop,ky_start,ky_stop",kx_start,kx_stop,ky_start,ky_stop

//Define Correct_FS wave

	delta=0.512*sqrt(photon)*sin(delta*pi/180)/ (pi/lattice)
	Nb_kx=round((kx_stop-kx_start)/Delta)+1
	Nb_ky=round((ky_stop-ky_start)/Delta)+1

	Make/O/N=(Nb_kx,Nb_ky) Correct_FS
	SetScale/I x (kx_start-delta/2),(kx_stop+delta/2),"", Correct_FS
	SetScale/I y (ky_start-delta/2),(ky_stop+delta/2),"", Correct_FS
	Correct_FS[][]=NaN

//Calculation 1 : for each point of FS_2D calculates kx and ky and enters it in Correct_FS
	indice_theta=0
	do
		theta_cur=(DimOffset(FS_2D,1)+indice_theta*DimDelta(FS_2D,1))
		Calculate_NewBase(theta_cur*pi/180,Rtilt_cur,phi_cur*pi/180,Rsample_tilt,Rphi_tilt)
		indice_scienta=0
		Rdelta_scienta=(RScientaStop-RScientaStart)/(abs(Dimsize(FS_2D,0))-1)
		do
			Rscienta=RScientaStart+indice_scienta*Rdelta_scienta
			kx= Calculate_kx(Rscienta,Base)
			ky= Calculate_ky(Rscienta,Base)
			indice_kx=round( (kx-DimOffset(Correct_FS,0))/DimDelta(Correct_FS,0) )
			indice_ky=round( (ky-DimOffset(Correct_FS,1))/DimDelta(Correct_FS,1) )

			if (Correct_FS[indice_kx][indice_ky]==Correct_FS[indice_kx][indice_ky])//returns 0 if NaN
				Correct_FS[indice_kx][indice_ky]=(Correct_FS[indice_kx][indice_ky]+FS_2D[indice_scienta][indice_theta])/2
			else
				Correct_FS[indice_kx][indice_ky]=FS_2D[indice_scienta][indice_theta]			
			endif	
		
			indice+=1	
			//print "indice_x,indice_y,tilt,theta,kx,ky,indice_kx,indice_ky",indice_x,indice_y,tilt_cur*180/pi,theta_cur*180/pi,kx,ky,indice_kx,indice_ky
			indice_scienta+=1
		while (indice_scienta<Dimsize(FS_2D,0))
		indice_theta+=1
	while (indice_theta<Dimsize(FS_2D,1)	)

//Calculation 2 : for each point of FS_2D calculates kx and ky and enters it in Correct_FS
	indice_theta=0
	do
		theta_cur=(DimOffset(FS_2D,1)+indice_theta*DimDelta(FS_2D,1))
		Calculate_NewBase(theta_cur*pi/180,Rtilt_cur,phi_cur*pi/180,Rsample_tilt,Rphi_tilt)
		indice_scienta=0
		Rdelta_scienta=(RScientaStop-RScientaStart)/(abs(Dimsize(FS_2D,0))-1)
		do
			Rscienta=RScientaStart+indice_scienta*Rdelta_scienta
			kx= Calculate_kx(Rscienta,Base)
			ky= Calculate_ky(Rscienta,Base)
			indice_kx=round( (kx-DimOffset(Correct_FS,0))/DimDelta(Correct_FS,0) )
			indice_ky=round( (ky-DimOffset(Correct_FS,1))/DimDelta(Correct_FS,1) )

			if (Correct_FS[indice_kx][indice_ky]==Correct_FS[indice_kx][indice_ky])//returns 0 if NaN
				Correct_FS[indice_kx][indice_ky]=(Correct_FS[indice_kx][indice_ky]+FS_2D[indice_scienta][indice_theta])/2
			else
				Correct_FS[indice_kx][indice_ky]=FS_2D[indice_scienta][indice_theta]			
			endif	
		
			indice+=1	
			//print "indice_x,indice_y,tilt,theta,kx,ky,indice_kx,indice_ky",indice_x,indice_y,tilt_cur*180/pi,theta_cur*180/pi,kx,ky,indice_kx,indice_ky
			indice_scienta+=1
		while (indice_scienta<Dimsize(FS_2D,0))
		indice_theta+=1
	while (indice_theta<Dimsize(FS_2D,1)	)

end

///////////////////////////////////

Function	 CorrectFermiSurface_VsPhi(FS_2D,delta) 
wave FS_2D
variable delta
//For a Fermi Surface done by a serie of phi values for one theta and tilt (taken from offsets)
//Tilt is taken as middle of the window
//Use values of BZcuts for sample tilt

nvar sample_tilt,phi_tilt,offset_theta,offset_tilt,phi
nvar photon,win,lattice
variable Rsample_tilt,Rphi_tilt,RScienta
	Rsample_tilt=sample_tilt*pi/180
	Rphi_tilt=phi_tilt*pi/180

variable indice_scienta,indice_phi,phiL
variable kx,ky,indice_kx,indice_ky
wave FS_2D

//creation of Correct_FS
variable kx_start,kx_stop,ky_start,ky_stop
variable Nb_kx,Nb_ky
variable RScientaStart,RScientaStop,RTilt_cur,Rdelta_scienta

RScientaStart=DimOffset(FS_2D,0)*pi/180
RScientaStop=(DimOffset(FS_2D,0)+(DimSize(FS_2D,0)-1)*DimDelta(FS_2D,0))*pi/180
RTilt_cur=(RScientaStart+RScientaStop)/2
RScientaStart=RScientaStart-RTilt_cur
RScientaStop=RScientaStop-RTilt_cur


	//look for min and max
phiL=DimOffset(FS_2D,1)-phi
Calculate_NewBase(offset_theta*pi/180,Rtilt_cur,phiL*pi/180,Rsample_tilt,Rphi_tilt)
wave Base
kx_start= 0.512 * sqrt (photon) * ( sin(RScientaStart) * Base[0][0] + cos(RScientaStart) * Base[2][0] )/ (pi/lattice)
kx_stop=kx_start
ky_start = 0.512 * sqrt (photon) * ( sin(RScientaStart) * Base[0][1] + cos(RScientaStart) * Base[2][1] )/ (pi/lattice)
ky_stop=ky_start
		
indice_phi=0
	do
		phiL=DimOffset(FS_2D,1)+indice_phi*DimDelta(FS_2D,1)-phi
		Calculate_NewBase(offset_theta*pi/180,Rtilt_cur,phiL*pi/180,Rsample_tilt,Rphi_tilt)
		
		kx= 0.512 * sqrt (photon) * ( sin(RScientaStart) * Base[0][0] + cos(RScientaStart) * Base[2][0] )/ (pi/lattice)
		ky = 0.512 * sqrt (photon) * ( sin(RScientaStart) * Base[0][1] + cos(RScientaStart) * Base[2][1] )/ (pi/lattice)
		//print "phi_cur,kx,ky",phi_cur,kx,ky
		if (kx<kx_start)
			kx_start=kx
		endif
		if (kx>kx_stop)
			kx_stop=kx
		endif	
		if (ky<ky_start)
			ky_start=ky
		endif
		if (ky>ky_stop)
			ky_stop=ky
		endif		

		kx= 0.512 * sqrt (photon) * ( sin(RScientaStop) * Base[0][0] + cos(RScientaStop) * Base[2][0] )/ (pi/lattice)
		ky = 0.512 * sqrt (photon) * ( sin(RScientaStop) * Base[0][1] + cos(RScientaStop) * Base[2][1] )/ (pi/lattice)
		//print "phi_cur,kx,ky",phi_cur,kx,ky
		if (kx<kx_start)
			kx_start=kx
		endif
		if (kx>kx_stop)
			kx_stop=kx
		endif	
		if (ky<ky_start)
			ky_start=ky
		endif
		if (ky>ky_stop)
			ky_stop=ky
		endif		

		indice_phi+=1
	while (indice_phi<Dimsize(FS_2D,1))

//print "kx_start,kx_stop,ky_start,ky_stop",kx_start,kx_stop,ky_start,ky_stop

//Define Correct_FS wave
Delta=min(DimDelta(FS_2D,0),DimDelta(FS_2D,1))  // delta for angle chosen as the minimum step value
delta=0.512*sqrt(photon)*sin(delta*pi/180)/ (pi/lattice)
Nb_kx=round((kx_stop-kx_start)/Delta)
Nb_ky=round((ky_stop-ky_start)/Delta)

Make/O/N=(Nb_kx,Nb_ky) Correct_FS
SetScale/I x kx_start,kx_stop,"", Correct_FS
SetScale/I y ky_start,ky_stop,"", Correct_FS
Correct_FS=NaN

//Calculation
indice_phi=0
Rdelta_scienta=(RScientaStop-RScientaStart)/(Dimsize(FS_2D,0)-1)
do
	phiL=DimOffset(FS_2D,1)+indice_phi*DimDelta(FS_2D,1)-phi
	Calculate_NewBase(offset_theta*pi/180,Rtilt_cur,phiL*pi/180,Rsample_tilt,Rphi_tilt)
	
	indice_scienta=0
	
	do
		Rscienta=RScientaStart+indice_scienta*Rdelta_scienta
		kx= 0.512 * sqrt (photon) * ( sin(RScienta) * Base[0][0] + cos(RScienta) * Base[2][0] )/ (pi/lattice)
		ky = 0.512 * sqrt (photon) * ( sin(RScienta) * Base[0][1] + cos(RScienta) * Base[2][1] )/ (pi/lattice)
		
		indice_kx=round( (kx-DimOffset(Correct_FS,0))/DimDelta(Correct_FS,0) )
		indice_ky=round( (ky-DimOffset(Correct_FS,1))/DimDelta(Correct_FS,1) )
		
		if (Correct_FS[indice_kx][indice_ky]==Correct_FS[indice_kx][indice_ky])//returns 0 if NaN
			Correct_FS[indice_kx][indice_ky]=(Correct_FS[indice_kx][indice_ky]+FS_2D[indice_scienta][indice_phi])/2
			else
			Correct_FS[indice_kx][indice_ky]=FS_2D[indice_scienta][indice_phi]			
		endif	
		//print "Value at (kx,ky)",FS_2D[indice_scienta][indice_phi]
		
		indice_scienta+=1
	while (indice_scienta<Dimsize(FS_2D,0))
	indice_phi+=1
//while (indice_phi<3)
while (indice_phi<Dimsize(FS_2D,1)	)
	
end

//////////////////////////////////////////
/// Correct_FS vs kz

Function Correct_FermiSurface_kz(FSimage,theta_cur,phi_cur,delta)
wave FSimage
variable phi_cur,theta_cur  // real theta and phi value to apply to FS
variable delta   // angle step in degree to calculate the FS
//For a Fermi Surface done by a serie of energies for one phi, tilt and theta 
//NB : we assume tilt value is the middle of the scienta window

nvar sample_tilt,phi_tilt
nvar photon,lattice,latticeC,offset_theta
variable Rsample_tilt,Rphi_tilt,RScienta
	Rsample_tilt=sample_tilt*pi/180
	Rphi_tilt=phi_tilt*pi/180

variable indice_scienta,indice_theta,indice,Nb
variable kx,ky,k,indice_k,kz,indice_kz
wave FS_2D

//creation of Correct_FS
variable k_start,k_stop,kz_start,kz_stop,kx0,ky0
variable Nb_k,Nb_kz
variable RScientaStart,RScientaStop,Rdelta_scienta,RTilt_cur,E_cur
variable/G WorkFunction

	if (DimDelta(FS_2D,0)>0)
		RScientaStart=DimOffset(FS_2D,0)*pi/180
		RScientaStop=(DimOffset(FS_2D,0)+(DimSize(FS_2D,0)-1)*DimDelta(FS_2D,0))*pi/180
	else
		RScientaStop=DimOffset(FS_2D,0)*pi/180
		RScientaStart=(DimOffset(FS_2D,0)+(DimSize(FS_2D,0)-1)*DimDelta(FS_2D,0))*pi/180
	endif
	RTilt_cur=(RScientaStart+RScientaStop)/2
	RScientaStart=RScientaStart-RTilt_cur
	RScientaStop=RScientaStop-RTilt_cur

	//look for min and max : do the whole calculation wothout saving...
	indice=0
	indice_theta=0
	Calculate_NewBase(theta_cur*pi/180,Rtilt_cur,phi_cur*pi/180,Rsample_tilt,Rphi_tilt)
	wave Base
	Rscienta=RScientaStart+indice_scienta*Rdelta_scienta
	//initialisation
	E_cur=(DimOffset(FS_2D,1)+indice_theta*DimDelta(FS_2D,1))
	kx= 0.512 * sqrt (E_cur-WorkFunction) * ( sin(RScienta) * Base[0][0] + cos(RScienta) * Base[2][0] )/ (pi/lattice)
	ky = 0.512 * sqrt (E_cur-WorkFunction) * ( sin(RScienta) * Base[0][1] + cos(RScienta) * Base[2][1] )/ (pi/lattice)
	k_start=sign(kx)*sqrt(kx^2+ky^2)
	k_stop=k_start
	kz_start=sqrt(0.512^2*(E_cur-WorkFunction+photon)-(k_start*pi/lattice)^2)/pi*latticeC
	kz_stop=kz_start
	
	do //loop along rows of FS
		E_cur=(DimOffset(FS_2D,1)+indice_theta*DimDelta(FS_2D,1))
		indice_scienta=0
		Rdelta_scienta=(RScientaStop-RScientaStart)/(abs(Dimsize(FS_2D,0))-1)
		do //loop along one slice of FS
			Rscienta=RScientaStart+indice_scienta*Rdelta_scienta
			kx= 0.512 * sqrt (E_cur-WorkFunction) * ( sin(RScienta) * Base[0][0] + cos(RScienta) * Base[2][0] )/ (pi/lattice)
			ky = 0.512 * sqrt (E_cur-WorkFunction) * ( sin(RScienta) * Base[0][1] + cos(RScienta) * Base[2][1] )/ (pi/lattice)
			
			k=sign(kx)*sqrt(kx^2+ky^2)
			kz=sqrt(0.512^2*(E_cur-WorkFunction+photon)-(k*pi/lattice)^2)/pi*latticeC
		
			if (k>k_stop)
				k_stop=k
			endif
			if (k<k_start)
				k_start=k
			endif
			if (kz>kz_stop)
				kz_stop=kz
			endif
			if (kz<kz_start)
				kz_start=kz
			endif				
		
		indice+=1	
		//print "indice_x,indice_y,tilt,theta,kx,ky,indice_kx,indice_ky",indice_x,indice_y,tilt_cur*180/pi,theta_cur*180/pi,kx,ky,indice_kx,indice_ky
		indice_scienta+=1
	while (indice_scienta<Dimsize(FS_2D,0))
	indice_theta+=1
while (indice_theta<Dimsize(FS_2D,1)	)

//Define Correct_FS wave

delta=0.512*sqrt(E_cur)*sin(delta*pi/180)/ (pi/lattice)
Nb_k=round((k_stop-k_start)/Delta)+1
Nb_kz=round((kz_stop-kz_start)/Delta)+1

Make/O/N=(Nb_k,Nb_kz) Correct_FS
SetScale/I x (k_start-delta/2),(k_stop+delta/2),"", Correct_FS
SetScale/I y (kz_start-delta/2),(kz_stop+delta/2),"", Correct_FS
Correct_FS[][]=NaN

//Calculation
indice=0
indice_theta=0
Calculate_NewBase(theta_cur*pi/180,Rtilt_cur,phi_cur*pi/180,Rsample_tilt,Rphi_tilt)
	do //loop along rows of FS
		E_cur=(DimOffset(FS_2D,1)+indice_theta*DimDelta(FS_2D,1))
		indice_scienta=0
		Rdelta_scienta=(RScientaStop-RScientaStart)/(abs(Dimsize(FS_2D,0))-1)
		do //loop along one slice of FS
			Rscienta=RScientaStart+indice_scienta*Rdelta_scienta
			kx= 0.512 * sqrt (E_cur-WorkFunction) * ( sin(RScienta) * Base[0][0] + cos(RScienta) * Base[2][0] )/ (pi/lattice)
			ky = 0.512 * sqrt (E_cur-WorkFunction) * ( sin(RScienta) * Base[0][1] + cos(RScienta) * Base[2][1] )/ (pi/lattice)
			
			k=sign(kx)*sqrt(kx^2+ky^2)
			kz=sqrt(0.512^2*(E_cur-WorkFunction+photon)-(k*pi/lattice)^2)/pi*latticeC
		
		indice_k=round( (k-DimOffset(Correct_FS,0))/DimDelta(Correct_FS,0) )
		indice_kz=round( (kz-DimOffset(Correct_FS,1))/DimDelta(Correct_FS,1) )

		if (Correct_FS[indice_k][indice_kz]==Correct_FS[indice_k][indice_kz])//returns 0 if NaN
			Correct_FS[indice_k][indice_kz]=(Correct_FS[indice_k][indice_kz]+FS_2D[indice_scienta][indice_theta])/2
			else
			Correct_FS[indice_k][indice_kz]=FS_2D[indice_scienta][indice_theta]			
		endif	
		
		indice+=1	
		//print "indice_x,indice_y,tilt,theta,kx,ky,indice_kx,indice_ky",indice_x,indice_y,tilt_cur*180/pi,theta_cur*180/pi,kx,ky,indice_kx,indice_ky
		indice_scienta+=1
	while (indice_scienta<Dimsize(FS_2D,0))
	indice_theta+=1
while (indice_theta<Dimsize(FS_2D,1)	)


end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////-------------------------- BZ cuts

proc GraphForCuts()

string curr=GetDataFolder(1)
SetDataFolder root:



// Maille hexagonale (cobaltate)
//Make/O /N=7 BZ_kx,BZ_ky
//BZ_kx[0]=1.485
//BZ_kx[1]=0.743
//BZ_kx[2]=-0.743
//BZ_kx[3]=-1.485
//BZ_kx[4]=-0.743
//BZ_kx[5]=0.743
//BZ_kx[6]=1.485
//
//BZ_ky[0]=0
//BZ_ky[1]=-1.286
//BZ_ky[2]=-1.286
//BZ_ky[3]=0
//BZ_ky[4]=1.286
//BZ_ky[5]=1.286
//BZ_ky[6]=0

// Maille carrée
Make/O /N=5 BZ_kx,BZ_ky
BZ_kx[0]=-1
BZ_kx[1]=-1
BZ_kx[2]=1
BZ_kx[3]=1
BZ_kx[4]=-1
//
BZ_ky[0]=-1
BZ_ky[1]=1
BZ_ky[2]=1
BZ_ky[3]=-1
BZ_ky[4]=-1


	Display/W=(10,10,500,350) BZ_ky vs BZ_kx
	SetAxis bottom -2,2
	SetAxis left -1.6,1.6
	variable/G win=30,Nb=128//win=window of analyser (total, in degree), Nb= nb of points for fente (arbitrary, just for drawing)
	variable/G photon,theta,tilt,phi,sample_tilt,phi_tilt,lattice
	if (photon==0)  //otherwise, keep last used value
		photon=100
	endif	
	if (lattice==0)  //otherwise, keep last used value
		lattice=3.1416
	endif	
	if (theta==0)  //otherwise, keep last used value
		theta=0
	endif	
	if (tilt==0)  //otherwise, keep last used value
		tilt=0
	endif	
	if (sample_tilt==0)  //otherwise, keep last used value
		sample_tilt=0
	endif	
	if (phi_tilt==0)  //otherwise, keep last used value
		phi_tilt=0
	endif	
	if (phi==0)  //otherwise, keep last used value
		phi=0
	endif	
	string/G option="erase"  //=erase ou keep trace : pour rafraichir le tracé des fentes à chaque nouvelle valeur d'angle ou au contraire laisser afficher toutes les fentes calculées
	variable/G Nb_fente=1  //Nb de waves représentant des fentes 

	Make/O /N=(Nb) fente_kx_1,fente_ky_1
	Fente_ky_1=0
	Fente_kx_1=0.512*sqrt(photon)*sin((-win/2+p*win/(Nb-1))*pi/180)/(pi/lattice)
	AppendToGraph Fente_ky_1 vs fente_kx_1
	ModifyGraph lsize(Fente_ky_1)=3,rgb(Fente_ky_1)=(24576,24576,65280)
	ModifyGraph zero=1
	ModifyGraph axOffset(left)=10
	ModifyGraph fSize=16
	
	SetVariable photonBox,pos={10,10},size={80,14},limits={0,1000,10},proc =Refresh_cuts,title=" hn-W",value=photon
	SetVariable latticeBox,pos={10,35},size={80,14},limits={0,1000,10},proc =Refresh_cuts,title=" lattice",value=lattice
	
	SetVariable ThetaBox,pos={10,75},size={80,14},limits={-360,360,1},proc =Refresh_cuts,title="Theta",value=theta
	SetVariable TiltBox,pos={10,100},size={80,14},limits={-360,360,1},proc =Refresh_cuts,title="Tilt",value=tilt
	SetVariable PhiBox,pos={10,125},size={80,14},limits={-360,360,10},proc =Refresh_cuts,title="Phi",value=phi
	
	// Sample misalignment : angle theta_tilt around one axis in (x,y) plane, rotated from Ox by phi_tilt 
	SetVariable SampleTiltBox,pos={10,165},size={100,14},limits={-360,360,1},proc =Refresh_cuts,title="sample tilt",value=sample_tilt
	SetVariable PhiTiltBox,pos={10,190},size={100,14},limits={-360,360,10},proc =Refresh_cuts,title="Phi tilt",value=Phi_tilt
	
	PopupMenu PopOptions,pos={5,245},size={111,21},proc=SelectOption,title="Mode",popvalue="erase", value="erase;keep trace"

SetDataFolder curr

end	

Proc ChangePhiStep(Newstep)
variable newstep
SetVariable PhiBox,pos={10,100},size={80,14},limits={-360,360,newstep},proc = Refresh_cuts,title="Phi",value=phi
SetVariable PhiTiltBox,pos={10,165},size={100,14},limits={-360,360,newstep},proc = Refresh_cuts,title="Phi tilt",value=Phi_tilt
end

Proc SelectOption(ctrlName,popNum,popStr) : PopupMenuControl
//-----------------------------
        String ctrlName
        Variable popNum
        String popStr
        
        variable i
        string name_kx,name_ky
        
        string curr=GetDataFolder(1)
        SetDataFolder root:
        
        option=popStr
        
        // If switch to "erase", erase all previous traces
        if (cmpstr(option,"erase")==0)
        	i=2
        	do
        		name_kx="fente_kx_"+num2str(i)
        		name_ky="fente_ky_"+num2str(i)
        		RemoveFromGraph/Z $name_ky
        		Killwaves/Z $name_kx,$name_ky
        		i+=1
        	while(i<=Nb_fente)
        	Nb_fente=1
        endif	
        SetDataFolder curr
        Refresh_cuts("",0,"","")
        
end

Macro Refresh_cuts(ctrlname,bidon,varStr,varName):SetVariableControl
	String Ctrlname
	Variable bidon
	string varStr
	string varName

//First rotate sample and calculate the new frame (called "base" below)
//Then project the scienta slits in the sample plane (kx=OM.e_x and ky=kx=OM.e_y)

string curr=GetDataFolder(1)

SetDataFolder root:

	string name_kx,name_ky
	variable Rphi,Rtheta,Rtilt,Rsample_tilt,RPhi_tilt   // angles in radian
	Rphi=phi*pi/180
	Rtheta=theta*pi/180
	Rtilt=Tilt*pi/180
	Rsample_tilt=sample_tilt*pi/180
	RPhi_tilt=Phi_tilt*pi/180
	
	if (cmpstr(option,"keep trace")==0)
		Nb_fente+=1
	endif	
	name_kx="fente_kx_"+num2str(Nb_fente)
	name_ky="fente_ky_"+num2str(Nb_fente)
	
	Duplicate/O fente_kx_1 temp_kx,temp_ky

//////////////////////////////////////////////////////////////////////
//////////////////  Start calculation

make/O Base={ {1,0,0} , {0,1,0} , {0,0,1} }  // NB : { {colonne 1} , {colonne 2} , {colonne 3} }
Calculate_NewBase(Rtheta,Rtilt,Rphi,Rsample_tilt,Rphi_tilt)

// Project M( k.sin(alpha), 0, k.cos(alpha) ) in the sample plane. Alpha is the angle along Scienta = -win/2 to win/2
temp_kx = 0.512 * sqrt (photon) * ( sin((-win/2+p*win/(Nb-1))*pi/180) * Base[0][0] + cos((-win/2+p*win/(Nb-1))*pi/180) * Base[2][0] ) / (pi/lattice)
temp_ky = 0.512 * sqrt (photon) * ( sin((-win/2+p*win/(Nb-1))*pi/180) * Base[0][1] + cos((-win/2+p*win/(Nb-1))*pi/180) * Base[2][1] )/ (pi/lattice)

///////////////////////////////////////
	
	Duplicate/O  temp_kx $name_kx
	Duplicate/O  temp_ky $name_ky	
	
	if (cmpstr(option,"keep trace")==0)
		AppendToGraph $name_ky vs $name_kx
		ModifyGraph lsize($name_ky)=3,rgb($name_ky)=(0,15872,65280)
	endif	

SetDataFolder curr
		
end	

function	CalculateFS_k_line(theta,phi)
	variable theta,phi
	
	nvar sample_tilt,phi_tilt,photon,lattice
	wave FS_2D
	Make/O/N=(DimSize(FS_2D,0)) FS_k_line_x,FS_k_line_y
	variable Rphi,Rtheta,Rtilt,Rsample_tilt,RPhi_tilt,RScientaStart,RScientaStop   // angles in radian
	
	Rphi=phi*pi/180
	Rtheta=theta*pi/180
	if (DimDelta(FS_2D,0)>0)
		RScientaStart=DimOffset(FS_2D,0)*pi/180
		RScientaStop=(DimOffset(FS_2D,0)+(DimSize(FS_2D,0)-1)*DimDelta(FS_2D,0))*pi/180
	else
		RScientaStop=DimOffset(FS_2D,0)*pi/180
		RScientaStart=(DimOffset(FS_2D,0)+(DimSize(FS_2D,0)-1)*DimDelta(FS_2D,0))*pi/180
	endif
	RTilt=(RScientaStart+RScientaStop)/2
	RScientaStart=RScientaStart-RTilt
	RScientaStop=RScientaStop-RTilt

	Rsample_tilt=sample_tilt*pi/180
	RPhi_tilt=Phi_tilt*pi/180

	make/O Base={ {1,0,0} , {0,1,0} , {0,0,1} }  // NB : { {colonne 1} , {colonne 2} , {colonne 3} }
	Calculate_NewBase(Rtheta,Rtilt,Rphi,Rsample_tilt,Rphi_tilt)

	variable indice_scienta,Rdelta_scienta,Rscienta
	indice_scienta=0
	Rdelta_scienta=(RScientaStop-RScientaStart)/(abs(Dimsize(FS_2D,0))-1)
	do //loop along one slice of FS
		Rscienta=RScientaStart+indice_scienta*Rdelta_scienta

		FS_k_line_x[indice_scienta]= 0.512 * sqrt (photon) * ( sin(RScienta) * Base[0][0] + cos(RScienta) * Base[2][0] )/ (pi/lattice)
		FS_k_line_y[indice_scienta] = 0.512 * sqrt (photon) * ( sin(RScienta) * Base[0][1] + cos(RScienta) * Base[2][1] )/ (pi/lattice)
		
		indice_scienta+=1
	while (indice_scienta<Dimsize(FS_2D,0))


end

function	CalculateFS_k_line_energy(energy)
	variable energy
	
	nvar sample_tilt,phi_tilt,photon,lattice,offset_theta,WorkFunction,latticeC
	wave FS_2D,FS_k_line_y,FS_k_line_x
	
	variable Rphi,Rtheta,Rtilt,Rsample_tilt,RPhi_tilt,RScientaStart,RScientaStop   // angles in radian
	
	Rtheta=offset_theta*pi/180
	if (DimDelta(FS_2D,0)>0)
		RScientaStart=DimOffset(FS_2D,0)*pi/180
		RScientaStop=(DimOffset(FS_2D,0)+(DimSize(FS_2D,0)-1)*DimDelta(FS_2D,0))*pi/180
	else
		RScientaStop=DimOffset(FS_2D,0)*pi/180
		RScientaStart=(DimOffset(FS_2D,0)+(DimSize(FS_2D,0)-1)*DimDelta(FS_2D,0))*pi/180
	endif
	RTilt=(RScientaStart+RScientaStop)/2
	RScientaStart=RScientaStart-RTilt
	RScientaStop=RScientaStop-RTilt

	Rsample_tilt=sample_tilt*pi/180
	RPhi_tilt=Phi_tilt*pi/180

	make/O Base={ {1,0,0} , {0,1,0} , {0,0,1} }  // NB : { {colonne 1} , {colonne 2} , {colonne 3} }
	Calculate_NewBase(Rtheta,Rtilt,0,Rsample_tilt,Rphi_tilt)
	
	variable indice_scienta,Rdelta_scienta,kx,ky,Rscienta
	indice_scienta=0
	Rdelta_scienta=(RScientaStop-RScientaStart)/(abs(Dimsize(FS_2D,0))-1)
	do //loop along one slice of FS
		Rscienta=RScientaStart+indice_scienta*Rdelta_scienta
		kx= 0.512 * sqrt (energy-WorkFunction) * ( sin(RScienta) * Base[0][0] + cos(RScienta) * Base[2][0] )/ (pi/lattice)
		ky = 0.512 * sqrt (energy-WorkFunction) * ( sin(RScienta) * Base[0][1] + cos(RScienta) * Base[2][1] )/ (pi/lattice)
		
		FS_k_line_x[indice_scienta]=sign(kx)*sqrt(kx^2+ky^2)
		FS_k_line_y[indice_scienta]=sqrt(0.512^2*(energy-WorkFunction+photon)-(FS_k_line_x[indice_scienta]*pi/lattice)^2)/pi*latticeC
		indice_scienta+=1
	while (indice_scienta<Dimsize(FS_2D,0))
end

