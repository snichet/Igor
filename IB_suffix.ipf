#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function/S IB_suffix(str,suffix[,max_length,trim_start])
	
	// Add a suffix to a wave smartly, i.e. not exceeding the 31 character limit.
	//
	// Ilya
	// 18 March 2020

	String str, suffix
	Variable max_length, trim_start

	if (ParamIsDefault(max_length))
		max_length = 31 // max length for a wave name in IgorPro7
	endif
	
	if (ParamIsDefault(trim_start))
		trim_start = 10 // first character dropped
	endif

	String str_last = ParseFilePath(0, str, ":", 1, 0)
	String str_path = 	ParseFilePath(1, str, ":", 1, 0)

	Variable str_length = strlen(str_last)
	Variable suffix_length = strlen(suffix)

	Variable trim_length = str_length + suffix_length - max_length // number of chars that you have to remove

	String str_last_short
	if (trim_length <= 0)
		str_last_short = str_last + suffix
	else
		str_last_short = str_last[0,trim_start-1] + "ooo" + str_last[trim_start+trim_length+3,str_length-1] + suffix
	endif
	
	String str_out = str_path + str_last_short	
		
	Return str_out
	
End