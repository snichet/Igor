#pragma rtGlobals=1		// Use modern global access method.

// Always work on the data of one folder, containing a 3D wave called tmp_3D
// If this wave exists, "Window Plot of 3D Wave" from the menu will create the 3D window
// To create it (see procedures at the bottom of this file) : 
//		- to compile it from 2D images, use Make_3DWave() (NB : not so much used, and not shown in menu currently) 
// 		- to compile it from raw data : use process pannel (needs a table of parameters, see ProcessImages procedure)

// The z axis of tmp_3D can be theta, phi, energy or temperature.
// Looks at root:process:mode to know which one is used
// WARNING : Theta value remains the experimental one. It does not change with offset_theta. Ky does change.

// The file shown in the window are 2D slices of tmp_3D
// tmp_3D might be rotated, tmp_raw_3D is then created and contains original data (see Rotation_Disp)
// When selecting FS from the menu : work on the rotated data 

// Value for pi/a called lattice (see LoadImage)
// Warning : For FS, 0 of energy must be Ef 

// Switch to Kx : only applied to tmp_2D (tmp_3D stay with angle)
// It uses Transform_Image_True from ThetaPhi_conversions
// It should include a correction for theta, but this depends much on phi, so it's not easy. 

// Two fermi Surface can be done : 
// Theta_phi : raw integration
// Kx-Ky : true conversion, uses correct_FS from ThetaPhi_conversions

//Flags:
//	Flag_mode =0 for theta axis, 1 for Kx axis
// Build 3 windows : Theta windows ("Load3DImage(folder)"), Theta-Phi FS ("MakeFS"), Kx-Ky FS ("MakeFS_k")
//


Macro Load3DImage_menu()
	string folder
// 	prompt folder, "Folder"
//	DoPrompt "Enter folder name" folder

	//Execute "CreateBrowser prompt=\"Choose the data folder containing the data and click OK\" "
	CreateBrowser prompt="Choose the data folder containing the data and click OK"
	if (v_flag==1)
		folder = GetDataFolder(1)[0,strlen(GetDataFolder(1))-2]
	if (DataFolderExists(folder))
	 execute "Load3DImage(\""+folder+"\")"
	endif 
	endif
end

Proc Load3DImage(folder)
String folder
//Work on tmp_raw_3D  (must have been created by Make3Dwave, which also create slit_min)	
// X axis is slit axis
// Y axis is energy
// Z axis is theta value (or parameter to be changed)
//Create a window with the 2D plot of tmp_3D(theta_min)
//A cursor allow to see the different theta values of tmp_3D 


string path,name,nameforKy 

	if (cmpstr(folder[0,3],"root")==0) //folder doit contenir juste le nom du directory, path le chemin complet
		path=folder
		folder=folder[5,strlen(folder)]
		else
		path="root:"+folder
	endif
	SetDataFolder path
	//Duplicate/O tmp_raw_3D tmp_3D     // tmp_raw_3D only for rotation. Does noty exist if rotation is not used.

	//Check if Window already exists...
		name=folder+"_"
		//print name
		DoWindow/F $name

	//End if window already exists
	
	//Create Window when does not exist (i.e. DoExist=0)
	if (v_flag==0) 
	
		Display/W=(26.25,48.5,486.75,303.5) 
		
 		variable/G Flag_mode//0=Slits 1=Kx

		Make/O/N=(DimSize(tmp_3D, 0),DimSize(tmp_3D, 1)) tmp_2D
		SetScale/P x DimOffset(tmp_3D, 0),DimDelta(tmp_3D, 0),"", tmp_2D
		SetScale/P y DimOffset(tmp_3D, 1),DimDelta(tmp_3D, 1),"", tmp_2D
		tmp_2D=tmp_3D[p][q][0] 
		AppendImage tmp_2D 
	 	DoWindow/C $name
		DoWindow/T $name, name//Title of window : directory name
	
		ModifyGraph axOffset(left)=10
	  	ModifyImage tmp_2D ctab= {*,*,PlanetEarth,1}
	  	ModifyGraph zero(left)=1
 
	 	//Duplicate/O tmp_raw_3D tmp_3D

	 	//Button for theta and Ky value (just display for Ky)
  	 	string/G mode // mode=theta, phi, energy or temperature. Normally defined by process images. Defined as theta otherwise
	  	if (cmpstr(mode,"")==0)
	  		mode="theta"
	  	endif
	  	variable/G offset_Slits,offset_theta
	  	variable/G slit_min=DimOffset(tmp_3D,0)+offset_slits //otherwise, increases each time the window is reopened
	  	variable/G theta_value=DimOffset(tmp_3D, 2)
	  	variable/G Ky
	  	variable theta_max
	  	SetVariable ThetaBox,pos={10,25},size={90,14},proc=ChangeTheta,title=mode,value=theta_value
	  	theta_max=DimOffset(tmp_3D, 2)+(DimSize(tmp_3D, 2)-1)*DimDelta(tmp_3D, 2)
	  	SetVariable ThetaBox limits={DimOffset(tmp_3D, 2),theta_max,DimDelta(tmp_3D, 2)}
	   	SetVariable KyBox,pos={10,45},size={90,14},proc=ChangeKy,title="Ky",value=ky
	  	SetVariable KyBox limits={-100,100,0.01} 
	  	if (cmpstr(mode,"energy")==0)
			SetVariable KyBox,title="Kz"
		endif
		if (cmpstr(mode,"Temperature")==0)
			// Theta just indicates the indice in the parameter table
			// Ky indicates the corresponding temperature
			SetVariable ThetaBox,title="indice"
			SetVariable KyBox,title="Temp"
			theta_value=0
			SetVariable ThetaBox limits={0,DimSize(tmp_3D, 2)-1,1} 
		endif
	
	  	//Button for rotation angle
	  	variable/G angle_rot=0,Slits_AfterRot=0
	  	SetVariable RotationBox,pos={10,75},size={90,14},proc=Rotation_Disp_choix,title="Rotation",value=angle_rot
	  	SetVariable RotationBox limits={-180,180,1} 
	
		//Button for energy and co
		variable/G photon,lattice,latticeC  //lattice=pi gives angstrom units
	  	//variable/G offset_Slits,offset_theta
	  	if (photon==0) //i.e. 1st time
	  	photon=31
	  	endif
	  	if (lattice==0) //i.e. 1st time
	  	lattice=pi
	  	endif
	  	if (latticeC==0) //i.e. 1st time
	  	latticeC=pi
	  	endif
	 	SetVariable PhotonBox,pos={10,105},size={90,14},proc =ChangeSlitsOffset,title="hn-W",value=photon
	  	SetVariable LatticeBox,pos={10,125},size={90,14},proc =ChangeSlitsOffset,title="lattice",value=lattice
	  	Ky=round(0.512/pi*lattice*sqrt(photon)*sin((theta_value-offset_theta)*pi/180)*100)/100
	  	if (cmpstr(mode,"energy")==0)
			SetVariable PhotonBox,title="V0"
			SetVariable cLatticeBox,pos={10,145},size={90,14},proc =ChangeSlitsOffset,title="lattice c",value=latticeC
			Ky=FindCenterOfSlitsKz(dimoffset(tmp_3D,2))
			variable/G WorkFunction=4.4
		endif
		if (cmpstr(mode,"Temperature")==0)
			Ky=Nor_other_angle[theta_value]	
		endif
	  	//Button for offsets
	  	SetVariable offset_SlitsBox,pos={10,170},size={90,14},proc =ChangeSlitsOffset,title="Off_Slits",value=offset_Slits
	  	SetVariable Offset_thetaBox,pos={10,190},size={90,14},proc =ChangeThetaOffset,title="Off_Theta",value=offset_theta
	  	SetVariable offset_SlitsBox limits={-180,180,0.5}
	  	SetVariable Offset_ThetaBox limits={-180,180,0.5}
	 	//Switch button
	 	if (Flag_mode==0)
	  		Button SwitchToKxBox size={90,25},pos={10,215}, title="Show Kx",  proc=SwitchToKx
	  		Label bottom "Slits"
	  	else
  	  		Button SwitchToKxBox size={90,25},pos={10,215}, title="Show Slits",  proc=SwitchToKx
  	  		Label bottom "Kx"
	  	endif
	  

	  	//Do Fermi Surface
	    	Button DoFS size={90,40},pos={10,245}, title="\\JCFermi Surface\rTheta-Phi",  proc=MakeFS
	    	Button DoFS_k size={90,40},pos={10,290}, title="\\JCFermi Surface\r kx-ky", proc=MakeFS_k_FromPannel
		if (cmpstr(mode,"energy")==0)
		    	Button DoFS_k title="\\JCFermi Surface\r kx-kz"
		endif
		if (cmpstr(mode,"temperature")==0)
		    	Button DoFS_k title="Map k vs T", proc=MakeEDCmap
		endif
 
	  	/////// In a bar at top of window, a few operation from ImageTool
	  	ControlBar 22
	  	//Do Stacks
	  	variable/G Flag_Stacks=0
  	  	Button Stacks size={93,17},pos={108,1}, title="Go to stacks",  proc=CreateStacks
	  	//Go back to raw data
	  	//Button Refresh size={50,15},pos={270,2}, title="Refresh",  proc=Refresh
	  	//Calculate Maximum of dispersion
	    	//variable/G Flag_maximum=0//don't show maximum at first
	    	//Button DoMax size={50,15},pos={210,2}, title="Max",  proc=MaximumMap
	    
	     	//RedTemp
	    	Button RedTempButton size={62,17},pos={430,1}, title="RedTemp",  proc=RedTemp
	    	variable/G Gamma1=1
             SetVariable GammaBox,pos={500,2},size={80,15},proc=RedoRedTemp,title="Gamma",value=gamma1
  	  	SetVariable GammaBox limits={0.1,1,0.1} 
	   	make/o/n=(256,3) RedTemp_CT,Image_CT
 	   	make/o/n=256 pmap=p
 	   	RedTemp_CT[][0]=min(p,176)*370
 	   	RedTemp_CT[][1]=max(p-120,0)*482
 	   	RedTemp_CT[][2]=max(p-190,0)*1000
 	   
 	   	ChangeSlitsOffset("",0,"","")
	  	ChangeThetaOffset("",0,"","")
     endif 	   

EndMacro

//-----------------------------------------------------------------------------------------------------------------------------------------------
//--------------Actions when clicking in Load3D------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------------------------------------

Macro ChangeTheta(ctrlname,bidon,varStr,varName):SetVariableControl
	String Ctrlname
	Variable bidon
	string varStr
	string varName
	variable indice_theta
	
	FindCorrectFolder()
	string/G mode
	theta_value=round(theta_value*100)/100
	indice_theta=(theta_value-DimOffset(tmp_3D,2))/DimDelta(tmp_3D,2)
	tmp_2D=tmp_3D[p][q][indice_theta]
	
	if (cmpstr(mode,"theta")==0)
		Ky=round(0.512/pi*lattice*sqrt(photon)*sin((theta_value-offset_theta)*pi/180)*100)/100
	endif	
	if (cmpstr(mode,"phi")==0)
		Ky=round(0.512/pi*lattice*sqrt(photon)*sin((offset_theta)*pi/180)*100)/100
	endif
	if (cmpstr(mode,"energy")==0 && angle_rot==0)
		Ky=FindCenterOfSlitsKz(theta_value)
	endif		
	if (cmpstr(mode,"temperature")==0)
		Ky=Nor_other_angle[theta_value]
		tmp_2D=tmp_3D[p][q][theta_value]
	endif
	
	if (flag_mode==1)  // tmp_2D showed with kx scale
		// REMEMBER : In all cases the x scale of tmp_3D is angle
		if (cmpstr(mode,"theta")==0)
			Duplicate/O tmp_2D temp
			SetScale/P x, dimoffset(tmp_3D,0), dimdelta(tmp_3D,0), temp
			Transform_Image_True("temp","E vs angle",0,theta_value,photon,lattice)   //changes with theta
			Duplicate/O temp tmp_2D 
		endif	
		if (cmpstr(mode,"Energy")==0 && angle_rot==0)
			//tmp_2D must be rescaled with the new photon energy
			Duplicate/O tmp_2D temp
			SetScale/P x, dimoffset(tmp_3D,0), dimdelta(tmp_3D,0), temp
			Transform_Image_True("temp","E vs angle",0,0,theta_value-WorkFunction,lattice)   
			Duplicate/O temp tmp_2D 
		endif
	endif
			
	//if (Flag_maximum==1)
	//	max_1D=max_2D[p][indice_theta]
	//endif
	DoWindow/F Zoom_Lines
	if (v_flag==1)
		Show_lines(" ")
	endif
	
	Refresh_FSlines()
		
EndMacro 

/////

Macro ChangeKy(ctrlname,bidon,varStr,varName):SetVariableControl
	String Ctrlname
	Variable bidon
	string varStr
	string varName
	variable indice_theta
	variable ky_min,ky_max
		
	FindCorrectFolder()
	string/G mode
	if (cmpstr(mode,"theta")==0)
		Ky_min=round(0.512/pi*lattice*sqrt(photon)*sin((DimOffset(tmp_3D,2)-offset_theta)*pi/180)*100)/100
		Ky_max=DimOffset(tmp_3D,2)-offset_theta+(Dimsize(tmp_3D,2)-1)*DimDelta(tmp_3D,2)
		Ky_max=round(0.512/pi*lattice*sqrt(photon)*sin((Ky_max)*pi/180)*100)/100
	endif
	if (cmpstr(mode,"energy")==0)
			variable E_max
			ky_min=FindCenterOfSlitsKz(dimoffset(tmp_3D,2))
			E_max=DimOffset(tmp_3D,2)+(Dimsize(tmp_3D,2)-1)*DimDelta(tmp_3D,2)
			ky_max=FindCenterOfSlitsKz(E_max)
	endif
	if (ky<ky_min)
		ky=ky_min
	endif
	if (ky>ky_max)
		ky=ky_max
	endif
	
	if (cmpstr(mode,"theta")==0)
		theta_value=round(180/pi*asin(Ky/0.512/lattice*pi/sqrt(photon))+offset_theta)
		//print "yo",theta_value,ky
		// Ky=round(0.512/pi*lattice*sqrt(photon)*sin((theta_value+offset_theta)*pi/180)*100)/100
	endif
	
	if (cmpstr(mode,"energy")==0)
			variable angle0
			angle0=dimoffset(tmp_3D,0)+dimDelta(tmp_3D,0)*(dimSize(tmp_3D,0)+1)/2// Tilt angle at the center of the slits
			angle0=sqrt(angle0^2+offset_theta^2) // total angle from zero
			theta_value=((Ky*pi/latticeC)^2/0.512^2-photon)/(1-sin(angle0*pi/180)^2)+WorkFunction
	endif

	indice_theta=(theta_value-DimOffset(tmp_3D,2))/DimDelta(tmp_3D,2)
	tmp_2D=tmp_3D[p][q][indice_theta]

	Refresf_FS()
	
EndMacro 

//////

Macro SwitchToKx(ctrlname):ButtonControl 
      String Ctrlname
       //tmp_3D is not changing. We just transform tmp_2D to k scale using Transform_Image_True from AzimuthMapping procedure
	//Other places using Kx correction : ChangeSlitsOffset
	
	variable indice_theta

	FindCorrectFolder()
	string/G mode
	if (Flag_mode==0)   // Conversion from angle to k
		if (cmpstr(mode,"energy")==0)
			// conversion should use theta value, uses 0 here because it is not saved
			Transform_Image_True("tmp_2D","E vs angle",0,offset_theta,theta_value-WorkFunction,lattice)   
		endif
		if (cmpstr(mode,"theta")==0)
			Transform_Image_True("tmp_2D","E vs angle",0,theta_value,photon,lattice)   
		endif
		if (cmpstr(mode,"temperature")==0 || cmpstr(mode,"phi")==0)
			// conversion should use theta value, uses offset_theta here because it is not saved
			Transform_Image_True("tmp_2D","E vs angle",0,offset_theta,photon,lattice)   
		endif
		Label bottom "Kx"
		Flag_mode=1
	 	Button SwitchToKxBox title="Show Slits"
	else // Conversion from angle to k
		indice_theta=(theta_value-DimOffset(tmp_3D,2))/DimDelta(tmp_3D,2)
		SetScale/P x DimOffset(tmp_3D,0),DimDelta(tmp_3D,0),"", tmp_3D, tmp_2D
		tmp_2D=tmp_3D[p][q][indice_theta]
		Label bottom "Slits"
		Flag_mode=0
		 Button SwitchToKxBox title="Show Kx"
	endif
EndMacro

/////////

Macro ChangeSlitsOffset(ctrlname,bidon,varStr,varName):SetVariableControl
	String Ctrlname
	Variable bidon
	string varStr
	string varName
	//Called by change in photon, lattice or slits-offsets

	variable k_min,k_max, Slits_AfterRot,K_AfterRot,Slits_max,indice_theta
	string path,name
		
	FindCorrectFolder()
	string/G mode
	offset_Slits=round(offset_Slits*10)/10
	// Shift tmp_raw_3D and tmp_3D
	if (exists("tmp_raw_3D")==1)
		Slits_AfterRot=DimOffset(tmp_3D,0)-DimOffset(tmp_raw_3D,0)
		Slits_max=slit_min-offset_Slits+(Dimsize(tmp_raw_3D,0)-1)*DimDelta(tmp_raw_3D,0)
		SetScale/I x slit_min-offset_Slits,Slits_max,"", tmp_raw_3D	
	else
		Slits_AfterRot=0
	endif	

	Slits_max=slit_min-offset_Slits+Slits_AfterRot+(Dimsize(tmp_3D,0)-1)*DimDelta(tmp_3D,0)
	SetScale/I x slit_min-offset_Slits+Slits_AfterRot,Slits_max,"", tmp_3D,tmp_2D
	indice_theta=(theta_value-DimOffset(tmp_3D,2))/DimDelta(tmp_3D,2)
	tmp_2D=tmp_3D[p][q][indice_theta]
	
	if (cmpstr(mode,"energy")==0)
			Ky=FindCenterOfSlitsKz(theta_value) 
	endif
	if (flag_mode==1)
		if (cmpstr(mode,"energy")==0)
			Transform_Image_True("tmp_2D","E vs angle",0,offset_theta,theta_value-WorkFunction,lattice)  
			else	
			if (cmpstr(mode,"theta")==0)
				Transform_Image_True("tmp_2D","E vs angle",0,theta_value,photon,lattice)   
				else
				Transform_Image_True("tmp_2D","E vs angle",0,offset_theta,photon,lattice)   
			endif
		endif	
	endif
	
	Refresh_FS()
EndMacro	

///////

Macro ChangeThetaOffset(ctrlname,bidon,varStr,varName):SetVariableControl
	String Ctrlname
	Variable bidon
	string varStr
	string varName
	variable Theta_AfterRot
	variable ky_min,ky_max
	string path,name
		
	FindCorrectFolder()
	string/G mode
	
	if (cmpstr(mode,"temperature")==0)
		// do nothing
	else
		offset_theta=round(offset_theta*10)/10
		if (exists("tmp_raw_3D")==1)
			Theta_AfterRot=DimOffset(tmp_3D,2)-DimOffset(tmp_raw_3D,2)
			else
			Theta_AfterRot=0
		endif	
		if (cmpstr(mode,"theta")==0)
			Ky=round(0.512/pi*lattice*sqrt(photon)*sin((theta_value-Offset_theta+Theta_AfterRot)*pi/180)*100)/100
		endif
		if (cmpstr(mode,"energy")==0)
			Ky=FindCenterOfSlitsKz(theta_value)
		endif
		Refresh_FS()
	endif
EndMacro	


////////////   Rotation--------------------------------------------------------

Macro Rotation_Disp_choix(ctrlname,bidon,varStr,varName):SetVariableControl
	String Ctrlname
	Variable bidon
	string varStr
	string varName
	
	FindCorrectFolder()
	if (cmpstr(mode,"energy")==0) 	
		Rotation_Energy_Disp()
		else
		Rotation_Disp()
	endif
end

////////

Macro Rotation_Disp()

	FindCorrectFolder()

	//Go to Slits mode for calculation
	variable changement_temp
	Changement_temp=0
	if (Flag_mode==1) 
		SwitchToKx("")
		Changement_temp=1
	endif

	//Rotate
	if (angle_rot==0)
		if  (exists("tmp_raw_3D")==1)
			Duplicate /O tmp_raw_3D tmp_3D
			Killwaves tmp_raw_3D
			//If does not exist, probably a mistake, do nothing
		endif	
	else
		if  (exists("tmp_raw_3D")==1)
			// Already rotated, go back to original data before rotating again
			Duplicate /O tmp_raw_3D tmp_3D  
		else
			// Create backup
			Duplicate /O tmp_3D tmp_raw_3D  
		endif
		LetsRotate3D(tmp_3D,angle_rot)
	endif 
	
	// Refresh tmp_2D
	Redimension/N=(DimSize(tmp_3D,0),DimSize(tmp_3D,1)) tmp_2D
	SetScale/P x DimOffset(tmp_3D,0),DimDelta(tmp_3D,0),"", tmp_2D
	SetScale/P y DimOffset(tmp_3D,1),DimDelta(tmp_3D,1),"", tmp_2D

	tmp_2D=tmp_3D[p][q][DimSize(tmp_3D, 2)/2]//Load the image at center
	theta_value=DimOffset(tmp_3D, 2)+round(DimSize(tmp_3D, 2)/2)*DimDelta(tmp_3D, 2)
	SetVariable ThetaBox limits={DimOffset(tmp_3D, 2),DimOffset(tmp_3D, 2)+(DimSize(tmp_3D, 2)-1)*DimDelta(tmp_3D, 2),DimDelta(tmp_3D, 2)}

	//Go back to Kx mode 
	if (Changement_temp==1) 
		SwitchToKx("")
	endif
	
	Refresh_FS()	

EndMacro

////

Macro Rotation_Energy_Disp()
// This should give the dispersion at constant kz

	variable Nb_kx,Nb_kz,Nb_energy

	FindCorrectFolder()

	if (angle_rot==0)
		if (exists("tmp_raw_3D")==1)
			Duplicate /O tmp_raw_3D tmp_3D
			// if does not exist probably a mistake : do nothing
		endif	
		flag_mode=0
	else
		MakeFS(" ")
		//Correct_FermiSurface_kz(FS_2D,offset_theta,phi,delta_FS)
		if (exists("tmp_raw_3D")==1)
			//already rotated go back to zero value before rotating again
			Duplicate/O tmp_raw_3D tmp_3D  // keep same number of points as measured, should not be a bad choice 
			else
			// Not in rotation mode, save original data as tmp_raw_3D
			Duplicate/O tmp_3D tmp_raw_3D  // keep same number of points as measured, should not be a bad choice 
		endif	
		variable kx_start,kx_stop,kz_start,kz_stop
		kx_start=DimOffset(correct_FS,0)
		kx_stop=kx_start+(DimSize(correct_FS,0)-1)*DimDelta(correct_FS,0)
		kz_start=DimOffset(correct_FS,1)
		kz_stop=kz_start+(DimSize(correct_FS,1)-1)*DimDelta(correct_FS,1)
		SetScale/I x kx_start,kx_stop, tmp_3D
		SetScale/I z kz_start,kz_stop, tmp_3D		

		tmp_3D=interp3D(tmp_raw_3D,180/pi*asin( x*pi/lattice/ 0.512 / sqrt( (FindEnergy(x,z)-WorkFunction) ) ),y,FindEnergy(x,z))

	endif //if on angle_rot=0

	Redimension/N=(DimSize(tmp_3D,0),DimSize(tmp_3D,1)) tmp_2D
	SetScale/P x DimOffset(tmp_3D,0),DimDelta(tmp_3D,0),"", tmp_2D
	SetScale/P y DimOffset(tmp_3D,1),DimDelta(tmp_3D,1),"", tmp_2D
	
	string name
	name=GetDatafolder(0)+"_"
	DoWindow/F $name
	tmp_2D=tmp_3D[p][q][DimSize(tmp_3D, 2)/2]//Load the image at center
	theta_value=DimOffset(tmp_3D, 2)+round(DimSize(tmp_3D, 2)/2)*DimDelta(tmp_3D, 2)
	SetVariable ThetaBox limits={DimOffset(tmp_3D, 2),DimOffset(tmp_3D, 2)+(DimSize(tmp_3D, 2)-1)*DimDelta(tmp_3D, 2),DimDelta(tmp_3D, 2)}
	Label bottom "Kx"
	Flag_mode=1
 	Button SwitchToKxBox title="Show Slits"
	 	
	name="FS_k_"+GetDatafolder(0)
	if (v_flag==0)
		KillWindow $name   // no sense when rotated
	endif	
	Refresh_FS()
EndMacro

////

function FindEnergy(x,z)
variable x,z
nvar lattice,latticec,WorkFunction,photon
	return ((x*pi/lattice)^2+(z*pi/latticec)^2)/0.512^2+WorkFunction-photon
end

////// Go to stacks --------------------------------
Macro CreateStacks(ctrlname):ButtonControl
	String Ctrlname
	string name,curr	
	
	//Transfer and transpose tmp_2D in ImageTools
	FindCorrectFolder()
	curr=GetDataFolder(1)
	//Zoom in the area display on the window plot
	GetAxis bottom
	name=curr+"tmp_2D"
	ShowImageTool( )
	Duplicate/O $name root:IMG:Image
	DoLoad(curr) 
	ImgModify(" ", 0,"Transpose")
	SetAxis left v_min,v_max
	//Do stacks through ImageTool
	CreateStack("")
	DoWindow/F Stack_
	DoWindow/F ImageTool
end

Macro CreateStacksEDC(ctrlname):ButtonControl
	String Ctrlname
	string name,curr	
	
	//Transfer and transpose tmp_2D in ImageTools
	FindCorrectFolder()
	curr=GetDataFolder(1)
	//Zoom in the area display on the window plot
	GetAxis bottom
	name=curr+"EDCmap"
	ShowImageTool( )
	Duplicate/O $name root:IMG:Image
	DoLoad(curr) 
	UpdateStack()
end

Macro CreateStacksFS(ctrlname):ButtonControl
	String Ctrlname
	string name,curr	
	
	//Transfer and transpose tmp_2D in ImageTools
	FindCorrectFolder()
	curr=GetDataFolder(1)
	//Zoom in the area display on the window plot
	GetAxis bottom
	name=curr+"FS_2D"
	ShowImageTool( )
	Duplicate/O $name root:IMG:Image
	DoLoad(curr) 
	UpdateStack()
end

//--------------------------------------------------------------------------------------------------------------------------------------------------
// -------------------------  Everything for Fermi surface -------------------------  -------------------------  -------------------------  
//--------------------------------------------------------------------------------------------------------------------------------------------------

Macro MakeFS(ctrlname):ButtonControl
	string Ctrlname
	//Create a window with the FS of tmp_3D
	//Cursors allow to scan energies
	// If mode= temperature, creates a 2D wave with EDC spectra at one k value for all temperatures

	//Warning : 0 must be Ef 
	variable indice_zero
	string name,path
 	variable Doexist=1
 		
	//Check whether window already exist 
	FindCorrectFolder()
	path=GetDataFolder(1)
	SetDataFolder path 	
	
	//Go to procedure to create and integrate tmp_3D
	variable/G energy_FS
	variable/G deltaE_FS
	//if (cmpstr(mode,"temperature")==0)
	//	deltaE_FS=0
	//	EDCmap()
	//else
		IntegrateForFS()
	//endif

 	Make/O/N=2 FS_line
  	SetScale/I x DimOffset(FS_2D, 0),DimOffset(FS_2D, 0)+(DimSize(FS_2D, 0)-1)*DimDelta(FS_2D, 0),"", FS_line
	FS_line:=Theta_value-offset_theta

	//Create window if it does not already exists
	name="FS_"+path[5,strlen(path)-2]
 	DoWindow/F $name
       if (v_flag==0) //i.e window does not exist : create a new one
		Display/W=(400,10,850,350);AppendImage FS_2D
 		DoWindow/C $name
 		DoWindow/T $name name
		AppendToGraph FS_line

		ControlBar 22
   		//ShowDisp
   		Button ShowDisp size={110,17},pos={16,1}, title="Show disp",  proc=Show_Disp
  	  	Button Stacks size={93,17},pos={190,1}, title="Go to stacks",  proc=CreateStacksFS
   		//Button ShowLines size={70,25},pos={10,260}, title="Show lines",  proc=Show_lines
   				
		//Ultimately should be hooked to refresh
		//SetWindow Graph1 hook=refreshFS
	  	ModifyGraph axOffset(left)=20
        	ModifyImage FS_2D ctab= {*,*,PlanetEarth,1}
        	ModifyGraph zero(left)=1
		ModifyGraph zero=1
       	//Button for energy
  		SetVariable EnergyBox,pos={10,30},size={130,14},proc=RecalculateFS,title="Energy (meV)",value=energy_FS
  		SetVariable EnergyBox limits={DimOffset(tmp_3D,1)*1000,(DimOffset(tmp_3D,1)+(DimSize(tmp_3D,1)-1)*DimDelta(tmp_3D,1))*1000,1000*DimDelta(tmp_3D,1)}
  		//Button for energy increment
 		SetVariable IntegrationBox,pos={10,55},size={130,14},proc=RecalculateFS,title="Integration (meV)",value=DeltaE_FS
  		SetVariable IntegrationBox limits={0,1000,1000*DimDelta(tmp_3D,1)}
  		//Button for offsets
 		SetVariable offset_SlitsFS,pos={30,100},size={120,14},proc =ChangeSlitsOffset,title="Off_Slits",value=offset_Slits
  		SetVariable offset_SlitsFS limits={-90,90,0.5} 
  		SetVariable Offset_thetaFS,pos={30,125},size={120,14},proc =ChangeThetaOffset,title="Off_Theta",value=offset_theta
  		SetVariable Offset_thetaFS limits={-90,90,0.5} 

   		Button DoFS_k size={90,40},pos={10,350}, title="\\JCFermi Surface\r Kx-ky",  proc=MakeFS_k_FromPannel 
   		Label bottom "Slit angle"
   		//Label left mode
 
   		if (cmpstr(mode,"energy")==0)
   			Button MDCmap size={90,40},pos={10,300}, title="MDC map",  proc=MyMDCmap
   		endif
  	endif //if on window already active
EndMacro

////////////////

Function IntegrateForFS()
// Integrate dispersion between energy-integration/2 and energy+integration/2
// Only for angles : use kx-ky map for reciprocal space
// Except if temperature mode : then rescaled as k if switch is on k

nvar energy_FS,deltaE_FS,offset_theta,theta_value
variable indice,indice_Emin,indice_Emax,delta
wave FS_2D,tmp_3D
string/G mode

	if (DeltaE_FS==0) //Otherwise last value used
		DeltaE_FS=round(1000*DimDelta(tmp_3D,1) )
	endif

	//Create FS_2D
 	Make/O/N=(DimSize(tmp_3D, 0),DimSize(tmp_3D, 2)) FS_2D
 	SetScale/P x DimOffset(tmp_3D, 0),DimDelta(tmp_3D, 0),"", FS_2D  
 	SetScale/P y DimOffset(tmp_3D, 2)-offset_Theta,DimDelta(tmp_3D, 2),"", FS_2D  // FS_2D is always against angle
 	if (cmpstr(mode,"temperature")==0)
		SetScale/P x DimOffset(tmp_2D, 0),DimDelta(tmp_2D,0),"", FS_2D
	endif
	//Calculate
	FS_2D=0
	delta=round(DimDelta(tmp_3D,1)*1000)
	energy_FS=round(energy_FS/delta)*delta
	DeltaE_FS=round(DeltaE_FS/delta)*delta
  	indice_Emin=trunc(( (energy_FS-DeltaE_FS)/1000 -DimOffset(tmp_3D, 1))/DimDelta(tmp_3D, 1))
  	indice_Emax=trunc(((energy_FS+DeltaE_FS)/1000-DimOffset(tmp_3D, 1))/DimDelta(tmp_3D, 1))
	//print indice,E_min,p_Emin
  	indice=indice_Emin
	do //Sum of tmp_3D between p_Emin and p_Emax
   		FS_2D[][]+=tmp_3D[p][indice][q]
	      indice+=1
       while (indice<=indice_Emax)
End
///
Macro RecalculateFS(ctrlname,bidon,varStr,varName):SetVariableControl
	String Ctrlname
	Variable bidon
	string varStr
	string varName
	variable indice_energy	
	//Called by change in energy or width for integration
	
	Refresh_FS()
 EndMacro
 
////////////////////

Macro MakeEDCmap(Ctrlname):ButtonControl 
string  Ctrlname
// Used in temperature mode
// Extract EDC at specified k value (k variable called energy)
// Integrate over 2*deltaE+1 slices
// y axis is indice

	//Warning : 0 must be Ef 
	variable indice_zero
	string name,path
 	variable Doexist=1
 		
	//Check whether window already exist 
	FindCorrectFolder()
	path=GetDataFolder(1)
	SetDataFolder path 	
	
	//Go to procedure to create and integrate tmp_3D
	variable/G K_map
	variable/G deltaK_map

	variable indice,indice_k
	//wave EDCmap,tmp_3D

	//if (K_map==0)
	//	K_map=dimoffset(tmp_2D,0)+dimsize(tmp_2D,0)*dimDelta(tmp_2D,0)/2  // default k value : middle of the window
	//endif	
	
	//Create EDCmap : x is energy, y is indice
 	Make/O/N=(DimSize(tmp_3D, 1),DimSize(tmp_3D, 2)) EDCmap
 	SetScale/P x DimOffset(tmp_3D, 1),DimDelta(tmp_3D, 1),"", EDCmap  
 	SetScale/P y 0,1,"", EDCmap
 	
 	EDCmap=0
 	
 	indice_k=trunc(( K_map-DimOffset(tmp_2D, 0))/DimDelta(tmp_2D, 0))  // tmp_2D either in angle or k mode
  	
 	indice=-deltaK_map
	do //Sum of tmp_3D between p_Emin and p_Emax
   		EDCmap[][]+=tmp_3D[indice+indice_k][p][q]
	      indice+=1
       while (indice<=deltaK_map)
       
       
	//Create window if it does not already exists
	name="EDCmap_"+path[5,strlen(path)-2]
 	DoWindow/F $name
       if (v_flag==0) //i.e window does not exist : create a new one
		variable/G deltaK_map=1
		variable/G K_map=DimOffset(tmp_2D,0)+(DimSize(tmp_2D,0)-1)*DimDelta(tmp_2D,0)/2
		Display/W=(400,10,850,350);AppendImage EDCmap
 		DoWindow/C $name
 		DoWindow/T $name name
		
		ControlBar 22
   		//ShowDisp
   		Button ShowDisp size={110,17},pos={16,1}, title="Show disp",  proc=Show_Disp
   		Button Stacks size={93,17},pos={190,1}, title="Go to stacks",  proc=CreateStacksEDC
   		//Button ShowLines size={70,25},pos={10,260}, title="Show lines",  proc=Show_lines
   				
		//Ultimately should be hooked to refresh
		//SetWindow Graph1 hook=refreshFS
	  	ModifyGraph axOffset(left)=20
        	ModifyImage EDCmap ctab= {*,*,PlanetEarth,1}
        	ModifyGraph zero(left)=1
		ModifyGraph zero=1
       	//Button for energy
  		SetVariable KBox,pos={10,30},size={130,14},proc=RecalculateEDCmap,title="k ",value=k_map
  		SetVariable KBox limits={DimOffset(tmp_2D,0),(DimOffset(tmp_2D,0)+(DimSize(tmp_2D,0)-1)*DimDelta(tmp_2D,0)),DimDelta(tmp_2D,0)}
  		//Button for energy increment
 		SetVariable IntegrationKBox,pos={10,55},size={130,14},proc=RecalculateEDCmap,title="Integration (slices)",value=DeltaK_map
  		SetVariable IntegrationKBox limits={0,1000,1}

   	endif //if on window already active
  	
  	

 End
 //////////////////////////
 
 Macro Rescale_Kf(Ctrlname):ButtonControl 
string  Ctrlname
// IS IT USED ????
// Used in temperature mode to rescale tmp_3D. Zero for x is given by a wave (usually kf)
// Remember that x of tmp_3D is in angle !!
Wavestats/Q theta_kf
SetScale/P x Dimoffset(tmp_3D,0)-V_avg,DimDelta(tmp_3D,0),"", tmp_3D,tmp_2D
tmp_3D=tmp_raw_3D(x+Theta_Kf(z))(y)(z)
//ChangeTheta("",0,"","")
 End

//////////
function EDCmap3()
variable k,delta_k
prompt k, "k value"
prompt delta_k,"delta k"
DoPrompt "Loading...",k,delta_k
EDCmap2(k,delta_k)
end
//
Function EDCmap2(k,delta_k)
// Extract EDC at specified k value 
// Integrate over 2*deltaE+1 slices
//Save it as EDC_map

variable k,delta_k
variable indice,indice_k
wave FS_2D,tmp_3D

	//Create EDC_map : x is energy, y is indice
 	Make/O/N=(DimSize(tmp_3D, 1),DimSize(tmp_3D, 2)) EDC_map
 	SetScale/P x DimOffset(tmp_3D, 1),DimDelta(tmp_3D, 1),"", EDC_map
 	SetScale/P y 0,1,"", EDC_map  
 	EDC_map=0
 	
 	indice_k=trunc(( k -DimOffset(tmp_2D, 0))/DimDelta(tmp_2D, 0))  // tmp_2D either in angle or k mode
  	
 	indice=-delta_k
	do //Sum of tmp_3D between p_Emin and p_Emax
   		EDC_map[][]+=tmp_3D[indice+indice_k][p][q]
	      indice+=1
       while (indice<=delta_k)
       Display;AppendImage EDC_map
       ModifyImage EDC_map ctab= {*,*,PlanetEarth,1}
 End
//////////////////  
 Macro RecalculateEDCmap(ctrlname,bidon,varStr,varName):SetVariableControl
	String Ctrlname
	Variable bidon
	string varStr
	string varName
	variable indice_energy	

      FindCorrectFolder()
      MakeEDCmap("")
 
  EndMacro

///////

Function MyMDCmap(ctrlname):ButtonControl
string ctrlname
// Convert FS_2D into MDC map 
// Value of energy and integration are the same as FS_2D

nvar lattice
variable indice,indice_k
wave FS_2D,tmp_3D
variable energy_stop,angle_start,angle_stop,tilt,energy
variable WF=4.2
variable theta=0 // should be done : theta_wave as parameter to do exact corrections
string curr,name

	curr=GetDataFolder(1)
 	Duplicate/O FS_2D MDCmap
 	// On veut dimensionner l'image de façon à couvrir toutes les énergies.
 	variable k_start,k_stop
 	energy=dimOffset(FS_2D,1)-WF
 	FindCorrectk(FS_2D,0,theta,energy,lattice)
	wave index_k 
	k_start=DimOffset(index_k,0)
	k_stop=k_start+DimDelta(index_k,0)*(dimSize(index_k,0)-1)
	
	energy=dimOffset(FS_2D,1)+dimdelta(FS_2D,1)*(dimSize(FS_2D,1)-1)-WF
 	FindCorrectk(FS_2D,0,theta,energy,lattice)
	wave index_k 
	k_start=min(k_start,DimOffset(index_k,0))
	k_stop=max(k_stop,DimOffset(index_k,0)+DimDelta(index_k,0)*(dimSize(index_k,0)-1))
	
	SetScale/I x k_start,k_stop,"", MDCmap  
 	MDCmap=NaN
 	
 	indice=0
	do 
		energy=dimoffset(FS_2D,1)+indice*dimdelta(FS_2D,1)-WF
		FindCorrectk(FS_2D,0,theta,energy,lattice)
		MDCmap[][indice]=FS_2D[index_k(k_start+p*DimDelta(MDCmap,0) )][indice]
	      indice+=1
       while (indice<=dimsize(FS_2D,1))
       //Load in ImageTool
      	name=curr+"MDCmap"
	execute "ShowImageTool( )"
	Duplicate/O $name root:IMG:Image
	execute "DoLoad(\""+curr+"\")"
 End

// Kx-Ky or Kx-Kz Fermi Surface -----------------------------------------------------------------------------------------------

Macro MakeFS_k_FromPannel(ctrlname):ButtonControl
string ctrlname
	FindCorrectFolder()
	MakeFS_k(" ")
end

Macro MakeFS_k(ctrlname):ButtonControl
string ctrlname
	
	string/G mode
	variable/G phi
	variable/G sample_tilt,phi_tilt 
	variable/G delta_FS,interp_side
	variable/G energy_FS
	variable/G deltaE_FS

	if (cmpstr(mode,"temperature")==0)
		deltaE_FS=0
		EDCmap()
	else
			
		if (delta_FS==0)
	    		delta_FS=min(abs(DimDelta(FS_2D,0)),abs(DimDelta(FS_2D,1)))*2  // delta for angle chosen as twice the minimum step value
		endif
		if (interp_side==0)
		    interp_side=abs(DimDelta(FS_2D,1)) // default value = theta step 
		endif

	Refresh_FS() // Creates or updates FS_2D and updates Correct_FS if exists
		
	//Create window for kx-ky FS if it does not already exists
	string path,name
 	FindCorrectFolder()
	path=GetDataFolder(1)
	SetDataFolder path 	
	name="FS_k_"+path[5,strlen(path)-2]
 	DoWindow/F $name

      if (v_flag==0) //i.e window does not exist : create a new one	
		Display/W=(450,100,900,450)
		if (cmpstr(mode,"theta")==0 || cmpstr(mode,"phi")==0)
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

			AppendToGraph BZ_ky vs BZ_kx
			ModifyGraph lsize=2,rgb=(0,0,0)
			ModifyGraph zero=1
			ModifyGraph fSize=16
		endif
		DoWindow/C $name
 		DoWindow/T $name name

		//Control bar
		ControlBar 22
   		Button ShowDisp size={110,17},pos={16,1}, title="Show disp",  proc=Show_Disp
		SetVariable AngleStepBox,pos={190,1},size={120,14},limits={0,5,0.1},proc =Refresh_FS_k,title="Angle step",value=delta_FS
		SetVariable InterpBox,pos={370,1},size={120,30},limits={0,10,0.05},proc =Refresh_FS_k,title="Interpolation",value=interp_side
		
		//Button for energy
	  	SetVariable EnergyBox,pos={10,30},size={130,14},proc=RecalculateFS,title="Energy (meV)",value=energy_FS
  		SetVariable EnergyBox limits={DimOffset(tmp_3D,1)*1000,(DimOffset(tmp_3D,1)+(DimSize(tmp_3D,1)-1)*DimDelta(tmp_3D,1))*1000,1000*DimDelta(tmp_3D,1)}
	  	//Button for energy increment
 		SetVariable IntegrationBox,pos={10,55},size={130,14},proc=RecalculateFS,title="Integration (meV)",value=DeltaE_FS
	  	SetVariable IntegrationBox limits={0,1000,1000*DimDelta(tmp_3D,1)}
  		//Button for offsets	
		SetVariable TiltBox,pos={30,100},size={110,14},limits={-360,360,0.5},proc =ChangeSlitsoffset,title="Off_Slits",value=offset_slits
		SetVariable ThetaBox,pos={30,125},size={110,14},limits={-360,360,0.5},proc =ChangeThetaOffset,title="Off_Theta",value=offset_theta
		SetVariable PhiBox,pos={30,150},size={110,14},limits={-360,360,1},proc =Refresh_FS_k_window,title="Phi",value=phi
		// Sample misalignment : angle theta_tilt around one axis in (x,y) plane, rotated from Ox by phi_tilt 
      		SetVariable SampleTiltBox,pos={30,190},size={110,14},limits={-360,360,1},proc =Refresh_FS_k_window,title="sample tilt",value=sample_tilt
		SetVariable PhiTiltBox,pos={30,215},size={110,14},limits={-360,360,1},proc =Refresh_FS_k_window,title="Phi tilt",value=Phi_tilt
		
		Refresh_FS_k("",0,"","done")
		AppendImage Correct_FS
		ModifyImage Correct_FS ctab= {*,*,PlanetEarth,1}
		ModifyGraph axOffset(left)=10			
		Make/O/N=(DimSize(FS_2D,0)) FS_k_line_x,FS_k_line_y
		if (cmpstr(mode,"theta")==0)
			CalculateFS_k_line(theta_value-offset_theta,phi)
			AppendToGraph FS_k_line_y vs FS_k_line_x
		endif
		if (cmpstr(mode,"Phi")==0)
			CalculateFS_k_line(offset_theta,theta_value)
			AppendToGraph FS_k_line_y vs FS_k_line_x
		endif
		if (cmpstr(mode,"energy")==0)
			CalculateFS_k_line_energy(theta_value)
			AppendToGraph FS_k_line_y vs FS_k_line_x
		endif
	endif	
endif
end	


//////// Refresh for FS----------------------------------------------

Macro Refresh_FS()
string path, name,topwindow

	FindCorrectFolder()
	path=GetDataFolder(1)
		
	//Theta-Phi FS
	IntegrateForFs()
	name="FS_"+path[5,strlen(path)-2]
 	DoWindow $name
	if (v_flag==1)
		SetScale/I x DimOffset(FS_2D, 0),DimOffset(FS_2D, 0)+(DimSize(FS_2D, 0)-1)*DimDelta(FS_2D, 0),"", FS_line
	endif	
	  	
	//Also change FS_k offset if window exists
	name="FS_k_"+path[5,strlen(path)-2]
 	DoWindow $name
	if (v_flag==1)
		Refresh_FS_k("",0,"","done")	
	endif	
		
end

/////

Macro Refresh_FS_k_window(ctrlname,bidon,varStr,varName):SetVariableControl
	String Ctrlname
	Variable bidon
	string varStr
	string varName

FindCorrectFolder()
Refresh_FS_k(ctrlname,bidon,varStr,varName)

end

Macro Refresh_FS_k(ctrlname,bidon,varStr,varName):SetVariableControl
	String Ctrlname
	Variable bidon
	string varStr
	string varName
	variable indice_energy	
	//string mode=root:process:mode
	
	variable/G interp_side
	string/G mode
	variable/G delta_FS // angle step for correct_FS
	variable/G phi
	
	if (cmpstr(mode,"theta")==0 || cmpstr(mode,"temperature")==0)
		Correct_FermiSurface(FS_2D,phi,delta_FS)  // in ThetaPhi_conversion procedure
	endif	
	if (cmpstr(mode,"phi")==0 || cmpstr(mode,"temperature")==0)
		CorrectFermiSurface_VsPhi(FS_2D,delta_FS)  // in ThetaPhi_conversion procedure
	endif	
	if (cmpstr(mode,"energy")==0)
		variable/G offset_theta,phi
		Correct_FermiSurface_kz(FS_2D,offset_theta,phi,delta_FS)  // in ThetaPhi_conversion procedure
	endif	
	
	
	if (Interp_Side>0)
		//Fills all NaN points with interpolated values
		variable side
		side=round(interp_side/delta_FS)+1
		if (side>=3 && delta_FS>0)
			MatrixFilter/N=(side)/P=1 NaNZapMedian, Correct_FS	
		endif	
	endif
	
	Refresh_FSlines()
	
 EndMacro

//////

Macro Refresh_FSlines()
string path, name
	path=GetDataFolder(1)
	name="FS_k_"+path[5,strlen(path)-2]
 	DoWindow $name
	if (v_flag==1)
		if (cmpstr(mode,"theta")==0)
		CalculateFS_k_line(theta_value-offset_theta,phi)
		endif
		if (cmpstr(mode,"Phi")==0)
			CalculateFS_k_line(offset_theta,theta_value-phi)
		endif
		if (cmpstr(mode,"energy")==0)
			CalculateFS_k_line_energy(theta_value)
		endif
	endif	
end

///////

macro Show_disp(ctrlname):ButtonControl
	string Ctrlname
	
	FindCorrectFolder()
	string folder=GetDataFolder(1)
	folder=folder[0,strlen(folder)-2]  //remove : at the end
	Load3DImage(folder)

endmacro

//--------------------------------------------------------------------------------------------------------------------------------------------------
// -------------------------  Utilities -------------------- -------------------- -------------------------------------------------------------------  
//-------------------------------------------------------------------------------------------------------------------------------------------------- 

Macro RedTemp(ctrlname):ButtonControl
	String Ctrlname
		FindCorrectFolder()
		pmap:=255*(p/255)^gamma1
		Image_CT:=RedTemp_CT[pmap[p]][q]
		WaveStats/Q tmp_2D
		SetScale/I x V_min, V_max,Image_CT
		ModifyImage tmp_2D cindex=Image_CT
EndMacro	

Macro RedoRedTemp(ctrlname,bidon,varStr,varName):SetVariableControl
	String Ctrlname
	Variable bidon
	string varStr
	string varName
	string bid
	RedTemp(bid)
EndMacro	

/////

Macro FindCorrectFolder()
	// Read the folder to look to, through the wave plotted in the graph
	string name
	variable i

	name=WinName(0,1)
	SetDataFolder root: //Otherwise only partial path shown in wavelist
	GetWindow $name,wavelist
	//edit w_wavelist
	i=0
	do
		name=w_wavelist[i][0]
		//print name
		if (cmpstr(name,"tmp_2D")==0)
			name="FS_2D"
		endif
		if (cmpstr(name,"Correct_FS")==0)
			name="FS_2D"
		endif
		if (cmpstr(name,"EDCmap")==0)
			name="FS_2D"
		endif
		i+=1
	while (abs(cmpstr(name,"FS_2D"))>0) 
	
	//print name
	name=w_wavelist[i-1][1]

	//print GetWavesDataFolder($name,3)
	SetDataFolder GetWavesDataFolder($name,3)
endMacro

//////////////////////////////////////
function FindCenterOfSlitsKz(PhotonEnergy)
variable PhotonEnergy
	variable angle0, k0
	nvar offset_theta,photon,latticeC,Ky,WorkFunction  // NB : here photon=V0
	wave tmp_3D
	
	// General formula used at k=0 : kz = 0.512 sqrt (E - W + V0) in units of pi/c
	//         	E = photon energy (usually current theta parameter)
	//		W = work function, defined as root:process:WorkFunction, 4.4eV by default
	//		V0 = inner potential defined in the 3D window. Its name is root:process:photon
	// 		c = distance along z axis, to be defined in the 3D window
	// In addition, substract kx^2, where kx is defined as center of the slits
	angle0=dimoffset(tmp_3D,0)+dimDelta(tmp_3D,0)*(dimSize(tmp_3D,0)+1)/2// Tilt angle at the center of the slits
	angle0=sqrt(angle0^2+offset_theta^2) // total angle from zero
	k0=0.512*sqrt(PhotonEnergy-WorkFunction)*sin(angle0*pi/180) // k distance of the center of the slits from zero
	Ky=sqrt( 0.512^2*(PhotonEnergy-WorkFunction+photon)-k0^2)/pi*latticeC
	Ky=round(Ky*100)/100
	return Ky	
end		


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Procedures to create tmp_raw_3D (also used by ProcessImages)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

proc Smart3Dwave_FromMenu(path)
string path
	if (abs(cmpstr(path[0,3],"root"))>0)
     		path="root:"+path
	endif
	Smart3Dwave(path)
end

function Smart3Dwave(path)
string path
// All images in directory path should be normalized and centered on the right Slits0 (just compile them)
// They may have different energy bondaries : the program will look for min and max
// Will create tmp_3D, tmp_raw_3D, slit_min and Flag_mode

//Reads the table of parameters 
//  => should have waves OriginalImage, Theta_Angle,Slits_Angle and ProcessFlag in the folder containing normalized data
//           (these were automatically created if you used ProcessImages or can be created by setparameters in process panel)

variable energy_min,energy_max,delta_energy,NewEnergy_min,NewEnergy_max,i,j,fin
variable other_min,other_max,slit_max,delta_slit
variable Nbpnts_slit,Nbpnts_energy,Nbpnts_other,other,indice_other
variable slit_start,slit_stop,indice_slit_start, indice_slit_stop,Nb_slit
string name
nvar delta_other=root:process:delta_other
//svar mode=root:process:mode
variable newslit_min, newslit_max,first

     		SetDataFolder path
		svar mode
		wave/T NormalizedImage
		wave NorProcessFlag,Nor_Slit_Angle,Nor_Other_Angle
		variable/G Slit_min
				
		// First look for other_min and other_max (usually theta, but also temperature, photon energy...), slit_min and slit_max, energy_min and energy_max, among used files (i.e. with processFlag=1)
		// Also delete from normalized parameters table all files not flagged (useful especially for temperature mode)
			i=-1
			do 
				i+=1
			while (NorProcessFlag[i]==0) //Skip images with ProcessFlag=0	

			DeletePoints 0,i, NormalizedImage,NorProcessFlag,Nor_Other_Angle,Nor_Slit_Angle
			i=0
			name=NormalizedImage[i]
			If (waveexists($name)==0)
				abort "Can't find wave "+name
			endif
			
			//Initialize min and max of other with boundaries of first image
			other_min=Nor_Other_Angle[i]
			other_max=other_min
			//Same for slit axis, possibly with changing the sign of delta (we choose the output image to have Delta>0)
			if(DimDelta($name,1)>0)
				slit_min=DimOffset($name,1)
				slit_max=DimOffset($name,1)+DimDelta($name,1)*(DimSize($name,1)-1)
			else
				slit_max=DimOffset($name,1)
				slit_min=DimOffset($name,1)+DimDelta($name,1)*(DimSize($name,1)-1)
			endif
			//Same for energy axis
			energy_min=DimOffset($name,0)
			energy_max=DimOffset($name,0)+DimDelta($name,0)*(DimSize($name,0)-1)
					
			// Now loop on the other images and changes boundaries if necessary
			do
				i+=1
				if (NorProcessFlag[i]==1)
					//Check image exists
					name=NormalizedImage[i]
					If (waveexists($name)==0)
						abort "Can't find wave "+name
					endif
					//Check other
					if (Nor_Other_Angle[i]>other_max) 
						other_max=Nor_Other_Angle[i] 
					endif
					if (Nor_Other_Angle[i]<other_min) 
						other_min=Nor_Other_Angle[i] 
					endif
					//Check slits
					if(DimDelta($name,1)>0)
						newslit_min=DimOffset($name,1)
						newslit_max=DimOffset($name,1)+DimDelta($name,1)*(DimSize($name,1)-1)
					else
						newslit_max=DimOffset($name,1)
						newslit_min=DimOffset($name,1)+DimDelta($name,1)*(DimSize($name,1)-1)
					endif
					if (newslit_min<slit_min) 
						slit_min=newslit_min 
					endif
					if (newslit_max>slit_max) 
						slit_max=newslit_max 
					endif
					//Check energy
					newenergy_min=DimOffset($name,0)
					newenergy_max=DimOffset($name,0)+DimDelta($name,0)*(DimSize($name,0)-1)
					if (newenergy_min<energy_min) 
						energy_min=newenergy_min 
					endif
					if (newenergy_max>energy_max) 
						energy_max=newenergy_max 
					endif
				else // Image not flagged
				DeletePoints i,1, NormalizedImage,NorProcessFlag,Nor_Other_Angle,Nor_Slit_Angle	
				i-=1
			endif
		while (i<=numpnts(NormalizedImage))
		
		delta_slit=abs(DimDelta($name,1))
		delta_energy=DimDelta($name, 0)
		Nbpnts_energy=(energy_max-energy_min)/delta_energy+1

	 	//////////  Create 3D wave
		Nbpnts_slit=round((slit_max-slit_min)/delta_slit)+1
		Nbpnts_other=round((other_max-other_min)/delta_other)+1
		if (cmpstr(mode,"temperature")==0)
			Nbpnts_other=Numpnts(NormalizedImage)
			other_min=0
			delta_other=1
		endif		
		Make/N=(Nbpnts_slit,Nbpnts_energy,Nbpnts_other)/D/O tmp_3D
		Redimension/S tmp_3D
		SetScale/P x slit_min,delta_slit,"", tmp_3D
		SetScale/P y energy_min,delta_energy,"", tmp_3D
		SetScale/P z other_min,delta_other,"", tmp_3D
		tmp_3D=NaN
		 
		//// Fill 3D wave
		
		// For theta mode, sort parameters table, so that different slit values at same theta angle follow each other
		if (cmpstr(mode,"theta")==0)
			sort {Nor_Other_Angle,Nor_Slit_Angle},Nor_Other_Angle,Nor_Slit_Angle,NormalizedImage,NorProcessFlag  
		endif	

		i=0
		do
			Nb_slit=0
			if (NorProcessFlag[i]==1)
				name=NormalizedImage[i]
				Duplicate/O $name temp				
				// If Delta<0, reverse wave order
				if(DimDelta($NormalizedImage[i],1)<0)
					Duplicate/O $name temp2
					temp=temp2[p][DimSize($name,1)-1-q]
					first=DimOffset($NormalizedImage[i],1)+(DimSize($NormalizedImage[i],1)-1)*DimDelta($NormalizedImage[i],1)
					SetScale/P y, first, abs(DimDelta($NormalizedImage[i],1)), temp
					KillWaves temp2
				endif //end of reverse order
				
				other=Nor_Other_Angle[i]
				indice_other=(other-other_min)/delta_other
				if (cmpstr(mode,"temperature")==0)
					indice_other=i
				endif	

				// Look for the number of files with the same "other" parameters. 
				// They are usually one theta value at different slit values, which should be compiled together
				if (cmpstr(mode,"theta")==0)
					fin=0
					do
						Nb_slit+=1
						if (Nor_Other_Angle[i+Nb_slit]>other)
							fin=1
						endif
						if ((i+Nb_slit)>=numpnts(NormalizedImage))
							fin=1
						endif		
					while (fin==0) 
				endif
						
				// Fill theta rows of the image waves OriginalSlits[i] to OriginalSlits[i+Nb_Slits-1] 
				j=0
				slit_start=DimOffset(temp,1)
				slit_stop=slit_start+(DimSize(temp,1)-1)*DimDelta(temp,1)
				indice_slit_start=round((slit_start-slit_min)/delta_slit)
				indice_slit_stop=round((slit_stop-slit_min)/delta_slit)
				
				//Images might not have same energy scale
				tmp_3D[indice_slit_start,indice_slit_stop][][indice_other]=temp[(energy_min-Dimoffset(temp,0)+q*delta_energy)/Dimdelta(temp,0)][(slit_min-Dimoffset(temp,1)+p*delta_slit)/Dimdelta(temp,1)]
			
				// Only when there are different slits to compile
				if (j<(Nb_slit-1))
					do
						j+=1
						if (NorProcessFlag[i+j]==1)
							name=NormalizedImage[i+j]
							Duplicate/O $name temp
							
							// If Delta<0, reverse wave order
						if(DimDelta($NormalizedImage[i+j],1)<0)
							Duplicate/O $name temp2
							temp=temp2[p][DimSize($name,1)-1-q]
							first=DimOffset($NormalizedImage[i+j],1)+(DimSize($NormalizedImage[i+j],1)-1)*DimDelta($NormalizedImage[i+j],1)
							SetScale/P y, first, abs(DimDelta($NormalizedImage[i+j],1)), temp
							KillWaves temp2
						endif 
							
							
							if (DimOffset(temp,1)<slit_stop)
								slit_start=DimOffset(temp,1)
								indice_slit_start=round((slit_start-slit_min)/delta_slit)
								indice_slit_stop=round((slit_stop-slit_min)/delta_slit)
								//Zone of overlap between two Slits values : take the average
								//tmp_3D[indice_slit_start,indice_slit_stop][][indice_other]=(tmp_3D[p][q][indice_other]+temp[(energy_min-Dimoffset(temp,0)+q*delta_energy)/Dimdelta(temp,0)][(slit_min-Dimoffset(temp,1)+p*delta_slit)/Dimdelta(temp,1)])/2
								
								//Zone of overlap between two Slits values : take linear combination
								tmp_3D[indice_slit_start,indice_slit_stop][][indice_other]=(p-indice_slit_stop)/(indice_slit_start-indice_slit_stop)*tmp_3D[p][q][indice_other]+(indice_slit_start-p)/(indice_slit_start-indice_slit_stop)*temp[(energy_min-Dimoffset(temp,0)+q*delta_energy)/Dimdelta(temp,0)][(slit_min-Dimoffset(temp,1)+p*delta_slit)/Dimdelta(temp,1)]
								
								//print "other,name,slit_start,slit_stop=",other,name,slit_start,slit_stop
								slit_start=slit_stop
							else	
								slit_start=DimOffset(temp,1)
							endif
							slit_stop=DimOffset(temp,1)+(DimSize(temp,1)-1)*DimDelta(temp,1)
							indice_slit_start=round((slit_start-slit_min)/delta_slit)
							indice_slit_stop=round((slit_stop-slit_min)/delta_slit)
							tmp_3D[indice_slit_start,indice_slit_stop][][indice_other]=temp[(energy_min-Dimoffset(temp,0)+q*delta_energy)/Dimdelta(temp,0)][(slit_min-Dimoffset(temp,1)+p*delta_slit)/Dimdelta(temp,1)]
						endif
					while (j<(Nb_slit-1))
				endif //on j	
			endif //on ProcessFlag[i]=0
		i+=max(Nb_slit,1)
		while (i<numpnts(NormalizedImage))
							
		name=path[5,strlen(path)-1]+"_"
		DoWindow/F $name
		if (v_flag==1)
			DoWindow/K $name
		endif	
		//Duplicate/O tmp_3D tmp_raw_3D
		variable/G Flag_mode=0
		execute "Load3DImage(\""+path+"\")"
end

//////////////

Function Compile()
//WARNING : all waves must be in theta-Slits mode to be compiled correctly
	variable NbSlits,NbTheta,Indice_theta_min,Indice_theta_max,Indice_slit_min,Indice_Slits_max,Nbpnts_shift
	variable delta_p_indice,delta_r_indice,delta_p_ratio,delta_r_ratio,delta_q_indice,delta_q_ratio
	variable begin=5
	variable theta_min,theta_max,Slits_loc_min,Slits_max
	string name

	string FinalFolder="root:final"
	prompt FinalFolder,"Folder to save results (not process)"
	DoPrompt "Compile 3D Wave", FinalFolder
	
	if (v_flag==0)
		do
			String FolderToProcess="root:process",WaveToProcess
			prompt FolderToProcess,"Name of folder to process (Hit Cancel if no more wave to compile)"
			prompt theta_min,"Theta_min"
			prompt theta_max,"Theta_max"
			prompt Slits_loc_min,"slit_min"
			prompt Slits_max,"Slits_max"
	
			DoPrompt "Compile 3D Wave", FolderToProcess
			WaveToProcess=FolderToProcess+":tmp_3D"
			if (v_flag==0)
				//Extract data from one folder
				theta_min=DimOffset($WaveToProcess,2)
				theta_max=DimOffset($WaveToProcess,2)+(DimSize($WaveToProcess,2)-1)*DimDelta($WaveToProcess,2)
				Slits_loc_min=DimOffset($WaveToProcess,0)
				Slits_max=DimOffset($WaveToProcess,0)+(DimSize($WaveToProcess,0)-1)*DimDelta($WaveToProcess,0)
				DoPrompt "Compile 3D Wave",theta_min,theta_max,Slits_loc_min,Slits_max
			
				NewDataFolder/O $FinalFolder
				SetDataFolder FinalFolder
		
				name=FinalFolder+":temp"
				Wave temp=$name
				name=FinalFolder+":Compile_3D"
				Wave Compile_3D=$name
						
				
				
				if (v_flag==0)
					//print "Wave:", WaveToProcess
				   	if (begin==5) 
				   	//FIRST WAVE TO COMPILE
				   	//NOTE THAT Delta for Slits and theta will be the one of this wave AND photon and lattice are taken from there)
				   	
						//print "duplication de :", WaveToProcess,"dans"
						//name=FolderToProcess+":temp"
						//print name
						//Duplicate/O $WaveToProcess  $name
						//name=FolderToProcess+":Compile_3D"
						//print "et",name
						//Duplicate/O $WaveToProcess  $name
						SetDataFolder FinalFolder
						Duplicate/O $WaveToProcess  Compile_3D,temp
						//(does not necessarily begins at origin)
						SetScale/P x Slits_loc_min,DimDelta(Compile_3D, 0),"",  Compile_3D
						SetScale/P z theta_min,DimDelta(Compile_3D, 2),"", Compile_3D
						NbSlits=(Slits_max-DimOffset(Compile_3D,0))/DimDelta( Compile_3D,0)+1
	  					NbTheta=(theta_max-DimOffset(Compile_3D,2))/DimDelta(Compile_3D,2)+1
				  		Redimension/N=(NbSlits,-1,NbTheta) Compile_3D
						begin=0
				  	else
						//First : shift the previous data if necessary
						if (Slits_loc_min<DimOffset(Compile_3D, 0))
							SetDataFolder FinalFolder
							Duplicate/O Compile_3D temp
	  						Nbpnts_shift=round((-Slits_loc_min+DimOffset(Compile_3D, 0))/DimDelta(Compile_3D,0))
					  		//print "Nbpnts_shift for Slits",Nbpnts_shift
				  			SetScale/P x Slits_loc_min,DimDelta(Compile_3D, 0),"", Compile_3D
	  						Redimension/N=(DimSize(Compile_3D,0)+NbPnts_shift,-1,-1) Compile_3D
				  			Compile_3D[Nbpnts_shift,DimSize(Compile_3D,0)-1][][]=temp[p-Nbpnts_shift][q][r]
	  						Compile_3D[0,Nbpnts_shift-1][][]=0
				  		endif
	  					if (theta_min<DimOffset(Compile_3D, 2))
				  			SetDataFolder FinalFolder
	  						Duplicate/O Compile_3D temp
				  			Nbpnts_shift=round((-theta_min+DimOffset(Compile_3D, 2))/DimDelta(Compile_3D,2))
	  						print "Nbpnts_shift (theta), theta_min,DimOffset( Compile_3D, 2)", Nbpnts_shift,theta_min,DimOffset(Compile_3D, 2)
				  			SetScale/P z theta_min,DimDelta(Compile_3D, 2),"", Compile_3D
	  						Redimension/N=(-1,-1,DimSize(Compile_3D,2)+NbPnts_shift)  Compile_3D
				  			Compile_3D[][][Nbpnts_shift,DimSize(Compile_3D,2)-1]=temp[p][q][r-Nbpnts_shift]
				  			Compile_3D[][][0,Nbpnts_shift-1]=0
  						endif
			  			//Then duplicate in temp the new data to paste
  						Duplicate/O $WaveToProcess temp
				  	endif //1st wave or not
	  			SetDataFolder FinalFolder
	  			NbSlits=max((Slits_max-DimOffset(Compile_3D,0))/DimDelta(Compile_3D,0)+1,DimSize(Compile_3D,0))
	  			NbTheta=max((theta_max-DimOffset(Compile_3D,2))/DimDelta(Compile_3D,2)+1,DimSize(Compile_3D,2))
			  	print "Wave to process", WaveToProcess///
	  			print "slit_min=",Slits_loc_min,"Slits_max=",Slits_max//,DimDelta( Compile_3D,0)
			  	print "theta_min",theta_min,"theta_max",theta_max//,DimDelta( Compile_3D,2)
			  	//print "NbSlits,NbTheta",NbSlits,NbTheta///
	  			Redimension/N=(NbSlits,-1,NbTheta)  Compile_3D//Only useful to extend data
			  	Indice_slit_min=(Slits_loc_min - DimOffset(Compile_3D, 0))/DimDelta(Compile_3D, 0)
			  	Indice_Slits_max=(Slits_max - DimOffset(Compile_3D, 0))/DimDelta(Compile_3D, 0)
	  			Indice_theta_min=(theta_min - DimOffset(Compile_3D, 2))/DimDelta(Compile_3D, 2)
			  	Indice_theta_max=(theta_max - DimOffset(Compile_3D, 2))/DimDelta(Compile_3D, 2)
			   	//temp does not necessarily have the same delta and beginning than Compile_3D
	   			Delta_p_indice=(DimOffset(Compile_3D, 0)-DimOffset( temp, 0))/DimDelta(temp, 0)
			   	Delta_p_ratio=DimDelta(Compile_3D, 0)/DimDelta(temp, 0)
	   			Delta_q_indice=(DimOffset(Compile_3D, 1)-DimOffset( temp, 1))/DimDelta(temp, 1)
	   			Delta_q_ratio=DimDelta(Compile_3D, 1)/DimDelta(temp, 1)
	   		   	Delta_r_indice=(DimOffset(Compile_3D,2)-DimOffset( temp, 2))/DimDelta(Compile_3D,2)
			   	Delta_r_ratio=DimDelta(Compile_3D, 2)/DimDelta(temp, 2)
	   			//print "Indice_slit_min",Indice_slit_min,"Indice_Slits_max",Indice_Slits_max
			   	//print "Delta_p_indice",Delta_p_indice,"Delta_p_ratio",Delta_p_ratio
	   			//print "Indice_theta_min",Indice_theta_min,"Indice_theta_max",Indice_theta_max
			   	//print "Delta_r_indice",Delta_r_indice,"Delta_r_ratio",Delta_r_ratio
	   			//print "Delta_q_indice",Delta_q_indice,"Delta_q_ratio",Delta_q_ratio
			   	Compile_3D[Indice_slit_min,indice_Slits_max][][indice_theta_min,indice_theta_max]=temp[Delta_p_indice+p*Delta_p_ratio][Delta_q_indice+q*Delta_q_ratio][Delta_r_indice+r*Delta_r_ratio]
			endif //cancel for choice of limits 
			//v_flag=0//should ask another wave
		endif //cancel for choice of wave (i.e. last wave)
	while (v_flag==0)//Cancel not hit
	SetDataFolder FinalFolder
	variable/G Flag_mode=0
	name=FinalFolder+":tmp_3D"
	Duplicate/O Compile_3D $name
	variable/G slit_min=Dimoffset(compile_3D,0)
	execute "Load3DImage(\""+FinalFolder+"\")"
	endif //cancel on folder for final data
end


/////////////////////////////////////
function Merge_3Dwaves(wave1,wave2)
wave wave1,wave2  // full path
	// Merge only z axis
	// x and y must be the same
	// Must be in the directory of one of the function. Will add the other one to tmp_3D and reload
	variable Z_min1,Z_max1 
	variable Z_min2,Z_max2
	variable New_NbZ
	Z_min1=DimOffset(wave1,2)
	Z_max1=Z_min1+ DimDelta(wave1,2)*(DimSize(wave1,2)-1)
	Z_min2=DimOffset(wave2,2)
	Z_max2=Z_min2+ DimDelta(wave2,2)*(DimSize(wave2,2)-1)
	if (Z_min1<=Z_min2)
		Duplicate/O wave1 wave_temp
		New_NbZ=DimSize(wave1,2)+(Z_max2-Z_max1)/DimDelta(wave1,2)
		Redimension/N=(-1,-1,New_NbZ) wave_temp
		wave_temp[][][DimSize(wave1,2),New_NbZ-1]=wave2[p][q][r-DimSize(wave1,2)]
	endif
	if (Z_min1>Z_min2)
		Duplicate/O wave2 wave_temp
		New_NbZ=DimSize(wave2,2)+(Z_max1-Z_max2)/DimDelta(wave2,2)
		Redimension/N=(-1,-1,New_NbZ) wave_temp
		wave_temp[][][DimSize(wave2,2),New_NbZ-1]=wave1[p][q][r-DimSize(wave2,2)]
	endif
	// add result to tmp_3D of current directory
	Duplicate/O wave_temp tmp_3D
	Killwaves wave_temp 
	string WindowName
	WindowName=GetDataFolder(0)+"_"
	Killwindow $WindowName
	execute "Load3DImage(\""+GetDataFolder(0)+"\")"	
end