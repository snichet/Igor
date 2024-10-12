#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "Macintosh HD:Users:tylerac:Documents:data:IGOR stuff_tc20200904:NanProcs"
//Instructions for GFermi function.
//
//In current version you must input sample temperature (T) by hand.
//The resolution is a fit parameter, w.
//The Fermi level is also a fit parameter.
//Independent linear offsets have been implemented above and below Ef.
//
//pw is a wave of the initial parameter values
//yw is the input wave to be fit to
//xw is a wave the same length as yw, with the xvalue of each point.
//
//You can use GFermi to write the values of yw.
//Example "GFermi(pw,yw,xw)" writes yw based on parameters in pw.
//
//You can also use GFermi with the FuncFit command. In this case if you do not include an xwave (xw) then it automatically calculated one based on wave scaling.
//Example FuncFit /NTHR=0 /TBOX=784 GFermi pw InputWave[Start,Stop] /D
//
//There are some details about how the convolution deals with end points that make it so that the "ywave" below is extended past the end points.
//There is some mechanism for choosing the sampling density of the gaussian and the ywave. Not sure if this always works, but it has worked for my tests.
//resolutionfactor can be changed to suit your purpose. Lower will reduce computation time.

Function GFermi(pw,yw,xw) : FitFunc
	
	wave pw,yw,xw
	
	variable T = 162 //tempurature in K
	variable kb = 8.617333*10^-5 // Boltzmann constant in eV * K^-1

 	//f(x)=(A+B*x)/(exp((x-Ep)/(kb*T))+1)+C+D*x
 	//G(x)=1/(w*sqrt(pi))*exp(-x^2/w^2)
 	//A=pw[0]
 	//Ef=pw[1]
 	//w=pw[2]
 	//B=pw[3]
 	//C=pw[4]
 	//D=pw[5]
 	 	
 	Variable resolutionfactor = 10
 	Variable dx = min(kb*T/resolutionfactor,pw[2]/resolutionfactor)
 	Variable nGaussianWavePnts = round(10*pw[2]/dx)*2+1
 	make/d/free/o/n=(nGaussianWavePnts) GaussianWave
 	Variable nyPnts = 3*(xw[dimsize(xw,0)-1]-xw[0])/dx //3*max(resolutionfactor*numpnts(yw),ngaussianWavePnts)
 	make /d/free/o/n=(nyPnts) yWave
 	
 	setscale /p x -dx*(ngaussianwavepnts/2),dx,gaussianwave
 	setscale /p x, xw[0]-(xw[dimsize(xw,0)-1]-xw[0]),dx,ywave
 	
 	GaussianWave = 1/(pw[2]*sqrt(pi))*exp(-x^2/pw[2]^2)
 	
 	variable sumGauss
 	sumGauss=sum(GaussianWave,-inf,inf)
	gaussianwave/=sumGauss
	 	
 	ywave = (pw[0]+pw[3]*x)/(exp((x-pw[1])/(kb*T))+1)+pw[4]+pw[5]*x
 	
 	convolve /a gaussianwave, ywave

 	yw = ywave(xw[p])
End

Function GFermiAndLor(pw,yw,xw) : FitFunc
	
	wave pw,yw,xw
	
	variable T = 8 //tempurature in K
	variable kb = 8.617333*10^-5 // Boltzmann constant in eV * K^-1

 	//f(x)=((A+B*x)+L1/(1+((x-L3)/L2)^2))/(exp((x-Ep)/(kb*T))+1)+C+D*x
 	//G(x)=1/(w*sqrt(pi))*exp(-x^2/w^2)
 	//A=pw[0]
 	//Ef=pw[1]
 	//w=pw[2]
 	//B=pw[3]
 	//C=pw[4]
 	//D=pw[5]
 	//T=pw[6]
 	//L1=pw[7]
 	//L2=pw[8]
 	//L3=pw[9]
 	 	
 	Variable resolutionfactor = 10
 	Variable dx = min(kb*T/resolutionfactor,pw[2]/resolutionfactor)
 	Variable nGaussianWavePnts = round(10*pw[2]/dx)*2+1
 	make/d/free/o/n=(nGaussianWavePnts) GaussianWave
 	Variable nyPnts = 3*(xw[dimsize(xw,0)-1]-xw[0])/dx //3*max(resolutionfactor*numpnts(yw),ngaussianWavePnts)
 	make /d/free/o/n=(nyPnts) yWave
 	
 	setscale /p x -dx*(ngaussianwavepnts/2),dx,gaussianwave
 	setscale /p x, xw[0]-(xw[dimsize(xw,0)-1]-xw[0]),dx,ywave
 	
 	GaussianWave = 1/(pw[2]*sqrt(pi))*exp(-x^2/pw[2]^2)
 	
 	variable sumGauss
 	sumGauss=sum(GaussianWave,-inf,inf)
	gaussianwave/=sumGauss
	 	
 	ywave = (pw[0]+pw[3]*x+pw[7]/(1+((x-pw[9])/pw[8])^2))/(exp((x-pw[1])/(kb*pw[6]))+1)+pw[4]+pw[5]*x
 	
 	convolve /a gaussianwave, ywave

 	yw = ywave(xw[p])
End

//Now the goal is to fit the BCS coherence peak convoluted with a Gaussian.
//We'll use the same setup as GFermi above.

Function GaussianBCS(pw,yw,xw) : FitFunc
	
	wave pw,yw,xw
	
	variable T = 8 //tempurature in K
	variable kb = 8.617333*10^-5 // Boltzmann constant in eV * K^-1

 	//f(x)=N0*Abs(x)/(x^2-Delta^2)+B
 	//G(x)=1/(w*sqrt(pi))*exp(-x^2/w^2)
 	//N0=pw[0]
 	//Delta=pw[1]
 	//w=pw[2]
 	//B=pw[3]
 	 	
 	Variable resolutionfactor = 10
 	Variable dx = min(kb*T/resolutionfactor,pw[2]/resolutionfactor)
 	Variable nGaussianWavePnts = round(10*pw[2]/dx)*2+1
 	make/d/free/o/n=(nGaussianWavePnts) GaussianWave
 	Variable nyPnts = 3*(xw[dimsize(xw,0)-1]-xw[0])/dx //3*max(resolutionfactor*numpnts(yw),ngaussianWavePnts)
 	make /d/free/o/n=(nyPnts) yWave
 	
 	setscale /p x -dx*(ngaussianwavepnts/2),dx,gaussianwave
 	setscale /i x, xw[0]-(xw[dimsize(xw,0)-1]-xw[0]),-(xw[0]-(xw[dimsize(xw,0)-1]-xw[0])),ywave
 	
 	GaussianWave = 1/(pw[2]*sqrt(pi))*exp(-x^2/pw[2]^2)
 	
 	variable sumGauss
 	sumGauss=sum(GaussianWave,-inf,inf)
	gaussianwave/=sumGauss
	 	
 	ywave = pw[0]*Abs(x)/sqrt(x^2-pw[1]^2)+pw[3]
 	nanstovalue(ywave,pw[3])
 	
 	convolve /a gaussianwave, ywave

 	yw = ywave(xw[p])
End


//So now I want to try to fit the data with the chemical potential not pinned to the middle of the gap.
//The would break particle/hole symmetry.
//Maybe this is physical, idk. But I think the most straight forward thing to do is to fit and unsymmetrized EDC.

Function GaussianBCSUnSym(pw,yw,xw) : FitFunc
	
	wave pw,yw,xw
	
	variable T = 8 //tempurature in K
	variable kb = 8.617333*10^-5 // Boltzmann constant in eV * K^-1

 	//f(x)=N0*Abs((x-mu))/((x-mu)^2-Delta^2)+B
 	//G(x)=1/(w*sqrt(pi))*exp(-x^2/w^2)
 	//N0=pw[0]
 	//Delta=pw[1]
 	//w=pw[2]
 	//B=pw[3]
 	//mu=pw[4]
 	 	
 	Variable resolutionfactor = 10
 	Variable dx = min(kb*T/resolutionfactor,pw[2]/resolutionfactor)
 	Variable nGaussianWavePnts = round(10*pw[2]/dx)*2+1
 	make/d/free/o/n=(nGaussianWavePnts) GaussianWave
 	Variable nyPnts = 3*(xw[dimsize(xw,0)-1]-xw[0])/dx //3*max(resolutionfactor*numpnts(yw),ngaussianWavePnts)
 	make /d/free/o/n=(nyPnts) yWave
 	
 	setscale /p x -dx*(ngaussianwavepnts/2),dx,gaussianwave
 	setscale /i x, xw[0]-(xw[dimsize(xw,0)-1]-xw[0]),-(xw[0]-(xw[dimsize(xw,0)-1]-xw[0])),ywave
 	
 	GaussianWave = 1/(pw[2]*sqrt(pi))*exp(-x^2/pw[2]^2)
 	
 	variable sumGauss
 	sumGauss=sum(GaussianWave,-inf,inf)
	gaussianwave/=sumGauss
	 	
 	ywave = pw[0]*Abs((x-pw[4]))/sqrt((x-pw[4])^2-pw[1]^2)+pw[3]
 	ywave[x2pnt(ywave,-pw[1]+pw[4]),]=pw[3] //Sets imaginary values to zero and removes DOS above gap
 	
 	convolve /a gaussianwave, ywave

 	yw = ywave(xw[p])
End