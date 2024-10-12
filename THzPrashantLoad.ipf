#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function LoadPrashant(OutputbaseName,ScanNum,FirstIteration,LastIteration,Polarimetry,WindowBaseName)

	String OutputbaseName
	Variable ScanNum
	Variable FirstIteration
	Variable LastIteration
	Variable Polarimetry
	String WindowBaseName
	
	string pathname
	string namestring
	string NameTest
	string NameTest1
	wave tempwave

	string s_path
	newpath folderpath  //choose folder
	pathinfo folderpath
	print s_path
	
	variable i
	for(i=firstiteration;i<=lastiteration;i+=1)
		print "i = "+num2str(i)
		PathName = s_path +"Scan"+Num2Str(ScanNum)+"-"+num2str(i)
		print pathname

		Nametest = outputbasename+"_td"+num2str(i)
		If(exists(Nametest)==1)
			killwaves $nametest
		endif
		Nametest = outputbasename+"_xd"+num2str(i)
		If(exists(Nametest)==1)
			killwaves $nametest
		endif
		Nametest = outputbasename+"_yd"+num2str(i)
		If(exists(Nametest)==1)
			killwaves $nametest
		endif
		namestring = "N=" + outputbasename +"_td" + num2str(i)+";N=" + outputbasename + "_xd" + num2str(i)+";N="+outputbasename+"_yd" + num2str(i)+";"
		print namestring
		LoadWave /J /D /K=0 /A /B=namestring PathName
		
		NameTest=outputbasename+"_td"+num2str(i)
		NameTest1 = outputbasename+"_xd"+num2str(i)
		wave tempwave = $NameTest
		setscale /p x, 0, -(1-2*Polarimetry)*(tempwave[dimsize(tempwave,0)-1]-tempwave[0])/(dimsize(tempwave,0)-1),$NameTest1
		
		NameTest=outputbasename+"_td"+num2str(i)
		NameTest1 = outputbasename+"_yd"+num2str(i)
		wave tempwave = $NameTest
		setscale /p x, 0, -(1-2*Polarimetry)*(tempwave[dimsize(tempwave,0)-1]-tempwave[0])/(dimsize(tempwave,0)-1),$NameTest1
		
		Nametest = outputbasename+"_FFTx"+num2str(i)
		NameTest1=outputbasename+"_xd"+num2str(i)
		If(exists(Nametest)==1)
			killwaves $nametest
		endif
		
		FFT/OUT=4/PAD={256}/DEST=$NameTest $nametest1;DelayUpdate
		
		Nametest = outputbasename+"_FFTy"+num2str(i)
		NameTest1=outputbasename+"_yd"+num2str(i)
		If(exists(Nametest)==1)
			killwaves $nametest
		endif
		
		FFT/OUT=4/PAD={256}/DEST=$NameTest $nametest1;DelayUpdate
		
		NameTest=outputbasename+"_xd"+num2str(i)
		NameTest1=outputbasename+"_xAve"
		If(i==firstiteration)
			duplicate /o $NameTest $NameTest1
			wave xAve = $NameTest1
		Else
			wave tempwave = $nametest
			xAve[]=xAve[p]+ tempwave[p]
		EndIf
		
		NameTest=outputbasename+"_yd"+num2str(i)
		NameTest1=outputbasename+"_yAve"
		If(i==firstiteration)
			duplicate /o $NameTest $NameTest1
			wave yAve = $NameTest1
		Else
			wave tempwave = $nametest
			yAve[]=yAve[p]+ tempwave[p]
		EndIf
	endfor
	
	xAve/=(LastIteration-FirstIteration+1)
	yAve/=(LastIteration-FirstIteration+1)

	
	Nametest = outputbasename+"_xAveFFT"
	NameTest1=outputbasename+"_xAve"
	If(exists(Nametest)==1)
		killwaves $nametest
	endif
	
	FFT/OUT=4/PAD={256}/DEST=$NameTest $nametest1;DelayUpdate
	
	Wave xAveFFT = $NameTest
	
	Nametest = outputbasename+"_yAveFFT"
	NameTest1=outputbasename+"_yAve"
	If(exists(Nametest)==1)
		killwaves $nametest
	endif
	
	FFT/OUT=4/PAD={256}/DEST=$NameTest $nametest1;DelayUpdate
	
	Wave yAveFFT = $NameTest

	
	nametest = OutputBaseName+"xd"
	If(exists(Nametest)==1)
		killwaves $nametest
	endif
	nametest = OutputBaseName+"yd"
	If(exists(Nametest)==1)
		killwaves $nametest
	endif
	nametest = OutputBaseName+"FFTx"
	If(exists(Nametest)==1)
		killwaves $nametest
	endif
	nametest = OutputBaseName+"FFTy"
	If(exists(Nametest)==1)
		killwaves $nametest
	endif
	
	nametest = OutputBaseName+"xd"
	concatenate /np=1 wavelist(OutputbaseName+"_xd*",";",""), $nametest
	redimension /s $nametest
	nametest = outputbasename+"yd"
	concatenate /np=1 wavelist(OutputbaseName+"_yd*",";",""), $nametest
	redimension /s $nametest
	nametest = OutputBaseName+"FFTx"
	concatenate /np=1 wavelist(OutputbaseName+"_FFTx*",";",""), $nametest
	redimension /s $nametest
	nametest = outputbasename+"FFTy"
	concatenate /np=1 wavelist(OutputbaseName+"_FFTy*",";",""), $nametest
	redimension /s $nametest
	
	If(Polarimetry==0)
		String DelayWindowName = WindowBaseName+"_DelayScans"
		DoWindow /F DelayWindowName
		If(v_flag ==0)
			display
		endif
		
		appendtograph xave, yave
		modifygraph rgb(yave)=(0,0,0)
		
		String SpectrumWindowName = WindowBasename + "_THzSpectrum"
		DoWindow /F SpectrumWindowName
		If(v_flag ==0)
			display
		endif
		
		appendtograph xavefft, yavefft
		modifygraph rgb(yavefft)=(0,0,0)
		SetAxis bottom 0,5
	Else
		String PolarWindowName = WindowBasename+"_PolarScan"
		DoWindow /F PolarWindowName
		If(v_flag ==0)
			display
		endif
		
		appendtograph xave, yave
		modifygraph rgb(yave)=(0,0,0)
	EndIf
End