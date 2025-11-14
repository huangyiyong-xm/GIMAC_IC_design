--------------------------------------------------------------------------------
--@SEE << Factory Processing Date Setting >>
--    @ID      : LDYS0011
--
--    @Written : 1.0.0                   2025.10.13 Zhang Yulin / YMSL
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
    ps_mode VARCHAR,
    ps_process_id VARCHAR
)
RETURNS TABLE(
    rn_status           INTEGER,
    rs_sql_code         VARCHAR,
    rs_err_code         VARCHAR,
    rs_err_msg          VARCHAR,
    rs_err_focus        VARCHAR
) AS
$$
DECLARE
    -- 使用表字段类型（带 schema 前缀）
    ls_ic_slip_date     gimac.ld_mst_slip_date.ic_slip_date%TYPE := ' ';
    ls_base_datetime    gimac.ld_mst_slip_date.base_datetime%TYPE := NULL;
    ls_system_date      DATE := CURRENT_DATE;
    ls_new_ic_slip_date gimac.ld_mst_slip_date.ic_slip_date%TYPE := ' ';
BEGIN
    --------------------------------------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------------------------------------
    rn_status    := 0;
    rs_sql_code  := ' ';
    rs_err_code  := ' ';
    rs_err_msg   := ' ';
    rs_err_focus := ' ';

    --------------------------------------------------------------------------------
    --  < STEP2 : Argument Check >
    --------------------------------------------------------------------------------
    IF ps_mode IS NULL OR ps_process_id IS NULL THEN
        rn_status    := -2;
        rs_err_code  := 'E000';
        rs_err_msg   := 'Argument Error. : Arg1 = [' || COALESCE(TRIM(ps_mode), '') || '], Arg2 = [' || COALESCE(TRIM(ps_process_id), '') || ']';
        rs_err_focus := 'LDYS0011';
        RAISE EXCEPTION 'PGM_ERROR';
    END IF;

    --------------------------------------------------------------------------------
    --  < STEP3 : Main Processing >
    --------------------------------------------------------------------------------
    SELECT ic_slip_date,
           base_datetime
      INTO ls_ic_slip_date,
           ls_base_datetime
      FROM ld_mst_slip_date
     WHERE operation_type = ps_process_id;

    IF NOT FOUND THEN
        rn_status    := 100;
        rs_err_code  := 'LDP10911';
        rs_err_msg   := 'The IC pymac date is not exist.';
        rs_err_focus := 'LDYS0011';
        RAISE EXCEPTION 'NOT_FOUND';
    END IF;

    CASE
        WHEN UPPER(ps_mode) = 'A' THEN
            UPDATE ld_mst_slip_date
               SET base_datetime  = TO_TIMESTAMP(TO_CHAR(ls_system_date, 'YYYYMMDD'), 'YYYYMMDD'),
                   update_author  = 'LDYS0011',
                   update_counter = update_counter + 1,
                   update_datetime= CURRENT_TIMESTAMP,
                   update_pgmid   = 'LDYS0011'
             WHERE operation_type = ps_process_id;

        WHEN UPPER(ps_mode) = 'B' THEN
            -- base_datetime + 1 天
            ls_new_ic_slip_date := TO_CHAR((ls_base_datetime::date + INTERVAL '1 day')::date, 'YYYYMMDD');

            IF TO_DATE(ls_new_ic_slip_date, 'YYYYMMDD') >= TO_DATE(ls_ic_slip_date, 'YYYYMMDD') THEN
                UPDATE ld_mst_slip_date
                   SET ic_slip_date   = ls_new_ic_slip_date,
                       update_author  = 'LDYS0011',
                       update_counter = update_counter + 1,
                       update_datetime= CURRENT_TIMESTAMP,
                       update_pgmid   = 'LDYS0011'
                 WHERE operation_type = ps_process_id;
            ELSE
                rn_status    := -2;
                rs_err_code  := 'W001';
                rs_err_msg   := 'Not Update :: (New pymac_date [' || TRIM(ls_new_ic_slip_date) || ']) < (Current pymac_date [' || TRIM(ls_ic_slip_date) || '])';
                rs_err_focus := 'LDYS0011';
                RAISE EXCEPTION 'PGM_WARNING';
            END IF;

        WHEN UPPER(ps_mode) = 'C' THEN
            IF TO_CHAR(ls_base_datetime, 'DD') > '15' THEN
                ls_new_ic_slip_date := TO_CHAR( (date_trunc('month', ls_base_datetime)::date + INTERVAL '1 month')::date, 'YYYYMMDD');
            ELSE
                ls_new_ic_slip_date := TO_CHAR( date_trunc('month', ls_base_datetime)::date, 'YYYYMMDD');
            END IF;

            IF TO_DATE(ls_new_ic_slip_date, 'YYYYMMDD') > TO_DATE(ls_ic_slip_date, 'YYYYMMDD') THEN
                UPDATE ld_mst_slip_date
                   SET ic_slip_date   = ls_new_ic_slip_date,
                       update_author  = 'LDYS0011',
                       update_counter = update_counter + 1,
                       update_datetime= CURRENT_TIMESTAMP,
                       update_pgmid   = 'LDYS0011'
                 WHERE operation_type = ps_process_id;
            ELSE
                rn_status    := -2;
                rs_err_code  := 'W001';
                rs_err_msg   := 'Not Update :: (New pymac_date [' || TRIM(ls_new_ic_slip_date) || ']) < (Current pymac_date [' || TRIM(ls_ic_slip_date) || '])';
                rs_err_focus := 'LDYS0011';
                RAISE EXCEPTION 'PGM_WARNING';
            END IF;

        WHEN UPPER(ps_mode) = 'D' THEN
            ls_new_ic_slip_date := TO_CHAR(ls_system_date, 'YYYYMMDD');

            IF TO_DATE(ls_new_ic_slip_date, 'YYYYMMDD') >= TO_DATE(ls_ic_slip_date, 'YYYYMMDD') THEN
                UPDATE ld_mst_slip_date
                   SET ic_slip_date   = ls_new_ic_slip_date,
                       update_author  = 'LDYS0011',
                       update_counter = update_counter + 1,
                       update_datetime= CURRENT_TIMESTAMP,
                       update_pgmid   = 'LDYS0011'
                 WHERE operation_type = ps_process_id;
            ELSE
                rn_status    := -2;
                rs_err_code  := 'W001';
                rs_err_msg   := 'Not Update :: (New pymac_date [' || TRIM(ls_new_ic_slip_date) || ']) < (Current pymac_date [' || TRIM(ls_ic_slip_date) || '])';
                rs_err_focus := 'LDYS0011';
                RAISE EXCEPTION 'PGM_WARNING';
            END IF;

        WHEN LENGTH(ps_mode) = 8 THEN
            ls_new_ic_slip_date := TO_CHAR(TO_DATE(ps_mode, 'YYYYMMDD'), 'YYYYMMDD');

            UPDATE ld_mst_slip_date
               SET ic_slip_date   = ls_new_ic_slip_date,
                   base_datetime  = TO_TIMESTAMP(ls_new_ic_slip_date, 'YYYYMMDD'),
                   update_author  = 'LDYS0011',
                   update_counter = update_counter + 1,
                   update_datetime= CURRENT_TIMESTAMP,
                   update_pgmid   = 'LDYS0011'
             WHERE operation_type = ps_process_id;

        ELSE
            rn_status    := -2;
            rs_err_code  := 'E000';
            rs_err_msg   := 'Argument Error.  : Arg1 = [' || TRIM(ps_mode) || ']';
            rs_err_focus := 'LDYS0011';
            RAISE EXCEPTION 'PGM_ERROR';
    END CASE;

    --------------------------------------------------------------------------------
    --  < STEP4 : Return Value Setting >
    --------------------------------------------------------------------------------
    RETURN NEXT;
    RETURN;

EXCEPTION
    ----------------------------------------------------------------------------
    --  Error Handle
    ----------------------------------------------------------------------------
    WHEN raise_exception THEN
        IF rn_status <> 0 THEN
            NULL;
        ELSE
            rn_status    := -2;
            rs_sql_code  := ' ';
            rs_err_code  := 'E000';
            rs_err_msg   := 'Program Error.';
            rs_err_focus := 'LDYS0011';
        END IF;
        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN
        rn_status    := -1;
        rs_sql_code  := SQLSTATE;
        rs_err_code  := ' ';
        rs_err_msg   := SQLERRM;
        rs_err_focus := 'LDYS0011';
        RETURN NEXT;
        RETURN;
END;
$$
LANGUAGE plpgsql;