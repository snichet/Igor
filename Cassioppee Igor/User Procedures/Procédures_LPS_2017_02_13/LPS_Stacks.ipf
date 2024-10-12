
#pragma rtGlobals=1		// Use modern global access method.
#include <Readback ModifyStr>

// Procedures concerning stacks (copied from Jonathan Denlinger's ImageTool)
// Plus Procedures "AddStacks"

//Window		Stack_										: Graph
//Fct			UpdateStack(ctrlName) 						: ButtonControl 
//Proc 			SetOffset(ctrlName,varNum,varStr,varName) 		: SetVariableControl
//Fct			OffsetStack( shift, offset )
//Proc 			MoveCursor(ctrlName) 						: ButtonControl
//Proc			ExportStack

//  Add stacks procedures
//Proc  			DoAddStacksWindow(ctrlname):Buttoncontrol						// Button on Stack window : creates Add stacks window
//Fct			Add_Stack(ctrlname):ButtonControl									// "Add" button on Add Stacks window
//Fct			Refresh_Addedlimits(ctrlName,popNum,popStr) : PopupMenuControl	// Calculates limits for added image. 
//Fct			Refresh_ImageToolStacksLimits(ctrlname) :Buttoncontrol				// Refresh limits of stacks from ImageTool
//Fct			Refresh_AddStacks (ctrlName,varNum,varStr,varName) : SetVariableControl		// When step or avg value is changed : automatic refresh
//Addwave

//  Utilities (from image_util)

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////                 Stack Procs and Functions       //////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function Build_StackPannel()
variable i
string name
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	nvar offset_val=root:IMG:STACK:offset
	SetDataFolder root:IMG:STACK:
	Make/O/N=100 line0
	Display /W=(280,50,530,450) line0 as "STACK_"
	//i=1
	//do
	//	name="line"+num2str(i)
	//	AppendToGraph $name
	//	ModifyGraph offset($name)={0,offset_val*i}
	//	i+=1
	//while (i<Nblines)
	SetDataFolder fldrSav
	ModifyGraph cbRGB=(32769,65535,32768)
	ModifyGraph tick=2
	ModifyGraph zero(bottom)=2
	ModifyGraph mirror=1
	ModifyGraph minor=1
	ModifyGraph sep(left)=8,sep(bottom)=10
	ModifyGraph fSize=10
	ShowInfo
	ControlBar 51
	//shift
	SetVariable setshift,pos={6,2},size={80,16},proc=SetOffset,title="shift"
	SetVariable setshift,help={"Incremental X shift of spectra."}
	SetVariable setshift,limits={-Inf,Inf,0.0201709},value= root:IMG:STACK:shift
	SetVariable setoffset,pos={90,2},size={90,16},proc=SetOffset,title="offset"
	SetVariable setoffset,help={"Incremental Y offset of spectra."}
	SetVariable setoffset,limits={-Inf,Inf,0.2},value= root:IMG:STACK:offset
	//Button SaveCursor,pos={295,25},size={70,18},proc=save_cur,title="Save Cursors"
	Button AddStack,pos={13,25},size={70,18},proc=DoAddStacksWindow,title="Add Stacks"
	Button AddStack,help={"Add stack from another image"}
	Button Addwave,pos={109,25},size={70,18},proc=Addwave,title="Add Wave"
	Button MoveImgCsr,pos={210,2},size={70,18},proc=MoveCursor,title="Show "
	Button MoveImgCsr,help={"Reposition cross-hair in Image_Tool panel to the location of the A cursor placed in the Stack_ window."}
	Button ExportStack,pos={210,27},size={70,18},proc=ExportAction,title="Export"
	Button ExportStack,help={"Copy stack spectra to a new window with a specified basename.  Wave notes contain appropriate shift, offset, and Y-value information."}
	DoWindow/C Stack_
EndMacro

//================
Function CreateStack(ctrlName) : ButtonControl
	String ctrlName
	
	DoWindow/F Stack_
	if (v_flag==0)  // i.e. window does not exist
		Build_StackPannel()
	endif
	UpdateStack() 
end
	
Function UpdateStack() 
// Restart from scratch, except for pannel. Just Simpler !!
// Does not put pannel up front

	string curr=GetDataFolder(1)
	wave img=root:IMG:Image  // this is the image loaded in ImageTool
	// copy as "image" in stack directory, using only subset from marquee or current graph axes	
	variable x1, x2, y1, y2
	GetMarquee/K/W=ImageTool left, bottom
	if (V_Flag==1)
		x1=V_left; x2=V_right
		y1=V_bottom; y2=V_top
	else
		GetAxis/Q/W=ImageTool bottom 
		x1=V_min; x2=V_max
		GetAxis/Q/W=ImageTool left
		y1=V_min; y2=V_max
	endif
	Duplicate/O/R=(x1,x2)(y1,y2) img, root:IMG:Stack:Image
	wave imgstack=root:IMG:Stack:Image
	
	// Remove and kill previous stacks from graph
	string basen="root:IMG:STACK:line"
	SetDataFolder root:IMG:Stack:
	string trace_lst=WaveList("line*", ";","")
	variable nt
	nt=ItemsInList(trace_lst,";")//nt=nb de stacks dans le directory
	variable ii
	ii=0
	do
		RemoveFromGraph/Z/W=Stack_ $("line"+num2istr(ii))
		Killwaves/Z $("line"+num2istr(ii))
		ii+=1
	while( ii<nt )
	
	// Calculate new stacks
	nvar pinc=root:IMG:STACK:pinc
	WaveStats/Q imgstack
	variable/G root:IMG:STACK:dmin=V_min
	variable/G root:IMG:STACK:dmax=V_max 
	
	variable Nb_Stacks, nx, dir=0
	Nb_Stacks=round(DimSize(imgstack,1)/pinc)
		//Limit the number of stacks to 100
		if (Nb_Stacks>100)
		   do
			pinc+=1
			Nb_Stacks=round(DimSize(imgstack,1)/pinc)
		    while (Nb_Stacks>100)
		endif	
	Image2Waves( imgstack, basen, dir, pinc ) // Creates the waves "lineN" (limited to 100 waves)	
	//
	nx=DimSize(root:IMG:STACK:Image, 0) // Nb of points along x
	variable/G root:IMG:STACK:ymin=y1, root:IMG:STACK:yinc=(y2-y1)/(Nb_Stacks-1)
	variable/G root:IMG:STACK:xmin=x1 , root:IMG:STACK:xinc=(x2-x1)/(nx-1) // in case there is a shift along x (I don't use)

	// Plot stacks
	ii=0
	DO
		AppendToGraph/W=Stack_ $(basen+num2istr(ii))
		ii+=1
	WHILE( ii<Nb_Stacks )
	ModifyGraph/W=Stack_ zero(bottom)=2
	
	// Window title
	SVAR imgnam=root:IMG:imgnam
	DoWindow/T Stack_,"STACK_: "+imgnam
	
	//calculates good values for offset and shift increment
	nvar dmax=root:IMG:STACK:dmax, dmin=root:IMG:STACK:dmin
	variable shiftinc=DimDelta(imgstack,0), offsetinc, exp
	offsetinc=0.1*(dmax-dmin)
	exp=10^floor( log(offsetinc) )
	offsetinc=round( offsetinc / exp) * exp
//	print offsetinc, exp
	SetVariable setshift win=Stack_, limits={-Inf,Inf, shiftinc}//,value=shift
	SetVariable setoffset win=Stack_, limits={-Inf,Inf, offsetinc}//,value=offset
	
	//Offset the lines
	nvar shift=root:IMG:STACK:shift,  offset=root:IMG:STACK:offset
	shift=0
	offset=offsetinc*(1-2*(offset<0))		//preserve previous sign of offset
	OffsetStack( shift, offset)
	
	HighlightSelectedStack()//Show stack of x profile in blue
	
	if (XYonStacks()==1)
		
		svar XwaveL=root:IMG:STACK:Xwave
		svar YwaveL=root:IMG:STACK:Ywave
		svar XYfolder=root:IMG:STACK:XYfolder
		XwaveL=XYfolder+XwaveL
		YwaveL=XYfolder+YwaveL
		// BUG : sometimes Xwave is with path. I can't find where path is written in it !!
		//DoAddwave($XwaveL,$YwaveL)
	endif
	
	SetDataFolder curr

End

Proc UpdateStack_pinc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	UpdateStack()
	DoWindow/F Stack_
end

function HighlightSelectedStack()
// Stacks corresponding to y value in Image Tool will be blue
// All other will be red (should find a way to keep stacks in other color than red and blue as they were)
	
	nvar ymin=root:IMG:STACK:ymin, yinc=root:IMG:STACK:yinc
	nvar Yvalue= root:WinGlobals:ImageTool:Y0
	variable index_line,NbLines,i
	string name,AllLines,curr
	
	curr=GetDataFolder(1)
	SetDataFolder root:IMG:STACK
	DoWindow Stack_
	if (v_flag==1)
		AllLines=WaveList("line*", ";","WIN:Stack_")
		Nblines=ItemsInList(AllLines,";")
		i=0
		do
			name="line"+num2str(i)
			ModifyGraph/Z/W=Stack_ rgb($name)=(65280,0,0)
			i+=1
		while(i<Nblines)
		index_line=round((Yvalue-ymin)/yinc)
		if (index_line<Nblines && index_line>0)  // otherwise, HairY is outside image
			name="line"+num2str(index_line)
			ModifyGraph/Z/W=Stack_ rgb($name)=(0,15872,65280)
		endif	
	endif	
	SetDataFolder curr
end

Proc SetOffset(ctrlName,varNum,varStr,varName) : SetVariableControl
//---------------
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	if (cmpstr(ctrlName,"setShift")==0)
		root:IMG:STACK:shift=varNum
	else
		root:IMG:STACK:offset=varNum
	endif
	
	OffsetStack( root:IMG:STACK:shift, root:IMG:STACK:offset)
	if (XYonStacks()==1)
		string XwaveL=root:IMG:STACK:Xwave,YwaveL=root:IMG:STACK:Ywave,XYfolder=root:IMG:STACK:XYfolder
		XwaveL=XYfolder+XwaveL
		YwaveL=XYfolder+YwaveL
		DoAddwave($XwaveL,$YwaveL)
	endif
End

Function OffsetStack( shift, offset )
//================
	Variable shift, offset
	nvar pinc=root:IMG:STACK:pinc
	
	string trace_lst=TraceNameList("Stack_",";",1 )
	//string trace_lst=WaveList("line*",";","" ) //use wavelist to exclude offset_scale
	variable nt=ItemsInList(trace_lst,";")
	//print nt,trace_lst
	
	variable ii=0
	string wn, cmd
	DO
		wn=StrFromList(trace_lst, ii, ";")
		//print wn
		//WAVE w=wn
//		ModifyGraph offset(wn)={ii*shift, ii*offset}
		cmd="ModifyGraph/W=Stack_ offset("+wn+")={"+num2str(ii*shift)+", "+num2str(ii*offset)+"}"
		execute cmd
		ii+=1
	WHILE( ii<nt )
    	
	return nt
End

Proc MoveCursor(ctrlName) : ButtonControl
//------ "Show on Image" button. Position the Hair cursor in Image Tool on the corresponding stack
	String ctrlName,curr
	
	curr=GetDataFolder(1)
	SetDataFolder root:IMG
	variable xcur=xcsr(A), ycur
	if ( numtype(xcur)==0 ) 
		string wvn=CsrWave(A)
		//ycur=root:IMG:STACK:ymin + root:IMG:STACK:yinc * str2num( wvn[4,strlen(wvn)-1] )
		ycur=DimOffset(root:IMG:STACK:Image,1) + DimDelta(root:IMG:STACK:Image,1)* str2num( wvn[4,strlen(wvn)-1] )*root:IMG:STACK:pinc
		DoWindow/F ImageTool
		ModifyGraph offset(HairY0)={xcur, ycur}
		//Cursor/P A, profileH, round((xcur - DimOffset(root:IMG:Image, 0))/DimDelta(root:IMG:Image,0))
		//Cursor/P B, profileV_y, round((ycur - DimOffset(root:IMG:Image, 1))/DimDelta(root:IMG:Image,1))
	endif
	SetDataFolder curr
End


Proc ExportStack( basen )
//======================
	String basen=root:IMG:STACK:basen
	
	SetDataFolder root:
	NewDataFolder/O ExportedStacks
	SetDataFolder root:ExportedStacks
	NewDataFolder/O $basen
	
	SetDataFolder $basen
	//root:IMG:STACK:basen=basen

	string imgn=root:IMG:imgnam
	variable shift=root:IMG:STACK:shift, offset=root:IMG:STACK:offset

	string trace_lst=TraceNameList("Stack_",";",1 )
	variable nt=ItemsInList(trace_lst,";")

	display
	PauseUpdate; Silent 1
	string tn, wn, tval, wnote
	variable ii=0, yval
	DO
		tn="root:IMG:STACK:"+StrFromList(trace_lst, ii, ";")
		yval=NumberByKey( "VAL", note($tn), "=", ",")		// get y-axis value
		//wn=basen+num2istr(ii)
		wn=basen+"_"+num2istr(round(yval*1000))
		duplicate/o $tn $wn
		//$wn+=offset*ii
		SetScale/P x DimOffset($tn,0),DimDelta($tn,0),"" $wn
		Write_Mod($wn, shift*ii, offset*ii, 1, 0, 0.5, 0, yval, imgn)
		AppendToGraph $wn
		ModifyGraph offset($wn)={0,offset*ii}
		ii+=1
	WHILE( ii<nt )
	
	string winnam=(basen+"_Stack")
	DoWindow/F $winnam
	if (V_Flag==1)
		DoWindow/K $winnam
	endif
	DoWindow/C $winnam
	MoveWindow 50,50,300,400
	
//	SetDataFolder curr
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////              Add Stacks               ////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Proc  DoAddStacksWindow(ctrlname):Buttoncontrol
string ctrlname
variable y_end
      		string curr=GetDataFolder(1) // Should be directory where is the image to be added
		DoWindow/F Add_Stacks
		if (V_flag==0)
			NewDataFolder/O/S root:IMG:AddStacks
			PauseUpdate; Silent 1		// building window...
			NewPanel /W=(10,50,500,300)
			DoWindow/C Add_Stacks
			DoWindow/T Add_Stacks "Add stacks"
			ModifyPanel cbRGB=(0,64512,30000)
			MoveWindow 330,50,710,240
		endif
		SetDataFolder root:IMG:AddStacks 	
    		SetDrawEnv fstyle= 1
		DrawText 10,18,"Stacks displayed in ImageTool : "
		variable/G  cur_start,cur_end,cur_delta,cur_Vmin,cur_Vmax
		cur_start=Dimoffset(root:IMG:STACK:Image,1)
		cur_delta=(DimDelta(root:IMG:STACK:Image,1))*(root:IMG:stack:pinc)
		y_end=cur_start+(root:IMG:ny-1)*(DimDelta(root:IMG:STACK:Image,1))
		cur_end=cur_start+round((y_end-cur_start)/cur_delta)*cur_delta
		WaveStats/Q root:IMG:STACK:Image
		cur_Vmin=V_min
		cur_Vmax=V_max
		DrawText 25,38,"k_start = "+num2str(cur_start)+"  ,   k_stop = "+ num2str(cur_end)+"  ,   k_delta = "+ num2str(cur_delta)
		DrawText 25,55,"min = "+num2str(cur_Vmin)+"  ,  max = "+ num2str(cur_Vmax)
		Button button_refresh,pos={360,10},size={100,30},proc=refresh_ImageToolStackslimits,title="Refresh"
		DrawLine 0,60,550,60
		
		SetDataFolder curr
		SetDrawEnv fstyle= 1
		DrawText 10,88,"Add stacks from image : "
		PopupMenu Popaddstack,pos={150,68},size={450,25},proc=refresh_Addedlimits,title=" ",popvalue="-", value=WaveList("*",";","DIMS:2")
		SetDataFolder root:IMG:AddStacks
		string/G ImgName
		variable/G new_start,new_end,new_delta
		SetVariable val_newstart,pos={40,101},size={120,15},title="k_start"
		SetVariable val_newstart,limits={-1000,1000,0.001},barmisc={0,1000},value=new_start
		SetVariable val_newend,pos={180,101},size={120,15},title="k_end"
		SetVariable val_newend,limits={-1000,1000,0.001},barmisc={0,1000},value=new_end
		DrawText 330,115,"k_delta = "+num2str(new_delta)
		
		variable/G new_shift=0,new_step=1,new_value=1,new_Ef=0,new_avg=1
		SetVariable val_newstep,pos={5,135},size={185,15},title="            Step :          "
		SetVariable val_newstep,limits={1,100,1},barmisc={0,1000},proc=Refresh_AddStacks,value=new_step
		SetVariable val_newavg,pos={5,155},size={185,15},title="            Avg :            "
		SetVariable val_newavg,limits={1,100,1},barmisc={0,1000},proc=Refresh_AddStacks,value=new_avg
			DrawText 200,160,"k_delta = "+num2str(new_step*new_delta*new_avg)
 		SetVariable val_newshift,pos={5,175},size={185,15},title="            Offset :        "
		SetVariable val_newshift,limits={-1000,1000,1},barmisc={0,1000},proc=Refresh_Offset,value=new_shift
			DrawText 190,192," * k_delta"
		SetVariable val_newvalue,pos={40,195},size={150,15},title="Multiply by : "
		SetVariable val_newvalue,limits={-1000,1000,0.1},barmisc={0,1000},proc=Refresh_Value,value=new_value
		SetVariable val_newEf,pos={40,215},size={150,15},title="Ef shift :       "
		SetVariable val_newEf,limits={-1000,1000,0.005},barmisc={0,1000},proc=Refresh_Offset,value=new_Ef
		
		Button AddStacks,pos={360,160},size={100,30},proc=Add_Stack,title="Add"
		SetDataFolder curr
		
end

function Add_Stack(ctrlname):ButtonControl
// Button "Add" in Add_Stack window
string ctrlname
variable i,Ny,Nx,indice_ds_ImgName,val_K,K_offset,new_offset,offset_inter,deb_x,delta_x
variable/G new_Ef
string name,ordre,partial_order
svar ImgName=root:IMG:AddStacks:ImgName
nvar new_start=root:IMG:AddStacks:new_start,new_end=root:IMG:AddStacks:new_end,new_delta=root:IMG:AddStacks:new_delta
nvar new_step=root:IMG:AddStacks:new_step,new_avg=root:IMG:AddStacks:new_avg,new_shift=root:IMG:AddStacks:new_shift
nvar cur_start=root:IMG:AddStacks:cur_start,cur_end=root:IMG:AddStacks:cur_end,cur_delta=root:IMG:AddStacks:cur_delta
nvar offset=root:IMG:STACK:offset,pinc=root:IMG:STACK:pinc,shift=root:IMG:STACK:shift
wave Image=root:IMG:Image

	string curr=GetDataFolder(1) 
	refresh_ImageToolStacksLimits(" ")
	offset_inter=offset
	DoWindow/F ImageTool
	UpdateStack()
	offset=offset_inter   //We do not want to change offset when reactualizing
	OffsetStack(shift,offset)
	SetDataFolder root:IMG:AddStacks
	KillWaves/A/Z
	
	Nx=Dimsize($ImgName,0)//Nb de points des waves 1D
	Ny=round((new_end-new_start)/(new_delta*new_step))//Nb de stacks à faire
	K_offset=DimDelta(Image,1)*pinc //Valeur de l'offset en k
	
	deb_x=DimOffset($ImgName,0)
	delta_x=DimDelta($ImgName,0)
	partial_order="SetScale/P x "+num2str(deb_x)+","+num2str(delta_x)+", $"
	i=0
	DoWindow/F Stack_
	do
	     val_K=new_start+i*new_step*new_avg*new_delta+(new_avg-1)/2*new_delta
   	     indice_ds_ImgName=round((val_K-DimOffset($ImgName,1))/DimDelta($ImgName,1))
   	     val_K=DimOffset($ImgName,1)+indice_ds_ImgName*DimDelta($ImgName,1) // true k value for the extracted stack
	     name="K_"+num2str(val_K)
	     ordre="Make/N=("+num2str(Nx)+")/O $"+"\""+name+"\""
	     execute ordre
	     //Make/N=(Nx)/O $name
	     ordre=partial_order+"\""+name+"\""
	     execute ordre
	     //SetScale/P x DimOffset($ImgName,0),DimDelta($ImgName,0),"", $name
	     ordre="attribute_values("+"\""+name+"\""+","+num2str(indice_ds_ImgName)+")"
	     execute ordre

	     ordre="AppendToGraph $\""+name+"\""
	     execute ordre
	     //AppendToGraph $name
	     ordre="ModifyGraph rgb($\""+name+"\")=(0,12800,52224)"
	     execute ordre
	     //ModifyGraph rgb($name)=(0,12800,52224)
	     new_offset=((val_K-cur_start+new_shift*new_delta)/K_offset)*offset
	     //print "new_offset,val_K,cur_start,new_shift,new_delta,K_offset,offset",new_offset,val_K,cur_start,new_shift,new_delta,K_offset,offset
	     ordre="ModifyGraph offset($\""+name+"\")={"+num2str(new_Ef)+", "+num2str(new_offset)+"}"
	     execute ordre
	    
	     //ModifyGraph offset($name)={0,new_offset}
	     i+=1
	while (i<=round(Ny/new_avg))	
	SetDataFolder curr

end

function Refresh_AddedLimits(ctrlName,popNum,popStr) : PopupMenuControl
//-----------------------------
	String ctrlName
	Variable popNum
	String popStr   // name of Image selected in popup menu
	
	//Everything labelled new is from the image selected in popup menu
	//everything labelled add will be added in stacks
	nvar cur_delta=root:IMG:Addstacks:cur_delta
	nvar cur_Vmax=root:IMG:Addstacks:cur_Vmax
	nvar cur_Vmin=root:IMG:Addstacks:cur_Vmin
	nvar new_start=root:IMG:Addstacks:new_start
	nvar new_end=root:IMG:Addstacks:new_end
	nvar new_delta=root:IMG:Addstacks:new_delta
	nvar new_step=root:IMG:Addstacks:new_step
	nvar new_avg=root:IMG:Addstacks:new_avg
	nvar new_value=root:IMG:Addstacks:new_value
	nvar add_start=root:IMG:Addstacks:add_start,add_end=root:Addstacks:add_end,add_delta=root:Addstacks:add_delta
       svar ImgName=root:IMG:Addstacks:ImgName
       
       string curr=GetDataFolder(1) 
            
      new_start=DimOffset($popstr,1)
	new_end=(new_start+(Dimsize($popstr,1)-1)*new_delta)
	// Step chosen to be similar to current stack
      new_delta=DimDelta($popstr,1)
      new_step=round(cur_delta/new_delta)/new_avg
	SetDrawenv linefgc=(0,64512,30000), fillfgc=(0,64512,30000) 
	DrawRect 200, 140, 300, 160
	DrawText 200,160,"k_delta = "+num2str(new_step*new_delta*new_avg)
      // Multiplying coefficient chosen to match image in stacks
      Wavestats/Q $popstr
      new_value=(cur_Vmax-cur_Vmin)/(V_max-V_min)
	
	ImgName=curr+popstr
       SetDataFolder curr
end	

function Refresh_ImageToolStacksLimits(ctrlname) :Buttoncontrol
string ctrlname
//refresh limits of stacks from ImageTool
	nvar cur_start=root:IMG:Addstacks:cur_start,cur_end=root:IMG:Addstacks:cur_end,cur_delta=root:IMG:Addstacks:cur_delta,pinc=root:IMG:stack:pinc      
       nvar cur_Vmin=root:IMG:Addstacks:cur_Vmin,cur_Vmax=root:IMG:Addstacks:cur_Vmax
       wave Img=root:IMG:STACK:Image // Attention : il se peut qu'elle soit différente de celle de IMG (par exemple si on fait les stacks sur un expand)
       
      string curr=GetDataFolder(1) 
      cur_start=DimOffset(Img,1)
	cur_end=cur_start+(Dimsize(img,1)-1)*DimDelta(Img,1)
      cur_delta=DimDelta(Img,1)*pinc
	WaveStats/Q Img
	cur_Vmin=V_min
	cur_Vmax=V_max
	SetDrawenv linefgc=(0,64512,30000),fillfgc=(0,64512,30000)  // green rectangle with no line
	DrawRect 20, 25, 350, 58
	DrawText 25,38,"k_start = "+num2str(cur_start)+"  ,   k_stop = "+ num2str(cur_end)+"  ,   k_delta = "+ num2str(cur_delta)
	DrawText 25,55,"min = "+num2str(cur_Vmin)+"  ,  max = "+ num2str(cur_Vmax)
     SetDataFolder curr
end	



Proc attribute_values(name,indice)
string name
variable indice
string ImgName=root:IMG:Addstacks:ImgName
variable new_value=root:IMG:Addstacks:new_value
variable new_avg=root:IMG:Addstacks:new_avg    
variable ind

    $name=0
    ind=indice
    do
    	$name+=$ImgName[p][ind]*new_value
    	ind+=1
    while (ind<(indice+new_avg))
    $name/=new_avg
end

Function Refresh_AddStacks (ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	nvar new_step=root:IMG:Addstacks:new_step,new_avg=root:IMG:Addstacks:new_avg,new_delta=root:IMG:Addstacks:new_delta

	SetDrawenv linefgc=(0,64512,30000), fillfgc=(0,64512,30000) 
	DrawRect 200, 140, 300, 160
	DrawText 200,160,"k_delta = "+num2str(new_step*new_delta*new_avg)
	Add_Stack(" ")
end	

Function Refresh_Offset (ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable

variable i,Ny,Nx,indice_ds_ImgName,val_K,K_offset,new_offset,offset_inter
variable /G new_Ef
string name,ordre
svar ImgName=root:IMG:AddStacks:ImgName
nvar new_start=root:IMG:AddStacks:new_start,new_end=root:IMG:AddStacks:new_end,new_delta=root:IMG:AddStacks:new_delta
nvar new_step=root:IMG:AddStacks:new_step,new_avg=root:IMG:AddStacks:new_avg,new_shift=root:IMG:AddStacks:new_shift
nvar cur_start=root:IMG:AddStacks:cur_start,cur_end=root:IMG:AddStacks:cur_end,cur_delta=root:IMG:AddStacks:cur_delta
nvar offset=root:IMG:STACK:offset,pinc=root:IMG:STACK:pinc,shift=root:IMG:STACK:shift
wave Image=root:IMG:Image


	Ny=round((new_end-new_start)/(new_delta*new_step))//Nb de stacks à faire
	K_offset=DimDelta(Image,1)*pinc //Valeur de l'offset en k
	
	i=0
	DoWindow/F Stack_
	do
	     val_K=new_start+i*new_step*new_avg*new_delta+(new_avg-1)/2*new_delta
   	     indice_ds_ImgName=round((val_K-DimOffset($ImgName,1))/DimDelta($ImgName,1))
   	     val_K=DimOffset($ImgName,1)+indice_ds_ImgName*DimDelta($ImgName,1) // true k value for the extracted stack
	     name="K_"+num2str(val_K)
	     
	     new_offset=((val_K-cur_start+new_shift*new_delta)/K_offset)*offset
	     //print "new_offset,val_K,cur_start,new_shift,new_delta,K_offset,offset",new_offset,val_K,cur_start,new_shift,new_delta,K_offset,offset
	     ordre="ModifyGraph offset($\""+name+"\")={"+num2str(new_Ef)+", "+num2str(new_offset)+"}"
	     execute ordre
	     //ModifyGraph offset($name)={0,new_offset}
	     i+=1
	while (i<=round(Ny/new_avg))	
		
End


Function Refresh_Value (ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable

variable i,Ny,Nx,indice_ds_ImgName,val_K
string name,ordre,curr
svar ImgName=root:IMG:AddStacks:ImgName
nvar new_start=root:IMG:AddStacks:new_start,new_end=root:IMG:AddStacks:new_end,new_delta=root:IMG:AddStacks:new_delta
nvar new_step=root:IMG:AddStacks:new_step,new_avg=root:IMG:AddStacks:new_avg,new_shift=root:IMG:AddStacks:new_shift

	curr=GetDataFolder(1)
	SetDataFolder root:IMG:AddStacks
	Ny=round((new_end-new_start)/(new_delta*new_step))//Nb de stacks à faire
		
	i=0
	DoWindow/F Stack_
	do
	     val_K=new_start+i*new_step*new_avg*new_delta+(new_avg-1)/2*new_delta
   	     indice_ds_ImgName=round((val_K-DimOffset($ImgName,1))/DimDelta($ImgName,1))
   	     val_K=DimOffset($ImgName,1)+indice_ds_ImgName*DimDelta($ImgName,1) // true k value for the extracted stack
	     name="K_"+num2str(val_K)
	     
           ordre="attribute_values("+"\""+name+"\""+","+num2str(indice_ds_ImgName)+")"
	     execute ordre

	     i+=1
	while (i<=round(Ny/new_avg))	
	SetDataFolder $curr	
End



Function Refresh_EfValue (ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable

 Add_Stack(" ")
		
End


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// Utilities (previously in image_util and so on)

Function Image2Waves( img, basen, dir, inc )
//================
// Extract wave set from 2D array
// use image scaling for x-axis and y-value in wave note
// For dir=1, transpose image first
// specify output x-axis increment of wave set
	Wave img
	String basen
	Variable dir, inc
	inc=round( max(inc,1) )
	variable nx=DimSize(img, 0), ny=DimSize(img,1)
//	print nx, ny
	string linen, imgn=NameOfWave( img )
	variable ii=0, val
	if (dir==0)
		ny=round(ny/inc)
		//print nx, ny, inc
		DO
			linen=basen+num2str(ii)
			Make/o/n=(nx) $linen
			WAVE line=$linen	
			//CopyScales img, line
			SetScale/P x  DimOffset(img,0), DimDelta(img,0), WaveUnits(img,0) line
			line=img[p][ii*inc]
			val=DimOffset(img,1)+ii*inc*DimDelta(img,1)
			Write_Mod( line, 0,0,1,0,1,0, val, imgn )
	   		//print ii, ii*inc, val
			ii+=1
		WHILE( ii<ny && ii<=100)
		return ny
	else
		nx=round(nx/inc)
		//print nx, ny, inc
		DO
			linen=basen+num2str(ii)
			Make/o/n=(ny) $linen
			WAVE line=$linen	
			//CopyScales img, line
			SetScale/P x  DimOffset(img,1), DimDelta(img,1), WaveUnits(img,1) line
			line=img[ii*inc][p]
			val=DimOffset(img,0)+ii*inc*DimDelta(img,0)
			Write_Mod( line, 0,0,1,0,1,0, val, imgn )
	   		//print ii, ii*inc, val, note(line)
			ii+=1
		WHILE( ii<nx  && ii<=100)
		return nx
	endif
End


Function KeySet( key, str )
//===================
	string key, str
	key=LowerStr(key); str=LowerStr(str)
	variable set=stringmatch( str, "*/"+key+"*" )
	// keyword NOT set if "/K=0" used
	set=SelectNumber( KeyVal( key, str)==0, set, 0)
	return set
end

Function/T KeyStr( key, str )
//===================
	string key, str
	return StringByKey( key, str, "=", "/")
end

Function KeyVal( key, str )
//===================
	string key, str
	return NumberByKey( key, str, "=", "/")
end

Function/S StrFromList(list, n, separator)
//==================================
// same as GetStrFromList in <Strings as Lists>
// same as new built-in function:  StringFromList( n, list [, sep] )
// list is a sequence of separated strings optionally with a separator at the end
// n index starts from zero 
	String list, separator
	Variable n
	return StringFromList( n, list, separator )
End

Function/T Write_Mod(w, shft, off, gain, lin,  thk, clr, val, txt)
//=============
// repeat of WaveMod function in "Stack" so that Stack.ipf does not need to be called
	wave w
	variable shft, off, gain, lin, thk, clr, val
	string txt
	string notestr, modlst
	modlst="Shift="+num2str(shft)+",Offset="+num2str(off)+",Gain="+num2str(gain)
	modlst+=",Lin="+num2str(lin)+",Thk="+num2str(thk)+",Clr="+num2str(clr)
	modlst+=",Val="+num2str(val)+",Txt="+txt
	notestr=note(w)
	notestr=ReplaceStringByKey("MOD", notestr, modlst, ":", "\r")
   	Note/K w			//kill previous note
   	Note w, noteStr
   	return modlst
end

Function AddWave(ctrlname):ButtonControl
string ctrlname
wave save_cur_k,save_cur_BE,save_cur_amp
//DoAddWave(save_cur_k,save_cur_BE,save_cur_amp)
AskAddWave()
end

Function AskAddWave()
//From menu : select waves
string curr
curr=GetDataFolder(1)
string XwaveL,YwaveL,ListOfNames
ListOfnames="none;"+WaveList("*",";","DIMS:1")
SetDataFolder root:IMG:STACK
string/G Xwave,Ywave,XYfolder
XYfolder=curr
XwaveL=Xwave
YwaveL=Ywave
prompt XwaveL," Wave for x positions ", popup,ListOfnames
prompt YwaveL," Wave for y positions ", popup,ListOfnames
//prompt Ampwave," Wave for amplitudes ", popup,ListOfnames

DoPrompt "Add..." XwaveL,YwaveL//,Ampwave

if (v_flag==0)
	Xwave=XwaveL
	Ywave=YwaveL
	XwaveL=curr+XwaveL
	YwaveL=curr+YwaveL
	DoAddWave($XwaveL,$YwaveL)
endif

SetDataFolder curr

end

function DoAddWave(input_x,input_y)
wave input_x,input_y   // with no path
//Add wave on stacks as blue points
string curr
svar XYfolder

curr=GetDataFolder(1)

//SetDataFolder root:IMG:STACK
//SetDataFolder XYFolder
DoWindow/F Stack_
wave Image=root:IMG:STACK:Image // This image is cropped
nvar pinc=root:IMG:STACK:pinc
nvar offset=root:IMG:STACK:offset
variable delta_k,start_k,stop_k,Nblines,index_start_k

delta_k=pinc*dimDelta(Image,1)
index_start_k=round((input_y[0]-DimOffset(Image,1))/delta_k)
start_k=DimOffset(Image,1)+index_start_k*delta_k
stop_k=DimOffset(Image,1)+round((input_y[DimSize(input_y,0)-1]-DimOffset(Image,1))/delta_k)*delta_k
Nblines=(stop_k-start_k)/delta_k+1

Interpolate2/T=1/N=(Nblines)/Y=pos_x input_y, input_x
wave pos_x
Make/O/N=(Nblines) pos_z
pos_z=Image(pos_x(start_k+p*delta_k))(start_k+p*delta_k)
pos_z+=offset*(p+index_start_k)

RemoveFromGraph/Z pos_z vs pos_x
AppendToGraph pos_z vs pos_x
ModifyGraph mode(pos_z)=3,msize(pos_z)=2,marker(pos_z)=19,rgb(pos_z)=(0,12800,52224)

SetDataFolder curr
End

function XYonStacks()
//check if a wave is added or not
string curr
	curr=GetDataFolder(1)
	SetDataFolder root:IMG:STACK
	DoWindow/F Stack_
	//print "check wavelist=", WaveList("!line*", ";","WIN:STACK_")
	if (ItemsInList(WaveList("!line*", ";","WIN:"),";")>0)
		return 1
	else
		return 0	
	endif
	SetDataFolder curr
end