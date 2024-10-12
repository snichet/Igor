#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function NansToZeros(inputwave)

wave inputwave

variable i,j,k

For(i=0;i<max(dimsize(inputwave,0),1);i+=1)
For(j=0;j<max(dimsize(inputwave,1),1);j+=1)
For(k=0;k<max(dimsize(inputwave,2),1);k+=1)
	if(numtype(inputwave[i][j][k])==2)
		inputwave[i][j][k]=0
	endif
endfor
endfor
endfor

end

Function NansToValue(inputwave,Value)

wave inputwave
variable value

variable i,j,k

For(i=0;i<max(dimsize(inputwave,0),1);i+=1)
For(j=0;j<max(dimsize(inputwave,1),1);j+=1)
For(k=0;k<max(dimsize(inputwave,2),1);k+=1)
	if(numtype(inputwave[i][j][k])==2)
		inputwave[i][j][k]=value
	endif
endfor
endfor
endfor

end

Function ZerosToNans(inputwave)

wave inputwave

variable i,j,k

If(Dimsize(inputwave,2)==0)

	If(dimsize(inputwave,1)==0)
		For(i=0;i<dimsize(inputwave,0);i+=1)
			if(inputwave[i]==0)
				inputwave[i]=NaN
			endif
		endfor
	Else
		For(i=0;i<dimsize(inputwave,0);i+=1)
		For(j=0;j<dimsize(inputwave,1);j+=1)
			if(inputwave[i][j]==0)
				inputwave[i][j]=NaN
			endif
		endfor
		endfor
	EndIf
Else

For(i=0;i<dimsize(inputwave,0);i+=1)
For(j=0;j<dimsize(inputwave,1);j+=1)
For(k=0;k<dimsize(inputwave,2);k+=1)
	if(inputwave[i][j][k]==0)
		inputwave[i][j][k]=NaN
	endif
endfor
endfor
endfor

EndIf

end