#pragma rtGlobals=1		// Use modern global access method.

// ************************************************************************************************************
// * LoadSEStxt(pathStr) -	Loads an SES-style ARPES txt file into Igor waves, as if you were 	*
// *						opening an SES pxt file. The regions are loaded into wave0, wave1,	*
// *						etc.															*
// *																					*
// * 03/05/10 :	First working code.													*
// ************************************************************************************************************
Function LoadSEStxt(pathStr, baseName)	// pathStr in Igor (":") format
	String pathStr
	String baseName	
	
	String dirStr = ParseFilePath(1, pathStr, ":", 1, 0)		// file directory
	String fileStr = ParseFilePath(3, pathStr, ":", 1, 0)	// file name
	String extStr = ParseFilePath(4, pathStr, ":", 1, 0)	// file extension (no "." included)
	
	Variable refnum		// file ref number
	Variable i, j, k, m		// loop counters
	Variable p1=0, p2=0	// text position counters
	Variable dim1size, dim2size	// dimension sizes
	String line = "", fullText = "", infoStr = "", dataStr = "", regionStr = "", noteStr = ""	// text reads
	String scale1Str = "", scale2Str = "", datValStr = "", mdcStr = ""					// text reads
	String wName
	
	// read the text and then parse into smaller string variables
	NewPath/O/Q path, dirStr
	Open/R/P=path refnum as fileStr+"."+extStr
	FBinRead/B=3 refnum, fullText
	do
		FReadLine refnum, line
		fullText += line
	while(strlen(line) > 0)
	Close refnum
	KillPath path

	p1 = strsearch(fullText, "[Info]", 0)
	p2 = strsearch(fullText, "[Region 1]", p1)
	infoStr = fullText[p1, p2-1]
	infoStr = ReplaceString("[Info]\r", infoStr, "")
	Variable numRegions = NumberByKey("Number of Regions", infoStr, "=", "\r")
	String version = StringByKey("Version", infoStr, "=", "\r")
	
	// do for each region...
	for(i = 1; i <= numRegions; i += 1)
		p1 = strsearch(fullText, "[Region "+num2istr(i)+"]", p2)
		p2 = strsearch(fullText, "[Info "+num2istr(i)+"]", p1)
		regionStr = fullText[p1, p2-1]
		regionStr = ReplaceString("[Region "+num2istr(i)+"]\r", regionStr, "")
		p1 = strsearch(fullText, "[Info "+num2istr(i)+"]", p2)
		p2 = strsearch(fullText, "[Data "+num2istr(i)+"]", p1)
		noteStr = fullText[p1, p2-1]
		noteStr = ReplaceString("[Info "+num2istr(i)+"]\r", noteStr, "")
		p1 = strsearch(fullText, "[Data "+num2istr(i)+"]", p2)
		p2 = strsearch(fullText, "[Region "+num2istr(i+1)+"]", p1)
		dataStr = fullText[p1, p2 >= 0 ? p2-1 : strlen(fullText)-1]
		dataStr = ReplaceString("[Data "+num2istr(i)+"]\r", dataStr, "")
		dim1size = NumberByKey("Dimension 1 size", regionStr, "=", "\r")
		dim2size = NumberByKey("Dimension 2 size", regionStr, "=", "\r")
		scale1str = StringByKey("Dimension 1 scale", regionStr, "=", "\r")
		scale2str = StringByKey("Dimension 2 scale", regionStr, "=", "\r")
		wName = UniqueName(baseName, 1, 0)
		Make/D/N=(dim1size, dim2size) $wName
		Wave w = $wName
		SetScale/I x, str2num(StringFromList(0, scale1str, " ")), str2num(StringFromList(ItemsInList(scale1str, " ")-1, scale1str, " ")), "eV", w
		SetScale/I y, str2num(StringFromList(0, scale2str, " ")), str2num(StringFromList(ItemsInList(scale2str, " ")-1, scale2str, " ")), "deg", w
		Note w, "[SES]"
		Note w, "Version="+version
		Note w, noteStr

		// scan the 2D data string into the wave
		for(j = 0; j < dim1size; j += 1)
			mdcStr = StringFromList(j, dataStr, "\r")
			m = 0
			p1 = 0
			p2 = -1			
			for(k = -1; k < dim2size; k += 1)
				p1 = p2 + 1
				do
					if(char2num(mdcStr[p1]) == 32)		// space?
						p1 += 1
					else
						break
					endif
				while(p1 < strlen(mdcStr))
				p2 = p1+1
				do
					if(char2num(mdcStr[p2]) != 32)		// not space?
						p2 += 1
					else
						break
					endif
				while(p2 < strlen(mdcStr))
				if(k >= 0)	// skip the -1 indexed read (just telling you the energy of the MDC, which is already known)
					datValStr = mdcStr[p1, p2-1]
					w[j][k] = str2num(datValStr)
				endif
			endfor
		endfor
	endfor
End