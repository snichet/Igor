// ###################################################################
//  Igor Pro - JER Additional Functions
// 
//  FILE: "jer_add_functions.ipf"
//                                    created: 06/10/2014 
//                                last update: 06/10/2014 
//  Author: Julien E. Rault
//  E-mail: julien.e.rault [at] gmail.com
//  www: https://sites.google.com/site/julienerault/
//  
//  Licence : This work is licensed under a Creative Commons Attribution 4.0 International License (http://creativecommons.org/licenses/by/4.0/)
// 
//  Description: 
//	Several macros and functions for miscellaneous operations on Igor Pro.

//  History
// 
//  modified   by  rev reason
//  ---------- --- --- -----------
//  2014-10-06 JER 1.0 original
// ###################################################################

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

Menu "Additional Functions"

	"Landscape Layout",paysage()
	"Retrieve Data from Images", Retrieve_Data()
	"Clean Multifit folders", Clean_MFP()
	"-"
	"Generate Iterative Table", table_nouvelle()
	"Generate Ferroelectric P-E Loop", Cycle_PE()
	"-"
	"Split 2D wave into 1D waves", split_wave_2D()
	"Split 3D wave into 2D waves", split_wave_3D()
	"Recover 3D wave from 2D waves", recover_wave_3D("Nd")
	"Recover 2D wave from 1D waves", recover_wave_2D("Ni")
	"Extract a 1D wave from a 2D wave", Extract_2D()
	"Extract a 1D wave from a 3D wave", Extract_3D()
	"Normalize all 1D waves", normalize_all()
	"-"
	"Converter", Converter()

End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function normalize_all()

String list_wave = SortList(WaveList("*",";","DIMS:1"),";",4)
Variable maximum = 0, j = 0, i = 0
String name = ""

Do
	Name = StringFromList(i, list_wave,";")
	Wave source = $(Name)
	
	maximum = WaveMax(source)
	
	Do
		source[j] = source[j]/maximum
		j += 1
	While(j < DimSize(source,0))
	
	print "The maximum value is", num2str(maximum)
	
	j = 0
	
	i += 1
While(CmpStr(StringFromList(i,list_wave,";"),"") != 0)

End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function split_wave_2D()

String s_popup_spectre =  SortList(WaveList("*",";","DIMS:2"),";",4), s_spectre = ""
Prompt s_spectre, "Nom de la wave 2D : ", popup s_popup_spectre
DoPrompt "Choix de la wave 2D", s_spectre
Wave wave2D = $(s_spectre)

Variable j = 0
String name = ""
Do
	sprintf name, "%s_%03.0f", s_spectre, j
	Make/O/N=(DimSize(wave2D,0)) $(name)
	Wave temp = $(name)
	
	temp[] = wave2D[p][j]		// Matrix operation: copies all rows (use p for rows, q for columns, r for layers)
	
	SetScale/P x, DimOffset(wave2D,0), DimDelta(wave2D,0), temp
	j += 1
While(j < DimSize(wave2D,1))

End

Function split_wave_3D()

String s_popup_spectre =  SortList(WaveList("*",";","DIMS:3"),";",4), s_spectre = ""
Prompt s_spectre, "Nom de la wave 3D : ", popup s_popup_spectre
DoPrompt "Choix de la wave 3D", s_spectre
Wave wave3D = $(s_spectre)

Variable k = 0

String name = ""
Do
	sprintf name, "%s_%03.0f", s_spectre, k
	Make/O/N=(DimSize(wave3D,0),DimSize(wave3D,1)) $(name)
	Wave temp = $(name)
	
	temp[][] = wave3D[p][q][k]
	
	SetScale/P x, DimOffset(wave3D,0), DimDelta(wave3D,0), temp
	SetScale/P y, DimOffset(wave3D,1), DimDelta(wave3D,1), temp
	k += 1
While(k < DimSize(wave3D,2))

End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Useful functions (2D to 3D and 1D to 2D) but not on the menu !!
//////////////////////////////////////////////////////////////////////////////////////////////////

Function recover_wave_3D(part_name)
String part_name

String s_popup_spectre =  SortList(WaveList("*"+part_name+"*",";","DIMS:2"),";",16), s_spectre = ""

Variable i = 0, j = 0, k = 0

Wave original = $(StringFromList(0,s_popup_spectre,";"))

Make/N=(DimSize(original,0),DimSize(original,1),ItemsInList(s_popup_spectre,";")) $(part_name+"_3D")
Wave wave3D = $(part_name+"_3D")

SetScale/P x, DimOffset(original,0), DimDelta(original,0), wave3D
SetScale/P y, DimOffset(original,1), DimDelta(original,1), wave3D

String name = ""
Do
	Wave temp = $(StringFromList(k,s_popup_spectre,";"))
	
	wave3D[][][k] = temp[p][q]
	
	k += 1
While(k < DimSize(wave3D,2))

End

Function recover_wave_2D(part_name)
String part_name

String s_popup_spectre =  SortList(WaveList("*"+part_name+"*",";","DIMS:1"),";",16), s_spectre = ""

Variable k = 0

Wave original = $(StringFromList(0,s_popup_spectre,";"))

Make/N=(DimSize(original,0),ItemsInList(s_popup_spectre,";")) $(part_name+"_2D")
Wave wave2D = $(part_name+"_2D")

SetScale/P x, DimOffset(original,0), DimDelta(original,0), wave2D

String name = ""
Do
	Wave temp = $(StringFromList(k,s_popup_spectre,";"))
	wave2D[][k] = temp[p]
	k += 1
While(k < DimSize(wave2D,1))

End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function Clean_MFP()
// Delete every folder in MultIPeakFit2 which is not CheckPoint (*CP)

String DataFolder =  "root:Packages:MultiPeakFit2:", folder = "", last_letter = ""
SetDataFolder DataFolder
DFREF dfr = GetDataFolderDFR()
Variable i = 0, N_objects = CountObjectsDFR(dfr, 4)

Do
	folder = GetIndexedObjNameDFR(dfr, 4, i)
	If(!StringMatch(folder, "*CP"))
		KillDataFolder/Z DataFolder + folder
	EndIf
	i += 1

While(i < N_objects)

SetDataFolder "root:"

End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function Converter()

Variable quantite = 1
String unite_avant = "eV", unite_apres = "nm"
String popup_unites = "eV;nm;Hz"

Prompt quantite, "Value to convert"
Prompt unite_avant, "Before", popup popup_unites
Prompt unite_apres, "After", popup popup_unites
DoPrompt "Converter", quantite, unite_avant, unite_apres

If(V_flag == 1)
	Print "Conversion Failure."
	Return 0
EndIf

Variable resultat = 0
Variable h_planck = 6.626068*10^(-34)
Variable c_vide = 299792458
Variable q_elementaire = 1.60217653*10^(-19)

If(StringMatch(unite_avant,"eV"))
	If(StringMatch(unite_apres,"nm"))
		resultat = (h_planck*c_vide)/(quantite*q_elementaire)
		resultat *= 10^(9)
	EndIf
	If(StringMatch(unite_apres,"hz"))
		resultat = (quantite*q_elementaire)/h_planck
	EndIf
EndIf

If(StringMatch(unite_avant,"nm"))
	If(StringMatch(unite_apres,"eV"))
		quantite *= 10^(-9)
		resultat = (h_planck*c_vide)/(quantite*q_elementaire)
	EndIf
	If(StringMatch(unite_apres,"hz"))
		quantite *= 10^(-9)
		resultat = c_vide/quantite
	EndIf
EndIf

If(StringMatch(unite_avant,"hz"))
	If(StringMatch(unite_apres,"eV"))
		resultat = (h_planck*quantite)/q_elementaire
	EndIf
	If(StringMatch(unite_apres,"nm"))
		resultat = c_vide/quantite
		resultat *= 10^(9)
	EndIf
EndIf

Print num2str(resultat)+" "+unite_apres
Return resultat 

End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function paysage()
NewLayout/P=Landscape
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function table_nouvelle()

Variable debut=0,fin=0,pas=0
String/G G_nom_table
String nom_table= G_nom_table

Prompt debut, "Première valeur :"
Prompt fin, "Dernière valeur :"
Prompt pas, "Pas entre les valeurs :"
Prompt nom_table, "Nom de la Wave :"
DoPrompt "Information sur la table à créer", debut,fin,pas,nom_table

If(V_flag)
	Print "Procédure annulée."
	Return 0
EndIf

Variable i = 0

Make/O/N=((fin-debut)/pas+1) $(nom_table)
Wave table = $(nom_table)

Do
	table[i] = debut + i*pas
	i += 1
While(i < ((fin-debut)/pas)+1)

End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Retrieve data from an image

Function Retrieve_Data()

String nom_image=""
Variable axe_y_min=0, axe_y_max=0

Prompt axe_y_min, "First y value:"
Prompt axe_y_max, "Last y value:"
Prompt nom_image, "Image name: "
DoPrompt "Data information", axe_y_min,axe_y_max,nom_image

Variable coul_R = 255, coul_V = 0, coul_B = 255
Prompt coul_R, "Red value:"
Prompt coul_V, "Green value:"
Prompt coul_B, "Blue value:"
DoPrompt "Curve color", coul_R,coul_V,coul_B

If(V_flag)
	Print "Procedure cancelled."
	Return 0
EndIf

ImageLoad

Wave avant = $(S_fileName)
Duplicate avant, $(nom_image)
KillWaves/Z avant
Wave image = $(nom_image)

Variable i = 0, j = 0, k = 0

Make/o/n=(DimSize(image,0)) $(nom_image+"_data")
Wave resultat = $(nom_image+"_data")

Do
	Do
		If(image[i][j][0] == coul_R && image[i][j][1] == coul_V && image[i][j][2] == coul_B)
			resultat[i] = -j
		EndIf
		j += 1
	While(j<DimSize(image,1))
	j = 0
	
	i +=1
While(i<DimSize(image,0))

lissage(nom_image,DimSize(image,0),DimSize(image,1),axe_y_max)

End

Function lissage(nom_image,long1,long2,axe_y_max)
String nom_image
Variable long1,long2,axe_y_max

Variable i=0, iMin = 0, iMax = 0
Wave resultat = $(nom_image+"_data")

Do
	iMin = i
	i += 1
While(resultat[i]==0)
i += 50
Do
	iMax = i
	i += 1
While(resultat[i] != 0 && i < long1)

i = iMin
Do
	resultat[i] = axe_y_max + (resultat[i]+0.00001)*axe_y_max/(long2-1)
	i += 1
While(i<iMax)

i = 0
Do
	If(iMin != 0)
		resultat[i] = resultat[iMin+1]*(1+(i-iMin)/(iMin))
	EndIf
	i += 1
While(i<iMin+1)

i = iMax - 1
Do
	resultat[i+1] = resultat[iMax-1]*(1-(i+1-iMax)/(long1-iMax))
	i += 1

While(i<long1)

End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function Extract_2D()

String s_popup_spectre = SortList(WaveList("*",";","DIMS:2"),";",4), s_spectre = ""
Prompt s_spectre, "2D wave name:", popup s_popup_spectre
DoPrompt "Choose the 2D wave", s_spectre
Wave wave2D = $(s_spectre)

If(V_flag)
	Print "Procedure cancelled."
	Return 0
EndIf

// Choix utilisateurs terminés

String s_choix = "Row"
Variable ligne_debut = 0, ligne_fin = DimSize(wave2D,0), colonne_debut = 0, colonne_fin = DimSize(wave2D,1), l = 0, c = 0, i = 0
Prompt s_choix, "Extraction de lignes ou de colonnes : " popup "lignes;colonnes"
Prompt ligne_debut, "Début de ligne entre 0 et "+num2str(DimSize(wave2D,0))+ " : "
Prompt ligne_fin, "Fin de ligne entre 0 et "+num2str(DimSize(wave2D,0))+ " : "
Prompt colonne_debut, "Début colonne entre 0 et "+num2str(DimSize(wave2D,1))+" : "
Prompt colonne_fin, "Fin de colonne entre 0 et "+num2str(DimSize(wave2D,1))+" : "

DoPrompt "Infos sur l'extraction", s_choix, ligne_debut, ligne_fin, colonne_debut, colonne_fin

If(V_flag)
	Print "Procédure annulée."
	Return 0
EndIf

// Si l'utilisateur choisit "colonnes" i.e. CmpStr(s_choix, "colonnes") = 0, on extrait le long des colonnes de colonne_debut à colonne_fin (moyenné) et 
// on retourne une wave 1D entre entre ligne _debut et ligne_fin

If(!CmpStr(s_choix,"colonnes"))

	Make/O/N=(ligne_fin-ligne_debut+1) $("colonne_"+num2str(colonne_debut)+"_"+num2str(colonne_fin))
	Wave li_resultat = $("colonne_"+num2str(colonne_debut)+"_"+num2str(colonne_fin))
	c = colonne_debut
	i = 0
	
	Do
		Do
			li_resultat[i] += wave2D[i+ligne_debut][c]
			i += 1
		While(i < (ligne_fin-ligne_debut+1))
		i = 0
		c += 1
	While(c < (colonne_fin+1))
	
	li_resultat /= (colonne_fin - colonne_debut + 1)

// Si l'utilisateur choisit "lignes"...
ElseIf(!CmpStr(s_choix,"lignes"))

	Make/O/N=(colonne_fin-colonne_debut+1) $("ligne_"+num2str(ligne_debut)+"_"+num2str(ligne_fin))
	Wave co_resultat = $("ligne_"+num2str(ligne_debut)+"_"+num2str(ligne_fin))
	l = ligne_debut
	i = 0
	
	Do
		Do
			co_resultat[i] += wave2D[l][i+colonne_debut]
			i += 1
		While(i < (colonne_fin - colonne_debut + 1))
		i = 0
		l += 1
	While(l < (ligne_fin+1))
	
	co_resultat /= (ligne_fin - ligne_debut + 1)
EndIf

Print "Procédure 2D to 1D terminée."

End

// Même chose pour les waves 3D sans possibilité de moyenner : on ne prend un spectre selon une direction qu'en un point précis pour les deux autres directions.

Function Extract_3D()

String s_popup_spectre =  SortList(WaveList("*",";","DIMS:3"),";",4), s_spectre = ""
Prompt s_spectre, "Nom de la wave 3D : ", popup s_popup_spectre
DoPrompt "Choix de la wave 3D", s_spectre
Wave wave3D = $(s_spectre)

If(V_flag)
	Print "Procédure annulée."
	Return 0
EndIf

// Choix utilisateurs terminés

Variable ligne = -1, colonne = -1, hauteur = -1,  l = 0, c = 0, h = 0, i = 0
Prompt ligne, "Numéro de ligne entre 0 et "+num2str(DimSize(wave3D,0))+", -1 pour extraire selon cette direction : "
Prompt colonne, "Numéro de colonne entre 0 et "+num2str(DimSize(wave3D,1))+", -1 pour extraire selon cette direction : "
Prompt hauteur, "Numéro de hauteur entre 0 et "+num2str(DimSize(wave3D,2))+", -1 pour extraire selon cette direction : "
DoPrompt "Infos sur l'extraction", ligne, colonne, hauteur

If(V_flag)
	Print "Procédure annulée."
	Return 0
EndIf

// Si la dimension est en -1, alors on extrait selon cette dimension sur le point dont les coordonnées sont données par les deux autres dimensions

If(ligne == -1)
	Make/O/N=(dimsize(wave3D,0)) $("point_c"+num2str(colonne)+"_h"+num2str(hauteur))
	Wave li_resultat = $("point_c"+num2str(colonne)+"_h"+num2str(hauteur))
	Do
		li_resultat[i] = wave3D[i][colonne][hauteur]
		i += 1
	While(i < DimSize(wave3D,0))
ElseIf(colonne == -1)
	Make/O/N=(dimsize(wave3D,1)) $("point_l"+num2str(ligne)+"_h"+num2str(hauteur))
	Wave co_resultat = $("point_l"+num2str(ligne)+"_h"+num2str(hauteur))
	Do
		co_resultat[i] = wave3D[ligne][i][hauteur]
		i += 1
	While(i < DimSize(wave3D,1))
ElseIf(hauteur == -1)
	Make/O/N=(dimsize(wave3D,2)) $("point_l"+num2str(ligne)+"_c"+num2str(colonne))
	Wave ha_resultat = $("point_l"+num2str(ligne)+"_c"+num2str(colonne))
	Do
		ha_resultat[i] = wave3D[ligne][colonne][i]
		i += 1
	While(i < DimSize(wave3D,2))
EndIf


Print "Procédure 3D to 1D terminée."

End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function Choisir_Folder()
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Fonction chargée d'enregistrer en String global un choix de Dossier de l'utilisateur pour des 		  //
// opérations ultérieures. Demande Sigma si demande = 1										  //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

String s_Dossier="", liste_Dossier = "", s_Dossier_liste = ""

SetDataFolder "root:"
liste_Dossier = DataFolderDir(1)		// Listage de tous les Dossiers
String/G choix_Dossier = ""
Variable i = 0

Do
	If(StringMatch(liste_Dossier[i+8],","))
		s_Dossier_liste[i] = ";"					// Remplacement des virgules par des points-virgules (eux sont compris par popup)
	Else
		s_Dossier_liste[i] = liste_Dossier[i+8]		// Suppression de "FOLDERS:" au début de liste_Dossier
	EndIf
	i += 1
While(i<(StrLen(liste_Dossier)-10))

s_Dossier_liste += ";root:;"

// l'utilisateur choisit la série à modIfier
Prompt s_Dossier, "Série d'images à choisir : ", popup s_Dossier_liste
DoPrompt "Choix de la série d'images", s_dossier

If(V_flag)
	Return 0
EndIf

// son choix devient une Variable globale
choix_Dossier = s_Dossier

Return 1

End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Fonction qui crée un cycle P-E de base pour structure MFM parfaitement écrantée
// Paramètre d'entrée : P saturation, P rémanent et champ coercitif

Function Cycle_PE()

Variable Pr = 1.5, Ps = 2, Ec = 100, eps = 100, points = 1000, Emax = 500
String graph = "oui"
Prompt Pr, "Polarisation Rémanente en uC/cm²"
Prompt Ps, "Polarisation à saturation en uC/cm²"
Prompt Ec, "Champ coercitif en kV/cm"
Prompt Emax, "Champ maximal testé en kV/cm"
Prompt eps, "Permittivité matériau"
Prompt points, "Nombre de points"
Prompt graph, "Afficher le graph ?" popup "oui;non"
DoPrompt "Infos sur le cycle", Pr, Ps, Ec, Emax, eps, points, graph

If(V_flag)
	Print "Procédure annulée"
	Return 0
EndIf

Variable i = 0, delta = Ec/(ln((1+Pr/Ps)/(1-Pr/Ps)))

// Définition du domaine en Champ Electrique : +/- (3* Ec)

Variable Emin = -Emax
Variable pas = (Emax - Emin)/points
Variable permittivite_vide = 8.85*10^(-12)

// Calcul de la polarisation (référence Choi, APL 98, 102901, 2011)

Make/O/N=(points+1) Electric_Field
Wave E = $("Electric_Field")
Make/O/N=(points+1) Polarization_P
Wave PP = $("Polarization_P")
Make/O/N=(points+1) Polarization_M
Wave PM = $("Polarization_M")

Do
	E[i] = Emin + pas*i
	PP[i] = Ps*tanh((E[i] - Ec)/(2*delta))+E[i]*10^7*eps*permittivite_vide
	PM[i] = Ps*tanh((E[i] + Ec)/(2*delta))+E[i]*10^7*eps*permittivite_vide
	// Ajout d'une contribution diélectrique simple (avec eps constant). Le jeu d'unité introduit un facteur 10^7 pour avoir des uC/cm² à gauche et utiliser des kV/cm à droite
	i += 1
While(i < (points+1))

If(!CmpStr("oui",graph))
	Execute("polarization_graph_PE("+num2str(1.2*Emin)+","+num2str(1.2*Emax)+","+num2str(1.2*Round(PP[DimSize(PP,0)-1]))+","+num2str(1.2*Round(PP[0]))+")")
EndIf

End

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Window polarization_graph_PE(bottom_L,Bottom_R,Left_U,Left_D) : Graph
	Variable bottom_L,bottom_R,left_U,left_D
	PauseUpdate; Silent 1		// building window...
	Display /W=(306.75,203,831,543.5) Polarization_P,Polarization_M vs Electric_Field
	ModifyGraph lSize=3
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2
	ModifyGraph zero=1
	ModifyGraph mirror=1
	ModifyGraph fSize=20
	ModifyGraph standoff=0
	ModifyGraph axThick=2
	ModifyGraph gridStyle(left)=3
	ModifyGraph gridHair(left)=1
	ModifyGraph zeroThick=1
	Label left "Polarization (\\F'Symbol'm\\F'Arial'C/cm²)"
	Label bottom "Electric Field (kV/cm)"
	SetAxis left Left_D,Left_U
	SetAxis bottom bottom_L,bottom_R
	SetDrawLayer UserFront
	SetDrawEnv linethick= 2,arrow= 1
	DrawLine 0.587272727272727,0.665689149560117,0.634545454545455,0.542521994134897
	SetDrawEnv linethick= 2,arrow= 2
	DrawLine 0.376363636363636,0.472140762463343,0.423636363636364,0.348973607038123
EndMacro


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Change l'extension d'une chaine de caractère.
Function/S change_extension(input_string,new_extension)
String input_string, new_extension

Variable i = 0
String output_string = ""

Do
	output_string[i] = input_string[i]
	i += 1
While(i < (strlen(input_string)-3))

output_string += new_extension

Return output_string

End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
