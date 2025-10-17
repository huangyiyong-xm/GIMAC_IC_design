--------------------------------------------------------------------------------
--@SEE << Date Edit (6 digits → 8 digits) >>
--    @ID      : LDYS0001
--
--    @Written : 1.0.0                   2025.09.10 Zhang Yulin / YMSL
--    --------------------------------------------------------------------------
--    @Update  : xxxxxxxxxxxx            xxxx.xx.xx xxxxxxxx / xx
--     Reason  : xxx
--              xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--
--------------------------------------------------------------------------------
--@SEE < Date Edit (6 digits → 8 digits) >
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
    ps_date_yymmdd VARCHAR
)
RETURNS TABLE(
    rn_status        INTEGER,   --1
    rs_sql_code      VARCHAR,   --2
    rs_err_code      VARCHAR,   --3
    rs_err_msg       VARCHAR,   --4
    rs_err_focus     VARCHAR,   --5
    rs_date_yyyymmdd VARCHAR    --6
) AS
$$
DECLARE
    ls_date_yyyymmdd VARCHAR := ' ';
BEGIN
    --------------------------------------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------------------------------------
    rn_status        := 0;
    rs_sql_code      := ' ';
    rs_err_code      := ' ';
    rs_err_msg       := ' ';
    rs_err_focus     := ' ';
    rs_date_yyyymmdd := ' ';
    ls_date_yyyymmdd := ' ';

    --------------------------------------------------------------------------------
    --  < STEP2 : Argument Check >
    --------------------------------------------------------------------------------
    --(none)
    --------------------------------------------------------------------------------
    --  < STEP3 : Main Processing >
    --------------------------------------------------------------------------------
    IF ps_date_yymmdd = '999999' THEN
        ls_date_yyyymmdd := '999999';
    ELSIF ps_date_yymmdd = '' OR ps_date_yymmdd IS NULL THEN
        ls_date_yyyymmdd := '';
    ELSE
        IF SUBSTRING(ps_date_yymmdd, 1, 2) > '80' THEN
            ls_date_yyyymmdd := '19' || ps_date_yymmdd;
        ELSE
            ls_date_yyyymmdd := '20' || ps_date_yymmdd;
        END IF;
    END IF;

    --------------------------------------------------------------------------------
    --  < STEP4 : Return Value Setting >
    --------------------------------------------------------------------------------
    rs_date_yyyymmdd := ls_date_yyyymmdd;
    rn_status := 0;
    RETURN NEXT;
    RETURN;

EXCEPTION
    --------------------------------------------------
    --  Error Handle
    --------------------------------------------------
    --  # Indispensability(End)
    --------------------------------------------------
    WHEN raise_exception THEN
        IF rn_status <> 0 THEN
            NULL;
        ELSE
            rn_status    := -2;
            rs_sql_code  := ' ';
            rs_err_code  := ' ';
            rs_err_msg   := 'PGM Error';
            rs_err_focus := 'LDYS0001';
        END IF;

        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN
        rn_status    := -1;
        rs_sql_code  := SQLSTATE;
        rs_err_code  := ' ';
        rs_err_msg   := SQLERRM;
        rs_err_focus := 'LDYS0001';

        RETURN NEXT;
        RETURN;
END;
$$
LANGUAGE plpgsql;