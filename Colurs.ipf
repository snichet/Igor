#pragma rtGlobals=1        // Use modern global access method.
#include "SES"

Window Panel_Slider0() : Panel
    PauseUpdate; Silent 1        // building window...
    NewPanel /W=(1247,657,2128,1410)
    ShowTools/A
    SetDrawLayer UserBack
    SetDrawEnv fname= "Vladimir Script",fsize= 50,fstyle= 1,textrgb= (65280,43520,0)
    DrawText 33,74,"Color Bar !"
    SetDrawEnv fname= "MS PGothic",fsize= 40,fstyle= 4,textrgb= (65280,0,52224)
    DrawText 545,105,"pIck uR cuLurZ !!"
    SetDrawEnv linefgc= (39168,0,15616),arrow= 1,arrowlen= 30,arrowfat= 1
    DrawLine 720,110,679,255
    SetDrawEnv linefgc= (0,0,65280),fsize= 50,textrgb= (65280,32512,16384)
    DrawText 608,564,"the numba"
    Slider slider0_color,pos={73,114},size={130,538},proc=slider0_color,fSize=30
    Slider slider0_color,limits={0,200,0},value= 10.9803921568627
    Slider slider1_color,pos={221,122},size={152,579},proc=slider1_color
    Slider slider1_color,labelBack=(32768,65280,0),fSize=20,fColor=(65280,21760,0)
    Slider slider1_color,valueColor=(65280,16384,55552)
    Slider slider1_color,limits={0,0.1,0},value= 0.0899814471243043
    Slider slider_rangeMed,pos={410,34},size={98,660},proc=slider0_color
    Slider slider_rangeMed,labelBack=(65280,0,26112),fSize=24,fStyle=1
    Slider slider_rangeMed,fColor=(0,65280,0),valueColor=(32768,65280,65280)
    Slider slider_rangeMed,limits={0,10,0},value= 6.53605015673981,thumbColor= (48896,65280,48896)
    PopupMenu popup0,pos={575,276},size={200,33},proc=PopMenuProc
    PopupMenu popup0,mode=3,value= #"\"*COLORTABLEPOPNONAMES*\""
    ValDisplay valdisp0,pos={567,420},size={417,88},fSize=72
    ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000}
    ValDisplay valdisp0,value= #"root:TIT1cuts:colorNumber"
EndMacro


Function slider0_color(sa) : SliderControl
    STRUCT WMSliderAction &sa

    switch( sa.eventCode )
        case -1: // control being killed
            break
        default:
            if( sa.eventCode & 1 ) // value set
                Variable curval = sa.curval
                sliderColorChange(curval)
            endif
            break
    endswitch

    return 0
End


Function sliderColorChange(curval)

    Variable curval

    Variable/G colorNumber
    colorNumber = curval
    SVAR colorScheme

	//ModifyImage/W=graph13 css2_1495_n ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=imagetool10 image ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=imagetool16 image ctab={0,curval,$colorScheme,1}
	//ModifyImage/W=graph4 css2_1493_t ctab={0,curval,$colorScheme,1}
	//ModifyImage/W=graph5 test ctab={0,curval,$colorScheme,1}
	//ModifyImage/W=graph6 css2_1492_t ctab={0,curval,$colorScheme,1}
	//ModifyImage/W=graph9 css2_1515_n ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=ImageTool3 image ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=ImageTool4 image ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=ImageTool5 image ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=ImageTool6 image ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=ImageTool7 image ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=ImageTool9 image ctab={0,curval,$colorScheme,1}
      // ModifyImage/W=imagetool9 h_img ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=imagetool9 v_img ctab={0,curval,$colorScheme,1}
      // ModifyImage/W=ImageTool12 image ctab={0,curval,$colorScheme,1}
     //  ModifyImage/W=imagetool12 h_img ctab={0,curval,$colorScheme,1}
     //  ModifyImage/W=imagetool12 v_img ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=ImageTool19 image ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=imagetool19 h_img ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=imagetool19 v_img ctab={0,curval,$colorScheme,1}
      // ModifyImage/W=graph10 css2_fs18_2d_71 ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=ImageTool14 image ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=imagetool14 h_img ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=imagetool14 v_img ctab={0,curval,$colorScheme,1}
       ModifyImage/W=ImageTool22 image ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=imagetool11 h_img ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=imagetool11 v_img ctab={0,curval,$colorScheme,1}
       ModifyImage/W=ImageTool21 image ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=imagetool21 h_img ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=imagetool21 v_img ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=ImageTool16 image ctab={0,curval,$colorScheme,1}
       //ModifyImage/W=ImageTool10 image ctab={0,curval,$colorScheme,1}

   
    String cutListName = "ST1_FS3_fne_80eV_2_EKnames"
    Wave /T cutList = $cutListName
    Variable cutNum = DimSize(cutList,0)
   
    //ModifyImage/W=f00003_scl_n_refFS_w f00003_scl_n_refFS ctab={0,curval,$colorScheme,1}
   
    Variable i
    String cutNow, cutNowWin
   
    for (i = 0; i < cutNum; i += 1)
        cutNow = cutList[i][0]
        cutNowWin = cutList[i][1]
        if (str2num(cutList[i][2]))
            //print cutNowWin
            //print cutNow
          //  ModifyImage/W=$cutNowWin $cutNow ctab={0,curval,$colorScheme,0}
        endif
    endfor
   
End


Function PopMenuProc(pa) : PopupMenuControl
    STRUCT WMPopupAction &pa

    switch( pa.eventCode )
        case 2: // mouse up
            Variable popNum = pa.popNum
            String popStr = pa.popStr
            String/G colorScheme
            colorScheme = popStr
            break
        case -1: // control being killed
            break
    endswitch

    return 0
End


Function slider1_color(sa) : SliderControl
    STRUCT WMSliderAction &sa

    switch( sa.eventCode )
        case -1: // control being killed
            break
        default:
            if( sa.eventCode & 1 ) // value set
                Variable curval = sa.curval
                sliderColorChange(curval)
            endif
            break
    endswitch

    return 0
End



