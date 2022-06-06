#AutoIt3Wrapper_Au3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7
#cs ----------------------------------------------------------------------------

 AutoIt Version : 3.3.14.5
 Programme Version :
 Auteur:         OUTIN Yann
 Description du programme :
	<....>

#ce ----------------------------------------------------------------------------
#pragma compile(Icon, C:\Program Files (x86)\AutoIt3\Icons\au3.ico)
#include <Crypt.au3>
#include <File.au3>

Global $source = "D:\TEMP\v4\"
Global $target = "D:\TEMP\v4decrypt\"
Global $name = "FileSync"
Global $sFichierLog = @ScriptDir&"\decrypt.log"

_DecryptControl($source,$target,$name,True)

Func _DecryptControl($f_sSource,$f_sTarget,$f_sName,$f_bDebug = False)
    Local $f_aListFolderFiles = _FileListToArrayRec($f_sSource,"*",1,1,0,1)
    If Not IsArray($f_aListFolderFiles) Then Return SetError(1,0,"ERROR Le contenu de "&$f_sSource&" n'est pas valide")
    Local $f_bError = False
    Local $f_sPassword = ""
    Local $f_sPathSource = ""
    Local $f_sPathTarget = ""

    $f_sPassword = _GetPassword($f_sName)
    If @error Then Return SetError(1,0,$f_sPassword)
    If $f_bDebug Then ConsoleWrite("[Decrypt] Le mode de passe est : "&$f_sPassword&@CRLF)

    If $f_bDebug Then ConsoleWrite("[Decrypt] "&$f_sSource&" > "&$f_sTarget&@CRLF)
    $f_sPathSource = _ReformatPath($f_sSource)
    $f_sPathTarget = _ReformatPath($f_sTarget)

    If Not _IsFolder($f_sPathSource) Then Return SetError(2,0,"ERROR Le chemin "&$f_sPathSource&" n'est pas un dossier valide")
    If Not _IsFolder($f_sPathTarget) Then Return SetError(3,0,"ERROR Le chemin "&$f_sPathTarget&" n'est pas un dossier valide")

    For $i = 1 To $f_aListFolderFiles[0]
        If $f_bDebug Then ConsoleWrite("[Decrypt] Liste "&$i&" sur "&$f_aListFolderFiles[0]&" decryptage de  "&$f_sSource&$f_aListFolderFiles[$i]&@CRLF)
        If  Not _Crypt_DecryptFile($f_sSource&$f_aListFolderFiles[$i],$f_sTarget&$f_aListFolderFiles[$i] ,$f_sPassword , $CALG_AES_128) Then
           $f_bError = True
           If $f_bDebug Then
               ConsoleWrite("[Decrypt] ERROR decryptage code "&@error&" de  "&$f_sSource&$f_aListFolderFiles[$i]&@CRLF)
            Else
                _FileWriteLog($sFichierLog,"[Decrypt] ERROR decryptage code "&@error&" de  "&$f_sSource&$f_aListFolderFiles[$i])
            EndIf
        EndIf
    Next
    SetError(0)
    Return $f_bError
EndFunc

Func _GetPassword($f_sName)
    Local $f_aCred[3]
    $f_aCred = CredRead($f_sName)
    If Not IsArray($f_aCred) Then Return SetError(1,0,"[GetPassword] ERROR No credential found")
    SetError(0)
    Return $f_aCred[1]
EndFunc

Func CredRead($Target)
    Local $FuncRet[3]

    Local $targetName = DllStructCreate("wchar[100]")
    DllStructSetData($targetName,1,$Target)

    Local $hAdvapi32 = DllOpen("Advapi32.dll")
    Local $Ret = DllCall($hAdvapi32, 'bool', 'CredReadW', 'ptr', DllStructGetPtr($targetName), 'dword', 1, 'dword', 0, 'ptr*', 0)

    if $Ret[0]=0 then Return SetError(1,0,$FuncRet)

    Local $structCREDENTIAL= "" & _
        "DWORD Flags;" & _
        "DWORD Type;"  & _
        "Ptr TargetName;" & _
        "Ptr Comment;" & _
        "UINT64 LastWritten;" & _
        "DWORD CredintialBlobSize;" & _
        "Ptr CredentialBlob;" & _
        "DWORD Persist;" & _
        "DWORD AttributeCount;" & _
        "Ptr Attributes;" & _
        "Ptr TargetAlias;" & _
        "Ptr Username"

    Local $tdata=DllStructCreate($structCREDENTIAL, $Ret[4])

    Local $userName = DllStructCreate("wchar[100]", DllStructGetData($tdata, 'Username'))
    Local $User = DllStructGetData($userName, 1)

    Local $CredentialBlobSize = DllStructGetData($tdata, 'CredintialBlobSize')
    Local $credentialBlob = DllStructCreate("wchar[100]", DllStructGetData($tdata, 'CredentialBlob'))
    Local $Password = StringLeft(DllStructGetData($credentialBlob, 1), $CredentialBlobSize/2)

    Local $Comment = DllStructCreate("wchar[100]", DllStructGetData($tdata, 'Comment'))
    Local $Comm = DllStructGetData($Comment, 1)

    Dim $FuncRet[] = [$User, $Password, $Comm]
	SetError(0)
    Return $FuncRet
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
