#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//#include "Macintosh HD:Users:tylerac:Documents:data:IGOR stuff_tc20200904:HDF5LoadingProc"
#include "Macintosh HD:Users:tylerac:Documents:data:IGOR stuff_tc20200904:BinningProcs"

//Example: HDF5DataLoadSSRL("Macintosh HD:Users:tylerac:Documents:data:20210526_SSRL_5-2_CMG111:",0,0,"CMA1",1,1,1,0)
//Output dimensions are dim0=ScanningAngle dim1=AnalyzerAngle dim2=BindingEnergy
Function HDF5DataLoadSSRL(PathName,Start,Stop,SampleName,BinNumX,BinNumY,BinNumZ, photdep)
	
	Variable start
	Variable stop
	Variable BinNumX
	Variable BinNumY
	Variable BinNumZ
	Variable photdep // 1 if the map is a photon dependence, 0 if otherwise
	
	String SampleName
	String PathName
	
	NewPath /O ThePath PathName
	
	Variable k
	
	String CountDataName
	String TimeDataName
	String NormDataName
	
	Wave FS
		
	For(k=start;k<stop+1;k+=1)
		
		String fileName
		If(k<10)
			fileName = "CMG7_000" + num2str(k) +".h5"	// Name of HDF5 file
		Else
			If(k<100)
				fileName = "CMG7_00" + num2str(k) +".h5"	// Name of HDF5 file
			Else
				If(k<1000)
					fileName = "CMG7_0" + num2str(k) +".h5"	// Name of HDF5 file
				Else
					If(k<10000)
						fileName = "CMG7_0" + num2str(k) +".h5"	// Name of HDF5 file
					Else
						print "fuck it"
						fileName = "TMFS1_" + num2str(k) +".h5"	// Name of HDF5 file
					EndIf
				EndIf
			EndIf
		EndIf
		
		String CountName = "/Data/Count"	// Name of dataset Count to be loaded
		String TimeName = "/Data/Time" // Name of dataset Time to be loaded
		String Axes0_GroupName = "/Data/Axes0"
		String Axes1_GroupName = "/Data/Axes1"
		String Axes2_GroupName = "/Data/Axes2"
		
		String AlphaScalingName = "/entry1/analyser/angles"
		String ThetaScalingName = "/entry1/analyser/sapolar"
		String EnergyScalingName = "/entry1/analyser/energies"
		String hvScalingName = "/entry1/analyser/energy"
		String TestName = "/Data/Axes0"
		
		Variable fileID	// HDF5 file ID will be stored here	
		
		Variable result = 0	// 0 means no error
				
		// Open the HDF5 file.
		HDF5OpenFile /P=ThePath /R /Z fileID as fileName
		if (V_flag != 0)
			Print "HDF5OpenFile failed"
			return -1
		endif
								
		// Load the HDF5 datasets.
		HDF5LoadData /O /Z fileID, CountName
		if (V_flag != 0)
			Print "HDF5LoadData failed on CountName"
			result = -1
		endif
		
		HDF5LoadData /O /Z fileID, TimeName
		if (V_flag != 0)
			Print "HDF5LoadData failed on TimeName"
			result = -1
		endif
		
		wave Count
		Wave Time0
		
		CountDataName=SampleName+"_Count_"+num2str(k)
		TimeDataName=SampleName+"_Time_"+num2str(k)
		NormDataName=SampleName+"_Norm_"+num2str(k)
		
		print "k="+num2str(k)
		
		killwaves /Z $CountDataName
		killwaves /Z $TimeDataName
		rename Count $CountDataName
		rename Time0 $TimeDataName
		
		duplicate /o Count $NormDataName
		Wave NormData = $NormDataName
		
		NormData[][][]=Count[p][q][r]/Time0[p][q][r]
		
		//Load Scaling Waves
		wave Offset
		wave Delta
		killwaves /z offset,delta
		HDF5LoadData /A="Offset" /TYPE=1 fileID, "/Data/Axes0"
		if (V_flag != 0)
			Print "HDF5LoadData failed On Axes0 Offset"
			result = -1
		endif
		
		HDF5LoadData /A="Delta" /TYPE=1 fileID, "/Data/Axes0"
		if (V_flag != 0)
			Print "HDF5LoadData failed On Axes0 Delta"
			result = -1
		endif
		
		wave Offset
		wave Delta
		variable Offset_Axes0 = Offset[0]
		variable Delta_Axes0= Delta[0]
		
		killwaves /z offset,delta
		HDF5LoadData /A="Offset" /TYPE=1 fileID, "/Data/Axes1"
		if (V_flag != 0)
			Print "HDF5LoadData failed On Axes1 Offset"
			result = -1
		endif
		
		HDF5LoadData /A="Delta" /TYPE=1 fileID, "/Data/Axes1"
		if (V_flag != 0)
			Print "HDF5LoadData failed On Axes1 Delta"
			result = -1
		endif
		
		wave Offset
		wave Delta
		variable Offset_Axes1 = Offset[0]
		variable Delta_Axes1= Delta[0]
		
		If(dimsize(Count,2)>0)
			
			killwaves /z offset,delta
			HDF5LoadData /A="Offset" /TYPE=1 fileID, "/Data/Axes2"
			if (V_flag != 0)
				Print "HDF5LoadData failed On Axes2 Offset"
				result = -1
			endif
			
			HDF5LoadData /A="Delta" /TYPE=1 fileID, "/Data/Axes2"
			if (V_flag != 0)
				Print "HDF5LoadData failed On Axes2 Delta"
				result = -1
			endif
			
			wave Offset
			wave Delta
			variable Offset_Axes2 = Offset[0]
			variable Delta_Axes2= Delta[0]
			
			setscale /p z, offset_axes2,delta_axes2,Count
			setscale /p z, offset_axes2,delta_axes2,Time0
			setscale /p z, offset_axes2,delta_axes2,NormData
			
		Else
			Print "2D Wave"
		Endif
		
		// Close the HDF5 file.
		HDF5CloseFile fileID
						
//		setscale /p x, offset_axes2,delta_axes2,Count
//		setscale /p x, offset_axes2,delta_axes2,Time0
//		setscale /p x, offset_axes2,delta_axes2,NormData
		
		setscale /p y, offset_axes1,delta_axes1,Count
		setscale /p y, offset_axes1,delta_axes1,Time0
		setscale /p y, offset_axes1,delta_axes1,NormData
		
		if(dimsize(count,0)>0)
		
//		setscale /p z, offset_axes0,delta_axes0,Count
//		setscale /p z, offset_axes0,delta_axes0,Time0
//		setscale /p z, offset_axes0,delta_axes0,NormData

		setscale /p x, offset_axes0,delta_axes0,Count
		setscale /p x, offset_axes0,delta_axes0,Time0
		setscale /p x, offset_axes0,delta_axes0,NormData
		
		endif
		
		If(BinNumX==1 && BinNumY==1 && BinNumZ==1)
			Print "No Binning Selected"
			newimagetool5(NormDataName)
		Else
			//DataCondense(BinNumX,BinNumy,BinNumZ, CountDataName)
			DataBinXYZ(Count,BinNumX,BinNumY,BinNumZ)
			String OutputWaveName = NameofWave(Count)+"_bin"
			Wave CountB = $OutputWaveName
			//DataCondense(BinNumX,BinNumy,BinNumZ,TimeDataName)
			DataBinXYZ(Time0,BinNumX,BinNumY,BinNumZ)
			OutputWaveName = NameofWave(Time0)+"_bin"
			Wave Time0B = $OutputWaveName
			//DataCondense(BinNumX,BinNumy,BinNumZ,NormDataName)
			DataBinXYZ(NormData,BinNumX,BinNumY,BinNumZ)
			OutputWaveName = NameofWave(NormData)+"_bin"
			Wave NormDataB = $OutputWaveName
			
			Print "Data Binned"
			
			newimagetool5(OutputWaveName)
			
			KillWaves count, time0,normdata
		EndIf
		
		killwaves /z Count, Time0
		
	EndFor
	//newimagetool5(NormDataName)
	Print "Loading Procedure Finished"
End
