#pragma rtGlobals=1		// Use modern global access method.
#include "LPS_Fitting_Functions"
//Fitting_EDC : fits the EDC stacks 


Proc Init_EDCWindow()
//-----------------

	DoWindow/F EDC_Fitting
	if (V_flag==0)
		NewDataFolder/O/S root:EDC
	
		PauseUpdate; Silent 1		// building window...
		NewPanel /W=(15,50,500,290)
		DoWindow/C EDC_Fitting
		DoWindow/T EDC_Fitting "Fitting EDC"
		ModifyPanel cbRGB=(0,43520,65280)
            
             
             Button LoadEDCline,pos={9,8},size={200,25},proc=Export_EDCline,title="Load EDC line from ImageTool"
		
		string/G FitFunc="LorTimesFermi",FitConstraint="none"
		variable/G Nb_lor=1
		 SetDrawLayer UserBack
   	   	DrawRect 8,42,223,102
		PopupMenu PopFunctions,pos={10,48},size={111,21},proc=SelectEDCFunction,title="Fitting Functions",popvalue="LorTimesFermi;", value="LorTimesFermi;GaussPlusParaboliBgd;TwoLinesTimesFermiPlusPolyBg;Fermi_meV"
		PopupMenu PopConstraints,pos={10,73},size={111,21},proc=SelectEDCConstraint,title="Constraints         ",popvalue="none", value="none;fixed Ef;fixed Fermi step;special"
		
		variable/G energy_start=round(DimOffset(root:IMG:image,0)*100)/100
		variable/G energy_end =round((energy_start+DimDelta(root:IMG:image,0)*(DimSize(root:IMG:image,0)-1))*100)/100
		SetVariable energy_start,pos={10,113},size={130,25},title="Energy   : start",limits={-Inf,Inf,0.01},value=energy_start
		SetVariable energy_end,pos={150,113},size={90,25},title="end",value=energy_end,limits={-Inf,Inf,0.01},value=energy_end
		variable/G Kx_start =round(DimOffset(root:IMG:image,1)*100)/100
		variable/G Kx_end =round(  (Kx_start+DimDelta(root:IMG:image,1)*(DimSize(root:IMG:image,1)-1)) *100)/100
		SetVariable Kx_start_box,pos={10,143},size={130,15},title="Kx         : start",limits={-Inf,Inf,0.01},value=Kx_start
		SetVariable Kx_end_box,pos={150,143},size={90,15},title="end",limits={-Inf,Inf,0.01},value=Kx_end

		Button FitEDCStacks,pos={36,192},size={200,30},proc=Fitting_EDC,title="Fit Stacks of ImageTool"
				
		//DrawText  300,20, "Take maximum from EDC"
		//DrawText  300,35, "(also available by mouse right click)"
		Button EDCBgd,pos={260,40},size={170,25},proc=Substract_EDCBgd_FromPannel,title="Substract EDC background"	
		Button LookForMaxButton,pos={260,70},size={170,25},proc=LookForMax,title="Look for max"
		Button AddMaxButton,pos={260,100},size={170,25},proc=AddMax,title="Add max to stacks"
	      
	      Button SaveResults,pos={311,192},size={116,30},proc=Save_resultsEDC,title="Save results"		
	endif
End


Proc SelectEDCFunction(ctrlName,popNum,popStr) : PopupMenuControl
//-----------------------------
	String ctrlName
	Variable popNum
	String popStr
	
	SetDataFolder "root:EDC"
	FitFunc=popStr
	Nb_lor=popNum//Not universal (for example, might want to fit with Gaussians), so should be changed some day
end

Proc SelectEDCConstraint(ctrlName,popNum,popStr) : PopupMenuControl
//-----------------------------
	String ctrlName
	Variable popNum
	String popStr
	
	SetDataFolder "root:EDC"
	FitConstraint=popStr
end


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function Fitting_EDC(ctrlname):ButtonControl
string ctrlname

variable i,j,LineNumber_start,LineNumber_end,Nb_analyse,Kx_inc
wave w_coef,w_sigma
string name

// Goal : fit all slices of the image loaded in ImageTools between boundaries defined by the user
// Before using it, correct values of initial parameters should be entered
// Simplest way to obtain this : export the first line (through export_line button) and fit it.

// Fait le graphe pour surveiller les fits au fur et a mesure
// Fait un graphe avec les positions et les largeurs en fonctions de x à la fin

//All results are savec in EDC folder. 

// FITTING FUNCTION : in the menu. Coded by Nb_lor. 
////////

//Reading the parameters for start and stop from ImageTool
//Choice of the window to analyse
wave Image=root:IMG:Image
GetAxis/Q left
Kx_inc=DimDelta(image,1)

SetDataFolder "root:EDC"
nvar energy_start,energy_end,Kx_start,Kx_end,Nb_lor
svar FitConstraint
variable sens=1
LineNumber_start=round((Kx_start-DimOffset(image,1))/Kx_inc)
LineNumber_end=round((Kx_end-DimOffset(image,1))/Kx_inc)
Nb_analyse=abs(LineNumber_end-LineNumber_start)+1
if (LineNumber_start>LineNumber_end)
	sens=-1
endif
//Création des waves où sauver les résultats
Make/N=(Nb_analyse)/D/O k_value
Make/N=(Nb_analyse)/D/O background,slope,slope2
Make/N=(Nb_analyse)/D/O amplitude1,err_amplitude1, amplitude2,err_amplitude2
Make/N=(Nb_analyse)/D/O largeur1,err_largeur1,largeur2,err_largeur2
Make/N=(Nb_analyse)/D/O position1, err_position1,position2, err_position2
Make/N=(Nb_analyse)/D/O Fermi, err_fermi
Make/N=(Nb_analyse)/D/O res, err_res

Make/O/N=(dimsize(Image,0)) to_fit
SetScale/P x dimoffset(Image,0),dimdelta(image,0), to_fit
//////////////////////////
// j is the number of the line to be fitted, this is Image[p][j]
// The current function to be fitted is called to_fit

j=round(LineNumber_start)
i=0
Do

to_fit=Image[p][j]

//do the fit
if (j==round(LineNumber_start))
	Display to_fit
	Movewindow 420,30,750,190
	DoWindow Fitting
	if (v_flag==1)
	   DoWindow/K Fitting
	endif   	
	DoWindow/C Fitting	
endif


if (Nb_lor==1)
	if (cmpstr(Fitconstraint,"none")==0)
		FuncFit/Q LorTimesFermi W_coef to_fit(energy_start,energy_end) /D
	endif   	
	if (cmpstr(Fitconstraint,"fixed Ef")==0)
		FuncFit/Q/H="0000010" LorTimesFermi W_coef to_fit(energy_start,energy_end) /D
	endif   	
	if (cmpstr(Fitconstraint,"fixed Fermi step")==0)
		FuncFit/Q/H="0000011" LorTimesFermi W_coef to_fit(energy_start,energy_end) /D
	endif   	
	if (cmpstr(Fitconstraint,"special")==0)
	//Fixed Fermi and position
		//FuncFit/Q/H="0000110" LorTimesFermi W_coef to_fit(energy_start,energy_end) /D
	//Fixed Fermi step and width
		w_coef[3]=0.015+0.25*(-0.2+(j-round(LineNumber_start))*0.00294)^2
		//w_coef[3]=0.02
		FuncFit/Q/H="0001000" LorTimesFermi W_coef to_fit(energy_start,energy_end) /D	
	endif  
endif

if (Nb_lor==2)
	if (cmpstr(Fitconstraint,"none")==0)
		FuncFit/Q GaussPlusParabolicBgd W_coef to_fit(energy_start,energy_end) /D
	endif   	
endif

if (Nb_lor==3)
	if (cmpstr(Fitconstraint,"none")==0)
	// Par défaut on fixe Ef et on limite le Bgd à l'ordre 2
		FuncFit/Q/H="0001100000011" TwoLinesTimesFermiPlusPolyBgd W_coef to_fit(energy_start,energy_end) /D
	endif   	
endif

if (Nb_lor==4)
	if (cmpstr(Fitconstraint,"none")==0)
		FuncFit/Q Fermi_meV W_coef to_fit(energy_start,energy_end) /D
	endif   	
endif

if (j==round(LineNumber_start))
	ModifyGraph rgb(fit_to_fit)=(0,0,52224)
endif

// all parameters and error bars results are saved 
	k_value[i]=Kx_start+i*sens*Kx_inc
	background[i]=w_coef[0]
      
      if (Nb_lor==1)
      		//LorTimesFermi
      		slope[i]=w_coef[1]
      		amplitude1[i]=w_coef[2]
      		largeur1[i]=w_coef[3]
	      position1[i]=w_coef[4]
	      Fermi[i]=w_coef[5]
	      Res[i]=w_coef[6]
      		err_amplitude1[i]=w_sigma[2]
      		err_largeur1[i]=w_sigma[3]
      		err_position1[i]=w_sigma[4]
     endif
     
     if (Nb_lor==2)
      		//GaussPlusParbolicBgd
      		amplitude1[i]=w_coef[3]
      		largeur1[i]=w_coef[5]
	      position1[i]=w_coef[4]
      		err_amplitude1[i]=w_sigma[3]
      		err_largeur1[i]=w_sigma[5]
      		err_position1[i]=w_sigma[4]
      endif		

     if (Nb_lor==3)
      		//TwoLinesTimesFermiPlusPolyBgd
      		amplitude1[i]=w_coef[5]
      		largeur1[i]=w_coef[7]
	      position1[i]=w_coef[6]
  		err_amplitude1[i]=w_sigma[5]
      		err_largeur1[i]=w_sigma[7]
      		err_position1[i]=w_sigma[6]
      		amplitude2[i]=w_coef[8]
      		largeur2[i]=w_coef[10]
	      position2[i]=w_coef[9]
  		err_amplitude2[i]=w_sigma[8]
      		err_largeur2[i]=w_sigma[10]
      		err_position2[i]=w_sigma[9]
      		background[i]=w_coef[0]
      		slope[i]=w_coef[1]
      		slope2[i]=w_coef[2]
      endif	

     if (Nb_lor==4)
      		//Fermi_meV
      		amplitude1[i]=w_coef[0]
      		largeur1[i]=w_coef[3]
	      position1[i]=w_coef[2]
      		err_amplitude1[i]=w_sigma[0]
      		err_largeur1[i]=w_sigma[3]
      		err_position1[i]=w_sigma[2]
      endif	
            
j=j+sens
i+=1
while (i<Nb_analyse)

//Graph for positions
Display position1 vs k_value;ModifyGraph mode=3,marker=19,msize=4  //markers instead of line
ModifyGraph zero(left)=1
Movewindow 10,240,350,420
DoWindow  Positions_Evsk
if (v_flag==1) 
	DoWindow/K Positions_Evsk
endif
DoWindow/C Positions_Evsk
Label left "Binding energy (eV)"
Label bottom "Kx"
Make/N=(Nb_analyse)/D/O position1, err_position1
AppendToGraph Fermi vs k_value
ModifyGraph rgb(Fermi)=(0,15872,65280)
ErrorBars Fermi Y,wave=(res,res)
//SetAxis/A/E=1 left

//Graph for widths
Display largeur1 vs position1;ModifyGraph mode=3,marker=19,msize=4  //markers instead of line
Movewindow 370,240,720,420
ModifyGraph lowTrip(left)=0.01
DoWindow  Widths_WvsE
if (v_flag==1) 
	DoWindow/K Widths_WvsE
endif
DoWindow/C Widths_WvsE

ModifyGraph zero(left)=1
Legend/C/N=text0/A=MC
SetAxis/A/E=1 left//Autoscale from zero
Label left "Lorentzian Half Width (eV)"
Label bottom "Binding energy (eV)"
//SetAxis/A/E=1 bottom

end
/////////////////////////////////////

Function Save_EDCresults(ctrlName) : ButtonControl
string ctrlName
end

Function Export_EDCline(ctrlName) : ButtonControl
string ctrlName
variable deb,fin

//Exporte la ligne active dans la fenêtre ImageTool dans un graphe
NewDataFolder/O root:EDC
SetDataFolder "root:EDC"
Duplicate/O root:IMG:ProfileH  Exported_line  //duplicate in current folder, not MDC that might not exist
Duplicate/O root:IMG:ProfileH_x  temp_scale
wave Exported_line, temp_scale
deb= temp_scale[0]
fin=temp_scale[numpnts(temp_scale)-1]
SetScale/I x deb,fin,"", Exported_line
killwaves temp_scale
Display Exported_line
Movewindow 420,15,750,190
ModifyGraph rgb(Exported_line)=(0,0,65280)
DoWindow EDCexported_line
if (v_flag==1)
   DoWindow/K EDCexported_line
endif   
DoWindow/C EDCexported_line
ShowInfo
deb=leftx(Exported_line)	
fin=deb+deltax(Exported_line)*(numpnts(Exported_line)-1)
Cursor A, Exported_line, deb
Cursor B, Exported_line, fin
DoUpdate
nvar Kx_curr=root:EDC:Kx_curr, Y0=root:WinGlobals:ImageTool:Y0	
Kx_curr=Y0//refresh value of Kx corresponding to exported line
end





Proc SubstractBgd():GraphMarquee

SetDataFolder root:IMG
variable/G Bgd_Kx1, Bgd_Kx2

GetMarquee/K left
If (V_Flag==1)  //Marquee was invoked
	Bgd_Kx1=V_bottom
	Bgd_Kx2=V_top
	DoSubstract(" ") 
endif

end

Function Substract_EDCBgd_fromPannel(ctrlName) : ButtonControl
string ctrlName

SetDataFolder root:IMG
variable/G Bgd_Kx1, Bgd_Kx2

		Bgd_Kx1=round(Dimoffset(Image,1)*1000)/1000
		Bgd_Kx2=round((Dimoffset(Image,1)+10*DimDelta(Image,1))*1000)/1000

		PauseUpdate; Silent 1		// building window...
		NewPanel /W=(10,300,460,450)

		DoWindow/F EDCbgd
		if (v_flag==1)
	   		DoWindow/K EDCbgd
		endif   	
		DoWindow/C EDCbgd
		DoWindow/T EDCbgd "EDC Background"

		SetVariable KxBgd1,pos={10,35},size={120,20},title=" k =  ",limits={-Inf,Inf,0.01},value=Bgd_Kx1
		SetVariable KxBgd2,pos={150,35},size={120,20},title=" to ",limits={-Inf,Inf,0.01},value=Bgd_Kx2
		DrawText  10,15,"Substract the EDC line, averaged between positions below, "
		DrawText 10,30, "to the image loaded in ImageTool "
		DrawText  10,80,"(you can also select positions in ImageTool with marquee and right click)"
				
		Button DoSubstractButton,pos={70,100},size={180,40},proc=DoSubstract,title="Substract"

end

function DoSubstract(ctrlname):ButtonControl
string ctrlname

SetDataFolder root:IMG
nvar Bgd_Kx1,Bgd_Kx2
wave Image
variable indice,indice_Bgd_Kx1,indice_Bgd_Kx2

	Make/O/N=(DimSize(Image,0)) Bgd
	Setscale/P x Dimoffset(Image,0),DimDelta(Image,0)," ", Bgd
	Bgd=0
	indice_Bgd_Kx1=round((Bgd_Kx1-Dimoffset(Image,1))/DimDelta(Image,1))
	indice_Bgd_Kx2=round((Bgd_Kx2-Dimoffset(Image,1))/DimDelta(Image,1))
	indice=min(indice_Bgd_Kx1,indice_Bgd_Kx2)
	do
	    Bgd+=Image[p][indice]
	    indice+=1
	while (indice<=max(indice_Bgd_Kx1,indice_Bgd_Kx2))
	Bgd/=(abs(indice_Bgd_Kx2-indice_Bgd_Kx1)+1)
	Image=Image[p][q]-Bgd[p]

	DoWindow/F EDCbgd
		if (v_flag==1)
	   		DoWindow/K EDCbgd
		endif  
	execute "AdjustCT()"
	
end

function Save_SingleEDCresults(ctrlname):ButtonControl
string ctrlname
execute "SaveProc()"
end


proc SaveProc()
//Look for the dimension of w_coef and save all parameters

string name
variable construire=0

SetDataFolder "root:EDC"

			
name=RootName+"_Kx"
Machin(name)
$name[DimSize($name,0)-1]=Kx_curr

name=RootName+"_"
DoWindow/F $name //Table de parametres
if (v_flag==0)
	name=RootName+"_Kx"
	edit $name
	name=RootName+"_"
	DoWindow/C $name
	DoWindow/T $name name
	Construire=1
endif	
		
variable i,Nb_coef=Dimsize(w_coef,0)
i=0
do
	//Fit coef
	name=RootName+"_w"+num2str(i)
	Machin(name)
	$name[DimSize($name,0)-1]=w_coef[i]
	if (construire==1) 
		AppendToTable $name 
	endif
	//error bars (not saved in table)
	name=RootName+"_err_w"+num2str(i)
	Machin(name)
	$name[DimSize($name,0)-1]=w_sigma[i]

	i+=1
while (i<=Nb_coef)

end



proc SaveProc_pedestre()
//Here fitting function is assumed to be GaussTimesFermiPlusParaBgd

string name
variable construire=0

SetDataFolder "root:EDC"

			
name=RootName+"_Kx"
Machin(name)
$name[DimSize($name,0)-1]=Kx_curr

name=RootName+"_"
DoWindow $name
if (v_flag==0)
	name=RootName+"_Kx"
	edit $name
	name=RootName+"_"
	DoWindow/C $name
	DoWindow/T $name name
	Construire=1
endif	
		
name=RootName+"_Amp"
Machin(name)
$name[DimSize($name,0)-1]=w_coef[0]
if (construire==1) 
	AppendToTable $name 
endif

name=RootName+"_err_Amp"
Machin(name)
$name[DimSize($name,0)-1]=w_sigma[0]
if (construire==1) 
	AppendToTable $name 
endif

name=RootName+"_Pos"
Machin(name)
$name[DimSize($name,0)-1]=w_coef[1]
if (construire==1) 
	AppendToTable $name 
endif

name=RootName+"_err_Pos"
Machin(name)
$name[DimSize($name,0)-1]=w_sigma[1]
if (construire==1) 
	AppendToTable $name 
endif

name=RootName+"_Width"
Machin(name)
$name[DimSize($name,0)-1]=w_coef[2]
if (construire==1) 
	AppendToTable $name 
endif

name=RootName+"_err_Width"
Machin(name)
$name[DimSize($name,0)-1]=w_sigma[2]
if (construire==1) 
	AppendToTable $name 
endif

name=RootName+"_FermiLevel"
Machin(name)
$name[DimSize($name,0)-1]=w_coef[3]
if (construire==1) 
	AppendToTable $name 
endif

name=RootName+"err_FermiLevel"
Machin(name)
$name[DimSize($name,0)-1]=w_sigma[3]
if (construire==1) 
	AppendToTable $name 
endif

name=RootName+"_WidthFermi"
Machin(name)
$name[DimSize($name,0)-1]=w_coef[4]
if (construire==1) 
	AppendToTable $name 
endif

name=RootName+"err_WidthFermi"
Machin(name)
$name[DimSize($name,0)-1]=w_sigma[4]
if (construire==1) 
	AppendToTable $name 
endif

name=RootName+"_BgdCst"
Machin(name)
$name[DimSize($name,0)-1]=w_coef[5]
if (construire==1) 
	AppendToTable $name 
endif

name=RootName+"_err_BgdCst"
Machin(name)
$name[DimSize($name,0)-1]=w_sigma[5]
if (construire==1) 
	AppendToTable $name 
endif

name=RootName+"_BgdPara"
Machin(name)
$name[DimSize($name,0)-1]=w_coef[6]
if (construire==1) 
	AppendToTable $name 
endif

name=RootName+"_err_BgdPara"
Machin(name)
$name[DimSize($name,0)-1]=w_sigma[6]
if (construire==1) 
	AppendToTable $name 
endif

//Plot results (if plot already exists, append new results (not yet done))

string abscisse=RootName+"_Kx"
string errorName

DoWindow/F FitRes_Amp
if (v_flag==0)
	name=RootName+"_Amp"
	errorName=RootName+"_err_Amp"
	Display $name vs $abscisse
	ModifyGraph mode=3,marker=19
	ErrorBars $name,Y wave=($errorName,$errorName)
	Label bottom "Kx"
	Label left "Amplitude"
	Legend/C/N=text0/A=MC
	
	DoWindow/C FitRes_Amp
	DoWindow/T FitRes_Amp "Fit results : amplitude"
endif	
MoveWindow 10,10,260,160

DoWindow/F FitRes_Pos
if (v_flag==0)
	name=RootName+"_Pos"
	errorName=RootName+"_err_pos"
	Display $name vs $abscisse
	ModifyGraph mode=3,marker=19
	ErrorBars $name,Y wave=($errorName,$errorName)
	Label bottom "Kx"
	Label left "Position"
	Legend/C/N=text0/A=MC
	
	DoWindow/C FitRes_Pos
	DoWindow/T FitRes_Pos "Fit results : position"
endif	
MoveWindow 270,10,520,160

DoWindow/F FitRes_Width
if (v_flag==0)
	name=RootName+"_Width"
	errorName=RootName+"_err_Width"
	Display $name vs $abscisse
	ModifyGraph mode=3,marker=19
	ErrorBars $name,Y wave=($errorName,$errorName)
	Label bottom "Kx"
	Label left "Peak width"
	Legend/C/N=text0/A=MC
	
	DoWindow/C FitRes_Width
	DoWindow/T FitRes_Width "Fit results : width"
endif	
MoveWindow 530,10,780,160

DoWindow/F FitRes_Fermi
if (v_flag==0)
	name=RootName+"_FermiLevel"
	errorName=RootName+"err_FermiLevel"
	Display $name vs $abscisse
	ModifyGraph mode=3,marker=19
	ErrorBars $name,Y wave=($errorName,$errorName)
	Label bottom "Kx"
	Label left "Fermi level"
	Legend/C/N=text0/A=MC
		
	DoWindow/C FitRes_Fermi
	DoWindow/T FitRes_Fermi "Fit results : Fermi level"
endif	
MoveWindow 10,170,260,320

DoWindow/F FitRes_WidthFermi
if (v_flag==0)
	name=RootName+"_WidthFermi"
	errorName=RootName+"err_WidthFermi"
	Display $name vs $abscisse
	ModifyGraph mode=3,marker=19
	ErrorBars $name,Y wave=($errorName,$errorName)
	Label bottom "Kx"
	Label left "Fermi level width (eV)"
	Legend/C/N=text0/A=MC
	
	DoWindow/C FitRes_WidthFermi
	DoWindow/T FitRes_WidthFermi "Fit results : Width Fermi"
endif	
MoveWindow 10,330,260,480

DoWindow/F FitRes_BgdCst
if (v_flag==0)
	name=RootName+"_BgdCst"
	errorName=RootName+"_err_BgdCst"
	Display $name vs $abscisse
	ModifyGraph mode=3,marker=19
	ErrorBars $name,Y wave=($errorName,$errorName)
	Label bottom "Kx"
	Label left "Bgd constant"
	Legend/C/N=text0/A=MC
	
	DoWindow/C FitRes_BgdCst
	DoWindow/T FitRes_BgdCst "Fit results : Bgd (constant)"
endif	
MoveWindow 260,180,510,320

DoWindow/F FitRes_BgdPara
if (v_flag==0)
	name=RootName+"_BgdPara"
	errorName=RootName+"_err_BgdPara"
	Display $name vs $abscisse
	ModifyGraph mode=3,marker=19
	ErrorBars $name,Y wave=($errorName,$errorName)
	Label bottom "Kx"
	Label left "Coef Bgd x^2"
	Legend/C/N=text0/A=MC
	
	DoWindow/C FitRes_BgdPara
	DoWindow/T FitRes_BgdPara "Fit results : Bgd (parabolic)"
endif	
MoveWindow 260,330,510,480

end

proc Machin(name)
string name
	if (exists(name)==0) 
		Make/N=1 $name 
		else 
		//print "name, dim", name, DimSize($name,0)+1
		Redimension/N=(DimSize($name,0)+1) $name
	endif
end


//////////////////////////////////////////

proc LookForMax(ctrlName) : ButtonControl
	String ctrlName
//Works on the entire image
//To define other limits, use Marquee

variable y_min,y_max,y_cur,x_min,x_max
SetDataFolder root:IMG
Dowindow/F ImageTool
x_min=Dimoffset(Image,0)
x_max=x_min+DimDelta(Image,0)*(DimSize(Image,0)-1)
y_min=Dimoffset(Image,1)
y_max=y_min+DimDelta(Image,1)*(DimSize(Image,1)-1)

DoLookForMax(x_min,x_max,y_min,y_max)

End



proc Find_max():GraphMarquee
// Works on Image from ImageTool
// Looks for maximum in the window defined by Marquee
variable y_min,y_max,y_cur,x_min,x_max
SetDataFolder root:IMG

GetMarquee/K left,bottom

if (V_bottom<Dimoffset(Image,1))
	V_bottom=DimOffset(Image,1)
endif	
variable top=Dimoffset(Image,1)+(DimSize(Image,1)-1)*DimDelta(Image,1)
if (V_top>top)
	V_top=top
endif
		y_min=V_bottom
		y_max=V_top
		x_min=V_left
		x_max=V_right


DoLookForMax(x_min,x_max,y_min,y_max)

end

proc DoLookForMax(x_min,x_max,y_min,y_max)
variable y_min,y_max,y_cur,x_min,x_max
variable indice,nb_y
	
SetDataFolder root:IMG
      
      variable delta_y=abs(DimDelta(Image,1))
	y_min=round(y_min/delta_y)*delta_y
	y_max=round(y_max/delta_y)*delta_y
	nb_y=(y_max-y_min)/delta_y
	x_min=round(x_min/DimDelta(Image,0))*DimDelta(Image,0)
	x_max=round(x_max/DimDelta(Image,0))*DimDelta(Image,0)
	Make/O /N=(nb_y+1) Max_x,Max_y,Max_z
	Setscale/I x y_min,y_max, Max_x,Max_y,Max_z
	Make/O /N=(Dimsize(Image,0)) temp
	Setscale/P x Dimoffset(Image,0),DimDelta(Image,0), temp
	
	y_cur=y_min
	indice=0
	do
		temp=Image(x)(y_cur)
		Wavestats/Q /R=(x_min,x_max) temp
		Max_y(y_cur)=y_cur
		Max_x(y_cur)=v_maxloc
		Max_z(y_cur)=v_max
		y_cur+=delta_y
		indice+=1
	while (indice<=nb_y)		
	
	Killwaves temp
	
	RemoveFromGraph/Z Max_y vs Max_x
	AppendToGraph Max_y vs Max_x
	ModifyGraph rgb(Max_y)=(65535,65535,65535)
	ModifyGraph mode(Max_y)=3,marker(Max_y)=19
end

proc Fitting_EDC_Disp(ctrlname) : ButtonControl
string ctrlname

SetDataFolder root:IMG
Display Max_y vs Max_x
ShowInfo
        variable cursor1,cursor2
        cursor1=leftx(QPenergy)    
        cursor2=cursor1+deltax(Max_x)*(numpnts(Max_x)-1)
        Cursor A, Max_y, cursor1
        Cursor B, Max_y, cursor2
        DoUpdate    
end

function AddMax(ctrlName) : ButtonControl
	String ctrlName
//Add max on stacks (QPvalue) as blue points

nvar pinc=root:IMG:STACK:pinc,offset=root:IMG:STACK:offset
wave Image=root:IMG:Image
wave Max_x=root:IMG:Max_x,Max_z=root:IMG:Max_z,Max_y=root:IMG:Max_y
variable y_start,y_stop,nb,p_decal

y_start=Max_y[0]
y_stop=Max_y[DimSize(Max_y,0)-1]
nb=DimSize(Max_y,0)/pinc
Make/O /N=(nb) QPmax_y, QPmax_x
p_decal=round((y_start-Dimoffset(Image,1))/Dimdelta(Image,1))  // Max might be done only for part of the image

QPmax_x=Max_x[p*pinc]
QPmax_y=Max_x[p*pinc]+(p_decal/pinc+p)*offset

DoWindow/F Stack_
RemoveFromGraph/Z QPmax_y vs QPmax_x
AppendToGraph QPmax_y vs QPmax_x
ModifyGraph mode(QPmax_y)=3,marker(QPmax_y)=19,rgb(QPmax_y)=(0,12800,52224)

End



function Export_max_old(ctrlName) : ButtonControl
	String ctrlName
// Dispersion has been calculated as max of EDC image [QPpos vs QPenergy]
// This procedure saves the useful points as a wave (E vs k) or (k vs E) or 2 waves under a name chosen by the user
// Also do the plot
// No conversion from degree to AA (use menu to do that)

SetDataFolder root:IMG
//Transform_disp() //in AzimuthMapping

string Disp_pos,Disp_Energy,choix
choix="none;"+WaveList("*",";","DIMS:1")
disp_pos="QPpos"
disp_energy="QPenergy"
prompt Disp_pos,"Wave of position (degree) ", popup,choix
prompt Disp_Energy,"Wave of energy (eV) ", popup,choix
variable p_min,p_max,nb
p_min=0
p_max=dimsize(QPpos,0)-1
prompt p_min,"From index p= "
prompt p_max,"To index p= "
choix="E vs k (1 wave); k vs E (1 wave); E vs k (2 waves); k vs E (2 waves)"  
string PlotType="E vs k (1 wave)"
prompt PlotType, "Plot", popup,choix
string name="EDCmax"
prompt name, "Name for output wave(s)"
DoPrompt "Save..." Disp_pos,Disp_Energy,p_min,p_max,PlotType,name

nb=p_max-p_min+1

if (v_flag==0)
	DoWindow/K EDCmax_

	variable pos_start
	string name2

	//temp = energy values scaled as function of position
	Duplicate/O $disp_energy temp2
	Make/O /N=(nb) temp
	temp[]=temp2[p+p_min]
	pos_start=Dimoffset($Disp_pos,0)+p_min*DimDelta($Disp_pos,0)
	SetScale/P x pos_start,DimDelta($Disp_pos,0), temp


	if (cmpstr(PlotType,"E vs k (1 wave)")==0)
		Duplicate/O temp $name
		Display $name
		Label left "energy (eV)"
		Label bottom "position (eV)"
		ModifyGraph zero(left)=1
	endif

if (cmpstr(PlotType," E vs k (2 waves)")==0)
	Duplicate/O temp $name
	temp=pos_start+p*DimDelta($Disp_pos,0)
	name2=name+"_k"
	Duplicate/O temp $name2

	Display $name vs $name2
	Label left "energy (eV)"
	Label bottom "position (eV)"
	ModifyGraph zero(left)=1
endif

if (cmpstr(PlotType," k vs E (2 waves)")==0)
	name2=name+"_e"
	Duplicate/O temp $name2
	temp=pos_start+p*DimDelta($Disp_pos,0)
	Duplicate/O temp $name

	Display $name vs $name2
	Label bottom "energy (eV)"
	Label left "position (eV)"
	ModifyGraph zero(bottom)=1
endif


if (cmpstr(PlotType," k vs E (1 wave)")==0)
	Duplicate/O temp temp2,temp3
	temp2=pos_start+p*DimDelta($Disp_pos,0)
	execute "Interpolate/T=1/N="+num2str(nb)+"/Y=temp3 temp2 /X=temp"
	Duplicate/O temp3 $name
	Killwaves temp3
	Display $name
	Label bottom "energy (eV)"
	Label left "position (eV)"
	ModifyGraph zero(bottom)=1
endif

Killwaves temp,temp2

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

proc SymmetrizeImage(Ef)
variable Ef
string InputName=Find_TopImageName()
string OutputName=InputName+"_sym"
	Duplicate/O $InputName Image_temp
	Image_temp= $InputName(x)(y)+ $InputName(2*Ef-x)(y)
	Duplicate/O Image_temp $OutputName
	Killwaves Image_temp
	Display;AppendImage $OutputName
	ModifyImage $OutputName ctab= {*,*,PlanetEarth,1}
end

proc SymmetrizeSpectrum(Input_Name,Ef)
string Input_Name
variable Ef

	string OutputName=Input_Name+"_sym"
	
	variable Offset,NbPnts
	Offset=DimOffset($Input_Name,0)
	NbPnts=abs(round(2*Offset/DimDelta($Input_Name,0)))
	Make/O/N=(NbPnts) EDC_temp
	Setscale/I x,Offset,-Offset,EDC_temp
	
	EDC_temp= $Input_Name(x)+ $Input_Name(2*Ef-x)
	Duplicate/O EDC_temp $OutputName
	Killwaves EDC_temp
end

Function Save_resultsEDC(ctrlName) : ButtonControl
string ctrlName
variable i
string curr=GetDataFolder(1)
SetDataFolder root:MDC
string/G nameIN,nameOUT
nvar Nb_lor=root:MDC:Nb_lor
//Save everything in new folder with extension of folder name

        //where
        string suffix,path
        prompt suffix,"Save the following parameters in folder : "
        DoPrompt "Save results", suffix
       
   
        ////////////
if (v_flag==0)  
         path="root:EDC:"+suffix
        NewDataFolder/O $path
        path+=":"
        SetDataFolder "root:EDC"
      
             nameOut="kvalue_"+suffix
             Duplicate/O k_value, $nameOut
             SetDataFolder $path
             Killwaves/Z $nameOut
		SetDataFolder "root:EDC"
             MoveWave $nameout $path
	i=1
	do
            nameIN="amplitude"+num2str(i)
            nameOUT=nameIn+"_"+suffix
            SetDataFolder $path
             Killwaves/Z $nameOUT
		SetDataFolder "root:EDC"
            Rename $nameIN, $nameOUT
            MoveWave $nameOUT $path
            
            nameIN="position"+num2str(i)
            nameOUT=nameIn+"_"+suffix
            SetDataFolder $path
             Killwaves/Z $nameOUT
		SetDataFolder "root:EDC"
             Rename $nameIN, $nameOUT
             MoveWave $nameOUT $path

            nameIN="largeur"+num2str(i)
            nameOUT=nameIn+"_"+suffix
            SetDataFolder $path
             Killwaves/Z $nameOUT
		SetDataFolder "root:EDC"
             Rename $nameIN, $nameOUT
             MoveWave $nameOUT $path
                             
             nameIN="err_amplitude"+num2str(i)
            nameOUT=nameIn+"_"+suffix
            SetDataFolder $path
             Killwaves/Z $nameOUT
		SetDataFolder "root:EDC"
            Rename $nameIN, $nameOUT
            MoveWave $nameOUT $path
            
            nameIN="err_position"+num2str(i)
            nameOUT=nameIn+"_"+suffix
            SetDataFolder $path
             Killwaves/Z $nameOUT
		SetDataFolder "root:EDC"
             Rename $nameIN, $nameOUT
             MoveWave $nameOUT $path

            nameIN="err_largeur"+num2str(i)
            nameOUT=nameIn+"_"+suffix
            SetDataFolder $path
             Killwaves/Z $nameOUT
		SetDataFolder "root:EDC"
             Rename $nameIN, $nameOUT
             MoveWave $nameOUT $path            
             i=i+1
        while (i<=2)
        
            nameIN="background"
            nameOUT=nameIn+"_"+suffix
            SetDataFolder $path
             Killwaves/Z $nameOUT
		SetDataFolder "root:EDC"
            Rename $nameIN, $nameOUT
            MoveWave $nameOUT $path
            
             nameIN="slope"
            nameOUT=nameIn+"_"+suffix
            SetDataFolder $path
             Killwaves/Z $nameOUT
		SetDataFolder "root:EDC"
            Rename $nameIN, $nameOUT
            MoveWave $nameOUT $path
            
             nameIN="slope2"
            nameOUT=nameIn+"_"+suffix
            SetDataFolder $path
             Killwaves/Z $nameOUT
		SetDataFolder "root:EDC"
            Rename $nameIN, $nameOUT
            MoveWave $nameOUT $path 
endif //if on cancel
SetDataFolder curr

end