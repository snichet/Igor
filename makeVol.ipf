#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function makeVol()

	String mapName = "root:BAT1_FS23" //"root:TIT6_FS1"
	String refCutName = "root:BAT1_1093" //"root:TIT6:TIT6_0005:TIT6_0005_Itp"
	Wave refCut = $refCutName

	Variable xSize = DimSize(refCut,0)
	Variable ySize = DimSize(refCut,1)

	Variable start = 1093
	Variable stop = 1144
	Variable step = 1

	Make/O/N=(xSize,ySize,(stop-start+1)/step) $mapName

	Wave FS1 = $mapName
	
	Variable thetaStart = -7.5
	Variable thetaStep = .25
	
	Variable energy =60
	Variable work = 4.25
	
	Variable yOffset = 0
	Variable zOffset = 0
	
	SetScale /P x, energy - work - DimOffset(refCut,0), -DimDelta(refCut,0), $mapName
	//SetScale /P y, DimOffset(refCut,1)*(pi/180)*sqrt(energy-work)*0.5123 + yOffset, DimDelta(refCut,1)*(pi/180)*sqrt(energy-work)*0.5123, $mapName
	SetScale /P y, DimOffset(refCut,1) + yOffset, DimDelta(refCut,1), $mapName
	//SetScale /P z, thetaStart*(pi/180)*sqrt(energy-work)*0.5123 + zOffset, thetaStep*(pi/180)*sqrt(energy-work)*0.5123, $mapName	
	SetScale /P z, thetaStart + zOffset, thetaStep, $mapName

	String cutName, cropcutName
	Variable i

	for (i = start; i < stop+1; i += step)

		if (i < 10)
			cutName = "root:BAT1_" + num2str(i);
			// cutName = "root:TIT6:TIT6_000" + num2str(i) + ":TIT6_000" + num2str(i) + "_Itp";		
		else
			cutName = "root:BAT1_" + num2str(i);
			// cutName = "root:TIT6:TIT6_00" + num2str(i) + ":TIT6_00" + num2str(i) + "_Itp";		
		endif
				
		//cropcutName = cropCut(cutName,1,10,10)		
		Wave cut = $cutName;
		FS1[][][(i-start)/step] = cut[p][q]
		
	endfor

End