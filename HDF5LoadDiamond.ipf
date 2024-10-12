#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "Macintosh HD:Users:tylerac:Documents:data:IGOR stuff_tc20200904:HDF5LoadingProc"

//Example: HDF5DataLoadDiamond("Macintosh HD:Users:tylerac:Documents:data:20190911_Diamond_TMS:Data:",107874,107874,"TMS",1,1,1,0)
//Output dimensions are dim0=ScanningAngle dim1=AnalyzerAngle dim2=BindingEnergy

//20210911 text save: HDF5DataLoadDiamond("Macintosh HD:Users:tylerac:Documents:data:20210911_Diamond:",130418,1301418,"LMS",1,1,1)
Function HDF5DataLoadDiamond(PathName,Start,Stop,SampleName,BinNumX,BinNumY,BinNumZ)
	
	Variable start
	Variable stop
	Variable BinNumX
	Variable BinNumY
	Variable BinNumZ
	
	String SampleName
	String PathName
	
	NewPath /O ThePath PathName
	
	Variable photdep // 1 if the map is a photon dependence, 0 if otherwise

	
	Variable k
	
	String CountDataName
	String TimeDataName
	String NormDataName
	
	Wave FS
			
	For(k=start;k<stop+1;k+=1)
		
		String fileName
		String kstring=num2str(trunc(k/1e5))+num2str(trunc(mod(k,1e5)/1e4))+num2str(trunc(mod(k,1e4)/1e3))+num2str(trunc(mod(k,1e3)/1e2))+num2str(trunc(mod(k,1e2)/1e1))+num2str(trunc(mod(k,1e1)))

		print "Starting Load on k = "+kstring
		
		fileName = "i05-"+kstring+".nxs"
		
		//string PathFileName=PathName+fileName
		//NewPath /O ThePath PathFileName
		
		String CountName = "/entry1/analyser/data"	// Name of dataset Count to be loaded
		String angles_path = "/entry1/analyser/angles"
		String binding_energies_path = "/entry1/analyser/energies"
		String sapolar_path = "/entry1/analyser/sapolar"
		String salong_path = "/entry1/analyser/salong"
		String energy_path = "/entry1/analyser/energy"
		
		Variable fileID	// HDF5 file ID will be stored here	
		
		Variable result = 0	// 0 means no error
				
		// Open the HDF5 file.
		HDF5OpenFile /P=ThePath /R /Z fileID as fileName
		if (V_flag != 0)
			Print "HDF5OpenFile failed"
			result = -1
		endif
								
		// Load the HDF5 datasets.
		HDF5LoadData /O /Z fileID, CountName
		if (V_flag != 0)
			Print "HDF5LoadData failed on CountName"
			result = -1
		endif

		String DataWaveName="data"
		wave DataWave=$DataWaveName
		
		NormDataName=SampleName+kstring
				
		rename DataWave $NormDataName

		//Load Scaling Waves
		
		HDF5LoadData /O /Z fileID, salong_path
		if (V_flag != 0)
			Print "HDF5LoadData failed on salong. Proceeding to scaling and binning."
			result = -1
			
			HDF5LoadData /O /Z fileID, angles_path
			if (V_flag != 0)
				Print "HDF5LoadData failed on angles"
				killwaves datawave
				result = -1
			Else
				HDF5LoadData /O /Z fileID, binding_energies_path
				if (V_flag != 0)
					Print "HDF5LoadData failed on binding_energies"
					result = -1
				endif
				
				HDF5LoadData /O /Z fileID, sapolar_path
				if (V_flag != 0)
					Print "HDF5LoadData failed on sapolar"
					result = -1
				endif
				
				HDF5LoadData /O /Z fileID, energy_path
				if (V_flag != 0)
					Print "HDF5LoadData failed on energy"
					result = -1
					photdep=0
				else
					photdep=1
					Print "existence of 'energy' dataset indicates this is a photo energy dependence measurement"
				endif
				
				wave angles
				wave energies
				wave sapolar
				wave energy
				
				setscale /i y, angles[0],angles[inf], Datawave
				setscale /i z, energies[0][0],energies[0][inf],datawave
				
				if(dimsize(datawave,0)>1)
					if(photdep==0)
						setscale /i x, sapolar[0],sapolar[inf],datawave
					else
						setscale /i x, energy[0], energy[inf],datawave
					endif
				endif
		
				killwaves /z angles, binding_energies, sapolar
				// Close the HDF5 file.
				HDF5CloseFile fileID
				
				// Bin Data
				String OutputCutName
				If(BinNumX==1 && BinNumY==1 && BinNumZ==1)
					If(dimsize(DataWave,0)>1)
						newimagetool5(NormDataName)
						Setaxis/A/R imghL
						Setaxis/A/R imgvB
					Else
						OutputCutName="c_"+NormDataName
						Make /O /N=(dimsize(DataWave,1),dimsize(datawave,2)) $OutputCutName
						Wave OutputCut=$OutputCutName
						OutputCut[][]=DataWave[1][p][q]
						setscale /p x, dimoffset(datawave,1),dimdelta(datawave,1),outputcut
						setscale /p y, dimoffset(datawave,2),dimdelta(datawave,2),outputcut
						Killwaves DataWave
						newimagetool5(outputcutname)
					EndIf
					Print "No Binning Selected"
				Else
					DataCondense(BinNumX,BinNumy,BinNumZ,NormDataName)
					String OutputWaveName = "b_"+NameofWave(DataWave)
					Wave DataWaveB = $OutputWaveName
					
					Print "Data Binned"
					
					KillWaves DataWave
					
					If(dimsize(datawaveB,0)>1)
						newimagetool5(OutputWaveName)
						//Setaxis/A/R imghL
						//Setaxis/A/R imgvB
					Else
						OutputCutName="c"+OutputWaveName
						Make /O /N=(dimsize(DataWaveB,1),dimsize(datawaveB,2)) $OutputCutName
						Wave OutputCut=$OutputCutName
						OutputCut[][]=DataWaveB[0][p][q] 
						print dimoffset(datawaveb,1),dimdelta(datawaveb,1),dimoffset(datawaveb,1),dimdelta(datawaveb,1)
						setscale /p x, dimoffset(datawaveb,1),dimdelta(datawaveb,1),Outputcut
						setscale /p y, dimoffset(datawaveb,2),dimdelta(datawaveb,2),outputcut
						Killwaves DataWaveB
						newimagetool5(outputcutname)
					EndIf
				EndIf
			endif
		Else
			Print "HDF5LoadData successfully loaded salong"
			Print "Killing data wave."
			wave salong
			Killwaves datawave, salong
		endif
		
	print "Ending Load on k = "+kstring

		
	EndFor
	
	Print "Loading Procedure Finished"
End
