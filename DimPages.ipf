#pragma rtGlobals=3		// Use modern global access method and strict wave access.





// (C) Dmitry Marchenko       Helmholtz-Zentrum Berlin, BESSY II, 2017-2018
// version 2018-05-15




Menu "DimPages"
	"Open DimPages panel", DimPagesStart()
	"Show DimPages help", Show_DimPages_Help()
End



Function Show_DimPages_Help()
	DoWindow/F DimPages_Help
	If (V_Flag!=0)
		DoWindow/K DimPages_Help
	EndIf
	NewNotebook/F=0/K=1/OPTS=12/N=DimPages_Help as "DimPages help"
	Notebook DimPages_Help text="(c) Dmitry Marchenko, Helmholtz-Zentrum Berlin, 2017-2018 \r"
	Notebook DimPages_Help text="\r"
	Notebook DimPages_Help text="DimPages panel \r"
	Notebook DimPages_Help text="version 10.03.2019 \r"
	Notebook DimPages_Help text="\r"
	Notebook DimPages_Help text="The panel allows to organize the Igor Pro working area by creating pages.\r"
	Notebook DimPages_Help text="\r"
	Notebook DimPages_Help text="[Mouse click] opens a page. Additionally it moves all unsaved windows there.\r"
	Notebook DimPages_Help text="[Shift + mouse click] moves the active window to the selected page.\r"
	Notebook DimPages_Help text="[Double mouse click] allows to rename a page.\r"
	Notebook DimPages_Help text="[Drag by mouse] - sorting pages order.\r"
	Notebook DimPages_Help text="[Keyboard up/down buttons] open previous/next page.\r"
	Notebook DimPages_Help text="\r"
	Notebook DimPages_Help text="Any questions/comments/suggestions => E-mail: marchenko.dmitry@gmail.com\r"
End


Window DimPages() : Panel
	PauseUpdate; Silent 1
	NewPanel /K=1/W=(54.6,52.8,274.8,525.6) as "DimPages panel"
	ModifyPanel frameStyle=1
	ListBox pagesPanelList,pos={9.00,9.00},size={204.00,459.00},proc=pagesPanelListProc
	ListBox pagesPanelList,fSize=14,listWave=root:DPages:nDPages,mode= 2,selRow= 3
EndMacro



Function DimPagesStart()
	String savedDF= GetDataFolder(1)
	NewDataFolder/O/S root:DPages

	If (!exists("nDWindows"))
		Make/T/O/N=(0,2) 'nDWindows'
	EndIf

	If (!exists("nDPages"))
		Make/T/O/N=1 'nDPages'
	EndIf

	If (!exists("nDcurpage"))
		Variable/G 'nDcurpage'
		'nDcurpage'=0	
	EndIf
	If (!exists("nDrenaming"))
		Variable/G 'nDrenaming'
		'nDrenaming'=0	
	EndIf
	NVAR 'nDcurpage'=root:DPages:'nDcurpage'

	If (!exists("nDdownrow"))
		Variable/G 'nDdownrow'
		'nDdownrow'=-1
	EndIf
	NVAR 'nDdownrow'=root:DPages:'nDdownrow'

	DoWindow/F DimPages
	If (V_Flag!=0)
		DoWindow/K DimPages
	EndIf
	String cmd
	sprintf cmd, "DimPages()"
	Execute/P cmd
	
	SetDataFolder savedDF
	DoUpdate
	checkDWindowsExistence()
End



Function inDimPagesWhiteList(wname)
	String wname
	Variable result=0
	If (CmpStr(wname,"DimPages")==0)
		result=1
	EndIf
	If (CmpStr(wname,"WMImageRangeGraph")==0)
		result=1
	EndIf
	If (CmpStr(wname,"WMImageFilterPanel")==0)
		result=1
	EndIf	
	If (CmpStr(wname,"DimPages_Help")==0)
		result=1
	EndIf	
	return result
End




Function newDPage()
	String savedDF= GetDataFolder(1)
	SetDataFolder root:DPages 
	NVAR 'nDcurpage'=root:DPage:'nDcurpage' 
	'nDcurpage'=DfindMaxPage()+1
	saveDWindows('nDcurpage')
	checkDWindowsExistence()
	SetDataFolder savedDF
End



Function saveDWindows(pageNumber)
	Variable pageNumber
	String savedDF= GetDataFolder(1)
	SetDataFolder root:DPages	
	Wave/T 'nDWindows'
	Wave/T 'nDPages'
	NVAR 'nDcurpage'=root:DPages:'nDcurpage'

	String str
	Variable i
	String list = WinList("*", ";","WIN:87,VISIBLE:1") 
	Variable n=0
	Do 
		str=StringFromList(n,list)
		n+=1
	While (StringMatch(str,"")==0)
	Variable pagesDynamicSize=0
	For (i=0;i<n-1;i+=1)
		str=StringFromList(i,list)
		If (!inDimPagesWhiteList(str))
			pagesDynamicSize=DimSize('nDWindows',0)
			Variable found=-1
			Variable jj
			For (jj=0;jj<pagesDynamicSize;jj+=1)
				If (CmpStr('nDWindows'[jj][0],str)==0)	
					found=jj
				EndIf
			EndFor
			If (found>=0)
				'nDWindows'[found][1]=num2str('nDcurpage')
			Else
				Redimension/N=(pagesDynamicSize+1,2) 'nDWindows'
				'nDWindows'[pagesDynamicSize][0]=str
				'nDWindows'[pagesDynamicSize][1]=num2str('nDcurpage')
			EndIf
			SetWindow $str hide=1
		EndIf
	EndFor
	SetDataFolder savedDF
End


Function openDPage()
	closeAllDWindows()
	String savedDF= GetDataFolder(1)
	SetDataFolder root:DPages
	Wave/T 'nDWindows'
	NVAR 'nDcurpage'=root:DPages:'nDcurpage'
	Variable ii
	For (ii=0;ii<DimSize('nDWindows',0);ii+=1)
		If (str2num('nDWindows'[ii][1])=='nDcurpage')
			String str='nDWindows'[ii][0]
			SetWindow $str hide=0
		EndIf
	EndFor
	SetDataFolder savedDF
	checkDWindowsExistence()
End



Function pagesPanelListProc(ctrlName,row,col,event) : ListBoxControl
	String ctrlName
	Variable row
	Variable col
	Variable event	
	
	String savedDF= GetDataFolder(1)
	SetDataFolder root:DPages	
	NVAR 'nDcurpage'=root:DPages:'nDcurpage'
	NVAR 'nDdownrow'=root:DPages:'nDdownrow'
	NVAR 'nDrenaming'=root:DPages:'nDrenaming'
	Wave/T 'nDPages'
	Wave/T 'nDWindows'
	
	Variable executeOpen=0
	Variable executeDrag=0
	
	Variable code=enoise(1)
	
	If (!exists("nDrenaming"))
		Variable/G 'nDrenaming'
		'nDrenaming'=0	
	EndIf
	
	If ('nDdownrow'==-1)
		//print ">"
	EndIf	
	//print "- - -> DimPages: event=",event," row=",row," nDdownrow=",'nDdownrow', " nDcurpage=",'nDcurpage', " code=",code
	
   If ('nDrenaming'==0) // not renaming
	Switch (event)
		case 1: 
			// mouse down
			//print "        (mouse down)"
			'nDdownrow'=row
			break
		case 2: 
			// mouse up
			//print "        (mouse up)"
			If ('nDdownrow'>-1)
				If (row=='nDdownrow')
					executeOpen=1
					//print "- - -> DimPages: set executeOpen=1"
				Else 
					executeDrag=1
					//print "- - -> DimPages: set executeDrag=1"
				EndIf
			EndIf
			break
		case 3: 
			// mouse double click
			//print "        (mouse double click)"
			'nDrenaming'=1
			String pagenameprompt='nDPages'['nDcurpage']
			Prompt pagenameprompt, "   "
			DoPrompt "Enter the new page name", pagenameprompt
			if (V_Flag)
				SetDataFolder savedDF
				//print "        <rename cancelled>"
				return 0 // cancelled
			endif
			'nDPages'['nDcurpage']=pagenameprompt
			'nDrenaming'=0
			//print "        (exit mouse double click)"
			break
		case 4: 
			// cell select with mouse or keys
			//print "        (cell select)"
			If ('nDdownrow'==-1)
				executeOpen=1
			EndIf
			break
		case 5: 
			//print "- - -> DimPages: case5a :: row=",row," nDdownrow=",'nDdownrow'," nDcurpage=",'nDcurpage'
			// cell select with shift key
			//print "        (cell select with shift)"
			closeAllDWindows()
			//print "- - -> DimPages: case5b :: row=",row," nDdownrow=",'nDdownrow'," nDcurpage=",'nDcurpage'
			String wname=WinName(1,87) /// WIN
			Variable ii
			For (ii=0;ii<DimSize('nDWindows',0);ii+=1)
				If (CmpStr('nDWindows'[ii][0],wname)==0)
					'nDWindows'[ii][1]=num2str(row)
				EndIf
			EndFor
			//print "- - -> DimPages: case5c :: row=",row," nDdownrow=",'nDdownrow'," nDcurpage=",'nDcurpage'
			'nDcurpage'=row
			//print "- - -> DimPages: case5d :: row=",row," nDdownrow=",'nDdownrow'," nDcurpage=",'nDcurpage'
			//openDPage()
			//print "- - -> DimPages: case5e :: row=",row," nDdownrow=",'nDdownrow'," nDcurpage=",'nDcurpage'
		//
		//executeOpen=1
		//print "- - -> DimPages: set executeOpen=1"			
		//
			DoWindow/F DimPages
			break
		case 6: 
			//print "        (begin edit)"
			// begin edit
			break
		case 7: 
			print "        (end edit)"
			// end edit
			break
		default: 
			print "ERROR #UYQM3T in DimPages->pagesPanelListProc: Unknown event=",event 
			break
	EndSwitch
	EndIf // If not renaming
	
	If (executeOpen)
			//print "        [executeOpen]"
			closeAllDWindows()
			'nDcurpage'=row
			openDPage()
			DoWindow/F DimPages
			'nDdownrow'=-1
	EndIf
	If (executeDrag)
		//print "        [executeDrag]"
		DimPages_movePage('nDdownrow',row)
		'nDdownrow'=-1
	EndIf
	
	//print "        exit event=",event," row=",row," nDdownrow=",'nDdownrow', " nDcurpage=",'nDcurpage', " code=",code
	//print "- - -> DimPages: exit event=",event," row=",row," nDdownrow=",'nDdownrow'
	If ('nDdownrow'==-1)
		//print ">"
	EndIf	

	SetDataFolder savedDF
	return 0
End



Function DfindMaxPage()
	String savedDF= GetDataFolder(1)
	SetDataFolder root:DPages
	Variable maxPage=-1
	Wave/T 'nDWindows'
	Variable ii
	For (ii=0;ii<DimSize('nDWindows',0);ii+=1)
		If (str2num('nDWindows'[ii][1])>maxPage) 
			maxPage=str2num('nDWindows'[ii][1])
		EndIf
	EndFor
	SetDataFolder savedDF
	return maxPage
End



Function closeAllDWindows()
	String savedDF= GetDataFolder(1)
	SetDataFolder root:DPages
	Wave/T 'nDPages'
	Wave/T 'nDWindows'
	NVAR 'nDcurpage'=root:DPages:'nDcurpage'
	// list visible windows
	String str
	Variable i
	String list = WinList("*", ";","WIN:87,VISIBLE:1") 
	Variable n=0
	Do 
		str=StringFromList(n,list)
		n+=1
	While (StringMatch(str,"")==0)
	// close windows which are listed in 'nDWindows'
	For (i=0;i<n-1;i+=1)
		str=StringFromList(i,list)
		Variable jj
		For (jj=0;jj<DimSize('nDWindows',0);jj+=1)
			If (CmpStr(str,'nDWindows'[jj][0])==0)
				If (!inDimPagesWhiteList(str))
					SetWindow $str hide=1
				EndIf
			EndIf
		EndFor
	EndFor
	saveDWindows('nDcurpage') // save those who left
	SetDataFolder savedDF
	checkDWindowsExistence()
End



Function checkDWindowsExistence()
	String savedDF= GetDataFolder(1)
	SetDataFolder root:DPages
	Wave/T 'nDWindows'
	Wave/T 'nDPages'
	// sort 'nDWindows'
	Variable si,sj
	For (si=0;si<DimSize('nDWindows',0);si+=1)
	For (sj=0;sj<DimSize('nDWindows',0)-1;sj+=1)
			If (str2num('nDWindows'[sj+1][1])>str2num('nDWindows'[sj][1]))
				String tmp=""
				tmp='nDWindows'[sj][1]
				'nDWindows'[sj][1]='nDWindows'[sj+1][1]
				'nDWindows'[sj+1][1]=tmp
				tmp='nDWindows'[sj][0]
				'nDWindows'[sj][0]='nDWindows'[sj+1][0]
				'nDWindows'[sj+1][0]=tmp
			EndIf
	EndFor
	EndFor
	// minimize page numbers
	Variable uplimit=DfindMaxPage()
	Variable mi,mj
	For (mi=0;mi<uplimit;mi+=1)
		Variable found=0
		For (mj=DimSize('nDWindows',0)-1;mj>=0;mj-=1)
			If (str2num('nDWindows'[mj][1])==mi)
				found=1
			EndIf
		EndFor
		If (!found) 
			For (mj=DimSize('nDWindows',0)-1;mj>=0;mj-=1)
				If (str2num('nDWindows'[mj][1])>mi)
					'nDWindows'[mj][1]=num2str(str2num('nDWindows'[mj][1])-1)
				EndIf
			EndFor
			Variable pagesize=DimSize('nDPages',0)
			Variable rr
			For (rr=mi+1;rr<pagesize;rr+=1)
				'nDPages'[rr-1]='nDPages'[rr]
			EndFor
			//print pagesize,mi
			Redimension/N=(pagesize-1) 'nDPages'
			uplimit=DfindMaxPage()
		EndIf
	EndFor
	// check existence of windows mentioned in the 'nDWindows'
	Variable ii
	For (ii=0;ii<DimSize('nDWindows',0);ii+=1)
		String wname='nDWindows'[ii][0]
		Variable n=0
		String str=""
		String list = WinList(wname, ";","WIN:87") 
		Do 
			str=StringFromList(n,list)
			n+=1
		While (StringMatch(str,"")==0)		
		If (n==1)
			Variable jj
			For (jj=ii+1;jj<DimSize('nDWindows',0);jj+=1)
				'nDWindows'[jj-1][0]='nDWindows'[jj][0]
				'nDWindows'[jj-1][1]='nDWindows'[jj][1]
			EndFor
			Redimension/N=(DimSize('nDWindows',0)-1,2) 'nDWindows'
			ii=0
		EndIf
	EndFor
	// fill nDPages list
	//print "DfindMaxPage=",DfindMaxPage()
	Redimension/N=(DfindMaxPage()+2) 'nDPages'
	Variable index
	For (index=0;index<=DfindMaxPage();index+=1)
		If (CmpStr('nDPages'[index],"New page")==0)
			'nDPages'[index]="Page "+num2str(index)
		EndIf
		//print "   > ",index," "+'nDPages'[index]
	EndFor
	'nDPages'[DfindMaxPage()+1]="New page"
	SetDataFolder savedDF
End



Function DimPages_movePage(from,to)
	Variable from,to
	String savedDF= GetDataFolder(1)
	SetDataFolder root:DPages
	Wave/T 'nDPages'
	Wave/T 'nDWindows'
	
	Variable size=DimSize('nDPages',0)
	If (from>-1 && to>-1) 
		If (from!=to)
			If (size>2)
				If (from<size-1 && to<size-1)
				
					String tmpstr="ERROR #DTEF32"
					
					tmpstr='nDPages'[from]
					'nDPages'[from]='nDPages'[to]
					'nDPages'[to]=tmpstr
			
					Variable index
					For (index=0;index<DimSize('nDWindows',0);index+=1)
						If (str2num('nDWindows'[index][1])==from) 
							'nDWindows'[index][1]="-2"
						EndIf
					EndFor
					For (index=0;index<DimSize('nDWindows',0);index+=1)
						If (str2num('nDWindows'[index][1])==to) 
							'nDWindows'[index][1]=num2str(from)
						EndIf
					EndFor
					For (index=0;index<DimSize('nDWindows',0);index+=1)
						If (str2num('nDWindows'[index][1])==-2) 
							'nDWindows'[index][1]=num2str(to)
						EndIf
					EndFor
				
				EndIf
			EndIf
		EndIf
	EndIf
	
	// emulate mouse click on the current page
	pagesPanelListProc("pagesPanelList",to,0,1)
	pagesPanelListProc("pagesPanelList",to,0,2)
	
	SetDataFolder savedDF
End


