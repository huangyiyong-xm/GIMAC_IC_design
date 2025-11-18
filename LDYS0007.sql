--------------------------------------------------------------------------------
--@SEE << Get Pymac-Date Process. >>
--    @ID      : LDYS0007
--
--    @Written : 1.0.0                   2025.10.13 Sun Sheng / YMSLX
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--
----------------------------------------------------------------------------
--@SEE << Get Pymac-Date Process. >>
----------------------------------------------------------------------------
--  < INPUT Parameter >
--    @ps_process_id         <I/ >VARCHAR  : Process ID
--  < OUTPUT Parameter >
--    @rn_status             < /O> INTEGER :  Return Code
--                                                   (  0 : Normal        )
--                                                   ( -1 : Sql Error     )
--                                                   ( -2 : Program Error )
--    @rs_sql_code           < /O> VARCHAR : Sql Error Code
--    @rs_err_code           < /O> VARCHAR : Program Error Code
--    @rs_err_msg            < /O> VARCHAR : Error Message
--    @rs_err_focus          < /O> VARCHAR : Error Focus
--    @rs_Date_YYYYMMDD      < /O> VARCHAR : Date (YYYYMMDD)
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0007(
    ps_process_id VARCHAR       -- 1 処理ID
)
 RETURNS TABLE(
      rn_status        INTEGER  -- 1 処理ステータス
    , rs_sql_code      VARCHAR  -- 2 SQLコード
    , rs_err_code      VARCHAR  -- 3 エラーコード
    , rs_err_msg       VARCHAR  -- 4 エラーメッセージ
    , rs_err_focus     VARCHAR  -- 5 エラー位置
    , rs_Date_YYYYMMDD VARCHAR  -- 6 工場処理日
)AS
$BODY$
DECLARE
    ls_date              ld_mst_slip_date.ic_slip_date%type;
    cs_space             CONSTANT VARCHAR := ' ';
    cs_pgmid             CONSTANT VARCHAR := 'LDYS0007';
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    /* Return Value Set */
    rn_status         :=   0;
    rs_sql_code       := cs_space;
    rs_err_code       := cs_space;
    rs_err_msg        := cs_space;
    rs_err_focus      := cs_space;
    rs_Date_YYYYMMDD  := cs_space;

    ls_date           := cs_space;

    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    IF EXISTS (SELECT 1
                 FROM ld_mst_slip_date
                WHERE operation_type = ps_process_id
      )THEN
        SELECT ic_slip_date
          INTO ls_date
          FROM ld_mst_slip_date
         WHERE operation_type = ps_process_id;
        IF ls_date IS NULL OR ls_date = cs_space THEN
            rs_sql_code  := cs_space;
            rs_err_code  := 'ld.E.LDP10004';
            rs_err_msg   := 'The IC pymac date is not exist.';
            RAISE EXCEPTION ' ';
        END IF;
    ELSE
        rs_sql_code  := cs_space;
        rs_err_code  := 'ld.E.LDP10004';
        rs_err_msg   := 'The IC pymac date is not exist.';
        RAISE EXCEPTION ' ';

        RETURN NEXT;
        RETURN;
    END IF;

    -- Retrieve the value (STRICT to surface unexpected multiple rows)


    rn_status        :=   0;
    rs_sql_code      := cs_space;
    rs_err_code      := cs_space;
    rs_err_msg       := cs_space;
    rs_err_focus     := cs_space;
    rs_Date_YYYYMMDD := ls_date;

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
            rn_status         :=  -2;
            rs_sql_code       := cs_space;
        END IF;

        rs_err_focus          := cs_pgmid;
        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN            -- FOR SQL ERROR
        rn_status         := -1;
        rs_sql_code       := SQLSTATE;
        rs_err_code       := cs_space;
        rs_err_msg        := SQLERRM;
        rs_err_focus      := cs_pgmid;

        RETURN NEXT;
        RETURN;
END;
$BODY$
LANGUAGE 'plpgsql';
