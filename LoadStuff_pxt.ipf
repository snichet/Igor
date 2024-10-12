#pragma rtGlobals=1		// Use modern global access method.

//20181012 Cochran - Adapted from LoadStuff() that Ilya wrote for SSRL txt files

Function LoadStuffPxt()

////////////////////////////////////////////////////////////////////////////////////////////////////////

//First and Last File Number
Variable FirstFileNum = 105
Variable LastFileNum = 105

//File Base Name
String baseName = "FeSi3_"

//Name for New Igor Wave
String newnamebase = "CL1"

//Window will pop up and ask to identify the folder where the waves are.

////////////////////////////////////////////////////////////////////////////////////////////////////////

Variable i
string dataname
string newname
string tempname

NewPath Path

For(i = FirstFileNum;i<=LastFileNum;i+=1)

	If(i<10)
		dataname = baseName + "000" + num2str(i) + ".pxt"
		tempname = baseName + "00" + num2str(i)
	Else
		If(i<100)
			dataname = baseName + "00" + num2str(i) + ".pxt"
			tempname = baseName + "0" + num2str(i)
		Else
			If(i<1000)
				dataname = baseName + "0" + num2str(i) + ".pxt"
				tempname = baseName + num2str(i)
			Else
				dataname = baseName + num2str(i) + ".pxt"
				tempname = baseName + num2str(i)

			EndIf
		EndIf
	EndIf
	
	tempname = "ARPES_DA30_phot_dep"
	
	newname= newnamebase+num2str(i)
	loaddata /p=path dataname
	rename $tempname $newname
	redimension /s $newname

EndFor
	
	KillPath Path

//for(i = 1; i <= 2; i += 1)
//	dataname = baseName + "000" + num2str(i) + ".pxt"
//	newname= newnamebase+num2str(i)
//	loaddata /p=path dataname
//	rename $dataname $newname
//	redimension /s $newname
//
//endfor
//
//
//for(i = 10; i <= 41; i += 1)
//	dataname = baseName + "00" + num2str(i) + ".pxt"
//	newname= newnamebase+num2str(i)
//	loaddata /p=path dataname
//	rename $dataname $newname
//	redimension /s $newname
//endfor
//
//
//for(i = 100; i <= 876; i += 1)
//	dataname = baseName + "0" + num2str(i) + ".pxt"
//	newname= newnamebase+num2str(i)
//	loaddata /p=path dataname
//	rename $dataname $newname
//	redimension /s $newname
//endfor
//
//for(i = 1145; i <= 1195; i += 1)
//	dataname = baseName + num2str(i) + ".pxt"
//	newname= newnamebase+num2str(i)
//	loaddata /p=path dataname
//	rename $dataname $newname
//	redimension /s $newname
//endfor

End