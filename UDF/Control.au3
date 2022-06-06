#include-once

Func _Crypt_EncryptFileControl($f_sSource,$f_sTarget,$f_sPassword)
    If FileExists($f_sTarget) Then FileDelete($f_sTarget)
    If Not _Crypt_EncryptFile($f_sSource, $f_sTarget,$f_sPassword , $CALG_AES_128) Then Return SetError(1,0,"[Crypt_EncryptFileControl] ERROR code "&@error&"from "&$f_sSource&" to "&$f_sTarget)
    SetError(0)
    Return True
EndFunc

Func _FileCopyControl($f_sSource,$f_sTarget)
    If Not FileCopy($f_sSource,$f_sTarget ,9) Then Return SetError(1,0,"[FileCopyControl] ERROR copy from "&$f_sSource&" to "&$f_sTarget)
    SetError(0)
    Return True
EndFunc

Func _FileDeleteControl($f_sSource)
    If Not FileDelete($f_sSource) Then Return SetError(1,0,"[FileDeleteControl] ERROR delete  : "&$f_sSource)
    SetError(0)
    Return True
EndFunc

Func _DecryptControl($f_sSource,$f_sTarget,$f_sForcePassword,$f_sName)
    Local $f_aListFolderFiles = _FileListToArrayRec($f_sSource,"*",1,1,0,1)
    If Not IsArray($f_aListFolderFiles) Then Return SetError(1,0,"[Decrypt] ERROR invalid content for "&$f_sSource)
    Local $f_sPassword = ""
    Local $f_sPathSource = ""
    Local $f_sPathTarget = ""
    Local $f_aArray[1]
    $f_aArray[0] = 0

    If $f_sForcePassword <> "" Then
        $f_sPassword = $f_sForcePassword
    Else
        $f_sPassword = _GetPassword($f_sName)
        If @error Then Return SetError(2,0,$f_sPassword)
    EndIf

    $f_sPathSource = _ReformatPath($f_sSource)
    $f_sPathTarget = _ReformatPath($f_sTarget)

    If Not _IsFolder($f_sPathSource) Then Return SetError(3,0,"[Decrypt] ERROR invalid source path : "&$f_sPathSource&" not a folder")
    If Not _IsFolder($f_sPathTarget) Then Return SetError(4,0,"[Decrypt] ERROR invalid target path : "&$f_sPathTarget&" not a folder")

    For $i = 1 To $f_aListFolderFiles[0]
        If  Not _Crypt_DecryptFile($f_sSource&$f_aListFolderFiles[$i],$f_sTarget&$f_aListFolderFiles[$i] ,$f_sPassword , $CALG_AES_128) Then
            _ArrayAdd($f_aArray,"[Decrypt] ERROR loop at "&$i&" / "&$f_aListFolderFiles[0]&" for this file : "&$f_aListFolderFiles[$i]&" with code "&@error)
            $f_aArray[0] += 1
        EndIf
    Next
    If $f_aArray[0] > 0 Then Return $f_aArray
    SetError(0)
    Return True
EndFunc
