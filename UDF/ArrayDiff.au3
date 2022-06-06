#include-once
;###########################################################################
;   Compare two columns in two arrays
;   $f_aSource = a 2D array
;   $f_nSourceRow = first row to compare
;   $f_nSourceCol = column to compare
;   $f_aTarget = a second 2D array
;   $f_nTargetRow =  first row to compare
;   $f_nTargetCol = column to compare
;##########################################################################
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
