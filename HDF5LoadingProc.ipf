#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//Example : HDF5DataLoad("Macintosh HD:Users:cochra96:Documents:Data:20190911_Diamond_TMSetc:",107992,107992,"TMS1","TMS1_FS17",1,5,5,0)

Function HDF5DataLoad(PathName,Start,Stop,SampleName,FinalName,BinNumX,BinNumY,BinNumZ, photdep)
	
	Variable start
	Variable stop
	Variable BinNumX
	Variable BinNumY
	Variable BinNumZ
	Variable photdep // 1 if the map is a photon dependence, 0 if otherwise
	
	String SampleName
	String PathName
	String FinalName
	
	NewPath /O ThePath PathName
	
	Variable k
	
	String NewDataSetName
	
	Wave FS
		
	For(k=start;k<stop+1;k+=1)
	
		String fileName = "i05-" + num2str(k) +".nxs"	// Name of HDF5 fil	e
		String datasetName = "/entry1/analyser/data"	// Name of dataset to be loaded
		String AlphaScalingName = "/entry1/analyser/angles"
		String ThetaScalingName = "/entry1/analyser/sapolar"
		String EnergyScalingName = "/entry1/analyser/energies"
		String hvScalingName = "/entry1/analyser/energy"
		
		Variable fileID	// HDF5 file ID will be stored here	
		
		Variable result = 0	// 0 means no error
		
		// Open the HDF5 file.
		HDF5OpenFile /P=ThePath /R /Z fileID as fileName
		if (V_flag != 0)
			Print "HDF5OpenFile failed"
			return -1
		endif
		
		// Load the HDF5 dataset.
		HDF5LoadData /O /Z fileID, datasetName
		if (V_flag != 0)
			Print "HDF5LoadData failed"
			result = -1
		endif
		
		wave data
		
		//Load Scaling Waves
		HDF5LoadData /O /Z fileID, AlphaScalingName
		if (V_flag != 0)
			Print "HDF5LoadData failed"
			result = -1
		endif
		
		HDF5LoadData /O /Z fileID, ThetaScalingName
		if (V_flag != 0)
			Print "HDF5LoadData failed"
			result = -1
		endif
		
		HDF5LoadData /O /Z fileID, EnergyScalingName
		if (V_flag != 0)
			Print "HDF5LoadData failed"
			result = -1
		endif
		
		HDF5LoadData /O /Z fileID, hvScalingName
		if (V_flag != 0)
			Print "HDF5LoadData failed"
			result = -1
		endif
		
		// Close the HDF5 file.
		HDF5CloseFile fileID
		
		NewDataSetName = SampleName + "_" + num2str(k)
		wave energies
		wave angles
		wave sapolar
		wave energy
		
		If (photdep == 1)
			setscale /I x, energy[0], energy[dimsize(energy,0)-1], "hv eV", data
			setscale /I y,  angles[0], angles[dimsize(angles,0)-1], "A deg", data
			setscale /I z, energies[0], energies[dimsize(energies,0)-1], "eV", data
			killwaves /Z $NewDataSetName
			rename data, $NewDataSetName
			Print "3D Photon Energy Dependence Wave Loaded:" + NewDataSetName
		Else
			If(dimsize(data,0)>1)
				setscale /I x, sapolar[0], sapolar[dimsize(sapolar,0)-1], "T deg", data
				setscale /I y,  angles[0], angles[dimsize(angles,0)-1], "A deg", data
				setscale /I z, energies[0], energies[dimsize(energies,0)-1], "eV", data
				killwaves /Z $NewDataSetName
				rename data, $NewDataSetName
				Print "3D Fermi Surface Map Wave Loaded:" + NewDataSetName
			Else
				Make /O /N=(dimsize(data,1), dimsize(data,2)) $NewDataSetName
				wave OutputDataSet = $NewDataSetName
				OutputDataSet[][] = data[0][p][q]
				setscale /I x, angles[0], angles[dimsize(angles,0)-1], "A deg", OutputDataSet
				setscale /I y, energies[0], energies[dimsize(energies,0)-1], "eV", OutputDataSet
				Print "2D Wave Loaded:" + NewDataSetName
			EndIf
		EndIf
		
		DataCondense(BinNumX,BinNumy,BinNumZ, NewDataSetName)
		
		Print "Data Binned"
		
		KillWaves $NewDataSetName
		
		String OutputWaveName = "b_"+NewDataSetName
		Wave OutputWave = $OutputWaveName
		
		If (k==start)
			Make /O /n = (0,dimsize(OutputWave,1),dimsize(OutputWave,2)) $FinalName
			Wave Final = $FinalName
		Else
		EndIf
		
		InsertPoints  dimsize(final,0), dimsize(OutputWave,0), Final
		
		Final[dimsize(final,0)-dimsize(OutputWave,0),dimsize(final,0)-1][][] = OutputWave[p-(dimsize(final,0)-dimsize(OutputWave,0))][q][r]
		
		If(k==start)
			setscale /p x, dimoffset(Outputwave,0), dimdelta(Outputwave,0),"",final
			setscale /p y, dimoffset(outputwave,1), dimdelta(outputwave,1),"",final
			setscale /p z, dimoffset(outputwave,2),dimdelta(outputwave,2),"",final
		Else
		EndIf
		
		Killwaves Outputwave
		
		Print"Data Copied to " + FinalName
		
	EndFor
	newimagetool5(finalname)
	Print "Loading Procedure Finished"
End

Function DataCondense(BinNumX,BinNumY,BinNumZ, InputWaveName)

	Variable BinNumX
	Variable BinNumY
	Variable BinNumZ
	
	
	String InputWaveName
	String OutputWaveName = "b_" + InputWaveName
	String IntermedWaveName = "Placeholder"
	String FirstWaveName = "Placeholder1"
	
	Variable i, j,k,l
	Variable a
	
	Wave InputWave = $InputWaveName
	
	If(BinNumX>1)	
		Make /o /n = (trunc(dimsize(InputWave,0)/BinNumX),dimsize(InputWave,1),dimsize(InputWave,2)), $FirstWaveName
		
		Wave FirstWave = $FirstWaveName
		
		For(l=0;l<dimsize(InputWave,1);l+=1)
			For(k=0;k<dimsize(InputWave,2);k+=1)
				For(i=0;i<trunc(dimsize(InputWave,0)/BinNumX);i+=1)
					a=0
					For (j=0;j<BinNumX;j+=1)
						a += Inputwave[i*BinNumX+j][l][k]
					EndFor
					FirstWave[i][l][k] = a
				EndFor
			EndFor
		EndFor
	Else
		duplicate /o $InputWaveName $FirstWaveName
		wave FirstWave = $FirstWaveName
	EndIf
	
	If(BinNumZ>1)
		Make /o /n = (dimsize(FirstWave,0),dimsize(FirstWave,1),trunc(dimsize(FirstWave,2)/BinNumZ)), $IntermedWaveName
		
		Wave Intermedwave = $IntermedWaveName
		
		For(l=0;l<dimsize(FirstWave,1);l+=1)
			For(k=0;k<dimsize(FirstWave,0);k+=1)
				For(i=0;i<trunc(dimsize(FirstWave,2)/BinNumZ);i+=1)
					a=0
					For (j=0;j<BinNumZ;j+=1)
						a += FirstWave[k][l][i*BinNumZ+j]
					EndFor
					Intermedwave[k][l][i] = a
				EndFor
			EndFor
		EndFor
	Else
		duplicate /o $FirstWaveName $IntermedWaveName
		wave IntermedWave = $intermedWaveName
	EndIf
	
	If(BinNumY>1)
		Make /o /n = (dimsize(IntermedWave,0),trunc(dimsize(IntermedWave,1)/BinNumY),dimsize(IntermedWave,2)), $OutputWaveName
		
		Wave Outputwave = $OutputWaveName
		
		For(l=0;l<dimsize(IntermedWave,2);l+=1)
			For(k=0;k<dimsize(IntermedWave,0);k+=1)
				For(i=0;i<trunc(dimsize(IntermedWave,1)/BinNumY);i+=1)
					a=0
					For (j=0;j<BinNumY;j+=1)
						a += Intermedwave[k][i*BinNumY+j][l]
					EndFor
					Outputwave[k][i][l] = a
				EndFor
			EndFor
		EndFor
	Else	
		duplicate /o $IntermedWaveName $OutputWaveName
		Wave OutputWave = $OutputWaveName
	EndIf
	
	Killwaves FirstWave, IntermedWave
	
	//If(Dimsize(Inputwave,0)>1)
		setscale /p x, DimOffset(InputWave,0)+DimDelta(InputWave,0)*BinNumX/2, DimDelta(InputWave, 0)*BinNumX,"", OutputWave
		setscale /p y, DimOffset(InputWave,1)+DimDelta(InputWave,1)*BinNumY/2, DimDelta(Inputwave, 1)*BinNumY,"", OutputWave
		SetScale /p z, DimOffset(InputWave,2)+DimDelta(InputWave,2)*BinNumZ/2,DimDelta(InputWave,2)*BinNumZ,"", OutputWave
	//Else
		//setscale /p x, DimOffset(InputWave,0)+DimDelta(InputWave,0)*BinNumX/2, DimDelta(InputWave, 0)*BinNumX,"", OutputWave
		//setscale /p y, DimOffset(InputWave,1)+DimDelta(InputWave,1)*BinNumY/2, DimDelta(Inputwave, 1)*BinNumY,"", OutputWave
	//EndIf

End

