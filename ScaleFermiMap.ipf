#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "Macintosh HD:Users:tylerac:Documents:data:IGOR stuff_tc20200904:Noise"
//Based on design of ScalePhotDep - T Cochran

//Dim0 = Binding Energy. 0 is Ef. Neg is below Ef
//Dim1 = Analyzer Angle.
//Dim2 = Scanning angle

//Inputwave should be scaled such that Ef is zero and below Ef is positive binding energies

//20221019 Updated. There had been a mixup in the assingment of SAInverse and AAInverse. Fixed - TAC

Function ScaleFermiMap(Inputwave, AAzero,workfunc,ScanningDirectionZero,hv,Interpolate)
	Wave InputWave
	Variable AAzero
	Variable WorkFunc //>0
	Variable ScanningDirectionZero
	Variable hv
	Variable Interpolate //0==NO 1 == YES
	
	Variable NearestPointRadius=3
	
	//Step 1: Define some handy references
	
	//Step 2 : Make a numeral function that maps (Ek, AA, SA) -> (Eb,kx,ky). Use this is identify the offsets of the outputwave
	
	Duplicate /o inputwave Eb
	Eb=0
	Duplicate /o inputwave AA
	AA=0
	Duplicate /o inputwave SA
	SA=0
	Duplicate /o inputwave kx
	kx=0
	Duplicate /o inputwave ky
	ky=0
	
	Eb[][][]=dimoffset(inputwave,0)+p*dimdelta(inputwave,0)
	AA[][][]=(dimoffset(inputwave,1)+q*dimdelta(inputwave,1)-AAZero)*pi/180
	SA[][][]=(dimoffset(inputwave,2)+r*dimdelta(inputwave,2)-ScanningDirectionZero)*pi/180 //Scaled in Radians
	kx[][][]=.5121*sqrt(hv-WorkFunc-Eb[p][q][r])*cos(SA[p][q][r])*sin(AA[p][q][r])
	ky[][][]=.5121*sqrt(hv-WorkFunc-Eb[p][q][r])*sin(SA[p][q][r])
	
	Variable V_min, V_max
	
	Wavestats /q Eb
	Variable Dim0Low=V_min
	Variable Dim0HIgh=V_max
	
	Wavestats /q kx
	Variable Dim1Low = V_min
	Variable Dim1High = V_Max
	
	Wavestats /q ky
	Variable Dim2Low = V_min
	Variable Dim2High = V_max
	
	//Step 3 : Determine the size of the ouputwave and make it.
	
	Variable Dim0PixelSep = Dimdelta(inputwave,0)
	Variable Dim1PixelSep = .5121*sqrt(hv-WorkFunc-Eb[dimsize(inputwave,0)-1][0][0])*dimdelta(inputwave,1)*pi/180
	Variable Dim2PixelSep = .5121*sqrt(hv-WorkFunc-Eb[dimsize(inputwave,0)-1][0][0])*dimdelta(inputwave,2)*pi/180
	
	Variable Dim0Size = abs((Dim0High-Dim0Low)/Dim0PixelSep)+3
	Variable Dim1Size = abs((Dim1High-Dim1Low)/Dim1PixelSep) + 3
	Variable Dim2Size = abs((Dim2High- Dim2Low)/Dim2PixelSep) + 3
	
	String OutputwaveName = NameofWave(Inputwave)+"_kxkyScaled"
	Make /o /n=(Dim0Size,Dim1Size,Dim2Size) $OutputWaveName
	Wave OutputWave = $OutputWaveName
	OutputWave = 0
	
	Setscale /p x, dim0Low-dim0pixelsep,Dim0PixelSep,OutputWave
	setscale /p y, dim1Low-dim1pixelsep, dim1pixelsep,outputwave
	setscale /p z, dim2Low-dim2pixelsep, dim2PixelSep, Outputwave
	
	//Step 4: Read the inputwave, based on numerical inverse of Eb,kx,kz functions. Then write the outputwave.
	
	Variable i,j,k,l,m,n
	Variable a
	Variable Dim0PointNearest,Dim1PointNearest,Dim2PointNearest //The nearest points in the inputwave to the eb,kx,kz position of the outputwave
	Variable SAInverse, AAInverse //value of SA nd AA when inverse funcetion are applied to grid point in outputwave
	Variable SAFracIndex, AAFracIndex //fractional index of SAInverse and AAInverse in scale of InputWave
	Variable CenterEb=0,Centerkx=0,Centerky = 0
//	Variable aDim0Max = 2*dimdelta(outputwave,0)
//	Variable aDim1Max = 2*dimdelta(outputwave,1)
//	Variable aDim2Max = 2*dimdelta(outputwave,2)
	
	Make /o /n=(dimsize(outputwave,0)) ProgressWave
	Wave ProgressWave
	Variable /d starttime = datetime
	ProgressWave=-starttime
	
	Variable t0 = DateTime
	Make /O /D /N=(Dimsize(outputwave,0)) TimeKeepingWave //stuff for projecting finish time.
	TimeKeepingWave = 0
	Wave TimeKeepingWave
	Display TimeKeepingWave
	DoWindow /C TimeKeepingWindow
	ModifyGraph mode=3,marker=19
	Label left "minutes"
	Label bottom "slices"
	ModifyGraph swapXY=1
	Wave fit_TimeKeepingWave
	Variable Vertex = Dimsize(outputwave,0)/2-0.5
	Make/O /D/N=3/O W_coef
	Wave W_Coef
	W_coef[0] = {-1,Vertex,1}
	Variable LastUpdate
	
	//Variable EbStartTracker1=0,EbStartTracker2=0,EbStartTracker3=0, kxStartTracker1=0,kxstarttracker2=0,kystarttracker=0
	
	If(Interpolate==1)
	
//		Duplicate /o OutputWave AAInverseWave //Analyzer angle inverse wave
//		Duplicate /o OutputWave SAInverseWave //Scanning angle inverse wave 
		
		for(i=0;i<dimsize(outputwave,0);i+=1)
		for(j=0;j<dimsize(outputwave,1);j+=1)
		for(k=0;k<dimsize(outputwave,2);k+=1)
			//hvInverse=(IndexToScale(OutputWave,j,1)*Sec(SlitPerpAngleWave[k]*pi/180)/.5121)^2+(IndexToScale(OutputWave,k,2)*Sec(SlitPerpAngleWave[k]*pi/180)/.5121)^2-innerpot*Sec(SlitPerpAngleWave[k]*pi/180)^2+workfunc-IndexToScale(OutputWave,i,0)
			If(IndexToScale(OutputWave,k,2)<0)
				//SAInverse=-ASin(Abs(IndexToScale(OutputWave,k,2))/sqrt(.5121^2*(hv-workfunc)-IndexToScale(OutputWave,j,1)^2))*180/Pi+ScanningDirectionZero
				SAInverse=-ASin(Abs(IndexToScale(OutputWave,k,2))/(0.5121*sqrt(hv-workfunc)))*180/pi+ScanningDirectionZero
			Else
				//SAInverse=ASin(Abs(IndexToScale(OutputWave,k,2))/sqrt(.5121^2*(hv-workfunc)-IndexToScale(OutputWave,j,1)^2))*180/Pi+ScanningDirectionZero
				SAInverse=ASin(Abs(IndexToScale(OutputWave,k,2))/(0.5121*sqrt(hv-workfunc)))*180/pi+ScanningDirectionZero
			EndIf
			
			If(IndexToScale(Outputwave,j,1)<0)
				//AAInverse=-ASin(Abs(IndexToScale(OutputWave,j,1))/(.5121*Sqrt(hv-workfunc)))*180/Pi+AAZero
				AAInverse=-ASin(Abs(IndexToScale(OutputWave,j,1))/sqrt(0.5121^2*(hv-workfunc)-IndexToScale(OutputWave,k,2)^2))*180/Pi+AAZero
			Else
				//AAInverse=ASin(Abs(IndexToScale(OutputWave,j,1))/(.5121*Sqrt(hv-workfunc)))*180/Pi+AAZero
				AAInverse=ASin(Abs(IndexToScale(OutputWave,j,1))/sqrt(0.5121^2*(hv-workfunc)-IndexToScale(OutputWave,k,2)^2))*180/Pi+AAZero
			EndIf
			
//			If(IndexToScale(OutputWave,j,1)<0)
//				ThetaInverse=-ACos(Sqrt(IndexToScale(OutputWave,k,2)^2-InnerPot*.5121^2)/Sqrt(IndexToScale(OutputWave,j,1)^2+IndexToScale(OutputWave,k,2)^2-InnerPot*.5121^2))*180/Pi+AAZero
//			Else
//				ThetaInverse=ACos(Sqrt(IndexToScale(OutputWave,k,2)^2-InnerPot*.5121^2)/Sqrt(IndexToScale(OutputWave,j,1)^2+IndexToScale(OutputWave,k,2)^2-InnerPot*.5121^2))*180/Pi+AAZero
//			EndIf
			
			SAFracIndex=(SAInverse-Dimoffset(InputWave,2))/DimDelta(InputWave,2)
			AAFracIndex=(AAInverse-DimOffset(InputWave,1))/DimDelta(InputWave,1)
			
			If(SAFracIndex<0 || AAFracIndex<0 || SAFracIndex>dimsize(Inputwave,2)-1 || AAFracIndex>dimsize(inputwave,1)-1)
				Outputwave[i][j][k]=0
			Else
				Outputwave[i][j][k]=(1-(AAFracIndex-Trunc(AAFracIndex)))*(1-(SAFracIndex-Trunc(SAFracIndex)))*InputWave[i][Trunc(AAFracIndex)][Trunc(SAFracIndex)]+(1-(AAFracIndex-Trunc(AAFracIndex)))*(SAFracIndex-Trunc(SAFracIndex))*InputWave[i][Trunc(AAFracIndex)][Trunc(SAFracIndex)+1]+(AAFracIndex-Trunc(AAFracIndex))*(1-(SAFracIndex-Trunc(SAFracIndex)))*InputWave[i][Trunc(AAFracIndex)+1][Trunc(SAFracIndex)]+(Trunc(AAFracIndex)-AAFracIndex)*(Trunc(SAFracIndex)-SAFracIndex)*InputWave[i][Trunc(AAFracIndex)+1][Trunc(SAFracIndex)+1]
				//Outputwave[i][j][k]=(1-(ThetaFracIndex-Trunc(ThetaFracIndex)))*(1-(hvFracIndex-Trunc(hvFracIndex)))*InputWave[i][Trunc(ThetaFracIndex)][Trunc(hvFracIndex)]+(1-(ThetaFracIndex-Trunc(ThetaFracIndex)))*(hvFracIndex-Trunc(hvFracIndex))*InputWave[i][Trunc(ThetaFracIndex)][Trunc(hvFracIndex)+1]+(ThetaFracIndex-Trunc(ThetaFracIndex))*(1-(hvFracIndex-Trunc(hvFracIndex)))*InputWave[i][Trunc(ThetaFracIndex)+1][Trunc(hvFracIndex)]+(Trunc(ThetaFracIndex)-ThetaFracIndex)*(Trunc(hvFracIndex)-hvFracIndex)*InputWave[i][Trunc(ThetaFracIndex)+1][Trunc(hvFracIndex)+1]
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
			If(IndexToScale(OutputWave,k,2)<0)
				SAInverse=-ASin(IndexToScale(OutputWave,k,2)/sqrt(.5121^2*(hv-workfunc)-IndexToScale(OutputWave,j,1)^2))*180/Pi+ScanningDirectionZero
			Else
				SAInverse=ASin(IndexToScale(OutputWave,k,2)/sqrt(.5121^2*(hv-workfunc)-IndexToScale(OutputWave,j,1)^2))*180/Pi+ScanningDirectionZero
			EndIf
			
			If(IndexToScale(Outputwave,j,1)<0)
				AAInverse=-ASin(IndexToScale(OutputWave,j,1)/(.5121*Sqrt(hv-workfunc)))*180/Pi+AAZero
			Else
				AAInverse=ASin(IndexToScale(OutputWave,j,1)/(.5121*Sqrt(hv-workfunc)))*180/Pi+AAZero
			EndIf
//			hvInverse=(IndexToScale(OutputWave,j,1)*Sec(SlitPerpAngleWave[k]*pi/180)/.5121)^2+(IndexToScale(OutputWave,k,2)*Sec(SlitPerpAngleWave[k]*pi/180)/.5121)^2-innerpot*Sec(SlitPerpAngleWave[k]*pi/180)^2+workfunc-IndexToScale(OutputWave,i,0)
//			If(IndexToScale(OutputWave,j,1)<0)
//				ThetaInverse=-ACos(Sqrt(IndexToScale(OutputWave,k,2)^2-InnerPot*.5121^2)/Sqrt(IndexToScale(OutputWave,j,1)^2+IndexToScale(OutputWave,k,2)^2-InnerPot*.5121^2))*180/Pi+AAZero
//			Else
//				ThetaInverse=ACos(Sqrt(IndexToScale(OutputWave,k,2)^2-InnerPot*.5121^2)/Sqrt(IndexToScale(OutputWave,j,1)^2+IndexToScale(OutputWave,k,2)^2-InnerPot*.5121^2))*180/Pi+AAZero
//			EndIf
			SAFracIndex=(SAInverse-Dimoffset(InputWave,2))/DimDelta(InputWave,2)
			AAFracIndex=(AAInverse-DimOffset(InputWave,1))/DimDelta(InputWave,1)
//			hvFracIndex=(hvInverse-Dimoffset(InputWave,2))/DimDelta(InputWave,2)
//			ThetaFracIndex=(ThetaInverse-DimOffset(InputWave,1))/DimDelta(InputWave,1)
			
			If(SAFracIndex<0 || AAFracIndex<0 || SAFracIndex>dimsize(Inputwave,2)-1 || AAFracIndex>dimsize(inputwave,1)-1)
				Outputwave[i][j][k]=0
			Else
				//Outputwave[i][j][k]=(1-(ThetaFracIndex-Trunc(ThetaFracIndex)))*(1-(hvFracIndex-Trunc(hvFracIndex)))*InputWave[i][Trunc(ThetaFracIndex)][Trunc(hvFracIndex)]+(1-(ThetaFracIndex-Trunc(ThetaFracIndex)))*(hvFracIndex-Trunc(hvFracIndex))*InputWave[i][Trunc(ThetaFracIndex)][Trunc(hvFracIndex)+1]+(ThetaFracIndex-Trunc(ThetaFracIndex))*(1-(hvFracIndex-Trunc(hvFracIndex)))*InputWave[i][Trunc(ThetaFracIndex)+1][Trunc(hvFracIndex)]+(Trunc(ThetaFracIndex)-ThetaFracIndex)*(Trunc(hvFracIndex)-hvFracIndex)*InputWave[i][Trunc(ThetaFracIndex)+1][Trunc(hvFracIndex)+1]
				Outputwave[i][j][k]=Inputwave[i][ScaleToIndex(InputWave,AAInverse,1)][ScaleToIndex(InputWave,SAInverse,2)]
			EndIf
			
		endfor
		endfor
		
			progresswave[i] = datetime-starttime
			
			if(ProgressWave[i]>LastUpdate+30)
				Print "Time Elapsed: " + num2str(trunc(100*ProgressWave[i]/60)/100) + " minutes. Estimated time remaining: " +num2str(trunc(100*(dimsize(progresswave,0)-i)*ProgressWave[i]/(i+1)/60)/100) + " minutes."
				LastUpdate=ProgressWave[i]
			EndIf
		
		endfor
	EndIf
		
		
		
		
//The below commented section is for just finding the nearest point without invoking an inverse function for the mapping from angle to k space.	
//		For(i=0;i<dimsize(outputwave,0);i+=1)
//		For(j=0;j<dimsize(outputwave,1);j+=1)
//		for(k=0;k<dimsize(outputwave,2);k+=1)
//			a=inf
	//		Dim0PointNearest=0
	//		Dim1PointNearest=0
	//		Dim2PointNearest=0
	//		For(l=max(CenterEb-3,0);l<min(CenterEb+3,dimsize(inputwave,0));l+=1)
	//		For(m=max(Centerkx-3,0);m<min(Centerkx+3,dimsize(inputwave,1));m+=1)
	//		For(n=max(Centerky-3,0);n<min(Centerky+3,dimsize(inputwave,2));n+=1)
	//			If(a>(dimoffset(Outputwave,0)+i*dimdelta(outputwave,0)-Eb[l][m][n])^2+(dimoffset(outputwave,1)+j*dimdelta(outputwave,1)-kx[l][m][n])^2+(dimoffset(outputwave,2)+k*dimdelta(outputwave,2)-ky[l][m][n])^2)
	//				a=(dimoffset(Outputwave,0)+i*dimdelta(outputwave,0)-Eb[l][m][n])^2+(dimoffset(outputwave,1)+j*dimdelta(outputwave,1)-kx[l][m][n])^2+(dimoffset(outputwave,2)+k*dimdelta(outputwave,2)-ky[l][m][n])^2
	//				Dim0PointNearest=l
	//				Dim1PointNearest=m
	//				Dim2PointNearest=n
	//			Endif
	//		Endfor
	//		Endfor
	//		endfor
	
//			For(m=max(Centerkx-NearestPointRadius,0);m<min(Centerkx+NearestPointRadius,dimsize(inputwave,1));m+=1)
//			For(n=max(Centerky-NearestPointRadius,0);n<min(Centerky+NearestPointRadius,dimsize(inputwave,2));n+=1)
//				If(a>(dimoffset(Outputwave,0)+i*dimdelta(outputwave,0)-Eb[i][m][n])^2+(dimoffset(outputwave,1)+j*dimdelta(outputwave,1)-kx[i][m][n])^2+(dimoffset(outputwave,2)+k*dimdelta(outputwave,2)-ky[i][m][n])^2)
//					a=(dimoffset(Outputwave,0)+i*dimdelta(outputwave,0)-Eb[i][m][n])^2+(dimoffset(outputwave,1)+j*dimdelta(outputwave,1)-kx[i][m][n])^2+(dimoffset(outputwave,2)+k*dimdelta(outputwave,2)-ky[i][m][n])^2
//					Dim0PointNearest=i
//					Dim1PointNearest=m
//					Dim2PointNearest=n
//				Endif
//			Endfor
//			Endfor
//			
//			If(Dim0PointNearest==0||Dim0PointNearest==dimsize(inputwave,0)-1||Dim1PointNearest==0||Dim1PointNearest==dimsize(inputwave,1)-1||Dim2PointNearest==0||Dim2PointNearest==dimsize(inputwave,2)-1)
//				OutputWave[i][j][k] = NaN
//			Else
//				Outputwave[i][j][k] = Inputwave[Dim0PointNearest][Dim1PointNearest][Dim2PointNearest] //No Interpolation.... Can be improved.
//			EndIf
//			
//			If(k==dimsize(outputwave,2)-1)
//				If(j==dimsize(outputwave,1)-1)
//					If(i==dimsize(outputwave,0)-1)
//						CenterEb=EbStartTracker3
//						Centerkx=kxstarttracker2
//						Centerky=kyStartTracker
//					Else
//						Centerkx=kxstarttracker2
//						CenterEb=EbStartTracker2
//						centerky=kystarttracker
//					EndIf
//				Else
//					CenterEb=EbStartTracker1
//					Centerkx=KxStartTracker1
//					centerky=kystarttracker
//				EndIf
//			Else
//				CenterEb=dim0pointnearest
//				Centerkx=Dim1PointNearest
//				centerky=dim2pointnearest
//			Endif
//			
//			If(k==0)
//				KxStartTracker1=Dim1PointNearest
//				EbStartTracker1=Dim0PointNearest
//				kyStartTracker=Dim2PointNearest
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
//		endfor
//		endfor
//		
//			TimeKeepingWave[i]=(DateTime-t0)/60
//			If(i==0)
//				LastUpdate=timekeepingwave[0]
//			endif
//			
//			If(i>=3 && timekeepingwave[i]-lastupdate>.5)
//				//CurveFit /Q/X=1/NTHR=0 poly 4,  TimeKeepingWave[0,i] /D
//				FuncFit /Q /X=1/H="010"/NTHR=0 TimeFit W_coef TimeKeepingWave[0,i] /D 
//				Print "Projected finishing time: " + Secs2Date(fit_TimeKeepingWave[dimsize(fit_TimeKeepingWave,0)-1]*60+t0,1)+ " " +Secs2Time(fit_TimeKeepingWave[dimsize(fit_TimeKeepingWave,0)-1]*60+t0,1)
//				LastUpdate=timekeepingwave[i]
//			Else
//			EndIf
			
	//	progresswave[i] = datetime-starttime
	//		
	//	Print "Time Elapsed: " + num2str(trunc(100*ProgressWave[i]/60)/100) + " minutes. Estimated time remaining: " +num2str(trunc(100*(dimsize(progresswave,0)-i)*ProgressWave[i]/(i+1)/60)/100) + " minutes."
		
		//endfor
	
	Print "TotalTime: " +num2str((DateTime-t0)/60) + " minutes"
	
	KillWindow TimeKeepingWindow
	
	killwaves eb, aa, sa,kx,ky
	
	MakeNoise()
	
End

Function TimeFit(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = -A*(x-B)^3+C*x-A*B^3
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = A
	//CurveFitDialog/ w[1] = B
	//CurveFitDialog/ w[2] = C

	return -w[0]*(x-w[1])^3+w[2]*x-w[0]*w[1]^3
End