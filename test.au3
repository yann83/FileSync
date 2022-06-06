#AutoIt3Wrapper_Au3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7
#cs ----------------------------------------------------------------------------

 AutoIt Version : 3.3.14.5
 Programme Version :
 Auteur:
 Description du programme :
	<....>

#ce ----------------------------------------------------------------------------
#pragma compile(Icon, C:\Program Files (x86)\AutoIt3\Icons\au3.ico)

#include <Array.au3>

Global $aTest[16]
$aTest[0] = 15
$aTest[1] = "fdfsdfsfsdfsf"
$aTest[2] = "qfqdgqsgsdf"

Global $f_sRowsToDelete,$f_nCountDelete

For $k = 1 To $aTest[0]
    If $aTest[$k] = "" Then
        $f_sRowsToDelete &= $k&";"
        $f_nCountDelete += 1
    EndIf
Next
_ArrayDisplay($aTest)
If $aTest[0] > 0 And $f_sRowsToDelete <> "" Then
    $f_sRowsToDelete = StringTrimRight($f_sRowsToDelete,1)
    ConsoleWrite($f_sRowsToDelete&@CRLF)
     ;##########################################################
    _ArrayDelete($aTest,$f_sRowsToDelete)
    ConsoleWrite(@error&@CRLF)
     ;########################################################
     $aTest[0] -= $f_nCountDelete
EndIf
_ArrayDisplay($aTest)

