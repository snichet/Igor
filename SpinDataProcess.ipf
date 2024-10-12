#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "Macintosh HD:Users:tylerac:Documents:data:IGOR stuff_tc20200904:BinningProcs"

function QuickUpdate_SpinDataProcess(DetectorName,DirectionName,BaseName,Bin,MultOffset,Plot) //this was created based on BL10 naming scheme in Nov 2021
	
	String DetectorName// = "Black_Z"
	String DirectionName
	String Basename// = "SR11B"
	Variable Bin// = 8
	Variable MultOffset
	Variable Plot
	
	String PlusName1=DetectorName+"_spin_"+DetectorName+"_"+DirectionName+"plus"
	String PlusName2= Basename + "_plus"+DirectionName
	String MinusName1=DetectorName+"_spin_"+DetectorName+"_"+DirectionName+"minus"
	String MinusName2	=Basename + "_minus"+DirectionName
	
	rename $PlusName1 $PlusName2
	rename $MinusName1 $MinusName2
	
	Wave PlusWave = $PlusName2
	Wave MinusWave = $MinusName2
	
	DataBinX(PlusWave,Bin)
	dataBinX(MinusWave,Bin)
	
	String PlusNameBin = PlusName2+"_bin0"
	String MinusNameBin = MinusName2+"_bin0"
	
	Wave PlusWaveBin = $PlusNameBin
	Wave MinusWaveBin = $MinusNameBin
	
	String NewBaseName=BaseName+DirectionName
	
	SpinDataProcess(PlusWaveBin,MinusWaveBin,0.27,0,0,MultOffset,NewBasename,Plot)
	
	Print "Commands Carried Out:"
	Print "rename "+PlusName1+" "+PlusName2
	Print "rename "+MinusName1+" "+MinusName2
	Print "DataBinX("+PlusName2+","+num2str(Bin)+")"
	Print "DataBinX("+MinusName2+","+num2str(Bin)+")"
	Print "SpinDataProcess("+PlusNameBin+","+MinusNameBin+",0.27,0,0,"+num2str(MultOffset)+",\""+NewBaseName+"\",1)"
	
//	rename New_Region1_Black_Zplus SR11B_plus
//	rename New_Region1_Black_Zminus SR11B_minus
//	DataBinX(SR11B_minus,8);DataBinX(SR11B_plus,8)
//	SpinDataProcess(SR11B_minus_bin0,SR11B_plus_bin0,0.27,0,0,1,"SR11B",1)
end

function QuickUpdateBessy_SpinDataProcess(DetectorNumber1,DetectorNumber2,SequenceName,BaseName,Bin,MultOffset,Plot) //this was created based on BL10 naming scheme in Nov 2021
	
	variable DetectorNumber1
	variable DetectorNumber2
	string SequenceName
	
//	String DetectorName// = "Black_Z"
//	String DirectionName
	String Basename// = "SR11B"
	Variable Bin// = 8
	Variable MultOffset
	Variable Plot
	
	String PlusName1=SequenceName+"_Dev3_ctr"+num2str(DetectorNumber1)+"_in"
	String PlusName2= Basename+"_Ch"+num2str(DetectorNumber1)
	String MinusName1=SequenceName+"_Dev3_ctr"+num2str(DetectorNumber2)+"_in"
	String MinusName2	=Basename+"_Ch"+num2str(DetectorNumber2)
	
	rename $PlusName1 $PlusName2
	rename $MinusName1 $MinusName2
	
	Wave PlusWave = $PlusName2
	Wave MinusWave = $MinusName2
	
	DataBinX(PlusWave,Bin)
	dataBinX(MinusWave,Bin)
	
	String PlusNameBin = PlusName2+"_bin0"
	String MinusNameBin = MinusName2+"_bin0"
	
	Wave PlusWaveBin = $PlusNameBin
	Wave MinusWaveBin = $MinusNameBin
	
	String NewBaseName=BaseName+"_Ch"+num2str(detectornumber1)+num2str(detectornumber2)
	
	SpinDataProcess(PlusWaveBin,MinusWaveBin,0.27,0,0,MultOffset,NewBasename,Plot)
	
	Print "Commands Carried Out:"
	Print "rename "+PlusName1+" "+PlusName2
	Print "rename "+MinusName1+" "+MinusName2
	Print "DataBinX("+PlusName2+","+num2str(Bin)+")"
	Print "DataBinX("+MinusName2+","+num2str(Bin)+")"
	Print "SpinDataProcess("+PlusNameBin+","+MinusNameBin+",0.27,0,0,"+num2str(MultOffset)+",\""+NewBaseName+"\",1)"
	
//	rename New_Region1_Black_Zplus SR11B_plus
//	rename New_Region1_Black_Zminus SR11B_minus
//	DataBinX(SR11B_minus,8);DataBinX(SR11B_plus,8)
//	SpinDataProcess(SR11B_minus_bin0,SR11B_plus_bin0,0.27,0,0,1,"SR11B",1)
end

//Example: SpinDataProcess(SR1B_minus,SR1B_plus,0.27,0,0,1,"SR1B",1)

function SpinDataProcess(InputIntensityLeft,InputIntensityRight,ShermanFunction,RightPreMultAddOffset,RightAddOffset,RightMultOffset,BaseName,Plot)
	wave InputIntensityLeft
	wave InputIntensityRight
	variable ShermanFunction
	variable RightPreMultAddOffset
	variable RightAddOffset
	variable RightMultOffset
	String BaseName
	variable Plot //0 if not wanting to plot the outputs.
	
	String OutputPolarizationName = BaseName +"_P"
	String OutputIntensityLeftName = BaseName +"_IL"
	String OutputIntensityRightName = BaseName +"_IR"
	string InputIntensityRightOffsetName=nameofwave(InputIntensityRight)+"_offset"
	string inputintensityleftname=nameofwave(inputintensityleft)		
	
	Duplicate /o InputIntensityLeft $InputIntensityRightOffsetName
	Duplicate /o InputIntensityLeft $OutputPolarizationName
	Duplicate /o InputIntensityLeft $OutputIntensityLeftName
	Duplicate /o InputIntensityLeft $OutputIntensityRightName
	
	Wave InputIntensityRightOffset=$InputIntensityRightOffsetName
	Wave OutputPolarization=$OutputPolarizationName
	Wave OutputIntensityLeft=$OutputIntensityLeftName
	Wave OutputIntensityRight=$OutputIntensityRightName
	
	InputIntensityRightOffset[]=(InputIntensityRight[p]+RightPreMultAddOffset)*RightMultOffset+RightAddOffset
	
	OutputPolarization[] = 1/ShermanFunction*(InputIntensityLeft[p]-InputIntensityRightOffset[p])/(InputIntensityLeft[p]+InputIntensityRightOffset[p])
	OutputIntensityLeft[]=(1+OutputPolarization[p])*(InputIntensityLeft[p]+InputIntensityRightOffset[p])/2
	OutputIntensityRight[]=(1-OutputPolarization[p])*(InputIntensityLeft[p]+InputIntensityRightOffset[p])/2
	
	If(Plot==0)
		Print "Results Not Plotted"
	Else
		display inputintensityleft, inputintensityrightoffset
		ModifyGraph rgb($InputIntensityLeftName)=(0,0,65535)
		display OutputPolarization
		SetAxis left -.1,.1
		ModifyGraph rgb=(0,0,0)
		ModifyGraph grid(left)=1
		display OutputIntensityLeft, OutputIntensityRight
		ModifyGraph rgb($OutputIntensityLeftName)=(0,0,65535)
	EndIf
	
	Note InputIntensityRightOffset num2str(datetime)
	Note InputIntensityRightOffset "SpinDataProcess() function created this wave with the following input parameters:"
	Note InputIntensityRightOffset "InputIntensityLeft: "+nameofwave(inputintensityleft)
	Note InputIntensityRightOffset "InputIntensityRight: "+nameofwave(inputintensityright)
	Note InputIntensityRightOffset "ShermanFunction: "+num2str(shermanfunction)
	Note InputIntensityRightOffset "RightPreMultAddOffset: "+num2str(rightpremultaddoffset)
	Note InputIntensityRightOffset "RightAddOffset: "+num2str(rightaddoffset)
	Note InputIntensityRightOffset "RightMultOffset: "+num2str(rightmultoffset)
	Note InputIntensityRightOffset "BaseName: "+basename
end

Function SumWaves(Prefix,Detector)
	String Prefix
	String Detector
	
	If(CmpStr(Detector,"Black")==0)
		Concatenate /O Wavelist(Prefix+"*_plusZ",";",""), TempMatrix
		MatrixOp Black_spin_Black_Zplus = sumrows(TempMatrix)
		
		Concatenate /O Wavelist(Prefix+"*_minusZ",";",""), TempMatrix
		MatrixOp Black_spin_Black_Zminus = sumrows(TempMatrix)
		
		Concatenate /O Wavelist(Prefix+"*_plusX",";",""), TempMatrix
		MatrixOp Black_spin_Black_Xplus = sumrows(TempMatrix)
		
		Concatenate /O Wavelist(Prefix+"*_minusX",";",""), TempMatrix
		MatrixOp Black_spin_Black_Xminus = sumrows(TempMatrix)
		
		Print "Waves Summed to Output Black_spin_Black_Zplus:"
		Print Wavelist(Prefix+"*_plusZ",";","")
		Print "Waves Summed to Output Black_spin_Black_Zminus:"
		Print Wavelist(Prefix+"*_minusZ",";","")
		Print "Waves Summed to Output Black_spin_Black_Xplus:"
		Print Wavelist(Prefix+"*_plusX",";","")
		Print "Waves Summed to Output Black_spin_Black_Xminus:"
		Print Wavelist(Prefix+"*_minusX",";","")
	Else
		Concatenate /O Wavelist(Prefix+"*_plusZ",";",""), TempMatrix
		MatrixOp White_spin_White_Zplus = sumrows(TempMatrix)
		
		Concatenate /O Wavelist(Prefix+"*_minusZ",";",""), TempMatrix
		MatrixOp White_spin_White_Zminus = sumrows(TempMatrix)
		
		Concatenate /O Wavelist(Prefix+"*_plusY",";",""), TempMatrix
		MatrixOp White_spin_White_Yplus = sumrows(TempMatrix)
		
		Concatenate /O Wavelist(Prefix+"*_minusY",";",""), TempMatrix
		MatrixOp White_spin_White_Yminus = sumrows(TempMatrix)
		
		Print "Waves Summed to Output White_spin_White_Zplus:"
		Print Wavelist(Prefix+"*_plusZ",";","")
		Print "Waves Summed to Output White_spin_White_Zminus:"
		Print Wavelist(Prefix+"*_minusZ",";","")
		Print "Waves Summed to Output White_spin_White_Yplus:"
		Print Wavelist(Prefix+"*_plusY",";","")
		Print "Waves Summed to Output White_spin_White_Yminus:"
		Print Wavelist(Prefix+"*_minusY",";","")
	EndIf
End

Function SumWavesBessy(Prefix,OutputBaseName)
	String Prefix
	//String Detector
	String OutputBaseName
	
	String Suffix
	String OutputWaveName
		variable i
		For(i=1;i<=7;i+=1)
			
			if(i==2)
			else
				Suffix = "_Ch"+num2str(i)
				OutputWaveName = OutputBaseName+Suffix
				Concatenate /O Wavelist(Prefix+"*"+Suffix,";",""), TempMatrix
				MatrixOp $OutputWaveName = sumrows(TempMatrix)
				Setscale /p x, dimoffset(tempmatrix,0),dimdelta(tempmatrix,0),$OutputWaveName
			endif
		
		EndFor
		
//		Print "Waves Summed to Output Black_spin_Black_Zplus:"
//		Print Wavelist(Prefix+"*_plusZ",";","")
//		Print "Waves Summed to Output Black_spin_Black_Zminus:"
//		Print Wavelist(Prefix+"*_minusZ",";","")
//		Print "Waves Summed to Output Black_spin_Black_Xplus:"
//		Print Wavelist(Prefix+"*_plusX",";","")
//		Print "Waves Summed to Output Black_spin_Black_Xminus:"
//		Print Wavelist(Prefix+"*_minusX",";","")

End