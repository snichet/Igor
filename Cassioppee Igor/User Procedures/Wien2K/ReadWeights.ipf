#pragma rtGlobals=1		// Use modern global access method.


Proc MakeTableWeight()
// For one point of one band, calculates the weight of all characters listed below
string RootName=""
string Waveweight="Weight14"
variable num=45

string nameOut,OrbitalName
Make/O/N=1 toto

//OrbitalName="Alld"
//toto[0]= ReadWeight(RootName,WaveWeight,OrbitalName,num)
//nameOut=name+OrbitalName
//Duplicate/O toto $nameOut

OrbitalName="dz2"
toto[0]= ReadWeight(RootName,WaveWeight,OrbitalName,num)
nameOut=Waveweight+"_"+num2str(num)+"_"+OrbitalName
Duplicate/O toto $nameOut

OrbitalName="dx2my2"
toto[0]= ReadWeight(RootName,WaveWeight,OrbitalName,num)
nameOut=Waveweight+"_"+num2str(num)+"_"+OrbitalName
Duplicate/O toto $nameOut

OrbitalName="dxy"
toto[0]= ReadWeight(RootName,WaveWeight,OrbitalName,num)
nameOut=Waveweight+"_"+num2str(num)+"_"+OrbitalName
Duplicate/O toto $nameOut

OrbitalName="dxz"
toto[0]= ReadWeight(RootName,WaveWeight,OrbitalName,num)
nameOut=Waveweight+"_"+num2str(num)+"_"+OrbitalName
Duplicate/O toto $nameOut

OrbitalName="dyz"
toto[0]= ReadWeight(RootName,WaveWeight,OrbitalName,num)
nameOut=Waveweight+"_"+num2str(num)+"_"+OrbitalName
Duplicate/O toto $nameOut

end

Function ReadWeight(RootName,WaveWeight,OrbitalName,num)
string RootName,WaveWeight,OrbitalName
variable num
string FolderName,NameOut
//returns num point of wave "WaveWeight" in folder RootName+":"+OrbitalName+":"
// Par exemple RootName="Fe1_" et OrbitalName="dz2"

FolderName=RootName+":"+OrbitalName+":"
Duplicate/O  $FolderName+WaveWeight totoband
return totoband[num]

Killwaves totoband
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Proc MakeTableWeight_pedestre()
string name="band13_45"
string nameOut

Make/O/N=1 toto

toto[0]=:Fe1_Alld:weight13[45]
nameOut=name+"Fe1_Alld"
Duplicate/O toto $nameOut

toto[0]=:Fe1_dz2:weight13[45]
nameOut=name+"Fe1_dz2"
Duplicate/O toto $nameOut

toto[0]=:Fe1_dx2my2:weight13[45]
nameOut=name+"Fe1_dx2my2"
Duplicate/O toto $nameOut

toto[0]=:Fe1_dxy:weight13[45]
nameOut=name+"Fe1_dxy"
Duplicate/O toto $nameOut

toto[0]=:Fe1_dxz:weight13[45]
nameOut=name+"Fe1_dxz"
Duplicate/O toto $nameOut

toto[0]=:Fe1_dyz:weight13[45]
nameOut=name+"Fe1_dyz"
Duplicate/O toto $nameOut

//

toto[0]=:Fe2_Alld:weight13[45]
nameOut=name+"Fe2_Alld"
Duplicate/O toto $nameOut

toto[0]=:Fe2_dz2:weight13[45]
nameOut=name+"Fe2_dz2"
Duplicate/O toto $nameOut


toto[0]=:Fe2_dx2my2:weight13[45]
nameOut=name+"Fe2_dx2my2"
Duplicate/O toto $nameOut

toto[0]=:Fe2_dxy:weight13[45]
nameOut=name+"Fe2_dxy"
Duplicate/O toto $nameOut

toto[0]=:Fe2_dxz:weight13[45]
nameOut=name+"Fe2_dxz"
Duplicate/O toto $nameOut

toto[0]=:Fe2_dyz:weight13[45]
nameOut=name+"Fe2_dyz"
Duplicate/O toto $nameOut

end
