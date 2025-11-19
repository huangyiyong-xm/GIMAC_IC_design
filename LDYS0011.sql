--------------------------------------------------------------------------------
--@SEE << Update ic_pymac_date Table Process >>
--    @ID      : LDYS0011
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
--    @ps_mode                     < /I> VARCHAR   : Mode
--    @ps_process_id               < /I> VARCHAR   : Process ID
--  < OUTPUT Parameter >
--    @rn_status                   < /O> INTEGER   : Return Code
--                                                   (   0 : Normal        )
--                                                   ( 100 : Notfound      )
--                                                   (  -1 : Sql Error     )
--                                                   (  -2 : Program Error )
--    @rs_sql_code                 < /O> VARCHAR   : Sql Error Code
--    @rs_err_code                 < /O> VARCHAR   : Program Error Code
--    @rs_err_msg                  < /O> VARCHAR   : Error Message
--    @rs_err_focus                < /O> VARCHAR   : Error Focus
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0011(
    ps_mode             VARCHAR,    --1. 処理モード
    ps_process_id       VARCHAR     --2. 処理ID
)
RETURNS TABLE(
    rn_status           INTEGER,    --1. ステータス
    rs_sql_code         VARCHAR,    --2. SQLコード
    rs_err_code         VARCHAR,    --3. エラーコード
    rs_err_msg          VARCHAR,    --4. エラーメッセージ
    rs_err_focus        VARCHAR     --5. エラー位置
) AS
$BODY$
DECLARE
    --------------------------------------------------
    --  < Definition Local Paramater >
    --------------------------------------------------
    ls_ic_slip_date     DATE;
    ls_base_datetime    ld_mst_slip_date.base_datetime%TYPE;
    ls_system_date      TIMESTAMP;
    ls_new_ic_slip_date DATE;

    cs_space            CONSTANT CHAR(1) := ' ';
    cs_pgmid            CONSTANT CHAR(8) := 'LDYS0011';
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    rn_status           := 0;
    rs_sql_code         := cs_space;
    rs_err_code         := cs_space;
    rs_err_msg          := cs_space;
    rs_err_focus        := cs_space;

    ls_ic_slip_date     := NULL;
    ls_base_datetime    := NULL;
    ls_new_ic_slip_date := NULL;
    ls_system_date      := CURRENT_TIMESTAMP;

    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    IF EXISTS (
        SELECT 1 
          FROM ld_mst_slip_date 
         WHERE operation_type = ps_process_id
    ) THEN
        SELECT TO_DATE(ic_slip_date, 'YYYYMMDD')
             , base_datetime
          INTO ls_ic_slip_date
             , ls_base_datetime
          FROM ld_mst_slip_date
         WHERE operation_type = ps_process_id;
    ELSE
        rn_status    := -2;
        rs_err_code  := 'ld.E.LDP10004';
        rs_err_msg   := 'The IC pymac date is not exist.';
        RAISE EXCEPTION ' ';
    END IF;

    CASE
        WHEN UPPER(ps_mode) = 'A' THEN
            UPDATE ld_mst_slip_date
               SET base_datetime  = ls_system_date,
                   update_author  = cs_pgmid,
                   update_counter = update_counter + 1,
                   update_datetime= ls_system_date,
                   update_pgmid   = cs_pgmid
             WHERE operation_type = ps_process_id;

        WHEN UPPER(ps_mode) = 'B' THEN
            ls_new_ic_slip_date := ls_base_datetime::date + INTERVAL '1 day';

            IF ls_new_ic_slip_date >= ls_ic_slip_date THEN
                UPDATE ld_mst_slip_date
                   SET ic_slip_date   = TO_CHAR(ls_new_ic_slip_date, 'YYYYMMDD'),
                       update_author  = cs_pgmid,
                       update_counter = update_counter + 1,
                       update_datetime= ls_system_date,
                       update_pgmid   = cs_pgmid
                 WHERE operation_type = ps_process_id;
            ELSE
                rn_status    := -2;
                rs_err_code  := 'ld.E.LDP10135';
                rs_err_msg   := 'Specify the date latter than the system date.Not Update :: (New gimac_date [' || TO_CHAR(ls_new_ic_slip_date, 'YYYYMMDD') || ']) < (Current gimac_date [' || TO_CHAR(ls_ic_slip_date, 'YYYYMMDD') || '])';
                RAISE EXCEPTION ' ';
            END IF;

        WHEN UPPER(ps_mode) = 'C' THEN
            IF TO_CHAR(ls_base_datetime, 'DD') > '15' THEN
                ls_new_ic_slip_date := TO_DATE(SUBSTRING(TO_CHAR(ls_base_datetime, 'YYYYMMDD'), 1, 6) || '01', 'YYYYMMDD');
                ls_new_ic_slip_date := ls_new_ic_slip_date + INTERVAL '1 month';
            ELSE
                ls_new_ic_slip_date := TO_DATE(TO_CHAR(ls_base_datetime, 'YYYYMM') || '01', 'YYYYMMDD');
            END IF;

            IF ls_new_ic_slip_date > ls_ic_slip_date THEN
                UPDATE ld_mst_slip_date
                   SET ic_slip_date   = TO_CHAR(ls_new_ic_slip_date, 'YYYYMMDD'),
                       update_author  = cs_pgmid,
                       update_counter = update_counter + 1,
                       update_datetime= ls_system_date,
                       update_pgmid   = cs_pgmid
                 WHERE operation_type = ps_process_id;
            ELSE
                rn_status    := -2;
                rs_err_code  := 'ld.E.LDP10135';
                rs_err_msg   := 'Specify the date latter than the system date.Not Update :: (New gimac_date [' || TO_CHAR(ls_new_ic_slip_date, 'YYYYMMDD') || ']) < (Current gimac_date [' || TO_CHAR(ls_ic_slip_date, 'YYYYMMDD') || '])';
                RAISE EXCEPTION ' ';
            END IF;

        WHEN UPPER(ps_mode) = 'D' THEN
            ls_new_ic_slip_date := ls_system_date::date;

            IF ls_new_ic_slip_date >= ls_ic_slip_date THEN
                UPDATE ld_mst_slip_date
                   SET ic_slip_date   = TO_CHAR(ls_new_ic_slip_date, 'YYYYMMDD'),
                       update_author  = cs_pgmid,
                       update_counter = update_counter + 1,
                       update_datetime= ls_system_date,
                       update_pgmid   = cs_pgmid
                 WHERE operation_type = ps_process_id;
            ELSE
                rn_status    := -2;
                rs_err_code  := 'ld.E.LDP10135';
                rs_err_msg   := 'Specify the date latter than the system date.Not Update :: (New gimac_date [' || TO_CHAR(ls_new_ic_slip_date, 'YYYYMMDD') || ']) < (Current gimac_date [' || TO_CHAR(ls_ic_slip_date, 'YYYYMMDD') || '])';
                RAISE EXCEPTION ' ';
            END IF;

        WHEN LENGTH(ps_mode) = 8 THEN
            ls_new_ic_slip_date := TO_DATE(ps_mode, 'YYYYMMDD');

            UPDATE ld_mst_slip_date
               SET ic_slip_date   = TO_CHAR(ls_new_ic_slip_date, 'YYYYMMDD'),
                   base_datetime  = TO_TIMESTAMP(TO_CHAR(ls_new_ic_slip_date, 'YYYYMMDD'), 'YYYYMMDD'),
                   update_author  = cs_pgmid,
                   update_counter = update_counter + 1,
                   update_datetime= ls_system_date,
                   update_pgmid   = cs_pgmid
             WHERE operation_type = ps_process_id;

        ELSE
            rn_status    := -2;
            rs_err_code  := 'ld.E.LDP10011';
            rs_err_msg   := 'Subtraction value error has occurred in the internal processing. Contact the staff in charge of the system.Argument Error.  : Arg1 = [' || TRIM(ps_mode) || ']';
            RAISE EXCEPTION ' ';
    END CASE;

    --------------------------------------------------
    --  < STEP3 : Return Value Setting >
    --------------------------------------------------
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
            rs_sql_code   := cs_space;
        END IF;

        rs_err_focus      := cs_pgmid;
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
LANGUAGE plpgsql;