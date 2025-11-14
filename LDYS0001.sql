--------------------------------------------------------------------------------
--@SEE << Date Edit yyMMdd -> yyyyMMdd >>
--    @ID      : LDYS0001
--
--    @Written : 1.0.0                   2025.09.10 Zhang Yulin / YMSLX
--    --------------------------------------------------------------------------
--    @Update  : xxxxxxxxxxxx            xxxx.xx.xx xxxxxxxx / xx
--     Reason  : xxx
--              xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--
--------------------------------------------------------------------------------
--  < INPUT Parameter >
--    @ps_date_yymmdd                < /I> VARCHAR   : Date (yyMMdd)
--  < OUTPUT Parameter >
--    @rn_status                     < /O> INTEGER   : Return Code
--                                                     (  0 : Normal        )
--                                                     ( -1 : Sql Error     )
--                                                     ( -2 : Program Error )
--                                                     (  1 : Warning       )
--    @rs_sql_code                   < /O> VARCHAR   : Sql Error Code
--    @rs_err_code                   < /O> VARCHAR   : Program Error Code
--    @rs_err_msg                    < /O> VARCHAR   : Error Message
--    @rs_err_focus                  < /O> VARCHAR   : Error Focus
--    @rs_date_yyyymmdd              < /O> VARCHAR   : Date (yyyyMMdd)
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0001(
    ps_date_yymmdd   VARCHAR     --1
)
RETURNS TABLE(
    rn_status        INTEGER,    --1. 処理ステータス
    rs_sql_code      VARCHAR,    --2. SQLコード
    rs_err_code      VARCHAR,    --3. エラーコード
    rs_err_msg       VARCHAR,    --4. エラーメッセージ
    rs_err_focus     VARCHAR,    --5. エラー位置
    rs_date_yyyymmdd VARCHAR     --6. 日付（８桁）
) AS
$BODY$
DECLARE
    ls_date            VARCHAR;
    cs_pgmid           VARCHAR := 'LDYS0001';
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    /* Return Value Set */
    rn_status         :=   0;
    rs_sql_code       := ' ';
    rs_err_code       := ' ';
    rs_err_msg        := ' ';
    rs_err_focus      := ' ';
    rs_date_yyyymmdd  := ' ';
    /* Local Variable Set */
    ls_date           := ' ';

    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    IF ps_date_yymmdd = '999999' THEN
        ls_date := '99999999';
    ELSE
        IF TRIM(ps_date_yymmdd) = '' THEN
            ls_date := ' ';
        ELSE
            IF SUBSTR(ps_date_yymmdd, 1, 2) > '80' THEN
                ls_date := '19' || ps_date_yymmdd;
            ELSE
                ls_date := '20' || ps_date_yymmdd;
            END IF;
        END IF;
    END IF;

    rn_status        :=   0;
    rs_sql_code      := ' ';
    rs_err_code      := ' ';
    rs_err_msg       := ' ';
    rs_err_focus     := ' ';
    rs_date_yyyymmdd := ls_date;

    RETURN NEXT;
    RETURN;

EXCEPTION
    --------------------------------------------------
    --  Error Handle
    --------------------------------------------------
    WHEN RAISE_EXCEPTION THEN
        IF rn_status <> 0 THEN  -- FOR CALL SP ERROR
            NULL;
        ELSE                    -- FOR PGM ERROR
            rn_status     :=  -2;
            rs_sql_code   := ' ';
        END IF;

        rs_err_focus      := cs_pgmid;
        rs_date_yyyymmdd  := ' ';

        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN            -- FOR SQL ERROR
        rn_status         := -1;
        rs_sql_code       := SQLSTATE;
        rs_err_code       := ' ';
        rs_err_msg        := SQLERRM;
        rs_err_focus      := cs_pgmid;
        rs_date_yyyymmdd  := ' ';

        RETURN NEXT;
        RETURN;
END;
$BODY$
LANGUAGE plpgsql;