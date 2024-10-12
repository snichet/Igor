#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function DrawHexagons(LatticeConstant,RotationAngle,Plot)
	Variable LatticeConstant
	Variable RotationAngle
	Variable Plot
	
	Make /o /N=(30,2) HoneyComb_x
	Make /o /N=(30,2) HoneyComb_y
	
	Variable x=LatticeConstant/2
	Variable y1=LatticeConstant/2*Tan(Pi/6)
	Variable y2=LatticeConstant/2/Cos(Pi/6)
	
	HoneyComb_x[0][0]=x
	HoneyComb_x[0][1]=0
	HoneyComb_y[0][0]=y1
	HoneyComb_y[0][1]=y2
	
	HoneyComb_x[1][0]=0
	HoneyComb_x[1][1]=-x
	HoneyComb_y[1][0]=y2
	HoneyComb_y[1][1]=y1
	
	HoneyComb_x[2][0]=-x
	HoneyComb_x[2][1]=-x
	HoneyComb_y[2][0]=y1
	HoneyComb_y[2][1]=-y1
	
	HoneyComb_x[3][0]=-x
	HoneyComb_x[3][1]=0
	HoneyComb_y[3][0]=-y1
	HoneyComb_y[3][1]=-y2
	
	HoneyComb_x[4][0]=0
	HoneyComb_x[4][1]=x
	HoneyComb_y[4][0]=-y2
	HoneyComb_y[4][1]=-y1
	
	HoneyComb_x[5][0]=x
	HoneyComb_x[5][1]=x
	HoneyComb_y[5][0]=-y1
	HoneyComb_y[5][1]=y1
	
	HoneyComb_x[6][0]=x
	HoneyComb_x[6][1]=2*x
	HoneyComb_y[6][0]=y1
	HoneyComb_y[6][1]=y2
	
	HoneyComb_x[7][0]=0
	HoneyComb_x[7][1]=0
	HoneyComb_y[7][0]=y2
	HoneyComb_y[7][1]=y2+2*y1
	
	HoneyComb_x[8][0]=-x
	HoneyComb_x[8][1]=-2*x
	HoneyComb_y[8][0]=y1
	HoneyComb_y[8][1]=y2
	
	HoneyComb_x[9][0]=x
	HoneyComb_x[9][1]=2*x
	HoneyComb_y[9][0]=-y1
	HoneyComb_y[9][1]=-y2
	
	HoneyComb_x[10][0]=0
	HoneyComb_x[10][1]=0
	HoneyComb_y[10][0]=-y2
	HoneyComb_y[10][1]=-y2-2*y1
	
	HoneyComb_x[11][0]=-x
	HoneyComb_x[11][1]=-2*x
	HoneyComb_y[11][0]=-y1
	HoneyComb_y[11][1]=-y2
	
	HoneyComb_x[12][0]=3*x
	HoneyComb_x[12][1]=2*x
	HoneyComb_y[12][0]=y1
	HoneyComb_y[12][1]=y2
	
	HoneyComb_x[13][0]=2*x
	HoneyComb_x[13][1]=2*x
	HoneyComb_y[13][0]=y2
	HoneyComb_y[13][1]=y2+2*y1
	
	HoneyComb_x[14][0]=2*x
	HoneyComb_x[14][1]=x
	HoneyComb_y[14][0]=y2+2*y1
	HoneyComb_y[14][1]=2*y2+y1
	
	HoneyComb_x[15][0]=x
	HoneyComb_x[15][1]=0
	HoneyComb_y[15][0]=2*y2+y1
	HoneyComb_y[15][1]=y2+2*y1
	
	HoneyComb_x[16][0]=-3*x
	HoneyComb_x[16][1]=-2*x
	HoneyComb_y[16][0]=y1
	HoneyComb_y[16][1]=y2
	
	HoneyComb_x[17][0]=-2*x
	HoneyComb_x[17][1]=-2*x
	HoneyComb_y[17][0]=y2
	HoneyComb_y[17][1]=y2+2*y1
	
	HoneyComb_x[18][0]=-2*x
	HoneyComb_x[18][1]=-x
	HoneyComb_y[18][0]=y2+2*y1
	HoneyComb_y[18][1]=2*y2+y1
	
	HoneyComb_x[19][0]=-x
	HoneyComb_x[19][1]=0
	HoneyComb_y[19][0]=2*y2+y1
	HoneyComb_y[19][1]=y2+2*y1
	
	HoneyComb_x[20][0]=3*x
	HoneyComb_x[20][1]=2*x
	HoneyComb_y[20][0]=-y1
	HoneyComb_y[20][1]=-y2
	
	HoneyComb_x[21][0]=2*x
	HoneyComb_x[21][1]=2*x
	HoneyComb_y[21][0]=-y2
	HoneyComb_y[21][1]=-y2-2*y1
	
	HoneyComb_x[22][0]=2*x
	HoneyComb_x[22][1]=x
	HoneyComb_y[22][0]=-y2-2*y1
	HoneyComb_y[22][1]=-2*y2-y1
	
	HoneyComb_x[23][0]=x
	HoneyComb_x[23][1]=0
	HoneyComb_y[23][0]=-2*y2-y1
	HoneyComb_y[23][1]=-y2-2*y1
	
	HoneyComb_x[24][0]=-3*x
	HoneyComb_x[24][1]=-2*x
	HoneyComb_y[24][0]=-y1
	HoneyComb_y[24][1]=-y2
	
	HoneyComb_x[25][0]=-2*x
	HoneyComb_x[25][1]=-2*x
	HoneyComb_y[25][0]=-y2
	HoneyComb_y[25][1]=-y2-2*y1
	
	HoneyComb_x[26][0]=-2*x
	HoneyComb_x[26][1]=-x
	HoneyComb_y[26][0]=-y2-2*y1
	HoneyComb_y[26][1]=-2*y2-y1
	
	HoneyComb_x[27][0]=-x
	HoneyComb_x[27][1]=0
	HoneyComb_y[27][0]=-2*y2-y1
	HoneyComb_y[27][1]=-y2-2*y1
	
	HoneyComb_x[28][0]=3*x
	HoneyComb_x[28][1]=3*x
	HoneyComb_y[28][0]=-y1
	HoneyComb_y[28][1]=y1
	
	HoneyComb_x[29][0]=-3*x
	HoneyComb_x[29][1]=-3*x
	HoneyComb_y[29][0]=-y1
	HoneyComb_y[29][1]=y1
	
	variable i
	
	If(RotationAngle==0)
		If(Plot==1)
			For(i=0;i<dimsize(Honeycomb_x,0);i+=1)
				Appendtograph Honeycomb_y[i][] vs Honeycomb_x[i][]
			EndFor
		EndIf
	Else
		Make /o /N=(30,2) HoneyComb_xr
		Make /o /N=(30,2) HoneyComb_yr
		HoneyComb_xr[][]=HoneyComb_x[p][q]*Cos(RotationAngle*pi/180)-Honeycomb_y[p][q]*Sin(RotationAngle*pi/180)
		HoneyComb_yr[][]=HoneyComb_y[p][q]*Cos(RotationAngle*pi/180)+HoneyComb_x[p][q]*Sin(RotationAngle*pi/180)
		If(Plot==1)
			For(i=0;i<dimsize(Honeycomb_xr,0);i+=1)
				AppendtoGraph Honeycomb_yr[i][] vs Honeycomb_xr[i][]
			EndFor
		EndIf
		
	EndIf
	
End