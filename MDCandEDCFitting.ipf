#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "Macintosh HD:Users:tylerac:Documents:data:IGOR stuff_tc20200904:FittingFunctions"

Function WaterfallMDC(InputCut,SepParameter)
	wave inputcut
	Variable SepParameter//Start with 1 as guess
	string inputcutname = nameofwave(inputcut)

	Display
	
	variable v_avg,i
	string mdcname
	wavestats /q inputcut
	
	For(i=0;i<dimsize(InputCut,1);i+=1)
		
		MDCName=InputcutName+"_MDC"+Num2Str(i)
		Make /O /N=(Dimsize(InputCut,0)) $MDCName
		Wave MDC = $MDCName
		Setscale /p x, dimoffset(InputCut,0),dimdelta(Inputcut,0),MDC
		
		MDC[]=InputCut[p][i]
		
		setscale /p x, dimoffset(inputcut,0),dimdelta(inputcut,0),mdc
		
		AppendToGraph MDC
				
		ModifyGraph offset($MDCName)={0,v_avg*SepParameter*i}
		
	EndFor
	
End

Function WaterfallEDC(InputCutName)

	String InputCutName
	
	Wave InputCut = $InputCutName
	Variable i
	String MDCName
	
	Display
	
	For(i=0;i<dimsize(InputCut,0);i+=1)
		
		MDCName=InputcutName+"_EDC"+Num2Str(i)
		Make /O /N=(Dimsize(InputCut,1)) $MDCName
		Wave MDC = $MDCName
		Setscale /p x, dimoffset(InputCut,1),dimdelta(Inputcut,1),MDC
		
		MDC[]=InputCut[i][p]
		
		AppendToGraph MDC
		
		ModifyGraph offset($MDCName)={0,2.2e4*i}
		
	EndFor
	
End




Function PlotFitEDCsResults(InputWaveName,FirstEDC,LastEDC)
	String InputWaveName
	Variable FirstEDC
	Variable LastEDC
	
	Variable i
	String EDCName
	String EDCFitName
	String Peak1Name
	String Peak2name
	String Peak3name
	
	For(i=FirstEDc;i<=LastEDC;i+=1)
		EDCName = InputWaveName+"_EDC"+Num2Str(i)
		Wave EDC = $EDCName
		EDCfitName = "Fit_" + EDCName
		Wave EDCFit = $EDCFitName
		Peak1Name= EDCName+"_p1"
		Peak2Name= EDCName+"_p2"
		Peak3Name= EDCName+"_p3"
		Wave Peak1 = $Peak1Name
		Wave Peak2 = $Peak2Name
		Wave Peak3 = $Peak3Name
		Display EDC,EDCfit,peak1,peak2, peak3
		Modifygraph lsize=2, rgb($peak2name)=(0,0,0), rgb($EDCName)=(0,0,65000),rgb($EDCfitName)=(0,65000,0),rgb($peak3name)=(0,65000,65000)
	EndFor
	
	String Band1name = InputWaveName+"_band1"
	Wave Band1 = $Band1Name
	String Band2name = InputWaveName+"_band2"
	Wave Band2 = $Band2Name
	Display Band1, Band2
	ModifyGraph lsize=2, rgb($band2name)=(0,0,0)
End

Function FitEDCs(InputWaveName,FirstEDC,LastEDC)
	String InputWaveName
	Variable FirstEDC
	Variable LastEDC
	
///////////////////////////////
	// f(e) = y0+ a/(exp(-(e-b)/(c))+1)*(d+A1/((e-x1)^2+g1^2)+A2/((e-x2)^2+g2^2))
	Variable y0 = 17000
	Variable b = 0.18
	Variable c = .026
	Variable g1 = .14
	Variable x1 = .57
	Variable g2 = .01
	Variable x2 = .1
	Variable A1 = 97000
	Variable A2 = 40000
	Variable d= 54000
	Variable A3= 220000
	Variable x3 = 2.2
	Variable g3 = .65
	Variable m = 6700
///////////////////////////////	
	
	Variable i
	String EDCName
	String EDCFitName
	String Peak1Name
	String Peak2name
	String Peak3name
	String parasname = inputwavename+"_EDCparas"
	String sigsname = inputwavename+"_EDCsigs"
	
	Make /O /N=(14,LastEDC-FirstEDC+1) $parasname
	Duplicate /O $parasname $sigsname
	
	Wave EDCparas=$parasname
	Wave EDCsigmas=$sigsname
	
	Make /O /N=(14) W_coef
	Wave W_Coef
	W_Coef[0] = {y0,b,c,g1,x1,g2,x2,A1,A2,d,A3,x3,g3,m}
	Wave W_sigma
	
	Make /O /T /N=(5) T_Constraints
	T_Constraints[0] = {"K3<.2","K5<.1","K6>0.05","K8 > 0","k8<225000"}
	
	For(i=FirstEDc;i<=LastEDC;i+=1)
		EDCName = InputWaveName+"_EDC"+Num2Str(i)
		Wave EDC = $EDCName
		
		FuncFit /NTHR=0 FermiandTripLor2 W_coef  EDC[30 ,630] /D /C=T_Constraints
				
		EDCparas[][i-FirstEDC]=W_coef[p]
		EDCsigmas[][i-FirstEDC]=W_sigma[p]
		
		EDCfitName = "Fit_" + EDCName
		Wave EDCFit = $EDCFitName
		
		Peak1Name= EDCName+"_p1"
		Peak2Name= EDCName+"_p2"
		Peak3Name= EDCName+"_p3"
		
		Duplicate /O EDCfit $Peak1Name
		Duplicate /O EDCfit $Peak2Name
		Duplicate /O EDCfit $Peak3Name
		Wave Peak1 = $Peak1Name
		Wave Peak2 = $Peak2Name
		Wave Peak3 = $Peak3Name
		
		Peak1[]=edcparas[0][i-FirstEDC]+(edcparas[7][i-FirstEDC]/((x-edcparas[4][i-FirstEDC])^2/edcparas[3][i-FirstEDC]^2+1))
		Peak2[]=edcparas[0][i-FirstEDC]+(edcparas[8][i-FirstEDC]/((x-edcparas[6][i-FirstEDC])^2/edcparas[5][i-FirstEDC]^2+1))
		Peak3[]=edcparas[0][i-FirstEDC]+(edcparas[10][i-FirstEDC]/((x-edcparas[11][i-FirstEDC])^2/edcparas[12][i-FirstEDC]^2+1))
		
		Display EDC,EDCfit,peak1,peak2, peak3
	
		Modifygraph lsize=2, rgb($peak2name)=(0,0,0), rgb($EDCName)=(0,0,65000),rgb($EDCfitName)=(0,65000,0),rgb($peak3name)=(0,65000,65000)
		
	EndFor
	
	String Band1name = InputWaveName+"_band1"
	Make /O /N=(dimsize(edcparas,1)) $Band1Name
	Wave Band1 = $Band1Name
	Band1[] = edcparas[4][p]
	
	String Band2name = InputWaveName+"_band2"
	Make /O /N=(dimsize(edcparas,1)) $Band2Name
	Wave Band2 = $Band2Name
	Band2[] = edcparas[6][p]
	
	setscale/p x,firstedc,1,band1
	setscale/p x, firstedc, 1, band2
	
	Display Band1, Band2
	ModifyGraph lsize=2, rgb($band2name)=(0,0,0)

End

Function FitMDCs(InputWaveName,FirstMDC,LastMDC)
	String InputWaveName
	Variable FirstMDC
	Variable LastMDC
	
///////////////////////////////
	//f(k) = y0+A1*Exp(-(k-k1)^2/(2*sigma1^2))+A2*Exp(-(k-k2)^2/(2*sigma2^2))+A3*Exp(-(k-k3)^2/(2*sigma3^2))+A4*Exp(-(k-k4)^2/(2*sigma4^2))
	Variable y0 = 51000
	Variable A1 = 180000
	Variable k1 = -.72
	Variable sigma1 = .06
	Variable A2 = 145000
	Variable k2 = -.6
	Variable sigma2 = .02
	Variable A3 = 125000
	Variable k3 = -.14
	Variable sigma3 = .06
	Variable A4 = 73000
	Variable k4 = 0.04
	Variable sigma4 = .06
///////////////////////////////	
	
	Variable i
	String MDCName
	String MDCfitName
	String peak1name
	String peak2name
	String peak3name
	String peak4name
	
	Make /O /N=(13,FirstMDC-LastMDC+1) MDCparas
	Duplicate /O MDCparas MDCsigmas
	
	Make /O /D /N=(13) W_coef
	Wave W_Coef
	W_Coef[0] = {y0,k1,sigma1,k2,sigma2,k3,sigma3,k4,sigma4,A1,A2,A3,A4}
	Make /O /T /N=(23) T_Constraints
	

	Wave W_sigma
	
	For(i=FirstMDC;i>=LastMDC;i-=1)
		MDCName = InputWaveName+"_MDC"+Num2Str(i)
		MDCfitName = "fit_" + MDCName
		Peak1name = MDCName + "_p1"
		Peak2name = MDCName + "_p2"
		Peak3name = MDCName + "_p3"
		Peak4name = MDCName + "_p4"
		Wave MDC = $MDCName
		Wave MDCfit = $MDCfitname
		
		FuncFit/X=1/NTHR=0 QuadGauss W_coef  MDC[137 ,284] /D /C=T_Constraints
		
		MDCparas[][FirstMDC-i]=W_coef[p]
		MDCsigmas[][FirstMDC-i]=W_sigma[p]
		
		Duplicate/O MDCfit $Peak1Name
		Duplicate/O MDCfit $Peak2Name
		Duplicate/O MDCfit $Peak3Name
		Duplicate/O MDCfit $Peak4Name		
		Wave peak1= $peak1name
		wave peak2 = $peak2name
		wave peak3 = $peak3name
		wave peak4 = $peak4name
		
		peak1[]=MDCparas[0][FirstMDC-i]+MDCparas[9][FirstMDC-i]*Exp(-(x-MDCparas[1][FirstMDC-i])^2/(2*MDCparas[2][FirstMDC-i]^2))
		peak2[]=MDCparas[0][FirstMDC-i]+MDCparas[10][FirstMDC-i]*Exp(-(x-MDCparas[3][FirstMDC-i])^2/(2*MDCparas[4][FirstMDC-i]^2))
		peak3[]=MDCparas[0][FirstMDC-i]+MDCparas[11][FirstMDC-i]*Exp(-(x-MDCparas[5][FirstMDC-i])^2/(2*MDCparas[6][FirstMDC-i]^2))
		peak4[]=MDCparas[0][FirstMDC-i]+MDCparas[12][FirstMDC-i]*Exp(-(x-MDCparas[7][FirstMDC-i])^2/(2*MDCparas[8][FirstMDC-i]^2))

		
		Display MDC, MDCfit,peak1, peak2,peak3,peak4
		
		ModifyGraph rgb($MDCName)=(0,0,0),rgb($MDCfitname)=(1,16019,65535), lsize=2, rgb($peak2name)=(65535,43690,0), rgb($peak3name)=(32792,65535,1), rgb($peak4name)=(0,65535,65535)
	EndFor
	
	

End

Function FitMDCsQuadGaussLin(InputWaveName,FirstMDC,LastMDC)
	String InputWaveName
	Variable FirstMDC
	Variable LastMDC
	
///////////////////////////////
	//f(k) = y0+A1*Exp(-(k-k1)^2/(2*sigma1^2))+A2*Exp(-(k-k2)^2/(2*sigma2^2))+A3*Exp(-(k-k3)^2/(2*sigma3^2))+A4*Exp(-(k-k4)^2/(2*sigma4^2))
	Variable y0 = 63000
	Variable k1 = -.74
	Variable sigma1 = .044
	Variable k2 = -.61
	Variable sigma2 = .061
	Variable k3 = -.13
	Variable sigma3 = .16
	Variable k4 = .098
	Variable sigma4 = .030
	Variable A1 = 1.5e5
	Variable A2 = 1.0e5
	Variable A3 = 8.5e4
	Variable A4 = 2.5e4
	Variable m = -2.0e4
///////////////////////////////	
	
	Variable i
	String MDCName
	String MDCfitName
	String peak1name
	String peak2name
	String peak3name
	String peak4name
	
	Make /O /N=(14,FirstMDC-LastMDC+1) MDCparas
	Duplicate /O MDCparas MDCsigmas
	
	Make /O /D /N=(14) W_coef
	Wave W_Coef
	W_Coef[0] = {y0,k1,sigma1,k2,sigma2,k3,sigma3,k4,sigma4,A1,A2,A3,A4,m}
	Make /O /T /N=(9) T_Constraints
	T_Constraints[0] = {"K0>0","K2>0","K4>0","K6>0","K8>0","K9>0","K10>0","K11>0","K12>0"}
	

	Wave W_sigma
	
	For(i=FirstMDC;i>=LastMDC;i-=1)
		MDCName = InputWaveName+"_MDC"+Num2Str(i)
		MDCfitName = "fit_" + MDCName
		Peak1name = MDCName + "_p1"
		Peak2name = MDCName + "_p2"
		Peak3name = MDCName + "_p3"
		Peak4name = MDCName + "_p4"
		Wave MDC = $MDCName
		Wave MDCfit = $MDCfitname
		
		FuncFit/X=0/NTHR=0 QuadGaussLin W_coef  MDC[130 ,300] /D /C=T_Constraints
		
		MDCparas[][FirstMDC-i]=W_coef[p]
		MDCsigmas[][FirstMDC-i]=W_sigma[p]
		
		Duplicate/O MDCfit $Peak1Name
		Duplicate/O MDCfit $Peak2Name
		Duplicate/O MDCfit $Peak3Name
		Duplicate/O MDCfit $Peak4Name		
		Wave peak1= $peak1name
		wave peak2 = $peak2name
		wave peak3 = $peak3name
		wave peak4 = $peak4name
		
		peak1[]=MDCparas[0][FirstMDC-i]+MDCparas[9][FirstMDC-i]*Exp(-(x-MDCparas[1][FirstMDC-i])^2/(2*MDCparas[2][FirstMDC-i]^2))
		peak2[]=MDCparas[0][FirstMDC-i]+MDCparas[10][FirstMDC-i]*Exp(-(x-MDCparas[3][FirstMDC-i])^2/(2*MDCparas[4][FirstMDC-i]^2))
		peak3[]=MDCparas[0][FirstMDC-i]+MDCparas[11][FirstMDC-i]*Exp(-(x-MDCparas[5][FirstMDC-i])^2/(2*MDCparas[6][FirstMDC-i]^2))
		peak4[]=MDCparas[0][FirstMDC-i]+MDCparas[12][FirstMDC-i]*Exp(-(x-MDCparas[7][FirstMDC-i])^2/(2*MDCparas[8][FirstMDC-i]^2))

		
		Display MDC, MDCfit,peak1, peak2,peak3,peak4
		
		ModifyGraph rgb($MDCName)=(0,0,0),rgb($MDCfitname)=(1,16019,65535), lsize=2, rgb($peak2name)=(65535,43690,0), rgb($peak3name)=(32792,65535,1), rgb($peak4name)=(0,65535,65535)
	EndFor
	
	

End

Function FitMDCsQuadLorLin(InputWaveName,FirstMDC,LastMDC)
	String InputWaveName
	Variable FirstMDC
	Variable LastMDC
	
///////////////////////////////
	Variable y0 = 3191
	Variable k1 = -0.066-.355
	Variable sigma1 = .18
	Variable k2 = -0.066-.13
	Variable sigma2 = .15
	Variable k3 = -0.066+.13
	Variable sigma3 = .15
	Variable k4 = -0.066+.355
	Variable sigma4 = .18
	Variable A1 = 1467
	Variable A2 = 1800
	Variable A3 = 190
	Variable A4 = 1483
	Variable m = 648
	
	variable numparameters = 14
	
	variable FirstPoint = 482
	variable LastPoint  = 597
///////////////////////////////	
	
	Make /O /D /N=(numparameters) W_coef
	Wave W_Coef
	Wave W_sigma
	W_Coef[0] = {y0,k1,sigma1,k2,sigma2,k3,sigma3,k4,sigma4,A1,A2,A3,A4,m}
	Make /O /T /N=(4) T_Constraints
	T_Constraints[0] = {"k9 > 0","k10 > 0", "k11 > 0", "k12 > 0"}
	
	Variable i=0,aa
	String MDCName
	String MDCfitName
	String peak1name
	String peak2name
	String peak3name
	String peak4name
	
	String ParasName
	Do
		ParasName = InputWaveName+"_L4Paras"+num2str(i)
		i+=1
		aa=exists(ParasName)
	While(aa==1)
	Make /O /N=(numparameters,LastMDC-FirstMDC+1) $parasName
	Wave paras = $parasname
	
	i=0
	
	String SigmasName
	Do
		SigmasName = InputWaveName+"_L4Sigmas"+num2str(i)
		i+=1
		aa=exists(SigmasName)
	While(aa==1)
	Duplicate /o paras $sigmasname
	Wave sigmas = $SigmasName
		
	make /o /n=4 temp
	wave temp
	
	For(i=FirstMDC;i<=LastMDC;i+=1)
		MDCName = InputWaveName+"_MDC"+Num2Str(i)
		MDCfitName = "fit_" + MDCName
		Peak1name = MDCName + "_p1"
		Peak2name = MDCName + "_p2"
		Peak3name = MDCName + "_p3"
		Peak4name = MDCName + "_p4"
		Wave MDC = $MDCName
		Wave MDCfit = $MDCfitname
		
		FuncFit/NTHR=0 QuadLorLin W_coef  MDC[FirstPoint ,LastPoint] /D /C=T_Constraints
		
		paras[][i-FirstMDC]=W_coef[p]
		sigmas[][i-FirstMDC]=W_sigma[p]
		
		Duplicate/O MDCfit $Peak1Name
		Duplicate/O MDCfit $Peak2Name
		Duplicate/O MDCfit $Peak3Name
		Duplicate/O MDCfit $Peak4Name		
		Wave peak1= $peak1name
		wave peak2 = $peak2name
		wave peak3 = $peak3name
		wave peak4 = $peak4name
		
		temp[0]={paras[0][i-FirstMDC],paras[1][i-FirstMDC],paras[2][i-FirstMDC],paras[9][i-FirstMDC],paras[13][i-FirstMDC]}
		peak1[]=lor(temp,x)
		temp[0]={paras[0][i-FirstMDC],paras[3][i-FirstMDC],paras[4][i-FirstMDC],paras[10][i-FirstMDC],paras[13][i-FirstMDC]}
		peak2[]=lor(temp,x)
		temp[0]={paras[0][i-FirstMDC],paras[5][i-FirstMDC],paras[6][i-FirstMDC],paras[11][i-FirstMDC],paras[13][i-FirstMDC]}
		peak3[]=lor(temp,x)
		temp[0]={paras[0][i-FirstMDC],paras[7][i-FirstMDC],paras[8][i-FirstMDC],paras[12][i-FirstMDC],paras[13][i-FirstMDC]}
		peak4[]=lor(temp,x)
		
		Display MDC, MDCfit,peak1, peak2,peak3,peak4
		SetAxis bottom -0.8,0.8
		
		ModifyGraph rgb($MDCName)=(0,0,0),rgb($MDCfitname)=(1,16019,65535), lsize=2, rgb($peak2name)=(65535,43690,0), rgb($peak3name)=(32792,65535,1), rgb($peak4name)=(0,65535,65535)
	EndFor
	
	String Band1name = InputWaveName+"_MDCband1"
	Make /O /N=(dimsize(paras,1)) $Band1Name
	Wave Band1 = $Band1Name
	Band1[] = paras[1][p]
	
	String Band2name = InputWaveName+"_MDCband2"
	Make /O /N=(dimsize(paras,1)) $Band2Name
	Wave Band2 = $Band2Name
	Band2[] = paras[3][p]
	
	String Band3name = InputWaveName+"_MDCband3"
	Make /O /N=(dimsize(paras,1)) $Band3Name
	Wave Band3 = $Band3Name
	Band3[] = paras[5][p]
	
	String Band4name = InputWaveName+"_MDCband4"
	Make /O /N=(dimsize(paras,1)) $Band4Name
	Wave Band4 = $Band4Name
	Band4[] = paras[7][p]
	
	setscale/p x,firstmdc,1,band1
	setscale/p x, firstmdc, 1, band2
	setscale/p x, firstmdc, 1, band3
	setscale/p x, firstmdc, 1, band4
	
	Display /VERT Band1, Band2, Band3, Band4
	ModifyGraph lsize=2, rgb($band2name)=(65535,43690,0),rgb($band3name)=(32792,65535,1),rgb($band4name)=(0,65535,65535)

End

Function FitMDCsTripLorLin(InputWaveName,FirstMDC,LastMDC)
	String InputWaveName
	Variable FirstMDC
	Variable LastMDC
	
///////////////////////////////
	Variable y0 = 2106  
	Variable k1 = -.24
	Variable sigma1 = .082
	Variable k2 = -0.067
	Variable sigma2 = .18
	Variable k3 = .23
	Variable sigma3 = .085
	Variable A1 = 1010
	Variable A2 = 2290
	Variable A3 = 1300
	Variable m = 112
	
	variable numparameters=11
	
	Variable firstpoint = 482
	variable LastPoint  = 597
///////////////////////////////	
	
	Make /O /D /N=(numparameters) W_coef
	Wave W_Coef
	Wave W_sigma
	W_Coef[0] = {y0,k1,sigma1,k2,sigma2,k3,sigma3,A1,A2,A3,m}
	Make /O /T /N=(3) T_Constraints
	T_Constraints[0] = {"k7 > 0","k8 > 0", "k9 > 0"}
	
	Variable i=0,aa
	String MDCName
	String MDCfitName
	String peak1name
	String peak2name
	String peak3name
	String peak4name
	
	String ParasName
	Do
		ParasName = InputWaveName+"_L3Paras"+num2str(i)
		i+=1
		aa=exists(ParasName)
	While(aa==1)
	Make /O /N=(numparameters,LastMDC-FirstMDC+1) $parasName
	Wave paras = $parasname
	
	i=0
	
	String SigmasName
	Do
		SigmasName = InputWaveName+"_L3Sigmas"+num2str(i)
		i+=1
		aa=exists(SigmasName)
	While(aa==1)
	Duplicate /o paras $sigmasname
	Wave sigmas = $SigmasName
		
	make /o /n=4 temp
	wave temp
	
	For(i=FirstMDC;i<=LastMDC;i+=1)
		MDCName = InputWaveName+"_MDC"+Num2Str(i)
		MDCfitName = "fit_" + MDCName
		Peak1name = MDCName + "_p1"
		Peak2name = MDCName + "_p2"
		Peak3name = MDCName + "_p3"
		Wave MDC = $MDCName
		
		FuncFit/NTHR=0 TripLorLin W_coef  MDC[FirstPoint ,LastPoint] /D /C=T_Constraints
		Wave MDCfit = $MDCfitname

		
		paras[][i-FirstMDC]=W_coef[p]
		sigmas[][i-FirstMDC]=W_sigma[p]
		
		Duplicate/O MDCfit $Peak1Name
		Duplicate/O MDCfit $Peak2Name
		Duplicate/O MDCfit $Peak3Name
		Wave peak1= $peak1name
		wave peak2 = $peak2name
		wave peak3 = $peak3name
		
		temp[0]={paras[0][i-FirstMDC],paras[1][i-FirstMDC],paras[2][i-FirstMDC],paras[7][i-FirstMDC],paras[10][i-FirstMDC]}
		peak1[]=lor(temp,x)
		temp[0]={paras[0][i-FirstMDC],paras[3][i-FirstMDC],paras[4][i-FirstMDC],paras[8][i-FirstMDC],paras[10][i-FirstMDC]}
		peak2[]=lor(temp,x)
		temp[0]={paras[0][i-FirstMDC],paras[5][i-FirstMDC],paras[6][i-FirstMDC],paras[9][i-FirstMDC],paras[10][i-FirstMDC]}
		peak3[]=lor(temp,x)
		
		Display MDC, MDCfit,peak1, peak2,peak3
		SetAxis bottom -0.8,0.8
		
		ModifyGraph rgb($MDCName)=(0,0,0),rgb($MDCfitname)=(1,16019,65535), lsize=2, rgb($peak2name)=(65535,43690,0), rgb($peak3name)=(32792,65535,1)
	EndFor
	
	String Band1name = InputWaveName+"_MDCband1"
	Make /O /N=(dimsize(paras,1)) $Band1Name
	Wave Band1 = $Band1Name
	Band1[] = paras[1][p]
	
	String Band2name = InputWaveName+"_MDCband2"
	Make /O /N=(dimsize(paras,1)) $Band2Name
	Wave Band2 = $Band2Name
	Band2[] = paras[3][p]
	
	String Band3name = InputWaveName+"_MDCband3"
	Make /O /N=(dimsize(paras,1)) $Band3Name
	Wave Band3 = $Band3Name
	Band3[] = paras[5][p]
	
	setscale/p x,firstmdc,1,band1
	setscale/p x, firstmdc, 1, band2
	setscale/p x, firstmdc, 1, band3
	
	Display /VERT Band1, Band2, Band3
	ModifyGraph lsize=2, rgb($band2name)=(65535,43690,0),rgb($band3name)=(32792,65535,1)

End


Function FitMDCsDoubLorLin(InputWaveName,FirstMDC,LastMDC)
	String InputWaveName
	Variable FirstMDC
	Variable LastMDC
	
///////////////////////////////
	Variable y0 = 1450
	Variable k1 = -.02
	Variable sigma1 = .08
	Variable k2 = -0.067
	Variable sigma2 = .12
	Variable A1 = 500
	Variable A2 = 500
	Variable m = 0
	
	variable numparameters=8
	
	Variable firstpoint = 482
	variable LastPoint  = 597
///////////////////////////////	
	
	Make /O /D /N=(numparameters) W_coef
	Wave W_Coef
	Wave W_sigma
	W_Coef[0] = {y0,k1,sigma1,k2,sigma2,A1,A2,m}
	Make /O /T /N=(2) T_Constraints
	T_Constraints[0] = {"k6 > 0","k7 > 0"}
	
	Variable i=0,aa
	String MDCName
	String MDCfitName
	String peak1name
	String peak2name
	
	String ParasName
	Do
		ParasName = InputWaveName+"_L2Paras"+num2str(i)
		i+=1
		aa=exists(ParasName)
	While(aa==1)
	Make /O /N=(numparameters,LastMDC-FirstMDC+1) $parasName
	Wave paras = $parasname
	
	i=0
	
	String SigmasName
	Do
		SigmasName = InputWaveName+"_L2Sigmas"+num2str(i)
		i+=1
		aa=exists(SigmasName)
	While(aa==1)
	Duplicate /o paras $sigmasname
	Wave sigmas = $SigmasName
		
	make /o /n=4 temp
	wave temp
	
	For(i=FirstMDC;i<=LastMDC;i+=1)
		MDCName = InputWaveName+"_MDC"+Num2Str(i)
		MDCfitName = "fit_" + MDCName
		Peak1name = MDCName + "_p1"
		Peak2name = MDCName + "_p2"
		Wave MDC = $MDCName
		
		FuncFit/NTHR=0 DoubLorLin W_coef  MDC[FirstPoint ,LastPoint] /D /C=T_Constraints
		Wave MDCfit = $MDCfitname
		
		paras[][i-FirstMDC]=W_coef[p]
		sigmas[][i-FirstMDC]=W_sigma[p]
		
		Duplicate/O MDCfit $Peak1Name
		Duplicate/O MDCfit $Peak2Name
		Wave peak1= $peak1name
		wave peak2 = $peak2name
		
		temp[0]={paras[0][i-FirstMDC],paras[1][i-FirstMDC],paras[2][i-FirstMDC],paras[5][i-FirstMDC],paras[7][i-FirstMDC]}
		peak1[]=lor(temp,x)
		temp[0]={paras[0][i-FirstMDC],paras[3][i-FirstMDC],paras[4][i-FirstMDC],paras[6][i-FirstMDC],paras[7][i-FirstMDC]}
		peak2[]=lor(temp,x)
		
		Display MDC, MDCfit,peak1, peak2
		SetAxis bottom -0.8,0.8
		
		ModifyGraph rgb($MDCName)=(0,0,0),rgb($MDCfitname)=(1,16019,65535), lsize=2, rgb($peak2name)=(65535,43690,0)
	EndFor
	
	String Band1name = InputWaveName+"_MDCband1"
	Make /O /N=(dimsize(paras,1)) $Band1Name
	Wave Band1 = $Band1Name
	Band1[] = paras[1][p]
	
	String Band2name = InputWaveName+"_MDCband2"
	Make /O /N=(dimsize(paras,1)) $Band2Name
	Wave Band2 = $Band2Name
	Band2[] = paras[3][p]
	
	setscale/p x,firstmdc,1,band1
	setscale/p x, firstmdc, 1, band2
	
	Display /VERT Band1, Band2
	ModifyGraph lsize=2, rgb($band2name)=(65535,43690,0)

End


Function PlotFit2MDCPeaksResults(InputWaveName,FirstMDC,LastMDC)
	String InputWaveName
	Variable FirstMDC
	Variable LastMDC

	Variable i
	String MDCName
	String MDCfitName
	String peak1name
	String peak2name
	String peak3name
	String peak4name
	
	For(i=FirstMDC;i>=LastMDC;i-=1)
		MDCName = InputWaveName+"_MDC"+Num2Str(i)
		MDCfitName = "fit_" + MDCName
		Peak1name = MDCName + "_p1"
		Peak2name = MDCName + "_p2"
		Peak3name = MDCName + "_p3"
		Peak4name = MDCName + "_p4"
		Wave MDC = $MDCName
		Wave MDCfit = $MDCfitname
		Wave peak1= $peak1name
		wave peak2 = $peak2name
		Wave peak3 = $peak3name
		Wave peak4 = $peak4name
		Display MDC, MDCfit,peak1, peak2,peak3,peak4
		
		ModifyGraph rgb($MDCName)=(0,0,0),rgb($MDCfitname)=(1,16019,65535), lsize=2, rgb($peak2name)=(65535,43690,0), rgb($peak3name)=(32792,65535,1), rgb($peak4name)=(0,65535,65535)
	EndFor
End

Function Fit2MDCPeaks(InputWaveName,FirstMDC,LastMDC)
	String InputWaveName
	Variable FirstMDC
	Variable LastMDC
	
///////////////////////////////
	//f(k) = y0+A1*Exp(-(k-k1)^2/(2*sigma1^2))+A2*Exp(-(k-k2)^2/(2*sigma2^2))
	Variable y0 = 140000
	Variable A = 220000
	Variable B = 55000
	Variable k1 = -1.99
	Variable k2 = -1.49
	Variable k3 = -1.34
	Variable k4 = -.84 
	Variable sigma1 = .059
	Variable sigma2 = .059
///////////////////////////////	
	
	Variable i
	String MDCName
	String MDCfitName
	String peak1name
	String peak2name
	String peak3name
	String peak4name
	
	String MDC2PeakParasName = InputWaveName+"_MDC2PeakParas"
	Make /O /N=(9,FirstMDC-LastMDC+1) $MDC2peakparasName
	Wave MDC2peakparas = $MDC2peakparasname
	String MDC2PeakSigmasName = InputWaveName+"_MDC2PeakSigmas"
	Duplicate /O MDC2peakparas $MDC2peaksigmasName
	Wave MDC2PeakSigmas = $MDC2PeakSigmasName
	
	Make /O /D /N=(9) W_coef
	Wave W_Coef
	W_Coef[0] = {y0,A,B,k1,k2,k3,k4,sigma1,sigma2}
	Make /O /T /N=(1) T_Constraints
	T_Constraints[0] = {"K7 < .5"}
	
	Wave W_sigma
	
	For(i=FirstMDC;i>=LastMDC;i-=1)
		MDCName = InputWaveName+"_MDC"+Num2Str(i)
		MDCfitName = "fit_" + MDCName
		Peak1name = MDCName + "_p1"
		Peak2name = MDCName + "_p2"
		Peak3name = MDCName + "_p3"
		Peak4name = MDCName + "_p4"
		Wave MDC = $MDCName
		Wave MDCfit = $MDCfitname
		
		FuncFit/X=1 /H= "000000011" /NTHR=1 DoubGauss W_coef  MDC[15 ,161] /D //C=T_Constraints
		
		MDC2peakparas[][FirstMDC-i]=W_coef[p]
		MDC2peaksigmas[][FirstMDC-i]=W_sigma[p]
		
		Duplicate/O MDCfit $Peak1Name
		Duplicate/O MDCfit $Peak2Name
		Duplicate /O MDCfit $Peak3Name
		Duplicate /O MDCfit $Peak4Name
		Wave peak1= $peak1name
		wave peak2 = $peak2name
		Wave peak3 = $peak3name
		Wave peak4 = $peak4name
		
		peak1[]=MDC2peakparas[0][FirstMDC-i]+MDC2peakparas[2][FirstMDC-i]*Exp(-(x-MDC2peakparas[3][FirstMDC-i])^2/(2*MDC2peakparas[8][FirstMDC-i]^2))
		peak2[]=MDC2peakparas[0][FirstMDC-i]+MDC2peakparas[1][FirstMDC-i]*Exp(-(x-MDC2peakparas[4][FirstMDC-i])^2/(2*MDC2peakparas[7][FirstMDC-i]^2))
		peak3[]=MDC2peakparas[0][FirstMDC-i]+MDC2peakparas[1][FirstMDC-i]*Exp(-(x-MDC2peakparas[5][FirstMDC-i])^2/(2*MDC2peakparas[7][FirstMDC-i]^2))
		peak4[]=MDC2peakparas[0][FirstMDC-i]+MDC2peakparas[2][FirstMDC-i]*Exp(-(x-MDC2peakparas[6][FirstMDC-i])^2/(2*MDC2peakparas[8][FirstMDC-i]^2))
		
		Display MDC, MDCfit,peak1, peak2,peak3,peak4
		
		ModifyGraph rgb($MDCName)=(0,0,0),rgb($MDCfitname)=(1,16019,65535), lsize=2, rgb($peak2name)=(65535,43690,0), rgb($peak3name)=(32792,65535,1), rgb($peak4name)=(0,65535,65535)
	EndFor
	
	

End



Function PartialWaterfallMDC(InputCutName,SepParameter,First,Last)

	String InputCutName
	Variable SepParameter
	Variable First
	Variable Last
	
	Wave InputCut = $InputCutName
	
	variable v_avg,i
	string mdcname
	wavestats /q inputcut
	
	Display
	
	For(i=First;i<=Last;i+=1)
		
		MDCName=InputcutName+"_MDC"+Num2Str(i)
		Make /O /N=(Dimsize(InputCut,0)) $MDCName
		Wave MDC = $MDCName
		Setscale /p x, dimoffset(InputCut,0),dimdelta(Inputcut,0),MDC
		
		MDC[]=InputCut[p][i]
		
		AppendToGraph MDC
		
		ModifyGraph offset($MDCName)={0,v_avg*SepParameter*i}
		
	EndFor
	
End

Function PartialWaterfallEDC(InputCutName,First,Last)

	String InputCutName
	Variable First
	Variable Last
	
	Wave InputCut = $InputCutName
	Variable i
	String MDCName
	
	//Display
	
	For(i=First;i<=Last;i+=1)
		
		MDCName=InputcutName+"_MDC"+Num2Str(i)
		Make /O /N=(Dimsize(InputCut,1)) $MDCName
		Wave MDC = $MDCName
		Setscale /p x, dimoffset(InputCut,1),dimdelta(Inputcut,1),MDC
		
		MDC[]=InputCut[i][p]
		
		AppendToGraph MDC
		
		ModifyGraph offset($MDCName)={0,2e-6*(i)}
		
	EndFor
	
End

Function mdcyvalue(InputBaseName,PeakPositionWave,FirstMDC,LastMDC,OffsetSeparation,IndexedByPoint)

	String InputBaseName
	Wave PeakPositionWave
	Variable FirstMDC
	Variable LastMDC
	Variable OffsetSeparation
	Variable IndexedByPoint //1 if PeakPositionWave is indexed by point, 0 if it is indexed by value
	
	String MDCName
	Variable i
	String yValueWavename = InputBaseName+"_WFyValues"
	Make /o /N=(LastMDC-FirstMDC+1) $yValueWaveName
	wave yValueWave = $yValueWaveName
	
	For(i=firstMDC;i<=lastMDC;i+=1)
		MDCName = InputBaseName+num2str(i)
		Wave MDC = $MDCName
		If(IndexedByPoint==1)
			yValueWave[i-FirstMDC]=MDC[PeakPositionWave[i-FirstMDC]]+OffsetSeparation*i
		Else
			yValueWave[i-firstMDC]=MDC[round((PeakPositionWave[i-FirstMDC]-dimoffset(MDC,0))/dimdelta(mdc,0))]+OffsetSeparation*i
		EndIf
	EndFor
End

Function mdcxvalue(InputBaseName,PeakPointWave)
	
	String InputBaseName
	Wave PeakPointWave
	
	String OutputWaveName = InputBaseName + "_WFxValues"
	Duplicate /o PeakPointWave  $OutputWaveName
	Wave OutputWave = $OutputWaveName
	
	String SampleWaveName = InputBaseName + "0"
	Wave SampleWave = $SampleWaveName
	
	OutputWave[]=dimoffset(SampleWave,0)+PeakPointWave[p]*dimdelta(SampleWave,0)
	
End

Function edcyvalue(InputWaveName,first,last)
	String InputWaveName
	Variable First
	Variable Last
	
	String EDCName
	Variable i
	string ParasWavename = InputwaveName + "_EDCparas"
	wave ParasWave = $ParasWaveName
	
	String yValueWavename = InputWaveName + "_EDCBand2Position_y"
	Make /o /N=(last-first+1) $yValueWaveName
	wave yValueWave = $yValueWavename
	
	For(i=first;i<=last;i+=1)
		EDCName = InputWaveName + "_EDC" + Num2Str(i)
		Wave EDC = $EDCName
		yValueWave[i-first]=EDC[round((Paraswave[6][i-first+3]-dimoffset(EDC,0))/dimdelta(edc,0))]+2.2e4*(i)
	EndFor
End

//This one was first used for NiRhSi on 20190919 - TC
Function WFFitLor4Mirror(InputWaveName,FirstMDC,LastMDC)
	String InputWaveName
	Variable FirstMDC
	Variable LastMDC
	
///////////////////////////////
	//f(k) = Lor4Mirror
	Variable y0 = 3197
	Variable A = 1463
	Variable B = 1796
	Variable C = 191
	Variable D = 1481
	Variable kc = -0.066
	Variable k1 = 0.35
	Variable k2 = 0.13 
	Variable sigma1 = .18
	Variable sigma2 = .15
	Variable m = 642
	
	Variable numparameters = 11
	
	Variable StartPoint = 482
	Variable EndPoint = 597
///////////////////////////////	

	
	Make /O /D /N=(numparameters) W_coef
	Wave W_Coef
	Wave W_sigma
	W_Coef[0] = {y0,A,B,C, D, kc, k1,k2,sigma1,sigma2,m}
	Make /O /T /N=(3) T_Constraints
	T_Constraints[0] = {"K1 > 0", "K2 > 0", "K3 > 0","k4 > 0"}
	
	Variable i,aa
	String MDCName
	String MDCfitName
	String peak1name
	String peak2name
	String peak3name
	String peak4name
	
	String ParasName
	Do
		ParasName = InputWaveName+"_L4MParas"+num2str(i)
		i+=1
		aa=exists(ParasName)
	While(aa==1)
	Make /O /N=(numparameters,LastMDC-FirstMDC+1) $parasName
	Wave paras = $parasname
	
	String SigmasName
	Do
		SigmasName = InputWaveName+"_L4MSigmas"+num2str(i)
		i+=1
		aa=exists(SigmasName)
	While(aa==1)
	Duplicate /o paras $sigmasname
	Wave sigmas = $SigmasName
	
	make /o /n=(5) LorParameters
	wave LorParameters
		
	For(i=FirstMDC;i<=LastMDC;i+=1)
		MDCName = InputWaveName+"_MDC"+Num2Str(i)
		MDCfitName = "fit_" + MDCName
		Peak1name = MDCName + "_p1"
		Peak2name = MDCName + "_p2"
		Peak3name = MDCName + "_p3"
		Peak4name = MDCName + "_p4"
		Wave MDC = $MDCName
		Print "Fitting " +MDCName
		
		FuncFit/X=1 /NTHR=1 Lor4Mirror W_coef  MDC[StartPoint ,EndPoint] /D /C=T_Constraints
		Wave MDCfit = $MDCfitname

		paras[][i-FirstMDC]=W_coef[p]
		sigmas[][i-FirstMDC]=W_sigma[p]
		
		Duplicate/O MDCfit $Peak1Name
		Duplicate/O MDCfit $Peak2Name
		Duplicate/O MDCfit $Peak3Name
		Duplicate/O MDCfit $Peak4Name
		Wave peak1 = $peak1name
		Wave peak2 = $peak2name
		Wave peak3 = $peak3name
		Wave peak4 = $peak4name
		
		LorParameters[0]={w_coef[0],w_coef[5]-w_coef[6],w_coef[8],w_coef[1],w_coef[10]}
		peak1[]=Lor(LorParameters,x)
		
		LorParameters[0]={w_coef[0],w_coef[5]-w_coef[7],w_coef[9],w_coef[2],w_coef[10]}
		peak2[]=Lor(LorParameters,x)
		
		LorParameters[0]={w_coef[0],w_coef[5]+w_coef[7],w_coef[9],w_coef[3],w_coef[10]}
		peak3[]=Lor(LorParameters,x)
		
		LorParameters[0]={w_coef[0],w_coef[5]+w_coef[6],w_coef[8],w_coef[4],w_coef[10]}
		peak4[]=Lor(LorParameters,x)
		
		Display MDC, MDCfit,peak1, peak2,peak3,peak4
		SetAxis bottom -0.7,0.7
		
		ModifyGraph rgb($MDCName)=(0,0,0),rgb($MDCfitname)=(1,16019,65535), lsize=2, rgb($peak2name)=(65535,43690,0), rgb($peak3name)=(32792,65535,1), rgb($peak4name)=(0,65535,65535)
	EndFor

End