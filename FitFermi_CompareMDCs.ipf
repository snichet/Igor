#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function angleint()
	
	//integrates 2d cut to give and EDC and fits Fermi distribution, then matches the Fermi levels and compares
	//the same MDCs of the different hv cuts.
	
	//fill in info here
	string basename = "css2_"
	variable start = 1480 //first file number
	variable stop = 1489	//last file number
	variable EnergyStart = 130.5 //hv for first file number
	variable EnergyStep = 0.5  //difference in hv between scans
	variable deltaE = -0.000 //energy of first mdc to be summed relative to fermi level
	variable numcuts = 5 //the number of mdcs to be summed
	variable EL = 4.7 //amount bottom of scanned range is below hv
	variable ET = 4.1 //amount top of scanned range is below hv
	variable wfg = 4.17 //work function guess
	variable g1 = 2.7e+9// Fermi functions is f(e) = (a+d*e)/(exp((e-b)/(c))+1)+g This is a
	variable g2 =.014 // this is c
	variable g3 =-2.14e+7//this is d
	variable g4 = 25000 // this is g
	variable fermifitstart = 75 //point to start Fermi Fit
	variable deltaEpixel = .005 //energy difference between pixels
	variable gammaang = 1.5125 //angle (in deg) in single scan of the gamma point
	
	string cutname
	string intname
	
	Variable a,b
	variable i
	variable j
	variable k
	variable x
	
	Make/D/N=5/O w_coef
	wave w_coef 
	W_coef[] = {g1, EnergyStart-wfg, g2, g3, g4}
	
	Make/D/N=5/O w_sigma
	wave w_sigma
	
	Make /N=(stop-start+1,7) /o fitparameters
	wave fitparameters
	
	Make /N=(stop-start+1,7) /o fitsigmas
	wave fitsigmas
	
	//display /n=MDCs40
	display /n=EDCs
	
	For(k=start;k<stop+1;k+=1)
	
		If(k<100)
			If(k<10)
				cutname = basename +""+ num2str(k)
			Else
				cutname = basename +""+ num2str(k)
			EndIf
		Else
			cutname = basename + num2str(k)
		EndIf
		
		wave cut = $cutname
		intname = cutname +"_int"
	
		Make /o /n=(dimsize(cut,0)) $intname
		
		wave onedwave = $intname
	
		For (i=0; i<dimsize(cut,0); i+=1)
			a=0
			For(j=0;j<dimsize(cut,1);j+=1)
				a=a+cut[i][j]
			EndFor
			onedwave[i]=a
		EndFor
		
		appendtograph /w = edcs onedwave
		
		
		setscale /i x, EnergyStart+EnergyStep*(k-start)-EL, EnergyStart+EnergyStep*(k-start)-ET, "eV", onedwave
		
		W_coef[] = {w_coef[0], EnergyStart+EnergyStep*(k-start)-wfg, w_coef[2], w_coef[3], w_coef[4]}
		
		FuncFit  /NTHR=0 FermiAndLinear W_coef onedwave[fermifitstart,dimsize(onedwave,0)-1] /D
		
		//setscale /p x, dimoffset(onedwave,0)-W_coef[1],dimdelta(onedwave,0),"",onedwave
		//SetAxis bottom -0.1,0.1
		
		fitparameters[k-start][0]=k
		fitparameters[k-start][1]= (EnergyStart+EnergyStep*(k-start))
		fitparameters[k-start][2]=w_coef[0]
		fitparameters[k-start][3]=w_coef[1]
		fitparameters[k-start][4]=w_coef[2]
		fitparameters[k-start][5]=w_coef[3]
		fitparameters[k-start][6]=w_coef[4]
		
		fitsigmas[k-start][0]=k
		fitsigmas[k-start][1]=(EnergyStart+EnergyStep*(k-start))
		fitsigmas[k-start][2]=w_sigma[0]
		fitsigmas[k-start][3]=w_sigma[1]
		fitsigmas[k-start][4]=w_sigma[2]
		fitsigmas[k-start][5]=w_sigma[3]
		fitsigmas[k-start][6]=w_sigma[4]
		
		string fitname = "fit_" + intname
		
		ModifyGraph /w = edcs rgb($fitname)=(0,0,0)
		
		string mdcname = cutname + "_mdc"+"0"
		Make /o /n=(dimsize(cut,1)) $mdcname
		wave mdc = $mdcname
		
		x = (deltaEpixel*Round((w_coef[1])/(deltaEpixel))+deltaE-(EnergyStart+EnergyStep*(k-start)- EL))*120/(-ET-(-EL))
		
		For (i=0;i<dimsize(cut,1);i+=1)
			a=0
			For(j=0;j<numcuts+1;j+=1)
				a=a+cut[x+j][i]
			EndFor
			mdc[i]=a
		EndFor
		
		b = sum(mdc)
		
		mdc *= 10000/b //normalize to correct for pixel effects
		
		setscale /i x, .5121*Sqrt(w_coef[1]+deltaE)*(-14.7125-gammaang)*(PI/180), .5121*Sqrt(w_coef[1]+deltaE)*(15.4275-gammaang)*(PI/180), "inverse angstroms", mdc
		
		appendtograph /w = mdcs0 mdc
		
		ModifyGraph /w = mdcs0 offset($mdcname)={0,(k-start+1)*(4)}
	Endfor
	//edit fitparameters
End