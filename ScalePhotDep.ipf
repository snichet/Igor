#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "Macintosh HD:Users:tylerac:Documents:data:IGOR stuff_tc20200904:Noise"
//Successfully Applied to NiRhSi data on 20190822 - T Cochran
//20210512 Modified to accomodate photon energy dependences with increase and decreasing photon energy. Cleaned up. - T Cochran

//Dim0 = Binding Energy. 0 is Ef. Neg is below Ef
//Dim1 = Analyzer Angle.
//Dim2 = Photon Energy

Function ScalePhotDep(inputwave,AAZero,workfunc,innerpot,SlitPerpAngleWave0,SlitPerpAngleZero,Interpolate)
	Wave InputWave
	Variable AAZero
	Variable workfunc //>0
	Variable InnerPot //>0
	Wave SlitPerpAngleWave0 //You must have a wave that has the value of the angle perpendicular to the analyzer slit for each cut. Should be the same size as dimsize(inputwave,2)
	Variable SlitPerpAngleZero //This will be subtracted from the wave immediately
	Variable interpolate //0==NO 1==YES
	print("break")

	Duplicate /o SlitPerpAngleWave0 SlitPerpAngleWave
	SlitPerpAngleWave -= SlitPerpAngleZero
	
	
	Variable NearestPointRadius=5
		
	//Step 1: Define some handy referencesd
	
	Make/o /n=(dimsize(inputwave,0),dimsize(inputwave,2)) EkWave
	Wave EkWave
	
	EkWave[][]=dimoffset(inputwave,2)+q*dimdelta(inputwave,2)+dimoffset(inputwave,0)+p*dimdelta(inputwave,0)-workfunc

	Variable InputwaveDim0Max = Dimoffset(inputwave,0)+dimdelta(inputwave,0)*dimsize(inputwave,0)
	Variable InputwaveDim1Max = Dimoffset(inputwave,1)+dimdelta(inputwave,1)*dimsize(inputwave,1)
	Variable InputwaveDim2Max = Dimoffset(inputwave,2)+dimdelta(inputwave,2)*dimsize(inputwave,2)
		
	//Step 2: Make numerical function that maps (Eb, AA, hv) -> (Eb, kx, kz). Use this to identifiy the offsets of the outputwave
	
	Duplicate /o inputwave Eb
	Eb=0
	duplicate /o inputwave kx
	kx=0
	duplicate /o inputwave kz
	kz=0
		
	Eb[][][]=dimoffset(inputwave,0)+p*dimdelta(inputwave,0)
	kx[][][] = .5121*sqrt(Ekwave[p][r])*cos(SlitPerpAngleWave[r]*pi/180)*sin((dimoffset(inputwave,1)+q*dimdelta(inputwave,1)-AAZero)*pi/180)
	kz[][][] = .5121*sqrt(Ekwave[p][r]*cos(SlitPerpAngleWave[r]*pi/180)^2*cos((dimoffset(inputwave,1)+q*dimdelta(inputwave,1)-AAZero)*pi/180)^2+innerpot)
		
	Variable V_min, V_max
	
	Wavestats /q Eb
	Variable Dim0Low =V_Min
	Variable Dim0High = V_Max
	
	Wavestats /q kx
	Variable Dim1Low = V_min
	Variable Dim1High = V_Max
	
	Wavestats /q kz
	Variable Dim2Low = V_min
	Variable Dim2High = V_max
	
	//Step 3: Determine the size of the outputwave and make it.
	
	Variable Dim0PixelSep = Dimdelta(inputwave,0)
	Variable Dim1PixelSep = .5121*sqrt(EkWave[dimsize(inputwave,0)-1][dimsize(inputwave,2)-1])*dimdelta(inputwave,1)*pi/180
	Variable Dim2PixelSep
	If(dimdelta(inputwave,2)>0)	
		Dim2PixelSep = .5121*(sqrt(InputwaveDim2Max)-sqrt(Dimoffset(inputwave,2)+dimdelta(inputwave,2)*(dimsize(inputwave,2)-1)))
	Else
		Dim2PixelSep = .5121*(sqrt(Dimoffset(inputwave,2)+dimdelta(inputwave,2))-sqrt(Dimoffset(inputwave,2)))
	EndIf
	 	
	Variable Dim0Size = dimsize(inputwave,0)
	Variable Dim1Size = abs((Dim1High-Dim1Low)/Dim1PixelSep) + 3
	Variable Dim2Size = abs((Dim2High- Dim2Low)/Dim2PixelSep) + 3
	
	String OutputwaveName = NameofWave(Inputwave)+"_PDScaled"
	Make /o /n=(Dim0Size,Dim1Size,Dim2Size) $OutputWaveName
	Wave OutputWave = $OutputWaveName
	OutputWave = 0
	
	Setscale /p x, dim0Low-dim0pixelsep,Dim0PixelSep,OutputWave
	setscale /p y, dim1Low-dim1pixelsep, abs(dim1pixelsep),outputwave
	setscale /p z, dim2Low-dim2pixelsep, abs(dim2PixelSep), Outputwave
	
	//Step 4: Read the inputwave, based on numerical inverse of Eb,kx,kz functions. Then write the outputwave.
	
	Variable i,j,k,l,m,n
	Variable a
	Variable Dim0PointNearest,Dim1PointNearest,Dim2PointNearest //The nearest points in the inputwave to the eb,kx,kz position of the outputwave
	Variable hvInverse, ThetaInverse //value of hv and theta when inverse functions are applied to grid point in output wave
	Variable hvFracIndex, ThetaFracIndex //fractional index of hvInverse and ThetaInverse in the scale of InputWave
	Variable CenterEb=0,Centerkx=0,Centerkz = 0
	
	Make /o /n=(dimsize(outputwave,0)) ProgressWave
	Wave ProgressWave
	Variable /d starttime = datetime
	ProgressWave=-starttime
	Variable LastUpdate
	
	If(Interpolate==1)
	
		Duplicate /o Outputwave ThetaInverseWave
		Duplicate /o OutputWave hvInverseWave
		
//		ThetaInverseWave[][][]=-ACos(Sqrt(IndexToScale(OutputWave,r,2)^2-InnerPot*.5121^2)/Sqrt(IndexToScale(OutputWave,q,1)^2+IndexToScale(OutputWave,r,2)^2-InnerPot*.5121^2))*180/Pi
//		hvInverseWave[][][]=(IndexToScale(OutputWave,q,1)*Sec(SlitPerpAngleWave[r]*pi/180)/.5121)^2+(IndexToScale(OutputWave,r,2)*Sec(SlitPerpAngleWave[r]*pi/180)/.5121)^2-innerpot*Sec(SlitPerpAngleWave[r]*pi/180)^2+workfunc-IndexToScale(OutputWave,p,0)
//		return(0)
	
		for(i=0;i<dimsize(outputwave,0);i+=1)
		for(j=0;j<dimsize(outputwave,1);j+=1)
		for(k=0;k<dimsize(outputwave,2);k+=1)
			hvInverse=(IndexToScale(OutputWave,j,1)*Sec(SlitPerpAngleWave[k]*pi/180)/.5121)^2+(IndexToScale(OutputWave,k,2)*Sec(SlitPerpAngleWave[k]*pi/180)/.5121)^2-innerpot*Sec(SlitPerpAngleWave[k]*pi/180)^2+workfunc-IndexToScale(OutputWave,i,0)
			If(IndexToScale(OutputWave,j,1)<0)
				ThetaInverse=-ACos(Sqrt(IndexToScale(OutputWave,k,2)^2-InnerPot*.5121^2)/Sqrt(IndexToScale(OutputWave,j,1)^2+IndexToScale(OutputWave,k,2)^2-InnerPot*.5121^2))*180/Pi+AAZero
			Else
				ThetaInverse=ACos(Sqrt(IndexToScale(OutputWave,k,2)^2-InnerPot*.5121^2)/Sqrt(IndexToScale(OutputWave,j,1)^2+IndexToScale(OutputWave,k,2)^2-InnerPot*.5121^2))*180/Pi+AAZero
			EndIf
			
			hvFracIndex=(hvInverse-Dimoffset(InputWave,2))/DimDelta(InputWave,2)
			ThetaFracIndex=(ThetaInverse-DimOffset(InputWave,1))/DimDelta(InputWave,1)
			
			If(hvFracIndex<0 || ThetaFracIndex<0 || hvFracIndex>dimsize(Inputwave,2)-1 || ThetaFracIndex>dimsize(inputwave,1)-1)
				Outputwave[i][j][k]=0
			Else
				Outputwave[i][j][k]=(1-(ThetaFracIndex-Trunc(ThetaFracIndex)))*(1-(hvFracIndex-Trunc(hvFracIndex)))*InputWave[i][Trunc(ThetaFracIndex)][Trunc(hvFracIndex)]+(1-(ThetaFracIndex-Trunc(ThetaFracIndex)))*(hvFracIndex-Trunc(hvFracIndex))*InputWave[i][Trunc(ThetaFracIndex)][Trunc(hvFracIndex)+1]+(ThetaFracIndex-Trunc(ThetaFracIndex))*(1-(hvFracIndex-Trunc(hvFracIndex)))*InputWave[i][Trunc(ThetaFracIndex)+1][Trunc(hvFracIndex)]+(Trunc(ThetaFracIndex)-ThetaFracIndex)*(Trunc(hvFracIndex)-hvFracIndex)*InputWave[i][Trunc(ThetaFracIndex)+1][Trunc(hvFracIndex)+1]
				//Outputwave[i][j][k]=Inputwave[i][thetafracindex][hvfracindex]
			EndIf
			
		endfor
		endfor
		
			progresswave[i] = datetime-starttime
			
			if(ProgressWave[i]>LastUpdate+30)
				Print "Time Elapsed: " + num2str(trunc(100*ProgressWave[i]/60)/100) + " minutes. Estimated time remaining: " +num2str(trunc(100*(dimsize(progresswave,0)-i)*ProgressWave[i]/(i+1)/60)/100) + " minutes."
				LastUpdate=ProgressWave[i]
			EndIf
		
		endfor
	
	Else
		
		for(i=0;i<dimsize(outputwave,0);i+=1)
		for(j=0;j<dimsize(outputwave,1);j+=1)
		for(k=0;k<dimsize(outputwave,2);k+=1)
			hvInverse=(IndexToScale(OutputWave,j,1)*Sec(SlitPerpAngleWave[k]*pi/180)/.5121)^2+(IndexToScale(OutputWave,k,2)*Sec(SlitPerpAngleWave[k]*pi/180)/.5121)^2-innerpot*Sec(SlitPerpAngleWave[k]*pi/180)^2+workfunc-IndexToScale(OutputWave,i,0)
			If(IndexToScale(OutputWave,j,1)<0)
				ThetaInverse=-ACos(Sqrt(IndexToScale(OutputWave,k,2)^2-InnerPot*.5121^2)/Sqrt(IndexToScale(OutputWave,j,1)^2+IndexToScale(OutputWave,k,2)^2-InnerPot*.5121^2))*180/Pi+AAZero
			Else
				ThetaInverse=ACos(Sqrt(IndexToScale(OutputWave,k,2)^2-InnerPot*.5121^2)/Sqrt(IndexToScale(OutputWave,j,1)^2+IndexToScale(OutputWave,k,2)^2-InnerPot*.5121^2))*180/Pi+AAZero
			EndIf
			
			hvFracIndex=(hvInverse-Dimoffset(InputWave,2))/DimDelta(InputWave,2)
			ThetaFracIndex=(ThetaInverse-DimOffset(InputWave,1))/DimDelta(InputWave,1)
			
			If(hvFracIndex<0 || ThetaFracIndex<0 || hvFracIndex>dimsize(Inputwave,2)-1 || ThetaFracIndex>dimsize(inputwave,1)-1)
				Outputwave[i][j][k]=0
			Else
				//Outputwave[i][j][k]=(1-(ThetaFracIndex-Trunc(ThetaFracIndex)))*(1-(hvFracIndex-Trunc(hvFracIndex)))*InputWave[i][Trunc(ThetaFracIndex)][Trunc(hvFracIndex)]+(1-(ThetaFracIndex-Trunc(ThetaFracIndex)))*(hvFracIndex-Trunc(hvFracIndex))*InputWave[i][Trunc(ThetaFracIndex)][Trunc(hvFracIndex)+1]+(ThetaFracIndex-Trunc(ThetaFracIndex))*(1-(hvFracIndex-Trunc(hvFracIndex)))*InputWave[i][Trunc(ThetaFracIndex)+1][Trunc(hvFracIndex)]+(Trunc(ThetaFracIndex)-ThetaFracIndex)*(Trunc(hvFracIndex)-hvFracIndex)*InputWave[i][Trunc(ThetaFracIndex)+1][Trunc(hvFracIndex)+1]
				Outputwave[i][j][k]=Inputwave[i][ScaleToIndex(InputWave,ThetaInverse,1)][ScaleToIndex(InputWave,hvInverse,2)]
			EndIf
			
		endfor
		endfor
		
			progresswave[i] = datetime-starttime
			
			if(ProgressWave[i]>LastUpdate+30)
				Print "Time Elapsed: " + num2str(trunc(100*ProgressWave[i]/60)/100) + " minutes. Estimated time remaining: " +num2str(trunc(100*(dimsize(progresswave,0)-i)*ProgressWave[i]/(i+1)/60)/100) + " minutes."
				LastUpdate=ProgressWave[i]
			EndIf
		
		endfor
		
		//The below section is a algorythm for searching for the closest point in the area, without using the inverse map from k-space back to angle space.
//		Variable EbStartTracker1=0,EbStartTracker2=0,EbStartTracker3=0, kxStartTracker1=0,kxstarttracker2=0,kzstarttracker=0
//		
//		For(i=0;i<dimsize(outputwave,0);i+=1)
//			Dim0PointNearest=i
//		For(j=0;j<dimsize(outputwave,1);j+=1)
//		for(k=0;k<dimsize(outputwave,2);k+=1)
//			a=inf
//	
//			For(m=max(Centerkx-NearestPointRadius,0);m<min(Centerkx+NearestPointRadius,dimsize(inputwave,1));m+=1)
//			For(n=max(Centerkz-NearestPointRadius,0);n<min(Centerkz+NearestPointRadius,dimsize(inputwave,2));n+=1)
//				If(a>(dimoffset(outputwave,1)+j*dimdelta(outputwave,1)-kx[i][m][n])^2+(dimoffset(outputwave,2)+k*dimdelta(outputwave,2)-kz[i][m][n])^2)
//					a=(dimoffset(outputwave,1)+j*dimdelta(outputwave,1)-kx[i][m][n])^2+(dimoffset(outputwave,2)+k*dimdelta(outputwave,2)-kz[i][m][n])^2
//					Dim1PointNearest=m
//					Dim2PointNearest=n
//				Endif
//			Endfor
//			Endfor
//				
//			If(Dim0PointNearest==0||Dim0PointNearest==dimsize(inputwave,0)-1||Dim1PointNearest==0||Dim1PointNearest==dimsize(inputwave,1)-1||Dim2PointNearest==0||Dim2PointNearest==dimsize(inputwave,2)-1)
//				OutputWave[i][j][k] = 0//NaN
//			Else
//				Outputwave[i][j][k] = Inputwave[Dim0PointNearest][Dim1PointNearest][Dim2PointNearest] //No Interpolation.... Can be improved.
//			EndIf
//			
//			If(k==dimsize(outputwave,2)-1)
//				If(j==dimsize(outputwave,1)-1)
//					If(i==dimsize(outputwave,0)-1)
//						CenterEb=EbStartTracker3
//						Centerkx=kxstarttracker2
//						Centerkz=kzStartTracker
//					Else
//						Centerkx=kxstarttracker2
//						CenterEb=EbStartTracker2
//						centerkz=kzstarttracker
//					EndIf
//				Else
//					CenterEb=EbStartTracker1
//					Centerkx=KxStartTracker1
//					centerkz=kzstarttracker
//				EndIf
//			Else
//				CenterEb=dim0pointnearest
//				Centerkx=Dim1PointNearest
//				centerkz=dim2pointnearest
//			Endif
//			
//			If(k==0)
//				KxStartTracker1=Dim1PointNearest
//				EbStartTracker1=Dim0PointNearest
//				kzStartTracker=Dim2PointNearest
//			EndIf
//			
//			If(j==0)
//				kxStartTracker2=Dim1PointNearest
//				EbStartTracker2=Dim0PointNearest
//			EndIf
//			
//			If(i==0)
//				EbStartTracker3=Dim0PointNearest
//			EndIf
//					
//		endfor
//		endfor
//			progresswave[i] = datetime-starttime
//			
//			if(ProgressWave[i]>LastUpdate+30)
//				Print "Time Elapsed: " + num2str(trunc(100*ProgressWave[i]/60)/100) + " minutes. Estimated time remaining: " +num2str(trunc(100*(dimsize(progresswave,0)-i)*ProgressWave[i]/(i+1)/60)/100) + " minutes."
//				LastUpdate=ProgressWave[i]
//			EndIf
//			
//		endfor
		
	EndIf
	
	Killwaves EkWave
	killwaves eb, kx, kz
	killwaves SlitPerpAngleWave
	killwaves ProgressWave
	
	MakeNoise()
End