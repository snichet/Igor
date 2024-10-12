#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//Dimension 0 is binding energy
//Dimension 1 is analyzer angle

Function LowPassFilterCut(InputWave,EbFreq,EbWidth,AAFreq,AAWidth)
	Wave InputWave
	Variable EbFreq
	Variable EbWidth
	Variable AAFreq
	Variable AAWidth
	
	Variable EbDim = dimsize(inputwave,0)
	Variable AADim = dimsize(inputwave,1)
	
	Variable i=0
	Variable a=0
	
	String OutputWaveName
	String TestName
	
	Do
		OutputWaveName = NameofWave(Inputwave)+"_LP"+num2str(i)
		i+=1
		a=exists(OutputWaveName)
	While(a==1)
	
	Duplicate inputwave $OutputWaveName
	Wave Outputwave = $OutputwaveName
	Make/O/D/N=0 coefs
	Wave coefs
	FilterFIR/DIM=0/LO={EbFreq-EbWidth,EbFreq+EbWidth,EbDim}/COEF coefs,OutputWave
	FilterFIR/DIM=1/LO={AAFreq-AAWidth,AAFreq+AAWidth,AADim}/COEF coefs,OutputWave
	
	Note Outputwave, " "
	Note OutputWave, "Low Pass Filtered"
	Note OutputWave, "EBFreq="+num2str(EbFreq)
	Note OutputWave, "EBWidth="+num2str(EbWidth)
	Note OutputWave, "EBDim="+num2str(EbDim)
	Note OutputWave, "AAFreq="+num2str(AAFreq)
	Note OutputWave, "AAWidth="+num2str(AAWidth)
	Note OutputWave, "AADim="+num2str(AADim)
	Note OutputWave, " "
	
	Print Nameofwave(InputWave) + " filtered. Output wave is " +Outputwavename
 
	
End

//Dim 0 is binding energy
//Dim1 is analyzer angle
//Dim 2 is scanning dimension

Function LowPassFilterCube(Inputwave,EbFreq,EbWidth,AAFreq,AAWidth,SDFreq,SDWidth)

	Wave InputWave
	Variable EbFreq
	Variable EbWidth
	//Variable EbDim
	Variable AAFreq
	Variable AAWidth
	//Variable AADim
	Variable SDFreq
	Variable SDWidth
	//Variable SDDim
	
	Variable EbDim = dimsize(inputwave,0)
	Variable AADim = dimsize(inputwave,1)
	Variable SDDim = dimsize(inputwave,2)
	
	Variable i=0
	Variable a=0
	
	String OutputWaveName
	String TestName
	
	Do
		OutputWaveName = NameofWave(Inputwave)+"_LP"+num2str(i)
		i+=1
		a=exists(OutputWaveName)
	While(a==1)
	
	Duplicate inputwave $OutputWaveName
	Wave Outputwave = $OutputwaveName
	Make/O/D/N=0 coefs

	Wave coefs
	FilterFIR/DIM=0/LO={EbFreq-EbWidth,EbFreq+EbWidth,EbDim}/COEF coefs,OutputWave
	FilterFIR/DIM=1/LO={AAFreq-AAWidth,AAFreq+AAWidth,AADim}/COEF coefs,OutputWave
	FilterFIR/DIM=2/LO={SDFreq-SDWidth,SDFreq+SDWidth,SDDim}/COEF coefs,OutputWave
	
	Note Outputwave, " "
	Note OutputWave, "Low Pass Filtered"
	Note OutputWave, "EBFreq="+num2str(EbFreq)
	Note OutputWave, "EBWidth="+num2str(EbWidth)
	Note OutputWave, "EBDim="+num2str(EbDim)
	Note OutputWave, "AAFreq="+num2str(AAFreq)
	Note OutputWave, "AAWidth="+num2str(AAWidth)
	Note OutputWave, "AADim="+num2str(AADim)
	Note OutputWave, "SDFreq="+num2str(SDFreq)
	Note OutputWave, "SDWidth="+num2str(SDWidth)
	Note OutputWave, "SDDim="+num2str(SDDim)
	Note OutputWave, " "
	
	Print Nameofwave(InputWave) + " filtered. Output wave is " +Outputwavename

End

//Dim 0 is binding energy
//Dim1 is analyzer angle
//Dim 2 is scanning dimension

Function LowHighPassFilterCube(Inputwave,EbFreqLow,EbWidthLow,EbFreqHigh,EbWidthHigh,AAFreqLow,AAWidthLow,AAFreqHigh,AAWidthHigh,SDFreqLow,SDWidthLow,SDFreqHigh,SDWidthHigh)

	Wave InputWave
	Variable EbFreqLow
	Variable EbWidthLow
	Variable EbFreqHigh
	Variable EbWidthHigh
	Variable AAFreqLow
	Variable AAWidthLow
	Variable AAFreqHigh
	Variable AAWidthHigh
	VAriable SDFreqLow
	Variable SDWidthLow
	Variable SDFreqHigh
	Variable SDWidthHigh
	
	Variable EbDim = dimsize(inputwave,0)/2
	Variable AADim = dimsize(inputwave,1)/2
	Variable SDDim = dimsize(inputwave,2)/2
	
	Variable i=0
	Variable a=0
	
	String OutputWaveName
	String TestName
	
	Do
		OutputWaveName = NameofWave(Inputwave)+"_LHP"+num2str(i)
		i+=1
		a=exists(OutputWaveName)
	While(a==1)
	
	Duplicate inputwave $OutputWaveName
	Wave Outputwave = $OutputwaveName
	Make/O/D/N=0 coefs
	Wave coefs
	FilterFIR/DIM=0/HI={EbFreqLow-EbWidthLow,EbFreqLow+EbWidthLow,EbDim}/LO={EbFreqHigh-EbWidthHigh,EbFreqHigh+EbWidthHigh,EbDim}/COEF coefs,OutputWave
	FilterFIR/DIM=1/HI={AAFreqLow-AAWidthLow,AAFreqLow+AAWidthLow,AADim}/Lo={AAFreqHigh-AAWidthHigh,AAFreqHigh+AAWidthHigh,AADim}/COEF coefs,OutputWave
	FilterFIR/DIM=2/HI={SDFreqLow-SDWidthLow,SDFreqLow+SDWidthLow,SDDim}/LO={SDFreqHigh-SDWidthHigh,SDFreqHigh+SDWidthHigh,SDDim}/COEF coefs,OutputWave
	
	Note Outputwave, " "
	Note OutputWave, "Low/High Pass Filtered"
	Note OutputWave, "EBFreqLow="+num2str(EbFreqLow)
	Note OutputWave, "EBWidthLow="+num2str(EbWidthLow)
	Note OutputWave, "EBFreqHigh="+num2str(EbFreqHigh)
	Note OutputWave, "EBWidthHigh="+num2str(EbWidthHigh)
	Note OutputWave, "EBDim="+num2str(EbDim)
	Note OutputWave, "AAFreqLow="+num2str(AAFreqLow)
	Note OutputWave, "AAWidthLow="+num2str(AAWidthLow)
	Note OutputWave, "AAFreqHigh="+num2str(AAFreqHigh)
	Note OutputWave, "AAWidthHigh="+num2str(AAWidthHigh)
	Note OutputWave, "AADim="+num2str(AADim)
	Note OutputWave, "SDFreqLow="+num2str(SDFreqLow)
	Note OutputWave, "SDWidthLow="+num2str(SDWidthLow)
	Note OutputWave, "SDFreqHigh="+num2str(SDFreqHigh)
	Note OutputWave, "SDWidthHigh="+num2str(SDWidthHigh)
	Note OutputWave, "SDDim="+num2str(SDDim)
	Note OutputWave, " "

	Print Nameofwave(InputWave) + " filtered. Output wave is " +Outputwavename

End

//Dimension 0 is binding energy
//Dimension 1 is analyzer angle

Function NotchFilterCut(InputWave,EbFreq,EbWidth,AAFreq,AAWidth)
	Wave InputWave
	Variable EbFreq
	Variable EbWidth
	Variable AAFreq
	Variable AAWidth
	
	Variable EbDim = dimsize(inputwave,0)
	Variable AADim = dimsize(inputwave,1)
	
	Variable i=0
	Variable a=0
	
	String OutputWaveName
	String TestName
	
	Do
		OutputWaveName = NameofWave(Inputwave)+"_LP"+num2str(i)
		i+=1
		a=exists(OutputWaveName)
	While(a==1)
	
	Duplicate inputwave $OutputWaveName
	Wave Outputwave = $OutputwaveName
	Make/O/D/N=0 coefs
	Wave coefs
	FilterFIR/DIM=0/LO={EbFreq-EbWidth,EbFreq+EbWidth,EbDim}/COEF coefs,OutputWave
	FilterFIR/DIM=1/LO={AAFreq-AAWidth,AAFreq+AAWidth,AADim}/COEF coefs,OutputWave
	
	Note Outputwave, " "
	Note OutputWave, "Low Pass Filtered"
	Note OutputWave, "EBFreq="+num2str(EbFreq)
	Note OutputWave, "EBWidth="+num2str(EbWidth)
	Note OutputWave, "EBDim="+num2str(EbDim)
	Note OutputWave, "AAFreq="+num2str(AAFreq)
	Note OutputWave, "AAWidth="+num2str(AAWidth)
	Note OutputWave, "AADim="+num2str(AADim)
	Note OutputWave, " "
	
	Print Nameofwave(InputWave) + " filtered. Output wave is " +Outputwavename
 
	
End