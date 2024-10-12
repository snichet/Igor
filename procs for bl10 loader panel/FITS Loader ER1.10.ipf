#pragma rtGlobals=2		// Use modern global access and logic ops

#include <Autosize Images>
#include <Strings as lists>		//ER
//version 1.08 Oct 2007
// Now requires Igor 6, see note at error to change manually to work with igor 5
// emode set using igorinfo(4) mode 4 is only supported by igor 6.

//version 1.07 Dec 2005
//fixed variable loading
// load files without images in one go


//version 1.05 jun 2004
// Put FITS variable comments in *_Comment
// Make bualean variables work

//version  1.04 oct 2003	
// special cased ReadDataBinTableMultirow for single row reads to reduce copying AB

//Version 1.03 changed Oct 2003	
// Changed redimension in multirowbindata redimensioning to be faster

//version 1.02 changed, june 2003
//changed so that instead of fbinread'ing each multirowbindata, it is broken up into smaller read chunks


//eli's changes mar 2003
//added "consolidate" function which assuming that extension(N), extension(N+1)... are identical,
//		consolidates the data into higher-dimension waves. e.g. scalars --> 1-d waves, 1-d waves--> images, etc
//for multi-row bintable, where a column contains vectors, put data in correct order in final image
//added "nodata" option for loadOneFITS to skip all data (useful to read header only when browsing large files)

//eli's changes dec 2002
//enabled loading of "IMAGE   " extensions
//fixed bug when loading double precision images (wrong numtype)
//improvements to reading bintable extensions
//	can now set the x and y scales
//	for images in multirow bintables, convert stacks of image into 3d volume
//	for single row bintables:
//		rename the data structure according to TTYPE (already was done for multirow BTs)
//		don't transpose the input matrix, so that images are plotted as tdim=(horiz, vert)

// FITS Loader Version 2.11; For use with Igor Pro 4.0 or later
//	Larry Hutchinson, WaveMetrics inc., 1-19-02
//	Version 2.11:
//		Fix wave name conflict in BINTABLE load
//		Added support for ascii in BINTABLE.  
//	Version 2.1:
//		Support for multi-row BINTABLE extension.
//	Version 2.0:
//		Support for BINTABLE extension (but only kind where all data is packed into 1 row).
//		Eliminated keyword list in favor of reading ALL keywords into variables.
//	Version 2.0 (beta prior to 8-3):
//		Can now use the fits load routine as a subroutine in a user written procedure. See LoadOneFITS below.
//		Can now specify a list of keywords to suck out of the header. (removed 000807)
//		See FITS Loader Demo example experiment for examples of use including making movies.
//		This version does not create a menu item because the standard WMMenus.ipf file includes one in the
//			Data->Load Waves->Packages menu.  If you would like to have a menu that brings up the
//			panel, copy the commented-out Menu definition below into your procedure window and
//			remove the comment chars.
//	Version 1.02 differs from 1.01 in the use of the /K flag with NewPanel
//		This flag causes the need for 3.11B01.
//		Other changes made include changing of function names to avoid conflict with user names
//	Version 1.01 differs from 1.0 only in the use of FBinRead/B=3 to force bigendian
//		under Windows. This flag causes the need for 3.1.
//
//	This code is intended to be a starting point for a user supported astro package.
//	Documentation is provided in an example experiment named 'FITS Loader Demo'

Menu "Macros"
	"FITS Loader Panel ER",CreateFITSLoader()
End

//------------------------------------------------------------------------------------------------------------------

Function consolidate(df, n0,kill)
	string df		//datafolder name
	variable n0		//first extension to start consolidating from
	variable kill	//if true, kill original data after consolidation
	//
	variable next=countobjects(df,4) - 1 	//subtract off primary extension
	string df0=df+":Extension"+num2str(n0)	//first datafolder
	variable nw=countobjects(df0,1)			//#waves
	variable nn=countobjects(df0,2)			//#numerics
	variable ns=countobjects(df0,3)			//#strings
	variable i,j
	string nm
	//make strings --> waves of strings
	for(i=0; i<ns; i+=1)	
		nm=getindexedobjname(df0,3,i)
		//print i,nm, nn
		make/o/n=(next)/t $(df+":"+nm)
		wave/t dnmt=$(df+":"+nm)
		setscale/p x 0,1,"cycle #",dnmt
		for (j=n0; j<(n0+next);j+=1)
			svar sv=$(df+":Extension"+num2str(j)+":"+nm)
			dnmt[j-n0]=sv
		endfor
	endfor
	//make variables --> waves 
	for(i=0; i<nn; i+=1)	
		nm=getindexedobjname(df0,2,i)
		//print i,nm, nn
		make/o/n=(next) $(df+":"+nm)
		wave dnm=$(df+":"+nm)
		setscale/p x 0,1,"cycle #",dnm
		for (j=n0; j<(n0+next);j+=1)
			nvar v=$(df+":Extension"+num2str(j)+":"+nm)
			dnm[j-n0]=v
		endfor
	endfor
	
	//make waves --> waves of higher dimension
	for(i=0; i<nw; i+=1)	
		nm=getindexedobjname(df0,1,i)
		variable ds=wavedims($(df0+":"+nm))
		//print i,nm, ds

		if(ds==1)
			make/o/n=(dimsize($(df0+":"+nm),0),next) $(df+":"+nm)
			setscale/p x dimoffset($(df0+":"+nm),0), dimdelta($(df0+":"+nm),0), waveunits($(df0+":"+nm),0), $(df+":"+nm)
			setscale/p y 0,1,"cycle #",$(df+":"+nm)
		else
			if(ds==2)
				make/o/n=(dimsize($(df0+":"+nm),0),dimsize($(df0+":"+nm),1),next) $(df+":"+nm)
				setscale/p x dimoffset($(df0+":"+nm),0), dimdelta($(df0+":"+nm),0), waveunits($(df0+":"+nm),0), $(df+":"+nm)
				setscale/p y dimoffset($(df0+":"+nm),1), dimdelta($(df0+":"+nm),1), waveunits($(df0+":"+nm),1), $(df+":"+nm)
				setscale/p z 0,1,"cycle #",$(df+":"+nm)
			else
				make/o/n=(dimsize($(df0+":"+nm),0),dimsize($(df0+":"+nm),1),dimsize($(df0+":"+nm),2),next) $(df+":"+nm)
				setscale/p x dimoffset($(df0+":"+nm),0), dimdelta($(df0+":"+nm),0), waveunits($(df0+":"+nm),0), $(df+":"+nm)
				setscale/p y dimoffset($(df0+":"+nm),1), dimdelta($(df0+":"+nm),1), waveunits($(df0+":"+nm),1), $(df+":"+nm)
				setscale/p z dimoffset($(df0+":"+nm),2), dimdelta($(df0+":"+nm),2), waveunits($(df0+":"+nm),2), $(df+":"+nm)
				setscale/p t 0,1,"cycle #",$(df+":"+nm)
			endif
		endif
		wave dnmw=$(df+":"+nm)
		for (j=n0; j<(n0+next);j+=1)
			wave wv=$(df+":Extension"+num2str(j)+":"+nm)
			if(ds==1)
				dnmw[][j-n0]=wv[p]
			else
				if(ds==2)
					dnmw[][][j-n0]=wv[p][q]
				else
					dnmw[][][][j-n0]=wv[p][q][r]
				endif
			endif
		endfor
	endfor
	if(kill)
		for (i=n0; i<(n0+next); i+=1)
			killdatafolder $(df+":Extension"+num2str(i))
		endfor
	endif
end

//------------------------------------------------------------------------------------------------------------------

Function CreateFITSLoader()
	DoWindow/F FITSPanelER
	if( V_Flag != 0 )
		return 0
	endif
	

	WMDoFITSPanel()
end
	
//------------------------------------------------------------------------------------------------------------------

Static Function WMLoadFITS()
	Variable doHeader= NumVarOrDefault("root:Packages:FITS:wantHeader",1)			// set true to put header(s) in a notebook
	Variable doHistory= NumVarOrDefault("root:Packages:FITS:wantHistory",0)			// set true to put HISTORY in the notebook
	Variable doComment= NumVarOrDefault("root:Packages:FITS:wantComments",0)		// ditto for COMMENT
	Variable doAutoDisp= NumVarOrDefault("root:Packages:FITS:wantAutoDisplay",0)	// true to display data
	Variable doInt2Float= NumVarOrDefault("root:Packages:FITS:promoteInts",1)		// true convert ints to floats
	Variable bigBytes= NumVarOrDefault("root:Packages:FITS:askifSize",0)				// if data exceeds this size, ask permission to load  
	
	Variable refnum
	String path= StrVarOrDefault("root:Packages:FITS:thePath","")
	if( CmpStr(path,"_current_")==0 )
		Open/R/T="????" refnum
	else
		Open/R/P=$path/T="????" refnum
	endif
	if( refnum==0 )
		return 0
	endif
	
	FStatus refnum
	print "FITS Load from",S_fileName
	LoadOneFITS(refnum,S_fileName,doHeader,doHistory,doComment,doAutoDisp,doInt2Float,bigBytes,-1,-1)
	setdatafolder $s_filename
	LoadFITSPrimary(refnum,doInt2Float,doAutoDisp)
	LoadFITSExtensions(refnum, -1,-1,doInt2Float)
	setdatafolder ::
	Close refnum
end

//------------------------------------------------------------------------------------------------------------------

// LH991101: rewrote to make this routine independent of the panel so it can be called as a
// subroutine from a user written procedure.
//
//ER added extnum and rownum options
//ER removed loading of data, now the data are loaded separately with loadFITSPrimary and loadFITSExtensions
Function LoadOneFITS(refnum,dfName,doHeader,doHistory,doComment,doAutoDisp,doInt2Float,bigBytes,extnum,rownum)
	Variable refnum
	String dfName				// data folder name for results -- may be file name if desired
	Variable doHeader			// set true to put header(s) in a notebook
	Variable doHistory			// set true to put HISTORY in the notebook
	Variable doComment			// ditto for COMMENT
	Variable doAutoDisp			// true to display data
	Variable doInt2Float			// true convert ints to floats
	Variable bigBytes				// if data exceeds this size, ask permission to load 
	variable extnum				//if extnum is -1 read all extensions otherwise only read the data from extension # extnum
	variable rownum				//if rownum is -1 read all rows otherwise only read row# rownum
	Variable doLogNotebook= doHeader | doHistory | doComment

	FStatus refnum

	String s
	s= PadString("",80,0)
	FBinRead refnum,s
	Variable err= 0
	String errstr=""
	do
		if( CmpStr("SIMPLE  =                    T ",s[0,30]) != 0 )
			errstr="doesn't begin with 'SIMPLE'"
			err= 1
			break
		endif
		if( mod(V_logEOF,2880) != 0 )
			errstr= "file size is not a multiple of 2880 bytes"
			DoAlert 1,"WARNING: "+errstr+"; Continue anyway?"
			if( V_Flag==2 )
				err= 2
			endif
			break;
		endif
	while(0)
	if( err )
		if( err==1 )
			Abort "Not a FITS file: "+errstr
		endif
		return err
	endif
	
	String nb = ""
	if( doLogNotebook )
		nb = CleanupName(dfName,0)
		NewNotebook/N=$nb/F=1/V=1/W=(5,40,623,337) 
		Notebook $nb defaultTab=36, statusWidth=238, pageMargins={72,72,72,72}
		Notebook $nb showRuler=0, rulerUnits=1, updating={1, 60}
		Notebook $nb newRuler=Normal, justification=0, margins={0,0,576}, spacing={0,0,0}, tabs={}, rulerDefaults={"Monaco",10,0,(0,0,0)}
		Notebook $nb ruler=Normal
	endif
	
	String dfSav= GetDataFolder(1)	
	NewDataFolder/O/S $dfName
	
	String/G NotebookName= nb			// save name for later kill
	String/G GraphName= ""				// place for graph name(s) for later kill
	
	NewDataFolder/O/S Primary
	
	//
	//	Load the primary data
	//
	do
		err= GetRequired(refnum,nb,doHeader,bigBytes,0)
		if( err )
			errstr= StrVarOrDefault("errorstr","problem reading required parameters")
			break
		endif

		err= GetOptional(refnum,nb, doHeader,doHistory,doComment)
		if( err )
			errstr= StrVarOrDefault("errorstr","problem reading optional parameters")
			break
		endif
		err= SetFPosToNextRecord(refnum)
		if( err )
			errstr= StrVarOrDefault("errorstr","unexpected end of file")
			break
		endif
		
		FStatus refnum						//ER moved here
		variable/g DataOffset=v_filepos	//ER so we can load primary data quickly later
		NVAR gSkipData= gSkipData
		NVAR gDataBytes= gDataBytes
		if( gDataBytes != 0 )
			if( gSkipData+1)			//ER always skip reading primary data; will load with LoadFitsPrimary()
				//FStatus refnum
				FSetPos refnum,min(V_filePos+gDataBytes,V_logEOF)
			else
				FBinRead/B=3 refnum,data
				SetDataProperties(data,doInt2Float)
				if( doAutoDisp )
					AutoDisplayData(data)
					GraphName= WinName(0, 1)		// for later kill
				endif
			endif
			SetFPosToNextRecord(refnum)		// ignore error
		endif
	while(0)
	
	WM_FITSAppendNB(nb,"*************")
	Variable/g NExtension= 0
	if( !err )
		do
			NExtension += 1
			FStatus refnum
			Variable exStart= V_filePos				// remember this so we can skip extensions we don't understand
			
			if( V_filePos ==  V_logEOF )
				break
			endif
			if( V_logEOF < (V_filePos+2880) )
				WM_FITSAppendNB(nb,num2str(V_logEOF-V_filePos)+" bytes unread")		// LH991101: used to print to history but that is too much clutter
				break
			endif
			
			NewDataFolder/O/S ::$"Extension"+num2str(NExtension)
			FBinRead refnum,s
			WM_FITSAppendNB(nb,s)

			if( CmpStr(s[0,8],"XTENSION=") != 0 )		// ok for extra records to exist after primary and extensions
				break
			endif
		
			String/G XTENSION= GetFitsString(s)
			if( strlen(XTENSION) == 0 )
				errstr= "XTENSION char string missing"
				err= 1
				break
			endif
			Variable isBinTable= CmpStr("BINTABLE",XTENSION) == 0
			variable isImage=cmpstr("IMAGE   ",XTENSION)==0			// ER

			if( isBinTable )
				err= GetRequiredBinTable(refnum,nb,doHeader)	
			else
				err= GetRequired(refnum,nb,doHeader,bigBytes,1-isImage)	// ER; 1 means we don't create a wave
			endif
			if( err  )
				break
			endif

			err= GetOptional(refnum,nb, doHeader,doHistory,doComment)
			if( err )
				errstr= StrVarOrDefault("errorstr","problem reading optional extension parameters")
				break
			endif
			SetFPosToNextRecord(refnum)		// ignore error

			if( Exists("PCOUNT") != 2 )
				errstr= "PCOUNT extension param missing"
				err= 1
				break
			endif
			if( Exists("GCOUNT") != 2 )
				errstr= "GCOUNT extension param missing"
				err= 1
				break
			endif
			NVAR PCOUNT,GCOUNT,BITPIX
			NVAR gDataBytes					// doesn't include p or g count
			
			gDataBytes= gDataBytes*8/abs(BITPIX)
			gDataBytes= abs(BITPIX)*GCOUNT*(PCOUNT+gDataBytes)/8

			 //FStatus refnum					//ER killed
			 //Variable exDataStart= V_filePos	//ER killed
			 FStatus refnum												//ER
			 variable/g DataOffset=v_filepos									//ER store data position for reading later		 
			 FStatus refnum
			 FSetPos refnum,min(V_filePos+gDataBytes,V_logEOF)	//skip reading the data
			 SetFPosToNextRecord(refnum)		// ignore error
				
			//ER changed exdatastart to DataOffset in next line
			//FSetPos refnum,min(DataOffset+gDataBytes,V_logEOF)		//skip the data; do something with it later
			//SetFPosToNextRecord(refnum)		// ignore error
		
		while(1)
	endif
	
	if( err )
		DoAlert 0, errstr
	endif
	
	SetDataFolder dfSav
	NExtension -= 1
	return err
end

//------------------------------------------------------------------------------------------------------------------

//ER added this function
//should already be in data folder
function LoadFitsPrimary(refnum,doInt2Float,doAutoDisp)
	variable refnum
	variable doInt2Float, doAutoDisp
	setdatafolder primary
	NVAR gDataBytes= gDataBytes
	NVAR DataOffset=DataOffset
	SVAR graphName
	fstatus refnum
	if( gDataBytes != 0 )
		FSetPos refnum,min(DataOffset,V_logEOF)
		FBinRead/B=3 refnum,data
		SetDataProperties(data,doInt2Float)
		if( doAutoDisp )
			AutoDisplayData(data)
			GraphName= WinName(0, 1)		// for later kill
		endif
	endif
	SetFPosToNextRecord(refnum)		// ignore error
	setdatafolder ::
end

//ER added this function to load data from a particular extension
//should already be in data folder
function LoadFitsExtensionN(refnum, extnum,rownum,doInt2Float)
	variable refnum
	variable extnum	//should be extension # starting with 1 (-1 not allowed here)
	variable rownum	//can  be -1 to indicate all rows
	variable doInt2Float
	string nb=CleanupName(getDataFolder(0),0)
	string dfn="Extension" + num2str(extnum)
	//print dfn
	if (datafolderexists(dfn))
		setdatafolder $dfn
		NVAR gDataBytes
		SVAR xtn=XTENSION
		NVAR DataOffset
		variable err
		string errstr
		SVAR errorstr
		fsetpos refnum,DataOffset
		if(( cmpstr(xtn,"BINTABLE")==0 )*(gdatabytes>0))
			err= ReadDataBinTable(refnum,extnum,rownum,errstr)
			if( err )
				WM_FITSAppendNB(nb,"***BINTABLE ERROR (did not load data): "+errstr)
				err= 0			// continue with the rest of the file
			endif
		endif													//ER

		if((cmpstr(xtn,"IMAGE")==0)*(gDataBytes>0))		//ER this if-endif block
			NVAR gDataBytes= gDataBytes
			if( gDataBytes != 0 )
				FSetPos refnum,DataOffset
				FBinRead/B=3 refnum,data
				SetDataProperties(data,doInt2Float)	
			endif
		endif
	
		if((CmpStr("TABLE   ",xtn) == 0 )*(gDataBytes>0))
			WM_FITSAppendNB(nb,"***Start TABLE data***")
			NVAR NAXIS1,NAXIS2
			String ss= PadString("",NAXIS1,0x20)
			Variable j=1
			do
				if( j>NAXIS2)
					break
				endif
				FBinRead refnum,ss
				WM_FITSAppendNB(nb,ss)
				j+=1
			while(1)
			WM_FITSAppendNB(nb,"***End TABLE data***")
		endif
		setdatafolder ::
	else
		err=1
	endif
	return(err)
end //LoadFitsExtensionN

//------------------------------------------------------------------------------------------------------------------

function LoadFitsExtensions(refnum, extnum,rownum,doInt2Float)
	variable refnum
	variable extnum	//should be extension # starting with 1 (-1 not allowed here)
	variable rownum	//can  be -1 to indicate all rows
	variable doInt2Float
	variable extension=0,err=0
	fsetpos refnum,0
	do
		fstatus refnum
		//printf "%d  %d", v_filepos, v_logeof
		if (err+(v_filepos==v_logEOF))
			break
		endif
		if (extnum > 0)
			loadFitsExtensionN(refnum,extnum,rownum,doInt2Float)
			break
		else
			extension+=1
			err=loadFitsExtensionN(refnum,extension,rownum,doInt2Float)
			err+=SetFPosToNextRecord(refnum)	
		endif
	while (1) 
end

//------------------------------------------------------------------------------------------------------------------

Static Function ScaleIntData(d,bscale,bzero,blank,blankvalid)
	Variable d,bscale,bzero,blank,blankvalid
	
	if( blankvalid )
		if( d==blank )
			return NaN
		endif
	endif
	return d*bscale+bzero
end

//------------------------------------------------------------------------------------------------------------------

Static Function SetDataProperties(data,doInt2Float)
	Wave data
	Variable doInt2Float
	
	Variable ndims= WaveDims(data)
	Variable i=1
	do
		if( i>ndims )
			break
		endif
		String ctype= StrVarOrDefault("CTYPE"+num2istr(i),"")
		Variable cref= NumVarOrDefault("CRPIX"+num2istr(i),1)-1
		Variable crval= NumVarOrDefault("CRVAL"+num2istr(i),0)
		Variable cdelt= NumVarOrDefault("CCDELT"+num2istr(i),1)
		Variable d0= crval-cref*cdelt
		if( i==1 )
			SetScale/P x,d0,cdelt,ctype,data
		endif
		if( i==2 )
			SetScale/P y,d0,cdelt,ctype,data
		endif
		if( i==3 )
			SetScale/P z,d0,cdelt,ctype,data
		endif
		if( i==4 )
			SetScale/P t,d0,cdelt,ctype,data
		endif
		i+=1
	while(1)
	
	if( Exists("BUNIT")==2 )
		SetScale d,0,0,StrVarOrDefault("BUNIT",""),data
	endif
	
	NVAR BITPIX= BITPIX
	if( (BITPIX > 0) &&  doInt2Float )
		Variable bscale= NumVarOrDefault("BSCALE",1)
		Variable bzero= NumVarOrDefault("BZERO",0)
		Variable blank= NumVarOrDefault("BLANK",0)
		Variable blankvalid= Exists("BLANK")==2
		
		if( BITPIX==32 )
			Redimension/D $"data"		// need double precision to maintian all 32 bits
		else
			Redimension/S $"data"
		endif
		if( (bscale!=1) | (bzero!=0) | blankvalid )
			data=ScaleIntData(data,bscale,bzero,blank,blankvalid)
		endif
	endif
end

//------------------------------------------------------------------------------------------------------------------

Static Function AutoDisplayData(data)
	Wave data
	
	Variable ndims= WaveDims(data)
	if( ndims > 1 )
		Display;AppendImage data
		if( DimSize(data, 2) > 3 )
			Variable/G curPlane
			ControlBar 22
			SetVariable setvarPlane,pos={9,2},size={90,17},proc=WM_FITSSetVarProcPlane,title="plane"
			SetVariable setvarPlane,format="%d"
			SetVariable setvarPlane,limits={0,DimSize(data, 2)-1,1},value= curPlane
		endif
		DoAutoSizeImage(0,1)
	else
		Display data
	endif
end

//------------------------------------------------------------------------------------------------------------------

Static Function SetFPosToNextRecord(refnum)
	Variable refnum

	FStatus refnum
	Variable nextRec= ceil(V_filePos/2880)*2880
	if( nextRec != V_filePos )
		if( nextRec >= V_logEOF )
			String/G errorstr= "hit end of file"
			return 1
		endif
		FSetPos refnum,nextRec
	endif
	return 0
end	

Function WM_FITSAppendNB(nb,s)
	String nb
	String s
	
	if( strlen(nb) != 0 )
		Notebook $nb,text=s+"\r"
	endif
end

Static Function/S GetFitsString(s)
	String s

	String strVal
	Variable strValValid=0,sp1
	if( char2num(s[10]) == char2num("'") )
		strValValid= 1
		strVal= s[11,79]
		sp1= StrSearch(strVal,"'",0)
		if( sp1<0 )
			strValValid= 0
		else
			strVal= strVal[0,sp1-1]
		endif
	endif
	if( strValValid )
		return strVal
	else
		return ""
	endif
end
	
//------------------------------------------------------------------------------------------------------------------

Static Function GetRequired(refnum,nb,doHeader,bigBytes,noWave)
	Variable refnum
	String nb
	Variable doHeader,bigBytes,noWave
	
	if( !doHeader )
		nb= ""
	endif
	
	String s= PadString("",80,0)
	FBinRead refnum,s
	WM_FITSAppendNB(nb,s)

	Variable/G BITPIX
	if( CmpStr("BITPIX  = ",s[0,9]) != 0 )
		String/G errorstr= "BITPIX missing"
		return 1
	endif
	BITPIX= str2num(s[10,29])
	Variable numberType
	if( BITPIX== 8 )
		numberType= 8+0x40
	elseif( BITPIX== 16 )
		numberType= 0x10
	elseif( BITPIX== 32 )
		numberType= 0x20
	elseif( BITPIX== -32 )
		numberType= 2
	elseif( BITPIX== -64 )
		numberType= 4				//ER  1-->4
	else
		String/G errorstr= "BITPIX bad value"
		return 1
	endif
	
	FBinRead refnum,s
	WM_FITSAppendNB(nb,s)
	Variable/G NAXIS
	if( CmpStr("NAXIS   = ",s[0,9]) != 0 )
		String/G errorstr= "NAXIS missing"
		return 1
	endif
	NAXIS= str2num(s[10,29])
	Variable i=0
	Make/O/N=200 dims=0			// 199 is max possible NAXIS

	Variable/G gDataBytes= abs(BITPIX)/8
	Variable/G gSkipData=0
	if( NAXIS==0 )
		gSkipData= 1				// no primary data
		gDataBytes= 0
	endif

	do
		if( i>=NAXIS )
			break
		endif
		FBinRead refnum,s
		WM_FITSAppendNB(nb,s)
		String naname= "NAXIS"+num2istr(i+1)
		Variable/G $naname
		NVAR na= $naname
		if( CmpStr(PadString(naname,8,0x20)+"= ",s[0,9]) != 0 )
			String/G errorstr= naname+" missing"
			return 1
		endif
		na= str2num(s[10,29])
		dims[i]= na
		gDataBytes *= na
		i+=1
	while(1)
	Variable trueNDims= NAXIS
	if( (NAXIS > 0)  && (noWave==0) )
		i=NAXIS-1
		do
			if( i<0 )
				break
			endif
			if( dims[i]<=1 )
				dims[i]= 0
				trueNDims -= 1
			else
				break
			endif
			i-=1
		while(1)
		
		if( trueNDims > 4 )
			String/G errorstr= "NAXIS > 4 not supported at present time (could be done with data folders)"
			return 1
		endif
		if( gDataBytes > bigBytes )
			String s1
			sprintf s1,"load big data (%d)?",gDataBytes
			DoAlert 1,s1
			gSkipData= V_Flag!=1
		endif
		if( !gSkipData )
			Make/O/Y=(numberType)/N=(dims[0],dims[1],dims[2],dims[3]) data
		endif
	
	endif
	KillWaves dims
	return 0
end

//------------------------------------------------------------------------------------------------------------------

Static Function KWCheck(kw,s8)
	String kw,s8
	
	return CmpStr(PadString(kw,8,0x20),s8) == 0
end

//------------------------------------------------------------------------------------------------------------------

Static  Function/S StripTrail(s)
	String s
	
	Variable n= strlen(s)-1
	do
		if( (n<0) || (char2num(s[n])!=0x20) )
			break
		endif
		n-=1
	while(1)
	return s[0,n]
end

//------------------------------------------------------------------------------------------------------------------

//ER
  Function/S StripLead(s)
	String s
	
	Variable n=0
	do
		if( (n> strlen(s)) || (char2num(s[n])!=0x20) )
			break
		endif
		n+=1
	while(1)
	return s[n,strlen(s)]
end

//------------------------------------------------------------------------------------------------------------------

// read optional header stuff until END or error
// Reads all keywords into variables
//
Static Function GetOptional(refnum,nb, doHeader,doHistory, doComment)
	Variable refnum
	String nb
	Variable doHeader,doHistory,doComment
	
	
	String s= PadString("",80,0)
	String nbText=""
	do
		FStatus refnum
		if( (V_filePos+80) > V_logEOF )
			String/G errorstr= "hit end of file before END card"
			return 1
		endif
		FBinRead refnum,s
		if( CmpStr("HISTORY",s[0,6]) == 0 )
			if( doHistory )
				nbText += s+"\r"
			endif
			continue
		elseif( CmpStr("COMMENT",s[0,6]) == 0 )
			if( doComment )
				nbText += s+"\r"
			endif
			continue
		else
			if( doHeader )
				nbText += s+"\r"
			endif
		endif
		
		if( CmpStr("END ",s[0,3]) == 0 )		// this is how we exit; Very liberal
			break
		endif
		
		String kw=  StripTrail(s[0,7])
		String strVal
		Variable strValValid=0,sp1,sp2
		sp1= StrSearch(s,"'",10)
		if( sp1 >= 10 )
			sp2= StrSearch(s,"'",sp1+1)
			if( sp2 > 0 )
				strValValid= 1
				strVal= StripTrail(s[sp1+1,sp2-1])
			endif
		endif

		Variable val1= str2num(s[10,29])
		Variable hasVal= CmpStr(s[8,9],"= ") == 0

		if (strValValid==0)
			if (cmpstr(s[10,29],"                   T")==0)
				strVal="True"
				strValValid= 1
			elseif (cmpstr(s[10,29],"                   F")==0)
					strVal="False"
					strValValid= 1
			endif
		endif
			
		
		if( hasVal )
			if( strValValid )
				String/G $kw= strVal
				if (cmpstr(s[sp2+2],"/")==0)
					String/G $(kw+"_Comment")= StripTrail(s[sp2+3,79])
				endif
			else
				Variable/G $kw= val1
				if (cmpstr(s[31],"/")==0)
					String/G $(kw+"_Comment")= StripTrail(s[32,79])
				endif
			endif
		endif
	while(1)

	if( (strlen(nb)!=0)  && (strlen(nbText)!=0) )
		Notebook $nb,text=nbText
	endif
		
	return 0
end

//------------------------------------------------------------------------------------------------------------------

Static Function GetRequiredBinTable(refnum,nb,doHeader)
	Variable refnum
	String nb
	Variable doHeader
	
	if( !doHeader )
		nb= ""
	endif
	
	String s= PadString("",80,0)
	FBinRead refnum,s
	WM_FITSAppendNB(nb,s)

	Variable tmp
	if( CmpStr("BITPIX  = ",s[0,9]) != 0 )
		String/G errorstr= "BITPIX missing"
		return 1
	endif
	tmp= str2num(s[10,29])
	if( tmp != 8 )
		String/G errorstr= "BITPIX not 8"
		return 1
	endif
	Variable/G BITPIX=8
	

	FBinRead refnum,s
	WM_FITSAppendNB(nb,s)
	if( CmpStr("NAXIS   = ",s[0,9]) != 0 )
		String/G errorstr= "NAXIS missing"
		return 1
	endif
	tmp= str2num(s[10,29])
	if( tmp != 2 )
		String/G errorstr= "NAXIS not 2"
		return 1
	endif

	Variable/G gDataBytes= 1
	FBinRead refnum,s
	WM_FITSAppendNB(nb,s)
	if( CmpStr("NAXIS1  = ",s[0,9]) != 0 )
		String/G errorstr= "NAXIS1  missing"
		return 1
	endif
	Variable/G NAXIS1= str2num(s[10,29])		// bytes per row
	gDataBytes *= NAXIS1

	FBinRead refnum,s
	WM_FITSAppendNB(nb,s)
	if( CmpStr("NAXIS2  = ",s[0,9]) != 0 )
		String/G errorstr= "NAXIS2  missing"
		return 1
	endif
	Variable/G NAXIS2= str2num(s[10,29])		// rows
	gDataBytes *= NAXIS2

	FBinRead refnum,s
	WM_FITSAppendNB(nb,s)
	if( CmpStr("PCOUNT  = ",s[0,9]) != 0 )
		String/G errorstr= "PCOUNT  missing"
		return 1
	endif
	Variable/G PCOUNT= str2num(s[10,29])		//Random parameter count 
	
	FBinRead refnum,s
	WM_FITSAppendNB(nb,s)
	if( CmpStr("GCOUNT  = ",s[0,9]) != 0 )
		String/G errorstr= "GCOUNT  missing"
		return 1
	endif
	Variable/G GCOUNT= str2num(s[10,29])		//Group count
	
	FBinRead refnum,s
	WM_FITSAppendNB(nb,s)
	if( CmpStr("TFIELDS = ",s[0,9]) != 0 )
		String/G errorstr= "TFIELDS  missing"
		return 1
	endif
	Variable/G TFIELDS= str2num(s[10,29])		//Number of columns

	return 0
end

//------------------------------------------------------------------------------------------------------------------

//ER added rownum
//extnum is which extension to read
//if rownum=-1 then read all rows, else read row# rownum from multirow bintables
Static Function ReadDataBinTable(refnum,extnum,rownum,errMessage)	//ER added extnum, rownum
	Variable refnum, extnum,rownum
	String &errMessage

	NVAR NAXIS2
	//if( NAXIS2 != 1 )
		return ReadDataBinTableMultirow(refnum,errMessage,rownum)		//er added rownum
	//endif
	
	Variable i
	variable /g hasImages
	Variable nType,numpnts,isAscii

	make /o numpntsW,ntypeW,isAsciiW
	for(i=1;;i+=1)
		SVAR/Z tform= $"TFORM"+num2str(i)
		if( !SVAR_Exists(tform) )
			break
		endif
		numpnts= ParseTFORM(tform,nType,isAscii)
		numpntsW[i]= numpnts
		ntypeW[i] = ntype
		isAsciiW[i] = isAscii
		if (numpnts>1)
			hasImages=1
		endif
	endfor
	
	variable /g numTform= i-1
		
	for(i=1;;i+=1)
		SVAR/Z tform= $"TFORM"+num2str(i)
		if( !SVAR_Exists(tform) )
			break
		endif
		
		numpnts= ParseTFORM(tform,nType,isAscii)
		if( nType<0 )
			errMessage= "Don't know how to handle BINTABLE with tform= "+tform
			return 1
		endif
		if( numpnts==0 )		// null records are allowed
			continue
		endif
		
		
		String wname= "BTData"+num2str(i)
		SVAR/Z ttype= $"TTYPE"+num2str(i)	//ER 	look for TTYPE variable
		if( SVAR_Exists(ttype) )				//ER	rename wave using TTYPE
			wname= StripTrail(ttype)			//ER
		endif								//ER
		if( CheckName(wname, 1) != 0 )		//ER
			wname= UniqueName(wname,1,0)	//ER
		endif								//ER

		Make/O/N=(numpnts)/Y=(nType) $wname
		WAVE data= $wname
		FBinRead/B=3 refnum,data

		SVAR/Z tdim= $"TDIM"+num2str(i)
		if( SVAR_Exists(tdim) )
			Variable dim1,dim2,err
			err= ParseTDIM(tdim,dim1,dim2)
			if( !err )
				Redimension/N=(dim1,dim2) data		
				//MatrixTranspose data				
			endif
			SetDataPropertiesBinTableImage(data,i)		//ER
		else											//ER
			SetDataPropertiesBinTable(data,i,0)			//ER
		endif				
		SVAR/Z tunit= $"TUNIT"+num2str(i)
		if( SVAR_Exists(tunit) )
			SetScale d 0,0,tunit, data
		endif
		// swap if complex?, split mult cols?
		
	endfor
	
	return 0
end

//------------------------------------------------------------------------------------------------------------------

// Returns number of bytes for a given number type
// See /Y flag for Make,Redimension
Static Function NumSize(ntype)
	Variable ntype
	
	Variable cmult= (ntype&0x01) ? 2 : 1;

	if( ntype&0x40 )
		return 1*cmult
	elseif( ntype &0x10 )
		return 2*cmult
	elseif( (ntype&0x20) || (ntype&0x02) )
		return 4*cmult
	elseif( ntype&0x04 )
		return 8*cmult
	else
		return -1
	endif
End

//------------------------------------------------------------------------------------------------------------------

//ER added rownum; 	if rownum=-1 then read all rows including images
//ER 				if rownum=#, then read all rows, except for images, only read row "#"
Static  Function ReadDataBinTableMultirow(refnum,errMessage,rownum)
	Variable refnum
	variable rownum	//ER
	String &errMessage

	NVAR NAXIS1
	NVAR NAXIS2
	Variable emode= CmpStr( IgorInfo(4),"PowerPC")==0 ? 1 : 2;	//  See Redimension's new /E flag for meaning of emode comment out line for igor 5. Set emode=1 for powerpc emode =2 for intel
	
	//emode=2 
	NVAR DataOffset	//ER start of binary table 
	// read entire data into unsigned byte wave
	//Make/B/U/N=(NAXIS1,NAXIS2) bindata
	//if( !WaveExists(bindata) )
	//	errMessage= "not enough memory"
//		return 1
//	endif
//print "about to read..."
//	FBinRead refnum,bindata
//print "done reading!"

	// disburse individual columns
	
		
	Variable i
	variable /g hasImages
	Variable nType,numpnts,isAscii

//	make /o numpntsW,ntypeW,isAsciiW
	for(i=1;;i+=1)
		SVAR/Z tform= $"TFORM"+num2str(i)
		if( !SVAR_Exists(tform) )
			break
		endif
		numpnts= ParseTFORM(tform,nType,isAscii)
//		numpntsW[i]= numpnts
//		ntypeW[i] = ntype
//		isAsciiW[i] = isAscii
		
		SVAR/Z tdim= $"TDIM"+num2str(i)				//ER --this means it's a 2d array
		hasImages=svar_exists(tdim)
	endfor
	if (hasImages==0)
			// read entire data into unsigned byte wave
	//		print naxis1,naxis2,naxis1*naxis2
	//		print "allocating mem"
			Make/B/U/N=(NAXIS1,NAXIS2) bindata
	//		print "done"
			if( !WaveExists(bindata) )
				//errMessage= "not enough memory"
				hasimages=1
			endif
	//		print "about to read..."
			FBinRead refnum,bindata
	//		print "done reading!"
	endif
	Variable colStart=0,colBytes
	for(i=1;;i+=1)
	
		SVAR/Z tform= $"TFORM"+num2str(i)
		if( !SVAR_Exists(tform) )
			break
		endif
		numpnts= ParseTFORM(tform,nType,isAscii)
		//print ">",numpnts
		if( nType<0 )
			errMessage= "Don't know how to handle BINTABLE with tform= "+tform
			return 1
		endif
		if( numpnts==0 )		// null records are allowed
			continue
		endif
		
		colBytes= numpnts*NumSize(nType)

		String wname= "BTData"+num2str(i)
		SVAR/Z ttype= $"TTYPE"+num2str(i)
		if( SVAR_Exists(ttype) )
			wname= StripTrail(ttype)
		endif

		SVAR/Z tdim= $"TDIM"+num2str(i)				//ER --this means it's a 2d array
		variable isimage=svar_exists(tdim)
	
		if((isimage==0)*CheckName(wname, 1) != 0 )		//ER
			if (cmpstr(wname,"time")==0)					//manually trap "time", a common illegal name
				wname="time0"							//ER
			endif
			if (cmpstr(wname,"X")==0)					
				wname="X0"							
			endif
			if (cmpstr(wname,"Y")==0)					
				wname="Y0"							
			endif
			if (cmpstr(wname,"Z")==0)					
				wname="Z0"							
			endif						
			//wname= UniqueName(wname,1,0)				//ER allow overwrite of same name
		endif
		
		 wname = CleanupName(wname, 0)
		
		variable /g $("TCST"+num2str(i))=colstart
		
		if ((exists(wname)==0) + (isimage))	//ER Name not in use or movie name, proceed
			//print "extracting..."
			variable numrows=(isImage*(rownum>=0) ? 1 : naxis2)
			variable startrow=((isImage*(rownum>=0)) ? rownum : 0)
			make/b/u/o/n=(colbytes, numrows) $wname					//ER
			WAVE w= $wname										//ER
			if(numrows==1)											//AB
				make/b/u/o/n=(colbytes) $wname					//ER
				WAVE w= $wname	
				FSetPos refnum,dataoffset+naxis1*(startrow) + colstart	//ER
				fbinread refnum,w			
			else
				if (hasimages==1)
					make/b/u/o/n=(colbytes, numrows) $wname					//ER
					WAVE w= $wname	
					make/b/u/o/n=(colbytes) onedata							//ER
					variable ii												//ER
					for (ii=0; ii<numrows; ii+=1)								//ER
						FSetPos refnum,dataoffset+naxis1*(ii+startrow) + colstart	//ER
						fbinread refnum,onedata								//ER
						w[][ii]=onedata[p]										//ER
					endfor	
					killwaves onedata										//ER
				else
					Duplicate/O/R=[colStart,colStart+colBytes-1] bindata,$wname
					WAVE w= $wname	
				endif

			endif											//ER
		
			//ER commented out next block		
			//Duplicate/O/R=[colStart,colStart+colBytes-1] bindata,$wname
			//WAVE w= $wname
//			if( !WaveExists(w) )
//				errMessage= "not enough mem for extract"
//				return 1
//			endif
		
			//print "process data -",wname,wavedims(w)
			if( isAscii )
				if( Convert2Text(w,1) )
					errMessage= "couldn't create text version"
					return 1
				endif
			else
				variable dm1=numrows  //was naxis2
				variable dm2=(numpnts==1 ? 0 : numpnts)
				variable dm3=(isimage ? 1 : 0)
				Redimension/E=(emode)/N=(dm1, dm2, dm3)/Y=(nType) w  //ER add 3rd dimension here
				SVAR/Z tunit= $"TUNIT"+num2str(i)
				if( SVAR_Exists(tunit) )
					if( Strlen( StripTrail(tunit) ) > 0 )
						SetScale d,0,0,StripTrail(tunit) w
					endif
				endif
			endif


			//ER for multirow plots, reorganize vector data in proper order in final image
			if (wavedims(w)==2)				//ER
				//print "making vector-->image ",wavedims(w)
				duplicate/o w data_temp		//ER
				matrixtranspose data_temp	//ER
				variable d1=dimsize(w,1)		//ER
				data_temp=w[p+q*d1]			//ER
				duplicate/o data_temp w		//ER
				killwaves data_temp			//ER
			endif 							//ER

			// Handle TDIM here?							
			if( wavedims(w)==3)							//ER added this block
				//print "image-->volume ",wavedims(w)
				Variable dim1,dim2,err
				err= ParseTDIM(tdim,dim1,dim2)
				if( !err )
					//make 3d array out of stacks of images
					redimension /n=(dim1*dim2*numrows,0,0) w //AB
					redimension /n=(dim1,dim2,numrows) w		//AB
				endif		
				SetDataPropertiesBinTableImage(w,i)
			else
				//not an image, must be simple array
				SetDataPropertiesBinTable(w,i,1)
			endif
		endif
		colStart += colBytes
	endfor
	IF (waveexists(bindata))
		KillWaves bindata
	endif
	return 0
end
//======================================
Static  Function ReadDataBinTableMultirowxx(refnum,errMessage,rownum)
	Variable refnum, rownum	//er added rownum
	String &errMessage

	NVAR NAXIS1
	NVAR NAXIS2
	Variable emode= CmpStr( IgorInfo(4 ),"PowerPC")==0 ? 1 : 2;		// ASSUME: platforms other than Mac are little endian (need better indication). See Redimension's new /E flag for meaning of emode

	
	// read entire data into unsigned byte wave
print naxis1,naxis2,naxis1*naxis2
print "allocating mem"
	Make/B/U/N=(NAXIS1,NAXIS2) bindata
print "done"
	if( !WaveExists(bindata) )
		errMessage= "not enough memory"
		return 1
	endif
print "about to read..."
	FBinRead refnum,bindata
print "done reading!"

	// disburse individual columns
	Variable i,colStart=0,colBytes
	for(i=1;;i+=1)
		SVAR/Z tform= $"TFORM"+num2str(i)
		if( !SVAR_Exists(tform) )
			break
		endif
		Variable nType,numpnts,isAscii=0
		
		numpnts= ParseTFORM(tform,nType,isAscii)
		if( nType<0 )
			errMessage= "Don't know how to handle BINTABLE with tform= "+tform
			return 1
		endif
		if( numpnts==0 )		// null records are allowed
			continue
		endif
		
		colBytes= numpnts*NumSize(nType)

		String wname= "BTData"+num2str(i)
		SVAR/Z ttype= $"TTYPE"+num2str(i)
		if( SVAR_Exists(ttype) )
			wname= StripTrail(ttype)
		endif
		if( CheckName(wname, 1) != 0 )
			wname= UniqueName(wname,1,0)
		endif
		
print "extracting..."
		Duplicate/O/R=[colStart,colStart+colBytes-1] bindata,$wname
		WAVE w= $wname
		if( !WaveExists(w) )
			errMessage= "not enough mem for extract"
			return 1
		endif
		
print "process data -",wname,wavedims(w)
		SVAR/Z tdim= $"TDIM"+num2str(i)				//ER --this means it's a 2d array
		if( isAscii )
			if( Convert2Text(w,1) )
				errMessage= "couldn't create text version"
				return 1
			endif
		else
			Redimension/E=(emode)/N=(NAXIS2,numpnts==1 ? 0 : numpnts, svar_exists(tdim) ? 1 : 0)/Y=(nType) w  //ER add 3rd dimension here
			SVAR/Z tunit= $"TUNIT"+num2str(i)
			if( SVAR_Exists(tunit) )
				if( Strlen( StripTrail(tunit) ) > 0 )
					SetScale d,0,0,StripTrail(tunit) w
				endif
			endif
		endif

		//ER for multirow plots, reorganize vector data in proper order in final image
		if (wavedims(w)==2)				//ER
			print "making vector-->image ",wavedims(w)
			duplicate/o w data_temp		//ER
			matrixtranspose data_temp	//ER
			variable d1=dimsize(w,1)		//ER
			data_temp=w[p+q*d1]			//ER
			duplicate/o data_temp w		//ER
			killwaves data_temp			//ER
		endif 							//ER

		// Handle TDIM here?							
		if( wavedims(w)==3)							//ER added this block
			print "image-->volume ",wavedims(w)
			Variable dim1,dim2,err
			err= ParseTDIM(tdim,dim1,dim2)
			if( !err )
				//make 3d array out of stacks of images
				duplicate/o w data_temp				//ER
				redimension/n=(dim1,dim2,naxis2) w	//ER
				w=data_temp[p+q*dim1+r*dim1*dim2]	//ER
				killwaves data_temp					//ER
			endif		
			SetDataPropertiesBinTableImage(w,i)
		else
			//not an image, must be simple array
			SetDataPropertiesBinTable(w,i,1)
		endif
		colStart += colBytes
	endfor
	
	KillWaves bindata
	
	return 0
end

//------------------------------------------------------------------------------------------------------------------

//ER added this: works for vectors stored in bintables
Static Function SetDataPropertiesBinTable(w,i,multirow)
	Wave w
	Variable i, multirow
	//if multirow then multiple row bin table
	
	String ctype= StrVarOrDefault("TTYPE"+num2istr(i),"")
	String cdesc=StrVarOrDefault("TDESC"+num2istr(i),"")
	Variable cref= NumVarOrDefault("TRPIX"+num2istr(i),1)-1
	Variable crval= NumVarOrDefault("TRVAL"+num2istr(i),0)
	Variable cdelt= NumVarOrDefault("TDELT"+num2istr(i),1)
	Variable d0= crval-cref*cdelt
	if(!multirow)
		SetScale/P x,d0,cdelt,cdesc,w
	else
		SetScale/P y,0,1,"",w
		SetScale/P x,d0,cdelt,cdesc,w
	endif
	if( Exists("TUNIT")==2 )
		SetScale d,0,0,StrVarOrDefault("TUNIT"+num2str(i),""),w
	endif
end

//------------------------------------------------------------------------------------------------------------------

//Added by ER, loads correct scale information for images in binary tables
Static Function SetDataPropertiesBintableImage(w,i)
	wave w
	variable i
	//check for TDESC
	SVAR/Z tdesc=$"TDESC"+num2str(i)
	string desc1="",desc2=""
	if(SVAR_Exists(tdesc))
		variable err2
		err2=ParseTstring(tdesc,desc1,desc2)
	endif
	
	//check for TRPIX
	SVAR/Z trpix=$"TRPIX"+num2str(i)
	variable pix1=0,pix2=0
	if(SVAR_Exists(trpix))
		variable err3
		err3=ParseTfloat(trpix,pix1,pix2)
		pix1-=1
		pix2-=1
	endif
		
	//check for TRVAL
	SVAR/Z trval=$"TRVAL"+num2str(i)
	variable val1=0,val2=0
	if(SVAR_Exists(trval))
		variable err4=ParseTfloat(trval,val1,val2)
	endif

	//check for TDELT
	SVAR/Z tdelt=$"TDELT"+num2str(i)
	variable delt1=0,delt2=0
	if(SVAR_Exists(trval))
		variable err5=ParseTfloat(tdelt,delt1,delt2)
	endif
	
	//check for TUNIT
	SVAR/Z tunit=$"TUNIT"+num2str(i)
	string unit=StrVarOrDefault(tunit,"")
	variable d1=val1-pix1*delt1, d2=val2-pix2*delt2
	setscale/P x, d1, delt1, desc1, w
	setscale/P y, d2, delt2, desc2, w
	setscale d, 0, 0, unit, w
end

//------------------------------------------------------------------------------------------------------------------

Static  Function ParseTFORM(tform,nType,isAscii)
	String tform
	Variable &nType
	Variable &isAscii
	
	Variable i,digit,num=0
	String s=""
	for(i=0;;i+=1)
		digit= char2num( tform[i]) - 48
		if( digit < 0 || digit > 9 )
			break
		endif
		num= num*10+digit
	endfor
	if( i==0 )
		num= 1		// missing repeat count is defined as 1
	endif

	strswitch(tform[i])
		case "A":
			isAscii= 1			// data is really text
		case "L":
		case "B":
			nType= 0x48		// unsigned byte
			break
		case "I":
			nType= 0x10		// signed 16 bit int
			break
		case "J":
			nType= 0x20		// signed 32 bit int
			break
		case "E":
			nType= 0x02		// 32 bit float
			break
		case "D":
			nType= 0x04		// 64 bit float
			break
		case "C":
			nType= 0x03		// 32 bit float complex
			break
		case "M":
			nType= 0x05		// 64 bit float complex
			break
		default:						// Don't handle X,A,P yet
			nType= -1
	endswitch
	return num
end

//------------------------------------------------------------------------------------------------------------------

// Kinda' special purpose for now
Static  Function ParseTDIM(tdim,dim1,dim2)
	String tdim
	Variable &dim1,&dim2
	
	Variable ddim1,ddim2
	
	sscanf tdim,"(%d,%d)",ddim1,ddim2		// BUG: sscanf can accept pass-by-ref but doesn't work
	dim1= ddim1
	dim2= ddim2
	return V_Flag!=2			// i.e., failed
end

//------------------------------------------------------------------------------------------------------------------

//ER added
//like parseTdim, only the values are floating
Static  Function ParseTfloat(tdim,dim1,dim2)
	String tdim
	Variable &dim1,&dim2
	
	Variable ddim1,ddim2
	
	sscanf tdim,"(%f,%f)",ddim1,ddim2		// BUG: sscanf can accept pass-by-ref but doesn't work
	dim1= ddim1
	dim2= ddim2
	return V_Flag!=2			// i.e., failed
end

//------------------------------------------------------------------------------------------------------------------

//ER parse the card "NAME    = (s1,s2)" where s1 and s2 are strings
  Function ParseTstring(tstr,str1,str2)
	String tstr
	string &str1,&str2
	
	string dstr
	
	dstr=tstr[strsearch(tstr,"(",0)+1, strsearch(tstr,")",0)-1] //string between parentheses
	
	str1= striplead(striptrail(getstrfromlist(dstr,0,",")))
	str2= striplead(striptrail(getstrfromlist(dstr,1,",")))

	return 0			// i.e., never failed
end

//-----------------------------------------------------------------------------------------------------------------

Function CheckProcFitsGeneric(ctrlName,checked) // : CheckBoxControl
	String ctrlName
	Variable checked

	if( CmpStr(ctrlName,"checkHead") == 0 )
		Variable/G root:Packages:FITS:wantHeader= checked
	elseif( CmpStr(ctrlName,"checkHist") == 0 )
		Variable/G root:Packages:FITS:wantHistory= checked
	elseif( CmpStr(ctrlName,"checkCom") == 0 )
		Variable/G root:Packages:FITS:wantComments= checked
	elseif( CmpStr(ctrlName,"checkAutoDisp") == 0 )
		Variable/G root:Packages:FITS:wantAutoDisplay= checked
	elseif( CmpStr(ctrlName,"checkPromoteInts") == 0 )
		Variable/G root:Packages:FITS:promoteInts= checked
	endif
End

//------------------------------------------------------------------------------------------------------------------

Function ButtonProcLoadFits(ctrlName)//  : ButtonControl
	String ctrlName

	WMLoadFITS()
End

//------------------------------------------------------------------------------------------------------------------

Function WMDoFITSPanel()
	if( NumVarOrDefault("root:Packages:FITS:wantHeader",-1) == -1 )
		String dfSav= GetDataFolder(1)
		NewDataFolder/O/S root:Packages
		NewDataFolder/O/S FITS
		
		Variable/G wantHeader=1
		Variable/G wantHistory=0
		Variable/G wantComments=0
		Variable/G wantAutoDisplay= 1
		Variable/G promoteInts=0			// if true, then ints are converted floats
		Variable/G askifSize= 1e6			// ask if ok to load if data size is bigger than this
		
		String/G thePath= "_current_"
		SetDataFolder dfSav
	endif

	NewPanel/K=1 /W=(71,89,371,289)
	DoWindow/C FITSPanelER
	CheckBox checkHead,pos={47,42},size={139,20},proc=CheckProcFitsGeneric,title="Include Header",value=1
	CheckBox checkHist,pos={47,59},size={139,20},proc=CheckProcFitsGeneric,title="Include History",value=0
	CheckBox checkCom,pos={47,75},size={139,20},proc=CheckProcFitsGeneric,title="Include Comments",value=0
	CheckBox checkAutoDisp,pos={47,107},size={139,20},proc=CheckProcFitsGeneric,title="Auto Display",value=1
	CheckBox checkPromoteInts,pos={47,91},size={139,20},proc=CheckProcFitsGeneric,title="Promote Ints",value=0
	SetVariable setvarAskSize,pos={47,127},size={216,17},title="Max autoload size"
	SetVariable setvarAskSize,format="%d"
	SetVariable setvarAskSize,limits={0,INF,100000},value= root:Packages:FITS:askifSize
	Button buttonLoad,pos={24,14},size={99,20},proc=ButtonProcLoadFits,title="Load FITS..."
	PopupMenu popupPath,pos={133,14},size={126,19},proc=WM_FITS_PathPopMenuProc,title="path"
	PopupMenu popupPath,mode=2,popvalue="_current_",value= #"\"_new_;_current_;\"+PathList(\"*\", \";\", \"\")"
	PopupMenu killpop,pos={24,163},size={98,20},proc=WM_FITS_KillMenuProc,title="Unload FITS"
	PopupMenu killpop,mode=0,value= #"WM_FITS_GetLoadedList()"
EndMacro

//------------------------------------------------------------------------------------------------------------------

Function WM_FITSSetVarProcPlane(ctrlName,varNum,varStr,varName) // : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	ModifyImage data,plane=varNum
End

//------------------------------------------------------------------------------------------------------------------

Function WM_FITS_PathPopMenuProc(ctrlName,popNum,popStr) // : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	if( CmpStr(popStr,"_new_") == 0 )
		popStr= ""
		Prompt popStr,"name for new path"
		DoPrompt "Get Path Name",popStr
		if( strlen(popStr)!=0 )
			NewPath /M="folder containing FITS files"/Q $popStr
			PopupMenu popupPath,mode=1,popvalue=popStr
		else
			SVAR cp= root:Packages:FITS:thePath
			PopupMenu popupPath,mode=1,popvalue=cp
			return 0								// exit if cancel
		endif
	endif

	String/G root:Packages:FITS:thePath= popStr
End

//------------------------------------------------------------------------------------------------------------------

Function WM_FITS_KillMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	SVAR/Z nbName= root:$(popStr):NotebookName
	SVAR/Z gName= root:$(popStr):GraphName
	
	if( !SVAR_Exists(nbName) || !SVAR_Exists(gName) )
		return 0		// should never happen
	endif
	
	if( strlen(nbName) != 0 )
		DoWindow/K $nbName
	endif
	if( strlen(gName) != 0 )
		DoWindow/K $gName
	endif
	KillDataFolder root:$(popStr)
End

//------------------------------------------------------------------------------------------------------------------

// returns list of data folders in root from loaded fits files
Function/S WM_FITS_GetLoadedList()	
	Variable i
	String dfList="",dfName
	for(i=0;;i+=1)
		dfName= GetIndexedObjName("root:",4,i )
		if( strlen(dfName) == 0 )
			break
		endif
		SVAR/Z nbName= root:$(dfName):NotebookName
		if( SVAR_Exists(nbName) )			// we take the existance of this string var as an indication that this df is from a fits load
			dfList += dfName+";"
		endif
	endfor
	if( strlen(dfList)==0 )
		return "_none found_"
	else
		return dfList
	endif
End

//------------------------------------------------------------------------------------------------------------------

Static Function Convert2Text(w,useRow)
	WAVE w
	Variable useRow
	
	String s,swtxt= NameOfWave(w)+"_txt"
	Variable nrows= DimSize(w,0)
	Variable ncols= DimSize(w,1)
	
	
	Variable row,col
	Make/O/T/N=(useRow ? ncols : nrows) $swtxt
	WAVE/T wtxt= $swtxt
	if( !WaveExists(wtxt) )
		return 1
	endif
	if( useRow )
		for(col=0;col<ncols;col+=1)
			s= PadString("",nrows,0x20)
			for(row=0;row<nrows;row+=1)
				s[row]= num2char(w[row][col])
			endfor
			wtxt[col]= s	// StripTrail(s)
		endfor
	else
		for(row=0;row<nrows;row+=1)
			s= PadString("",ncols,0x20)
			for(col=0;col<ncols;col+=1)
				s[col]= num2char(w[row][col])
			endfor
			wtxt[row]= s	// StripTrail(s)
		endfor
	endif
	return 0
end
