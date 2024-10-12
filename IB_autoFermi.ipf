#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// A set of routines to automatically detect & fit Fermi edges.
//
// Ilya, June 2018

Function/S IB_smooth_by_avg(theWave,halfWidth)

	Wave theWave
	Variable halfWidth // Smoothing parameter

	String theWaveAvgStr = GetWavesDataFolder(theWave,2) + "_avg" // NameOfWave(theWave)	
	Duplicate/O theWave, $theWaveAvgStr
	Wave theWaveAvg = $theWaveAvgStr
	
	theWaveAvg[0,halfWidth-1] = sum(theWave,pnt2x(theWave,0),pnt2x(theWave,2*halfWidth))/(2*halfWidth+1)
	theWaveAvg[halfWidth,DimSize(theWave,0)-1-halfWidth-1] = sum(theWave,pnt2x(theWave,p-halfWidth),pnt2x(theWave,p+halfWidth))/(2*halfWidth+1)
	theWaveAvg[DimSize(theWave,0)-1-halfWidth,DimSize(theWave,0)-1] = sum(theWave,pnt2x(theWave,DimSize(theWave,0)-1-2*halfWidth),pnt2x(theWave,DimSize(theWave,0)-1))/(2*halfWidth+1)
	
	Return theWaveAvgStr
	
End


Function/S IB_guess_fermi(DC)

	Wave DC
	String DCstr = GetWavesDataFolder(DC,2)	

	String paramDump_s = "IB_guess_fermi: " + date() + " at " + time() + "\r"

	Variable verbose = 1
	
	// Use a FindLevel approach -- assumes that larger binding energies move above the Fermi level (20210125)
	Variable searchThreshold = 1
	
	// Settings -- in practice you need to change these rather often... It is not very autonomous.
	Variable halfWidth = 3 // smoothing parameter
	Variable numDifs = 3 // number of times to differentiate, as of 20191027 only the 1st deriv is actually used later by the program
	Variable stepWidth = 2 // determines the width of the drop
	Variable tolDCfactor = 4 // needed for choosing the half maximum of the peak associated with the Fermi level, larger means more sensitive

	paramDump_s = paramDump_s + "halfWidth = " + num2str(searchThreshold) + "\r"
	paramDump_s = paramDump_s + "halfWidth = " + num2str(halfWidth) + "\r"
	paramDump_s = paramDump_s + "numDifs = " + num2str(1) + "\r"
	paramDump_s = paramDump_s + "stepWidth = " + num2str(stepWidth) + "\r"
	paramDump_s = paramDump_s + "tolDCfactor = " + num2str(tolDCfactor) + "\r"

	// Optional cheating parameters to restrict the energy window of the Fermi level search
	Variable cheatRange = 1 // 1 or 0
	Variable cheatRange_start = -0.15
	Variable cheatRange_stop = 0.05

	paramDump_s = paramDump_s + "cheatRange = " + num2str(cheatRange) + "\r"
	paramDump_s = paramDump_s + "cheatRange_start = " + num2str(cheatRange_start) + "\r"
	paramDump_s = paramDump_s + "cheatRange_stop = " + num2str(cheatRange_stop) + "\r"

	// 20191027 Attempt to make the program smarter by assuming that the counts above the Fermi edge are 'low' -- haven't finished this yet!
	Variable avg = mean(DC);

	IB_smooth_by_avg(DC, halfWidth)
	String DCavgstr = DCstr + "_avg"
	Wave DCavg = $DCavgstr

	// Differentiate some number of times
	String DCdifstr = DCstr + "_dif"
	String DCdifnstr = DCstr + "_difn" // the nth derivative, set by numDifs above
	Variable i
	for (i = 0; i < numDifs; i += 1)
		if (i == 0)
			Differentiate DCavg /D=$DCdifstr
			Wave DCdif = $DCdifstr
			
			// Remove artifacts due to smoothing
			DCdif[0,i*2*halfWidth] = 0
			DCdif[DimSize(DCdif,0)-i*2*halfWidth-1,DimSize(DCdif,0)-1] = 0

			// Re-smooth
			String DCdifavgstr = IB_smooth_by_avg(DCdif, halfWidth)
			Wave DCdifavg = $DCdifavgstr
		else
			Differentiate DCdifavg /D=$DCdifnstr
			Wave DCdifn = $DCdifnstr

			// Remove artifacts due to smoothing
			DCdifn[0,i*2*halfWidth] = 0
			DCdifn[DimSize(DCdifn,0)-i*2*halfWidth-1,DimSize(DCdifn,0)-1] = 0

			// Re-smooth
			String DCdifnavgstr = IB_smooth_by_avg(DCdifn, halfWidth)
			Wave DCdifnavg = $DCdifnavgstr
		endif
	endfor	

	if (0) // Blocked-out 20191027, not needed
	// Remove artifacts due to smoothing
	DCdif[0,(numDifs - 1)*2*halfWidth] = 0
	DCdif[DimSize(DCdif,0)-(numDifs - 1)*2*halfWidth-1,DimSize(DCdif,0)-1] = 0
	endif

	// Take a guess at the Fermi level energy	
	String DCabsstr = DCstr + "_abs"
	Duplicate /O DCdif, $DCabsstr
	Wave DCabs = $DCabsstr

	// An idea for a more sophisticated approach 20191027, didn't finish
	// Compute a rolling average, stop when you reach a local maximum
	// Compute a FWHM-type quantity for the local maximum and compare the averages
	// on either side of the local maximum
	// One of the averages should be less than the global average of the DC
	// If both are above, then we have probably not found the Fermi level and we should keep scanning 

	DCabs[] = abs(DCdif[p])
	// DCabs[] = abs(DCdifavg[p])
	Variable maxDC
	
	// Specified search range
	if (cheatRange)
		maxDC = WaveMax(DCabs,cheatRange_start,cheatRange_stop)
	
	// Try to get a search range using FindLevel
	elseif (searchThreshold)	
	
		Variable ignore_ends_fraction = 0.1 // ignore the first and last 10% of the DC
		Variable threshold_avg_fraction = 0.05 // significant counts = 10% or 5% or w/e of the average counts
		Variable search_range_fraction = 0.05 // get the derivative max within +/-5% of V_LevelX reported by FindLevel
		
		Variable start_level_index = ignore_ends_fraction*DimSize(DC,0)
		Variable end_level_index = (1-ignore_ends_fraction)*DimSize(DC,0)
		Variable avg_level = threshold_avg_fraction*sum(DC)/DimSize(DC,0)

		// searching from top down here (high energy to low energy) -- this is not robust...
		//	i.e. assuming that larger binding energies move above the Fermi level
		FindLevel /B=50 /Q /EDGE=0 /R=[end_level_index,start_level_index] DC, avg_level

		Variable searchRange_start = V_LevelX - search_range_fraction*(DimSize(DC,0)*DimDelta(DC,0))
		Variable searchRange_stop = V_LevelX + search_range_fraction*(DimSize(DC,0)*DimDelta(DC,0))		
		
		maxDC = WaveMax(DCabs,searchRange_start,searchRange_stop)
		
	// Search the full range
	else
	
		maxDC = WaveMax(DCabs)
	
	endif

	paramDump_s = paramDump_s + "maxDC = " + num2str(maxDC) + "\r"
	
	//	print maxDC
	
	Variable tolDC // = maxDC/10e6;
	FindValue /T=(tolDC) /V=(maxDC) DCabs
	Variable guess_ef_loc = V_value
	Variable guess_ef = pnt2x(DC,V_value)

	paramDump_s = paramDump_s + "guess_ef_loc = " + num2str(guess_ef_loc) + "\r"
	paramDump_s = paramDump_s + "guess_ef = " + num2str(guess_ef) + "\r"
	
	// Make a guess for the linear regions above and below EF	
	tolDC = maxDC/tolDCfactor;
	FindValue /T=(tolDC) /S=(guess_ef_loc) /V=(maxDC/2) DCabs
	if (V_value == - 1)
		print "IB_guess_fermi: blahhahahahahahhahah!!!!" 
		abort
	endif
	Variable drop_width = stepWidth*abs(guess_ef_loc - V_value)

	paramDump_s = paramDump_s + "drop_width = " + num2str(drop_width) + "\r"

//	print guess_ef_loc
//	print V_value
//	print drop_width

	Variable start_drop = guess_ef_loc - drop_width
	Variable end_drop = guess_ef_loc + drop_width

	if (start_drop < 0)
		start_drop = 0
	endif
	
	if (end_drop > DimSize(DC,0) - 1)
		end_drop = DimSize(DC,0) - 1
	endif
	
	paramDump_s = paramDump_s + "start_drop = " + num2str(start_drop) + "\r"
	paramDump_s = paramDump_s + "end_drop = " + num2str(end_drop) + "\r"
	
	Variable start_fit	= start_drop - drop_width
	Variable/G IB_autoFermi_start_fit_var = start_fit
	if (start_fit < 0)
		start_fit = 0
	endif
	
	Variable end_fit = end_drop + drop_width
	Variable/G IB_autoFermi_end_fit_var = end_fit
	if (end_fit > DimSize(DC,0) - 1)
		end_fit = DimSize(DC,0) - 1
	endif
	
	paramDump_s = paramDump_s + "start_fit = " + num2str(start_fit) + "\r"
	paramDump_s = paramDump_s + "end_fit = " + num2str(end_fit) + "\r"

	// If the energy range is rather small and "stepWidth" is large (set at 3 or something like that), then
	// start_fit and start_drop can end up both being zero (similarly for end_drop, end_fit)
	// This problem encountered: 20181215 for root:CSS1:CSS1_452_DC, SSRL 5-2 July 2018 with stepWidth = 3
	
	// Avoid this with a simple hack:
	
	if (start_fit == 0 && start_drop == 0)
		start_drop = abs(guess_ef_loc - V_value) 
	endif
	 
	if (end_drop == (DimSize(DC,0) - 1) && end_fit == (DimSize(DC,0) - 1))
		end_drop = DimSize(DC,0) - 1 - abs(guess_ef_loc - V_value) 
	endif

	Variable top_slope = (DC[start_fit] - DC[start_drop])/(pnt2x(DC,start_fit) - pnt2x(DC,start_drop))
	Variable top_intercept = DC[start_fit] - pnt2x(DC,start_fit)*top_slope
	Variable bottom_slope = (DC[end_drop] - DC[end_fit])/(pnt2x(DC,end_drop) - pnt2x(DC,end_fit))
	Variable bottom_intercept = DC[end_drop] - pnt2x(DC,end_drop)*bottom_slope

	paramDump_s = paramDump_s + "top_slope = " + num2str(top_slope) + "\r"
	paramDump_s = paramDump_s + "top_intercept = " + num2str(top_intercept) + "\r"
	paramDump_s = paramDump_s + "bottom_slope = " + num2str(bottom_slope) + "\r"
	paramDump_s = paramDump_s + "bottom_intercept = " + num2str(bottom_intercept) + "\r"

	// Generate a coefficient guess wave for the Fermi fit
	String coeffGstr = DCstr + "_coeffG"
	Make /D/O/N=6 $coeffGstr
	Wave coeffG = $coeffGstr
	coeffG[0] = guess_ef
	coeffG[1] = DimDelta(DC,0)*drop_width/10
	if ((DCdif[guess_ef_loc] < 0 && DimDelta(DC,0) > 0) || (DCdif[guess_ef_loc] > 0 && DimDelta(DC,0) < 0))
		coeffG[2] = top_slope
		coeffG[3] = top_intercept
		coeffG[4] = bottom_slope
		coeffG[5] = bottom_intercept
	else
		coeffG[4] = top_slope
		coeffG[5] = top_intercept
		coeffG[2] = bottom_slope
		coeffG[3] = bottom_intercept
	endif

	String DCguessstr = DCstr + "_guess"
	Duplicate /O DC, $DCguessstr
	Wave DCguess = $DCguessstr
	DCguess = (coeffG[2]*x + coeffG[3])/(exp((x-coeffG[0])/coeffG[1]) + 1) + (coeffG[4]*x + coeffG[5])
	//DCguess = (coeffG[4]*x + coeffG[5])/(exp((x-coeffG[0])/coeffG[1]) + 1) + (coeffG[2]*x + coeffG[3])
	//DCguess = (10^8)/(exp((x-coeffG[0])/coeffG[1]) + 1)

	if (verbose)
		String diagStr = "IB_autoFermi"
		Variable vertline_max = max(WaveMax(DC),WaveMax(DCavg),WaveMax(DCdif),WaveMax(DCabs))
		Variable vertline_min = min(WaveMin(DC),WaveMin(DCavg),WaveMin(DCdif),WaveMin(DCabs))

		Make /O/N=(2,2) $(diagStr + "_guess_ef")
		Wave guess_ef_indicator = $(diagStr + "_guess_ef")
		guess_ef_indicator[][0] = guess_ef
		guess_ef_indicator[0][1] = vertline_max
		guess_ef_indicator[1][1] = vertline_min

		Make /O/N=(2,2) $(diagStr + "_start_fit")
		Wave start_fit_indicator = $(diagStr + "_start_fit")
		start_fit_indicator[][0] = DimOffset(DC,0) + start_fit*DimDelta(DC,0)
		start_fit_indicator[0][1] = vertline_max
		start_fit_indicator[1][1] = vertline_min

		Make /O/N=(2,2) $(diagStr + "_end_fit")
		Wave end_fit_indicator = $(diagStr + "_end_fit")
		end_fit_indicator[][0] = DimOffset(DC,0) + end_fit*DimDelta(DC,0)
		end_fit_indicator[0][1] = vertline_max
		end_fit_indicator[1][1] = vertline_min

		Duplicate /O DC, $(diagStr + "_line_top")
		Wave line_top_indicator = $(diagStr + "_line_top")
		line_top_indicator = top_slope*x + top_intercept //coeffG[2]*x + coeffG[3]
	
//		print top_slope
//		print top_intercept

		Duplicate /O DC, $(diagStr + "_line_bottom")
		Wave line_bottom_indicator = $(diagStr + "_line_bottom")
		line_bottom_indicator = bottom_slope*x + bottom_intercept // coeffG[4]*x + coeffG[5]

//		print bottom_slope
//		print bottom_intercept

		DoWindow $(diagStr + "_w")
		if (!V_flag)	
			Display/N=$(diagStr + "_w") DC, DCavg, DCdif, DCabs, DCguess, line_top_indicator, line_bottom_indicator 
			AppendToGraph/W=$(diagStr + "_w") guess_ef_indicator[][1] vs guess_ef_indicator[][0] 
			AppendToGraph/W=$(diagStr + "_w") start_fit_indicator[][1] vs start_fit_indicator[][0]
			AppendToGraph/W=$(diagStr + "_w") end_fit_indicator[][1] vs end_fit_indicator[][0]			 			
			ModifyGraph/W=$(diagStr + "_w") rgb($(ParseFilePath(0, DCstr, ":", 1, 0)))=(0,65535,0),rgb($(ParseFilePath(0, DCavgstr, ":", 1, 0)))=(0,0,65535),rgb($(ParseFilePath(0, DCdifstr, ":", 1, 0)))=(65535,0,0),rgb($(ParseFilePath(0, DCabsstr, ":", 1, 0)))=(0,65535,65535)
			Legend/W=$(diagStr + "_w")/C/N=text0/F=0/A=MC/X=20/Y=30
			ModifyGraph/W=$(diagStr + "_w") lstyle($(diagStr + "_guess_ef"))=3,rgb($(diagStr + "_guess_ef"))=(0,0,0)
			ModifyGraph/W=$(diagStr + "_w") lstyle($(diagStr + "_start_fit"))=3,rgb($(diagStr + "_start_fit"))=(0,0,0)
			ModifyGraph/W=$(diagStr + "_w") lstyle($(diagStr + "_end_fit"))=3,rgb($(diagStr + "_end_fit"))=(0,0,0)	
			ModifyGraph/W=$(diagStr + "_w") lstyle($(diagStr + "_line_top"))=5,rgb($(diagStr + "_line_top"))=(0,35535,0)	
			ModifyGraph/W=$(diagStr + "_w") lstyle($(diagStr + "_line_bottom"))=5,rgb($(diagStr + "_line_bottom"))=(0,35535,0)					
		endif
	endif

	Return paramDump_s

End


Function Fer(w,x) : FitFunc

	Wave w
	Variable x

	//return w[2]*(x-w[3])/(exp((x-w[0])/w[1]) + 1) + w[4] + x*w[5]
	//return w[2]*(x-w[3])/(exp((x-w[0])/w[1]) + 1)
	return (w[2]*x + w[3])/(exp((x-w[0])/w[1]) + 1) + (w[4]*x + w[5])
	//return w[0] + x*w[1]
	
End

// FuncFit /NTHR=0 $fitFuncWant coeffFin distCurve[start,stop] /D // /C=constraintWave
//	FuncFit /NTHR=0 Fer CO3040_fit_in CO3040_DC[141,197] /D

//	CurveFit/M=2/W=0 poly 3, $fitName[*][1]/X=$fitName[*][0]/D
//	CurveFit/M=2/W=0 poly 4, $fitName[*][0]/X=$fitName[*][1]/D


// 20201127 For dividing out by the Fermi edge
Function Fermi_edge_only(w,x) : FitFunc

	Wave w
	Variable x

	return 1/(exp((x-w[0])/w[1]) + 1)
	
End



Function/S IB_fit_Fermi_edge(DC)

	// In practice you need to change the settings in IB_guess_fermi() rather often... It is not very autonomous.

	Wave DC

	Variable verbose = 1
	Variable plot = 1

	// Error handling
	if (!WaveExists(DC))
		Print "IB_fit_Fermi_edge: I couldn't find the distribution curve \"" + NameOfWave(DC) + "\". Aborting..."
		Abort
	endif
	
	String DCstr = GetWavesDataFolder(DC,2) // NameOfWave(DC)	
	
	if (DimSize(DC,1) > 0)
		Print "IB_fit_Fermi_edge: I expected the input wave " + DCstr + " to be 1D, but it's not. Aborting..."
		Abort
	endif
	
	String paramDump_s_guess
	
	// Generate a guess for the fit
	paramDump_s_guess = IB_guess_fermi(DC)

	NVAR IB_autoFermi_start_fit_var
	NVAR IB_autoFermi_end_fit_var
	
	String coeffGstr = DCstr + "_coeffG"
	Wave coeffG = $coeffGStr
	
	String coeffFstr = DCstr + "_coeffF"
	Duplicate /O coeffG, $coeffFstr
	Wave coeffF = $coeffFstr
	
	String DCsclstr = DCstr + "_scl"
	Duplicate /O DC, $DCsclstr
	Wave DCscl = $DCsclstr
	DCscl = x
	
	String DCfitstr = DCstr + "_fit"
	Duplicate /O DC, $DCfitstr
	Wave DCfit = $DCfitstr
	DCfit = 0

	// Attempt to perform the fit

	// 20200120 I realized that this will catch errors, but only if the Debugger is not enabled; to catch errors w/ & w/out Debugger, need to do it differently 
//	try
//		FuncFit /Q/NTHR=0 Fer coeffF DC[IB_autoFermi_start_fit_var,IB_autoFermi_end_fit_var] /X=DCscl /D=DCfit
//		AbortOnRTE
//	catch
//		Variable err = GetRTError(1)
//		String errMessage = GetErrMessage(err)
//		print "IB_fit_Fermi_edge: fitting failed for " + DCstr + " with the error: " + errMessage + ", " + num2str(err)
//	endtry
			
	// 20200120 This new version catches errors both w/ & w/out Debugger enabled; it's crucial (apparently) that "GetRTError(1)" is on the *same* line as "FuncFit"
	FuncFit /Q/NTHR=0 Fer coeffF DC[IB_autoFermi_start_fit_var,IB_autoFermi_end_fit_var] /X=DCscl /D=DCfit;	 Variable err = GetRTError(1)
	if (err != 0 && verbose)
		String errMessage = GetErrMessage(err)
		print "IB_fit_Fermi_edge: fitting failed for " + DCstr + " with the error: " + errMessage + ", error No." + num2str(err)
	endif			

	// Plot the result
	//Variable legposX = -30, legposY = 30
	Variable legposX = 30, legposY = 30
	//Variable legposX = -30, legposY = -30
	if (plot)
		String winStr = ParseFilePath(0, DCstr, ":", 1, 0) + "_fit_w"
		String fitOutStr = DCstr + "_fit"
		String guessStr = DCstr + "_guess"
		DoWindow $winStr
		if (!V_flag)	
			// print winStr
			// print DCstr
			// print fitOutStr
			// print guessStr
			Display/N=$winStr $DCstr, $fitOutStr, $guessStr
			ModifyGraph/W=$winStr rgb($(ParseFilePath(0, fitOutStr, ":", 1, 0)))=(0,65535,0),rgb($(ParseFilePath(0, guessStr, ":", 1, 0)))=(1,16019,65535)
		else
			DoWindow/F $winStr
		endif
		Legend/C/N=text0/F=0/A=MC/X=(legposX)/Y=(legposY)
	endif	
		
	Note coeffG, paramDump_s_guess
	Note coeffF, paramDump_s_guess
	Note DCscl, paramDump_s_guess
	Note DCfit, paramDump_s_guess
	
	if (err != 0)
		Return "error"
	endif
	
	if (plot)		
		Return winStr
	endif
		
End


Function/S IB_fit_Fermi_edge_map(mapStrList,resultsTableStr)

	// To do: change name of "mapStrList" to something clearer -- this is the list of waves to fit
	// Better way to implement the avgDistCurve step, which currently is hard-coded
	// need to adjust the tableFermi[i][2] line with the dimension each time!!! very frustrating
	// output string list as variable
	// perhaps direct all output to a different folder?

	String mapStrList, resultsTableStr

	Variable numMaps = ItemsInList(mapStrList)

	Make /O/N=(numMaps,3) $resultsTableStr
	Wave tableFermi = $resultsTableStr

	Variable i, sizeDC
	String mapStr, DCStr, winStr, winStrList = ""

	//for (i = 0; i < 1; i += 1)
	for (i = 0; i < numMaps; i += 1)
		
		mapStr = StringFromList(i,mapStrList)
		// print "IB_fit_Fermi_edge_list: trying to see the Fermi edge for wave: " + mapStr
		Wave map = $mapStr
		sizeDC = DimSize(map,0) // <--- need to change this if you change avgDistCurve dimension
		avgDistCurve(mapStr,1,0,sizeDC-1)
//		avgDistCurve(mapStr,0,0,sizeDC-1)
//		avgDistCurve3D(mapStr,0,0,-1,19,19)
		DCStr = mapStr + "_DC"
		Wave DC = $DCStr
		winStr = IB_fit_Fermi_edge(DC)
		winStrList = AddListItem(winStr,winStrList)
		String coeffStr = DCStr + "_coeffF"
		Wave coeff = $coeffStr
		tableFermi[i][0] = coeff[0]
		tableFermi[i][1] = coeff[1]
		tableFermi[i][2] = (coeff[0] - DimOffset(map,1))/DimDelta(map,1)
//		tableFermi[i][2] = (coeff[0] - DimOffset(map,0))/DimDelta(map,0)

	endfor

	print "IB_fit_Fermi_edge_list: I'm done fitting. Results stored in " + resultsTableStr

	Return winStrList

End


Function/S IB_fit_Fermi_edge_list(edgeList_name_s, [yesno_w, table_s])

	// Fits every row/column of 2D wave using IB_fit_Fermi_edge()
	//
	// edgeList_name_s: string, name of a global string variable, in quotes, containing a list of Fermi edges to fit
	// yesno_w: optional wave, must be same length as the number of distribution curves, with 1 or 0 indicating
	//		whether or not to perform the fit; useful for adjusting parameters for individual Fermi edge fits 
	// table_s: optional string, name of the Fermi table, default = $edgeList_s + "_tab"
	//
	// to do: more robust in terms of which directory you are in
	//
	// Ilya
	// 6 Jan 2020

	String edgeList_name_s
	Wave yesno_w
	String table_s

	// Error handling
	SVAR /Z edgeList_s = $edgeList_name_s
	if (!SVAR_Exists(edgeList_s))
		Print "IB_fit_Fermi_edge_list: couldn't find the global string variable named ", edgeList_name_s, " containing the list of Fermi edges. Aborting..."
		Abort
	endif
	
	Variable num_v = ItemsInList(edgeList_s)
	
	// yesno_w exists?
	Variable yesno_w_exists = 1
	if (ParamIsDefault(yesno_w))
		yesno_w_exists = 0
	endif
	
	// yesno_w has correct dimensions?
	
	// yesno_w has correct length?
	if (yesno_w_exists)
		Variable yesno_dim = DimSize(yesno_w,0)
		if (yesno_dim != num_v)
			Print "IB_fit_Fermi_edge_list: you supplied a yes/no wave " + NameOfWave(yesno_w) + ", but it has " + num2str(yesno_dim) + " entries, while I expected " + num2str(num_v) + " entries. Aborting..."
			Abort
		endif
	endif
	
	String tableFermi_s
	if (ParamIsDefault(table_s))
		tableFermi_s = edgeList_name_s + "_tab"
	else
		tableFermi_s = table_s
	endif
	Make /O/N=(num_v,3) $tableFermi_s
	Wave tableFermi_w = $tableFermi_s
	//SetScale /P x, DimOffset(), DimDelta(), tableFermi_w

	String edge_s, win_s, coeff_s, winList_s = ""

	Variable i
	for (i = 0; i < num_v; i += 1)

		if (yesno_w_exists && yesno_w[i])	
		
			edge_s = StringFromList(i,edgeList_s)
			Wave edge = $edge_s

			win_s = IB_fit_Fermi_edge(edge)	
			winList_s = winList_s + win_s + ";"

			coeff_s = edge_s + "_coeffF"
			Wave coeff = $coeff_s
			tableFermi_w[i][0] = coeff[0]
			tableFermi_w[i][1] = coeff[1]
			tableFermi_w[i][2] = (coeff[0] - DimOffset(edge,0))/DimDelta(edge,0)

		endif

	endfor

	Print "IB_fit_Fermi_edge: table of Fermi edges saved in " + tableFermi_s + "."

	String winList_name_s = edgeList_name_s + "_w"
	String/G $winList_name_s = winList_s

	Return winList_s

End