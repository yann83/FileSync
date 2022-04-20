#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=FileSync.exe
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Fileversion=0.1b
#AutoIt3Wrapper_AU3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version : 3.3.14.5
 Programme Version :
 Auteur:         Yann83
 Description du programme :
	<....>

#ce ----------------------------------------------------------------------------
#pragma compile(Icon, C:\Applications\AutoIt3\Icons\au3.ico)
#include <File.au3>
#include <Crypt.au3>
#include <Array.au3>
#include <SQLite.au3>
#include <SQLite.dll.au3>

Global $sProgName =  StringTrimRight(@ScriptName,4)
Global $sFichierIni = @ScriptDir &"\"&$sProgName& ".ini"
If Not FileExists($sFichierIni) Then _FileCreate($sFichierIni)
Global $sFichierLog = @ScriptDir &"\"&$sProgName& ".log"
Global $SQLDll = @ScriptDir&"\Dlls\SQLite3.dll"
If @AutoItX64 Then $SQLDll = @ScriptDir&"\Dlls\SQLite3_x64.dll"
Global $sCredName = $sProgName

Global $aJobs[1]
Global $Ret

Global $Debug = False

If $CmdLine[0] > 0 Then
    Switch $CmdLine[1]

        Case "-password"
            If $CmdLine[0] > 1 Then
                $Ret = CredWrite($sCredName,@UserName,$CmdLine[2],"0")
                If $Ret = 1 Then
                    ConsoleWrite("Password registration successful."&@CRLF)
                Else
                    ConsoleWrite("Unable to register credential."&@CRLF)
                EndIf
                Exit
            Else
                ConsoleWrite("Enter a Password."&@CRLF)
                Exit
            EndIf

        Case "-removepassword"
            $Ret = CredDelete($sCredName)
            If $Ret = 1 Then
                ConsoleWrite("Password unregistration successful."&@CRLF)
            Else
                ConsoleWrite("Unable to remove credential."&@CRLF)
            EndIf
            Exit

        Case "-runall"
             $aJobs = IniReadSectionNames($sFichierIni)
            If @error Then
                ConsoleWrite($sFichierIni&" is invalid"&@CRLF)
            Else
                $Ret = _SyncFile($aJobs)
                If @error Then ConsoleWrite($Ret&@CRLF)
            EndIf
            Exit

        Case "-run"
            If $CmdLine[0] > 1 Then
                $aJobs[0] = 0
                For $i = 2 To $CmdLine[0]
                    _ArrayAdd($aJobs,$CmdLine[$i])
                    $aJobs[0] += 1
                Next
                $Ret = _SyncFile($aJobs)
                If @error Then ConsoleWrite($Ret&@CRLF)
                Exit
            Else
                ConsoleWrite("Select at least one job."&@CRLF)
                Exit
            EndIf

        Case "-addjob"
            If $CmdLine[0] > 4 Then
                If Not _CheckIfExist($CmdLine[2],$sFichierIni) Then
                    IniWrite($sFichierIni,$CmdLine[2],"source",_ReformatPath($CmdLine[3]))
                    IniWrite($sFichierIni,$CmdLine[2],"target",_ReformatPath($CmdLine[4]))
                    IniWrite($sFichierIni,$CmdLine[2],"encryption",_CheckBool($CmdLine[5]))
                    Exit
                Else
                   ConsoleWrite("Job already exist."&@CRLF)
                    Exit
                EndIf
            Else
                ConsoleWrite("Invalid parameters."&@CRLF)
                Exit
            EndIf

        Case "-deletejob"
            If $CmdLine[0] > 1 Then
                IniDelete($sFichierIni,$CmdLine[2])
                Exit
            Else
                ConsoleWrite("Invalid parameters."&@CRLF)
                Exit
            EndIf

        Case "-runmanager"
            Run(@ScriptDir&"\JobsManager.exe")
            Exit

        Case "-decrypt"
            If $CmdLine[0] > 2 Then
                If Not _Decrypt($CmdLine[2],$CmdLine[3]) Then ConsoleWrite("Error, some datas cannot be decrypt, see log for details."&@CRLF)
                Exit
            Else
                ConsoleWrite("Invalid parameters."&@CRLF)
                Exit
            EndIf

        Case "-?"
            ConsoleWrite("Commands list"&@CRLF)
            ConsoleWrite("Register a password with [-password] <your password>"&@CRLF)
            ConsoleWrite("Unregister a password with [-removepassword]"&@CRLF)
            ConsoleWrite("Add or edit a job [-addjob] <job name> <path to file or folder> <path to save folder> <encrypt yes or no>"&@CRLF)
            ConsoleWrite(". <job name> no space inside name"&@CRLF)
            ConsoleWrite(". <path to file or folder> if it's a folder add a \ at the end"&@CRLF)
            ConsoleWrite(". <path to save folder> add a \ at the end"&@CRLF)
            ConsoleWrite(". <encryption> false or true"&@CRLF)
            ConsoleWrite(". ex : -addjob MyJob C:\myfolder\ E:\mysavefolder\ true"&@CRLF)
            ConsoleWrite(". ex : -addjob MyJob C:\myfolder\myfile.txt E:\mysavefile\ false"&@CRLF)
            ConsoleWrite("Delete a job [-deletejob], ex : -deletejob MyJob"&@CRLF)
            ConsoleWrite("Run the jobs manager [-runmanager]"&@CRLF)
            ConsoleWrite("Run all jobs [-runall]"&@CRLF)
            ConsoleWrite("Run selected job(s) [-run] <job(s) name> no space inside name and one space to separate them, ex : -run SaveProfile"&@CRLF)
            ConsoleWrite("Decrypt one or more fildes [-decrypt] <path to crypted folder> <path to restore folder> , ex : -decrypt E:\mysavefolder\ C:\restore\"&@CRLF)
            ConsoleWrite(". <path to crypted folder> add a \ at the end"&@CRLF)
            ConsoleWrite(". <path to restore folder> add a \ at the end"&@CRLF)
            Exit

        Case Else
            ConsoleWrite("Use [-?] for help."&@CRLF)
            Exit
    EndSwitch
EndIf

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
    Local $f_bIsFolder = True
    Local $f_iSize = DirGetSize($f_sSource, 2)
    If @error Then $f_bIsFolder = False
    If $f_bIsFolder Then
        If StringRight($f_sData,1) <> "\" Then $f_sData = $f_sData & "\"
    EndIf
    Return($f_sData)
EndFunc

Func _SyncFile($f_aJob)
    Local $f_aProcessJob
    #forceref $f_aProcessJob
    Local $f_bEncrypt = False
    Local $f_bIsFolder = False
    Local $f_iSize = 0
    #forceref $f_iSize
    Local $f_aDiff
    Local $f_iStringLen = 0
    Local $f_sFileName,$f_sSource,$f_sSourceFinalPath,$f_sTarget
    Local $f_aCred[3]
    Local $f_aListFolderFiles
    Local $f_aErrors[2]
    $f_aErrors[0] = 0

    Local $f_sFichierData
    Local $f_aExtractDb
    Local $f_aCheckFiles
    Local $f_sRowsToDelete = ""
    Local $f_nCountDelete = 0

    For $i = 1 To $f_aJob[0]

        $f_aProcessJob = IniReadSection($sFichierIni,$f_aJob[$i])
        If @error Then $f_aErrors = _ErrorArray($f_aErrors,"Error in _SyncFile for reading section in "&$sFichierIni)

        $f_sFichierData = @ScriptDir &"\"&$f_aJob[$i]& ".db"

        $f_bEncrypt = False
        If IniRead($sFichierIni,$f_aJob[$i],"encryption","false") = "true" Then $f_bEncrypt = True

        $f_sSource = IniRead($sFichierIni,$f_aJob[$i],"source","")
        $f_sTarget = IniRead($sFichierIni,$f_aJob[$i],"target","")

         If FileExists($f_sSource) Then
            $f_bIsFolder = True
            $f_iSize = DirGetSize($f_sSource, 2)
            If @error Then $f_bIsFolder = False

            If $f_bIsFolder Then
                If StringRight($f_sSource,1) <> "\" Then $f_sSource = $f_sSource & "\"
                If StringRight($f_sTarget,1) <> "\" Then $f_sTarget = $f_sTarget & "\"
                $f_aListFolderFiles = _FileListToArrayRec($f_sSource,"*",1,1,0,1)
                If Not IsArray($f_aListFolderFiles) Then $f_aErrors = _ErrorArray($f_aErrors,"Error $f_aListFolderFiles")
            Else
                $f_sFileName = _GetfileName($f_sSource)
                Local $f_aListFolderFiles[2] = [1,$f_sFileName]
            EndIf
        Else
            $f_aErrors = _ErrorArray($f_aErrors,"Error Source : "&$f_sSource&" doesn't exist")
        EndIf

        ;_ArrayDisplay($f_aListFolderFiles)
        ;ContinueLoop

        ; partie ou on compare les fichiers
        If Not FileExists($f_sFichierData) Then ; on crée la db et on ajoute les données
            If Not $f_bIsFolder Then
                If Not _CreateStockData($SQLDll,$f_sFichierData,_GetPath($f_sSource),$f_aListFolderFiles) Then Return SetError(1,0,"Error [_CreateStockData] "&$f_sFichierData)
            Else
                If Not _CreateStockData($SQLDll,$f_sFichierData,$f_sSource,$f_aListFolderFiles) Then Return SetError(1,0,"Error [_CreateStockData] "&$f_sFichierData)
            EndIf
        Else ; on lit la db et on compare les données avec celles actuelle1309
            $f_aExtractDb = _ExtractDb($SQLDll,$f_sFichierData)
            If Not $f_bIsFolder Then
                $f_aCheckFiles = _CheckFiles(_GetPath($f_sSource),$f_aListFolderFiles)
            Else
                $f_aCheckFiles = _CheckFiles($f_sSource,$f_aListFolderFiles)
            EndIf
            ;_ArrayDisplay($f_aExtractDb)
            ;_ArrayDisplay($f_aCheckFiles)
            $f_aDiff = _ArrayDiff2D($f_aExtractDb,1,0,$f_aCheckFiles,1,0)
            #cs
            fichier DB                                      recherche
            col 0               1               2               3                   4           5
            160
            fichier             date    taille              fichier         date    taille      > identique
                                                                    nouveau fichier                  > ajout 1 fichier
            fichier2            date    4                   fichier2        date     6          > fichier diff a remplacer
            fichier3            date    taille                                                          > suppression 1 fichier

            1. on supprime les fichier supp dans target
            2. on extrait une table avec les nouveau fichiers et les diffs
            3. on recré la db avec la nouvelle base sans les fichiers supp
            #ce
            Local $f_bDbChange = False
            $f_nCountDelete = 0
            ;_ArrayDisplay($f_aDiff)
            ;1. on supprime les fichier supp dans target

            For $k = 1 To $f_aDiff[0][0]
                If $f_aDiff[$k][3] = "" Then
                    _FileDeleteControl($f_sTarget&$f_aDiff[$k][0],$Debug)
                    $f_sRowsToDelete &= $k&";"
                    $f_nCountDelete += 1
                EndIf
            Next
            If $f_sRowsToDelete <> "" Then
                $f_sRowsToDelete = StringTrimRight($f_sRowsToDelete,1)
                _ArrayDelete($f_aDiff,$f_sRowsToDelete)
                $f_aDiff[0][0] -= $f_nCountDelete
                $f_bDbChange = True
            EndIf
             ;_ArrayDisplay($f_aDiff)
            ;2. on extrait une table avec les nouveau fichiers et les diffs
            Local $f_nRows = UBound($f_aDiff)
            Local $f_aListFolderFiles[$f_nRows]
            $f_aListFolderFiles[0] = $f_aDiff[0][0]
            ;_ArrayDisplay($f_aListFolderFiles)
            For $k = 1 To $f_aDiff[0][0]
                If $f_aDiff[$k][0] = "" Then $f_aListFolderFiles[$k] = $f_aDiff[$k][3]
                If $f_aDiff[$k][2] <> $f_aDiff[$k][5] Or  $f_aDiff[$k][1] <> $f_aDiff[$k][4] Then $f_aListFolderFiles[$k] = $f_aDiff[$k][3]
            Next
            For $k = 1 To $f_aListFolderFiles[0]
                If $f_aListFolderFiles[$k] = "" Then
                    $f_sRowsToDelete &= $k&";"
                    $f_nCountDelete += 1
                EndIf
            Next
            $f_aListFolderFiles[0] -= $f_nCountDelete
            If $f_aListFolderFiles[0] > 0 And $f_sRowsToDelete <> "" Then
                $f_sRowsToDelete = StringTrimRight($f_sRowsToDelete,1)
                _ArrayDelete($f_aListFolderFiles,$f_sRowsToDelete)
            EndIf
            If $f_aListFolderFiles[0] > 0 Then $f_bDbChange = True
            ;3. on recré la db avec la nouvelle base sans les fichiers supp
            If $f_bDbChange Then
                If Not _StockData($SQLDll,$f_sFichierData,$f_aDiff) Then Return SetError(2,0,"Error [_StockData] "&$f_sFichierData)
            EndIf
        EndIf

        If $f_aListFolderFiles[0] > 0 Then
            For $k = 1 To $f_aListFolderFiles[0]

                If Not $f_bIsFolder Then $f_sSourceFinalPath = _GetPath($f_sSource) & $f_aListFolderFiles[$k]
                If $f_bIsFolder Then $f_sSourceFinalPath = $f_sSource&$f_aListFolderFiles[$k]

                $f_iStringLen = StringLen($f_sTarget&$f_aListFolderFiles[$k])
                If $f_iStringLen > 256 Then $f_aErrors = _ErrorArray($f_aErrors,"Erreur nom trop long ("&$f_iStringLen&" char) : "&$f_sTarget&$f_aListFolderFiles[$k])

                If $f_bEncrypt Then

                    If $Debug Then $f_aCred[1] = "password"
                    If @Compiled Then $f_aCred = CredRead($sCredName)
                    If Not IsArray($f_aCred) Then Return SetError(3,0,"No credential")

                    If Not _Crypt_EncryptFileControl($f_sSourceFinalPath, $f_sTarget&$f_aListFolderFiles[$k],$f_aCred[1] , $Debug) Then
                        $f_aErrors = _ErrorArray($f_aErrors,"Error encryption for "&$f_sSourceFinalPath)
                    EndIf

                Else
                    If Not _FileCopyControl($f_sSourceFinalPath, $f_sTarget&$f_aListFolderFiles[$k],$Debug) Then
                          $f_aErrors = _ErrorArray($f_aErrors,"Error copy for "&$f_sSourceFinalPath)
                    EndIf
                EndIf

            Next
        EndIf
    Next
    If $f_aErrors[0] > 0 Then Return SetError(4,0,$f_aErrors)
    SetError(0)
    Return (1)
EndFunc

Func _CreateStockData($f_hSqliteDll,$f_sFichierDb,$f_sSource,$f_aData)
    _SQLite_Startup($f_hSqliteDll, True, 1)
    If @error Then Return SetError(1,0,"Error [_StockData] DLL "&$f_hSqliteDll&" couldn't be loaded")
    Local $f_hDskDb = _SQLite_Open($f_sFichierDb)
    If @error Then Return SetError(2,0,"Error [_StockData] database "&$f_sFichierDb&" won't open")

    Local $f_ret = _SQLite_Exec(-1,"CREATE TABLE IF NOT EXISTS tSync (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,"& _
                                                                                                        "FileName TEXT,"& _
                                                                                                        "Date TEXT,"& _
                                                                                                        "Size INTEGER);")
    If $f_ret <> $SQLITE_OK Then Return SetError(3,0,"Error [_StockData] _SQLite_Exec create table tSync : "&_SQLite_ErrMsg())

    Local $f_sDateFile
    Local $f_iSizeFile
    Local $f_sSelectedColumns = "FileName,Date,Size"

    For $i = 1 To $f_aData[0]
        $f_sDateFile = FileGetTime($f_sSource&$f_aData[$i],0,1)
        $f_iSizeFile = FileGetSize($f_sSource&$f_aData[$i])
        ;                                                                                                                         Binary correctif pour garder les caracteres speciaux (€ é etc...)
        $f_ret = _SQLite_Exec(-1,"INSERT INTO tSync ("&$f_sSelectedColumns&") values ('"&Binary($f_aData[$i])&"','"&$f_sDateFile&"',"&$f_iSizeFile&");")
        If $f_ret <> $SQLITE_OK Then Return SetError(3,0,"Error Sqlite : "&_SQLite_ErrMsg())
    Next

    _SQLite_Close($f_hDskDb)
    _SQLite_Shutdown()
    SetError(0)
    Return True
EndFunc

Func _StockData($f_hSqliteDll,$f_sFichierDb,$f_aData)
    _SQLite_Startup($f_hSqliteDll, True, 1)
    If @error Then Return SetError(1,0,"Error [_StockData] DLL "&$f_hSqliteDll&" couldn't be loaded")
    Local $f_hDskDb = _SQLite_Open($f_sFichierDb)
    If @error Then Return SetError(2,0,"Error [_StockData] database "&$f_sFichierDb&" won't open")

    Local $f_ret = _SQLite_Exec(-1,"DROP TABLE tSync;")
    If $f_ret <> $SQLITE_OK Then Return SetError(3,0,"Error [_StockData] _SQLite_Exec drop table tSync : "&_SQLite_ErrMsg())

    $f_ret = _SQLite_Exec(-1,"CREATE TABLE IF NOT EXISTS tSync (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,"& _
                                                                                                        "FileName TEXT,"& _
                                                                                                        "Date TEXT,"& _
                                                                                                        "Size INTEGER);")
    If $f_ret <> $SQLITE_OK Then Return SetError(3,0,"Error [_StockData] _SQLite_Exec create table tSync : "&_SQLite_ErrMsg())

    Local $f_sSelectedColumns = "FileName,Date,Size"

    For $i = 1 To $f_aData[0][0]
        ;                                                                                                                         Binary correctif pour garder les caracteres speciaux (€ é etc...)
        $f_ret = _SQLite_Exec(-1,"INSERT INTO tSync ("&$f_sSelectedColumns&") values ('"&Binary($f_aData[$i][3])&"','"&$f_aData[$i][4]&"',"&$f_aData[$i][5]&");")
        If $f_ret <> $SQLITE_OK Then Return SetError(3,0,"Error Sqlite : "&_SQLite_ErrMsg())
    Next

    _SQLite_Close($f_hDskDb)
    _SQLite_Shutdown()
    SetError(0)
    Return True
EndFunc

Func _ExtractDb($f_hSqliteDll,$f_sFichierDb)
    _SQLite_Startup($f_hSqliteDll, True, 1)
    If @error Then Return SetError(1,0,"Error [_ExtractDb] DLL "&$f_hSqliteDll&" couldn't be loaded")
    Local $f_hDskDb = _SQLite_Open($f_sFichierDb)
    If @error Then Return SetError(2,0,"Error [_ExtractDb] database "&$f_sFichierDb&" won't open")

    Local $f_sSelectedColumns = "FileName,Date,Size"
    Local $f_aResult, $f_iRows, $f_iColumns, $f_iRval
    $f_iRval = _SQLite_GetTable2d(-1, "SELECT "&$f_sSelectedColumns&" FROM tSync; ", $f_aResult, $f_iRows, $f_iColumns)
    If $f_iRval <> $SQLITE_OK Then Return SetError(3,0,"Error [_ExtractDb] SQLite Error: " & $f_iRval &" "& _SQLite_ErrMsg())

    $f_aResult[0][0] = $f_iRows
    ;BinaryToString correctif pour garder les caracteres speciaux (€ é etc...)
    For $i = 1 To $f_iRows
        $f_aResult[$i][0] = BinaryToString($f_aResult[$i][0])
    Next

    _SQLite_Close($f_hDskDb)
    _SQLite_Shutdown()
    SetError(0)
    Return $f_aResult
EndFunc

Func _CheckFiles($f_sSource,$f_aData)
    Local $f_sDateFile,$f_iSizeFile
    Local $f_aResult[1][3]
    $f_aResult[0][0] = $f_aData[0]
    For $i = 1 To $f_aData[0]
        $f_sDateFile = FileGetTime($f_sSource&$f_aData[$i],0,1)
        $f_iSizeFile = FileGetSize($f_sSource&$f_aData[$i])
        _ArrayAdd($f_aResult,$f_aData[$i]&"|"&$f_sDateFile&"|"&$f_iSizeFile)
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
        $f_aArray[1] = "Error _ErrorArray function"
    EndIf
    Return $f_aArray
EndFunc

Func _Crypt_EncryptFileControl($f_sSource,$f_sTarget,$f_sPassword,$f_bDebug = False)
    If $f_bDebug Then
        _FileWriteLog($sFichierLog,"[Encrypt] "&$f_sSource&" > "&$f_sTarget)
        Return True
    Else
        If FileExists($f_sTarget) Then FileDelete($f_sTarget)
        If _Crypt_EncryptFile($f_sSource, $f_sTarget,$f_sPassword , $CALG_AES_256) Then Return True
        Return False
    EndIf
EndFunc

Func _FileCopyControl($f_sSource,$f_sTarget,$f_bDebug = False)
    If $f_bDebug Then
        _FileWriteLog($sFichierLog,$f_sSource&" > "&$f_sTarget)
        Return True
    Else
        If FileCopy($f_sSource,$f_sTarget ,9) Then Return True
        Return False
    EndIf
EndFunc

Func _FileDeleteControl($f_sSource,$f_bDebug = False)
    If $f_bDebug Then
        _FileWriteLog($sFichierLog,"Delete file : "&$f_sSource)
        Return True
    Else
        If FileDelete($f_sSource) Then Return True
        Return False
    EndIf
EndFunc

Func _Decrypt($f_sSource,$f_sTarget)
    Local $f_aCred
    Local $f_aListFolderFiles = _FileListToArrayRec($f_sSource,"*",1,1,0,1)
    Local $f_bError = False
    If IsArray($f_aListFolderFiles) Then
        $f_aCred = CredRead($sCredName)
        For $i = 1 To $f_aListFolderFiles[0]
           if  _Crypt_DecryptFile($f_sSource&$f_aListFolderFiles[$i], $f_sTarget&$f_aListFolderFiles[$i],$f_aCred[1] , $CALG_AES_256) Then
               Sleep(50)
           Else
               $f_bError = True
               _FileWriteLog($sFichierLog,"Error decrypt for "&$f_sSource)
            EndIf
        Next
    EndIf
    Return $f_bError
EndFunc

Func _GetfileName($f_sSource)
    Local $f_sFileName = StringRegExpReplace($f_sSource, "^.*\\", "")
    Return $f_sFileName
EndFunc

Func _GetPath($f_sSource)
    Local $f_sPath = StringRegExpReplace($f_sSource, "(^.*\\)(.*)", "\1")
    Return $f_sPath
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
    $Ret = DllCall($hAdvapi32, 'bool', 'CredDeleteW', 'ptr', DllStructGetPtr($targetName), 'dword', 1, 'dword', 0)
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
    $Ret = DllCall($hAdvapi32, 'bool', 'CredWriteW', 'ptr', DllStructGetPtr($NewCred), 'dword', 0)
    $NewCred = 0
	SetError(0)
	Return(1)
EndFunc

Func _Log($f_sFile,$f_data,$f_bExit = False)
    _FileWriteLog($f_sFile,$f_data)
    If $f_bExit Then Exit
EndFunc

Func _ArrayDiff2D($f_aSource,$f_nSourceRow,$f_nSourceCol,$f_aTarget,$f_nTargetRow,$f_nTargetCol)
    Local $f_nColumns = UBound($f_aSource,2) + UBound($f_aTarget,2)
    Local $f_aCompare[1][$f_nColumns]
    $f_aCompare[0][0] = 0

    Local $f_bSource = False
    Local $sAddLine = ""
    Local $f_sRange = ""

    For $i = $f_nSourceRow To UBound($f_aSource) - 1
        $f_bSource = False
        $sAddLine = ""

        For $j = $f_nTargetRow To UBound($f_aTarget) - 1
            ;If $f_aSource[$i][$f_nSourceCol] = $f_aTarget[$j][$f_nTargetCol] Then
            If Binary($f_aSource[$i][$f_nSourceCol]) = Binary($f_aTarget[$j][$f_nTargetCol]) Then
                $f_bSource = True
                For $k = 0 To UBound($f_aSource,2) - 1
                    $sAddLine &= $f_aSource[$i][$k] & "|"
                Next
                For $k = 0 To UBound($f_aTarget,2) - 1
                    $sAddLine &= $f_aTarget[$j][$k] & "|"
                Next
                $sAddLine = StringTrimRight($sAddLine,1)
                _ArrayAdd($f_aCompare,$sAddLine); si correspondance de source on ajoute les deux
                $f_sRange &= $j & ";"
                $f_aCompare[0][0] += 1
                ;ContinueLoop
            EndIf
        Next

        If Not $f_bSource Then
            For $k = 0 To UBound($f_aSource,2) - 1
                $sAddLine &= $f_aSource[$i][$k] & "|"
            Next
            For $k = 0 To UBound($f_aTarget,2) - 1
                $sAddLine &= "|"
            Next
            $sAddLine = StringTrimRight($sAddLine,1)
            _ArrayAdd($f_aCompare,$sAddLine,0); si pas de target pour source on ajoute que source
            $f_aCompare[0][0] += 1
        EndIf
    Next

     _ArrayDelete($f_aTarget,StringTrimRight($f_sRange,1))

    For $i = 1 To UBound($f_aTarget) - 1
        $sAddLine = ""
        For $k = 0 To UBound($f_aTarget,2) - 1
            $sAddLine &= $f_aTarget[$i][$k] & "|"
        Next
        $sAddLine = StringTrimRight($sAddLine,1)
        _ArrayAdd($f_aCompare,$sAddLine,UBound($f_aSource,2))
    Next

     $f_aCompare[0][0] = UBound($f_aCompare) - 1
    _ArraySort($f_aCompare,0,1,0,$f_nSourceCol)
    Return($f_aCompare)
EndFunc
