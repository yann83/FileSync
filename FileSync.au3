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
;#pragma compile(Icon, C:\Applications\AutoIt3\Icons\au3.ico)
#pragma compile(Icon, C:\Program Files (x86)\AutoIt3\Icons\au3.ico)
#include <File.au3>
#include <Crypt.au3>
#include <Array.au3>
#include <SQLite.au3>
#include <SQLite.dll.au3>

#include <.\UDF\ArrayDiff.au3>
#include <.\UDF\Tools.au3>
#include <.\UDF\Creds.au3>
#include <.\UDF\Control.au3>
#include <.\UDF\SqliteFunctions.au3>
#include <.\UDF\Sync.au3>

Global $sProgName =  StringTrimRight(@ScriptName,4)
Global $sFichierIni = @ScriptDir &"\"&$sProgName& ".ini"
If Not FileExists($sFichierIni) Then _FileCreate($sFichierIni)
Global $sFichierLog = @ScriptDir &"\"&$sProgName& ".log"
Global $SQLDll = @ScriptDir&"\Dlls\SQLite3.dll"
If @AutoItX64 Then $SQLDll = @ScriptDir&"\Dlls\SQLite3_x64.dll"
Global $sCredName = $sProgName
Global $aJobs[1]
Global $Ret
Global $sPassword = ""
Global $Debug = False

#cs
$aJobs = IniReadSectionNames($sFichierIni)
_SyncFile($sCredName,$aJobs,True)
 Exit
#ce


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
                For $i = 1 To $CmdLine[0]
                    If StringLower($CmdLine[$i]) = "-debug" Then $Debug = True
                Next
                For $i = 1 To $CmdLine[0]
                    If StringLower($CmdLine[$i]) = "-password" Then
                        $sPassword = $CmdLine[$i+1]
                        ExitLoop
                    EndIf
                Next
                $Ret = _SyncFile($sFichierIni,$SQLDll,$sCredName,$aJobs,$sFichierLog,$sPassword,$Debug)
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
                For $i = 1 To $CmdLine[0]
                    If StringLower($CmdLine[$i]) = "-debug" Then $Debug = True
                Next
                For $i = 1 To $CmdLine[0]
                    If StringLower($CmdLine[$i]) = "-password" Then
                        $sPassword = $CmdLine[$i+1]
                        ExitLoop
                    EndIf
                Next
                $Ret = _SyncFile($sFichierIni,$SQLDll,$sCredName,$aJobs,$sFichierLog,$sPassword,$Debug)
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
                For $i = 1 To $CmdLine[0]
                    If StringLower($CmdLine[$i]) = "-password" Then
                        $sPassword = $CmdLine[$i+1]
                        ExitLoop
                    EndIf
                Next
                $Ret = _DecryptControl($CmdLine[2],$CmdLine[3],$sPassword,$sCredName)
                If @error Then
                    ConsoleWrite("ATTENTION il y a des erreurs"&@CRLF)
                    If IsArray($Ret) Then
                        For $i = 1 To $Ret[0]
                            If $Debug Then
                                _Log($sFichierLog,$Ret[$i],$Debug)
                            Else
                                _Log($sFichierLog,$Ret[$i])
                            EndIf
                        Next
                    EndIf
                    Exit
                EndIf
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
            ConsoleWrite("[Special] For Run and Decrypt you can use switch [-password <password>] to force password and [-debug] for console logs"&@CRLF)
            Exit

        Case Else
            ConsoleWrite("Use [-?] for help."&@CRLF)
            Exit
    EndSwitch
EndIf

