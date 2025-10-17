--------------------------------------------------------------------------------
--@SEE << Valid / Order Login >>
--    @ID      : LDAS0313
--
--    @Written : 1.0.0                2012.08.01 Lian Zhibin / YMSLX
--    @Written : 1.0.0                2017.02.01 Y.Mochiduki / YMSL
--    --------------------------------------------------------------------------
--    @Update  : xxxxxxxxxxxx         xxxx.xx.xx xxxxxxxx / xx
--     Reason  : xxx
--              xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--
----------------------------------------------------------------------------
--@SEE << Validation for Order Enter >>
----------------------------------------------------------------------------
--  < INPUT Parameter >
--    @ps_user_id                 <I/ > VARCHAR     : User ID
--    @ps_log_sign                <I/ > VARCHAR     : Log Sign
--    @ps_recieve_id              <I/ > VARCHAR     : Recieve ID
--    @ps_request_system_code     <I/ > VARCHAR     : Request System Code
--    @ps_itemno                  <I/ > VARCHAR     : Item NO
--    @ps_supplier                <I/ > VARCHAR     : Supplier
--    @ps_usercd                  <I/ > VARCHAR     : Usercd
--    @ps_order_no                <I/ > VARCHAR     : Order NO
--    @pn_order_qty               <I/ > DECIMAL     : Order Qty
--    @ps_start_date              <I/ > VARCHAR     : Start Date
--    @ps_due_date                <I/ > VARCHAR     : Due Date
--    @ps_disburse_date           <I/ > VARCHAR     : Disburse Date
--    @ps_due_begin_time          <I/ > VARCHAR     : Begin Time   
--    @ps_due_end_time            <I/ > VARCHAR     : End Time     
--    @ps_reason_code             <I/ > VARCHAR     : Reason Code
--    @pn_carry_over_qty          <I/ > DECIMAL     : Carry Over Qty
--    @ps_pilot_class             <I/ > VARCHAR     : Pilot Class
--    @ps_input_txn               <I/ > VARCHAR     : Input Txn
--  < OUTPUT Parameter >
--    @rn_status                  < /O> INTEGER     : Return Code
--                                                 (  0 : Normal        )
--                                                 (  1 : Warn          )
--                                                 ( -1 : Sql Error     )
--                                                 ( -2 : PGM Error     )
--    @rs_sql_code                < /O> VARCHAR     : Sql Code
--    @rs_err_code                < /O> VARCHAR     : Error Code
--    @rs_err_msg                 < /O> VARCHAR     : Error Message
--    @rs_err_focus               < /O> VARCHAR     : Error Focus
----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION gimac.ldas0313(
      ps_user_id                         IN VARCHAR                         -- 1
    , ps_log_sign                        IN VARCHAR                         -- 2
    , ps_recieve_id                      IN VARCHAR                         -- 3
    , ps_request_system_code             IN VARCHAR                         -- 4
    , ps_itemno                          IN VARCHAR                         -- 5
    , ps_supplier                        IN VARCHAR                         -- 6
    , ps_usercd                          IN VARCHAR                         -- 7
    , ps_order_no                        IN VARCHAR                         -- 8
    , pn_order_qty                       IN DECIMAL                         -- 9
    , ps_start_date                      IN VARCHAR                         -- 10
    , ps_due_date                        IN VARCHAR                         -- 11
    , ps_disburse_date                   IN VARCHAR                         -- 12
    , ps_due_begin_time                  IN VARCHAR                         -- 13
    , ps_due_end_time                    IN VARCHAR                         -- 14
    , ps_reason_code                     IN VARCHAR                         -- 15
    , pn_carry_over_qty                  IN DECIMAL                         -- 16
    , ps_pilot_class                     IN VARCHAR                         -- 17
    , ps_input_txn                       IN VARCHAR                         -- 18
)
RETURNS TABLE(
      rn_status    INTEGER
    , rs_sql_code  VARCHAR
    , rs_err_code  VARCHAR
    , rs_err_msg   VARCHAR
    , rs_err_focus VARCHAR
) LANGUAGE plpgsql
AS $function$
DECLARE
    -- SP return record  --
    rec_itemmast_date RECORD;
    rec_err_log_login RECORD;
    rec_order_date    RECORD;
    ls_demand_policy_code      gimac.le_mst_mrp_information.demand_policy_code%type;
    ls_item_status             gimac.la_itemmast.item_status%type;
    ln_float_safety_stock_qty  gimac.le_mst_mrp_information.float_safety_stock_qty%type;
    ls_order_policy_code       gimac.le_mst_mrp_information.order_policy_code%type;
    ld_due_date                TIMESTAMP;
    ls_due_weekday             VARCHAR(3);
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    /* Return Value Set */
    rn_status               :=   0;
    rs_sql_code             := ' ';
    rs_err_code             := ' ';
    rs_err_msg              := ' ';
    rs_err_focus            := ' ';

    /* Variable Initialization */
    ls_demand_policy_code     := ' ';
    ls_item_status            := ' ';
    ln_float_safety_stock_qty :=   0;
    ls_order_policy_code      := ' ';
    ld_due_date    := TO_TIMESTAMP(ps_due_date,'YYYYMMDD');
    ls_due_weekday := TO_CHAR(ld_due_date,'DY');
    /* Argument Check */
    IF pn_order_qty <= 0 THEN
        rs_err_code  := 'E.LDP10307';
        rs_err_msg   := 'You cannot specify 0 or less than 0.';
        rs_err_focus := 'orderQty';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_pilot_class <> '2' AND ps_pilot_class <> '3'
                             AND TRIM(ps_pilot_class) <> '' THEN
        rs_err_code  := 'E.LDP10426';
        rs_err_msg   := 'You can specify only 2(Pilot Production),'
                     || ' 3(First Production) or Blank(Mass Production)'
                     || ' for Producion Classsification.';
        rs_err_focus := 'pilotClass';
        RAISE EXCEPTION ' ';
    END IF;
    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
  

    /* Get Itemmast Date Record */
        SELECT *
          INTO STRICT rec_itemmast_date
          FROM LDAS0300 ( 'LD11'
                          ,ps_itemno
                          ,ps_supplier
                          ,ps_usercd
                            );
    -- return item set --
    rn_status    := rec_itemmast_date.rn_status;
    rs_sql_code  := rec_itemmast_date.rs_sql_code;
    rs_err_code  := rec_itemmast_date.rs_err_code;
    rs_err_msg   := rec_itemmast_date.rs_err_msg;
    rs_err_focus := rec_itemmast_date.rs_err_focus;

    IF rec_itemmast_date.rn_status = -1 THEN

        RETURN NEXT;
        RETURN;
    ELSIF rec_itemmast_date.rn_status = -2 THEN

        RAISE EXCEPTION ' ';
    ELSE
        ls_demand_policy_code     := rec_itemmast_date.rs_demand_policy_code;
        ls_item_status            := rec_itemmast_date.rs_item_status;
        ln_float_safety_stock_qty
                                  := rec_itemmast_date.rn_float_safety_stock_qty;
    END IF;

    /* Get Order Date Record */
    SELECT *
    INTO STRICT rec_order_date
    FROM LDAS0301 ( 'LD11'
                   ,ps_start_date
                   ,ps_due_date
                   ,ps_disburse_date
                   ,ps_itemno
                   ,ps_supplier
                   ,ps_usercd
                   ,ls_demand_policy_code
                   );
    -- return item set --
    rn_status    := rec_order_date.rn_status;
    rs_sql_code  := rec_order_date.rs_sql_code;
    rs_err_code  := rec_order_date.rs_err_code;
    rs_err_msg   := rec_order_date.rs_err_msg;
    rs_err_focus := rec_order_date.rs_err_focus;

    IF rec_order_date.rn_status = -1 THEN

        RETURN NEXT;
        RETURN;
    ELSIF rec_order_date.rn_status = -2 THEN

        RAISE EXCEPTION ' ';
    ELSE
        NULL;
    END IF;

    /* Reason Code */
    IF EXISTS ( SELECT 1
                  FROM le_mst_order_reason
                 WHERE order_reason_code     =  ps_reason_code )THEN
        NULL;
    ELSE
        rs_err_code  := 'E.LDP10023';
        rs_err_msg   := 'Reason Code does not exist'
                     || ' in the order reason code table.';
        rs_err_focus := 'reasonCode';
        RAISE EXCEPTION ' ';
    END IF;

    /* Return Pilot Class Check */
    IF ps_input_txn = '18' OR ps_input_txn = '28' THEN
        IF ls_item_status = '2' THEN
            IF ps_pilot_class <> '2' THEN
                rs_err_code  := 'E.LDP10509';
                rs_err_msg   := 'You cannot register Mass Production Order'
                             || ' for Pilot Production Parts in Parts Return'
                             || ' and Scrap Report Operation.';
                rs_err_focus := 'pilotClass';
                RAISE EXCEPTION ' ';
            END IF;
        END IF;
    END IF;

    /* Safety Stock Check */
    IF ps_input_txn = '28' THEN
        IF ln_float_safety_stock_qty <> 0 THEN
            rs_err_code  := 'E.LDP10510';
            rs_err_msg   := 'In Scrap Report Operation, you cannot register'
                         || ' the order for the item that has safety stock.';
            rs_err_focus := 'itemno';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    /* Due Date Check */
    IF EXISTS ( SELECT 1
                  FROM le_mst_mrp_information
                 WHERE itemno       = ps_itemno
                   AND supplier     = ps_supplier
                   AND usercd       = ps_usercd ) THEN
        SELECT order_policy_code
          INTO STRICT ls_order_policy_code
          FROM le_mst_mrp_information
         WHERE itemno       = ps_itemno
           AND supplier     = ps_supplier
           AND usercd       = ps_usercd;

        IF ls_order_policy_code = 'S' THEN
            IF EXISTS ( SELECT 1
                          FROM le_mst_deliv_std_day
                         WHERE supplier        = ps_supplier
                           AND deliv_std_class = 'D'
                           AND deliv_std_day   = SUBSTR(ps_due_date,7,2) ) THEN
                NULL;
            ELSE
                IF EXISTS ( SELECT 1
                              FROM le_mst_deliv_std_day
                             WHERE supplier        = ps_supplier
                               AND deliv_std_class = 'W'
                               AND deliv_std_day   = ls_due_weekday ) THEN
                    NULL;
                ELSE
                    rn_status    := 1;
                    rs_sql_code  := ' ';
                    rs_err_code  := 'E.LDP10372';
                    rs_err_msg   := 'Due Date you entered does not meet with the'
                                 || ' setting of DELIVERY STANDARD DAY TABLE.';
                    rs_err_focus := 'dueDate';
                END IF;
            END IF;
        END IF;
    END IF;

    /* Pilot Class Check */
    IF EXISTS ( SELECT 1
                  FROM le_trn_order
                 WHERE itemno           = ps_itemno
                   AND supplier         = ps_supplier
                   AND usercd           = ps_usercd
                   AND TRIM(delete_ymd) = ''
                   AND pilot_class      = '3' ) THEN
        IF ps_pilot_class = '3' THEN
            IF ls_item_status = '3' THEN
                rn_status    := 1;
                rs_sql_code  := ' ';
                rs_err_code  := 'E.LDP10473';
                rs_err_msg   := 'First production order of'
                             || ' the same item already exists.';
                rs_err_focus := 'pilotClass';
            END IF;
        END IF;
    ELSE
        NULL;
    END IF;

    /* Item Status Does Not Exist */
    IF ps_pilot_class = '3' THEN
        IF ls_item_status > '3' THEN
        rs_err_code  := 'E.LDP10474';
        rs_err_msg   := 'Because Item Status is not 3(First Production),'
                     || ' you cannot register first production order.';
        rs_err_focus := 'pilotClass';
        RAISE EXCEPTION ' ';
        END IF;
    END IF;

    /* Order Does Not Exist */
    IF EXISTS ( SELECT 1
                  FROM le_trn_order
                 WHERE itemno           = ps_itemno
                   AND supplier         = ps_supplier
                   AND usercd           = ps_usercd
                   AND TRIM(delete_ymd) = ''
                   AND pilot_class      = '3'
                   AND due_date         > ps_due_date ) THEN
        IF TRIM(ps_pilot_class) = '' THEN
            IF ls_item_status = '3' THEN
                rn_status    := 1;
                rs_sql_code  := ' ';
                rs_err_code  := 'E.LDP10475';
                rs_err_msg   := 'After the mass production order you entered,'
                             || ' first production order exists.';
                rs_err_focus := 'pilotClass';
            END IF;
        END IF;
    ELSE
        NULL;
    END IF;
    --------------------------------------------------
    --  < STEP3 : Return Value Processing >
    --------------------------------------------------
    IF rn_status = 1 THEN
        IF ps_log_sign = '1' THEN
            SELECT *
            INTO STRICT rec_err_log_login
            FROM LDAS0409 ( '99'                                 --1
                           ,ps_user_id                           --2
                           ,rs_err_code                          --3
                           ,'LD11'                               --4
                           ,'1'                                  --5
                           ,'9'                                  --6
                           ,ps_recieve_id                        --7
                           ,ps_request_system_code               --8
                           ,ps_input_txn                         --9
                           ,'LDAS0313'                           --10
                           ,ps_itemno                            --11
                           ,ps_supplier                          --12
                           ,ps_usercd                            --13
                           ,ps_order_no                          --14
                           ,' '                                  --15
                           ,' '                                  --16        
                           ,pn_order_qty                         --17
                           ,ps_reason_code                       --18
                           ,' '                                  --19
                           ,' '                                  --20
                           ,' '                                  --21
                           ,' '                                  --22
                           ,' '                                  --23
                           ,' '                                  --24
                           ,ps_start_date                        --25
                           ,ps_due_date                          --26
                           ,ps_disburse_date                     --27
                           ,ps_due_begin_time                    --28
                           ,ps_due_end_time                      --29
                           ,pn_carry_over_qty                    --30
                           ,ps_pilot_class                       --31
                           ,' '                                  --32           
                           ,' '                                  --33           
                           ,' '                                  --34           
                           ,' '                                  --35           
                           ,' '                                  --36           
                           ,' '                                  --37
                           ,' '                                  --38
                           ,' '                                  --39
                           ,' '                                  --40
                           ,' '                                  --41
                           ,' '                                  --42
                           ,' '                                  --43
                           ,0                                    --44
                           ,' '                                  --45
                           ,' '                                  --46
                           ,' '                                  --47
                           ,' '                                  --48
                           ,' '                                  --49
                           ,' '                                  --50
                           ,' '                                  --51
                           ,' '                                  --52
                           ,' '                                  --53
                           ,' '                                  --54
                           ,' '                                  --55
                           ,' '                                  --56
                           ,' '                                  --57
                           ,' '                                  --58
                           ,' '                                  --59
                           ,' '                                  --60
                           ,' '                                  --61
                           ,' '                                  --62
                           ,' '                                  --63
                           ,' '                                  --64
                           ,' '                                  --65  
                           ,ps_itemno                            --66
                           ,ps_supplier                          --67
                           ,ps_usercd                            --68
                           ,pn_order_qty                         --69
                           ,ps_start_date                        --70
                           ,ps_due_date                          --71
                           ,ps_disburse_date                     --72
                           );
            -- status judgement --
            IF rec_err_log_login.rn_status <> 0 THEN
                rn_status   := rec_err_log_login.rn_status;
                rs_sql_code := rec_err_log_login.rs_sql_code;
                rs_err_code := rec_err_log_login.rs_err_code;
                rs_err_msg  := rec_err_log_login.rs_err_msg;
                RETURN NEXT;
                RETURN;
            END IF;
        END IF;
    END IF;
    RETURN NEXT;
    RETURN;

EXCEPTION
    WHEN RAISE_EXCEPTION THEN
        rn_status   :=  -2;
        rs_sql_code := ' ';

        IF ps_log_sign = '1' THEN
            SELECT *
            INTO STRICT rec_err_log_login
            FROM LDAS0409 ( '99'                                 --1
                           ,ps_user_id                           --2
                           ,rs_err_code                          --3
                           ,'LD11'                               --4
                           ,'1'                                  --5
                           ,'9'                                  --6
                           ,ps_recieve_id                        --7
                           ,ps_request_system_code               --8
                           ,ps_input_txn                         --9
                           ,'LDAS0313'                           --10
                           ,ps_itemno                            --11
                           ,ps_supplier                          --12
                           ,ps_usercd                            --13
                           ,ps_order_no                          --14
                           ,' '                                  --15
                           ,' '                                  --16        
                           ,pn_order_qty                         --17
                           ,ps_reason_code                       --18
                           ,' '                                  --19
                           ,' '                                  --20
                           ,' '                                  --21
                           ,' '                                  --22
                           ,' '                                  --23
                           ,' '                                  --24
                           ,ps_start_date                        --25
                           ,ps_due_date                          --26
                           ,ps_disburse_date                     --27
                           ,ps_due_begin_time                    --28
                           ,ps_due_end_time                      --29
                           ,pn_carry_over_qty                    --30
                           ,ps_pilot_class                       --31
                           ,' '                                  --32           
                           ,' '                                  --33           
                           ,' '                                  --34           
                           ,' '                                  --35           
                           ,' '                                  --36           
                           ,' '                                  --37
                           ,' '                                  --38
                           ,' '                                  --39
                           ,' '                                  --40
                           ,' '                                  --41
                           ,' '                                  --42
                           ,' '                                  --43
                           ,0                                    --44
                           ,' '                                  --45
                           ,' '                                  --46
                           ,' '                                  --47
                           ,' '                                  --48
                           ,' '                                  --49
                           ,' '                                  --50
                           ,' '                                  --51
                           ,' '                                  --52
                           ,' '                                  --53
                           ,' '                                  --54
                           ,' '                                  --55
                           ,' '                                  --56
                           ,' '                                  --57
                           ,' '                                  --58
                           ,' '                                  --59
                           ,' '                                  --60
                           ,' '                                  --61
                           ,' '                                  --62
                           ,' '                                  --63
                           ,' '                                  --64
                           ,' '                                  --65  
                           ,ps_itemno                            --66
                           ,ps_supplier                          --67
                           ,ps_usercd                            --68
                           ,pn_order_qty                         --69
                           ,ps_start_date                        --70
                           ,ps_due_date                          --71
                           ,ps_disburse_date                     --72
                           );
            -- status judgement --
            IF rec_err_log_login.rn_status <> 0 THEN
                rn_status   := rec_err_log_login.rn_status;
                rs_sql_code := rec_err_log_login.rs_sql_code;
                rs_err_code := rec_err_log_login.rs_err_code;
                rs_err_msg  := rec_err_log_login.rs_err_msg;
                RETURN NEXT;
                RETURN;
            END IF;
        END IF;

        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN
        rn_status    := -1;
        rs_sql_code  := SQLSTATE;
        rs_err_code  := ' ';
        rs_err_msg   := SQLERRM;
        rs_err_focus := ' ';

        RETURN NEXT;
        RETURN;
END;
$function$;;
