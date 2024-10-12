#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function SmoothCutY(InputWaveName,TimesSmoothed,BoxWidth)

	String InputWaveName
	Variable timessmoothed
	variable boxwidth
	
	Wave InputWave = $InputWaveName
	
	String OutputWaveName = InputWaveName +"_SmthY"
	
	Duplicate/O  InputWave $OutputWaveName
	
	Wave OutputWave = $OutputWaveName
	
	OutputWave = 0
	
	make /o /n=(dimsize(InputWave,1)) temp
	
	Wave temp
	
	variable i,j
	
	For(i=0;i<dimsize(inputwave,0);i+=1)
		
		temp[]=InputWave[i][p]
			
		For(j=0;j<TimesSmoothed;j+=1)
			Smooth/EVEN/B BoxWidth, temp
		EndFor
		
		OutputWave[i][]=temp[q]
		
	Endfor
	
	Killwaves temp
	
	//display
	//appendimage inputwave
	
	//display
	//appendimage outputwave
	
End

Function SmoothCutX(InputWaveName,TimesSmoothed,BoxWidth)

	String InputWaveName
	Variable timessmoothed
	variable boxwidth
	
	Wave InputWave = $InputWaveName
	
	String OutputWaveName = InputWaveName +"_SmthX"
	
	Duplicate/O  InputWave $OutputWaveName
	
	Wave OutputWave = $OutputWaveName
	
	OutputWave = 0
	
	make /o /n=(dimsize(InputWave,0)) temp
	
	Wave temp
	
	variable i,j
	
	For(i=0;i<dimsize(inputwave,1);i+=1)
		
		temp[]=InputWave[p][i]
			
		For(j=0;j<TimesSmoothed;j+=1)
			Smooth/EVEN/B BoxWidth, temp
		EndFor
		
		OutputWave[][i]=temp[p]
		
	Endfor
	
	Killwaves temp
	
	//display
	//appendimage inputwave
	
	//display
	//appendimage outputwave
	
End

Function SmoothWave(InputWave,TimesSmoothed,BoxWidth)
	
	Wave InputWave
	Variable timessmoothed
	variable boxwidth
	
	String OutputWaveName = NameofWave(InputWave) +"_Smth" + num2str(TimesSmoothed)+"_"+num2str(BoxWidth)
	
	Duplicate/O  InputWave $OutputWaveName
	
	Wave OutputWave = $OutputWaveName
		
	variable i
	
	For(i=0;i<TimesSmoothed;i+=1)
		Smooth/B BoxWidth, OutputWave
	EndFor
	
	AppendtoGraph OutputWave

End