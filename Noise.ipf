#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function MakeNoise()
	Make/b/o/n=(50000/4) sound
	setscale /p x,0,1e-4,sound
	sound[0,2499]=100*sin(2*pi*600*x)*sin(20*x)+100*sin(2*pi*1200*x)*cos(20*x)
	sound[2500,4999]=100*sin(2*pi*650*x)*sin(20*x)+100*sin(2*pi*1300*x)*cos(20*x)
	sound[5000,7499]=100*sin(2*pi*600*x)*sin(20*x)+100*sin(2*pi*1200*x)*cos(20*x)
	sound[7500,9999]=100*sin(2*pi*550*x)*sin(20*x)+100*sin(2*pi*1100*x)*cos(20*x)
	sound[10000,12499]=100*sin(2*pi*150*x)*sin(20*x)+100*sin(2*pi*300*x)*cos(20*x)
	playsound sound
End