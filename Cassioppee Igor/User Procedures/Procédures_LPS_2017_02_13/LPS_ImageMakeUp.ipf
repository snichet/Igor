#pragma rtGlobals=1		// Use modern global access method.

/// These procedures can be called from "Make-up" menu and applied to any image plot 
	// Works on image displayed in graph : there must be only one !
	// If error message "No appropriate wave in directory", must be the wrong directory in data browser
// Changes are applied to the current image, but there is a possibility to undo (twice)
// Alternatively, one can work on a wave Image from ImgProcess folder (choose Image process in ARPES menu)

//	"Image Make-up window", ImgProcessMenu()
//     "Arrange Graph",ArrangeGraph()
//	"-"
//	"Rotate an image",RotationFromMenu()
//	"Rotate 3D wave",LetsRotate3D()    [ for 3Dtools window]
//	"Transpose", DoTranspose()
//	"Second derivative vs E",DoSecondDerivativeE()
//	"Second derivative vs k",DoSecondDerivativek()
	//"Symmetrize",Img_Symmetrize(" ")
//	"-"
//	"Scaling", Img_Scale(" ")// In ImageMakeUp
//	"Shift",Img_Shift()
//	"Make-up pannel", MakeUpPannel(" ")// In ImageMakeUp
//	"Interpolate 2D image",ImgPannel_interpolate2D(" ")
// For 3D image : type Dointerpolate3D("name") in command window

//	"-"
//	"Rotate two X and Y waves",Ask_WaveRotation()
//	"Center symmetric dispersion at zero",Center_disp()
//	"-"
//	"Undo ",Img_undo(" ")
	

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////  Image Make-up Window
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
Macro ArrangeGraph()
	ModifyGraph mirror=2,fSize=16
	Legend/C/N=text0
	ModifyGraph zero(bottom)=1
end

Macro ImgProcessMenu()
//Use the same directory as ImageToolLoad an image
//Allow interpolation, rotation, filling with zero or bgd, symmetrization
string curr,name

curr=GetDataFolder(1)
NewDataFolder/O root:ImgProcess

DoWindow/F ImgProcess
if (v_flag==0)
	//Load image of top graph if there is one
	string List=Wavelist("*",";" ,"DIMS:2,WIN:")
	name=StrFromList(List, 0, ";")
	if (cmpstr(name,"")==0)
   		else
		Duplicate/O $name root:ImgProcess:Image
	endif
	SetDataFolder root:ImgProcess //à prévoir : load pour data

	if (exists("Image")==0)//does not exist
		Make /N=(2,2) Image
	endif
	
	Display/W=(53,23,510,425);AppendImage Image
	ModifyImage Image ctab= {*,*,PlanetEarth,1}
	ShowInfo
	DoWindow/C ImgProcess
	DoWindow/T ImgProcess "Image Make-up"
	ControlBar 70
	//ModifyPanel cbRGB=(65280,32768,32768)
	Button LoadImg,pos={13,10},size={80,22},proc=Img_load,title="Load"
	Button ExportImg,pos={13,40},size={80,22},proc=Img_export,title="Export"
	Button UndoImg,pos={470,15},size={80,35},proc=Img_undo,title="Undo"
	
	Button MakeUpButton,pos={110,10},size={80,22},proc=MakeUpPannel,title="Make up"
	Button ScaleImg,pos={110,40},size={80,22},proc=Img_scale,title="Scale"
	Button InterpImg,pos={200,10},size={80,22},proc=ImgPannel_interpolate,title="Refresh"
	Button CombImg,pos={300,10},size={80,22},proc=ImgPannel_combine,title="Combine"
	Button SymImg,pos={200,40},size={80,22},proc=Img_symmetrize,title="Symmetrize"
	Button RotateImg,pos={300,40},size={80,22},proc=RotationFromPannel,title="Rotation"
	SetDataFolder root:ImgProcess
	variable/G angle_image=0   //angle_image est la valeur actuelle de rotation de l'image	
	variable/G angle_back=0
	variable/G angle_back_back=0    
	variable/G angle_back_back_back=0    
	ValDisplay Angle,pos={390,44},size={50,20},title=" ",limits={-Inf,Inf,0.1},value=#"root:ImgProcess:angle_image"

endif
//SetDataFolder curr

end
//////////////////
function Img_load(ctrlname):ButtonControl
string ctrlname
string name,curr

curr=GetDataFolder(1)
nvar angle_image=root:ImgProcess:angle_image
nvar angle_back=root:ImgProcess:angle_back
nvar angle_back_back=root:ImgProcess:angle_back_back
prompt name, "Name of wave to load",popup,WaveList("*",";","DIMS:2")
DoPrompt "Loading...",name
if (v_flag==0)
	Duplicate/O $name root:ImgProcess:Image
	SetDataFolder root:ImgProcess
	nvar angle_image,angle_back,angle_back_back,angle_back_back_back
		angle_image=0
		angle_back=0
		angle_back_back=0
		angle_back_back_back=0
endif
SetDataFolder curr
//execute "rewrite()"// Rewrite Image to get dx>0
end

///////////
function Img_export(ctrlname):ButtonControl
string ctrlname
string name,name2

prompt name, "Name to export wave"
DoPrompt "Exporting...",name
name2="root:"+name
SetDataFolder root:ImgProcess
if (v_flag==0)
	Duplicate/O Image $name2 
endif
SetDataFolder root:
Display;AppendImage $name
nvar Img_Min=root:ImgProcess:Img_min,Img_max=root:ImgProcess:Img_max
ModifyImage $name ctab= {Img_min,Img_max,PlanetEarth,1}

end
//////////////////////
proc rewrite()

variable last,deb
SetDataFolder root:ImgProcess
Duplicate/O Image Image_backup
if (DimDelta(Image,0)<0)
	
	last=DimSize(Image,0)-1
	deb=DimOffset(Image,0)+DimDelta(Image,0)*last
	Image=Image_backup[last-p][q]
	SetScale/P x deb, -DimDelta(Image_backup,0), Image
endif
Duplicate/O Image Image_backup
end


proc Rescale_line(new_min,new_max)
variable new_min,new_max
//rescale the line where cursors are set to new_min for cursor A and new_max to cursor_B

variable old_min, old_max

old_min=Image[pcsr(A)][qcsr(A)]
old_max=Image[pcsr(B)][qcsr(B)]
Image[][qcsr(A)]=(Image[p][qcsr(A)]-old_min)/(old_max-old_min)*(new_max-new_min)+new_min

end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// General Make-up procedures (from menu or pannel)
// pannel : replace, multiply, crop (also available from Marquee)
// Scaling (to visualize easily changes of image scale)
// Symmetrize
// Interpolation
// Shift
// Rotation

//////////////////  Small Make Up procedures (replace, multiply,crop)
function MakeUpPannel(ctrlname):ButtonControl
string ctrlname
// These functions can be accessed by mouse click (GraphMarquee)
// With this pannel, only allows to enter numbers


DoWindow/F MakeUp
 if (V_flag==0)
            NewPanel /W=(700,200,960,400)
            DoWindow/C MakeUp
            DoWindow/T MakeUp "Make Up"
            
             string/G StrValue="0"
		variable/G Kx_start,Kx_stop, Ky_start,Ky_stop,NorValue
		string name=Find_TopImageName()
		Kx_start=round(DimOffset($name,0)*1000)/1000
		Kx_stop=round((Kx_start+DimDelta($name,0)*(DimSize($name,0)-1))*1000)/1000
		Ky_start=round(DimOffset($name,1)*1000)/1000
		Ky_stop=round((Ky_start+DimDelta($name,1)*(DimSize($name,1)-1))*1000)/1000


		SetVariable KxStart,pos={10,10},size={130,20},title="For kx from :  ",limits={-Inf,Inf,0.01},value=Kx_start
		SetVariable KxStop,pos={150,10},size={80,20},title=" to :  ",limits={-Inf,Inf,0.01},value=Kx_stop
		SetVariable KyStart,pos={10,30},size={130,20},title="For ky from :  ",limits={-Inf,Inf,0.01},value=Ky_start
		SetVariable KyStop,pos={150,30},size={80,20},title=" to :  ",limits={-Inf,Inf,0.01},value=Ky_stop
		Button Fillwith,pos={25,60},size={65,22},proc=ReplaceFromPannel,title="Replace"
		SetVariable BgdValue,pos={110,60},size={80,20},title=" with  :  ",value=Strvalue
		Button MultiplyBy,pos={25,95},size={65,22},proc=MultiplyFromPannel,title="Multiply "
		SetVariable MultiplyValue,pos={110,95},size={80,20},title=" by    :   ",limits={-Inf,Inf,0},value=Norvalue
		Button Docrop,pos={25,130},size={65,22},proc=CropFromPannel,title="Crop"

endif

end

/////// Replace -----------------
function Replace():GraphMarquee
//Replace rectangle by...
string StrValue
    prompt StrValue, "Replace by (value or NaN) : "
    Doprompt "Replace",StrValue

	if (v_flag==0)	
		//Get rectangle
		GetMarquee/K left, bottom
		//print v_left,v_right,v_bottom,v_top // values in axis units of the selected rectangle
		DoReplace(v_left,v_right,v_bottom,v_top,StrValue)
	endif
end
///////
function ReplaceFromPannel(ctrlname):ButtonControl
	string Ctrlname
	nvar Kx_start,Kx_stop,Ky_start,Ky_stop
	svar StrValue
      		DoReplace(Kx_start,Kx_stop,Ky_start,Ky_stop,StrValue)
end
///////
function DoReplace(x_start,x_stop,y_start,y_stop,StrValue)
	variable x_start,x_stop,y_start,y_stop
	string StrValue

	variable Xindice_start,Xindice_stop,Yindice_start,Yindice_stop,Xnb,Ynb

	string name=Find_TopImageName()
	DuplicateForUndo(name)
	Duplicate/O $name temp
	
	Xindice_start=round((x_start-Dimoffset(temp,0))/DimDelta(temp,0))
	Xindice_stop=round((x_stop-Dimoffset(temp,0))/DimDelta(temp,0))
	Xnb=Xindice_stop-Xindice_start+1
	Yindice_start=round((y_start-DimOffset(Image,1))/DimDelta(Image,1))
	Yindice_stop=round((y_stop-DimOffset(Image,1))/DimDelta(Image,1))
	Ynb=Yindice_stop-Yindice_start+1

	if (cmpstr(StrValue,"NaN")==0)
		temp[Xindice_start,Xindice_stop][Yindice_start,Yindice_stop]=NaN
		else
		temp[Xindice_start,Xindice_stop][Yindice_start,Yindice_stop]=str2num(Strvalue)
      endif

	Duplicate/O temp $name 
	Killwaves temp
      
end

//////////////////////////////////////////////////////

function Multiply():GraphMarquee
//Multuiply by value
variable NorValue
    prompt Norvalue,"Multiply by : "
    Doprompt "Normalize",NorValue
	
	if (v_flag==0)	
		//Get rectangle
		GetMarquee/K left, bottom
		DoMultiply(v_left,v_right,v_bottom,v_top,NorValue)
	endif
end
///////////
function MultiplyFromPannel(ctrlname):ButtonControl
	string Ctrlname
	nvar Kx_start,Kx_stop,Ky_start,Ky_stop, Norvalue
      		DoMultiply(Kx_start,Kx_stop,Ky_start,Ky_stop,NorValue)
end

function DoMultiply(x_start,x_stop,y_start,y_stop,NorValue)
variable x_start,x_stop,y_start,y_stop,NorValue
variable Xindice_start,Xindice_stop,Yindice_start,Yindice_stop,Xnb,Ynb
	string name=Find_TopImageName()
	DuplicateForUndo(name)
	Duplicate/O $name temp 
	
	Xindice_start=round((x_start-DimOffset($name,0))/DimDelta($name,0))
	Xindice_stop=round((x_stop-DimOffset($name,0))/DimDelta($name,0))
	Xnb=Xindice_stop-Xindice_start+1
	Yindice_start=round((y_start-DimOffset($name,1))/DimDelta($name,1))
	Yindice_stop=round((y_stop-DimOffset($name,1))/DimDelta($name,1))
	Ynb=Yindice_stop-Yindice_start+1

	//Do multiply
	temp[Xindice_start,Xindice_stop][Yindice_start,Yindice_stop]*=NorValue
	
	Duplicate/O temp $name
	Killwaves temp
      
end

//////////////////////////////////////////////////////
Macro CropFromMarquee()

		//Get rectangle
		GetMarquee/K left, bottom
		DoCrop(v_left,v_right,v_bottom,v_top)

end

function CropFromPannel(ctrlname):ButtonControl
	string Ctrlname
	nvar Kx_start,Kx_stop,Ky_start,Ky_stop
      		DoCrop(Kx_start,Kx_stop,Ky_start,Ky_stop)
      		
end

function DoCrop(x_start,x_stop,y_start,y_stop)
variable x_start,x_stop,y_start,y_stop
wave Image_backup
variable indiceX_start,indiceY_start,NbX,NbY

	string name=Find_TopImageName()
	DuplicateForUndo(name)
	Duplicate/O $name temp
	
	indiceX_start=round((x_start-DimOffset(temp,0))/DimDelta(temp,0))
	indiceY_start=round((y_start-DimOffset(temp,1))/DimDelta(temp,1))
	temp=Image_backup[indiceX_start+p][indiceY_start+q]

	NbX=round((x_stop-x_start)/DimDelta(temp,0))+1
	NbY=round((y_stop-y_start)/DimDelta(temp,1))+1

	Redimension/N=(NbX,NbY) temp
	SetScale/P x x_start, DimDelta(temp,0), temp
	SetScale/P y y_start, DimDelta(temp,1), temp
	Duplicate/O temp $name
end
//////////////////////////////////////////////////////


/////////  Scaling procedures
/// Img_scale        creates pannel
/// rescale, rescale_step : when one value is changed in pannel

function Img_Scale(ctrlname):ButtonControl
string ctrlname
string name

//SetDataFolder root:ImgProcess
name=Find_TopImageName()
variable/G Img_Min,Img_max,Img_step

DoWindow/F Scaling
        if (V_flag==0)
            NewPanel /W=(700,10,920,150)
            DoWindow/C Scaling
            DoWindow/T Scaling "Scaling"
            ImageStats $name
		Img_min=V_min
		Img_max=V_max
		Img_step=(Img_max-Img_min)/10
		
		SetVariable StepBox,pos={20,60},size={100,20},title=" Step =  ",proc=Rescale_step,limits={-Inf,Inf,10},value=img_step
		SetVariable MinBox,pos={20,10},size={180,20},title=" Min =  "+num2str(v_min),proc=Rescale,limits={-Inf,Inf,Img_step},value=Img_min
		SetVariable MaxBox,pos={20,30},size={180,20},title=" Max =  "+num2str(v_max),proc=Rescale,limits={-Inf,Inf,Img_step},value=img_max
		ModifyImage $name ctab= {Img_min,Img_max,,1}
		// Exponential color scales
		variable/G Gcolor=1
		Button RedBox,pos={21,91},size={60,20},proc=SetToRed,title="Red"
		Button GreyBox,pos={22,114},size={60,20},proc=SetToGray,title="Gray"	
		Button ResetBox,pos={120,91},size={60,20},proc=reset,title="Reset"	
		SetVariable setgamma,pos={120,114},size={52,18},title="g"
		SetVariable setgamma,font="Symbol",limits={0.1,inf,0.1},value= Gcolor
	endif	

end
//
proc Rescale(ctrlName,varNum,varStr,varName) : SetVariableControl
//----------------------------------
	String ctrlName
	Variable varNum
	String varStr
	String varName

	string name,nameCT

	//SetDataFolder root:ImgProcess
	name=Find_TopImageName()
	if (Gcolor==1)
		ModifyImage $name ctab= {Img_min,Img_max,,1}
	else
		nameCT=name+"_CT"
		SetScale/I x Img_min, Img_max,"" $nameCT
		ModifyImage $name cindex= $nameCT
	endif	
end	

//
proc Rescale_step(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
SetVariable MinBox,limits={-Inf,Inf,Img_step}
SetVariable MaxBox,limits={-Inf,Inf,Img_step}

end	
//
Proc SetToRed(ctrlname):ButtonControl
string ctrlname
	SetColor(0)
end

proc SetToGray(ctrlname):ButtonControl
string ctrlname
	SetColor(1)
end

proc reset(ctrlname):ButtonControl
string ctrlname
string name	
	Gcolor=1
	name=Find_TopImageName() // name of active image
	WaveStats/Q $name
	Img_min=V_min
	Img_max=V_max
	Img_step=(Img_max-Img_min)/10
	Setcolor(0)
end
	
Proc SetColor(color)
variable color	
string name,nameCT
	make/o/n=256 pmap=p
	name=Find_TopImageName() // name of active image
	nameCT=name+"_CT"
	make/o/n=(256,3) CT,$nameCT
	if (color==0)
		//red temp
		CT[][0]=min(p,176)*370
		CT[][1]=max(p-120,0)*482
		CT[][2]=max(p-190,0)*1000
	else //grey
		CT=65280-p*256
	endif	
	pmap:=255*(p/255)^Gcolor
	Duplicate/O CT $nameCT
	$nameCT:=CT[pmap[p]][q]	//  255
	WaveStats/Q $name
	//SetScale/I x V_min, V_max,"" $nameCT
	SetScale/I x Img_min, Img_max,"" $nameCT
	ModifyImage $name cindex= $nameCT, ctab= {Img_min,Img_max,,1}
end
//


//////////////////////// end of scaling procedures

/////// Start symmetrize procedures
// Img_Symmetrize(ctrlname)     builds pannel
// AxisTypeProc(ctrlName,popNum,popStr) : PopupMenuControl
// GOTOshow_axis(ctrlName,popNum,popStr) : PopupMenuControl
// Show_axis(ctrlName,varNum,varStr,varName) : SetVariableControl
// Sym_x(x,y,a,b) et Sym_x(x,y,a,b) :       math
// DoSymmetrize(ctrlname):ButtonControl

function Img_Symmetrize(ctrlname):ButtonControl
string ctrlname
NewPanel /W=(600,10,920,210)  as "symmetrize"
//SetDataFolder root:ImgProcess

	variable/G axis_x=0,axis_y=0,axis_angle=0
	SetVariable axisXBox,pos={40,10},size={150,20},title=" Axis X origin =  ",proc=Show_axis,limits={-Inf,Inf,0.1},value=axis_x
	SetVariable axisYBox,pos={40,30},size={150,20},title=" Axis Y origin =  ",proc=Show_axis,limits={-Inf,Inf,0.1},value=axis_y
	SetVariable axisAngle,pos={40,50},size={150,20},title=" Axis angle =     ",proc=Show_axis,limits={-90,90,5},value=axis_angle	
	
	DrawText 10,100, "Area to symmetrize :"
	string/G mode="left/bottom of axis"
	PopupMenu cote,pos={120,80},size={200,21},proc=GOTOShow_axis,title=" ",popvalue=mode, value="left/bottom of axis;right/top of axis"
	variable/G x_start,x_stop
	SetVariable x_startBox,pos={10,110},size={120,20},title=" x from :  ",proc=ShowBoundaries,limits={-Inf,Inf,0.1},value=x_start
	SetVariable x_stopBox,pos={140,110},size={100,20},title=" to ",proc=ShowBoundaries,limits={-Inf,Inf,0.1},value=x_stop
	variable/G y_start,y_stop
	SetVariable y_startBox,pos={10,135},size={120,20},title=" y from :  ",proc=ShowBoundaries,limits={-Inf,Inf,0.1},value=y_start
	SetVariable y_stopBox,pos={140,135},size={100,20},title=" to ",proc=ShowBoundaries,limits={-Inf,Inf,0.1},value=y_stop
	Button DoSymmetrizeButton,pos={100,160},size={65,30},proc=DoSymmetrize,title="Symmetrize"
	
	execute "Show_axis(\" \",0,\" \",\" \")"
end
//
Proc GOTOshow_axis(ctrlName,popNum,popStr) : PopupMenuControl
//-----------------------------
	String ctrlName
	Variable popNum
	String popStr
	
	mode=popstr
	Show_axis(" " ,0," " , " " )
end
//
proc Show_axis(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	variable a_axis,b_axis // y=a_axis*x+b_axis
		if (abs(axis_angle)==90)
			  a_axis=inf
			  b_axis=axis_x
			else
			  a_axis=tan(axis_angle*pi/180)
			  b_axis=axis_y-a_axis*axis_x
		endif
	string name=Find_TopImageName()
	variable ImXstart,ImXstop,ImYstart,ImYstop
	
	RemoveFromGraph/Z Axis
	Make/O /N=2 Axis

	ImXstart=Dimoffset($name,0)
	ImXstop=ImXstart+DimDelta($name,0)*(DimSize($name,0)-1)
	
	ImYstart=Dimoffset($name,1)
	ImYstop=ImYstart+DimDelta($name,1)*(DimSize($name,1)-1)
	
	if (a_axis==inf)
		SetScale/I  x b_axis,b_axis+1e-6,"", Axis
      		Axis[0]=ImYstart
      		Axis[1]=ImYstop
      else
		SetScale/I  x ImXstart,ImXstop,"", Axis
		Axis=a_axis*x+b_axis
		//If limits of axis out of image : rescale
		if (Axis[0]<ImYstart)
			Axis[0]=ImYstart
			ImXstart=(Axis[0]-b_axis)/(a_axis+1e-18)
		endif      
		if (Axis[0]>ImYstop)
			Axis[0]=ImYstop
			ImXstart=(Axis[0]-b_axis)/(a_axis+1e-18)
		endif      
		if (Axis[1]<ImYstart)
			Axis[1]=ImYstart
			ImXstop=(Axis[1]-b_axis)/(a_axis+1e-18)
		endif      
		if (Axis[1]>ImYstop)
			Axis[1]=ImYstop
			ImXstop=(Axis[1]-b_axis)/(a_axis+1e-18)
		endif      
		SetScale/I  x ImXstart,ImXstop,"", Axis
      endif	
	       
	AppendToGraph Axis
	Refresh_SymmetricBoundaries(a_axis,b_axis)
end

proc Refresh_SymmetricBoundaries(a_axis,b_axis)
variable a_axis,b_axis
//Boundaries are global variables : x_start,x_stop,y_start,y_stop
//Tries to propose reasonable value as default values
variable axis_start=dimoffset(axis,0),axis_stop=axis_start+dimDelta(axis,0)

	string name=Find_TopImageName()

	variable ImXstart,ImXstop,ImYstart,ImYstop
	ImXstart=Dimoffset($name,0)
	ImXstop=ImXstart+DimDelta($name,0)*(DimSize($name,0)-1)
	ImYstart=Dimoffset($name,1)
	ImYstop=ImYstart+DimDelta($name,1)*(DimSize($name,1)-1)
	
	variable A_x,A_y,B_x,B_y,Axis0_x,Axis1_x
	Axis0_x=DimOffset(Axis,0)
	Axis1_x=DimOffset(Axis,0)+DimDelta(Axis,0)
	
	if (abs(axis_angle)<=45)
		if (cmpstr(mode,"right/top of axis")==0)
			// les limites sont données par le segment symétrique du bas de l'image
			A_x=Sym_x(Axis0_x,ImYstart,a_axis,b_axis)
			A_y=Sym_y(Axis0_x,ImYstart,a_axis,b_axis)
			B_x=Sym_x(Axis1_x,ImYstart,a_axis,b_axis)
			B_y=Sym_y(Axis1_x,ImYstart,a_axis,b_axis)
			x_start=min(Axis0_x,A_x)
			x_stop=max(Axis1_x,B_x)
			y_start=min (Axis[0],Axis[1])
			y_stop=max(A_y,B_y)
			else
			// les limites sont données par le segment symétrique du haut de l'image
			A_x=Sym_x(ImXstart,ImYstop,a_axis,b_axis)
			A_y=Sym_y(ImXstart,ImYstop,a_axis,b_axis)
			B_x=Sym_x(ImXstop,ImYstop,a_axis,b_axis)
			B_y=Sym_y(ImXstop,ImYstop,a_axis,b_axis)
			x_start=min(Axis0_x,A_x)
			x_stop=max(Axis1_x,B_x)
			y_start=min(A_y,B_y)
			y_stop=max (Axis[0],Axis[1])
		endif	
	else
		if (cmpstr(mode,"right/top of axis")==0)
			// les limites sont données par le segment symétrique du côté gauche de l'image
			A_x=Sym_x(ImXstart,ImYstart,a_axis,b_axis)
			A_y=Sym_y(ImXstart,ImYstart,a_axis,b_axis)
			B_x=Sym_x(ImXstart,ImYstop,a_axis,b_axis)
			B_y=Sym_y(ImXstart,ImYstop,a_axis,b_axis)
			x_start=min(Axis0_x,Axis1_x)
			x_stop=max(A_x,B_x)
			y_start=min (A_y,ImYstart)
			y_stop=max(B_y,ImYstop)
			else
			// les limites sont données par le segment symétrique du côté droit de l'image
			A_x=Sym_x(ImXstop,ImYstart,a_axis,b_axis)
			A_y=Sym_y(ImXstop,ImYstart,a_axis,b_axis)
			B_x=Sym_x(ImXstop,ImYstop,a_axis,b_axis)
			B_y=Sym_y(ImXstop,ImYstop,a_axis,b_axis)
			x_start=min(A_x,B_x)
			x_stop=max(DimOffset(Axis,0),DimOffset(Axis,0)+DimDelta(Axis,0))
			y_start=min (A_y,ImYstart)
			y_stop=max(B_y,ImYstop)
		endif	
	endif	
		
	//if (abs(axis_angle)<=45)
	//	x_start=axis_start
	//	x_stop=axis_stop
	//		if (cmpstr(mode,"right/top of axis")==0)
	//			y_start=min(Axis[0],Axis[1])
	//			y_stop=2*max(Axis[0],Axis[1])-ImYstart
	//			else
	//			y_start=2*min(Axis[0],Axis[1])-ImYstop
	//			y_stop=max(Axis[0],Axis[1])
	//		endif	
	//	else
	//	y_start=Axis[0]
	//	y_stop=Axis[1]
	//		if (cmpstr(mode,"right/top of axis")==0)
	//			x_start=min(axis_start,axis_stop)
	//			x_stop=2*max(axis_start,axis_stop)-ImXstart
	//			else
	//			x_start=2*max(axis_start,axis_stop)-ImXstop
	//			x_stop=max(axis_start,axis_stop)
	//		endif	
	//endif
		
	x_start=round(x_start*100)/100
	x_stop=round(x_stop*100)/100
	y_start=round(y_start*100)/100
	y_stop=round(y_stop*100)/100
	//SetAxis bottom min(x_start,ImXstart),max(x_stop,ImXstop)
	//SetAxis left min(y_start,ImYstart),max(y_stop,ImYstop)
	ShowBoundaries(" ",0," "," ")
end

proc ShowBoundaries(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	Make/O /N=5 SymArea_x,SymArea_y
	SymArea_x[0]=x_start
	SymArea_y[0]=y_start
	SymArea_x[1]=x_stop
	SymArea_y[1]=y_start
	SymArea_x[2]=x_stop
	SymArea_y[2]=y_stop
	SymArea_x[3]=x_start
	SymArea_y[3]=y_stop
	SymArea_x[4]=x_start
	SymArea_y[4]=y_start
		
	RemoveFromGraph/Z SymArea_y
	AppendToGraph SymArea_y vs SymArea_x
	ModifyGraph lstyle(SymArea_y)=3
end
//

Proc DoSymmetrize(ctrlname):ButtonControl
	string ctrlname 

	string name=Find_TopImageName()
	DuplicateForUndo(name)
	Duplicate/O $name New_Image
	
	variable a_axis,b_axis // y=a_axis*x+b_axis
		if (abs(axis_angle)==90)
			  a_axis=inf
			  b_axis=axis_x
			else
			  a_axis=tan(axis_angle*pi/180)
			  b_axis=axis_y-a_axis*axis_x
		endif
		
	//New scaling de l'image 
	//Warning : ici, on suppuse deltaX et deltaY positifs, il faudrait prévoir les autres cas
	variable ImXstart,ImXstop,ImYstart,ImYstop
	variable NewXstart,NewXstop,NewYstart,NewYstop
	variable New_NbX, New_NbY
	ImXstart=Dimoffset($name,0)
	ImXstop=ImXstart+DimDelta($name,0)*(DimSize($name,0)-1)
	ImYstart=Dimoffset(Image,1)
	ImYstop=ImYstart+DimDelta($name,1)*(DimSize($name,1)-1)
	NewXstart=min(x_start,ImXstart)
	NewXstop=max(x_stop,ImXstop)
	NewYstart=min(y_start,ImYstart)
	NewYstop=max(y_stop,ImYstop)
	New_NbX=1+round((NewXstop-NewXstart)/DimDelta(Image,0))
	New_NbY=1+round((NewYstop-NewYstart)/DimDelta(Image,1))
	Make/N=(New_NbX,New_NbY)/O New_Image
	SetScale/P x NewXstart,DimDelta($name,0),"", New_Image
	SetScale/P y NewYstart,DimDelta($name,1),"", New_Image

	//Symetrie
	//NB :  on veut symétriser dans le rectangle défini dans la fenêtre symmetrize, mais à partir de l'axe
	//         on doit donc redéfinir les bornes pour chaque valuer de x
	variable x_cur,y_cur
	New_Image=NaN
	New_Image=Image_backup(x)(y)
	x_cur=x_start
	do
		if (a_axis==inf)
			if (cmpstr(mode,"right/top of axis")==0)
				y_cur=y_start
				else
				y_cur=y_stop
			endif	
		else
			y_cur=a_axis*x_cur+b_axis
			if (y_cur<y_start)
	    			y_cur=y_start
			endif    
			if (y_cur>y_stop)
	    			y_cur=y_stop
			endif	
		endif	
		// Pour la valeur x_cur : calculer de y_start à y_cur si 	left/bottom of axis
		//								y_cur à y_stop si right/top of axis
		
		
		//if (axis_angle<0)
			if (cmpstr(mode,"right/top of axis")==0)
				New_Image(x_cur)(y_cur,y_stop)=Image_backup(Sym_x(x,y,a_axis,b_axis))(Sym_y(x,y,a_axis,b_axis)) 
			else
				New_Image(x_cur)(y_start,y_cur)=Image_backup(Sym_x(x,y,a_axis,b_axis))(Sym_y(x,y,a_axis,b_axis)) 
			endif
			print
		//endif
		
		//if (a_axis==0)
		//	New_Image(x_cur)(y_start,y_stop)=Image_backup(Sym_x(x,y,a_axis,b_axis))(Sym_y(x,y,a_axis,b_axis)) 
		//endif
		
		//if (a_axis>0)
		//	if (cmpstr(mode,"right of axis")==0)
		//		New_Image(x_cur)(y_start,y_cur)=Image_backup(Sym_x(x,y,a_axis,b_axis))(Sym_y(x,y,a_axis,b_axis)) 
		//	else
		//		New_Image(x_cur)(y_cur,y_stop)=Image_backup(Sym_x(x,y,a_axis,b_axis))(Sym_y(x,y,a_axis,b_axis)) 
		//	endif
		//endif
		
		//if (a_axis==inf)
		//	New_Image(x_cur)(y_start,y_stop)=Image_backup(Sym_x(x,y,a_axis,b_axis))(Sym_y(x,y,a_axis,b_axis)) 
		//endif
		x_cur+=DimDelta(Image,0)
	while (x_cur<=x_stop)

	Duplicate/O New_Image $name
	Killwaves New_Image
	SetAxis/A
end
//////////////////

function Sym_x(x,y,a,b)
//return x value of the point symmetric of (x,y) with respect to a*x+b
variable x,y,a,b
variable res
if (a==inf)
      res=b-(x-b)
      else
      res=(x*(1-a^2)+2*a*y-2*a*b)/(1+a^2)
endif      
return  res
end
//
function Sym_y(x,y,a,b)
variable x,y,a,b
variable res
if (a==inf)
      res=y
      else
      res=(y*(-1+a^2)+2*a*x+2*b)/(1+a^2)
endif
return  res
end

////// end of symmetrize procedures


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function Img_Shift()

	string name=Find_TopImageName()
	DoWindow/F Shift
        if (V_flag==0)
            NewPanel /W=(600,10,750,100)
            DoWindow/C Shift
            DoWindow/T Shift "Shift"
		
		variable/G Shift_X0,Shift_Y0
		Shift_X0=DimOffset($name,0)
		Shift_Y0=DimOffset($name,1)
		SetVariable Shift_xBox,pos={10,10},size={100,20},title=" X0 =  ",proc=DoShift,limits={-Inf,Inf,DimDelta($name,0)},value=Shift_X0
		SetVariable Shift_yBox,pos={10,30},size={100,20},title=" Y0 =  ",proc=DoShift,limits={-Inf,Inf,DimDelta($name,1)},value=Shift_Y0
	endif	

end

proc DoShift(ctrlName,varNum,varStr,varName) : SetVariableControl
//----------------------------------
	String ctrlName
	Variable varNum
	String varStr
	String varName

	string name=Find_TopImageName()
	DuplicateForUndo(name)
	SetScale/P x Shift_X0,DimDelta($name,0), $name
	SetScale/P y Shift_Y0,DimDelta($name,1), $name
	//SetAxis/A
end



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////                Interpolate                  ///////////////////////////////////////////////////////////////////////

// Interp_linear    just Igor's interp2D
// Interp_through max            Try to do better
// InterpolateNaNpoints(side)													use Igor NaNZapmedian
// SquareAvgStart(side_x,side_y)  and SquareAvg(Correct_FS,side_x,side_y)       takes the avg value of points in rectangle (discard NaN points)
// DefineRectangle(side_x,side_y)                 pas utile ?

Macro Interp_linear(kx_step,ky_step)
	variable kx_step,ky_step

	string name=Find_TopImageName()
	DuplicateForUndo(name)	
	
	variable NbX,NbY
	NbX=round((DimDelta($name,0)*Dimsize($name,0))/kx_step)
	NbY=round((DimDelta($name,1)*Dimsize($name,1))/ky_step)
	Make/O/N=(NbX,NbY) temp
	SetScale/P x DimOffset($name,0),kx_step,"", temp
	SetScale/P y DimOffset($name,1),ky_step,"", temp
	temp=NaN
	temp=interp2D($name,x,y)
	Duplicate/O temp $name
	Killwaves temp
end

function Interp_throughMax(sigma)
variable sigma
sigma=0.6
//L'idée est de faire l'interpolation dans la direction du maximum.
//On considere les deux lignes encadrant M dans l'image originale 
//et on y cherche le maximum dans une rangée de points de taille SigmaX (qui doit être de l'ordre de deltaY)
//On trace la droite parallèle à la direction de ces deux maximums passant par M : A et B en sont les intersections avec les 2 lignes de l'image d'origine
// On dit alors : I(M)= d(BM)/d(AB) * I(A)  + d(AM)/d(AB) * I(B) 

nvar Kx_start=root:ImgProcess:Kx_start,Kx_stop=root:ImgProcess:Kx_stop,Ky_start=root:ImgProcess:Ky_start,Ky_stop=root:ImgProcess:Ky_stop
nvar Kx_step= root:ImgProcess:Kx_step,Ky_step= root:ImgProcess:Ky_step
nvar NbKx= root:ImgProcess:NbKx,NbKy= root:ImgProcess:NbKy
variable Ix_m,Iy_M,x_M,y_m,Ix_A,Iy_A,x_a,y_A,x_B,Ix_B,y_B,Iy_B,Ix0,SigmaX,d_AM,d_AB
variable x1,w1,x2,w2,slope

		SetDataFolder root:ImgProcess
		Duplicate/O Image Image_backup
		
		
		// Map sera l'image à interpoler, Intermap, l'image interpolée (trop long si on ne le fait pas par une fonction).
		//Les variables globales Kx_step, Ky_step sont les nouvelles valeurs à lui appliquer.
		
		if (NbKy==(Ky_stop-Ky_start)/Ky_step)
		      //then no interpolation to do on the last row
		     Ky_stop=Ky_stop-Ky_step
		endif
		Ky_start=Ky_start+Ky_step // avoid first and last lines where no possible interpolation
		NbKx=round((Kx_stop-Kx_start)/Kx_step)+1
		NbKy=round((Ky_stop-Ky_start)/Ky_step)+1
		
		Make/O/N=(NbKx,Nbky) InterMap
		SetScale/P x Kx_start,Kx_step,"", InterMap
		SetScale/P y Ky_start,Ky_step,"", InterMap
		
		SigmaX=round(DimDelta(Image_backup,1)/DimDelta(Image_backup,0))*sigma//x range to consider in search for max
		//SigmaX=0
		//print SigmaX
		
		InterMap=0
				
		//Do Interpolation
		
		//consider for the interpolation of M, a series of points A with :
					//		- the 2 closest Y value 
					//		- a row of points along x of size sigmaX (should be chosen similar to y spacing)
		Iy_M=0//Y indice value to be interpolated
		Ix_M=0//X indice value to be interpolated
			do //Loop on Iy_M
				Ix_M=0
				y_M=Ky_start+Iy_M*Ky_step
				Iy_A=floor((y_M-Dimoffset(Image_backup,1))/DimDelta(Image_backup,1))
				Y_A=Dimoffset(Image_backup,1)+Iy_A*DimDelta(Image_backup,1)
				//print "y_M=",y_M
				do //Loop on Ix_M
				 
					x_M=Kx_start+Ix_M*Kx_step
				    if (Image_backup(x_M)(y_M)==0)	
				    	InterMap[Ix_M][Iy_M]=NaN
				    else
					Ix0=round((x_M-Dimoffset(Image_backup,0))/DimDelta(Image_backup,0))
					//Ix0=indice of closest x value on Image_backup
					//print "ix_M=",ix_m,"iy_M=",iy_M,"x_M=",x_m,"y_M=",y_M
					
					//First calculate max
						Ix_A=Ix0-SigmaX 
						x1=0 // x value for max on row below
						w1=0 // max value
						x2=0  // x value on row above
						w2=0  // max value
						do //loop on a row of point of x axis 
							if (Image_backup[ix_A][iy_A]>w1)
								x1=Dimoffset(Image_backup,0)+Ix_A*DimDelta(Image_backup,0)
								w1=Image_backup[ix_A][iy_A]
							endif
							if (Image_backup[ix_A][iy_A+1]>w2)
								x2=Dimoffset(Image_backup,0)+Ix_A*DimDelta(Image_backup,0)
								w2=Image_backup[ix_A][iy_A+1]
							endif	
							Ix_A+=1
						while (Ix_A<=Ix0+SigmaX)
						
					//Then direction to interpolate	a=(x2-x1), b=DimDelta(Image_backup,1)
						//calculate crossings A and B with the two y lines 
						x_A=x_M-(x2-x1)*(y_M-y_A)/DimDelta(Image_backup,1)
						Ix_A=(x_A-Dimoffset(Image_backup,0))/DimDelta(Image_backup,0)
						y_B=y_A+DimDelta(Image_backup,1)
						x_B=x_M-(x2-x1)*(y_M-y_B)/DimDelta(Image_backup,1)
						Ix_B=round((x_B-Dimoffset(Image_backup,0))/DimDelta(Image_backup,0))
						Iy_B=Iy_A+1
						
						d_AM=sqrt(   (x_M-x_A)^2 +(y_M-y_A)^2)
						d_AB=sqrt(   (x_B-x_A)^2 +(y_B-y_A)^2)
						slope=(Image_backup[ix_B][iy_B]-Image_backup[ix_A][iy_A])/d_AB
						InterMap[ix_M][iy_M]+=(Image_backup[ix_A][iy_A]+slope*d_AM)
						//print "M=",x_M,y_M,"x1=",x1,"x2=",x2,"A=",x_a,y_A,"B=",x_B,y_B
						//print "M=",x_M,y_M,"f(A)=",Image_backup[ix_A][iy_A],"f(B)=",Image_backup[ix_B][iy_B],"slope,d_AB,d_AM=",slope,d_AB,d_AM
					endif //If on Image_backup(M)=0
					Ix_M+=1	
				while (Ix_M<=(DimSize(InterMap,0)-1))
				
				Iy_M+=1
			while (Iy_M<=(DimSize(InterMap,1)-1))
		
		
	Duplicate/O InterMap Image
	Killwaves InterMap
end
//////
Macro InterpolateNaNpoints(side)
variable side
string name
	name=Find_TopImageName()
	DuplicateForUndo(name)
	MatrixFilter/N=(side)/P=1 NaNZapMedian, $name
end
///////
Macro SquareAvgStart(side_x,side_y)
variable side_x,side_y
string name
variable center_x,center_y

	RemoveFromGraph/Z square_y
	Make/O /N=5 square_x,square_y
	center_x=Dimoffset($name,0)+round(Dimsize($name,0)/2)*DimDelta($name,0)
	center_y=Dimoffset($name,1)+round(Dimsize($name,1)/2)*DimDelta($name,1)
	square_x[0]=center_x-side_x*DimDelta($name,0)
	square_y[0]=center_y-side_y*DimDelta($name,1)
	square_x[1]=center_x+side_x*DimDelta($name,0)
	square_y[1]=center_y-side_y*DimDelta($name,1)
	square_x[2]=center_x+side_x*DimDelta($name,0)
	square_y[2]=center_y+side_y*DimDelta($name,1)
	square_x[3]=center_x-side_x*DimDelta($name,0)
	square_y[3]=center_y+side_y*DimDelta($name,1)
	square_x[4]=center_x-side_x*DimDelta($name,0)
	square_y[4]=center_y-side_y*DimDelta($name,1)
	AppendToGraph square_y vs square_x
	
	SquareAvg(side_x,side_y)

end

function 	SquareAvg(side_x,side_y)
variable side_x,side_y
//Takes the average of the points in (2*side+1)*(2*side+1) around one point

	variable ind_p,ind_q,sum_p,sum_q,somme,nb_somme,indice
	string name
	
	name=Find_TopImageName()
	DuplicateForUndo(name)
	
	Duplicate/O $name temp
	Duplicate/O $name new_image
	new_image=0
	ind_p=0
	do   
		ind_q=0
	//print ind_p,ind_q
	do
		//compute avg for one value
		sum_p= max(ind_p-side_x,0)
			somme=0
			nb_somme=0
			do
				sum_q= max(ind_q-side_y,0)
				do
					if (temp[sum_p][sum_q]==temp[sum_p][sum_q]) //i.e. not NaN value
						somme+=temp[sum_p][sum_q]
						nb_somme+=1
					endif
					if (ind_q==1)
					 //print ind_p,ind_q,sum_p,sum_q
					endif
					sum_q+=1
				while (sum_q<=min(ind_q+side_y,dimsize(temp,1)-1))
				sum_p+=1
			while (sum_p<=min(ind_p+side_x,dimsize(temp,0)-1))
			New_image[ind_p][ind_q]=somme/nb_somme
		ind_q+=1
	while (ind_q<Dimsize(temp,1))
	//while (ind_q<=5)
	ind_p+=1
while (ind_p<Dimsize(temp,0))
//while (ind_p<=5)

Duplicate/O new_image $name
Killwaves temp,new_image
end
/////////

////////////

function ImgFromContour()
//First transforms the image into X,Y,Z waves (because contour would not work if there are NaN points)
//Then use Igir contourZ procedure

variable contour_side=50
		
string name=find_TopImageName()
variable Nb,ind_p,ind_q,indice

DuplicateForUndo(name)

Duplicate/O $name, temp

Nb=Dimsize(temp,0)*Dimsize(temp,1)
Make/O /N=(Nb) temp_X,temp_Y,temp_Z
ind_p=0
indice=0
do
	ind_q=0
	//print ind_p,dimsize(temp,0)
	do
		if (temp[ind_p][ind_q]==temp[ind_p][ind_q]) //i.e. not a NaN value
			temp_X[indice]=dimoffset(temp,0)+ind_p*dimdelta(temp,0)
			temp_Y[indice]=dimoffset(temp,1)+ind_q*dimdelta(temp,1)
			temp_Z[indice]=temp[ind_p][ind_q]
			indice+=1
		endif
		ind_q+=1
	while (ind_q<Dimsize(temp,1))
	ind_p+=1
while (ind_p<Dimsize(temp,0))

Redimension /N=(indice) temp_X,temp_Y,temp_Z

		Display;AppendXYZContour temp_Z vs {temp_X,temp_Y}
		DoWindow/C contourplot
		ModifyContour temp_Z autoLevels={*,*,contour_side}
		ModifyContour temp_Z labels=0
		
		temp=0
		temp= ContourZ("","temp_Z",0,x,y)
		Dowindow/K contourplot
		
Duplicate/O temp $name
Killwaves temp_X,temp_Y,temp_Z,temp
end
//////////

Macro DefineRectangle(side_x,side_y)
variable side_x,side_y
string curr,name
variable nb,center_x,center_y

RemoveFromGraph/Z square_y

curr=GetDataFolder(1)
nb=ItemsInList(wavelist("*"," ","DIMS:2,WIN:"))
if (nb>0)
	name=StringFromList(0,wavelist("*","","DIMS:2,WIN:"))
	Make/O /N=5 square_x,square_y
	center_x=Dimoffset($name,0)+round(Dimsize($name,0)/2)*DimDelta($name,0)
	center_y=Dimoffset($name,1)+round(Dimsize($name,1)/2)*DimDelta($name,1)
	square_x[0]=center_x-side_x*DimDelta($name,0)
	square_y[0]=center_y-side_y*DimDelta($name,1)
	square_x[1]=center_x+side_x*DimDelta($name,0)
	square_y[1]=center_y-side_y*DimDelta($name,1)
	square_x[2]=center_x+side_x*DimDelta($name,0)
	square_y[2]=center_y+side_y*DimDelta($name,1)
	square_x[3]=center_x-side_x*DimDelta($name,0)
	square_y[3]=center_y+side_y*DimDelta($name,1)
	square_x[4]=center_x-side_x*DimDelta($name,0)
	square_y[4]=center_y-side_y*DimDelta($name,1)
	AppendToGraph square_y vs square_x
endif	
endmacro

////////// Interpolation procedures---------------------------------


function ImgPannel_interpolate2D(ctrlname):ButtonControl
string ctrlname
//SetDataFolder root:ImgProcess
string/G methode="linear"
variable/G Bgd=0
variable/G Kx_start,Kx_stop, Ky_start,Ky_stop,Kx_step,Ky_step,NbKx,NbKy
	
	string name=Find_TopImageName()
	Kx_start=round(Dimoffset($name,0)*1000)/1000
	Kx_stop=round((Kx_start+DimDelta($name,0)*(DimSize($name,0)-1))*1000)/1000
	Kx_step=round(DimDelta($name,0)*100000)/100000
	Ky_start=round(Dimoffset($name,1)*1000)/1000
	Ky_stop=round((Ky_start+DimDelta($name,1)*(DimSize($name,1)-1))*1000)/1000
	Ky_step=round(DimDelta($name,1)*100000)/100000
	NbKx=round((Kx_stop-Kx_start)/Kx_step)+1
	NbKy=round((Ky_stop-Ky_start)/Ky_step)+1

	DoWindow/F Interpolation
       if (V_flag==0)
            NewPanel /W=(700,10,1000,180)
            DoWindow/C Interpolation
            DoWindow/T Interpolation "Interpolation"
            //ModifyPanel cbRGB=(65280,32768,32768)
            SetVariable Kxstep,pos={20,10},size={120,20},title=" kx step :  ",proc=RefreshStep,limits={-Inf,Inf,Kx_step},value=Kx_step
		SetVariable NbKxbox,pos={150,10},size={120,15},title="Nb points :",value=NbKx,proc=RefreshNbPnts
		SetVariable Kystep,pos={20,40},size={120,20},title=" ky step :  ",proc=RefreshStep,limits={-Inf,Inf,Ky_step},value=Ky_step
		SetVariable NbKybox,pos={150,40},size={120,15},title="Nb points :",value=NbKy,proc=RefreshNbPnts
		// Lines below where meant for different averaging procedures, I don't know if this should be kept. 
			//DrawText 20,90,"With no NaN points "
			//PopupMenu InterMethode1,pos={10,95},size={111,21},proc=SelectMethode,title="Méthode ",popvalue="Avergae"
			//PopUpMenu InterMethode1,value="Average"//linear;through max" 
			//DrawText 170,90,"With NaN points "
			//PopupMenu InterMethode2,pos={150,95},size={111,21},proc=SelectMethode,title="Méthode ",popvalue="linear", value="Igor;by average"
		Button DoRefresh,pos={18,129},size={65,30},proc= ImgPannel_interpolate2D,title="Refresh"
		Button DoInterpolate,pos={158,129},size={65,30},proc=DoInterpolate,title="Interpolate"
       endif
end

function DoInterpolate(ctrlname):Buttoncontrol
string ctrlname
nvar Kx_step,Ky_step,NbKx,NbKy
	string name=Find_TopImageName()
	 DoInterpolate2D(name,Kx_step,Ky_step)
end

function DoInterpolate2D(name,Kx_step,Ky_step)
string name
variable Kx_step,Ky_step

	variable AvgX,AvgY,NbKx,NbKy

	NbKx=DimSize($name,0)*DimDelta($name,0)/Kx_step
	NbKy=DimSize($name,1)*DimDelta($name,1)/Ky_step
	Make/O/N=(NbKx,NbKy) temp
	SetScale/P x, DimOffset($name,0),Kx_step, temp
	SetScale/P y , DimOffset($name,1),Ky_step,temp
	
	//Average image in a rectangle corresponding to the size of desired sampling
	AvgX=round(Kx_step/DimDelta($name,0))
	AvgY=round(Ky_step/DimDelta($name,1))
	if (AvgX>=1 && AvgY>=1)
		//ImageInterpolate/PXSZ={AvgX,AvgY} Pixelate $name
		wave M_PixelatedImage
		SetScale/P x, DimOffset($name,0),DimDelta($name,0)*AvgX, M_PixelatedImage 
		SetScale/P y , DimOffset($name,1),DimDelta($name,1)*AvgY,M_PixelatedImage
		temp=interp2D(M_PixelatedImage,x,y)
		Killwaves M_PixelatedImage
		else
		temp=interp2D($name,x,y)
	endif
	
	Duplicate/O temp $name
	Killwaves temp
end


function DoInterpolate3D(name)
string name
// Average images along z with Kz_step (rounded to integer value)
// Then interpolate each (x,y) image with Kx_step,Ky_step

variable Kx_step,Ky_step,kz_step
variable AvgX,AvgY,AvgZ
variable NbKx,NbKy,NbKz
	
	Kx_step=round(DimDelta($name,0)*100000)/100000
	Ky_step=round(DimDelta($name,1)*100000)/100000
	Kz_step=round(DimDelta($name,2)*100000)/100000
	NbKx=DimSize($name,0)
	NbKy=DimSize($name,1)
	NbKZ=DimSize($name,2)
	
	print "Old Kx step=",Kx_step,"NbKx=",NbKx
	print "Old Ky step=",Ky_step,"NbKy=",NbKy
	print "Old Kz step=",Kz_step,"NbKz=",NbKz
	
	
	prompt Kx_step,"New Kx step ="
	prompt Ky_step,"New Ky step ="
	prompt Kz_step,"New Kz step ="
	Doprompt "Enter values", Kx_step,Ky_step,Kz_step
	
	if (v_flag==0)
	AvgZ=round(Kz_step/DimDelta($name,2))
	if (AvgZ>1)
		Kz_step=AvgZ*DimDelta($name,2)
	else
		Kz_step=DimDelta($name,2)
	endif	
	
	NbKx=round(DimSize($name,0)*DimDelta($name,0)/Kx_step)
	NbKy=round(DimSize($name,1)*DimDelta($name,1)/Ky_step)
	NbKz=round(DimSize($name,2)*DimDelta($name,2)/Kz_step)
	
	//Average over z
	Make/O/N=( DimSize($name,0), DimSize($name,1),NbKz) temp3D
	SetScale/P x, DimOffset($name,0), DimDelta($name,0), temp3D
	SetScale/P y , DimOffset($name,1), DimDelta($name,1),temp3D
	SetScale/P z ,  DimOffset($name,2),Kz_step,temp3D

	Duplicate/O $name Old_temp
		
	variable indice=0
	do
		temp3D=Old_temp[p][q][r*AvgZ+indice]
		indice+=1
	while (indice<AvgZ)
	
	Duplicate/O temp3D Old_temp
		
	// Average over (x,y)
	Redimension/N=(NbKx,NbKy,-1) temp3D
	SetScale/P x,DimOffset($name,0),Kx_step, temp3D
	SetScale/P y , DimOffset($name,1),Ky_step,temp3D
	
	Make/O/N=( DimSize($name,0), DimSize($name,1)) temp2D
	SetScale/P x, DimOffset($name,0),DimDelta($name,0), temp2D
	SetScale/P y , DimOffset($name,1),DimDelta($name,1),temp2D
	
	AvgX=round(Kx_step/DimDelta($name,0))
	AvgY=round(Ky_step/DimDelta($name,1))
	
		if (AvgX>=1 && AvgY>=1)
			indice=0
			do
				Redimension/N=( DimSize($name,0), DimSize($name,1)) temp2D
				SetScale/P x, DimOffset($name,0),DimDelta($name,0), temp2D
				SetScale/P y , DimOffset($name,1),DimDelta($name,1),temp2D
				temp2D=Old_temp[p][q][indice]
				DoInterpolate2D("temp2D",Kx_step,Ky_step)		
				temp3D[][][indice]=temp2D[p][q]	
				indice+=1
			while (indice<DimSize(temp3D,2)	)
		else
			temp3D=interp3D($name,x,y,z)
		endif

	Killwaves/Z M_PixelatedImage
	
	Duplicate/O temp3D $name
	Killwaves temp3D,temp2D,Old_temp
	
	if (cmpstr(name,"tmp_3D")==0)
		//refresh 3D window
		string folder=GetDataFolder(0)
		string  Image3D=folder+"_"
		DoWindow/K $Image3D
		 execute "Load3DImage(\""+folder+"\")"
	endif
	
	endif
end

function ImgPannel_combine(ctrlname):ButtonControl
string ctrlname
variable n=1
string name,curr	
	
	curr=GetDataFolder(1)
	prompt name, "Name of wave to combine",popup,WaveList("*",";","DIMS:2")
	prompt n,"factor"
	DoPrompt "Combine with...",name,n
	
	if (v_flag==0)
	combine(curr+name,"root:ImgProcess:Image",n)
	DuplicateForUndo("root:ImgProcess:Image")

	Duplicate/O root:FS_temp root:ImgProcess:Image
	Killwaves root:FS_temp
	endif
end

Function Combine(name1,name2,n)
string name1,name2   // name with path
variable n // output=(wave1+n*wave2)/(1+n)
variable startX1,startX2,stopX1,stopX2,startY1,startY2,stopY1,stopY2
variable start_x,stop_x,start_y,stop_y,delta_x,delta_y,Nb_x,Nb_y
variable x0,y0,index_p,index_q,p1,q1,p2,q2,val1,val2
	
	SetDataFolder root:
	Duplicate/O $name1 wave1
	Duplicate/O $name2 wave2
	
	startX1=DimOffset(wave1,0)
	startX2=DimOffset(wave2,0)
	stopX1=DimOffset(wave1,0)+DimDelta(wave1,0)*(DimSize(wave1,0)-1)
	stopX2=DimOffset(wave2,0)+DimDelta(wave2,0)*(DimSize(wave2,0)-1)
	delta_x=min(Dimdelta(wave1,0),Dimdelta(wave2,0))
	start_x=min(startX1,startX2)
	stop_x=max(StopX1,stopX2)
	Nb_x=round((stop_x-start_x)/delta_x)+1
	
	startY1=DimOffset(wave1,1)
	startY2=DimOffset(wave2,1)
	stopY1=DimOffset(wave1,1)+DimDelta(wave1,1)*(DimSize(wave1,1)-1)
	stopY2=DimOffset(wave2,1)+DimDelta(wave2,1)*(DimSize(wave2,1)-1)
	delta_y=min(Dimdelta(wave1,1),Dimdelta(wave2,1))
	start_y=min(startY1,startY2)
	stop_y=max(stopY1,stopY2)
	Nb_y=round((stop_y-start_y)/delta_y)+1
	
	Make/O /N=(Nb_x,Nb_y) FS_temp
	SetScale/P x start_x, delta_x," " ,FS_temp
	SetScale/P y start_y, delta_y," " ,FS_temp
	
	index_p=0
	do
	  x0=start_x+index_p*delta_x
	  p1=round((x0-startX1)/DimDelta(wave1,0))
	  p2=round((x0-startX2)/DimDelta(wave2,0))
	  index_q=0
	  do
		y0=start_y+index_q*delta_y
		q1=round((y0-startY1)/DimDelta(wave1,1))
		q2=round((y0-startY2)/DimDelta(wave2,1))
				
		val1=wave1[p1][q1]
		if (p1<0)
		   val1=NaN 
		endif   
		if (q1<0) 		   
			val1=NaN 
		endif
		if (p1>=Dimsize(wave1,0)) 		   
			val1=NaN 
		endif
		if (q1>=Dimsize(wave1,1))		   
			val1=NaN 
		endif
		
		val2=wave2[p2][q2]
		if (p2<0)
		   val2=NaN 
		endif   
		if (q2<0) 		   
			val2=NaN 
		endif
		if (p2>=Dimsize(wave2,0)) 		   
			val2=NaN 
		endif
		if (q2>=Dimsize(wave2,1))		   
			val2=NaN 
		endif
			
		if (val1==val1) //valeur déjà assignée
			if (val2==val2)
			     FS_temp[index_p][index_q]=(val1+n*val2)/2
				else
			     FS_temp[index_p][index_q]=val1
			endif     
		else // pas de valeur assignée (NaN ou hors zone d'existence) : valeur de wave2 si elle existe
			if (val2==val2)
			     FS_temp[index_p][index_q]=n*val2
			else     
				FS_temp[index_p][index_q]=NaN
			endif     
		endif

		index_q+=1
	    while (index_q<Nb_y)
           index_p+=1
	while (index_p<Nb_x)
	
	Killwaves wave1,wave2	
end

////////
proc RefreshStep(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	string name=Find_TopImageName()
	DuplicateForUndo(name)
	NbKx=round((Kx_stop-Kx_start)/Kx_step)+1
	NbKy=round((Ky_stop-Ky_start)/Ky_step)+1
	//Redimension/N=(NbKx,NbKy) $name
	//SetScale/P x Kx_start,Kx_step, $name
	//SetScale/P y Ky_start,Ky_step, $name
	//$name=interp2D(Image_backup,x,y)
end
////////
proc RefreshNbPnts(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	string name=Find_TopImageName()
	DuplicateForUndo(name)
	Kx_step=(Kx_stop-Kx_start)/(NbKx-1)
	Ky_step=(Ky_stop-Ky_start)/(NbKy-1)
	//Redimension/N=(NbKx,NbKy) $name
	//SetScale/P x Kx_start,Kx_step, $name
	//SetScale/P y Ky_start,Ky_step, $name
	//$name=interp2D(Image_backup,x,y)
end
/////////
Proc SelectMethode(ctrlName,popNum,popStr) : PopupMenuControl
//-----------------------------
	String ctrlName
	Variable popNum
	String popStr
	
	SetDataFolder "root:ImgProcess"
	methode=popStr
	//if (cmpstr(methode,"through maximum")==0)
	//     variable/G sigma=0.6
	  //   SetVariable sigma,pos={200,132},size={80,21},title="  ",noproc,limits={-Inf,Inf,0.1},value=sigma
	    // Drawtext 180,170, "width to search for max "
	     //Drawtext 180,182," (in multiples of delta y) "
	//endif
end

Proc GoToInterp(ctrlname):Buttoncontrol
string ctrlname
//svar methode=root:ImgProcess:methode
SetDataFolder root:ImgProcess
	if (cmpstr(methode,"linear")==0)
		Interp_linear() 
	endif
	if (cmpstr(methode,"through max")==0)
		Interp_throughmax(sigma)
      endif
      	if (cmpstr(methode,"Igor")==0)
		InterpolateNaNpoints()
      endif
      	if (cmpstr(methode,"by average")==0)
		SquareAvgStart()
      endif
end


///////////////////////////////////////////////   End of Interpolate procedures

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////    Average procedures


Macro  IgorAvg(size,NbTimes)
variable Size=3,NbTimes=1
string name=Find_TopImageName()
if (exists("Image_backup")==1)
	Duplicate/O Image_backup Image_backup_backup
endif
Duplicate/O $name Image_backup 

MatrixFilter/N=(size)/P=(NbTimes) avg, $name

end


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////:
///////////////////////:       Rotation
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////:

Macro RotationFromPannel(ctrlname):ButtonControl
//La différence avec le menu, c'est qu'on tient le compte des valeurs cumulées de rotation
	String Ctrlname
	 string curr
	curr=GetDataFolder(1)
	SetDataFolder root:ImgProcess
	RotationFromMenu()
	SetDataFolder curr
end


Macro RotationFromMenu(NewAngle)
//Just a trick because we want a macro to get it written in command line
	variable NewAngle

	string name=Find_TopImageName()
	DuplicateForUndo(name)
	LetsRotate2D($name,Newangle)
	
	if (cmpstr(name,"Image")==0)
		variable/G angle_image, angle_back,angle_back_back,angle_back_back_back
		angle_image+=NewAngle
		angle_back_back_back=angle_back_back
		angle_back_back=angle_back
		angle_back=NewAngle  
	endif
end

function LetsRotate2D(Image,angle)
wave Image
variable angle

	Duplicate/O Image, temp
	SetScale/P x 0,1, temp
	SetScale/P y 0,1, temp
	Duplicate/O temp, temp1
	//SquareAfterRotation(temp,angle)
	//temp=interp2D(Image,RotX(x,y,-angle),RotY(x,y,-angle))
	temp=interp2D(temp1,RotX(p,q,-angle),RotY(p,q,-angle))
	
	//Remove spikes (why do they appear ?)
	Wavestats/Q Image
	temp=min(V_max,temp(x)(y))
	temp=max(V_min,temp(x)(y))
	Duplicate/O temp Image
	Killwaves temp
end	

function LetsRotate3D(Image,angle)
wave Image    //this is tmp_3D
variable angle
//Used by 3D window to rotate dispersion
//X and Z are the two coordinates to rotate

	Make/O/N=(dimsize(Image,0),dimsize(Image,2)) temp2D  // dimension d'une surface de Fermi
	SetScale/P x dimoffset(Image,0),DimDelta(Image,0), temp2D
	SetScale/P y dimoffset(Image,2),DimDelta(Image,2), temp2D
	SquareAfterRotation(temp2D,angle)  // Also choose step (transferred through temp2D)
		
	Make/O/N=(dimsize(temp2D,0),dimsize(Image,1),dimsize(temp2D,1)) temp3D
	SetScale/P x dimoffset(temp2D,0),DimDelta(temp2D,0), temp3D
	SetScale/P z dimoffset(temp2D,1),DimDelta(temp2D,1), temp3D
	SetScale/P y dimoffset(Image,1),DimDelta(Image,1), temp3D
	
	//temp3D=interp3D(Image,RotX(x,z,-angle),y,RotY(x,z,-angle))
	// Average raw data before doing interpolation
		//variable New_dx,New_dy
		//New_dx=max(abs(DimDelta(temp2D,0)*cos(-angle*pi/180)),abs(DimDelta(temp2D,1)*sin(-angle*pi/180)))
		//New_dy=max(abs(DimDelta(temp2D,0)*sin(-angle*pi/180)),abs(DimDelta(temp2D,1)*cos(-angle*pi/180)))
		//print "Average over",new_dx/dimdelta(Image,0),"point along slits and",new_dy/dimdelta(Image,2),"point along theta"
		//DoInterpolate2D(Image,New_dx,New_dy)
	temp3D=interp3D(Image,cos(angle*pi/180)*x+sin(angle*pi/180)*z,y,-sin(angle*pi/180)*x+cos(angle*pi/180)*z) // Just interpolate, no averaging
		
	//Remove spikes (why do they appear ?)
	Wavestats/Q Image
	temp3D=min(V_max,temp3D(x)(y)(z))
	temp3D=max(V_min,temp3D(x)(y)(z))
	Duplicate/O temp3D Image
	Killwaves temp2D,temp3D
end	

function LetsRotate3D_July14(Image,angle)
wave Image    //this is tmp_3D
variable angle
//Used by 3D window to rotate dispersion
//X and Z are the two coordinates to rotate
// Compared to Letsrotate3D, we want to make use of all the signal over noise by averaging in the basic rectangle.

	Make/O/N=(dimsize(Image,0),dimsize(Image,2)) temp2D  // dimension d'une surface de Fermi
	SetScale/P x dimoffset(Image,0),DimDelta(Image,0), temp2D
	SetScale/P y dimoffset(Image,2),DimDelta(Image,2), temp2D
	SquareAfterRotation(temp2D,angle)  // Also choose step (transferred through temp2D, which asks user the final choice)
	
	Make/O/N=(dimsize(temp2D,0),dimsize(Image,1),dimsize(temp2D,1)) temp3D
	SetScale/P x dimoffset(temp2D,0),DimDelta(temp2D,0), temp3D
	SetScale/P z dimoffset(temp2D,1),DimDelta(temp2D,1), temp3D
	SetScale/P y dimoffset(Image,1),DimDelta(Image,1), temp3D
	
	// Calculates limits of basic rectangle after rotation by -angle
	// Same as in SquareAfterRotation
		variable xA,yA,xB,yB,xC,yC,xD,yD
		xA=RotX(0,0,-angle)
		yA=RotY(0,0,-angle)
		xB=RotX(dimDelta(temp3D,0),0,-angle)
		yB=RotY(dimDelta(temp3D,0),0,-angle)
		xC=RotX(dimDelta(temp3D,0),dimDelta(temp3D,2),-angle)
		yC=RotY(dimDelta(temp3D,0),dimDelta(temp3D,2),-angle)
		xD=RotX(0,dimDelta(temp3D,2),-angle)
		yD=RotY(0,dimDelta(temp3D,2),-angle)

		//New limits
		variable New_xmin,New_xmax,New_ymin,New_ymax
		variable V1,V2
		V1=min(xA,xB)
		V2=min(xC,xD)
		New_xmin=min(V1,V2)
		V1=max(xA,xB)
		V2=max(xC,xD)
		New_xmax=max(V1,V2)
		V1=min(yA,yB)
		V2=min(yC,yD)
		New_ymin=min(V1,V2)
		V1=max(yA,yB)
		V2=max(yC,yD)
		New_ymax=max(V1,V2)
	
	// Now calculate how many points should be averaged in the basic unit rectangle
	// Save this in a small table (AvgTable) of number of y values to average and between which x values
	variable x_temp, y_temp,Nb_Avg
	Nb_avg=0
	Make/O /N=(Nb_avg,3) AvgTable
	y_temp=New_ymin
	do
		y_temp=trunc(y_temp/DimDelta(temp3D,2))*DimDelta(temp3D,2)
		AvgTable[Nb_avg,0]=y_temp
		//Nb of x points on this y line
		do
			if (y_temp>0)
				if (y_temp<yD)
					//First x : intersection AD et y_temp : x=xD/yD*y_temp
					AvgTable[Nb_avg,1]=trunc(xD/yD*y_temp/DimDelta(temp3D,0))*DimDelta(temp3D,0)
					else
					//First x : intersection DC et y_temp : x=xD+(y_temp-yD)*(xC-xD)/(yC-yD)
					AvgTable[Nb_avg,1]=trunc(xD+(y_temp-yD)*(xC-xD)/(yC-yD)/DimDelta(temp3D,0))*DimDelta(temp3D,0)
				endif	
				if (y_temp<yB)
					//Stop x : intersection AB et y_temp : x=xA+(y_temp-yA)*(xB-xA)/(yB-yA)
					AvgTable[Nb_avg,2]=trunc(xA+(y_temp-yA)*(xB-xA)/(yB-yA)/DimDelta(temp3D,0))*DimDelta(temp3D,0)
					else
					//Stop x : intersection BC et y_temp : x=xB+(y_temp-yB)*(xC-xB)/(yC-yB)
					AvgTable[Nb_avg,2]=trunc(xB+(y_temp-yB)*(xC-xB)/(yC-yB)/DimDelta(temp3D,0))*DimDelta(temp3D,0)
				endif	
			if (y_temp<0)  // means negative angle
				if (y_temp<yB)
					//First x : intersection BC et y_temp : x=xB+(y_temp-yB)*(xC-xB)/(yC-yB)
					AvgTable[Nb_avg,2]=trunc(xB+(y_temp-yB)*(xC-xB)/(yC-yB)/DimDelta(temp3D,0))*DimDelta(temp3D,0)
					else
					//First x : intersection AB et y_temp : x=xB/yB*y_temp
					AvgTable[Nb_avg,2]=trunc(xB/yB*y_temp/DimDelta(temp3D,0))*DimDelta(temp3D,0)
				endif	
				if (y_temp<yC)		
					//Stop x : intersection BC et y_temp : x=xB+(y_temp-yB)*(xC-xB)/(yC-yB)
					AvgTable[Nb_avg,2]=trunc(xB+(y_temp-yB)*(xC-xB)/(yC-yB)/DimDelta(temp3D,0))*DimDelta(temp3D,0)
					else
					//Stop x : intersection BC et y_temp : x=xB+(y_temp-yB)*(xC-xB)/(yC-yB)
					AvgTable[Nb_avg,2]=trunc(xB+(y_temp-yB)*(xC-xB)/(yC-yB)/DimDelta(temp3D,0))*DimDelta(temp3D,0)
				endif	
			endif
			
			endif
		while (x_temp<=New_xmax)
		y_temp+=DimDelta(temp3D,2) 
		Nb_avg+=1
	while (y_temp<=New_ymax)

end	


function	SquareAfterRotation(Image,angle)
wave Image
variable angle
// Calculates the rectangle obtained after rotation by angle
// Rescale Image with these new limits and an appropriate step

	//Old limits
	variable Old_xmin,Old_xmax,Old_ymin,Old_ymax
	Old_xmin=DimOffset(Image,0)
	Old_xmax=DimOffset(Image,0)+DimDelta(Image,0)*(DimSize(Image,0)-1)
	Old_ymin=DimOffset(Image,1)
	Old_ymax=DimOffset(Image,1)+DimDelta(Image,1)*(DimSize(Image,1)-1)

	//After rotation : ABCD rectangle
	variable xA,yA,xB,yB,xC,yC,xD,yD
	xA=RotX(Old_xmin,Old_ymin,angle)
	yA=RotY(Old_xmin,Old_ymin,angle)
	xB=RotX(Old_xmax,Old_ymin,angle)
	yB=RotY(Old_xmax,Old_ymin,angle)
	xC=RotX(Old_xmax,Old_ymax,angle)
	yC=RotY(Old_xmax,Old_ymax,angle)
	xD=RotX(Old_xmin,Old_ymax,angle)
	yD=RotY(Old_xmin,Old_ymax,angle)

	//New limits
	variable New_xmin,New_xmax,New_ymin,New_ymax
	variable V1,V2
	V1=min(xA,xB)
	V2=min(xC,xD)
	New_xmin=min(V1,V2)
	V1=max(xA,xB)
	V2=max(xC,xD)
	New_xmax=max(V1,V2)
	V1=min(yA,yB)
	V2=min(yC,yD)
	New_ymin=min(V1,V2)
	V1=max(yA,yB)
	V2=max(yC,yD)
	New_ymax=max(V1,V2)
	
	//Resize Image with dx and dy obtained after rotation
	Variable dX,dY	
	Variable NbX,NbY	
	dx=max(abs(DimDelta(Image,0)*cos(angle*pi/180)),abs(DimDelta(Image,1)*sin(angle*pi/180)))
	dy=max(abs(DimDelta(Image,0)*sin(angle*pi/180)),abs(DimDelta(image,1)*cos(angle*pi/180)))
	NbX=round((New_xmax-New_xmin)/dx+1)
	NbY=round((New_ymax-New_ymin)/dy+1)
	//print "NbX,Nby=",NbX,NbY
	
	//Ask user which deltax and deltay he wants
	prompt dx,"resolution for x ("+num2str(NbX)+"points)"
	prompt dy,"resolution for y ("+num2str(NbY)+" points)"
	DoPrompt "Rotate with",dx,dy
	if (v_flag==1)
		abort
	endif
	NbX=round((New_xmax-New_xmin)/dx+1)
	NbY=round((New_ymax-New_ymin)/dy+1)
	
	Redimension/N=(NbX,NbY)/D Image
	Image=NaN
	SetScale/P x New_xmin,dx,"", Image
	SetScale/P y New_ymin,dy,"", Image

end

function RotX(x,y,angle)
variable x,y,angle
//sens trigo
	//print x,y
	//return (cos(angle*pi/180)*(x-x0)/DimDelta(Image,0)-sin(angle*pi/180)*(y-y0)DimDelta(Image,1))*DimDelta(Image,0)+x0
	return cos(angle*pi/180)*x-sin(angle*pi/180)*y
end

function RotY(x,y,angle)
variable x,y,angle
//sens trigo
	return sin(angle*pi/180)*x+cos(angle*pi/180)*y
end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////            Utilities
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// DuplicateForUndo(name)
// Find_TopImageName()           Returns the name of the image in the top graph 
// Img_undo(ctrlname)

Function/S Find_TopImageName()
	string List=Wavelist("*",";" ,"DIMS:2,WIN:")
	string name=StrFromList(List, 0, ";")
	if (cmpstr(name,"")==0)
		abort "No appropiate wave in  DataFolder"
	endif

	return name
end

///

function DuplicateForUndo(name)
string name
	
	if (exists("Image_backup")==1)
		Duplicate/O Image_backup, Image_backup_backup
	endif
	Duplicate/O $name, Image_backup
	
	//if (cmpstr(name,"Image")==0)
		//Then we are in ImgProcess pannel
	//	nvar angle_image,angle_back,angle_back_back,angle_back_back_back
	//	angle_back_back_back=angle_back_back
	//	angle_back_back=angle_back
	//	angle_back=0
	//endif
end
///

function Img_undo(ctrlname):ButtonControl
	string ctrlname
	string name=Find_TopImageName()
	Duplicate/O Image_backup $name
	if (exists("Image_backup_backup")==1)
		Duplicate/O Image_backup_backup Image_backup
	endif
	if (cmpstr(name,"image")==1)
		//Then undo made from Pannel
		nvar angle_image,angle_back,angle_back_back,angle_back_back_back
		angle_image-=angle_back
		angle_back=angle_back_back
		angle_back_back=angle_back_back_back
	endif
end


////////////////////////////////////
function ReplaceNaNbyZero(image)
wave Image
    variable index_p,index_q
    index_p=0
    do
    index_q=0
    	do
    		if (image[index_p][index_q]==image[index_p][index_q])
    		else
         	image[index_p][index_q]=0
    		endif
    		index_q+=1
    	while (index_q<Dimsize(Image,1))	
    index_p+=1
    while(index_p<Dimsize(Image,0))
end

function AddDespiteNaN(image1,image2)
wave Image1,Image2
//Add the 2 images in wave somme. Avoid NaN points
	variable start_x,stop_x,delta_x,Nb_x
	variable start_y,stop_y,delta_y,Nb_y
	start_x=min(dimoffset(image1,0),dimoffset(image2,0))
	stop_x=max(dimoffset(image1,0)+dimDelta(image1,0)*(dimSize(image1,0)-1),dimoffset(image2,0)+dimDelta(image2,0)*(dimSize(image2,0)-1))
	delta_x=max(DimDelta(image1,0),DimDelta(image2,0))
	Nb_x=(stop_x-start_x)/delta_x+1
	start_y=min(dimoffset(image1,1),dimoffset(image2,1))
	stop_y=max(dimoffset(image1,1)+dimDelta(image1,1)*(dimSize(image1,1)-1),dimoffset(image2,1)+dimDelta(image2,1)*(dimSize(image2,1)-1))
	delta_y=max(DimDelta(image1,1),DimDelta(image2,1))
	Nb_y=(stop_y-start_y)/delta_y+1
	Make/O/N=(Nb_x,Nb_y) somme
	SetScale/P x start_x,delta_x, somme
	SetScale/P y start_y,delta_y, somme
	
    variable index_p,index_q
    variable x_value,p_img1,q_img1,y_value,p_img2,q_img2
    index_p=0
    do
    x_value=dimoffset(somme,0)+index_p*DimDelta(somme,0)
    p_img1=round((x_value-dimoffset(image1,0))/Dimdelta(image1,0))
    p_img2=round((x_value-dimoffset(image2,0))/Dimdelta(image2,0))
    index_q=0
    	do
    		 y_value=dimoffset(somme,1)+index_q*DimDelta(somme,1)
		 q_img1=round((y_value-dimoffset(image1,1))/Dimdelta(image1,1))
		 q_img2=round((y_value-dimoffset(image2,1))/Dimdelta(image2,1))
		 
    		if (image1[p_img1][q_img1]==image1[p_img1][q_img1])
	    		if (image2[p_img2][q_img2]==image2[p_img2][q_img2])
	    			somme[index_p][index_q]=(image1[p_img1][q_img1]+image2[p_img2][q_img2])/2
	    			else
	    			somme[index_p][index_q]=image1[p_img1][q_img1]
	    		endif	
    		else
    			if (image2[p_img2][q_img2]==image2[p_img2][q_img2])
    				somme[index_p][index_q]=image2[p_img2][q_img2]
    			else
	    			somme[index_p][index_q]=NaN	
	    		endif		
    		endif	
    		//print x_value,y_value,somme[index_p][index_q]
    		index_q+=1
    	while (index_q<Dimsize(somme,1))	
    index_p+=1
    while(index_p<Dimsize(somme,0))
end

////////////////////////////
/// Rotates two waves

function Ask_WaveRotation()
	string/G Xwave,Ywave
	string XwaveL,YwaveL
	variable theta
	XwaveL=Xwave
	YwaveL=Ywave

	string choix
	choix=WaveList("*",";","DIMS:1")
	prompt XwaveL,"Wave for X ", popup,choix
	prompt YWaveL,"Wave for Y ", popup,choix
	prompt theta,"Rotate by angle "
	DoPrompt "Convert..." XwaveL,YwaveL,theta

	Xwave=XwaveL
	Ywave=YwaveL
	print "LetsRotateXY("+num2str(theta)+","+Xwave+","+Ywave+")"
	LetsRotateXY(theta,$Xwave,$Ywave)
end

function LetsRotateXY(theta,x_data,y_data)
variable theta
wave x_data,y_data
wave x_int
//rewrite in x_data and y_data the rotated coordinate
Duplicate /O x_data x_int
theta=-theta*pi/180 // sens trigo
//print cos(theta),sin(theta)
x_int=cos(theta)*x_data-sin(theta)*y_data
y_data=sin(theta)*x_data+cos(theta)*y_data
x_data=x_int
end

////////////////////////// Second derivative (Maria)

function DoSecondDerivativeE()
	string name=Find_TopImageName()
	Second_derivative($name,1)
	Display;AppendImage result
	ModifyImage result ctab= {*,*,ColdWarm,1}
	DoWindow/T Graph6,"Second derivative : result"
end

function DoSecondDerivativek()
	string name=Find_TopImageName()
	Second_derivative($name,0)
	Display;AppendImage result
	ModifyImage result ctab= {*,*,ColdWarm,1}
	DoWindow/T Graph6,"Second derivative : result"
end

Function Second_derivative(Img,var)
wave Img //name of image
variable var //0 for k 1 for E

//duplicate/o /R=(-0.51,0.51)() lub w
duplicate/o /R=()() Img w

//smooth/DIM=0 5,w 
//smooth/DIM=1 5,w

duplicate/o w result


duplicate/o w ww
smooth/DIM=0 50,ww

differentiate/dim=0  ww /D=dif_a1
differentiate/dim=0  dif_a1 /D=dif_a2

duplicate/o w ww
smooth/DIM=1 20,ww
differentiate/dim=1  ww /D=dif_b1
differentiate/dim=1  dif_b1 /D=dif_b2



//result=dif_a2+dif_b2
if(var==0)
result=dif_a2
elseif(var==1)
result=dif_b2
endif

variable i,j
for(i=0;i<dimsize(result,0);i+=1)
	for(j=0;j<dimsize(result,1);j+=1)
		if(result[i][j]>0)
		result[i][j]=0
		endif
	endfor
endfor
end

function DoTranspose()
	string name=Find_TopImageName()
	MatrixTranspose $name
end

/////////////////////////////////
function remove_spike(Wav)
wave Wav
variable avg, index_p,index_q, ecart
       index_p=1
       do
       index_q=1
       do
          avg=(Wav[index_p-1][index_q-1]+Wav[index_p-1][index_q+1]+Wav[index_p+1][index_q-1]+Wav[index_p+1][index_q+1])/4
      		ecart=max(Wav[index_p-1][index_q]-Wav[index_p+1][index_q],Wav[index_p][index_q-1]-Wav[index_p][index_q+1])
      		if ((wav[index_p][index_q]-avg)>2*ecart) 
      		 Wav[index_p][index_q]=avg 
      		endif
          index_q+=1
        while (index_q<(dimsize(wav,1)-1))
          index_p+=1
        while (index_p<(dimsize(wav,0)-1))
              
end

/////////////////////////////////////////////////////////////////////////
function MyConvolution(name,width)
string name
variable width

variable Nb,stop,i,j,start
width/=1.66 // sigma = full width at half maximum divided by 1.66
Duplicate/O $name original,convoluted
Nb=round(3*width/DimDelta(original,0)+1)
print Nb,"points in the gaussian"
Make/O/N=(Nb) Gaussian
SetScale/P x 0,DimDelta(original,0),"", Gaussian
Gaussian=exp(-(x/width)^2)

stop=Dimoffset(original,0)+DimDelta(original,0)*(DimSize(original,0)-1)
convoluted=0
start=round(3*width/DimDelta(original,0))
i=start
do
	j=-start
	do
		convoluted[i]+=original[i+j]*Gaussian[abs(j)]
		j+=1
		//print j
	while(j<=start)
	i+=1
while(i<Dimsize(original,0)-start)

// normalisation
variable nor=sum(original)/sum(convoluted)
convoluted*=nor

end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////// Reformat 3D wave

function Format_3Dwave(ctrlname):ButtonControl
string ctrlname
//SetDataFolder root:ImgProcess
string/G methode="linear"
variable/G Bgd=0
variable/G Kx_start,Kx_stop, Ky_start,Ky_stop,Kx_step,Ky_step,NbKx,NbKy
variable/G Kz_start,Kz_stop, Kz_step,NbKz
	
	string name=Find_TopImageName()
	Kx_start=round(Dimoffset($name,0)*1000)/1000
	Kx_stop=round((Kx_start+DimDelta($name,0)*(DimSize($name,0)-1))*1000)/1000
	Kx_step=round(DimDelta($name,0)*100000)/100000
	
	Ky_start=round(Dimoffset($name,1)*1000)/1000
	Ky_stop=round((Ky_start+DimDelta($name,1)*(DimSize($name,1)-1))*1000)/1000
	Ky_step=round(DimDelta($name,1)*100000)/100000
	
	Kz_start=round(Dimoffset($name,2)*1000)/1000
	Kz_stop=round((Kz_start+DimDelta($name,2)*(DimSize($name,2)-1))*1000)/1000
	Kz_step=round(DimDelta($name,2)*100000)/100000
	
	NbKx=round((Kx_stop-Kx_start)/Kx_step)+1
	NbKy=round((Ky_stop-Ky_start)/Ky_step)+1
	NbKz=round((Kz_stop-Kz_start)/Kz_step)+1

	DoWindow/F Format_3Dwave
       if (V_flag==0)
            NewPanel /W=(700,10,1000,180)
            DoWindow/C Format_3Dwave
            DoWindow/T Format_3Dwave "Format 3D wave"
            //ModifyPanel cbRGB=(65280,32768,32768)
            SetVariable Kxstart,pos={20,10},size={120,20},title=" kx start :  ",proc=RefreshStep,limits={-Inf,Inf,Kx_step},value=Kx_start
            SetVariable Kxstop,pos={20,10},size={120,20},title=" kx start :  ",proc=RefreshStep,limits={-Inf,Inf,Kx_step},value=Kx_start
            SetVariable Kxstep,pos={20,10},size={120,20},title=" kx step :  ",proc=RefreshStep,limits={-Inf,Inf,Kx_step},value=Kx_step
		SetVariable NbKxbox,pos={150,10},size={120,15},title="Nb points :",value=NbKx,proc=RefreshNbPnts
		SetVariable Kystep,pos={20,40},size={120,20},title=" ky step :  ",proc=RefreshStep,limits={-Inf,Inf,Ky_step},value=Ky_step
		SetVariable NbKybox,pos={150,40},size={120,15},title="Nb points :",value=NbKy,proc=RefreshNbPnts
		SetVariable Kzstep,pos={20,40},size={120,20},title=" kz step :  ",proc=RefreshStep,limits={-Inf,Inf,Ky_step},value=Ky_step
		SetVariable NbKzbox,pos={150,40},size={120,15},title="Nb points :",value=NbKy,proc=RefreshNbPnts
		
		Button DoRefresh,pos={18,129},size={65,30},proc= ImgPannel_interpolate,title="Refresh"
		Button DoInterpolate,pos={158,129},size={65,30},proc=DoInterpolate,title="Interpolate"
       endif
end

///////////////////////////////////////////////////////////////////////:
Macro Center_disp()
variable cursor_center
string name
cursor_center=(hcsr(A)+hcsr(B))/2

// Just shift by offset
//name=StringByKey("TNAME",CsrInfo(A))
//ModifyGraph offset($name)={-Cursor_center,0}
//name=StringByKey("TNAME",CsrInfo(B))
//ModifyGraph offset($name)={-Cursor_center,0}

// Shift for real 
// Warning : must be in the good data folder
name=CsrXwave(A)
$name-=cursor_center
name=CsrXwave(B)
$name-=cursor_center

end

Function CenterMass()
//wave wave1
string name
variable Xmin,Xmax


prompt name, "Name of wave to load",popup,WaveList("*",";","DIMS:1")
prompt Xmin,"Xmin"
prompt Xmax,"Xmax"
DoPrompt "Loading...",name,Xmin,Xmax

print "DoCenterMass(\""+name+"\","+num2str(Xmin)+","+num2str(Xmax)+")"
DoCenterMass(name,Xmin,Xmax)
end

function DoCenterMass(name,Xmin,Xmax)
string name
variable Xmin,Xmax
variable XHalf
variable FullArea,HalfArea
variable i	
	FullArea=area($name,Xmin,Xmax)
	i=1
	do
		XHalf=Xmin+i*DimDelta($name,0)
		HalfArea=area($name,XHalf,Xmax)
		i+=1
	while (HalfArea>FullArea/2)
	XHalf=Xhalf+DimDelta($name,0)*(FullArea/2-area($name,XHalf,Xmax))/(area($name,XHalf+DimDelta($name,0),Xmax)-area($name,XHalf,Xmax))
	print "Center mass=",XHalf
	return XHalf
end
/////
Function HWHM()
//wave wave1
string name
variable Xmin,Xmax

prompt name, "Name of wave to load",popup,WaveList("*",";","DIMS:1")
prompt Xmin,"Xmin"
prompt Xmax,"Xmax"
DoPrompt "Loading...",name,Xmin,Xmax

print "DoHWHM(\""+name+"\","+num2str(Xmin)+","+num2str(Xmax)+")"
DoHWHM(name,Xmin,Xmax)
end

function DoHWHM(name,Xmin,Xmax)
string name
variable Xmin,Xmax
variable XHalf_min,XHalf_max,index_max,MiLargeur
variable i	
	Duplicate/O $name temp
	Wavestats/Q temp
	index_max=x2pnt(temp,V_maxloc)
	i=1
	do
		XHalf_min=index_max-i*0.05// It does interpolate so it's nicer
		i+=1
	while (temp[XHalf_min]>V_max/2)
	i=1
	do
		XHalf_max=index_max+i*0.05
		i+=1
	while (temp[XHalf_max]>V_max/2)
	
	MiLargeur=(Xhalf_max-XHalf_min)*DimDelta(temp,0)/2
	print "HWHM=",MiLargeur
	Killwaves temp
	return MiLargeur
end
////////////////////////////////////////////////////////////////////////////////

function MakeFermiForDiv(Temp,res)
variable Temp,res  // Temp in K, res in eV
variable Teff
//SetDataFolder root:
Make/O/N=128 FermiForDiv
SetScale/I x -0.3,0.2, FermiForDiv
Teff=0.8617e-4*Temp+res/4 // Effective Temp in eV
FermiForDiv=1/(1+exp(x/Teff))
end

Macro DivideByTemp(NameFolder)
string NameFolder
// Divide by Fermi level at temperature taken from Nor_other_angle
// Works in a folder with tmp_3D wave and Nor_other_angle wave
//Builds a new folder with the necessary waves
SetDataFolder "root:"
SetDataFolder $NameFolder
variable res=0.01  //  res in eV
//variable Teff,i
//wave tmp_3D,Nor_other_angle

	Duplicate/O tmp_3D tmp_3D_div
	//Teff=0.8617e-4*Nor_other_angle[i]+res/4 // Effective Temp in eV
	//FermiForDiv=1/(1+exp(x/Teff))
	// tmp_3D_div= tmp_3D / FermiForDiv
	 tmp_3D_div()()[]= tmp_3D(x)(y)[r]*(1+exp(y/(0.8617e-4*Nor_other_angle[r]+res/4 )))

//string NameFolder=GetDataFolder(1)
string NewFolder
SetDataFolder "root:"
variable i=1
do
	NewFolder=NameFolder+"_div"+num2str(i)
	i+=1
while (DataFolderExists(NewFolder))

DuplicateDataFolder $NameFolder $NewFolder
SetDataFolder $NewFolder
Killwaves tmp_3D
Rename tmp_3D_div tmp_3D
 execute "Load3DImage(\""+NewFolder+"\")"
end

/////

Function AddDisp()
//wave wave1
//string name
variable z_start,z_end

//prompt name, "Name of output wave"
prompt z_start,"theta_start"
prompt z_end,"theta_stop"
DoPrompt "Add Disp from tmp_3D...",z_start,z_end
DoAddDisp(tmp_3D,z_start,z_end)
wave ImageAdd
Display;AppendImage ImageAdd
ModifyImage ImageAdd ctab= {*,*,PlanetEarth,1}
end

function DoAddDisp(Image,z_start,z_end)
wave Image
variable z_start,z_end
// Additionne dans une image 2D, les tranches d'une image 3D entre z_start et z_end
variable i,z_cur,r_cur
Make/O /N=(DimSize(Image,0),DimSize(Image,1)) ImageAdd
SetScale/P x, Dimoffset(Image,0),DimDelta(Image,0), ImageAdd
SetScale/P y, Dimoffset(Image,1),DimDelta(Image,1), ImageAdd
ImageAdd=0
	z_cur=z_start
	do
		r_cur=round((z_cur-Dimoffset(Image,2))/DimDelta(Image,2))
		ImageAdd+=Image[p][q][r_cur]
		z_cur+=DimDelta(Image,2)
	while (z_cur<z_end)    
	print "Result is in ImageAdd"
end