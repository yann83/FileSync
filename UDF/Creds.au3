#include-once

Func _GetPassword($f_sName)
    Local $f_aCred[3]
    $f_aCred = CredRead($f_sName)
    If Not IsArray($f_aCred) Then Return SetError(1,0,"[GetPassword] ERROR No credential found [CredRead] return "&@error)
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


Func CredDelete($Target)
    Local $targetName = DllStructCreate("wchar[100]")
    DllStructSetData($targetName,1,$Target)

    Local $hAdvapi32 = DllOpen("Advapi32.dll")
    DllCall($hAdvapi32, 'bool', 'CredDeleteW', 'ptr', DllStructGetPtr($targetName), 'dword', 1, 'dword', 0)
	Return(1)
EndFunc

Func CredWrite($Target, $User, $Password, $Comm)
    Local $targetName = DllStructCreate("wchar[100]")
    DllStructSetData($targetName,1,$Target)

    Local $userName = DllStructCreate("wchar[100]")
    DllStructSetData($userName,1,$User)

    Local $credentialBlob = DllStructCreate("wchar[100]")
    DllStructSetData($credentialBlob,1,$Password)

    Local $Comment = DllStructCreate("wchar[100]")
    DllStructSetData($Comment,1,$Comm)

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
        "ptr Attributes;" & _
        "Ptr TargetAlias;" & _
        "Ptr Username"

    Local $NewCred = DllStructCreate($structCREDENTIAL)
    If @error Then Return SetError(1, 0, "Error in DllStructCreate " & @error);

    DllStructSetData($NewCred,"Flags",0)
    DllStructSetData($NewCred,"Type",1)
    DllStructSetData($NewCred,"TargetName",DllStructGetPtr($targetName))
    DllStructSetData($NewCred,"Persist",3)
    DllStructSetData($NewCred,"AttributeCount",0)
    DllStructSetData($NewCred,"UserName",DllStructGetPtr($userName))
    DllStructSetData($NewCred,"CredentialBlob",DllStructGetPtr($credentialBlob))
    DllStructSetData($NewCred,"CredintialBlobSize",StringLen($Password)*2)
    DllStructSetData($NewCred,"Comment",DllStructGetPtr($Comment))

    Local $hAdvapi32 = DllOpen("Advapi32.dll")
    If @error Then
        Msgbox (0,"Error","Cannot open Advapi32.dll")
        Exit
    Endif
    DllCall($hAdvapi32, 'bool', 'CredWriteW', 'ptr', DllStructGetPtr($NewCred), 'dword', 0)
    $NewCred = 0
	SetError(0)
	Return(1)
EndFunc
