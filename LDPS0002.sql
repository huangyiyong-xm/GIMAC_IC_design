--------------------------------------------------------------------------------
--@SEE << IC Main Proc - MRP Demand Policy Code Change >>
--    @ID      : LDPS0002
--
--    @Written : 1.0.0                   2025.11.5 Zhang Yulin / YMSLX
--    --------------------------------------------------------------------------
--    @Update  : xxxxxxxxxxxx            xxxx.xx.xx xxxxxxxx / xx
--     Reason  : xxx
--              xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--------------------------------------------------------------------------------
--  < INPUT Parameter >
--    (none)
--  < OUTPUT Parameter >
--    @rn_status                   < /O> INTEGER   : Return Code
--                                                   (  0 : Normal        )
--                                                   ( -1 : Sql Error     )
--                                                   ( -2 : Program Error )
--                                                   (100 : NotDataFound  )
--    @rs_sql_code                 < /O> VARCHAR   : Sql Error Code
--    @rs_err_code                 < /O> VARCHAR   : Program Error Code
--    @rs_err_msg                  < /O> VARCHAR   : Error Message
--    @rs_err_focus                < /O> VARCHAR   : Error Focus
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDPS0002()
RETURNS TABLE(
    rn_status           INTEGER,              --1. 処理ステータス
    rs_sql_code         VARCHAR,              --2. SQLコード
    rs_err_code         VARCHAR,              --3. エラーコード
    rs_err_msg          VARCHAR,              --4. エラーメッセージ
    rs_err_focus        VARCHAR               --5. エラー位置
) AS
$BODY$
DECLARE
    --------------------------------------------------
    --  < Definition Local Paramater >
    --------------------------------------------------
    cs_pgmid                                          CONSTANT VARCHAR := 'LDPS0002';
    cs_input_txn_ic_rev                               CONSTANT VARCHAR := 'IC_REV';
    cs_space                                          CONSTANT VARCHAR := ' ';

    ls_parent_itemno                                  ld_trn_derev_trn.parent_itemno%TYPE;
    ls_parent_supplier                                ld_trn_derev_trn.parent_supplier%TYPE;
    ls_parent_usercd                                  ld_trn_derev_trn.parent_usercd%TYPE;
    ls_structure_seq                                  ld_trn_derev_trn.structure_seq%TYPE;
    ls_comp_itemno                                    ld_trn_derev_trn.comp_itemno%TYPE;
    ls_comp_supplier                                  ld_trn_derev_trn.comp_supplier%TYPE;
    ls_comp_usercd                                    ld_trn_derev_trn.comp_usercd%TYPE;
    ls_message_code                                   ld_trn_derev_trn.message_code%TYPE;
    ld_maintenance_datetime                           ld_trn_derev_trn.maintenance_datetime%TYPE;
    ls_demand_policy_code                             ld_trn_derev_trn.demand_policy_code%TYPE;

    ls_le_trn_order_forecast_order_no                 le_trn_order_forecast.order_no%TYPE;
    ls_le_trn_order_forecast_disburse_date            le_trn_order_forecast.disburse_date%TYPE;
    ls_le_trn_order_forecast_demand_policy_code       le_trn_order_forecast.demand_policy_code%TYPE;

    ln_call_status                                    INTEGER;
    ls_call_sql_code                                  VARCHAR;
    ls_call_err_code                                  VARCHAR;
    ls_call_err_msg                                   VARCHAR;
    ls_call_err_focus                                 VARCHAR;

    ln_derev_trn_count                                INTEGER;
    ln_order_forecast_count                           INTEGER;
    ln_order_delete_count                             INTEGER;

    rec_derev_trn                                     RECORD;
    rec_order_forecast                                RECORD;

BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    rn_status                                         := 0;
    rs_sql_code                                       := cs_space;
    rs_err_code                                       := cs_space;
    rs_err_msg                                        := cs_space;
    rs_err_focus                                      := cs_space;

    ls_parent_itemno                                  := cs_space;
    ls_parent_supplier                                := cs_space;
    ls_parent_usercd                                  := cs_space;
    ls_structure_seq                                  := cs_space;
    ls_comp_itemno                                    := cs_space;
    ls_comp_supplier                                  := cs_space;
    ls_comp_usercd                                    := cs_space;
    ls_message_code                                   := cs_space;
    ld_maintenance_datetime                           := NULL;
    ls_demand_policy_code                             := cs_space;

    ls_le_trn_order_forecast_order_no                 := cs_space;
    ls_le_trn_order_forecast_disburse_date            := cs_space;
    ls_le_trn_order_forecast_demand_policy_code       := cs_space;

    ln_call_status                                    := 0;
    ls_call_sql_code                                  := cs_space;
    ls_call_err_code                                  := cs_space;
    ls_call_err_msg                                   := cs_space;
    ls_call_err_focus                                 := cs_space;

    ln_derev_trn_count                                := 0;
    ln_order_forecast_count                           := 0;
    ln_order_delete_count                             := 0;

    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    
    FOR rec_derev_trn IN
        SELECT parent_itemno
             , parent_supplier
             , parent_usercd
             , structure_seq
             , comp_itemno
             , comp_supplier
             , comp_usercd
             , message_code
             , maintenance_datetime
             , demand_policy_code
          FROM ld_trn_derev_trn
         WHERE close_sign    = '0'
           AND message_code  = '100'
         ORDER BY parent_itemno
                , parent_supplier
                , parent_usercd
                , structure_seq
                , comp_itemno
                , comp_supplier
                , comp_usercd
                , maintenance_datetime
    LOOP
        ln_derev_trn_count := ln_derev_trn_count + 1;

        ls_parent_itemno           := rec_derev_trn.parent_itemno;
        ls_parent_supplier         := rec_derev_trn.parent_supplier;
        ls_parent_usercd           := rec_derev_trn.parent_usercd;
        ls_structure_seq           := rec_derev_trn.structure_seq;
        ls_comp_itemno             := rec_derev_trn.comp_itemno;
        ls_comp_supplier           := rec_derev_trn.comp_supplier;
        ls_comp_usercd             := rec_derev_trn.comp_usercd;
        ls_message_code            := rec_derev_trn.message_code;
        ld_maintenance_datetime    := rec_derev_trn.maintenance_datetime;
        ls_demand_policy_code      := rec_derev_trn.demand_policy_code;

        FOR rec_order_forecast IN
            SELECT order_no
                 , disburse_date
                 , demand_policy_code
              FROM le_trn_order_forecast
             WHERE itemno        = ls_parent_itemno
               AND supplier      = ls_parent_supplier
               AND usercd        = ls_parent_usercd
               AND order_status  = '0'
             ORDER BY order_no
        LOOP
            ln_order_forecast_count := ln_order_forecast_count + 1;

            ls_le_trn_order_forecast_order_no            := rec_order_forecast.order_no;
            ls_le_trn_order_forecast_disburse_date       := rec_order_forecast.disburse_date;
            ls_le_trn_order_forecast_demand_policy_code  := rec_order_forecast.demand_policy_code;

            -- Check deletion conditions
            -- Skip if any of the following conditions are met:
            -- 1. Order demand policy code is manual management ('1')
            -- 2. Order demand policy equals BOM revision demand policy
            -- 3. Both are MRP types ('3','4','5','6')
            IF ls_le_trn_order_forecast_demand_policy_code = '1' THEN
                CONTINUE;
            END IF;

            IF ls_le_trn_order_forecast_demand_policy_code = ls_demand_policy_code THEN
                CONTINUE;
            END IF;

            IF ls_le_trn_order_forecast_demand_policy_code IN ('3', '4', '5', '6')
               AND ls_demand_policy_code IN ('3', '4', '5', '6') THEN
                CONTINUE;
            END IF;

            ln_order_delete_count := ln_order_delete_count + 1;

            -- Call SP LDAS0414 to delete order detail
            SELECT sp.rn_status
                 , sp.rs_sql_code
                 , sp.rs_err_code
                 , sp.rs_err_msg
                 , sp.rs_err_focus
              INTO ln_call_status
                 , ls_call_sql_code
                 , ls_call_err_code
                 , ls_call_err_msg
                 , ls_call_err_focus
              FROM LDAS0414(
                       ls_parent_itemno
                     , ls_parent_supplier
                     , ls_parent_usercd
                     , ls_le_trn_order_forecast_order_no
                     , NULL
                     , cs_input_txn_ic_rev
                     , ''
                     , ''
                     , ''
                   ) AS sp;

            -- Check SP call result
            IF ln_call_status <> 0 THEN
                rn_status    := ln_call_status;
                rs_sql_code  := ls_call_sql_code;
                rs_err_code  := ls_call_err_code;
                rs_err_msg   := 'le_trn_order_forecast' 
                             || ' <<SP LDAS0414 Error Return>> ' 
                             || 'Return: ' 
                             || CAST(ln_call_status AS VARCHAR) || ', '
                             || COALESCE(ls_call_sql_code, '') || ', '
                             || COALESCE(ls_call_err_code, '') || ', '
                             || COALESCE(ls_call_err_msg, '') || ', '
                             || COALESCE(ls_call_err_focus, '');
                rs_err_focus := cs_pgmid;
                RAISE EXCEPTION '%', rs_err_msg;
            END IF;

        END LOOP;

        UPDATE ld_trn_derev_trn
           SET close_sign            = '1'
             , update_counter        = update_counter + 1
             , update_datetime       = CURRENT_TIMESTAMP
             , update_author         = cs_pgmid
             , update_pgmid          = cs_pgmid
         WHERE close_sign            = '0'
           AND parent_itemno         = ls_parent_itemno
           AND parent_supplier       = ls_parent_supplier
           AND parent_usercd         = ls_parent_usercd
           AND structure_seq         = ls_structure_seq
           AND comp_itemno           = ls_comp_itemno
           AND comp_supplier         = ls_comp_supplier
           AND comp_usercd           = ls_comp_usercd
           AND message_code          = ls_message_code
           AND maintenance_datetime  = ld_maintenance_datetime;

    END LOOP;

    RAISE NOTICE '<ld_trn_derev_trn> Read Count = %', ln_derev_trn_count;
    RAISE NOTICE '<le_trn_order_forecast> Read Count = %', ln_order_forecast_count;
    RAISE NOTICE '........................................ Delete Count = %', ln_order_delete_count;

    --------------------------------------------------
    --  < STEP3 : Return Value Setting >
    --------------------------------------------------
    RETURN NEXT;
    RETURN;

EXCEPTION
    --------------------------------------------------
    --  Error Handle
    --------------------------------------------------
    WHEN raise_exception THEN
        IF rn_status <> 0 THEN  -- FOR CALL SP ERROR
            NULL;
        ELSE                    -- FOR PGM ERROR
            rn_status    := -2;
            rs_sql_code  := cs_space;
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

        RETURN NEXT;
        RETURN;
END;
$BODY$
LANGUAGE plpgsql;