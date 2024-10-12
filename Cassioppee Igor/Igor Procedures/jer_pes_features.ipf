// ###################################################################
//  Igor Pro - JER PhotoEmission Features
// 
//  FILE: "jer_pes_features.ipf"
//                                    created: 06/10/2014 
//                                last update: 11/02/2015 
//  Author: Julien E. Rault
//  E-mail: julien.e.rault [at] gmail.com
//  www: https://sites.google.com/site/julienerault/
//  
//  Licence : This work is licensed under a Creative Commons Attribution 4.0 International License (http://creativecommons.org/licenses/by/4.0/)
// 
//  Description: 
//	Several macros and fitting functions useful for PhotoEmission-based experiments.

//  History
// 
//  modified   by  rev reason
//  ---------- --- --- -----------
//  2014-10-06 JER 1.0 original
//  2015-02-11 JER 2.0 addition of Angle to K converters functions
//  2015-02-19 JER 2.1 addition of Load_Cassiopee_Band_Mapping()
// ###################################################################

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma rtGlobals=1		// Use modern global access method.

Menu "PES analysis"
	"Background Shirley One Spectrum", Launch_BCG(1)
	"Background Shirley Full Folder", Launch_BCG(0)
	"-"
	"Angle Averaging One Spectrum", Launch_Angle_Average(1,0)
	"Angle Averaging One Spectrum - Kill", Launch_Angle_Average(1,1)
	"Angle Averaging Full Folder", Launch_Angle_Average(0,0)
	"Angle Averaging Full Folder - Kill", Launch_Angle_Average(0,1)
	"-"
	"Sequence Averaging One Spectrum", Launch_Sequence_Average(1,0)
	"Sequence Averaging One Spectrum - Kill", Launch_Sequence_Average(1,1)
	"Sequence Averaging Full Folder", Launch_Sequence_Average(0,0)	
	"Sequence Averaging Full Folder - Kill", Launch_Sequence_Average(0,1)
	"-"	
	"ARPES normalization 2D One Spectrum", Launch_ARPES_normalization(1,2)
	"ARPES normalization 2D Full Folder/5", Launch_ARPES_normalization(0,2)
	"ARPES normalization 3D One Spectrum", Launch_ARPES_normalization(1,3)
	"ARPES normalization 3D Full Folder", Launch_ARPES_normalization(0,3)
	"-"
	"3D angle to k conversion/6", Launch_convert_momentum_3D()
	"2D angle to k conversion/7", Launch_convert_momentum_2D()
	"-"
	"Export Waves to .txt files", SaveAll_as_Text()
	"Retrieve FS data - cassiopee", Load_Cassiopee_Band_Mapping(0,1)
	"Load a single Spectrum", Load_Single_Spectrum()
	"Retrieve RC data - galaxies", Retrieve_DATA_SCIENTA()
End


///////////
// Secret kz estimation proc'

Function estimate_kz()

Variable starting_hv = 20, hv_step = 1, local_hv, number_points = 1000

Variable c_lattice_para = 2.2, internal_potential = 15, work_function = 4, binding_energy = 0

Make/N=(number_points)/O $("kz_E")
Wave kz = $("kz_E")

Make/N=(number_points)/O $("kz_BZ")
Wave kz_BZ = $("kz_BZ")

SetScale/P x, starting_hv, hv_step, kz
SetScale/P x, starting_hv, hv_step, kz_BZ

Variable i = 0

Do
	local_hv = starting_hv + hv_step*i
	kz[i] = 0.512*sqrt(local_hv + internal_potential - work_function - binding_energy)
	kz_BZ[i] = kz[i]/(2*Pi/c_lattice_para)
	i += 1
While(i < DimSize(kz,0))

End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Launcher for the 3D angle to K converter

Function Launch_convert_momentum_3D()

Variable mounting_tilt = 0, mounting_rotation = 0

String s_popup_spectre =  SortList(WaveList("*",";","DIMS:3"),";",4), s_spectre = ""
Prompt s_spectre, "3D wave name: ", popup s_popup_spectre
Prompt mounting_tilt, "Sample tilt"
Prompt mounting_rotation, "Zero rotation"
DoPrompt "Choix de la wave 2D", s_spectre, mounting_tilt, mounting_rotation
Wave inwave = $(s_spectre)

AngleToK_3D(inwave, mounting_tilt, mounting_rotation)

End

// Idea taken from http://www.igorexchange.com/node/5751 adapted for Cassiopee and (scienta_angle,polar_angle,KE) data stack

Function AngleToK_3D(inwave, mounting_tilt, mounting_rotation)
	Wave inwave
	Variable mounting_tilt, mounting_rotation
	
	String newname = NameofWave(inwave)+"_k"
	Duplicate/O inwave, $newname
	Wave outwave = $newname

	Variable rows,columns,layers,xdelta,xoffset,ydelta,yoffset,zdelta,zoffset		// inwave parameters
	rows	= DimSize(inwave,0)
	columns	= DimSize(inwave,1)
	layers	= DimSize(inwave,2)
	xdelta	= DimDelta(inwave,0)
	xoffset	= DimOffset(inwave,0)
	ydelta	= DimDelta(inwave,1)
	yoffset	= DimOffset(inwave,1)
	zdelta	= DimDelta(inwave,2)
	zoffset	= DimOffset(inwave,2)
	
	Variable kxmin,kxmax,kxdelta,kymin,kymax,kydelta,Emax
	Emax	= zoffset + zdelta*(layers-1)
	kxmin	= 0.512*sqrt(Emax)*sin(pi/180*(xoffset+mounting_tilt))		// calculate the k boundaries (i.e., k at highest Ekin)
	kxmax	= 0.512*sqrt(Emax)*sin(pi/180*((xoffset+mounting_tilt+(rows-1)*xdelta)))
	kymin	= 0.512*sqrt(Emax)*sin(pi/180*(yoffset+mounting_rotation))		// calculate the k boundaries (i.e., k at highest Ekin)
	kymax	= 0.512*sqrt(Emax)*sin(pi/180*((yoffset+mounting_rotation+(columns-1)*ydelta)))	
	
	SetScale/I	x kxmin,kxmax,"Ang^-1", outwave			// scale the x axis
	SetScale/I	y kymin,kymax,"Ang^-1", outwave			// scale the y axis
	
	outwave = interp3D(inwave, 180/pi*asin((x)/ (0.512*sqrt(z)))-mounting_tilt, 180/pi*asin((y)/ (0.512*sqrt(z)))-mounting_rotation, z) // recalculate to k
	outwave = (NumType(outwave)==2) ? 0 : outwave		// replace NaNs (optional)

End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Launcher for the 2D angle to K converter

Function Launch_convert_momentum_2D()

Variable mounting_tilt = 0

String s_popup_spectre =  SortList(WaveList("*",";","DIMS:2"),";",4), s_spectre = ""
Prompt s_spectre, "2D wave name: ", popup s_popup_spectre
Prompt mounting_tilt, "Sample tilt"
DoPrompt "Choix de la wave 2D", s_spectre, mounting_tilt
Wave inwave = $(s_spectre)

AngleToK_2D(inwave, mounting_tilt)

End

// Idea taken from http://www.igorexchange.com/node/5751 adapted for Cassiopee and (KE, scienta_angle) data stack

Function AngleToK_2D(inwave, mounting_tilt)
	Wave inwave
	Variable mounting_tilt
	
	String newname = NameofWave(inwave)+"_k"
	Duplicate/O inwave, $newname
	Wave outwave = $newname

	Variable rows,columns,xdelta,xoffset,ydelta,yoffset		// inwave parameters
	rows	= DimSize(inwave,0)
	columns	= DimSize(inwave,1)
	xdelta	= DimDelta(inwave,0)
	xoffset	= DimOffset(inwave,0)
	ydelta	= DimDelta(inwave,1)
	yoffset	= DimOffset(inwave,1)
	
	Variable kmin,kmax,kdelta,Emax
	Emax	= xoffset + xdelta*(rows-1)
	kmin	= 0.512*sqrt(Emax)*sin(pi/180*(yoffset+mounting_tilt))		// calculate the k boundaries (i.e., k at highest Ekin)
	kmax	= 0.512*sqrt(Emax)*sin(pi/180*((yoffset+mounting_tilt+(columns-1)*ydelta)))
	SetScale/I	y kmin,kmax,"Ang^-1", outwave			// scale the y axis
	
	outwave = interp2D(inwave, x, 180/pi*asin((y)/ (0.512*sqrt(x)))-mounting_tilt) // recalculate to k
	outwave = (NumType(outwave)==2) ? 0 : outwave		// replace NaNs (optional)

	
End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Retrieve a series of spectrum from Igor Cassiopée

Function Load_Cassiopee_Band_Mapping(first_angle_theta,step_angle_theta)
Variable first_angle_theta, step_angle_theta

// Chemin des images .txt
NewPath/Q/C/O/M="Folder of the Spectra: " PathFiles
PathInfo PathFiles

String name_path = S_path
String name_RC = StringFromList(ItemsInList(name_path,":")-1,name_path,":")



// Liste des images en .asc
String list_images = SortList(IndexedFile(PathFiles, -1, ".txt"),";",16)
Variable angle_steps = ItemsInList(list_images, ";")

String Name = ""
Variable i = 0, j = 0, k = 0

String root_DF = GetDataFolder(1)

NewDataFolder/O/S $(":temp")

// Récupération des paramètres angulaires Scienta
LoadWave/k=2/Q/J/V={"\t","$",0,0}/L={0,11,1,0,0}/D/N=ref/P=PathFiles StringFromList(0,list_images,";")
Wave/T angle_list = $("ref1")
String angle_list_str = angle_list[0]
variable first_angle = str2num(StringFromList(0,angle_list_str," "))
variable angle_step = (str2num(StringFromList(ItemsInList(angle_list_str," ")-1,angle_list_str," ")) - str2num(StringFromList(0,angle_list_str," ")))/ItemsInList(angle_list_str," ")

// Récuparation des données

Do
	Name = StringFromList(k, list_images,";")
	LoadWave/Q/J/M/U={0,1,0,0}/D/L={0,45,0,0,0}/P=PathFiles Name
	Wave source = $("wave"+num2str(k))
	
	If(i == 0)
		SetDataFolder(root_DF)
		Make/O/N=(DimSize(source,1),angle_steps,Dimsize(source,0)) $(name_RC)
		Wave RC = $(name_RC)
		SetDataFolder(":temp")
	EndIf

	Do
		Do
			RC[j][k][i] = source[i][j]
			i += 1
		While(i < DimSize(source,0))
		i = 0
		j += 1
	While(j < DimSize(source,1))
	j = 0
	i = 0	
	k += 1
While(CmpStr(StringFromList(k,list_images,";"),"") != 0)

SetScale/P x, first_angle, angle_step, RC
SetScale/P y, first_angle_theta, step_angle_theta, RC
SetScale/P z, DimOffset(source,0), DimDelta(source,0), RC

KillDataFolder/Z $("::temp")

End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function Load_Single_Spectrum()

// Récupération des paramètres angulaires Scienta

LoadWave/Q/J/M/U={0,1,0,0}/D/L={0,45,0,0,0}

Wave loaded_wave = $(StringFromList(0,S_wavenames))

NewPath/Q/C/O S_path_parameters, S_path

LoadWave/k=2/Q/J/V={"\t","$",0,0}/L={0,11,1,0,0}/D/N=ref/P=S_path_parameters S_filename
Wave/T angle_list = $("ref1")
String angle_list_str = angle_list[0]
variable first_angle = str2num(StringFromList(0,angle_list_str," "))
variable angle_step = (str2num(StringFromList(ItemsInList(angle_list_str," ")-1,angle_list_str," ")) - str2num(StringFromList(0,angle_list_str," ")))/ItemsInList(angle_list_str," ")

SetScale/P y, first_angle, angle_step, loaded_wave

KillWaves/Z ref0, ref1

End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Retrieve a series of spectrum from Tango_Scienta

Function Retrieve_DATA_SCIENTA()

// Chemin des images .asc
NewPath/Q/C/O/M="Folder of the Spectra: " PathFiles
PathInfo PathFiles

String name_path = S_path
String name_RC = StringFromList(ItemsInList(name_path,":")-1,name_path,":")

// Liste des images en .asc
String list_images = IndexedFile(PathFiles, -1, "????")
Variable angle_steps = ItemsInList(list_images, ";")
String Name = ""
Variable i = 0, j = 0

String root_DF = GetDataFolder(1)

NewDataFolder/O/S $(":temp")

Do
	Name = StringFromList(i, list_images,";")
	LoadWave/G/M/Q/H/P=PathFiles Name
	Wave source = $("wave"+num2str(i))
	
	If(i == 0)
		SetDataFolder(root_DF)
		Make/O/N=(DimSize(source,0),angle_steps) $(name_RC)
		Wave RC = $(name_RC)
		SetDataFolder(":temp")
	EndIf

	Do
		RC[j][i] = source[j][1]
		j += 1
	While(j < DimSize(source,0))
	j = 0	
	i += 1
While(CmpStr(StringFromList(i,list_images,";"),"") != 0)

SetScale/P x, source[0][0], (source[1][0]-source[0][0]), RC
SetScale/P y, -2.5, 0.02, RC

KillDataFolder/Z $("::temp")

End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Save all 1D waves from the current folder as (row	intensity) .txt files

Function SaveAll_as_Text()

// Destination Path to be chosen by the user
NewPath/Q/C/O/M="Folder to put the text files: " PathFiles

// List of 1D waves
String list_waves = WaveList("*",";","DIMS:1")

String local_wave = ""
Variable i = 0

Do
	local_wave = StringFromList(i,list_waves,";")
	// Save the wave as .txt (overwrite existing .txt files having the same name !)
	Save/O/B/P=PathFiles/J/M="\r\n"/U={0,1,0,0} local_wave
	i += 1 
While(CmpStr(StringFromList(i,list_waves,";"),"")!=0)

End



// 1) Subtract background

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 									BCG Shirley										  //
// 									by Julien RAULT										  //
// 									v 2.0 July of 2013									  //
//									julien.e.rault@gmail.com
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// 2) Doniach-Sunjic fit function

// 3) Normalize ARPES data

// 4) Average over all angles Scienta files

// affichage du menu contextuel

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function Launch_BCG(type)
Variable type

Variable j = 0, type_BG = 1, passe = 0

Variable passeMax = 3	// Nombre d'itérations pour le calcul du fond 

Print "Procédure Background_Shirley"

Variable Imin,Imax, DimSpectres							
Variable maxi, maxiback

// Rassemblement des spectres en présence pour affichage dans le menu d'interaction
String s_spectre
String s_popup_spectre = SortList(Wavelist("*",";","DIMS:1"),";",4)

If(type)
	// Interaction utilisateur
	Prompt s_spectre, "Spectrum Name : ", popup s_popup_spectre
	Prompt passeMax, "Pass iterations : "
	Prompt type_BG, "Background type (0 = constant, 1 = Shirley, 2 = linear): "
	DoPrompt "Spectrum Information", s_spectre, type_BG, passeMax

	If(V_flag)
		Print "Procedure cancelled."
		Return 0
	EndIf

	Background_Shirley(type_BG, passeMax, s_spectre)
	
Else
	Variable i = 0
	Prompt passeMax, "Pass iterations : "
	Prompt type_BG, "Background type (1 = Shirley, 2 = linear): "
	DoPrompt "Spectrum Information", type_BG, passeMax

	If(V_flag)
		Print "Procedure cancelled."
		Return 0
	EndIf

	Do
		Background_Shirley(type_BG,passeMax,StringFromList(i,s_popup_spectre,";"))
		i += 1	
	While(cmpstr("",StringFromList(i,s_popup_spectre,";")) != 0)
EndIf

Print "Procédure terminée."

End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Function Background_Shirley(type_BG, passeMax, s_spectre)
Variable type_BG, passeMax
String s_spectre

Variable j = 0, passe = 0
Variable Imin,Imax, DimSpectres							
Variable maxi, maxiback

Wave ref = $(s_spectre)					// assignation des waves avec fond

DimSpectres = DimSize(ref,0)

// Chargement des données utiles pour le calcul du fond (cf. thèse ITA)
	//Wave energie = $(s_energie)
	
	Make/O/N=(DimSpectres) $("I_ss_B")
	Make/O/N=(DimSpectres) $(s_spectre+"_BG")				// création des waves fond
	Make/O/N=(DimSpectres) $(s_spectre+"_SF")					// création des nouvelles waves sans fond
	Wave temp = $(s_spectre+"_SF")								// assignation
	temp[] = 0
	Wave back =$(s_spectre+"_BG")					// assignation des fonds
	back[] = 0
	Wave temporaire = $("I_ss_B")
	temporaire[] = 0
	
	Imin = ref[0]
	Imax = ref[DimSpectres - 1]
	
	// suppression du fond signal
	Do
		temporaire[j] = ref[j] - Imax
		j += 1
	While(j < DimSpectres)
	temp[0] = temporaire[0]/2
	
	// suppression de la diffusion inélastique

	Do
		j = 0
		Do
			If(type_BG == 1)	// Si type_BG = 1 : Shirley
				temp[j] = temporaire[j] - temp[0]*(sum(temporaire,j,DimSpectres)/sum(temporaire,0,DimSpectres))			// formule de Shirley qui donne directement l'intensité	
				back[j] = ref[j] - temp[j]
			ElseIf(type_BG == 2)		// autre type BG : linéaire
				back[j] = Imin*0.98 + ((Imax - Imin*0.98)/(DimSpectres - 0))*j
				temp[j] = ref[j] - back[j]
			Elseif(type_BG == 0)		// autre type BG : constant
		
				back[j] = Imax
				temp[j] = ref[j] - back[j]
			Else
				back[j] = 0		// Fake BG
				temp[j] = ref[j] - back[j]
			EndIf				
			j += 1
		While(j < DimSpectres)
		j = 0
		Do
			temporaire[j] = temp[j]
			j += 1
		While(j < DimSpectres)	
			
		If(type_BG)
			temp[0] = temporaire[0]/2
		EndIf
		
		passe +=1
	While(passe < passeMax)	
	
	temp[0] = temp[1]
	j = 0

String type = "constant;Shirley;linear;None"
Print "Background type "+num2str(type_BG)+" = "+StringFromList(type_BG,type,";")

SetScale/P x DimOffset(ref,0),DimDelta(ref,0),"eV", back // _BG
SetScale/P x DimOffset(ref,0),DimDelta(ref,0),"eV", temp	// _SF

Note /K temp, note(ref)
Note /K back, note(ref)

// Suppress normalized waves which are annoying...

KillWaves/Z $("I_ss_B")

Return 1	
	///////////////////// fin de la normalisation à la Shirley D.A.
	
End

Function erreur_xps()

NewPanel/N=Erreur/K=1
TitleBox title_box, anchor = MC, title="ERREUR !", frame = 0, win=Erreur, fsize = 16, fstyle = 0, disable = 2, fixedSize = 1, size ={300,150}
Button button_ok proc=quitter_erreur_xps, appearance = {native}, title = "QUITTER", win = Erreur, pos={100,150}, size={100,20}

End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Additional functions

Function quitter_erreur_xps (ctrlName) : ButtonControl
// Fonction associée à OK de erreur_xps
String ctrlName
KillWindow Erreur
Return 1
End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function Launch_ARPES_normalization(type, dimension)
Variable type, dimension

String s_popup_spectre = ""
String s_spectre = ""

// Rassemblement des spectres en présence pour affichage dans le menu d'interaction
If(dimension == 2)
	s_popup_spectre= SortList(Wavelist("*",";","DIMS:2"),";",4)
Else
	s_popup_spectre = SortList(Wavelist("*",";","DIMS:3"),";",4)
EndIf

If(type)
	// Interaction utilisateur
	Prompt s_spectre, "Spectrum Name : ", popup s_popup_spectre
	DoPrompt "Spectrum Information", s_spectre

	If(V_flag)
		Print "Procedure cancelled."
		Return 0
	EndIf

	If(dimension == 2)
		ARPES_normalization_2D(s_spectre)
	Else
		ARPES_normalization_3D(s_spectre)
	EndIf
	
Else
Variable i = 0

	If(dimension == 2)
		Do
			ARPES_normalization_2D(StringFromList(i,s_popup_spectre,";"))
			i += 1	
		While(cmpstr("",StringFromList(i,s_popup_spectre,";")) != 0)
	Else
		Do
			ARPES_normalization_3D(StringFromList(i,s_popup_spectre,";"))
			i += 1	
		While(cmpstr("",StringFromList(i,s_popup_spectre,";")) != 0)
	EndIf
EndIf

End

Function ARPES_normalization_2D(s_spectre)
String s_spectre
	
Wave original = $(s_spectre)

Make/O/N=(DimSize(original,0), DimSize(original,1)) $(s_spectre+"_n")
Wave normed = $(s_spectre+"_n")
normed[][] = 0

Make/O/N=(DimSize(original,1)) $(s_spectre+"_XPD")
Wave XPD_normed = $(s_spectre+"_XPD")
XPD_normed[] = 0

Make/O/N=(DimSize(original,0)) $(s_spectre+"_DOS")
Wave DOS_normed = $(s_spectre+"_DOS")
DOS_normed[] = 0

Make/O/N=(DimSize(original,0), DimSize(original,1)) $("XPD_n")
Wave tempXPD_normed = $("XPD_n")

Make/O/N=(DimSize(original,0), DimSize(original,1)) $("DOS_n")
Wave tempDOS_normed = $("DOS_n")

//Variable E_min_XPD = 0, E_max_XPD = DimSize(original,0), k_min_DOS = 0, k_max_DOS = DimSize(original,1)

Variable E_min_XPD = 0, E_max_XPD = DimSize(original,0), k_min_DOS = 0, k_max_DOS = 100

// Step 1: XPD normed

Variable E = E_min_XPD, k = 0
Do
	Do
		XPD_normed[k] += original[E][k]
		k += 1
	While(k < DimSize(original,1))
	k = 0
	E += 1
While(E < E_max_XPD)
	
// Step 2: DOS normed

k = k_min_DOS
E = 0

Do
	Do
		DOS_normed[E] += original[E][k]
		E += 1
	While(E < DimSize(original,0))
	E = 0
	k += 1
While(k < k_max_DOS)

// Step 3: Remove XPD

tempXPD_normed[][] = original[p][q]/XPD_normed[q]

// Step 4 : Remove DOS 

Variable mean_bg = mean(DOS_normed)/10

tempDOS_normed[][] = tempXPD_normed[p][q]/(DOS_normed[p]+mean_bg)
	
// Step 5 : Normalize

Variable maxi = Wavemax(tempDOS_normed)
normed[][] = tempDOS_normed[p][q]/maxi

SetScale/P x DimOffset(original,0),DimDelta(original,0),"eV", normed
SetScale/P y DimOffset(original,1),DimDelta(original,1),"deg", normed

SetScale/P x DimOffset(original,1),DimDelta(original,1),"deg", XPD_normed
SetScale/P x DimOffset(original,0),DimDelta(original,0),"deg", DOS_normed

KillWaves/Z tempDOS_normed, tempXPD_normed

Print "**XPD normalization has been done between E = "+num2str(DimOffset(original,0)+DimDelta(original,0)*E_min_XPD)+" and "+num2str(DimOffset(original,0)+DimDelta(original,0)*E_max_XPD)+" eV**"
Print "**DOS normalization has been done between angle = "+num2str(DimOffset(original,1)+DimDelta(original,1)*k_min_DOS)+" and "+num2str(DimOffset(original,1)+DimDelta(original,1)*k_max_DOS)+" deg**"

End

// ################################################################################################################################

Function ARPES_normalization_3D(s_spectre)
String s_spectre
	
Wave original = $(s_spectre)

Make/O/N=(DimSize(original,0), DimSize(original,1),DimSize(original,2)) $(s_spectre+"_n")
Wave normed = $(s_spectre+"_n")
normed[][][] = 0

Make/O/N=(DimSize(original,1),DimSize(original,2)) $(s_spectre+"_XPD")
Wave XPD_normed = $(s_spectre+"_XPD")
XPD_normed[][] = 0

Make/O/N=(DimSize(original,0)) $(s_spectre+"_DOS")
Wave DOS_normed = $(s_spectre+"_DOS")
DOS_normed[] = 0

Make/O/N=(DimSize(original,0), DimSize(original,1),DimSize(original,2)) $("tempXPD_n")
Wave tempXPD =  $("tempXPD_n")
tempXPD[][][] = 0

Make/O/N=(DimSize(original,0), DimSize(original,1),DimSize(original,2)) $("tempDOS_n")
Wave tempDOS =  $("tempDOS_n")
tempDOS[][][] = 0

Variable E_min_XPD = 0, E_max_XPD = DimSize(original,0), k_min_DOS = 0, k_max_DOS = DimSize(original,1)

//Variable E_min_XPD = 0, E_max_XPD = DimSize(original,0), k_min_DOS = 0, k_max_DOS = DimSize(original,1)

// Step 1: XPD normed

Variable E = E_min_XPD, k = 0, s = 0
Do
	Do
		Do
			XPD_normed[k][s] += original[E][k][s]
			k += 1
		While(k < DimSize(original,1))
		k = 0
		s += 1
	While(s < DimSize(original,2))
	k = 0
	s = 0
	E += 1
While(E < E_max_XPD)

// Step 2: DOS normed

k = 0
s = 0
E = 0

Do
	Do
		Do
			DOS_normed[E] += original[E][k][s]
			E += 1
		While(E < DimSize(original,0))
		E= 0
		k += 1
	While(k < DimSize(original,1))
	k = 0
	s += 1
While(s < DimSize(original,2))

// Step 3: Remove XPD

tempXPD[][][] = original[p][q][r]/XPD_normed[q][r]

// Step 4 : Remove DOS 

Variable mean_bg = mean(DOS_normed)/10

tempDOS[][][] = tempXPD[p][q][r]/(DOS_normed[p]+mean_bg)
	
// Step 5 : Normalize

Variable maxi = Wavemax(tempDOS)
normed[][][] = tempDOS[p][q][r]/maxi

SetScale/P x DimOffset(original,0),DimDelta(original,0),"eV", normed
SetScale/P y DimOffset(original,1),DimDelta(original,1),"deg", normed
SetScale/P z DimOffset(original,2),DimDelta(original,2),"deg", normed

SetScale/P x DimOffset(original,1),DimDelta(original,1),"deg", XPD_normed
SetScale/P y DimOffset(original,2),DimDelta(original,2),"deg", XPD_normed

SetScale/P x DimOffset(original,0),DimDelta(original,0),"eV", DOS_normed

KillWaves/Z tempXPD, tempDOS


Print "**XPD normalization has been done between E = "+num2str(DimOffset(original,0)+DimDelta(original,0)*E_min_XPD)+" and "+num2str(DimOffset(original,0)+DimDelta(original,0)*E_max_XPD)+" eV**"
Print "**DOS normalization has been done between angle = "+num2str(DimOffset(original,1)+DimDelta(original,1)*k_min_DOS)+" and "+num2str(DimOffset(original,1)+DimDelta(original,1)*k_max_DOS)+" deg**"

End

Function Angle_averaged_Scienta(s_spectre)
String s_spectre

Wave original = $(s_spectre)

// Get rid of the edges of the image !!
Variable yScale_start = 0, yScale_stop = DimSize(original,1)

Print "**Averaging have been done between channel "+num2str(yScale_start)+" and "+num2str(yScale_stop)+"**"

Make/O/N=(DimSize(original,0)) $(s_spectre+"_avg")
Wave angle_averaged = $(s_spectre+"_avg")
angle_averaged[] = 0

Variable i = yScale_start
Do
	angle_averaged[] += original[p][i]
	i += 1
While(i < yScale_stop)

angle_averaged /= (yScale_stop-yScale_start)+1

SetScale/P x DimOffset(original,0),DimDelta(original,0),"eV", angle_averaged
Note /K angle_averaged, note(original)

End

Function Launch_Angle_Average(type, kill)
Variable type, kill

// Rassemblement des spectres en présence pour affichage dans le menu d'interaction
String s_spectre = ""
String s_popup_spectre = SortList(Wavelist("*",";","DIMS:2"),";",16)

If(type)
	// Interaction utilisateur
	Prompt s_spectre, "Spectrum Name : ", popup s_popup_spectre
	DoPrompt "Spectrum Information", s_spectre

	If(V_flag)
		Print "Procedure cancelled."
		Return 0
	EndIf

	Angle_averaged_Scienta(s_spectre)
	If(kill == 1)
		KillWaves/Z $(s_spectre)
	EndIf	
Else
Variable i = 0
	Do
		Angle_averaged_Scienta(StringFromList(i,s_popup_spectre,";"))
		If(kill == 1)
			KillWaves $(StringFromList(i,s_popup_spectre,";"))
		EndIf	
		i += 1	
	While(cmpstr("",StringFromList(i,s_popup_spectre,";")) != 0)

EndIf

End

// ################################################################################################################################

Function Sequence_averaged_Scienta(s_spectre)
String s_spectre
	
Wave original = $(s_spectre)
Make/O/N=(DimSize(original,0), DimSize(original,1)) $(s_spectre+"_seq")
Wave seq_averaged = $(s_spectre+"_seq")
seq_averaged[][] = 0

Variable k = 0

Do
	seq_averaged[][] += original[p][q][k]
	k += 1
While(k < DimSize(original,2))

seq_averaged /= DimSize(original, 2)

SetScale/P x DimOffset(original,0),DimDelta(original,0),"eV", seq_averaged
SetScale/P y DimOffset(original,1),DimDelta(original,1),"°", seq_averaged

Note /K seq_averaged, note(original)

End

Function Launch_Sequence_Average(type, kill)
Variable type, kill

// Rassemblement des spectres en présence pour affichage dans le menu d'interaction
String s_spectre = ""
String s_popup_spectre = SortList(Wavelist("*",";","DIMS:3"),";",4)

If(type)
	// Interaction utilisateur
	Prompt s_spectre, "Spectrum Name : ", popup s_popup_spectre
	DoPrompt "Spectrum Information", s_spectre

	If(V_flag)
		Print "Procedure cancelled."
		Return 0
	EndIf

	Sequence_averaged_Scienta(s_spectre)
	If(kill == 1)
		KillWaves/Z $(s_spectre)
	EndIf	
	
Else
Variable i = 0
	Do
		//Print StringFromList(i,s_popup_spectre,";")
		Sequence_averaged_Scienta(StringFromList(i,s_popup_spectre,";"))
		If(kill == 1)
			KillWaves/Z $(StringFromList(i,s_popup_spectre,";"))
		EndIf	
		i += 1	
	While(cmpstr("",StringFromList(i,s_popup_spectre,";")) != 0)

EndIf

End




