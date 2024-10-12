#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Function HDF5LoadDatasetBL7(datasetName, groupname, filename, desname,Xbin,Ybin,Zbin)
	//Example: hdf5loaddatasetBL7("Swept_Spectra0","2D_Data","20190405_00216.h5","Baals",1,1,1)

	// by Zijia Cheng
	// 20190407 Cochran - Modified for ALS beamline7 and scaling and binning

	String datasetName	// Name of dataset to be loaded
	String filename     // Name of the filename where the dataset is
	String groupname    // Name of the groupname where the dataset is
	String desname      // Name of the loaded wave
	Variable xbin
	Variable ybin
	Variable zbin
	
	Variable fileID	// HDF5 file ID will be stored here
  	Variable groupID //group ID will be stored here
   
	Variable result = 0	// 0 means no error
	
	NewPath HDF5path
	
	// Open the HDF5 file.
	HDF5OpenFile /P=HDF5path /R /Z fileID as filename
	if (V_flag != 0)
		Print "HDF5OpenFile failed"
		return -1
	endif
	
	//open the group
	HDF5OpenGroup  /z fileID, groupname, groupID
	if (V_flag != 0)
		Print "HDF5Oloadgroup failed"
		return -1
	endif
	
	
	// Load the HDF5 dataset.
	HDF5MakeHyperslabWave("root:slab", 3)
	wave slab
	slab[][0]=0
	slab[][1]=1
	slab[][2]=1
	slab[0][3]=10000
	slab[1][3]=10000
	slab[2][3]=1
	String tempname = "temp"
	string temp2name = "temp2"
	String desNamebin = desName + "_bin"
	string tempnamebin = tempname +"_bin"

	Variable i
	For(i=0;V_flag==0;i+=1)
		If(i==0)
			slab[2][0]=i
			HDF5LoadData /O /z /N=$desname /SLAB=slab groupID, datasetName
			if (V_flag != 0)
				Print "HDF5LoadData failed"
				result = -1
			endif
			Wave desWave = $desName
			DataBinXYZ(desWave,xbin,ybin,1)
			killwaves deswave
			rename $desnamebin $desname
		Else			
			slab[2][0]=i
			HDF5LoadData /O /z /q /N=$tempname /SLAB=slab groupID, datasetName
			if (V_flag != 0)
				Print "HDF5LoadData failed"
				result = -1
			endif
			if(V_flag==0)
				Wave temp=$tempname
				DataBinXYZ(temp,xbin,ybin,1)
				killwaves temp
				rename $tempnamebin $tempname
				concatenate /o /np=2 /kill {$desname,$tempname}, $temp2name
				rename $temp2name $desName
			EndIf
		EndIf
	EndFor

	//Load Attribute and Scale xy
	String OffsetWaveName = "OffsetWave"
	HDF5LoadData /O /Z /q /A="scaleOffset" /TYPE=2 /N=$OffsetWaveName groupID, dataSetName
	String DeltaWaveName = "DeltaWave"
	HDF5LoadData /O /Z /q /A="scaleDelta" /TYPE=2 /N=$DeltaWaveName groupID, dataSetName
	wave OffsetWave=$offsetWaveName
	wave DeltaWave =$DeltaWaveName
	setscale /p y, 17.64+(-0.0902303/2)*(YBin-1),(-0.0902303/2)*YBin,$desname
	setscale /p x, offsetwave[1]+deltawave[1]*(XBin-1),deltawave[1]*XBin,$desname
	Redimension /s $desname
	
	//Scalez
	
	HDF5CloseGroup groupID
	String ZeroDDataName = "0D_Data"
	HDF5OpenGroup /Z fileID, ZeroDDataName, groupID
	if (V_flag != 0)
		Print "HDF5Oloadgroup failed"
		return -1
	endif
	String Dim2ScaleName = "Dim2Scale"
	String Dim2Motor = "Beta"
	HDF5LoadData /O /Z /q  /N=$Dim2ScaleName groupID, Dim2Motor
	If(V_flag==0)
		wave Dim2ScaleWave = $dim2ScaleName
		setscale /p z, dim2scalewave[0],dim2scalewave[1]-dim2scalewave[0],$desname
	Else
		Dim2Motor = "X"
		HDF5LoadData /O /Z /q  /N=$Dim2ScaleName groupID, Dim2Motor
		If(V_flag==0)
			wave Dim2ScaleWave = $dim2ScaleName
			setscale /p z, dim2scalewave[0],dim2scalewave[1]-dim2scalewave[0],$desname
		Else
			Print "Unable to Determine Scaling for Dimension 2"
		EndIf
	EndIf

	//Print Comments in commandline
	HDF5CloseGroup groupID
	String commentname="Comments"
	HDF5OpenGroup /Z fileID, commentname, groupID
	if (V_flag != 0)
		Print "HDF5Oloadgroup failed"
		return -1
	endif
	String PreCommentsName="PreScan"
	HDF5LoadData /O /Z /q /COMP={1,"comment"} /N=$PreCommentsName groupID, PreCommentsName
	if (V_flag != 0)
		Print "HDF5LoadData failed"
		result = -1
	endif
	String PostCommentsName="PostScan"
	HDF5LoadData /O /Z /q /COMP={1,"comment"} /N=$PostCommentsName groupID, PostCommentsName
	if (V_flag != 0)
		Print "HDF5LoadData failed"
		result = -1
	endif
	wave PreScan
	Wave PostScan
	Print PreScan
	Print PostScan
	
	//BinFile
	If(zbin>1)
		DataBinXYZ(desWave,1,1,zbin)
		killwaves $desName
	EndIf
	
	// Close the HDF5 file.
	HDF5CloseFile fileID

	return result
End