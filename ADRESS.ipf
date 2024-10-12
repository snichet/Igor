#pragma rtGlobals=3		// Use modern global access method and strict wave access.



menu "ADRESS"
	
	"load ADRESS auto scan", loadADRESS_AuScan_e()

end

function loadADRESS_AuScan_e()


variable temperature=numvarOrDefault("gtemperature", 10)
string pre=strvarOrDefault("gpre","F_")


prompt temperature, "Data aquisition temperature"
prompt pre, "pre"

doprompt "Load Adress Aut scan", temperature, pre
///
///code necessary one press cancel in the prompt
if(V_Flag!=0)
return -1
else
endif
////

variable/g gtemperature=temperature
string/g gpre=pre

extract_Spec_ADRESS_e(pre,1, 0, temperature)


End




function extract_Spec_ADRESS_e(pre,fnum_start, list_num, temperature)
string pre 
variable fnum_start 
variable list_num
variable temperature

killdatafolder/Z $"root:temp"
newdatafolder/o/s $"root:temp"

//Load the data
variable refNum
string source3D
	
	HDF5OpenFile/R refNum as ""
	If (V_Flag==0)
		source3D = S_filename[0,strlen(S_filename)-4];
		HDF5LoadData/IGOR=-1/N=$source3D  refNum,"Matrix"	
		HDF5CloseFile refNum
	else
		print "Load Error"
		return -1
	endif
//End Load data

string info_print=("Loaded Data " + source3D)
print info_print


///////Getting from user the new foder name. Suggested is the loaded file name
string new_folder_name=source3D
prompt new_folder_name, " Insert New Folder Name"
doprompt "New Folder Name", new_folder_name 
///
if(V_Flag!=0)
	return -1
endif
////
//////////////////////////////////////////////////////////////////


string new_folder_long_name="root:"+new_folder_name
if(DataFolderExists(new_folder_long_name))
	DoAlert 1, "Folder already Exist. Do you want to overwrite it?"
	if(V_flag==1)
		killdatafolder/Z $new_folder_long_name
		renamedatafolder  $"root:temp", $new_folder_name
	else
		return -1
	endif
else	
	renamedatafolder  $"root:temp", $new_folder_name	
endif 


variable edim, emin, estep, emax
variable pdim, pmin, pstep, pmax
variable ndim, nmin, nstep, nmax


string filename, filename1, filename2, filename3

pauseupdate; silent 1

edim = dimsize($source3D,0)
emin = dimoffset($source3D,0)
estep = dimdelta($source3D,0)
emax = emin + estep*(edim - 1)

pdim = dimsize($source3D,1)
pmin = dimoffset($source3D,1)
pstep = dimdelta($source3D,1)
pmax = pmin + pstep*(pdim - 1)
						
ndim = (dimsize($source3D,2)==0) ? 1 :dimsize($source3D,2)   //in case the wave is 2D
nmin = dimoffset($source3D,2)
nstep = dimdelta($source3D,2)
nmax = nmin + nstep*(ndim - 1)
			
	

wave Wsource3D=$source3D
string speclist_name="speclist"+num2str(list_num)
string theta_name="theta"+num2str(list_num)
string tilt_name="tilt"+num2str(list_num)
string phi_name="phi"+num2str(list_num)
string hv_name="hv"+num2str(list_num)

make/o/n= (ndim) $speclist_name, $theta_name, $tilt_name, $phi_name, $hv_name
wave speclist=$speclist_name
wave theta=$theta_name
wave phi=$phi_name
wave tilt=$tilt_name
wave hv=$hv_name
	
speclist=fnum_start+p

string Shv=note(Wsource3D)[10+strsearch(note(Wsource3D),"hv",0 ),strsearch(note(Wsource3D),"Pol",0)-2]
//hv=str2num(Shv)

variable Shv_len=strlen(Shv)

if(strsearch(Shv, ":",0 )==-1)
	if(strsearch(Shv, "+",1 )==-1 && strsearch(Shv, "-",1 )==-1)
		hv=str2num(Shv)	
	else
			if(strsearch(Shv, "+",1 )!=-1)
				hv=str2num(Shv[0, strsearch(Shv, "+",1 )-1])+str2num(Shv[ strsearch(Shv, "+",1 )+1, Shv_len+1])
			else
				hv=str2num(Shv[0, strsearch(Shv, "+",1 )-1])-str2num(Shv[ strsearch(Shv, "+",1 )+1, Shv_len+1])
			endif
	endif
else
	
	string Shv_min= Shv[0,strsearch(Shv, ":",0 )-1 ]
	string Shv_delta= Shv[strsearch(Shv, ":",0 )+1,strsearch(Shv, ":",Shv_len,1 ) -1]
	variable hv_min=str2num(Shv_min)
	variable hv_delta=str2num(Shv_delta)
	
	hv=hv_min+p*hv_delta	
endif


string SPol=note(Wsource3D)[10+strsearch(note(Wsource3D),"Pol     =",0 ),strsearch(note(Wsource3D),"Slit    =",0)-2]


string SSlits=note(Wsource3D)[10+strsearch(note(Wsource3D),"Slit    =",0 ),strsearch(note(Wsource3D),"Mode    =",0)-2]


string SMode=note(Wsource3D)[10+strsearch(note(Wsource3D),"Mode    =",0 ),strsearch(note(Wsource3D),"Epass   =",0)-2]


string SEpass=note(Wsource3D)[10+strsearch(note(Wsource3D),"Epass   =",0 ),strsearch(note(Wsource3D),"Ek/Eb   = ",0)-2]


string SEk_Eb=note(Wsource3D)[10+strsearch(note(Wsource3D),"Ek/Eb   = ",0 ),strsearch(note(Wsource3D),"dt      = ",0)-2]


string Sdt=note(Wsource3D)[10+strsearch(note(Wsource3D),"dt      = ",0 ),strsearch(note(Wsource3D),"Sweeps  = ",0)-2]



string Ssweeps=note(Wsource3D)[10+strsearch(note(Wsource3D),"Sweeps  = ",0 ),strsearch(note(Wsource3D),"Theta   = ",0)-2]


	
string Sphi=note(Wsource3D)[10+strsearch(note(Wsource3D),"Azimuth =",0 ),strsearch(note(Wsource3D),"Comment",0)-2]
phi=str2num(Sphi)
	


string Stilt=note(Wsource3D)[10+strsearch(note(Wsource3D),"Tilt    = ",0 ), strsearch(note(Wsource3D),"Azimuth =",0)-2]
//tilt=str2num(Stilt)

variable Stilt_len=strlen(Stilt)

if(strsearch(Stilt, ":",0 )==-1)
	if(strsearch(Stilt, "+",1 )==-1 && strsearch(Stilt, "-",1 )==-1)
		tilt=str2num(Stilt)	
	else
			if(strsearch(Stilt, "+",1 )!=-1)
				tilt=str2num(Stilt[0, strsearch(Stilt, "+",1 )-1])+str2num(Stilt[ strsearch(Stilt, "+",1 )+1, Stilt_len+1])
			else
				tilt=str2num(Stilt[0, strsearch(Stilt, "+",1 )-1])-str2num(Stilt[ strsearch(Stilt, "+",1 )+1, Stilt_len+1])
			endif
	endif
else
	//print Stilt
	string Stilt_min=Stilt[0,strsearch(Stilt, ":",0 )-1 ]
	string Stilt_delta= Stilt[strsearch(Stilt, ":",0 )+1,strsearch(Stilt, ":",Stilt_len,1 ) -1]
	variable tilt_min=(cmpstr(Stilt_min[0],"[")==0)?str2num(Stilt_min[0,strlen(Stilt_min)-1]):str2num(Stilt_min)
	variable tilt_delta=str2num(Stilt_delta)
	//print Stilt_min, tilt_delta
	tilt=tilt_min+p*tilt_delta	
endif


	
string Stheta=note(Wsource3D)[10+strsearch(note(Wsource3D),"Theta   = ",0 ), strsearch(note(Wsource3D),"Tilt    = ",0)-2]

variable Stheta_len=strlen(Stheta)

if(strsearch(Stheta, ":",0 )==-1)
	if(strsearch(Stheta, "+",1 )==-1 && strsearch(Stheta, "-",1 )==-1)
		theta=str2num(Stheta)	
	else
			if(strsearch(Stheta, "+",1 )!=-1)
				theta=str2num(Stheta[0, strsearch(Stheta, "+",1 )-1])+str2num(Stheta[ strsearch(Stheta, "+",1 )+1, Stheta_len+1])
			else
				theta=str2num(Stheta[0, strsearch(Stheta, "+",1 )-1])-str2num(Stheta[ strsearch(Stheta, "+",1 )+1, Stheta_len+1])
			endif
	endif
else
	
	string Stheta_min= Stheta[0,strsearch(Stheta, ":",0 )-1 ]
	string Stheta_delta= Stheta[strsearch(Stheta, ":",0 )+1,strsearch(Stheta, ":",stheta_len,1 ) -1]
	variable theta_min=str2num(Stheta_min)
	variable theta_delta=str2num(Stheta_delta)
	
	theta=theta_min+p*theta_delta	
endif
	
	
	variable i
	for(i=0;i<ndim;i+=1)
				filename = pre + num2str(i+fnum_start)
				make/o/n=(edim,pdim) $filename
				wave Wfilename=$filename
				Wfilename = Wsource3D[p][q][i]
				setscale/i x, emin,emax, Wfilename	
				setscale/i y, pmin,pmax, $filename	
              		//create_info(i+fnum_start,theta[i], phi[i], tilt[i],0)
                		
                		set_gVarPar_e(speclist[ i ], 0,1,0, 0, 0, 0,0, 0, 0,0,0)
                		
				set_info2_e(speclist[i],theta[i], phi[i], tilt[i], hv[i], str2num(Ssweeps), str2num(Sdt), 0,str2num(SEpass), temperature, str2num(Sslits), 0,0,0,0,0,0,0) 
				
				matrixtranspose Wfilename
	endfor

/////////////////////////////////////////////////
newdatafolder/o :info
setdatafolder :info



string info_spec_name="I_sp"+num2str(0)
make/o/T/n=2  $info_spec_name
wave/t info_spec=$info_spec_name

info_spec[0]=s_path
info_spec[1]=S_fileName


make/o/T/n=2  info_spec_text

info_spec_text[0]="Loaded file path"
info_spec_text[1]="Loaded file name"

setdatafolder $new_folder_long_name
//////////////////////////////////////////////////	

//killwaves $source3D
	
end



Function set_gVarPar_e(fnum,VarMS, VarAS, VarBG, VarEF, VarSym, VarCuNorm, VarEDCNorm, VarSquareNorm,VarFDdiv, VarLRDec, VarAng2k)
variable fnum, VarMS, VarAS, VarBG, VarEF, VarSym, VarCuNorm, VarEDCNorm, VarSquareNorm,VarFDdiv, VarLRDec, VarAng2k


newdatafolder/o :infoVar

variable/g $":infoVar:g_"+num2str(fnum)+"_MS"
variable/g $":infoVar:g_"+num2str(fnum)+"_AS"
variable/g $":infoVar:g_"+num2str(fnum)+"_BG"
variable/g $":infoVar:g_"+num2str(fnum)+"_EF"
variable/g $":infoVar:g_"+num2str(fnum)+"_Sym"
variable/g $":infoVar:g_"+num2str(fnum)+"_CuNorm"
variable/g $":infoVar:g_"+num2str(fnum)+"_EDCNorm"
variable/g $":infoVar:g_"+num2str(fnum)+"_SquareNorm"
variable/g $":infoVar:g_"+num2str(fnum)+"_FDdiv"
variable/g $":infoVar:g_"+num2str(fnum)+"_LRDec"
variable/g $":infoVar:g_"+num2str(fnum)+"_Ang2k"

NVar MS_local				=$":infoVar:g_"+num2str(fnum)+"_MS"
NVar AS_local				=$":infoVar:g_"+num2str(fnum)+"_AS"
NVar BG_local				=$":infoVar:g_"+num2str(fnum)+"_BG"
NVar EF_local				=$":infoVar:g_"+num2str(fnum)+"_EF"
NVar Sym_local			=$":infoVar:g_"+num2str(fnum)+"_Sym"
NVar CuNorm_local		=$":infoVar:g_"+num2str(fnum)+"_CuNorm"
NVar EDCNorm_local		=$":infoVar:g_"+num2str(fnum)+"_EDCNorm"
NVar SquareNorm_local=$":infoVar:g_"+num2str(fnum)+"_SquareNorm"
NVar FDdiv_local			=$":infoVar:g_"+num2str(fnum)+"_FDdiv"
NVar LRDec_local			=$":infoVar:g_"+num2str(fnum)+"_LRDec"
NVar Ang2k_local			=$":infoVar:g_"+num2str(fnum)+"_Ang2k"

MS_local				= VarMS
AS_local				= VarAS
BG_local				= VarBG
EF_local				= VarEF
Sym_local				=VarSym
CuNorm_local			= VarCuNorm
EDCNorm_local			= VarEDCNorm
SquareNorm_local		= VarSquareNorm
FDdiv_local				= VarFDdiv
LRDec_local			= VarLRDec
Ang2k_local			= VarAng2k


end




function set_info2_e(f_num,theta, phi, tilt, hv, sweeps, dt_ms, de_eV,Ep_eV, temperature, ES, manip_X_mm, manip_Y_mm, manip_Z_mm, KEi_eV, KEf_eV, elapsed_time_secs, AuSC_number) 
variable f_num,theta, phi, tilt, hv, sweeps, dt_ms, de_eV,Ep_eV, temperature, ES
variable manip_X_mm, manip_Y_mm, manip_Z_mm, KEi_eV, KEf_eV, elapsed_time_secs, AuSC_number

 string current_Folder = getdatafolder(1)
 newdatafolder/o/s :info	
 	
string  	info_name="I_"+num2str(f_num)
make/o/n=(18) $info_name
wave Winfo_name=$info_name
	
Winfo_name[0]=f_num
Winfo_name[1]=theta
Winfo_name[2]=phi
Winfo_name[3]=tilt
Winfo_name[4]=sweeps
Winfo_name[5]=dt_ms
Winfo_name[6]=dE_eV
Winfo_name[7]=KEi_eV
Winfo_name[8]=KEf_eV
Winfo_name[9]=Ep_eV 
Winfo_name[10]=manip_X_mm
Winfo_name[11]=manip_Y_mm
Winfo_name[12]=manip_Z_mm
Winfo_name[13]=temperature
Winfo_name[14]=ES
Winfo_name[15]=hv
Winfo_name[16]=elapsed_time_secs
Winfo_name[17]=AuSC_number
 	
 	
 	
 make/o/T/n=(18) info_text
 info_text[0]="scan number"
 info_text[1]="theta"
 info_text[2]="phi"
 info_text[3]="tilt"
 info_text[4]="sweeps"
 info_text[5]="dt_ms"
 info_text[6]="dE_eV"
 info_text[7]="KEi_eV"
 info_text[8]="kEf_eV" 
 info_text[9]="Ep_eV"
 info_text[10]="manip_X_mm"
 info_text[11]="manip_Y_mm"
 info_text[12]="manip_Z_mm"
 info_text[13]="temperature"
 info_text[14]="ES"
 info_text[15]="hv_ev"
 info_text[16]="elapsed time secs"
 info_text[17]="AuSc_number"
 
string info_nameCom="I_"+num2str(f_num)+"Comments"
string/g $info_nameCom
SVAR Wcom=$info_nameCom
Wcom="raw data"

 
 
setdatafolder $current_Folder
 
end
