
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function TransposeCube(inputwave,Dim0GoesTo,Dim1GoesTo,Dim2GoesTo)
	Wave InputWave
	Variable Dim0GoesTo
	Variable Dim1GoesTo
	Variable Dim2GoesTo
	
	String OutputWaveName
	
	If(Dim0GoesTo==0)
		If(Dim1GoesTo==1)//012
			print "TransposeCube In Need of Development"
		Else//021
			
			OutputWaveName = NameOfWave(InputWave)+"t021"
			Make /N=(dimsize(inputwave,0),dimsize(inputwave,2),dimsize(inputwave,1)) $OutputWaveName
			Wave OutputWave = $OutputWaveName
			OutputWave[][][]=InputWave[p][r][q]
			setscale /p x, dimoffset(inputwave,0),dimdelta(inputwave,0),OutputWave
			setscale /p y, dimoffset(inputwave,2),dimdelta(inputwave,2),OutputWave
			setscale /p z, dimoffset(inputwave,1),dimdelta(inputwave,1),Outputwave
			print "Output wave name: " + Outputwavename
		EndIf
	Else
		If(Dim0GoesTo==1)
			If(Dim1GoesTo==0)//102
				
				OutputWaveName = NameOfWave(InputWave)+"t102"
				Make /s /N=(dimsize(inputwave,1),dimsize(inputwave,0),dimsize(inputwave,2)) $OutputWaveName
				Wave Outputwave=$outputwavename
				Outputwave[][][]=Inputwave[q][p][r]
				setscale /p x, dimoffset(inputwave,1),dimdelta(inputwave,1),OutputWave
				setscale /p y, dimoffset(inputwave,0),dimdelta(inputwave,0),outputwave
				setscale /p z, dimoffset(inputwave,2),dimdelta(inputwave,2),outputwave
				print "Output wave name: " + Outputwavename
			Else //120
				
				OutputWaveName=nameofwave(inputwave)+"t120"
				Make /o /n=(dimsize(inputwave,2),dimsize(inputwave,0),dimsize(inputwave,1)) $OutputWaveName
				Wave OutputWave = $OutputWaveName
				OutputWave[][][]=InputWave[q][r][p]
				setscale /p x, dimoffset(inputwave,2),dimdelta(inputwave,2),outputwave
				setscale /p y, dimoffset(inputwave,0),dimdelta(inputwave,0),outputwave
				setscale /p z, dimoffset(inputwave,1),dimdelta(inputwave,1),outputwave
				print "Output wave name: " + Outputwavename
			EndIf
		Else
			If(Dim1GoesTo==0) //201
				
				OutputWaveName = NameofWave(InputWave)+"t201"
				Make /o /n=(dimsize(inputwave,1),dimsize(inputwave,2),dimsize(inputwave,0)) $OutputWaveName
				Wave OutputWave = $OutputWaveName
				OutputWave[][][]=InputWave[r][p][q]
				setscale/p x, dimoffset(inputwave,1),dimdelta(inputwave,1),outputwave
				setscale /p y, dimoffset(inputwave,2),dimdelta(inputwave,2),outputwave
				setscale /p z, dimoffset(inputwave,0),dimdelta(inputwave,0),outputwave
				print "Output wave name: " + Outputwavename
			Else //210
				
				OutputWaveName = NameOfWave(InputWave)+"t210"
				Make /o /N=(dimsize(inputwave,2),dimsize(inputwave,1),dimsize(inputwave,0)) $OutputWaveName
				Wave OutputWave = $OutputWaveName
				OutputWave[][][]=InputWave[r][q][p]
				setscale /p x, dimoffset(inputwave,2),dimdelta(inputwave,2),OutputWave
				setscale /p y, dimoffset(inputwave,1),dimdelta(inputwave,1),OutputWave
				setscale /p z, dimoffset(inputwave,0),dimdelta(inputwave,0),Outputwave
				print "Output wave name: " + Outputwavename
			EndIf
		EndIf
		
	EndIf
End

Function TransposeSquare(Inputwave)

	wave inputwave
	
	string outputwavename=nameofwave(inputwave)+"t10"
	make /n=(dimsize(inputwave,1),dimsize(inputwave,0)) $outputwavename
	wave OutputWave = $outputwavename
	
	Outputwave[][]=inputwave[q][p]
	
	setscale /p x, dimoffset(inputwave,1),dimdelta(inputwave,1),outputwave
	setscale /p y, dimoffset(inputwave,0),dimdelta(inputwave,0),outputwave
	
end