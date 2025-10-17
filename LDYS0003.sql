--------------------------------------------------------------------------------
--  < Order Number Assignment >
--    @ID      : LDYS0003
--
--    @Written : 1.0.0                   2025.10.14 Zhang Yulin / YMSL
--    --------------------------------------------------------------------------
--    @Update  : xxxxxxxxxxxx            xxxx.xx.xx xxxxxxxx / xx
--     Reason  : xxx
--              xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--
--------------------------------------------------------------------------------
--    @$LastChangedDate:$
--    @$LastChangedRevision:$
--    @$LastChangedBy:$
--
--------------------------------------------------------------------------------
--  < INPUT Parameter >
--    @ps_user_id            <I/ > VARCHAR   : User ID
--    @ps_itemno             <I/ > VARCHAR   : Item Number
--    @ps_supplier           <I/ > VARCHAR   : Supplier
--    @ps_usercd             <I/ > VARCHAR   : User Code
--    @ps_input_class        <I/ > VARCHAR   : Input Class
--    @ps_pilot_class        <I/ > VARCHAR   : Pilot Class
--  < OUTPUT Parameter >
--    @rn_status                   < /O> INTEGER   : Return Code
--                                                   (  0 : Normal        )
--                                                   ( -1 : Sql Error     )
--                                                   ( -2 : Program Error )
--    @rs_sql_code                 < /O> VARCHAR   : Sql Error Code
--    @rs_err_code                  < /O> VARCHAR   : Program Error Code
--    @rs_err_msg                   < /O> VARCHAR   : Error Message
--    @rs_err_focus                 < /O> VARCHAR   : Error Focus
--    @rs_order_no                 < /O> VARCHAR   : Order Number
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0003(
    ps_user_id      IN VARCHAR,              --1
    ps_itemno       IN VARCHAR,              --2
    ps_supplier     IN VARCHAR,              --3
    ps_usercd       IN VARCHAR,              --4
    ps_input_class  IN VARCHAR,              --5
    ps_pilot_class  IN VARCHAR               --6
)
RETURNS TABLE(
    rn_status            INTEGER,              --1
    rs_sql_code          VARCHAR,              --2
    rs_err_code          VARCHAR,              --3
    rs_err_msg           VARCHAR,              --4
    rs_err_focus         VARCHAR,              --5
    rs_order_no          VARCHAR               --6
) AS
$BODY$
DECLARE
    ls_next_ohorder_ic     gimac.ld_trn_inv.next_ohorder_ic%TYPE := ' ';
    ls_next_odorder_ic     gimac.ld_trn_inv.next_odorder_ic%TYPE := ' ';
    ls_next_bhorder_ic     gimac.ld_trn_inv.next_bhorder_ic%TYPE := ' ';
    ls_next_bdorder_ic     gimac.ld_trn_inv.next_bdorder_ic%TYPE := ' ';
    ls_init_prefix_online  VARCHAR := ' ';
    ls_init_seq_online     VARCHAR := ' ';
    ls_init_prefix_batch   VARCHAR := ' ';
    ls_init_seq_batch      VARCHAR := ' ';
    ls_carry_flg           VARCHAR := '0';
    ls_loop_flg            VARCHAR := '0';
    ls_order_no            VARCHAR := ' ';
    ls_seq_max             VARCHAR := '9999';
BEGIN
    --------------------------------------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------------------------------------
    rn_status    := 0;
    rs_sql_code  := ' ';
    rs_err_code  := ' ';
    rs_err_msg   := ' ';
    rs_err_focus := ' ';
    rs_order_no  := ' ';

    --------------------------------------------------------------------------------
    --  < STEP2 : Inventory Record Existence Check >
    --------------------------------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1 
        FROM ld_trn_inv
       WHERE itemno = ps_itemno
         AND supplier = ps_supplier
         AND usercd = ps_usercd
    ) THEN
           rn_status := -1;
         rs_err_code := 'E.LDP10564';
          rs_err_msg := 'No framework for order number assignment remains.';
        rs_err_focus := 'LDYS0003';
        RETURN NEXT;
        RETURN;
    ELSE
        RAISE NOTICE 'Inventory record exists (itemno=%, supplier=%, usercd=%)', ps_itemno, ps_supplier, ps_usercd;
    END IF;

    --------------------------------------------------------------------------------
    --  < STEP3 : Update Inventory Record (Basic Info) >
    --------------------------------------------------------------------------------
    UPDATE ld_trn_inv
    SET ic_update_datetime = statement_timestamp(),
         update_author = ps_user_id,
          update_pgmid = 'LDYS0003',
        update_counter = COALESCE(update_counter, 0) + 1
    WHERE itemno = ps_itemno
      AND supplier = ps_supplier
      AND usercd = ps_usercd;

    --------------------------------------------------------------------------------
    --  < STEP4 : Get Next Order Number Configuration >
    --------------------------------------------------------------------------------
   SELECT next_ohorder_ic, 
           next_odorder_ic, 
           next_bhorder_ic, 
           next_bdorder_ic
     INTO ls_next_ohorder_ic, 
         ls_next_odorder_ic, 
         ls_next_bhorder_ic, 
         ls_next_bdorder_ic
     FROM ld_trn_inv
    WHERE itemno = ps_itemno
      AND supplier = ps_supplier
      AND usercd = ps_usercd;

    --------------------------------------------------------------------------------
    --  < STEP5 : Save Initial Configuration for Comparison >
    --------------------------------------------------------------------------------
    IF ps_input_class = '1' THEN
        ls_init_prefix_online := ls_next_ohorder_ic;
        ls_init_seq_online := ls_next_odorder_ic;
    ELSE
        ls_init_prefix_batch := ls_next_bhorder_ic;
        ls_init_seq_batch := ls_next_bdorder_ic;
    END IF;

    --------------------------------------------------------------------------------
    --  < STEP6 : Main Processing (Order Number Generation & Check) >
    --------------------------------------------------------------------------------
    WHILE ls_loop_flg = '0' LOOP
        IF ps_pilot_class IN ('2', '4') 
        THEN
            ls_order_no := CASE 
        WHEN ps_input_class = '1' 
        THEN 'M' || ls_next_odorder_ic 
        ELSE 'N' || ls_next_bdorder_ic 
        END;
        ELSE
            ls_order_no := CASE 
            WHEN ps_input_class = '1' 
            THEN TRIM(ls_next_ohorder_ic) || ls_next_odorder_ic 
            ELSE TRIM(ls_next_bhorder_ic) || ls_next_bdorder_ic 
            END;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM le_trn_order WHERE order_no = ls_order_no AND itemno = ps_itemno AND supplier = ps_supplier AND usercd = ps_usercd) 
        THEN
            ls_loop_flg := '1';
        END IF;

        IF ls_loop_flg = '1' THEN
            IF EXISTS (SELECT 1 FROM le_trn_ird WHERE order_no = ls_order_no AND itemno = ps_itemno AND supplier = ps_supplier AND usercd = ps_usercd) 
            THEN
                ls_loop_flg := '0';
            END IF;
        END IF;

        IF ls_loop_flg = '1' THEN
            IF EXISTS (SELECT 1 FROM le_trn_order_forecast WHERE order_no = ls_order_no AND itemno = ps_itemno AND supplier = ps_supplier AND usercd = ps_usercd) 
            THEN
                 ls_loop_flg := '0';
                ls_carry_flg := '0';
            END IF;
        END IF;

        IF ls_loop_flg = '0' THEN
            IF ps_input_class = '1' THEN
                ls_next_odorder_ic := CASE 
                WHEN ls_next_odorder_ic <> ls_seq_max 
                THEN TO_CHAR(TO_NUMBER(ls_next_odorder_ic, '9999') + 1, 'FM0000') 
                ELSE '0001' 
                END;
            ELSE
                ls_next_bdorder_ic := CASE 
                WHEN ls_next_bdorder_ic <> ls_seq_max 
                THEN TO_CHAR(TO_NUMBER(ls_next_bdorder_ic, '9999') + 1, 'FM0000') 
                ELSE '0001' 
                 END;
            END IF;
            IF (ps_input_class = '1' AND ls_next_odorder_ic = '0001') OR (ps_input_class <> '1' AND ls_next_bdorder_ic = '0001') THEN
                ls_carry_flg := '1';
            END IF;
        END IF;

        IF ls_loop_flg = '0' THEN
            IF ps_input_class = '1' THEN
                IF ps_pilot_class IN ('2', '4') THEN
                    IF ls_init_seq_online = ls_next_odorder_ic THEN
                           rn_status := -1;
                         rs_err_code := 'E.LDP10564';
                          rs_err_msg := 'No framework for order number assignment remains.';
                        rs_err_focus := 'LDYS0003';
                        RETURN NEXT;
                        RETURN;
                    END IF;
                ELSE
                    IF ls_init_prefix_online = ls_next_ohorder_ic 
                   AND    ls_init_seq_online = ls_next_odorder_ic 
                  THEN
                           rn_status := -1;
                         rs_err_code := 'E.LDP10564';
                          rs_err_msg := 'No framework for order number assignment remains.';
                        rs_err_focus := 'LDYS0003';
                        RETURN NEXT;
                        RETURN;
                    END IF;
                END IF;
            ELSE
                IF ps_pilot_class IN ('2', '4') THEN
                    IF ls_init_seq_batch = ls_next_bdorder_ic THEN
                           rn_status := -1;
                         rs_err_code := 'E.LDP10564';
                          rs_err_msg := 'No framework for order number assignment remains.';
                        rs_err_focus := 'LDYS0003';
                        RETURN NEXT;
                        RETURN;
                    END IF;
                ELSE
                    IF ls_init_prefix_batch = ls_next_bhorder_ic AND ls_init_seq_batch = ls_next_bdorder_ic THEN
                           rn_status := -1;
                         rs_err_code := 'E.LDP10564';
                          rs_err_msg := 'No framework for order number assignment remains.';
                        rs_err_focus := 'LDYS0003';
                        RETURN NEXT;
                        RETURN;
                    END IF;
                END IF;
            END IF;
        END IF;

        IF ls_carry_flg = '1' THEN
            IF ps_input_class = '1' THEN
                ls_next_odorder_ic := '0001';
                ls_next_ohorder_ic := CASE WHEN ls_next_ohorder_ic = 'H' THEN 'A' ELSE CHR(ASCII(ls_next_ohorder_ic) + 1) END;
            ELSE
                ls_next_bdorder_ic := '0001';
                ls_next_bhorder_ic := CASE 
                                    WHEN ls_next_bhorder_ic = 'V' THEN 'X'
                                    WHEN ls_next_bhorder_ic = 'Z' THEN 'P'
                                    ELSE CHR(ASCII(ls_next_bhorder_ic) + 1)
                                  END;
            END IF;
            ls_carry_flg := '0';
        END IF;
    END LOOP;

    --------------------------------------------------------------------------------
    --  < STEP7 : Update Inventory Record (New Order Config) >
    --------------------------------------------------------------------------------
    IF ps_input_class = '1' THEN
        UPDATE ld_trn_inv
           SET next_ohorder_ic = ls_next_ohorder_ic,
            next_odorder_ic = ls_next_odorder_ic,
            update_counter = COALESCE(update_counter, 0) + 1,
            ic_update_datetime = statement_timestamp(),
            update_author = ps_user_id,
            update_pgmid = 'LDYS0003'
        WHERE itemno = ps_itemno
          AND supplier = ps_supplier
          AND usercd = ps_usercd;
    ELSE
        UPDATE ld_trn_inv
           SET next_bhorder_ic = ls_next_bhorder_ic,
            next_bdorder_ic = ls_next_bdorder_ic,
            update_counter = COALESCE(update_counter, 0) + 1,
            ic_update_datetime = statement_timestamp(),
            update_author = ps_user_id,
            update_pgmid = 'LDYS0003'
        WHERE itemno = ps_itemno
          AND supplier = ps_supplier
          AND usercd = ps_usercd;
    END IF;

    --------------------------------------------------------------------------------
    --  < STEP8 : Set Return Values >
    --------------------------------------------------------------------------------
    rs_order_no := ls_order_no;

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
            rs_err_focus      := 'LDYS0003';
        END IF;

        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN
        rn_status             := -1;
        rs_sql_code           := SQLSTATE;
        rs_err_code           := ' ';
        rs_err_msg            := SQLERRM;
        rs_err_focus          := 'LDYS0003';

        RETURN NEXT;
        RETURN;
END;
$BODY$
LANGUAGE 'plpgsql';