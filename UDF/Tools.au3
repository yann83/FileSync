#include-once

Func _CheckIfExist($f_sJobName,$f_sFichierIni)
    Local $f_aGetJobsList = IniReadSectionNames($f_sFichierIni)
    If @error Then Return False
    For $i = 1 To $f_aGetJobsList[0]
        If $f_aGetJobsList[$i] = $f_sJobName Then Return True
    Next
    Return False
EndFunc

Func _CheckBool($f_sData)
    If StringLower($f_sData) = "true" Then Return "true"
    Return "false"
EndFunc

Func _ReformatPath($f_sData)
    Local $f_bIsFolder = _IsFolder($f_sData)
    If $f_bIsFolder Then
        If StringRight($f_sData,1) <> "\" Then $f_sData = $f_sData & "\"
    EndIf
    Return($f_sData)
EndFunc

Func _IsFolder($f_sPath)
   Local $f_iSize = 0
   #forceref $f_iSize
    $f_iSize = DirGetSize($f_sPath, 2)
    If @error Then Return False
    Return True
EndFunc

Func _CheckFiles($f_sSource,$f_aData)
    Local $f_iSizeFile
    Local $f_aResult[1][3]
    $f_aResult[0][0] = $f_aData[0]
    For $i = 1 To $f_aData[0]
        $f_iSizeFile = FileGetSize($f_sSource&$f_aData[$i])
        _ArrayAdd($f_aResult,$f_aData[$i]&"|"&$f_iSizeFile)
    Next
    Return $f_aResult
EndFunc

Func _ErrorArray($f_aArray,$f_data)
    If IsArray($f_aArray) Then
        _ArrayAdd($f_aArray,$f_data)
        $f_aArray[0] += 1
    Else
        Local $f_aArray[2]
        $f_aArray[0] = 1
        $f_aArray[1] = "[ErrorArray] ERROR function"
    EndIf
    Return $f_aArray
EndFunc

Func _GetfileName($f_sSource)
    Local $f_sFileName = StringRegExpReplace($f_sSource, "^.*\\", "")
    Return $f_sFileName
EndFunc

Func _GetPath($f_sSource)
    Local $f_sPath = StringRegExpReplace($f_sSource, "(^.*\\)(.*)", "\1")
    Return $f_sPath
EndFunc

Func _Log($f_sFile,$f_data,$f_bConsole = False,$f_bExit = False)
    If $f_bConsole Then
        ConsoleWrite($f_data&@CRLF)
    Else
        _FileWriteLog($f_sFile,$f_data)
    EndIf
    If $f_bExit Then Exit
EndFunc
