#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function C4Sym(InputWave,CenterX, CenterY)

	Wave InputWave
	Variable CenterX
	Variable CenterY
	
	Variable ImageSizeX
	Variable ImageSizeY
	Variable ImageSize
	
	If(CenterX-Dimoffset(Inputwave,0)<Dimoffset(inputwave,0)+Dimdelta(inputwave,0)*(dimsize(inputwave,0)-1)-CenterX)
		ImageSizeX = CenterX-Dimoffset(Inputwave,0)
	Else
		ImageSizeX = Dimoffset(inputwave,0)+Dimdelta(inputwave,0)*(dimsize(inputwave,0)-1)-CenterX
	EndIf
	
	If(Centery-Dimoffset(Inputwave,1)<Dimoffset(inputwave,1)+Dimdelta(inputwave,1)*(dimsize(inputwave,1)-1)-CenterY)
		ImageSizeY = CenterY-Dimoffset(Inputwave,1)
	Else
		ImageSizeY = Dimoffset(inputwave,1)+Dimdelta(inputwave,1)*(dimsize(inputwave,1)-1)-CenterY
	EndIf
	
	If(ImageSizeX<ImageSizeY)
		ImageSize = 2*ImageSizeX
	Else
		ImageSize = 2*ImageSizeY
	EndIf
	
	Variable PixSize
	
	If(DimDelta(Inputwave,0)<Dimdelta(Inputwave,1))
		PixSize = DimDelta(Inputwave,0)
	Else
		PixSize = DimDelta(Inputwave,1)
	EndIf
	
	String OutputWaveName
	Variable i,a,j
	
	Do
		OutputWaveName = NameofWave(Inputwave)+"_C4"+num2str(i)
		i+=1
		a=exists(OutputWaveName)
	While(a==1)
	Make /n=(ImageSize/PixSize+1, ImageSize/PixSize+1) $OutputWaveName
	Wave OutputWave = $OutputWaveName
	
	Setscale /p x, CenterX-ImageSize/2,PixSize,OutputWave
	Setscale /p y, Centery-ImageSize/2,PixSize,OutputWave
	
	Duplicate /o OutputWave Temp1
	Duplicate /o OutputWave Temp2
	Duplicate /o OutputWave Temp3
	Duplicate /o OutputWave Temp4
	
	For(i=0;i<dimsize(outputwave,0);i+=1)
	For(j=0;j<dimsize(outputwave,1);j+=1)
		Temp1[i][j]=InputWave(Dimoffset(Outputwave,0)+i*dimdelta(Outputwave,0))(Dimoffset(Outputwave,1)+j*dimdelta(outputwave,1))
		Temp2[i][j]=Inputwave(Dimoffset(Outputwave,1)+j*dimdelta(outputwave,1))(-(Dimoffset(Outputwave,0)+i*dimdelta(Outputwave,0)))
		Temp3[i][j]=InputWave(-(Dimoffset(Outputwave,0)+i*dimdelta(Outputwave,0)))(-(Dimoffset(Outputwave,1)+j*dimdelta(outputwave,1)))
		Temp4[i][j]=Inputwave(-(Dimoffset(Outputwave,1)+j*dimdelta(outputwave,1)))(Dimoffset(Outputwave,0)+i*dimdelta(Outputwave,0))
		Outputwave[i][j]=(Temp1[i][j]+Temp2[i][j]+Temp3[i][j]+Temp4[i][j])/4
	EndFor
	EndFor	
	
	Display
	AppendImage Outputwave
		
	Note Outputwave "This wave was symmeterized with C4Sym"
	Note Outputwave "Original Wave Name :" + Nameofwave(InputWave)
	Note Outputwave "CenterX = " + Num2Str(CenterX)
	Note Outputwave "CenterY = " + Num2Str(CenterY)
	Note Outputwave "Output Wave Name: " + NameofWave(OutputWave)
	
	Print "Output Wave of 4FoldRotSym: " + NameofWave(OutputWave)
	
	Killwaves Temp1, temp2, temp3, temp4
	
End

Function C2Sym(InputWave,CenterX, CenterY)

	Wave InputWave
	Variable CenterX
	Variable CenterY
	
	Variable ImageSizeX
	Variable ImageSizeY
	Variable ImageSize
	
	If(CenterX-Dimoffset(Inputwave,0)<Dimoffset(inputwave,0)+Dimdelta(inputwave,0)*(dimsize(inputwave,0)-1)-CenterX)
		ImageSizeX = CenterX-Dimoffset(Inputwave,0)
	Else
		ImageSizeX = Dimoffset(inputwave,0)+Dimdelta(inputwave,0)*(dimsize(inputwave,0)-1)-CenterX
	EndIf
	
	If(Centery-Dimoffset(Inputwave,1)<Dimoffset(inputwave,1)+Dimdelta(inputwave,1)*(dimsize(inputwave,1)-1)-CenterY)
		ImageSizeY = CenterY-Dimoffset(Inputwave,1)
	Else
		ImageSizeY = Dimoffset(inputwave,1)+Dimdelta(inputwave,1)*(dimsize(inputwave,1)-1)-CenterY
	EndIf
	
	If(ImageSizeX<ImageSizeY)
		ImageSize = 2*ImageSizeX
	Else
		ImageSize = 2*ImageSizeY
	EndIf
	
	Variable PixSize
	
	If(DimDelta(Inputwave,0)<Dimdelta(Inputwave,1))
		PixSize = DimDelta(Inputwave,0)
	Else
		PixSize = DimDelta(Inputwave,1)
	EndIf
	
	String OutputWaveName
	Variable i,a,j
	
	Do
		OutputWaveName = NameofWave(Inputwave)+"_C2"+num2str(i)
		i+=1
		a=exists(OutputWaveName)
	While(a==1)
	Make /n=(ImageSize/PixSize+1, ImageSize/PixSize+1) $OutputWaveName
	Wave OutputWave = $OutputWaveName
	
	Setscale /p x, CenterX-ImageSize/2,PixSize,OutputWave
	Setscale /p y, Centery-ImageSize/2,PixSize,OutputWave
	
	Duplicate /o OutputWave Temp1
	Duplicate /o OutputWave Temp2
	
	For(i=0;i<dimsize(outputwave,0);i+=1)
	For(j=0;j<dimsize(outputwave,1);j+=1)
		Temp1[i][j]=InputWave(Dimoffset(Outputwave,0)+i*dimdelta(Outputwave,0))(Dimoffset(Outputwave,1)+j*dimdelta(outputwave,1))
		Temp2[i][j]=InputWave(-(Dimoffset(Outputwave,0)+i*dimdelta(Outputwave,0)))(-(Dimoffset(Outputwave,1)+j*dimdelta(outputwave,1)))
		Outputwave[i][j]=(Temp1[i][j]+Temp2[i][j])/2
	EndFor
	EndFor	
	
	Display
	AppendImage Outputwave
		
	Note Outputwave "This wave was symmeterized with C2Sym"
	Note Outputwave "Original Wave Name :" + Nameofwave(InputWave)
	Note Outputwave "CenterX = " + Num2Str(CenterX)
	Note Outputwave "CenterY = " + Num2Str(CenterY)
	Note Outputwave "Output Wave Name: " + NameofWave(OutputWave)
	
	Print "Output Wave of 2FoldRotSym: " + NameofWave(OutputWave)
	
	Killwaves Temp1, temp2
	
End

Function C3Sym(InputWave,CenterX,CenterY,Graph)

Wave InputWave
Variable CenterX
Variable CenterY
Variable Graph //if 1 will graph output wave

Variable Radius

If(CenterX>dimoffset(inputwave,0)+dimsize(inputwave,0)/2*dimdelta(inputwave,1))
	If(CenterY>dimoffset(inputwave,1)+dimsize(inputwave,1)/2*dimdelta(inputwave,1))
		Radius=sqrt((centerx-dimoffset(inputwave,0))^2+(centery-dimoffset(inputwave,1))^2)
	Else
		Radius=sqrt((centerx-dimoffset(inputwave,0))^2+(dimoffset(inputwave,1)+dimsize(inputwave,1)*dimdelta(inputwave,1)-centery)^2)
	EndIf
Else
	If(CenterY>dimoffset(inputwave,1)+dimsize(inputwave,1)/2*dimdelta(inputwave,1))
		Radius=sqrt((dimoffset(inputwave,0)+dimsize(inputwave,0)*dimdelta(inputwave,0)-centerx)^2+(centery-dimoffset(inputwave,1))^2)
	Else
		Radius=sqrt((dimoffset(inputwave,0)+dimsize(inputwave,0)*dimdelta(inputwave,0)-centerx)^2+(dimoffset(inputwave,1)+dimsize(inputwave,1)*dimdelta(inputwave,1)-centery)^2)
	EndIf
EndIf

String OutputWaveName = NameofWave(InputWave)+"_C3"
Make /O /N=(2*Radius/Min(dimdelta(inputwave,0),dimdelta(inputwave,1)),2*Radius/Min(dimdelta(inputwave,0),dimdelta(inputwave,1))) $OutputWaveName
Wave OutputWave = $OutputWaveName
Setscale /p x, Centerx-radius, Min(dimdelta(inputwave,0),dimdelta(inputwave,1)),OutputWave
Setscale /p y, Centery-radius, Min(dimdelta(inputwave,0),dimdelta(inputwave,1)),OutputWave

Duplicate /o OutputWave temp1
Duplicate /o OutputWave temp2
Duplicate /o OutputWave temp3

variable i,j,xout,yout,xrot1,yrot1,xrot2,yrot2

for(i=0;i<dimsize(outputwave,0);i+=1)
for(j=0;j<dimsize(outputwave,1);j+=1)
	xout = dimoffset(outputwave,0)+i*dimdelta(outputwave,0)
	yout = dimoffset(outputwave,1)+j*dimdelta(outputwave,1)
	xrot1 = 1/2*(-(xout-centerx)-sqrt(3)*(yout-centery)+2*centerx)
	yrot1 = 1/2*(sqrt(3)*(xout-centerx)-(yout-centery)+2*centery)
	xrot2 = 1/2*(-(xout-centerx)+sqrt(3)*(yout-centery)+2*centerx)
	yrot2 = 1/2*(-sqrt(3)*(xout-centerx)-(yout-centery)+2*centery)
	//print yout
	//print Max(Min(yout,dimoffset(inputwave,1)+(dimsize(inputwave,1)-1)*dimdelta(inputwave,1)),dimoffset(inputwave,1))
	if(xout<dimoffset(inputwave,0)+(dimsize(inputwave,0)-1)*dimdelta(inputwave,0) && xout>dimoffset(Inputwave,0) && yout<dimoffset(inputwave,1)+(dimsize(inputwave,1)-1)*dimdelta(inputwave,1) && yout>dimoffset(inputwave,1))
		Temp1[i][j]=InputWave(Max(Min(xout,dimoffset(inputwave,0)+(dimsize(inputwave,0)-1)*dimdelta(inputwave,0)),dimoffset(inputwave,0)))(Max(Min(yout,dimoffset(inputwave,1)+(dimsize(inputwave,1)-1)*dimdelta(inputwave,1)),dimoffset(inputwave,1)))
	Else
		Temp1[i][j]=0
	EndIf
	if(xrot1<dimoffset(inputwave,0)+(dimsize(inputwave,0)-1)*dimdelta(inputwave,0) && xrot1>dimoffset(Inputwave,0) && yrot1<dimoffset(inputwave,1)+(dimsize(inputwave,1)-1)*dimdelta(inputwave,1) && yrot1>dimoffset(inputwave,1))
		Temp2[i][j]=InputWave(Max(Min(xrot1,dimoffset(inputwave,0)+(dimsize(inputwave,0)-1)*dimdelta(inputwave,0)),dimoffset(inputwave,0)))(Max(Min(yrot1,dimoffset(inputwave,1)+(dimsize(inputwave,1)-1)*dimdelta(inputwave,1)),dimoffset(inputwave,1)))
	else
		temp2[i][j]=0
	endif
	if(xrot2<dimoffset(inputwave,0)+(dimsize(inputwave,0)-1)*dimdelta(inputwave,0) && xrot2>dimoffset(Inputwave,0) && yrot2<dimoffset(inputwave,1)+(dimsize(inputwave,1)-1)*dimdelta(inputwave,1) && yrot2>dimoffset(inputwave,1))
		Temp3[i][j]=InputWave(Max(Min(xrot2,dimoffset(inputwave,0)+(dimsize(inputwave,0)-1)*dimdelta(inputwave,0)),dimoffset(inputwave,0)))(Max(Min(yrot2,dimoffset(inputwave,1)+(dimsize(inputwave,1)-1)*dimdelta(inputwave,1)),dimoffset(inputwave,1)))
	else
		temp3[i][j]=0
	endif
	Outputwave[i][j]=(Temp1[i][j]+Temp2[i][j]+Temp3[i][j])/3
endfor
endfor

If(Graph==1)
	display;appendimage outputwave
EndIf

killwaves temp1, temp2, temp3

End

Function C3CubeSym(InputWave,CenterX, CenterY)
Wave InputWave
Variable CenterX
Variable CenterY
Variable Graph

Variable Radius

If(CenterX>dimoffset(inputwave,0)+dimsize(inputwave,0)/2*dimdelta(inputwave,1))
	If(CenterY>dimoffset(inputwave,1)+dimsize(inputwave,1)/2*dimdelta(inputwave,1))
		Radius=sqrt((centerx-dimoffset(inputwave,0))^2+(centery-dimoffset(inputwave,1))^2)
	Else
		Radius=sqrt((centerx-dimoffset(inputwave,0))^2+(dimoffset(inputwave,1)+dimsize(inputwave,1)*dimdelta(inputwave,1)-centery)^2)
	EndIf
Else
	If(CenterY>dimoffset(inputwave,1)+dimsize(inputwave,1)/2*dimdelta(inputwave,1))
		Radius=sqrt((dimoffset(inputwave,0)+dimsize(inputwave,0)*dimdelta(inputwave,0)-centerx)^2+(centery-dimoffset(inputwave,1))^2)
	Else
		Radius=sqrt((dimoffset(inputwave,0)+dimsize(inputwave,0)*dimdelta(inputwave,0)-centerx)^2+(dimoffset(inputwave,1)+dimsize(inputwave,1)*dimdelta(inputwave,1)-centery)^2)
	EndIf
EndIf

//Radius/=Sqrt(2)
//print 2*Radius/Min(dimdelta(inputwave,0),dimdelta(inputwave,1))
//print 2*Radius/Min(dimdelta(inputwave,0),dimdelta(inputwave,1)),dimsize(inputwave,2)
//return(0)

String OutputWaveName = NameofWave(InputWave)+"_C3"
Make /O /N=(2*Radius/Min(dimdelta(inputwave,0),dimdelta(inputwave,1)),2*Radius/Min(dimdelta(inputwave,0),dimdelta(inputwave,1)),dimsize(inputwave,2)) $OutputWaveName
Wave OutputWave = $OutputWaveName
Setscale /p x, Centerx-radius, Min(dimdelta(inputwave,0),dimdelta(inputwave,1)),OutputWave
Setscale /p y, Centery-radius, Min(dimdelta(inputwave,0),dimdelta(inputwave,1)),OutputWave
setscale /p z, dimoffset(inputwave,2),dimdelta(inputwave,2),OutputWave
Outputwave=Nan

Duplicate /o OutputWave temp1
Duplicate /o OutputWave temp2
Duplicate /o OutputWave temp3

variable i,j,xout,yout,xrot1,yrot1,xrot2,yrot2

for(i=0;i<dimsize(outputwave,0);i+=1)
for(j=0;j<dimsize(outputwave,1);j+=1)
	xout = dimoffset(outputwave,0)+i*dimdelta(outputwave,0)
	yout = dimoffset(outputwave,1)+j*dimdelta(outputwave,1)
	xrot1 = 1/2*(-(xout-centerx)-sqrt(3)*(yout-centery)+2*centerx)
	yrot1 = 1/2*(sqrt(3)*(xout-centerx)-(yout-centery)+2*centery)
	xrot2 = 1/2*(-(xout-centerx)+sqrt(3)*(yout-centery)+2*centerx)
	yrot2 = 1/2*(-sqrt(3)*(xout-centerx)-(yout-centery)+2*centery)
	//print yout
	//print Max(Min(yout,dimoffset(inputwave,1)+(dimsize(inputwave,1)-1)*dimdelta(inputwave,1)),dimoffset(inputwave,1))
	if(xout<dimoffset(inputwave,0)+(dimsize(inputwave,0)-1)*dimdelta(inputwave,0) && xout>dimoffset(Inputwave,0) && yout<dimoffset(inputwave,1)+(dimsize(inputwave,1)-1)*dimdelta(inputwave,1) && yout>dimoffset(inputwave,1))
		Temp1[i][j][]=InputWave(Max(Min(xout,dimoffset(inputwave,0)+(dimsize(inputwave,0)-1)*dimdelta(inputwave,0)),dimoffset(inputwave,0)))(Max(Min(yout,dimoffset(inputwave,1)+(dimsize(inputwave,1)-1)*dimdelta(inputwave,1)),dimoffset(inputwave,1)))(dimoffset(inputwave,2)+r*dimdelta(inputwave,2))
	Else
		Temp1[i][j][]=NaN
	EndIf
	if(xrot1<dimoffset(inputwave,0)+(dimsize(inputwave,0)-1)*dimdelta(inputwave,0) && xrot1>dimoffset(Inputwave,0) && yrot1<dimoffset(inputwave,1)+(dimsize(inputwave,1)-1)*dimdelta(inputwave,1) && yrot1>dimoffset(inputwave,1))
		Temp2[i][j][]=InputWave(Max(Min(xrot1,dimoffset(inputwave,0)+(dimsize(inputwave,0)-1)*dimdelta(inputwave,0)),dimoffset(inputwave,0)))(Max(Min(yrot1,dimoffset(inputwave,1)+(dimsize(inputwave,1)-1)*dimdelta(inputwave,1)),dimoffset(inputwave,1)))(dimoffset(inputwave,2)+r*dimdelta(inputwave,2))
	else
		temp2[i][j][]=NaN
	endif
	if(xrot2<dimoffset(inputwave,0)+(dimsize(inputwave,0)-1)*dimdelta(inputwave,0) && xrot2>dimoffset(Inputwave,0) && yrot2<dimoffset(inputwave,1)+(dimsize(inputwave,1)-1)*dimdelta(inputwave,1) && yrot2>dimoffset(inputwave,1))
		Temp3[i][j][]=InputWave(Max(Min(xrot2,dimoffset(inputwave,0)+(dimsize(inputwave,0)-1)*dimdelta(inputwave,0)),dimoffset(inputwave,0)))(Max(Min(yrot2,dimoffset(inputwave,1)+(dimsize(inputwave,1)-1)*dimdelta(inputwave,1)),dimoffset(inputwave,1)))(dimoffset(inputwave,2)+r*dimdelta(inputwave,2))
	else
		temp3[i][j][]=NaN
	endif
	Outputwave[i][j][]=(Temp1[i][j][r]+Temp2[i][j][r]+Temp3[i][j][r])/3
endfor
endfor

If(Graph==1)
	display;appendimage outputwave
EndIf

killwaves temp1, temp2, temp3

End