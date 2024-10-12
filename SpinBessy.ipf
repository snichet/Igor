#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//Example: LoadSpinWavesBessy("Macintosh HD:Users:cochra96:Documents:Data:20190920_Bessy:NRS1:","NRS_",35,0.16,0,1)

//#include  "Macintosh HD:Users:cochra96:Documents:Data:IGOR stuff:BinningProcs"

Function LoadSpinWavesBessy(PathBase,ScanBaseName,ScanNumber,ShermanFunction,SuppressDim1,Asyms)
	String PathBase
	String ScanBaseName
	Variable ScanNumber
	Variable ShermanFunction
	Variable SuppressDim1
	Variable Asyms
	
	//First Load Data
	
	String PathName
	Variable i,j,k
	String InputName
	String OutputName
	
	i=0
	If(ScanNumber<10)
		For(i=0;i<8;i+=1)
			PathName = PathBase+ScanBaseName+"000"+num2str(ScanNumber)+"SR-VB_Dev3_ctr"+num2str(i)+"_in.ibw"
			LoadWave /H PathName
		EndFor
	Else
		If(ScanNumber<100)
			For(i=0;i<8;i+=1)
				PathName = PathBase+ScanBaseName+"00"+num2str(ScanNumber)+"SR-VB_Dev3_ctr"+num2str(i)+"_in.ibw"
				LoadWave /H PathName
			EndFor
		Else
			If(ScanNumber<1000)
				For(i=0;i<8;i+=1)
					PathName = PathBase+ScanBaseName+"0"+num2str(ScanNumber)+"SR-VB_Dev3_ctr"+num2str(i)+"_in.ibw"
					LoadWave /H PathName
				EndFor
			Else
				For(i=0;i<8;i+=1)
					PathName = PathBase+ScanBaseName+num2str(ScanNumber)+"SR-VB_Dev3_ctr"+num2str(i)+"_in.ibw"
					LoadWave /H PathName
				EndFor
			EndIf
		EndIf
	EndIf
	
	For(i=0;i<8;i+=1)
		InputName = "SR-VB_Dev3_ctr"+num2str(i)+"_in"
		Outputname = ScanBaseName+num2str(ScanNumber)+"_c"+num2str(i)
		If(Exists(OutputName))
			killwaves $OutputName
		EndIf
		rename $inputname $outputname
		Redimension /s $OutputName
		Wave OutputWave = $OutputName
//		For(k=0;k<dimsize(outputwave,0);k+=1)
//		For(j=0;j<dimsize(outputwave,1);j+=1)
//			If(OutputWave[k][j]==0)
//				OutputWave[k][j]=0.000001
//			Else
//			EndIf
//		EndFor
//		EndFor
	EndFor
	
	//If Multidimensional Wave, condense data
	
	If(SuppressDim1==1)
		SupDim1(OutputName,ScanBaseName,ScanNumber)
	Else
	EndIf
	
	//Calculate Asymmetries and Spins
	
	If(Asyms==1)
		AsymAndSpins(ScanBaseName,ScanNumber,ShermanFunction)
	Else
	EndIf
		
End

//For Summing along Dim1 of a 2D wave and turning into a 1D wave
Function SupDim1(OutputName,ScanBaseName,ScanNumber)
	String OutputName
	String ScanBaseName
	Variable ScanNumber
	
	Wave OutputWave = $OutputName
	
	Variable j,i
	If(Dimsize(Outputwave,1)>0)
		For(i=0;i<8;i+=1)
			Outputname = ScanBaseName+num2str(ScanNumber)+"_c"+num2str(i)
			Wave OutputWave = $OutputName
			Make /n=(dimsize(OutputWave,0)) temp1
			Temp1 = 0
			For(j=0;j<dimsize(OutputWave,1);j+=1)
				Temp1[]=Temp1[p]+Outputwave[p][i]
			EndFor
			killwaves Outputwave
			rename Temp1 $outputname
		EndFor
	Else
	EndIf
	killwaves temp1
End

//For Calculation the channel asymmetries and spin signals
Function AsymAndSpins(ScanBaseName,ScanNumber,ShermanFunction)
	
	String ScanBaseName
	Variable ScanNumber
	Variable ShermanFunction
	
	String Ch1Name
	String Ch2Name
	String AsName
	String Spin1Name
	String Spin2Name
	Variable Scale
	Variable V_sum
	Variable PreviousSum
	Variable ScaleStep
	Variable ConvergenceCounter
	Variable i,j
	
	//Channels 0 & 2
	Ch1Name = ScanBaseName+num2str(ScanNumber)+"_c0"
	Ch2Name = ScanBaseName+num2str(ScanNumber)+"_c2"
	AsName = ScanBaseName+num2str(ScanNumber)+"_as02"
	Spin1Name = ScanBaseName+num2str(ScanNumber)+"_s0"
	Spin2Name = ScanBaseName+num2str(ScanNumber)+"_s2"
	Duplicate /o $Ch1Name $AsName
	Duplicate /o $Ch1Name $Spin1Name
	Duplicate /o $Ch1Name $Spin2Name
	Duplicate /o $Ch1Name temp
	temp = 0
	Wave Ch1 = $Ch1Name
	Wave Ch2 = $Ch2Name
	Wave As = $AsName
	Wave Spin1 = $Spin1Name
	Wave Spin2 = $Spin2Name
	As=0
	Spin1=0
	Spin2=0
	
	Scale=1
	ScaleStep = 0.01
	PreviousSum=0
	Do
		If(PreviousSum>0)
			Scale*=(1+ScaleStep)
		Else
			Scale*=(1-ScaleStep)
		EndIf
		
		temp[][] = Ch1[p][q]-Scale*Ch2[p][q]		
		wavestats /q temp
		
		If(Sign(V_sum)==Sign(PreviousSum))
		Else
			ScaleStep*=0.5
		EndIf
		
		If(Abs(V_sum)<Abs(PreviousSum))
			ConvergenceCounter=0
		Else
			ConvergenceCounter+=1
		EndIf
		
		PreviousSum=V_sum
	While(ConvergenceCounter<40)
	
	//Equations written for me by Dmitry 20190927
	As[][]=(Ch1[p][q]-Scale*Ch2[p][q])/(Ch1[p][q]+Scale*Ch2[p][q])
	Spin1[][]=1/(2)*(Ch1[p][q]+Scale*Ch2[p][q])*(1+As[p][q]/ShermanFunction) 
	Spin2[][]=1/(2)*(Ch1[p][q]+Scale*Ch2[p][q])*(1-As[p][q]/ShermanFunction)
	
	String SPName =  ScanBaseName+num2str(ScanNumber)+"_SP02"
	Duplicate /o As $SPName
	Wave SP = $SPName
	SP/=ShermanFunction 
	
	Print "Scale for a02: " +num2str(Scale)
	
	Display $AsName
	Display $Spin1Name, $Spin2Name
	
	//Channels 1 & 3
	Ch1Name = ScanBaseName+num2str(ScanNumber)+"_c1"
	Ch2Name = ScanBaseName+num2str(ScanNumber)+"_c3"
	AsName = ScanBaseName+num2str(ScanNumber)+"_as13"
	Spin1Name = ScanBaseName+num2str(ScanNumber)+"_s1"
	Spin2Name = ScanBaseName+num2str(ScanNumber)+"_s3"
	Duplicate /o $Ch1Name $AsName
	Duplicate /o $Ch1Name $Spin1Name
	Duplicate /o $Ch1Name $Spin2Name
	Duplicate /o $Ch1Name temp
	temp = 0
	Wave Ch1 = $Ch1Name
	Wave Ch2 = $Ch2Name
	Wave As = $AsName
	Wave Spin1 = $Spin1Name
	Wave Spin2 = $Spin2Name
	As=0
	Spin1=0
	Spin2=0
	
	Scale=1
	ScaleStep = 0.01
	PreviousSum=0
	ConvergenceCounter=0
	Do
		If(PreviousSum>0)
			Scale*=(1+ScaleStep)
		Else
			Scale*=(1-ScaleStep)
		EndIf
		
		temp[][] = Ch1[p][q]-Scale*Ch2[p][q]		
		wavestats /q temp
		
		If(Sign(V_sum)==Sign(PreviousSum))
		Else
			ScaleStep*=0.5
		EndIf
		
		If(Abs(V_sum)<Abs(PreviousSum))
			ConvergenceCounter=0
		Else
			ConvergenceCounter+=1
		EndIf
		
		PreviousSum=V_sum
	While(ConvergenceCounter<40)
	
	//Equations written for me by Dmitry 20190927
	As[][]=(Ch1[p][q]-Scale*Ch2[p][q])/(Ch1[p][q]+Scale*Ch2[p][q])
	Spin1[][]=1/(2)*(Ch1[p][q]+Scale*Ch2[p][q])*(1+As[p][q]/ShermanFunction) 
	Spin2[][]=1/(2)*(Ch1[p][q]+Scale*Ch2[p][q])*(1-As[p][q]/ShermanFunction)
	
	SPName =  ScanBaseName+num2str(ScanNumber)+"_SP13"
	Duplicate /o As $SPName
	Wave SP = $SPName
	SP/=ShermanFunction 	
	Print "Scale for a13: " +num2str(Scale)
	
	Display $AsName
	Display $Spin1Name, $Spin2Name
	
	//Channels 4 & 6
	Ch1Name = ScanBaseName+num2str(ScanNumber)+"_c4"
	Ch2Name = ScanBaseName+num2str(ScanNumber)+"_c6"
	AsName = ScanBaseName+num2str(ScanNumber)+"_as46"
	Spin1Name = ScanBaseName+num2str(ScanNumber)+"_s4"
	Spin2Name = ScanBaseName+num2str(ScanNumber)+"_s6"
	Duplicate /o $Ch1Name $AsName
	Duplicate /o $Ch1Name $Spin1Name
	Duplicate /o $Ch1Name $Spin2Name
	Duplicate /o $Ch1Name temp
	temp = 0
	Wave Ch1 = $Ch1Name
	Wave Ch2 = $Ch2Name
	Wave As = $AsName
	Wave Spin1 = $Spin1Name
	Wave Spin2 = $Spin2Name
	As=0
	Spin1=0
	Spin2=0
	
	Scale=1
	ScaleStep = 0.01
	PreviousSum=0
	ConvergenceCounter=0

	Do
		If(PreviousSum>0)
			Scale*=(1+ScaleStep)
		Else
			Scale*=(1-ScaleStep)
		EndIf
		
		temp[][] = Ch1[p][q]-Scale*Ch2[p][q]		
		wavestats /q temp
		
		If(Sign(V_sum)==Sign(PreviousSum))
		Else
			ScaleStep*=0.5
		EndIf
		
		If(Abs(V_sum)<Abs(PreviousSum))
			ConvergenceCounter=0
		Else
			ConvergenceCounter+=1
		EndIf
		
		PreviousSum=V_sum
	While(ConvergenceCounter<40)
	
	//Equations written for me by Dmitry 20190927
	As[][]=(Ch1[p][q]-Scale*Ch2[p][q])/(Ch1[p][q]+Scale*Ch2[p][q])
	Spin1[][]=1/(2)*(Ch1[p][q]+Scale*Ch2[p][q])*(1+As[p][q]/ShermanFunction) 
	Spin2[][]=1/(2)*(Ch1[p][q]+Scale*Ch2[p][q])*(1-As[p][q]/ShermanFunction)
	
	SPName =  ScanBaseName+num2str(ScanNumber)+"_SP46"
	Duplicate /o As $SPName
	Wave SP = $SPName
	SP/=ShermanFunction 	
	Print "Scale for a46: " +num2str(Scale)
	
	Display $AsName
	Display $Spin1Name, $Spin2Name
	
	//Channels 5 & 7
	Ch1Name = ScanBaseName+num2str(ScanNumber)+"_c5"
	Ch2Name = ScanBaseName+num2str(ScanNumber)+"_c7"
	AsName = ScanBaseName+num2str(ScanNumber)+"_as57"
	Spin1Name = ScanBaseName+num2str(ScanNumber)+"_s5"
	Spin2Name = ScanBaseName+num2str(ScanNumber)+"_s7"
	Duplicate /o $Ch1Name $AsName
	Duplicate /o $Ch1Name $Spin1Name
	Duplicate /o $Ch1Name $Spin2Name
	Duplicate /o $Ch1Name temp
	temp = 0
	Wave Ch1 = $Ch1Name
	Wave Ch2 = $Ch2Name
	Wave As = $AsName
	Wave Spin1 = $Spin1Name
	Wave Spin2 = $Spin2Name
	As=0
	Spin1=0
	Spin2=0
	
	Scale=1
	ScaleStep = 0.01
	PreviousSum=0
	ConvergenceCounter=0

	Do
		If(PreviousSum>0)
			Scale*=(1+ScaleStep)
		Else
			Scale*=(1-ScaleStep)
		EndIf
		
		temp[][] = Ch1[p][q]-Scale*Ch2[p][q]		
		wavestats /q temp
		
		If(Sign(V_sum)==Sign(PreviousSum))
		Else
			ScaleStep*=0.5
		EndIf
		
		If(Abs(V_sum)<Abs(PreviousSum))
			ConvergenceCounter=0
		Else
			ConvergenceCounter+=1
		EndIf
		
		PreviousSum=V_sum
	While(ConvergenceCounter<40)
	
	//Equations written for me by Dmitry 20190927
	As[][]=(Ch1[p][q]-Scale*Ch2[p][q])/(Ch1[p][q]+Scale*Ch2[p][q])
	Spin1[][]=1/(2)*(Ch1[p][q]+Scale*Ch2[p][q])*(1+As[p][q]/ShermanFunction) 
	Spin2[][]=1/(2)*(Ch1[p][q]+Scale*Ch2[p][q])*(1-As[p][q]/ShermanFunction)
	
	SPName =  ScanBaseName+num2str(ScanNumber)+"_SP57"
	Duplicate /o As $SPName
	Wave SP = $SPName
	SP/=ShermanFunction 
	
	Print "Scale for a57: " +num2str(Scale)
	
	Display $AsName
	Display $Spin1Name, $Spin2Name
	
	killwaves temp
	
End

Function AsymAndSpinsBinned(ScanBaseName,ScanNumber,ShermanFunction,BinNum)
	
	String ScanBaseName
	Variable ScanNumber
	Variable ShermanFunction
	Variable BinNum
	
	String Ch1Name
	String Ch2Name
	String AsName
	String Spin1Name
	String Spin2Name
	Variable Scale
	Variable V_sum
	Variable PreviousSum
	Variable ScaleStep
	Variable ConvergenceCounter
	Variable i,j
	
	//Channels 0 & 2
	Ch1Name = ScanBaseName+num2str(ScanNumber)+"_c0_bin"+num2str(binnum)
	Ch2Name = ScanBaseName+num2str(ScanNumber)+"_c2_bin"+num2str(binnum)
	AsName = ScanBaseName+num2str(ScanNumber)+"_as02_bin"+num2str(binnum)
	Spin1Name = ScanBaseName+num2str(ScanNumber)+"_s0_bin"+num2str(binnum)
	Spin2Name = ScanBaseName+num2str(ScanNumber)+"_s2_bin"+num2str(binnum)
	Duplicate /o $Ch1Name $AsName
	Duplicate /o $Ch1Name $Spin1Name
	Duplicate /o $Ch1Name $Spin2Name
	Duplicate /o $Ch1Name temp
	temp = 0
	Wave Ch1 = $Ch1Name
	Wave Ch2 = $Ch2Name
	Wave As = $AsName
	Wave Spin1 = $Spin1Name
	Wave Spin2 = $Spin2Name
	As=0
	Spin1=0
	Spin2=0
	
	Scale=1
	ScaleStep = 0.01
	PreviousSum=0
	ConvergenceCounter=0
	Do
		If(PreviousSum>0)
			Scale*=(1+ScaleStep)
		Else
			Scale*=(1-ScaleStep)
		EndIf
		
		temp[][] = Ch1[p][q]-Scale*Ch2[p][q]		
		wavestats /q temp
		
		If(Sign(V_sum)==Sign(PreviousSum))
		Else
			ScaleStep*=0.5
		EndIf
		
		If(Abs(V_sum)<Abs(PreviousSum))
			ConvergenceCounter=0
		Else
			ConvergenceCounter+=1
		EndIf
		
		PreviousSum=V_sum
	While(ConvergenceCounter<40)
	
	//Equations written for me by Dmitry 20190927
	As[][]=(Ch1[p][q]-Scale*Ch2[p][q])/(Ch1[p][q]+Scale*Ch2[p][q])
	Spin1[][]=1/(2)*(Ch1[p][q]+Scale*Ch2[p][q])*(1+As[p][q]/ShermanFunction) 
	Spin2[][]=1/(2)*(Ch1[p][q]+Scale*Ch2[p][q])*(1-As[p][q]/ShermanFunction)
	
	String SPName =  ScanBaseName+num2str(ScanNumber)+"_SP57"
	Duplicate /o As $SPName
	Wave SP = $SPName
	SP/=ShermanFunction 
	
	Print "Scale for a02: " +num2str(Scale)
	
	Display $AsName
	Display $Spin1Name, $Spin2Name
	
	//Channels 1 & 3
	Ch1Name = ScanBaseName+num2str(ScanNumber)+"_c1_bin"+num2str(binnum)
	Ch2Name = ScanBaseName+num2str(ScanNumber)+"_c3_bin"+num2str(binnum)
	AsName = ScanBaseName+num2str(ScanNumber)+"_as13_bin"+num2str(binnum)
	Spin1Name = ScanBaseName+num2str(ScanNumber)+"_s1_bin"+num2str(binnum)
	Spin2Name = ScanBaseName+num2str(ScanNumber)+"_s3_bin"+num2str(binnum)
	Duplicate /o $Ch1Name $AsName
	Duplicate /o $Ch1Name $Spin1Name
	Duplicate /o $Ch1Name $Spin2Name
	Duplicate /o $Ch1Name temp
	temp = 0
	Wave Ch1 = $Ch1Name
	Wave Ch2 = $Ch2Name
	Wave As = $AsName
	Wave Spin1 = $Spin1Name
	Wave Spin2 = $Spin2Name
	As=0
	Spin1=0
	Spin2=0
	
	Scale=1
	ScaleStep = 0.01
	PreviousSum=0
	ConvergenceCounter=0
	Do
		If(PreviousSum>0)
			Scale*=(1+ScaleStep)
		Else
			Scale*=(1-ScaleStep)
		EndIf
		
		temp[][] = Ch1[p][q]-Scale*Ch2[p][q]		
		wavestats /q temp
		
		If(Sign(V_sum)==Sign(PreviousSum))
		Else
			ScaleStep*=0.5
		EndIf
		
		If(Abs(V_sum)<Abs(PreviousSum))
			ConvergenceCounter=0
		Else
			ConvergenceCounter+=1
		EndIf
		
		PreviousSum=V_sum
	While(ConvergenceCounter<40)
	
	//Equations written for me by Dmitry 20190927
	As[][]=(Ch1[p][q]-Scale*Ch2[p][q])/(Ch1[p][q]+Scale*Ch2[p][q])
	Spin1[][]=1/(2)*(Ch1[p][q]+Scale*Ch2[p][q])*(1+As[p][q]/ShermanFunction) 
	Spin2[][]=1/(2)*(Ch1[p][q]+Scale*Ch2[p][q])*(1-As[p][q]/ShermanFunction)
	
	SPName =  ScanBaseName+num2str(ScanNumber)+"_SP57"
	Duplicate /o As $SPName
	Wave SP = $SPName
	SP/=ShermanFunction 
	
	Print "Scale for a13: " +num2str(Scale)
	
	Display $AsName
	Display $Spin1Name, $Spin2Name
	
	//Channels 4 & 6
	Ch1Name = ScanBaseName+num2str(ScanNumber)+"_c4_bin"+num2str(binnum)
	Ch2Name = ScanBaseName+num2str(ScanNumber)+"_c6_bin"+num2str(binnum)
	AsName = ScanBaseName+num2str(ScanNumber)+"_as46_bin"+num2str(binnum)
	Spin1Name = ScanBaseName+num2str(ScanNumber)+"_s_bin"+num2str(binnum)
	Spin2Name = ScanBaseName+num2str(ScanNumber)+"_s6_bin"+num2str(binnum)
	Duplicate /o $Ch1Name $AsName
	Duplicate /o $Ch1Name $Spin1Name
	Duplicate /o $Ch1Name $Spin2Name
	Duplicate /o $Ch1Name temp
	temp = 0
	Wave Ch1 = $Ch1Name
	Wave Ch2 = $Ch2Name
	Wave As = $AsName
	Wave Spin1 = $Spin1Name
	Wave Spin2 = $Spin2Name
	As=0
	Spin1=0
	Spin2=0
	
	Scale=1
	ScaleStep = 0.01
	PreviousSum=0
	ConvergenceCounter=0

	Do
		If(PreviousSum>0)
			Scale*=(1+ScaleStep)
		Else
			Scale*=(1-ScaleStep)
		EndIf
		
		temp[][] = Ch1[p][q]-Scale*Ch2[p][q]		
		wavestats /q temp
		
		If(Sign(V_sum)==Sign(PreviousSum))
		Else
			ScaleStep*=0.5
		EndIf
		
		If(Abs(V_sum)<Abs(PreviousSum))
			ConvergenceCounter=0
		Else
			ConvergenceCounter+=1
		EndIf
		
		PreviousSum=V_sum
	While(ConvergenceCounter<40)
	
	//Equations written for me by Dmitry 20190927
	As[][]=(Ch1[p][q]-Scale*Ch2[p][q])/(Ch1[p][q]+Scale*Ch2[p][q])
	Spin1[][]=1/(2)*(Ch1[p][q]+Scale*Ch2[p][q])*(1+As[p][q]/ShermanFunction) 
	Spin2[][]=1/(2)*(Ch1[p][q]+Scale*Ch2[p][q])*(1-As[p][q]/ShermanFunction)
	
	SPName =  ScanBaseName+num2str(ScanNumber)+"_SP57"
	Duplicate /o As $SPName
	Wave SP = $SPName
	SP/=ShermanFunction 	
	Print "Scale for a46: " +num2str(Scale)
	
	Display $AsName
	Display $Spin1Name, $Spin2Name
	
	//Channels 5 & 7
	Ch1Name = ScanBaseName+num2str(ScanNumber)+"_c5_bin"+num2str(binnum)
	Ch2Name = ScanBaseName+num2str(ScanNumber)+"_c7_bin"+num2str(binnum)
	AsName = ScanBaseName+num2str(ScanNumber)+"_as57_bin"+num2str(binnum)
	Spin1Name = ScanBaseName+num2str(ScanNumber)+"_s5_bin"+num2str(binnum)
	Spin2Name = ScanBaseName+num2str(ScanNumber)+"_s7_bin"+num2str(binnum)
	Duplicate /o $Ch1Name $AsName
	Duplicate /o $Ch1Name $Spin1Name
	Duplicate /o $Ch1Name $Spin2Name
	Duplicate /o $Ch1Name temp
	temp = 0
	Wave Ch1 = $Ch1Name
	Wave Ch2 = $Ch2Name
	Wave As = $AsName
	Wave Spin1 = $Spin1Name
	Wave Spin2 = $Spin2Name
	As=0
	Spin1=0
	Spin2=0
	
	Scale=1
	ScaleStep = 0.01
	PreviousSum=0
	ConvergenceCounter=0

	Do
		If(PreviousSum>0)
			Scale*=(1+ScaleStep)
		Else
			Scale*=(1-ScaleStep)
		EndIf
		
		temp[][] = Ch1[p][q]-Scale*Ch2[p][q]		
		wavestats /q temp
		
		If(Sign(V_sum)==Sign(PreviousSum))
		Else
			ScaleStep*=0.5
		EndIf
		
		If(Abs(V_sum)<Abs(PreviousSum))
			ConvergenceCounter=0
		Else
			ConvergenceCounter+=1
		EndIf
		
		PreviousSum=V_sum
	While(ConvergenceCounter<40)
	
	//Equations written for me by Dmitry 20190927
	As[][]=(Ch1[p][q]-Scale*Ch2[p][q])/(Ch1[p][q]+Scale*Ch2[p][q])
	Spin1[][]=1/(2)*(Ch1[p][q]+Scale*Ch2[p][q])*(1+As[p][q]/ShermanFunction) 
	Spin2[][]=1/(2)*(Ch1[p][q]+Scale*Ch2[p][q])*(1-As[p][q]/ShermanFunction)
	
	SPName =  ScanBaseName+num2str(ScanNumber)+"_SP57"
	Duplicate /o As $SPName
	Wave SP = $SPName
	SP/=ShermanFunction 	
	Print "Scale for a57: " +num2str(Scale)
	
	Display $AsName
	Display $Spin1Name, $Spin2Name
	
	killwaves temp
	
End