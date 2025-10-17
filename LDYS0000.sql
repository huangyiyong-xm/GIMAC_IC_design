--------------------------------------------------------------------------------
--@SEE << Operation State Confirm >>
--    @ID      : LDYS0000
--
--    @Written : 1.0.0                   2025.10.13 Zhang Yulin / YMSL
--    --------------------------------------------------------------------------
--    @Update  : xxxxxxxxxxxx            xxxx.xx.xx xxxxxxxx / xx
--     Reason  : xxx
--              xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--------------------------------------------------------------------------------
--@SEE < Operation State Confirm >
--------------------------------------------------------------------------------
--  < INPUT Parameter >
--    (none)
--  < OUTPUT Parameter >
--    @rn_status                   < /O> INTEGER   : Return Code
--                                                   (  0 : Normal        )
--                                                   ( -1 : Sql Error     )
--                                                   ( -2 : Program Error )
--    @rs_sql_code                 < /O> VARCHAR   : Sql Error Code
--    @rs_err_code                 < /O> VARCHAR   : Program Error Code
--    @rs_err_msg                  < /O> VARCHAR   : Error Message
--    @rs_err_focus                < /O> VARCHAR   : Error Focus
--    @rs_operation_status         < /O> VARCHAR   : Operation Status
--    @rs_system_msg               < /O> VARCHAR   : System Message
--    @rs_operation_msg            < /O> VARCHAR   : Operation Message
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0000()
RETURNS TABLE(
    rn_status           INTEGER,              --1
    rs_sql_code         VARCHAR,              --2
    rs_err_code         VARCHAR,              --3
    rs_err_msg          VARCHAR,              --4
    rs_err_focus        VARCHAR,              --5
    rs_operation_status VARCHAR,              --6
    rs_system_msg       VARCHAR,              --7
    rs_operation_msg    VARCHAR               --8
) AS
$$
DECLARE
    ls_ope_status         gimac.lz_ope_state.ope_status%TYPE:= ' ';
    ls_system_msg         VARCHAR := ' ';
    ls_operation_msg      gimac.lz_ope_state.ope_remark%TYPE:= ' ';
    ls_update_dt          gimac.lz_ope_state.update_datetime%TYPE:= ' ';
    ls_yushi_status       gimac.ld_mst_st_control.supply_status%TYPE:= ' ';
    ls_shanai_status      gimac.ld_mst_st_control.st_status%TYPE:= ' ';
BEGIN
    --------------------------------------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------------------------------------
    rn_status           := 0;
    rs_sql_code         := ' ';
    rs_err_code         := ' ';
    rs_err_msg          := ' ';
    rs_err_focus        := ' ';
    rs_operation_status := ' ';
    rs_system_msg       := ' ';
    rs_operation_msg    := ' ';

    --------------------------------------------------------------------------------
    --  < STEP2 : Argument Check >
    --------------------------------------------------------------------------------
    -- No input parameter. No argument check needed.

    --------------------------------------------------------------------------------
    --  < STEP3 : Main Processing >
    --------------------------------------------------------------------------------
    SELECT supply_status
         , st_status
      INTO ls_yushi_status
         , ls_shanai_status
      FROM ld_mst_st_control a
     WHERE a.st_ymd = (
            SELECT MAX(st_ymd)
              FROM ld_mst_st_control b
             WHERE b.st_class IN('1','2')
         );

    IF ls_yushi_status IS NOT NULL AND ls_yushi_status <> ' ' 
       AND ls_yushi_status = '1' 
       AND ls_shanai_status IN ('0','1','2','3','4','5','6','9') THEN
        ls_ope_status    := 'U';
        ls_system_msg    := '有償支給残高 報告可能';
        ls_operation_msg := '有償支給残高 報告可能';
    ELSE
        SELECT ope_status
             , ope_remark
             , update_datetime
          INTO ls_ope_status
             , ls_operation_msg
             , ls_update_dt
          FROM lz_ope_state
         WHERE system_code = 'LD';

        IF ls_ope_status = 'U' THEN
            ls_system_msg := ls_update_dt || ' より通常業務稼働中';
        ELSIF ls_ope_status = 'X' THEN
            ls_system_msg := ls_update_dt || ' よりシステム処理中';
        ELSIF ls_ope_status = 'S' THEN
            ls_system_msg := ls_update_dt || ' より一時機能制限中';
        ELSE
            ls_system_msg := 'ＳＴＳ判定不能！ 担当者に連絡して下さい。';
        END IF;
    END IF;

    --------------------------------------------------------------------------------
    --  < STEP4 : Return Value Setting >
    --------------------------------------------------------------------------------
    rs_operation_status := ls_ope_status;
    rs_system_msg      := ls_system_msg;
    rs_operation_msg   := ls_operation_msg;

    rn_status := 0;
    RETURN NEXT;
    RETURN;

EXCEPTION
    --------------------------------------------------------------------------------
    --  Error Handle
    --------------------------------------------------------------------------------
    WHEN RAISE_EXCEPTION THEN
        IF rn_status <> 0 THEN
            NULL;
        ELSE
            rn_status         := -2;
            rs_sql_code       := ' ';
            rs_err_code       := ' ';
            rs_err_msg        := 'PGM Error';
            rs_err_focus      := 'LDYS0000';
        END IF;

        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN
        rn_status             := -1;
        rs_sql_code           := SQLSTATE;
        rs_err_code           := ' ';
        rs_err_msg            := SQLERRM;
        rs_err_focus          := 'LDYS0000';
        rs_operation_status   := ' ';
        rs_system_msg         := ' ';
        rs_operation_msg      := ' ';

        RETURN NEXT;
        RETURN;
END;
$$
LANGUAGE 'plpgsql';