#pragma rtGlobals=1		// Use modern global access method.
#include "KBColorizeTraces"   // from WaveMatrix/Graphing

#include "OpenWien2K" // To set energy limits :  Load_Agr_File
#include "Wien2K_klist" 
#include "Wien2K_2Dplots" 


menu "Wien2K"
	"Spaghetti plot with weights",MakeWeightBandPlot()
	"Extract dispersion from spaghetti plot ", ExtractSpaghetti()
	"Extract dispersion from multiple bands ", ExtractDispFromManyBands()
	"Add k scale from wave",MakeScale()
	"Add k scale from periodicity",MakePeriodicScale()
	"Extract 2 bands with max weight from spaghetti plot ", MenuExtractMaxWeight()
	"-"
	"Unfold one band structure [1D]",Unfold()
	"Add new periodicity [1D] ", AddBands1D()
	//"Calculate unfolded weight",UnfoldedWeight(Folder_unfolded,Folder_original)
	"-"  
	/// in procedure Wien2k_2Dplots
	"View 2D image dispersion and contour ",ExtractDispersion()
	"Integrate weight on dipsersion plot",IntegrateBandWeight()
	"Make Kx-Ky image ",MakeKxKyImage()
	"Make Kz image ",MakeKzImage()
	"Extract dispersion at constant photon energy",Disp_variableKz()
	"Renormalize Band",RenormalizeBand()
	"Extract points from one contour",SeparateContour()
	//"Extract energy contour [2D] ",ExtractEnergyContour()
	"-"
	"Create klist path", CreateKlistPath_window()   // in procedure Wien2k_Klist
	// puis SaveAsKlist(filename)
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////  Open File
	/////  Function  BeforeFileOpenHook 
	/////  Function Load_Agr_File(refnum, filename, symPath)   
			// Called by hook, load the bands in one folder and make plot.
			// Choose energies between which the files should be loaded in this procedure
	/////  function MakeWeightBandPlot()  // Has to be in the folder where data are loaded. Plot the data.
	/////  function ReadKscale(refnum, filename, symPath)   

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////  Unfolding procedures

// Procedures to build klist and 2D images (still in progress)
	//			Look for  : CreateKlistPath() to create waves with appropriate kx, ky, kz
	// 			Save them in a file with : "SaveAsKlist"

///////////////////////////:      Loading files

////
function MakeWeightBandPlot()
string folder=GetDataFolder(1)
string name0,name1,name2
variable indice
indice=1

// Look for weight_min and weight_max 
variable weight_min=0,weight_max=0
do
	name1="weight"+num2str(indice)
	weight_max=max(wavemax($name1),weight_max)
	weight_min=min(wavemin($name1),weight_min)
	indice+=1
	name1="weight"+num2str(indice)
while  (exists(name1)==1)
	
	indice=1
	Display band1
	ModifyGraph mode(band1)=3,marker(band1)=19,zmrkSize(band1)={weight1,weight_min,weight_max,0,5}
	//ModifyGraph mode(band1)=3,marker(band1)=19,zmrkSize(band1)={weight1,*,*,0,5}
	ModifyGraph zero(left)=1
	ModifyGraph fSize(bottom)=16
	ModifyGraph fSize(left)=16
	indice=2
	name1="band"+num2str(indice)
	do
		name1="band"+num2str(indice)
		name2="weight"+num2str(indice)
		AppendToGraph $name1
		ModifyGraph mode($name1)=3,marker($name1)=19,zmrkSize($name1)={$name2,weight_min,weight_max,0,5}
		indice+=1
		name1="band"+num2str(indice)
	while (exists(name1)==1)
	
string WindowName=WinName(0,3)
name0= folder[5,strlen(folder)-2]
DoWindow/T $WindowName,name0
if (exists("kvert")==1 && exists("kscale0")==1)
	AppendToGraph kvert vs kscale0
	ModifyGraph rgb(kvert)=(0,0,0)
endif
name1="\\Z16"+name0
TextBox/C/N=text0/F=0/A=MC name1
end

///////////////////////////////////////////:
function ReadKscale(refnum, filename, symPath)
String symPath, filename
variable refnum
		
	variable a0=0.52918
	Make/O/N=1 spaghetti_k
	
	string StringToFind,String_Read
	StringToFind="@ xaxis  tick major   0"
       Open/R /P=$symPath refnum filename
        do
	        FReadline refnum, String_Read
             if (stringmatch(String_Read, StringToFind+"*") )
                        break
                endif
        while (1)
        
       Spaghetti_k[0]=str2num(String_Read[23,30])/a0
       
      variable indice=1
	do
		Redimension/N=(indice+1) spaghetti_k
		FReadline refnum, String_Read
		FReadline refnum, String_Read
	       Spaghetti_k[indice]=str2num(String_Read[24,33])/a0
		indice+=1
	while (cmpstr(String_Read[0,20],"@ xaxis  tick major")==1)

        close refnum
end 

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////      Unfolding procedures

proc ExtractSpaghetti(A,B,band_start,band_stop,name)
//Extract from band1, band2... the dispersion between A and B,
//A should be the k position of Gamma in a spaghetti and B the end point
// band_start is the index of first band to be considered, band_stop of last band
// Symmetrize it and save it in name1, name2...
variable A,B,band_start,band_stop
string name

variable indice=band_start
if (indice==0)
   indice=1
endif   
if (band_stop==0)
   band_stop=1000
endif   

variable Nbpoints=128
string name1,name2,name3

variable offsetX=abs(A-B)
Make/O/N=(Nbpoints) temp
Setscale/I x -offsetX,offsetX, temp
name1="band"+num2str(indice)

NewDataFolder/O $name
name3=":"+name+":"

do
	duplicate/O $name1 band
	if (A<B)
		temp(0,offsetX)=band(x+A)
		temp(-offsetX,-0.0001)=temp(-x)
	else
		temp(-offsetX,0)=band(A+x)
		temp(0.0001,offsetX)=temp(-x)
	endif
	name2=name+"_"+num2str(indice)
	duplicate/O temp,$name2
	MoveWave $name2, $name3
	indice+=1
	name1="band"+num2str(indice)
while (exists(name1)==1 && indice<=band_stop)
//while (indice<=band_stop)

Killwaves band,temp

end

/////////////

Proc ExtractDispFromManyBands(p_wave,band_index_wave,BandNameRoot,OutputWaveName)
String p_wave,band_index_wave
string BandNameRoot,OutputWaveName
// In the current folder with many waves BandNameRoot1, BandNameroot2....
// Make a new dispersion with band_indexwave between position indicated in p_wave
string name,name1
variable index, indice_start,indice_stop,indice_kz

//print "ExtractDispFromManyBands("+p_wave+","+band_index_wave+","+BandNameRoot+","+OutputWaveName+")"
name=BandNameRoot+"1"
Duplicate/O $name Newband

indice_start=0
index=0
	do
		indice_stop=$p_wave[index]
		name=BandNameRoot+num2str($band_index_wave[index])
		duplicate/O $name AuxBand
		Newband[indice_start,indice_stop]=AuxBand[p]
		indice_start=indice_stop+1
		index+=1
	while (index<DimSize($p_wave,0))

Duplicate/O Newband $OutputWaveName
Killwaves NewBand,AuxBand

end
//////////////
function MakeScale()
string name
prompt name,"Name of wave"
DoPrompt "wave",name

if (v_flag==0)
	MakeScale2(name)
endif
end

function MakeScale2(name)
string name
	variable NbPnts,indice
	Duplicate/O $name,temp
	NbPnts=DimSize(temp,0)
	indice=0
	Make/O/N=(3*NbPnts) kscale,kvert
	do
		kscale[3*indice]=temp[indice]
		kscale[3*indice+1]=temp[indice]
		kscale[3*indice+2]=NaN		
		kvert[3*indice]=inf
		kvert[3*indice+1]=-inf
		kvert[3*indice+2]=NaN
		indice+=1
	while(indice<Nbpnts)

	indice=0
	do
		name="kscale"+num2str(indice)
		indice+=1
	while(exists(name)==1)
	Duplicate/O kscale $name	
	AppendToGraph kvert vs $name
	ModifyGraph rgb(kvert)=(0,0,0)
	Killwaves kscale,temp
end

Proc MakePeriodicScale(k_range,q)
variable k_range,q
//Make k_scale from -k_range/2 to k_ra,ge/2 with ticks every q

	variable indice
	string name
	//variable NbTicks=ceil(k_range/q)
	variable NbTicks=round(k_range/q)+1
	Make/O/N=(3*NbTicks) kscale
	
	if (exists("kvert")==1)
		if (DimSize(kvert,0)<3*NbTicks)
			Redimension/N=(3*NbTicks) kvert
		endif
	else
		Make/O/N=(3*NbTicks) kvert
	endif	
	indice=0
	do
		kscale[6*indice]=q/2+indice*q
		kscale[6*indice+1]=q/2+indice*q
		kscale[6*indice+2]=NaN		
		kscale[6*indice+3]=-kscale[6*indice]
		kscale[6*indice+4]=-kscale[6*indice+1]
		kscale[6*indice+5]=NaN		
		kvert[6*indice]=inf
		kvert[6*indice+1]=-inf
		kvert[6*indice+2]=NaN
		kvert[6*indice+3]=inf
		kvert[6*indice+4]=-inf
		kvert[6*indice+5]=NaN

		indice+=1
	while(q/2+indice*q<=k_range)

	indice=0
	do
		name="kscale"+num2str(indice)
		indice+=1
	while(exists(name)==1)
	Duplicate/O kscale $name	
	AppendToGraph kvert vs $name
	Killwaves kscale
end

//////////////////////////////////////////////////////////////////////////////////

//////////////
function Unfold()
	
	string folder_unfolded=GetDataFolder(0),folder_original=""
	string/G NameRoot
	string NameRootL
	NameRootL=NameRoot
	prompt folder_unfolded, "Folder with bands to unfold : "
	prompt NameRootL, "Basis for band names : "
	prompt folder_original, "Folder with original bands (for weights) :"
	DoPrompt "Enter folder name" folder_unfolded,NameRootL,folder_original

	if (v_flag==0)
	NameRoot=NameRootL
	string name
	SetDataFolder "root:"	
	if (DataFolderExists(folder_unfolded)==1)
		SetDataFolder folder_unfolded
		variable/G q_SBZ,q_UBZ
		name=NameRoot+"1"
		if (exists(name)==1)
			q_SBZ=-DimOffset($name,0)*2
		endif
		variable q_SBZ_L=q_SBZ
		variable q_UBZ_L=q_UBZ
		prompt q_SBZ_L, "Supercell periodicity (2pi/a) : "
		prompt q_UBZ_L, "Unfolded BZ periodicity (2pi/a) : "
		DoPrompt "Enter folder name" q_SBZ_L,q_UBZ_L
		if (v_flag==0)
			q_SBZ=q_SBZ_L
			q_UBZ=q_UBZ_L
			ExpandBands1D(q_SBZ,q_UBZ,NameRoot)
			name=folder_unfolded
			variable indice
			DoWindow/F $name
       		if (v_flag==0) //i.e window does not exist : create a new one
				PlotBands1D(folder_unfolded,NameRoot)
				// else : assumes the graph is already correct
 			endif
 			if (cmpstr(folder_original,"")!=0)
				execute "UnfoldedWeight("+Folder_unfolded+","+Folder_original+")"
			endif	
			AddWeightToPlot()
		endif	
	else
		abort "No data folder of that name exists"
	endif	
	endif
end	
	
Function ExpandBands1D(q_SBZ,q_UBZ,NameRoot)
variable q_SBZ,q_UBZ // 1D periodicity of the BZ supercell (SBZ) and the unfolded BZ (UBZ)
string NameRoot

// Make new bands with UBZ periodicity (with all bands in the folder called band1, band2....
string name
variable delta,Nbpnts,start,stop,indice
variable indice_SBZ_zero,indice_UBZ_zero,indice_SBZ,indice_UBZ,n
	
	indice=1
	name=NameRoot+num2str(indice)
	delta=DimDelta($name,0)
	indice_SBZ=round(q_SBZ/delta/2)
	indice_UBZ=round(q_UBZ/delta/2)
	NbPnts=round(q_UBZ/delta)+1
	indice_SBZ_zero=x2pnt($name,0)  // not necessarily the middle (but will not work if not symmetric)
	Make/O/N=(NbPnts) band_UBZ
	SetScale/P x -q_UBZ/2,delta,"", band_UBZ
		
	do
		Duplicate/O $name band_SBZ
		band_UBZ=0
		// First SBZ 
		band_UBZ[indice_UBZ,indice_UBZ+indice_SBZ]=band_SBZ[p-indice_UBZ+indice_SBZ_zero]
		// Next SBZ
		n=0
		do
			n+=1
			start=indice_UBZ+indice_SBZ+(n-1)*indice_SBZ*2
			stop=min(start+indice_SBZ*2,2*indice_UBZ)
			band_UBZ[start,stop]=band_SBZ[p -start-indice_SBZ+ indice_SBZ_zero]
		while (stop<indice_UBZ*2)
		//Symmetrize to negative x
		band_UBZ[0,indice_UBZ-1]=band_UBZ[2*indice_UBZ-p]
		name=NameRoot+"_UBZ"+num2str(indice)
		Duplicate/O band_UBZ $name
		indice+=1
		name=NameRoot+num2str(indice)
	while(exists(name)==1)	
	Killwaves band_UBZ,band_SBZ
end

Macro UnfoldedWeight(Folder_unfolded,Folder_original)
string Folder_unfolded,Folder_original
// Calculate weights of unfolded bands compared to original bands
// = somme de 1/( band_UBZ(x)-band_BZ(x) ) ^ 2

string name
variable indiceOriginal,indiceUnfolded
variable eps,start,delta
eps=0.05

SetDataFolder "root:"
SetDataFolder Folder_original
indiceUnfolded=1
name="root:"+Folder_unfolded+":band1_UBZ"
do
	Duplicate/O $name band_UBZ,weight_UBZ
	weight_UBZ=0
	indiceOriginal=1
	name="band1"
	start=DimOffset($name,0)
	delta=DimDelta($name,0)
	do
		Duplicate/O $name band
		//weight_UBZ[]+=1/(abs(band_UBZ[p]-band[x2pnt(band,p*delta+start)])+eps)
		//weight_UBZ[]=abs(band_UBZ[p]-band[x2pnt(band,p*delta+start)])
		weight_UBZ+=1/(abs(band_UBZ(x)-band(x))+eps)
		indiceOriginal+=1
		name="band"+num2str(indiceOriginal)
	while (exists(name)==1)
	name="Weight_UBZ"+num2str(indiceUnfolded)
	Duplicate/O weight_UBZ $name
	indiceUnfolded+=1
	name="root:"+Folder_unfolded+":band"+num2str(indiceUnfolded)+"_UBZ"
while (exists(name)==1)
Killwaves band,band_UBZ,weight_UBZ
end

function AddWeightToPlot()
end

/////////////////

Function AddBands1D()

// Make new bands corresponding to k+q

	variable/G q
	variable qL
	qL=q
	prompt qL, "New periodicity : "
	string/G NameRoot
	string NameRootL
	NameRootL=NameRoot
	prompt NameRootL, "Basis for bands names : "
	DoPrompt "Enter value" qL,NameRootL
	if (v_flag==0)
	q=qL
	NameRoot=NameRootL
	
	string name
	variable indice_band=1
	name=NameRoot+"1"
	do
	// Works on 2 bands named band and band_folded
	Duplicate/O $name, band, band_folded
	variable q_BZ
	q_BZ=DimDelta(band,0)*(DimSize(band,0)-1)//assumes dispersion given between -q_BZ/2 and q_BZ/2, but could be changed here
	variable indice,indice_q,indice_qBZ,indice_stop
	indice_stop=DimSize(band,0)-1
	indice_q=round(q/DimDelta(band,0))
	indice_qBZ=round(q_BZ/DimDelta(band,0))
	
	indice=0
	if (indice_q>0)
		do
			band_folded[0,indice_q]=band[p-indice_q+indice_qBZ]
			band_folded[indice_q+1,indice_stop]=band[p-indice_q]
			indice+=1
		while(indice<=indice_stop)
	else
		do
			band_folded[0,indice_stop+indice_q]=band[p-indice_q]
			band_folded[indice_stop+indice_q+1,indice_stop]=band[p-indice_q-indice_qBZ]
			indice+=1
		while(indice<=indice_stop)
	endif	
	
	//Copy and delete bands
	name=NameRoot+"_q"+num2str(q)+"_"+num2str(indice_band)
	Duplicate/O band_folded $name
	indice_band+=1
	name=NameRoot+num2str(indice_band)
	while(exists(name)==1)
	Killwaves band,band_folded
	
	//PlotAfterAddBands1D(q_BZ,q)
	endif
end

///////////////

function PlotBands1D(folder_unfolded,NameRoot)
string folder_unfolded,NameRoot
nvar q_SBZ,q_UBZ
string name=folder_unfolded
	
	Display/W=(400,10,850,350)
	DoWindow/C $name
	DoWindow/T $name name
	
	variable indice=1
	name=NameRoot+"_UBZ1"
	do
		AppendToGraph $name
		ModifyGraph rgb($name)=(0,12800,52224)
		indice+=1
		name=NameRoot+"_UBZ"+num2str(indice)
	while (exists(name)==1)
	
	indice=1
	name=NameRoot+"1"
	do
		AppendToGraph $name
		indice+=1
		name=NameRoot+num2str(indice)
	while (exists(name)==1)
	
	ModifyGraph zero(left)=1
	ModifyGraph fSize=16
	
	execute "MakePeriodicScale("+num2str(q_UBZ)+","+num2str(q_SBZ)+")"
	execute "MakePeriodicScale("+num2str(q_UBZ)+","+num2str(q_UBZ)+")"
	ModifyGraph rgb(kvert#1)=(0,15872,65280)
end	

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Proc MenuExtractMaxweight(name)
string name
Extract_Maxweight(name)
end

function Extract_Maxweight(name)
string name  // output waves will be name_1 and name_2
			// They contain the bands with maximum weights among the NbBandes (to be entered below)

Duplicate/O band1 temp1,temp2,temp_max1,temp_max2
variable i,Nbpnts,NbBandes


Nbpnts=dimsize(band1,0)
Nbbandes=11
i=0
do
	WeightMax(i,NbBandes)  // returns the bands with highest weight in temp_max1 and temp_max2
	temp1[i]=temp_max1[i]
	temp2[i]=temp_max2[i]
	i+=1
while (i<Nbpnts)

FindContinuousBand(temp1,temp2)
 
string name1,name2
name1=name+"_1"
name2=name+"_2"
Duplicate/O temp1 $name1
Duplicate/O temp2 $name2
Killwaves temp1,temp2,temp_max1,temp_max2,weight_temp

end

//

function Weightmax(i,NbBandes)
variable i,NbBandes

variable indice_bande,max1,max2,band_max1,band_max2
wave weight1,weight2
string name
// initialisation
if (weight1[i]>weight2[i])
	max1=weight1[i]
	max2=weight2[i]
	band_max1=1
	band_max2=2
else
	max1=weight2[i]
	max2=weight1[i]
	band_max1=2
	band_max2=1
endif	

//Look for max in NbBandes
indice_bande=3
do
	name="weight"+num2str(indice_bande)
	Duplicate/O $name weight_temp
	if (weight_temp[i]>max1)
		max2=max1
		band_max2=band_max1
		max1=weight_temp[i]
		band_max1=indice_bande
	else
		if (weight_temp[i]>max2)
			max2=weight_temp[i]
			band_max2=indice_bande
		endif
	endif
	//print "indice_bande,weight_temp[i],max1,max2=",indice_bande,weight_temp[i],max1,max2
	indice_bande+=1
while (indice_bande<=NbBandes)
//print "band_max1,band_max2=",band_max1,band_max2

// Copy max values in temp1 and temp2
name="band"+num2str(band_max1)
Duplicate/O $name temp_max1
name="band"+num2str(band_max2)
Duplicate/O $name temp_max2

end

////
function FindContinuousBand(bandC1,bandC2)
wave bandC1,bandC2
Duplicate/O bandC1 tempC1
Duplicate/O bandC2 tempC2
variable NbPnts=Dimsize(bandC1,0)
variable i=0
do
	if ((abs(bandC1[i+1]-tempC1[i])>abs(bandC2[i+1]-tempC1[i]))&&(abs(bandC2[i+1]-tempC2[i])>abs(bandC1[i+1]-tempC2[i])))
		tempC1[i+1]=bandC2[i+1]
		tempC2[i+1]=bandC1[i+1]
	else	
		tempC1[i+1]=bandC1[i+1]
		tempC2[i+1]=bandC2[i+1]
	endif
	i+=1
while (i<NbPnts)
Duplicate/O tempC1 bandC1
Duplicate/O tempC2 bandC2
Killwaves tempC1,tempC2
end


Function RenormalizeBand()
// Work on bands with name "name_In_L"+#+"name_In_ext_L" in the current folder
// The names are prompted, as well as output names

// Shift and Renormalize all these bands

// Possibly symmetrize the bands

	string/G name_In, name_In_ext,name_Out
	string name_In_L, name_In_ext_L,name_Out_L
	
//	name_In="KzBand_"	
//	name_in_ext="_ph"
//	 name_Out="Renor"
		
	name_In_L=name_In
	name_In_ext_L=name_In_ext
	name_Out_L=name_Out
	
	variable/G indice_start,indice_stop
	variable indice_start_L,indice_stop_L
	indice_start_L=indice_start
	indice_stop_L=indice_stop
	
	prompt name_In_L, "Prefix for band name : "
	prompt name_In_ext_L, "Suffix for band name : "
	prompt name_out_L, "Name for output waves : "
	prompt indice_start_L,"Number of first wave to proceed :"
	prompt indice_stop_L,"Number of last wave to proceed :"
	DoPrompt "Enter name of waves (in selected folder : \" PrefixNumberSuffix\") " name_In_L, name_In_ext_L,name_Out_L,indice_start_L,indice_stop_L
	
	if (v_flag==0)
		name_In=name_In_L
		name_In_ext=name_In_ext_L
		name_Out=name_Out_L
		indice_start=indice_start_L
		indice_stop=indice_stop_L

		variable/G shift_energy, nor_energy,shift_k,nor_k,side
		variable shift_energy_L,nor_energy_L,shift_k_L,nor_k_L,side_L
		//shift_k=1.414
		//nor_k=0.785
		if (nor_k==0)
			nor_k=1 //default value
		endif
		shift_energy_L=shift_energy
		nor_energy_L=nor_energy
		shift_k_L=shift_k
		nor_k_L=nor_k
		side_L=side
//		variable k_start,k_stop
//			string name
//			name=name_In+"1"+Name_In_ext
//			k_start=DimOffset($name,0)
//			k_stop=DimOffset($name,0)+DimDelta($name,0)*(DimSize($name,0)-1)
					
		prompt shift_energy_L, "energy shift (eV) :"
		prompt nor_energy_L, "energy normalization :"
		prompt shift_k_L, "k shift :"
		prompt nor_k_L, "k normalization :"
		prompt side_L, "Symmetrize with respect to first point (1) or last point (2). Otherwise 0."
		DoPrompt "Enter parameters for renormalization " shift_energy_L,nor_energy_L,shift_k_L,nor_k_L,side_L


		if (v_flag==0)
		shift_energy=shift_energy_L
		nor_energy=nor_energy_L
		shift_k=shift_k_L
		nor_k=nor_k_L
		side=side_L
		
		variable indice=indice_start
		string name1,name2
		  do
			name1=name_In+num2str(indice)+Name_In_ext
			Duplicate/O $name1 temp
			temp+=shift_energy
			temp/=nor_energy
			SetScale/I x, (DimOffset(temp,0)/nor_k-shift_k),((DimOffset(temp,0)+DimDelta(temp,0)*(DimSize(temp,0)-1))/nor_k-shift_k),temp
			name2=name_Out+num2str(indice)
			Duplicate/O temp $name2
			indice+=1
		  while (indice<=indice_stop)	

		//Now all bands have the same k_scale than original waves
		//Symmetrize to get the desired k range
		
		if (side>0)
		indice=indice_start
		variable last,OldN
		 do
			name2=name_Out+num2str(indice)
			OldN=Dimsize($name2,0)
			if (side==1) 
				// Add a negative side
				last=DimOffset($name2,0)+(DimSize($name2,0)-1)*DimDelta($name2,0)
				SetScale/P x -last,DimDelta($name2,0),$name2
			endif	
			Redimension/N=(OldN*2-1) $name2
			Duplicate/O $name2 temp
			if (side==1)
				temp[OldN-1,Dimsize($name2,0)]=temp[p-OldN+1]
				temp[0,OldN-2]=temp[DimSize($name2,0)-1-p]
			else
				temp[OldN-1,Dimsize($name2,0)-1]=temp[Dimsize($name2,0)-1-p]
			endif	
			Duplicate/O temp $name2 
			indice+=1
		  while (indice<=indice_stop)	// stop symmetrize
		
	endif
		endif

	endif
end
///////////////////////////////
function RebuiltBand(p_index,band_index)
wave p_index,band_index

string name1,name2
name1="Kzband__disp"
name2=name1+"1"
Duplicate/O $name2 NewBand

string name3,name4
name3="DispWeight"
name4=name3+"1"
Duplicate/O $name4 NewBandWeight

variable i=0
do
	name2=name1+num2str(band_index[i])
	Duplicate/O $name2 temp
	Newband[p_index[i],p_index[i+1]-1]=temp[p]
	
	name4=name3+num2str(band_index[i])
	Duplicate/O $name4 temp
	NewbandWeight[p_index[i],p_index[i+1]-1]=temp[p]
	
	i+=1
while (i<DimSize(p_index,0)-1)
	
	name2=name1+num2str(band_index[i])
	Duplicate/O $name2 temp
	Newband[p_index[i],DimSize(Newband,0)-1]=temp[p]
	
	name4=name3+num2str(band_index[i])
	Duplicate/O $name4 temp
	NewbandWeight[p_index[i],DimSize(Newband,0)-1]=temp[p]
	
Killwaves temp
end

//////////////
function RebuiltBand_AllWeight(p_index,band_index)
wave p_index,band_index
//For a 2D wave : calculate waves from all bands (recalculate weight each time)
string NewName,FolderName

FolderName="dxz"
AddWeightDisp(FolderName)
NewName="NewBandWeight_"+FolderName
RebuiltBand(p_index,band_index)
rename NewBandWeight, $NewName

FolderName="dyz"
AddWeightDisp(FolderName)
NewName="NewBandWeight_"+FolderName
RebuiltBand(p_index,band_index)
rename NewBandWeight, $NewName

FolderName="dxy"
AddWeightDisp(FolderName)
NewName="NewBandWeight_"+FolderName
RebuiltBand(p_index,band_index)
rename NewBandWeight, $NewName

FolderName="dx2my2"
AddWeightDisp(FolderName)
NewName="NewBandWeight_"+FolderName
RebuiltBand(p_index,band_index)
rename NewBandWeight, $NewName

FolderName="dz2"
AddWeightDisp(FolderName)
NewName="NewBandWeight_"+FolderName
RebuiltBand(p_index,band_index)
rename NewBandWeight, $NewName

Duplicate/O NewBandWeight_dxy TotalWeight
wave NewBandWeight_dyz,NewBandWeight_dxz,NewBandWeight_dxy,NewBandWeight_dz2,NewBandWeight_dx2my2
TotalWeight=NewBandWeight_dyz+NewBandWeight_dxz+NewBandWeight_dxy+NewBandWeight_dz2+NewBandWeight_dx2my2-0.07*4
Display NewBandWeight_dxz,NewBandWeight_dyz,NewBandWeight_dxy,NewBandWeight_dx2my2,NewBandWeight_dz2
ModifyGraph lsize=1.5,rgb(NewBandWeight_dyz)=(0,65280,0)
ModifyGraph rgb(NewBandWeight_dxy)=(16384,28160,65280)
ModifyGraph rgb(NewBandWeight_dx2my2)=(0,0,0)
ModifyGraph rgb(NewBandWeight_dz2)=(65280,16384,55552)
Legend/C/N=text0/A=MC
AppendToGraph TotalWeight
end
