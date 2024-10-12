#pragma rtGlobals=1		// Use modern global access method.

#include "LPS_LoadTextFiles"
#include "LPS_ProcessImages"
#include "LPS_ImageTool3"
#include "LPS_Stacks"
#include "LPS_VB_3DTools"
#include "LPS_Fitting_MDC"
#include "LPS_Fitting_EDC"
#include "LPS_SubtractRes"
#include "LPS_ThetaPhi_conversions"
#include "LPS_ImageMakeUp"


menu "ARPES"
	
	//From Image_Tool
	"Image Tool", ShowImageTool()
	//"Image Process", ImgProcessMenu()
	//"Multiple stacks", AddToStacks()    // In procedure MultipleStacks
	"-"
	
	//For loading and processing original images
	"Process Images of one folder", Build_ProcessImage_Panel() //From ProcessImages
	"Find Ef for energy scans",FindEf()
	"Process 3D wave", Build_ProcessImage_Panel3D() //From ProcessImages
	//"Set parameters for current folder",Folder_SetParameters()//From ProcessImages
	//"Correct bad pixel",Correct_badpixel()  //From ProcessImages
	//"Correct N successive bad pixels",Correct_Nbadpixel()  //From ProcessImages
	//From VB_3DTools
	"Window Plot of 3D wave", Load3DImage_menu()   // tmp_3D already exists
	"EDC map",EDCmap3()
	//"Make 3D wave",Smart3DWave_FromMenu()
	//"Compile 3D wave",Compile()
//	"CorrectMap",Correct_Map()
	"-"
	//From Fitting_MDC_Window
	"MDC analysis", InitWindow()
	"EDC analysis", Init_EDCWindow()
	"Center of mass [1D wave]",CenterMass()
	"Half width at half maximum [1D wave]",HWHM()
	//"Export line from ImageTool",Export_line(" ")
	//"Normalize by Vf",NormalizeByVf(" ")
	//"Symmetrize image [k vs E]",SymmetrizeImage()
	//"Substract background from EDC",	Substract_EDCBgd_fromPannel(" ")//in Fitting_EDC
	//"Extract max from EDC",	Save_disp(" ")//in Fitting_EDC
	//"Add wave to stacks", AskAddWave()// in Stacks
	"-"
	//From ThetaPhi_conversions (all in this procedure)
	"Draw cuts of reciprocal space",GraphForCuts() 
	"Convert one point [theta,tilt,phi] ",Transform_point()  
	"Convert one list of points [theta,tilt,phi]",Transform_List()
	"Convert one dispersion ",Transform_disp()
	"Convert one image ",Ask_Transform_image_true(0)
end


menu "Make-up"
	"Image Make-up window", ImgProcessMenu()
	"Arrange Graph", ArrangeGraph()
	"-"
	"Rotate an image",RotationFromMenu()
	"Add dispersion",AddDisp()
	"Transpose", DoTranspose()
	"Second derivative vs E",DoSecondDerivativeE()
	"Second derivative vs k",DoSecondDerivativek()
	"Divide 3D wave by Fermi",DivideByTemp()
	//"Symmetrize",Img_Symmetrize(" ")
	"-"
	"Scaling", Img_Scale(" ")// In ImageMakeUp
	"Shift",Img_Shift()
	"Make-up pannel", MakeUpPannel(" ")// In ImageMakeUp
	"Interpolate 2D image",ImgPannel_interpolate2D(" ")
	//"Convolute", MyConvolution()
	//"-"
	//"Linear",Interp_linear()
	//"Interpolate by average value in rectangle",SquareAvgStart()
	//"Interpolate NaN points",InterpolateNaNpoints()
	//"Contour Image",ImgFromContour()
	//"Show rectangle n * m ",DefineRectangle()
	//"-"
	//"Igor average",IgorAvg()
	//"-"
	"-"
	"Rotate two X and Y waves",Ask_WaveRotation()
	"Center 2 symmetric dispersions at zero",Center_disp()
	"-"
	"Undo ",Img_undo(" ")
end
