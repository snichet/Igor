#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function/S avgDistCurve3D(theVolStr, whichDimens, startDistCurveX, endDistCurveX, startDistCurveY, endDistCurveY)

	// The variable whichDimens is the dimension to preserve. The other dimensions are collapsed.
	// The order of the other two dimensions is determined by: X = mod(whichDimens+1,3); Y = mod(whichDimens+2,3)

	// Options: use endDistCurveX = -1 and/or endDistCurveY = -1 to average through until the end of the dimension.

	// Note that this procedure actually performs a binning, rather than an average
	
	// Ilya, before 2018...

	String theVolStr
	Variable whichDimens, startDistCurveX, endDistCurveX, startDistCurveY, endDistCurveY
	
	// Preliminary error handling
	Wave theVol = $theVolStr
	if (!WaveExists(theVol))
		Print "avgDistCurve3D: I couldn't find the wave \"" + theVolStr + "\". Aborting..."
		Abort
	endif
	
	if (DimSize(theVol,3) > 0 || DimSize(theVol,2) == 0) // Exclude wave with more than 3 or less than 3 dimensions
		Print "avgDistCurve3D: I expected a 3D wave, and you gave me something else. Aborting..."
		Abort
	endif
	
	if ((whichDimens != 0 && whichDimens != 1 && whichDimens != 2))
		Print "avgDistCurve3D: your value for whichDimens doesn't make sense. Aborting..."
		Abort
	endif
	
	String theCurveStr = theVolStr + "_DC"
	Make /O/N=(DimSize(theVol, whichDimens)) $theCurveStr
	SetScale /P x, DimOffset(theVol, whichDimens), DimDelta(theVol, whichDimens), $theCurveStr
	Wave theCurve = $theCurveStr
	theCurve = 0
	
	Variable scanDimX = mod(whichDimens + 1,3)
	Variable scanDimY = mod(whichDimens + 2,3)
	
	Variable scanDimXSize = DimSize(theVol, scanDimX)
	Variable scanDimYSize = DimSize(theVol, scanDimY)
	
	Variable i, j
	
	if (endDistCurveX == -1)
		endDistCurveX = scanDimXSize-1	
	endif
	
	if (endDistCurveY == -1)
		endDistCurveY = scanDimYSize-1
	endif

	Variable fudge = 1 // 20210121 Not sure if this functionality is good...
	if (fudge)

		if (startDistCurveX < 0)
			startDistCurveX = 0
		endif
	
//		if (startDistCurveX > scanDimXSize-1)
//			startDistCurveX = scanDimXSize-1
//		endif
		
//		if (endDistCurveX < 0)
//			endDistCurveX = 0
//		endif
	
		if (endDistCurveX > scanDimXSize-1)
			endDistCurveX = scanDimXSize-1
		endif
		
		if (startDistCurveY < 0)
			startDistCurveY = 0
		endif
	
//		if (startDistCurveY > scanDimYSize-1)
//			startDistCurveY = scanDimYSize-1
//		endif
		
//		if (endDistCurveY < 0)
//			endDistCurveY = 0
//		endif
	
		if (endDistCurveY > scanDimYSize-1)
			endDistCurveY = scanDimYSize-1
		endif
	
	endif // fudge

	if (startDistCurveX < 0 || startDistCurveX > scanDimXSize-1 || endDistCurveX < 0 || endDistCurveX > scanDimXSize-1 || startDistCurveX > endDistCurveX || startDistCurveY < 0 || startDistCurveY > scanDimYSize-1 || endDistCurveY < 0 || endDistCurveY > scanDimYSize-1 || startDistCurveY > endDistCurveY)
		Print "avgDistCurve3D: your values for startDistCurveX,Y and/or endDistCurveX,Y don't make sense. Aborting..."
		Abort
	endif
	
	// Calculate the sum	
	for (i = startDistCurveX; i < endDistCurveX+1; i += 1)
		for (j = startDistCurveY; j < endDistCurveY+1; j += 1)
			if (whichDimens == 0)
				theCurve[] = theCurve[p] + theVol[p][i][j]
			elseif (whichDimens == 1)
				theCurve[] = theCurve[p] + theVol[j][p][i]
			else // (whichDimens == 2)
				theCurve[] = theCurve[p] + theVol[i][j][p]
			endif
		endfor
	endfor
	
	Return theCurveStr
	
End