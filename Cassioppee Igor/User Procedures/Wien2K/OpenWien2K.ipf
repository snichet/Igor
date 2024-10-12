#pragma rtGlobals=1		// Use modern global access method.

Function BeforeFileOpenHook(refnum, filename, symPath, type, creator, kind)
variable refnum, kind
string filename, symPath, type, creator

       //Columns of the text file are loaded in temp directory as wave0, wave1 etc.
       NewDataFolder/O root:Temp
       SetDataFolder root:Temp:
       KillWaves/A/Z    
       LoadWave/A /G/P=$symPath fileName  
	
	// Rearrange waves
       Load_Agr_File(refnum, filename, symPath)

	//Read k scale
	ReadKscale(refnum, filename, symPath)
	MakeScale2("spaghetti_k")		
	wave spaghetti_k
	Duplicate/O spaghetti_k distance_k
	 distance_k[]=spaghetti_k[p]-spaghetti_k[p-1]
	 //edit/W=(200,200,500,450) spaghetti_k,distance_k
	 
	variable echec
	
        if (echec==1)
             print "FICHIER INCONNU"
        endif     
         return 1       // don't let igor open the file 
end


////////////////////////////////

function/S Find_Line_In_Header(symPath, filename, refnum, StringToFind)
// Return the line that contains StringToFind
String symPath, filename
variable refnum
string StringToFind

string SES_line
variable VariableToAssign

        Open/R /P=$symPath refnum filename
        do
        FReadline refnum, SES_line
             if (stringmatch(SES_line, StringToFind+"*") )
                        break
                endif
                
        while (1)
        
        close refnum
        return SES_line
end

///////////////////////////////////////////////////////////////////////////

Function Load_Agr_File(refnum, filename, symPath)  
// All bands are loaded in temp as wave0, wave1...

// We want to keep only bands in a given energy window (entered below)
// Rescale them (in 1/angstrom i.e. divided by a0=0.52918
// We plot them with weight, if exists

// We consider structures as :   k value	E value	Weight(éventuellement)

Variable        refnum
String filename, symPath

variable a0=0.52918
variable E_min=-3
variable E_max=2.2
prompt E_min,"E_min"
prompt E_max,"E_max"
DoPrompt "Enter values : ", E_min,E_max
if (v_flag==0)
string folder="root:essai"
prompt folder,"folder to save data :"
DoPrompt "Save in",folder

if (v_flag==0)
NewDataFolder/O $folder
folder+=":"

variable indice=0,indiceband=0
string name0,name1,name2
variable weight_min=0,weight_max=0
variable ok=1

do
	name0="wave"+num2str(indice)
	name1="wave"+num2str(indice+1)
	name2="wave"+num2str(indice+2)
	Duplicate/O $name0 kscale
	Duplicate/O $name1 band
	Duplicate/O $name2 weight
	if (exists(name1)!=1)
		ok=0
	endif
	
	print "indice,indiceband,band[0]",indice,indiceband,band[0]
	if (band[0]>E_min && band[0]<E_max && ok==1)
		Setscale/I x kscale[0]/a0,kscale[DimSize(kscale,0)-1]/a0,band,weight
		weight_max=max(wavemax(weight),weight_max)
		weight_min=min(wavemin(weight),weight_min)
		indiceband+=1
		name1="band"+num2str(indiceband)
		name2="weight"+num2str(indiceband)
		Duplicate/O band $name1
		Duplicate/O weight $name2
		Movewave $name1 $folder
		Movewave $name2 $folder
	endif
	
	indice+=3
while (band[0]<E_max && ok==1 )
Killwaves/A/Z        

SetDataFolder $folder

MakeWeightBandPlot()
endif
endif
End

