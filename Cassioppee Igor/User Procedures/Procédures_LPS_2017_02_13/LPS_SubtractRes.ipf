#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// Procédure à suivre : 
// Pour 2 lorentziennes
// - Créer des paramètres MDC (energy, amplitude, largeur, position) de l'image qu'on veut fitter : 
// ça peut être les fits de l'image brute. Souvent, il faut les lisser d'une manière ou d'une autre.
// - Créer l'image MDC correspondante. La fitter dans ImageTool en prenant bien ses limites extrèmes.
// Attention : il faut que l'échelle d'énergie soit dans le même sens que le fit.
// - Copier w_coef dans w_coef_backup (dans MDC)
// - Mettre ces paramètres dans un dossier "Fit1" de MDC. 
// - Démarrer  Ite_auto(ite_cur,ite_ToGo,res,k_start,k_stop,Nb_k)
// NB : Quand il fait le fit il demande où sauver les résultats du fit de l'image convolué : Fit1b, Fit2b...
// Il faut un plot de largeur2 en fon des ites
//
/////////////////////////////////////////////////////////////////////////
// Convolution_Wave1D_Res(Name,ResValue)  
//		Name=wave1D
//		Output : wave 1D conv_out=name convolué gaussienne demi-largeur mi-hauteur  ResValue
// Convolution_Wave2D_YRes(Name2D,ResValue)
//		Name2D = Wave 2D
// 		Output = Name2D_conv = Name2D convolué pour la dimension Y par Gaussienne HWHM Resvalue
//
//Build_EDCimage()
//		From model of dispersion E(k) and width L(E)
//		Each EDC=Lor( E , A , E(k) , L(E) )
//		Only for a fit with 2 lorentzians so far
//		Output : ImageMDC_name = energy vs k
//		k window given as parameters of function
//		energy window taken from energy, dispersion from position, width from largeur etc...//
//
// Build_MDCimage(Name,k_start,k_stop,Nb_k)
//		In a directory with results from a MDC fit in the form "energy_name" etc.
//		Only for a fit with 2 lorentzians so far
//		Output : ImageMDC_name = energy vs k
//		k window given as parameters of function
//		energy window taken from energy, dispersion from position, width from largeur etc...
// 
// Iterative fit to extract resolution : 
// Iteration(Name_first,Name_old,Name_new,Name_next)
// 		Name_first= name of directory with original parameters
//		Name_old=  name of directory with current iteration, before convolution
//		Name_new =name of directory with current iteration, after convolution
//		Name_next = name of directory where to save next iteration
//		Calculates difference between parameters before and after convolution
//		Subtract this from first parameters
//		Builds the new image and convoluates it (parameters for this to be entered in the function)
// Ite_auto(ite_cur,ite_ToGo,res)
// 		Does ite_ToGo iterations starting with ite_cur
//		First dataset must be called Fit1 (or enter name in function)
//		Must have a wave w_coef_backup in MDC folder with reasonable starting parameters
//		Makes a graph with the evolution of largeur1
//////////////////////////////////////////////////////////////////////////


Function Convolution_Wave1D_Res(Name,ResValue,NameOut)
wave Name
variable ResValue // Demi largeur mi-hauteur Gaussienne
string NameOut

variable Nb,index1,index2,aire,index2_start,index2_stop

Nb=round(3*ResValue/abs(DimDelta(Name,0)))
Make/O/N=(2*Nb+1) GaussConv
SetScale/P x, -3*ResValue,abs(DimDelta(Name,0)),GaussConv
GaussConv=Gaussienne(x,1,0,ResValue)
 
Duplicate/O Name Conv_out
Conv_out=0

index1=0
do
	index2=-Nb
	index2_start=Nb
	index2_stop=-Nb
	do
		if (((index1+index2)>=0) && ((index1+index2)<DimSize(Name,0)))
			Conv_out[index1]+=Name[index1+index2]*GaussConv[index2+Nb]
			if (index2<index2_start)
				index2_start=index2
			endif
			if (index2>index2_stop)
				index2_stop=index2
			endif	
		endif	
		index2+=1
	while (index2<=Nb)
	Conv_out[index1]/=sum(GaussConv,pnt2x(GaussConv,index2_start+Nb),pnt2x(GaussConv,index2_stop+Nb))
	//print index2_start,index2_stop,sum(GaussConv,pnt2x(GaussConv,index2_start+Nb),pnt2x(GaussConv,index2_stop+Nb))
	index1+=1
while (index1<DimSize(Name,0))	

//aire=area(conv_out)
//Conv_out*=area(Name)/aire

Duplicate/O conv_out $NameOut
Killwaves GaussConv

end

///////////////

Function Convolution_Wave2D_YRes(Name2D,ResValue)
wave Name2D
variable ResValue // Demi largeur mi-hauteur Gaussienne

variable index

// Fit all the X values as D waves
Make/O/N=(dimsize(Name2D,1)) Name1D   
SetScale/P x DimOffset(Name2D,1),DimDelta(Name2D,1),Name1D
Duplicate/O Name2D Name2D_conv

Convolution_Wave1D_Res(Name1D,ResValue,"conv_out")  // just to reference conv_out
wave conv_out
	
index=0
do
	Name1D[]=Name2D[index][p]
	Convolution_Wave1D_Res(Name1D,ResValue,"conv_out")
	Name2D_conv[index][]=conv_out[q]
	index+=1
while (index<DimSize(Name2D,0))	

//Display;AppendImage Name2D_conv
//ModifyImage Name2D_conv ctab= {*,*,PlanetEarth,1}

Killwaves Conv_out

end

//////////////////////////////
Function Build_EDCimage(Disp,Largeur,FermiWidth)
wave Disp,largeur
variable FermiWidth
// Il faut construire une wave de dispersion (vs k) et une wave de largeur (vs E) et il s'occupe de tout.

Make/O/N=(Dimsize(Disp,0),Dimsize(Largeur,0)) EDCimg
SetScale/P x, DimOffset(Disp,0),DimDelta(Disp,0),EDCimg
SetScale/P y, DimOffset(Largeur,0),DimDelta(Largeur,0),EDCimg
EDCimg=Lor(y,FermiStep(y,0,FermiWidth),Disp(x),Largeur(y))

end


///////////////////////////////////
Function Build_MDCimage(Name,k_start,k_stop,Nb_k)
string Name
variable k_start,k_stop,Nb_k
// Builds a wave ImageMDC_name (energy vs k) from the parameters of a MDC fit
// Should be in the directory with parameters and for a 2 lorentzians fit
// Name is the extension for the parameter waves, k_start etc the dimensions wanted in k

string name_tmp
variable index
name_tmp="energy_"+Name
Duplicate/O $name_tmp energy
Make/O/N=(Nb_k,DimSize(energy,0)) ImageMDC
SetScale/I x, k_start,k_stop,ImageMDC
SetScale/P y, energy[0],(energy[1]-energy[0]),ImageMDC
ImageMDC=0

name_tmp="amplitude1_"+Name
Duplicate/O $name_tmp amp1
name_tmp="position1_"+Name
Duplicate/O $name_tmp pos1
name_tmp="largeur1_"+Name
Duplicate/O $name_tmp width1

name_tmp="amplitude2_"+Name
Duplicate/O $name_tmp amp2
name_tmp="position2_"+Name
Duplicate/O $name_tmp pos2
name_tmp="largeur2_"+Name
Duplicate/O $name_tmp width2

index=0
do 
	ImageMDC[][index]=Lor(p*DimDelta(ImageMDC,0)+DimOffset(ImageMDC,0),amp1[index],pos1[index],Width1[index])
	ImageMDC[][index]+=Lor(p*DimDelta(ImageMDC,0)+DimOffset(ImageMDC,0),amp2[index],pos2[index],Width2[index])
	index+=1
while (index<DimSize(energy,0))

name_tmp="ImageMDC_"+name
Duplicate/O ImageMDC $name_tmp

Killwaves energy
Killwaves pos1,amp1,width1
Killwaves pos2,amp2,width2
Killwaves ImageMDC
end

//////////////////

Proc Iteration(Name_first,Name_old,Name_new,Name_next,res,k_start,k_stop,Nb_k)
string Name_first,Name_old,Name_new,Name_Next
variable res // energy resolution
variable k_start,k_stop,Nb_k
//Names of the directory containing MDC fits (new=old after convolution)
// Parameters are first+(new-old)
// Creates image for the next iteration (enter desired k window directly at end of procedure : see Build_MDCimage)
// Convoluate this image (set resolution below) for new fitting : see Convolution_Wave2D_YRes

string name1,name2

name1="root:MDC:"+Name_next
NewDataFolder/O $name1

//Duplicate parameter waves of Name_first
name1="root:MDC:"+Name_first+":amplitude1_"+Name_first
name2="root:MDC:"+Name_next+":amplitude1_"+Name_next
Duplicate/O $name1 $name2									// next=first
name1="root:MDC:"+Name_new+":amplitude1_"+Name_new
$name2-=$name1											// next=first - Nb
name1="root:MDC:"+Name_old+":amplitude1_"+Name_old
$name2+=$name1											// next=first + N
//$name2=abs($name2)//Force positive amplitude
//$name2=FermiStep(x,0,0.02)  // Force FermiDirac
$name2=1
//$name2=root:MDC:Fit1:amplitude1_Fit_raw_SS0

name1="root:MDC:"+Name_first+":amplitude2_"+Name_first
name2="root:MDC:"+Name_next+":amplitude2_"+Name_next
Duplicate/O $name1 $name2
name1="root:MDC:"+Name_new+":amplitude2_"+Name_new
$name2-=$name1
name1="root:MDC:"+Name_old+":amplitude2_"+Name_old
$name2+=$name1										
//$name2=abs($name2)//Force positive amplitude
//$name2=FermiStep(x,0,0.02) // Force FermiDirac
$name2=1
//$name2=root:MDC:Fit1:amplitude1_Fit_raw_SS0

name1="root:MDC:"+Name_first+":position1_"+Name_first
name2="root:MDC:"+Name_next+":position1_"+Name_next
Duplicate/O $name1 $name2
name1="root:MDC:"+Name_new+":position1_"+Name_new
$name2-=$name1
name1="root:MDC:"+Name_old+":position1_"+Name_old
$name2+=$name1
$name2=root:MDC:Fit1:position1_Fit1

name1="root:MDC:"+Name_first+":position2_"+Name_first
name2="root:MDC:"+Name_next+":position2_"+Name_next
Duplicate/O $name1 $name2
name1="root:MDC:"+Name_new+":position2_"+Name_new
$name2-=$name1
name1="root:MDC:"+Name_old+":position2_"+Name_old
$name2+=$name1
$name2=root:MDC:Fit1:position2_Fit1

name1="root:MDC:"+Name_first+":largeur1_"+Name_first
name2="root:MDC:"+Name_next+":largeur1_"+Name_next
Duplicate/O $name1 $name2
name1="root:MDC:"+Name_new+":largeur1_"+Name_new
$name2-=$name1
name1="root:MDC:"+Name_old+":largeur1_"+Name_old
$name2+=$name1

name1="root:MDC:"+Name_first+":largeur2_"+Name_first
name2="root:MDC:"+Name_next+":largeur2_"+Name_next
Duplicate/O $name1 $name2
name1="root:MDC:"+Name_new+":largeur2_"+Name_new
$name2-=$name1
name1="root:MDC:"+Name_old+":largeur2_"+Name_old
$name2+=$name1

name1="root:MDC:"+Name_first+":energy_"+Name_first
name2="root:MDC:"+Name_next+":energy_"+Name_next
Duplicate/O $name1 $name2



// Build new image
name1="root:MDC:"+Name_next
SetDataFolder $name1
Build_MDCimage(name_next,k_start,k_stop,Nb_k)   // enter here k window
name2="ImageMDC_"+name_next
Convolution_Wave2D_YRes($Name2,res)   // enter here resolution
end

//////////////////////////

Proc Ite_auto(ite_cur,ite_ToGo,res,k_start,k_stop,Nb_k)
variable ite_cur,ite_ToGo,res
variable k_start,k_stop,Nb_k

// Name of first directory : Fit1 in MDC folder (or entered below in Iteration(...))
// ite_cur : current iteration (directory FitN with N=ite_cur must exist)
// ite_ToGo : Number of iterations to perform
// Save all intermediate results in directory FitNb (asks for the name of each : usually Fit1b, Fit2b, etc)

// MDC panel must be filled with good parameters (the ones used to get first parameters)
// MUST BE a w_coef_backup wave in root:MDC with good parameters to start the fit.
// Must be a wave Name2D_conv in the first directory to fit

// First build an image with parameters in FitN
// Then convolve this image with resolution
// Fit this image => result in FitNb
// procedure "iteration" calculates the next image N+1 : First + (FitNb-FitN)

string name,name1,name2
variable index

// Build new image for ite_cur
name1="root:MDC:Fit"+num2str(ite_cur)
SetDataFolder $name1
name1="Fit"+num2str(ite_cur)
Build_MDCimage(name1,k_start,k_stop,Nb_k)   // enter here k window. Also needed in iteration.
name2="ImageMDC_"+name1
Convolution_Wave2D_YRes($Name2,res) 

index=ite_cur

name1="root:MDC:Fit"+num2str(index)+":largeur2_Fit"+num2str(index)
name2="root:MDC:Fit"+num2str(index)+":energy_Fit"+num2str(index)
DoWindow/F Largeur_VsN
if (v_flag==0)
	Display  $name1 vs $name2
	ModifyGraph rgb=(0,0,0)
	DoWindow/C Largeur_VsN
else
	AppendToGraph  $name1 vs $name2
endif	

		
do
	// Load convoluated image in ImageTool
	name="root:MDC:Fit"+num2str(index)+":Name2D_conv"
	Duplicate/O $name root:IMG:Image
	
	SetDataFolder "root:MDC"
	Duplicate/O w_coef_backup w_coef
	Fitting_MDC(" ")
	Save_results(" ")

	Iteration("Fit1","Fit"+num2str(index),"Fit"+num2str(index)+"b","Fit"+num2str(index+1),res,k_start,k_stop,Nb_k)
	
	index+=1
	
	name1="root:MDC:Fit"+num2str(index)+":largeur2_Fit"+num2str(index)
	name2="root:MDC:Fit"+num2str(index)+":energy_Fit"+num2str(index)
	DoWindow/F Largeur_VsN
	AppendToGraph  $name1 vs $name2
		
while (index<ite_cur+ite_ToGo)

end

