#pragma rtGlobals=1             // Use modern global access method.

// Fitting Fermi level
//		Fermi_temp
//		Fermi_meV
//		Fermi_Francois     (convoluted by a Gaussian for resolution)

// Fitting dispersion
// 	 	Fit_DispKvsE(w,x) 
//		Fit_DispEvsK(w,x) 
//		Disp_parabolic(w,x) 

// Fitting MDC
// 		1,2,3,4,5 lorentziennes
// 		1 ou 3 Gaussiennes

// Fitting EDC
//		GaussTimesFermi
//		LorTimesFermi
//		LorTimesFermi_OmegaWidth
//		LineTimesFermiPlusTwoBgd
//		TwoLinesTimesFermi
//		TwoLinesTimesFermiPlusPolyBgd
//		GaussTimesFermiPlusShirleyBgd   => à revoir !!


// Fitting Fermi level
Function Fermi_temp(w,x) : FitFunc
        Wave w
        Variable x
        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) = A/(1+exp((x-Ef)/0.86e-4/T))+Bgd
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 6
        //CurveFitDialog/ w[0] = A1
        //CurveFitDialog/ w[1] = p1
        //CurveFitDialog/ w[2] = Ef
        //CurveFitDialog/ w[3] = T
        //CurveFitDialog/ w[4] = Bgd
        //CurveFitDialog/ w[5] = p_Bgd

        return (w[0]+w[1]*(x-w[2]))/(1+exp((x-w[2])/0.86e-4/w[3]))+w[4]+w[5]*(x-w[2])
End


Function Fermi_meV(w,x) : FitFunc
        Wave w
        Variable x
        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) = A/(1+exp((x-Ef)/T))+Bgd
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 6
        //CurveFitDialog/ w[0] = A1
        //CurveFitDialog/ w[1] = p1
        //CurveFitDialog/ w[2] = Ef
        //CurveFitDialog/ w[3] = T              => width for 10%-90%(=4.394*kBT)
        //CurveFitDialog/ w[4] = Bgd
        //CurveFitDialog/ w[5] = p_Bgd
        
        return (w[0]+w[1]*(x-w[2]))/(1+exp((x-w[2])/(w[3]/4.394)))+w[4]+w[5]*(x-w[2])
End

Function Fermi_Francois(pw, yw, xw) : FitFunc
	Wave pw, yw, xw
	
	//pw[0] = resolution
	//pw[1] = temperature
	//pw[2] = pente fond
	//pw[3] = constante fond
	//pw[4] = pente densite etats
	//pw[5] = constante densite etats
	//pw[6] = energie Fermi
	
	Variable dT = 4*pw[0]/200
	Make/D/O/N=201 GaussWave
	SetScale/P x -dT*100, dT, GaussWave
	
	GaussWave = (2*sqrt(ln(2)/pi)/pw[0])*exp(-(4*ln(2)*x^2)/pw[0]^2)
	
	Variable nYPnts=round((xw[numpnts(xw)-1]-xw[0])/dT)+200
	Make/D/O/N=(nYPnts) yWave
	SetScale/P x xw[0]-99*dT, dT, yWave
	
	yWave = pw[3]+pw[2]*(x-pw[6])+(pw[5]+pw[4]*(x-pw[6]))/(exp((x-pw[6])/(8.617343e-5*pw[1]))+1)
	
	convolve/A GaussWave, yWave
	
	yw = yWave(xw[p])
	
End


//***************************************************************
// Fitting dispersion

Function Fit_DispKvsE(w,x) : FitFunc
        Wave w
        Variable x


        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) = x/Vf+Kf
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 2
        //CurveFitDialog/ w[0] = Vf
        //CurveFitDialog/ w[1] = kf

return x/w[0]+w[1]

End

Function Fit_DispEvsK(w,x) : FitFunc
        Wave w
        Variable x


        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) = Vf*(k-kf)
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 2
        //CurveFitDialog/ w[0] = Vf
        //CurveFitDialog/ w[1] = kf

return w[0]*(x-w[1])

End

Function Disp_parabolic(w,x) : FitFunc
        Wave w
        Variable x


        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) =a*(k-k_min)^2+E_min
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 3
        //CurveFitDialog/ w[0] =a
        //CurveFitDialog/ w[1] =k_min
        //CurveFitDialog/ w[2] =E_min
                     
wave to_fit
	 
        return w[0]*(x-w[1])^2+w[2]

end
//*****************************************************

//==========   Fitting MDC     =========================================

// *******************************************************************************************************************
// 1, 2, 3, 4 lorentziennes

Function One_lor(w,x) : FitFunc
        Wave w
        Variable x


        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) = C+A1/( ((x-x1)/L)^2+1)
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 4
        //CurveFitDialog/ w[0] = C
        //CurveFitDialog/ w[1] = A1
        //CurveFitDialog/ w[2] = L1
        //CurveFitDialog/ w[3] = X1


// A=valeur au sommet
// L=largeur à mi-hauteur
// Aire prop = A*L*pi
        
// 1 lorentzienne
return w[0]+w[1]/(((x-w[3])/w[2])^2+1)


End



Function Two_lor(w,x) : FitFunc
        Wave w
        Variable x


        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) = C+A1*L1/((x-x1)^2+L1^2)+A2*L2/((x-x2)^2+L2^2)
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 7
        //CurveFitDialog/ w[0] = C
        //CurveFitDialog/ w[1] = A1
        //CurveFitDialog/ w[2] = L1
        //CurveFitDialog/ w[3] = X1
        //CurveFitDialog/ w[4] = A2
        //CurveFitDialog/ w[5] = L2
        //CurveFitDialog/ w[6] = X2


// A=valeur au sommet
// L=largeur à mi-hauteur
        
// 2 lorentziennes
return w[0]+w[1]/(((x-w[3])/w[2])^2+1)+w[4]/(((x-w[6])/w[5])^2+1)


End

Function Two_lor_WithRes(w,x) : FitFunc
        Wave w
        Variable x


        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) = C+A1*L1/((x-x1)^2+(L1+res)^2)+A2*L2/((x-x2)^2+(L2+res)^2)
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 8
        //CurveFitDialog/ w[0] = C
        //CurveFitDialog/ w[1] = A1
        //CurveFitDialog/ w[2] = L1
        //CurveFitDialog/ w[3] = X1
        //CurveFitDialog/ w[4] = A2
        //CurveFitDialog/ w[5] = L2
        //CurveFitDialog/ w[6] = X2
        //CurveFitDialog/ w[7] = res


// A=valeur au sommet
// L=largeur à mi-hauteur
        
// 2 lorentziennes
return w[0]+w[1]/(((x-w[3])/(w[2]+w[7]))^2+1)+w[4]/(((x-w[6])/(w[5]+w[7]))^2+1)


End



Function Three_lor(w,x) : FitFunc
        Wave w
        Variable x


        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) = C+A1*L1/((x-x1)^2+L1^2)+A2*L2/((x-x2)^2+L2^2)+A3*L3/((x-x3)^2+L3^2)
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 10
        //CurveFitDialog/ w[0] = C
        //CurveFitDialog/ w[1] = A1
        //CurveFitDialog/ w[2] = L1
        //CurveFitDialog/ w[3] = X1
        //CurveFitDialog/ w[4] = A2
        //CurveFitDialog/ w[5] = L2
        //CurveFitDialog/ w[6] = X2
        //CurveFitDialog/ w[7] = A3
        //CurveFitDialog/ w[8] = L3
        //CurveFitDialog/ w[9] = X3


// A=valeur au sommet
// L=largeur à mi-hauteur
        
// 3 lorentziennes
        return w[0]+w[1]/(((x-w[3])/w[2])^2+1)+w[4]/(((x-w[6])/w[5])^2+1)+w[7]/(((x-w[9])/w[8])^2+1)
End

Function Four_lor(w,x) : FitFunc
        Wave w
        Variable x


        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) = C+A1*L1/((x-x1)^2+L1^2)+A2*L2/((x-x2)^2+L2^2)+A3*L3/((x-x3)^2+L3^2)+A4*L4/((x-x4)^2+L4^2)
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 14
        //CurveFitDialog/ w[0] = C
        //CurveFitDialog/ w[1] = A1
        //CurveFitDialog/ w[2] = L1
        //CurveFitDialog/ w[3] = X1
        //CurveFitDialog/ w[4] = A2
        //CurveFitDialog/ w[5] = L2
        //CurveFitDialog/ w[6] = X2
        //CurveFitDialog/ w[7] = A3
        //CurveFitDialog/ w[8] = L3
        //CurveFitDialog/ w[9] = X3
        //CurveFitDialog/ w[10] = A4
        //CurveFitDialog/ w[11] = L4
        //CurveFitDialog/ w[12] = X4
 //CurveFitDialog/ w[13] = p

// A=valeur au sommet
// L=largeur à mi-hauteur
        
// 4 lorentziennes
        return w[0]+w[13]*x+w[1]/(((x-w[3])/w[2])^2+1)+w[4]/(((x-w[6])/w[5])^2+1)+w[7]/(((x-w[9])/w[8])^2+1)+w[10]/(((x-w[12])/w[11])^2+1)


End


Function Five_lor(w,x) : FitFunc
        Wave w
        Variable x


        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) = C+A1*L1/((x-x1)^2+L1^2)+A2*L2/((x-x2)^2+L2^2)+A3*L3/((x-x3)^2+L3^2)+A4*L4/((x-x4)^2+L4^2)
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 16
        //CurveFitDialog/ w[0] = C
        //CurveFitDialog/ w[1] = A1
        //CurveFitDialog/ w[2] = L1
        //CurveFitDialog/ w[3] = X1
        //CurveFitDialog/ w[4] = A2
        //CurveFitDialog/ w[5] = L2
        //CurveFitDialog/ w[6] = X2
        //CurveFitDialog/ w[7] = A3
        //CurveFitDialog/ w[8] = L3
        //CurveFitDialog/ w[9] = X3
        //CurveFitDialog/ w[10] = A4
        //CurveFitDialog/ w[11] = L4
        //CurveFitDialog/ w[12] = X4
        //CurveFitDialog/ w[13] = A5
        //CurveFitDialog/ w[14] = L5
        //CurveFitDialog/ w[15] = X5


// A=valeur au sommet
// L=largeur à mi-hauteur
        
// 5 lorentziennes
        return w[0]+w[1]/(((x-w[3])/w[2])^2+1)+w[4]/(((x-w[6])/w[5])^2+1)+w[7]/(((x-w[9])/w[8])^2+1)+w[10]/(((x-w[12])/w[11])^2+1)+w[13]/(((x-w[15])/w[14])^2+1)


End

////////////////////// Gaussiennes
Function One_Gauss(w,x) : FitFunc
        Wave w
        Variable x


        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) =C+(A_1*exp(-((x-X0_1)/L_1)^2) 
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 4
           //CurveFitDialog/ w[0] =C
        //CurveFitDialog/ w[1] =A_1
        //CurveFitDialog/ w[2] =X0_1
        //CurveFitDialog/ w[3] =L1     // Mi-hauteur (1.177*sigma)
                            
wave to_fit
	 
        return w[0]+Gaussienne(x,w[1],w[2],w[3])

end

Function Two_Gauss(w,x) : FitFunc
        Wave w
        Variable x


        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) =C+(A_1*exp(-((x-X0_1)/L_1)^2) 
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 7
           //CurveFitDialog/ w[0] =C
        //CurveFitDialog/ w[1] =A_1
        //CurveFitDialog/ w[2] =X0_1
        //CurveFitDialog/ w[3] =L1     // Mi-hauteur (1.177*sigma)
        //CurveFitDialog/ w[1] =A_2
        //CurveFitDialog/ w[2] =X0_2
        //CurveFitDialog/ w[3] =L2     // Mi-hauteur (1.177*sigma)
                            
wave to_fit
	 
        return w[0]+Gaussienne(x,w[1],w[2],w[3])+Gaussienne(x,w[4],w[5],w[6])

end

//   ****************************************************************************************************

//================== Fitting functions for EDC ===========================

//   **********************************************************************************************************

Function GaussTimesFermi(w,x) : FitFunc
        Wave w
        Variable x
        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) = (A*exp(-((x-X1)/L1)^2))/(1+exp((x-Ef)/T))+Bgd
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 7
        //CurveFitDialog/ w[0] = Bgd
        //CurveFitDialog/ w[1]=p
        //CurveFitDialog/ w[2] = A
        //CurveFitDialog/ w[3] = X1
        //CurveFitDialog/ w[4] = L1
        //CurveFitDialog/ w[5] = Ef
        //CurveFitDialog/ w[6] = T
    
       variable result
    
       if (x<=w[5])
	    	//result=w[0]+(w[1]*exp(-((x-w[3])/w[2])^2))/(1+exp((x-w[4])/w[5]))
	    	result=w[0]+w[1]*(x-w[5]) + Gaussienne(x,w[2],w[3],w[4]) * FermiStep(x,w[5],w[6])
	else
	    result=w[0]+Gaussienne(x,w[2],w[3],w[4]) * FermiStep(x,w[5],w[6])
	endif   
        return result
 
//Use line below to see decomposition of the function
	//Make/O/N=128 Line,Bgd,FermiFn
	//SetScale/I x -1,0.2,"", Line,Bgd,FermiFn
	//Line:=Gaussienne(x,w_coef[2],w_coef[3],w_coef[4])
	//Bgd:=w_coef[0]+w_coef[1]*(x-w_coef[5])
	//FermiFn:=FermiStep(x,w_coef[5],w_coef[6])	
End
End

Function LorTimesFermi(w,x) : FitFunc
//Linear Bgd w[0]+w[1]*x for x<0

        Wave w
        Variable x
        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) = (Bgd+p*x)+(A*exp(-((x-X1)/L1)^2))/(1+exp((x-Ef)/T))
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 7
        //CurveFitDialog/ w[0] = Bgd
        //CurveFitDialog/ w[1] = p
        //CurveFitDialog/ w[2] = A
        //CurveFitDialog/ w[3] = X1
        //CurveFitDialog/ w[4] = L1
        //CurveFitDialog/ w[5] = Ef
        //CurveFitDialog/ w[6] = T
        variable result
    
       if (x<=w[5])
	    	//result=(w[0]+w[1]*(x-w[5]))+w[2]/(((x-w[4])/w[3])^2+1)/(1+exp((x-w[5])/w[6]))
	    	result=w[0]+w[1]*(x-w[5]) + Lor(x,w[2],w[3],w[4]) * FermiStep(x,w[5],w[6])
	else
	    result=w[0]+Lor(x,w[2],w[3],w[4]) * FermiStep(x,w[5],w[6])
	endif   
        return result
End

Function LorTimesFermi_OmegaWidth(w,x) : FitFunc
//Width changes as L1_0 + L1_B*omega^2
        Wave w
        Variable x
        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) = (Bgd+p*x+Lor)*Fermi  with (width for Lor)=L1_0+L1_B*x^2
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 8
        //CurveFitDialog/ w[0] = C
        //CurveFitDialog/ w[1] = p
        //CurveFitDialog/ w[2] = A
        //CurveFitDialog/ w[3] = X1
        //CurveFitDialog/ w[4] = L1_0
        //CurveFitDialog/ w[5] = L1_B
        //CurveFitDialog/ w[6] = Ef
        //CurveFitDialog/ w[7] = T

        variable result
        if (x<=w[6])
     		    result=w[0]+w[1]*(x-w[6]) + Lor(x,w[2],w[3],w[4]+w[5]*x^2) * FermiStep(x,w[6],w[7]) 
	 else
     		    result=w[0] + Lor(x,w[2],w[3],w[4]+w[5]*x^2) * FermiStep(x,w[6],w[7])
	endif   
        return result
End

Function LineTimesFermiPlusTwoBgd(w,x) : FitFunc
        Wave w
        Variable x
        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) = (Bgd+p*x)+(A*exp(-((x-X1)/L1)^2))/(1+exp((x-Ef)/T))
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 10
        //CurveFitDialog/ w[0] = Bgd
        //CurveFitDialog/ w[1] = p1
        //CurveFitDialog/ w[2] = cutoff    
        //CurveFitDialog/ w[3] = p2
        //CurveFitDialog/ w[4] = p3
        //CurveFitDialog/ w[5] = A
        //CurveFitDialog/ w[6] = X1
        //CurveFitDialog/ w[7] = L1
        //CurveFitDialog/ w[8] = Ef
        //CurveFitDialog/ w[9] = T
        
        variable result
        // Linear Bgd with 2 different values between (EF and w[2]) and (-inf and w[2])
        // + Parabolic Bgd     
       if (x>=w[8])
	    result=w[0]
	    result+=Gaussienne(x,w[5],w[6],w[7]) * FermiStep(x,w[8],w[9])
	else    
	    if (x>=w[2])
	    		result=w[0]+w[1]*(x-w[8]) + w[4]*(x-w[8])^2
			result+=Gaussienne(x,w[5],w[6],w[7]) * FermiStep(x,w[8],w[9])
		else
	    		result=w[0]+w[3]*(x-w[8]) + w[4]*(x-w[8])^2+(w[1]-w[3])*(w[2]-w[8])
	    		result+=Gaussienne(x,w[5],w[6],w[7]) * FermiStep(x,w[8],w[9])
	    endif   
      endif     
      
      return result
      
//Use line below to see decomposition of the function
	//Make/O/N=128 Line,Bgd,Bgd2
	//SetScale/I x -1,0.2,"", Line,Bgd,Bgd2
	// Line:=Lor(x,w_coef[5],w_coef[6],w_coef[7])
	// Line:=Gaussienne(x,w_coef[5],w_coef[6],w_coef[7])
	//Bgd:=w_coef[0]+w_coef[1]*(x-w_coef[8])+w_coef[4]*(x-w_coef[8])^2
	//Bgd2:=w_coef[0]+w_coef[3]*(x-w_coef[8])+(w_coef[1]-w_coef[3])*(w_coef[2]-w_coef[8])+w_coef[4]*(x-w_coef[8])^2
	//FermiFn:=FermiStep(x,w_coef[8],w_coef[9])	
End


Function TwoLinesTimesFermi(w,x) : FitFunc
        Wave w
        Variable x

        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) = C +p*x + (Lor(A1,X0_1,L1) +Gauss(A2,X0_2,L2)) * Fermi
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 10
        //CurveFitDialog/ w[0] =C
        //CurveFitDialog/ w[1] =p
        //CurveFitDialog/ w[2] =A1
        //CurveFitDialog/ w[3] =X0_1
        //CurveFitDialog/ w[4] =L1
       //CurveFitDialog/ w[5] =A2
       //CurveFitDialog/ w[6] =X0_2
       //CurveFitDialog/ w[7] =L2
       //CurveFitDialog/ w[8] =Ef
       //CurveFitDialog/ w[9] =T
         
	//Choose below the fomr of the 2 lines
	variable result
	if (x<=w[8])
	    result= w[0]+w[1]*(x-w[8])  + (Lor(x,w[2],w[3],w[4]) + Lor (x,w[5],w[6],w[7])  ) * FermiStep(x,w[8],w[9])
	    else
	   result=w[0]+(Lor(x,w[2],w[3],w[4]) + Lor (x,w[5],w[6],w[7])  ) * FermiStep(x,w[8],w[9])
	endif   
        return result

//Use line below to see decomposition of the function
	//Make/O/N=128 Line,Line2,Bgd,FermiFn
	//SetScale/I x -1,0.2,"", Line,Line2,Bgd,FermiFn
	// Line:=Lor(x,w_coef[2],w_coef[3],w_coef[4])
	// Line2:=Gaussienne(x,w_coef[5],w_coef[6],w_coef[7])
	//Bgd:=w_coef[0]+w_coef[1]*(x-w_coef[8])
	//FermiFn:=FermiStep(x,w_coef[8],w_coef[9])	 
end


Function TwoLinesTimesFermiPlusPolyBgd(w,x) : FitFunc
        Wave w
        Variable x

        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) =PolyBgd + (Line1 + Line2) * Fermi
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 13
        //CurveFitDialog/ w[0] =C
        //CurveFitDialog/ w[1] =p1
        //CurveFitDialog/ w[2] =p2
        //CurveFitDialog/ w[3] =p3
        //CurveFitDialog/ w[4] =p4
        //CurveFitDialog/ w[5] =A1
        //CurveFitDialog/ w[6] =X0_1
        //CurveFitDialog/ w[7] =L1
       //CurveFitDialog/ w[8] =A2
       //CurveFitDialog/ w[9] =X0_2
       //CurveFitDialog/ w[10] =L2
       //CurveFitDialog/ w[11] =Ef
       //CurveFitDialog/ w[12] =T
  
       // Choose in function which forms you want to use
       variable result
	if (x<=w[11])
	    result=w[0]+w[1]*(x-w[11])+w[2]*(x-w[11])^2+w[3]*(x-w[11])^3+w[4]*(x-w[11])^4     // PolyBgd up to4th order
	    //result+=Lor(x,w[5],w[6],w[7])+Lor(x,w[8],w[9],w[10])*FermiStep(x,w[11],w[12])
	    //result+=Gaussienne(x,w[5],w[6],w[7])+Lor(x,w[8],w[9],w[10])*FermiStep(x,w[11],w[12])
	    result+=Gaussienne(x,w[5],w[6],w[7])+Gaussienne(x,w[8],w[9],w[10])*FermiStep(x,w[11],w[12])
	else
	    result=w[0]
	    //result+=Lor(x,w[5],w[6],w[7])+Lor(x,w[5],w[6],w[7])*FermiStep(x,w[11],w[12])	 
	    //result+=Gaussienne(x,w[5],w[6],w[7])+Lor(x,w[8],w[9],w[10])*FermiStep(x,w[11],w[12])
	    result+=Gaussienne(x,w[5],w[6],w[7])+Gaussienne(x,w[8],w[9],w[10])*FermiStep(x,w[11],w[12])
	endif   
        return result

//Use line below to see decomposition of the function
	//Make/O/N=128 Line,Line2,Bgd
	//SetScale/I x -1,0.2,"", Line,Line2,Bgd
	// Line:=Lor(x,w_coef[5],w_coef[6],w_coef[7])
	//Line:=Gaussienne(x,w_coef[5],w_coef[6],w_coef[7])
	//Line2:=Lor(x,w_coef[8],w_coef[9],w_coef[10])
	//Bgd:=w_coef[0]+w_coef[1]*(x-w_coef[11])+w_coef[2]*(x-w_coef[11])^2+w_coef[3]*(x-w_coef[11])^3+w_coef[4]*(x-w_coef[11])^4 
	//FermiFn:=FermiStep(x,w_coef[11],w_coef[12])	 
end

//
Function TwoLinesTimesFermiPlusGaussBgd(w,x) : FitFunc
        Wave w
        Variable x

        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) =PolyBgd + (Line1 + Line2) * Fermi
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 13
        //CurveFitDialog/ w[0] =C
        //CurveFitDialog/ w[1] =A_bgd
        //CurveFitDialog/ w[2] =X_bgd
        //CurveFitDialog/ w[3] =L_Bgd_keft
        //CurveFitDialog/ w[4] =L_Bgd_right
        //CurveFitDialog/ w[5] =A1
        //CurveFitDialog/ w[6] =X0_1
        //CurveFitDialog/ w[7] =L1
       //CurveFitDialog/ w[8] =A2
       //CurveFitDialog/ w[9] =X0_2
       //CurveFitDialog/ w[10] =L2
       //CurveFitDialog/ w[11] =Ef
       //CurveFitDialog/ w[12] =T
  
       // Choose in function which forms you want to use
       variable result
	
	  result=(w[0]+GaussienneAsym(x-w[11],w[1],w[2],w[3],w[4])+Gaussienne(x,w[5],w[6],w[7])+Gaussienne(x,w[8],w[9],w[10]))*FermiStep(x,w[11],w[12])

        return result

//Use line below to see decomposition of the function
	//Make/O/N=128 Line,Line2,Bgd
	//SetScale/I x -1,0.2,"", Line,Line2,Bgd
	// Line:=Lor(x,w_coef[5],w_coef[6],w_coef[7])
	//Line:=Gaussienne(x,w_coef[5],w_coef[6],w_coef[7])
	//Line2:=Lor(x,w_coef[8],w_coef[9],w_coef[10])
	//Bgd:=w_coef[0]+w_coef[1]*(x-w_coef[11])+w_coef[2]*(x-w_coef[11])^2+w_coef[3]*(x-w_coef[11])^3+w_coef[4]*(x-w_coef[11])^4 
	//FermiFn:=FermiStep(x,w_coef[11],w_coef[12])	 
end

Function TwoLinesTimesFermiPlusStepBgd(w,x) : FitFunc
        Wave w
        Variable x

        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) =PolyBgd + (Line1 + Line2) * Fermi
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 13
        //CurveFitDialog/ w[0] =C
        //CurveFitDialog/ w[1] =E_step_bgd
        //CurveFitDialog/ w[2] =L_step_bgd
        //CurveFitDialog/ w[3] =A_step_Bgd
        //CurveFitDialog/ w[4] =Not used
        //CurveFitDialog/ w[5] =A1
        //CurveFitDialog/ w[6] =X0_1
        //CurveFitDialog/ w[7] =L1
       //CurveFitDialog/ w[8] =A2
       //CurveFitDialog/ w[9] =X0_2
       //CurveFitDialog/ w[10] =L2
       //CurveFitDialog/ w[11] =Ef
       //CurveFitDialog/ w[12] =T
  
       // Choose in function which forms you want to use
       variable result
	
	  result=(w[0]+w[3]*FermiStep(x-w[11],w[1],w[2])+Gaussienne(x,w[5],w[6],w[7])+Gaussienne(x,w[8],w[9],w[10]))*FermiStep(x,w[11],w[12])

        return result

//Use line below to see decomposition of the function
	//Make/O/N=128 Line,Line2,Bgd
	//SetScale/I x -1,0.2,"", Line,Line2,Bgd
	// Line:=Lor(x,w_coef[5],w_coef[6],w_coef[7])
	//Line:=Gaussienne(x,w_coef[5],w_coef[6],w_coef[7])
	//Line2:=Lor(x,w_coef[8],w_coef[9],w_coef[10])
	//Bgd:=w_coef[0]+w_coef[1]*(x-w_coef[11])+w_coef[2]*(x-w_coef[11])^2+w_coef[3]*(x-w_coef[11])^3+w_coef[4]*(x-w_coef[11])^4 
	//FermiFn:=FermiStep(x,w_coef[11],w_coef[12])	 
end

Function TwoLinesTimesFermi_ConstantArea(w,x) : FitFunc
        Wave w
        Variable x

        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) =PolyBgd + (Line1 + Line2) * Fermi
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 13
        //CurveFitDialog/ w[0] =C
        //CurveFitDialog/ w[1] =p1
        //CurveFitDialog/ w[2] =p2
        //CurveFitDialog/ w[3] =p3
        //CurveFitDialog/ w[4] =p4
        //CurveFitDialog/ w[5] =A  //total area. A1=A-A2*L2/L1
        //CurveFitDialog/ w[6] =X0_1
        //CurveFitDialog/ w[7] =L1
       //CurveFitDialog/ w[8] =A2
       //CurveFitDialog/ w[9] =X0_2
       //CurveFitDialog/ w[10] =L2
       //CurveFitDialog/ w[11] =Ef
       //CurveFitDialog/ w[12] =T
  
       // Choose in function which forms you want to use
       variable result
	if (x<=w[11])
	    result=w[0]+w[1]*(x-w[11])+w[2]*(x-w[11])^2+w[3]*(x-w[11])^3+w[4]*(x-w[11])^4     // PolyBgd up to4th order
	    //result+=Lor(x,w[5],w[6],w[7])+Lor(x,w[8],w[9],w[10])*FermiStep(x,w[11],w[12])
	    //result+=Gaussienne(x,w[5],w[6],w[7])+Lor(x,w[8],w[9],w[10])*FermiStep(x,w[11],w[12])
	    result+=Gaussienne(x,(w[5]-w[8]*w[10])/w[7],w[6],w[7])+Gaussienne(x,w[8],w[9],w[10])*FermiStep(x,w[11],w[12])
	else
	    result=w[0]
	    //result+=Lor(x,w[5],w[6],w[7])+Lor(x,w[5],w[6],w[7])*FermiStep(x,w[11],w[12])	 
	    //result+=Gaussienne(x,w[5],w[6],w[7])+Lor(x,w[8],w[9],w[10])*FermiStep(x,w[11],w[12])
	    result+=Gaussienne(x,(w[5]-w[8]*w[10])/w[7],w[6],w[7])+Gaussienne(x,w[8],w[9],w[10])*FermiStep(x,w[11],w[12])
	endif   
        return result

//Use line below to see decomposition of the function
	//Make/O/N=128 Line,Line2,Bgd
	//SetScale/I x -1,0.2,"", Line,Line2,Bgd
	// Line:=Lor(x,w_coef[5],w_coef[6],w_coef[7])
	//Line:=Gaussienne(x,w_coef[5],w_coef[6],w_coef[7])
	//Line2:=Lor(x,w_coef[8],w_coef[9],w_coef[10])
	//Bgd:=w_coef[0]+w_coef[1]*(x-w_coef[11])+w_coef[2]*(x-w_coef[11])^2+w_coef[3]*(x-w_coef[11])^3+w_coef[4]*(x-w_coef[11])^4 
	//FermiFn:=FermiStep(x,w_coef[11],w_coef[12])	 
end

Function ThreeLinesTimesFermiPlusPolyBgd(w,x) : FitFunc
        Wave w
        Variable x

        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) = C +p*x + (Lor(A1,X0_1,L1) +Gauss(A2,X0_2,L2)) * Fermi
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 14
        //CurveFitDialog/ w[0] =C
        //CurveFitDialog/ w[1] =p1
        //CurveFitDialog/ w[2] =p2
                
        //CurveFitDialog/ w[3] =A1
        //CurveFitDialog/ w[4] =X0_1
        //CurveFitDialog/ w[5] =L1
       //CurveFitDialog/ w[6] =A2
       //CurveFitDialog/ w[7] =X0_2
       //CurveFitDialog/ w[8] =L2
        //CurveFitDialog/ w[9] =A3
       //CurveFitDialog/ w[10] =X0_3
       //CurveFitDialog/ w[11] =L3
       //CurveFitDialog/ w[12] =Ef
       //CurveFitDialog/ w[13] =T
         
	//Choose below the fomr of the 2 lines
	variable result
	if (x<=w[12])
	    result=w[0]+w[1]*(x-w[12])+w[2]*(x-w[12])^2
	    result+= (Lor(x,w[3],w[4],w[5]) + Lor (x,w[6],w[7],w[8]) +Lor (x,w[9],w[10],w[11]) ) * FermiStep(x,w[12],w[13])
	    else
	   result=w[0]
	   result+=(Lor(x,w[3],w[4],w[5]) + Lor (x,w[6],w[7],w[8])+Lor (x,w[9],w[10],w[11])  ) * FermiStep(x,w[12],w[13])
	endif   
        return result

//Use line below to see decomposition of the function
	//Make/O/N=128 Line,Line2,Bgd,FermiFn
	//SetScale/I x -1,0.2,"", Line,Line2,Bgd,FermiFn
	// Line:=Lor(x,w_coef[2],w_coef[3],w_coef[4])
	// Line2:=Gaussienne(x,w_coef[5],w_coef[6],w_coef[7])
	//Bgd:=w_coef[0]+w_coef[1]*(x-w_coef[8])
	//FermiFn:=FermiStep(x,w_coef[8],w_coef[9])	 
end


//Function GaussTimesFermiPlusShirleyBgd(w,x) : FitFunc
//        Wave w
//        Variable x


        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) =(Amp*exp(-((x-X_0)/Width)^2) + Bgd_amp*(sum(to_fit,x,x_max))^Bgd_beta)/(1+exp((x-Ef)/Temp_meV))  
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 7
        //CurveFitDialog/ w[0] =Amp
        //CurveFitDialog/ w[1] =X_0
        //CurveFitDialog/ w[2] =Width
        //CurveFitDialog/ w[3] =Ef
       //CurveFitDialog/ w[4] =Temp_meV
       //CurveFitDialog/ w[5] =Bgd_amp
       //CurveFitDialog/ w[6] =Bgd_beta  
       
//WARNING : Name of function to fit must be to_fit
//NB : for real ShirleyBgd, beta=1
       
//wave to_fit
//variable x_max=rightx(to_fit)
	
	 
  //      return (w[0]*exp(-((x-w[1])/w[2])^2)   +  w[5]*(sum(to_fit,x,x_max))^w[6]  )/(1+exp((x-w[3])/w[4]))  

//end

///////////////////////////////
////// Small Functions
//
function Lor(x,A,X0,L)
	variable x,A,X0,L
	return A/( ( (x-X0)/L )^2 + 1 )
end
//
function Gaussienne(x,A,X0,L)
	variable x,A,X0,L      
	// Largeur mi-hauteur = L=1.177*sigma  (avec exp( - (x-X0)^2/2*sigma^2 ) )
	// Area exp(-x2)=sqrt(pi)
	// Area = A*L/1.177*sqrt(2*pi)
	return A * exp(- ( (x-X0)/(sqrt(2)*L/1.177) )^2 )
end
//
function GaussienneAsym(x,A,X0,L1,L2)
	variable x,A,X0,L1,L2      
	// Largeur mi-hauteur = L=1.177*sigma  (avec exp( - (x-X0)^2/2*sigma^2 ) )
	// Area exp(-x2)=sqrt(pi)
	// Area = A*L/1.177*sqrt(2*pi)
	if (x<=X0)
	 	return A * exp(- ( (x-X0)/(sqrt(2)*L1/1.177) )^2 )
	else
		return A * exp(- ( (x-X0)/(sqrt(2)*L2/1.177) )^2 )
	endif   
	
end
//
function FermiStep(x,Ef,L)
variable x,Ef,L
	// L is the width between 10% and 90% in eV
	return 1 / ( 1 + exp( (x-Ef) / (L/4.394) ))
end

////////////////////////////////////////////////////////

function MultipleCos(w,x) : FitFunc
        Wave w
        Variable x

        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) =PolyBgd + (Line1 + Line2) * Fermi
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 4
        //CurveFitDialog/ w[0] =C
        //CurveFitDialog/ w[1] =A_cos
        //CurveFitDialog/ w[2] =A_sin
        //CurveFitDialog/ w[3] =A_cos2
       
       return w[0]+w[1]*cos(x*pi)+w[2]*sin(x*pi)+w[3]*cos(2*x*pi)
end

////////////////////////////////
Function KzVsE(w,x) : FitFunc
        Wave w
        Variable x

        //CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
        //CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
        //CurveFitDialog/ Equation:
        //CurveFitDialog/ f(x) = C +p*x + (Lor(A1,X0_1,L1) +Gauss(A2,X0_2,L2)) * Fermi
        //CurveFitDialog/ End of Equation
        //CurveFitDialog/ Independent Variables 1
        //CurveFitDialog/ x
        //CurveFitDialog/ Coefficients 3
        //CurveFitDialog/ w[0] =V0
        //CurveFitDialog/ w[1] =a
        //CurveFitDialog/ w[2] =c
	//Choose below the fomr of the 2 lines

	return sqrt(0.512^2*(x-4.2+w[0])-(sqrt(2)*pi/w[1])^2)/(pi/w[2]*2)


end
