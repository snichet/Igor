#pragma rtGlobals=1             // Use modern global access method.
#include "LPS_Fitting_Functions"
//Fitting_MDC : fits the MDC stacks with 1 to 4 lorentzians
//Export_line : display the line shown in ImageTool in a normal graph


//menu "MDC_Fitting"
//      "-"
//      "Show Window", InitWindow()
//end


Proc InitWindow()
//-----------------


        DoWindow/F MDC_Fitting
        if (V_flag==0)
                NewDataFolder/O/S root:MDC
        
                PauseUpdate; Silent 1           // building window...
                NewPanel /W=(15,50,500,290)
                DoWindow/C MDC_Fitting
                DoWindow/T MDC_Fitting "Fitting MDC"
                ModifyPanel cbRGB=(64512,0000,30000)
                
                Button LoadMDCline,pos={9,8},size={200,25},proc=Export_line,title="Load MDC line from ImageTool"
                
                
                string/G FitFunc="One_lor",FitConstraint="none"
                variable/G Nb_lor=1
                SetDrawLayer UserBack
		   DrawRect 8,42,223,102
                PopupMenu PopFunctions,pos={10,48},size={111,21},proc=SelectFunction,title="Fitting Functions",popvalue="One_lor", value="One_lor;Two_lor;Three_lor;Four_lor;Five_lor;Fermi;GaussPlusLorTimesFermi"
                PopupMenu PopConstraints,pos={10,73},size={111,21},proc=SelectConstraint,title="Constraints         ",popvalue="none", value="none;same width;fixed para"
               
                variable/G energy_start=round(DimOffset(root:IMG:image,1)*100)/100
                variable/G energy_end =round((energy_start+DimDelta(root:IMG:image,1)*(DimSize(root:IMG:image,1)-1))*100)/100
                SetVariable energy_start,pos={10,113},size={130,25},title="Energy   : start",limits={-Inf,Inf,0.01},value=energy_start
                SetVariable energy_end,pos={150,113},size={90,25},title="end",value=energy_end,limits={-Inf,Inf,0.01},value=energy_end
                variable/G Kx_start =round(DimOffset(root:IMG:image,0)*100)/100
                variable/G Kx_end =round(  (Kx_start+DimDelta(root:IMG:image,0)*(DimSize(root:IMG:image,0)-1)) *100)/100
                SetVariable Kx_start_box,pos={10,143},size={130,15},title="Kx         : start",limits={-Inf,Inf,0.01},value=Kx_start
                SetVariable Kx_end_box,pos={150,143},size={90,15},title="end",limits={-Inf,Inf,0.01},value=Kx_end
               
                Button FitStacks,pos={41,192},size={200,30},proc=Fitting_MDC,title="Fit Stacks of ImageTool"
                 
                string/G FitMode="Kx-range"
                SetDrawEnv linethick= 2,fillpat= 0
		   DrawRect 262,170,460,44
                PopupMenu PopFitMode,pos={263,59},size={151,21},proc=SelectFitMode,title="Fitting Mode",popvalue="Kx-range",value= "Kx-range;Around maximum"
                DrawText 274,103,"Define range around maximum"
                variable/G LeftAngleRange,RightAngleRange
                SetVariable RangeLeft,pos={289,111},size={155,16},title="Degrees to the left",limits={-Inf,Inf,0.01},value=LeftAngleRange
		   SetVariable RangeRight,pos={289,136},size={155,16},title="Degrees to the right",limits={-Inf,Inf,0.01},value=RightAngleRange
                
                //Button FitMDCline,pos={300,45},size={200,25},proc=Fit_line,title="Fit MDC line"
                //Button Normalize,pos={262,230},size={180,30},proc=NormalizeByVf,title="Fit dispersion / Normalize width"
                Button SaveResults,pos={311,192},size={116,30},proc=Save_results,title="Save results"
                
        endif
End



Proc SelectFunction(ctrlName,popNum,popStr) : PopupMenuControl
//-----------------------------
        String ctrlName
        Variable popNum
        String popStr
        
        SetDataFolder "root:MDC"
        FitFunc=popStr
        Nb_lor=popNum//Not universal (for example, might want to fit with Gaussians), so should be changed some day
end


Proc SelectConstraint(ctrlName,popNum,popStr) : PopupMenuControl
//-----------------------------
        String ctrlName
        Variable popNum
        String popStr
        
        SetDataFolder "root:MDC"
        FitConstraint=popStr
end

Proc SelectFitMode(ctrlName,popNum,popStr) : PopupMenuControl
//-----------------------------
        String ctrlName
        Variable popNum
        String popStr
        
        SetDataFolder "root:MDC"
        FitMode=popStr
end



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function Fitting_MDC(ctrlname):ButtonControl
string ctrlname


variable i,j,LineNumber_start,LineNumber_end,Nb_analyse,energy_inc
wave w_coef,w_sigma,pw
string name
wave Image=root:IMG:Image

// Goal : fit all slices of imagetools (i.e all stacks, Image must be loaded in ImageTool)
// Before using it, correct values of initial parameters should be entered
// Simplest way to obtain this : export the first line (through export_line button) and fit it.


// Fait le graphe pour surveiller les fits au fur et a mesure
// Fait un graphe avec les positions et les largeurs en fonctions de x à la fin


//All results are savec in MDC folder. Use save button to export those you want to keep.


// FITTING FUNCTION
// The ones in Fitting function popup display. 
//Presently, only 1 to 4 lorentzian. The chosen function is defined by Nb_lor. 
//This should be changed to the name of the function to be able to use other fitting functions
////////

string curr=GetDataFolder(1)


//Reading the parameters for start and stop from ImageTool
//Choice of the window to analyse
GetAxis/Q left


energy_inc=DimDelta(root:IMG:image,1)


//First do stacks with step=1 (through ImageTool)
NVAR pinc=root:IMG:STACK:pinc
pinc=1
DoWindow/F ImageTool
SetAxis/A
CreateStack("")
/////////////////////


SetDataFolder "root:MDC"
nvar energy_start,energy_end,Kx_start,Kx_end,Nb_lor
svar FitConstraint
variable sens=1

LineNumber_start=round((energy_start-DimOffset(root:IMG:image,1))/energy_inc)
LineNumber_end=round((energy_end-DimOffset(root:IMG:image,1))/energy_inc)
Nb_analyse=abs(LineNumber_end-LineNumber_start)+1
if (LineNumber_start>LineNumber_end)
	sens=-1
endif

//Création des waves où sauver les résultats
Make/N=(Nb_analyse)/D/O energy
Make/N=(Nb_analyse)/D/O background
//lor 1
Make/N=(Nb_analyse)/D/O amplitude1
Make/N=(Nb_analyse)/D/O err_amplitude1
Make/N=(Nb_analyse)/D/O largeur1; SetScale/I x, energy_start, energy_end, largeur1
Make/N=(Nb_analyse)/D/O err_largeur1
Make/N=(Nb_analyse)/D/O position1; SetScale/I x, energy_start, energy_end, position1
Make/N=(Nb_analyse)/D/O err_position1
//lor2
if (Nb_lor>1)
Make/N=(Nb_analyse)/D/O amplitude2
Make/N=(Nb_analyse)/D/O err_amplitude2
Make/N=(Nb_analyse)/D/O largeur2;SetScale/I x, energy_start, energy_end, largeur2
Make/N=(Nb_analyse)/D/O err_largeur2
Make/N=(Nb_analyse)/D/O position2;SetScale/I x, energy_start, energy_end, position2
Make/N=(Nb_analyse)/D/O err_position2
endif
//lor3
if (Nb_lor>2)
Make/N=(Nb_analyse)/D/O amplitude3
Make/N=(Nb_analyse)/D/O err_amplitude3
Make/N=(Nb_analyse)/D/O largeur3;SetScale/I x, energy_start, energy_end, largeur3
Make/N=(Nb_analyse)/D/O err_largeur3
Make/N=(Nb_analyse)/D/O position3;SetScale/I x, energy_start, energy_end,position3
Make/N=(Nb_analyse)/D/O err_position3
endif
//lor4
if (Nb_lor>3)
Make/N=(Nb_analyse)/D/O amplitude4
Make/N=(Nb_analyse)/D/O err_amplitude4
Make/N=(Nb_analyse)/D/O largeur4;SetScale/I x, energy_start, energy_end, largeur4
Make/N=(Nb_analyse)/D/O err_largeur4
Make/N=(Nb_analyse)/D/O position4;SetScale/I x, energy_start, energy_end, position4
Make/N=(Nb_analyse)/D/O err_position4
endif
//lor5
if (Nb_lor>4)
Make/N=(Nb_analyse)/D/O amplitude5
Make/N=(Nb_analyse)/D/O err_amplitude5
Make/N=(Nb_analyse)/D/O largeur5;SetScale/I x, energy_start, energy_end, largeur5
Make/N=(Nb_analyse)/D/O err_largeur5
Make/N=(Nb_analyse)/D/O position5;SetScale/I x, energy_start, energy_end, position5
Make/N=(Nb_analyse)/D/O err_position5
endif

//Nb_lor=6  => GaussPlusLorTimesFermi n'utilise pas tous les paramètres, mais pas grave


//////////////////////////
// j is the number of the line to be fitted, named line0, line1 etc
// The current function to be fitted is called to_fit
Make/O/N=(dimsize(Image,0)) to_fit
SetScale/P x dimoffset(Image,0),dimdelta(image,0), to_fit


j=round(LineNumber_start)
i=0
Do
// write linej in to_fit
name="root:IMG:Stack:line"+num2str(j)
//print name
//Duplicate/O $name to_fit
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

variable starta, startb,center
svar FitMode
nvar LeftAngleRange,RightAngleRange
starta = xcsr(A,"Plot_exported_line")
startb = xcsr(B,"Plot_exported_line")

if (Nb_lor==1)
	 if (cmpstr(FitMode,"Kx-range")==0)
		FuncFit/Q One_lor W_coef to_fit(Kx_start,Kx_end) /D
	else
      	wavestats  /q /r=(starta,startb) /q to_fit
	center=V_maxloc
      	FuncFit/Q One_lor W_coef to_fit(center-LeftAngleRange,center+RightAngleRange) /D
      	center = w_coef[3]
      	FuncFit/Q One_lor W_coef to_fit(center-LeftAngleRange,center+RightAngleRange) /D
      	endif
endif
if (Nb_lor==2)
        if (cmpstr(Fitconstraint,"none")==0)
        	Make/O/T/N=2 T_Constraints
             //T_Constraints[0] = {"K2>0","K5>0"}  // impose des largeurs positives
                if (cmpstr(FitMode,"Kx-range")==0)
				//FuncFit/Q Two_lor W_coef to_fit(Kx_start,Kx_end) /D/C=T_Constraints 
				FuncFit/Q Two_lor W_coef to_fit(Kx_start,Kx_end) /D
				//Next line is to fit with amplitudes fixed (ie parameters 2 and 5)
				//FuncFit/Q/H="0100100" Two_lor W_coef to_fit(Kx_start,Kx_end) /D 
			else
      				wavestats  /q /r=(starta,startb) /q to_fit
				center=V_maxloc
      				FuncFit/Q Two_lor W_coef to_fit(center-LeftAngleRange,center+RightAngleRange) /D/C=T_Constraints 
      				//center = w_coef[3]
      				//FuncFit/Q Two_lor W_coef to_fit(center-LeftAngleRange,center+RightAngleRange) /D
      		   endif
        
                
          else
                Make/O/T/N=2 T_Constraints
                T_Constraints[0] = {"K5<K2","K5>K2"}// Impose les deux raies du milieu même largeur
                FuncFit/Q Two_lor W_coef to_fit(Kx_start,Kx_end) /D/C=T_Constraints 
        endif           
endif
if (Nb_lor==3)
        if (cmpstr(Fitconstraint,"none")==0)
                FuncFit/Q Three_lor W_coef to_fit(Kx_start,Kx_end) /D
        else
                
        endif           
endif

if (Nb_lor==4)
        if (cmpstr(Fitconstraint,"none")==0)
                FuncFit/Q Four_lor W_coef to_fit(Kx_start,Kx_end) /D
         else
                Make/O/T/N=4 T_Constraints
                //T_Constraints[0] = {"K7<K4","K7>K4","K8<K5","K8>K5"}// Impose les deux raies du milieu même largeur
                //T_Constraints[0] = {"K5<K2","K5>K2","K8<K2","K8>K2","K11<K2","K11>K2"}// Impose les quatre raies de même largeur
                T_Constraints[0] = {"K5<K2","K5>K2","K8<K11","K8>K11"}// Impose même largeur pour raies 1 et 4 d'une part, 2 et 3 d'autre part
                FuncFit/Q Four_lor W_coef to_fit(Kx_start,Kx_end) /D/C=T_Constraints 
        endif           
endif

if (Nb_lor==5)
        if (cmpstr(Fitconstraint,"none")==0)
                FuncFit/Q Five_lor W_coef to_fit(Kx_start,Kx_end) /D
         else
                //Make/O/T/N=6 T_Constraints
                //T_Constraints[0] = {"K5<K2","K5<K2","K11<K8","K11>K8","K15<0.005","K15>0.005"}// Impose les deux raies à gauche de même largeur, même chose à droite, dernière raie centrée à zero
                //T_Constraints[0] = {"K7<K4","K7>K4","K8<K5","K8>K5"}// Impose les deux raies du milieu même largeur
                //T_Constraints[0] = {"K5<K2","K5>K2","K11<K2","K11>K2","K14<K2","K14>K2"}// Impose les quatre raies extremes de même largeur (bgd au centre)
                Make/O/T/N=2 T_Constraints
                T_Constraints[0] = {"K9<0.01","K9>0.01"} // Impose de centrer en 0 la raie centrale
                FuncFit/Q Five_lor W_coef to_fit(Kx_start,Kx_end) /D/C=T_Constraints 
        endif           
endif

if (Nb_lor==6)
                // Fonction François
                // Attention : pw doit être dans Folder MDC
                FuncFit/Q/H="0100000"/NTHR=1/TBOX=768 FermiFit pw  to_fit(Kx_start,Kx_end) /D 
endif

if (Nb_lor==7)
        if (cmpstr(Fitconstraint,"none")==0)
                FuncFit/Q GaussPlusLorTimesFermi W_coef to_fit(Kx_start,Kx_end) /D
        else
        	   variable k_int,E_int
        	   k_int=energy_start+(j-LineNumber_start)*energy_inc
        	   E_int=0.2*(k_int-0.69)^2-0.145
        	   w_coef[5]=0.022+0.72*E_int^2
        	   FuncFit/Q/H="100001011" GaussPlusLorTimesFermi W_coef to_fit(Kx_start,Kx_end) /D
        endif           
endif


if (j==round(LineNumber_start))
        ModifyGraph rgb(fit_to_fit)=(0,0,52224)
endif


// all parameters and error bars results are saved 
if (Nb_lor==6)
wave pw
	energy[i]=energy_start+i*sens*energy_inc // this is in fact detector position
	amplitude1[i]=pw[6]  // Fermi level
      largeur1[i]=pw[0]  //gaussian broadening
      largeur2[i]=pw[1]  // temperature

else       
       energy[i]=energy_start+i*sens*energy_inc
       background[i]=w_coef[0]
      
      amplitude1[i]=w_coef[1]
      largeur1[i]=w_coef[2]
      position1[i]=w_coef[3]
      err_amplitude1[i]=w_sigma[1]
      err_largeur1[i]=w_sigma[2]
      err_position1[i]=w_sigma[3]
      if (Nb_lor>1)
      amplitude2[i]=w_coef[4]
      largeur2[i]=w_coef[5]
      position2[i]=w_coef[6]
      err_amplitude2[i]=w_sigma[4]
      err_largeur2[i]=w_sigma[5]
      err_position2[i]=w_sigma[6]
      endif
      if (Nb_lor>2)
      amplitude3[i]=w_coef[7]
      largeur3[i]=w_coef[8]
      position3[i]=w_coef[9]
      err_amplitude3[i]=w_sigma[7]
      err_largeur3[i]=w_sigma[8]
      err_position3[i]=w_sigma[9]
      endif
     if (Nb_lor>3)
      amplitude4[i]=w_coef[10]
      largeur4[i]=w_coef[11]
      position4[i]=w_coef[12]
      err_amplitude4[i]=w_sigma[10]
      err_largeur4[i]=w_sigma[11]
      err_position4[i]=w_sigma[12]
      endif
      if (Nb_lor>4)
      amplitude5[i]=w_coef[13]
      largeur5[i]=w_coef[14]
      position5[i]=w_coef[15]
      err_amplitude5[i]=w_sigma[16]
      err_largeur5[i]=w_sigma[17]
      err_position5[i]=w_sigma[18]
      endif
endif
j=j+sens
i+=1
while (i<Nb_analyse)


//Graph for positions

if (Nb_lor==6)
	Killwaves/Z position,FermiLevel,broadening,temperature
	rename energy position    
	rename amplitude1 FermiLevel 
      	rename largeur1 broadening 
     	rename largeur2 temperature
      Display FermiLevel vs Position
      ModifyGraph mode=3,marker=19
      legend
      Display broadening vs Position; AppendToGraph/R temperature vs Position
      ModifyGraph manTick(left)={0,0.001,0,3},manMinor(left)={0,0}
      ModifyGraph rgb(temperature)=(0,0,52224)
      legend
      ModifyGraph mode=3,marker=19

else

Display energy vs position1;ModifyGraph mode=3,marker=19,msize=4  //markers instead of line
ModifyGraph zero(left)=1
Movewindow 10,280,350,460
DoWindow  Positions_Evsk
if (v_flag==1) 
        DoWindow/K Positions_Evsk
endif
DoWindow/C Positions_Evsk


if (Nb_lor>1)
AppendToGraph energy vs position2;ModifyGraph mode=3,marker=19,msize=4
ModifyGraph rgb(energy#1)=(0,21760,65280)
endif
if (Nb_lor>2)
AppendToGraph energy vs position3;ModifyGraph mode=3,marker=19,msize=4 
ModifyGraph rgb(energy#2)=(0,52224,0)
endif
if (Nb_lor>3)
AppendToGraph energy vs position4;ModifyGraph mode=3,marker=19,msize=4
ModifyGraph rgb(energy#3)=(13056,0,5120)
endif
if (Nb_lor>4)
AppendToGraph energy vs position5;ModifyGraph mode=3,marker=19,msize=4
ModifyGraph rgb(energy#4)=(65280,65280,16384)
endif
Label left "Binding energy (eV)"
Label bottom "Kx"
ShowInfo
variable deb,fin
deb=leftx(energy)        
fin=deb+deltax(energy)*(numpnts(energy)-1)
Cursor A, energy, deb
Cursor B, energy, fin
DoUpdate        

//Graph for widths
Display largeur1 vs energy;ModifyGraph mode=3,marker=19,msize=4  //markers instead of line
Movewindow 370,280,720,460
ModifyGraph lowTrip(left)=0.01
DoWindow  Widths_WvsE
if (v_flag==1) 
        DoWindow/K Widths_WvsE
endif
DoWindow/C Widths_WvsE
ShowInfo

ModifyGraph zero(left)=1
if (Nb_lor>1)
AppendToGraph largeur2 vs energy;ModifyGraph mode=3,marker=19,msize=4 
ModifyGraph rgb(largeur2)=(0,21760,65280)
endif
if (Nb_lor>2)
AppendToGraph largeur3 vs energy;ModifyGraph mode=3,marker=19,msize=4
ModifyGraph rgb(largeur3)=(0,52224,0)
endif
if (Nb_lor>3)
AppendToGraph largeur4 vs energy;ModifyGraph mode=3,marker=19,msize=4
ModifyGraph rgb(largeur4)=(13056,0,5120)
endif
if (Nb_lor>4)
AppendToGraph largeur5 vs energy;ModifyGraph mode=3,marker=19,msize=4
ModifyGraph rgb(largeur5)=(65280,65280,16384)
endif
Legend/C/N=text0/A=MC
SetAxis/A/E=1 left//Autoscale from zero
Label left "Lorentzian Half Width (pi/a units)"
Label bottom "Binding energy (eV)"
endif

SetDataFolder curr

end
/////////////////////////////////////


Function Export_line(ctrlName) : ButtonControl
string ctrlName
variable deb,fin

//Exporte la ligne active dans la fenêtre ImageTool dans un graphe
// Il le place dans root:MDC parce qu'on veut que les paramètres du fit (en particulier w_coef) s'y trouvent
//pour enchaîner avec le fit des stacks.
string curr=GetDataFolder(1)
NewDataFolder/O root:MDC
SetDataFolder "root:MDC"  //Sinon : w_coef n'est pas forcement dans MDC et pas utilisé dans la suite
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
DoWindow Plot_exported_line
if (v_flag==1)
   DoWindow/K Plot_exported_line
endif   
DoWindow/C Plot_exported_line
ShowInfo
deb=leftx(Exported_line)        
fin=deb+deltax(Exported_line)*(numpnts(Exported_line)-1)
Cursor A, Exported_line, deb
Cursor B, Exported_line, fin
DoUpdate        
//SetDataFolder curr
end



Function Save_results_old(ctrlName) : ButtonControl
string ctrlName
variable i
string curr=GetDataFolder(1)
SetDataFolder root:MDC
string/G nameIN,nameOUT
nvar Nb_lor=root:MDC:Nb_lor


        //where
        string path="root:MDC:"
        prompt path,"Save the following parameters in folder : "
        //which parameters
        string energyS=" ",amplitudeS=" ",positionS=" ",energyVSposS="disp",largeurVSenergyS="width"
        prompt energyS,"energy as ..."
        prompt amplitudeS,"amplitude as ..."
        prompt positionS,"position (Kx) as ..."
        prompt energyVSposS,"dispersion (k vs E) as ..."
        prompt largeurVSenergyS,"width (W vs E) as ... "
        //for which waves
        string line1=" ",line2=" ",line3=" ",line4=" "
        prompt line1,"for line 1 with extension (' ' if no save) "
        if (Nb_lor>1)
              prompt line2,"for line 2 with extension (' '  if no save) "
        endif
        if (Nb_lor>2)
              prompt line3,"for line 3 with extension (' ' if no save) "
        endif
        if (Nb_lor>3)
                prompt line4,"for line 4 with extension (' '  if no save) "
        endif   


        if (Nb_lor==1)
               line1="1"
             DoPrompt "Save results", path,energyS,amplitudeS,positionS,energyVSposS,largeurVSenergyS,line1
        endif
        if (Nb_lor==2)
                line1="1",line2="2"
                DoPrompt "Save results", path,energyS,amplitudeS,positionS,energyVSposS,largeurVSenergyS,line1,line2
        endif
        if (Nb_lor==3)
                DoPrompt "Save results", path,energyS,amplitudeS,positionS,energyVSposS,largeurVSenergyS,line1,line2,line3
        endif
        if (Nb_lor==4)
                line1="1",line2="2",line3="3",line4="4"
                DoPrompt "Save results", path,energyS,amplitudeS,positionS,energyVSposS,largeurVSenergyS,line1,line2,line3,line4
        endif
        Make/O/T/n=5 NameOfLine
        NameOfLine[1]=line1,NameOfLine[2]=line2,NameOfLine[3]=line3,NameOfLine[4]=line4


        ////////////
if (v_flag==0)  
        NewDataFolder/O $path
        path+=":"
        SetDataFolder "root:MDC"
        i=1
        do
        //print "1",NameOFLine[1],cmpstr(NameOfLine[1]," ")
        //print "2",NameOFLine[2],cmpstr(NameOfLine[2]," ")
        //print "3",NameOFLine[3],cmpstr(NameOfLine[3]," ")
        //print "4",NameOFLine[4],cmpstr(NameOfLine[4]," ")
                if (cmpstr(NameOfLine[i]," "))
                        //changed by Andres : waves are already scaled : no interpolation
                        if (cmpstr(energyVSposS," "))
                                nameIN="position"+num2str(i)
                                nameOUT=energyVSposS+NameOfLine[i]
                                Duplicate/O $nameIN $nameOUT
                                SetDataFolder $path
                                Killwaves/Z $nameOUT
					SetDataFolder "root:MDC"
                                //execute "Interpolate/T=1/N=200/Y=$nameOUT energy /X=$nameIN"
                                MoveWave $nameOUT $path
                                print nameout,path
                        endif
                        if (cmpstr(largeurVSenergyS," "))
                                nameIN="largeur"+num2str(i)
                                nameOUT=largeurVSenergyS+NameOfLine[i]
                                SetDataFolder $path
                                Killwaves/Z $nameOUT
					SetDataFolder "root:MDC"
                                //execute "Interpolate/T=1/N=200/Y=$nameOUT $nameIN /X=energy"
                                Duplicate/O $nameIN $nameOUT
                                MoveWave $nameOUT $path
                                print nameout,path
                        endif
                        
                        if (cmpstr(energyS," "))
                                if (cmpstr(energyS,"energy")==0)
                                energyS+="s"
                                endif
                                Duplicate/O energy, $energyS
                                SetDataFolder $path
                                Killwaves/Z $energyS
					SetDataFolder "root:MDC"
                                MoveWave $energyS $path
                        endif
                        if (cmpstr(amplitudeS," "))
                                nameIN="amplitude"+num2str(i)
                                nameOUT=amplitudeS+NameOfLine[i]
                                SetDataFolder $path
                                Killwaves/Z $nameOUT
					SetDataFolder "root:MDC"
                                Rename $nameIN, $nameOUT
                                MoveWave $nameOUT $path
                        endif
                        if (cmpstr(positionS," "))
                                nameIN="position"+num2str(i)
                                nameOUT=positionS+NameOfLine[i]
                                SetDataFolder $path
                                Killwaves/Z $nameOUT
					SetDataFolder "root:MDC"
                                 Rename $nameIN, $nameOUT
                                MoveWave $nameOUT $path
                        endif
                        
                        

                endif
                i=i+1
        while (i<=4)            
endif//if on cancel
SetDataFolder curr

end

Function Save_results(ctrlName) : ButtonControl
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
         path="root:MDC:"+suffix
        NewDataFolder/O $path
        path+=":"
        SetDataFolder "root:MDC"
      
             nameOut="energy_"+suffix
             Duplicate/O energy, $nameOut
             SetDataFolder $path
             Killwaves/Z $nameOut
		SetDataFolder "root:MDC"
             MoveWave $nameout $path
	i=1
	do
            nameIN="amplitude"+num2str(i)
            nameOUT=nameIn+"_"+suffix
            SetDataFolder $path
             Killwaves/Z $nameOUT
		SetDataFolder "root:MDC"
            Rename $nameIN, $nameOUT
            MoveWave $nameOUT $path
            
            nameIN="position"+num2str(i)
            nameOUT=nameIn+"_"+suffix
            SetDataFolder $path
             Killwaves/Z $nameOUT
		SetDataFolder "root:MDC"
             Rename $nameIN, $nameOUT
             MoveWave $nameOUT $path

            nameIN="largeur"+num2str(i)
            nameOUT=nameIn+"_"+suffix
            SetDataFolder $path
             Killwaves/Z $nameOUT
		SetDataFolder "root:MDC"
             Rename $nameIN, $nameOUT
             MoveWave $nameOUT $path
                             
             nameIN="err_amplitude"+num2str(i)
            nameOUT=nameIn+"_"+suffix
            SetDataFolder $path
             Killwaves/Z $nameOUT
		SetDataFolder "root:MDC"
            Rename $nameIN, $nameOUT
            MoveWave $nameOUT $path
            
            nameIN="err_position"+num2str(i)
            nameOUT=nameIn+"_"+suffix
            SetDataFolder $path
             Killwaves/Z $nameOUT
		SetDataFolder "root:MDC"
             Rename $nameIN, $nameOUT
             MoveWave $nameOUT $path

            nameIN="err_largeur"+num2str(i)
            nameOUT=nameIn+"_"+suffix
            SetDataFolder $path
             Killwaves/Z $nameOUT
		SetDataFolder "root:MDC"
             Rename $nameIN, $nameOUT
             MoveWave $nameOUT $path            
             i=i+1
        while (i<=Nb_lor)            
endif //if on cancel
SetDataFolder curr

end

Function Fit_line(ctrlName) : ButtonControl
string ctrlName


//CurveFit
end


//////////////////////////////////////////////////////////////////////////
//	Normalization panel and procedures			//
/////////////////////////////////////////////////////////////////////////

Function NormalizeByVf(ctrlName) : ButtonControl
string ctrlName


DoWindow/F Normalization
        if (V_flag==0)
                
                PauseUpdate; Silent 1           // building window...
                NewPanel /W=(400,200,860,615)
                DoWindow/C Normalization
                DoWindow/T Normalization "Normalization"
                ModifyPanel cbRGB=(0,43520,65280)
		   SetDrawLayer UserBack
		   SetDrawEnv linethick= 2,fillpat= 0
		   DrawRect 268,103,13,11
		   SetDrawEnv fstyle= 1
		   DrawText 30,144,"LINEAR FIT OF DISPERSION"
		   SetDrawEnv linethick= 2,fillpat= 0
		   DrawRect 18,117,194,287
		   SetDrawEnv fstyle= 1
		   DrawText 251,144,"QUADRATIC FIT OF DISPERSION"
		   DrawText 271,163,"E=VfQ*(k-kfQ)+B*(k-kfQ)^2"
		   SetDrawEnv linethick= 2,fillpat= 0
		   DrawRect 235,115,443,287
                
                SetDataFolder "root:MDC"
                
                string/G Folder, NameOfDispersion, NameOfWidth
                //SetVariable FolderBox activate, pos={15,20},size={240,25},proc=GoToFolder,title="                               Folder",value=Folder
                Button PickFolder, pos={100,17},size={75,25},proc=PickFolderThroughDataBrowser,title="Pick folder"
                Folder="root:MDC"
                PopupMenu PopDisp,pos={10,45},size={250,25},proc=ChooseDisp,mode=1,title="Name of dipsersion wave",value=WaveList("*",";","DIMS:1"), popvalue=NameOfDispersion
                ChooseDisp(" ",0,"-")  //valeur par defaut
                PopupMenu PopWidth,pos={10,70},size={250,25},proc=ChooseWidth,mode=1,title="Name of width wave", value=WaveList("*",";","DIMS:1"),popvalue=NameOfwidth
                ChooseWidth(" ",0,"largeur1")  //valeur par defaut
                //SetVariable NameOfDispersionBox,pos={10,45},size={250,25},title="Name of dipsersion wave",value=NameOfDispersion
                //SetVariable NameOfWidthBox,pos={10,70},size={250,25},title="Name of width wave       ",value=NameOfWidth
                                
                Button PlotDisp,pos={304,11},size={130,35},proc=Plot_Disp,title="Plot dispersion"
                Button FitDisp,pos={38,250},size={130,30},proc=Fit_Disp,title="Fit dispersion : E=Vf*(k-k0)"
                
                Variable/G Vf=6,K0=0.1
                SetVariable coefA,pos={51,198},size={100,20},title="Vf  ",limits={-Inf,Inf,0.01},value=Vf
                SetVariable coefX0,pos={51,225},size={100,20},title="k0",limits={-Inf,Inf,0.01},value=K0
                //DrawText  40,195,"Vf Units : eV.[AA/(pi/a)]"
                DrawText 38,169,"Default units: [Vf]=eV/deg"
		   DrawText 112,185,"[k0]=deg"
                
                Button DoNormalizeWidth,pos={17,294},size={180,40},proc=DoNormalizeWidth,title="Normalize width by Vf"
                Button ShiftDisp,pos={17,341},size={180,40},proc=ShiftDispersion,title="Shift dispersion to zero"              
        	   
        	   Button buttonCompDeriv,pos={279,59},size={178,37},proc=CompNumericDerivative,title="Numerical derivative of dispersion"
		   
		   Variable/G VfQ, kfQ, B
		   SetVariable setvarVFQ,pos={262,171},size={101,16},title="VfQ",value= root:MDC:VfQ
		   SetVariable setvarKFQ,pos={263,198},size={99,16},title="kfQ",value= root:MDC:kfQ
		   SetVariable setvarB,pos={270,225},size={92,16},title="B",value= root:MDC:B
		   
		   Button buttonQFitDisp,pos={289,253},size={120,25},proc=QuadraticFitDisp,title="Quadratic fit !"
		   Button buttonNormVFQ,pos={214,296},size={126,29},proc=NormByVFQ,title="Normalize width by VfQ"
		   Button bttnNormNumDer,pos={214,365},size={192,27},proc=NormByNumericSlope,title="Normalize width by numerical derivative"
		   Button bttnNormNumDer01,pos={215,331},size={192,27},proc=NormByAnalyticSlope,title="Normalize width by VfQ + 2*B*(k-kfQ)"

        endif

end

//---------------------------------
Function PickFolderThroughDataBrowser(ctrlname):ButtonControl	
	string ctrlname
	SVAR Folder
	
	//String cdfBefore = GetDataFolder(1)		// Save current data folder before.
	Execute "CreateBrowser prompt=\"Select data folder and click OK\" "
	String cdfAfter = GetDataFolder(1)		// Save current data folder after.
	Folder=cdfAfter
	SetDataFolder cdfAfter				// Restore current data folder.
	//print cdfAfter
	//print Folder
	//SetDataFolder cdfBefore				// Restore data folder before.

End

//-----------------------------
Function ChooseDisp(ctrlName,popNum,popStr) : PopupMenuControl
        String ctrlName
        Variable popNum
        String popStr
	  SVAR NameOfDispersion=root:MDC:NameOfDispersion
        
        NameOfDispersion=popStr
        //print NameOfDispersion

end


//-----------------------------
Function ChooseWidth(ctrlName,popNum,popStr) : PopupMenuControl
        String ctrlName
        Variable popNum
        String popStr
	  SVAR NameOfWidth=root:MDC:NameOfWidth
        
        NameOfWidth=popStr


end

//-----------------------------------------------
Function Plot_Disp(ctrlName) : ButtonControl
string ctrlName
string name,LocalFolder
variable cursor1,cursor2,nop
SVAR Folder=root:MDC:Folder, NameOfDispersion=root:MDC:NameOfDispersion
SetDataFolder Folder
NVAR K0		//K0=root:MDC:K0


//name=Folder+":"+NameOfDispersion
name=NameOfDispersion
//SetDataFolder $Folder
//print waveexists($name)
//print Folder
if (waveexists($name) && wavetype($name)!=0)
        Display $name; label bottom, "Binding energy [eV]"; label left, "Peak position [degrees]"
        MoveWindow 10,200,310,500
        ModifyGraph mode=3,marker=19
        ModifyGraph rgb=(0,0,52224)
        ShowInfo         
        cursor1=leftx($Name)    
        cursor2=cursor1+deltax($Name)*(numpnts($NameOfDispersion)-1)
        Cursor A, $NameOfDispersion, cursor1
        Cursor B, $NameOfDispersion, cursor2
        DoUpdate        
        K0=round(cursor1*100)/100
else
        LocalFolder="root:"
        Name="disp"
        prompt LocalFolder,"Folder"
        prompt Name,"Name of dispersion wave"
        DoPrompt "Wave does not exist or wave type is not appropriate",LocalFolder,Name
        
        if (v_flag==0)	// user clicks "Continue"
        	   Folder=LocalFolder
                NameOfDispersion=Name
                Plot_Disp(" ")  
        endif   
endif   
end


//-----------------------------------------------
Function CompNumericDerivative(ctrlName) : ButtonControl	// Computes and plots the NUMERICAL derivative of a wave of name "name"
	string ctrlName
	string name, LocalFolder, derivative="NumericDerivOf"
	SVAR Folder		//Folder=root:MDC:Folder
	SVAR NameOfDispersion	//NameOfDispersion=root:MDC:NameOfDispersion
	WAVE LocalFermiVel
	
	SetDataFolder Folder
	name=NameOfDispersion		//name=Folder+":"+NameOfDispersion
	//print waveexists($name)
	if (waveexists($name) && wavetype($name)!=0)
		derivative+=name		// Sets the name of the differentiated wave
       	duplicate/o $name $derivative	// Target wave is set equal to source wave
       	Differentiate $derivative		// Target wave is replaced by it numerical derivative
       	duplicate/o $derivative LocalFermiVel
       	LocalFermiVel=1/LocalFermiVel				// Target is replaced by its reciprocal (to get Fermi velocities)
       	Display LocalFermiVel; label bottom, "Binding energy [eV]"; label left, "Local Fermi velocity [eV / degree]"
        	MoveWindow 10,200,310,500
        	ModifyGraph mode=3,marker=19
        	ModifyGraph rgb=(0,0,52224)
        else
        	LocalFolder="root:"
        	Name="disp"
        	prompt LocalFolder,"Folder"
        	prompt Name,"Name of dispersion wave"
        	DoPrompt "Wave does not exist or wave type is not appropriate",LocalFolder,Name
        	
        	if (v_flag==0)		// Continue was clicked...
        		Folder=LocalFolder
                	NameOfDispersion=Name
                	CompNumericDerivative(" ")  
        	endif   
	endif   

End

Function QuadraticFitDisp(ctrlName) : ButtonControl
	String ctrlName
	string name
	SVAR Folder, NameOfDispersion		
	SetDataFolder Folder
	NVAR VfQ,kfQ,B 							
	variable cursor1,cursor2
	wave W_coef


	Make/N=3/O W_coef		// Where the pre-fitting values are stored
	W_coef[0]=kfQ				
	W_coef[1]=vfQ
	W_coef[2]=B
	name=NameOfDispersion			
	FuncFit/X ParabolicBand, W_coef, $name(xcsr(A),xcsr(B)) /D
	KfQ=W_coef[0]
	VfQ=W_coef[1]		
	B=W_coef[2]
	
End

Function NormByVFQ(ctrlName) : ButtonControl
	String ctrlName
	String NameOfVFQNorWidth
	SVAR Folder, NameOfWidth		
	NVAR VfQ 				

	SetDataFolder Folder
	NameOfVFQNorWidth="VFQNor_"+NameOfWidth


	Duplicate/O $NameOfWidth temp
	temp*=abs(VfQ)
	Duplicate/O temp $NameOfVFQNorWidth 
	KillWaves temp
	Display $NameOfVFQNorWidth 
	ModifyGraph mode=3,marker=19
	SetAxis/A/E=1 left
	MoveWindow  10,80,400,300
	Label left "Width (eV)"
	Label bottom "Energy (eV)"
	Legend/C/N=text0/F=0/H=20/A=MC

End

Function NormByAnalyticSlope(ctrlName) : ButtonControl
	String ctrlName
	String NameOfQSlopeNorWidth
	SVAR Folder, NameOfDispersion,NameOfWidth		
	NVAR VfQ, B, kfQ
	Wave QSlopeWave 				

	SetDataFolder Folder
	NameOfQSlopeNorWidth="QSlopeNor_"+NameOfWidth
	
	// Compute normalizing wave
	Make/O/N=(DimSize($NameOfWidth,0)) QSlopeWave
	Duplicate/O $NameOfDispersion tempDisp
	QSlopeWave=abs(VfQ+2*B*(tempDisp-kfQ))
	KillWaves tempDisp

	// Perform normalization
	Duplicate/O $NameOfWidth tempWidth
	tempWidth*=QSlopeWave
	Duplicate/O tempWidth $NameOfQSlopeNorWidth 
	KillWaves tempWidth
	Display $NameOfQSlopeNorWidth 
	ModifyGraph mode=3,marker=19
	SetAxis/A/E=1 left
	MoveWindow  10,80,400,300
	Label left "Width (eV)"
	Label bottom "Energy (eV)"
	Legend/C/N=text0/F=0/H=20/A=MC

End

Function NormByNumericSlope(ctrlName) : ButtonControl
	String ctrlName
	String NameOfNumSlopeNorWidth
	SVAR Folder, NameOfDispersion,NameOfWidth		
	//NVAR VfQ, B, kfQ
	WAVE LocalFermiVel 				

	SetDataFolder Folder
	NameOfNumSlopeNorWidth="NumSlopeNor_"+NameOfWidth
	
	// Compute normalizing wave
	//Make/O/N=(DimSize($NameOfWidth,0)) QSlopeWave
	//Duplicate/O $NameOfDispersion tempDisp
	//QSlopeWave=abs(VfQ+2*B*(tempDisp-kfQ))
	//KillWaves tempDisp

	// Perform normalization
	Duplicate/O $NameOfWidth tempWidth
	tempWidth*=LocalFermiVel
	Duplicate/O tempWidth $NameOfNumSlopeNorWidth 
	KillWaves tempWidth
	Display $NameOfNumSlopeNorWidth 
	ModifyGraph mode=3,marker=19
	SetAxis/A/E=1 left
	MoveWindow  10,80,400,300
	Label left "Width (eV)"
	Label bottom "Energy (eV)"
	Legend/C/N=text0/F=0/H=20/A=MC

End



//-----------------------------------------------------------------
Function Fit_Disp(ctrlName) : ButtonControl
string ctrlName
string name
SVAR Folder=root:MDC:Folder, NameOfDispersion=root:MDC:NameOfDispersion
SetDataFolder Folder
NVAR Vf=root:MDC:Vf,K0=root:MDC:K0
variable cursor1,cursor2


//SetDataFolder $Folder
Make/N=2/O W_coef

name=NameOfDispersion			//name=Folder+":"+NameOfDispersion
FuncFit Fit_DispEvsK W_coef energy[pcsr(A),pcsr(B)] /X=position1 /D 
if (cmpstr(NameOfdispersion,"-")==0)
	//Fit energy vs position1 in graph already displayed
	W_coef[0]=Vf					//W_coef[0]=Vf
	W_coef[1]=K0
	DoWindow/F Positions_Evsk
	FuncFit Fit_DispEvsK W_coef energy[pcsr(A),pcsr(B)] /X=position1 /D 
	Vf=W_coef[0]
	K0=W_coef[1]
else
	W_coef[0]=K0					//W_coef[0]=Vf
	W_coef[1]=1/Vf
	CurveFit/X=1 Line $name(xcsr(A),xcsr(B)) /D		// Fits K=K0 + (1/Vf)*E	//FuncFit/X=1 Slope W_coef $name(xcsr(A),xcsr(B)) /D
	Vf=1/W_coef[1]		//Vf=round(W_coef[0]*100)/100
	K0=W_coef[0]
endif

End


Function DoNormalizeWidth(ctrlName) : ButtonControl
string ctrlName
string NameOfNorWidth
SVAR Folder=root:MDC:Folder, NameOfWidth=root:MDC:NameOfWidth		
NVAR Vf=root:MDC:Vf 				

SetDataFolder Folder
NameOfNorWidth="Nor_"+NameOfWidth


Duplicate/O $NameOfWidth temp
temp*=abs(Vf)
Duplicate/O temp $NameOfNorWidth 
//KillWaves temp
Display $NameOfNorWidth 
ModifyGraph mode=3,marker=19
SetAxis/A/E=1 left
MoveWindow  10,80,400,300
Label left "Width (eV)"
Label bottom "Energy (eV)"
Legend/C/N=text0/F=0/H=20/A=MC

End


Function ShiftDispersion(ctrlName) : ButtonControl
string ctrlName
string NameOfNorDisp
svar Folder=root:MDC:Folder, NameOfDispersion=root:MDC:NameOfDispersion
nvar K0=root:MDC:K0,Vf=root:MDC:Vf
variable length
// Works on a wave containing k vs E
//Shift by kf and gives positive slope

SetDataFolder $Folder
NameOfNorDisp="Nor_"+NameOfDispersion


Duplicate/O $NameOfDispersion temp
temp-=K0
if (Vf<0)
        temp*=-1
endif

//if (Vf>0)
//        length=(numpnts(temp)-1)*deltax(temp)
//        SetScale/P x length,-deltax(temp),"", temp
//else    
//        SetScale/P x 0,deltax(temp),"", temp
//endif


Duplicate/O temp $NameOfNorDisp 
KillWaves temp
Display $NameOfNorDisp
ModifyGraph mode=3,marker=19
MoveWindow  10,80,300,400
Label left "K-K0 (pi/a units)"
Label bottom "Energy (eV)"
ModifyGraph zero(bottom)=1
Legend/C/N=text0/F=0/H=20/A=MC
ModifyGraph lowTrip(bottom)=0.001
end




//Function GoToFolder (ctrlName,varNum,varStr,varName) : SetVariableControl
//	string ctrlName
//	variable varnum
//	string varstr
//	string varName
//	SVAR Folder
//
//   	SetDataFolder Folder
//end 

