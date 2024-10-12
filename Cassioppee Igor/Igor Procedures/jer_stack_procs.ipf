// ###################################################################
//  Igor Pro - JER Image Processing
// 
//  FILE: "jer_stack_procs.ipf"
//                                    created: 06/10/2014 
//                                last update: 06/10/2014 
//  Author: Julien E. Rault
//  E-mail: julien.e.rault [at] gmail.com
//  www: https://sites.google.com/site/julienerault/
//  
//  Licence : This work is licensed under a Creative Commons Attribution 4.0 International License (http://creativecommons.org/licenses/by/4.0/)
// 
//  Description: 
//	Several macros and functions useful for dealing with 3D waves.

//  History
// 
//  modified   by  rev reason
//  ---------- --- --- -----------
//  2014-10-06 JER 1.0 original
//  2014-10-07 JER 1.1 Addition of the contrast slider
//  2014-10-08 JER 1.2 Addition of the functions Launch_binning and bin_stack_xyz
// ###################################################################

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

Menu "Image Processing"
	"Rotate a stack", Rotate_stack_3D()
	"Rotate an image", Rotate_image_2D()
	"-"
	"Retrieve ASCII images", Retrieve_ASCII_images()
	"Load 3D image stack", Load_Stack_3D()
	"Save 3D image stack", Save_Stack_3D()
	"Save a TIFF image", Save_TIFF()
	"Extract mean value from ROI", Extract_average()
	"-"
	"JER Stack Displayer/2", Stack_Displayer()
	"JER Stack Binning/3", Launch_binning()
End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Charge des images .asc dans un dossier et les convertit en .tiff 16 bits.
Function Retrieve_ASCII_images()

// Chemin des images .asc
NewPath/Q/C/O/M="Folder of the Spectra: " PathFiles

// Liste des images en .asc
String list_images = IndexedFile(PathFiles, -1, ".asc")
String Name = "", string_name = "", tiff_name = ""
Variable i = 0

Do
	Name = StringFromList(i, list_images,";")
	LoadWave/G/M/Q/H/P=PathFiles Name
	tiff_name = change_extension(S_filename,"tif")
	string_name = StringFromList(0,S_waveNames,";")
	Wave wave_name = $(string_name)
	ImageSave/O/P=PathFiles/IGOR/T="tiff"/U/D=16 wave_name as tiff_name
	Rename wave_name, $(tiff_name)
	i += 1
While(CmpStr(StringFromList(i,list_images,";"),"") != 0)

End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Extract mean value of a ROI defined by user cursors.
Function Extract_average()

Variable mean_value_ROI = 0

String s_popup_spectre =  SortList(WaveList("*",";","DIMS:2"),";",4), s_spectre = ""
Prompt s_spectre, "Image name : ", popup s_popup_spectre
DoPrompt "Choose the 2D wave", s_spectre
Wave wave_2D = $(s_spectre)

If(V_flag)
	Print "Procedure cancelled."
	Return 0
EndIf

Variable x_1,x_2,y_1,y_2
Variable c = 0, e = 0, l = 0

Prompt x_1, "Position x1 : "
Prompt x_2, "Position x2 : "
Prompt y_1, "Position y1 : "
Prompt y_2, "Position y2 : "

x_1 = pcsr(A)
y_1 = qcsr(A)
x_2 = pcsr(B)
y_2 = qcsr(B)

DoPrompt "Information on spectrum", x_1,y_1,x_2,y_2

If(V_flag)									// En cas d'erreur lors du chargement on arrête tout.
	Print "Procedure cancelled."
	Return 0
EndIf

// Valeur par défauts de la zone à analyser en cas d'erreurs utilisateurs (négatIfs, hors dimension)

If(x_1 < 0) 
	x_1 = 0
EndIf
If(x_2 > DimSize(image,0))
	x_2 = DimSize(image,0)
EndIf
If(y_1 < 0)
	y_1 = 0
EndIf
If(y_2 > DimSize(image,1))
	y_2 = DimSize(image,1)
EndIf

l = y_1
c = x_1

Do // boucle sur lignes
	Do // boucle sur colonnes
		mean_value_ROI += wave_2D[c][l]
		c += 1
	While(c < x_2 + 1)
	l += 1
	c = x_1
While(l < y_2 + 1)

Variable surface = abs((y_2-y_1+1)*(x_2 - x_1+1))

mean_value_ROI /= surface

Variable/G mean_ROI

mean_ROI = mean_value_ROI

Print "The mean value is: ", mean_value_ROI

KillWaves/Z stack_temporaire

End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function Rotate_stack_3D()

String s_popup_spectre =  SortList(WaveList("*",";","DIMS:3"),";",4), s_spectre = ""
Prompt s_spectre, "3D wave name: ", popup s_popup_spectre
DoPrompt "Choose the 3D wave", s_spectre
Wave wave3D = $(s_spectre)

Make/O/N=(DimSize(wave3D,2),DimSize(wave3D,0),DimSize(wave3D,1)) $(s_spectre+"_r")
Wave wave3D_rot = $(s_spectre+"_r")

wave3D_rot[][][]=wave3D[q][r][p]

SetScale/P x, DimOffset(wave3D,2), DimDelta(wave3D,2), wave3D_rot
SetScale/P y, DimOffset(wave3D,0), DimDelta(wave3D,0), wave3D_rot
SetScale/P z, DimOffset(wave3D,1), DimDelta(wave3D,1), wave3D_rot

End

Function Rotate_image_2D()

String s_popup_spectre =  SortList(WaveList("*",";","DIMS:2"),";",4), s_spectre = ""
Prompt s_spectre, "2D wave name: ", popup s_popup_spectre
DoPrompt "Choose the 2D wave", s_spectre
Wave wave2D = $(s_spectre)

Make/O/N=(DimSize(wave2D,1),DimSize(wave2D,0)) $(s_spectre+"_r")
Wave wave2D_rot = $(s_spectre+"_r")

wave2D_rot[][]=wave2D[q][p]

SetScale/P x, DimOffset(wave2D,1), DimDelta(wave2D,1), wave2D_rot
SetScale/P y, DimOffset(wave2D,0), DimDelta(wave2D,0), wave2D_rot

End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function Load_Stack_3D()

String nom1 = ""

// Variables d'interactions utilisateur
Prompt nom1, "Name of the image series"
DoPrompt "Information on the image series", nom1

If(V_flag)										// en cas d'erreur lors du chargement on arrête tout.
	Print "Procedure cancelled."
	Return 0
EndIf

String nom = "serie_"+nom1+"_"				// ce formatage est nécessaire pour éviter les erreurs Igor sur les noms de Dossiers

ImageLoad/C=-1/T=tiff/N=last_load/Q			// Chargement d'un stack avec interface utilisateur

If(V_flag==0)									// En cas d'erreur lors du chargement on arrête tout.
	Print "Error when loading the image."
	Print "Procedure cancelled."
	Return 0
EndIf

MoveWave last_load, $(nom1)

Print "Stack loading done."
Return 1

End

Function Save_Stack_3D()

Variable resultat = 0
String format = "0 = 16 bits"

String s_popup_spectre =  SortList(WaveList("*",";","DIMS:3"),";",4), s_spectre = ""
Prompt s_spectre, "3D wave name: ", popup s_popup_spectre
Prompt format, "Stack format", popup "0 = 16 bits;1 = 32 bits"
DoPrompt "Choose the 3D wave", s_spectre, format
Wave wave3D = $(s_spectre)

If(V_flag)
	Print "Procedure cancelled."
	Return 0
EndIf

If(!CmpStr(format,"1 = 32 bits"))
	ImageSave/IGOR/O/T="tiff"/S/U/F wave3D
	Print "Image saved as a 32 bits .tif"
Else
	ImageSave/IGOR/O/T="tiff"/S/U/D=16 wave3D
	Print "Image saved as a 16 bits .tif"
EndIf

Print "All done."
Return 1

End

Function Save_TIFF()

Variable resultat = 0
String format = "0 = 16 bits"

String s_popup_spectre =  SortList(WaveList("*",";","DIMS:2"),";",4), s_spectre = ""
Prompt s_spectre, "2D wave name: ", popup s_popup_spectre
Prompt format, "Image format", popup "0 = 16 bits;1 = 32 bits"
DoPrompt "Choose the 2D wave", s_spectre, format
Wave wave3D = $(s_spectre)

If(V_flag)
	Print "Procedure cancelled."
	Return 0
EndIf

If(!CmpStr(format,"1 = 32 bits"))
	ImageSave/IGOR/O/T="tiff"/U/F wave3D
	Print "Image saved as a 32 bits .tif"
Else
	ImageSave/IGOR/O/T="tiff"/U/D=16 wave3D
	Print "Image saved as a 16 bits .tif"
EndIf

Print "All done."
Return 1

End

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Function to access any layer of a 3D stack for Igor (label are designed for ARPES but can be changed)

Function Stack_Displayer()

// The user choose which 3D data to display
String s_spectre = ""
String s_popup_spectre = SortList(Wavelist("*",";","DIMS:2")+Wavelist("*",";","DIMS:3"),";",4)

Prompt s_spectre, "Stack Name: ", popup s_popup_spectre
DoPrompt "Stack Information", s_spectre
If(V_flag)
	Print "Procedure cancelled."
	Return 0
EndIf

Wave data = $(s_spectre)
String/G name_image = s_spectre
// Creation of Image windows and proper labelling

Display;AppendImage/T/L data

ModifyGraph swapXY=1
ModifyGraph margin(bottom)=60,margin(right)=70, margin(left)=65, margin(top)=30
ModifyGraph width=285,height=285
ModifyGraph mirror=1,nticks=12,fSize=15,axThick=2,btLen=0
Label right "Axis 1 (unit)\\u#2"
Label bottom "Axis 2 (unit)\\u#2"
ModifyGraph lblMargin(bottom)=10,tlOffset(bottom)=0
ModifyGraph lblMargin=10,tlOffset=0

ModifyImage ''#0 ctab= {*,*,YellowHot,0}

// Creation of the layer slider + variable box

If(WaveDims(data) == 3)

Variable/G layer_setup = 0
Variable/G dim_offset = DimOffset(data,2)
Variable/G dim_delta = DimDelta(data,2)
String/G unit = WaveUnits(data,2)
String energy_value = num2str(dim_offset+layer_setup*dim_delta) + " " + unit

// Slider and Variable for the layer #
Slider layers,limits={0,DimSize(data,2)-1,1},variable= layer_setup,side= 0,vert= 0, pos={140,10}, size={150,100},fsize=10, proc=Slider_Layer
SetVariable layer_val,pos={320,5},bodyWidth = 50,size={50,20},limits={0,DimSize(data,2)-1,1},value= layer_setup,title=" layer # ", proc=Variable_Layer
TextBox/C/N=energy_value/F=0/A=MC/X=35.00/Y=57.00 energy_value

EndIf

Variable/G contrast_max = WaveMax(data)
Variable/G contrast_min = WaveMin(data)

// Slider and Variable to set the maximum contrast value
Slider contrast_max_slider,limits={WaveMin(data),WaveMax(data),(WaveMax(data)-Wavemin(data))/1000},variable= contrast_max,side= 0,vert= 1, pos={20,80}, size={150,300},fsize=10, proc=Slider_contrast_max
SetVariable contrast_max_val,pos={15,55},bodyWidth = 60,size={50,20},limits={WaveMin(data),WaveMax(data),(WaveMax(data)-Wavemin(data))/100},value= contrast_max,title=" ", proc = Variable_contrast_max

// Slider and Variable to set the minimum contrast value
Slider contrast_min_slider,limits={WaveMin(data),WaveMax(data),(WaveMax(data)-Wavemin(data))/1000},variable= contrast_min,side= 0,vert= 1, pos={40,80}, size={150,300},fsize=10, proc=Slider_contrast_min
SetVariable contrast_min_val,pos={15,390},bodyWidth = 60,size={50,20},limits={WaveMin(data),WaveMax(data),(WaveMax(data)-Wavemin(data))/100},value= contrast_min,title=" ", proc = Variable_contrast_min

// Button to put the contrast in Auto mode
Button button_auto,pos={8,410},title="Auto",proc=Auto_Contrast

End

// Procs associated with the sliders and the variable boxes.

Function Slider_Layer(name, value, event) : SliderControl
	String name
	Variable value
	Variable event
	
	ModifyImage ''#0 plane= value
	
	Variable/G dim_offset
	Variable/G dim_delta
	String/G unit
	String energy_value = num2str(dim_offset+value*dim_delta) + " " + unit
	TextBox/C/N=energy_value/F=0/A=MC/X=35.00/Y=57.00 energy_value
	
	return 0
End

Function Variable_Layer (ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	
	ModifyImage ''#0 plane= varNum
	Variable/G dim_offset
	Variable/G dim_delta
	String/G unit
	String energy_value = num2str(dim_offset+varNum*dim_delta) + " " + unit
	TextBox/C/N=energy_value/F=0/A=MC/X=35.00/Y=57.00 energy_value
	
	return 0

End

Function Slider_contrast_max(name, value, event) : SliderControl
	String name
	Variable value
	Variable event
	
	ModifyImage ''#0 ctab= {,value,,0}
	return 0
End

Function Variable_contrast_max(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	
	ModifyImage ''#0 ctab= {,varNum,,0}
	return 0

End

Function Slider_contrast_min(name, value, event) : SliderControl
	String name
	Variable value
	Variable event
	
	ModifyImage ''#0 ctab= {value,,,0}
	return 0
End

Function Variable_contrast_min(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	
	ModifyImage ''#0 ctab= {varNum,,,0}
	return 0

End

Function Auto_Contrast(name) : ButtonControl
	String name
	
	String/G name_image
	Wave data = $(name_image)
	
	ModifyImage ''#0 ctab= {*,*,,0}
	Variable/G contrast_max = WaveMax(data)
	Variable/G contrast_min = WaveMin(data)
	
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Function to launch binning function with user parameters

Function Launch_binning()

// The user choose which 3D data to display
String s_spectre = ""
String s_popup_spectre = SortList(Wavelist("*",";","DIMS:3"),";",4)

Variable bin_x = 1, bin_y = 1, bin_z = 1

Prompt bin_x, "Row binning: "
Prompt bin_y, "Column binning: "
Prompt bin_z, "Layer binning: "
Prompt s_spectre, "Stack Name: ", popup s_popup_spectre
DoPrompt "Stack Information", s_spectre, bin_z, bin_y, bin_x

If(V_flag)
	Print "Procedure cancelled."
	Return 0
EndIf

Wave data = $(s_spectre)

If(bin_x < 1 || bin_y < 1 || bin_z < 1)
	Print "Error: binning cannot be below 1"
	Print "Procedure aborted."
ElseIf(bin_x > DimSize(data,0) || bin_y > DimSize(data,1) || bin_z > DimSize(data,2))
	Print "Error: binning cannot be above wave DimSize"
	Print "Procedure aborted."
Else
	bin_stack_xyz(bin_x,bin_y,bin_z,s_spectre)
	Print "Procedure finished."
EndIf

End

// Function to bin a 3D wave in every direction

Function bin_stack_xyz(bin_x,bin_y,bin_z,s_spectre)
Variable bin_x,bin_y,bin_z
String s_spectre

Wave data = $(s_spectre)

Make/N=(FLOOR(DimSize(data,0)/bin_x),FLOOR(DimSize(data,1)/bin_y),FLOOR(DimSize(data,2)/bin_z))/O $(s_spectre+"_x"+num2str(bin_x)+"_y"+num2str(bin_y)+"_z"+num2str(bin_z))
Wave bin_xyz_data = $(s_spectre+"_x"+num2str(bin_x)+"_y"+num2str(bin_y)+"_z"+num2str(bin_z))

SetScale/P x DimOffset(data,0),DimDelta(data,0)*bin_x,WaveUnits(data,0), bin_xyz_data
SetScale/P y DimOffset(data,1),DimDelta(data,1)*bin_y,WaveUnits(data,1), bin_xyz_data
SetScale/P z DimOffset(data,2),DimDelta(data,2)*bin_z,WaveUnits(data,2), bin_xyz_data
Note bin_xyz_data, note(data)

Variable i = 0, j = 0, k = 0
Variable a = 0, b = 0, c = 0, local_mean = 0


Do
	Do
		Do

			local_mean = 0
			a = 0
			b = 0
			c = 0
			Do
				Do
					Do
						local_mean += data[i*bin_x+a][j*bin_y+b][k*bin_z+c]
						c += 1
					While(c < bin_z)
					c = 0
					b += 1
				While(b < bin_y)
				b = 0
				a += 1
			While(a < bin_x)
					
			local_mean /= (bin_z*bin_y*bin_x)
			bin_xyz_data[i][j][k] = local_mean
			
			k += 1
		While(k < DimSize(bin_xyz_data,2))
		k = 0
		j += 1
	While(j < DimSize(bin_xyz_data,1))
	j = 0
	i += 1
While(i < DimSize(bin_xyz_data,0))

// If the binning is made over the full range, then the wave dimension is reduced for easer visualization
If(DimSize(bin_xyz_data,0) == 1)
	Redimension/N=(0,DimSize(bin_xyz_data,1),DimSize(bin_xyz_data,2)) bin_xyz_data
EndIf

If(DimSize(bin_xyz_data,1) == 1)
	Redimension/N=(DimSize(bin_xyz_data,0),0,DimSize(bin_xyz_data,2)) bin_xyz_data
EndIf

If(DimSize(bin_xyz_data,2) == 1)
	Redimension/N=(DimSize(bin_xyz_data,0),DimSize(bin_xyz_data,1),0) bin_xyz_data
EndIf

Return 0

End