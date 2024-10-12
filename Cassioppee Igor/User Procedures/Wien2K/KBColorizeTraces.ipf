#pragma rtGlobals=1		// Use modern global access method.
#pragma moduleName=KBColorizeTraces
#pragma version=6.34	// shipped with Igor 6.34

// Written by Kevin Boyce with tweaks by Howard Rodstein and Jim Prouty.
//
// Version 6.03, JP:	Added Markers and Line Styles Quick Sets
//						Added image plots and value readouts for the Color Wheel sliders.
//						Added Linear Hue checkbox.
//						Now Desaturated colors no longer tend towards pink.
//						Made most functions static.
//
// Version 6.04, JP:	Restored KBColorizeTraces to lightness, saturation, startingHue parameters only (as per Igor 6.02A and earlier),
//						and added KBColorizeTracesLinearHue() with same parameters,
//						and KBColorizeTracesOptLinear(lightness, saturation, startingHue,[useLinearHue]).
//
// Version 6.041, JP:	Works correctly if the current data folder isn't root. Fixes thanks to  "Marcel Graf" <marcel.graf@gmx.ch>
// Version 6.1, JP:		Slider pointers don't overlap the image plots on Windows.
// Version 6.22, JP:		Fixed lstyle wrapping to not skip style 17
// Version 6.34, JP:		Fixed bug in KBColorTablePopMenuProc().
//
// Colorize the waves in the top graph, with given lightness and saturation starting hue.
// Lightness, saturation and starting hue vary between 0 and 1.
// NOTE: lightness and saturation are really cheap approximations.
// For that matter, so is hue, which is a real simple rgb circle.
// Colors are evenly distributed in "hue", except around
// green-blue, where they move more quickly, since color perception
// isn't as good there.  I generally call it with lightness=0.9 and 
// saturation=1.


//------------- Public Routines ----------------------------

Menu "Graph"
	"Make Traces Different", /Q, ShowKBColorizePanel()
End

Function ShowKBColorizePanel()
	DoWindow/F KBColorizePanel
	if (V_Flag == 0)
		CreateKBColorizePanel()
	endif
End


Function CreateKBColorizePanel()

	DoWindow/K KBColorizePanel
	NewPanel /W=(425,56,728,589)/N=KBColorizePanel/K=1 as "Make Traces Different"
	ModifyPanel/W=KBColorizePanel noEdit=1, fixedSize=1
	DefaultGuiFont/W=#/Mac popup={"_IgorMedium",12,0},all={"_IgorMedium",12,0}
	DefaultGuiFont/W=#/Win popup={"_IgorMedium",0,0},all={"_IgorMedium",0,0}
	String topGraph=WinName(0,1)
	if( strlen(topGraph) )
		AutoPositionWindow/M=0/R=$topGraph KBColorizePanel
	endif

	GroupBox markersGroup,pos={10,9},size={280,78},title="Markers Quick Set"
	PopupMenu allMarkers,pos={40,33},size={169,20},proc=KBColorizeTraces#AllMarkersPopMenuProc,title="Reset All Traces To:"
	PopupMenu allMarkers,mode=20,popvalue="",value= #"\"*MARKERPOP*\""
	PopupMenu markersSeries,pos={23,60},size={199,20},proc=KBColorizeTraces#UniqueMarkersPopMenuProc,title="Unique Markers:"
	PopupMenu markersSeries,mode=1,popvalue="All Sequential",value= #"\"All Sequential;All Random;Only Filled;Only Outlined;Only Lines;Only Round;Only Square;Only Diamond;Only Triangle;Only Crosses;\""
	GroupBox lineStylesGroup,pos={10,99},size={280,78},title="Line Styles Quick Set"

	PopupMenu allLineStyles,pos={19,122},size={258,24},proc=KBColorizeTraces#AllLineStylesPopMenuProc,title="Reset All Traces To:"
	PopupMenu allLineStyles,mode=1,bodyWidth= 130,popvalue="",value= #"\"*LINESTYLEPOP*\""
	Button uniqueLineStyles,pos={69,150},size={154,20},proc=KBColorizeTraces#UniqueLineStylesButtonProc,title="Sequential Line Styles"

	GroupBox colorsQuickSetGroup,pos={10,185},size={280,117},title="Colors Quick Set"
	PopupMenu ColorPop,pos={71,210},size={178,24},proc=KBColorizeTraces#ColorizePopMenuProc,title="Reset All Traces To:"
	PopupMenu ColorPop,help={"Sets all traces in the active graph to the color you choose."}
	PopupMenu ColorPop,mode=1,popColor= (0,0,0),value= #"\"*COLORPOP*\""
	PopupMenu ColorTablePop,pos={32,238},size={244,24},proc=KBColorizeTraces#KBColorTablePopMenuProc,title="Set Traces To:"
	PopupMenu ColorTablePop,help={"Sets all traces in the active graph using the entire range of the color table you choose."}
	PopupMenu ColorTablePop,mode=56,bodyWidth= 150,popvalue="",value= #"\"*COLORTABLEPOP*\""
	Button commonColorsButton,pos={71,270},size={175,20},proc=CommonColorsButtonProc,title="Commonly-Used Colors"
	Button commonColorsButton,help={"Sets all traces in the active graph to a range of commonly-used colors. The colors repeat every 10 traces."}

	GroupBox colorWheelGroup,pos={10,307},size={280,220},title="Color Wheel"
	TitleBox hueTitle,pos={26,328},size={73,16},title="Starting Hue",frame=0
	TitleBox saturationTitle,pos={123,328},size={60,16},title="Saturation",frame=0
	TitleBox lightnessTitle,pos={210,328},size={57,16},title="Lightness",frame=0
	// the global variables don't exist until RestoreKBColorizePanelSettings is called, so they're set there, not here
	Slider hueSlider,pos={24,348},size={25,123},proc=KBColorizeTraces#KBJPColorizeSliderProc
	Slider hueSlider,help={"Sets the hue for the first trace. Other trace colors are distributed around the color wheel."}
	Slider hueSlider,limits={0,0.99,0.01},ticks= 0		// ,variable= root:Packages:KBColorize:gStartingHue
	Slider satSlider,pos={120,348},size={25,123},proc=KBColorizeTraces#KBJPColorizeSliderProc
	Slider satSlider,help={"Sets the hue for the first trace. Other trace colors are distributed around the color wheel."}
	Slider satSlider,limits={0.2,1,0.01},ticks= 0	// ,variable= root:Packages:KBColorize:gSaturation
	Slider lightSlider,pos={207,348},size={25,123},proc=KBColorizeTraces#KBJPColorizeSliderProc
	Slider lightSlider,help={"Sets the hue for the first trace. Other trace colors are distributed around the color wheel."}
	Slider lightSlider,limits={0.2,0.9,0.01},ticks= 0	// ,variable= root:Packages:KBColorize:gLightness
	CheckBox linearHue,pos={31,502},size={86,16},proc=KBColorizeTraces#LinearCheckProc,title="Linear Hue "
	//CheckBox linearHue,variable= root:Packages:KBColorize:gLinearHue

	// restore control settings and create globals
	// RestoreKBColorizePanelSettings needs controls, creates the global variables
	RestoreKBColorizePanelSettings()

	ValDisplay hueReadout,pos={46,476},size={33,17},format="%.2f",frame=5
	ValDisplay hueReadout,limits={0,0,0},barmisc={0,1000}
	ValDisplay hueReadout,value= #"root:Packages:KBColorize:gStartingHue"
	ValDisplay hueReadout1,pos={144,476},size={33,17},format="%.2f",frame=5
	ValDisplay hueReadout1,limits={0,0,0},barmisc={0,1000}
	ValDisplay hueReadout1,value= #"root:Packages:KBColorize:gSaturation"
	ValDisplay hueReadout2,pos={232,476},size={33,17},format="%.2f",frame=5
	ValDisplay hueReadout2,limits={0,0,0},barmisc={0,1000}
	ValDisplay hueReadout2,value= #"root:Packages:KBColorize:gLightness"
	
	// UpdateHueTicks needs globals, creates images
	UpdateHueTicks()

	// Create image subwindows

	DefineGuide UGH0={FT,357},UGH1={FT,462}
	Display/W=(52,170,82,295)/FG=(,UGH0,,UGH1)/HOST=KBColorizePanel
	AppendImage/T root:Packages:KBColorize:hueRGBImage
	ModifyImage hueRGBImage ctab= {*,*,Grays,0}
	ModifyGraph userticks(left)={root:Packages:KBColorize:hueTicks,root:Packages:KBColorize:hueTickLabels}
	ModifyGraph userticks(top)={root:Packages:KBColorize:hueTicks,root:Packages:KBColorize:hueTickLabels}
	ModifyGraph margin(left)=-1,margin(bottom)=-1,margin(top)=-1,margin(right)=-1
	ModifyGraph tick=2
	ModifyGraph mirror=0
	ModifyGraph nticks=10
	ModifyGraph noLabel=2
	ModifyGraph standoff=0
	ModifyGraph axThick(left)=0
	SetAxis/A/R left
	ModifyGraph swapXY=1
	RenameWindow #,G0
	SetActiveSubwindow ##
	Display/W=(147,172,177,293)/FG=(,UGH0,,UGH1)/HOST=# 
	AppendImage/T root:Packages:KBColorize:satRGBImage
	ModifyImage satRGBImage ctab= {*,*,Grays,0}
	ModifyGraph margin(left)=-1,margin(bottom)=-1,margin(top)=-1,margin(right)=-1
	ModifyGraph mirror=0
	ModifyGraph nticks=0
	ModifyGraph noLabel=2
	ModifyGraph standoff=0
	ModifyGraph axThick=0
	SetAxis/A/R left
	ModifyGraph swapXY=1
	RenameWindow #,G1
	SetActiveSubwindow ##
	Display/W=(233,173,261,295)/FG=(,UGH0,,UGH1)/HOST=# 
	AppendImage/T root:Packages:KBColorize:lightRGBImage
	ModifyImage lightRGBImage ctab= {*,*,Grays,0}
	ModifyGraph margin(left)=-1,margin(bottom)=-1,margin(top)=-1,margin(right)=-1
	ModifyGraph mirror=0
	ModifyGraph nticks=0
	ModifyGraph noLabel=2
	ModifyGraph standoff=0
	ModifyGraph axThick=0
	SetAxis/A/R left
	ModifyGraph swapXY=1
	RenameWindow #,G2
	SetActiveSubwindow ##
	
	SetWindow kwTopWin,hook(KBColorize)=KBColorizeTraces#KBColorizePanelHook
End


//-------------- Private (static) Routines ---------------------------

static Function KBColorizePanelHook(s)
	STRUCT WMWinHookStruct &s

	Variable statusCode= 0
	strswitch(s.eventName)
		case "kill":
			StoreKBColorizeSettings()
			Execute/P "DELETEINCLUDE <KBColorizeTraces>"
			Execute/P "COMPILEPROCEDURES "
			break
		case "activate":
			UpdateHueTicks()
			break
	endswitch
	return statusCode		// 0 if nothing done, else 1
End


Function KBColorizeTracesOptLinear(lightness, saturation, startingHue,[useLinearHue])
	Variable lightness, saturation, startingHue	// 0-1
	Variable useLinearHue		// optional boolean. If false, use "warped" hue, new parameter for 6.03
	
	if( ParamIsDefault(useLinearHue) )
		useLinearHue= 0
	endif
	
	Variable traceIndex, numTraces
	
	numTraces = KBTracesInGraph("")
	if (numTraces <= 0)
		return 0
	endif
	
	for( traceIndex= 0; traceIndex < numTraces; traceIndex += 1 )
		Variable hue= mod(startingHue + traceIndex/numTraces, 1)	// 0-1
		if( !useLinearHue )
			hue= GetKBHueFromLinearHue(hue)	// 0-1
		endif
		Variable red, green, blue
		KBHSLToRGB(hue*65535, saturation*65535, lightness*65535, red, green, blue)
		ModifyGraph/Z rgb[traceIndex]=(red, green, blue)
	endfor

	return numTraces
End

Function KBColorizeTraces(lightness, saturation, startingHue)
	Variable lightness, saturation, startingHue	// 0-1

	return KBColorizeTracesOptLinear(lightness, saturation, startingHue)
End


Function KBColorizeTracesLinearHue(lightness, saturation, startingHue)
	Variable lightness, saturation, startingHue	// 0-1
	
	return KBColorizeTracesOptLinear(lightness, saturation, startingHue, useLinearHue=1)
End

static Constant ksNumDemoColors= 100

static Function CreateHSLImages(useLinearHue, startHue, sat, light)
	Variable useLinearHue		// boolean. If false, use "warped" hue
	Variable startHue, sat, light	// 0...1, startHue is a linear index into the HSL space
	
	NewDataFolder/O  root:Packages
	NewDataFolder/O  root:Packages:KBColorize

	// make hue image
	Make/O/N=(ksNumDemoColors,1,3)/U/W root:Packages:KBColorize:hueRGBImage
	WAVE/U/W hueRGBImage= root:Packages:KBColorize:hueRGBImage
	SetScale x, 0, 1, "", hueRGBImage
	if( useLinearHue )
		hueRGBImage[][][0] = mod(0+p*65535/ksNumDemoColors, 65535)	// varying hues. since we distribute them differently, we should modify this as per KB
	else
		// Colors are evenly distributed in "hue", except around
		// green-blue, where they move more quickly, since color perception isn't as good there. 
		// those colors are centered at Hue = 0.7 and Hue=0.35
		hueRGBImage[][][0] = limit(GetKBHueFromLinearHue(p/ksNumDemoColors)*65535,0,65535)// varying hues. since we distribute them differently, we should modify this as per KB
	endif
	hueRGBImage[][][1] = limit(sat*65535,0,65535)		// constant saturation
	hueRGBImage[][][2] = limit(light*65535,0,65535)	// constant lightness
	ImageTransform/O hsl2rgb hueRGBImage		// converts 0...65535 HSL values to 0...65535 /U/W RGB values
	
	// NOTE: ONLY the Hue image is capable of showing the colors of all the traces 
	// (since only that image has both saturation and lightness held constant).
	
	// Add user-defined ticks to the image plot #G0 right axis (remember the X and Y axes are swapped)
	// to indicate the chosen colors.
	Variable numTraces = KBTracesInGraph("")
	Make/O/N=(numTraces) root:Packages:KBColorize:hueTicks= mod(startHue+p/numTraces,1)
	Make/O/N=(numTraces)/T root:Packages:KBColorize:hueTickLabels= ""	// to make user ticks happy
	
	if( !useLinearHue )
		startHue= GetKBHueFromLinearHue(startHue)
	endif
	// make saturation image from 0.2 to 1
	Make/O/N=(ksNumDemoColors,1,3)/U/W root:Packages:KBColorize:satRGBImage
	WAVE/U/W satRGBImage= root:Packages:KBColorize:satRGBImage
	satRGBImage[][][0] =  mod(startHue*65535, 65535)	// constant hue
	satRGBImage[][][1] = (0.2 + 0.8*p/ksNumDemoColors)*65535		// increasing saturation
	satRGBImage[][][2] = limit(light*65535,0,65535)	// constant lightness
	ImageTransform/O hsl2rgb satRGBImage	

	// make lightness image	range from 0.2 to 0.9
	Make/O/N=(ksNumDemoColors,1,3)/U/W root:Packages:KBColorize:lightRGBImage
	WAVE/U/W lightRGBImage= root:Packages:KBColorize:lightRGBImage
	lightRGBImage[][][0] =  mod(startHue*65535, 65535)	// constant hue
	lightRGBImage[][][1] = limit(sat*65535,0,65535)		// constant saturation
	lightRGBImage[][][2] = (0.2 +0.7*p/ksNumDemoColors)*65535	// increasing lightness
	ImageTransform/O hsl2rgb lightRGBImage	
End


// Find the number of traces on the top graph
static Function KBTracesInGraph(win)	// "" for top graph
	String win
	
	if( strlen(win) == 0 )
		win= WinName(0,1)
		if( strlen(win) == 0 )
			return 0
		endif
	endif
	return ItemsInList(TraceNameList(win,";",3))
End


// GetKBHueFromLinearHue warps the hue space to accomplish this goal:
// Colors are evenly distributed in "hue", except around
// green-blue, where they move more quickly, since color perception isn't as good there. 
// those colors are centered at Hue = 0.7 and Hue=0.35

static Function GetKBHueFromLinearHue(linearHue)
	Variable linearHue // 0-1
	
	Variable red, green, blue
	KBGetColorRGB( 0.5, 1, linearHue, red, green, blue)

	Variable warpedHue, sat, light
	
	KBRGBToHSL(red, green, blue, warpedHue, sat, light)

	return warpedHue/65535	// 0-1
End

// convert RGB to HSL
static Function KBRGBToHSL(red, green, blue, hue, sat, light)
	Variable red, green, blue	// inputs, 0-65535
	Variable &hue, &sat, &light	// outputs, 0-65535

	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:KBColorize
	Make/O/N=(1,1,3)/U/W root:Packages:KBColorize:rgbhsl
	WAVE rgbhsl=root:Packages:KBColorize:rgbhsl
	rgbhsl[0][0][0]= round(red)
	rgbhsl[0][0][1]= round(green)
	rgbhsl[0][0][2]= round(blue)
	
	ImageTransform/O rgb2hsl rgbhsl
	
	hue=rgbhsl[0][0][0]*257		// 0-65535
	sat=rgbhsl[0][0][1]*257		// 0-65535
	light= rgbhsl[0][0][2]*257	// 0-65535
End

// convert HSL to RGB:
static Function KBHSLToRGB(hue, sat, light, red, green, blue)
	Variable hue, sat, light	// inputs, 0-65535
	Variable &red, &green, &blue	// outputs, 0-65535

	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:KBColorize
	Make/O/N=(1,1,3)/U/W root:Packages:KBColorize:rgbhsl
	WAVE rgbhsl= root:Packages:KBColorize:rgbhsl
	rgbhsl[0][0][0]= hue
	rgbhsl[0][0][1]= sat
	rgbhsl[0][0][2]= light
	ImageTransform/O hsl2rgb rgbhsl
	red=rgbhsl[0][0][0]	// 0-65535
	green=rgbhsl[0][0][1]	// 0-65535
	blue= rgbhsl[0][0][2]	// 0-65535
End


static Function KBGetColorRGB( lightness, saturation, ratio, red, green, blue )
	Variable lightness, saturation	// 0-1
	Variable ratio // 0-1, really a hue
	Variable &red, &green, &blue	// outputs, 0-65535
	
	Variable rmin, rmax, gmin, gmax, bmin,bmax, phi, r,g,b

	bmax = 65535*lightness
	bmin = 65535*max(min((lightness-saturation), 1), 0)
	
	// Reduce red and green maximum values, since red is brighter
	// than blue, and green is brighter still.  This started out using
	// CIE values, but that didn't look good, so it's just empirical now.
	rmin = bmin/1; rmax = bmax/1
	gmin = bmin/1.5; gmax = bmax/1.5
	
	phi= ratio * ((2*PI)-1)		// phi will determine the "hue".
	
	// Make phi move faster between 1.5 and 2.5, since color
	// sensitivity is less in that region.
	if( phi > 2.5 )
		phi += 1
	else
		if( phi > 1.5 )
			phi += (phi-1.5)
		endif
	endif
	
	// Calculate r, g, and b
	if( phi < 2*PI/3 ) 
		red= rmin + (rmax-rmin)*(1+cos(phi))/2
		green=  gmin + (gmax-gmin)*(1+cos(phi-2*PI/3))/2
		blue= bmin
	else
		if( phi < 4*PI/3 )
			red= rmin
			green= gmin + (gmax-gmin)*(1+cos(phi-2*PI/3))/2
			blue= bmin + (bmax-bmin)*(1+cos(phi-4*PI/3))/2
		else
			red= rmin + (rmax-rmin)*(1+cos(phi))/2
			green= gmin
			blue= bmin + (bmax-bmin)*(1+cos(phi-4*PI/3))/2
		endif
	endif
End

static Function UpdateColors()

	UpdateHueTicks()

	String graphName = WinName(0, 1)
	if ( strlen(graphName))
		NVAR saturation = root:Packages:KBColorize:gSaturation
		NVAR lightness = root:Packages:KBColorize:gLightness
		NVAR startingHue = root:Packages:KBColorize:gStartingHue
		NVAR linearHue = root:Packages:KBColorize:gLinearHue
		KBColorizeTracesOptLinear(lightness, saturation, startingHue,useLinearHue=linearHue)
	endif
End

Static Function UpdateHueTicks()

	NVAR saturation = root:Packages:KBColorize:gSaturation
	NVAR lightness = root:Packages:KBColorize:gLightness
	NVAR startingHue = root:Packages:KBColorize:gStartingHue
	NVAR linearHue = root:Packages:KBColorize:gLinearHue
	
	CreateHSLImages(linearHue, startingHue, saturation, lightness)
End

static Function KBJPColorizeSliderProc(name, value, event) : SliderControl
	String name
	Variable value
	Variable event
	
	UpdateColors()
End

static Function LinearCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	UpdateColors()
End

//	StoreKBColorizeSettings()
//	Stores the state of the control panel settings in global variables in the
//	KBColorizePanel data folder.
static Function StoreKBColorizeSettings()

	String savedDataFolder = GetDataFolder(1)
	
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S :KBColorize
	
	// Markers Quick Set
	ControlInfo/W=KBColorizePanel allMarkers
	Variable/G gAllMarkersMenuItem= V_Value

	ControlInfo/W=KBColorizePanel markersSeries
	Variable/G gUniqueMarkersMenuItem= V_Value

	// Line Styles Quick Set
	ControlInfo/W=KBColorizePanel allLineStyles
	Variable/G gAllLineStylesMenuItem= V_Value
	
	// Colors Quick Set
	
	ControlInfo/W=KBColorizePanel ColorPop
	Variable/G gPopRed = V_red
	Variable/G gPopGreen = V_green
	Variable/G gPopBlue = V_blue

	ControlInfo/W=KBColorizePanel ColorTablePop
	String/G gColorTableName= S_value
	
	// Color Wheel
	// gStartingHue, gSaturation, gLightness and gLinearHue
	// global variables are set directly by their controls.

	SetDataFolder savedDataFolder
End

static Function RestoreKBColorizePanelSettings()

	String savedDataFolder = GetDataFolder(1)
	
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S :KBColorize

	// Markers Quick Set
	NVAR/Z menuItem = gAllMarkersMenuItem
	if (NVAR_Exists(menuItem))
		PopupMenu allMarkers,win=KBColorizePanel, mode=menuItem
	endif

	NVAR/Z menuItem = gUniqueMarkersMenuItem
	if (NVAR_Exists(menuItem))
		PopupMenu markersSeries,win=KBColorizePanel, mode=menuItem
	endif

	// Line Styles Quick Set
	NVAR/Z menuItem = gAllLineStylesMenuItem
	if (NVAR_Exists(menuItem))
		PopupMenu allLineStyles,win=KBColorizePanel, mode=menuItem
	endif

	// Colors Quick Set
	NVAR/Z popRed = gPopRed
	NVAR/Z popGreen = gPopGreen
	NVAR/Z popBlue = gPopBlue
	if (NVAR_Exists(popRed))
		PopupMenu colorPop,win=KBColorizePanel, popColor=(popRed,popGreen,popBlue)
	endif

	SVAR/Z colorTableName = gColorTableName
	if (SVAR_Exists(colorTableName))
		Variable ctableMenuItem= 1+WhichListItem(colorTableName, CTabList())
		PopupMenu colorTablePop,win=KBColorizePanel, mode=ctableMenuItem
	endif

	// Color Wheel
	NVAR/Z startingHue = gStartingHue
	if (!NVAR_Exists(startingHue))
		Variable/G gStartingHue= 0
	endif
	Slider hueSlider,win=KBColorizePanel,variable= root:Packages:KBColorize:gStartingHue
	
	NVAR/Z linearHue= gLinearHue
	if (!NVAR_Exists(linearHue))
		Variable/G gLinearHue= 0
	endif
	CheckBox linearHue,win=KBColorizePanel,variable= root:Packages:KBColorize:gLinearHue

	NVAR/Z saturation = gSaturation
	if (!NVAR_Exists(saturation))
		Variable/G gSaturation= 1
	endif
	Slider satSlider,win=KBColorizePanel,variable= root:Packages:KBColorize:gSaturation
	
	NVAR/Z lightness = gLightness
	if (!NVAR_Exists(lightness))
		Variable/G gLightness= 0.5
	endif
	Slider lightSlider,win=KBColorizePanel,variable= root:Packages:KBColorize:gLightness
	
	ControlUpdate/W=KBColorizePanel/A
	
	SetDataFolder savedDataFolder
End

Static Function ColorizePopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	String graphName = WinName(0, 1)
	if (strlen(graphName) == 0)
		return -1
	endif
	
	StoreKBColorizeSettings()	

	ControlInfo $ctrlName				// Another way: sets V_Red, V_Green, V_Blue
	ModifyGraph rgb=(V_Red, V_Green, V_Blue)
End

Function CommonColorsButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	String graphName = WinName(0, 1)
	if (strlen(graphName) == 0)
		return -1
	endif
	
	Variable numTraces = KBTracesInGraph("")

	if (numTraces <= 0)
		return -1
	endif

	Variable red, green, blue
	Variable i, index
	for(i=0; i<numTraces; i+=1)
		index = mod(i, 10)				// Wrap after 10 traces.
		switch(index)
			case 0:
				red = 0; green = 0; blue = 0;
				break

			case 1:
				red = 65535; green = 16385; blue = 16385;
				break
				
			case 2:
				red = 2; green = 39321; blue = 1;
				break
				
			case 3:
				red = 0; green = 0; blue = 65535;
				break
				
			case 4:
				red = 39321; green = 1; blue = 31457;
				break
				
			case 5:
				red = 48059; green = 48059; blue = 48059;
				break
				
			case 6:
				red = 65535; green = 32768; blue = 32768;
				break
				
			case 7:
				red = 0; green = 65535; blue = 0;
				break
				
			case 8:
				red = 16385; green = 65535; blue = 65535;
				break
				
			case 9:
				red = 65535; green = 32768; blue = 58981;
				break
		endswitch
		ModifyGraph rgb[i]=(red, green, blue)
	endfor
End

static Function/S KBColorTabWave(ctabName)
	String ctabName
	
	String savedDataFolder= GetDatafolder(1)
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S :KBColorize

	ColorTab2Wave $ctabname	// creates M_colors
	Wave M_colors
	SetDataFolder savedDataFolder
	return GetWavesDataFolder(M_colors,2)
End

static Function KBColorTablePopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	StoreKBColorizeSettings()	

	String graphName = WinName(0, 1)
	if (strlen(graphName) == 0)
		return -1
	endif

	Variable numTraces =KBTracesInGraph(graphName)
	if (numTraces <= 0)
		return -1
	endif
	
   Variable denominator= numTraces-1
   if( denominator < 1 )
       denominator= 1    // avoid divide by zero, use just the first color for 1 trace
   endif

	Wave rgb= $KBColorTabWave(popStr)
	Variable numRows= DimSize(rgb,0)
	Variable red, green, blue
	Variable i, index
	for(i=0; i<numTraces; i+=1)
		index = round(i/denominator * (numRows-1))	// spread entire color range over all traces.
		ModifyGraph rgb[i]=(rgb[index][0], rgb[index][1], rgb[index][2])
	endfor
End

static Function AllMarkersPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	StoreKBColorizeSettings()	
	ModifyGraph marker=(popNum-1)
End

static Function UniqueMarkersPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	StoreKBColorizeSettings()	

	Variable numTraces = KBTracesInGraph("")
	if (numTraces <= 0)
		return -1
	endif

//value= #"\"All;Only Filled;Only Outlined;Only Lines;Only Round;Only Square;Only Diamond;Only Triangle;Only Crosses;Random;\""

	String df= GetDataFolder(1)
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S root:Packages:KBColorize

	strswitch(popStr)
		case "All Sequential":
				Make/O/N=51 markers=p
				break
		case "All Random":
				Make/O/N=51 markers=p, key=enoise(1)
				Sort key, markers
				break
		case "Only Filled":
				Make/O markers={19,16,17,23,46,49,26,29,18,32,34,36,38,15,14}
				break
		case "Only Outlined":
				Make/O markers={8,5,6,22,45,48,25,28,7,41,13,44,24,47,50,27,30,40,42,11,31,33,4,3,43,12,35,37}
				break
		case "Only Lines":
				Make/O markers={0,1,2,9,10,20,21,39}
				break
		case "Only Round":
				Make/O markers={8,19,41,42,43}
				break
		case "Only Square":
				Make/O markers={5,16,13,11,12}
				break
		case "Only Diamond":
				Make/O markers={7,18,40,25,26,27,28,29,30}
				break
		case "Only Triangle":
				Make/O markers={6,22,45,48,17,23,46,46,44,24,47,50}
				break
		case "Only Crosses":
				Make/O markers={1,0,2,39,12,11,43,42}
				break
	endswitch
	Wave markers
	Variable numMarkers= numpnts(markers)
	SetDataFolder df

	Variable i, row
	for(i=0; i<numTraces; i+=1)
		row = mod(i, numMarkers)	// repeat if we run out of markers
		ModifyGraph marker[i]=markers[row]
	endfor

End

static Function AllLineStylesPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	StoreKBColorizeSettings()	

	Variable numTraces = KBTracesInGraph("")
	if (numTraces <= 0)
		return -1
	endif
	Variable i
	for(i=0; i<numTraces; i+=1)
		ModifyGraph lstyle[i]=popNum-1
	endfor

End

static Function UniqueLineStylesButtonProc(ctrlName) : ButtonControl
	String ctrlName

	StoreKBColorizeSettings()	

	Variable numTraces = KBTracesInGraph("")
	if (numTraces <= 0)
		return -1
	endif
	Variable i
	for(i=0; i<numTraces; i+=1)
		Variable lstyle= mod(i,18)
		ModifyGraph lstyle[i]=lstyle
	endfor
End