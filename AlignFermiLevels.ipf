#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "Macintosh HD:Users:tylerac:Documents:data:IGOR stuff_tc20200904:FittingFunctions"
#include "Macintosh HD:Users:tylerac:Documents:data:IGOR stuff_tc20200904:Noise"

//Dim0 = Binding Energy
//Dim1 = Analyzer Angle
//Dim2 = Scanning Direction

Function GenerateEfList(mapname,TwoD)
	String MapName
	variable TwoD
	
	Wave Map = $MapName
	
	
	////////////////////////////////////////////////////
	Variable Ef = 45.31 //nominal Fermi level
	Variable T = 0.03 //nominal resolution
	Variable B = 20000 //background
	Variable S =((vcsr(B)-vcsr(A))/(xcsr(B)-xcsr(A))) //slope of linear region above Ef
	Variable Y = 60000-S*Ef //y intercept
	
	Variable FitStart = 160 //point the fit begins
	Variable FitStop = 230 //point that fit ends
	////////////////////////////////////////////////////
	
	
	//Integrate ThetaX
	String IntSpecName = MapName + "_ThXInt"
	If(TwoD==0)
		Make /O /N=(dimsize($mapname,0),dimsize($mapname,2)) $IntSpecName
		Wave IntSpec = $IntSpecName
		setscale /p x, dimoffset($mapname,0),dimdelta($mapname,0),IntSpec
		setscale /p y, dimoffset($mapname,2),dimdelta($mapname,2),IntSpec
	
		//If( !WaveExists(IntSpec) )
			Variable a,i,j,k
			
			For(i=0;i<dimsize($MapName,0);i+=1)
				For(j=0;j<dimsize($MapName,2);j+=1)
				 	a=0
				 	For(k=0;k<dimsize($MapName,1);k+=1)
						a += Map[i][k][j]
					EndFor
					IntSpec[i][j]=a
				EndFor
			EndFor
		//endIf
	Else
		Duplicate /O $mapname $IntSpecName
		Wave IntSpec = $IntSpecName
	EndIf
	
	//Fit the Individual EDCs
	String EDCName = "SingleEDC"
	Make /O /N=(dimsize(IntSpec,0)) $EDCName
	Wave EDC = $EDCName
	
	setscale /p x, dimoffset(IntSpec,0),dimdelta(IntSpec,0),edc
	
	String EfListName = MapName +"_EfList"
	Make /O /N = (dimsize(IntSpec, 1)) $EfListName
	Wave EfList = $EfListName
	
	String ResListName = MapName +"_ResList"
	Make /O /N = (dimsize(IntSpec, 1)) $ResListName
	Wave ResList = $ResListName
	
	setscale /p x, dimoffset(intspec,1),dimdelta(intspec,1), EfList
	setscale /p x, dimoffset(intspec,1),dimdelta(intspec,1), ResList
		
	For(i=0;i<dimsize(intspec,1);i+=1)
		For(j=0;j<dimsize(intspec,0);j+=1)
			EDC[j] = IntSpec[j][i]
		EndFor
		
		If(i==0)
			Make/D/N=4/O W_coef
			W_coef[0] = {Y,Ef,T,S,B}
			wave w_coef
			FuncFit /q /NTHR=0 FermiAndLinear W_coef  EDC[fitstart, fitstop] /D
			Variable Efi = W_coef[1]
			
		Else
			FuncFit /q /NTHR=0 FermiAndLinear W_coef  EDC[fitstart+round((W_coef[1]-Efi)/dimdelta(intspec,0)), fitstop+round((W_coef[1]-Efi)/dimdelta(intspec,0))] /D
		EndIf
	
		EfList[i] = W_coef[1]
		ResList[i] = W_coef[2]
	EndFor
	
	Killwaves EDC
	Display EfList
	Display ResList
	
	String EfIndexName = MapName+"_EfIndex"
	Duplicate /O $EfListName $EFIndexname
	Wave EfIndex = $EfIndexName
	
	For(i=0;i<dimsize(EfIndex,0);i+=1)
		EfIndex[i] = round((EfList[i]-dimoffset(intspec,0))/dimdelta(intspec ,0))
	EndFor
	
	Display EfIndex
	
	Display
	AppendImage IntSpec
	AppendtoGraph /Vert EfList
		
	print "alignFermi_PhotDep(\""+mapname+"\",\""+EfIndexName+"\")"
	
	MakeNoise()
End

Function alignFermi_photDep(photDepStr,fermiListStr)
        String photDepStr, fermiListStr
        Wave photDep = $photDepStr
        Wave fermiList = $fermiListStr
              
        Variable fermiMax = round(WaveMax(fermiList))
        Variable fermiMin = round(WaveMin(fermiList))
                        
        Variable extra = fermiMax - fermiMin // The extra width needed to accommodate the Fermi level shifts
        
        // Make the target wave
        String photDepShiftStr = photDepStr + "_sft"
        Make /O/N=(DimSize(photDep,0)+extra,DimSize(photDep,1),DimSize(photDep,2)) $photDepShiftStr
        Wave photDepShift = $photDepShiftStr
        SetScale /P x, -DimDelta(photDep,0)*fermiMax, DimDelta(photDep,0), photDepShift
	SetScale /P y, DimOffset(photDep,1), DimDelta(photDep,1), photDepShift
	SetScale /P z, DimOffset(photDep,2), DimDelta(photDep,2), photDepShift
        
        Variable i, fermi, start
        
        for (i = 0; i < DimSize(photDep,2); i += 1)
                
                fermi = fermiList[i]
                // for fermiMin, start = extra
                // for fermiMax, start = 0
                start = fermiMax - fermi
                photDepShift[,start][][i] = photDep[0][q][i]
                photDepShift[start,start+DimSize(photDep,0)-1][][i] = photDep[p-start][q][i]
                photDepShift[start+DimSize(photDep,0)-1,][][i] = photDep[DimSize(photDep,0)-1][q][i]
                
        endfor
	MakeNoise()
End