#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//DataBinXYZ(InputWave,XBinSize,YBinSize,ZBinSize)
//DataBinXY(InputWave,XBinSize,YBinSize)
//DataBinX(InputWave,XBinSize)
//AverageOutDim_2D(InputWave,Dim)
//AverageOutDim_4D(InputWave,Dim)
//Int3Dto1D(Inputwave,Dim)
//Int3Dto2D(Inputwave,Dim)


//Note: this binning functions trucate through out the remainer data in each dimension that doesn't fit in a bin
Function DataBinXYZ(InputWave,XBinSize,YBinSize,ZBinSize)
	Wave InputWave
	Variable XBinSize
	Variable YBinSize
	Variable ZBinSize
	
	String OutputWaveName
	Variable i,a
	Do
		OutputWaveName = NameofWave(Inputwave)+"_bin"+num2str(i)
		i+=1
		a=exists(OutputWaveName)
	While(a==1)
	Make /O /N=(Trunc(dimsize(Inputwave,0)/XBinSize),Trunc(dimsize(inputwave,1)/YBinSize),Trunc(dimsize(inputwave,2)/zbinsize)) /S $OutputWaveName
	Wave OutputWave=$OutputWaveName
	
	Variable j,k,m,n,o
	
	For(i=0;i<dimsize(outputwave,0);i+=1)
		For(j=0;j<dimsize(outputwave,1);j+=1)
			For(k=0;k<dimsize(outputwave,2);k+=1)
				a=0
					For(m=0;m<XBinSize;m+=1)
						For(n=0;n<YBinSize;n+=1)
							For(o=0;o<ZBinSize;o+=1)
								a+=Inputwave[i*XBinSize+m][j*YBinSize+n][k*ZBinSize+o]
							EndFor
						Endfor
					EndFor
				Outputwave[i][j][k]=a
			EndFor
		EndFor
	EndFor
	
	setscale /p x, dimoffset(inputwave,0)+(dimdelta(inputwave,0)*(Xbinsize-1))/2,dimdelta(Inputwave,0)*XbinSize,Outputwave
	setscale /p y, dimoffset(inputwave,1)+(dimdelta(inputwave,1)*(Ybinsize-1))/2,dimdelta(Inputwave,1)*YbinSize,Outputwave
	setscale /p z, dimoffset(inputwave,2)+(dimdelta(inputwave,2)*(Zbinsize-1))/2,dimdelta(Inputwave,2)*ZbinSize,Outputwave
	
	Note OutputWave "DataBinXYZ Performed."
	Note Outputwave "Input Wave = " + NameofWave(Inputwave)
	Note OutputWave "xbinsize = " +num2str(xbinsize)
	Note Outputwave "ybinsize = " +num2str(ybinsize)
	NOTE OutputWave "zbinsize = " +num2str(zbinsize)
End

Function DataBinXY(InputWave,XBinSize,YBinSize)
	Wave InputWave
	Variable XBinSize
	Variable YBinSize
	
	String OutputWaveName
	Variable i,a
	Do
		OutputWaveName = NameofWave(Inputwave)+"_bin"+num2str(i)
		i+=1
		a=exists(OutputWaveName)
	While(a==1)
	Make /O /N=(Trunc(dimsize(Inputwave,0)/XBinSize),Trunc(dimsize(inputwave,1)/YBinSize)) /S $OutputWaveName
	Wave OutputWave=$OutputWaveName
	
	Variable j,m,n
	
	For(i=0;i<dimsize(outputwave,0);i+=1)
		For(j=0;j<dimsize(outputwave,1);j+=1)
				a=0
					For(m=0;m<XBinSize;m+=1)
						For(n=0;n<YBinSize;n+=1)
								a+=Inputwave[i*XBinSize+m][j*YBinSize+n]
						Endfor
					EndFor
				Outputwave[i][j]=a
		EndFor
	EndFor
	
	setscale /p x, dimoffset(inputwave,0)+(dimdelta(inputwave,0)*(Xbinsize-1))/2,dimdelta(Inputwave,0)*XbinSize,Outputwave
	setscale /p y, dimoffset(inputwave,1)+(dimdelta(inputwave,1)*(Ybinsize-1))/2,dimdelta(Inputwave,1)*YbinSize,Outputwave

	Print "DataBinXY Procedure Complete. Output wave: "+OutputWaveName
	Print "Input Wave = " + NameofWave(Inputwave)
	Print "xbinsize = " +num2str(xbinsize)
	Print "ybinsize = " +num2str(ybinsize)
	
	Note OutputWave "DataBinXY Performed."
	Note Outputwave "Input Wave = " + NameofWave(Inputwave)
	Note OutputWave "xbinsize = " +num2str(xbinsize)
	Note Outputwave "ybinsize = " +num2str(ybinsize)
	
End

Function DataBinX(InputWave,XBinSize)
	Wave InputWave
	Variable XBinSize
	
	String OutputWaveName
	Variable i,a
	//Do
		OutputWaveName = NameofWave(Inputwave)+"_bin0"//+num2str(i)
		//i+=1
		//a=exists(OutputWaveName)
	//While(a==1)
	Make /O /N=(Trunc(dimsize(Inputwave,0)/XBinSize)) /S $OutputWaveName
	Wave OutputWave=$OutputWaveName
	
	Variable j,m,n
	
	For(i=0;i<dimsize(outputwave,0);i+=1)
		//For(j=0;j<dimsize(outputwave,1);j+=1)
				a=0
					For(m=0;m<XBinSize;m+=1)
						//For(n=0;n<YBinSize;n+=1)
								a+=Inputwave[i*XBinSize+m]
						//Endfor
					EndFor
				Outputwave[i]=a
		//EndFor
	EndFor
	
	setscale /p x, dimoffset(inputwave,0)+(dimdelta(inputwave,0)*(Xbinsize-1))/2,dimdelta(Inputwave,0)*XbinSize,Outputwave
	//setscale /p y, dimoffset(inputwave,1)+(dimdelta(inputwave,1)*(Ybinsize-1))/2,dimdelta(Inputwave,1)*YbinSize,Outputwave

	Print "DataBinX Procedure Complete. Output wave: "+OutputWaveName
	Print "Input Wave = " + NameofWave(Inputwave)
	Print "xbinsize = " +num2str(xbinsize)
	//Print "ybinsize = " +num2str(ybinsize)
	
	Note OutputWave "DataBinX Performed."
	Note Outputwave "Input Wave = " + NameofWave(Inputwave)
	Note OutputWave "xbinsize = " +num2str(xbinsize)
	//Note Outputwave "ybinsize = " +num2str(ybinsize)
	
End

Function AverageOutDim_2D(InputWave,Dim)
	Wave InputWave
	Variable Dim

	Variable a,i,j
	
	Variable other
	
	string OutputWaveName
	
	if(Dim==0)
		OutputWaveName = NameOfWave(InputWave)+"_AveDim"+num2str(Dim)
		Make /O /N=(dimsize(inputwave,1)) $OutputWaveName
		Wave OutputWave=$OutputWaveName
		for(i=0;i<dimsize(inputwave,1);i+=1)
			a=0
			for(j=0;j<dimsize(inputwave,dim);j+=1)
				a+=inputwave[j][i]
			endfor
			OutputWave[i]=a/dimsize(inputwave,dim)
		endfor
		setscale /p x, dimoffset(inputwave,1),dimdelta(inputwave,1),outputwave
	else
		OutputWaveName = NameOfWave(InputWave)+"_AveDim"+num2str(Dim)
		Make /O /N=(dimsize(inputwave,0)) $OutputWaveName
		Wave OutputWave=$OutputWaveName
		for(i=0;i<dimsize(inputwave,0);i+=1)
			a=0
			for(j=0;j<dimsize(inputwave,dim);j+=1)
				a+=inputwave[i][j]
			endfor
			OutputWave[i]=a/dimsize(inputwave,dim)
		endfor
		setscale /p x, dimoffset(inputwave,0),dimdelta(inputwave,0),outputwave
	endif

//display
Appendtograph OutputWave

Print "AverageOutDim_2D was performed."
Print "Dimension " + num2str(dim) + " has been averaged out of wave: " + nameOfWave(inputwave)
Print "Output wave name is: " + nameofwave(outputwave)

Note Outputwave "AverageOutDim_2D was performed."
Note Outputwave "Dimension" + num2str(dim) + "has been averaged out of wave" + nameOfWave(inputwave)
	
End

Function AverageOutDim_4D(InputWave,Dim)
	Wave InputWave
	Variable Dim

	Variable a,i,j,k,l
		
	string OutputWaveName
	
	OutputWaveName = NameOfWave(InputWave)+"_AveDim"+num2str(Dim)
	
	if(Dim==0)
		Make /O /N=(dimsize(inputwave,1),dimsize(inputwave,2),dimsize(inputwave,3)) $OutputWaveName
		Wave OutputWave=$OutputWaveName
		for(i=0;i<dimsize(inputwave,1);i+=1)
		for(j=0;j<dimsize(inputwave,2);j+=1)
		for(k=0;k<dimsize(inputwave,3);k+=1)
			a=0
			for(l=0;l<dimsize(inputwave,dim);l+=1)
				a+=inputwave[l][i][j][k]
			endfor
			OutputWave[i][j][k]=a/dimsize(inputwave,dim)
		endfor
		endfor
		endfor
		setscale /p x, dimoffset(inputwave,1),dimdelta(inputwave,1),outputwave
		setscale /p y, dimoffset(inputwave,2),dimdelta(inputwave,2),outputwave
		setscale /p z, dimoffset(inputwave,3),dimdelta(inputwave,3),outputwave
	endif
	
	if(Dim==1)
		Make /O /N=(dimsize(inputwave,0),dimsize(inputwave,2),dimsize(inputwave,3)) $OutputWaveName
		Wave OutputWave=$OutputWaveName
		for(i=0;i<dimsize(inputwave,0);i+=1)
		for(j=0;j<dimsize(inputwave,2);j+=1)
		for(k=0;k<dimsize(inputwave,3);k+=1)
			a=0
			for(l=0;l<dimsize(inputwave,dim);l+=1)
				a+=inputwave[i][l][j][k]
			endfor
			OutputWave[i][j][k]=a/dimsize(inputwave,dim)
		endfor
		endfor
		endfor
		setscale /p x, dimoffset(inputwave,0),dimdelta(inputwave,0),outputwave
		setscale /p y, dimoffset(inputwave,2),dimdelta(inputwave,2),outputwave
		setscale /p z, dimoffset(inputwave,3),dimdelta(inputwave,3),outputwave
	endif
	
	if(Dim==2)
		Make /O /N=(dimsize(inputwave,0),dimsize(inputwave,1),dimsize(inputwave,3)) $OutputWaveName
		Wave OutputWave=$OutputWaveName
		for(i=0;i<dimsize(inputwave,0);i+=1)
		//Print "Dim 0 " + num2str(i) + "/" + num2str(dimsize(inputwave,0))
		for(j=0;j<dimsize(inputwave,1);j+=1)
		//Print "Dim 1 " + num2str(j) + "/" + num2str(dimsize(inputwave,1))
		for(k=0;k<dimsize(inputwave,3);k+=1)
			//Print "Dim 3 " + num2str(k) + "/" + num2str(dimsize(inputwave,3))
			a=0
			for(l=0;l<dimsize(inputwave,dim);l+=1)
				a+=inputwave[i][j][l][k]
			endfor
			OutputWave[i][j][k]=a/dimsize(inputwave,dim)
		endfor
		endfor
		endfor
		setscale /p x, dimoffset(inputwave,0),dimdelta(inputwave,0),outputwave
		setscale /p y, dimoffset(inputwave,1),dimdelta(inputwave,1),outputwave
		setscale /p z, dimoffset(inputwave,3),dimdelta(inputwave,3),outputwave
	endif
	
	if(Dim==3)
		Make /O /N=(dimsize(inputwave,0),dimsize(inputwave,1),dimsize(inputwave,2)) $OutputWaveName
		Wave OutputWave=$OutputWaveName
		for(i=0;i<dimsize(inputwave,0);i+=1)
		for(j=0;j<dimsize(inputwave,1);j+=1)
		for(k=0;k<dimsize(inputwave,2);k+=1)
			a=0
			for(l=0;l<dimsize(inputwave,dim);l+=1)
				a+=inputwave[i][j][k][l]
			endfor
			OutputWave[i][j][k]=a/dimsize(inputwave,dim)
		endfor
		endfor
		endfor
		setscale /p x, dimoffset(inputwave,0),dimdelta(inputwave,0),outputwave
		setscale /p y, dimoffset(inputwave,1),dimdelta(inputwave,1),outputwave
		setscale /p z, dimoffset(inputwave,2),dimdelta(inputwave,2),outputwave
	endif

Print "AverageOutDim_4D was performed."
Print "Dimension " + num2str(dim) + " has been averaged out of wave: " + nameOfWave(inputwave)
Print "Output wave name is: " + nameofwave(outputwave)

Note Outputwave "AverageOutDim_4D was performed."
Note Outputwave "Dimension" + num2str(dim) + "has been averaged out of wave" + nameOfWave(inputwave)
	
End

Function Int3Dto1D(Inputwave,Dim)
	Wave InputWave
	Variable Dim
	
	Variable i,a
	
	String OutputWaveName=nameofwave(inputwave)+"_EDC"
	Make /N=(dimsize(inputwave,dim)) $OutputWaveName
	Wave OutputWave=$OutputWaveName
	
	If(Dim==0)
	
		Make /n=(dimsize(inputwave,1),dimsize(inputwave,2)) temp
			
		For(i=0;i<dim;i+=1)
			temp[][] = inputwave[i][p][q]
			wavestats /q temp
			Outputwave[i] = v_sum
			temp=0
		EndFor
		
		KillWaves temp
		
	EndIf
	
	If(Dim==1)
	
		Make /n=(dimsize(inputwave,0),dimsize(inputwave,2)) temp
			
		For(i=0;i<dim;i+=1)
			temp[][] = inputwave[p][i][q]
			wavestats /q temp
			Outputwave[i] = v_sum
			temp=0
		EndFor
		
		KillWaves temp
		
	EndIf
	
	If(Dim==2)
	
		Make /n=(dimsize(inputwave,0),dimsize(inputwave,1)) temp
			
		For(i=0;i<dim;i+=1)
			temp[][] = inputwave[p][q][i]
			wavestats /q temp
			Outputwave[i] = v_sum
			temp=0
		EndFor
		
		KillWaves temp
		
	EndIf
	
	Note Outputwave "Int3Dto1D Executed along the " + num2str(dim) + " dimension."
	Note OutputWave "original Wave: " + nameofwave(inputwave)
	Note OutputWave "Output Wave : " + outputWaveName
	
	Print "Integration Complete. Output Wave Name:" + outputwavename
	
End

Function Int3Dto2D(Inputwave,Dim)
	Wave InputWave
	Variable Dim
	
	Variable i,j,a
	
	String OutputWaveName=nameofwave(inputwave)+"_"+num2str(dim)+"int"
	
	Make /o /n=(dimsize(inputwave,dim)) temp
	
	If(Dim==0)
	
		Make /N=(dimsize(inputwave,1),dimsize(inputwave,2)) $OutputWaveName
		Wave OutputWave=$OutputWaveName
			
		For(i=0;i<dimsize(inputwave,1);i+=1)
		For(j=0;j<dimsize(inputwave,2);j+=1)
			temp[] = inputwave[p][i][j]
			wavestats /q temp
			Outputwave[i][j] = v_sum
			temp=0
		EndFor
		EndFor
		
		KillWaves temp
		
	EndIf
	
	If(Dim==1)
	
		Make /N=(dimsize(inputwave,0),dimsize(inputwave,2)) $OutputWaveName
		Wave OutputWave=$OutputWaveName
			
		For(i=0;i<dimsize(inputwave,0);i+=1)
		For(j=0;j<dimsize(inputwave,2);j+=1)
			temp[] = inputwave[i][p][j]
			wavestats /q temp
			Outputwave[i][j] = v_sum
			temp=0
		EndFor
		EndFor
		
		KillWaves temp
		
	EndIf
	
	If(Dim==2)
	
		Make /N=(dimsize(inputwave,0),dimsize(inputwave,1)) $OutputWaveName
		Wave OutputWave=$OutputWaveName
			
		For(i=0;i<dimsize(inputwave,0);i+=1)
		For(j=0;j<dimsize(inputwave,1);j+=1)
			temp[] = inputwave[i][j][p]
			wavestats /q temp
			Outputwave[i][j] = v_sum
			temp=0
		EndFor
		EndFor
		
		KillWaves temp
		
	EndIf
	
	Note Outputwave "Int3Dto2D Executed along the " + num2str(dim) + " dimension."
	Note OutputWave "original Wave: " + nameofwave(inputwave)
	Note OutputWave "Output Wave : " + outputWaveName
	
	Print "Integration Complete. Output Wave Name:" + outputwavename
	
End