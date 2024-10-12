#pragma rtGlobals=1		// Use modern global access method.

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////  2D images
	//	Use Make2D images to convert the agr file into images	
	//		MakeKxKyImage or MakeKzImage  (needs klist_x etc.)
	//		If necessary change to cartesian coordinates with RewriteKlist()
	//            In original spaghetti plot, the point (x,y) had number Position(x,y)
	//			It is indice_x + (indice_y*Nb_X)+ FirstPoint (FirstPoint=1 in old calculations, 0 otherwise)
	
	// Procedures to extract dispersion and contour from 2D images (available from menu)
	//			ExtractDispersion             // to build the window
	//			Save a bunch of dispersion : Save_disp1
	//			ExtractEnergyContour       // for contours
	//					NB : in  Calculate_contour, one can choose the way contour is defined.
	//
	
	// Procedures to add weight
			// See windows buttons : AddWeightDisp
			// To extract weight of one orbital character along one dispersion (KzWindow)  : ExtractBandDispAndWeight
			// Along all directions : PartialWeights
			
	// Procedure to extract disp at constant photon energy : Disp_variableKz()
	//	 			
	

	//
	////////////////////////////////////////////////////
	// Procedures annexes pas encore mise sous forme facile à utiliser
	// =>  Calculate_NbCarriers()
	// => Symetrization()
	// =>  RenormalizeBand()
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Proc MakeKxKyImage()
// Written for a calculation vs kx and ky
// Nb_kx values first repeated Nb_ky times
// kx and ky are read from klist
// Output called KxKyband_1,KxKyband_2....

// Attention : prévu pour des lignes parallèles à kx

// Find number of kx points for one ky value
variable kx_start,kx_delta,Nb_kx
variable ky_start,ky_delta,Nb_ky
variable i
kx_start=klist_x[0]
ky_start=klist_y[0]
i=0
do
	i+=1
while (klist_y[i]==ky_start)
kx_delta=klist_x[1]-kx_start
kx_start/=klist_m[0]
kx_delta/=klist_m[0]
Nb_kx=i
// Number of ky points
ky_start=klist_y[0]/klist_m[0]
ky_delta=klist_y[i]/klist_m[0]-ky_start
Nb_ky=dimsize(klist_y,0)/Nb_kx
MakeKxKyImage_FromPara(Nb_kx,Nb_ky,kx_start,kx_delta,ky_start,ky_delta)
end

Proc MakeKxKyImage_FromPara(Nb_kx,Nb_ky,kx_start,kx_delta,ky_start,ky_delta)
variable Nb_kx,Nb_ky,kx_start,kx_delta,ky_start,ky_delta
		
Make/O/N=(Nb_kx,Nb_ky) band2D
// With kx and ky in units of reciprocal vector
Setscale/P x kx_start,kx_delta, band2D   
Setscale/P y ky_start,ky_delta, band2D

// With kx and ky in units of inverse angstrom (assuming vectors are the same along kx and ky)
//variable k_delta=dimdelta(band1,0)
//Setscale/P x kx_start*k_delta,k_delta, band2D   
//Setscale/P y ky_start*k_delta,k_delta, band2D

variable indice=1
variable FirstPoint=0
string name
name="band"+num2str(indice)
do
	Duplicate/O $name band1D
	band2D=band1D[FirstPoint+p+q*Nb_kx]
	name="KxKyband_"+num2str(indice)
	Duplicate/O band2D $name
	indice+=1
	name="band"+num2str(indice)
while(exists(name)==1)
Killwaves band1D,band2D

string/G Nameroot
NameRoot="KxKyband_"
ExtractDispersion()
end

////

function MakeKzImage()
// Rewrite all bands from one folder as an image vs kz
// Ultimately, should use klist tables to make images automatically

// Structure should be some variation as a function of kx and kx repeated for different values of kz
// Automatically calculates the number of kz values
// Then create an image with k as x scale (taken from band1 abscisse), kz as y scale.

//NB : for old calculations, first point in k_list did not count
// Now it does : if using old calculations, uncomment band2D=...

variable kz_start,kz_delta,Nb_kz,k_start,k_delta,Nb_k
variable i
wave klist_z,klist_m,band1
	kz_start=klist_z[0]
	i=0
	do
		i+=1
	while (klist_z[i]==kz_start)
	kz_delta=klist_z[i]-kz_start
	kz_start/=klist_m[0]
	kz_delta/=klist_m[0]
	Nb_k=i
	k_start=dimoffset(band1,0)
	k_delta=dimdelta(band1,0)
	Nb_kz=dimsize(klist_z,0)/Nb_k

Make/O/N=(Nb_k,Nb_kz) band2D
Setscale/P x k_start,k_delta, band2D
Setscale/P y kz_start,kz_delta, band2D

variable indice=1
string name
name="band"+num2str(indice)
do
	Duplicate/O $name band1D
	//band2D=band1D[1+p+q*Nb_k]
	band2D=band1D[p+q*Nb_k]
	name="KzBand_"+num2str(indice)
	Duplicate/O band2D $name
	indice+=1
	name="band"+num2str(indice)
while(exists(name)==1)
Killwaves band1D,band2D

string/G Nameroot
NameRoot="Kzband_"
ExtractDispersion()
end

function Position(kx,ky)
variable kx,ky
//Return the number of point (kx,ky) in spaghetti plot
// This is indice_kx + Nb_X * indice_ky

variable FirstPoint=1 // Put 1 for old calculations

svar NameRoot
string name=NameRoot+"1"  // 2D wave from which dispersions are extracted
variable Nb_X=DimSize($name,0)

variable indice_kx,indice_ky
indice_kx=round((kx-dimoffset($name,0))/DimDelta($name,0))
indice_ky=round((ky-dimoffset($name,1))/DimDelta($name,1))

return indice_kx+Nb_x*indice_ky
end

////////////////////////////////////////////////////////////////////////////////////
Function ExtractDispersion()

// For all 2D bands in one folder named NameRoot1, 2...
// extract dispersion along one line

// First kill existing 2D plots
DoWindow/K Extract_Dispersion
DoWindow/K ShowDisp
DoWindow/K EXtract_contour

string/G Nameroot
string AskNameRoot=Nameroot
prompt AskNameRoot,"Name basis for 2D bands"
DoPrompt "Enter value" AskNameRoot

if (v_flag==0)
NameRoot=AskNameRoot
string name
		DoWindow/F Extract_Dispersion
		if (v_flag==0)
			Display/W=(20,20,350,350) 
			DoWindow/C Extract_Dispersion
			DoWindow/T Extract_Dispersion,"Extract_Dispersion"
		  	ControlBar 50		
 			variable/G kx1,ky1
 			variable/G kx2,ky2
	 		variable/G angle	
	 		variable/G BandIndex=1
	 		string/G mode="Two points"
		  	PopupMenu DefineLine,pos={1,1},size={68,21},title=" ",value= "Two points;Point & angle",proc=Select_LineMode
		  	SetVariable Kx1Box,pos={110,1},size={90,14},limits={-inf,inf,0.1}, proc=ChangeLine,title="kx1",value=kx1
	  		SetVariable Ky1Box,pos={210,1},size={90,14},limits={-inf,inf,0.1},proc=ChangeLine,title="ky1",value=ky1	
	  		SetVariable Kx2Box,pos={110,26},size={90,14},limits={-inf,inf,0.1},proc=ChangeLine,title="kx2",value=kx2
		  	SetVariable Ky2Box,pos={210,26},size={90,14},limits={-inf,inf,0.1},proc=ChangeLine,title="ky2",value=ky2
		  	//SetVariable AngleBox,pos={225,27},size={105,14},limits={-inf,inf,10},proc=ChangeLine_angle,title=" or angle : ",value=angle
		  	SetVariable BandBox,pos={343,1},size={80,18},limits={1,inf,1}, proc=ChangeBand,title="Band #",value=BandIndex
		  	Button ShowDisp pos={240,25},size={80,18},title="Dispersions",  proc=ShowDispersion
		       mode="point & angle"
		      execute "Select_LineMode(\"\",0,\""+mode+"\")"
		      
		  	// For contour
		  	string/G FolderName="none"
		  	//variable/G energy
			//variable/G eps=0.005
			//variable/G contour=0
		  	//SetVariable energyBox,pos={6,50},size={136,14},limits={-inf,inf,0.01}, proc=Calculate_Contour,title="Contour energy : ",value=energy
		  	//SetVariable epsBox,pos={150,50},size={100,14},limits={-inf,inf,0.002}, proc=Calculate_Contour,title="Delta : ",value=eps
  			Button Calculate_contour, pos={343,25},size={80,18},title="Contour",  proc=ExtractEnergyContour
  			//Button Save_contour, pos={370,50},size={80,18},title="Save",  proc=Save_Contour
  			
		  	name=NameRoot+num2str(BandIndex)
		  	Duplicate/O $name BandDisplay
		  	AppendImage BandDisplay
		  	ModifyImage BandDisplay ctab= {*,*,PlanetEarth,1}
		  	Make/O/N=2 line
		  	kx1=DimOffset($name,0)
		  	kx2=DimOffset($name,0)+DimDelta($name,0)*(DimSize($name,0)-1)
		  	ky1=DimOffset($name,1)
		  	ky2=ky1+DimDelta($name,1)*(DimSize($name,1)-1)/2
		  	ky2=ky1
			SetVariable Kx1Box,limits={kx1,kx2,dimdelta($name,0)}
			SetVariable Kx2Box,limits={kx1,kx2,dimdelta($name,0)}
			SetVariable Ky1Box,limits={ky1,DimOffset($name,1)+DimDelta($name,1)*(DimSize($name,1)-1),dimdelta($name,1)}
			SetVariable Ky2Box,limits={ky1,DimOffset($name,1)+DimDelta($name,1)*(DimSize($name,1)-1),dimdelta($name,1)}
			 
			Find_AB(name,kx1,ky1,(ky2-ky1)/(kx2-kx1))
		
		  	AppendToGraph line
		  	execute "ChangeLine(\"\",0,\"\",\"\")"
	  	 endif 	
	  	 ShowDispersion(" ")
	  	 DoWindow/F Extract_Dispersion
endif
end
///

Proc Select_LineMode(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
  
variable/G kx2,ky2,angle
   if (cmpstr(popstr,"Two points")==0)
	mode="Two points"
	PopupMenu DefineLine,mode=1
  	SetVariable Kx2Box,pos={110,26},size={90,14},limits={-inf,inf,0.1},proc=ChangeLine,title="kx2",value=kx2
  	SetVariable Ky2Box,pos={210,26},size={90,14},limits={-inf,inf,0.1},proc=ChangeLine,title="ky2",value=ky2
  	SetVariable AngleBox,pos={800,26},size={1,1},title=" "
    endif
  
     if (cmpstr(popstr,"Point & Angle")==0)
	mode="Point & Angle"
 	SetVariable AngleBox,pos={110,26},size={105,14},limits={-inf,inf,5},proc=ChangeLine_angle,title="     Angle : ",value=angle
	PopupMenu DefineLine,mode=2
	//Hide kx2 and ky2, not used in this mode
  	SetVariable Kx2Box,pos={810,26},size={1,1},title=" "
  	SetVariable Ky2Box,pos={810,26},size={1,1},title=" "
    endif
end
///
Macro ChangeBand(ctrlname,bidon,varStr,varName):SetVariableControl
	String Ctrlname
	Variable bidon
	string varStr
	string varName
	
variable/G BandIndex
variable/G contour
string name
name=NameRoot+num2str(BandIndex)
if (exists(name)==1)
	Duplicate/O $name BandDisplay
	if (contour==1)
		calculate_contour("",0,"","")
	endif
else
	BandIndex=1
	ChangeBand("",0,"","")
endif
end
////
Macro ChangeLine(ctrlname,bidon,varStr,varName):SetVariableControl
	String Ctrlname
	Variable bidon
	string varStr
	string varName
	
variable/G kx1,kx2,ky1,ky2,angle
variable slope
string name
string/G nameroot
	
	//name=WinName(0,1)
	//GetWindow $name,wavelist
	//print w_wavelist
	//name=w_wavelist[1][0]  // should be the name of 2D wave
	name=nameroot+"1"
	
	if (cmpstr(mode,"Two points")==0)	
		angle=atan((ky2-ky1)/(kx2-kx1))*180/pi
	
		if (kx1!=kx2)
			slope=(ky2-ky1)/(kx2-kx1)
		else
			slope=inf
		endif	
	else
		// uses angle value
		kx2=DimOffset($name,0)+DimDelta($name,0)*(DimSize($name,0)-1)
		if (kx1!=kx2)
			ky2=tan(angle*pi/180)*(kx2-kx1)+ky1
			slope=(ky2-ky1)/(kx2-kx1)
		else
			kx2=DimOffset($name,0)
			ky2=tan(angle*pi/180)*(kx2-kx1)+ky1
			slope=(ky2-ky1)/(kx2-kx1)
		endif	
	
	endif
	
	Find_AB(name,kx1,ky1,slope)
	
	name=name[0,strlen(name)-2]
	ExtractBandDisp(slope,kx1,ky1)
	string/G FolderName
	if (DataFolderExists(FolderName)==1)
		AddWeightDisp(FolderName)
	endif
	
end
///
Macro ChangeLine_angle(ctrlname,bidon,varStr,varName):SetVariableControl
	String Ctrlname
	Variable bidon
	string varStr
	string varName
//Line going through kx1,ky1 making an angle "angle" with x	
variable/G kx1,kx2,ky1,ky2,angle
variable slope
string name
string/G nameroot
	
	//name=WinName(0,1)
	//GetWindow $name,wavelist
	//name=w_wavelist[1][0]
	name=nameroot+"1"
		
	kx2=DimOffset($name,0)+DimDelta($name,0)*(DimSize($name,0)-1)
	if (kx1!=kx2)
		ky2=tan(angle*pi/180)*(kx2-kx1)+ky1
		slope=(ky2-ky1)/(kx2-kx1)
	else
		kx2=DimOffset($name,0)
		ky2=tan(angle*pi/180)*(kx2-kx1)+ky1
		slope=(ky2-ky1)/(kx2-kx1)
	endif	
	
	Find_AB(name,kx1,ky1,slope)

	name=name[0,strlen(name)-2]
	ExtractBandDisp(slope,kx1,ky1)
		string/G FolderName
	if (DataFolderExists(FolderName)==1)
		AddWeightDisp(FolderName)
	endif
end
///

Function ExtractBandDisp(slope,kx1,ky1)

variable slope,kx1,ky1
svar NameRoot

string name
name=NameRoot+"1"
variable Nb=DimSize($name,0) //Nb of points


// Define k along the slope. The origin is (kx1,ky1)
	variable kx_start,kx_stop,ky_start,ky_stop,kx_inc,ky_inc,delta_inc,k_start
	wave line
	kx_start=DimOffset(line,0)
	kx_stop=DimOffset(line,0)+DimDelta(line,0)
	ky_start=line[0]
	ky_stop=line[1]

	kx_inc=(kx_stop-kx_start)/(Nb-1)
	ky_inc=(ky_stop-ky_start)/(Nb-1)
	delta_inc=sqrt(kx_inc^2+ky_inc^2)
	k_start=-sqrt( (kx_start-kx1)^2 + (ky_start-ky1)^2 )  // always negative by definition

Make/O/N=(Nb) disp
SetScale/P x k_start,delta_inc,"", Disp

variable indice=1
variable cur,kx,ky

do  // loop on the different bands of the folder
	Duplicate/O $name band2D
	cur=0
	kx=kx_start
	ky=ky_start

	do
		disp[cur]=band2D[round((kx-DimOffset(band2D,0))/DimDelta(band2D,0))][round((ky-DimOffset(band2D,1))/DimDelta(band2D,1))]
		cur+=1
		kx=kx+kx_inc
		ky=ky+ky_inc
	while (cur<Nb)

	name=NameRoot+"_disp"+num2str(indice)
	Duplicate/O disp $name
	
	indice+=1	
	name=Nameroot+num2str(indice)

while (exists(name)==1)

	
DoWindow/F Extract_Dispersion
end

////

Function Find_AB(name,kx1,ky1,slope)
string name
variable kx1,ky1,slope
wave line
variable eps=1e-3
// Defines the two points A and B where "ky=slope*(kx-kx1)+ky1" intersects the image
	
	variable kx_start,kx_stop,ky_start,ky_stop
	kx_start=DimOffset($name,0)
	kx_stop=DimOffset($name,0)+DimDelta($name,0)*(DimSize($name,0)-1)
	ky_start=DimOffset($name,1)
	ky_stop=DimOffset($name,1)+DimDelta($name,1)*(DimSize($name,1)-1)
	
	
	variable kx_A,kx_B,ky_A,ky_B	
	
	if (slope==0)
		kx_A=kx_start
		kx_B=kx_stop
		ky_A=ky1
		ky_B=ky1
	endif
		
	if (slope>0)
		ky_A=ky_start
		kx_A=(ky_A-ky1)/slope+kx1
		if (kx_A<kx_start)
			kx_A=kx_start
			ky_A=slope*(kx_A-kx1)+ky1
		endif
	
		kx_B=kx_stop
		ky_B=slope*(kx_B-kx1)+ky1
		if (ky_B>ky_stop)
			ky_B=ky_stop
			kx_B=(ky_B-ky1)/slope+kx1
		endif	
	endif
	
	if (slope<0)
		kx_A=kx_start
		ky_A=slope*(kx_A-kx1)+ky1
		if (ky_A>ky_stop)
			ky_A=ky_stop
			kx_A=(ky_A-ky1)/slope+kx1
		endif
	
		ky_B=ky_start
		kx_B=(ky_B-ky1)/slope+kx1
		if (kx_B>kx_stop)
			kx_B=kx_stop
			ky_B=slope*(kx_B-kx1)+ky1
		endif	
	endif
	if (kx_A>kx_stop)
		kx_A=kx_stop
		ky_A=slope*(kx_A-kx1)+ky1
	endif	
	
	line[0]=ky_A
	line[1]=ky_B
	if (kx_A==kx_B)
		kx_B+=eps
	endif
	SetScale/I x kx_A,kx_B, line
end

/////

function Save_disp1(ctrlname):ButtonControl
	String Ctrlname

string NameForSave,name
prompt NameForSave,"Save as.."
DoPrompt "Enter value" NameForSave

variable i
string input_name,output_name
string/G Nameroot
if (v_flag==0)
	i=1
	do
		Input_name=Nameroot+"_disp"+num2str(i)
		Output_name=NameForSave+num2str(i)
		Duplicate/O $input_name $output_name
		i+=1
		Input_name=Nameroot+"_disp"+num2str(i)
	while (exists(input_name)==1)
endif

end

function ShowDispersion(ctrlname):ButtonControl
	String Ctrlname

variable indice
string name
svar NameRoot

DoWindow/F ShowDisp
if (v_flag==0)
	indice=1
	name=NameRoot+"_disp"+num2str(indice)
	Display/W=(360,20,700,350) 
	DoWindow/C ShowDisp
	DoWindow/T ShowDisp,"ShowDisp"
	ControlBar 30
	Button ShowImage pos={40,1},size={100,20},title="Show Image",  proc=ShowImage
	Button SaveDisp pos={160,1},size={100,20},title="Save Dispersions",  proc=Save_Disp1
	Button AddWeight pos={280,1},size={100,20},title="Add weight",  proc=AskAddWeightDisp
	do
		AppendToGraph $name
		indice+=1
		name=NameRoot+"_disp"+num2str(indice)
	while(exists(name)==1)
	CommonColorsButtonProc("")
	ModifyGraph zero(left)=1
	ModifyGraph fSize=16
	Legend/C/N=text0/A=MC
endif
end

function ShowImage(ctrlname):ButtonControl
	String Ctrlname

DoWindow/F Extract_Dispersion
end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function ExtractEnergyContour(ctrlname):ButtonControl
string ctrlname
svar NameRoot
// Creates Extract_contour window if does not exist and calculate contours again

string name=Nameroot+"_1"
DoWindow/F Extract_Contour
if (v_flag==0)
	Display/W=(350,200,700,500) 
	DoWindow/C Extract_Contour
	DoWindow/T Extract_Contour,"Extract_Contour"
  	ControlBar 50
	variable/G energy
	variable/G eps=0.005
  	SetVariable energyBox,pos={20,2},size={100,14},limits={-inf,inf,0.01}, proc=Calculate_Contour,title="Energy",value=energy
	string/G ModeContourType
	PopupMenu popup_ContourType,pos={20,22},size={100,16},popvalue="kx and kz",value="kx and kz;each kz",proc=Select_ModeContourType
  	//SetVariable epsBox,pos={200,6},size={140,14},limits={-inf,inf,0.002}, proc=Calculate_Contour,title="Delta energy",value=eps
	//SetVariable band_indexBox,pos={390,6},size={120,14},limits={0,inf,1},proc=Calculate_Contour,title="band index",value=band_index	
	//name=NameRoot+num2str(band_index)
	//Make/O/N=1 Contour_kx
	//SetScale/P x DimOffset($name,0),DimDelta($name,0),Contour_kx
	//Make/O/N=1 Contour_ky
	//SetScale/P y DimOffset($name,1),DimDelta($name,1),Contour_ky
	//AppendToGraph contour_ky vs contour_kx
	//SetAxis bottom DimOffset($name,0),DimOffset($name,0)+DimDelta($name,0)*(DimSize($name,0)-1)
	//SetAxis left DimOffset($name,1),DimOffset($name,1)+DimDelta($name,1)*(DimSize($name,1)-1)
	//ModifyGraph mode=4,marker=19
	Button ShowImage pos={130,1},size={80,20},title="Show Image",  proc=ShowImage
	//Button SaveDisp pos={160,1},size={100,20},title="Save Dispersions",  proc=Save_Disp1
	Button AddWeight pos={230,1},size={80,20},title="Add weight",  proc=AddWeightContour
	Button Nb_carriers pos={330,1},size={80,20},title="Nb carriers",  proc=NbCarriersWindow
	variable/G contour=0
endif
      
      Calculate_contour("",0,"","")

	// Plot contour of current band on the dispersion window
	DoWindow/F Extract_Dispersion
	RemoveFromGraph/Z contour_ky
      	AppendToGraph contour_ky vs contour_kx
      	ModifyGraph mode(contour_ky)=3,marker=19,msize=2
      contour=1
end

///

Proc Select_ModeContourType(ctrlName,popNum,popStr) : PopupMenuControl
String ctrlName
Variable popNum
String popStr
	string/G ModeContourType
	ModeContourType=popstr
	Calculate_contour("",0,"","")
end

////////

Function Calculate_contour(ctrlname,bidon,varStr,varName):SetVariableControl
	String Ctrlname
	Variable bidon
	string varStr
	string varName

string name,name_kx,name_ky
svar NameRoot,ModeContourType
nvar contour,bandIndex
variable i=1,Nb_temp	
name=NameRoot+num2str(i)
do
// loop on the different bands
	Duplicate/O $name temp2D
	Make/O/N=1 temp_kx,temp_ky
	temp_kx=NaN
	temp_ky=NaN
	
	// Calculate Contour by looking for crossing along all lines vertically and horizontally
	Calculate_contour_line(temp2D,i,0)  // along kx
	if (cmpstr(ModeContourType,"kx and kz")==0)
		duplicate/O temp_kx temp1
		duplicate/O temp_ky temp2
		Make/O/N=1 temp_kx,temp_ky
		temp_kx=NaN
		temp_ky=NaN
		calculate_contour_line(temp2D,i,1)  // along ky
		Nb_temp=DimSize(temp_kx,0)
		Redimension/N=(dimsize(temp1,0)+Dimsize(temp_kx,0)) temp_kx,temp_ky
		//edit temp1,temp2,temp_kx,temp_ky
		temp_kx[DimSize(temp_kx,0)-DimSize(temp1,0),DimSize(temp_kx,0)]=temp2[p-Nb_temp]
		temp_ky[DimSize(temp_kx,0)-DimSize(temp1,0),DimSize(temp_kx,0)]=temp1[p-Nb_temp]
		Sort temp_kx temp_ky,temp_kx
		name="contour_"+num2str(i)+"_kx"
		duplicate/O temp_ky $name
		name="contour_"+num2str(i)+"_ky"
		duplicate/O temp_kx $name
	else
		name="contour_"+num2str(i)+"_ky"
		duplicate/O temp_ky $name
		name="contour_"+num2str(i)+"_kx"
		duplicate/O temp_kx $name
	endif
	Killwaves temp1,temp2
	
	// Calculate contour through window
	//Calculate_contour_window(temp2D,i)
	Killwaves temp_kx,temp_ky,temp2D

	name_kx="contour_"+num2str(i)+"_kx"
	name_ky="contour_"+num2str(i)+"_ky"
	if (i==BandIndex)
		Duplicate/O $name_kx contour_kx
		Duplicate/O $name_ky contour_ky
	endif
//	if (contour==0)
		// Plot in contour window
		// Why is there this if condition ??? Sometimes does not refresh contour properly with the condition.
		DoWindow/F Extract_Contour
		RemoveFromGraph/Z $name_ky
		AppendToGraph $name_ky vs $name_kx
	      	ModifyGraph mode($name_ky)=3,marker=19,msize=2
	      	CommonColorsButtonProc("")
	      	Legend/C/N=text0/A=MC
//	endif
	i+=1
	name=NameRoot+num2str(i)
while(exists(name)==1)	

	DoWindow/F Extract_Dispersion
	if (ItemsInlist(Wavelist("contour_ky",";",""))==0)
		AppendToGraph contour_ky vs contour_kx
		ModifyGraph mode(contour_ky)=3,marker=19,msize=2
	endif	
	DoWindow NbCarriers
	if (v_flag==1)
		variable/G ModeContour
		execute "Select_ModeContour(\"\",ModeContour,\"\")"
	endif
end
/////////
Function Calculate_contour_window(temp2D,i)
	wave temp2D
	Variable i
// For band i, save crossing in contour_i_kx and contour_i_ky all points between E-dE and E+dE

svar NameRoot
nvar energy,eps

Make/O/N=1 temp_kx,temp_ky
temp_kx=NaN
temp_ky=NaN

variable index,kx,ky
index=0
kx=0
do
	ky=0
	do
		if (temp2D[kx][ky]<(energy+eps) && temp2D[kx][ky]>(energy-eps)) 
			temp_kx[index]=DimOffset(temp2D,0)+kx*DimDelta(temp2D,0)
			temp_ky[index]=DimOffset(temp2D,1)+ky*DimDelta(temp2D,1)
			index+=1
			Redimension/N=(index+1) temp_kx,temp_ky
		endif
		ky+=1
	while(ky<DimSize(temp2D,1))
	kx+=1
while (kx<DimSize(temp2D,0))

Redimension/N=(index) temp_kx,temp_ky
	
string name
name="contour_"+num2str(i)+"_kx"
duplicate/O temp_kx $name
name="contour_"+num2str(i)+"_ky"
duplicate/O temp_ky $name

end

////////
Function Calculate_contour_line(temp2D,i,HorV)
wave temp2D
variable i
variable HorV // 0 per horizontal line and 1 per vertical line

// For each line, save crossing in contour_i_kx and contour_i_ky 
// Looks for multiple crossings 

svar NameRoot
nvar energy
variable start,stop,index_ky
wave temp_kx,temp_ky // created temporary in calculate_contour

start=DimOffset(temp2D,HorV)
stop=DimOffset(temp2D,HorV)+DimDelta(temp2D,HorV)*(DimSize(temp2D,HorV)-1)
Make/O/N=(DimSize(temp2D,HorV)) temp1D
SetScale/P x DimOffset(temp2D,HorV),DimDelta(temp2D,HorV),"", temp1D


index_ky=0
variable cur=DimSize(temp_kx,0)-1
variable crossing=0
do
	start=DimOffset(temp2D,HorV)
	if (HorV==0)
		temp1D=temp2D[p][index_ky]-energy
	else
		temp1D=temp2D[index_ky][p]-energy
	endif
	
	do
		crossing=FindEfCrossings(temp1D,start,stop)
		if (crossing*0==0)	
			//i.e. not NaN, then save crossing values
			temp_kx[cur]=crossing
			temp_ky[cur]=Dimoffset(temp2D,mod(HorV+1,2))+index_ky*DimDelta(temp2D,mod(HorV+1,2))
			//print "i,HorV,index_ky,cur,temp_kx[cur],temp_ky[cur]",i,HorV,index_ky,cur,temp_kx[cur],temp_ky[cur]
			start=crossing+DimDelta(temp1D,0)
			Redimension/N=(DimSize(temp_kx,0)+1) temp_kx,temp_ky
			cur+=1
		endif	
	while (crossing*0==0 && start<stop)	

	index_ky+=1
while (index_ky<DimSize(temp2D,mod(HorV+1,2)))

Redimension/N=(DimSize(temp_kx,0)-1) temp_kx,temp_ky

Killwaves temp1D
end

////////////////////////////////////   Weights

function AskAddWeightDisp(ctrlname):ButtonControl
string ctrlname

// Uses this to find weights along contour
// The weights must be in waves weight1, weight2... from folder given below

string/G FolderName
string FolderNameL=FolderName
prompt FolderNameL,"Name of folder containing weights.."
DoPrompt "Enter value" FolderNameL
FolderName=FolderNameL

if (v_flag==0)
	AddWeightDisp(FolderName)
endif
end
////

function AddWeightDisp(FolderName)
string FolderName
// Uses this to find weights along contour
// The weights must be in waves weight1, weight2... from folder given below

DoWindow/F ShowDisp
variable band_index=1
variable i, indice
wave line

string name,name1
// Look for weight_min and weight_max 
variable weight_min=0,weight_max=0
indice=1
do
	name1=":"+FolderName+":weight"+num2str(indice)
	weight_max=max(wavemax($name1),weight_max)
	weight_min=min(wavemin($name1),weight_min)
	indice+=1
	name1="weight"+num2str(indice)
while  (exists(name1)==1)

//Calculate kx and ky along the profile

svar NameRoot
name=Nameroot+"_disp"+num2str(band_index)
Duplicate/O $name kx,ky
if (DimDelta(line,0)>1e-6)
	kx=dimoffset(line,0)+DimDelta(line,0)/(Dimsize($name,0)-1)*p
	ky=(line[1]-line[0])/DimDelta(line,0)*(kx[p]-Dimoffset(line,0))+line[0]
else
	kx=dimoffset(line,0)
	ky=line[0]+p*line[1]/(DimSize($name,0)-1)
endif	

if (DataFolderExists(FolderName)==1)
do
	name=Nameroot+"_disp"+num2str(band_index)
	Duplicate/O $name tmp_weight
	name1=":"+FolderName+":weight"+num2str(band_index)
	Duplicate/O $name1 OriginalWeight

	// In original spaghetti plot, the point (x,y) had number : indice_x + (indice_y*Nb_X)
	tmp_weight=OriginalWeight[Position(kx[p],ky[p])]   
	
	name1="DispWeight"+num2str(band_index)
	Duplicate/O tmp_weight $name1
	ModifyGraph mode($name)=3,marker($name)=19
	ModifyGraph zmrkSize($name)={$name1,Weight_min,weight_max,0,5}
	
	band_index+=1
	name=Nameroot+"_disp"+num2str(band_index)
while (exists(name)==1)
	else // FolderName does not exist
do
	name=Nameroot+"_disp"+num2str(band_index)
	ModifyGraph mode($name)=0
	band_index+=1
	name=Nameroot+"_disp"+num2str(band_index)
while (exists(name)==1)
endif
	
//Killwaves tmp_contourX,tmp_contourY,tmp_weight,OriginalWeight
//SetDataFolder folder
end

////

function ExtractBandDispAndWeight(p_wave,band_index_wave,OutputWaveName,OrbitalCharacter)
wave p_wave,band_index_wave
string OutputWaveName,OrbitalCharacter
// Input : 2 waves with positions (p_wave) corresponding to which band index (band_index_wave)
//		OrbitalCharacter must be the name of a subfolder with weights
//		Bands in main directory will have a name : BandNameRoot+number	
//Output : Band dispersion extracted from the previous waves (named OutputWaveName)
// 		Weight for the orbital character along this dispersion

// Exemple : ExtractBandDispAndWeight(p_dxz_hole,IndexBand_dxz_hole,"Disp_dxz_holes","dxz")

// Now : writen for Kz plots. To be generalized.
string BandNameRoot="Kzband__disp"

string name,name1
variable index, indice_start,indice_stop,indice_kz
wave line

name=BandNameRoot+"1"
Duplicate/O $name Newband,NewWeight
indice_kz=line[0]/DimDelta(KzBand_1,1)*DimSize(KzBand_1,0)  // index for first point in the considered profile

indice_start=0
index=0
	do
		indice_stop=p_wave[index]
		name=BandNameRoot+num2str(band_index_wave[index])
		duplicate/O $name AuxBand
		Newband[indice_start,indice_stop]=AuxBand[p]
		// Le suivant est simple mais ne marche que quand la fenêtre a été actualisée
		//name="DispWeight"+num2str(band_index_wave[index])
		name1=":"+OrbitalCharacter+":weight"+num2str(band_index_wave[index])
		duplicate/O $name1 AuxWeight
		NewWeight[indice_start,indice_stop]=AuxWeight[p+indice_kz]
		indice_start=indice_stop+1
		index+=1
	while (index<DimSize(p_wave,0))

Duplicate/O Newband $OutputWaveName
name="Weight_"+OrbitalCharacter+"_"+OutputWaveName
Duplicate/O NewWeight $name
Killwaves NewBand,NewWeight,AuxBand,AuxWeight
end

/////

Macro PartialWeights(p_wave,band_index_wave,OutputWaveName)
string p_wave,band_index_wave
string OutputWaveName
// p_wave : index jusqu'où on veut sélectionner la bande #band_index_wave

string OrbitalCharacter,name
OrbitalCharacter="dxz"
ExtractBandDispAndWeight($p_wave,$band_index_wave,OutputWaveName,OrbitalCharacter)
name="Weight_"+OrbitalCharacter+"_"+OutputWaveName
Display $name

//OrbitalCharacter="dyz"
//ExtractBandDispAndWeight($p_wave,$band_index_wave,OutputWaveName,OrbitalCharacter)
//name="Weight_"+OrbitalCharacter+"_"+OutputWaveName
//AppendToGraph $name
//ModifyGraph rgb($name)=(0,65280,0)

OrbitalCharacter="dxy"
ExtractBandDispAndWeight( $p_wave,$band_index_wave,OutputWaveName,OrbitalCharacter)
name="Weight_"+OrbitalCharacter+"_"+OutputWaveName
AppendToGraph $name
ModifyGraph rgb($name)=(0,15872,65280)

//OrbitalCharacter="dx2my2"
//ExtractBandDispAndWeight( $p_wave,$band_index_wave,OutputWaveName,OrbitalCharacter)
//name="Weight_"+OrbitalCharacter+"_"+OutputWaveName
//AppendToGraph $name
//ModifyGraph rgb($name)=(0,0,0)

OrbitalCharacter="dz2"
ExtractBandDispAndWeight( $p_wave,$band_index_wave,OutputWaveName,OrbitalCharacter)
name="Weight_"+OrbitalCharacter+"_"+OutputWaveName
AppendToGraph $name
ModifyGraph rgb($name)=(65280,16384,55552)

Legend/C/N=text0/A=MC
ModifyGraph lsize=1.5
end

///

function IntegrateBandWeight()
variable energy_start,energy_stop
variable k_start,k_stop
// Work on dispersion window when a weight is chosen (from FolderName)
// Gives the integrated value for the chosen band with respect to zero and for the plotted k scale
//
	prompt energy_start,"Between energy "
	prompt energy_stop," and energy "
//	prompt k_start,"Between energy "
//	prompt k_stop,"Between energy "
	DoPrompt "Calculate weight..." energy_start,energy_stop
if (v_flag==0)
svar FolderName
string name_weight,name_disp,name_disp_prefix
variable band_index=1
variable WeightSum=0,weightAll=0
variable index

if (DataFolderExists(FolderName)==1)
name_weight="DispWeight"+num2str(band_index)
name_disp_prefix="KxKyband__disp"
name_disp=name_disp_prefix+num2str(band_index)
do
	Duplicate/O $name_weight temp_weight
	Duplicate/O $name_disp temp_disp
	index=0
	do
		if (temp_disp[index]>energy_start && temp_disp[index]<energy_stop)
			WeightSum+=temp_weight[index]
		endif
		WeightAll+=temp_weight[index]
		index+=1
	while (index<DimSize(temp_weight,0))
	
	band_index+=1
	name_weight="DispWeight"+num2str(band_index)
	name_disp=name_disp_prefix+num2str(band_index)
while (exists(name_weight)==1)
Killwaves temp_weight,temp_disp
print "Total weight in ",FolderName, "= ",WeightAll
print "Weight in energy window =",WeightSum," ratio :",WeightSum/WeightAll
else
abort "No folder defined for weights"
endif
endif
end

/////////////////

function IntegrateBandWeight_FS(energy_start,energy_stop)
variable energy_start,energy_stop
// Work on an entire image : integrates everything in the energy window from weight1, weight2, etc.
// Must be in the folder with the wanted waves weight1,....

	string name_weight,name_disp,name_disp_prefix
	variable band_index=1
	variable WeightSum=0,weightAll=0
	variable index

	name_weight="Weight"+num2str(band_index)
	name_disp="band"+num2str(band_index)
	do
		Duplicate/O $name_weight temp_weight
		Duplicate/O $name_disp temp_disp
		index=0
		do
			if (temp_disp[index]>energy_start && temp_disp[index]<energy_stop)
				WeightSum+=temp_weight[index]-0.07
			endif
			WeightAll+=temp_weight[index]-0.07
			index+=1
		while (index<DimSize(temp_weight,0))
	
		band_index+=1
		name_weight="Weight"+num2str(band_index)
		name_disp="Band"+num2str(band_index)
	while (exists(name_weight)==1)
	Killwaves temp_weight,temp_disp
	print "Total weight = ",WeightAll
	print "Weight in energy window =",WeightSum," Nb electron :",WeightSum/WeightAll*2

end


/////////////////
function AddWeightContour(ctrlname):ButtonControl
string Ctrlname
// In original spaghetti plot, the point (x,y) had number : indice_x + (indice_y*Nb_X)
// Uses this to find weights along contour
// The weights must be in waves weight1, weight2... from folder given below

svar FolderName
string FolderNameL=FolderName
prompt FolderNameL,"Name of folder containing weights.."
DoPrompt "Enter value" FolderNameL
FolderName=FolderNameL
variable indice
string name1
if (v_flag==0)

if (cmpstr(FolderName,"none")==0)
	indice=1
	do
	name1="contour_"+num2str(indice)+"_ky"
	ModifyGraph mode($name1)=0
	indice+=1
	name1="contour_"+num2str(indice)+"_ky"
while  (exists(name1)==1)
	
else
//string folder=GetDataFolder(1)
//SetDataFolder FolderName

// Look for weight_min and weight_max 
variable weight_min=0,weight_max=0
indice=1
do
	name1=":"+FolderName+":weight"+num2str(indice)
	weight_max=max(wavemax($name1),weight_max)
	weight_min=min(wavemin($name1),weight_min)
	indice+=1
	name1="weight"+num2str(indice)
while  (exists(name1)==1)

string/G NameRoot
string name=NameRoot+"1"
variable Nb_X=DimSize($name,0)
variable band_index=1
variable i
do
	name="contour_"+num2str(band_index)+"_kx"
	Duplicate/O $name tmp_contourX
	name="contour_"+num2str(band_index)+"_ky"
	Duplicate/O $name tmp_contourY
	Duplicate/O $name tmp_weight
	name=":"+FolderName+":weight"+num2str(band_index)
	Duplicate/O $name OriginalWeight

	i=0
	do
		tmp_weight[i]=OriginalWeight[Position(tmp_contourX[i],tmp_contourY[i])]  
		i+=1
	while(i<dimsize(tmp_contourX,0))
	name1="ContourWeight"+num2str(band_index)
	Duplicate/O tmp_weight $name1
	name1="ContourWeight"+num2str(band_index)
	Duplicate/O tmp_weight $name1
	name="contour_"+num2str(band_index)+"_ky"
	ModifyGraph mode($name)=3,marker($name)=19
	ModifyGraph zmrkSize($name)={$name1,Weight_min,weight_max,0,5}
	
	band_index+=1
	name="contour_"+num2str(band_index)+"_kx"
while (exists(name)==1)

Killwaves tmp_contourX,tmp_contourY,tmp_weight,OriginalWeight
//SetDataFolder folder
endif
endif

end

////////////////////////////////////////////////////////

function Save_contour(ctrlname):ButtonControl
	String Ctrlname

string NameForSave,name
prompt NameForSave,"Save as.."
DoPrompt "Enter value" NameForSave

if (v_flag==0)
	name=NameForSave+"_kx"
	Duplicate/O contour_kx $name
	name=NameForSave+"_ky"
	Duplicate/O contour_ky $name
endif
end

////////////////////////////////////////////////////////////////

Function FindEfCrossings(BandName,start,stop)
wave BandName  // 1D wave
variable start,stop
variable indice,indice_stop,x_crossing,g
indice=round((start-DimOffset(bandName,0))/DimDelta(BandName,0))
indice_stop=round((stop-DimOffset(bandName,0))/DimDelta(BandName,0))
x_crossing=NaN
do
	g=BandName[indice]*BandName[indice+1]
	if (BandName[indice]*BandName[indice+1]<0)
		x_crossing=indice+abs(BandName[indice])/abs(BandName[indice+1]-BandName[indice])
		x_crossing=DimOffset(BandName,0)+x_crossing*DimDelta(BandName,0)
		//print "crossing at ",x_crossing
		break
	endif
	indice+=1
while(indice<indice_stop)
return x_crossing
end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Procedure to extract disp at constant photon energy : Disp_variableKz()
proc Disp_variableKz(Photon,k_start,k_end)
variable Photon,k_start,k_end
// Original waves are KzBand_xxx
// k must be positive
// if k_end> k in KzBand : takes reduced kx value

	variable Nb,kdata_end,i_ks
	string name="KzBand_1"
	if (exists(name)==0)
		abort "No such wave"
	endif
	i_ks= IndexOf(k_start,name,0)  // index for start in demanded disp
	Nb=round((k_end-k_start)/DimDelta($name,0))
	Make/O/N=(Nb) Kz_ph,index_ph
	SetScale/P x k_start,DimDelta($name,0), Kz_ph,index_ph
	Kz_ph=Kperp(photon,k_start+p*DimDelta($name,0))
	index_ph=IndexOf(Kz_ph[p],name,1)

	string name2
	variable band_index=1
	variable i
	do
		Duplicate/O $name, temp2D
		Make/O/N=(Nb) temp
		SetScale/P x k_start,DimDelta($name,0), temp
		// temp=temp2D(kx)(kz(kx))
		temp[0,DimSize($name,0)-1-i_ks]=temp2D[p+i_ks][index_ph[p]]
		// same as above with linear extrapolation
		//temp[0,DimSize($name,0)-1-i_ks]=(index_ph[p]-trunc(index_ph[p]))*temp2D[p+i_ks][trunc(index_ph[p])]+(trunc(index_ph[p]+1-index_ph[p]))*temp2D[p+i_ks][trunc(index_ph[p])+1]
		
		temp[DimSize($name,0)-i_ks,DimSize(temp,0)]=temp2D[2*DimSize($name,0)-p-i_ks][IndexOf(Kperp(photon,k_start+p*DimDelta($name,0)),name,1)]
		name2=name+"_ph"
		Duplicate/O temp $name2
		band_index+=1
		name="KzBand_"+num2str(band_index)
	while (exists(name)==1)
	Killwaves temp
end

function Kperp(photon, kpara)
variable photon,kpara
	variable W=4.2
	variable V0=14
	variable c=6.5
	variable kperp,kz
	
	kperp=sqrt(0.512^2*(photon-W+V0)-kpara^2)
	kz=kperp/(pi/c)-2*trunc(kperp/(2*pi/c))  // kperp in units of pi/c
	if (kz>1)
		kz=2-kz
	endif
	return kz
	
end

function IndexOf(number,name,dim)
// It does extrapolate if index is not an integer for 1D wave but not 2D wave
variable number
string name
variable dim
variable p_ind
p_ind=(number-DimOffset($name,dim))/DimDelta($name,dim)
return p_ind
end

//////////////////////////////////////

Proc Symetrization()
string name_kx,name_ky
variable k0
variable indice=1
do
name_kx="contour_"+num2str(indice)+"_kx"
name_ky="contour_"+num2str(indice)+"_ky"
if (DimSize($name_kx,0)>1)
	if (indice<7)
		//Holes : sym with respect to zero
		//Sym with repect to ky=0
		Redimension/N=(DimSize($name_kx,0)*2) $name_kx,$name_ky
		$name_ky[DimSize($name_ky,0)/2,DimSize($name_ky,0)-1]=$name_ky[DimSize($name_ky,0)-p-1]
		$name_kx[DimSize($name_kx,0)/2,DimSize($name_kx,0)-1]=-$name_kx[DimSize($name_kx,0)-p-1]
		//Sym with repect to kx=0
		Redimension/N=(DimSize($name_kx,0)*2) $name_kx,$name_ky
		$name_ky[DimSize($name_ky,0)/2,DimSize($name_ky,0)-1]=-$name_ky[DimSize($name_ky,0)-p-1]
		$name_kx[DimSize($name_kx,0)/2,DimSize($name_kx,0)-1]=$name_kx[DimSize($name_kx,0)-p-1]
	endif
	if (indice>6)
		//Electrons : sym with respect to corner
		Redimension/N=(DimSize($name_kx,0)*2) $name_kx,$name_ky
		//k0=pi/3.7914
		k0=sqrt(2)*pi/3.962
		$name_kx[DimSize($name_kx,0)/2,DimSize($name_kx,0)-1]=$name_kx[DimSize($name_kx,0)-p-1]
		//$name_ky[DimSize($name_ky,0)/2,DimSize($name_ky,0)-1]=2*k0-$name_ky[DimSize($name_ky,0)-p-1]
		$name_ky[DimSize($name_ky,0)/2,DimSize($name_ky,0)-1]=-$name_ky[DimSize($name_ky,0)-p-1]
		Redimension/N=(DimSize($name_kx,0)*2) $name_kx,$name_ky
		$name_kx[DimSize($name_kx,0)/2,DimSize($name_kx,0)-1]=2*k0-$name_kx[DimSize($name_kx,0)-p-1]
		$name_ky[DimSize($name_ky,0)/2,DimSize($name_ky,0)-1]=$name_ky[DimSize($name_ky,0)-p-1]
	endif
	
endif
indice+=1
name_kx="contour_"+num2str(indice)+"_kx"
name_ky="contour_"+num2str(indice)+"_ky"
while (exists(name_kx)==1)
end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////		Nb Carriers

function	CallSeparateContour()
// Window
	DoWindow/F SeparateContour
	if (v_flag==0)
		NewPanel /W=(10,550,550,700)
		DoWindow/C ExtractContour
		DoWindow/T ProcessPanel "Extract points from one contour"
		
		PopupMenu popup_ChooseWave1,pos={250,10},size={200,16},popvalue="- none -",value=WaveList("*",";","DIMS:1")+"-none-"
		PopupMenu popup_ChooseWave2,pos={250,40},size={200,16},popvalue="- none -",value=WaveList("*",";","DIMS:1")+"-none-",noproc
		PopupMenu popup_ChooseWave3,pos={250,70},size={200,16},popvalue="- none -",value=WaveList("*",";","DIMS:1")+"-none-",noproc
		string/G res
		SetVariable set_Result,pos={50,110},size={320,26},title="Separate contours :    ",value=res,limits={-Inf,Inf,1}
	endif
	/////////////
end

function SeparateContour(kx_wave,ky_wave,indice_wave_name)
wave kx_wave,ky_wave
string indice_wave_name
	// contour defined by kx_wave and ky_wave
	// Put points in indice_wave in temp1_kx
	// the others in temp2_ky
	
	variable index_contour,index_indice,index_temp1,index_temp2
	if (Exists(indice_wave_name)==1)
		//Separate contours from indice_wave
		Duplicate/O $indice_wave_name temp
		Make/O /N=(dimsize(temp,0)) temp1_kx,temp1_ky
		Make/O /N=(dimsize(ky_wave,0)-dimsize(temp,0)) temp2_kx,temp2_ky
		index_contour=0
		index_indice=0
		index_temp1=0
		index_temp2=0
		do
		if (temp[index_indice]==index_contour)
			temp1_kx[index_temp1]=kx_wave[index_contour]
			temp1_ky[index_temp1]=ky_wave[index_contour]
			index_temp1+=1
			index_indice+=1
		else
			temp2_kx[index_temp2]=kx_wave[index_contour]
			temp2_ky[index_temp2]=ky_wave[index_contour]
			index_temp2+=1
		endif
		index_contour+=1
		while (index_contour<DimSize(kx_wave,0))
	endif
end

/////////////////////////////////////////////////////////////

function IntegrateContourByArea(kx_wave,ky_wave,indice_wave_name)
wave kx_wave,ky_wave
string indice_wave_name
	// contour defined by kx_wave and ky_wave
	// In case it is non monotonous, calculate area of contour points in indice_wave and substract area of others	
	//Normalized by side^2 (enter below)
	
	variable side=0.5
	variable aire
	if (Exists(indice_wave_name)==1)
		//Separate contours from indice_wave
		SeparateContour(kx_wave,ky_wave,indice_wave_name)
		//Calculate the area (needs monotonic values for x)
		Sort temp1_kx temp1_ky,temp1_kx
		Sort temp2_kx temp2_ky,temp2_kx
		aire=(areaXY(temp1_kx,temp1_ky)-areaXY(temp2_kx,temp2_ky))/side^2
	else	
		Sort kx_wave kx_wave,ky_wave
		aire=areaXY(kx_wave,ky_wave)/side^2
	endif
	print "aire=",aire
	return aire
end
//////
Proc Select_Wave(ctrlName,popNum,popStr) : PopupMenuControl
String ctrlName
Variable popNum
String popStr
	variable/G ModeContour
	string/G Wave1=popstr
 	if (ModeContour==1)
		Calculate_NbCarriers_Circles()
	endif
	if (ModeContour==2)
		Calculate_NbCarriers_Ellipse122()
	endif
	if (ModeContour==3)
		Calculate_NbCarriers_Ellipse111()
	endif
end	

//////////////////////////////////////////////
Proc Calculate_NbCarriers()
// enter below the value of a and the name of the hole and electron contours
// this procedures assumes circular electron pockets and elliptic electron pockets
// the contour should have one kx value for each ky value (choose both=0 in calculate_contour)
// It will only work for odd number of points in contour !!

variable a  // put a=pi here if contours are in units of pi/a
a=3.966
//a=pi
variable BZ_area
BZ_area=(2*pi/a)^2 
string system="122" // changes the way electrons are integrated
variable i=0

variable Nb_hole1,Nb_hole2,Nb_hole3,Nb_hole
//enter here the names of the 3 hole contours (remove one if only 2)
Duplicate/O contour_3_kx contour_hole1_kx
Duplicate/O contour_4_kx contour_hole2_kx
//Duplicate/O contour_12_kx contour_hole3_kx
variable NbPnts=Dimsize(contour_hole1_kx,0)



do
	Nb_hole1+=contour_hole1_kx[i]^2
	Nb_hole2+=contour_hole2_kx[i]^2
//	Nb_hole3+=contour_hole3_kx[i]^2
	
	i+=1
while (i<NbPnts)

Nb_hole1/=NbPnts
Nb_hole2/=NbPnts
Nb_hole3/=NbPnts

Nb_hole1=pi*Nb_hole1/BZ_area  // times 2 for the spin and divided by 2 per Fe
Nb_hole2=pi*Nb_hole2/BZ_area
//Nb_hole3=pi*Nb_hole3/BZ_area
//Nb_hole=Nb_hole1+Nb_hole2+Nb_hole3
Nb_hole=Nb_hole1+Nb_hole2

variable Nb_elec1,Nb_elec2,Nb_elec,diag
//enter here the names of the 2 electron contours 
// Assumes it forms an ellispe : multiplies the two
Duplicate/O contour_6_kx contour_elec1_kx
Duplicate/O contour_7_kx contour_elec2_kx///

if (cmpstr(system,"111")==0)
	NbPnts=Dimsize(contour_elec1_kx,0)
	diag=sqrt(2)*pi/a // kF value is computed with respect to X
	i=0
	do
		Nb_elec1+=(diag-contour_elec1_kx[i])*(diag-contour_elec1_kx[i])
		//	Nb_elec2+=(diag-contour_elec2_kx[i])*(diag-contour_elec2_kx[NbPnts-1-i])
		i+=1
	while (i<NbPnts)
	Nb_elec1*=2
	//Nb_elec2*=2
	//Nb_elec1+=(diag-contour_elec1_kx[(NbPnts-1)/2])*(diag-contour_elec1_kx[(NbPnts-1)/2])
	//Nb_elec2+=(diag-contour_elec2_kx[(NbPnts-1)/2])*(diag-contour_elec2_kx[(NbPnts-1)/2])
	Nb_elec1/=NbPnts
	Nb_elec2/=NbPnts
	Nb_elec1=pi*Nb_elec1/BZ_area  // times 2 for the spin and divided by 2 per Fe
	//Nb_elec2=pi*Nb_elec2/BZ_area
	Nb_elec=Nb_elec1//+Nb_elec2
else
	NbPnts=Dimsize(contour_elec1_kx,0)
	diag=sqrt(2)*pi/a // kF value is computed with respect to X
	i=0
	do
		Nb_elec1+=(diag-contour_elec1_kx[i])*(diag-contour_elec1_kx[NbPnts-1-i])
		Nb_elec2+=(diag-contour_elec2_kx[i])*(diag-contour_elec2_kx[NbPnts-1-i])
		i+=1
	while (i<(NbPnts-1)/2)
	Nb_elec1*=2
	Nb_elec2*=2
	Nb_elec1+=(diag-contour_elec1_kx[(NbPnts-1)/2])*(diag-contour_elec1_kx[(NbPnts-1)/2])
	Nb_elec2+=(diag-contour_elec2_kx[(NbPnts-1)/2])*(diag-contour_elec2_kx[(NbPnts-1)/2])
	Nb_elec1/=NbPnts
	Nb_elec2/=NbPnts
	Nb_elec1=pi*Nb_elec1/BZ_area  // times 2 for the spin and divided by 2 per Fe
	Nb_elec2=pi*Nb_elec2/BZ_area
	Nb_elec=Nb_elec1+Nb_elec2
endif

print "Nb_holes, Nb_elec =",Nb_hole, Nb_elec
print "Nb_holes 1,2,3 =",Nb_hole1, Nb_hole2,Nb_hole3
end

//////////////////////////
Proc NbCarriersWindow(ctrlname):ButtonWindow
string ctrlname
// Integrate along kz one contours (for circles)
// or 2 (for ellipses)

	DoWindow/F NbCarriers
	if (v_flag==0)
		NewPanel /W=(10,550,550,700)
		DoWindow/C NbCarriers
		DoWindow/T ProcessPanel "Nb carriers"
		
		PopupMenu popup_type,pos={50,10},size={200,16},popvalue="- none -",value="1 contour (circular);2 contours (ellipse 122) ; 2 contours (ellipse 111)",proc=Select_ModeContour
		PopupMenu popup_ChooseWave1,pos={250,10},size={200,16},popvalue="- none -",value=WaveList("contour_*kx",";","DIMS:1")+"-none-",proc=Select_Wave1
		PopupMenu popup_ChooseWave2,pos={250,40},size={200,16},popvalue="- none -",value=WaveList("contour_*kx",";","DIMS:1")+"-none-",proc=Select_Wave2
		PopupMenu popup_ChooseWave3,pos={250,70},size={200,16},popvalue="- none -",value=WaveList("contour_*kx",";","DIMS:1")+"-none-",proc=Select_Wave3
		string/G res
		SetVariable set_Result,pos={50,110},size={320,26},title="Nb carriers :    ",value=res,limits={-Inf,Inf,1}
	endif
	
end
//////////////

/////////////
Proc Select_ModeContour(ctrlName,popNum,popStr) : PopupMenuControl
String ctrlName
Variable popNum
String popStr
	variable /G ModeContour
	ModeContour=popNum
	if (ModeContour==1)
		Calculate_NbCarriers_Circles()
	endif
	if (ModeContour==2)
		Calculate_NbCarriers_Ellipse122()
	endif
	if (ModeContour==3)
		Calculate_NbCarriers_Ellipse111()
	endif
end
//////
Proc Select_Wave1(ctrlName,popNum,popStr) : PopupMenuControl
String ctrlName
Variable popNum
String popStr
	variable/G ModeContour
	string/G Wave1=popstr
 	if (ModeContour==1)
		Calculate_NbCarriers_Circles()
	endif
	if (ModeContour==2)
		Calculate_NbCarriers_Ellipse122()
	endif
	if (ModeContour==3)
		Calculate_NbCarriers_Ellipse111()
	endif
end
/////
Proc Select_Wave2(ctrlName,popNum,popStr) : PopupMenuControl
String ctrlName
Variable popNum
String popStr

	string/G Wave2=popstr
	//Duplicate/O $popstr temp2_kx
	if (ModeContour==1)
		Calculate_NbCarriers_Circles()
	endif
	if (ModeContour==2)
		Calculate_NbCarriers_Ellipse122()
	endif
	if (ModeContour==3)
		Calculate_NbCarriers_Ellipse111()
	endif
end
/////
Proc Select_Wave3(ctrlName,popNum,popStr) : PopupMenuControl
String ctrlName
Variable popNum
String popStr

	string/G Wave3=popstr
	//Duplicate/O $popstr temp3_kx
	if (ModeContour==1)
		Calculate_NbCarriers_Circles()
	endif
	if (ModeContour==2)
		Calculate_NbCarriers_Ellipse122()
	endif
	if (ModeContour==3)
		Calculate_NbCarriers_Ellipse111()
	endif
end
/////////
function Calculate_NbCarriers_Circles()
// contour_kx copied in temp1_kx
// assumes there is one point per kz

variable BZ_area
variable a  // put a=pi here if contours are in units of pi/a
a=3.966
//a=pi
BZ_area=(2*pi/a)^2 

string/G wave1,wave2,wave3
if (cmpstr(wave1,"-none-")!=0)
	Duplicate/O $Wave1 temp1_kx
endif
if (cmpstr(wave2,"-none-")!=0)
	Duplicate/O $Wave2 temp2_kx
endif
if (cmpstr(wave3,"-none-")!=0)
	Duplicate/O $Wave3 temp3_kx
endif
variable Nb_hole
variable i=0
variable NbPnts
if (cmpstr(wave1,"-none-")!=0)
	NbPnts=Dimsize(temp1_kx,0)
	do
		Nb_hole+=temp1_kx[i]^2
		i+=1
	while (i<NbPnts)
endif	
if (cmpstr(wave2,"-none-")!=0)
	i=0
	NbPnts=Dimsize(temp2_kx,0)
	do
		Nb_hole+=temp2_kx[i]^2
		i+=1
	while (i<NbPnts)
endif
if (cmpstr(wave3,"-none-")!=0)
	i=0
	NbPnts=Dimsize(temp3_kx,0)
	do
		Nb_hole+=temp3_kx[i]^2
		i+=1
	while (i<NbPnts)
endif
//string NameRef=StringFromList(0,Wavelist("*",";","WIN:Extract_Dispersion,DIM:2"))
variable NbKz=Dimsize(BandDisplay,1)
Nb_hole/=NbKz

Nb_hole=pi*Nb_hole/BZ_area  // times 2 for the spin and divided by 2 per Fe
svar res
res=num2str(Nb_hole)
end

/////////////////////////
function Calculate_NbCarriers_Ellipse122()
// The 2 contours are copied in temp1_kx and temp2_kx
// The 2 sides of the ellipse are for different kz
// Calculation assumes there is one point per kz

variable BZ_area
variable a  // put a=pi here if contours are in units of pi/a
a=3.966
//a=pi
BZ_area=(2*pi/a)^2 

variable Nb_elec,Nb_elec1,Nb_elec2
string/G wave1,wave2
Duplicate/O $Wave1 temp1_kx
Duplicate/O $Wave2 temp2_kx

variable i=0
variable NbPnts,diag
	NbPnts=Dimsize(temp1_kx,0)
	diag=sqrt(2)*pi/a // kF value is computed with respect to X
	i=0
	do
		Nb_elec1+=(diag-temp1_kx[i])*(diag-temp2_kx[NbPnts-1-i])
		Nb_elec2+=(diag-temp2_kx[i])*(diag-temp1_kx[NbPnts-1-i])
		i+=1
	while (i<(NbPnts-1)/2)
	Nb_elec1*=2
	Nb_elec2*=2
	Nb_elec1+=(diag-temp1_kx[(NbPnts-1)/2])*(diag-temp2_kx[(NbPnts-1)/2])
	Nb_elec2+=(diag-temp1_kx[(NbPnts-1)/2])*(diag-temp2_kx[(NbPnts-1)/2])
	Nb_elec1/=NbPnts
	Nb_elec2/=NbPnts
	Nb_elec1=pi*Nb_elec1/BZ_area  // times 2 for the spin and divided by 2 per Fe
	Nb_elec2=pi*Nb_elec2/BZ_area
	Nb_elec=Nb_elec1+Nb_elec2

svar res
res=num2str(Nb_elec)
end

/////////////////////////

function Calculate_NbCarriers_Ellipse111()
// The 2 contours are copied in temp1_kx and temp2_kx
// The 2 sides of the ellipse are for the same kz
// Calculation assumes there is one point per kz

variable BZ_area
variable a  // put a=pi here if contours are in units of pi/a
a=3.966
//a=pi
BZ_area=(2*pi/a)^2 

variable Nb_elec
string/G wave1,wave2
Duplicate/O $Wave1 temp1_kx
Duplicate/O $Wave2 temp2_kx
variable i=0
variable NbPnts,diag
	NbPnts=Dimsize(temp1_kx,0)
	diag=sqrt(2)*pi/a // kF value is computed with respect to X
	i=0
	do
		Nb_elec+=(diag-temp1_kx[i])*(diag-temp2_kx[i])
		i+=1
	while (i<NbPnts)
	Nb_elec/=NbPnts
	Nb_elec=pi*Nb_elec/BZ_area  // times 2 for the spin and divided by 2 per Fe

svar res
res=num2str(Nb_elec)
end
////////////////////////

