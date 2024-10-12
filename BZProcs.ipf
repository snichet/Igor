#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function DrawHexBZ(a,OutputName)

variable a //distance between neighboring 2D zone centers
String OutputName

String XOutputName=OutputName+"_x"
make /o /n=126 $XOutputName
Wave XOut=$XOutputName

String YOutputName=OutputName+"_y"
make /o /n=126 $YOutputName
Wave YOut=$YOutputName

XOut[0]=a*0.5
YOut[0]=a*1/2*tan(30*pi/180)
XOut[1]=a*0.5
YOut[1]=-a*1/2*tan(30*pi/180)
XOut[2]=nan
YOut[2]=nan

XOut[3]=-a*0.5
YOut[3]=a*1/2*tan(30*pi/180)
XOut[4]=-a*0.5
YOut[4]=-a*1/2*tan(30*pi/180)
XOut[5]=nan
YOut[5]=nan

XOut[6]=-a*0.5
YOut[6]=a*1/2*tan(30*pi/180)
XOut[7]=0
YOut[7]=a/2/cos(30*pi/180)
XOut[8]=nan
YOut[8]=nan

XOut[9]=-a*0.5
YOut[9]=-a*1/2*tan(30*pi/180)
XOut[10]=0
YOut[10]=-a/2/cos(30*pi/180)
XOut[11]=nan
YOut[11]=nan

XOut[12]=a*0.5
YOut[12]=-a*1/2*tan(30*pi/180)
XOut[13]=0
YOut[13]=-a/2/cos(30*pi/180)
XOut[14]=nan
YOut[14]=nan

XOut[15]=a*0.5
YOut[15]=a*1/2*tan(30*pi/180)
XOut[16]=0
YOut[16]=a/2/cos(30*pi/180)
XOut[17]=nan
YOut[17]=nan

variable n

n=1

XOut[0+n*18]=a*(0.5+1)
YOut[0+n*18]=a*1/2*tan(30*pi/180)
XOut[1+n*18]=a*(0.5+1)
YOut[1+n*18]=-a*1/2*tan(30*pi/180)
XOut[2+n*18]=nan
YOut[2+n*18]=nan

XOut[3+n*18]=a*(-0.5+1)
YOut[3+n*18]=a*1/2*tan(30*pi/180)
XOut[4+n*18]=a*(-0.5+1)
YOut[4+n*18]=-a*1/2*tan(30*pi/180)
XOut[5+n*18]=nan
YOut[5+n*18]=nan

XOut[6+n*18]=a*(-0.5+1)
YOut[6+n*18]=a*1/2*tan(30*pi/180)
XOut[7+n*18]=a*(0+1)
YOut[7+n*18]=a*1/2/cos(30*pi/180)
XOut[8+n*18]=nan
YOut[8+n*18]=nan

XOut[9+n*18]=a*(-0.5+1)
YOut[9+n*18]=-a*1/2*tan(30*pi/180)
XOut[10+n*18]=a*(0+1)
YOut[10+n*18]=-a*1/2/cos(30*pi/180)
XOut[11+n*18]=nan
YOut[11+n*18]=nan

XOut[12+n*18]=a*(0.5+1)
YOut[12+n*18]=-a*1/2*tan(30*pi/180)
XOut[13+n*18]=a*(0+1)
YOut[13+n*18]=-a*1/2/cos(30*pi/180)
XOut[14+n*18]=nan
YOut[14+n*18]=nan

XOut[15+n*18]=a*(0.5+1)
YOut[15+n*18]=a*1/2*tan(30*pi/180)
XOut[16+n*18]=a*(0+1)
YOut[16+n*18]=a*1/2/cos(30*pi/180)
XOut[17+n*18]=nan
YOut[17+n*18]=nan

n=2

XOut[0+n*18]=a*(0.5-1)
YOut[0+n*18]=a*1/2*tan(30*pi/180)
XOut[1+n*18]=a*(0.5-1)
YOut[1+n*18]=-a*1/2*tan(30*pi/180)
XOut[2+n*18]=nan
YOut[2+n*18]=nan

XOut[3+n*18]=a*(-0.5-1)
YOut[3+n*18]=a*1/2*tan(30*pi/180)
XOut[4+n*18]=a*(-0.5-1)
YOut[4+n*18]=-a*1/2*tan(30*pi/180)
XOut[5+n*18]=nan
YOut[5+n*18]=nan

XOut[6+n*18]=a*(-0.5-1)
YOut[6+n*18]=a*1/2*tan(30*pi/180)
XOut[7+n*18]=a*(0-1)
YOut[7+n*18]=a*1/2/cos(30*pi/180)
XOut[8+n*18]=nan
YOut[8+n*18]=nan

XOut[9+n*18]=a*(-0.5-1)
YOut[9+n*18]=-a*1/2*tan(30*pi/180)
XOut[10+n*18]=a*(0-1)
YOut[10+n*18]=-a*1/2/cos(30*pi/180)
XOut[11+n*18]=nan
YOut[11+n*18]=nan

XOut[12+n*18]=a*(0.5-1)
YOut[12+n*18]=-a*1/2*tan(30*pi/180)
XOut[13+n*18]=a*(0-1)
YOut[13+n*18]=-a*1/2/cos(30*pi/180)
XOut[14+n*18]=nan
YOut[14+n*18]=nan

XOut[15+n*18]=a*(0.5-1)
YOut[15+n*18]=a*1/2*tan(30*pi/180)
XOut[16+n*18]=a*(0-1)
YOut[16+n*18]=a*1/2/cos(30*pi/180)
XOut[17+n*18]=nan
YOut[17+n*18]=nan

n=3

XOut[0+n*18]=a*(0.5+0.5)
YOut[0+n*18]=a*(1/2*tan(30*pi/180)+1/2*tan(60*pi/180))
XOut[1+n*18]=a*(0.5+0.5)
YOut[1+n*18]=a*(-1/2*tan(30*pi/180)+1/2*tan(60*pi/180))
XOut[2+n*18]=nan
YOut[2+n*18]=nan

XOut[3+n*18]=a*(-0.5+0.5)
YOut[3+n*18]=a*(1/2*tan(30*pi/180)+1/2*tan(60*pi/180))
XOut[4+n*18]=a*(-0.5+0.5)
YOut[4+n*18]=a*(-1/2*tan(30*pi/180)+1/2*tan(60*pi/180))
XOut[5+n*18]=nan
YOut[5+n*18]=nan

XOut[6+n*18]=a*(-0.5+0.5)
YOut[6+n*18]=a*(1/2*tan(30*pi/180)+1/2*tan(60*pi/180))
XOut[7+n*18]=a*(0+0.5)
YOut[7+n*18]=a*(1/2/cos(30*pi/180)+1/2*tan(60*pi/180))
XOut[8+n*18]=nan
YOut[8+n*18]=nan

XOut[9+n*18]=a*(-0.5+0.5)
YOut[9+n*18]=a*(-1/2*tan(30*pi/180)+1/2*tan(60*pi/180))
XOut[10+n*18]=a*(0+0.5)
YOut[10+n*18]=a*(-1/2/cos(30*pi/180)+1/2*tan(60*pi/180))
XOut[11+n*18]=nan
YOut[11+n*18]=nan

XOut[12+n*18]=a*(0.5+0.5)
YOut[12+n*18]=a*(-1/2*tan(30*pi/180)+1/2*tan(60*pi/180))
XOut[13+n*18]=a*(0+0.5)
YOut[13+n*18]=a*(-1/2/cos(30*pi/180)+1/2*tan(60*pi/180))
XOut[14+n*18]=nan
YOut[14+n*18]=nan

XOut[15+n*18]=a*(0.5+0.5)
YOut[15+n*18]=a*(1/2*tan(30*pi/180)+1/2*tan(60*pi/180))
XOut[16+n*18]=a*(0+0.5)
YOut[16+n*18]=a*(1/2/cos(30*pi/180)+1/2*tan(60*pi/180))
XOut[17+n*18]=nan
YOut[17+n*18]=nan

n=4

XOut[0+n*18]=a*(0.5-0.5)
YOut[0+n*18]=a*(1/2*tan(30*pi/180)+1/2*tan(60*pi/180))
XOut[1+n*18]=a*(0.5-0.5)
YOut[1+n*18]=a*(-1/2*tan(30*pi/180)+1/2*tan(60*pi/180))
XOut[2+n*18]=nan
YOut[2+n*18]=nan

XOut[3+n*18]=a*(-0.5-0.5)
YOut[3+n*18]=a*(1/2*tan(30*pi/180)+1/2*tan(60*pi/180))
XOut[4+n*18]=a*(-0.5-0.5)
YOut[4+n*18]=a*(-1/2*tan(30*pi/180)+1/2*tan(60*pi/180))
XOut[5+n*18]=nan
YOut[5+n*18]=nan

XOut[6+n*18]=a*(-0.5-0.5)
YOut[6+n*18]=a*(1/2*tan(30*pi/180)+1/2*tan(60*pi/180))
XOut[7+n*18]=a*(0-0.5)
YOut[7+n*18]=a*(1/2/cos(30*pi/180)+1/2*tan(60*pi/180))
XOut[8+n*18]=nan
YOut[8+n*18]=nan

XOut[9+n*18]=a*(-0.5-0.5)
YOut[9+n*18]=a*(-1/2*tan(30*pi/180)+1/2*tan(60*pi/180))
XOut[10+n*18]=a*(0-0.5)
YOut[10+n*18]=a*(-1/2/cos(30*pi/180)+1/2*tan(60*pi/180))
XOut[11+n*18]=nan
YOut[11+n*18]=nan

XOut[12+n*18]=a*(0.5-0.5)
YOut[12+n*18]=a*(-1/2*tan(30*pi/180)+1/2*tan(60*pi/180))
XOut[13+n*18]=a*(0-0.5)
YOut[13+n*18]=a*(-1/2/cos(30*pi/180)+1/2*tan(60*pi/180))
XOut[14+n*18]=nan
YOut[14+n*18]=nan

XOut[15+n*18]=a*(0.5-0.5)
YOut[15+n*18]=a*(1/2*tan(30*pi/180)+1/2*tan(60*pi/180))
XOut[16+n*18]=a*(0-0.5)
YOut[16+n*18]=a*(1/2/cos(30*pi/180)+1/2*tan(60*pi/180))
XOut[17+n*18]=nan
YOut[17+n*18]=nan

n=5

XOut[0+n*18]=a*(0.5+0.5)
YOut[0+n*18]=a*(1/2*tan(30*pi/180)-1/2*tan(60*pi/180))
XOut[1+n*18]=a*(0.5+0.5)
YOut[1+n*18]=a*(-1/2*tan(30*pi/180)-1/2*tan(60*pi/180))
XOut[2+n*18]=nan
YOut[2+n*18]=nan

XOut[3+n*18]=a*(-0.5+0.5)
YOut[3+n*18]=a*(1/2*tan(30*pi/180)-1/2*tan(60*pi/180))
XOut[4+n*18]=a*(-0.5+0.5)
YOut[4+n*18]=a*(-1/2*tan(30*pi/180)-1/2*tan(60*pi/180))
XOut[5+n*18]=nan
YOut[5+n*18]=nan

XOut[6+n*18]=a*(-0.5+0.5)
YOut[6+n*18]=a*(1/2*tan(30*pi/180)-1/2*tan(60*pi/180))
XOut[7+n*18]=a*(0+0.5)
YOut[7+n*18]=a*(1/2/cos(30*pi/180)-1/2*tan(60*pi/180))
XOut[8+n*18]=nan
YOut[8+n*18]=nan

XOut[9+n*18]=a*(-0.5+0.5)
YOut[9+n*18]=a*(-1/2*tan(30*pi/180)-1/2*tan(60*pi/180))
XOut[10+n*18]=a*(0+0.5)
YOut[10+n*18]=a*(-1/2/cos(30*pi/180)-1/2*tan(60*pi/180))
XOut[11+n*18]=nan
YOut[11+n*18]=nan

XOut[12+n*18]=a*(0.5+0.5)
YOut[12+n*18]=a*(-1/2*tan(30*pi/180)-1/2*tan(60*pi/180))
XOut[13+n*18]=a*(0+0.5)
YOut[13+n*18]=a*(-1/2/cos(30*pi/180)-1/2*tan(60*pi/180))
XOut[14+n*18]=nan
YOut[14+n*18]=nan

XOut[15+n*18]=a*(0.5+0.5)
YOut[15+n*18]=a*(1/2*tan(30*pi/180)-1/2*tan(60*pi/180))
XOut[16+n*18]=a*(0+0.5)
YOut[16+n*18]=a*(1/2/cos(30*pi/180)-1/2*tan(60*pi/180))
XOut[17+n*18]=nan
YOut[17+n*18]=nan

n=6

XOut[0+n*18]=a*(0.5-0.5)
YOut[0+n*18]=a*(1/2*tan(30*pi/180)-1/2*tan(60*pi/180))
XOut[1+n*18]=a*(0.5-0.5)
YOut[1+n*18]=a*(-1/2*tan(30*pi/180)-1/2*tan(60*pi/180))
XOut[2+n*18]=nan
YOut[2+n*18]=nan

XOut[3+n*18]=a*(-0.5-0.5)
YOut[3+n*18]=a*(1/2*tan(30*pi/180)-1/2*tan(60*pi/180))
XOut[4+n*18]=a*(-0.5-0.5)
YOut[4+n*18]=a*(-1/2*tan(30*pi/180)-1/2*tan(60*pi/180))
XOut[5+n*18]=nan
YOut[5+n*18]=nan

XOut[6+n*18]=a*(-0.5-0.5)
YOut[6+n*18]=a*(1/2*tan(30*pi/180)-1/2*tan(60*pi/180))
XOut[7+n*18]=a*(0-0.5)
YOut[7+n*18]=a*(1/2/cos(30*pi/180)-1/2*tan(60*pi/180))
XOut[8+n*18]=nan
YOut[8+n*18]=nan

XOut[9+n*18]=a*(-0.5-0.5)
YOut[9+n*18]=a*(-1/2*tan(30*pi/180)-1/2*tan(60*pi/180))
XOut[10+n*18]=a*(0-0.5)
YOut[10+n*18]=a*(-1/2/cos(30*pi/180)-1/2*tan(60*pi/180))
XOut[11+n*18]=nan
YOut[11+n*18]=nan

XOut[12+n*18]=a*(0.5-0.5)
YOut[12+n*18]=a*(-1/2*tan(30*pi/180)-1/2*tan(60*pi/180))
XOut[13+n*18]=a*(0-0.5)
YOut[13+n*18]=a*(-1/2/cos(30*pi/180)-1/2*tan(60*pi/180))
XOut[14+n*18]=nan
YOut[14+n*18]=nan

XOut[15+n*18]=a*(0.5-0.5)
YOut[15+n*18]=a*(1/2*tan(30*pi/180)-1/2*tan(60*pi/180))
XOut[16+n*18]=a*(0-0.5)
YOut[16+n*18]=a*(1/2/cos(30*pi/180)-1/2*tan(60*pi/180))
XOut[17+n*18]=nan
YOut[17+n*18]=nan

Display YOut vs XOut

End
