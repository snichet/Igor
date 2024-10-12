// Procedure to visualize and analyse an image
// Created by Jonathan Denlinger at Lawrence Berkeley National Laboratory
// Modified and simplified by Veronique Brouet, March 2008
// Everything concerning stacks transferred in procedure "Stacks"


#pragma rtGlobals=1		// Use modern global access method.
#include <Cross Hair Cursors>

///////////////////////////////////////////////////////////////////////////////////////////
////////////////////////            ImageTool window
//Proc	 	InitImageTool()
//Macro 		ShowImageTool( )
//Window 	ImageTool()			 	: Graph

//Proc 		NewImg(ctrlName) 			: ButtonControl
//Proc 		PickImage( wn )
//Proc 		DoLoad(curr)

//Fct/T 		ImgInfo( image )
//Proc 		SetProfiles()
//Proc 		StepHair ()				:ButtonControl  					//  From which Button ??
//Fct 		SetHairXY(ctrlName,varNum,varStr,varName) 	: SetVariableControl

//Fct 		UpdateXYGlobals(tinfo)
//			ImageHookfcn

//Proc 		ExportAction(ctrlName) 				: ButtonControl
//Proc 		ExportImage( exportn, eopt, dopt )
// Fct		ScaleWave

//Proc 		ImageUndo(ctrlName,popNum,popStr) 	: PopupMenuControl

///////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////              Process Menus (Modify, Filter & Analyze)

//Proc 		ImgModify(ctrlName, popNum,popStr) : PopupMenuControl
//Proc 		PopFilter(ctrlName,popNum,popStr) 	: PopupMenuControl
//Proc 		ImgAnalyze(ctrlName, popNum,popStr) : PopupMenuControl

// Graph marquee (from mouse right click) + SelectCT
//Proc 		Crop() 									: GraphMarquee
//Proc 		NormY() 								: GraphMarquee
//Proc 		OffsetZ() 								: GraphMarquee
//Proc 		AreaX() 									: GraphMarquee
//Proc 		Find_Edge() 								: GraphMarquee
//Proc 		Find_Peak() 								: GraphMarquee
//Proc 		AdjustCT()								: GraphMarquee
//Proc 		SelectCT()

// Small procedures associated with previous actions (not listed here)

// Procedure for analyze menu (to check, does not always work fine)
//Fct 		AREA2D( img, axis, x1, x2, y0 )
//Fct/C  		EDGE2D( img, x1, x2, y0, wfrac )            // return CMPLX(pos, width)
//Fct/C  		PEAK2D( img, x1, x2, y0 )			         // return CMPLX(pos, width)
//Proc 		Area_Style() 				: GraphStyle
//Proc 		Edge_Style() 				: GraphStyle
//Proc 		Peak_Style() 				: GraphStyle

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Fct/T 		PickStr( promptstr, defaultstr, wvlst )	Ñ calls procedure 
//Proc 		Pick_Str( str1, str2 )			Ñ pops up dialog box

// Find_max in Fitting_EDC window



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////              ImageTool Window     ///////////////////////////////////////////////////////////
 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Proc InitImageTool()

//---------
	Silent 1
	NewDataFolder/O/S root:WinGlobals
	NewDataFolder/O/S root:WinGlobals:ImageTool
		variable/G X0=0, Y0=0, D0
		String/G S_TraceOffsetInfo		
		Variable/G hairTrigger
		// Dependencies
		SetFormula hairTrigger,"UpdateXYGlobals(S_TraceOffsetInfo)"
		
	NewDataFolder/O/S root:IMG
		string/G imgnam, imgfldr, imgproc, imgproc_undo, exportn
		variable/G nx=51, ny=51, center, width
		variable/G xmin=0, xinc=1, xmax, ymin=0, yinc=1, ymax
		variable/G dmin0, dmax0, dmin=0, dmax=1
		variable/G numpass=1			//# of filter passes
		variable/G gamma2=1, CTinvert=1
		make/o/n=(nx, ny) image0, image, image_undo
		make/o/n=(nx) profileH, profileH_x=p
		make/o/n=(ny) profileV, profileV_y=p
		Make/O HairY0={0,0,0,NaN,Inf,0,-Inf}
		Make/O HairX0={-Inf,0,Inf,NaN,0,0,0}
		make/o/n=256 pmap=p

		make/o/n=(256,3) RedTemp_CT,  Gray_CT, Image_CT
		RedTemp_CT[][0]=min(p,176)*370
		RedTemp_CT[][1]=max(p-120,0)*482
		RedTemp_CT[][2]=max(p-190,0)*1000
		Gray_CT=p*256

		// Dependencies
		pmap:=255*(p/255)^gamma2
		Image_CT:=RedTemp_CT[pmap[p]][q]	//  255
		profileH:=image(profileH_x)(root:WinGlobals:ImageTool:Y0)
		profileV:=image(root:WinGlobals:ImageTool:X0)(profileV_y)
		root:WinGlobals:ImageTool:D0:=root:IMG:image(root:WinGlobals:ImageTool:X0)(root:WinGlobals:ImageTool:Y0)

		// Nice pretty initial image
		image=cos((pi/10)*sqrt((x-25)^2+(y-25)^2))*cos( (2.5*pi)*atan2( y-25, x-25))
		ImgInfo(Image)
		
		NewDataFolder/O/S root:IMG:STACK
		variable/G xmin=0, xinc=1, ymin=0, yinc=1, dmin=0, dmax=1
		variable/G shift=0, offset=0, pinc=1, NbForAvg=1
		string/G basen
		SetDataFolder root:
End

///

Proc ShowImageTool( )
//----------------
	string curr=GetDataFolder(1)
	PauseUpdate; Silent 1
	DoWindow/F ImageTool
	if (V_flag==0)
		InitImageTool()
		Build_ImageTool()
		AdjustCT() 
		SetWindow imagetool hook=imgHookFcn, hookevents=3
		ModifyGraph offset(HairY0)={0,0}
		
		string os=IgorInfo(2)
		//If (!stringmatch( IgorInfo(2), "Macintosh") )
		//	MoveWindow 300,60,300+(878-399)*0.85,502  // My display : VB
			//reposition cursor step buttons
	//		variable cx=355, cy=165
	//	endif
		//alternately use screen size
		string screen=IgorInfo(0)
		screen=StringByKey( "SCREEN1", screen, ":" )
		print os, screen
	endif
	SetDataFolder $curr
end

///

Proc Build_ImageTool() 
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:IMG:
	Display /W=(500,50,900,500) HairY0 vs HairX0 as "ImageTool"
	AppendToGraph/R=lineX profileH vs profileH_x
	AppendToGraph/T=lineY profileV_y vs profileV
	AppendImage image
	ModifyImage image cindex= Image_CT
	SetDataFolder fldrSav0
	ModifyGraph cbRGB=(65535,65532,16385)
	ModifyGraph rgb(HairY0)=(0,65535,65535)
	ModifyGraph quickdrag(HairY0)=1
	ModifyGraph offset(HairY0)={25,0}  // where do these values come from ??
	ModifyGraph mirror(left)=3,mirror(bottom)=3,mirror(lineX)=1,mirror(lineY)=1
	ModifyGraph minor(left)=1,minor(bottom)=1
	ModifyGraph sep(left)=8,sep(bottom)=8
	ModifyGraph fSize=10
	ModifyGraph lblPos(left)=53,lblPos(bottom)=38,lblPos(lineX)=54,lblPos(lineY)=39
	ModifyGraph lblLatPos(lineX)=1,lblLatPos(lineY)=8
	ModifyGraph freePos(lineX)=0
	ModifyGraph freePos(lineY)=0
	ModifyGraph axisEnab(left)={0,0.7}
	ModifyGraph axisEnab(bottom)={0,0.7}
	ModifyGraph axisEnab(lineX)={0.75,1}
	ModifyGraph axisEnab(lineY)={0.75,1}
	Label left "eV"
	Label bottom "deg"
	Cursor/P A profileH 0;Cursor/P B profileH 26
	ShowInfo
	TextBox/C/N=title/F=0/A=MT/X=-4.28/Y=1.90/E "\\Z09'Ascan2': + Crop+ Transpose+ Norm Y+ Transpose"
	TextBox/C/N=text0/F=0/X=104.13/Y=-19.19 "\\Z10v3.6"
	ControlBar 70
	// Load and export
	Button LoadImg,pos={4,3},size={50,22},proc=NewImg,title="Load"
	Button LoadImg,help={"Select 2D image array in memory to copy to the ImageTool Panel"}
	Button ExportImage,pos={4,30},size={50,22},proc=ExportAction,title="Export"
	Button ExportImage,help={"Export current image or profile to a separate window with a new name (prompted for)."}
	// X, Y, Z
	SetVariable setX0,pos={65,6},size={70,16},proc=SetHairXY,title="X"
	SetVariable setX0,help={"Cross hair X-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setX0,fSize=10
	SetVariable setX0,limits={0,50,1},value= root:WinGlobals:ImageTool:X0
	SetVariable setY0,pos={65,27},size={70,16},proc=SetHairXY,title="Y"
	SetVariable setY0,help={"Cross hair Y-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setY0,fSize=10
	SetVariable setY0,limits={0,50,1},value= root:WinGlobals:ImageTool:Y0
	ValDisplay valD0,pos={65,48},size={61,15},title="D"
	ValDisplay valD0,help={"Image intensity value at current cross hair (X,Y) location.  "}
	ValDisplay valD0,fSize=10,limits={0,0,0},barmisc={0,1000}
	ValDisplay valD0,value= #"root:WinGlobals:ImageTool:D0"
	//ValDisplay nptx,pos={283,5},size={45,15},title="Nx"
	//ValDisplay nptx,help={"Number of horizontal pixels of current image."},fSize=10
	//ValDisplay nptx,limits={0,0,0},barmisc={0,1000},value= #"root:IMG:nx"
	//ValDisplay npty,pos={331,5},size={46,15},title="Ny"
	//ValDisplay npty,help={"Number of vertical pixels of current image."},fSize=10
	//ValDisplay npty,limits={0,0,0},barmisc={0,1000},value= #"root:IMG:ny"
	
	// Analysis
	PopupMenu ImageProcess,pos={147,4},size={68,21},proc=ImgModify,title="Modify"
	PopupMenu ImageProcess,help={"Image Modification:\rCrop & Norm Y optionally use a marquee box sub range.\rNorm X(Y),  Set X(Y)=0  use current crosshair location."}
	PopupMenu ImageProcess,mode=0,value= #"\"Crop;Transpose;Resize;Rescale;Set X=0;Set Y=0;Norm X;Norm Y;Norm Z;Symmetrize X;Offset Z;Invert Z\""
	//SetVariable setnumpass,pos={125,25},size={30,18},title=" "
	//SetVariable setnumpass,help={"# of passes to apply filter"}
	//SetVariable setnumpass,limits={1,9,1},value= root:IMG:numpass
	//PopupMenu popFilter,pos={162,23},size={59,21},proc=PopFilter,title="Filter"
	//PopupMenu popFilter,help={"Convolution -type image modification."}
	//PopupMenu popFilter,mode=0,value= #"\"AvgX;AvgY;median;avg;gauss;min;max;NaNZapMedian;FindEdges;Point;Sharpen;SharpenMore;gradN;gradS;gradE;gradW;\""
	PopupMenu ImageAnalyze,pos={219,4},size={74,21},proc=ImgAnalyze,title="Analyze"
	PopupMenu ImageAnalyze,help={"Image Analysis within a horizontal (X) range of the image selected by a marquee or A/B Cursors on the horizontal line profile.  Resulting (Area, Position, Width) waves are plotted in an new window with prompted-for names."}
	PopupMenu ImageAnalyze,mode=0,value= #"\"Area X;Find Edge;Fit Edge;Find Peak;Find Peak Max;-;Average Y;\""
	Button Conversion,pos={147,26},size={70,21},proc=ImageTool_convert,title="Convert"
	// Red temp
	SetVariable setgamma,pos={221,48},size={52,18},title="g"
	SetVariable setgamma,help={"Gamma value for image color table mapping.  Gamma < 1 enhances lower intensity features."}
	SetVariable setgamma,font="Symbol",limits={0.1,inf,0.1},value= root:IMG:gamma2
	PopupMenu SelectCT,pos={147,48},size={74,21},proc=SelectCT,title="   CT   "   
	PopupMenu SelectCT,mode=0,value= #"\"Grayscale;Red Temp;Invert;Rescale\""
	SetWindow kwTopWin,hook=imgHookFcn,hookevents=3
	//Stacks
	SetVariable setpinc,pos={310,5},size={35,18},title=" "
	SetVariable setpinc,help={"Y-increment to stack"}
	SetVariable setpinc,limits={1,99,1},value= root:IMG:STACK:pinc,proc=UpdateStack_pinc
	Button Stack,pos={352,5},size={70,20},proc=CreateStack,title="Stacks"
	Button Stack,help={"Average stacks"}
	SetVariable setavg,pos={310,30},size={35,18},title=" "
	SetVariable setavg,help={"Number of stacks to average"}
	SetVariable setavg,limits={1,100,1},value= root:IMG:STACK:NbForAvg
	Button AvgStack,pos={352,28},size={70,20},proc=Do_AvgStack,title="Avg Stacks"
	// Undo
	//PopupMenu ImageUndo,pos={444,2},size={63,21},proc=ImageUndo
	//PopupMenu ImageUndo,help={"Undo last image modification or restore to original"}
	//PopupMenu ImageUndo,mode=1,popvalue="Undo",value= #"\"Undo;Restore\""
	Button ImageUndo,pos={443,17},size={63,30},proc=ImageUndo,title="Undo"
	DoWindow/C ImageTool
EndMacro

/////////////////////////////    LOAD

Proc NewImg(ctrlName) : ButtonControl
//------------ Appelé par bouton Load
	String ctrlName
	string curr=GetDataFolder(1)

	// Popup Dialog image array selection
	string datnam
	if (stringmatch(ctrlName, "LoadImg"))
		PickImage( )
		datnam=root:IMG:imgfldr+root:IMG:imgnam
	else
		datnam=ctrlName
		root:img:imgnam=datnam
		root:img:imgfldr=""
	endif
      
	PauseUpdate; Silent 1
	SetDataFolder root:IMG
	duplicate/o $datnam Image,  Image0,  Image_undo
        DoLoad(curr)
end

Proc PickImage( wn )
//------------
	String wn=StrVarOrDefault("root:img:imgnam","")
	prompt wn, "new image, 2D array", popup, WaveList("!*_CT",";","DIMS:2")+"-; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")
	
	root:img:imgnam="'"+wn+"'"
	root:img:imgfldr=GetWavesDataFolder($wn, 1)
	root:img:exportn=wn		// prepare export name
End


Proc DoLoad(curr)
	string curr // Name of Data Folder to go back to at the end of Load
		SetDataFolder root:IMG
		DoWindow/F ImageTool
		SetAxis/A
		ImgInfo(Image)
		//print dmin0, dmax0
		variable/G dmin=dmin0, dmax=dmax0
		ModifyImage  Image cindex= Image_CT
		//ModifyImage  Image cindex= RedTemp_CT
		//SetScale/I x dmin0, dmax0,"" root:IMG:RedTemp_CT
		//print dmin, dmax, dmin0, dmax0
		AdjustCT()
		//print dmin, dmax, dmin0, dmax0
	
		SetHairXY( "Center", 0, "", "" )
 		SetProfiles()		
		
		ReplaceText/N=title "\Z09"+imgnam
		imgproc=""
		Label bottom WaveUnits(Image, 0)
		Label left WaveUnits(Image, 1)
			
	SetDataFolder $curr
End

///////////////////////////////////////////////////////////

Function/T ImgInfo( image )
//================
// creates variables in current folder
// returns info string
	wave image
	variable/G nx, ny
	variable/G xmin, xinc, xmax, ymin, yinc, ymax, dmin0, dmax0
	nx=DimSize(image, 0); 	ny=DimSize(image, 1)
	xmin=DimOffset(image,0);  ymin=DimOffset(image,1);
	xinc=round(DimDelta(image,0) * 1E6) / 1E6	
	yinc=round(DimDelta(image,1)* 1E6) / 1E6
	xmax=xmin+xinc*(nx-1);	ymax=ymin+yinc*(ny-1);
	WaveStats/Q image
	dmin0=V_min;  dmax0=V_max
	string info="x: "+num2istr(nx)+", "+num2str(xmin)+", "+num2str(xinc)+", "+num2str(xmax)
	info+=    "\r y: "+num2istr(ny)+", "+num2str(ymin)+", "+num2str(yinc)+", "+num2str(ymax)
	info+=    "\r z: "+num2str(dmin0)+", "+num2str(dmax0)
	return info
End

Proc SetProfiles()				//XY profiles
//-------------
	PauseUpdate; Silent 1
	string curr=GetDataFolder(1)
	SetDataFolder root:IMG
	
		Redimension/N=(nx) profileH, profileH_x
		profileH_x=xmin+p*xinc
		
		Redimension/N=(ny) profileV, profileV_y
		profileV_y=ymin+p*yinc
		
		//ImageTool Window must be on top
		DoWindow/F ImageTool
		SetVariable setX0 limits={min(xmin, xmax), max(xmin, xmax), abs(xinc)}
		SetVariable setY0 limits={min(ymin, ymax), max(ymin, ymax), abs(yinc)}
		
		SetDataFolder $curr
End

Proc StepHair(ctrlName) : ButtonControl
//-------------------
// step XYHair offset; automatically updates profiles
	String ctrlName
	variable/C coffset=GetWaveOffset(root:IMG:HairY0)
	variable xcur=REAL(coffset), ycur=(IMAG(coffset))
	
	if (CmpStr(ctrlname,"stepRight")==0)
		ModifyGraph offset(HairY0)={xcur+root:IMG:xinc, ycur}
	endif
	if (CmpStr(ctrlname,"stepLeft")==0)
		ModifyGraph offset(HairY0)={xcur-root:IMG:xinc, ycur}
	endif
	if (CmpStr(ctrlname,"stepUp")==0)
		ModifyGraph offset(HairY0)={xcur, ycur+root:IMG:yinc}
	endif
	if (CmpStr(ctrlname,"stepDown")==0)
		ModifyGraph offset(HairY0)={xcur, ycur-root:IMG:yinc}
	endif
	if (CmpStr(ctrlname,"center")==0)
		SetHairXY( "Center", 0, "", "" )
	endif
End

Function SetHairXY(ctrlName,varNum,varStr,varName) : SetVariableControl
//=================================
//  reposition image cursor offset if X or Y value changed manually from display
//  new cursor offset automatically reupdates X0,Y0 and D0 display values
// Show corresponding stack in blue
	String ctrlName
	Variable varNum
	String varStr
	String varName

	variable/C coffset=GetWaveOffset(root:IMG:HairY0)
	variable xcur=REAL(coffset), ycur=(IMAG(coffset))   
	

		
	NVAR xmin=root:IMG:xmin, xmax=root:IMG:xmax
	NVAR ymin=root:IMG:ymin, ymax=root:IMG:ymax
	
	//print "old: ", xcur, ycur
	//
	if (cmpstr(ctrlName,"SetX0")==0)
		// force Hair value to be on one image point
		varNum=round((varNum - DimOffset(root:IMG:Image, 0))/DimDelta(root:IMG:Image,0))*DimDelta(root:IMG:Image,0)+DimOffset(root:IMG:Image, 0)
		nvar Xvalue= root:WinGlobals:ImageTool:X0
		Xvalue=varNum
		ModifyGraph offset(HairY0)={varNum, ycur}
	endif
	if (cmpstr(ctrlName,"SetY0")==0)
		// force Hair value to be on one image point
		varNum=round((varNum - DimOffset(root:IMG:Image, 1))/DimDelta(root:IMG:Image,1))*DimDelta(root:IMG:Image,1)+DimOffset(root:IMG:Image, 1)
		nvar Yvalue= root:WinGlobals:ImageTool:Y0
		Yvalue=varNum
		ModifyGraph offset(HairY0)={xcur, varNum}
		// Corresponding stack in blue
		HighlightSelectedStack()
	endif
	if (cmpstr(ctrlName,"Check")==0)
//		print xmin,xmax, ymin,ymax
		if ((xcur<xmin)+(xcur>xmax))
			xcur=(xmin+xmax)/2
			ModifyGraph offset(HairY0)={ xcur, ycur}
		endif
		if ((ycur<ymin)+(ycur>ymax))
			ModifyGraph offset(HairY0)={ xcur, (ymin+ymax)/2 }
		endif
	endif
	if (cmpstr(ctrlName,"Center")==0)
		ModifyGraph offset(HairY0)={(xmin+xmax)/2, (ymin+ymax)/2 }
	endif
	if (cmpstr(ctrlName,"ResetCursor")==0)
		Cursor/P A, profileH, round((xcur - DimOffset(root:IMG:Image, 0))/DimDelta(root:IMG:Image,0))
		Cursor/P B, profileV_y, round((ycur - DimOffset(root:IMG:Image, 1))/DimDelta(root:IMG:Image,1))
	endif

End

Function UpdateXYGlobals(tinfo)
//======================
// Copied from "UpdateHairGlobals" in <Cross Hair Cursors>
	String tinfo
	
	tinfo= ";"+tinfo
	
	String s= ";GRAPH:"
	Variable p0= StrSearch(tinfo,s,0),p1
	if( p0 < 0 )
		return 0
	endif
	p0 += strlen(s)
	p1= StrSearch(tinfo,";",p0)
	String gname= tinfo[p0,p1-1]
	String thedf= "root:WinGlobals:"+gname
	if( !DataFolderExists(thedf) )
		return 0
	endif
	
	s= ";TNAME:HairY"
	p0= StrSearch(tinfo,s,0)
	if( p0 < 0 )
		return 0
	endif
	p0 += strlen(s)
	p1= StrSearch(tinfo,";",p0)
	Variable n= str2num(tinfo[p0,p1-1])
	
	String dfSav= GetDataFolder(1)
	SetDataFolder thedf
	
	s= "XOFFSET:"
	p0=  StrSearch(tinfo,s,0)
	if( p0 >= 0 )
		p0 += strlen(s)
		p1= StrSearch(tinfo,";",p0)
		Variable/G $"X"+num2str(n)=str2num(tinfo[p0,p1-1])
	endif
	
	s= "YOFFSET:"
	p0=  StrSearch(tinfo,s,0)
	if( p0 >= 0 )
		p0 += strlen(s)
		p1= StrSearch(tinfo,";",p0)
		Variable/G $"Y"+num2str(n)=str2num(tinfo[p0,p1-1])
	endif
	
//	CreateUpdateZ(gname,n)
	
	SetDataFolder dfSav
	
	HighlightSelectedStack()
end

function imgHookfcn (infostr)
//===============
//  CMD/CTRL key + mouse motion = dynamical update of cross-hair
//  OPT/ALT key + mouse motion =  left/right/up/down step  of cross-hair
// SHIFT key + mouse motion = bring cross-hair to center
// need to setwindow imagetool hook=imgHookFcn, hookevents=3 to imagetool window
//  Modifier bits:  0001=mousedown, 0010=shift  , 0100=option/alt, 1000=cmd/ctrl
	string infostr
	variable mousex,mousey,ax,ay, modif
	modif=numbykey("modifiers", infostr)
	//print modif
	if ((modif==9)+(modif==5))
		mousex=numbykey("mousex",infostr)
		mousey=numbykey("mousey",infostr)
		ay=axisvalfrompixel("imagetool","left",mousey)
		ax=axisvalfrompixel("imagetool","bottom",mousex)	
	endif
	if (modif==9)			//9 = "1001" = cmd/ctrl+mousedown
		ModifyGraph offset(HairY0)={ax,ay}
		return 1
	else
	if (modif==5)				// 5 = "0101" = option/alt +mousedown
		variable dx, dy, xrng, yrng
		string dir
		NVAR x0=root:WinGlobals:imageTool:x0, y0=root:WinGlobals:imageTool:y0
		GetAxis/Q bottom
		dx= (ax - x0) / abs(V_max-V_min)
		GetAxis/Q left
		dy= (ay - y0) / abs(V_max-V_min)
		if (abs(dx/dy)>=1)	
			dir="step"+SelectString( dx>0, "Left", "Right")
		else	
			dir="step"+SelectString( dy>0, "Down", "Up")
		endif
		//print dir, abs(dx/dy)
		execute "StepHair(\"" +dir+"\")"
		return 2
	else
	if (modif==3)			// 3 = "0011" =shift +mousedown
		execute "StepHair(\"center\")"
		return 3
	else
		return 0
	endif
	endif
	endif
end

////////////////////////////////    EXPORT

Proc ExportAction(ctrlName) : ButtonControl
String ctrlName
 	if (stringmatch(ctrlname,"ExportStack"))
 		ExportStack( )
 		else
		ExportImage()
	endif	
End

Proc ExportImage( exportn, eopt, dopt )
	String exportn=StrVarOrDefault( "root:IMG:exportn", "")
	variable eopt=NumVarOrDefault( "root:IMG:exportopt", 1), dopt=NumVarOrDefault( "root:IMG:dispopt", 1)
	prompt eopt, "Export", popup, "Image; Image & Color Table;X profile;Y profile;Maximum"
	prompt dopt, "Option", popup, "Display;Append;None"
	
	string/G root:IMG:exportn=exportn 
	variable/G root:IMG:exportopt=eopt, root:IMG:dispopt=dopt
		
	SetDataFolder root:
	PauseUpdate; Silent 1
	
	IF (eopt<=2)  
		// Export Image
		//** use only subset from graph axes	
		GetAxis/Q bottom 
		variable left=V_min, right=V_max
		GetAxis/Q left
		variable bottom=V_min, top=V_max
		Duplicate/O/R=(left,right)(bottom,top) root:IMG:Image, $exportn
		if (dopt<3)
			Display; Appendimage $exportn
			execute "ModifyImage "+exportn+" ctab= {*,*,PlanetEarth,1}"
			ModifyGraph fSize=16
			ModifyGraph zero(left)=1
			string titlestr="\\Z16"+exportn
			Textbox/N=title/F=0/A=MT/E titlestr
			string winnam=exportn+"_Img"
			DoWindow/F $winnam
			if (V_Flag==1)
				DoWindow/K $winnam
			endif
			DoWindow/C $winnam
		endif
		
		if (eopt==2)          // also export color table
			Duplicate/O root:IMG:Image_CT $(exportn+"_CT")
			if (dopt<3)
				execute "ModifyImage "+exportn+" cindex= "+exportn+"_CT"
			endif
		endif
	ELSE
		// Export Profile
		variable np
		if (eopt==4)   		// vertical Y-profile
			np=numpnts( root:IMG:profileV )
			make/o/n=(np) $exportn
			$exportn=root:IMG:profileV
			ScaleWave( $exportn, "root:IMG:profileV_y", 0, 0 )
		endif	
		if (eopt==3)   		// horizontal X-profile
			np=numpnts( root:IMG:profileH )
			make/o/n=(np) $exportn
			$exportn=root:IMG:profileH
			ScaleWave( $exportn, "root:IMG:profileH_x", 0, 0 )	
		endif
		// Export Maximum
		if (eopt==5)   		// maximum
			 Export_max(exportn,dopt)
		endif
		
		if (dopt==1 && eopt<5)
			Display $exportn
		else
			if (dopt==2 && eopt<5 )
				DoWindow/F $WinName(1,1)		// next graph behind ImageTool
				Append $exportn
			endif
		endif
	ENDIF
End

function/T ScaleWave( wv, xwn, dim, method )
//====   Used by export profiles
// scale n-dim wave to x-wave values for specified dimension 
// 2D wave to both x and y values
// methods: 0 - Point, 1-inclusive, 2 - reinterpolated
	wave wv
	string xwn
	variable dim, method
	variable ndim=WaveDims(wv)
	if (dim>=ndim)
		return "dimension out of range: "+num2str(ndim)
	endif
	//string wvn=NameOfWave(wv)
	string wvn=GetWavesDataFolder(wv, 2)			// returns full data folder path and name
	string cmd
	variable incr, np
	if (strlen(xwn)>0)
		if (cmpstr(xwn[0],"_")==0)
			xwn=wvn+xwn
		endif
		WAVE xw=$xwn
		//WaveStats/Q $xwn
		//SetScale/I x V_min,V_max, "" wv
		if (method==0)
			cmd="SetScale/P "+"xyzt"[dim]+" "
			cmd+=num2str(xw[0])+", "+num2str( xw[1]-xw[0])
		else
			np=numpnts(xw)
			cmd="SetScale/I "+"xyzt"[dim]+" "
			cmd+=num2str(xw[0])+", "+num2str( xw[np-1])
		endif
		cmd+=", \""+ WaveUnits(xw, 0) +"\" "+ wvn
		execute cmd 
		if (method==2)
			duplicate/o wv wtmp
			wv=interp( x, xw, wtmp )
			killwaves/Z wtmp
		endif
	endif
	return cmd
end

function Export_max(name,mode)
	String name
	variable mode // 1 for display, 2 for append
// Maximum has been calculated (usually max_y vs max_x)
// This procedure saves waves chosen in the window, with given name 
// (with extra _y for y wave (which is just a scale))
// Also do the plot Max vs Max_x
// If Append, continue existing file

// NB : an older version can be found in Fitting_EDC (more choices on plots)

SetDataFolder root:IMG

string Disp_posY,Disp_EnergyX,choix
choix="none;"+WaveList("*",";","DIMS:1")
disp_posY="Max_y"
disp_energyX="Max_x"
prompt Disp_posY,"Wave for y ", popup,choix
prompt Disp_EnergyX,"Wave for x ", popup,choix
variable p_min,p_max,nb
p_min=0
p_max=dimsize(Max_x,0)-1
prompt p_min,"From index p= "
prompt p_max,"To index p= "
//choix="E vs k (1 wave); k vs E (1 wave); E vs k (2 waves); k vs E (2 waves)"  
//string PlotType="E vs k (1 wave)"
//prompt PlotType, "Plot", popup,choix
string/G nameX,nameY
string nameX_L=nameX
prompt nameX_L, "Suffix for output X wave(s)"
string nameY_L=nameY
prompt nameY_L, "Suffix for output Y wave(s)"

//DoPrompt "Save..." Disp_pos,Disp_Energy,p_min,p_max,PlotType,name
DoPrompt "Save..." Disp_EnergyX,Disp_PosY,nameX_L,nameY_L,p_min,p_max

nameX=nameX_L
nameY=nameY_L
nb=p_max-p_min+1

if (v_flag==0)
	
	variable Y_start
	string name1,name2
	
	//Disp_EnergyX and Disp_PosY have X and Y value to save (usually max_x and max_y)
	// We want to change boundaries : temp will have the chosen subset of x values (duplicated in temp2)
	Duplicate/O $disp_energyX temp2
	Make/O /N=(nb) temp
	temp[]=temp2[p+p_min]
	// Rescale X wave with y values (will not work for append)
	Y_start=Dimoffset($Disp_posY,0)+p_min*DimDelta($Disp_posY,0)
	SetScale/P x Y_start,DimDelta($Disp_posY,0), temp
	
	//Copy these temporary waves into output waves (just copy or append)
	name1=name+"_"+nameX
	if (mode==1)
		Duplicate/O temp $name1
		else	 // Append to existing wave
		Duplicate/O $name1 temp3
		Redimension/N=(DimSize($name1,0)+Nb) temp3
		 temp3[DimSize($name1,0),DimSize(temp3,0)-1]=temp[p-DimSize($name1,0)]
		 Duplicate/O temp3, $name1
		 Killwaves temp3
	endif

	name2=name+"_"+nameY
	temp=Y_start+p*DimDelta($Disp_posY,0)  // Just a scale
	if (mode==1)
		Duplicate/O temp $name2
		else
		Duplicate/O $name2 temp3
		Redimension/N=(DimSize($name2,0)+Nb) temp3
		 temp3[DimSize($name2,0),DimSize(temp3,0)-1]=temp[p-DimSize($name2,0)]
		 Duplicate/O temp3, $name2
		 Killwaves temp3
	endif	
	Killwaves temp,temp2
	
	if (mode==1 )
			//Simple display
			DoWindow/K Max_
			Display $name1 vs $name2
			DoWindow/C Max_
			DoWindow/T Max_,"Max_"
			Label left nameX
			Label bottom nameY
			Legend/C/N=text0/A=MC
			ModifyGraph zero(left)=1
			ModifyGraph mode=3,marker=19
			ShowInfo
			variable deb,fin
			deb=leftx($name1)        
			fin=deb+deltax($name1)*(numpnts($name1)-1)
			Cursor A, $name1, deb
			Cursor B, $name1, fin
			DoUpdate  	
	else
			//Append
			DoWindow/F Max_
			//AppendToGraph  $name1 vs $name2
			//ModifyGraph mode=3,marker=19,rgb($name1)=(0,15872,65280)
	endif		
	
	
endif



end

///////////////////////////////  UNDO
Proc ImageUndo(ctrlName) : ButtonControl
//Proc ImageUndo(ctrlName,popNum,popStr) : PopupMenuControl
//--------------------------------
	String ctrlName
	//Variable popNum
	//String popStr

	string curr=GetDataFolder(1), stmp
	SetDataFolder root:IMG
	PauseUpdate; Silent 1
	//if (cmpstr(popStr,"Restore")==0)
//		duplicate/o Image Image_Undo
//		duplicate/o Image0 Image
//		imgproc_undo=imgproc
//		imgproc=""
//		ReplaceText/N=title "\Z09"+imgnam
//		 SetAxis/A
//		 dmin=dmin0;  dmax=dmax0
//		 AdjustCT()
//	endif
//	if (cmpstr(popStr,"Undo")==0)		//swap Image and Image_Undo
		duplicate/o Image tmp
		duplicate/o Image_Undo Image
		duplicate/o tmp Image_Undo
		stmp=imgproc
		imgproc=imgproc_undo
		imgproc_undo=stmp
		ReplaceText/N=title "\Z09"+imgnam+": "+imgproc
		 AdjustCT()
//	endif
	ImgInfo( Image )	
	SetProfiles()	
	SetHairXY( "Check", 0, "", "" )
	//PopupMenu ImageUndo mode=1		//restore to first item
	SetAxis/A
	DoWindow Stack_
	if (v_flag==1)
		UpdateStack()
	endif
	SetDataFolder curr
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////              Process Menus (Modify, Filter & Analyze)              /////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Proc ImgModify(ctrlName, popNum,popStr) : PopupMenuControl
//------------------------
	String ctrlName
	Variable popNum
	String popStr
	
	PauseUpdate; Silent 1
	string curr=GetDataFolder(1)
	
	SetDataFolder root:IMG
	Duplicate/O Image Image_Undo
	imgproc_undo=imgproc
	
	variable/C coffset=GetWaveOffset(root:IMG:HairY0)
	
	if (cmpstr(popStr,"Crop")==0)
		variable/G x1_crop, x2_crop, y1_crop, y2_crop
		GetMarquee/K left, bottom
		if (V_Flag==1)
			x1_crop=xinc*round(V_left/xinc)		//round to nearest data increment
			x2_crop=xinc*round(V_right/xinc)
			y1_crop=yinc*round(V_bottom/yinc)
			y2_crop=yinc*round(V_top/yinc)
		endif
		ConfirmRECT( )
		Duplicate/O/R=(x1_crop,x2_crop)(y1_crop,y2_crop) Image_Undo, Image
		AdjustCT()
	endif

	if (cmpstr(popStr,"Transpose")==0)
		MatrixTranspose Image
		 SetAxis/A
		ModifyGraph offset(HairY0)={IMAG(coffset), REAL(coffset)}

	endif
	
	if (cmpstr(popStr,"Resize")==0)
		ResizeImg(  )
	endif
		if (cmpstr(popStr,"Rebin X")==0)
			variable nx2=trunc(nx/2)
			xinc*=2
			Redimension/N=(nx2, ny) Image
			SetScale/P x xmin, xinc,"" Image
			variable ii
			DO
				Image[ii][]=( Image_Undo[2*ii][q]+Image_Undo[2*ii+1][q] )  //*0.5
				ii+=1
			WHILE( ii<nx2)
		endif
		if (cmpstr(popStr,"Rebin Y")==0)
			variable ny2=trunc(ny/2)
			yinc*=2
			Redimension/N=(nx, ny2) Image
			SetScale/P y ymin, yinc,"" Image
			variable ii
			DO
				Image[][ii]=( Image_Undo[p][2*ii]+Image_Undo[p][2*ii+1] )  //*0.5
				ii+=1
			WHILE( ii<ny2)
		endif

	if (cmpstr(popStr,"Rescale")==0)
		RescaleImg( )
	endif
	
	if (cmpstr(popStr,"Set X=0")==0)
		SetScale/P x xmin-REAL(coffset), xinc,"" Image
		ModifyGraph offset(HairY0)={0, IMAG(coffset)}
	endif
	
	if (cmpstr(popStr,"Set Y=0")==0)
		SetScale/P y ymin-IMAG(coffset), yinc,"" Image
		ModifyGraph offset(HairY0)={REAL(coffset), 0}
	endif
	
	if (cmpstr(popStr,"Norm X")==0)
		variable/G y1_norm, y2_norm
		GetMarquee/K left
		if (V_Flag==1)
			y1_norm=yinc*round(V_bottom/yinc)		//round to nearest data increment
			y2_norm=yinc*round(V_top/yinc)
		endif
		ConfirmYNorm(  )
		make/o/n=(nx) xtmp
		SetScale/P x xmin, xinc, "" xtmp
		xtmp = AREA2D( Image, 1, y1_norm, y2_norm, x )
		Image /= xtmp[p]
		 AdjustCT()
	endif

	if (cmpstr(popStr,"Norm Y")==0)
		variable/G x1_norm, x2_norm
		GetMarquee/K bottom
		if (V_Flag==1)
			x1_norm=xinc*round(V_left/xinc)		//round to nearest data increment
			x2_norm=xinc*round(V_right/xinc)
		endif
		ConfirmXNorm(  )
		Cursor/P A, profileH, x2pnt( Image, x1_norm) 
		Cursor/P B, profileH, x2pnt( Image, x2_norm)
		make/o/n=(ny) ytmp
		SetScale/P x ymin, yinc, "" ytmp
		ytmp = AREA2D( Image, 0, x1_norm, x2_norm, x )
		Image /= ytmp[q]
		 AdjustCT()
	endif
	
	if (cmpstr(popStr,"Norm Z")==0)
		// Normalize so that highest Z =1
		GetMarquee/K left, bottom
		If (V_Flag==1)
			Duplicate/O/R=(V_left,V_right)(V_bottom,V_top) Image, imgtmp
			WaveStats/Q imgtmp
			Image=Image_Undo / V_avg
		else
			//WaveStats/Q Image
			variable normval=Image(root:WinGlobals:ImageTool:X0)(root:WinGlobals:ImageTool:Y0)
			Image=Image_Undo / normval
		endif
		AdjustCT()
	endif
		
	if (cmpstr(popStr,"Symmetrize X")==0)
		Image=Image_Undo(x)[q]+Image_Undo(-x)[q] 
		AdjustCT()
	endif
	
	if (cmpstr(popStr,"Offset Z")==0)
		GetMarquee/K left, bottom
		If (V_Flag==1)
			Duplicate/O/R=(V_left,V_right)(V_bottom,V_top) Image, imgtmp
			WaveStats/Q imgtmp
			Image=Image_Undo - V_avg
		else
			WaveStats/Q Image
			Image=Image_Undo - V_min
		endif
		AdjustCT()
	endif
		
	if (cmpstr(popStr,"Invert Z")==0)
		Image=-Image_Undo
		AdjustCT()
	endif
	
	ImgInfo( Image )
 	SetProfiles()	
	SetHairXY( "Check", 0, "", "" )
	DoWindow/F ImageTool // Because Stacks is on top after SetHairXY
	imgproc+="+ "+popStr			// update this after operation incase of intermediate macro Cancel
	ReplaceText/N=title "\Z09"+imgnam+": "+imgproc
	
	SetDataFolder curr
End

///////////////////

Function PopFilter(ctrlName,popNum,popStr) : PopupMenuControl
//================
	String ctrlName
	Variable popNum
	String popStr
	
	string curr=GetDataFolder(1)
	SetDataFolder root:IMG
	
	string keyword=popStr
	variable size=3
	WAVE w=Image
	NVAR npass=root:IMG:numpass
	
	if( CmpStr(keyword,"NaNZapMedian") == 0 )
		if( (WaveType(w) %& (2+4) ) == 0 )
			Abort "Integer image has no NANs to zap!"
			return 0
		endif
	endif

	 // Save current image to backup
	Duplicate/o Image Image_Undo
	SVAR imgnam=imgnam, imgproc=imgproc, imgproc_undo=imgproc_undo
	imgproc_undo=imgproc
	imgproc+="+ "+keyword+num2istr(npass)
	
	if (popNum<=2)		// Custom Matrix filters
		if( CmpStr(keyword,"AvgX") == 0 )
			make/o CoefM={.25,.5,.25}					// 3x1 average
		endif
		if( CmpStr(keyword,"AvgY") == 0 )
			make/o CoefM={{.25},{.5},{.25}}			// 1x3 average
		endif
		
		variable ipass=0
		DO
			MatrixConvolve CoefM, Image
			ipass+=1
		WHILE( ipass<npass)
	else
		MatrixFilter/N=(size)/P=(npass) $keyword, Image	
	ENDIF
	
	ReplaceText/N=title "\Z09"+imgnam+": "+imgproc
	SetDataFolder curr
End

////////////////

Proc ImgAnalyze(ctrlName, popNum,popStr) : PopupMenuControl
//------------------------
	String ctrlName
	Variable popNum
	String popStr
	
	PauseUpdate; Silent 1
	string curr=GetDataFolder(1)
	
	SetDataFolder root:IMG

	if (popNum<=5)				// get & confirm analysis X-range
		variable/G x1_analysis, x2_analysis
		GetMarquee/K bottom
		if (V_Flag==1)
			x1_analysis=xinc*round(V_left/xinc)		//round to nearest data increment
			x2_analysis=xinc*round(V_right/xinc)
		endif
		ConfirmXAnalysis( )
		Cursor/P A, profileH, x2pnt( Image, x1_analysis) 
		Cursor/P B, profileH, x2pnt( Image, x2_analysis)	
	endif
	
	if (cmpstr(popStr,"Area X")==0)
		string/G root:IMG:arean
		string wn=PickStr( "Area Wave Name", root:IMG:arean, 0)
		root:IMG:arean=wn
		
		SetDataFolder curr
		//wn="root:"+wn
		make/o/n=(root:IMG:ny) $wn
		SetScale/P x root:IMG:ymin, root:IMG:yinc, "" $wn
		$wn = AREA2D( root:IMG:Image, 0, root:IMG:x1_analysis,  root:IMG:x2_analysis, x )
		
		DoWindow/F Area_
		if (V_Flag==0)
			Display $wn
			DoWindow/C Area_
			Area_Style("Area")
		else
			CheckDisplayed/W=Area_  $wn
			if (V_Flag==0)
				Append $wn
			endif
		endif
	endif
	
	if ((cmpstr(popStr,"Find Edge")==0) + (cmpstr(popStr,"Fit Edge")==0))
		PromptEdge()		//selects edgen, edgefit=(0,1), positionfit=(0,1,2)
		string wn=root:IMG:edgen
		SetDataFolder curr
		string ctr=wn+"_e", wdth=wn+"_w"
		make/C/o/n=(root:IMG:ny) $wn
		make/o/n=(root:IMG:ny) $ctr, $wdth
		SetScale/P x root:IMG:ymin, root:IMG:yinc, WaveUnits(root:IMG:Image,0) $wn,  $ctr, $wdth
		variable wfrac=0.15*SelectNumber(root:IMG:edgefit==1, 1, -1)	// negative turns on fitting
		variable debug=0
		if (debug)
			iterate( root:IMG:ny )
				$wn = EDGE2D( root:IMG:Image,  root:IMG:x1_analysis,  root:IMG:x2_analysis, pnt2x($wn, i), wfrac )
				PauseUpdate
				ResumeUpdate
				print i
			loop
		else
			$wn = EDGE2D( root:IMG:Image,  root:IMG:x1_analysis,  root:IMG:x2_analysis, x, wfrac )
		endif
		$ctr=REAL( $wn )
		$wdth=IMAG( $wn )
		//
		DoWindow/F Edge_
		if (V_Flag==0)
			Display $ctr
			Append/L=wid $wdth
			DoWindow/C Edge_
			Edge_Style()
		else
			CheckDisplayed/W=Edge_  $ctr, $wdth
			if (V_Flag==0)
				Append $ctr
				Append/L=wid $wdth
				print ctr, wdth
			endif
		endif
		ModifyGraph lstyle($wdth)=2, rgb($wdth)=(0,0,65535), mode($wdth)=4
		//
		variable fitpos=root:IMG:positionfit
		if (fitpos>0)
			if (fitpos==1)		//linear
				CurveFit line $ctr /D
			else					// quadratic or allow higher?
				CurveFit poly 3, $ctr /D
			endif 
			ModifyGraph rgb($("fit_"+ctr))=(0,65535,0)
		endif
	endif
	
	if (cmpstr(popStr,"Find Peak Max")==0)
		variable pkmode=0
		pkmode=1
		popStr="Find Peak"
	endif

	if (cmpstr(popStr,"Find Peak")==0)
		string/G root:IMG:peakn
		string wn=PickStr( "Peak Base Name", root:IMG:peakn, 0)
		root:IMG:peakn=wn
		//
		SetDataFolder curr
		string ctr=wn+"_e", wdth=wn+"_w"
		make/C/o/n=(root:IMG:ny) $wn
		make/o/n=(root:IMG:ny) $ctr, $wdth
		SetScale/P x root:IMG:ymin, root:IMG:yinc, "" $wn,  $ctr, $wdth
		$wn = PEAK2D( root:IMG:Image,  root:IMG:x1_analysis,  root:IMG:x2_analysis,  x, pkmode )
		$ctr=REAL( $wn )
		$wdth=IMAG( $wn )
		//
		DoWindow/F Peak_
		if (V_Flag==0)
			Display $ctr
			Append/R $wdth
			DoWindow/C Peak_
			Peak_Style()
		else
			CheckDisplayed/W=Peak_  $ctr, $wdth
			if (V_Flag==0)
				Append $ctr
				Append/R $wdth
				print ctr, wdth
			endif
		endif
		ModifyGraph lstyle($wdth)=2, rgb($wdth)=(0,0,65535), mode($wdth)=4
	endif
	
	if (cmpstr(popStr,"Average Y")==0)
		string/G root:IMG:sumn
		string wn=PickStr( "Avg Wave Name", root:IMG:sumn, 0)
		root:IMG:sumn=wn
		//
		SetDataFolder curr
		//wn="root:"+wn
		make/o/n=(root:IMG:nx) $wn
		SetScale/P x root:IMG:xmin, root:IMG:xinc, "" $wn
		iterate( root:IMG:ny )
			$wn+=root:IMG:Image[p][i]
		loop
		$wn /= root:IMG:ny
		//
		DoWindow/F Sum_
		if (V_Flag==0)
			Display $wn
			DoWindow/C Sum_
			Area_Style("Average")
		else
			CheckDisplayed/W=Sum_  $wn
			if (V_Flag==0)
				Append $wn
			endif
		endif
	endif

	SetDataFolder curr
End

/////////////////////////////////////
//        Graph Marquee

Proc Crop() : GraphMarquee
//--------------------
	string NameOfActiveWindow
	NameOfActiveWindow=WinList("*","","WIN:")
	if (cmpstr(NameOfActiveWindow,"ImageTool")==0)
		ImgModify(" ", 0,"Crop")
		else
		CropFromMarquee() //In ImgMakeUp procedure
	endif	
End

Proc NormX() : GraphMarquee
//--------------------
	ImgModify("", 0,"Norm X")
End

Proc NormY() : GraphMarquee
//--------------------
	ImgModify("", 0,"Norm Y")
End

Proc NormZ() : GraphMarquee
//--------------------
	ImgModify("", 0,"Norm Z")
End

Proc OffsetZ() : GraphMarquee
//--------------------
	ImgModify("", 0,"Offset Z")
End

Proc AreaX() : GraphMarquee
//--------------------
	ImgAnalyze("", 0,"Area X")
End

Proc Find_Edge() : GraphMarquee
//--------------------
	ImgAnalyze("", 0, "Find Edge")
End

Proc Find_Peak() : GraphMarquee
//--------------------
	ImgAnalyze("", 0, "Find Peak")
End

Proc AdjustCT() : GraphMarquee
//--------------------
	string curr=GetDataFolder(1)
	SetDataFolder root:IMG
	GetMarquee/K left, bottom
	If (V_Flag==1)
		Duplicate/O/R=(V_left,V_right)(V_bottom,V_top) root:IMG:Image, root:IMG:imgtmp
		WaveStats/Q root:IMG:imgtmp
		variable px1, px2, py1, py2
		px1=(V_left-DimOffset(root:IMG:Image,0))/ DimDelta(root:IMG:Image,0)
		px2=(V_right-DimOffset(root:IMG:Image,0))/ DimDelta(root:IMG:Image,0)
		py1=(V_bottom-DimOffset(root:IMG:Image,1))/ DimDelta(root:IMG:Image,1)
		py2=(V_top-DimOffset(root:IMG:Image,1))/ DimDelta(root:IMG:Image,1)
	else
		WaveStats/Q root:IMG:Image
	endif
	variable/G root:IMG:dmin=V_min, root:IMG:dmax=V_max
	if (root:IMG:CTinvert<0)
		SetScale/I x V_max, V_min,"" root:IMG:Image_CT
	else
		SetScale/I x V_min, V_max,"" root:IMG:Image_CT
	endif
	killwaves/Z root:IMG:imgtmp
	SetDataFolder $curr
End

Proc SelectCT(ctrlName,popNum,popStr) : PopupMenuControl
//--------------------
	String ctrlName
	Variable popNum
	String popStr
	
	PauseUpdate
	if (popNum==1)
		root:IMG:Image_CT:=root:IMG:Gray_CT[pmap[p]][q]
	else
	if (popNum==2)
		root:IMG:Image_CT:=root:IMG:RedTemp_CT[pmap[p]][q]
	else
	if (popNum==3)
		root:IMG:CTinvert*=-1
		root:IMG:gamma2=1/root:IMG:gamma2
		if (root:IMG:CTinvert<0)
			PopupMenu SelectCT value="Grayscale;Red Temp;Ã Invert;Rescale"
			SetVariable setgamma limits={0.1,Inf,1}
			SetScale/I x root:IMG:dmax, root:IMG:dmin,"" root:IMG:Image_CT
		else
			PopupMenu SelectCT value="Grayscale;Red Temp;Invert;Rescale"
			SetVariable setgamma limits={0.1,Inf,0.1}
			SetScale/I x root:IMG:dmin, root:IMG:dmax,"" root:IMG:Image_CT
		endif
	else
		AdjustCT()		//Rescale
	endif
	endif
	endif
End


////////    Small process procedures

Proc ConfirmRECT( x1, x2, y1, y2, opt )
//------------
	Variable x1=NumVarOrDefault("root:IMG:x1_crop", 0 ), x2=NumVarOrDefault("root:IMG:x2_crop", 1 )
	Variable y1=NumVarOrDefault("root:IMG:y1_crop", 0 ), y2=NumVarOrDefault("root:IMG:y2_crop", 1 )
	variable opt=1
	prompt opt, "Range option", popup, "None;Full X;Full Y;Full Axes"
	
	if ((opt==2)+(opt==4))
		GetAxis/Q bottom 
		x1=V_min; x2=V_max
	endif
	if ((opt==3)+(opt==4))
		GetAxis/Q left
		y1=V_min; y2=V_max
	endif
	Variable/G root:IMG:x1_crop=x1, root:IMG:x2_crop=x2
	Variable/G root:IMG:y1_crop=y1, root:IMG:y2_crop=y2
End

Proc ConfirmXNorm( x1, x2, opt )			// xrange
//------------
	Variable x1=NumVarOrDefault("root:IMG:x1_norm", 0 )
	Variable x2=NumVarOrDefault("root:IMG:x2_norm", 1 )
	Variable opt=1
	Prompt opt, "Norm Y option:", popup, "None;Full X"
	
	if (opt==2)
		GetAxis/Q bottom 
		x1=V_min; x2=V_max
	endif

	
	Variable/G root:IMG:x1_norm=x1, root:IMG:x2_norm=x2
End

Proc ConfirmYNorm( y1, y2, opt )			// yrange
//------------
	Variable y1=NumVarOrDefault("root:IMG:y1_norm", 0 )
	Variable y2=NumVarOrDefault("root:IMG:y2_norm", 1 )
	Variable opt=1
	Prompt opt, "Norm X option:", popup, "None;Full Y"
	
	if (opt==2)
		GetAxis/Q left
		y1=V_min; y2=V_max
	endif
	Variable/G root:IMG:y1_norm=y1, root:IMG:y2_norm=y2
End

Proc PromptEdge( edgewn, fitedge, fitpos )			// Shift Wave parms
//------------
	String edgewn=StrVarOrDefault("root:IMG:edgen", "" )
	Variable fitedge=NumVarOrDefault("root:IMG:edgefit", 1 )+1
	Variable fitpos=NumVarOrDefault("root:IMG:positionfit", 1 )+1
	prompt edgewn, "Output basename (_e, _w)"
	prompt fitedge, "Edge Detection", popup, "Find;Fit"
	prompt fitpos, "Post-fit Edge Postions", popup, "No;Linear;Quadratic"
	
	String/G root:IMG:edgen=edgewn
	Variable/G root:IMG:edgefit=fitedge-1, root:IMG:positionfit=fitpos-1
End

Proc RescaleImg( xopt, xrang, yopt, yrang  )
//------------
	string xrang=num2str(root:IMG:xmin)+", "+num2str(root:IMG:xmax)+", "+num2str(root:IMG:xinc)
	string yrang=num2str(root:IMG:ymin)+", "+num2str(root:IMG:ymax)+", "+num2str(root:IMG:yinc)
	variable xopt, yopt
	prompt xrang, "X-values:  (min,inc) or (min,max) or (center, inc) or (val)"
	prompt yrang, "Y-values:  (min,inc) or (min,max)  or (center, inc) or (val)"
	prompt xopt, "X-axis Rescaling:", popup, "No Change;Min, Inc;Min, Max;Center, Inc;Cursor=val"
	prompt yopt, "Y-axis Rescaling:", popup, "No Change;Min, Inc;Min, Max;Center, Inc;Cursor=val"
	
	string curr=GetDataFolder(1)
	SetDataFolder root:IMG
	variable nv, vmin, vinc
	variable/C coffset
	
	// globals will get updated later by ImgInfo()
	if (xopt>1) 
		vmin=ValFromList(xrang, 0, ",")
		nv=ItemsInList(xrang,",")
		vinc=xinc
		if (nv>1) 
			vinc=ValFromList(xrang, nv-1, ",")
		endif
		if (xopt==2)
			SetScale/P x vmin, vinc , "" Image
		endif
		if (xopt==3) 
			SetScale/I x vmin, ValFromList(xrang, 1, ","), "" Image
		endif
		if (xopt==4)
			SetScale/P x vmin-0.5*(nx-1)*vinc, vinc , "" Image
		endif
		if (xopt==5)
			coffset=GetWaveOffset(root:IMG:HairY0)
			SetScale/P x xmin-REAL(coffset)+vmin, xinc,"" Image
			ModifyGraph offset(HairY0)={vmin, IMAG(coffset)}
		endif
	endif
	if (yopt>1) 
		vmin=ValFromList(yrang, 0, ",")
		nv=ItemsInList(yrang,",")
		vinc=yinc
		if (nv>1) 
			vinc=ValFromList(yrang, nv-1, ",")
		endif
		if (yopt==2)
			SetScale/P y vmin, vinc , "" Image
		endif
		if (yopt==3) 
			SetScale/I y vmin, ValFromList(yrang, 1, ","), "" Image
		endif
		if (yopt==4)
			SetScale/P y vmin-0.5*(ny-1)*vinc, vinc , "" Image
		endif
		if (yopt==5)
			coffset=GetWaveOffset(root:IMG:HairY0)
			SetScale/P y ymin-IMAG(coffset)+vmin, yinc,"" Image
			ModifyGraph offset(HairY0)={REAL(coffset), vmin}
		endif
	endif
	SetDataFolder curr
End

Proc ResizeImg( xopt, xval,  yopt, yval )
//------------
	variable xopt, yopt
	variable xval=1, yval=1
	prompt xopt, "X-axis:", popup, "No Change;Rebin X;Thin X"
	prompt yopt, "Y-axis:", popup, "No Change;Rebin Y;Thin Y"
	prompt xval, "X number", popup, "2;3;4;5"
	prompt yval, "Y number", popup, "2;3;4;5"
	xval+=1; yval+=1

	string curr=GetDataFolder(1)
	SetDataFolder root:IMG
	variable/C coffset=GetWaveOffset(root:IMG:HairY0)
	
	// globals will get updated later by ImgInfo()
		if (xopt>1) 
		Duplicate/o Image tmp
		variable nx2=round(nx/xval)
		xinc*=xval
		Redimension/N=(nx2, ny) Image
		SetScale/P x xmin, xinc,"" Image
		variable ii=0, jj
		DO
			Image[ii][]=0
			if (xopt==2)				// Rebin X
				jj=0
				Image[ii][]=0
				DO
					Image[ii][]+= tmp[xval*ii+jj][q]
					jj+=1
				WHILE( jj<xval )
				Image[ii][]/=xval
			endif
			if (xopt==3)				// Thin X
				Image[ii][]+=tmp[xval*ii][q]
			endif
			ii+=1
		WHILE( ii<nx2)
	endif
	if (yopt>1) 
		Duplicate/o Image tmp
		variable ny2=trunc(ny/yval)
		yinc*=yval
		Redimension/N=(nx, ny2) Image
		SetScale/P y ymin, yinc,"" Image
		variable ii=0, jj
		DO
			Image[][ii]=0
			if (yopt==2)				// Rebin Y
				jj=0
				Image[][ii]=0
				DO
					Image[][ii]+= tmp[p][yval*ii+jj]
					jj+=1
				WHILE( jj<yval )
				Image[][ii]/=yval
			endif
			if (yopt==3)				// Thin Y
				Image[][ii]+= tmp[p][yval*ii]
			endif
			ii+=1
		WHILE( ii<ny2)
	endif
	SetDataFolder curr
End

Proc ConfirmXAnalysis( x1, x2 )			// xrange
//------------
	Variable x1=NumVarOrDefault("root:IMG:x1_analysis", 0 )
	Variable x2=NumVarOrDefault("root:IMG:x2_analysis", 1 )
	
	Variable/G root:IMG:x1_analysis=x1, root:IMG:x2_analysis=x2
End

////////////////////////

Function AREA2D( img, axis, x1, x2, y0 )
// Used for example by NormY
	
	wave img
	variable axis, x1, x2, y0
	
	axis*=(axis==1)		// make sure 0 or 1 only
	variable nx=DimSize( img, axis)
	make/O/n=(nx) tmp
	SetScale/P x DimOffset(img,axis), DimDelta(img,axis), "" tmp
	tmp=SelectNumber( axis, img(x)( y0), img(y0)(x) )
	
	return area( tmp, x1, x2)
End

Function/C  EDGE2D( img, x1, x2, y0, wfrac )
// Used by FindEdge in Analysis menu
//return complex value {edge postion, edgewidth}

	wave img
	variable x1, x2, y0, wfrac
	
	// extract 1D wave
	variable nx=DimSize( img, 0)
	make/O/n=(nx) root:tmp
	WAVE tmp=root:tmp
	CopyScales img, tmp
	tmp=img(x)( y0)
	
	// coef wave
	EdgeStats/Q/F=(abs(wfrac))/R=(x1, x2) tmp
	variable slope=(V_edgeLvl1-V_edgeLvl0)/(V_edgeLoc1-x1)
	make/O root:FEcoef={ V_edgeLoc2, V_edgeDloc3_1, -V_edgeAmp4_0, V_edgeLvl4, slope}
	WAVE FEcoef=root:FEcoef
	
	if (wfrac<0)		// do fit
		FEcoef[1]=FEcoef[1]/4.
		//FuncFit/Q/N Fermi_Fct FEcoef tmp(x1, x2) /D
		FuncFit/Q/N G_step root:FEcoef root:tmp(x1, x2) /D		// /N supresses updates
		return CMPLX( FEcoef[0],  FEcoef[1] )
	else
		return CMPLX( V_edgeLoc2,  V_edgeDloc3_1 )
	endif
End

Function/C  PEAK2D( img, x1, x2, y0, pkmode )
// Used by FindPeak
//return complex value {peak CENTROID postion, edgewidth}
	wave img
	variable x1, x2, y0, pkmode
	
	// extract line profile
	variable nx=DimSize( img, 0)
	make/O/n=(nx) tmp
	CopyScales img, tmp
	tmp=img(x)( y0)
	WaveStats/Q/R=(x1, x2) tmp
	variable hwlvl=(V_max+V_min)/2, lxhw, rxhw
	FindLevel/Q/R=(x1, x2) tmp, hwlvl
		lxhw=V_levelX
	FindLevel/Q/R=(x2, x1) tmp, hwlvl
		rxhw=V_levelX
	variable pkpos, pkwidth
	//Average between  half-height positions OR Peak max location 
	pkpos=SelectNumber(pkmode, (lxhw+rxhw)/2, V_maxloc)				
	pkwidth=abs(rxhw-lxhw)			//Difference between  half-height positions
	//
	return CMPLX( pkpos,  pkwidth )
End

///////////

Proc Area_Style(ylbl) : GraphStyle
	string ylbl
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z rgb[1]=(0,0,65535),rgb[2]=(0,65535,0)
	ModifyGraph/Z tick=2
	ModifyGraph/Z mirror=1
	ModifyGraph/Z minor=1
	ModifyGraph/Z sep=8
	ModifyGraph/Z fSize=12
	ModifyGraph/Z lblMargin(left)=4
	Label/Z left ylbl
EndMacro


Proc Edge_Style() : GraphStyle
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z mode[1]=4
	ModifyGraph/Z lStyle[1]=2
	ModifyGraph/Z rgb[1]=(0,0,65535),rgb[2]=(0,65535,0)
	ModifyGraph/Z tick=2
	ModifyGraph/Z mirror=1
	ModifyGraph/Z minor=1
	ModifyGraph/Z sep=8
	ModifyGraph/Z fSize=12
	ModifyGraph/Z lblMargin(left)=8
	ModifyGraph/Z standoff(left)=0,standoff(bottom)=0
	ModifyGraph/Z axThick=0.5
	ModifyGraph/Z lblPos(left)=69,lblPos(wid)=68
	ModifyGraph/Z lblLatPos(wid)=2
	ModifyGraph/Z freePos(wid)=0
	ModifyGraph/Z axisEnab(left)={0,0.58}
	ModifyGraph/Z axisEnab(wid)={0.62,1}
	Label/Z left "Edge Position"
	Label/Z wid "Edge Width"
EndMacro

Proc Peak_Style() : GraphStyle
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z mode[1]=4
	ModifyGraph/Z lStyle[1]=2
	ModifyGraph/Z rgb[1]=(0,0,65535)
	ModifyGraph/Z tick=2
	ModifyGraph/Z mirror(bottom)=1
	ModifyGraph/Z minor=1
	ModifyGraph/Z sep=8
	ModifyGraph/Z fSize=12
	ModifyGraph/Z lblMargin(left)=17,lblMargin(right)=6
	ModifyGraph/Z lblLatPos(left)=-1
	Label/Z left "Peak Position"
	Label/Z right "Edge Width"
	SetAxis/Z/A/E=1 right
EndMacro

//////////

function G_step(w, xx)
	wave w
	variable  xx
	variable dx=xx-w[0]
	return( w[3]+w[4]*dx*(dx<0)+w[2]*0.5*erfc(dx/(w[1]/1.66511)) )	
end

Function  Fermi_Fct( w, xx )
// no Gaussian broadening
	wave w
	variable xx
	variable dx=xx-w[0]
	return (w[3]+w[4]*dx*(dx<0)+ w[2]/(exp(dx/w[1])+1) )
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function/T PickStr( promptstr, defaultstr, wvlst )
//------------
	String promptstr, defaultstr
	variable wvlst
	String/G  PickStr0, Promptstr0=promptstr, DefaultStr0=defaultstr
	//string a=""
	if (wvlst==1)
		execute "Pick_Str( \"\", )"
	else
		execute "Pick_Str( , \"\" )"
	endif
	//execute cmd
	return PickStr0
End

Proc Pick_Str( str1, str2 )
//------------
	String str1=DefaultStr0, str2=DefaultStr0
	prompt str1, Promptstr0
	prompt str2, Promptstr0, popup, WaveList("!*_x",";","")
	Silent 1
	String/G PickStr0=str1+str2
End


Function Do_AvgStack(ctrlName) : ButtonControl
	String ctrlName
	nvar NbForAvg=root:Img:stack:NbForAvg
	variable i,Nb_y,start_y,delta_y
	
	SetDataFolder root:IMG
	wave Image
	Duplicate/o Image Image_Undo
	Nb_y=round(Dimsize(Image_undo,1)/NbForAvg)
	delta_y=DimDelta(Image_undo,1)*NbForAvg
	start_y=	DimOffset(Image_undo,1)+	(DimDelta(Image_undo,1)*(NbForAvg-1))/2
	Redimension/N=(Dimsize(Image_undo,0),Nb_y) Image
	delta_y=DimDelta(Image_undo,1)*NbForAvg
	SetScale/P y start_y, delta_y,  Image
	Image=0
	i=0
	do
	    Image+=Image_undo[p][NbForAvg*q+i]
	    i+=1
	while (i<NbForAvg)
	Image/=NbForAvg
	SetVariable setY0,limits={start_y,start_y+(Nb_y-1)*delta_y,delta_y}
	UpdateStack()
end



Function ImageTool_convert(ctrlName) : ButtonControl
	String ctrlName
	//True conversion : uses sin(theta) and not a linear scale but has to extrapolate so changes raw data
	string current=GetDataFolder(1)
	SetDataFolder root:IMG
	Duplicate/O Image Image_undo
	Ask_Transform_Image_True(1)	// in ThetaPhiConversions
	string/G TypeOfImage
	wave profileH_x,profileV_y,Image
	profileH_x[]=dimoffset(image,0)+dimdelta(Image,0)*p
	profileV_y[]=dimoffset(image,1)+dimdelta(Image,1)*p
	SetAxis bottom dimoffset(image,0),dimoffset(image,0)+dimdelta(image,0)*(dimsize(image,0)-1)
	SetAxis left dimoffset(image,1),dimoffset(image,1)+dimdelta(image,1)*(dimsize(image,1)-1)
	SetDataFolder current
end	