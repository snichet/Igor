#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function FermiAndDLor(w,e) : FitFunc
	Wave w
	Variable e

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(e) = y0+ a/(exp(-(e-b)/(c))+1)*(1/Pi)*(d+A1/((e-x1)^2+g1^2)+A2/((e-x2)^2+g2^2))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ e
	//CurveFitDialog/ Coefficients 14
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = b
	//CurveFitDialog/ w[2] = c
	//CurveFitDialog/ w[3] = g1
	//CurveFitDialog/ w[4] = x1
	//CurveFitDialog/ w[5] = g2
	//CurveFitDialog/ w[6] = x2
	//CurveFitDialog/ w[7] = A1
	//CurveFitDialog/ w[8] = A2
	//CurveFitDialog/ w[9] = d
	//CurveFitDialog/ w[10]= A3
	//CurveFitDialog/ w[11]= x3
	//CurveFitDialog/ w[12]= g3
	//CurveFitDialog/ w[13] = m


	return w[0] +w[13]*e+ 1/(exp(-(e-w[1])/(w[2]))+1)*(w[9]+w[7]/((e-w[4])^2+w[3]^2)+w[8]/((e-w[6])^2+w[5]^2)+w[10]/((e-w[11])^2+w[12]^2))
End

Function FermiAndTripLor2(w,e) : FitFunc
	Wave w
	Variable e

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(e) = y0+ a/(exp(-(e-b)/(c))+1)*(1/Pi)*(d+A1/((e-x1)^2+g1^2)+A2/((e-x2)^2+g2^2))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ e
	//CurveFitDialog/ Coefficients 14
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = b
	//CurveFitDialog/ w[2] = c
	//CurveFitDialog/ w[3] = g1
	//CurveFitDialog/ w[4] = x1
	//CurveFitDialog/ w[5] = g2
	//CurveFitDialog/ w[6] = x2
	//CurveFitDialog/ w[7] = A1
	//CurveFitDialog/ w[8] = A2
	//CurveFitDialog/ w[9] = d
	//CurveFitDialog/ w[10]= A3
	//CurveFitDialog/ w[11]= x3
	//CurveFitDialog/ w[12]= g3
	//CurveFitDialog/ w[13] = m


	return w[0] +w[13]*e+ 1/(exp(-(e-w[1])/(w[2]))+1)*(w[9]+w[7]/((e-w[4])^2/w[3]^2+1)+w[8]/((e-w[6])^2/w[5]^2+1)+w[10]/((e-w[11])^2/w[12]^2+1))
End

Function FermiAnd4Lor(w,e) : FitFunc
	Wave w
	Variable e
	
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(e) = y0+m*e+ 1/(exp(-(e-b)/(c))+1)*(d+A1/((e-x1)^2/w1^2+1)+A2/((e-x2)^2/w2^2+1)+A3/((e-x3)^2/w3^2+1)+A4/((e-x4)^2/w4^2+1))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ e
	//CurveFitDialog/ Coefficients 17
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = m
	//CurveFitDialog/ w[2] = b
	//CurveFitDialog/ w[3] = c
	//CurveFitDialog/ w[4] = d
	//CurveFitDialog/ w[5] = A1
	//CurveFitDialog/ w[6] = x1
	//CurveFitDialog/ w[7] = w1
	//CurveFitDialog/ w[8]=A2
	//CurveFitDialog/ w[9] = x2
	//CurveFitDialog/ w[10] = w2
	//CurveFitDialog/ w[11] = A3
	//CurveFitDialog/ w[12] = x3
	//CurveFitDialog/ w[13] = w3
	//CurveFitDialog/ w[14] = A4
	//CurveFitDialog/ w[15] = x4
	//CurveFitDialog/ w[16] = w4
	
	return w[0]+w[1]*e+ 1/(exp(-(e-w[2])/(w[3]))+1)*(w[4]+w[5]/((e-w[6])^2/w[7]^2+1)+w[8]/((e-w[9])^2/w[10]^2+1)+w[11]/((e-w[12])^2/w[13]^2+1)+w[14]/((e-w[15])^2/w[16]^2+1))
	
End

Function QuadGauss(w,k) : FitFunc
	Wave w
	Variable k

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(k) = y0+A1*Exp(-(k-k1)^2/(2*sigma1^2))+A2*Exp(-(k-k2)^2/(2*sigma2^2))+A3*Exp(-(k-k3)^2/(2*sigma3^2))+A4*Exp(-(k-k4)^2/(2*sigma4^2))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ k
	//CurveFitDialog/ Coefficients 13
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = k1
	//CurveFitDialog/ w[2] = sigma1
	//CurveFitDialog/ w[3] = k2
	//CurveFitDialog/ w[4] = sigma2
	//CurveFitDialog/ w[5] = k3
	//CurveFitDialog/ w[6] = sigma3
	//CurveFitDialog/ w[7] = k4
	//CurveFitDialog/ w[8] = sigma4
	//CurveFitDialog/ w[9] = A1
	//CurveFitDialog/ w[10] = A2
	//CurveFitDialog/ w[11] = A3
	//CurveFitDialog/ w[12] = A4

	return w[0]+w[9]*Exp(-(k-w[1])^2/(2*w[2]^2))+w[10]*Exp(-(k-w[3])^2/(2*w[4]^2))+w[11]*Exp(-(k-w[5])^2/(2*w[6]^2))+w[12]*Exp(-(k-w[7])^2/(2*w[8]^2))
End

Function QuadGaussLin(w,k) : FitFunc
	Wave w
	Variable k

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(k) = y0+m*k+A1*Exp(-(k-k1)^2/(2*sigma1^2))+A2*Exp(-(k-k2)^2/(2*sigma2^2))+A3*Exp(-(k-k3)^2/(2*sigma3^2))+A4*Exp(-(k-k4)^2/(2*sigma4^2))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ k
	//CurveFitDialog/ Coefficients 14
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = k1
	//CurveFitDialog/ w[2] = sigma1
	//CurveFitDialog/ w[3] = k2
	//CurveFitDialog/ w[4] = sigma2
	//CurveFitDialog/ w[5] = k3
	//CurveFitDialog/ w[6] = sigma3
	//CurveFitDialog/ w[7] = k4
	//CurveFitDialog/ w[8] = sigma4
	//CurveFitDialog/ w[9] = A1
	//CurveFitDialog/ w[10] = A2
	//CurveFitDialog/ w[11] = A3
	//CurveFitDialog/ w[12] = A4
	//CurveFitDialog/ w[13] = m

	return w[0]+w[13]*k+w[9]*Exp(-(k-w[1])^2/(2*w[2]^2))+w[10]*Exp(-(k-w[3])^2/(2*w[4]^2))+w[11]*Exp(-(k-w[5])^2/(2*w[6]^2))+w[12]*Exp(-(k-w[7])^2/(2*w[8]^2))
End

Function QuadLorLin(w,k) : FitFunc
	Wave w
	Variable k

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(k) = y0+m*k+A1*Exp(-(k-k1)^2/(2*sigma1^2))+A2*Exp(-(k-k2)^2/(2*sigma2^2))+A3*Exp(-(k-k3)^2/(2*sigma3^2))+A4*Exp(-(k-k4)^2/(2*sigma4^2))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ k
	//CurveFitDialog/ Coefficients 14
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = k1
	//CurveFitDialog/ w[2] = sigma1
	//CurveFitDialog/ w[3] = k2
	//CurveFitDialog/ w[4] = sigma2
	//CurveFitDialog/ w[5] = k3
	//CurveFitDialog/ w[6] = sigma3
	//CurveFitDialog/ w[7] = k4
	//CurveFitDialog/ w[8] = sigma4
	//CurveFitDialog/ w[9] = A1
	//CurveFitDialog/ w[10] = A2
	//CurveFitDialog/ w[11] = A3
	//CurveFitDialog/ w[12] = A4
	//CurveFitDialog/ w[13] = m

	return w[0]+w[13]*k+w[9]/((k-w[1])^2/w[2]^2+1)+w[10]/((k-w[3])^2/w[4]^2+1)+w[11]/((k-w[5])^2/w[6]^2+1)+w[12]/((k-w[7])^2/w[8]^2+1)
End

Function TripLorLin(w,k) : FitFunc
	Wave w
	Variable k

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(k) = y0+m*k+A1*Exp(-(k-k1)^2/(2*sigma1^2))+A2*Exp(-(k-k2)^2/(2*sigma2^2))+A3*Exp(-(k-k3)^2/(2*sigma3^2))+A4*Exp(-(k-k4)^2/(2*sigma4^2))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ k
	//CurveFitDialog/ Coefficients 11
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = k1
	//CurveFitDialog/ w[2] = sigma1
	//CurveFitDialog/ w[3] = k2
	//CurveFitDialog/ w[4] = sigma2
	//CurveFitDialog/ w[5] = k3
	//CurveFitDialog/ w[6] = sigma3
	//CurveFitDialog/ w[7] = A1
	//CurveFitDialog/ w[8] = A2
	//CurveFitDialog/ w[9] = A3
	//CurveFitDialog/ w[10] = m

	return w[0]+w[10]*k+w[7]/((k-w[1])^2/w[2]^2+1)+w[8]/((k-w[3])^2/w[4]^2+1)+w[9]/((k-w[5])^2/w[6]^2+1)
End

Function DoubLorLin(w,k) : FitFunc
	Wave w
	Variable k

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(k) = y0+m*k+A1*Exp(-(k-k1)^2/(2*sigma1^2))+A2*Exp(-(k-k2)^2/(2*sigma2^2))+A3*Exp(-(k-k3)^2/(2*sigma3^2))+A4*Exp(-(k-k4)^2/(2*sigma4^2))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ k
	//CurveFitDialog/ Coefficients 8
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = k1
	//CurveFitDialog/ w[2] = sigma1
	//CurveFitDialog/ w[3] = k2
	//CurveFitDialog/ w[4] = sigma2
	//CurveFitDialog/ w[5] = A1
	//CurveFitDialog/ w[6] = A2
	//CurveFitDialog/ w[7] = m

	return w[0]+w[7]*k+w[5]/((k-w[1])^2/w[2]^2+1)+w[6]/((k-w[3])^2/w[4]^2+1)
End

Function Lor(w,k) : FitFunc
	Wave w
	Variable k

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(k) = 
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ k
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = k1
	//CurveFitDialog/ w[2] = sigma1
	//CurveFitDialog/ w[3] = A1
	//CurveFitDialog/ w[4] = m

	return w[0]+w[4]*k+w[3]/((k-w[1])^2/w[2]^2+1)
End

Function DoubGauss(w,k) : FitFunc
	Wave w
	Variable k

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(k) = y0+A*Exp(-(k-k1)^2/(2*sigma1^2))+A*Exp(-(k-k2)^2/(2*sigma1^2))+B*Exp(-(k-k3)^2/(2*sigma2)^2)+B*Exp(-(k-k4)^2/(2*sigma2)^2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ k
	//CurveFitDialog/ Coefficients 9
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = B
	//CurveFitDialog/ w[3] = k1
	//CurveFitDialog/ w[4] = k2
	//CurveFitDialog/ w[5] = k3
	//CurveFitDialog/ w[6] = k4
	//CurveFitDialog/ w[7] = sigma1
	//CurveFitDialog/ w[8] = sigma2

	return w[0]+w[1]*Exp(-(k-w[4])^2/(2*w[7]^2))+w[1]*Exp(-(k-w[5])^2/(2*w[7]^2))+w[2]*Exp(-(k-w[3])^2/(2*w[8]^2))+w[2]*Exp(-(k-w[6])^2/(2*w[8]^2))
End

Function Hyperbola(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = a*Sqrt(b^2+(x-x0)^2)+y0
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = a
	//CurveFitDialog/ w[1] = b
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = y0

	return w[0]*Sqrt(w[1]^2+(x-w[2])^2)+w[3]
End

Function fermi(w,e) : FitFunc
	Wave w
	Variable e

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(e) = a/(exp((e-b)/(c))+1)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ e
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = a
	//CurveFitDialog/ w[1] = b
	//CurveFitDialog/ w[2] = c
	//CurveFitDialog/ w[3] = d

	return w[0]/(exp((e-w[1])/(w[2]))+1)+w[3]
End
Function RedimAll()
	variable n
	DFREF dfr=getdatafolderDFR()
	For(n=0;n<CountObjectsDFR(dfr,1);n+=1)
		wave wv=$GetIndexedObjNameDFR(dfr, 1, n)
		Redimension wv	
	endfor			
end

Function FermiAndLinear(w,e) : FitFunc
	Wave w
	Variable e

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(e) = (a+d*e)/(exp((e-b)/(c))+1)+g
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ e
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = a
	//CurveFitDialog/ w[1] = b
	//CurveFitDialog/ w[2] = c
	//CurveFitDialog/ w[3] = d
	//CurveFitDialog/ w[4] = g

	return (w[0]+w[3]*e)/(exp((e-w[1])/(w[2]))+1)+w[4]
End

Function TwoGauss(w,k) : FitFunc
	Wave w
	Variable k

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(k) = y0+A*Exp(-(k-k1)^2/(2*sigma1^2))+B*Exp(-(k-k2)^2/(2*sigma2)^2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ k
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = B
	//CurveFitDialog/ w[3] = k1
	//CurveFitDialog/ w[4] = k2
	//CurveFitDialog/ w[5] = sigma1
	//CurveFitDialog/ w[6] = sigma2

	return w[0]+w[1]*Exp(-(k-w[3])^2/(2*w[5]^2))+w[2]*Exp(-(k-w[4])^2/(2*w[6]^2))
End

Function ThreeGauss(w,k) : FitFunc
	Wave w
	Variable k

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(k) = y0+A*Exp(-(k-k1)^2/(2*sigma1^2))+B*Exp(-(k-k2)^2/(2*sigma2)^2)+C*Exp(-(k-k3)^2/(2*sigma3)^2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ k
	//CurveFitDialog/ Coefficients 10
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = B
	//CurveFitDialog/ w[3] = k1
	//CurveFitDialog/ w[4] = k2
	//CurveFitDialog/ w[5] = sigma1
	//CurveFitDialog/ w[6] = sigma2
	//CurveFitDialog/ w[7] = C
	//CurveFitDialog/ w[8] = k3
	//CurveFitDialog/ w[9] = sigma3

	return w[0]+w[1]*Exp(-(k-w[3])^2/(2*w[5]^2))+w[2]*Exp(-(k-w[4])^2/(2*w[6]^2))+w[7]*Exp(-(k-w[8])^2/(2*w[9]^2))
End

Function FourGauss(w,k) : FitFunc
	Wave w
	Variable k

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(k) = y0+A*Exp(-(k-k1)^2/(2*sigma1^2))+B*Exp(-(k-k2)^2/(2*sigma2)^2)+C*Exp(-(k-k3)^2/(2*sigma3)^2)+D*Exp(-(k-k4)^2/(2*sigma4)^2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ k
	//CurveFitDialog/ Coefficients 13
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = B
	//CurveFitDialog/ w[3] = k1
	//CurveFitDialog/ w[4] = k2
	//CurveFitDialog/ w[5] = sigma1
	//CurveFitDialog/ w[6] = sigma2
	//CurveFitDialog/ w[7] = C
	//CurveFitDialog/ w[8] = k3
	//CurveFitDialog/ w[9] = sigma3
	//CurveFitDialog/ w[10] = D
	//CurveFitDialog/ w[11] = k4
	//CurveFitDialog/ w[12] = sigma4
	return w[0]+w[1]*Exp(-(k-w[3])^2/(2*w[5]^2))+w[2]*Exp(-(k-w[4])^2/(2*w[6]^2))+w[7]*Exp(-(k-w[8])^2/(2*w[9]^2))+w[10]*Exp(-(k-w[11])^2/(2*w[12]^2))
End


Function Lor4Mirror(w,k) : FitFunc
	Wave w
	Variable k

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(k) = y0 + Lor(A, kc-k1,sigma1)+Lor(B,kc-k2, sigma1)+Lor(C,kc+k2,sigma1)+Lor(D,kc+k1,sigma1)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ k
	//CurveFitDialog/ Coefficients 11
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = B
	//CurveFitDialog/ w[3] = C
	//CurveFitDialog/ w[4] = D
	//CurveFitDialog/ w[5] = kc
	//CurveFitDialog/ w[6] = k1
	//CurveFitDialog/ w[7] = k2
	//CurveFitDialog/ w[8] = sigma1
	//CurveFitDialog/ w[9] = sigma2
	//CurveFitDialog/ w[10] = m

	return w[0]+w[10]*k+w[1]/((k-(w[5]-w[6]))^2/w[8]^2+1)+w[2]/((k-(w[5]-w[7]))^2/w[9]^2+1)+w[3]/((k-(w[5]+w[7]))^2/w[9]^2+1)+w[4]/((k-(w[5]+w[6]))^2/w[8]^2+1)
End