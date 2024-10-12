#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function/S avgDistCurve3Dto2D(theVolStr, whichDimens, whichDimensSlice, startDistCurve, endDistCurve, [outStr, verbose])

	// Collapses a 3D wave to a 2D wave by averaging within a given range on a given direction.
	//
	// whichDimens: the dimension to preserve for each slice
	// whichDimensSlice: move from slice to slice along whichDimensSlice and perform the averaging procedure
	// (thirdDimens: the other dimension, the one which is collapsed)
	// startDistCurve: the index (location along thirdDimens) where the program starts the binning
	// endDistCurve: the index (location along thirdDimens) where the program ends the binning
	// outStr: string, optional name for the output wave
	//
	// Ilya, March 2018

	// 20201126: Add verbose

	String theVolStr, outStr
	Variable whichDimens, whichDimensSlice, startDistCurve, endDistCurve, verbose

	// Error handling
	
	// theVol exists?
	Wave theVol = $theVolStr
	if (!WaveExists(theVol))
		Print "avgDistCurve3Dto2D: I couldn't find the wave \"" + theVolStr + "\". Aborting..."
		Abort
	endif
	
	// theVol is a vol?
	if (DimSize(theVol,3) > 0 || DimSize(theVol,2) == 0)
		Print "avgDistCurve3Dto2D: I expected a 3D wave, and you gave me something else. Aborting..."
		Abort
	endif
	
	// whichDimens & whichDimensSlice make sense?
	if ((whichDimens != 0 && whichDimens != 1 && whichDimens != 2) || (whichDimensSlice != 0 && whichDimensSlice != 1 && whichDimensSlice != 2))
		Print "avgDistCurve3Dto2D: your values for whichDimens and/or whichDimensSlice don't make sense. Aborting..."
		Abort
	endif
	
	// outStr directory exists?
	
	
	String theVolAvgName
	if (ParamIsDefault(outStr))
		theVolAvgName = IB_suffix(theVolStr,"_DC")
	else
		theVolAvgName = outStr
	endif
	
	Variable numSlices = DimSize(theVol, whichDimensSlice)
	Variable startParam = DimOffset(theVol, whichDimensSlice)
	Variable endParam = startParam + (numSlices-1)*DimDelta(theVol, whichDimensSlice)

	Variable thirdDimens = 3 - whichDimens - whichDimensSlice
	Variable thirdDimensSize = DimSize(theVol, thirdDimens)

	if (startDistCurve < 0 || startDistCurve >= thirdDimensSize || endDistCurve < 0 || endDistCurve >= thirdDimensSize || startDistCurve > endDistCurve)
		Print "avgDistCurve3Dto2D: your values for startDistCurve and/or endDistCurve don't make sense. Aborting..."
		Abort
	endif

	if (verbose)
		print "avgDistCurve3Dto2D: Scanning through dimension " + num2str(whichDimensSlice) + ", going from scaled values " + num2str(startParam) + " to " + num2str(endParam) + ", for a total of " + num2str(numSlices) + " slices."
	endif

	// The temporary slice that will be fed to avgDistCurve
	String theSliceName = "avgDistCurveSlice"
	Make /O/N=(DimSize(theVol, whichDimens), thirdDimensSize) $theSliceName
	SetScale /P x, DimOffset(theVol, whichDimens), DimDelta(theVol, whichDimens), $theSliceName
	SetScale /P y, DimOffset(theVol, thirdDimens), DimDelta(theVol, thirdDimens), $theSliceName
	Wave theSlice = $theSliceName

	String theSliceDCName = theSliceName + "_DC"

	// The final output that will consist of all of the outputs of avgDistCurve assembled into a 2D wave
	Make /O/N=(numSlices, DimSize(theVol, whichDimens)) $theVolAvgName
	SetScale /P x, startParam, DimDelta(theVol, whichDimensSlice), $theVolAvgName
	SetScale /P y, DimOffset(theVol, whichDimens), DimDelta(theVol, whichDimens), $theVolAvgName
	Wave theVolAvg = $theVolAvgName

	Variable i

	for (i = 0; i < numSlices; i += 1)
	//for (i = 0; i < 1; i += 1)
	
		if (whichDimensSlice == 0)
			if (whichDimens == 1)
				theSlice[][] = theVol[i][p][q]
			else
				theSlice[][] = theVol[i][q][p]
			endif
		elseif (whichDimensSlice == 1)
			if (whichDimens == 0)
				theSlice[][] = theVol[p][i][q]
			else
				theSlice[][] = theVol[q][i][p]				
			endif
		else
			if (whichDimens == 0)
				theSlice[][] = theVol[p][q][i]
			else
				theSlice[][] = theVol[q][p][i]
			endif
		endif
		
		avgDistCurve(theSliceName,0,startDistCurve,endDistCurve)
		Wave theSliceDC = $theSliceDCName	
		
		theVolAvg[i][] = theSliceDC[q]
	
	endfor

	KillWaves /Z $theSliceName, $theSliceDCName

	String record = "IB_avgDistCurve3Dto2D: " + date() + " at " + time() + ", average cut generated from the volume, " + theVolStr + ", preserving dimension " + num2str(whichDimens) + ", stepping along dimension " + num2str(whichDimensSlice) + ", integrating along dimension " + num2str(thirdDimens) + ", from index " + num2str(startDistCurve) + " to index " + num2str(endDistCurve) + ", output written to " + theVolAvgName + "."
	Note theVolAvg, record

	Return theVolAvgName

End