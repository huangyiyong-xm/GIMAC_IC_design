--------------------------------------------------------------------------------
--@SEE << CHANGE ORDER NO(5 to 3) >>
--    @ID      : LDYS0006
--
--    @Written : 1.0.0                   2025.10.14 Sun Sheng / YMSL
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--
----------------------------------------------------------------------------
--@SEE << CHANGE ORDER NO(5 to 3) >>
----------------------------------------------------------------------------
--  < INPUT Parameter >
--    @ps_orderno           <I/ >VARCHAR  : Order No (5 digits)

--  < OUTPUT Parameter >
--    @rn_status            : Return Code (0:Normal, -1:SQL Error, -2:PG Error, 1:Warning)
--    @rs_sql_code          : SQL Code
--    @rs_err_code          : Error Code
--    @rs_err_msg           : Error Message
--    @rs_err_focus         : Error Focus
--    @rs_orderno           : Order No (3 digits)
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0006(
      ps_orderno   VARCHAR)   --1 ５桁オーダ番号
RETURNS TABLE(
      rn_status    INTEGER    --1 処理ステータス
    , rs_sql_code  VARCHAR    --2 SQLコード
    , rs_err_code  VARCHAR    --3 エラーコード
    , rs_err_msg   VARCHAR    --4 エラーメッセージ
    , rs_err_focus VARCHAR    --5 エラー位置
    , rs_orderno   VARCHAR)   --6 ３桁オーダ番号
AS
$BODY$
DECLARE
    ls_orderno3  VARCHAR;

    cs_space       CONSTANT VARCHAR := ' ';
    cs_pgmid       CONSTANT VARCHAR := 'LDYS0006';
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    /* Return Value Set */
    rn_status    := 0;
    rs_sql_code  := cs_space;
    rs_err_code  := cs_space;
    rs_err_msg   := cs_space;
    rs_err_focus := cs_space;
    rs_orderno   := cs_space;

    /* Variable Initialization */
    ls_orderno3  := cs_space;

    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    IF SUBSTRING(ps_orderno, 1, 1) >= '0' AND SUBSTRING(ps_orderno, 1, 1) <= '9' AND
       SUBSTRING(ps_orderno, 2, 1) >= '0' AND SUBSTRING(ps_orderno, 2, 1) <= '9' AND
       SUBSTRING(ps_orderno, 3, 1) >= '0' AND SUBSTRING(ps_orderno, 3, 1) <= '9' AND
       SUBSTRING(ps_orderno, 4, 1) >= '0' AND SUBSTRING(ps_orderno, 4, 1) <= '9' AND
       SUBSTRING(ps_orderno, 5, 1) >= '0' AND SUBSTRING(ps_orderno, 5, 1) <= '9' THEN
        ls_orderno3 := SUBSTRING(ps_orderno, 3, 3);
    ELSE
        ls_orderno3 := SUBSTRING(ps_orderno, 1, 1) || SUBSTRING(ps_orderno, 4, 2);
    END IF;

    /* Return Value Set */
    rn_status    := 0;
    rs_sql_code  := cs_space;
    rs_err_code  := cs_space;
    rs_err_msg   := cs_space;
    rs_err_focus := cs_space;
    rs_orderno   := ls_orderno3;

    --------------------------------------------------
    --  < STEP3 : Return Value Processing >
    --------------------------------------------------
    RETURN NEXT;
    RETURN;
EXCEPTION
    WHEN RAISE_EXCEPTION THEN
        IF rn_status <> 0 THEN  -- FOR CALL SP ERROR
            NULL;
        ELSE                    -- FOR PGM ERROR
            rn_status    := -2;
            rs_sql_code  := ' ';
        END IF;
        rs_err_focus := cs_pgmid;

        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN            -- FOR SQL ERROR
        rn_status    := -1;
        rs_sql_code  := SQLSTATE;
        rs_err_code  := cs_space;
        rs_err_msg   := SQLERRM;
        rs_err_focus := cs_pgmid;
        rs_orderno   := cs_space;

        RETURN NEXT;
        RETURN;
END;
$BODY$
LANGUAGE 'plpgsql';