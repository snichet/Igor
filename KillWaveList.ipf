#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function KillWaveList(BaseName,First,Last)
	String BaseName
	Variable First
	Variable Last
	
	Variable i
	String Name
	
	For(i=First;i<=Last;i+=1)
		Name=BaseName+Num2Str(i)
		KillWaves $Name
	EndFor
End