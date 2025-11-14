--------------------------------------------------------------------------------
--@SEE << Operation State Confirm >>
--    @ID      : LDYS0000
--
--    @Written : 1.0.0                   2025.10.13 Zhang Yulin / YMSLX
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
    rn_status           INTEGER,              --1. 処理ステータス
    rs_sql_code         VARCHAR,              --2. SQLコード
    rs_err_code         VARCHAR,              --3. エラーコード
    rs_err_msg          VARCHAR,              --4. エラーメッセージ
    rs_err_focus        VARCHAR,              --5. エラー位置
    rs_operation_status VARCHAR,              --6. 稼動ステータス
    rs_system_msg       VARCHAR,              --7. システムメッセージ
    rs_operation_msg    VARCHAR               --8. 稼動メッセージ
) AS
$BODY$
DECLARE
    --------------------------------------------------
    --  < Definition Local Paramater >
    --------------------------------------------------
    ls_ope_status                      lz_ope_state.ope_status%TYPE;
    ls_system_msg                      VARCHAR;
    ls_ope_remark                      lz_ope_state.ope_remark%TYPE;
    ld_update_update_datetime          lz_ope_state.update_datetime%TYPE;
    ls_supply_status                   ld_mst_st_control.supply_status%TYPE;
    ls_st_status                       ld_mst_st_control.st_status%TYPE;
    cs_pgmid                           CONSTANT VARCHAR := 'LDYS0000';
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    rn_status                := 0;
    rs_sql_code              := ' ';
    rs_err_code              := ' ';
    rs_err_msg               := ' ';
    rs_err_focus             := ' ';
    rs_operation_status      := ' ';
    rs_system_msg            := ' ';
    rs_operation_msg         := ' ';
    ls_ope_status            := ' ';
    ls_system_msg            := ' ';
    ls_ope_remark            := ' ';
    ld_update_update_datetime:= NULL;
    ls_supply_status         := ' ';
    ls_st_status             := ' ';

    --------------------------------------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------------------------------------
    IF EXISTS (
        SELECT 1
          FROM ld_mst_st_control b
         WHERE b.st_ymd = (
                SELECT MAX(st_ymd)
                  FROM ld_mst_st_control b
                 WHERE b.st_class IN('1','2')
             )
    ) THEN
        SELECT supply_status
             , st_status
          INTO ls_supply_status
             , ls_st_status
          FROM ld_mst_st_control a
         WHERE a.st_ymd = (
                SELECT MAX(st_ymd)
                  FROM ld_mst_st_control b
                 WHERE b.st_class IN('1','2')
             );
    END IF;

    IF ls_supply_status = '1' 
       AND ls_st_status IN ('0','1','2','3','4') THEN
        ls_ope_status    := 'U';
        ls_system_msg    := '有償支給残高 報告可能';
        ls_ope_remark    := '有償支給残高 報告可能';
    ELSE
        IF EXISTS (
            SELECT 1
              FROM lz_ope_state
             WHERE system_code = 'LD'
        ) THEN
            SELECT ope_status
                 , ope_remark
                 , update_datetime
              INTO ls_ope_status
                 , ls_ope_remark
                 , ld_update_update_datetime
              FROM lz_ope_state
             WHERE system_code = 'LD';
        END IF;

        IF ls_ope_status = 'U' THEN
            ls_system_msg := ld_update_update_datetime || ' より通常業務稼働中';
        ELSIF ls_ope_status = 'X' THEN
            ls_system_msg := ld_update_update_datetime || ' よりシステム処理中';
        ELSIF ls_ope_status = 'S' THEN
            ls_system_msg := ld_update_update_datetime || ' より一時機能制限中';
        ELSE
            ls_system_msg := 'ＳＴＳ判定不能！ 担当者に連絡して下さい。';
        END IF;
    END IF;

    --------------------------------------------------------------------------------
    --  < STEP3 : Return Value Setting >
    --------------------------------------------------------------------------------
    rs_operation_status := ls_ope_status;
    rs_system_msg       := ls_system_msg;
    rs_operation_msg    := ls_ope_remark;

    rn_status := 0;
    RETURN NEXT;
    RETURN;

EXCEPTION
    --------------------------------------------------------------------------------
    --  Error Handle
    --------------------------------------------------------------------------------
    WHEN OTHERS THEN
    rn_status           := -1;
    rs_sql_code         := SQLSTATE;
    rs_err_code         := ' ';
    rs_err_msg          := SQLERRM;
    rs_err_focus        := cs_pgmid;
    rs_operation_status := ' ';
    rs_system_msg       := ' ';
    rs_operation_msg    := ' ';
    RETURN NEXT;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;