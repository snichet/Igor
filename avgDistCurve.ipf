#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function/S avgDistCurve(theCutName,whichDimens,startDistCurve,endDistCurve[,outStr])

	// whichDimens is the dimension to preserve, collapse will happen along otherDimens
	//
	// set endDistCurve = -1 to use the full range
	//
	// to-do: change name of proc
	// default entire range
	// handle it when the limits exceed 0 or the size of the cut
	//
	// Ilya, before 2017...

	String theCutName, outStr
	Variable whichDimens, startDistCurve, endDistCurve
	
	Wave theCut = $theCutName

	if (!WaveExists(theCut))
		Print "avgDistCurve: your cut ", theCutName, " doesn't exist... woops. Aborting..."
		Abort
	endif

	String distCurveStr
	if (ParamIsDefault(outStr))
		distCurveStr = theCutName + "_DC"
	else
		distCurveStr = outStr
	else
	
	endif

	Variable otherDimens = mod(whichDimens+1,2)
	Variable otherSize = DimSize(theCut,otherDimens)

	if (endDistCurve == -1)
		endDistCurve = otherSize-1
	endif
	
	Variable totalNum = endDistCurve - startDistCurve + 1
	
	Variable otherDimensStart = DimOffset(theCut, otherDimens) + startDistCurve*DimDelta(theCut,otherDimens)
	Variable otherDimensEnd = DimOffset(theCut, otherDimens) + endDistCurve*DimDelta(theCut,otherDimens)
	
	// print "avgDistCurve: Collapsing dimension " + num2str(otherDimens) + " of the wave " + theCutName + ", going from scaled values " + num2str(otherDimensStart) + " to " + num2str(otherDimensEnd) + "."
		
	// Initialize the distCurve
	Make /O/N=(DimSize(theCut,whichDimens)) $distCurveStr
//	String distCurveStr_lastpart = ParseFilePath(0, distCurveStr, ":", 1, 0)
	SetScale /P x, DimOffset(theCut,whichDimens), DimDelta(theCut,whichDimens), $distCurveStr//_lastpart
	Wave theEDC = $distCurveStr
	theEDC = 0;
	
	Variable i
	
	for (i = startDistCurve; i < endDistCurve + 1; i += 1)
		if (whichDimens)
			theEDC[] = theEDC[p] + theCut[i][p]	
		else
			theEDC[] = theEDC[p] + theCut[p][i]
		endif
	endfor

	theEDC[] = theEDC[p]/totalNum
	
	String record = "IB_avgDistCurve: " + date() + " at " + time() + ", distribution curve generated from the cut, " + theCutName + ", preserving dimension " + num2str(whichDimens) + ", integrating along dimension " + num2str(otherDimens) + ", from index " + num2str(startDistCurve) + " to index " + num2str(endDistCurve) + "."
	Note theEDC, record
	
	Return distCurveStr
	
End