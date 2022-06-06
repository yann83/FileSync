#include-once

Func _CreateStockData($f_hSqliteDll,$f_sFichierDb,$f_sSource,$f_aData)
    _SQLite_Startup($f_hSqliteDll, True, 1)
    If @error Then Return SetError(1,0,"[CreateStockData] ERROR DLL "&$f_hSqliteDll&" couldn't be loaded")
    Local $f_hDskDb = _SQLite_Open($f_sFichierDb)
    If @error Then Return SetError(2,0,"[CreateStockData] ERROR database "&$f_sFichierDb&" won't open")

    Local $f_ret = _SQLite_Exec(-1,"CREATE TABLE IF NOT EXISTS tSync (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,"& _
                                                                                                        "FileName TEXT,"& _
                                                                                                        "Size INTEGER);")
    If $f_ret <> $SQLITE_OK Then Return SetError(3,0,"[CreateStockData] ERROR _SQLite_Exec create table tSync : "&_SQLite_ErrMsg())

    Local $f_iSizeFile
    Local $f_sSelectedColumns = "FileName,Size"

    For $i = 1 To $f_aData[0]
        $f_iSizeFile = FileGetSize($f_sSource&$f_aData[$i])
        ;                                                                                                                         Binary correctif pour garder les caracteres speciaux (€ é etc...)
        $f_ret = _SQLite_Exec(-1,"INSERT INTO tSync ("&$f_sSelectedColumns&") values ('"&Binary($f_aData[$i])&"',"&$f_iSizeFile&");")
        If $f_ret <> $SQLITE_OK Then Return SetError(4,0,"[CreateStockData] ERROR Sqlite : "&_SQLite_ErrMsg())
    Next

    _SQLite_Close($f_hDskDb)
    _SQLite_Shutdown()
    SetError(0)
    Return True
EndFunc

Func _StockData($f_hSqliteDll,$f_sFichierDb,$f_aData)
    _SQLite_Startup($f_hSqliteDll, True, 1)
    If @error Then Return SetError(1,0,"[StockData] ERROR DLL "&$f_hSqliteDll&" couldn't be loaded")
    Local $f_hDskDb = _SQLite_Open($f_sFichierDb)
    If @error Then Return SetError(2,0,"[StockData] ERROR] database "&$f_sFichierDb&" won't open")

    Local $f_ret = _SQLite_Exec(-1,"DROP TABLE tSync;")
    If $f_ret <> $SQLITE_OK Then Return SetError(3,0,"[StockData] ERROR _SQLite_Exec drop table tSync : "&_SQLite_ErrMsg())

    $f_ret = _SQLite_Exec(-1,"CREATE TABLE IF NOT EXISTS tSync (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,"& _
                                                                                                        "FileName TEXT,"& _
                                                                                                        "Size INTEGER);")
    If $f_ret <> $SQLITE_OK Then Return SetError(4,0,"[StockData] ERROR _SQLite_Exec create table tSync : "&_SQLite_ErrMsg())

    Local $f_sSelectedColumns = "FileName,Size"

    For $i = 1 To $f_aData[0][0]
        ;                                                                                                                         Binary correctif pour garder les caracteres speciaux (€ é etc...)
        $f_ret = _SQLite_Exec(-1,"INSERT INTO tSync ("&$f_sSelectedColumns&") values ('"&Binary($f_aData[$i][2])&"',"&$f_aData[$i][3]&");")
        If $f_ret <> $SQLITE_OK Then Return SetError(5,0,"[StockData] ERROR Sqlite : "&_SQLite_ErrMsg())
    Next

    _SQLite_Close($f_hDskDb)
    _SQLite_Shutdown()
    SetError(0)
    Return True
EndFunc

Func _ExtractDb($f_hSqliteDll,$f_sFichierDb)
    _SQLite_Startup($f_hSqliteDll, True, 1)
    If @error Then Return SetError(1,0,"[ExtractDb] ERROR DLL "&$f_hSqliteDll&" couldn't be loaded")
    Local $f_hDskDb = _SQLite_Open($f_sFichierDb)
    If @error Then Return SetError(2,0,"[ExtractDb] ERROR database "&$f_sFichierDb&" won't open")

    Local $f_sSelectedColumns = "FileName,Size"
    Local $f_aResult, $f_iRows, $f_iColumns, $f_iRval
    $f_iRval = _SQLite_GetTable2d(-1, "SELECT "&$f_sSelectedColumns&" FROM tSync; ", $f_aResult, $f_iRows, $f_iColumns)
    If $f_iRval <> $SQLITE_OK Then Return SetError(3,0,"[ExtractDb] ERROR SQLite Error: " & $f_iRval &" "& _SQLite_ErrMsg())

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
