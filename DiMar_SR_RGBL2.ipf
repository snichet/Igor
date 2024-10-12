#pragma rtGlobals=1		// Use modern global access method.

// Dmitry Marchenko, HZB
// Procedures for work with spin resolved measurements from RGBL2 station
// Version 10-07-2019

Menu "DiMar_SR_RGBL2"
	"Control Panel", ControlRGBL2SR()
	//"---"
	"Load SR Files", LoadSRFiles()
	//"SR 0.16", SR(0,0,0.16)
	//"SR 0.112", SR(0,0,0.112)
	"Centroids", Centroids()
	//"---"
	//"Load SRDispersion Files", LoadSRDispersionFiles()
	//"Load Dispersion", LoadDispersion()
	//"Convert to k-space", ConvertToK()
	//"Wave to k-space NEW", NTMK7_waveToK(0,$"prompt for the wave name")
	//"MAP to k-space NEW", NTMK7_mapToK(0,0)
	//"---"
	//"Load HiRes data", LoadHiResData()
	//"Utils :: Duplicate axis help", DiMar_Utils_DuplicateAxis_Help()
	//"Utils :: 3D wave rotate", DiMar_Utils_3DwaveRotate()
	//"Utils :: Standard scale", DiMar_Utils_StandardScale()
	//"Utils :: 2xGauss fit", DiMar_Utils_Gauss2_Info()
	//"Utils :: 2xLorentz fit", DiMar_Utils_Lor2_Info()
	//"Utils :: Multidimentional pnt2x ", DiMar_Utils_pnt2x_Info()
	//"Utils :: Multidimentional x2pnt ", DiMar_Utils_x2pnt_Info()
End

//Window Control() : Panel
Function ControlRGBL2SR()


	DoWindow/K RGBL2_SR


	If (!exists("GSherman"))
		Variable/G GSherman=0.16
	EndIf
	If (!exists("GAsymm012"))
		Variable/G GAsymm012=0
	EndIf
	If (!exists("GAsymm034"))
		Variable/G GAsymm034=0
	EndIf	
	If (!exists("GNormalization"))
		Variable/G GNormalization=1
	EndIf	
	If (!exists("GRotation"))
		Variable/G GRotation=0
	EndIf	
	If (!exists("white"))
		Variable/G white=1
	EndIf	
	If (!exists("black"))
		Variable/G black=0
	EndIf	
	If (!exists("condenseValue"))
		Variable/G condenseValue=5
	EndIf	
	If (!exists("GAsymm012save"))
		Variable/G GAsymm012save=0
	EndIf
	If (!exists("GAsymm034save"))
		Variable/G GAsymm034save=0
	EndIf


	Variable/G GSherman//=0.16
	Variable/G GAsymm012//=0.0
	Variable/G GAsymm034//=0.0
	Variable/G GNormalization//=1
	Variable/G GRotation//=0
	String/G ListOfFiles//=""
	String/G IgorFolder=GetDataFolder(1)
	Variable/G black
	Variable/G white
	Variable/G condenseValue
	//print GetDataFolder(1)
	
	
	//testfunction()

	PauseUpdate; Silent 1
	NewPanel /M/W=(37.8,2,43.7,13.5) /N=RGBL2_SR
	ModifyPanel cbRGB=(65535,65535,65535), frameStyle=1, fixedSize=0
	
	Button ButtonLoad,pos={5,5},size={175,30},title="Update panel",proc=ButtonLoadProc
	SetVariable VariableGSherman, pos={5,40}, size={150,0}, value=GSherman, limits={-100,100,0.1}, proc=VariableUpdate
		SetVariable VariableGSherman_2, pos={155,40}, size={10,0}, value=GSherman, limits={-100,100,0.01}, title=" ", noedit=1, proc=VariableUpdate
		SetVariable VariableGSherman_3, pos={165,40}, size={10,0}, value=GSherman, limits={-100,100,0.001}, title=" ", noedit=1, proc=VariableUpdate
	SetVariable VariableGAsymm012, pos={5,65}, size={150,0}, value=GAsymm012, limits={-100,100,0.1}, proc=VariableUpdate
		SetVariable VariableGAsymm012_2, pos={155,65}, size={10,0}, value=GAsymm012, limits={-100,100,0.01}, title=" ", noedit=1, proc=VariableUpdate
		SetVariable VariableGAsymm012_3, pos={165,65}, size={10,0}, value=GAsymm012, limits={-100,100,0.001}, title=" ", noedit=1, proc=VariableUpdate
	SetVariable VariableGAsymm034, pos={5,90}, size={150,0}, value=GAsymm034, limits={-100,100,0.1}, proc=VariableUpdate
		SetVariable VariableGAsymm034_2, pos={155,90}, size={10,0}, value=GAsymm034, limits={-100,100,0.01}, title=" ", noedit=1, proc=VariableUpdate
		SetVariable VariableGAsymm034_3, pos={165,90}, size={10,0}, value=GAsymm034, limits={-100,100,0.001}, title=" ", noedit=1, proc=VariableUpdate
	SetVariable VariableGRotation, pos={5,115}, size={150,0}, value=GRotation, limits={-180,180,5}, proc=VariableUpdate
		SetVariable VariableGRotation_1, pos={155,115}, size={10,0}, value=GRotation, limits={-180,180,1}, title=" ", noedit=1,proc=VariableUpdate
	CheckBox CheckBoxNorm, pos={5,140}, size={10,0}, variable=GNormalization, title="Normalization", proc=CheckBoxNormProc
	
	TitleBox FilesToLoadTextBox1, pos={5,160}, size={150,0}, frame=0, title="List of files separated by ';' symbol"
	TitleBox FilesToLoadTextBox2, pos={5,175}, size={150,0}, frame=0, title="or empty to use data stored in Igor: "
	//String svariable=GetDataFolder(1)+"ListOfFiles"
	//print svariable
	SetVariable StringFilesToLoad, pos={5,190}, size={150,0}, value=ListOfFiles, title=" "
	
	
	CheckBox checkBox_White, pos={5,220}, title="WHITE", mode=1, variable=white, proc=checkBoxWhiteProc
	CheckBox checkBox_Black, pos={55,220}, title="BLACK", mode=1, variable=black, proc=checkBoxBlackProc
	
	SetVariable condenseValue, pos={5,250}, size={100,20}, title="Condense: ", limits={1,inf,1}, variable=condenseValue, proc=SetCondenseVarProc
	
	Button ButtonSRx,pos={5,280},size={175,30},title="Calculate",proc=ButtonUpdateProc
	Button ButtonAuto,pos={5,315},size={175,30},title="Auto",proc=ButtonAutoProc
	Button ButtonPlot12,pos={5,350},size={175,30},title="Display",proc=ButtonPlot12Proc
	//Button ButtonClose,pos={5,285},size={175,30},title="Close panel",proc=ButtonClose
	//Button ButtonPlot34,pos={95,250},size={85,30},title="Plot 34",proc=ButtonPlot34Proc
	
	TitleBox IgorFolderTextBox, pos={5,390}, size={150,0}, frame=0, variable=IgorFolder
	TitleBox ExpFolderTextBox, pos={5,405}, size={150,0}, frame=0, variable=ExpFolder
	//loadParameters()
End
//EndMacro

//Function testfunction()
//	print "testfunction: "+GetDataFolder(1)
//End

Function checkBoxWhiteProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR white=white
	NVAR black=black
	NVAR GAsymm012=GAsymm012
	NVAR GAsymm034=GAsymm034
	NVAR GAsymm012save=GAsymm012save
	NVAR GAsymm034save=GAsymm034save
	Variable as012tmp=GAsymm012
	Variable as034tmp=GAsymm034
	GAsymm012=GAsymm012save
	GAsymm034=GAsymm034save
	GAsymm012save=as012tmp
	GAsymm034save=as034tmp
	//Switch(white)
		//case 0:
			//black=1
			//white=0
			//break
		//case 1:
			black=0
			white=1
			//break
	//EndSwitch
	SRx()
End

Function checkBoxBlackProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR white=white
	NVAR black=black
	NVAR GAsymm012=GAsymm012
	NVAR GAsymm034=GAsymm034
	NVAR GAsymm012save=GAsymm012save
	NVAR GAsymm034save=GAsymm034save
	Variable as012tmp=GAsymm012
	Variable as034tmp=GAsymm034
	GAsymm012=GAsymm012save
	GAsymm034=GAsymm034save
	GAsymm012save=as012tmp
	GAsymm034save=as034tmp
	//Switch(black)
		//case 0:
			//black=0
			//white=1
			//break
		//case 1:
			black=1
			white=0
			//break
	//EndSwitch
	SRx()
End


//Function checkBoxBWProc(cb) : CheckBoxControl
//	STRUCT WMCheckboxAction& cb
//	
//	NVAR blackwhite= blackwhite
//	
//	strswitch (cb.ctrlName)
//		case "checkBox_White":
//			blackwhite= 1
//			break
//		case "checkBox_Black":
//			blackwhite= 2
//			break
//	endswitch
//	CheckBox checkBox_White,value= blackwhite==1
//	CheckBox checkBox_Black,value= blackwhite==2
//	return 0
//End



//Function createChannelsRGBL2()
//	Variable n
//	String str
//	
//	String thewavelist=WaveList("*_Dev3_ctr4_in",";","")
//	thewavelist=SortList(thewavelist)	
//	n=0
//	Do 
//		str=StringFromList(n,thewavelist)
//		
//		If (StringMatch(str,"")!=0)
//			break
//		EndIf
//		
//		If (n==0)
//			Duplicate/O $str,energy
//			Duplicate/O $str,ch1
//			Duplicate/O $str,ch2
//			Duplicate/O $str,ch3
//			Duplicate/O $str,ch4
//			energy[]=DimOffset(ch1,0)+DimDelta(ch1,0)*p
//			ch1=0
//			ch2=0
//			ch3=0
//			ch4=0
//		EndIf
//		
//		Wave ww=$str
//		ch1=ch1+ww
//
//		n+=1
//	While (1)
//	
//	thewavelist=WaveList("*_Dev3_ctr6_in",";","")
//	thewavelist=SortList(thewavelist)	
//	n=0
//	Do 
//		str=StringFromList(n,thewavelist)
//		If (StringMatch(str,"")!=0)
//			break
//		EndIf
//		Wave ww=$str
//		ch2=ch2+ww
//		n+=1
//	While (1)
//
//	thewavelist=WaveList("*_Dev3_ctr5_in",";","")
//	thewavelist=SortList(thewavelist)	
//	n=0
//	Do 
//		str=StringFromList(n,thewavelist)
//		If (StringMatch(str,"")!=0)
//			break
//		EndIf
//		Wave ww=$str
//		ch3=ch3+ww
//		n+=1
//	While (1)
//
//	thewavelist=WaveList("*_Dev3_ctr7_in",";","")
//	thewavelist=SortList(thewavelist)	
//	n=0
//	Do 
//		str=StringFromList(n,thewavelist)
//		If (StringMatch(str,"")!=0)
//			break
//		EndIf
//		Wave ww=$str
//		ch4=ch4+ww
//		n+=1
//	While (1)
//
//End










Function ButtonLoadProc(ctrlName) : ButtonControl
	String ctrlName
	//ControlUpdate VariableGSherman
	KillWindow RGBL2_SR
	ControlRGBL2SR()
End


//Function ButtonClose(ctrlName) : ButtonControl
//	String ctrlName
//	KillWindow RGBL2_SR
//End


//Function loadParameters()
//	NVAR GSherman=GSherman, GAsymm012=GAsymm012, GAsymm034=GAsymm034, GNormalization=GNormalization
//	NVAR GRotation=GRotation
//	SVAR ListOfFiles=ListOfFiles
//	Wave parameters
//	
//	GSherman=parameters[0]
//	GAsymm012=parameters[1]
//	GAsymm034=parameters[2]
//	GNormalization=parameters[3]
//	GRotation=parameters[4]
//End

Function ButtonAutoProc(ctrlName) : ButtonControl
	String ctrlName
	autoasymmetry()
End


Function autoasymmetry()
	SRx()
	Wave asymm12,asymm34
	NVAR GAsymm012,GAsymm034
	Variable index,ave12,ave34,nn
	ave12=0
	ave34=0
	nn=0
	For (index=0;index<numpnts(asymm12);index+=1)
		If (abs(asymm12[index])<0.3 && abs(asymm34[index])<0.3)
			nn+=1
			ave12=ave12+asymm12[index]
			ave34=ave34+asymm34[index]		
		EndIf
	EndFor
	ave12=ave12/nn
	ave34=ave34/nn
	GAsymm012=ave12
	GAsymm034=ave34
	SRx()
End

Function ButtonUpdateProc(ctrlName) : ButtonControl
	String ctrlName
	SRx()
End

Function VariableUpdate(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	SRx()
End

Function CheckBoxNormProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	SRx()
End

Function ButtonPlot12Proc(ctrlName) : ButtonControl
	String ctrlName
	Display /W=(240,50,640,260) up12, down12 vs energy as "In-plane"
	ModifyGraph rgb(down12)=(0,15872,65280)
	ModifyGraph mode(up12)=4, marker(up12)=17, msize(up12)=1
	ModifyGraph mode(down12)=4, marker(down12)=23, msize(down12)=1
	//display asymm12 vs energy as "Asymm12"
	//SetAxis/A bottom
	//SetAxis left -0.03, 0.03
	//ModifyGraph rgb=(0,52224,0)
	Display /W=(240,290,640,500) pol12 vs energy as "In-plane"
	SetAxis left -0.5,0.5
	ModifyGraph rgb=(0,0,0)
	ModifyGraph manTick(left)={0,0.2,0,1},manMinor(left)={0,50}
	ModifyGraph grid(left)=2,gridRGB(left)=(34816,34816,34816)

	Display /W=(650,50,1050,260) up34, down34 vs energy as "Out-of-plane"
	ModifyGraph rgb(down34)=(0,15872,65280)
	ModifyGraph mode(up34)=4, marker(up34)=17, msize(up34)=1
	ModifyGraph mode(down34)=4, marker(down34)=23, msize(down34)=1
	//display asymm34 vs energy as "Asymm34"
	//SetAxis/A bottom
	//SetAxis left -0.03, 0.03
	//ModifyGraph rgb=(0,52224,0)
	Display /W=(650,290,1050,500) pol34 vs energy as "Out-of-plane"
	SetAxis left -0.5,0.5
	ModifyGraph rgb=(0,0,0)
	ModifyGraph manTick(left)={0,0.2,0,1},manMinor(left)={0,50}
	ModifyGraph grid(left)=2,gridRGB(left)=(34816,34816,34816)


	Display /W=(240,530,640,740) up12_cond, down12_cond vs energy_cond as "In-plane condensed"
	ModifyGraph rgb(down12_cond)=(0,15872,65280)
	ModifyGraph mode(up12_cond)=4, marker(up12_cond)=17, msize(up12_cond)=1
	ModifyGraph mode(down12_cond)=4, marker(down12_cond)=23, msize(down12_cond)=1

	Display /W=(650,530,1050,740) up34_cond, down34_cond vs energy_cond as "Out-of-plane condensed"
	ModifyGraph rgb(down34_cond)=(0,15872,65280)
	ModifyGraph mode(up34_cond)=4, marker(up34_cond)=17, msize(up34_cond)=1
	ModifyGraph mode(down34_cond)=4, marker(down34_cond)=23, msize(down34_cond)=1
End

//-----------------------------------------------------------------------------------------------------



Function SRx()
	SVAR IgorFolder=IgorFolder
	//print ">"+IgorFolder
	//print "> current: "+GetDataFolder(1)
	If (StringMatch(IgorFolder,GetDataFolder(1))==1)
		SVAR ListOfFiles=ListOfFiles
		If (StringMatch(ListOfFiles,"")==0)
			Load_SR_files_RGBL2(ListOfFiles)
		EndIf
		NVAR GSherman=GSherman, GAsymm012=GAsymm012, GAsymm034=GAsymm034
		SR(GAsymm012,GAsymm034,GSherman)
		//
		NVAR condenseValue=condenseValue
		If (exists("condenseValue") && condenseValue>0)
			condense_UTRRX(condenseValue)
		Else
			condense_UTRRX(1)
		EndIf	
	Else
		print "Need ["+IgorFolder+"] folder, have ["+GetDataFolder(1)+"] folder active!"
	EndIf
End


Function SR(asymm012, asymm034, sherman)
	Variable asymm012, asymm034, sherman
	
	Wave energy, ch1, ch2, ch3, ch4
	Wave pol12,pol34
	Variable nRows, ave1, ave2, ave3, ave4
	Variable i
	
	NVAR GSherman=GSherman, GAsymm012=GAsymm012, GAsymm034=GAsymm034, GNormalization=GNormalization
	GSherman=sherman
	GAsymm012=asymm012
	GAsymm034=asymm034
	
	NVAR GRotation=GRotation
	Variable rotationAngleRad=GRotation/180*pi
	
	Make/O/N=10 parameters
	parameters[0]=sherman
	parameters[1]=asymm012
	parameters[2]=asymm034
	parameters[3]=GNormalization
	parameters[4]=GRotation

	
	
	If (WaveExists('energy') && WaveExists('ch1') && WaveExists('ch2') && WaveExists('ch3') && WaveExists('ch4'))
		//WaveStats energy
		//nRows=V_npnts
		nRows=numpnts(energy)
		

		duplicate/O ch1, ch1norm
		duplicate/O ch2, ch2norm
		duplicate/O ch3, ch3norm
		duplicate/O ch4, ch4norm
		
		ave1=0
		ave2=0
		ave3=0
		ave4=0
		For (i=nRows-10;i<=nRows-1;i+=1) 
			ave1+=(ch1norm[i]/10)
			ave2+=(ch2norm[i]/10)
			ave3+=(ch3norm[i]/10)
			ave4+=(ch4norm[i]/10)
		EndFor
		If (GNormalization==1)
			ch1norm-=ave1
			ch2norm-=ave2
			ch3norm-=ave3
			ch4norm-=ave4
		EndIf
		
		
		ave1=0
		ave2=0
		ave3=0
		ave4=0
		For (i=0;i<=9;i+=1) 
			ave1+=(ch1norm[i]/10)
			ave2+=(ch2norm[i]/10)
			ave3+=(ch3norm[i]/10)
			ave4+=(ch4norm[i]/10)
		EndFor
		If (GNormalization==1)
			ch1norm/=ave1
			ch2norm/=ave2
			ch3norm/=ave3
			ch4norm/=ave4
		EndIf

		duplicate/O energy, asymm12
		duplicate/O energy, c912
		duplicate/O energy, up12
		duplicate/O energy, down12
		duplicate/O energy, asymm34
		duplicate/O energy, c934
		duplicate/O energy, up34
		duplicate/O energy, down34
		
		duplicate/O asymm12, asymm12tmp
		duplicate/O asymm34, asymm34tmp
		duplicate/O asymm12, pol12
		duplicate/O asymm34, pol34
		
		duplicate/O up12,total
		
		asymm12tmp=(ch1norm-ch2norm)/(ch1norm+ch2norm)
		asymm34tmp=(ch4norm-ch3norm)/(ch4norm+ch3norm)
		asymm12=asymm12tmp*cos(rotationAngleRad)-asymm34tmp*sin(rotationAngleRad)
		asymm34=asymm12tmp*sin(rotationAngleRad)+asymm34tmp*cos(rotationAngleRad)

		c912=(asymm12-asymm012)/sherman
		up12=0.5*(ch1norm+ch2norm)*(1+c912)
		down12=0.5*(ch1norm+ch2norm)*(1-c912)
		c934=(asymm34-asymm034)/sherman
		up34=0.5*(ch3norm+ch4norm)*(1+c934)
		down34=0.5*(ch3norm+ch4norm)*(1-c934)
		
		total=up12+down12+up34+down34
		
///////
//		asymm12tmp=(ch1norm-ch2norm)/(ch1norm+ch2norm)-asymm012 //
//		asymm34tmp=(ch4norm-ch3norm)/(ch4norm+ch3norm)-asymm034 //
//		asymm12=asymm12tmp*cos(rotationAngleRad)-asymm34tmp*sin(rotationAngleRad)
//		asymm34=asymm12tmp*sin(rotationAngleRad)+asymm34tmp*cos(rotationAngleRad)
//
//		c912=(asymm12)/sherman // 
//		up12=0.5*(ch1norm+ch2norm)*(1+c912)
//		down12=0.5*(ch1norm+ch2norm)*(1-c912)
//		c934=(asymm34)/sherman //
//		up34=0.5*(ch3norm+ch4norm)*(1+c934)
//		down34=0.5*(ch3norm+ch4norm)*(1-c934)
///////
		
		pol12=(up12-down12)/(up12+down12)
		pol34=(up34-down34)/(up34+down34)
		
		//KillWindow WinChannels12
		//KillWindow WinChannels34 
		//KillWindow WinAsymm12 
		//KillWindow WinAsymm34
		
		//display/N=WinChannels12 up12, down12 vs energy as "Channels12"
		//ModifyGraph rgb(up12)=(0,15872,65280)
		//ModifyGraph mode(up12)=4, marker(up12)=17, msize(up12)=1
		//ModifyGraph mode(down12)=4, marker(down12)=23, msize(down12)=1
		//display/N=WinChannels34 up34, down34 vs energy as "Channels34"
		//ModifyGraph rgb(up34)=(0,15872,65280)
		//ModifyGraph mode(up34)=4, marker(up34)=17, msize(up34)=1
		//ModifyGraph mode(down34)=4, marker(down34)=23, msize(down34)=1
		
		//display/N=WinAsymm12 asymm12 vs energy as "Asymm12"
		//SetAxis/A bottom
		//SetAxis left -0.03, 0.03
		//ModifyGraph rgb=(0,52224,0)
		//display/N=WinAsymm34 asymm34 vs energy as "Asymm34"
		//SetAxis/A bottom
		//SetAxis left -0.03, 0.03
		//ModifyGraph rgb=(0,52224,0)
	Else
		print "Error: Check that waves 'energy', 'ch1', 'ch2', 'ch3', 'ch4' exist!"
	EndIf

End

Window Data() : Table
	PauseUpdate; Silent 1		// building window...
	Edit/W=(286.5,53.75,791.25,266) energy,ch1,ch2,ch3,ch4
	ModifyTable format(Point)=1
EndMacro

Function PrintVoidLines()
	Variable i
	For (i=0;i<10;i+=1)
		print " "
	EndFor
End




//// _____________ Centroids ________________

Function Centroids()
	Variable left, right, i, p1, p2, nRows
	Wave energy, up12, up34, down12, down34
	Variable centroidUp12, centroidUp34, centroidDown12, centroidDown34, delta12, delta34
	Variable sumint, suminten

	//WaveStats energy
	//nRows=V_npnts
	nRows=numpnts(energy)

	GetMarquee left, bottom
	if (V_flag == 0)
		Print "There is no selection"
	else
		left=V_left
		right=V_right
		print "left="+num2str(left)+" right="+num2str(right)
		For (i=0;i<nRows;i+=1)
			If (energy[i]>left)
				p1=i
				break
			EndIf
		EndFor
		For (i=nRows-1;i>=0;i-=1)
			If (energy[i]<right)
				p2=i
				break
			EndIf
		EndFor
		print "Selected region is ",p1,"-",p2
		
		
		//
		KillWaves/Z cent_bgline
		Duplicate energy, cent_bgline
		cent_bgline=0
		Variable a, b
		a=(up12[p1]-up12[p2])/(energy[p1]-energy[p2])
		b=up12[p1]-a*energy[p1]
		cent_bgline=a*energy[x]+b
		//
		
		sumint=0; suminten=0;
		For (i=p1;i<=p2;i+=1)
			sumint=sumint+(up12[i]-cent_bgline[i])
			suminten=suminten+(up12[i]-cent_bgline[i])*energy[i]
		EndFor
		centroidUp12=suminten/sumint
		sumint=0; suminten=0;
		For (i=p1;i<=p2;i+=1)
			sumint=sumint+(up34[i]-cent_bgline[i])
			suminten=suminten+(up34[i]-cent_bgline[i])*energy[i]
		EndFor
		centroidUp34=suminten/sumint
		sumint=0; suminten=0;
		For (i=p1;i<=p2;i+=1)
			sumint=sumint+(down12[i]-cent_bgline[i])
			suminten=suminten+(down12[i]-cent_bgline[i])*energy[i]
		EndFor
		centroidDown12=suminten/sumint
		sumint=0; suminten=0;
		For (i=p1;i<=p2;i+=1)
			sumint=sumint+(down34[i]-cent_bgline[i])
			suminten=suminten+(down34[i]-cent_bgline[i])*energy[i]
		EndFor
		centroidDown34=suminten/sumint
		
		delta12=centroidUp12-centroidDown12
		delta34=centroidUp34-centroidDown34
		
		print "Centroid of Up12=", centroidUp12
		print "Centroid of Down12=", centroidDown12
		print "Centroid of Up34=", centroidUp34
		print "Centroid of Down34=", centroidDown34
		print "SO_12=", (delta12*1000), "meV"
		print "SO_34=", (delta34*1000), "meV"
	endif
End




///// **************************
/////

/////


Function/S Load_SR_files_RGBL2(selectionlist)
	String selectionlist
	
	NVAR white=white
	
	If(!exists("ExpFolder"))
		//Ask the user to identify a folder on the computer
		getfilefolderinfo/D
 		String/G ExpFolder=S_path
		//Store the folder that the user has selected as a new symbolic path in IGOR called cgms
		newpath/O/Q cgms S_path
	Else
		String/G ExpFolder 
		newpath/O/Q cgms ExpFolder
	EndIf
	//Create a list of all files that are .ibw files in the folder. -1 parameter addresses all files.
	
	String filelist= indexedfile(cgms,-1,".ibw") // *_Dev3_ctr*_in.ibw
	//print filelist
	
	//variable k=ItemsInList(filelist)-1
	
	Variable thefirst=1
	
	String str
	Variable n=0
	do 
		str=StringFromList(n,filelist)
		
		If (StringMatch(str,"")!=0)
			break
		EndIf
		
		Variable nn=0
		String selectionstr
		do
			selectionstr=StringFromList(nn,selectionlist)
			If (StringMatch(selectionstr,"")!=0)
				break
			EndIf
			
			String loadedwavestr
			String matchstr="*_Dev3_ctr4_in.ibw"
			If (white)
				matchstr="*_Dev3_ctr1_in.ibw"
			EndIf
			If (StringMatch(str,"*"+selectionstr+matchstr)!=0)
				LoadWave/H/O/P=cgms str
				loadedwavestr=StringFromList(0,S_waveNames)
				Wave ww=$loadedwavestr
				addDimension_UTRRX(ww) 
				Duplicate/O ww,tmploadsrchannel
				KillWaves/Z ww
				
				If (thefirst==1 && !white)
					Duplicate/O tmploadsrchannel,energy
					Duplicate/O tmploadsrchannel,ch1
					Duplicate/O tmploadsrchannel,ch2
					Duplicate/O tmploadsrchannel,ch3
					Duplicate/O tmploadsrchannel,ch4
					Redimension/N=-1 energy
					energy[]=DimOffset(ch1,0)+DimDelta(ch1,0)*p
					ch1=0
					ch2=0
					ch3=0
					ch4=0
					thefirst=0
				EndIf
				
				ch1=ch1+tmploadsrchannel
				KillWaves/Z tmploadsrchannel
			EndIf
			matchstr="*_Dev3_ctr5_in.ibw"
			If (white)
				matchstr="*_Dev3_ctr2_in.ibw"
			EndIf			
			If (StringMatch(str,"*"+selectionstr+matchstr)!=0)
				LoadWave/H/O/P=cgms str
				loadedwavestr=StringFromList(0,S_waveNames)
				Wave ww=$loadedwavestr
				addDimension_UTRRX(ww) 
				Duplicate/O ww,tmploadsrchannel
				KillWaves/Z ww	
				ch3=ch3+tmploadsrchannel
				KillWaves/Z tmploadsrchannel
			EndIf
			matchstr="*_Dev3_ctr6_in.ibw"
			If (white)
				matchstr="*_Dev3_ctr3_in.ibw"
			EndIf			
			If (StringMatch(str,"*"+selectionstr+matchstr)!=0)
				LoadWave/H/O/P=cgms str
				loadedwavestr=StringFromList(0,S_waveNames)
				Wave ww=$loadedwavestr
				addDimension_UTRRX(ww) 
				Duplicate/O ww,tmploadsrchannel
				KillWaves/Z ww	
				ch2=ch2+tmploadsrchannel
				KillWaves/Z tmploadsrchannel
			EndIf
			matchstr="*_Dev3_ctr7_in.ibw"
			If (white)
				matchstr="*_Dev3_ctr0_in.ibw"
			EndIf			
			If (StringMatch(str,"*"+selectionstr+matchstr)!=0)
				LoadWave/H/O/P=cgms str
				loadedwavestr=StringFromList(0,S_waveNames)
				Wave ww=$loadedwavestr
				addDimension_UTRRX(ww) 
				Duplicate/O ww,tmploadsrchannel
				KillWaves/Z ww	
				
				If (thefirst==1 && white)
					Duplicate/O tmploadsrchannel,energy
					Duplicate/O tmploadsrchannel,ch1
					Duplicate/O tmploadsrchannel,ch2
					Duplicate/O tmploadsrchannel,ch3
					Duplicate/O tmploadsrchannel,ch4
					energy[]=DimOffset(ch1,0)+DimDelta(ch1,0)*p
					ch1=0
					ch2=0
					ch3=0
					ch4=0
					thefirst=0
				EndIf
								
				//print "tmp0",tmploadsrchannel[0]
				ch4=ch4+tmploadsrchannel
				//print "ch40",ch4[0]
				KillWaves/Z tmploadsrchannel
			EndIf
			
			nn+=1
		while (1)
		//print ">ch40",ch4[0]

		//String fname = stringfromlist(n,filelist)
		//print fname
		
		n+=1
	while (1)
	//print ">>ch40",ch4[0]
	
	//LoadWave/H/P=cgms fname
	return "" //fname //stringfromlist(0,S_waveNames)
	
End

Function ScanForFiles(folderName,index)
	String folderName
	Variable index
	NewPath/O/Q folderPath, folderName
	
	Variable i, filesNum
	String listAllFiles

	listAllFiles=IndexedFile(folderPath,-1,"????")
	filesNum=ItemsInList(listAllFiles)
	For (i=0;i<filesNum;i+=1)
		String fileName, strToPrint=""
		Variable j
		fileName = StringFromList(i, listAllFiles, ";")
		For (j=0;j<index;j+=1)
			strToPrint+="\t"
		EndFor
		strToPrint+=fileName
		print strToPrint	
		String newWaveName=fileName+"_"
		Make/D/O/N=1 $newWaveName
	EndFor
	
	KillPath folderPath
End
/////
Function ScanForFolders(folderName, index)
	String folderName
	Variable index
	
	NewPath/O/Q folderPath, folderName

	String savedDF=GetDataFolder(1)
	String folderShortName=ParseFilePath(0, folderName, ":", 1, 0)
	NewDataFolder/S $folderShortName
	//SetDataFolder $folderShortName
	//print ">>>>>", folderShortName,"<<<<<"
	
	Variable i, foldersNum
	String listAllFolders
	
	index+=1

	listAllFolders=IndexedDir(folderPath,-1,0)
	foldersNum=ItemsInList(listAllFolders)
	For (i=0;i<foldersNum;i+=1)
		String dirName, strToPrint=""
		Variable j
		dirName = StringFromList(i, listAllFolders, ";")
		For (j=0;j<index;j+=1)
			strToPrint+="\t"
		EndFor
		strToPrint+=dirName
		print strToPrint
		
		ScanForFolders(folderName+dirName,index)
	EndFor

	ScanForFiles(folderName,index)

	//KillPath folderPath	
	SetDataFolder savedDF
End
/////
///// **************************

///// *********/////*********///////
Function CreateDataTable(nFiles)
	Variable nFiles
	
	Wave energy, ch1, ch2, ch3, ch4
	//KillWaves/Z energy, ch1, ch2, ch3, ch4
	
	Wave wave0, wave1, wave2, wave3, wave4
	duplicate/O wave0, energy
	duplicate/O wave1, ch1
	duplicate/O wave2, ch2
	duplicate/O wave3, ch3
	duplicate/O wave4, ch4

	Variable i
	String wStr0="wave"
	String wStr=""
	For (i=2;i<=nFiles;i+=1)
		wStr=wStr0+num2str((i-1)*5+1)
		Wave w=$wStr
		ch1=ch1+w
		wStr=wStr0+num2str((i-1)*5+2)
		Wave w=$wStr
		ch2=ch2+w
		wStr=wStr0+num2str((i-1)*5+3)
		Wave w=$wStr
		ch3=ch3+w
		wStr=wStr0+num2str((i-1)*5+4)
		Wave w=$wStr
		ch4=ch4+w
	EndFor
End




//-------------------------------------- Splitting calculation


Function line(a,b,c,d,x)
	Variable a,b,c,d,x
	return (d-b)/(c-a)*(x-a)+b
End

Function reversecolumn()
	Wave sp2
	Variable i, tmp
	Variable numlines=6
	
	For (i=0;i<numlines/2;i+=1)
		tmp=sp2[i]
		sp2[i]=sp2[numlines-i-1]
		sp2[numlines-i-1]=tmp
	EndFor
End

Function splitting() 
// need waves sp1en, sp1,sp2en, sp2, so 
// in sp1 and sp2 intensity goes from small to large, else use reversecolumn()
// parameters are numlines, start, finish, numsteps
	Variable i, j
	Wave sp1en, sp1, sp2en, sp2, so
	
	Variable numlines=16
	Variable start=5.2
	Variable finish=9.2
	Variable numsteps=100
	Variable step=(finish-start)/numsteps
	
	Variable a1,b1,c1,d1,a2,b2,c2,d2,pos
	
	For (i=0;i<numsteps;i+=1)
		pos=start+i*step
		
		a1=0
		b1=0
		c1=0
		d1=0
		a2=0
		b2=0
		c2=0
		d2=0
		For (j=0;j<numlines;j+=1)
			If (pos>sp1[j] && pos<sp1[j+1])				
				a1=sp1en[j]
				b1=sp1[j]
				c1=sp1en[j+1]
				d1=sp1[j+1]
			EndIf
		EndFor
		For (j=0;j<numlines;j+=1)
			If (pos>sp2[j] && pos<sp2[j+1])				
				a2=sp2en[j]
				b2=sp2[j]
				c2=sp2en[j+1]
				d2=sp2[j+1]
			EndIf
		EndFor
		so[i]=(line(b1,a1,d1,c1,pos)-line(b2,a2,d2,c2,pos))*1000
	EndFor
End



Function showpolarizationvector(point,range,polar,azimuth)
	Variable point,range,polar,azimuth
	Wave up12,down12,up34,down34
	Variable i
	Variable aveup12,avedown12,aveup34,avedown34,npnts
	Variable avepol12,avepol34,totalpol
	
	aveup12=0
	avedown12=0
	aveup34=0
	avedown34=0
	npnts=0
	For (i=point-range;i<=point+range;i+=1)
		npnts+=1
		aveup12+=up12[i]
		avedown12+=down12[i]
		aveup34+=up34[i]
		avedown34+=down34[i]
	EndFor
	aveup12/=npnts
	avedown12/=npnts
	aveup34/=npnts
	avedown34/=npnts
	
	avepol12=round((aveup12-avedown12)/(aveup12+avedown12)*100)
	avepol34=round((aveup34-avedown34)/(aveup34+avedown34)*100)
	totalpol=round(sqrt(avepol12^2+avepol34^2))
	print "Polarization Horizontal=",avepol12,"%     Vertical=",avepol34,"%     Total=",totalpol,"%"
	
	Make/O/N=(2,2)/D polarizationvector
	polarizationvector[0][0]=0
	polarizationvector[0][1]=0
	polarizationvector[1][0]=avepol12
	polarizationvector[1][1]=avepol34
	
	//Make/O/N=(2,2)/D void
	//void[0][0]=-0.5
	//void[0][1]=-0.5
	//void[1][0]=0.5
	//void[1][1]=0.5
//	display polarizationvector as "PolarizationVector"
//	ModifyGraph width=113.386,height=113.386
//	ModifyGraph mode=2
//	ModifyGraph rgb=(65535,65535,65535)
//	ModifyGraph manTick(left)={0,10,0,0},manMinor(left)={0,50}
//	ModifyGraph manTick(bottom)={0,10,0,0},manMinor(bottom)={0,50}
//	ModifyGraph grid(left)=2
//	ModifyGraph grid(bottom)=2
//	SetAxis left -50,50
//	SetAxis bottom -50,50
//	SetDrawLayer UserAxes
//	SetDrawEnv xcoord= bottom,ycoord= left
//	SetDrawEnv linethick= 1.00
//	SetDrawEnv arrow= 0
//	DrawLine -50,0,50,0
//	SetDrawLayer UserAxes
//	SetDrawEnv xcoord= bottom,ycoord= left
//	SetDrawEnv linethick= 1.00
//	SetDrawEnv arrow= 0
//	DrawLine 0,-50,0,50
//	SetDrawLayer UserAxes
//	SetDrawEnv xcoord= bottom,ycoord= left
//	SetDrawEnv linethick= 2.00
//	SetDrawEnv arrow= 1
//	DrawLine 0,0,avepol12,avepol34
	
	drawposition(polar,azimuth,avepol12,avepol34)
End


Function drawposition(polar,azimuth,pol1,pol2)
	Variable polar,azimuth,pol1,pol2
	Variable magnification=5
	Variable polarcenter=255

	display polarizationvector as "Position"
	ModifyGraph width=113.386,height=113.386
	ModifyGraph mode=2
	ModifyGraph rgb=(65535,65535,65535)
	ModifyGraph manTick(left)={0,1,0,0},manMinor(left)={0,1}
	ModifyGraph manTick(bottom)={0,1,0,0},manMinor(bottom)={0,1}
	ModifyGraph grid(left)=2
	ModifyGraph grid(bottom)=2
	SetAxis left 87,93
	SetAxis bottom (polarcenter-3),(polarcenter+3)
	SetDrawLayer UserAxes
	SetDrawEnv xcoord= bottom,ycoord= left
	SetDrawEnv fillpat=0
	SetDrawEnv linethick= 1.00
	SetDrawEnv arrow= 0
	DrawOval (polarcenter-2),87.75,(polarcenter+2),91.75
	SetDrawLayer UserAxes
	SetDrawEnv xcoord= bottom,ycoord= left
	SetDrawEnv fillfgc=(0,0,0)
	SetDrawEnv fillpat=3
	SetDrawEnv linethick= 2.00
	SetDrawEnv arrow= 0
	DrawOval (polar+0.2),(azimuth-0.2),(polar-0.2),(azimuth+0.2)
	
	SetDrawLayer UserAxes
	SetDrawEnv xcoord= bottom,ycoord= left
	SetDrawEnv linethick= 2.00
	SetDrawEnv arrow= 1
	DrawLine polar,azimuth,(polar-pol1/15*magnification),(azimuth+pol2/15*magnification)
End













Function toKSpace(KE,ang)
	Variable KE,ang
	return 0.512*sqrt(KE)*sin(ang/180*pi)
End




Function DiMar_SR_ShiftChannel(wynew,wyold,wx,shift) // shift in energy (wx) scale
	Wave wynew,wyold,wx
	Variable shift
	If (numpnts(wynew)!=numpnts(wx) || numpnts(wynew)!=numpnts(wyold))
		print "ERROR #fskjg67 numpnts(wynew)!=numpnts(wx) || numpnts(wynew)!=numpnts(wyold)"
	Else
		Variable numpoints=numpnts(wynew)
		Variable wxstep=wx[1]-wx[0]
		Variable shiftrel=shift/wxstep
		Variable ii
		//wynew[0]=wyold[0]
		For (ii=0;ii<numpoints-1;ii+=1)
			wynew[ii]=DiMar_SR_getLineAtX(wx[ii]-shift,wx[ii],wyold[ii],wx[ii+1],wyold[ii+1]) // wx[ii]+shift
		EndFor
		wynew[numpoints-1]=wyold[numpoints-1]
	EndIf
	SRx()
End

Function DiMar_SR_getLineAtX(x,x1,y1,x2,y2)
	Variable x,x1,y1,x2,y2
	Variable aa=(y2-y1)/(x2-x1)
	Variable bb=y2-aa*x2
	return aa*x+bb
End




Function DiMar_SR_Norm()
	Wave w=CsrWaveRef(A)
	Variable vA=vcsr(A)
	Variable vB=vcsr(B)
	w=w-vA
	w=w/(vB-vA)
End






/////////// NEW wave to K /// START




Function DiMar_Utils_StandardScale()
	//ModifyGraph swapXY=1
	//SetAxis/R bottom 1,-4
	//SetAxis right 34,36
	ModifyGraph width=226.772,height=226.772
End


Function DiMar_Utils_Line(x1,y1,x2,y2,x0)
	Variable x1,y1,x2,y2,x0
	
	Variable aa=(y2-y1)/(x2-x1)
	Variable bb=y2-aa*x2
	
	Variable result=aa*x0+bb
	
	return result
End






Function DiMar_Utils_pnt2x_Info()
	print "DiMar_Utils_pnt2x(ww,pnt,dim)"
End

Function DiMar_Utils_pnt2x(ww,pnt,dim)
	Wave ww
	Variable pnt,dim
	// pnt2x(waveName, pointNum )
	// DimOffset(waveName, dim) + ScaledDimPos *DimDelta(waveName,dim)
	return DimOffset(ww,dim) + pnt *DimDelta(ww,dim)
End

Function DiMar_Utils_x2pnt_Info()
	print "DiMar_Utils_x2pnt(ww,xx,dim)"
End

Function DiMar_Utils_x2pnt(ww,xx,dim)
	Wave ww
	Variable xx,dim
	// x2pnt(waveName, x1 )
	// (ScaledDimPos - DimOffset(waveName, dim))/DimDelta(waveName,dim)
	return (xx - DimOffset(ww, dim))/DimDelta(ww,dim)
End



Function condense_UTRRX(nn) // ww - wave to condense, nn - number of merging points
	Variable nn
	Wave up12,down12,up34,down34,energy
	Variable wsize=numpnts(up12)
	Variable newsize=floor(wsize/nn)+1
	Variable ii,jj

	Make/O/N=(newsize) up12_cond
	up12_cond=0
	For (ii=0;ii<wsize;ii+=1)
		up12_cond[floor(ii/nn)]=up12_cond[floor(ii/nn)]+up12[ii]
	EndFor

	Make/O/N=(newsize) down12_cond
	down12_cond=0
	For (ii=0;ii<wsize;ii+=1)
		down12_cond[floor(ii/nn)]=down12_cond[floor(ii/nn)]+down12[ii]
	EndFor

	Make/O/N=(newsize) up34_cond
	up34_cond=0
	For (ii=0;ii<wsize;ii+=1)
		up34_cond[floor(ii/nn)]=up34_cond[floor(ii/nn)]+up34[ii]
	EndFor

	Make/O/N=(newsize) down34_cond
	down34_cond=0
	For (ii=0;ii<wsize;ii+=1)
		down34_cond[floor(ii/nn)]=down34_cond[floor(ii/nn)]+down34[ii]
	EndFor

	Make/O/N=(newsize) energy_cond
	energy_cond=0
	For (ii=0;ii<newsize;ii+=1)
		Variable en_ave=0
		For (jj=0;jj<nn;jj+=1)
			en_ave=en_ave+energy[ii*nn+jj]
			//print ii*nn+jj
		EndFor
		en_ave=en_ave/nn
		//print "	en_ave=",en_ave
		energy_cond[ii]=en_ave
	EndFor
	
	Make/O/N=(newsize) pol12_cond,pol34_cond
	pol12_cond=(up12_cond-down12_cond)/(up12_cond+down12_cond)
	pol34_cond=(up34_cond-down34_cond)/(up34_cond+down34_cond)

End

Function SetCondenseVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	Variable/G condenseValue=varNum
	condense_UTRRX(condenseValue)
End


/// Join data in the AddDimension-type spectrum
Function join_AddDimension_UTRRX(num) 
	// num=numbers of sequences to join, from zero to <<num>>
	// for example, 30 good sequences of 32 measured (channels waves have 31 columns) =>  num=30
	Variable num
	Variable ii
	Wave ch1,ch2,ch3,ch4
	
	Duplicate/O ch1,ch1save
	Redimension/N=-1 ch1
	ch1=0
	For (ii=0;ii<num;ii+=1)
		ch1[]=ch1[p]+ch1save[p][ii]
	EndFor
	
	Duplicate/O ch2,ch2save
	Redimension/N=-1 ch2
	ch2=0
	For (ii=0;ii<num;ii+=1)
		ch2[]=ch2[p]+ch2save[p][ii]
	EndFor

	Duplicate/O ch3,ch3save
	Redimension/N=-1 ch3
	ch3=0
	For (ii=0;ii<num;ii+=1)
		ch3[]=ch3[p]+ch3save[p][ii]
	EndFor

	Duplicate/O ch4,ch4save
	Redimension/N=-1 ch4
	ch4=0
	For (ii=0;ii<num;ii+=1)
		ch4[]=ch4[p]+ch4save[p][ii]
	EndFor
End

Function addDimension_UTRRX(ww) 
	// num=numbers of sequences to join, from zero to <<num>>
	// for example, 30 good sequences of 32 measured (channels waves have 31 columns) =>  num=30
	Wave ww

	Variable ii
	For (ii=1;ii<DimSize(ww,1);ii+=1)
		ww[][0]=ww[p][0]+ww[p][ii]
	EndFor

	Redimension/N=-1 ww
End


