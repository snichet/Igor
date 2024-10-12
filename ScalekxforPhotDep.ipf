#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//20180923 T Cochran - scales a 2D constant energy conture at the Fermi level which is hv vs phi.
//20181018 - Cochran - Seems like I expanded it to do a 3D block at some point
//20190201 - T Cochran - Added ability to add extra points on both low and high kx values for high energy cuts
//20190826 - T Cochran - Discovered a bug where if the highest k value at the high energy range correspondes to a angle >90deg from the zero angle at lower energy the program doesn't work.... Needs serious restructuring to fix.

Function Scale1DWave(InputWave,WaveKE,RefKE,kWave,kZeroAng,ExtraLowPoints,OutputWave)
	Wave InputWave
	Variable WaveKE
	Variable RefKE
	Wave kWave
	Variable kZeroAng
	Variable ExtraLowPoints
	Wave OutputWave
	
	Variable kValue
	Variable i
	Variable V_minRowLoc
	
	Duplicate/o  kWave kDifWave
	
	For(i=0;i<dimsize(OutputWave,0);i+=1)
		
		kValue = 0.5121*sqrt(refKE)*sin(((dimoffset(InputWave,0)+(i-ExtraLowPoints)*dimdelta(InputWave,0))-kZeroAng)*Pi/180)
		
		kDifWave[]=abs(kwave[p]-kValue)
		setscale /p x, 0,1,"",kDifWave
		
		WaveStats /Q kDifWave
				
		OutputWave[i]=InputWave[V_minRowLoc]
		
	EndFor
	
	Killwaves kDifWave

End


//1st dimension is anlge
//2nd dimension in photon energy
Function ScalePhotDepConstantEnergy(TargetWaveName,kZeroAng)
	String TargetWaveName
	Variable kZeroAng
	
	Wave TargetWave = $TargetWaveName
	Variable j,k
	Variable WaveKE
	Variable RefKE = dimoffset(TargetWave,1)-4.5
	
//	Variable LastAng = dimoffset(targetwave,0)+(dimsize(targetwave,0)-1)*dimdelta(targetwave,0)
//	Variable HighEnergy = dimoffset(targetwave,1)+(dimsize(targetwave,1)-1)*dimdelta(targetwave,1)
//	Variable LastKHighEnergy = .5121*sqrt(HighEnergy)*sin((LastAng-kZeroAng)*Pi/180)
//	Variable CorrespondingLowEnergyAngle = asin(LastKHighEnergy/(.5121*sqrt(dimoffset(targetwave,1))))*180/Pi+kZeroAng
//	Variable ExtraAngle = CorrespondingLowEnergyAngle - LastAng
//	Variable ExtraPoints = trunc(ExtraAngle/dimdelta(targetwave,0))
		
	Variable LastAng = dimoffset(targetwave,0)+(dimsize(targetwave,0)-1)*dimdelta(targetwave,0)
	Variable HighEnergy = dimoffset(targetwave,1)+(dimsize(targetwave,1)-1)*dimdelta(targetwave,1)
	Variable LastKHighEnergy = .5121*sqrt(HighEnergy)*sin((LastAng-kZeroAng)*Pi/180)
	Variable FirstKHighEnergy = .5121*sqrt(HighEnergy)*sin((dimoffset(targetwave,0)-kZeroAng)*Pi/180)
	Variable LowEnergyAngleOfLastK = asin(Max(-1,Min(1,LastKHighEnergy/(.5121*sqrt(dimoffset(targetwave,1))))))*180/Pi+kZeroAng
	Variable LowEnergyAngleOfFirstK = asin(Max(-1,Min(1,FirstKHighEnergy/(.5121*sqrt(dimoffset(targetwave,1))))))*180/Pi+kZeroAng
	Variable ExtraHighAngle = LowEnergyAngleOfLastK - LastAng 
	Variable ExtraLowAngle = DimOffset(targetwave,0) - LowEnergyAngleOfFirstK
	Variable ExtraHighPoints = trunc(ExtraHighAngle/dimdelta(targetwave,0))
	Variable ExtraLowPoints = trunc(ExtraLowAngle/dimdelta(targetwave,0))
		
	String TargetWaveExpandedName = "temp4"
	Duplicate /o TargetWave $targetwaveexpandedname
	Wave TargetWaveExpanded = $targetwaveexpandedname
	InsertPoints dimsize(TargetWaveExpanded,0),ExtraHighPoints, TargetWaveExpanded
	InsertPoints 0, ExtraLowPoints,TargetWaveExpanded
	setscale /p x, dimoffset(TargetWaveExpanded,0)-ExtraLowPoints*dimdelta(TargetWaveExpanded,0),dimdelta(TargetWaveExpanded,0),TargetWaveExpanded

	String kWaveName = "temp1"
	Make /o /n = (dimsize(TargetWaveExpanded,0)) $kWaveName
	Wave kWave = $kWaveName
	
	String ScaledWaveName = TargetWaveName + "_scaled"
	Make /o /n = (dimsize(targetwaveexpanded,0),dimsize(targetwaveexpanded,1)) $ScaledWaveName
	Wave ScaledWave = $ScaledWaveName
	
	String UnscaledCutName = "temp2"
	Make /o /n = (dimsize(TargetWaveExpanded,0)) $UnscaledCutName
	Wave UnscaledCut = $UnscaledCutName
	setscale /p x, dimoffset(TargetWave,0),dimdelta(TargetWave,0),"",UnscaledCut
	
	String ScaledCutName = "temp3"
	Make /o /n = (dimsize(TargetWaveExpanded,0)) $ScaledCutName
	Wave ScaledCut = $ScaledCutName
		
	For(j=0;j<dimsize(TargetWaveExpanded,1);j+=1)
		WaveKE = dimoffset(TargetWaveExpanded,1)+j*dimdelta(TargetWaveExpanded,1)-4.5
		
		For(k=0;k<dimsize(kWave,0);k+=1)
			kWave[k] = 0.5121*sqrt(WaveKE)*sin(((dimoffset(TargetWaveExpanded,0)+k*dimdelta(TargetWaveExpanded,0))-kZeroAng)*Pi/180)
		EndFor
		
		UnscaledCut[] = TargetWaveExpanded[p][j]
		
		Scale1DWave(UnscaledCut,WaveKE,RefKE,kWave,kZeroAng,ExtraLowPoints,ScaledCut)
		
		ScaledWave[][j]=ScaledCut[p]
		
		//Print "Row " + num2str(j) + "/" + num2str(dimsize(TargetWaveExpanded,1)-1) + " complete"
	
	EndFor
	
	setscale /p x, dimoffset(targetwave,0)-extralowpoints*dimdelta(targetwave,0),dimdelta(targetwave,0),"",scaledwave
	setscale /p y, dimoffset(targetwave,1), dimdelta(targetwave,1),"", scaledwave
	
	Killwaves ScaledCut UnscaledCut kWave TargetWaveExpanded

End

//Will make a function to convert a 3D block, but without correcting for the change of kinetic energy with binding energy.

//Input wave should have the following structure:
//diminsion 0 = Binding Energy
//diminsion 1 = Analyzer Angle
//diminsion 2 = hv

Function Scale3DBlock(InputWaveName, kZeroAng)

	String InputWaveName
	Variable kZeroAng
	
	wave inputwave = $InputWaveName
	
//	Variable LastAng = dimoffset(inputwave,1)+(dimsize(inputwave,1)-1)*dimdelta(inputwave,1)
//	Variable HighEnergy = dimoffset(inputwave,2)+(dimsize(inputwave,2)-1)*dimdelta(inputwave,2)
//	Variable LastKHighEnergy = .5121*sqrt(HighEnergy)*sin((LastAng-kZeroAng)*Pi/180)
//	Variable CorrespondingLowEnergyAngle = asin(LastKHighEnergy/(.5121*sqrt(dimoffset(inputwave,2))))*180/Pi+kZeroAng
//	Variable ExtraAngle = CorrespondingLowEnergyAngle - LastAng
//	Variable ExtraPoints = trunc(ExtraAngle/dimdelta(inputwave,1))

	Variable LastAng = dimoffset(inputwave,1)+(dimsize(inputwave,1)-1)*dimdelta(inputwave,1)
	Variable HighEnergy = dimoffset(inputwave,2)+(dimsize(inputwave,2)-1)*dimdelta(inputwave,2)
	Variable LastKHighEnergy = .5121*sqrt(HighEnergy)*sin((LastAng-kZeroAng)*Pi/180)
	Variable FirstKHighEnergy = .5121*sqrt(HighEnergy)*sin((dimoffset(inputwave,1)-kZeroAng)*Pi/180)
	Variable LowEnergyAngleOfLastK = asin(Max(-1,Min(1,LastKHighEnergy/(.5121*sqrt(dimoffset(inputwave,2))))))*180/Pi+kZeroAng
	Variable LowEnergyAngleOfFirstK = asin(Max(-1,Min(1,FirstKHighEnergy/(.5121*sqrt(dimoffset(inputwave,2))))))*180/Pi+kZeroAng
	Variable ExtraHighAngle = LowEnergyAngleOfLastK - LastAng 
	Variable ExtraLowAngle = DimOffset(inputwave,1) - LowEnergyAngleOfFirstK
	Variable ExtraHighPoints = trunc(ExtraHighAngle/dimdelta(inputwave,1))
	Variable ExtraLowPoints = trunc(ExtraLowAngle/dimdelta(inputwave,1))
	
	String OutputWaveName = InputWaveName + "_2Dscaled"
	make /o /n = (dimsize(inputwave,0),dimsize(inputwave,1)+extrahighpoints+extralowpoints,dimsize(inputwave,2)) $OutputWaveName
	Wave OutputWave = $OutputWaveName
	
	String TempInputWaveName = "TempSlice"
	Make /O /N = (dimsize(InputWave,1),Dimsize(InputWave,2)) $TempInputWaveName
	Wave TempInputWave = $TempINputWaveName
		
	Variable i
	
	wave TempOutputWave = TempSlice_scaled
		
	setscale /p x, dimoffset(Inputwave,1),dimdelta(inputwave,1),"",TempInputWave
	setscale /p y, dimoffset(Inputwave,2),dimdelta(Inputwave,2),"",TempInputWave
	
	For(i=0;i<dimsize(inputwave,0);i+=1)
	
		//String TempOutputWavename = TempInputWaveName + "_scaled"
		TempInputWave[][]=Inputwave[i][p][q]
				
		ScalePhotDepConstantEnergy(TempInputWaveName,kZeroAng)
				
		OutputWave[i][][] += TempOutputWave[q][r]
		
		//Killwaves TempOutputWave
		
		Print "Binding Energy Point" + num2str(i) + "/" + num2str(dimsize(inputwave,0)) + "completed"
	
	EndFor
	
	setscale /p x, dimoffset(InputWave,0),dimdelta(InputWave,0),OutputWave
	setscale /p z, dimoffset(InputWave,2),dimdelta(InputWave,2),OutputWave
	setscale /p y, .5121*Sqrt(dimoffset(InputWave,2)-4.5)*(dimoffset(Inputwave,1)-KZeroAng-dimdelta(InputWave,1)*ExtraLowPoints)*Pi/180,.5121*Sqrt(dimoffset(InputWave,2)-4.5)*dimdelta(inputwave,1)*Pi/180,outputwave
	
	killwaves tempInputwave, tempoutputwave

End