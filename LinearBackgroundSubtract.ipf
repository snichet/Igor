#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//dim0=angle
//dim1=binding energy

Function LinearBackgroundSub2D(InputWave,Point1,Point2)

	Wave InputWave
	Variable Point1
	Variable Point2
	
	String OutputWaveName = NameOfWave(InputWave)+"_LS"
	Duplicate /o InputWave $OutputWaveName
	Wave OutputWave = $OutputWaveName
	
	OutputWave = 0
	
	Make /o /n=(dimsize(inputwave,1)) temp
	wave test
	wave fit_temp
	
	Variable i,j
	
	For(i=0;i<dimsize(inputwave,0);i+=1)
		temp=0
		temp[]=Inputwave[i][p]
		
		CurveFit/L=688 /X=1/NTHR=0 line  temp[Point1,Point2] /D;
		
		For(j=0;j<dimsize(inputwave,1);j+=1)
			outputwave[i][j]=inputwave[i][j]-fit_temp[j]
		EndFor
		 
	EndFor
	
	killwaves temp

End