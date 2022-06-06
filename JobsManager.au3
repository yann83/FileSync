#AutoIt3Wrapper_Au3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7
#cs ----------------------------------------------------------------------------

 AutoIt Version : 3.3.14.5
 Programme Version :
 Auteur:         Yann83
 Description du programme :
	<....>

#ce ----------------------------------------------------------------------------
#pragma compile(Icon, C:\Program Files (x86)\AutoIt3\Icons\au3.ico)

#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiComboBox.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <File.au3>
#include <Array.au3>

Global $sProgName =  StringTrimRight(@ScriptName,4)
Global $sFichierIni = @ScriptDir &"\FileSync.ini"
If Not FileExists($sFichierIni) Then _FileCreate($sFichierIni)
Global $sFichierLog = @ScriptDir &"\"&$sProgName& ".log"

#Region ### START Koda GUI section ### Form=
Global $Form = GUICreate("Jobs Manager", 577, 343, 456, 266)

Global $LabelJobSelect = GUICtrlCreateLabel("Select an existing job :", 64, 16, 195, 24)
GUICtrlSetFont(-1, 12, 800, 0, "MS Sans Serif")

Global $JobsList = GUICtrlCreateCombo("", 64, 48, 241, 25, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL,$CBS_SORT))
GUICtrlSetFont(-1, 12, 400, 0, "MS Sans Serif")
_PopulatecomboBox($sFichierIni)

Global $JobsListUpdate= GUICtrlCreateButton("Open", 320, 48, 97, 25)
GUICtrlSetFont(-1, 12, 400, 0, "MS Sans Serif")
Global $JobsListDelete = GUICtrlCreateButton("Delete", 432, 48, 97, 25)
GUICtrlSetFont(-1, 12, 400, 0, "MS Sans Serif")

Global $LabelJobName = GUICtrlCreateLabel("Job name :", 64, 95, 92, 24)
GUICtrlSetFont(-1, 12, 800, 0, "MS Sans Serif")
Global $InputJobName = GUICtrlCreateInput("MyJobName", 168, 92, 137, 28)
GUICtrlSetFont(-1, 12, 400, 0, "MS Sans Serif")

Global $InputSource = GUICtrlCreateInput("Select source : file or folder", 64, 136, 241, 28)
GUICtrlSetFont(-1, 12, 400, 0, "MS Sans Serif")
GUICtrlSetStyle(-1, $ES_READONLY)
Global $SourceFile = GUICtrlCreateButton("File", 320, 136, 97, 25)
GUICtrlSetFont(-1, 12, 400, 0, "MS Sans Serif")
Global $SourceFolder = GUICtrlCreateButton("Folder", 432, 136, 97, 25)
GUICtrlSetFont(-1, 12, 400, 0, "MS Sans Serif")

Global $InputTarget = GUICtrlCreateInput("Select folder target", 64, 176, 241, 28)
GUICtrlSetFont(-1, 12, 400, 0, "MS Sans Serif")
GUICtrlSetStyle(-1, $ES_READONLY)
Global $TargetFolder = GUICtrlCreateButton("Folder", 320, 176, 97, 25)
GUICtrlSetFont(-1, 12, 400, 0, "MS Sans Serif")

Global $LabelEnCrypt = GUICtrlCreateLabel("Encrypt files ?", 64, 224, 185, 24)
GUICtrlSetFont(-1, 12, 800, 0, "MS Sans Serif")
Global $Encrpyt = GUICtrlCreateCombo("", 254, 219, 50, 25,BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL,$CBS_SORT))
GUICtrlSetFont(-1, 12, 400, 0, "MS Sans Serif")
GUICtrlSetData(-1,"Yes|No","No")

Global $AddUpdate = GUICtrlCreateButton("Add or update", 64, 272, 113, 33)
GUICtrlSetFont(-1, 13, 400, 0, "MS Sans Serif")

Global $nMsg

GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

Global $sLectureSelection
Global $bIsUpdate = False
Global $sLectureIniSource,$sLectureIniDest,$sLectureIniEncrypt
Global $sLectureGuiName,$sLectureGuiSource,$sLectureGuiDest
Global $Ret

While 1
    $nMsg = GUIGetMsg()
    Switch $nMsg
        Case $GUI_EVENT_CLOSE
            Exit
        Case $JobsListUpdate
            $sLectureSelection = GUICtrlRead($JobsList)
            If $sLectureSelection <> "" Then
                GUICtrlSetStyle($InputJobName, $ES_READONLY)
                GUICtrlSetData($InputJobName,$sLectureSelection)
                ;GUICtrlSetState($InputJobName,$GUI_DISABLE)
                GUICtrlSetData($InputSource, IniRead($sFichierIni,$sLectureSelection,"source","no result") )
                GUICtrlSetData($InputTarget, IniRead($sFichierIni,$sLectureSelection,"target","no result") )
                GUICtrlSetData($Encrpyt,"No")
                If IniRead($sFichierIni,$sLectureSelection,"encryption","false") = "true" Then GUICtrlSetData($Encrpyt,"Yes")
                $bIsUpdate = True
            Else
                MsgBox(16,"warning","Please select a Job")
            EndIf
        Case $JobsListDelete
            $sLectureSelection = GUICtrlRead($JobsList)
            If $sLectureSelection <> "" Then
                $Ret = MsgBox(36,"Delete confirmation","Please confirm that you want to delete "&$sLectureSelection)
                If $Ret = 6 Then
                    IniDelete($sFichierIni,$sLectureSelection)
                    _PopulatecomboBox($sFichierIni)
                EndIf
            Else
                MsgBox(48,"No selection","Please select a Job")
            EndIf
        Case $SourceFile
            $Ret = FileOpenDialog("Please select a file",@MyDocumentsDir&"\","All (*.*)",3)
            If Not @error Then
                GUICtrlSetData($InputSource,$Ret)
                GUICtrlSetTip($SourceFile,$Ret)
            EndIf
        Case $SourceFolder
            $Ret = FileSelectFolder("Please select a folder","")
            If Not @error Then
                GUICtrlSetData($InputSource,$Ret&"\")
                GUICtrlSetTip($SourceFolder,$Ret&"\")
            EndIf
        Case $TargetFolder
            $Ret = FileSelectFolder("Please select a folder","")
            If Not @error Then
                GUICtrlSetData($InputTarget,$Ret&"\")
                GUICtrlSetTip($TargetFolder,$Ret&"\")
            EndIf
        Case $AddUpdate
            $sLectureGuiName = GUICtrlRead($InputJobName)
            ConsoleWrite($sLectureGuiName)
            If $sLectureGuiName <> "" Then
                $sLectureGuiSource = GUICtrlRead($InputSource)
                If $sLectureGuiSource <> "" Then
                        $sLectureGuiDest = GUICtrlRead($InputTarget)
                        If $sLectureGuiDest <> "" Then
                            If Not _CheckIfExist($sLectureGuiName,$sFichierIni) Or $bIsUpdate Then
                                IniWrite($sFichierIni,$sLectureGuiName,"source",$sLectureGuiSource)
                                IniWrite($sFichierIni,$sLectureGuiName,"target",$sLectureGuiDest)
                                $Ret = _LectureGuiEncryption(GUICtrlRead($Encrpyt))
                                IniWrite($sFichierIni,$sLectureGuiName,"encryption",$Ret)
                                ;GUICtrlSetState($InputJobName,$GUI_ENABLE)
                                GUICtrlSetStyle($InputJobName, $GUI_SS_DEFAULT_INPUT)
                                _PopulatecomboBox($sFichierIni)
                                MsgBox(64,"Done","Entry "&$sLectureGuiName&" added or updated")
                                $bIsUpdate = False
                            Else
                                MsgBox(16,"warning","Job already exist")
                            EndIf
                        Else
                            MsgBox(16,"warning","No Target")
                        EndIf
                Else
                    MsgBox(16,"warning","No Source")
                EndIf
            Else
                MsgBox(16,"warning","No job name")
            EndIf
    EndSwitch
WEnd

Func _CheckIfExist($f_sJobName,$f_sFichierIni)
    Local $f_aGetJobsList = IniReadSectionNames($f_sFichierIni)
    If @error Then Return False
    For $i = 1 To $f_aGetJobsList[0]
        If $f_aGetJobsList[$i] = $f_sJobName Then Return True
    Next
    Return False
EndFunc

Func _PopulatecomboBox($f_sFichierIni)
    _GUICtrlComboBox_ResetContent($JobsList)
    Local $f_aGetJobsList = IniReadSectionNames($f_sFichierIni)
    Local $f_sGetJobsList = _ArrayToString($f_aGetJobsList,"|",1)
    GUICtrlSetData($JobsList,$f_sGetJobsList)
EndFunc

Func _LectureGuiEncryption($sData)
    If $sData = "No" Then Return "false"
    If $sData = "Yes" Then Return "true"
EndFunc
