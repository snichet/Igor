#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//For a 3D wave. a 2D Norm
Function NormXZ(InputWave)
	Wave Inputwave
	
	String OutputWaveName = NameOfWave(InputWave)+"_NormXZ"
	Duplicate /o InputWave $OutputWaveName
	Wave OutputWave = $OutputWaveName
	
	OutputWave = 0
	
	Make /o /n=(dimsize(inputwave,0),dimsize(inputwave,2)) temp
	Wave Temp
	
	Variable i,j,k,V_Sum
	
	For(i=0;i<dimsize(inputwave,1);i+=1)
	
		Temp=0
		Temp[][]=Inputwave[p][i][q]
		
		WaveStats/Q Temp
				
		OutputWave[][i][]=InputWave[p][i][r]/V_Sum
		
	EndFor
	
	KillWaves Temp
	
End

//For a 3D wave. a 2D Norm
Function NormYZ(InputWave)
	Wave Inputwave
	
	String OutputWaveName = NameOfWave(InputWave)+"_NormYZ"
	Duplicate /o InputWave $OutputWaveName
	Wave OutputWave = $OutputWaveName
	
	OutputWave = 0
	
	Make /o /n=(dimsize(inputwave,1),dimsize(inputwave,2)) temp
	Wave Temp
	
	Variable i,j,k,V_Sum
	
	For(i=0;i<dimsize(inputwave,0);i+=1)
	
		Temp=0
		Temp[][]=Inputwave[i][p][q]
		
		WaveStats/Q Temp
				
		OutputWave[i][][]=InputWave[i][q][r]/V_Sum
		
	EndFor
	
	KillWaves Temp
	
End

//For a 3D wave. a 2D Norm
Function NormXY(InputWave)
	Wave Inputwave
	
	String OutputWaveName = NameOfWave(InputWave)+"_NormXY"
	Duplicate /o InputWave $OutputWaveName
	Wave OutputWave = $OutputWaveName
	
	OutputWave = 0
	
	Make /o /n=(dimsize(inputwave,0),dimsize(inputwave,1)) temp
	Wave Temp
	
	Variable i,j,k,V_Sum
	
	For(k=0;k<dimsize(inputwave,2);k+=1)
	
		Temp=0
		Temp[][]=Inputwave[p][q][k]
		
		WaveStats/Q Temp
				
		OutputWave[][][k]=InputWave[p][q][k]/V_Sum
		
	EndFor
	
	KillWaves Temp
	
End

//For a 3D Wave. a 1D Norm
Function NormX3D(inputwave)
	wave inputwave
		
	string outputwavename = nameofwave(inputwave)+"normx"
	duplicate /o inputwave $outputwavename
	wave outputwave = $outputwavename
	
	outputwave=0
	
	make /o /n=(dimsize(inputwave,0)) temp
	wave test
	wave fit_temp
	
	variable i,j,k,v_sum
	
	for(i=0;i<dimsize(inputwave,1);i+=1)
	for(j=0;j<dimsize(inputwave,2);j+=1)
		temp=0
		temp[]=inputwave[p][i][j]
		
		wavestats /q temp
		
		For(k=0;k<dimsize(inputwave,0);k+=1)
			OutputWave[k][i][j]=inputwave[k][i][j]/v_sum
		EndFor
	endfor
	endfor
	
	killwaves temp
end

//For a 3D Wave. a 1D Norm
Function NormY3D(inputwave)
	wave inputwave
		
	string outputwavename = nameofwave(inputwave)+"normy"
	duplicate /o inputwave $outputwavename
	wave outputwave = $outputwavename
	
	outputwave=0
	
	make /o /n=(dimsize(inputwave,1)) temp
	wave test
	wave fit_temp
	
	variable i,j,k,v_sum
	
	for(i=0;i<dimsize(inputwave,0);i+=1)
	for(j=0;j<dimsize(inputwave,2);j+=1)
		temp=0
		temp[]=inputwave[i][p][j]
		
		wavestats /q temp
		
		For(k=0;k<dimsize(inputwave,1);k+=1)
			OutputWave[i][k][j]=inputwave[i][k][j]/v_sum
		EndFor
	endfor
	endfor
	
	killwaves temp
end

//For a 3D Wave. a 1D Norm
Function NormZ3D(inputwave)
	wave inputwave
		
	string outputwavename = nameofwave(inputwave)+"normx"
	duplicate /o inputwave $outputwavename
	wave outputwave = $outputwavename
	
	outputwave=0
	
	make /o /n=(dimsize(inputwave,2)) temp
	wave test
	wave fit_temp
	
	variable i,j,k,v_sum
	
	for(i=0;i<dimsize(inputwave,1);i+=1)
	for(j=0;j<dimsize(inputwave,0);j+=1)
		temp=0
		temp[]=inputwave[j][i][p]
		
		wavestats /q temp
		
		For(k=0;k<dimsize(inputwave,2);k+=1)
			OutputWave[j][i][k]=inputwave[j][i][k]/v_sum
		EndFor
	endfor
	endfor
	
	killwaves temp
end

//For a 2D Wave
Function NormX(InputWave)
	Wave InputWave
	
	String OutputWaveName = NameOfWave(InputWave)+"_NormX"
	Duplicate /o InputWave $OutputWaveName
	Wave OutputWave = $OutputWaveName
	
	OutputWave = 0
	
	Make /o /n=(dimsize(inputwave,0)) temp
	wave test
	wave fit_temp
	
	Variable i,j,V_sum
	
	For(i=0;i<dimsize(inputwave,1);i+=1)
		temp=0
		temp[]=Inputwave[p][i]
		
		WaveStats /Q Temp
				
		For(j=0;j<dimsize(inputwave,0);j+=1)
			outputwave[j][i]=inputwave[j][i]/v_sum
		EndFor
		 
	EndFor
	
	killwaves temp

End


//For a 2D Wave
Function NormY(InputWave)
	Wave InputWave
	
	String OutputWaveName = NameOfWave(InputWave)+"_NormY"
	Duplicate /o InputWave $OutputWaveName
	Wave OutputWave = $OutputWaveName
	
	OutputWave = 0
	
	Make /o /n=(dimsize(inputwave,1)) temp
	wave test
	wave fit_temp
	
	Variable i,j,V_sum,V_TotalSum
	WaveStats InputWave
	V_TotalSum=V_Sum
	
	For(i=0;i<dimsize(inputwave,0);i+=1)
		temp=0
		temp[]=Inputwave[i][p]
		
		WaveStats /Q Temp
				
		For(j=0;j<dimsize(inputwave,1);j+=1)
			outputwave[i][j]=inputwave[i][j]/v_sum*V_TotalSum
		EndFor
		 
	EndFor
	
	killwaves temp

End

//For a 2D Wave
Function NormXRegion(InputWave,FirstPoint,LastPoint)
	Wave InputWave
	Variable FirstPoint
	Variable LastPoint
	
	String OutputWaveName
	Variable i, a
	Do
		OutputWaveName = NameofWave(Inputwave)+"_NormXYReg"+num2str(i)
		i+=1
		a=exists(OutputWaveName)
	While(a==1)
	Duplicate /o InputWave $OutputWaveName
	Wave OutputWave = $OutputWaveName
	
	OutputWave = 0
	
	Make /o /n=(abs(LastPoint-FirstPoint)+1) temp
	wave test
	wave fit_temp
	
	Variable j,V_sum
	
	For(i=0;i<dimsize(inputwave,1);i+=1)
		temp=0
		temp[]=Inputwave[p+FirstPoint][i]
		
		WaveStats /q Temp
				
		For(j=0;j<dimsize(inputwave,0);j+=1)
			outputwave[j][i]=inputwave[j][i]/v_sum
		EndFor
		 
	EndFor
	
	killwaves temp
	
	Note OutputWave " "
	Note OutputWave "This wave was normed using NormXRegion"
	Note OutputWave "FirstZPoint = " + Num2str(FirstPoint)
	Note OutputWave "LastZPoint = " + Num2str(LastPoint)
	Note Outputwave " "

End

//For a 2D Wave
Function NormYRegion(InputWave,FirstPoint,LastPoint)
	Wave InputWave
	Variable FirstPoint
	Variable LastPoint
	
	String OutputWaveName
	Variable i, a
	Do
		OutputWaveName = NameofWave(Inputwave)+"_NormXYReg"+num2str(i)
		i+=1
		a=exists(OutputWaveName)
	While(a==1)
	Duplicate /o InputWave $OutputWaveName
	Wave OutputWave = $OutputWaveName
	
	OutputWave = 0
	
	Make /o /n=(abs(LastPoint-FirstPoint)+1) temp
	wave test
	wave fit_temp
	
	Variable j,V_sum
	
	For(i=0;i<dimsize(inputwave,0);i+=1)
		temp=0
		temp[]=Inputwave[i][p+FirstPoint]
		
		WaveStats /q Temp
				
		For(j=0;j<dimsize(inputwave,1);j+=1)
			outputwave[i][j]=inputwave[i][j]/v_sum
		EndFor
		 
	EndFor
	
	killwaves temp
	
	Note OutputWave " "
	Note OutputWave "This wave was normed using NormYRegion"
	Note OutputWave "FirstZPoint = " + Num2str(FirstPoint)
	Note OutputWave "LastZPoint = " + Num2str(LastPoint)
	Note Outputwave " "

End

//For a 3D wave. a 2D Norm
Function NormYZRegion(InputWave,FirstYPoint,LastYPoint,FirstZPoint,LastZPoint)
	Wave Inputwave
	Variable FirstYPoint
	Variable LastYPoint
	Variable FirstZPoint
	Variable LastZPoint
	
	String OutputWaveName
	Variable i,a
	
	Do
		OutputWaveName = NameofWave(Inputwave)+"_NormXYReg"+num2str(i)
		i+=1
		a=exists(OutputWaveName)
	While(a==1)
	
	Duplicate /o InputWave $OutputWaveName
	Wave OutputWave = $OutputWaveName
	
	OutputWave = 0
	
	Make /o /n=(LastYPoint-FirstYPoint+1,LastZPoint-FirstZPoint+1) temp
	Wave Temp
	
	Variable V_Sum
	
	For(i=0;i<dimsize(inputwave,0);i+=1)
	
		Temp=0
		Temp[][]=Inputwave[i][p+FirstYPoint][q+FirstZPoint]
		
		WaveStats/Q Temp
				
		OutputWave[i][][]=InputWave[i][q][r]/V_Sum
		
	EndFor
	
	KillWaves Temp
	
	Note OutputWave " "
	Note OutputWave "This wave was normed using NormYZRegion"
	Note OutputWave "FirstYPoint = " + Num2str(FirstYPoint)
	Note OutputWave "LastYPoint = " + Num2str(LastYPoint)
	Note OutputWave "FirstZPoint = " + Num2str(FirstZPoint)
	Note OutputWave "LastZPoint = " + Num2str(LastZPoint)
	Note Outputwave " "
	
End

//For a 3D wave. a 2D Norm
Function NormXYRegion(InputWave,FirstXPoint,LastXPoint,FirstYPoint,LastYPoint)
	Wave Inputwave
	Variable FirstXPoint
	VAriable LastXPoint
	Variable FirstYPoint
	Variable LastYPoint
	
	String OutputWaveName
	Variable i,a
	
	Do
		OutputWaveName = NameofWave(Inputwave)+"_NormXYReg"+num2str(i)
		i+=1
		a=exists(OutputWaveName)
	While(a==1)
	
	Duplicate /o InputWave $OutputWaveName
	Wave OutputWave = $OutputWaveName
	
	OutputWave = 0
	
	Make /o /n=(LastXPoint-FirstXPoint+1,LastYPoint-FirstYPoint+1) temp
	Wave Temp
	
	Variable V_Sum
	
	For(i=0;i<dimsize(inputwave,2);i+=1)
	
		Temp=0
		Temp[][]=Inputwave[p+FirstXPoint][q+FirstYPoint][i]
		
		WaveStats/Q Temp
				
		OutputWave[][][i]=InputWave[p][q][i]/V_Sum
		
	EndFor
	
	KillWaves Temp
	
	Note OutputWave " "
	Note OutputWave "This wave was normed using NormXYRegion"
	Note Outputwave "FirstXPoint = " + Num2str(FirstXPoint)
	Note Outputwave "LastXPoint = " + num2str(LastXPoint)
	Note OutputWave "FirstYPoint = " + Num2str(FirstYPoint)
	Note OutputWave "LastYPoint = " + Num2str(LastYPoint)
	Note Outputwave " "
	
End

//For a 4D wave, norming by 2D slices.
Function Norm4DZT(InputWave)
	Wave InputWave
	
	String OutputWaveName = NameOfWave(InputWave)+"NormZT"
	Duplicate /O InputWave $OutputWaveName
	Wave OutputWave = $OutputWaveName
	
	OutputWave = 0
	
	Make /O /N=(dimsize(InputWave,2),dimsize(InputWave,3)) Temp
	Wave Temp
	
	Variable i,j,k,l,V_Sum,Ave_Sum,Factor
	
	Wavestats /q Inputwave
	
	Ave_Sum=V_Sum/(dimsize(inputwave,0)*dimsize(inputwave,1))
		
	For(i=0;i<dimsize(Inputwave,0);i+=1)
	For(j=0;j<dimsize(InputWave,1);j+=1)
		Temp=0
		Temp[][]=InputWave[i][j][p][q]
		WaveStats /Q Temp
		Factor=V_Sum/Ave_Sum
		//Print Factor
		OutputWave[i][j][][]=InputWave[i][j][r][s]/Factor
	EndFor
	EndFor
	
	KillWaves Temp
	
	Print NameOfWave(InputWave) +" was normed by Norm4DZT. The output wave name is " + OutputWaveName+"."
	
	Note OutputWave NameOfWave(InputWave) +" was normed by Norm4DZT. This is the output wave name."

End