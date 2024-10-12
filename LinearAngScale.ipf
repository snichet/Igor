x#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//Assumes work function of 4.5eV.

Function LinearAngScale(InputWave,dim,hv,Ang0)

	Wave InputWave
	Variable dim
	Variable hv
	Variable Ang0
	
	If(dim==0)
		setscale /p x, .5121*sqrt(hv-4.5)*(dimoffset(inputwave,0)-Ang0)*Pi/180,.5121*sqrt(hv-4.5)*dimdelta(inputwave,0)*Pi/180,inputwave
	Else
		If(Dim==1)
			setscale /p y, .5121*sqrt(hv-4.5)*(dimoffset(inputwave,1)-Ang0)*Pi/180,.5121*sqrt(hv-4.5)*dimdelta(inputwave,1)*Pi/180,inputwave
		Else
			setscale /p z, .5121*sqrt(hv-4.5)*(dimoffset(inputwave,2)-Ang0)*pi/180,.5121*sqrt(hv-4.5)*dimdelta(inputwave,2)*Pi/180,inputwave
		EndIf
	EndIf
	
Print "Dimension " + num2str(dim)+ " of wave "+NameofWave(Inputwave) +"has been scaled using hv = " + num2str(hv)+ " and Ang0 = " + num2str(ang0) +"."

End