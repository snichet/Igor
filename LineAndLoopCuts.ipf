#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Dim 0: Analyzer Angler
// Dim 1: Binding Energy
// Dim 2: Scanning Angle
Function LoopCut(InputWaveName, CenterX,CenterY,Radius)

	String InputWaveName
	Variable CenterX
	Variable CenterY
	Variable Radius
	
	Wave Inputwave = $InputWaveName
	
	Variable Circumference = 2*Pi*Radius
	Variable NumPts=Round(Circumference/Dimdelta(InputWave, 0))
	
	String TempXName ="CirX"
	String TempYName ="CirY"
	Make /O /N = (NumPts+1) $TempXName
	Make /O /N = (NumPts+1) $TempYName
	Wave TempX = $TempXName
	Wave TempY = $TempYName
	
	TempX[]=CenterX+Radius*Cos(2*Pi/NumPts*p)
	TempY[]=CenterY+Radius*Sin(2*Pi/NumPts*p)

	String OutputWaveName = InputwaveName+"_loop_"+num2str(Centerx)+"_"+num2str(centery)+"_"+num2str(radius)
	Make /O /N = (NumPts+1,DimSize(InputWave,1)) $OutputWaveName
	Wave OutputWave = $OutputWaveName
	
	Variable i
	
//	For(i=0;i<dimsize(OutputWave,0);i+=1)
//		OutputWave[i][]=InputWave[Round((TempX[i]-dimoffset(Inputwave, 0))/dimdelta(Inputwave,0))][q][Round((TempY[i]-dimoffset(Inputwave,2))/dimdelta(Inputwave,2))]
//	EndFor

	Variable XHighWeight
	Variable YHighWeight
	
	For(i=0;i<dimsize(OutputWave,0);i+=1)
		XHighWeight = (TempX[i]-(dimoffset(InputWave,0)+dimdelta(InputWave,0)*Trunc((TempX[i]-dimoffset(Inputwave, 0))/dimdelta(Inputwave,0))))/dimdelta(Inputwave,0)
		YHighWeight = (TempY[i]-(dimoffset(Inputwave,2)+dimdelta(InputWave,2)*Trunc((TempY[i]-dimoffset(Inputwave, 2))/dimdelta(Inputwave,2))))/dimdelta(Inputwave,2)
		
		OutputWave[i][]=(1-XHighWeight)*(1-YHighWeight)*Inputwave[Trunc((TempX[i]-dimoffset(Inputwave, 0))/dimdelta(Inputwave,0))][q][Trunc((TempY[i]-dimoffset(Inputwave,2))/dimdelta(Inputwave,2))]+(XHighWeight)*(1-YHighWeight)*Inputwave[Trunc((TempX[i]-dimoffset(Inputwave, 0))/dimdelta(Inputwave,0))+1][q][Trunc((TempY[i]-dimoffset(Inputwave,2))/dimdelta(Inputwave,2))]+(1-XHighWeight)*(YHighWeight)*Inputwave[Trunc((TempX[i]-dimoffset(Inputwave, 0))/dimdelta(Inputwave,0))][q][Trunc((TempY[i]-dimoffset(Inputwave,2))/dimdelta(Inputwave,2))+1]+(XHighWeight)*(YHighWeight)*Inputwave[Trunc((TempX[i]-dimoffset(Inputwave, 0))/dimdelta(Inputwave,0))+1][q][Trunc((TempY[i]-dimoffset(Inputwave,2))/dimdelta(Inputwave,2))+1]
	EndFor
	
	Display
	AppendImage Outputwave
	
	Setscale /i x, 0, 1,OutputWave
	Setscale /p y, dimoffset(Inputwave,1), dimdelta(InputWave,1), OutputWave
	
	SetAxis left -1,.2
	
	//ModifyImage $OutputWaveName ctab= {0,140000,Grays,1}
End

Function ManyLoopCuts(Inputwave,Centerx,Centery,SmallRadius,LargeRadius,StepRadius)
	Wave Inputwave
	Variable Centerx
	Variable Centery
	Variable SmallRadius
	Variable LargeRadius
	Variable StepRadius
	
	Variable i
	String InputWaveName = NameofWave(InputWave)
	
	For(i=SmallRadius;I<=LargeRadius;i+=StepRadius)
		LoopCut(InputWaveName,Centerx,Centery,i)
	EndFor
End

// Dim 0: Analyzer Angler
// Dim 1: Binding Energy
// Dim 2: Scanning Angle
//X corresponds to Analyzer Angle
//Y corresponds to Rotation Angle
Function LineCut(InputWave, X1,Y1,X2,Y2,SpecifyOutputName,SpecifiedOutputName,SwitchXYForPlot)

	Wave InputWave
	Variable X1
	Variable Y1
	Variable X2
	Variable Y2
	Variable SpecifyOutputName
	String SpecifiedOutputName
	Variable SwitchXYForPlot
	
	String InputWaveName = NameofWave(inputwave)
	
	Wave Inputwave = $InputWaveName
	
	Variable Length = Sqrt((X2-X1)^2+(Y2-Y1)^2)
	Variable NumPts=Round(Length/Dimdelta(InputWave, 0))
	
	String TempXName
	String TempYName
	
	Variable i,a
	
	String OutputWaveName
	If(SpecifyOutputName==0)
		Do
			OutputWaveName = InputwaveName+"_line"+num2str(i)
			TempXName = InputWaveName+"_xwave"+num2str(i)
			TempYName = InputWaveName+"_ywave"+num2str(i)
			i+=1
			a=exists(OutputWaveName)
		While(a==1)
	Else
		OutputWaveName=SpecifiedOutputName
		TempXName = SpecifiedOutputName+"_XWave"
		TempYName = SpecifiedOutputName+"_YWave"
	EndIf
	Make /O /N = (NumPts+1,DimSize(InputWave,1)) $OutputWaveName
	Wave OutputWave = $OutputWaveName
	Make /O /N = (NumPts+1) $TempXName
	Make /O /N = (NumPts+1) $TempYName
	Wave TempX = $TempXName
	Wave TempY = $TempYName
	TempY[]=Y1+(Y2-Y1)*p/(NumPts)
	TempX[]=X1+(X2-X1)*p/(NumPts)
	//For(i=0;i<dimsize(OutputWave,0);i+=1)
	//	OutputWave[i][]=InputWave[Round((TempX[i]-dimoffset(Inputwave, 0))/dimdelta(Inputwave,0))][q][Round((TempY[i]-dimoffset(Inputwave,2))/dimdelta(Inputwave,2))]
	//EndFor
	
	//The commentized loop above gives the value of the raw data closest to the point along the line. The loop below linearly interpolates between the nearest 4 points, removing obvious steps in the scanning direction.
	
	Variable XHighWeight
	Variable YHighWeight
	
	For(i=0;i<dimsize(OutputWave,0);i+=1)
		XHighWeight = (TempX[i]-(dimoffset(InputWave,0)+dimdelta(InputWave,0)*Trunc((TempX[i]-dimoffset(Inputwave, 0))/dimdelta(Inputwave,0))))/dimdelta(Inputwave,0)
		YHighWeight = (TempY[i]-(dimoffset(InputWave,2)+dimdelta(InputWave,2)*Trunc((TempY[i]-dimoffset(Inputwave, 2))/dimdelta(Inputwave,2))))/dimdelta(Inputwave,2)
				
		OutputWave[i][]=(1-XHighWeight)*(1-YHighWeight)*Inputwave[Trunc((TempX[i]-dimoffset(Inputwave, 0))/dimdelta(Inputwave,0))][q][Trunc((TempY[i]-dimoffset(Inputwave,2))/dimdelta(Inputwave,2))]+(XHighWeight)*(1-YHighWeight)*Inputwave[Trunc((TempX[i]-dimoffset(Inputwave, 0))/dimdelta(Inputwave,0))+1][q][Trunc((TempY[i]-dimoffset(Inputwave,2))/dimdelta(Inputwave,2))]+(1-XHighWeight)*(YHighWeight)*Inputwave[Trunc((TempX[i]-dimoffset(Inputwave, 0))/dimdelta(Inputwave,0))][q][Trunc((TempY[i]-dimoffset(Inputwave,2))/dimdelta(Inputwave,2))+1]+(XHighWeight)*(YHighWeight)*Inputwave[Trunc((TempX[i]-dimoffset(Inputwave, 0))/dimdelta(Inputwave,0))+1][q][Trunc((TempY[i]-dimoffset(Inputwave,2))/dimdelta(Inputwave,2))+1]
	EndFor
	
	If(SwitchXYForPlot==0)
		AppendtoGraph tempy vs tempx
	Else
		AppendtoGraph tempx vs tempy
	EndIf
	Display /n=$OutputWaveName
	AppendImage Outputwave
	
	Setscale /p x, 0, dimdelta(InputWave,0), OutputWave
	Setscale /p y, dimoffset(Inputwave,1), dimdelta(InputWave,1), OutputWave
	
	Note Outputwave "This wave is a linecut extracted from "+nameofwave(inputwave)
	NOte Outputwave "Inputwave: "+nameofwave(inputwave)
	note outputwave "X1: "+num2str(x1)
	note outputwave "Y1: "+num2str(y1)
	note outputwave "X2: "+num2str(x2)
	note outputwave "Y2: "+num2str(y2)
End

//Extracts a line trace from a 2D wave.

Function LineTrace(InputWave, X1,Y1,X2,Y2)

	Wave InputWave
	Variable X1
	Variable Y1
	Variable X2
	Variable Y2
		
	Variable Length = Sqrt((X2-X1)^2+(Y2-Y1)^2)
	Variable NumPts=Round(Length/Min(Dimdelta(InputWave, 0),Dimdelta(Inputwave,1)))+1
	
	String TempXName = nameofwave(inputwave)+"_xwave"
	String TempYName = nameofwave(inputwave) +"_yname"
	Make /O /N = (NumPts) $TempXName
	Make /O /N = (NumPts) $TempYName
	Wave TempX = $TempXName
	Wave TempY = $TempYName
	
	TempY[]=Y1+(Y2-Y1)*p/(NumPts)
	TempX[]=X1+(X2-X1)*p/(NumPts)
	
	String OutputWaveName = nameofwave(inputwave)+"_LineTrace"//_("+num2str(X1)+","+num2str(Y1)+")_("+num2str(X2)+","+num2str(Y2)+")"
	Make /O /N = (NumPts) $OutputWaveName
	Wave OutputWave = $OutputWaveName
	
	Variable i
	
	//For(i=0;i<dimsize(OutputWave,0);i+=1)
	//	OutputWave[i][]=InputWave[Round((TempX[i]-dimoffset(Inputwave, 0))/dimdelta(Inputwave,0))][q][Round((TempY[i]-dimoffset(Inputwave,2))/dimdelta(Inputwave,2))]
	//EndFor
	
	//The commentized loop above gives the value of the raw data closest to the point along the line. The loop below linearly interpolates between the nearest 4 points, removing obvious steps in the scanning direction.
	
	Variable XHighWeight
	Variable YHighWeight
	
	For(i=0;i<dimsize(OutputWave,0);i+=1)
		XHighWeight = (TempX[i]-(dimoffset(InputWave,0)+dimdelta(InputWave,0)*Trunc((TempX[i]-dimoffset(Inputwave, 0))/dimdelta(Inputwave,0))))/dimdelta(Inputwave,0)
		YHighWeight = (TempY[i]-(dimoffset(Inputwave,1)+dimdelta(InputWave,1)*Trunc((TempY[i]-dimoffset(Inputwave, 1))/dimdelta(Inputwave,1))))/dimdelta(Inputwave,1)
		
		OutputWave[i]=(1-XHighWeight)*(1-YHighWeight)*Inputwave[Trunc((TempX[i]-dimoffset(Inputwave, 0))/dimdelta(Inputwave,0))][Trunc((TempY[i]-dimoffset(Inputwave,1))/dimdelta(Inputwave,1))]+(XHighWeight)*(1-YHighWeight)*Inputwave[Trunc((TempX[i]-dimoffset(Inputwave, 0))/dimdelta(Inputwave,0))+1][Trunc((TempY[i]-dimoffset(Inputwave,1))/dimdelta(Inputwave,1))]+(1-XHighWeight)*(YHighWeight)*Inputwave[Trunc((TempX[i]-dimoffset(Inputwave, 0))/dimdelta(Inputwave,0))][Trunc((TempY[i]-dimoffset(Inputwave,1))/dimdelta(Inputwave,1))+1]+(XHighWeight)*(YHighWeight)*Inputwave[Trunc((TempX[i]-dimoffset(Inputwave, 0))/dimdelta(Inputwave,0))+1][Trunc((TempY[i]-dimoffset(Inputwave,1))/dimdelta(Inputwave,1))+1]
	EndFor
	
	AppendtoGraph tempy vs tempx
	
	Display outputwave
	
	//Setscale /i x, 0, 1,OutputWave
	Setscale /p x, 0, min(dimdelta(InputWave,0),dimdelta(inputwave,1)), OutputWave
	
	Print "LineTrace has been carried out on "+nameofWave(inputwave)+"."
	Print "X1"+num2str(x1)
	Print "Y1"+num2str(y1)
	Print "X2"+num2str(x2)
	Print "Y2"+num2str(y2)
	Print "Output wave is "+nameofwave(outputwave)
	
	Note OutputWave "LineTrace has been carried out on "+nameofWave(inputwave)+"."
	Note OutputWave "X1"+num2str(x1)
	Note OutputWave "Y1"+num2str(y1)
	Note OutputWave "X2"+num2str(x2)
	Note OutputWave "Y2"+num2str(y2)
	
	//SetAxis left -1,0.3
	
	//ModifyImage $OutputWaveName ctab= {-24700,24700,RedWhiteBlue,0}

End