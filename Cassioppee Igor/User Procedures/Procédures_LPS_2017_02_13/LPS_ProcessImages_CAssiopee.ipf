#pragma rtGlobals=1		// Use modern global access method.

/////////  To normalize a set of data in one folder : Build_ProcessImage_Panel()
			// Also uses : Select_Mode(ctrlName,popNum,popStr) : PopupMenuControl
			//			function ParamInit(ctrlname):Buttoncontrol
			// 			Proc Select_WaveToEfCor(ctrlName,popNum,popStr) : PopupMenuControl
			// 			Proc Select_WaveToNor(ctrlName,popNum,popStr) : PopupMenuControl
			// 			Proc Show_2Dwaves(ctrlName,popNum,popStr) : PopupMenuControl     ====== COULD BE DELETED ?
			// 			Proc Correct_BadPixel(Folder_name,i_badpixel)
			//			Proc Correct_NBadPixel(Folder_name,Number_badPixel,i_FirstBadpixel)
			//		function Folder_SetParameters()
			//		function SetParameters(ctrlname):Buttoncontrol
			//		function Readphi(i,ImageFile)
			//		function ReadTheta(i,ImageFile)
			
			//		Function SetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
			// 		Function SetFolder(ctrlName,varNum,varStr,varName) : SetVariableControl

			// HEART OF PROCESS : function ProcessImages(ctrlname):Buttoncontrol
			//						function UpdateImages(ctrlname):Buttoncontrol
			//						Function MiseEnForme(Image,PhotonEnergy,phi0)
			

///////////////////////////////////// 3D waves /////////////////////
////////////////////          Proc Build_ProcessImage_Panel3D()
///						function ParamInit3D(ctrlname):Buttoncontrol
///						function ProcessImages3D(ctrlname):Buttoncontrol
/// NB : Contrary to the 2D case, process parameters are saved in the directory. Only InputFolderName is in root.
//          Now, often 2 procedures (one with extension "3D"), only because of this. Eventually, 2D images should also work this way.



///////////////////////   Small procedures used by all procedures
///		function SmartCrop(OriginalWave,axis,start,stop)
///		function SmartShift(OriginalWave,axis,shift)
///		function SmartRescale(OriginalWave,axis,scale)
///		function SmartAverage(OriginalWave,axis,Average)


///    OTHERS : 		Macro FindEf(minX,maxX)
//					function FindEdge(Name,minX,maxX)
///			Macro Correct_Curvature(wave3D,waveCurvature)

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Proc Build_ProcessImage_Panel()
//Most of the parameters of this window will be in root:process
//Experimental Parameters are in the input data folder
// Can be used to process files taken as a function of theta, phi, energy or temperature. In the experimental parameter table, "Other_Angle" should be this parameter
//			Theta : typically for a Fermi Surface. FS can be calculated by the 3D window as a function of theta-phi or kx-ky
//			Phi : for a Fermi Surface taken as a function of azimuthal angle (NOT UPDATED YET)
//			Energy : for runs as a function of photon energy
//					Ef can be a constant or defined by a wave (this wave is substracted from the spectra). FindEf() generates a wave Ef_cor by looking for the edge
//					the conversion from angle to k is exact for all energies (uses photon energy entered in the table - Work function, defined in process folder by default 4.4eV
//					Kz (shown below Energy in 3D window) is calculated in FindCenterOfSlitsKz
//			Temperature : for runs taken as a function of temperature (for example).
//						  The essential difference is that the parameter do not have to be regularly spaced. An index is used.
//						  There can be many data processed for the same parameter
//						   NB : currently the epxerimental table is sorted. Could be changed in VB_3Dtools.


	PauseUpdate; Silent 1		// building window...
	
     string path=GetDataFolder(1)

	DoWindow/F ProcessPanel
	
	if (v_flag==0)
	NewPanel /W=(200,150,730,450)
	DoWindow/C ProcessPanel
	DoWindow/T ProcessPanel "Processing images"
	ModifyPanel cbRGB=(64512,62423,1327)
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (40960,65280,16384)
	DrawRRect  6,5,522,292
	NewDataFolder/O root:PROCESS
	NewDataFolder/O root:OriginalData
	SetDataFolder root:PROCESS
	variable/G cropstart,cropend,energystart,energyend,norystart,noryend,zeroFermi,delta_other=1
     
	
	if (exists("InputFolderName")==0)  // i.e. does not exist
	    string/G InputFolderName="root:OriginalData"
	    string/G OutputFolderName="root:Phi"
	endif
	
	string/G mode
	if (cmpstr(mode,"")==0)
		mode="theta"
	endif	
	PopupMenu popup_mode,pos={50,10},size={200,16},proc=Select_Mode,title="Mode : ",value="Theta;Phi;Energy;Temperature"
	Button ParamButton,pos={200,10},size={260,25},proc=ParamInit,title="Initialize parameters from selected image "
	//Angles
	SetVariable set_CropStart,pos={10,50},size={115,16},proc=SetVarProc,title="Angle  Start"
	SetVariable set_CropStart,limits={-30,30,0.1},value= root:PROCESS:cropstart
	SetVariable set_CropEnd,pos={130,50},size={77,16},proc=SetVarProc,title="End"
	SetVariable set_CropEnd,limits={-30,30,0.1},value= root:PROCESS:cropend
       SetVariable set_SlitStep,limits={-100,100,0.5},value= root:PROCESS:delta_other
       //Energy
	SetVariable set_EnergyStart,pos={10,75},size={115,16},proc=SetVarProc,title="EnergyStart"
	SetVariable set_EnergyStart,limits={-Inf,Inf,0.1},value= root:PROCESS:energystart
	SetVariable set_EnergyEnd,pos={130,75},size={77,16},title="End"
	SetVariable set_EnergyEnd,limits={-Inf,Inf,0.1},value= root:PROCESS:energyend
	SetVariable set_ZeroFermi,pos={230,75},size={80,16},proc=SetVarProc,title="Ef : "
	SetVariable set_ZeroFermi,limits={-inf,Inf,0.001},value= root:PROCESS:zerofermi 
       PopupMenu popup_EfCor,pos={320,73},size={200,16},proc=Select_WaveToEfCor,title="OR     wave : "
	if (DataFolderExists(InputFolderName)==1)
		SetDataFolder $InputFolderName
		else
		abort "Check InputFolderName in root:process. The Folder does not exist."
		//NewDataFolder/S $InputFolderName
	endif	
	Make/O/N=10 NoNorm
	SetScale/I x -50,50, NoNorm
	NoNorm=1
	string/G PossibleValues:="- none -;"+ WaveList("*",";","DIMS:1")	// 1D wave in InputFolder       
	KillStrings/Z root:process:PossibleValues
	MoveString PossibleValues, root:Process:
	SetDataFolder root:process
	string/G Wave_EfCor="- none -"
	PopupMenu popup_EfCor,popvalue="- none -",value=#"root:PROCESS:PossibleValues"
	//Normalize
	SetVariable set_NorYStart,pos={10,100},size={115,16},proc=SetVarProc,title="NorY  Start "
	SetVariable set_NorYStart,limits={-Inf,Inf,0.1},value= root:PROCESS:norystart
	SetVariable set_NorYEnd,pos={130,100},size={77,16},proc=SetVarProc,title="End"
	SetVariable set_NorYEnd,limits={-Inf,Inf,0.1},value= root:PROCESS:noryend
      PopupMenu popup_norWave,pos={230,100},size={200,16},proc=Select_WaveToNor,title="OR      wave to normalize : "
	string/G WaveToNor="- none -"
	PopupMenu popup_norWave,popvalue="- none -",value=#"root:PROCESS:PossibleValues"
	//Bad pixel and averaging
	variable/G BadPixel=0
	SetVariable set_correction,pos={10,125},size={210,16},title="Correct bad pixel ( if needed) "
	SetVariable set_correction,limits={-Inf,Inf,1},value= root:PROCESS:BadPixel
	variable/G AvgAngle=1 // average slices (see MiseEnForme)
	SetVariable set_averaging,pos={250,125},size={200,16},title="Average angle (if needed) : "
	SetVariable set_averaging,limits={-Inf,Inf,1},value= root:PROCESS:AvgAngle
	
	//Folders 
	SetVariable set_Newname,pos={10,160},size={320,16},proc=SetFolderProc,title="Folder with raw data :    "
	SetVariable set_Newname,limits={-Inf,Inf,1},value= root:PROCESS:InputFolderName
	SetVariable set_OutputName,pos={10,185},size={320,16},proc=SetVarProc,title="Folder to save results : "
	SetVariable set_OutputName,limits={-Inf,Inf,1},value= root:PROCESS:OutputFolderName
	
     //Below : to save individual images. Not used anymore
	variable/G savegarde=1
	CheckBox savegarde, pos={380,160},size={100,15},title="Save each image ?",variable=savegarde
	PopupMenu popup_2DWave,pos={340,180},size={400,16},proc=Show_2DWaves,title="Images : "
	string/G Possible2DWaves="- none -;"+ WaveList("*_T*",";","DIMS:2")	       
	string/G TwoDWaves="- none -"
	PopupMenu popup_2DWave,popvalue="- none -",value=#"root:PROCESS:Possible2DWaves"
	
	//Buttons
	Button ProcessButton,pos={82,227},size={125,25},proc=ProcessImages,title="Process all images"
	Button UpdateButton,pos={222,227},size={125,25},proc=UpdateImages,title="Update"
      Button ParametersButton,pos={112,260},size={185,25},proc=SetParameters,title="Set experimental parameters"
	SetVariable set_SlitStep,pos={320,265},size={150,16},proc=SetVarProc,title="Angle step for FS"
	select_mode("",0,mode)
	
	endif
	SetDataFolder path
end

//////////////////////////////////

Proc Select_Mode(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
  
  SetDataFolder root:PROCESS

   if (cmpstr(popstr,"Theta")==0)
	mode="Theta"
	PopupMenu popup_mode,mode=1
	//Erase set_refPhotonEnergy not used in this mode
	SetVariable set_RefPhotonEnergy,pos={400,50},size={20,16},proc=SetVarProc,title="                                                            " 
    endif
  
     if (cmpstr(popstr,"Phi")==0)
	mode="Phi"
	PopupMenu popup_mode,mode=2
	//Erase set_refPhotonEnergy not used in this mode
	SetVariable set_RefPhotonEnergy,pos={400,50},size={20,16},proc=SetVarProc,title="                                                            " 
    endif
    
     if (cmpstr(popstr,"Energy")==0)
     	mode="Energy"
	PopupMenu popup_mode,mode=3
     	variable/G RefPhotonEnergy
     	SetVariable set_RefPhotonEnergy,pos={250,50},size={220,125},proc=SetVarProc,title="Reference photon energy" ,value=RefPhotonEnergy
    
    endif 
  
    if (cmpstr(popstr,"Temperature")==0)
     	mode="Temperature"
	PopupMenu popup_mode,mode=4
	//Erase set_refPhotonEnergy not used in this mode
	SetVariable set_RefPhotonEnergy,pos={400,50},size={20,16},proc=SetVarProc,title="                                                            " 
   endif 
    
end


Proc Select_Mode3D(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
  
 // SetDataFolder root:PROCESS

   if (cmpstr(popstr,"Theta")==0)
	mode="Theta"
	PopupMenu popup_mode,mode=1
	//Erase set_refPhotonEnergy not used in this mode
	SetVariable set_RefPhotonEnergy,pos={400,50},size={20,16},proc=SetVarProc,title="                                                            " 
    endif
  
     if (cmpstr(popstr,"Phi")==0)
	mode="Phi"
	PopupMenu popup_mode,mode=2
	//Erase set_refPhotonEnergy not used in this mode
	SetVariable set_RefPhotonEnergy,pos={400,50},size={20,16},proc=SetVarProc,title="                                                            " 
    endif
    
     if (cmpstr(popstr,"Energy")==0)
     	mode="Energy"
	PopupMenu popup_mode,mode=3
     	variable/G RefPhotonEnergy
     	SetVariable set_RefPhotonEnergy,pos={250,50},size={220,125},proc=SetVarProc,title="Reference photon energy" ,value=RefPhotonEnergy
    
    endif 
  
    if (cmpstr(popstr,"Temperature")==0)
     	mode="Temperature"
	PopupMenu popup_mode,mode=4
	//Erase set_refPhotonEnergy not used in this mode
	SetVariable set_RefPhotonEnergy,pos={400,50},size={20,16},proc=SetVarProc,title="                                                            " 
   endif 
    
end
/////////////////////////////
function ParamInit(ctrlname):Buttoncontrol
string ctrlname
//Take parameters from selected image
// Image should be with Angle on x axis and energy on y axis
	string List=Wavelist("*",";" ,"DIMS:2,WIN:")
	string name=StrFromList(List, 0, ";")
	variable cropstartL,cropendL,energystartL,energyendL
	if (cmpstr(name,"")==0)
		abort "No appropriate wave for default values"
		else
	cropstartL=dimoffset($name,0)
	cropendL=dimoffset($name,0)+(dimsize($name,0)-1)*dimdelta($name,0)
      	energystartL=dimoffset($name,1)
      	energyendL=dimoffset($name,1)+(dimsize($name,1)-1)*dimdelta($name,1)
     	endif

	nvar cropstart=root:process:cropstart,cropend=root:process:cropend,energystart=root:process:energystart,energyend=root:process:energyend
	nvar norystart=root:process:norystart,noryend=root:process:noryend
	    cropstart=cropstartL
	    cropend=cropendL
	    energystart=energystartL
	    energyend=energyendL
	    norystart=energystart
	    noryend=energyend	
	    print "Number of slices (angle) =",dimsize($name,0), "=",dimdelta($name,0),"°"    	    

end

////////////////////////////////////////////
Proc Select_WaveToEfCor(ctrlName,popNum,popStr) : PopupMenuControl
//-----------------------------
	String ctrlName
	Variable popNum
	String popStr
	
	//Wave_EfCor contains the name of the wave to be used for Ef subtaction. 
	//It is a string of Process Folder, but the wave is in InputFolder
     string/G InputFolderName=root:process:InputFolderName
     KillStrings root:process:PossibleValues
     SetDataFolder $InputFolderName
     string/G PossibleValues,Wave_EfCor
     PossibleValues="- none -;"+ WaveList("*",";","DIMS:1")	  // Must be reinitialized if folder has changed since window creation     
 	MoveString PossibleValues, root:Process:
     PopupMenu popup_EfCor,value=#"root:PROCESS:PossibleValues"
     SetDataFolder root:process
     Wave_EfCor=popstr
end

/////////////////////////////////////
Proc Select_WaveToNor(ctrlName,popNum,popStr) : PopupMenuControl
String ctrlName
Variable popNum
String popStr

	//The procedure use y values of this wave : it does not have to be of the same format.
	//Also set value of WaveToNor	
     string/G InputFolderName=root:process:InputFolderName
     KillStrings root:process:PossibleValues
     SetDataFolder $InputFolderName
     string/G PossibleValues,Wave_EfCor
     PossibleValues="- none -;"+ WaveList("*",";","DIMS:1")	  // Must be reinitialized if folder has changed since window creation     
	MoveString PossibleValues, root:Process:
    PopupMenu popup_norWave,value=#"root:PROCESS:PossibleValues"
     root:PROCESS:WaveToNor=popstr
     if (exists(popstr)==1)
             Duplicate/O $popstr root:NormalizeByAu
    else
 	   	root:PROCESS:WaveToNor="- none -"
    		popNum=0
    		PopupMenu popup_norWave,popvalue="- none -",value=#"root:PROCESS:PossibleValues"
    endif 
end
//
Proc Select_WaveToNor3D(ctrlName,popNum,popStr) : PopupMenuControl
String ctrlName
Variable popNum
String popStr
//SAME as Select_WaveToNor, but with values in InputFolder instead of process

	//The procedure use y values of this wave : it does not have to be of the same format.
	//Also set value of WaveToNor	
	string/G InputFolderName=root:InputFolderName
	SetDataFolder $InputFolderName
     string/G PossibleValues,Wave_EfCor,WaveToNor
     PossibleValues="- none -;"+ WaveList("*",";","DIMS:1")	  // Must be reinitialized if folder has changed since window creation     
	  PopupMenu popup_norWave,value=#"PossibleValues"
   WaveToNor=popstr
     if (exists(popstr)==1)
             Duplicate/O $popstr root:NormalizeByAu
    else
 	   	WaveToNor="- none -"
    		popNum=0
    		PopupMenu popup_norWave,popvalue="- none -",value=#"PossibleValues"
    endif 
end


Proc Show_2Dwaves(ctrlName,popNum,popStr) : PopupMenuControl
//-----------------------------
	String ctrlName
	Variable popNum,pos_point
	String popStr,name
	
     SetDataFolder root:process
     SetDataFolder $OutputFoldername
     string/G root:PROCESS:Possible2DWaves="- none -;"+ WaveList("*",";","DIMS:2")	  // Must be reinitialized if folder has changed since window creation     
     //PopupMenu popup_2DWave,value=#"root:PROCESS:Possible2DWaves"
     
     //Display 
     if (abs(cmpstr(popstr,"- none -"))>0) 
             //rewrite name without any points (that occur for non integer theta values) to be able to use the name as object name
                 pos_point=strsearch(popstr,".",0)
                 if (pos_point==-1)
                      name="Display_"+popstr
                      else
                      name="Display_"+popstr[0,pos_point-1]+popstr[pos_point+1,strlen(popstr)-1]
                 endif
              //   
     		name=name[0,30]//truncate because max is 32 letters
     		DoWindow/F $name//bring to front if exists
     		if (v_flag==0)  //else create
          		Display;AppendImage $popstr
          		DoWindow/C $name
          		ModifyImage $popstr ctab= {*,*,PlanetEarth,1}
          		ModifyGraph zero(bottom)=1
     		endif 
     endif    
end

///////////////////////////////////////////////
Proc Correct_BadPixel(Folder_name,i_badpixel)
String Folder_name
variable i_badpixel
//replace for all images of one folder the row index_badpixel by the average of the surronding rows 
string ImageFileList,ImageFile
Variable limit,i
 	
 	//if (cmpstr(folder_name[0,4],"root:")>0)
 	//	Folder_name="root:"+Folder_name
 	//endif	
 	SetDataFolder root:
 	SetDataFolder $Folder_name
       ImagefileList= WaveList("*",";","DIMS:2") 
      	limit=ItemsInList( ImagefileList, ";")
       If (limit>0)
       	i=0
       	do
       		ImageFile=StringFromList(i,ImagefileList,";")
       		$ImageFile[][i_badpixel]=($ImageFile[p][i_badpixel-1]+$ImageFile[p][i_badpixel+1])/2
       		//print Imagefile
			i=i+1
		while (i<limit)	
       endif   
   

end

Proc Correct_NBadPixel(Folder_name,Number_badPixel,i_FirstBadpixel)
String Folder_name
variable Number_badpixel,i_FirstBadPixel
//replace for all images of one folder the row (index_badpixel)... (index_badpixel +(N-1)) by average of the surronding rows 
string ImageFileList,ImageFile
Variable limit,i,i_badpixel
 	
 	Folder_name="root:"+Folder_name
 	SetDataFolder $Folder_name
       ImagefileList= WaveList("*",";","DIMS:2") 
      	limit=ItemsInList( ImagefileList, ";")
       If (limit>0)
       	i=0
       	do
       		ImageFile=StringFromList(i,ImagefileList,";")
       		i_badpixel=1
       		do
       			$ImageFile[][i_FirstBadpixel+i_badpixel-1]=((Number_badPixel+1-i_badPixel)*$ImageFile[p][i_FirstBadpixel-1]+i_badPixel*$ImageFile[p][i_FirstBadpixel+Number_badPixel])/(Number_badpixel+1)
				i_badpixel+=1
       			//print Imagefile
       		while (i_badpixel<=Number_badPixel)	
			i=i+1
		while (i<limit)	
       endif   
   

end


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function Folder_SetParameters()
//Look if there is already a table (more precisely if NorProcessFlag exists)
// If yes, just edit the table
//If no, look at the list of 2D waves, read the parameters if written in the name of file

variable dejavu,i,pos_T,pos_P,theta_angle,phi_angle
svar slitangle=root:process:slitangle
String ImageFile
	
String ImagefileList= WaveList("*",";","DIMS:2")	                 //Loaded Images
Variable limit=ItemsInList( ImagefileList, ";")
        
        if (Waveexists(NorProcessFlag)==1)  
        //continue la table avec les nouveaux fichiers
             i=Dimsize(NorProcessFlag,0)
             Redimension/N=(limit) NormalizedImage,Nor_Slit_Angle, Nor_Other_Angle,NorProcessFlag
        else
             i=0
  		Make/O/T/N=(limit) NormalizedImage
	      	Make/O/N=(limit) Nor_Slit_Angle, Nor_Other_Angle,NorProcessFlag
	  endif    
      		If (i<limit)
  				Do
					ImageFile=StringFromList(i,ImagefileList,";")
					NormalizedImage[i]=ImageFile
			         	NorProcessFlag[i]=1//valeur par defaut, change to zero if file not to be processed
					//Read theta and phi from filename if name ends with sth like   _T4NP5
						if (strsearch(ImageFile,"_T",0)>-1)
							pos_T=strsearch(ImageFile,"T",0)
							pos_P=strsearch(ImageFile,"P",0)
							//print "ImageFile, pos_T,pos_P",ImageFile, pos_T,pos_P
							if (stringmatch(ImageFile[pos_P-1],"N")==1)
			      					theta_angle=-str2num(ImageFile[(pos_T+1),(pos_P-2)])
		   					else
		      						theta_angle=str2num(ImageFile[(pos_T+1),(pos_P-1)])
		 					endif
		 					if (stringmatch(ImageFile[strlen(ImageFile)-1],"N")==1)
		      						phi_angle=-str2num(ImageFile[(pos_P+1),(strlen(ImageFile)-2)])
		   					else
		     						phi_angle=str2num(ImageFile[(pos_P+1),(strlen(ImageFile)-1)])
		 					endif   
		 	   		 	       if (cmpstr(SlitAngle,"Phi")==0)
		 						Nor_Slit_angle[i]=phi_angle
		 						Nor_Other_angle[i]=theta_angle
		 					else
		 						Nor_Slit_angle[i]=theta_angle
		 						Nor_Other_angle[i]=phi_angle
		 					endif	
						endif
	        			i=i+1
	        		while (i<limit)	
	     		endif

     DoWindow Info2D_Nor_table
     if (V_flag==1)
      		DoWindow/K Info2D_Nor_table
     endif
     Edit NormalizedImage, Nor_Other_Angle,Nor_Slit_Angle, NorProcessFlag as "2D Normalized Information Table"
     execute "ModifyTable width(NormalizedImage)=120"
     DoWindow/C Info2D_Nor_table
End

//////////////////////////////

function SetParameters(ctrlname):Buttoncontrol
	string ctrlname	
	svar Input_folder=root:PROCESS:InputFolderName
	svar mode=root:PROCESS:mode

	variable dejavu,i,pos_T,pos_P,theta_angle,phi_angle
	svar slitangle=root:process:slitangle
	String ImageFile

	SetDataFolder $Input_folder

	String ImagefileList= WaveList("*",";","DIMS:2")	              // List of images in Input Folder
	Variable limit1=ItemsInList( ImagefileList, ";") 			// Nb of images in Input Folder
	
	wave Slit_Angle,Other_Angle,ProcessFlag  // If not referenced here, error message "null wave". Except for OriginalImage : why ??
            
        if (Waveexists(ProcessFlag)==1)  
        	//continue la table avec les nouveaux fichiers
        	i=Dimsize(ProcessFlag,0)
             Redimension/N=(limit1) OriginalImage,Slit_Angle,Other_Angle,ProcessFlag
        else // create a new table
             i=0
  		Make/O/T/N=(limit1) OriginalImage
	      	Make/O/N=(limit1) Slit_Angle, Other_Angle
	      	Make/O/N=(limit1) ProcessFlag
	  endif    

  		If (i<limit1) // there are new images
				Do // automatic search of parameters written as _T4NP5 at the end of filename
					ImageFile=StringFromList(i,ImagefileList,";")
					OriginalImage[i]=ImageFile
			         	ProcessFlag[i]=1//valeur par defaut, change to zero if file not to be processed
						if (strsearch(ImageFile,"_T",0)>-1)
							pos_T=strsearch(ImageFile,"T",0)
							//pos_P=strsearch(ImageFile,"P",0)
							//print "ImageFile, pos_T,pos_P",ImageFile, pos_T,pos_P
							//if (stringmatch(ImageFile[pos_P-1],"N")==1)
			      				//	theta_angle=-str2num(ImageFile[(pos_T+1),(pos_P-2)])
		   					//else
		      						//theta_angle=str2num(ImageFile[(pos_T+1),(pos_P-1)])
		      						theta_angle=str2num(ImageFile[(pos_T+1),strlen(ImageFile)-1])
		 					//endif
		 					//if (stringmatch(ImageFile[strlen(ImageFile)-1],"N")==1)
		      					//	phi_angle=-str2num(ImageFile[(pos_P+1),(strlen(ImageFile)-2)])
		   					//else
		     					//	phi_angle=str2num(ImageFile[(pos_P+1),(strlen(ImageFile)-1)])
		 					//endif  
		 					Other_angle[i]=theta_angle 
//		 	   		 	       if (cmpstr(SlitAngle,"Phi")==0)
//		 						Slit_angle[i]=phi_angle
//		 						Other_angle[i]=theta_angle
//		 					else
//		 						Slit_angle[i]=theta_angle
//		 						Other_angle[i]=phi_angle
//		 					endif	
						endif
	        			i=i+1
	        		while (i<limit1)	
	     		endif
	
	
	//Automatic run on cassiopee :
	// look for parameters in root:originalData:LoadedImage and root:originalData:theta_cassiopee
	svar mode=root:process:mode
	variable j
	wave/Z theta_cassiopee=root:OriginalData:theta_cassiopee
	if (Waveexists(root:OriginalData:theta_cassiopee)==1 && cmpstr(mode,"theta")==0)  
		print "Run Cassiopee : lecture auto des parametres"
		wave/T LoadedImage=root:OriginalData:LoadedImage
		i=0
		do
			j=-1
			do
			     j+=1
			     //print OriginalImage[i],LoadedImage[j]
			while(abs(cmpstr(OriginalImage[i],LoadedImage[j]))>0 && j<DimSize(LoadedImage,0))
			
			Other_angle[i]=theta_cassiopee[j]
			i+=1
		while (i<DimSize(OriginalImage,0))	
		Sort Other_Angle OriginalImage,Slit_angle,ProcessFlag,Other_Angle
	endif
	wave/Z energy_cassiopee=root:OriginalData:energy_cassiopee
	if (Waveexists(energy_cassiopee)==1 && cmpstr(mode,"energy")==0)  
		print "Run Cassiopee : lecture auto des parametres"
		wave/T LoadedImage=root:OriginalData:LoadedImage
		i=0
		do
			j=-1
			do
			     j+=1
			     //print OriginalImage[i],LoadedImage[j]
			while(abs(cmpstr(OriginalImage[i],LoadedImage[j]))>0 && j<DimSize(LoadedImage,0))
			
			Other_angle[i]=energy_cassiopee[j]
			i+=1
		while (i<DimSize(OriginalImage,0))	
		Sort Other_Angle OriginalImage,Slit_angle,ProcessFlag,Other_Angle
	endif
	/////
	
     DoWindow/F Info2D_table
     
     if (V_flag==1)
     		 DoWindow/K Info2D_table  // Otherwise, does not update when input folder is changed
    endif
     	Edit OriginalImage, Slit_Angle, Other_Angle, ProcessFlag as "2D Original Information Table"
 	execute "ModifyTable width(OriginalImage)=120"
     	DoWindow/C Info2D_table
	
     
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function Readphi(i,ImageFile)
variable i
string ImageFile
//2 possibilities : the filename ends with _T4NP5 (this is the case when theta and phi were read saved in text file as in Stanford or made by XJ procedure) 
//                        or phi has been entered through set parameters in PhiAngle column
variable pos_T,pos_P,phi

	if (strsearch(ImageFile,"_T",0)==-1)
		//Read from experimental table
		svar Input_folder=root:PROCESS:InputFolderName
		SetDataFolder $Input_folder
		wave phi_Angle
		phi=phi_Angle[i]
	else
		//Read from filename
			pos_P=strsearch(ImageFile,"P",0)
			if (stringmatch(ImageFile[strlen(ImageFile)-1],"N")==1)
		      		phi=-str2num(ImageFile[(pos_P+1),(strlen(ImageFile)-2)])
		   	else
		     		phi=str2num(ImageFile[(pos_P+1),(strlen(ImageFile)-1)])
		 	endif   

	endif	
return phi
end


function ReadTheta(i,ImageFile)
variable i
string ImageFile
//2 possibilities : the filename ends with _T4NP5 (this is the case when theta and phi were read saved in text file as in Stanford) 
//                        or phi has been entered through set parameters in PhiAngle column
variable pos_T,pos_P,theta
	
	if (strsearch(ImageFile,"_T",0)==-1)   //i.e. theta is not written in name
		//Read from experimental table
		svar Input_folder=root:PROCESS:InputFolderName
		SetDataFolder $Input_folder
		wave theta_Angle
		theta=theta_Angle[i]
	else
		//Read from filename
		pos_T=strsearch(ImageFile,"T",0)
		pos_P=strsearch(ImageFile,"P",0)
		//print "ImageFile, pos_T,pos_P",ImageFile, pos_T,pos_P
			if (stringmatch(ImageFile[pos_P-1],"N")==1)
			      theta=-str2num(ImageFile[(pos_T+1),(pos_P-2)])
		   	else
		      		theta=str2num(ImageFile[(pos_T+1),(pos_P-1)])
		 	endif
	endif
return theta		 	
end

Function SetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	//varName
	
End

Function SetFolderProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	svar InputFolderName=root:Process:InputFolderName
	SetDataFolder $InputFolderName		

	Make/O/N=10 NoNorm
	SetScale/I x -50,50, NoNorm
	NoNorm=1

	SetDataFolder root:Process	
End

Function SetFolderProc3D(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	svar InputFolderName=root:InputFolderName
	NewDataFolder/O/S $InputFolderName		

	Make/O/N=10 NoNorm
	SetScale/I x -50,50, NoNorm
	NoNorm=1
	//Create a new window, because parameters should be linked to the new folder
	KillWindow ProcessPanel3D
	execute "Build_ProcessImage_Panel3D()"
	
End
	
Function SetFolder(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

svar InputFolderName=root:InputFolderName
SetDataFolder InputFolderName	
DoWindow/K ProcessPanel3D
execute "Build_ProcessImage_Panel3D()"
End



///////////////////////////////////  

function ProcessImages(ctrlname):Buttoncontrol
string ctrlname  // if update button has been it ctrlname="update"

//Crop, Normalize and substract Ef from raw images (with MiseEnForme)

	// NB :    La valeur d'énergie soustraite est 	soit : ZeroFermi OU Wave_EfCor[i] (si elle existe)
	//										soit, pour les runs en énergie quand il n'y a pas de Wave_EfCor : OtherAngle[i] + ZeroFermi
	//     	ZeroFermi est la valeur de Ef entrée dans Process Pannel, en général la seule à considérer
	//           Wave_EfCor est une wave avec une valeur différente de Ef pour chaque data, au cas où elle change.
	//		Pour les runs en énergie : OtherAngle contient l'énergie de photons (on en a besoin pour faire les conversions d'angle).
	//								L'idée est que ZeroFermi est le travail de sortie : OtherAngle[i]+ZeroFermi donne la bonne valeur de Ef
	//								S'il y a une wave EfCor, on utilise juste celle-ci. A utiliser aussi si l'énergie de photon est déjà soustraite des datas "raw" 
									 
//Correct bad pixel if necessary
//Add slit_angle to angle value but does not center Scienta window at zero

//Output : 2D images (with list that can be accessed and displayed from Processing Panel)
//				     (name : same as original data + theta and phi values (if not already in name))
//             3D wave in same output folder (also automatically displayed)

svar Input_folder=root:process:InputFolderName, Output_folder=root:process:OutputFolderName
svar WaveToNor=root:PROCESS:WaveToNor

string ImageFileList,ImageFile,name
Variable limit,bidon,DoIt,i,slit,PhotonEnergy,pos_point,nb

String curr= GetDataFolder(1)

// For runs in energy : Parameters can be entered in Process Pannel compared to a reference photon energy
// First substract it
	svar mode=root:process:mode
   	nvar RefPhotonEnergy=root:process:RefPhotonEnergy
	if (cmpstr(mode,"energy")==0 && RefPhotonEnergy>0)
	   	nvar energystart=root:process:energystart,energyend=root:process:energyend,norystart=root:process:norystart,noryend=root:process:noryend,zerofermi=root:process:zerofermi
     		zerofermi-=RefPhotonenergy
     		energystart-=RefPhotonEnergy+zerofermi
     		energyend-=RefPhotonEnergy+zerofermi
     		norystart-=refphotonenergy+zerofermi
     		noryend-=refphotonenergy+zerofermi
     		refphotonenergy-=refphotonenergy   
     	endif	

// First check status of parameter table
// 3 cases : 	- Table of parameters exists : nothing to do
// 			- Table does not exist and
//					- Theta and phi are written in the filename => automatically create table
//					- Theta and phi are not written in the filename => generate error message and stop
       SetDataFolder $Input_folder
       if (waveexists(OriginalImage)==0)  //i.e. there is no parameter table
 	       ImagefileList= WaveList("*_T*",";","DIMS:2") //List of waves with names containing theta values
      		 limit=ItemsInList( ImagefileList, ";")	   
      		 if (limit>0)
      		       //automatically create table of parameters by reading filename
      		 	SetParameters(" ")  
      		 else
      		 	//edit table but don't process images (user should enter them by hand)
      		 	SetParameters(" ")   
      		 	abort "Set parameters first"
      		 endif	   
       endif
       

// Cleaning the output folder....
// If folder already exists, should kill all waves in it, even if they are on display 
// because all the waves of the folder will be compiled in the 3D wave 
// This is not done if we just update
       NewDataFolder/O $Output_folder
       SetDataFolder $Output_folder 
      variable other

      	if (cmpstr(ctrlname,"update")==0)
      		//do nothing
      		else
      	ImagefileList= WaveList("*_T*",";","DIMS:2") //These waves have not been killed : they are probably displayed and we want to kill these graphs	      
	limit=ItemsInList( ImagefileList, ";")
	 If (limit>0)
      		i=0
      		do
      			ImageFile=StringFromList(i,ImagefileList,";")
      			//rewrite name without any points (that occur for non integer theta values) to be able to use the name as object name
            		pos_point=strsearch(ImageFile,".",0)
            		if (pos_point==-1)
                   		name="Display_"+ImageFile
                   	else
                   		name="Display_"+ImageFile[0,pos_point-1]+ImageFile[pos_point+1,strlen(ImageFile)-1]
            		endif
            		//   
            		 DoWindow/F $name
			if (v_flag==1)
				DoWindow/K $name  //Kill the graph if exists (to be able to kill the wave)
			endif	
			KillWaves $Imagefile
			i=i+1
		while (i<limit)	
      	endif
      endif
        //// end of kill old waves
              

////////////////////////  Start processing (if parameters are known)

       SetDataFolder root:Process
       Killwaves/A/Z  //Just to clean up
 	SetDataFolder $Output_folder
	// These waves will be used by Smart3Dwave (the idea is to make it independent of InputFolder).
	name=Input_Folder+":OriginalImage"
	Duplicate/O/T $name NormalizedImage
	name=Input_Folder+":ProcessFlag"
	Duplicate/O $name NorProcessFlag
	name=Input_Folder+":Other_Angle"
	Duplicate/O $name Nor_Other_Angle
	name=Input_Folder+":Slit_Angle"
	Duplicate/O $name Nor_Slit_Angle
	svar modeL=root:process:mode  // copy mode in output folder to be independent of process
	string/G mode
	mode=modeL
	
      SetDataFolder $Input_folder
       
       nvar Badpixel=root:process:badpixel
       execute "Correct_badpixel(\""+Input_Folder+"\","+num2str(BadPixel)+")"
       
      wave ProcessFlag,Slit_Angle,Other_Angle
      svar Wave_EfCor=root:process:Wave_EfCor
      if (cmpstr(Wave_EfCor,"- none -")==0)
      		//nothing
      		else
	      Duplicate/O $Wave_EfCor EfCor_wave  
      endif
      wave/T OriginalImage
	nvar ZeroFermi=root:process:ZeroFermi
	
	i=0
		Do
			SetDataFolder $Input_folder
			ImageFile=OriginalImage[i]
			if (ProcessFlag[i]==1)
				//Name of new image : add extension _T(other)P(slits)
				slit=Slit_Angle[i]
				if (cmpstr(mode,"Temperature")==0)
				// In temperature mode, use Ef cor to shift data. Must be in angle !
       				if (cmpstr(Wave_EfCor,"- none -")==0)
       				else
       					slit=Slit_Angle[i]-EfCor_wave[i]
       				endif	
            			endif
				
//				other=Other_Angle[i]
//				if (strsearch(ImageFile,"_T",0)==-1)
//					if (other>=0)
//						ImageFile=ImageFile+"_T"+num2str(other)
//					else
//						ImageFile=ImageFile+"_T"+num2str(-other)+"N"
//					endif
//					if (slit>=0)
//						ImageFile=ImageFile+"P"+num2str(slit)
//					else
//						ImageFile=ImageFile+"P"+num2str(-slit)+"N"
//					endif
//				endif

				SetDataFolder $Output_folder
				NormalizedImage[i]=ImageFile	
				SetDataFolder $Input_folder
				name=Output_Folder+":'"+ImageFile+"'"		
				if (waveexists($name)==1 && cmpstr(ctrlname,"update")==0)
						//do nothing
					else
						//print "i,phi,theta",i,phi,theta
						ImageFile=OriginalImage[i]
			      			if (cmpstr(Wave_EfCor,"- none -")==0 || cmpstr(mode,"Temperature")==0)
      			      				PhotonEnergy=ZeroFermi
            						if (cmpstr(mode,"energy")==0)
            							PhotonEnergy=Other_Angle[i] +ZeroFermi 
            							//PhotonEnergy=0 //when photon energy already sbstracted from data
            						endif
            					else
            						PhotonEnergy=Efcor_wave[i]
            					endif	
           					
            					//execute "MiseEnForme(\""+ImageFile+"\","+num2str(PhotonEnergy)+","+num2str(slit)+")" 
            					MiseEnForme(ImageFile,PhotonEnergy,slit) 
		
		             		// Put Normalized Image (which is called temp and is in process) in 2D folder with extension _TxxPxx
						SetDataFolder $Input_folder
						Duplicate/O root:process:temp2D $name
						SetDataFolder $Output_folder
				   endif // on update
				endif  // on processflag	
             	i=i+1
		while (i<numpnts(OriginalImage))	

 	//Refresh list of 2D waves
 	SetDataFolder $Output_Folder
      DoWindow/F ProcessPanel
      string/G root:process:Possible2DWaves="- none -;"+ WaveList("*_T*",";","DIMS:2")	  // Must ve reinitialized if folder has changed since window creation     
      //PopupMenu popup_2DWave,value=#"root:process:Possible2DWaves"
     
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
     	//Now 2D normalized and cropped images are compiled into a 3D wave (use VB_3DTools)
 	Smart3Dwave(Output_Folder)
 	execute "Refresh_FS()"  // updates FS if exists
 	
 	// Kill 2D waves to save space
 	nvar savegarde=root:process:savegarde
 	if (savegarde==0)
 	string Waves=WaveList("*_T*",";","DIMS:2") // stringlist with names of all waves to be killed
 	variable NbW=ItemsInList(Waves)
 	i=0
 	do
 		name=StringFromList(i,waves)
 		Killwaves/Z $name
 		i+=1
 	while (i<NbW)
 	endif
     SetDataFolder curr

End

/////////////////////////////////////

function UpdateImages(ctrlname):Buttoncontrol
	string ctrlname
	
	ProcessImages("update")
	
End

/////////////////////

Function MiseEnForme(Image,PhotonEnergy,phi0)
string Image
variable PhotonEnergy,phi0

// For raw Images with angle as y and energy as x (transpose if necessary)
// Crop energy and angle ranges chosen from Process Pannel
// Rescale angle axis by nor if necessary (manually defined below)
// Substract PhotonEnergy to Energy axis 
// Add phi0 to AngleScale
// Average angular slices by AvgAngle (=1 by default)
// Normalize along y either by value integrated between two energies defined in Process Pannel or by a WaveToNor in Input_Folder

// NB : this is a macro because I want to use wave(y) in normalizing. This is probably what makes it slow !

string FullName

	 SetDataFolder root:process
	 string/G mode,InputFolderName,WaveToNor
	 variable/G EnergyStart,EnergyEnd,CropStart,CropEnd,NorYstart,NorYend,AvgAngle
	 FullName=InputFolderName+":"+Image
	 // If images must be transposed...
	//MatrixTranspose $Fullname 
	 	 
	 // Crop energy
	 if (cmpstr(mode,"Energy")==0)
      		// For Energy mode, PhotonEnergy is already subtracted from EnergyStart and EnergyEnd
      		SmartCrop($FullName,0,EnergyStart+PhotonEnergy,EnergyEnd+PhotonEnergy)
      		else
		SmartCrop($FullName,0,EnergyStart,EnergyEnd)
	 endif
	 wave OutputWave
	 Duplicate/O OutputWave temp2D
 	 
 	 // Crop angle
 	 SmartCrop(temp2D,1,CropStart,CropEnd)
	 Duplicate/O OutputWave temp2D
	 
	// Average data, if necessary
	SmartAverage(temp2D,1,AvgAngle)  // currently, only proposed for angle axis
	 Duplicate/O OutputWave temp2D	
	 
	// ReCalibrate angle axis, if necessary (divide everything by nor)
	variable nor
	nor=1   //For example on BL12, data have to be divided by 1.3 (set nor=1.3) otherwise, set nor to 1 
	SmartRescale(temp2D,1,nor)
	Duplicate/O OutputWave temp2D
		 
	// Shift in energy and angle
	SmartShift(temp2D,0,-PhotonEnergy)
	 Duplicate/O OutputWave temp2D
	
 	SmartShift(temp2D,1,phi0)
	 Duplicate/O OutputWave temp2D
	
	// Normalize Y
		// Calculates the angle profile (y axis)
			//either by averaging along energies (x) the image between NorYstart and NorYend 
			//or by extrapolating the indicated wave
	if (cmpstr(WaveToNor,"- none -")==0)
		//divide by average value between Norystart and Noryend
		Make/O/N=(DimSize(temp2D,1)) Profile
		SetScale/P x DimOffset(temp2D,1),DimDelta(temp2D,1),"", Profile
		Profile=0

		variable index,index_NorYstart,index_NorYend
		 if (cmpstr(mode,"Energy")==0)
      		// For Energy mode, PhotonEnergy is already subtracted fromNorYStart and NorYEnd
	      		index_NorYstart=max(round((NorYstart-DimOffset(temp2D,0))/DimDelta(temp2D,0)),0) // Forces index_start to be positive
			index_NorYend=round((NorYend-DimOffset(temp2D,0))/DimDelta(temp2D,0))
      		else
      			index_NorYstart=max(round((NorYstart-PhotonEnergy-DimOffset(temp2D,0))/DimDelta(temp2D,0)),0) // Forces index_start to be positive
			index_NorYend=round((NorYend-PhotonEnergy-DimOffset(temp2D,0))/DimDelta(temp2D,0))
		endif
		
		index=index_NorYstart
		do
		 	Profile+=temp2D[index][p]
		 	index+=1
		 while (index<index_Noryend)
		 Profile/=(index_NorYend-index_NorYstart+1)
		 temp2D/= Profile[q]
	else
		if (cmpstr(WaveToNor,"NoNorm")==0)
		//do nothing
		else
		// WaveToNor may not have the same number of points or interval
		variable Nb
		string name=InputFolderName+":"+WaveToNor
		Nb=round((DimSize($name,0)-1)*DimDelta($name,0)/DimDelta(temp2D,1)) // Nb of points needed to have the right delta for Profile
		Interpolate2/T=1/N=(Nb)/Y=bidon $name
		SmartCrop(bidon,0,NorYstart,NorYend)
		Duplicate/O OutPutWave Profile
		temp2D/= Profile[q]
		endif
	endif
	
	//Killwaves Profile
End

///////////////////////////////////


///////////////////////////////////// 3D waves /////////////////////
///////////////////////////////////////////////////////////////////////////////////////////
Proc Build_ProcessImage_Panel3D()
//To resize a 3D wave, subtract Ef, Normalize... 
// 3D wave should be in a separate folder where all parameters for process will be saved, except InputFolderName, which is in root
// Ouput wave will be tmp_3D to be shown in the 3D window

	PauseUpdate; Silent 1		// building window...
	
     string path=GetDataFolder(1)

	DoWindow/F ProcessPanel3D
	
	if (v_flag==0)
	NewPanel /W=(200,150,730,450)
	DoWindow/C ProcessPanel3D
	DoWindow/T ProcessPanel3D "Process 3D wave"
	ModifyPanel cbRGB=(64512,62423,1327)
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (40960,65280,16384)
	DrawRRect  6,5,522,292
	
	SetDataFolder "root:"
	if (exists("InputFolderName")==0)  // i.e. does not exist
	    string/G InputFolderName="root:"
	    string/G InputWaveName="root:tmp_3D"
      else
	    string/G InputFolderName=root:InputFolderName
	    SetDataFolder InputFolderName
    	    string/G InputWaveName
	endif
	
	variable/G cropstart,cropend,energystart,energyend,norystart,noryend,zeroFermi
	string/G mode
	
	if (cmpstr(mode,"")==0)
		mode="theta"
	endif	
	
	// Waves 
	SetVariable set_FolderName,pos={10,10},size={260,16},proc=SetFolderProc3D,title=" Folder with raw data :    "
	SetVariable set_FolderName,limits={-Inf,Inf,1},value=root:InputFolderName
	SetVariable set_InputName,pos={10,35},size={260,16},proc=SetVarProc,title=" Name for input wave : "
	SetVariable set_InputName,limits={-Inf,Inf,1},value=InputWaveName
	Button ParamButton,pos={320,10},size={170,35},proc=ParamInit3D,title="Initialize "
	//SetDataFolder InputFolderName
	Make/O/N=10 NoNorm
	SetScale/I x -50,50, NoNorm
	NoNorm=1


	//Angles (x wave)
	SetVariable set_CropStart,pos={10,70},size={145,16},proc=SetVarProc,title="X (angle) :  Start"
	SetVariable set_CropStart,limits={-180,180,0.1},value=cropstart
	SetVariable set_CropEnd,pos={180,70},size={83,16},proc=SetVarProc,title="End"
	SetVariable set_CropEnd,limits={-180,180,0.1},value= cropend
       variable/G AvgX=1 // average slices (see MiseEnForme)
	SetVariable set_averaging,pos={280,70},size={86,16},title="Avg : "
	SetVariable set_averaging,limits={-Inf,Inf,1},value= AvgX
       //Energy (y wave)
	SetVariable set_EnergyStart,pos={10,95},size={145,16},proc=SetVarProc,title="Y (energy) : Start"
	SetVariable set_EnergyStart,limits={-Inf,Inf,0.1},value= Energystart
	SetVariable set_EnergyEnd,pos={180,95},size={83,16},title="End"
	SetVariable set_EnergyEnd,limits={-Inf,Inf,0.1},value= Energyend
	 variable/G AvgY=1 // average slices (see MiseEnForme)
	SetVariable set_averagingE,pos={280,95},size={86,16},title="Avg : "
	SetVariable set_averagingE,limits={-Inf,Inf,1},value= AvgY
	
	SetVariable set_ZeroFermi,pos={75,120},size={80,16},proc=SetVarProc,title="Ef : "
	SetVariable set_ZeroFermi,limits={-inf,Inf,0.001},value=Zerofermi 
       //PopupMenu popup_EfCor,pos={165,118},size={200,16},proc=Select_WaveToEfCor,title="OR     wave : "
	//string/G Wave_EfCor="- none -"
	//PopupMenu popup_EfCor,popvalue="- none -",value=#"root:PROCESS:PossibleValues"
	
	//Z axis
	variable/G Zstart,Zend
	variable/G AvgZ=1
	PopupMenu popup_mode,pos={10,145},size={150,16},proc=Select_Mode3D,title="Z : ",value="Theta;Phi;Energy;Temperature"
	//PopupMenu popup_mode,popvalue=mode
	select_mode3D("",0,mode)
	SetVariable set_ZStart,pos={125,145},size={85,16},proc=SetVarProc,title=" Start"
	SetVariable set_ZStart,limits={-Inf,Inf,0.1},value=Zstart
	SetVariable set_ZEnd,pos={215,145},size={77,16},title="End"
	SetVariable set_ZEnd,limits={-Inf,Inf,0.1},value=Zend
	 variable/G AvgZ=1 // average slices (see MiseEnForme)
	SetVariable set_averagingZ,pos={310,145},size={86,16},title="Avg : "
	SetVariable set_averagingZ,limits={-Inf,Inf,1},value= AvgZ
	
	//Normalize
	SetVariable set_NorYStart,pos={10,180},size={190,16},proc=SetVarProc,title="Normalize between : Estart "
	SetVariable set_NorYStart,limits={-Inf,Inf,0.1},value=norystart
	SetVariable set_NorYEnd,pos={210,180},size={110,16},proc=SetVarProc,title=" and E_end"
	SetVariable set_NorYEnd,limits={-Inf,Inf,0.1},value=noryend
      PopupMenu popup_norWave,pos={350,180},size={200,16},proc=Select_WaveToNor3D,title="OR with wave : "
	string/G WaveToNor="- none -"
	Make/O/N=2 NoNorm 
      string/G PossibleValues:="- none -;"+ WaveList("*",";","DIMS:1")	// 1D wave in InputFolder       
	PopupMenu popup_norWave,popvalue="- none -",value=#"PossibleValues"
	
	//Bad pixel and averaging
	//variable/G BadPixel=0
	//SetVariable set_correction,pos={10,125},size={210,16},title="Correct bad pixel ( if needed) "
	//SetVariable set_correction,limits={-Inf,Inf,1},value= root:PROCESS:BadPixel

	Button ProcessButton,pos={127,227},size={130,35},proc=ProcessImages3D,title="Process 3D image"

	ParamInit3D("")
	
	endif
	//SetDataFolder path
end

/////////////////////////////
function ParamInit3D(ctrlname):Buttoncontrol
string ctrlname
string path

svar InputFolderName=root:InputFolderName
SetDataFolder InputFolderName

variable/G cropstart,cropend,energystart,energyend,norystart,noryend,zeroFermi,delta_other=1
variable/G Zstart,Zend

string/G InputWaveName
  
  if (exists(InputWaveName)==1)
	cropstart=round(DimOffset($InputWaveName,0)*100000)/100000
	energystart=round(DimOffset($InputWaveName,1)*100000)/100000
	Zstart=round(DimOffset($InputWaveName,2)*100000)/100000
	
	cropend=DimOffset($InputWaveName,0)+DimDelta($InputWaveName,0)*(DimSize($InputWaveName,0)-1)
	cropend=round(cropend*100000)/100000
	energyend=DimOffset($InputWaveName,1)+DimDelta($InputWaveName,1)*(DimSize($InputWaveName,1)-1)
	energyend=round(energyend*100000)/100000
  	Zend=DimOffset($InputWaveName,2)+DimDelta($InputWaveName,2)*(DimSize($InputWaveName,2)-1)
	Zend=round(Zend*100000)/100000  	    
  endif
end

/////////////////////////////
function ProcessImages3D(ctrlname):Buttoncontrol
string ctrlname
// Crop between indicated values
// Subtract Fermi level (WILL NOT WORK WITH WAVE SO FAR)
// Avg if asked
// Normalize angle between indicated energy values

svar InputFolderName=root:InputFolderName
SetDataFolder InputFolderName

variable/G cropstart,cropend,energystart,energyend,norystart,noryend,zeroFermi
variable/G Zstart,Zend
variable/G avgX,AvgY,AvgZ
string/G InputWaveName

variable OldXstart,OldYstart,OldZstart,OldXend,OldYend,OldZend
variable pstart,qstart,rstart

	OldXstart=round(DimOffset($InputWaveName,0)*100000)/100000
	OldYstart=round(DimOffset($InputWaveName,1)*100000)/100000
	OldZstart=round(DimOffset($InputWaveName,2)*100000)/100000
	
	pstart=round((cropstart-OldXstart)/DimDelta($InputWaveName,0))
	qstart=round((energystart-OldYstart)/DimDelta($InputWaveName,1))
	rstart=round((Zstart-OldZstart)/DimDelta($InputWaveName,2))
	
	// Crop
	variable NbX,NbY,NbZ
	NbX=round((cropend-cropstart)/DimDelta($InputWaveName,0))
	NbY=abs(round((energyend-energystart)/DimDelta($InputWaveName,1)))
	NbZ=round((Zend-Zstart)/DimDelta($InputWaveName,2))
	
	Make/O /N=(NbX,NbY,NbZ) temp3D
	Duplicate/O $InputWaveName Old3D
	SetScale/P x cropstart,DimDelta($InputWaveName,0), temp3D
	SetScale/P y energystart-ZeroFermi,DimDelta($InputWaveName,1), temp3D
	SetScale/P z Zstart,DimDelta($InputWaveName,2), temp3D
	
	temp3D=Old3D[p+pstart][q+qstart][r+rstart]
	Killwaves Old3D
	
	// Avg
	variable i
	if (AvgX>1)
		NbX=round(NbX/AvgX)
		Make/O /N=(NbX,NbY,NbZ) temp3Db
		i=0
		do
			temp3Db+=temp3D[p*AvgX+i][q][r]
			i+=1
		while (i<AvgX)
		Duplicate/O temp3Db temp3D
		Killwaves temp3Db
	endif
	if (AvgY>1)
		NbY=round(NbY/AvgY)
		Make/O /N=(NbX,NbY,NbZ) temp3Db
		i=0
		do
			temp3Db+=temp3D[p][q*AvgY+i][r]
			i+=1
		while (i<AvgY)
		Duplicate/O temp3Db temp3D
		Killwaves temp3Db
	endif
	if (AvgZ>1)
		NbZ=round(NbZ/AvgZ)
		Make/O /N=(NbX,NbY,NbZ) temp3Db
		i=0
		do
			temp3Db+=temp3D[p][q][r*AvgZ+i]
			i+=1
		while (i<AvgZ)
		Duplicate/O temp3Db temp3D
		Killwaves temp3Db
	endif
	SetScale/P x cropstart,DimDelta($InputWaveName,0)*AvgX, temp3D
	SetScale/P y energystart-ZeroFermi,DimDelta($InputWaveName,1)*AvgY, temp3D
	SetScale/P z Zstart,DimDelta($InputWaveName,2)*AvgZ, temp3D
	
	// Normalize
	string/G WaveToNor
	//WaveToNor="- none -"
	WaveToNor="bid" // to avoid normalizing
	if (cmpstr(WaveToNor,"- none -")==0)
		//divide by average value between Norystart and Noryend
		variable IndexEstart,IndexEstop,IndexE
		Make/O/N=(NbX,NbZ) Bgd
		SetScale/I x CropStart,CropEnd,"", Bgd
		Bgd=0
		IndexEstart=round(NoryStart-ZeroFermi-Dimoffset(temp3D,1))/DimDelta(temp3D,1)
		IndexEstop=round(NoryEnd-ZeroFermi-Dimoffset(temp3D,1))/DimDelta(temp3D,1)
		IndexE=IndexEstart
		do
		 	Bgd+=temp3D[p][IndexE][q]
		 	IndexE+=1
		 while (IndexE<=IndexEstop)
		 Bgd/=(IndexEstop-IndexEstart)
		 temp3D /= Bgd[p][r]		
	else
		  //divide by NormalizeByAu, the copy in root of WaveToNor in InputFolder
		 //temp3D /= root:NormalizeByAu[]
	endif
	Duplicate/O temp3D tmp_3D
	Killwaves temp3D
	
	//Creates 3D window with the processed data
		// Kill window if exists
		string folder
		folder=InputFolderName[5,strlen(InputFolderName)]+"_"
		DoWindow/K $folder
		//Rebuilt window
	 	execute "Load3DImage(\""+InputFolderName+"\")"
	 	variable/G slit_min,offset_slits
	 	slit_min-=offset_slits   // have to apply offset_slits to slit_min by hand (usually taken from tmp_3D)
	  	execute "ChangeSlitsOffset(\"\",0,\"\",\"\")"
end

///////////////////////////////////////////////////////////////////////////////////////////
function SmartCrop(OriginalWave,axis,start,stop)
wave OriginalWave
variable axis // x=0 ; y=1 ; z=2
variable start,stop
//Works for 2D or 3D waves. Returns in OutputWave the wave cropped between start and stop	

	variable Nb,i_start
	Nb=round((stop-start)/DimDelta(OriginalWave,axis))
	i_start=round((start-DimOffset(OriginalWave,axis))/DimDelta(OriginalWave,axis))
	Duplicate/O OriginalWave Outputwave
	
	if (axis==0)
		Redimension/N=(Nb,-1,-1) OutputWave
		SetScale/P x start,DimDelta(OriginalWave,axis), OutputWave
		OutputWave=OriginalWave[p+i_start][q][r]
	endif	
	if (axis==1)
		Redimension/N=(-1,Nb,-1) OutputWave
		SetScale/P y start,DimDelta(OriginalWave,axis), OutputWave
		OutputWave=OriginalWave[p][q+i_start][r]
	endif
	if (axis==2)
		Redimension/N=(-1,-1,Nb) OutputWave
		SetScale/P z start,DimDelta(OriginalWave,axis), OutputWave
		OutputWave=OriginalWave[p][q][r+i_start]
	endif
end

//////////

function SmartShift(OriginalWave,axis,shift)
wave OriginalWave
variable axis // x=0 ; y=1 ; z=2
variable shift
//Works for 2D or 3D waves. Returns in OutputWave the wave with axis shifted by shift value

	Duplicate/O OriginalWave OutputWave
	if (axis==0)
		SetScale/P x DimOffset(OriginalWave,axis)+shift,DimDelta(OriginalWave,axis), OutputWave
	endif	
	if (axis==1)
		SetScale/P y DimOffset(OriginalWave,axis)+shift,DimDelta(OriginalWave,axis), OutputWave
	endif
	if (axis==2)
		SetScale/P z DimOffset(OriginalWave,axis)+shift,DimDelta(OriginalWave,axis), OutputWave
	endif
end

//////////

function SmartRescale(OriginalWave,axis,scale)
wave OriginalWave
variable axis // x=0 ; y=1 ; z=2
variable scale
//Works for 2D or 3D waves. Returns in OutputWave the wave with axis divide by scale

	Duplicate/O OriginalWave OutputWave
	variable start,stop
	start=DimOffset(OriginalWave,axis)/scale
	stop=start+DimDelta(OriginalWave,axis)*(DimSize(OriginalWave,axis)-1)/scale
	if (axis==0)
		SetScale/I x start,stop, OutputWave
	endif	
	if (axis==1)
		SetScale/I y start,stop, OutputWave
	endif
	if (axis==2)
		SetScale/I z start,stop, OutputWave
	endif
end

///////////////

function SmartAverage(OriginalWave,axis,Average)
wave OriginalWave
variable axis // x=0 ; y=1 ; z=2
variable Average
//Works for 2D or 3D waves. Returns in OutputWave the wave with axis averaged by average

	Duplicate/O OriginalWave OutputWave
	variable Nb,i

	Nb=round(DimSize(OriginalWave,axis)/Average)

	if (axis==0)
		Redimension/N=(Nb,-1,-1) OutputWave
		Setscale/P x DimOffset(OriginalWave,0),DimDelta(OriginalWave,0)*Average,OutputWave
		OutputWave=0
		i=0
		do
			OutputWave+=OriginalWave[p*Average+i][q][r]
			i+=1
		while (i<Average)
	endif
	if (axis==1)
		Redimension/N=(-1,Nb,-1) OutputWave
		Setscale/P y DimOffset(OriginalWave,1),DimDelta(OriginalWave,1)*Average,OutputWave
		OutputWave=0
		i=0
		do
			OutputWave+=OriginalWave[p][q*Average+i][r]
			i+=1
		while (i<Average)
	endif
	if (axis==2)
		Redimension/N=(-1,-1,Nb) OutputWave
		Setscale/P z DimOffset(OriginalWave,2),DimDelta(OriginalWave,2)*Average,OutputWave
		OutputWave=0
		i=0
		do
			OutputWave+=OriginalWave[p][q][r*Average+i]
			i+=1
		while (i<Average)
	endif
end	

////////////////////////  OTHERS : to find Ef in an energy run or correct curvature

Macro FindEf(minX,maxX)
// Should start in the folder with raw data
// Average the image over angle, differentiate and returns the minimum (see FindEdge, below)
// minX and maxX should be energy values around Ef (calculated as Other_angle-W)
// Does not work so well....
variable minX,maxX
variable Nb,i
//wave/T OriginalImage
//wave Other_angle
string name
variable W=-3.5
	Nb=Dimsize(OriginalImage,0)
	Make/O/N=(Nb) Ef_cor
	
	i=0
	do
		name=OriginalImage[i]
		Ef_cor[i]=FindEdge( $name ,minX+Other_Angle[i]+W,maxX+Other_Angle[i]+W)
		i+=1
	while (i<Nb)
end

///

function FindEdge(Name,minX,maxX)
wave name // name of a 2d wave
variable minX,maxX
variable i

Make/O/N=(dimsize(name,0)) AverageY
SetScale/P x, dimoffset(name,0),DimDelta(name,0), AverageY
AverageY=0
i=0
do
 	AverageY+=name[p][i]
 	i+=1
while(i<Dimsize(name,1))

Differentiate AverageY/D=AverageY_DIF	
Wavestats/Q /R=(minX,maxX) AverageY_Dif
print "Ef=",V_minloc
return V_minloc
KillWaves AverageY,AverageY_DIF
end
///

function FindEdgeEachLine(Name,minX,maxX)
// For each line, differentiate and save minimum as Ef
wave name // name of a 2d wave
variable minX,maxX
variable i

Make/O/N=(dimsize(name,0)) AverageY
SetScale/P x, dimoffset(name,0),DimDelta(name,0), AverageY
Make/O/N=(dimsize(name,1)) Edge
SetScale/P y, dimoffset(name,1),DimDelta(name,1), Edge
i=0
do
 	AverageY=name[p][i]
 	Differentiate AverageY/D=AverageY_DIF	
	Wavestats/Q /R=(minX,maxX) AverageY_Dif
	Edge[i]=V_minloc
	i+=1
	while(i<Dimsize(name,1))

//KillWaves AverageY,AverageY_DIF
end

//////////////////////////////////////////////

Macro Correct_Curvature(wave3D,waveCurvature)
string wave3D,waveCurvature
// x is angle, y is energy, z is something else
// 1D wave waveCurvature contains Fermi level as a function of angle

Duplicate/O $wave3D temp_3D
temp_3D=$wave3D(x)(y+$waveCurvature(x))(z)

end

///////////////////////////////////////////////////////////////////:
function NoNorb()
// Creates a profile equal to 1, so that data are not normalized 
svar InputFolderName=root:process:InputFolderName
	SetDataFolder $InputFolderName	
	Make/O/N=100 NoNorm
	SetScale/I x, -20, 20, NoNorm
	NoNorm=1
	execute "Select_WaveToNor(\"\",0,\"\")"
end