#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "Macintosh HD:Users:tylerac:Documents:data:IGOR stuff_tc20200904:Noise"
////////////////////////////////////////////////////////////////////////

//Example: smoothderivoutput3d(tmfs1_norm_0,thetest,0.1,3,5,685,830)
//
//Instructions:
//1. Make an outputwave. The dimensions don't have to match, just make a wave with the desired name.
//2. Cutoffpercentage take edcs whos total intensity is less that cutoffpercentage of the average and sets the Fermi level the average Fermi level. Should only apply to the border regions.
//3. Play with SmoothRange and SmoothTimes if problems.
//4. Identify the max and minimum points the Fermi level could be (EfMinPt, EfMaxPt) to eliminate effects from strong deep bands.
//
// 20210706 - TAC - v3 - I updated the from v1 direction (skipping the v2 update) to allow for a higher order polynomial fit to the Fermi surface curvature and implementing interpolation when writing the final wave.
//	20210727 - TAC - v4 - Start work on interpolated correction without using fitting....
////////////////////////////////////////////////////////////////////////




//dim0 is scanning angle
//dim1 is analyzer angle
//dim2 is binding energy

//Function SmoothDerivOutput3D_v3(InputWave,OutputWaveName,CutOffPercentage,SmoothRange, SmoothTimes,EfMinPt,EfMaxPt)
//	Wave InputWave
//	String OutputWaveName
//	Variable CutOffPercentage
//	Variable SmoothRange
//	Variable SmoothTimes
//	Variable EfMinPt
//	Variable EfMaxPt
//	
//	Make /s $OutputWaveName
//	wave OutputWave=$OutputWaveName
//	
//	variable v_sum
//	wavestats /q InputWave
//	Variable CutOffIntensity=v_sum/(dimsize(inputwave,0)*dimsize(inputwave,1))*CutOffPercentage
//	
//	String EDCName = "SingleEDC"
//	Make /O /N=(dimsize(inputwave,2)) $EDCName
//	Wave EDC = $EDCName
//	
//	 String EfIndexName=NameofWave(InputWave)+"EfIndex"
//	 Make /O /N=(dimsize(inputwave,0),dimsize(inputwave,1)) $EfIndexName
//	 Wave EfIndex=$EfIndexName
//	 
//	 String EfScaleName=NameofWave(InputWave)+"EfScale"
//	 Make /O /N=(dimsize(inputwave,0),dimsize(inputwave,1)) $EfScaleName
//	 Wave EfScale=$EfScaleName
//	 
//	 setscale /p x, dimoffset(inputwave,0),dimdelta(inputwave,0),efindex
//	 setscale /p y, dimoffset(inputwave,1),dimdelta(inputwave,1),efindex
//	 
//	String TempEfValueWaveName = "TempEf"
//	Make /O /N=1 $TempEfValueWaveName
//	Wave TempEfValue = $TempEfValueWaveName
//	
//	variable i,j
//	
//	for(i=0;i<dimsize(inputwave,0);i+=1)
//	for(j=0;j<dimsize(inputwave,1);j+=1)
//		EDC[]=InputWave[i][j][p]
//		wavestats /q EDC
//		If(v_sum>cutoffintensity)
//			smoothderivoutput(EDC,TempefValue,SmoothRange,SmoothTimes,EfMinPt,EfMaxPt)
//			EfIndex[i][j]=TempEfValue[0]
//			EfScale[i][j]=indextoscale(inputwave,TempEfValue[0],2)
//		Else
//			EfIndex[i][j]=NaN
//			EfScale[i][j]=NaN
//		EndIf
//	endfor
//	endfor
//	
//	String FitEfIndexName="fit_"+EfIndexName
//	duplicate /o /s EFIndex $FitEfIndexName
//	Wave FitEfIndex = $FitEfIndexName
//	
//	String FitEfScaleName="fit_"+EfScaleName
//	duplicate /o /s EFScale $FitEfScaleName
//	Wave FitEfScale = $FitEfScaleName
//
//	Make/D/N=16/O W_coef
//	W_coef[0] = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
//	FuncFitMD/NTHR=0 TwoDThirdOrder W_coef EfIndex /D=$FitEfIndexName
//	
//	variable fermiMax=WaveMax(FitEfIndex)
//	variable fermiMin=WaveMin(FitEfIndex)
//	Variable extra = trunc(fermiMax-fermiMin)+2
//	
//	String photDepShiftStr = NameofWave(OutputWave)
//	Make /O/N=(DimSize(Inputwave,0),Dimsize(inputwave,1),DimSize(Inputwave,2)+extra) $photDepShiftStr
//   Wave photDepShift = $photDepShiftStr
//   setscale /p x, dimoffset(inputwave,0),dimdelta(inputwave,0),photdepshift
//   setscale /p y, dimoffset(inputwave,1),dimdelta(inputwave,1),photdepshift
//   setscale /p z, -(fermimax+1)*dimdelta(inputwave,2),dimdelta(inputwave,2),photdepshift
//	
//	FitEfScale[][]=dimoffset(inputwave,2)+FitEfIndex[p][q]*dimdelta(inputwave,2)
//
//   variable NanFermi
//   wavestats /q FitEfScale
//   NanFermi=v_avg
//   
//   for(i=0;i<dimsize(inputwave,0);i+=1)
//   for(j=0;j<dimsize(inputwave,1);j+=1)
//   	if(numtype(fitefScale[i][j])==2)
//   		fitefScale[i][j]=NanFermi
//		endif
//	endfor
//	endfor
//
//	photDepShift[][][]=Interp3d(inputwave,indextoscale(inputwave,p,0),indextoscale(inputwave,q,1),z+FitEfScale[p][q])
//
//	MakeNoise()	
//End




//Example: smoothderivoutput3d(tmfs1_norm_0,thetest,0.1,3,5,685,830)
//
//Instructions:
//1. Make an outputwave. The dimensions don't have to match, just make a wave with the desired name.
//2. Cutoffpercentage take edcs whos total intensity is less that cutoffpercentage of the average and sets the Fermi level the average Fermi level. Should only apply to the border regions.
//3. Play with SmoothRange and SmoothTimes if problems.
//4. Identify the max and minimum points the Fermi level could be (EfMinPt, EfMaxPt) to eliminate effects from strong deep bands.
//
// 20210706 - TAC - v3 - I updated the from v1 direction (skipping the v2 update) to allow for a higher order polynomial fit to the Fermi surface curvature and implementing interpolation when writing the final wave.
////////////////////////////////////////////////////////////////////////




//dim0 is scanning angle
//dim1 is analyzer angle
//dim2 is binding energy

Function SmoothDerivOutput3D_v3(InputWave,OutputWave,CutOffPercentage,SmoothRange, SmoothTimes,EfMinPt,EfMaxPt)
	Wave InputWave
	Wave OutputWave
	Variable CutOffPercentage
	Variable SmoothRange
	Variable SmoothTimes
	Variable EfMinPt
	Variable EfMaxPt
	
	variable v_sum
	wavestats /q InputWave
	Variable CutOffIntensity=v_sum/(dimsize(inputwave,0)*dimsize(inputwave,1))*CutOffPercentage
	
	String EDCName = "SingleEDC"
	Make /O /N=(dimsize(inputwave,2)) $EDCName
	Wave EDC = $EDCName
	
	 String EfIndexName=NameofWave(InputWave)+"EfIndex"
	 Make /O /N=(dimsize(inputwave,0),dimsize(inputwave,1)) $EfIndexName
	 Wave EfIndex=$EfIndexName
	 
	 String EfScaleName=NameofWave(InputWave)+"EfScale"
	 Make /O /N=(dimsize(inputwave,0),dimsize(inputwave,1)) $EfScaleName
	 Wave EfScale=$EfScaleName
	 
	 setscale /p x, dimoffset(inputwave,0),dimdelta(inputwave,0),efindex
	 setscale /p y, dimoffset(inputwave,1),dimdelta(inputwave,1),efindex
	 
	String TempEfValueWaveName = "TempEf"
	Make /O /N=1 $TempEfValueWaveName
	Wave TempEfValue = $TempEfValueWaveName
	
	variable i,j
	
	for(i=0;i<dimsize(inputwave,0);i+=1)
	for(j=0;j<dimsize(inputwave,1);j+=1)
		EDC[]=InputWave[i][j][p]
		wavestats /q EDC
		If(v_sum>cutoffintensity)
			smoothderivoutput(EDC,TempefValue,SmoothRange,SmoothTimes,EfMinPt,EfMaxPt)
			EfIndex[i][j]=TempEfValue[0]
			EfScale[i][j]=indextoscale(inputwave,TempEfValue[0],2)
		Else
			EfIndex[i][j]=NaN
			EfScale[i][j]=NaN
		EndIf
	endfor
	endfor
	
	String FitEfIndexName="fit_"+EfIndexName
	duplicate /o /s EFIndex $FitEfIndexName
	Wave FitEfIndex = $FitEfIndexName
	
	String FitEfScaleName="fit_"+EfScaleName
	duplicate /o /s EFScale $FitEfScaleName
	Wave FitEfScale = $FitEfScaleName

	Make/D/N=16/O W_coef
	W_coef[0] = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
	FuncFitMD/NTHR=0 TwoDThirdOrder W_coef EfIndex /D=$FitEfIndexName
	
	variable fermiMax=WaveMax(FitEfIndex)
	variable fermiMin=WaveMin(FitEfIndex)
	Variable extra = trunc(fermiMax-fermiMin)+2
	
	String photDepShiftStr = NameofWave(OutputWave)
	Make /O/N=(DimSize(Inputwave,0),Dimsize(inputwave,1),DimSize(Inputwave,2)+extra) $photDepShiftStr
   Wave photDepShift = $photDepShiftStr
   setscale /p x, dimoffset(inputwave,0),dimdelta(inputwave,0),photdepshift
   setscale /p y, dimoffset(inputwave,1),dimdelta(inputwave,1),photdepshift
   setscale /p z, -(fermimax+1)*dimdelta(inputwave,2),dimdelta(inputwave,2),photdepshift
	
	FitEfScale[][]=dimoffset(inputwave,2)+FitEfIndex[p][q]*dimdelta(inputwave,2)

   variable NanFermi
   wavestats /q FitEfScale
   NanFermi=v_avg
   
   for(i=0;i<dimsize(inputwave,0);i+=1)
   for(j=0;j<dimsize(inputwave,1);j+=1)
   	if(numtype(fitefScale[i][j])==2)
   		fitefScale[i][j]=NanFermi
		endif
	endfor
	endfor

	photDepShift[][][]=Interp3d(inputwave,indextoscale(inputwave,p,0),indextoscale(inputwave,q,1),z+FitEfScale[p][q])

	MakeNoise()	
End









////////////////////////////////////////////////////////////////////////

//Example: smoothderivoutput3d(tmfs1_norm_0,thetest,0.1,3,5,685,830)
//
//Instructions:
//1. Make an outputwave. The dimensions don't have to match, just make a wave with the desired name.
//2. Cutoffpercentage take edcs whos total intensity is less that cutoffpercentage of the average and sets the Fermi level the average Fermi level. Should only apply to the border regions.
//3. Play with SmoothRange and SmoothTimes if problems.
//4. Identify the max and minimum points the Fermi level could be (EfMinPt, EfMaxPt) to eliminate effects from strong deep bands.
//
////////////////////////////////////////////////////////////////////////


//dim0 is scanning angle
//dim1 is analyzer angle
//dim2 is binding energy

Function SmoothDerivOutput3D_v1(InputWave,OutputWave,CutOffPercentage,SmoothRange, SmoothTimes,EfMinPt,EfMaxPt)
	Wave InputWave
	Wave OutputWave
	Variable CutOffPercentage
	Variable SmoothRange
	Variable SmoothTimes
	Variable EfMinPt
	Variable EfMaxPt
	
	variable v_sum
	wavestats /q InputWave
	Variable CutOffIntensity=v_sum/(dimsize(inputwave,0)*dimsize(inputwave,1))*CutOffPercentage
	
	String EDCName = "SingleEDC"
	Make /O /N=(dimsize(inputwave,2)) $EDCName
	Wave EDC = $EDCName
	
	 String EfIndexName=NameofWave(InputWave)+"EfIndex"
	 Make /O /N=(dimsize(inputwave,0),dimsize(inputwave,1)) $EfIndexName
	 Wave EfIndex=$EfIndexName
	 
	 setscale /p x, dimoffset(inputwave,0),dimdelta(inputwave,0),efindex
	 setscale /p y, dimoffset(inputwave,1),dimdelta(inputwave,1),efindex
	 
	String TempEfValueWaveName = "TempEf"
	Make /O /N=1 $TempEfValueWaveName
	Wave TempEfValue = $TempEfValueWaveName
	
	variable i,j
	
	for(i=0;i<dimsize(inputwave,0);i+=1)
	for(j=0;j<dimsize(inputwave,1);j+=1)
		EDC[]=InputWave[i][j][p]
		wavestats /q EDC
		If(v_sum>cutoffintensity)
			smoothderivoutput(EDC,TempefValue,SmoothRange,SmoothTimes,EfMinPt,EfMaxPt)
			EfIndex[i][j]=TempEfValue[0]
		Else
			EfIndex[i][j]=NaN
		EndIf
	endfor
	endfor
	
	String FitEfIndexName="fit_"+EfIndexName
	duplicate /o /s EFIndex $FitEfIndexName
	Wave FitEfIndex = $FitEfIndexName
	
	Make/D/N=9/O W_coef
	W_coef[0] = {1,1,1,1,1,1,1,1,1}
	FuncFitMD/NTHR=0 TwoDQaud W_coef EfIndex /D=$FitEfIndexName
	
	variable fermiMax=round(WaveMax(FitEfIndex))
	variable fermiMin=round(WaveMin(FitEfIndex))
	Variable extra = fermiMax-fermiMin
	
	String photDepShiftStr = NameofWave(OutputWave)
	Make /O/N=(DimSize(Inputwave,0),Dimsize(inputwave,1),DimSize(Inputwave,2)+extra) $photDepShiftStr
   Wave photDepShift = $photDepShiftStr
   setscale /p x, dimoffset(inputwave,0),dimdelta(inputwave,0),photdepshift
   setscale /p y, dimoffset(inputwave,1),dimdelta(inputwave,1),photdepshift
   setscale /p z, -fermimax*dimdelta(inputwave,2),dimdelta(inputwave,2),photdepshift
       
   variable fermi, start, NanFermi
   wavestats /q FitEfIndex
   NanFermi=v_avg
       
   for(i=0;i<dimsize(inputwave,0);i+=1)
   for(j=0;j<dimsize(inputwave,1);j+=1)
   	if(numtype(fitefindex[i][j])==2)
   		fermi=NanFermi
   	else
			fermi=fitefindex[i][j]
		endif
		start=round(fermimax-fermi)
		if(start<0)
			print "start is less than zero"
		endif
		if(start+dimsize(inputwave,2)-1>dimsize(photdepshift,2)-1)
			print "trouble in middle region"
			print start
			print dimsize(inputwave,2)
			print dimsize(photdepshift,2)
			print fermi
			print fermimin
			return(0)
		endif
		photDepShift[i][j][,start] = InputWave[i][j][0]
		photDepShift[i][j][start,start+DimSize(Inputwave,2)-1] = InputWave[i][j][r-start]
		photDepShift[i][j][start+DimSize(inputwave,2)-1,] = InputWave[i][j][DimSize(InputWave,2)-1]
	endfor
	endfor
	//MakeNoise()	
End

//dim0 is analyzer angle
//dim1 is binding energy
Function SmoothDerivOutput2D(InputCut,OutputCut,CutOffPercentage,SmoothRange,SmoothTimes,EfMinPt,EfMaxPt)
	Wave InputCut
	Wave OutputCut
	variable CutOffPercentage
	Variable SmoothRange
	Variable SmoothTimes
	Variable EfMinPt
	Variable EFMaxPt
	
	variable v_sum
	wavestats /q InputCut
	Variable CutOffIntensity=v_sum/dimsize(inputcut,0)*CutOffPercentage
	
	String EDCName = "SingleEDC"
	Make /O /N=(dimsize(inputcut,1)) $EDCName
	Wave EDC = $EDCName
	
	String EfIndexName = NameofWave(InputCut)+"_EfIndex"
	Make /O /N = (dimsize(inputcut, 0)) $EFIndexname
	Wave EfIndex = $EfIndexName
	
	setscale /p x, dimoffset(inputcut,0),dimdelta(inputcut,0), EfIndex
	
	String TempEfValueWaveName = "TempEf"
	Make /O /N=1 $TempEfValueWaveName
	Wave TempEfValue = $TempEfValueWaveName
	
	variable i
	
	for(i=0;i<dimsize(inputcut,0);i+=1)
		EDC[]=inputcut[i][p]
		wavestats /q EDC
		If(v_sum>CutOffIntensity)
			SmoothDerivOutput(EDC, TempEfValue,SmoothRange,SmoothTimes,EfMinPt,EfMaxPt)
			EfIndex[i]=TempEfValue[0]
		Else
			EfIndex[i]=NaN
		EndIf
	endfor
	
	variable fermiMax=WaveMax(EfIndex)
	variable fermiMin=WaveMin(EfIndex)
	Variable extra = fermiMax-fermiMin
	
	String photDepShiftStr = NameofWave(OutputCut)
	Make /O/N=(DimSize(InputCut,0),DimSize(InputCut,1)+extra) $photDepShiftStr
       Wave photDepShift = $photDepShiftStr
       setscale /p x, dimdelta(Inputcut,0),dimdelta(inputcut,0),photDepShift
     	SetScale /P y, -DimDelta(InputCut,1)*fermiMax, DimDelta(InputCut,1), photDepShift
     	
     	variable fermi, start
     	
     	for (i = 0; i < DimSize(InputCut,0); i += 1)
     		If(numtype(EfIndex[i])==2)
     			wavestats /q efindex
     			fermi=v_avg
     		Else
     			fermi = EfIndex[i]
     		EndIf
                start = fermiMax - fermi
                photDepShift[i][,start] = InputCut[i][0]
                photDepShift[i][start,start+DimSize(InputCut,1)-1] = InputCut[i][q-start]
                photDepShift[i][start+DimSize(InputCut,1)-1,] = InputCut[i][DimSize(InputCut,1)-1]
        endfor
	
End

Function SmoothDerivOutput(InputEDC,Result,SmoothRange,SmoothTimes,EfMinPt,EfMaxPt)

	wave inputEDC
	wave result //This will be the kinetic energy that corresponds to minimum derivative.
	variable SmoothRange
	Variable SmoothTimes
	Variable EfMinPt
	Variable EfMAxPt
	
	String SmoothInputWaveName = "swave"
	Duplicate /O InputEDC $SmoothInputWaveName
	wave SmoothInputWave = $SmoothInputWaveName
	
	variable i
	for(i=0;i<SmoothTimes;i+=1)
		Smooth SmoothRange, SmoothInputWave
	endfor
	
	String DiffWaveName = "dwave"
	Differentiate SmoothInputWave /D=$DiffWaveName
	Wave DiffWave = $DiffWaveName
	
	String EDCpartname = "windowEDC"
	make /o /n=(EfMaxPt-EfMinPt+1) $EDCpartname
	wave EDCpart = $EDCpartname
	EDCpart[]=DiffWave[EfMinPt+p]
	
	variable v_minloc
	wavestats /q $EDCpartname
	
	Result[0] = v_minloc+EfMinPt
	
End

Function TwoDQaud(w,x,y) : FitFunc
	Wave w
	Variable x
	Variable y

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x,y) = C1+C2*y+C3*y^2+C4*x+C5*x*y+C6*x*y^2+C7*x^2+C8*x^2*y+C9*x^2*y^2
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 2
	//CurveFitDialog/ x
	//CurveFitDialog/ y
	//CurveFitDialog/ Coefficients 9
	//CurveFitDialog/ w[0] = C1
	//CurveFitDialog/ w[1] = C2
	//CurveFitDialog/ w[2] = C3
	//CurveFitDialog/ w[3] = C4
	//CurveFitDialog/ w[4] = C5
	//CurveFitDialog/ w[5] = C6
	//CurveFitDialog/ w[6] = C7
	//CurveFitDialog/ w[7] = C8
	//CurveFitDialog/ w[8] = C9

	return w[0]+w[1]*y+w[2]*y^2+w[3]*x+w[4]*x*y+w[5]*x*y^2+w[6]*x^2+w[7]*x^2*y+w[8]*x^2*y^2
End

Function TwoDThirdOrder(w,x,y) : FitFunc
	Wave w
	Variable x
	Variable y

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x,y) = C1+C2*y+C3*y^2+C4*y3+C5*x+C6*x*y+C7*x*y^2+C8*x*y^3+C9*x^2+C10*x^2*y+C11*x^2*y^2+C12*x^2*y^3+C13*x^3+C14*x^3*y+C15*x^3*y^2+C16*x^2*y^3
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 2
	//CurveFitDialog/ x
	//CurveFitDialog/ y
	//CurveFitDialog/ Coefficients 9
	//CurveFitDialog/ w[0] = C1
	//CurveFitDialog/ w[1] = C2
	//CurveFitDialog/ w[2] = C3
	//CurveFitDialog/ w[3] = C4
	//CurveFitDialog/ w[4] = C5
	//CurveFitDialog/ w[5] = C6
	//CurveFitDialog/ w[6] = C7
	//CurveFitDialog/ w[7] = C8
	//CurveFitDialog/ w[8] = C9
	//CurveFitDialog/ w[9] = C10
	//CurveFitDialog/ w[10] = C11
	//CurveFitDialog/ w[11] = C12
	//CurveFitDialog/ w[12] = C13
	//CurveFitDialog/ w[13] = C14
	//CurveFitDialog/ w[14] = C15
	//CurveFitDialog/ w[15] = C16

	return w[0]+w[1]*y+w[2]*y^2+w[3]*y^3+w[4]*x+w[5]*x*y+w[6]*x*y^2+w[7]*x*y^3+w[8]*x^2+w[9]*x^2*y+w[10]*x^2*y^2+w[11]*x^2*y^3+w[12]*x^3+w[13]*x^3*y+w[14]*x^3*y^2+w[15]*x^3*y^3
End

//dim0 is scanning angle
//dim1 is analyzer angle
//dim2 is binding energy

// 20200909.TAC.v2 has EfMinPtScanStart and EfMinPtScanEnd as input parameters instead.
//						gives a linear shift in the lowest possible Ef value.
//						to offset low bring bands.

//Example: smoothderivoutput3d_v2(fs1t210,FS1FL,0.1,3,5,410,360,450)

Function SmoothDerivOutput3D_v2(InputWave,OutputWave,CutOffPercentage,SmoothRange, SmoothTimes,EfMinPtScanStart,EfMinPtScanEnd,EfMaxPt)
	Wave InputWave
	Wave OutputWave
	Variable CutOffPercentage
	Variable SmoothRange
	Variable SmoothTimes
	Variable EfMinPtScanStart //Lowest possible value of Fermi level along any EDC within the cut at the FIRST scanning angle.
	Variable EfMinPtScanEnd//Lowest possible value of the Fermi level along any EDC within the cut at the LAST scanning angle.
	Variable EfMaxPt
	
	Variable EfMinPt
	
	variable v_sum
	wavestats /q InputWave
	Variable CutOffIntensity=v_sum/(dimsize(inputwave,0)*dimsize(inputwave,1))*CutOffPercentage
	
	String EDCName = "SingleEDC"
	Make /O /N=(dimsize(inputwave,2)) $EDCName
	Wave EDC = $EDCName
	
	 String EfIndexName=NameofWave(InputWave)+"EfIndex"
	 Make /O /N=(dimsize(inputwave,0),dimsize(inputwave,1)) $EfIndexName
	 Wave EfIndex=$EfIndexName
	 
	 setscale /p x, dimoffset(inputwave,0),dimdelta(inputwave,0),efindex
	 setscale /p y, dimoffset(inputwave,1),dimdelta(inputwave,1),efindex
	 
	String TempEfValueWaveName = "TempEf"
	Make /O /N=1 $TempEfValueWaveName
	Wave TempEfValue = $TempEfValueWaveName
	
	variable i,j
	
	for(i=0;i<dimsize(inputwave,0);i+=1)
	for(j=0;j<dimsize(inputwave,1);j+=1)
		EDC[]=InputWave[i][j][p]
		wavestats /q EDC
		If(v_sum>cutoffintensity)
			EfMinpt=EfMinPtScanStart*(dimsize(inputwave,0)-i)/dimsize(inputwave,0)+EfMinPtScanEnd*(i)/dimsize(inputwave,0)
			smoothderivoutput(EDC,TempefValue,SmoothRange,SmoothTimes,EfMinPt,EfMaxPt)
			EfIndex[i][j]=TempEfValue[0]
		Else
			EfIndex[i][j]=NaN
		EndIf
	endfor
	endfor
	
	String FitEfIndexName="fit_"+EfIndexName
	duplicate /o /s EFIndex $FitEfIndexName
	Wave FitEfIndex = $FitEfIndexName
	
	Make/D/N=9/O W_coef
	W_coef[0] = {1,1,1,1,1,1,1,1,1}
	FuncFitMD/NTHR=0 TwoDQaud W_coef EfIndex /D=$FitEfIndexName
	
	variable fermiMax=round(WaveMax(FitEfIndex))
	variable fermiMin=round(WaveMin(FitEfIndex))
	Variable extra = fermiMax-fermiMin
	
	String photDepShiftStr = NameofWave(OutputWave)
	Make /O/N=(DimSize(Inputwave,0),Dimsize(inputwave,1),DimSize(Inputwave,2)+extra) $photDepShiftStr
       Wave photDepShift = $photDepShiftStr
       setscale /p x, dimoffset(inputwave,0),dimdelta(inputwave,0),photdepshift
       setscale /p y, dimoffset(inputwave,1),dimdelta(inputwave,1),photdepshift
       setscale /p z, -fermimax*dimdelta(inputwave,2),dimdelta(inputwave,2),photdepshift
       
       variable fermi, start
       
       for(i=0;i<dimsize(inputwave,0);i+=1)
       for(j=0;j<dimsize(inputwave,1);j+=1)
       	if(numtype(fitefindex[i][j])==2)
     			wavestats /q fitefindex
     			fermi=v_avg
            	else
       		fermi=fitefindex[i][j]
       	endif
       	start=round(fermimax-fermi)
       	if(start<0)
       		print "start is less than zero"
       	endif
       	if(start+dimsize(inputwave,2)-1>dimsize(photdepshift,2)-1)
       		print "troube in middle region"
       		print start
       		print dimsize(inputwave,2)
       		print dimsize(photdepshift,2)
       		print fermi
       		print fermimin
       		return(0)
       	endif
       	photDepShift[i][j][,start] = InputWave[i][j][0]
       	photDepShift[i][j][start,start+DimSize(Inputwave,2)-1] = InputWave[i][j][r-start]
      		photDepShift[i][j][start+DimSize(inputwave,2)-1,] = InputWave[i][j][DimSize(InputWave,2)-1]
       endfor
       endfor
		
End