#include-once

Func _SyncFile($f_sFichierIni,$f_dSqlDll,$f_sCredName,$f_aJob,$f_sLogFile,$f_sForcePassword,$f_bDebug = False)
    Local $f_aProcessJob
    #forceref $f_aProcessJob
    Local $f_bEncrypt = False
    Local $f_bIsFolder = False
    Local $f_iSize = 0
    #forceref $f_iSize
    Local $f_aDiff
    Local $f_iStringLen = 0
    Local $f_sFileName,$f_sSource,$f_sSourceFinalPath,$f_sTarget
    ;Local $f_aCred[3]
    Local $f_aListFolderFiles

    Local $f_Ret

    Local $f_sPassword

    Local $f_sFichierData
    Local $f_aExtractDb
    Local $f_aCheckFiles
    Local $f_sRowsToDelete = ""
    Local $f_nCountDelete = 0

    Local $f_sErrors = 0

    For $i = 1 To $f_aJob[0]
        _Log($f_sLogFile,"[SyncFile] INFO Process job "&$f_aJob[$i]&" at "&$i&" / "&$f_aJob[0],$f_bDebug)

        $f_aProcessJob = IniReadSection($f_sFichierIni,$f_aJob[$i])
        If @error Then
            _Log($f_sLogFile,"[SyncFile] ERROR couldn't read section from : "&$f_sFichierIni,$f_bDebug)
            $f_sErrors += 1
            ContinueLoop
        EndIf

        $f_sFichierData = @ScriptDir &"\"&$f_aJob[$i]& ".db"

        $f_bEncrypt = False
        If _CheckBool(IniRead($f_sFichierIni,$f_aJob[$i],"encryption","false")) = "true" Then
            _Log($f_sLogFile,"[SyncFile] INFO encryption mode is active",$f_bDebug)
            $f_bEncrypt = True
        EndIf

        $f_sSource = IniRead($f_sFichierIni,$f_aJob[$i],"source","")
        $f_sTarget = IniRead($f_sFichierIni,$f_aJob[$i],"target","")

         If FileExists($f_sSource) Then
            $f_bIsFolder = True
            $f_iSize = DirGetSize($f_sSource, 2)
            If @error Then $f_bIsFolder = False

            If $f_bIsFolder Then
                _Log($f_sLogFile,"[SyncFile] INFO this path "&$f_sSource&" is a folder",$f_bDebug)
                If StringRight($f_sSource,1) <> "\" Then $f_sSource = $f_sSource & "\"
                If StringRight($f_sTarget,1) <> "\" Then $f_sTarget = $f_sTarget & "\"
                $f_aListFolderFiles = _FileListToArrayRec($f_sSource,"*",1,1,0,1)
                If Not IsArray($f_aListFolderFiles) Then
                    _Log($f_sLogFile,"[SyncFile] ERROR code "&@error&" counldn't read content from : "&$f_sSource)
                    $f_sErrors += 1
                    ContinueLoop
                EndIf
            Else
                _Log($f_sLogFile,"[SyncFile] INFO this path "&$f_sSource&" is a file",$f_bDebug)
                $f_sFileName = _GetfileName($f_sSource)
                Local $f_aListFolderFiles[2] = [1,$f_sFileName]
            EndIf
        Else
            _Log($f_sLogFile,"[SyncFile] ERROR the path "&$f_sSource&" doesn't exist",$f_bDebug)
            $f_sErrors += 1
            ContinueLoop
        EndIf

        ;_ArrayDisplay($f_aListFolderFiles)
        ;ContinueLoop

        ; partie ou on compare les fichiers
        If Not FileExists($f_sFichierData) Then ; on crée la db et on ajoute les données
            _Log($f_sLogFile,"[SyncFile] INFO First time, a database is created",$f_bDebug)
            If Not $f_bIsFolder Then
                If Not _CreateStockData($f_dSqlDll,$f_sFichierData,_GetPath($f_sSource),$f_aListFolderFiles) Then Return SetError(1,0,"[SyncFile] ERROR [_CreateStockData] "&$f_sFichierData)
            Else
                If Not _CreateStockData($f_dSqlDll,$f_sFichierData,$f_sSource,$f_aListFolderFiles) Then Return SetError(1,0,"[SyncFile] ERROR [_CreateStockData] "&$f_sFichierData)
            EndIf
        Else ; on lit la db et on compare les données avec celles actuelle1309
            _Log($f_sLogFile,"[SyncFile] INFO a database exist",$f_bDebug)
            $f_aExtractDb = _ExtractDb($f_dSqlDll,$f_sFichierData)
            If Not $f_bIsFolder Then
                $f_aCheckFiles = _CheckFiles(_GetPath($f_sSource),$f_aListFolderFiles)
            Else
                $f_aCheckFiles = _CheckFiles($f_sSource,$f_aListFolderFiles)
            EndIf
            ;_ArrayDisplay($f_aExtractDb)
           ; _ArrayDisplay($f_aCheckFiles)
           _Log($f_sLogFile,"[SyncFile] INFO comparing changes",$f_bDebug)
            $f_aDiff = _ArrayDiff2D($f_aExtractDb,1,0,$f_aCheckFiles,1,0)
            #cs
            fichier DB                                      recherche
            col 0                    1               2                          3
            160
            fichier                taille           fichier                 taille      > identique
                                                        nouveau fichier                 > ajout 1 fichier
            fichier2                4              fichier2                  6          > fichier diff a remplacer
            fichier3                3                                                        > suppression 1 fichier

            1. on supprime les fichier supp dans target
            2. on extrait une table avec les nouveau fichiers et les diffs
            3. on recré la db avec la nouvelle base sans les fichiers supp
            #ce
            Local $f_bDbChange = False
            $f_nCountDelete = 0
            ;_ArrayDisplay($f_aDiff)

            _Log($f_sLogFile,"[SyncFile] INFO PHASE 1 deleting files from target",$f_bDebug)
            $f_sRowsToDelete = ""
            $f_nCountDelete = 0

            For $k = 1 To $f_aDiff[0][0]
                _Log($f_sLogFile,"[SyncFile] INFO loop compare array at "&$k&" / "&$f_aDiff[0][0],$f_bDebug)
                If $f_aDiff[$k][2] = "" Then
                    $f_Ret = _FileDeleteControl($f_sTarget&$f_aDiff[$k][0])
                    If @error Then
                        _Log($f_sLogFile,"[SyncFile] ERROR [FileDeleteControl] return "&$f_Ret,$f_bDebug)
                        $f_sErrors += 1
                    Else
                        _Log($f_sLogFile,"[SyncFile] INFO deleting "&$f_aDiff[$k][0],$f_bDebug)
                            $f_sRowsToDelete &= $k&";"
                            $f_nCountDelete += 1
                    EndIf
                EndIf
            Next
            If $f_sRowsToDelete <> "" Then
                $f_sRowsToDelete = StringTrimRight($f_sRowsToDelete,1)
                _Log($f_sLogFile,"[SyncFile] INFO compressing compare array, removing deleted files",$f_bDebug)
                _ArrayDelete($f_aDiff,$f_sRowsToDelete)
                $f_aDiff[0][0] -= $f_nCountDelete
                $f_bDbChange = True
            EndIf
             ;_ArrayDisplay($f_aDiff)
           _Log($f_sLogFile,"[SyncFile] INFO PHASE 2 extract new array with new and updated files",$f_bDebug)
            Local $f_nRows = UBound($f_aDiff)
            Local $f_aListFolderFiles[$f_nRows]
            $f_aListFolderFiles[0] = $f_aDiff[0][0]
            ;_ArrayDisplay($f_aListFolderFiles)
            For $k = 1 To $f_aDiff[0][0]
                _Log($f_sLogFile,"[SyncFile] INFO loop compare array at "&$k&" / "&$f_aDiff[0][0],$f_bDebug)
                If $f_aDiff[$k][0] = "" Then
                    $f_aListFolderFiles[$k] = $f_aDiff[$k][2]
                    _Log($f_sLogFile,"[SyncFile] INFO add new file "&$f_aDiff[$k][2],$f_bDebug)
                    ContinueLoop
                EndIf
                If $f_aDiff[$k][1] <> $f_aDiff[$k][3] Then
                    $f_aListFolderFiles[$k] = $f_aDiff[$k][2]
                    _Log($f_sLogFile,"[SyncFile] INFO  add an updated file "&$f_aDiff[$k][2],$f_bDebug)
                EndIf
            Next

            $f_sRowsToDelete = ""
            $f_nCountDelete = 0
            For $k = 1 To $f_aListFolderFiles[0]
                _Log($f_sLogFile,"[SyncFile] INFO loop new array searching for empty lines at "&$k&" / "&$f_aListFolderFiles[0],$f_bDebug)
                If $f_aListFolderFiles[$k] = "" Then
                    $f_sRowsToDelete &= $k&";"
                    $f_nCountDelete += 1
                EndIf
            Next
            If $f_nCountDelete > 1 Then _Log($f_sLogFile,"[SyncFile] INFO lines ["&$f_sRowsToDelete&"] will be deleted",$f_bDebug)
            If $f_aListFolderFiles[0] > 0 And $f_sRowsToDelete <> "" Then
                $f_sRowsToDelete = StringTrimRight($f_sRowsToDelete,1)
                If $f_bDebug Then ConsoleWrite("Process job "&$f_aJob[$i]&" updating new array "&$f_sRowsToDelete&@CRLF)
                _ArrayDelete($f_aListFolderFiles,$f_sRowsToDelete)
                 $f_aListFolderFiles[0] -= $f_nCountDelete
            EndIf

            If $f_aListFolderFiles[0] > 0 Then $f_bDbChange = True

            If $f_bDbChange Then
                _Log($f_sLogFile,"[SyncFile] INFO PHASE 3 updating database",$f_bDebug)
                If Not _StockData($f_dSqlDll,$f_sFichierData,$f_aDiff) Then Return SetError(2,0,"[SyncFile] ERROR "&$f_sFichierData)
            EndIf
        EndIf


        If $f_aListFolderFiles[0] > 0 Then

            _Log($f_sLogFile,"[SyncFile] INFO PHASE 4 process final list with "&$f_aListFolderFiles[0]&" updates",$f_bDebug)

            For $k = 1 To $f_aListFolderFiles[0]
                _Log($f_sLogFile,"[SyncFile] INFO loop final list at "&$k&" / "&$f_aListFolderFiles[0],$f_bDebug)

                If Not $f_bIsFolder Then
                    $f_sSourceFinalPath = _GetPath($f_sSource) & $f_aListFolderFiles[$k]
                    _Log($f_sLogFile,"[SyncFile] INFO  Source is a folder : "&$f_sSourceFinalPath,$f_bDebug)
                Else
                    $f_sSourceFinalPath = $f_sSource&$f_aListFolderFiles[$k]
                    _Log($f_sLogFile,"[SyncFile] INFO  Source is a file : "&$f_sSourceFinalPath,$f_bDebug)
                EndIf

                $f_iStringLen = StringLen($f_sTarget&$f_aListFolderFiles[$k])
                If $f_iStringLen > 256 Then
                    _Log($f_sLogFile,"[SyncFile] ERROR file path "&$f_aListFolderFiles[$k]&" contain more than 256 chr"&$f_Ret,$f_bDebug)
                    $f_sErrors += 1
                EndIf

                If $f_bEncrypt Then
                    If $f_bDebug Then ConsoleWrite("Process job "&$f_aJob[$i]&" encryption is active"&@CRLF)
                    If $f_sForcePassword <> "" Then
                        $f_sPassword = $f_sForcePassword
                    Else
                        $f_sPassword = _GetPassword($f_sCredName)
                    EndIf
                    If @error Then
                        _Log($f_sLogFile,"[SyncFile] ERROR "&$f_sPassword,$f_bDebug)
                        $f_sErrors += 1
                        ExitLoop
                    EndIf
                    If Not _Crypt_EncryptFileControl($f_sSourceFinalPath, $f_sTarget&$f_aListFolderFiles[$k],$f_sPassword) Then
                        _Log($f_sLogFile,"[SyncFile] ERROR encryption for "&$f_sSourceFinalPath,$f_bDebug)
                        $f_sErrors += 1
                        ContinueLoop
                    EndIf
                    ;$f_bDebug = True
                Else
                    If $f_bDebug Then ConsoleWrite("Process job "&$f_aJob[$i]&" encryption is disable"&@CRLF)
                    ;$f_bDebug = False
                    If Not _FileCopyControl($f_sSourceFinalPath, $f_sTarget&$f_aListFolderFiles[$k]) Then
                        _Log($f_sLogFile,"[SyncFile] ERROR copy for "&$f_sSourceFinalPath,$f_bDebug)
                        $f_sErrors += 1
                        ContinueLoop
                    EndIf
                   ; $f_bDebug = True
                EndIf

            Next
        EndIf
    Next
    If $f_sErrors > 0 Then
        _Log($f_sLogFile,"[SyncFile] ERROR  there is(are) "&$f_sErrors&" error(s)",$f_bDebug)
        Return SetError(4,0,"There is(are)  "&$f_sErrors&" error(s) see log")
    EndIf
    _Log($f_sLogFile,"[SyncFile] INFO end of processing jobs",$f_bDebug)
    SetError(0)
    Return (1)
EndFunc



