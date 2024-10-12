#pragma rtGlobals=1             // Use modern global access method.


//////////// Various functions to extract lines or values from the header of the file
//function Find_Value_In_Header(symPath, filename, refnum, StringToFind)
                   // Look for a line containing 'StringToFind=xxx' in FileName
                  // Return xxx 
//function Find_Line_In_Header(symPath, filename, refnum, StringToFind)
                   // Return the line that contains StringToFind
//function Find_ListOfValue_In_Header(symPath, filename, refnum, StringToFind)
                        // Look for a line containing 'StringToFind=xxx yyy zzz...' in FileName
                        // Assign xxx to start and (yyy-xxx) to delta (these are global variables)     
//function Find_Type_In_Header(symPath, filename, refnum, StringToFind)
                   // Look for a line containing 'StringToFind xxx' in FileName
                   // return xxx to VariableToAssign (function itself)                  
                                      
/////////////////////////////////
Function BeforeFileOpenHook(refnum, filename, symPath, type, creator, kind)
variable refnum, kind
string filename, symPath, type, creator

string SES_line,name,Folder,extra,location
variable Nb_x_pnts, Nb_y_pnts,Nb_images,i,start_y,delta_y,FileType,cur
variable/G echec=0      

       //Columns of the text file are loaded in temp directory as wave0, wave1 etc.
       NewDataFolder/O root:Temp
       SetDataFolder root:Temp:
       KillWaves/A/Z    
       LoadWave/A /G/P=$symPath fileName  
       
       //Now read the header to know what these waves are, format them, build images and so on
       //Simple files : wave0 to waveN are 1D lines of the image
       //Also possibility to have successive files for different theta values and so on (for example used by Stanford : wave(pN) to wave((p+1)N) are the lines of the pth image)    
      
       //Look in header for a string location=xxx
        location=Find_String_In_Header(symPath, filename, refnum,"Location") 

       if (cmpstr(location,"SSRL")==0)
                 Load_Stanford_Type(refnum, filename, symPath)
                 else
	        LoadSimpleFiles(refnum, filename, symPath)
	        //LoadFilesWithMissingParameters(refnum, filename, symPath)  
        endif 

        if (echec==1)
             print "FICHIER INCONNU"
        endif 
          KillDataFolder/Z root:Temp    
        SetDataFolder root:OriginalData
      
         return 1       // don't let igor open the file 
end
//////////////////////////////

Function LoadSimpleFiles(refnum, filename, symPath)  
//Look in the header for file type
// At present : 1D file (saved as 2 column : energy and data
//			  Image : list of values : one energy, list of angular values, next energy and so on
//No angles are read from the file 

Variable refnum
String filename, symPath

string SES_line,name,Folder,extra,filename2
variable Nb_x_pnts, Nb_y_pnts,Nb_images,i,FileType,cur,length,para
             
        //Look for which type : 1D or 2D 
        	FileType=Find_Type_In_Header(symPath, filename, refnum,"Dimension 2")+1 
        	length=strlen(filename)-5 // assumes filename = ****.txt and that one wants to delete the extension
        	//FileType = 1 or 2, for 1D or 2D files
          
      	//Load 1D file
      	if (Filetype==1)
      		//The loading procedure from Igor has  loaded wave1 as y data and wave0 as Xdata in temp folder
      		Nb_x_pnts=Find_Value_In_Header(symPath, filename, refnum,"Dimension 1 size")
      		wave wave0,wave1
      		SetScale/I x wave0[0],wave0[Nb_x_pnts-1],"", wave1
      		 name="A"+filename[0,length]
      		 Duplicate/O wave1, $name  
      		 Folder="root:OriginalData:"+name          
      		  MoveWave $name $Folder
      		  KillWaves/A/Z //in Temp
      		  SetDataFolder root:OriginalData
      		  Display $name
      	endif
      	
      	//Load 2D image
      If (FileType==2)
      		//Look in the header for parameters necessary to format the wave
      		Nb_x_pnts=Find_Value_In_Header(symPath, filename, refnum,"Dimension 1 size") // search for a line like Dimension 1 size = 500 and assign 500 to Nb_x_pnts
      		Nb_y_pnts=Find_Value_In_Header(symPath, filename, refnum,"Dimension 2 size")
      		NewDataFolder/O root:OriginalData
      		Folder="root:OriginalData:"
             
      		variable/G start, delta
      		variable start_x,delta_x,start_y,delta_y
      		Find_ListOfValue_In_Header(symPath, filename, refnum,"Dimension 1 scale"," " )
      		start_x=start
      		delta_x=delta
      		Find_ListOfValue_In_Header(symPath, filename, refnum,"Dimension 2 scale"," " )
      		start_y=start
      		delta_y=delta
      		
      		Make/O/N=((Nb_x_pnts),(Nb_y_pnts))/D LoadedWave           //Format the wave
      		wave wave0
      		//SetScale/I x wave0[0],wave0[Nb_x_pnts-1],"", LoadedWave   // Sometimes wave0 is the x scale but not always
      		SetScale/P x start_x,delta_x,"", LoadedWave
      		SetScale/P y start_y,delta_y,"", LoadedWave
      
      		////////////////
      		variable stop
             if (wave0[0]==start_x && wave0[1]==start_x+delta_x)
             	i=1
             	stop=Nb_y_pnts
             	else
             	i=0
             	stop=Nb_y_pnts-1
             endif	
             do   //loop on i, i.e. number of lines in the image
                  name="wave"+num2str(i)
                  Duplicate/O $name temp
                  LoadedWave[][i-1]=temp[p]
                  i=i+1
             while (i<=stop)
             
             name="A"+filename[0,length]

            	Duplicate/O LoadedWave, $name                
             //Display;AppendImage $name
             //ModifyImage $name ctab= {*,*,YellowHot,0}

            //Move in appropriate folder
            extra=folder+name
            if (Waveexists($extra)==1)
                    KillWaves $extra 
            endif   
             MoveWave $name $Folder
       
             KillWaves/A/Z // in temp 
             SetDataFolder root:OriginalData
              
    		// For Automatic run on Cassiopee : read theta and energy in the file              
              if (cmpstr(filename[length-4,length],"ROI1_")==0)
              variable Nb
	     		filename2= filename[0,length-5]+"i.txt"
      			//para=Find_Value_In_Header_After2P(symPath, filename2, refnum, "theta")
      			//para=Find_Value_In_Header_After2P(symPath, filename2, refnum, "hv (eV)")
      			//para=round(para*10)/10 // Garde 1 chiffre après la virgule
      			 if (WaveExists(LoadedImage)==1)
      			 	wave/T/Z LoadedImage
	      			 wave/Z Theta_cassiopee,Energy_cassiopee
	      			 Nb=DimSize(LoadedImage,0)+1
	      			  	// in case theta_cassiopee or energy_cassiopee have been killed or moved, create them again
	      			  	if (WaveExists(theta_cassiopee)==0)
	      			  	Make/O /N=(Nb) theta_cassiopee	
	      			  	endif
	      			  	if (WaveExists(energy_cassiopee)==0)
	      			  	Make/O /N=(Nb) energy_cassiopee	
	      			  	endif
      			 	Redimension/N=(Nb) LoadedImage, theta_cassiopee, energy_cassiopee
      			 	LoadedImage[Nb-1]="A"+filename[0,strlen(filename)-5]
      			 	theta_cassiopee[Nb-1]=Find_Value_In_Header_After2P(symPath, filename2, refnum, "theta")
      			 	Energy_cassiopee[Nb-1]=Find_Value_In_Header_After2P(symPath, filename2, refnum, "hv (eV)")
      			 	
      			 else
      			 	Make/N=1/T LoadedImage
      			 	Make/O/N=1 theta_cassiopee,Energy_cassiopee
      			 	Nb=1
      			 	LoadedImage[0]="A"+filename[0,strlen(filename)-5]
      			 	theta_cassiopee[0]=Find_Value_In_Header_After2P(symPath, filename2, refnum, "theta")
      			 	Energy_cassiopee[0]=Find_Value_In_Header_After2P(symPath, filename2, refnum, "hv (eV)")
      			 	
      			 endif
      			 print "Run Nb=",Nb,"LoadedImage=",LoadedImage[Nb-1],"Theta=",theta_cassiopee[Nb-1],"PhotonEnergy=",Energy_cassiopee[Nb-1]
      		endif
        endif
        DoWindow/F Info2D_table
        DoWindow/F ProcessPanel
End
/////////////////////////////
Function LoadFilesWithMissingParameters(refnum, filename, symPath)  
// For 2D files with no scaling (have to be rescaled afterwards)
// Just put the waves of temp folder in a 2D format

Variable refnum
String filename, symPath
string folder,name,extra
      		NewDataFolder/O root:OriginalData
      		Folder="root:OriginalData:"
             
      		variable/G start, delta
      		variable start_x,delta_x,start_y,delta_y

      		variable NbX,NbY,i
		NbX=Dimsize(wave0,0)
 		NbY=ItemsInList(WaveList("wave*",";","" ))  // Nb of waves in folder temp
		
		Make/O/N=((NbX),(NbY))/D LoadedWave           //Format the wave
		
		i=0
		do   //loop on i, i.e. number of lines in the image
                  name="wave"+num2str(i)
                  Duplicate/O $name temp
                  LoadedWave[][i-1]=temp[p]
                  i=i+1
             while (i<NbY)
             
             variable length=strlen(filename)-5
             name="A"+filename[0,length]
            	Duplicate/O LoadedWave, $name                
             //Display;AppendImage $name
             //ModifyImage $name ctab= {*,*,YellowHot,0}

            //Move in appropriate folder
            extra=folder+name
            if (Waveexists($extra)==1)
                    KillWaves $extra 
            endif   
             MoveWave $name $Folder
       
             KillWaves/A/Z // in temp 
             SetDataFolder root:OriginalData

        DoWindow/F Info2D_table
        DoWindow/F ProcessPanel
End
///////////////////////////

Function Load_Stanford_Type(refnum, filename, symPath)  
//Look in the header for file type
// At present : 1- Stanford format (one image)
//                     2- Stanford format (manipulator run) 
//Load the wave as general text, make images and save in Originaldata as filename_ThetaPhiValues (read in header)


Variable        refnum
String filename, symPath


string SES_line,name,Folder,extra
variable Nb_x_pnts, Nb_y_pnts,Nb_images,i,start_y,delta_y,FileType,cur
             
        //Look for which type. If this is a manipulator runs (contains many images) there will be a third dimension and FileType=3
        //Otherwise, it is just an image  
        FileType=Find_Type_In_Header(symPath, filename, refnum,"Dimension 2")+1 //If filetype=1 : 1D file, else 2D or 3D file
        if (FileType==2)
	        FileType=FileType+Find_Type_In_Header(symPath, filename, refnum,"Dimension 3")  
        endif
        //Now FileType is 1, 2 or 3, depending on the type of file
          
      //Look in the header for parameters necessary to format the wave
        Nb_x_pnts=Find_Value_In_Header(symPath, filename, refnum,"Dimension 1 size") // search for a line like Dimension 1 size = 500 and assign 500 to Nb_x_pnts
        Nb_y_pnts=Find_Value_In_Header(symPath, filename, refnum,"Dimension 2 size")
       NewDataFolder/O root:OriginalData
        if (FileType==3) 
              Nb_images=Find_Value_In_Header(symPath, filename, refnum,"Dimension 3 size")
              Folder="root:OriginalData:FS"+ filename[0,13]
              NewDataFolder/O $Folder
           else
              Nb_images=1
              Folder="root:OriginalData"
        endif
        
        Folder=Folder+":"
        variable/G start, delta
        Find_ListOfValue_In_Header(symPath, filename, refnum,"Dimension 2 scale"," " )
        start_y=start
        delta_y=delta
      Make/O/N=((Nb_x_pnts),(Nb_y_pnts))/D LoadedWave           //Format the wave
      wave wave0
      SetScale/I x wave0[0],wave0[Nb_x_pnts-1],"", LoadedWave
      SetScale/P y start_y,delta_y,"", LoadedWave
      
      ////////////////
      cur=1
      do //loop on cur=number of images in the file
             i=1
             do   //loop on i, i.e. number of lines in the image
                  name="wave"+num2str((cur-1)*(Nb_y_pnts+1)+i)
                  Duplicate/O $name temp
                  LoadedWave[][i-1]=temp[p]
                  i=i+1
             while (i<=Nb_y_pnts)
             name="A"+filename[0,13]+"_"
             //name=name+ReadHeader_ThetaPhi(symPath, filename, refnum,cur,Nb_images) 
                 if (cur==2) //Bug dans l'ecriture Stanford du fichier : 2 fois step 1
                   name="A"+filename[0,13]+"_nop"
                 endif  
            Duplicate/O LoadedWave, $name                
              //Display image (if only one)
              if (Nb_images==1)
                   //Display;AppendImage $name
                   //ModifyImage $name ctab= {*,*,YellowHot,0}
            endif   
            //Move in appropriate folder
            extra=folder+name
            if (Waveexists($extra)==1)
                    KillWaves $extra 
            endif   
             MoveWave $name $Folder
        
             cur=cur+1
        while (cur<=Nb_images)
       
       KillWaves/A/Z // in temp 
        
End


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Various functions to extract lines or values from the header of the file


function Find_Value_In_Header(symPath, filename, refnum, StringToFind)
// Look for a line containing 'StringToFind=xxx' in FileName
// Assign xxx to VariableToAssign (function itself)
String symPath, filename
variable refnum
string StringToFind

string SES_line
variable VariableToAssign

        Open/R /P=$symPath refnum filename
        do
        FReadline refnum, SES_line
             if (stringmatch(SES_line, StringToFind+"*") )
                        //print SES_line
                        VariableToAssign=NumberByKey(StringToFind, SES_line,"=","/r") 
                        //print "variable=", VariableToAssign
                        break
                endif
        while (1)
        
        close refnum
        return variableToAssign
end

/////

function/S Find_String_In_Header(symPath, filename, refnum, StringToFind)
// Same as Find_Value_In_Header but for strings
// // Look for a line containing 'StringToFind=xxx' in FileName. Return xxx.
String symPath, filename
variable refnum
string StringToFind

string SES_line
string VariableToAssign
variable pos_start,success

        success=0
        Open/R /P=$symPath refnum filename
        do
        FReadline refnum, SES_line
             if (stringmatch(SES_line, StringToFind+"*") )
                        //print SES_line
                        pos_start=strsearch(SES_line,"=",0)
                   VariableToAssign=SES_line[pos_start+1,strlen(SES_line)-2]  //-2 because of /r at end of line
                        success=1
                        //print "variable=", VariableToAssign
                        break
                endif
                FStatus refnum
                if (V_filePos>=V_logEOF) //fin du fichier
                      break
                endif     
        while (1)
        if (success==0) 
              VariableToAssign="none"
        endif      
        close refnum
        return variableToAssign
end

//////

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

function Find_ListOfValue_In_Header(symPath, filename, refnum, StringToFind,Separation)
// Look for a line containing 'StringToFind=xxx yyy zzz...' in FileName
// Assign xxx to start and (yyy-xxx) to delta (these are global variables)
//Typically to read angle values. Separation is " " for Stanford and "E" for Wisconsin
String symPath, filename
variable refnum
string StringToFind, Separation

string SES_line,first_value,second_value
variable pos_start,pos_end,pos_end2,skip
nvar start=root:Temp:start, delta=root:Temp:delta

        skip=strlen(Separation)
        Open/R /P=$symPath refnum filename
        do
        FReadline refnum, SES_line
             if (stringmatch(SES_line, StringToFind+"*") )
                    break
                endif
        while (1)
        close refnum
       
       //extract first value from = to next separation sign
       pos_start=strsearch(SES_line,"=",0)
       pos_end=strsearch(SES_line,Separation,pos_start)
       first_value=SES_line[pos_start+1,pos_end-1]
       pos_end2=strsearch(SES_line,Separation,pos_end+skip+1)
       second_value=SES_line[pos_end+skip,pos_end2-1]
        //print first_value,second_value
        
        start=str2num(first_value)
        delta=str2num(second_value)-start
        //print "start,delta (function)",start,delta
end

//////////

function/S    ReadHeader_ThetaPhi(symPath, filename, refnum,cur,Nb_images)
string symPath,filename
variable refnum,cur,Nb_images
variable Theta,Phi,pos_start,pos_end
string SES_Line,name

if (Nb_images==1)
        SES_Line=Find_Line_In_Header(symPath, filename, refnum, "T=")
        theta=str2num(SES_line[3,20])
        SES_line=Find_Line_In_Header(symPath, filename, refnum, "F=")
        phi=str2num(SES_line[3,20])
    else
       SES_Line="step "+num2str(cur-1)
       if (cur==1)
           SES_Line="step 1" //Bug dans l'ecriture des fichiers
       endif    
       SES_line=Find_Line_In_Header(symPath, filename, refnum, SES_line)
       pos_start=strsearch(SES_line,"=",0)
       pos_end=strsearch(SES_line,";",pos_start)
       theta=str2num(SES_line[pos_start+1, pos_end-1])
       pos_start=strsearch(SES_line,"=",pos_end)
       pos_end=strsearch(SES_line,";",pos_start)
       phi=str2num(SES_line[pos_start+1, pos_end-1])
endif
//print "theta, phi=",theta,phi
if (theta>=0)
    name="T"+num2str(theta)
    else
    name="T"+num2str(-theta)+"N"
endif    
if (phi>=0)
    name=name+"P"+num2str(phi)
    else
    name=name+"P"+num2str(-phi)+"N"
endif
return name
end

/////////////

function Find_Type_In_Header(symPath, filename, refnum, StringToFind)
// Look if StringToFind exists in the file
// If yes return 1 else return 0
String symPath, filename
variable refnum
string StringToFind

string SES_line
variable VariableToAssign

       VariableToAssign=0
        Open/R /P=$symPath refnum filename
        do
        FReadline refnum, SES_line
          //print SES_line
             if (stringmatch(SES_line, StringToFind+"*") )
                        VariableToAssign=1 //i.e. finds StringToFind ...
                        break
                endif
                if (stringmatch(SES_line, "*Data*") )
                         //i.e. no Dimension 3 in header
                        break
                endif
        while (1)
        close refnum
        
        return variableToAssign// =0 if StringToFind not found, 1 otherwise
end

///

function Find_Value_In_Header_After2P(symPath, filename, refnum, StringToFind)
// Look for a line containing 'StringToFind :	xxx' in FileName
// Assign xxx to VariableToAssign (function itself)
String symPath, filename
variable refnum
string StringToFind

string SES_line,numVar
variable VariableToAssign,i

        Open/R /P=$symPath refnum filename
        do
        FReadline refnum, SES_line
             if (stringmatch(SES_line, StringToFind+"*") )
             	   i=0
             	    do
             	    	i+=1
             	    while (abs(cmpstr(SES_line[i],":"))>0 ) 
                        VariableToAssign=Str2Num(SES_line[i+1,strlen(SES_line)]) 
				//print "Reading : ",SES_line,SES_line[i+1,strlen(SES_line)],VariableToAssign
                        break
                endif
        while (1)
        
        close refnum
        variableToAssign=round(variableToAssign*10)/10 // 1 chiffre apres la virgule
        return variableToAssign
end
/////


//////////////////////////////////////////////////////////////////////////////////////////
Proc AutoParameters(NumberInFileName,deletePnts)
variable NumberInFileName, deletePnts
// For auto runs on Cassiopee : rename the waves without the parenthesis and sort them by number
// Files should be transferred in one folder and a table of parameters should exist
// Enter below values for how many points to delete at the end and position of number in the filename
variable Nb=dimsize(OriginalImage,0)
variable index=0

	do
		rename $OriginalImage[index] $((OriginalImage[index])[0,strlen(OriginalImage[index])-DeletePnts])
		index+=1
	while (index<Nb)
	// Redo the table
	DoWindow/K Info2D_table
	Killwaves OriginalImage,Other_Angle,Slit_Angle,ProcessFlag	
	SetParameters("")
	// sort the waves
	index=0
	do
		Other_Angle[index]=str2num((OriginalImage[index])[NumberInFileName,NumberInFileName+2])
		index+=1
	while (index<Nb)
	Sort Other_Angle OriginalImage,Slit_Angle,ProcessFlag,Other_Angle
	// Give new values to other_angle
	//Other_Angle=-11+0.5*p
end