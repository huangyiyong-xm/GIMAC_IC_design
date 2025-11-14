--------------------------------------------------------------------------------
--@SEE << Valid/Independent Login Required>>
--    @ID      : LDAS0318
--
--    @Written : 1.0.0                2012.08.03 Lian Zhibin / YMSLX
--    @Written : 1.0.0                2017.02.01 Y.Mochiduki / YMSL
--    @Written : 1.0.0                2017.10.25 Y.Mochiduki / YMSL
--    @Written : 1.0.0                2017.11.14 Y.Mochiduki / YMSL
--    --------------------------------------------------------------------------
--    @Update  : xxxxxxxxxxxx         xxxx.xx.xx xxxxxxxx / xx
--     Reason  : xxx
--              xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--
--------------------------------------------------------------------------------
----------------------------------------------------------------------------
--@SEE << Valid/Independent Login Required>>
----------------------------------------------------------------------------
--  < INPUT Parameter >
--    @ps_user_id              <I/ > VARCHAR       : User ID
--    @ps_log_sign             <I/ > VARCHAR       : Log Sign
--    @ps_receive_id           <I/ > VARCHAR       : Recieve ID
--    @ps_request_system_code  <I/ > VARCHAR       : Request System Code
--    @ps_itemno               <I/ > VARCHAR       : Itemno
--    @ps_supplier             <I/ > VARCHAR       : Supplier
--    @ps_usercd               <I/ > VARCHAR       : User Code
--    @ps_order_no             <I/ > VARCHAR       : Order NO
--    @ps_rd_class             <I/ > VARCHAR       : Rd Class
--    @ps_ind_user_class       <I/ > VARCHAR       : Ind User Class
--    @ps_ind_user_code        <I/ > VARCHAR       : Ind User Code
--    @ps_start_date           <I/ > VARCHAR       : Start Date
--    @ps_reason_code          <I/ > VARCHAR       : Reason Code
--    @ps_pilot_class          <I/ > VARCHAR       : Pilot Class
--    @ps_pilot_condition_type <I/ > VARCHAR       : Pilot Condition Type
--    @pn_required_qty         <I/ > DECIMAL       : Required Qty
--    @ps_remark               <I/ > VARCHAR       : Remark
--    @ps_transfer_class       <I/ > VARCHAR       : Transfer Class
--    @ps_transfer_code        <I/ > VARCHAR       : Transfer Code
--    @ps_transfer_reason_code <I/ > VARCHAR       : Transfer Reason Code
--    @ps_account_heading      <I/ > VARCHAR       : Account Heading
--    @ps_budget_no            <I/ > VARCHAR       : Budget NO
--    @ps_account_code_sales   <I/ > VARCHAR       : Account Code Sales
--    @ps_delete_ymd           <I/ > VARCHAR       : Delete YMD
--    @ps_sp_order_class       <I/ > VARCHAR       : Sp Order Class
--    @ps_sp_delivery_code     <I/ > VARCHAR       : Sp Delivery Code
--    @ps_sp_dealer_no         <I/ > VARCHAR       : Sp Dealer NO
--    @ps_sp_order_no          <I/ > VARCHAR       : Sp Order NO
--  < OUTPUT Parameter >
--    @rn_status               < /O> INTEGER       : Return Code
--                                                (  0 : Normal        )
--                                                ( -1 : Sql Error     )
--                                                ( -2 : PGM Error     )
--    @rs_sql_code             < /O> VARCHAR       : Sql Code
--    @rs_err_code             < /O> VARCHAR       : Error Code
--    @rs_err_msg              < /O> VARCHAR       : Error Message
--    @rs_err_focus            < /O> VARCHAR       : Error Focus
----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION gimac.ldas0318(
      ps_user_id                          IN VARCHAR              --1
    , ps_log_sign                         IN VARCHAR              --2
    , ps_receive_id                       IN VARCHAR              --3
    , ps_request_system_code              IN VARCHAR              --4
    , ps_itemno                           IN VARCHAR              --5
    , ps_supplier                         IN VARCHAR              --6
    , ps_usercd                           IN VARCHAR              --7
    , ps_order_no                         IN VARCHAR              --8
    , ps_rd_class                         IN VARCHAR              --9
    , ps_ind_user_class                   IN VARCHAR              --10
    , ps_ind_user_code                    IN VARCHAR              --11
    , ps_start_date                       IN VARCHAR              --12
    , ps_reason_code                      IN VARCHAR              --13
    , ps_pilot_class                      IN VARCHAR              --14
    , ps_pilot_condition_type             IN VARCHAR              --15
    , pn_required_qty                     IN DECIMAL              --16
    , ps_remark                           IN VARCHAR              --17
    , ps_transfer_class                   IN VARCHAR              --18
    , ps_transfer_code                    IN VARCHAR              --19
    , ps_transfer_reason_code             IN VARCHAR              --20
    , ps_account_heading                  IN VARCHAR              --21
    , ps_budget_no                        IN VARCHAR              --22
    , ps_account_code_sales               IN VARCHAR              --23
    , ps_delete_ymd                       IN VARCHAR              --24
    , ps_sp_order_class                   IN VARCHAR              --25
    , ps_sp_delivery_code                 IN VARCHAR              --26
    , ps_sp_dealer_no                     IN VARCHAR              --27
    , ps_sp_order_no                      IN VARCHAR              --28
)
RETURNS TABLE(
    rn_status    INTEGER,
    rs_sql_code  VARCHAR,
    rs_err_code  VARCHAR,
    rs_err_msg   VARCHAR,
    rs_err_focus VARCHAR
) language plpgsql
AS $function$
DECLARE
    -- SP return record  --
    rec_itemmast_date         RECORD;
    rec_fix_period_date       RECORD;
    rec_day_type              RECORD;
    rec_transfer_account      RECORD;
    rec_delete_ymd            RECORD;
    rec_err_log_login         RECORD;
    ls_item_class             gimac.le_mst_mrp_information.item_class%TYPE;                         --1 
    ls_item_status            gimac.la_itemmast.item_status%TYPE;                                   --2 
    ls_airs_sign              gimac.le_mst_mrp_information.airs_sign%TYPE;                          --3 
    ls_demand_policy_code     gimac.le_mst_mrp_information.demand_policy_code%TYPE;                 --4 
    ln_float_safety_stock_qty gimac.le_mst_mrp_information.float_safety_stock_qty%TYPE;             --5 
    ls_calendar_code          gimac.la_area_master_su.calendar_code%TYPE;                           --6 
    ls_day_type               gimac.le_mst_calendar_sum.day_type%TYPE;                              --7 
    ls_fix_to_ymd             gimac.le_mst_fix_period.fix_to_ymd%TYPE;                              --8 
    ls_org_category_code3     gimac.la_area_master_su.area_category%TYPE;                           --9
    ls_org_category_code      gimac.la_area_master_su.area_category%TYPE;                           --10
    ls_ic_slip_date           gimac.ld_mst_slip_date.ic_slip_date%TYPE;                             --11
    ls_valid_ind_user_yn       
                              gimac.le_mst_ind_user_transfer_check.valid_ind_user_yn%TYPE;          --12
    ls_ind_user_eq_transfer_yn 
                              gimac.le_mst_ind_user_transfer_check.ind_user_eq_transfer_yn%TYPE;    --13
    ls_ope_day_no_check_yn     
                              gimac.le_mst_ind_user_transfer_check.ope_day_no_check_yn%TYPE;        --14
    ln_rd_input_days          
             gimac.le_system_parameter.rd_input_days%TYPE;                                          --15
    ln_rd_delete_input_days   
             gimac.le_system_parameter.rd_delete_input_days%TYPE;                                   --16
    ls_deal_flag              VARCHAR(01);                                                          --17
    ls_exist_class1           VARCHAR(01);                                                          --18
    ls_exist_class2           VARCHAR(01);                                                          --19
    ln_rd_input_days1         INTEGER;                                                              --20
    ln_rd_delete_input_days1  INTEGER;                                                              --21
    ls_fix_period_id          VARCHAR;                                                              --22
    

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
    ls_item_class              := ' ';                                    --1
    ls_item_status             := ' ';                                    --2
    ls_airs_sign               := ' ';                                    --3
    ls_demand_policy_code      := ' ';                                    --4
    ln_float_safety_stock_qty  :=   0;                                    --5
    ls_calendar_code           := ' ';                                    --6
    ls_day_type                := ' ';                                    --7
    ls_fix_to_ymd              := ' ';                                    --8
    ls_org_category_code3      := ' ';                                    --11
    ls_ic_slip_date            := ' ';                                    --12
    ls_valid_ind_user_yn       := ' ';                                    --13
    ls_ind_user_eq_transfer_yn := ' ';                                    --14
    ls_ope_day_no_check_yn     := ' ';                                    --15
    ln_rd_input_days           :=   0;                                    --16
    ln_rd_delete_input_days    :=   0;                                    --17
    ls_deal_flag               := ' ';                                    --18
    ls_exist_class1            := ' ';                                    --19
    ls_exist_class2            := ' ';                                    --20
    ls_fix_period_id           := ' ';                                    --21

    /* Argument Check */
    IF ps_pilot_class <> '2' AND ps_pilot_class <> '4'
                             AND TRIM(ps_pilot_class) <> '' THEN
        rs_err_code  := 'E.LDP10427';
        rs_err_msg   := 'You can specify only 2(Pilot Production),'
                     || ' 4(Part Trial Production) or Blank(Mass Production)'
                     || ' for Production Cl.';
        rs_err_focus := 'pilotClass';
        RAISE EXCEPTION ' ';
    END IF;

    IF pn_required_qty <= 0 THEN
        rs_err_code  := 'E.LDP10307';
        rs_err_msg   := 'You cannot specify 0 or less than 0.';
        rs_err_focus := 'requiredQty';
        RAISE EXCEPTION ' ';
    END IF;
    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    /* Get Itemmast Date Record */
    SELECT *
    INTO STRICT rec_itemmast_date
    FROM LDAS0300 ('LD21'
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

    IF rn_status = -1 THEN

        RETURN NEXT;
        RETURN;
    ELSIF rn_status = -2 THEN

        RAISE EXCEPTION ' ';
    ELSE
        ls_item_class             := rec_itemmast_date.rs_item_class;
        ls_item_status            := rec_itemmast_date.rs_item_status;
        ls_airs_sign              := rec_itemmast_date.rs_airs_sign;
        ls_demand_policy_code     := rec_itemmast_date.rs_demand_policy_code;
        ln_float_safety_stock_qty := rec_itemmast_date.rn_float_safety_stock_qty;
    END IF;

    /* 2.3.2.1 Get Calendar Code */
    IF EXISTS ( SELECT 1
                  FROM la_area_master_su
                 WHERE su_code     = ps_usercd ) THEN
        SELECT calendar_code
          INTO STRICT ls_calendar_code
          FROM la_area_master_su
         WHERE su_code     = ps_usercd;
    /* Calendar Code Data Not Found */
    ELSE
        rs_err_code  := 'E.LDP10910';
        rs_err_msg   := 'Effective calendar does not exist by'
                     || ' the specified Supplier/User.';
        rs_err_focus := 'usercd';
        RAISE EXCEPTION ' ';
    END IF;

    IF TRIM(ps_delete_ymd) <> '' THEN
        /*2.3.3 Day Type Does Not Exist Error */
        IF EXISTS ( SELECT 1
                      FROM le_mst_calendar_sum
                     WHERE calendar_code = ls_calendar_code
                       AND calendar_ymd  = ps_delete_ymd ) THEN
            SELECT day_type
              INTO STRICT ls_day_type
              FROM le_mst_calendar_sum
             WHERE calendar_code = ls_calendar_code
               AND calendar_ymd  = ps_delete_ymd;
            IF ls_day_type <> '0' THEN
                rs_err_code  := 'E.LDP10353';
                rs_err_msg   := 'The day you specified is not a working-day.' ||
                                '[ ps_delete_ymd  ] = ' ||
                                COALESCE( ps_delete_ymd , 'NULL' );
                rs_err_focus := 'deleteYmd';
                RAISE EXCEPTION ' ';
            END IF;
        /* Day Type Data Not Found */
        ELSE
            rs_err_code  := 'E.LDP10106';
            rs_err_msg   := 'Day String does not exist in the common calendar.';
            rs_err_focus := 'deleteYmd';
            RAISE EXCEPTION ' ';
        END IF;

        /*2.3.3.2 Get Fix Period */
        SELECT fix_period_id
        INTO STRICT ls_fix_period_id
          FROM le_mst_mrp_information
         WHERE item_no     = ps_itemno
           AND supplier    = ps_supplier
           AND usercd      = ps_usercd;

        SELECT *
          INTO STRICT rec_fix_period_date
          FROM LEBS0010 ( ls_fix_period_id
                       ,'T'
                       );
        -- return item set --
        rn_status   := rec_fix_period_date.rn_status;
        rs_sql_code := rec_fix_period_date.rs_sql_code;
        rs_err_code := rec_fix_period_date.rs_err_code;
        rs_err_msg  := rec_fix_period_date.rs_err_msg;

        IF rn_status = -1 THEN

            RETURN NEXT;
            RETURN;
        ELSIF rn_status = -2 THEN

            RAISE EXCEPTION ' ';
        ELSE
            ls_fix_to_ymd := rec_fix_period_date.rs_fix_to_ymd;
        END IF;

        IF ps_delete_ymd <= ls_fix_to_ymd THEN
            rs_err_code  := 'E.LDP10364';
            rs_err_msg   := 'For Deletion Date, specify the date later than'
                         || ' the final day of the fixed period of this time.';
            rs_err_focus := 'deleteYmd';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    /*2.3.4 Get Ic Slip Date */
    IF EXISTS ( SELECT 1
                  FROM ld_mst_slip_date
                 WHERE operation_type = 'STD' )THEN
        SELECT ic_slip_date
          INTO STRICT ls_ic_slip_date
          FROM ld_mst_slip_date
         WHERE operation_type = 'STD';
    ELSE
        rs_err_code  := 'E.LDP10911';
        rs_err_msg   := 'The IC pymac date is not exist.';
        rs_err_focus := ' ';
        RAISE EXCEPTION ' ';
    END IF;




    /* 2.3.5   Independent Required User Check */
    /* 2.3.5.1 Auto Safety Inventory R/D Check */
    IF EXISTS ( SELECT 1
                  FROM lz_function_parameter
                 WHERE system_code  = 'LC'
                   AND id_code      = 'LCB0002'
                   AND option_code  = '0'
                   AND select_flg   = 'T' ) THEN
        /* Auto Safety Inventory R/D : Not Register */
        IF ps_rd_class = '1' OR ps_rd_class = '4' THEN
            ls_deal_flag := '1';
        END IF;
    ELSE
        /* Auto Safety Inventory R/D : Register */
        IF ps_rd_class = '1' OR ps_rd_class = '3' OR ps_rd_class = '4' THEN
            ls_deal_flag := '1';
        END IF;
    END IF;

    /* 2.3.5.2 */
    IF ls_deal_flag <> '1' AND ps_rd_class = '2' THEN
        IF TRIM(ps_transfer_class) <> '' OR TRIM(ps_transfer_code) <> '' THEN
            rs_err_code  := 'E.LDP10430';
            rs_err_msg   := 'Enter the value for Charged'
                         || ' Section Classification and Code.';
            rs_err_focus := 'transferCode';
            RAISE EXCEPTION ' ';
        END IF;
        IF ls_item_class <> '0' AND ls_item_class <> '1'
                            AND ls_item_class <> '2' THEN
            rs_err_code  := 'E.LDP10408';
            rs_err_msg   := 'You can specify only the item of which '
                         || 'Item Cl. is 0(Packing Materials) or '
                         || '1(Raw Materials) or 2(Parts).';
            rs_err_focus := 'itemno';
            RAISE EXCEPTION ' ';
        END IF;
        IF ls_item_status < '2' OR ls_item_status > '7' THEN
            rs_err_code  := 'E.LDP10411';
            rs_err_msg   := 'You can specify only the item of'
                         || ' which Item Status is 2 to 7.';
            rs_err_focus := 'itemno';
            RAISE EXCEPTION ' ';
        END IF;
        IF ls_airs_sign = '1' THEN
            rs_err_code  := 'E.LDP10420';
            rs_err_msg   := 'You cannot specify  AIRS Item.';
            rs_err_focus := 'itemno';
            RAISE EXCEPTION ' ';
        END IF;
        IF ls_demand_policy_code < '2' OR ls_demand_policy_code > '5' THEN
            rs_err_code  := 'E.LDP10413';
            rs_err_msg   := 'You can specify only the item of which'
                         || ' MRP Demand Policy Code is 2 to 5.';
            rs_err_focus := 'itemno';
            RAISE EXCEPTION ' ';
        END IF;
        IF ln_float_safety_stock_qty = '0' THEN
            rs_err_code  := 'E.LDP10422';
            rs_err_msg   := 'You cannot specify the item of which'
                         || ' Variable Safety Stock Quantity is 0.';
            rs_err_focus := 'itemno';
            RAISE EXCEPTION ' ';
        END IF;
        /* 2.3.5.3 */
        ls_deal_flag := '1';
    END IF; 
        /* 2.3.5.3.1*/
    IF ls_deal_flag <> '1' THEN
        IF TRIM(ps_ind_user_class) = '' OR TRIM(ps_ind_user_code) = '' THEN
            rs_err_code  := 'E.LDP10428';
            rs_err_msg   := 'Enter the value for Independent Requirements'
                         || ' Destination Classification and Code.';
            rs_err_focus := 'indUserCode';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;
        /* 2.3.5.3.2*/
    IF ls_deal_flag <> '1' AND ps_ind_user_class <> '1'
                           AND ps_ind_user_class <> '2' THEN
        rs_err_code  := 'E.LDP10429';
        rs_err_msg   := 'You can specify only 1(S/U),  2(Accounting Code)'
                     || ' or "X" for Independent Requirements'
                     || ' Destination Classificaton.';
        rs_err_focus := 'indUserCode';
        RAISE EXCEPTION ' ';
    END IF;
        /* 2.3.5.4 */
    IF ls_deal_flag <> '1' AND ps_ind_user_class = '1' THEN
        IF EXISTS ( SELECT 1
                      FROM le_mst_ind_user_transfer_check
                     WHERE target_org_code = ps_ind_user_code )THEN
            SELECT valid_ind_user_yn
                  ,ind_user_eq_transfer_yn
              INTO STRICT ls_valid_ind_user_yn
                  ,ls_ind_user_eq_transfer_yn
              FROM le_mst_ind_user_transfer_check
             WHERE target_org_code = ps_ind_user_code;

            IF ls_valid_ind_user_yn = 'Y' THEN
                ls_deal_flag := '1';
            END IF;

            IF ls_ind_user_eq_transfer_yn = 'Y' THEN
                IF ps_ind_user_code <> ps_transfer_code THEN
                    rs_err_code  := 'E.LDP10512';
                    rs_err_msg   := 'Specify the same value for Ind. Reqts. '
                                 || 'Destination and Charged Sec. '
                                 || 'when you specify CKD REPLACEMENT '
                                 || 'value for the both.';
                    rs_err_focus := 'indUserCode';
                    RAISE EXCEPTION ' ';
                ELSE
                    ls_deal_flag := '1';
                END IF;
            END IF;
        END IF;
    END IF;
        /* 2.3.5.4  */
        IF ls_deal_flag <> '1' THEN
            IF EXISTS ( SELECT 1
                          FROM la_area_master_su
                         WHERE su_code = ps_ind_user_code )THEN
            
                ls_exist_class1 := '1';
            ELSE
                ls_exist_class1 := '0';
            END IF;
        END IF;

            IF EXISTS ( SELECT 1
                          FROM la_area_master
                         WHERE sys_owner_cd = ps_sys_owner_cd
                           AND area_code     = '***'||ps_ind_user_code )THEN
               
                ls_exist_class2 := '1';
            ELSE
                ls_exist_class2 := '0';
            END IF;
            IF ls_exist_class1 = '0' AND ls_exist_class2 = '0' THEN
                rs_err_code  := 'E.LDP10004';
                rs_err_msg   := 'Receiver Code of independent demand does '
                             || 'not exist in the organization master.';
                rs_err_focus := 'indUserCode';
                RAISE EXCEPTION ' ';
            END IF;
            /* 2.3.5.5 */
            IF ls_exist_class1 <> '2' THEN

                IF EXISTS ( SELECT 1
                              FROM lz_function_parameter
                             WHERE system_code       = 'LD'
                               AND function_id = 'LDA0011'
                               AND option_code    = '1'
                               AND select_flg    = 'T' )THEN
                               SELECT 1
                                 FROM la_area_master_su
                                WHERE su_code       = ps_ind_user_code
                                  AND area_category = '24';
                    rs_err_code  := 'E.LDP10005';
                    rs_err_msg   := 'Receiver Code of independent demand does not exist'
                                 || ' in the accounting code table';
                ELSE
                    SELECT 1
                      FROM la_area_master_su
                      WHERE su_code       = ps_ind_user_code;
                    rs_err_code  := 'E.LDP10956';
                    rs_err_msg   := 'Accounting code exists in organization master.';
                    RAISE EXCEPTION ' ';
                END IF;
            END IF;
    /* 2.3.6 Due Date Check */
    IF NOT EXISTS ( SELECT 1
                      FROM le_mst_ind_user_transfer_check
                     WHERE target_org_code = ps_ind_user_code
                       AND ope_day_no_check_yn = 'Y' ) THEN
        IF EXISTS ( SELECT 1
                      FROM le_mst_calendar_sum
                     WHERE calendar_code = ls_calendar_code
                       AND calendar_ymd  = ps_start_date ) THEN
            SELECT day_type
              INTO STRICT ls_day_type
              FROM le_mst_calendar_sum
             WHERE calendar_code = ls_calendar_code
               AND calendar_ymd  = ps_start_date;
            IF ls_day_type <> '0' THEN
                rs_err_code  := 'E.LDP10353';
                rs_err_msg   := 'The day you specified is not a working-day.'
                            '[ ps_start_date  ] = ' ||
                            COALESCE( ps_start_date , 'NULL' );
                rs_err_focus := 'startDate';
                RAISE EXCEPTION ' ';
            END IF;
        /* Day Type Data Not Found */
        ELSE
            rs_err_code  := 'E.LDP10106';
            rs_err_msg   := 'Day String does not exist in the common calendar.';
            rs_err_focus := 'startDate';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    IF ps_start_date < ls_ic_slip_date THEN
        rs_err_code  := 'E.LDP10357';
        rs_err_msg   := 'You cannot specify the past date for Start Date.';
        rs_err_focus := 'startDate';
        RAISE EXCEPTION ' ';
    END IF;

    /* 2.3.7 Independent Required Quantity Login Possible Days */
    IF EXISTS ( SELECT 1
                  FROM le_system_parameter)THEN
        SELECT rd_input_days
              ,rd_delete_input_days
          INTO STRICT ln_rd_input_days
                     ,ln_rd_delete_input_days
          FROM le_system_parameter;
    ELSE
        rs_err_code  := 'E.LDP10932';
        rs_err_msg   := 'Independent Requirements Input Days does not'
                     || ' exist in the MRP system parameter.';
        rs_err_focus := ' ';
        RAISE EXCEPTION ' ';
    END IF;
    
    ln_rd_input_days1        := ln_rd_input_days;
    ln_rd_delete_input_days1 := ln_rd_delete_input_days;

    /* 2.3.7.2 Day Type Count */
    SELECT *
    INTO STRICT rec_day_type
    FROM LEYS0001 ( ls_calendar_code
                   ,ls_ic_slip_date
                   ,ln_rd_input_days1
                   );
    -- return item set --
    rn_status   := rec_day_type.rn_status;
    rs_sql_code := rec_day_type.rs_sql_code;
    rs_err_code := rec_day_type.rs_err_code;
    rs_err_msg  := rec_day_type.rs_err_msg;

    IF rn_status = -1 THEN

        RETURN NEXT;
        RETURN;
    ELSIF rn_status = -2 THEN

        RAISE EXCEPTION ' ';
    ELSE
        IF ps_start_date > rec_day_type.rs_target_date THEN
            rs_err_code  := 'E.LDP10370';
            rs_err_msg   := 'Start Date is over the period in which'
                         || ' the date is able to be registered from now on.';
            rs_err_focus := 'startDate';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;
        /* 2.3.9 */
    IF ps_pilot_condition_type = '1' OR ps_pilot_condition_type = '2' THEN
        IF ps_rd_class <> '4' OR ps_pilot_class <> '2' THEN
            rs_err_code  := 'E.LDP10514';
            rs_err_msg   := 'In case of Operation Cl. is 1 or 2,'
                         || ' specify X for Destn. Cd of Ind. Reqts.'
                         || ' and 2(Pilot Prod.) for Production Class.';
            rs_err_focus := 'pilotClass';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    /* 2.3.9 Transfer And Account Heading And Account Detail Check */
    IF ps_rd_class = '0' THEN
        SELECT *
        INTO STRICT rec_transfer_account
        FROM LDAS0312 ( ps_transfer_class
                       ,ps_transfer_code
                       ,ps_account_heading
                       ,ps_account_detail
                       ,ps_account_code_sales
                       ,ps_start_date                 -- 2017/10/25 Y.Mochiduki ADD
                       ,'1'                           -- 2017/10/25 Y.Mochiduki ADD
                       );
        -- return item set --
        rn_status    := rec_transfer_account.rn_status;
        rs_sql_code  := rec_transfer_account.rs_sql_code;
        rs_err_code  := rec_transfer_account.rs_err_code;
        rs_err_msg   := rec_transfer_account.rs_err_msg;
        rs_err_focus := rec_transfer_account.rs_err_focus;
        
        IF rn_status = -1 THEN
        
            RETURN NEXT;
            RETURN;
        ELSIF rn_status = -2 THEN
        
            RAISE EXCEPTION ' ';
        ELSIF rn_status = 1 THEN
        
            RETURN NEXT;
        END IF;
    END IF;

    IF ps_rd_class = '1' THEN
        IF TRIM(ps_delete_ymd) = '' THEN
            rs_err_code  := 'E.LDP10362';
            rs_err_msg   := 'When you register Advanced Production'
                         || ' Requirements, specify Deletion Date.';
            rs_err_focus := 'deleteYmd';
            RAISE EXCEPTION ' ';
        END IF;
        IF ps_delete_ymd <= ps_start_date THEN
            rs_err_code  := 'E.LDP10363';
            rs_err_msg   := 'For Deletion Date, specify the date'
                         || ' later than Start Date.';
            rs_err_focus := 'deleteYmd';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    /* 2.3.11 Delete Date Check */
    SELECT *
    INTO STRICT rec_delete_ymd
    FROM LEYS0001 ( ls_calendar_code
                   ,ps_start_date
                   ,ln_rd_delete_input_days1
                   );
    -- return item set --
    rn_status   := rec_delete_ymd.rn_status;
    rs_sql_code := rec_delete_ymd.rs_sql_code;
    rs_err_code := rec_delete_ymd.rs_err_code;
    rs_err_msg  := rec_delete_ymd.rs_err_msg;

    IF rn_status = -1 THEN

        RETURN NEXT;
        RETURN;
    ELSIF rn_status = -2 THEN

        RAISE EXCEPTION ' ';
    ELSE
        IF ps_delete_ymd > rec_delete_ymd.rs_target_date THEN
            rs_err_code  := 'E.LDP10371';
            rs_err_msg   := 'Deletion Date is over the period in which the date'
                         || ' is able to be resistered from Start Date.';
            rs_err_focus := 'deleteYmd';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;
        /* 2.3.12 S#U. Item Registration Check */
    IF ps_rd_class = '0' AND ps_supplier <> ps_usercd THEN
        IF EXISTS ( SELECT 1
                      FROM la_area_master_su
                     WHERE su_code    = ps_usercd )THEN
            SELECT area_category
              INTO STRICT ls_org_category_code3
              FROM la_area_master_su
             WHERE su_code     = ps_usercd;
            IF ls_org_category_code3 = '56' THEN
                rs_err_code  := 'E.LDP10179';
                rs_err_msg   := 'In case User is vendor, you cannot'
                             || ' register the item of "S#U."';
                rs_err_focus := 'usercd';
                RAISE EXCEPTION ' ';
            END IF;
        ELSE
            rs_err_code  := 'E.LDP10722';
            rs_err_msg   := 'Data does not exist in the organization master.';
            rs_err_focus := 'usercd';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    --------------------------------------------------
    --  < STEP3 : Return Value Processing >
    --------------------------------------------------
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
                           ,'LD21'                               --4
                           ,'1'                                  --5
                           ,'9'                                  --6
                           ,ps_receive_id                        --7
                           ,ps_request_system_code               --8
                           ,' '                                  --9
                           ,'LDAS0318'                           --10
                           ,ps_itemno                            --11
                           ,ps_supplier                          --12
                           ,ps_usercd                            --13
                           ,ps_order_no                          --14
                           ,' '                                  --15
                           ,' '                                  --16
                           ,pn_required_qty                      --17 
                           ,ps_reason_code                       --18
                           ,ps_transfer_class                    --19
                           ,ps_transfer_code                     --20
                           ,ps_account_heading                   --21
                           ,ps_budget_no                         --22
                           ,ps_account_code_sales                --23
                           ,ps_pilot_condition_type              --24
                           ,ps_start_date                        --25
                           ,' '                                  --26
                           ,' '                                  --27
                           ,' '                                  --28        
                           ,' '                                  --29         
                           ,0                                    --30
                           ,ps_pilot_class                       --31
                           ,ps_rd_class                          --32
                           ,ps_ind_user_class                    --33
                           ,ps_ind_user_code                     --34
                           ,ps_transfer_reason_code              --35
                           ,ps_delete_ymd                        --36
                           ,ps_remark                            --37
                           ,ps_sp_order_class                    --38
                           ,ps_sp_delivery_code                  --39
                           ,ps_sp_dealer_no                      --40
                           ,ps_sp_order_no                       --41
                           ,' '                                  --42
                           ,' '                                  --43
                           ,0                                    --44
                           ,' '                                  --45
                           ,' '                                  --46
                           ,' '                                  --47
                           ,' '                                  --48
                           ,' '                                  --49
                           ,' '                                  --50
                           ,0                                    --51
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
                           ,pn_required_qty                      --69
                           ,ps_start_date                        --70
                           ,' '                                  --71
                           ,' '                                  --72
                           );
            -- status judgement --
            IF rec_err_log_login.rn_status <> 0 THEN
                -- return item set --
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
        rn_status   := -1;
        rs_sql_code := SQLSTATE;
        rs_err_code := ' ';
        rs_err_msg  := SQLERRM;

        RETURN NEXT;
        RETURN;
END;
$function$
