// File: LoadFITS		
// Eli Rotenberg, ERotenberg@lbl.gov
//	based on software by:
// 	Jonathan Denlinger, JDDenlinger@lbl.gov

// v3.57 JD  4/9/09 Add timer print command to LoadMovie for quantitative comparison of loading times on different Macs, PCs
// v3.56 JD  3/7/09 add color-coded File Summary based on ScanType; identify XY scantype as no variables file
//                    extract photon scan range from mono_eV; extract Sample Temperature form Cryostat_D
//                    add Beta-Compensated to Export3D list
// v3.55  JD  remove need for  'colortables.ipf'; only needs file User Procedures:ColorTables:IDL_CT.itx
// v3.55  AB   Scale Photon [eV] scans using mono_eV wave in _finish3Dexport
// V3.54  AB 1/25/08  used #if statments to make independent of presence of XOP
// v3.54 AB  PC dependent compliation for allowing use with Mac (BinXOP) and PC (no BinXOP yet)
// v3.53 AB ?
// v3.52 AB  added (Mac only) BinXOP reference to BinandCopy() in MakeMovie()
// v 3.51 - last working version for Windows PC without later Mac-specific version using BinXOP
// v??  added gamma, color table, invert control for load panel image
//  (v2.0) 1/17/06 JD read new info added to R4000 header (by AB) with appropriate defaults if not present
//                 change pop file list to ListBox (with file size column & color coding)
//                 summarize folder command added (add ReadHdr option to NOT load one image)
//  8/1/05 JD Fix so compiles independent of other LoadFITS version
//                Getspectra(ee)-> FITS7_GetDataList(ee, dim);  GetVariables()-> FITS7_GetVariables()
// (v1.6) ER, pauseupdate during export3d
// v1.7 AB 
//		Set Units for multi dem waves
//		plot scaler wave as images for 2d scans without images or movies			
// v1.6 ER, pauseupdate during export3d
// Added variable comments
// 4/04/04 Aaron: Allow importing of data waves with broken names ie"CRYO-X" as "CRYO_X"
//				Added an export default for export what	
//  10/6/03 Aaron: Fixed bining
//1/23/04 Eli, fixed export defaults

//
//  11/13/04 JD&FW   (1.2) Export1D; Export2D: scale Y by data1D
//                                      screen out 'time0' & 'null' from FITS7_GetDataList
//                                      added various scaling controls for 3D data
//                  rename FITS to FITS7 to make independent from previous
//  10/24/03  JD  (1.1) print every 10th movie slice only
//  10/6/03    AB: Speed up by putting binning for loops directly into  doExportStuff()
//                               instead of implied loop function call for each indice

#pragma version = 3.57
#pragma rtGlobals=2		// Use modern global access method.
#include "wav_util"
#include "List_util"
//#include "FITS Loader ER"
#include "progresswindow"

menu "Plot"
	"-"
	"Load FITS7 Panel!"+num2char(19), FITS7_ShowPanel()
end

Proc ShowFITS7Panel()		// for older LoadMenus.ipf
	FITS7_ShowPanel()
end

Proc FITS7_ShowPanel()
//-----------------
	DoWindow/F FITS7_Panel
	if (V_flag==0)
		FITS7_Init()
		FITS7_Panel()	
		
		//	FITS7_Panel()	
		modifyimage data2d,cindex=root:fits:ct
		PopupMenu extSpectra,mode=1
		PopupMenu extImages,mode=1
		PopupMenu extMovies,mode=1
	endif
end

Function FITS7_Init()
//-----------------
	NewDataFolder/O/S root:FITS
	string df ="root:FITS:"
	make/o/N=(5,2)/T fileListw		// for ListBox
	make/o/N=(5,2,2) fileSelectw
	Make/O/W/U fileColors= {{0,0,0},{0,0,0},{0,0,65535},{65535,0,0}}
	//Make/O/W/U fileColors= {{65535,65535,65535},{65535,0,0},{0,0,65535},{0,65535,65535}}
	//Make/O/W/U fileColors= {{52428,52428,52428},{65535,0,0},{0,0,65535},{0,65535,65535}}
	MatrixTranspose fileColors
	SetDimLabel 2,1,foreColors,fileSelectw
		
	string/G filpath, filnam, fileList
	if ( exists("folderList")!=2 )			// keep existing folder list if reinitialized
		string/G folderList="Select New Folder;Summarize Folder;-;"
	endif
	variable/G filnum, numfiles
	variable/G  nchan, nslice, nloop=1	//, nregion
	variable/G islice=0, iloop=0
	//variable/G Estart, Eend, Estep, Epass
	variable/G Epass, MONOEV=1
	//variable/G Xstart, Xend, Ystart, Yend
	string/G skind, smode,mnames
	string/G wvnam	, nameopt="/B"			//, prefix=""
	variable/G nametyp=1, namenum=3
	variable/G  dscale=4, escale=3, xscale=2
	variable/G autoload=1
	variable/G extEditing=1, cycEditing=0
	variable/G iSpectra=1
	string/G binFactor="5,3"
	variable/G bin=1, ebin=5, abin=3
	string/G TDIM="(1,1)"
	variable/G NAXIS2=1
		
	// Selected information variable
	Variable/G astep1=0.032, estep1=0.1, iEpass, Epixel=446		// for camera_image fixed mode scaling
	Variable/G astep, astep1=0.032, abin=3, abin1=1
	Variable/G estep, estep1, ebin=5, ebin1=1		// pre- and post-binning
	//make/o Ep={1,2,5,10,20,50}
	//	astep:=abin*abin1*astep1
	//	estep:=ebin*ebin1*estep1
	List2Textw("filename,mode,slit,hv,slits,E-rng,Estep,#frame,Dim,N,Scan,B-rng,Binc,T(K),Size,E pixel,A pixel", ",", "root:FITS:infonam")
	make/o/n=(18)/T infowav
	make/o/n=(20) data1D
	make/o/n=(20,20)/i data2D, wdata		//**
	make/o/n=(20,20,1) data3D
		
	variable /g root:FITS:gamma=1
	variable/g root:FITS:whichCT=0
	variable/g root:FITS:invertCT=0
	nvar invertct= root:FITS:invertCT
	nvar whichCT= root:FITS:whichCT
	print whichct
	execute "loadct("+num2str(whichCT)+")"	//load initial color table
	duplicate/o root:colors:ct $(df+"ct")
	make/n=256/o $(df+"pmap")

	duplicate/o root:colors:ct $(df+"ct")
	wave ct=$(df+"ct")
	wave pmap=$(dF+"pmap")
	nvar gamma=$(dF+"gamma")
	setformula $(df+"pmap") , "255*(p/255)^"+df+"gamma)"
	setformula $(df+"ct"), "root:colors:all_ct[pmap[(invertct==0 )* p+ (invertct==1 )*(256-p)]][q][whichCT]"
End

Proc FITS7_SelectFolder(ctrlName,popNum,popStr) : PopupMenuControl
//-------------------
	String ctrlName
	Variable popNum
	String popStr
	
	PauseUpdate
	SetDataFolder root:FITS:
	if (popNum==2)						//print "Summarize Folder"
		FITS7_Summarizefolder(filpath)
	else
		if (popNum==1)						//print "Select Folder"
			NewPath/O/Q/M="Select SES Work Folder" FITS				//dialog selection
			string/G filpath
			Pathinfo FITS
			filpath=S_path
			folderList=folderList+filpath+";"
		endif
		if (popNum>3)							//print "Select Existing Folder"
			filpath=StringFromList(popNum-1,folderList)
			//print popNum, filpath
			NewPath/O/Q FITS filpath
		endif 
		// want *.txt and *.dat only
		//fileList=IndexedFile( FITS, -1, ".dat")+IndexedFile( FITS, -1, ".txt")
		//fileList=IndexedFile( FITS, -1, ".txt")
		string fullfileList=IndexedFile( FITS, -1, "????")	
		fileList=ReduceList( fullfileList, "*.fits" ) + ReduceList( fullfileList, "*.fit" ) +ReduceList( fullfileList, "*.fts" ) 
		//fileList=ReduceList( fullfileList, "*.dat" )+ReduceList( fullfileList, "*.txt" )
		//fileList=ReduceList( fullfileList, "!*DATALOG.TXT" )
		//fileList=ReduceList(fullfileList,"!*.txt")
		//fileList=ReduceList(fullfileList,"!*.dat")
		//fileList=ReduceList(fullfileList,"!*.pxt")		//include in list but load differently
		//fileList=ReduceList(fullfileList,"!*.pxp")
		//fileList=ReduceList( fileList, "!*.0*" )  //screen out Labview ".0##" files
		numfiles=ItemsInList( fileList, ";")
		numfiles= List2Textw(fileList, ";","fileListw")
		Redimension/N=(numfiles,2) fileListw
		Redimension/N=(numfiles,2,2) fileSelectw
		fileListw[][1]=num2str( FileSizeMB( filpath, fileListw[p][0]) )+" MB"
		fileSelectw[][][%forecolors]=floor( log(  FileSizeMB( filpath, fileListw[p][0])) )+1
	endif
	SetDataFolder root:
	// Update filelist menu and reset to first file
	PopupMenu popup_file value=root:FITS:fileList, mode=1
	//SelectFileFITS("",1,"")
	//ReadFITS(0)
	if ( root:FITS:autoload==2 )
		DoWindow/F ImageTool
		if (V_flag==1)
			NewImg( "root:FITS:wdatafull" )
			DoWindow/F FITS7_Panel
		endif	
	endif
End

Function FileSizeMB( filpath, filnam )
//=============
	string filpath, filnam
	GetFileFolderInfo/Q/Z filpath+ filnam
	return round( 10*V_logEOF/1E6 )/10			//MB
End

Proc FITS7_UpdateFolder(ctrlName) : ButtonControl
//-----------------------
	String ctrlName

	PauseUpdate
	//UpdateFITS(0)
	SetDataFolder root:FITS:
	string fullfileList=IndexedFile( FITS, -1, "????")	
	fileList=ReduceList( fullfileList, "*.fits" ) + ReduceList( fullfileList, "*.fit" ) +ReduceList( fullfileList, "*.fts" ) 
	numfiles=ItemsInList( fileList, ";")
	numfiles=List2Textw(fileList, ";","fileListw")
	Redimension/N=(numfiles,2) fileListw
	Redimension/N=(numfiles,2,2) fileSelectw
	fileListw[][1]=num2str( FileSizeMB( filpath, fileListw[p][0]) )+" MB"
	fileSelectw[][][%forecolors]=floor( log(  FileSizeMB( filpath, fileListw[p][0])) )+1
	
	
	PopupMenu popup_file value=root:FITS:fileList		//#"root:SES:fileList"
	
	FITS7_StepFile("StepPlus") 		// increment file selection to next (N+1)
	//Jump to last slice
	//FITS7_SelectFile( "", root:FITS:numfiles, "" )
	//PopupMenu popup_file mode=root:FITS:numfiles
	SetDataFolder root:
End

Proc FITS7_SelectFile(ctrlName,popNum,popStr) : PopupMenuControl
//-----------------------------
	String ctrlName
	Variable popNum
	String popStr

	root:FITS:filnum=popNum
	//root:SES:filnam=popStr
	root:FITS:filnam=StringFromList(root:FITS:filnum-1, root:FITS:fileList, ";")
	string/G root:FITS:wvnam=ExtractName( root:FITS:filnam, root:FITS:nameopt )
	ListBox listFITSfiles selRow=popNum-1, row=max(0,popNum-3)
	
	string ext=ExtractName( root:FITS:filnam, "/E" )
	string/G root:FITS:loadwn
	FITS7_ReadHdr( root:FITS:filpath, root:FITS:filnam, 1 )
	FITS7_UpdateGraph()
	//	ReadFITSdat(0)
	//	SetDataFolder root:FITS:

	SetDataFolder root:
End

Function FITS7_SelectFileLB(ctrlName,row,col,event) : ListBoxControl
//====================
	String ctrlName
	Variable row
	Variable col
	Variable event	//1=mouse down, 2=up, 3=dbl click, 4=cell select with mouse or keys
	//5=cell select with shift key, 6=begin edit, 7=end
	//print "event=", event, "row=", row		
	PauseUpdate; Silent 1
	if ((event==4)) //+(event==10))    // mouse click or arrow up/down or 10=cmd ListBox
		NVAR filnum=root:FITS:filnum
		SVAR filnam=root:FITS:filnam, filpath=root:FITS:filpath
		WAVE/T fileListw=root:FITS:fileListw
		filnum=row
		filnam=fileListw[ row ]
		PopupMenu popup_file mode=row+1
		//SVAR wvnam=root:FITS:wvnam, skind=root:FITS:skind, nameopt=root:FITS:nameopt
		//wvnam=skind[0]+ExtractName( filnam, nameopt )
		//print wvnam
		
		FITS7_ReadHdr( filpath, filnam, 1 )
		FITS7_UpdateGraph()
	endif

	return row
End


Function/T FITS7_ReadHdr(fpath, fnam, loaddat)
//=================
// load variables as well as one image (unavoidable?)
	string fpath, fnam
	variable loaddat			//flag to skip (preview) data loading step
	
	variable debug=0			// programming flag
	Variable refnum
	
	string wl = tracenamelist("FITS7_Panel",";",1)
	variable num=itemsinlist(wl,";")
	variable i,j
	for(i=0;i<num;i+=1)
		removefromgraph /W=FITS7_PANEL /Z $(stringfromlist(i,wl,";"))
	endfor
	NewDataFolder/O/S root:FITS
	if (datafolderexists("data"))
		killdatafolder data
	endif
	newDataFolder data
	String/G filnam=fnam, filpath=fpath
	
	open/r/t="????" refnum as filpath+filnam
	//print refnum
	loadonefits(refnum, "data",0,0,0,0,0,1000000, -1,-1)
	//loadPrimary(refnum,0,0)
	NVAR ne=root:FITS:data:primary:NExtension
	NVAR ee=root:FITS:extEditing
	ee=1
	NVAR ce=root:FITS:cycEditing
	ce=0
	if ((loaddat!=0))
		for(ee=1;ee<=ne;ee+=1)
			setdatafolder data
			loadfitsextensions(refnum,ee,0,0)
			setdatafolder ::
			nvar ncyc=$("root:fits:data:extension"+num2str(ee)+":NAXIS2")
			SetVariable cycle limits={0,ncyc-1,1}
		endfor
		ee=ne // set to last extension
	endif
	close refnum
	SetVariable extEditing limits={1,ne,1}
	
	SetDataFolder root:FITS
	string lst
	// ----- SECONDARY variables -----
	lst=FITS7_GetVariables(ee)
	PopupMenu extVars value=#"FITS7_GetVariables(root:fits:extEditing)",mode=1

	variable/G Nscan
	NVAR Nscan=Nscan
	SVAR TDIM3=root:FITS:data:Extension1:TDIM3
	if (exists("root:FITS:data:Extension1:NAXIS2"))
		NVAR NAXIS2= root:FITS:data:Extension1:NAXIS2		//NAXIS2=NumberByKey("NAXIS2",lst,"=")
		Nscan=NAXIS2
	else
		Nscan=1
	endif
	
	svar skind=root:FITS:skind
	svar mnames=root:FITS:mnames
	mnames=""
	if(exists("root:FITS:data:Primary:LWLVNM"))
		SVAR scantype = root:FITS:data:Primary:LWLVNM
		skind = scantype
		NVAR LWLVLPN=root:FITS:data:Primary:LWLVLPN
		for(i=0;i<LWLVLPN;i+=1)	
			NVAR NMSBDV = $("root:FITS:data:Primary:NMSBDV"+num2str(i))
			for(j=0;j<NMSBDV;j+=1)	
				SVAR NM=$("root:FITS:data:Primary:NM_"+num2str(i)+"_"+num2str(j))
				if(j+i)
					mnames +=",  "
				endif
				mnames += NM
			endfor
		endfor
		mnames=ReplaceString("CRYO-", mnames, "")	
		mnames=ReplaceString(" ", mnames, "")			
	else 
		mnames="XY"
		skind=""
	endif
	
	// Photon energy
	variable/G hv
	NVAR hv=root:FITS:hv
	if(exists("root:FITS:data:Primary:MONOEV"))
		NVAR MONOEV=root:FITS:data:Primary:MONOEV		//hv=round(100*NumberByKey("MONOEV",lst,"="))/100
		hv=round(10*MONOEV)/10
	endif
	
	//-----
	lst=FITS7_GetDataList(ee,1)
	NVAR iSpectra=root:FITS:iSpectra
	PopupMenu extSpectra,value=#"FITS7_GetDataList(root:fits:extEditing,1)"
	PopupMenu extSpectra, mode=max(min(iSpectra, ItemsInList(lst)),1)
	PopupMenu extImages,value=#"FITS7_GetDataList(root:fits:extEditing,2)"	
	PopupMenu extMovies,value=#"FITS7_GetDataList(root:fits:extEditing,3)"	
	
	//----- PRIMARY variables ---------
	lst=FITS7_GetVariables(0)
	PopupMenu Vars,value=#"FITS7_GetVariables(0)", mode=1

	lst=FITS7_GetVariables(ee)
	string key,value
	variable n=1,rownum=0
	do
		key = "TTYPE"+num2str(n)
		value = StringByKey(key,lst,"=")
		if(stringmatch (value,"*Spectra*")==1)
			rownum=n
		endif
		n+=1
	while(strlen(value)>0)
//	if(rownum>0)
		FITS7_UpdateVariables(rownum,ee)
//	else							// 0:  XY, LEED or other incomplete FITS file
//		WAVE/T infowav=root:FITS:infowav
//		SVAR filnam=root:FITS:filnam
//		infowav={filnam[0,strlen(filnam)-6], "?","#","hv", "slits", "E","dE","1","dim","MxN","XY","?","?","Temp", "MB","Epix","Apix"}
//	endif
	SetDataFolder root:
	return filnam
end

Function FITS7_UpdateVariables(rownum,ee)
//=====================
	variable rownum,ee
	
	// ----- SECONDARY variables -----
	string lst=FITS7_GetVariables(ee)

	NVAR Nscan=root:FITS:Nscan

	string/G Nxy
	SVAR Nxy=Nxy	

	
	Nxy=StringByKey("TDIM"+num2str(rownum),lst,"=")
	//if (strlen(TDIM)==0)
	//	TDIM=StringByKey("TDIM3",lst,"=")
	//endif
		
	string acqmode
	acqmode=StringByKey("TTYPE"+num2str(rownum),lst,"=")			// Fixed_Spectra3 or Swept_Spectra0
	acqmode=acqmode[0]			// "F" or "S"
	SVAR mnames=mnames	
	string/G scantyp
//	scantyp=StringByKey("TTYPE2",lst,"=")		//CRYO-BETA, mono_eV
	scantyp=mnames
//	scantyp=SelectString( stringmatch("CRYO-BETA", scantyp), scantyp, "Beta")
	scantyp=SelectString( stringmatch("BETA", scantyp), scantyp, "Beta")
	scantyp=SelectString( stringmatch("BETA,X,Y,Z", scantyp), scantyp, "Beta-C")
	scantyp=SelectString( stringmatch("mono_eV", scantyp), scantyp, "hv")
	scantyp=SelectString( strlen(scantyp)==0, scantyp, "XY")
//		print scantyp, acqmode

		
	//----- PRIMARY variables ---------
	lst=FITS7_GetVariables(0)
		
	NVAR estep1=root:FITS:estep1
	estep1= 1/NumberByKey("SFPEV_0",lst,"=")
	if (numtype(estep1)==2)
		estep1=0.011	// lookup value from Epass, SES-100 vs R4000?
	endif
	
	
	// Combined Pass Energy, lensmode & acquisition mode
	variable amode
	string/G smode
	IF (strlen(acqmode)>0)
		if (stringmatch("F", acqmode))				//Fixed Mode		
			SVAR lensmode = root:fits:data:Primary:SFLNM0		// Angular30NF, Transmission
			NVAR Epass = root:fits:data:Primary:SFPE_0
		else										// Swept Mode
			SVAR lensmode = root:fits:data:Primary:SSLNM0
			NVAR Epass = root:FITS:data:Primary:SSPE_0	
		endif
		smode = num2str(Epass) + lensmode[0]
		smode += SelectString( stringmatch("A",lensmode[0]), "", lensmode[7,8] )		// add angular range
		smode += acqmode
		amode=str2num( lensmode[7,8] )
	ELSE
		// gives pre-existing smode string (ok fo XY scan)
	ENDIF



	//  Energy & Angle pre-binning  (Fixed-mode only)
	string/G EAbin
	SVAR EAbin=EAbin
	if (stringmatch("F", acqmode))				//Fixed Mode
		NVAR ebin1=root:FITS:data:Primary:SFBE0
		NVAR abin1=root:FITS:data:Primary:SFBA_0
		//ebin1= NumberByKey("SFBE0",lst,"=")
		//abin1= NumberByKey("SFBA_0",lst,"=")
		EAbin=num2str(ebin1)+","+num2str(abin1)
	else
		EAbin="1,1"
	endif

	// Energy range  (loaded data image is prescaled in energy)
	//  or compute from various variables
	variable Ewidth
	string/G Erng
	SVAR Erng=Erng
	variable Einc
	if (stringmatch("F", acqmode))				//Fixed Mode
		NVAR E0= root:FITS:data:Primary:SFE_0
		NVAR pixelsEV= root:FITS:data:Primary:SFPEV_0
		NVAR PX0= root:FITS:data:Primary:SFX0_0
		NVAR PX1= root:FITS:data:Primary:SFX1_0
		NVAR PY0= root:FITS:data:Primary:SFY0_0
		NVAR PY1= root:FITS:data:Primary:SFY1_0
		Ewidth=(PX1-PX0)/pixelsEV
		Einc = ebin1/pixelsEV
		Erng = num2str(1E-2*round(1E2*E0))+",w="+num2str(1E-2*round(1E2*Ewidth))
		//WAVE data2D =  root:FITS:data:Extension1:Fixed_Spectra5
		//e1 =DimOffset( data2D, 0)
		//einc = DimDelta( data2D, 0)
		//enum = DimSize( data2D, 0)
	else
		NVAR E0= root:FITS:data:Primary:SSE0_0
		NVAR E1= root:FITS:data:Primary:SSE1_0
		NVAR DE= root:FITS:data:Primary:SSDE_0
		NVAR pixelsEV= root:FITS:data:Primary:SSPEV_0
		NVAR PX0= root:FITS:data:Primary:SSX0_0
		NVAR PX1= root:FITS:data:Primary:SSX1_0
		NVAR PY0= root:FITS:data:Primary:SSY0_0
		NVAR PY1= root:FITS:data:Primary:SSY1_0
		Ewidth=(PX1-PX0)/pixelsEV
		if (DE>=1)			// assume dither mode
			NVAR pixelsEV= root:FITS:data:Primary:SSPEV_0
			Einc = 1/pixelsEV
			Erng = num2str(1E-2*round(1E2*E0))+",w="+num2str(1E-2*round(1E2*Ewidth))+",d"
		else
			Einc = DE
			Erng = num2str(1E-2*round(1E2*E0))+","+num2str(1E-2*round(1E2*E1))
		endif
		//WAVE data2D =  root:FITS:data:Extension1:Swept_Spectra0
		//e1 =DimOffset( data2D, 1)		//Transposed relative to Fixed
		//einc = DimDelta( data2D, 1)
		//enum = DimSize( data2D, 1)
	endif
	//e2 = e1+ (enum-1)*einc
		
	// Detector angle range
	string/G Arng ="-19,19"
	SVAR Arng=Arng
	// select range based on amode 30(38), 14, 7
	
	
	//Angle positions
	NVAR theta= root:FITS:data:Primary:LMOTOR3
	NVAR beta= root:FITS:data:Primary:LMOTOR4
	NVAR phi= root:FITS:data:Primary:LMOTOR5
	
	//Dwell: Frames, Sweeps
	if (stringmatch("F", acqmode))				//Fixed Mode		
		NVAR nframe = root:fits:data:Primary:SFFR_0
	else										// Swept Mode
		NVAR nframe = root:FITS:data:Primary:SSFR_0	
	endif
		
	// Scan range 
	string/G Brng
	SVAR Brng=Brng	
	NVAR b1=root:FITS:data:Primary:ST_0_0	//NumberByKey("ST_0_0",lst,"=")
	NVAR b2=root:FITS:data:Primary:EN_0_0	//NumberByKey("EN_0_0",lst,"=")
	NVAR bnum=root:FITS:data:Primary:N_0_0	//NumberByKey("N_0_0",lst,"=")
	variable bn=Nscan
	variable binc	
	if (bn==1)
		binc=1
		Brng = num2str( 1E-2*round(1E2*beta ) )	
	else
		binc=(b2-b1)/(bn-1)	
		Brng = num2str(b1)+","+num2str(b2)		//+","+num2str(binc)
	endif
	//extract photon scan range:  3/3/09 JD
	if (stringmatch(scantyp, "hv"))
		WAVE monoeV=root:FITS:data:Extension1:mono_eV
		Brng=num2str(monoev[0])+","+num2str( monoev[DimSize(monoeV,0)-1] )
		binc=monoeV[1]-monoeV[0]
		print Brng, binc
	endif
	
	
	//Extract Sample Temperature (if exists), 3/3/09 JD
	variable Temp0=NaN
	WAVE Temp_D=root:FITS:data:Extension1:Cryostat_D
	if (WaveExists(Temp_D))
		Temp0=round(10*Temp_D[0])/10
	endif

	variable/g root:fits:plot2dMode		//0=plot from images, 1=plot single cycle from movie
	nvar plot2dmode=root:fits:plot2dMode
	plot2dMode=strlen(FITS7_GetDataList(ee,3)) >0	//if movie exists, plot it by default
	if(!plot2dMode)
		SetVariable cycle limits={0,0,1}
	endif
	//FITS7_UpdateGraph()
	
	//NVAR filnum=filnum		//doesn't change
	//WAVE/T fileListw=fileListw
	//string filesize=	fileListw[filnum][1]				//round(V_logEOF/1E6)
	SVAR filpath=filpath, filnam=filnam
	variable filesize = FileSizeMB( filpath, filnam )
	NVAR hv=root:FITS:hv

	//--- write info wave with selected variable values
	variable nregion=1					//Maybe only one region possible in FITS?
	if (nregion>1)							
		make/T/o/n=(17,nregion) infowav
	else
		make/T/o/n=(17) infowav
	endif
	//infowav={filnam, mode, "slit#","hv","slits","Polar",num2str(Ep),"Slit#",num2tr(Estart)
	//string/G smode0=smode[0]
	variable ii=0
	DO
		infowav[0][ii]=filnam[0,strlen(filnam)-6]
		infowav[1][ii] = smode
		infowav[2][ii] ="#"
		infowav[3][ii]=num2str(hv); infowav[4][ii]="xx/yy";
		infowav[5][ii]=Erng
		infowav[6][ii]=num2str(1E-1*round(1E4*Einc))		//meV
		infowav[7][ii]=num2str(nframe)  		//1E-3*round(1E3*dwell[ii])); infowav[12][ii]=num2str(nsweep[ii])
		infowav[8][ii]=Nxy 
		infowav[9][ii]=num2str(Nscan)
		infowav[10][ii]=scantyp
		infowav[11][ii]=Brng
		infowav[12][ii]=num2str(binc); 
		//	infowav[5][ii]=num2str(Theta); infowav[6][ii]=num2str(Beta);
		infowav[13][ii]=num2str(Temp0)			//"Temp"
		infowav[14][ii]=num2str(filesize)+" MB"
		infowav[15][ii]= num2str(PX0)+","+num2str(PX1)
		infowav[16][ii]= num2str(PY0)+","+num2str(PY1)
		ii+=1
	WHILE(ii<nregion)

End

Proc FITS7_SummarizeFolder( pathnam )
//----------------
// reads scan info from each file in a specified (dialog) FITS data folder 
//    and prints the info to an Igor Notebook which than can then be used as is
//    or imported (saved/pasted) into a spreadsheet
	string pathnam

	//PauseUpdate;
	Silent 1	
	if (strlen(pathnam)==0)
		NewPath/O/Q/M="Select FITS7 Data Folder" DataLibrary				//dialog selection
		Pathinfo DataLibrary
		pathnam=S_path
	endif
	variable nfolder=ItemsInList(pathnam, ":")            //FolderSep()) same on both Mac & PC
	string libnam=StrFromList(pathnam, nfolder-1, ":")
	if (nfolder>=2)
		libnam=StrFromList(pathnam, nfolder-2, ":") +"_"+libnam 
	endif
	if (char2num(libnam[0])<65)		//non-alpha first character
		libnam="N"+libnam
	endif
	//print pathnam, libnam
	
	NewPath/O/Q DataLibrary pathnam
	string fileList=IndexedFile( DataLibrary, -1, ".fits")		//"*.pxt"
	variable numfil=ItemsInList(fileList, ";")
	print "# files=", numfil		//,  fileList
	
	string Nbknam=libnam
	NewNotebook/W=(10,50,780,250)/F=1/N=$Nbknam
	variable j=72		//pts per inch
//	Notebook $Nbknam, fSize=9, margins={0,0,11.0*j }, backRGB=(65535,65534,49151), fStyle=1, showruler=0
	Notebook $Nbknam, fSize=9, margins={0,0,11.0*j }, backRGB=(60681,65535,65535), fStyle=1, showruler=1, pageMargins={28,54,28,54}
	Notebook $Nbknam, tabs={0.1*j,1.25*j,1.9*j, 2.2*j,2.7*j,3.3*j,4.4*j,5.0*j,5.5*j,5*j, 5.5*j, 6.3*j,6.8*j,7.5*j,8.2*j,8.7*j,9.2*j,9.7*j}
	Notebook $Nbknam, fstyle=1, text="\tfilename\tmode\tslit\thv\tslits\tE-rng\tEstep\t#fr\tDim\tN\tScan\tB-rng\tBinc\tT(K)\tSize"

	//PauseUpdate
	//List2Textw("filename,mode,slit,hv,slits,E-rng,Estep,#frame,Dim,N,B-rng,Binc,T(K),Size", ",", "root:FITS:infonam")
	variable timerref=StartMSTimer
	string fnam, infostr
	variable ii=0
	DO
		fnam=StrFromList(fileList, ii, ";")
		FITS7_ReadHdr( pathnam, fnam, 1 )		// 1=loaddat  3/3/09 JDD
		//print Textw2List(root:FITS:infowav, "", 0, 18)
		//root:FITS:infowav[2] = root:FITS:infowav[6]+(root:FITS:infowav[1])[0]+"#"+(root:FITS:infowav[2])[0]
		infostr="\r\t"+Textw2List(root:FITS:infowav, "\t", 0, 14)
		if (stringmatch(root:FITS:infowav[10], "Beta*"))
			NoteBook $Nbknam, fstyle=0, textRGB=(65535,0,0), text=infostr		
		else
		if (stringmatch(root:FITS:infowav[10], "hv"))
			NoteBook $Nbknam, fstyle=0, textRGB=(0,0,65535), text=infostr		
		else
		if (stringmatch(root:FITS:infowav[10], "XY"))
			NoteBook $Nbknam, fstyle=0, textRGB=(0,35535,0), text=infostr		
		else
			NoteBook $Nbknam, fstyle=0, textRGB=(0,0,0), text=infostr		
		endif
		endif
		endif
		ii+=1
	WHILE(ii<numfil)
	print StopMSTimer( timerref )/1E6, "secs"
End



Function setVarExtn7(ctrlName,varNum,varStr,varName) : SetVariableControl
//=============
	String ctrlName
	Variable varNum
	String varStr
	String varName
	FITS7_UpdateGraph()
End

Function SetCycle7(ctrlName,varNum,varStr,varName) : SetVariableControl
//=============
	String ctrlName
	Variable varNum
	String varStr
	String varName
	nvar plot2dmode=root:fits:plot2dmode
	nvar ee=root:fits:extEditing
	if (strlen(FITS7_GetDataList(ee,3)))
		plot2dmode=1
	endif
	FITS7_UpdateGraph()
End

Function SetEpass(ctrlName,popNum,popStr) : PopupMenuControl
//===========
	String ctrlName
	Variable popNum
	String popStr
	NVAR iEpass=root:FITS:iEpass
	iEpass=popNum-1
End

Function SetBin(ctrlName,checked) : CheckBoxControl
//============
	String ctrlName
	Variable checked
	NVAR bin=root:FITS:bin
	NVAR ebin=root:FITS:ebin, abin=root:FITS:abin
	SVAR binfactor=root:FITS:binfactor
	bin=checked
	if (bin)
		ebin=NumFromList(0, binfactor,",")
		abin=NumFromList(1, binfactor,",")
	else
		ebin=1; abin=1
	endif
End

Function SetBinVal(ctrlName,varNum,varStr,varName) : SetVariableControl
//==================
	String ctrlName
	Variable varNum
	String varStr
	String varName
	variable checked
	NVAR bin=root:FITS:bin
	SetBin("", bin)
End


Function Export1D(ctrlName) : ButtonControl
//==============
	String ctrlName
	
	ControlInfo/w=FITS7_Panel extSpectra
	string wn,nam1d=s_value
	variable ni,i
	string ss,what,win
	SVAR scantype=root:FITS:data:Primary:LWLVNM
	NVAR ee=root:fits:extEditing
	SVAR filnam=root:fits:filnam
	controlinfo /w=FITS7_Panel fitssuffix
	variable suffix = V_Value
	
	if(cmpstr(nam1d,"All")==0)
		string slist =  FITS7_GetDataList(ee,1)		//Getspectra(ee)
		slist=ReduceList(slist,"!*null")
		ni = itemsinlist(slist)
		if(suffix==1)
			suffix=3
		endif
		for(i=1;i<ni-1;i+=1)	// don't include time or all
			ss = stringfromlist(i,slist)
			what="root:fits:data:extension"+num2str(ee)+":'"+ss+"'"
			string nam = exportname(suffix,ss)
			WAVE d1=$what
			duplicate/O d1 $nam
			if((stringmatch(ctrlName,"display*")==1)&&(i==1))
				display $nam
			else
				win=winname(0,1)
				if(stringmatch(win,"Fits*")==1)
					win=winname(1,1)
				endif
				dowindow /F $win
				Appendtograph $nam
			endif		
		endfor						
	else
		wn = exportname(suffix,nam1d)
		print "export:"+wn
		what="root:fits:data:extension"+num2str(ee)+":'"+nam1d+"'"
		WAVE d1=$what
		duplicate/O d1 $wn
		WAVE w=$wn
		if (stringmatch(nam1d,"*_EDC") )
			SetScale/P x -DimOffset(w,0),-DimDelta(w,0),"", w
			w*=1E-6		//rescale typical MHz amplitude
		endif
		if(exists("root:FITS:data:Primary:LWLVNM"))
			SVAR scantype = root:FITS:data:Primary:LWLVNM
			strswitch (scantype)
				case "XY Scan":
				case "Two Motor":
				case "Two Beamline":
				case "XY Motor Scan":
				case "XY Piezo Scan":

					NVAR st0 =  root:fits:data:Primary:ST_0_0
					NVAR n0=root:fits:data:Primary:N_0_0
					NVAR en0 = root:fits:data:Primary:EN_0_0
					SVAR nm0 =  root:fits:data:Primary:NM_0_0
					NVAR st1 =  root:fits:data:Primary:ST_0_1
					NVAR n1=root:fits:data:Primary:N_0_1
					NVAR en1 = root:fits:data:Primary:EN_0_1	
					SVAR nm1 =  root:fits:data:Primary:NM_0_1
					redimension /N=(n0,n1) w
					SetScale/P x st0,(en0-st0)/(n0-1),nm0, w
					SetScale/P y st1,(en1-st1)/(n1-1),nm1, w
					if (stringmatch(ctrlName,"display*")&& (wavedims(w)==2))
						Display; AppendImage w
					elseif (stringmatch(ctrlName,"append*"))
						openinImagetool(wn)
					endif
					return 0
					break
				case "One Motor":
				case "Beamline":
				case "Photon[eV]":
				case "DAC":
				case "Manual":
					NVAR st0 =  root:fits:data:Primary:ST_0_0
					NVAR n0=root:fits:data:Primary:N_0_0
					NVAR en0 = root:fits:data:Primary:EN_0_0
					SVAR nm0 =  root:fits:data:Primary:NM_0_0
					SetScale/P x st0,(en0-st0)/(n0-1),nm0, w
					break
			endswitch
			if (stringmatch(ctrlName,"display*"))
				Display $wn
				if (stringmatch(nam1d,"*_EDC") )
					//SetAxis/A/R bottom
				endif
			elseif (stringmatch(ctrlName,"append*"))
				win=winname(0,1)
				if(strsearch(win,"FITS7_Panel",0)==0)
					win=winname(1,1)		
					if(strsearch(win, "ImageTool", 0 )<0 && strlen(win)>0)	
						dowindow /F $win
						Appendtograph $wn
					endif
				endif
			endif	
		endif
	endif
End

Function Export2D(ctrlName) : ButtonControl
//===============
	String ctrlName
	
	ControlInfo/w=FITS7_Panel extImages
	if(V_flag<0)
		return 1
	endif	
	string nam2d=s_value
	ControlInfo/w=FITS7_Panel extSpectra
	if(V_flag<0)
		return 1
	endif
	string nam1d=s_value
	SVAR filnam=root:fits:filnam
	NVAR extEditing=root:FITS:extEditing
	controlinfo /w=FITS7_Panel fitssuffix
	variable suffix = V_Value
	string wn= exportname(suffix,nam2d)
	
	print "export:"+wn
	WAVE  d2=$("root:FITS:data:extension"+num2str(extEditing)+":"+nam2d)
	duplicate/O d2 $wn
	WAVE w=$wn
	
	if (stringmatch(nam2d,"*_EDC") )
		SetScale/P x -DimOffset(w,0),-DimDelta(w,0),waveunits(w,0), w
		//variable yoffset=d1[0], ydelta=(d1[1]-d1[0])
		//SetScale/P y yoffset, ydelta, w
		//SetScale/I y d1[0], d1[numpnts(d1)-1], w
		//w*=1E-6		//rescale typical MHz amplitude
	endif
	if(exists("root:FITS:data:Primary:LWLVNM"))
		SVAR scantype = root:FITS:data:Primary:LWLVNM
		strswitch (scantype)
			case "XY Scan":
			case "Two Motor":
			case "Two Beamline":
			case "XY Motor Scan":
			case "XY Piezo Scan":

				NVAR st0 =  root:fits:data:Primary:ST_0_0
				NVAR n0=root:fits:data:Primary:N_0_0
				NVAR en0 = root:fits:data:Primary:EN_0_0
				SVAR nm0 =  root:fits:data:Primary:NM_0_0
				NVAR st1 =  root:fits:data:Primary:ST_0_1
				NVAR n1=root:fits:data:Primary:N_0_1
				NVAR en1 = root:fits:data:Primary:EN_0_1
				SVAR nm1 =  root:fits:data:Primary:NM_0_1
				variable dm0=dimsize(w,0)
				//print dm0,n0,n1
				redimension /N=(dm0*n0*n1) w 
				redimension /N=(dm0,n0,n1) w
				SetScale/P y st0,(en0-st0)/(n0-1),nm0, w
				SetScale/P z st1,(en1-st1)/(n1-1),nm1, w
				break
			case "One Motor":
			case "Beamline":
			case "Photon[eV]":
			case "DAC":
			case "Manual":		
				NVAR st0 =  root:fits:data:Primary:ST_0_0
				NVAR n0=root:fits:data:Primary:N_0_0
				NVAR en0 = root:fits:data:Primary:EN_0_0
				SVAR nm0 =  root:fits:data:Primary:NM_0_0
				SetScale/P y st0,(en0-st0)/(n0-1),nm0, w
		endswitch
	endif		
	if(dimsize(w,1)==1)
		redimension /N=(-1,0) w
	endif
	if (stringmatch(ctrlName,"display*"))
		if (wavedims(w)==2)
			Display; AppendImage w
		else
			display w
		endif
	elseif (stringmatch(ctrlName,"imgtool*"))
		if (wavedims(w)==2)
			openinImagetool(wn)
		else
			string win=winname(0,1)
			if(strsearch(win,"FITS7_Panel",0)==0)
				win=winname(1,1)		
				if(strsearch(win, "ImageTool", 0 )<0 && strlen(win)>0)	
					dowindow /F $win
					Appendtograph $wn
				endif
			endif		
		endif
	endif		 
End

Function Export3D(ctrlName) : ButtonControl
//=====================
	String ctrlName
	string/g root:fits:exportctrlname=ctrlName
	ControlInfo/w=FITS7_Panel extMovies
	if(V_flag<0)
		return 1
	endif	
	string what=s_value
	variable suffix=1, expopt=2
	NVAR extEditing=root:FITS:extEditing
	SVAR binfactor=root:FITS:BinFactor
	NVAR bin=root:FITS:bin
	string bf=binfactor
	if (bin==0)
		bf="1,1"
	endif
	controlinfo /w=FITS7_Panel fitssuffix
	suffix=V_Value
	
	string nam=stringfromlist(itemsinlist(what,":")-1,what,":")
	SVAR filnam=root:FITS:filnam, filpath=root:FITS:filpath
	string wnam = 	exportname(suffix,nam)
	string what2=what
	NVAR naxis2=$"root:fits:data:extension"+num2str(extEditing)+":"+"naxis2"	//number of cycles
	NVAR naxis1=$"root:fits:data:extension"+num2str(extEditing)+":"+"naxis1"	//number of cycles
	NVAR dataoffset=$"root:fits:data:extension"+num2str(extEditing)+":"+"dataoffset"	//number of cycles
	
	string orgfolder=getdatafolder(1)

	what="root:FITS:data:extension"+num2str(extEditing)+":"+what
	WAVE wht=$what
	variable notmovie=(wavedims(wht)<3)
	variable xb=str2num(stringfromlist(0,bf,",")),  yb=str2num(stringfromlist(1,bf,","))
	//	print expopt, notmovie
	if ((expopt==1)+(notmovie)) //not movie or image only
		if (waveexists(wht))
			duplicate/o wht $wnam	//1D or image already loaded
		else
			duplicate/o root:fits:data2d $wnam	//movie frame, single image already loaded
		endif
		wave wnm=$wnam
	else   //whole movie

		//swap X-Y
		variable refnum,i,j,k
		if(stringmatch(what2,"ses100_image")||stringmatch(what2,"Swept_Spectra*"))
			make/o/n=(dimsize(wht,0)/xb, dimsize(wht,1)/yb, naxis2) $wnam		
		else
			make/o/n=(dimsize(wht,1)/yb, dimsize(wht,0)/xb, naxis2) $wnam
		endif
		WAVE w3d=$wnam
		string/g root:fits:exportname=GetWavesDataFolder(w3d,2)
		open/r refnum as filpath+filnam
		variable /g root:fits:exportrefnum=refnum
		string oldfolder=getdatafolder(1)
		
		setdatafolder $"root:fits:data:extension"+num2str(extEditing)

		for(i=1;;i+=1)
			SVAR/Z tform= $"TFORM"+num2str(i)
			if( !SVAR_Exists(tform) )
				break
			endif
			SVAR/Z TTYPE= $"TTYPE"+num2str(i)
			if (stringmatch(TTYPE,what2))
				NVAR TCST= $"TCST"+num2str(i)
				break
			endif
		endfor
			
		setdatafolder root:fits:data
	
//		make /o/N=1 root:FITS:prog
		variable /g root:progress 
		variable swap =( stringmatch(what2,"ses100_image")||stringmatch(what2,"Swept_Spectra*"))
		openprogresswindow("Export Progress",naxis2)
//		execute "root:progress :=	root:FITS:prog[0]"
//		variable/g root:fits:tgID=ThreadGroupCreate(1)
//		NVAR tgID=root:fits:tgID
//		If(1)
//			ThreadStart tgID,0,LoadMovie(refnum,w3d,wht,dataoffset,TCST,naxis1,naxis2,xb,yb,swap,root:FITS:prog)
//			CtrlNamedBackground Fits7exportbkg,period=100,proc=Fits7export_bkg,start
//		else
			LoadMovie(refnum,w3d,wht,dataoffset,TCST,naxis1,naxis2,xb,yb,swap,root:FITS:prog)
			FITS7_finish3Dexport()
//		endif
	endif
	setdatafolder $orgfolder
end

Function LoadMovie(refnum,dest,buf,dataoffset,colstart,naxis1,naxis2,xb,yb,swap,prog)
//==============
	Variable refnum	
	variable colstart,xb,yb,swap,dataoffset
	wave dest,buf,prog
	variable NAXIS1,NAXIS2

//	Variable emode= CmpStr( IgorInfo(4 ),"PowerPC")==0 ? 1 : 2;	// ASSUME: platforms other than Mac are little endian (need better indication). See Redimension's new /E flag for meaning of emode
		redimension /N=(-1,-1,0,0) buf
	variable timerRefNum, loadtime
	timerRefNum = startMStimer
			
	Variable i
	for (i=0; i<naxis2; i+=1)
		updateprogresswindow(i)
//		prog[0]=i
		FSetPos refnum,dataoffset+naxis1*(i) + colstart	//ER
		fbinread /b=2 refnum,buf	

		if(0*(xb==1)*(yb==1))					// no rebinning
			if(swap)
				//dest[][][i]=buf[p][q][0]
				ImageTransform  /P=(i) /D=buf setPlane dest
			else			
				dest[][][i]=buf[q][p][0]
			endif
		else
			variable i1,j1
			if(swap)
		#if exists("Binandcopy2dto3d")
				Binandcopy2dto3d(dest,i,buf,xb,yb)
		#else
				dest[][][i]=0
				for(i1=0;i1<xb;i1+=1)
					for(j1=0;j1<yb;j1+=1)
						dest[][][i] += buf[p*xb+i1][q*yb+j1]
					endfor
				endfor
		#endif
			else
			#if exists("Binandcopy2dto3d")
				matrixtranspose buf
				Binandcopy2dto3d(dest,i,buf,yb,xb)
				matrixtranspose buf
			#else
				dest[][][i]=0
				for(i1=0;i1<xb;i1+=1)
					for(j1=0;j1<yb;j1+=1)
						dest[][][i] += buf[q*xb+i1][p*yb+j1]
					endfor
				endfor
			#endif
			endif
		endif
	endfor
	redimension /N=(-1,-1,1,0) buf

	loadtime = round( stopMStimer( timerRefnum )/1E5)/10
	if (loadtime>4)
		print "load time:: ", loadtime, " sec"
	endif
end

//Function Fits7export_bkg(s)
//	STRUCT WMBackgroundStruct &s
//
//	String dfSav= GetDataFolder(1)
//
//	SetDataFolder root:fits:
//	NVAR tgID
//	
//	variable tgs= ThreadGroupWait(tgID,100)
//	if(tgs==0)
//		variable dummy= ThreadGroupRelease(tgID)	
//		FITS7_finish3Dexport()
//		
//		SetDataFolder dfSav
//		return 1
//	endif		
//	SetDataFolder dfSav
//	return 0
//End


function FITS7_finish3Dexport()
//=====================
	SVAR ctrlName=root:fits:exportctrlname
	ControlInfo/w=FITS7_Panel extMovies
	if(V_flag<0)
		return 1
	endif	
	string what=s_value
	variable suffix=1, expopt=2
	NVAR extEditing=root:FITS:extEditing
	SVAR binfactor=root:FITS:BinFactor
	NVAR bin=root:FITS:bin
	string bf=binfactor
	if (bin==0)
		bf="1,1"
	endif
	controlinfo /w=FITS7_Panel fitssuffix
	suffix=V_Value
	
	string nam=stringfromlist(itemsinlist(what,":")-1,what,":")
	string wnam = 	exportname(suffix,nam)
	string what2=what

	what="root:FITS:data:extension"+num2str(extEditing)+":"+what
	WAVE wht=$what
	variable notmovie=(wavedims(wht)<3)
	variable xb=str2num(stringfromlist(0,bf,",")),  yb=str2num(stringfromlist(1,bf,","))
       SVAR exportname=root:fits:exportname
	WAVE w3d=$exportname
	string oldfolder=getdatafolder(1)
		
	setdatafolder $"root:fits:data:extension"+num2str(extEditing)

	variable swap =( stringmatch(what2,"ses100_image")||stringmatch(what2,"Swept_Spectra*"))
	NVAR refnum=root:fits:exportrefnum

	close refnum
	closeprogresswindow()
	
	note /K w3d
	note  w3d,  FITS7_GetVariables(0)
	setdatafolder $oldfolder
		
	NVAR estep=root:FITS:estep, astep=root:FITS:astep
	SVAR smode=root:FITS:smode
	wave data2D = root:Fits:data2D
		
	// set scaling for image from loaded 2d wave
	if(swap)
		SetScale/P x dimoffset(wht,0),dimdelta(wht,0)*xb, waveunits(wht,0),w3d
		SetScale/P y dimoffset(wht,1),dimdelta(wht,1)*yb, waveunits(wht,1),w3d
	else
		SetScale/P x dimoffset(wht,1),dimdelta(wht,1)*yb, waveunits(wht,1),w3d
		SetScale/P y dimoffset(wht,0),dimdelta(wht,0)*xb, waveunits(wht,0),w3d
	endif
	//endif
	if(exists("root:FITS:data:Primary:LWLVNM"))
		SVAR scantype = root:FITS:data:Primary:LWLVNM
		strswitch (scantype)
			case "XY Scan":
			case "Two Motor":
			case "Two Beamline":
			case "XY Motor Scan":
			case "XY Piezo Scan":

				NVAR st0 =  root:fits:data:Primary:ST_0_0
				NVAR n0=root:fits:data:Primary:N_0_0
				NVAR en0 = root:fits:data:Primary:EN_0_0
				SVAR nm0 =  root:fits:data:Primary:NM_0_0
				NVAR st1 =  root:fits:data:Primary:ST_0_1
				NVAR n1=root:fits:data:Primary:N_0_1
				NVAR en1 = root:fits:data:Primary:EN_0_1
				SVAR nm1 =  root:fits:data:Primary:NM_0_1
				variable dm0=dimsize(w3d,0), dm1=dimsize(w3d,1)	
				redimension /N=(dm0*dm1*n0*n1) w3d
				redimension /N=(dm0,dm1,n0,n1) w3d
				SetScale/P z st0,(en0-st0)/(n0-1),nm0, w3d
				SetScale/P t st1,(en1-st1)/(n1-1),nm1, w3d
				break
			case "PowerMotor":
				NVAR st0 =  root:fits:data:Primary:ST_0_0
				NVAR n0=root:fits:data:Primary:N_0_0
				NVAR en0 = root:fits:data:Primary:EN_0_0
				SVAR nm0 =  root:fits:data:Primary:NM_0_0
				NVAR st1 =  root:fits:data:Primary:ST_1_0
				NVAR n1=root:fits:data:Primary:N_1_0
				NVAR en1 = root:fits:data:Primary:EN_1_0
				SVAR nm1 =  root:fits:data:Primary:NM_1_0
				 dm0=dimsize(w3d,0)
				 dm1=dimsize(w3d,1)	
				redimension /N=(dm0*dm1*n0*n1) w3d
				redimension /N=(dm0,dm1,n0,n1) w3d
				SetScale/P z st0,(en0-st0)/(n0-1),nm0, w3d
				SetScale/P t st1,(en1-st1)/(n1-1),nm1, w3d
				break
			case "One Motor":
			case "Beamline":
//			case "Photon[eV]":
			case "DAC":
			case "Manual":	
			case "Beta_Compensated":							// added 3/7/09
				NVAR st0 =  root:fits:data:Primary:ST_0_0
				NVAR n0=root:fits:data:Primary:N_0_0
				NVAR en0 = root:fits:data:Primary:EN_0_0
				SVAR nm0 =  root:fits:data:Primary:NM_0_0
				SetScale/P z st0,(en0-st0)/(n0-1),nm0, w3d
				break
			case "Photon [eV]":
				WAVE mono_eV = root:fits:data:Extension1:mono_Ev 
				SetScale /P z mono_ev[0],mono_ev[1]-mono_ev[0],"eV", w3d	
				break
			default:
				WAVE d1=root:FITS:data1D
				variable zoffset=round(1E3*d1[0])/1E3, zdelta=round(1E3*( d1[1]-d1[0]))/1E3
				//print zoffset, zdelta
				if (zdelta>0)
					SetScale/P z zoffset, zdelta,"" w3d
				endif
		endswitch
	endif
	
	if (dimsize(w3d,2)==1)
		redimension/n=(dimsize(w3d,0),dimsize(w3d,1),0) w3d
	endif	

	if (stringmatch(ctrlName,"imgtool*"))
		openinImagetool(wnam)
	endif
end








//extract file number out of fname
function/T extractNumber7(fname)
//===================
	string fname
	string s1=fname[strsearch(fname,"_",0)+1,strlen(fname)-1]
	string s2=s1[0,strsearch(s1,".",0)-1]
	return s2
end


function binIt7(wv,xb,yb,p,q,transp)
//==========
	wave wv
	variable xb,yb,p,q,transp
	variable i,j,ans=0
	for(i=0;i<xb;i+=1)
		for(j=0;j<yb;j+=1)
			if(transp)
				ans+=wv[q*xb+i][p*yb+j]			//AB
				//ans+=wv[q*xb+j][p*yb+i]	
			else
				ans+=wv[p*xb+i][q*yb+j]
			endif
		endfor
	endfor
	return ans
end



// combine updGraph, updImginGraph and updMovieinGraph -- jdd
Function FITS7_UpdatePreview(ctrlName,popNum,popStr) : PopupMenuControl
//======================
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR plot2dmode=root:fits:plot2dmode
	// plot2dmode =-1
	strswitch (ctrlName)
		case "extSpectra":
			NVAR iSpectra=root:FITS:iSpectra
			iSpectra=popNum
			break
		case "extImages":
			plot2dMode=0
			break
		case "extMovies":
			plot2dMode=1
	endswitch
	FITS7_UpdateGraph()
End

Function FITS7_UpdateGraph()
//===============

	controlinfo/w=FITS7_Panel extSpectra
	s_value=""
	controlinfo/w=FITS7_Panel extSpectra
	string ss=s_value
	s_value=""
	controlinfo/w=FITS7_Panel extImages
	string is=s_value
	s_value=""
	controlinfo/w=FITS7_Panel extMovies
	string ms=s_value
	NVAR ee=root:fits:extediting
	NVAR plot2dmode=root:fits:plot2dmode
	string dfname="root:fits:data:Extension"+num2str(ee)+":"
	wave d1=root:fits:data1D, d2=root:fits:data2D
	variable refnum
	string wl = tracenamelist("FITS7_Panel",";",1)
	variable num=itemsinlist(wl,";")
	variable i
	for(i=0;i<num;i+=1)
		removefromgraph /W=FITS7_PANEL /Z $(stringfromlist(i,wl,";"))
	endfor
	
	redimension/n=(2,2) d2
	d2=NaN
	
	NVAR nscan=root:fits:NSCAN
	if(strlen(ss))
		Button append1d,size={20,20},proc=Export1D,title="A"
		if(cmpstr(ss,"all")==0)
			string slist = FITS7_GetDataList(ee,1)			//Getspectra(ee)
			slist=ReduceList(slist,"!*null")
			variable ni = itemsinlist(slist)
			for(i=1;i<ni-1;i+=1)	                     // don't include time or all
				ss = stringfromlist(i,slist)
				wave spec = $(dfname+"'"+ss+"'")
				appendtograph spec				// condition;update loop variables
			endfor								// execute body code until continue test is FALSE
		else
			string s2=dfname+ss
			wave spec=$(dfname+"'"+ss+"'")
			appendtograph spec
		endif
	endif
	svar fpath=root:fits:filpath
	svar fname=root:fits:filnam
	string oldfolder=getdatafolder(1)
	
	NVAR hasimages=$(dfname+"hasimages")
	NVAR extediting=root:fits:extediting
	if (Nscan==1)
		if(strlen(is))
			appendtograph /r/t $(dfname+"'"+is+"'")
		endif
	endif
	if ((hasimages==0)*(itemsinlist(FITS7_GetDataList(extediting, 2))==0))
		if(cmpstr(ss,"all")!=0)		
			if(exists("root:FITS:data:Primary:LWLVNM"))
				SVAR scantype = root:FITS:data:Primary:LWLVNM
				strswitch (scantype)
					case "XY Scan":
					case "Two Motor":
					case "Two Beamline":
					case "XY Motor Scan":
					case "XY Piezo Scan":					
					duplicate /o spec, d2
					NVAR st0 =  root:fits:data:Primary:ST_0_0
					NVAR n0=root:fits:data:Primary:N_0_0
					NVAR en0 = root:fits:data:Primary:EN_0_0
					SVAR nm0 =  root:fits:data:Primary:NM_0_0
					NVAR st1 =  root:fits:data:Primary:ST_0_1
					NVAR n1=root:fits:data:Primary:N_0_1
					NVAR en1 = root:fits:data:Primary:EN_0_1	
					SVAR nm1 =  root:fits:data:Primary:NM_0_1
					redimension /N=(n0,n1) d2
					SetScale/I x st0,en0,nm0, d2
					SetScale/I y st1,en1,nm1, d2
					removefromgraph /W=FITS7_PANEL  $ss
					Button append1d,size={20,20},proc=Export1D,title="IT"
					break
				endswitch
			endif
		endif
	elseif((plot2dmode==1)+(itemsinlist(FITS7_GetDataList(extediting, 2))==0))
		if(strlen(ms))
			NVAR nc=root:fits:cycEditing
			open/r refnum as fpath+fname
			setdatafolder root:fits:data
			loadfitsextensionN(refnum,ee,nc,0)
			setdatafolder $oldfolder
			close refnum
			wave movie=$(dfname+"'"+ms+"'")
			//redimension/n=(dimsize(movie,0), dimsize(movie,1)) d2
			//setscale/i x dimoffset(movie,0), dimdelta(movie,0),waveunits(movie,0),d2
			//setscale/i y dimoffset(movie,1), dimdelta(movie,1),waveunits(movie,1),d2
			if(stringmatch(ms,"ses100_image*")||stringmatch(ms,"Swept_Spectra*"))
				redimension/n=(dimsize(movie,0), dimsize(movie,1))/i d2	//**
				d2=movie[p][q][0]
				setscale/p x dimoffset(movie,0), dimdelta(movie,0), waveunits(movie,0),d2
				setscale/p y dimoffset(movie,1), dimdelta(movie,1), waveunits(movie,1), d2
			else
				redimension/n=(dimsize(movie,1), dimsize(movie,0))/i d2	//**
				d2=movie[q][p][0]
				setscale/p x dimoffset(movie,1), dimdelta(movie,1), waveunits(movie,1), d2
				setscale/p y dimoffset(movie,0), dimdelta(movie,0), waveunits(movie,0), d2
			endif
		endif
	elseif((plot2dmode==0)+(hasimages==0))
		if(strlen(is))
			wave img=$(dfname+"'"+is+"'")
			duplicate/o img d2
			SetAxis/A right
		endif
	endif	
	
	wave ct = root:fits:ct
	imagestats d2
	setscale/i x v_min, v_max,ct
end


function/T FITS7_GetVariables(extnum)
//================
// extnum=0,  get variables from primary header
	variable extnum
	string dsv=getdatafolder(1)
	if (extnum==0)
		setdatafolder $"root:fits:data:primary:"
	else
		setdatafolder $"root:fits:data:Extension"+num2str(extnum)+":"
	endif
	
	string vlst=variablelist("*",";",6), slist=stringlist("!*_Comment",";") , clist=stringlist("*_Comment",";") 
	variable ilist=itemsinlist(vlst)
	string strg="-------------- VARIABLES --------------;",comment
	variable i,cindex
	string nm
	for(i=0; i<ilist; i+=1)
		nm=stringfromlist(i,vlst)
		nvar nn=$nm
		if (whichlistitem(nm,"K0;K1;K2;K3;K4;K5;K6;K7;K8;K9;K10;K11;K12;K13;K14;K15;K16;K17;K18;K19;K20")<0) 
			cindex=whichlistitem(nm+"_Comment",clist)
			if(cindex>0)
				svar cmt = $(nm+"_Comment")
				comment=" /"+cmt
			else
				comment =""
			endif
			strg+=stringfromlist(i,vlst)+"="+num2str(nn)+comment+";"
		endif
	endfor
	strg+="-------------- STRINGS --------------;"
	ilist=itemsinlist(slist)
	string sn
	for(i=0; i<ilist; i+=1)
		sn = stringfromlist(i,slist)
		svar ss=$sn
		cindex=whichlistitem(sn+"_Comment",clist)
		if(cindex>0)
			svar cmt = $(sn+"_Comment")
			comment=" /"+cmt
		else
			comment =""
		endif
		strg+= sn+"="+ss+comment+";"
	endfor
	setdatafolder $dsv
	return strg
end

Function/T FITS7_GetDataList(extnum, dim)
//===================
// extnum=0,  get data from primary header
	variable extnum, dim
	if (!(datafolderexists("root:fits:data:primary")*datafolderexists("root:fits:data:Extension"+num2str(extnum))))
		return ""
	endif
	string dsv=getdatafolder(1)
	if (extnum==0)
		setdatafolder $"root:fits:data:primary:"
	else
		setdatafolder $"root:fits:data:Extension"+num2str(extnum)+":"
	endif
	string wvlst=WaveList("*",";","DIMS:"+num2str(dim))
	if (dim==1)	// strip off 'time0' & 'null'
		//wvlst=ReduceList(wvlst,"!*time0")	//whoever removed time0 from the list DON't DO IT AGAIN - ER
		wvlst=ReduceList(wvlst,"!*null")
		wvlst += "All;"
	endif
	setdatafolder $dsv
	return wvlst
end
 




Proc FITS7_StepFile(ctrlName) : ButtonControl
	//====================
	String ctrlName
	
	PauseUpdate
	variable filnum=root:FITS:filnum
	string filnam
	if (cmpstr(ctrlName,"StepMinus")==0)
		filnum=max(1, root:FITS:filnum-1)
	endif
	if (cmpstr(ctrlName,"StepPlus")==0)
		filnum=min(root:FITS:numfiles, root:FITS:filnum+1)
	endif
	filnam=StringFromList( filnum-1, root:FITS:fileList, ";")
	PopupMenu popup_file mode=filnum
	ListBox listFITSfiles selRow=filnum-1, row=max(0,filnum-3)
	//print filnam, filnum
	FITS7_SelectFile( "", filnum, filnam )
End

Window FITS7_Panel() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(949,60,1357,672) as "Load_FITS7_Panel"
	AppendImage/T/R :FITS:data2D
	ModifyImage data2D ctab= {*,*,Grays,0}
	ModifyGraph cbRGB=(64512,62423,1327)
	ModifyGraph mirror=0
	ModifyGraph fSize=8
	ModifyGraph axOffset(right)=-1.6,axOffset(top)=-0.8
	Label top " "
	TextBox/N=text0/F=0/S=3/H=14/A=MT/X=-2.30/Y=4.86/E "\\{root:FITS:filnam}:  \\{root:FITS:smode}, \\{root:FITS:hv} eV, \\{root:FITS:scantyp}"
	ControlBar 327
	TitleBox version,pos={283,5},size={21,12},title="v3.57",frame=0,fStyle=2
	PopupMenu popFolder,pos={11,1},size={94,20},proc=FITS7_SelectFolder,title="Data Folder"
	PopupMenu popFolder,mode=0,value= #"root:FITS:folderList"
	SetVariable setlib,pos={11,23},size={300,15},title=" ",fSize=9
	SetVariable setlib,value= root:FITS:filpath
	PopupMenu popup_file,pos={80,299},size={177,20},proc=FITS7_SelectFile,title="File"
	PopupMenu popup_file,mode=55,popvalue="20051220_00054.fits",value= #"root:FITS:fileList"
	ListBox listFITSfiles,pos={12,44},size={200,75},proc=FITS7_SelectFileLB,frame=4
	ListBox listFITSfiles,listWave=root:FITS:fileListw,selWave=root:FITS:fileSelectw
	ListBox listFITSfiles,colorWave=root:FITS:fileColors,row= 50,mode= 2
	ListBox listFITSfiles,widths={70,35}
	Button FileUpdate,pos={226,3},size={50,16},proc=FITS7_UpdateFolder,title="Update"
	Button StepMinus,pos={23,300},size={20,18},proc=FITS7_StepFile,title="<<"
	Button StepPlus,pos={52,300},size={20,18},proc=FITS7_StepFile,title=">>"
	ValDisplay numExts,pos={117,148},size={80,14},title="# Exts"
	ValDisplay numExts,limits={0,0,0},barmisc={0,1000}
	ValDisplay numExts,value= #"root:fits:data:primary:NExtension"
	PopupMenu extVars,pos={7,166},size={337,20},title="Variables"
	PopupMenu extVars,mode=1,popvalue="-------------- VARIABLES --------------",value= #"FITS7_GetVariables(root:fits:extEditing)"
	SetVariable extEditing,pos={8,148},size={100,15},proc=setVarExtn7,title="Which Extn"
	SetVariable extEditing,limits={1,1,1},value= root:FITS:extEditing
	PopupMenu Vars,pos={5,125},size={337,20},title="Variables"
	PopupMenu Vars,mode=1,popvalue="-------------- VARIABLES --------------",value= #"FITS7_GetVariables(0)"
	PopupMenu extSpectra,pos={7,189},size={79,20},proc=FITS7_UpdatePreview,title="Spectra"
	PopupMenu extSpectra,mode=1,value= #"FITS7_GetDataList(root:fits:extEditing,1)"
	PopupMenu extImages,pos={7,212},size={152,20},proc=FITS7_UpdatePreview,title="Images"
	PopupMenu extImages,mode=1,value= #"FITS7_GetDataList(root:fits:extEditing,2)"
	PopupMenu extMovies,pos={9,235},size={103,20},proc=FITS7_UpdatePreview,title="Movies"
	PopupMenu extMovies,mode=1,value= #"FITS7_GetDataList(root:fits:extEditing,3)"
	SetVariable cycle,pos={181,237},size={80,15},proc=SetCycle7,title="cycle"
	SetVariable cycle,limits={0,0,1},value= root:FITS:cycEditing
	Button export3d,pos={275,234},size={20,20},proc=Export3D,title="E"
	Button imgtool3d,pos={301,234},size={20,20},proc=Export3D,title="IT"
	Button display2d,pos={275,212},size={20,20},proc=Export2D,title="D"
	Button imgtool2d,pos={301,212},size={20,20},proc=Export2D,title="IT"
	Button display1d,pos={275,190},size={20,20},proc=Export1D,title="D"
	Button append1d,pos={301,190},size={20,20},proc=Export1D,title="A"
	SetVariable lwlvl,pos={270,280},size={100,16},title=" ",fSize=9
	SetVariable lwlvl,value= root:FITS:skind
	SetVariable motornames,pos={270,296},size={100,16},title=" ",fSize=9
	SetVariable motornames,value= root:FITS:scantyp			//mnames  -JDD 3/3/09
	SetVariable sesmode,pos={238,44},size={70,16},title=" ",fSize=9
	SetVariable sesmode,value= root:FITS:smode
	SetVariable binfact,pos={292,261},size={30,15},proc=SetBinVal,title=" ",fSize=9
	SetVariable binfact,value= root:FITS:binFactor
	CheckBox bincheck,pos={258,261},size={32,14},proc=SetBin,title="Bin"
	CheckBox bincheck,variable= root:FITS:bin
	SetVariable tdim,pos={87,261},size={95,15},title=" TDIM",value= root:FITS:Nxy
	SetVariable NAXIS2,pos={192,261},size={55,15},title="x",value= root:FITS:Nscan
	SetVariable dE,pos={87,280},size={75,15},title="dE",value= root:FITS:Estep
	SetVariable dA,pos={184,281},size={70,15},title="dA",value= root:FITS:Astep
	SetVariable monoev,pos={249,61},size={70,15},title=" hv",value= root:FITS:hv
	//	CheckBox specsuffix,pos={327,193},size={75,14},title="FITS Suffix?",value= 0
	SetVariable Prebin,pos={15,260},size={65,15},title="PreBin"
	SetVariable Prebin,value= root:FITS:EAbin
	SetVariable Erange,pos={235,76},size={90,15},bodyWidth=80,title="E",value= root:FITS:Erng
	SetVariable Arange,pos={235,91},size={90,15},bodyWidth=80,title="A",value= root:FITS:Arng
	SetVariable Brange,pos={235,106},size={90,15},bodyWidth=80,title="B",value= root:FITS:Brng
	//	SetVariable tdim,pos={123,241},size={95,16},title=" TDIM",value= root:FITS:TDIM
	//	SetVariable NAXIS2,pos={219,241},size={55,16},title="x",value= root:FITS:NAXIS2
	//	PopupMenu iEpass,pos={15,217},size={76,21},proc=SetEpass,title="Ep"
	//	PopupMenu iEpass,mode=5,popvalue="20",value= #"\"1;2;5;10;20;50\""
	//	SetVariable dE,pos={83,219},size={75,16},title="dE",value= root:FITS:Estep
	//	SetVariable dA,pos={170,219},size={70,16},title="dA",value= root:FITS:Astep
	//	SetVariable monoev,pos={151,198},size={70,16},title=" hv"
	//	SetVariable monoev,value= root:FITS:MONOEV
	//	CheckBox specsuffix,pos={332,133},size={80,14},title="FITS Suffix?",value= 0
	//	CheckBox it5,pos={332,155},size={80,14},title="Imagetool5?",value= 0
	PopupMenu it5,pos={332,212},size={76,21}
	PopupMenu it5,mode=1,popvalue="Imagetool",value= #"\"Imagetool;Newimagetool;Imagetool5\""
	PopupMenu fitssuffix,pos={332,234},size={76,21}
	PopupMenu fitssuffix,mode=1,popvalue="No Suffix",value= #"\"No Suffix;Fits Suffix;Short Suffix\""


	SetVariable setgamma pos={0,327},size={52,14},title="g"
	SetVariable setgamma,help={"Gamma value for image color table mapping.  Gamma < 1 enhances lower intensity features."}
	SetVariable setgamma,font="Symbol"
	SetVariable setgamma,limits={0.1,Inf,0.1},value=root:FITS:gamma
	//CheckBox lockColors,pos={219,26},size={80,14},proc=ColorLockCheck,title="Lock colors?"
	//CheckBox lockColors,value= 0
	checkbox invertCT,pos={105,328},size={80,14},title="Invert?"
	checkbox invertCT,variable=root:FITS:invertCT 
	PopupMenu SelectCT,pos={56,325},size={43,20},proc= FITS7_SelectCTList,title="CT"
	PopupMenu SelectCT,mode=0,value= #"colornameslist()"

EndMacro


proc FITS7_DoPrefs(Imagetool,shortsuffix,kmapSampling)
	variable aspect=1+$("root:fits:Imagetool")
	variable rescale=1+$(getdf()+"rescaleAfterReZero")
	variable kmapSampling=$(getdf()+"kmapSampling")
	prompt aspect, "Aspect ratio", popup "free;1:1"
	prompt rescale, "Rescale after Rezeroing", popup "no;yes"
	prompt kmapSampling, "K-map sampling (1=ok, >1 means better/slower)"
	string df=getdf()
	$(df+"aspect")=aspect-1
	$(df+"rescaleafterrezero")=rescale-1
	$(df+"kmapSampling")=kmapSampling
	if($(df+"aspect"))
		ModifyGraph width={Plan,1,bottom,left}
	else
		ModifyGraph width=0
	endif
end





Function FITS7_SelectCTList(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string df="root:fits:"
	nvar  whichCT=$(df+"whichCT")
	whichCT=popnum-1
End



 function openinImagetool(wn)
	string wn
	controlinfo /w=FITS7_Panel it5
	variable it5 = V_Value

	string df=getdatafolder(1)
	setdatafolder root:
	wave w = $wn
	if ((wavedims(w)==2)||((it5<3)&&(wavedims(w)<4)))
		if(it5==1)
			DoWindow/F ImageTool
			if (V_flag==0)
				Execute "ShowImageTool()"
			endif
			execute "NewImg(\""+wn+"\")"
		else
			newimagetool( wn )
		endif
	elseif ((it5==3)||(wavedims(w)==4))
		execute "newimagetool5(\""+wn+"\")"
	endif
	setdatafolder $df
end

 function /S exportname(suffix,fitsnam)
	variable suffix
	string fitsnam
	
	SVAR filnam=root:fits:filnam
	string wn
	switch (suffix)
		case 0:
		case 1:
			wn=cleanupname("f"+extractnumber7(filnam),0)
			break
		case 2:
			wn=cleanupname("f"+extractnumber7(filnam)+"_"+fitsnam,0)
			break
		case 3:
			string suff
			if(stringmatch( fitsnam,"Fixed_Spectra*"))
				suff = "FS"+fitsnam[13,14]
			elseif(stringmatch( fitsnam,"Swept_Spectra*"))
				suff = "SS"+fitsnam[13,14]
			elseif(stringmatch( fitsnam,"I0_NEXAFS*"))
				suff ="I0"
			elseif(stringmatch( fitsnam,"IG_NEXAFS*"))
				suff="IG"
			elseif(stringmatch( fitsnam,"CRYO-*"))
				suff = fitsnam[5,20]
			else
				suff=fitsnam
			endif
			
			wn=cleanupname("f"+extractnumber7(filnam)+"_"+suff,0)
			break
	endswitch
	return wn
end
	
