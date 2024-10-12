#pragma rtGlobals=1		// Use modern global access method.

Function LoadStuff()

Variable i
String baseName = "NCSS1_"
String folder = "Macintosh HD:Users:cochra96:Documents:Data:20180605_SSRL_BL52_NCSS:NCSS1:"
string dataname


//LoadSEStxt(folder + baseName + "1000" + ".txt", baseName)

for(i = 0; i <= 9; i += 1)
	LoadSEStxt(folder + baseName + "000" + num2str(i) + ".txt", baseName)
	print i
	dataname = basename+num2str(i)
	redimension /S $dataname
endfor


for(i = 10; i <= 99; i += 1)
	LoadSEStxt(folder + baseName + "00" + num2str(i) + ".txt", baseName)
	print i
	dataname = basename+num2str(i)
	redimension /S $dataname
endfor


for(i = 100; i <= 876; i += 1)
	LoadSEStxt(folder + baseName + "0" + num2str(i) + ".txt", baseName)
	print i
	dataname = basename+num2str(i)
	redimension /S $dataname
endfor

for(i = 1145; i <= 1195; i += 1)
//	LoadSEStxt(folder + baseName + num2str(i) + ".txt", baseName)
//	print i
//	dataname = basename+num2str(i)
//	redimension /S $dataname
endfor

End