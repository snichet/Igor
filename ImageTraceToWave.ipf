#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function ImageTraceToWave(inputimage,outputwave)
	wave Inputimage
	wave OutputWave
	
	make /d/n=(dimsize(inputimage,1)) temp
	setscale /p x, dimoffset(inputimage,1),dimdelta(inputimage,1),temp
	
	variable i
	
	for(i=0;i<dimsize(inputimage,0);i+=1)
		temp[]=inputimage[i][p]
		findpeak /q /n /m=100 temp
		Outputwave[i]=V_PeakLoc
	endfor
	
End