#AutoIt3Wrapper_Au3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7
#cs ----------------------------------------------------------------------------

 AutoIt Version : 3.3.14.5
 Programme Version :
 Auteur:
 Description du programme :
	<....>
Petit fichier - MD5 = 25.2496
Petit fichier - CRC32 = 6.7427
Petit fichier - time = 0.1231
Petit fichier - size = 0.1
##############################################
Gros fichier - MD5 = 1369.9203
Gros fichier - CRC32 = 440.8074
Gros fichier - time = 0.1247
Gros fichier - size = 0.0668
#ce ----------------------------------------------------------------------------
#pragma compile(Icon, C:\Program Files (x86)\AutoIt3\Icons\au3.ico)
#include <Timers.au3>
#include <Crypt.au3>

Global $File1 = ""
Global $File2 = ""

Global $iStartTime,$dHash

$iStartTime = _Timer_Init()
$dHash = _Crypt_HashFile($File1, $CALG_MD5)
ConsoleWrite("Petit fichier - MD5 = "&_Timer_Diff($iStartTime)&@CRLF)

$iStartTime = _Timer_Init()
$dHash = _CRC32ForFile($File1)
ConsoleWrite("Petit fichier - CRC32 = "&_Timer_Diff($iStartTime)&@CRLF)

$iStartTime = _Timer_Init()
$dHash = FileGetTime($File1,0,1)
ConsoleWrite("Petit fichier - time = "&_Timer_Diff($iStartTime)&@CRLF)

$iStartTime = _Timer_Init()
$dHash = FileGetSize($File1)
ConsoleWrite("Petit fichier - size = "&_Timer_Diff($iStartTime)&@CRLF)

ConsoleWrite("##############################################"&@CRLF)

$iStartTime = _Timer_Init()
$dHash = _Crypt_HashFile($File2, $CALG_MD5)
ConsoleWrite("Gros fichier - MD5 = "&_Timer_Diff($iStartTime)&@CRLF)

$iStartTime = _Timer_Init()
$dHash = _CRC32ForFile($File2)
ConsoleWrite("Gros fichier - CRC32 = "&_Timer_Diff($iStartTime)&@CRLF)

$iStartTime = _Timer_Init()
$dHash = FileGetTime($File2,0,1)
ConsoleWrite("Gros fichier - time = "&_Timer_Diff($iStartTime)&@CRLF)

$iStartTime = _Timer_Init()
$dHash = FileGetSize($File2)
ConsoleWrite("Gros fichier - size = "&_Timer_Diff($iStartTime)&@CRLF)


; #FUNCTION# ;===============================================================================
;
; Name...........: _CRC32ForFile
; Description ...: Calculates CRC32 value for the specific file.
; Syntax.........: _CRC32ForFile ($sFile)
; Parameters ....: $sFile - Full path to the file to process.
; Return values .: Success - Returns CRC32 value in form of hex string
;                          - Sets @error to 0
;                  Failure - Returns empty string and sets @error:
;                  |1 - CreateFile function or call to it failed.
;                  |2 - CreateFileMapping function or call to it failed.
;                  |3 - MapViewOfFile function or call to it failed.
;                  |4 - RtlComputeCrc32 function or call to it failed.
; Author ........: trancexx
;
;==========================================================================================
Func _CRC32ForFile($sFile)

    Local $a_hCall = DllCall("kernel32.dll", "hwnd", "CreateFileW", _
            "wstr", $sFile, _
            "dword", 0x80000000, _ ; GENERIC_READ
            "dword", 3, _ ; FILE_SHARE_READ|FILE_SHARE_WRITE
            "ptr", 0, _
            "dword", 3, _ ; OPEN_EXISTING
            "dword", 0, _ ; SECURITY_ANONYMOUS
            "ptr", 0)

    If @error Or $a_hCall[0] = -1 Then
        Return SetError(1, 0, "")
    EndIf

    Local $hFile = $a_hCall[0]

    $a_hCall = DllCall("kernel32.dll", "ptr", "CreateFileMappingW", _
            "hwnd", $hFile, _
            "dword", 0, _ ; default security descriptor
            "dword", 2, _ ; PAGE_READONLY
            "dword", 0, _
            "dword", 0, _
            "ptr", 0)

    If @error Or Not $a_hCall[0] Then
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFile)
        Return SetError(2, 0, "")
    EndIf

    DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFile)

    Local $hFileMappingObject = $a_hCall[0]

    $a_hCall = DllCall("kernel32.dll", "ptr", "MapViewOfFile", _
            "hwnd", $hFileMappingObject, _
            "dword", 4, _ ; FILE_MAP_READ
            "dword", 0, _
            "dword", 0, _
            "dword", 0)

    If @error Or Not $a_hCall[0] Then
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)
        Return SetError(3, 0, "")
    EndIf

    Local $pFile = $a_hCall[0]
    Local $iBufferSize = FileGetSize($sFile)

    Local $a_iCall = DllCall("ntdll.dll", "dword", "RtlComputeCrc32", _
            "dword", 0, _
            "ptr", $pFile, _
            "int", $iBufferSize)

    If @error Or Not $a_iCall[0] Then
        DllCall("kernel32.dll", "int", "UnmapViewOfFile", "ptr", $pFile)
        DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)
        Return SetError(4, 0, "")
    EndIf

    DllCall("kernel32.dll", "int", "UnmapViewOfFile", "ptr", $pFile)
    DllCall("kernel32.dll", "int", "CloseHandle", "hwnd", $hFileMappingObject)

    Local $iCRC32 = $a_iCall[0]

    Return SetError(0, 0, Hex($iCRC32))

EndFunc   ;==>_CRC32ForFile
