--------------------------------------------------------------------------------
--@SEE << Valid / Payment report>>
--    @ID      : LDAS0318
--
--    @Written : 1.0.0                2025.10.17 Sun Sheng / YMSLX
--    --------------------------------------------------------------------------
--    @Update  : xxxxxxxxxxxx            xxxx.xx.xx xxxxxxxx / xx
--     Reason  : xxx
--              xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--
----------------------------------------------------------------------------
--  < INPUT Parameter >
--    @ps_user_id              <I/ > VARCHAR       : User ID
--    @ps_log_sign             <I/ > VARCHAR       : Log Sign
--    @ps_receive_id           <I/ > VARCHAR       : Receive ID
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
CREATE OR REPLACE FUNCTION LDAS0318(
      ps_user_id                          VARCHAR              --1  ユーザーＩＤ
    , ps_log_sign                         VARCHAR              --2  ログ出力サイン
    , ps_receive_id                       VARCHAR              --3  受信ID
    , ps_request_system_code              VARCHAR              --4  相手先システム識別
    , ps_itemno                           VARCHAR              --5  品目番号
    , ps_supplier                         VARCHAR              --6  供給者
    , ps_usercd                           VARCHAR              --7  使用者
    , ps_order_no                         VARCHAR              --8  オーダー番号
    , ps_rd_class                         VARCHAR              --9  所要量区分
    , ps_ind_user_class                   VARCHAR              --10 独立需要送り先区分
    , ps_ind_user_code                    VARCHAR              --11 独立需要送り先コード
    , ps_start_date                       VARCHAR              --12 着手日
    , ps_reason_code                      VARCHAR              --13 理由コード
    , ps_pilot_class                      VARCHAR              --14 生試初品区分
    , ps_pilot_condition_type             VARCHAR              --15 生試処理タイプ
    , pn_required_qty                     DECIMAL              --16 所要数
    , ps_remark                           VARCHAR              --17 コメント
    , ps_transfer_class                   VARCHAR              --18 費用振替先区分
    , ps_transfer_code                    VARCHAR              --19 費用振替先コード
    , ps_transfer_reason_code             VARCHAR              --20 振替理由コード
    , ps_account_heading                  VARCHAR              --21 勘定科目コード
    , ps_budget_no                        VARCHAR              --22 目的No
    , ps_account_code_sales               VARCHAR              --23 受払種別コード
    , ps_delete_ymd                       VARCHAR              --24 削除日付
    , ps_sp_order_class                   VARCHAR              --25 ｻｰﾋﾞｽﾊﾟｰﾂ特別発注区分
    , ps_sp_delivery_code                 VARCHAR              --26 ｻｰﾋﾞｽﾊﾟｰﾂ直送先ｺｰﾄﾞ
    , ps_sp_dealer_no                     VARCHAR              --27 ｻｰﾋﾞｽﾊﾟｰﾂﾃﾞｨｰﾗｰNO
    , ps_sp_order_no                      VARCHAR              --28 ｻｰﾋﾞｽﾊﾟｰﾂ受注番号
)
RETURNS TABLE(
    rn_status    INTEGER,    -- 処理ステータス
    rs_sql_code  VARCHAR,    -- SQLコード
    rs_err_code  VARCHAR,    -- エラーコード
    rs_err_msg   VARCHAR,    -- エラーメッセージ
    rs_err_focus VARCHAR     -- エラー位置
) AS
$BODY$
DECLARE
    -- SP return record  --
    rec_itemmast_date         RECORD;
    rec_fix_period_date       RECORD;
    rec_day_type              RECORD;
    rec_transfer_account      RECORD;
    rec_delete_ymd            RECORD;
    rec_err_log_login         RECORD;
    ls_item_class             le_mst_mrp_information.item_class%TYPE;
    ls_item_status            la_itemmast.item_status%TYPE;
    ls_airs_sign              le_mst_mrp_information.airs_sign%TYPE;
    ls_demand_policy_code     le_mst_mrp_information.demand_policy_code%TYPE;
    ln_float_safety_stock_qty le_mst_mrp_information.float_safety_stock_qty%TYPE;
    ls_calendar_code          la_area_master_su.calendar_code%TYPE;
    ls_day_type               le_mst_calendar_sum.day_type%TYPE;
    ls_fix_to_ymd             le_mst_fix_period.fix_to_ymd%TYPE;
    ls_area_category          la_area_master_su.area_category%TYPE;
    ls_area_category2         la_area_master_pf.area_category%TYPE;
    ls_area_category3         la_area_master_su.area_category%TYPE;
    ls_ic_slip_date           ld_mst_slip_date.ic_slip_date%TYPE;
    ls_valid_ind_user_yn      le_mst_ind_user_transfer_check.valid_ind_user_yn%TYPE;
    ls_ind_user_eq_transfer_yn
                              le_mst_ind_user_transfer_check.ind_user_eq_transfer_yn%TYPE;
    ls_ope_day_no_check_yn
                              le_mst_ind_user_transfer_check.ope_day_no_check_yn%TYPE;
    ln_rd_input_days          INTEGER;
    ln_rd_delete_input_days   INTEGER;
    ls_operation_flag         VARCHAR(01);    --処理区分
    ls_deal_flag              VARCHAR(01);    --取引フラグ
    ls_exist_class1           VARCHAR(01);
    ls_exist_class2           VARCHAR(01);
    ls_fix_period_id          VARCHAR;

    cs_pgmid                  CONSTANT VARCHAR := 'LDAS0318';
    cs_space                  CONSTANT VARCHAR := ' ';


BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    /* Return Value Set */
    rn_status                  := 0;
    rs_sql_code                := cs_space;
    rs_err_code                := cs_space;
    rs_err_msg                 := cs_space;
    rs_err_focus               := cs_space;

    /* Variable Initialization */
    ls_item_class              := cs_space;
    ls_item_status             := cs_space;
    ls_airs_sign               := cs_space;
    ls_demand_policy_code      := cs_space;
    ln_float_safety_stock_qty  := 0;
    ls_calendar_code           := cs_space;
    ls_day_type                := cs_space;
    ls_fix_to_ymd              := cs_space;
    ls_area_category           := cs_space;
    ls_area_category2          := cs_space;
    ls_area_category3          := cs_space;
    ls_ic_slip_date            := cs_space;
    ls_valid_ind_user_yn       := cs_space;
    ls_ind_user_eq_transfer_yn := cs_space;
    ls_ope_day_no_check_yn     := cs_space;
    ln_rd_input_days           := 0;
    ln_rd_delete_input_days    := 0;
    ls_operation_flag          := cs_space;
    ls_deal_flag               := cs_space;
    ls_exist_class1            := cs_space;
    ls_exist_class2            := cs_space;
    ls_fix_period_id           := cs_space;

    /* Argument Check */
    IF ps_pilot_class <> '2' AND ps_pilot_class <> '4'
                             AND TRIM(ps_pilot_class) <> '' THEN
        rs_err_code  := 'ld.E.LDP10089';
        rs_err_msg   := 'You can specify only 2(Pilot Production),'
                     || ' 4(Part Trial Production) or Blank(Mass Production)'
                     || ' for Production Cl.';
        RAISE EXCEPTION ' ';
    END IF;

    IF pn_required_qty <= 0 THEN
        rs_err_code  := 'ld.E.LDP10086';
        rs_err_msg   := 'You cannot specify 0 or less than 0.';
        RAISE EXCEPTION ' ';
    END IF;
    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    /* Get Itemmast Date Record */
    SELECT  LDAS0300.rn_status
          , LDAS0300.rs_sql_code
          , LDAS0300.rs_err_code
          , LDAS0300.rs_err_msg
          , LDAS0300.rs_item_class
          , LDAS0300.rs_item_status
          , LDAS0300.rs_airs_sign
          , LDAS0300.rs_demand_policy_code
          , LDAS0300.rn_float_safety_stock_qty
    INTO STRICT rec_itemmast_date
    FROM LDAS0300 ('LD21'
                   ,ps_itemno
                   ,ps_supplier
                   ,ps_usercd
                   );
    -- return item set --
    rs_sql_code      := rec_itemmast_date.rs_sql_code;
    rs_err_code      := rec_itemmast_date.rs_err_code;
    rs_err_msg       := rec_itemmast_date.rs_err_msg;

    IF rec_itemmast_date.rn_status = -1 THEN
        rn_status    := rec_itemmast_date.rn_status;
        rs_err_focus := cs_pgmid;

        RETURN NEXT;
        RETURN;
    ELSIF rec_itemmast_date.rn_status = -2 THEN

        RAISE EXCEPTION ' ';
    ELSE
        ls_item_class             := rec_itemmast_date.rs_item_class;
        ls_item_status            := rec_itemmast_date.rs_item_status;
        ls_airs_sign              := rec_itemmast_date.rs_airs_sign;
        ls_demand_policy_code     := rec_itemmast_date.rs_demand_policy_code;
        ln_float_safety_stock_qty := rec_itemmast_date.rn_float_safety_stock_qty;
    END IF;

    /* 2.3.2.1 Get Calendar Code */
    IF  EXISTS ( SELECT 1
                  FROM la_area_master_su
                 WHERE su_code = ps_usercd ) THEN
        SELECT calendar_code
          INTO STRICT ls_calendar_code
          FROM la_area_master_su
         WHERE su_code = ps_usercd;

    /* Calendar Code Data Not Found */
    ELSE
        rs_err_code  := 'ld.E.LDP10062';
        rs_err_msg   := 'Effective calendar does not exist by'
                     || ' the specified Supplier/User.';
        RAISE EXCEPTION ' ';
    END IF;

    /*2.3.3 Day Type Does Not Exist Error */
    IF TRIM(ps_delete_ymd) <> '' THEN

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
                rs_err_code  := 'ld.E.LDP10090';
                rs_err_msg   := 'The day you specified is not a working-day.';
                RAISE EXCEPTION ' ';
            END IF;

        /* Day Type Data Not Found */
        ELSE
            rs_err_code  := 'ld.E.LDP10064';
            rs_err_msg   := 'Day String does not exist in the common calendar.';
            RAISE EXCEPTION ' ';
        END IF;

        /*2.3.3.2 Get Fix Period */
        IF EXISTS(SELECT 1
                    FROM le_mst_mrp_information --MRP情報値
                   WHERE itemno   = ps_itemno
                     AND supplier = ps_supplier
                     AND usercd   = ps_usercd)THEN
            SELECT fix_period_id
              INTO STRICT ls_fix_period_id
              FROM le_mst_mrp_information
             WHERE itemno      = ps_itemno
               AND supplier    = ps_supplier
               AND usercd      = ps_usercd;
        ELSE
            rs_err_code  := 'ld.E.LDP10129';
            rs_err_msg   := 'The data you specified is not exist in MRP information.';
            RAISE EXCEPTION ' ';
        END IF;

        SELECT  LEBS0010.rn_status
              , LEBS0010.rs_sql_code
              , LEBS0010.rs_err_code
              , LEBS0010.rs_err_msg
              , LEBS0010.rs_t_fix_to_ymd
          INTO STRICT rec_fix_period_date
          FROM LEBS0010 ( ls_fix_period_id
                       ,'T');
        -- return item set --
        rs_sql_code     := rec_fix_period_date.rs_sql_code;
        rs_err_code     := rec_fix_period_date.rs_err_code;
        rs_err_msg      := rec_fix_period_date.rs_err_msg;

        IF rec_fix_period_date.rn_status = -1 THEN
           rn_status    := rec_fix_period_date.rn_status;
           rs_err_focus := cs_pgmid;

            RETURN NEXT;
            RETURN;
        ELSIF rec_fix_period_date.rn_status = -2 THEN

            RAISE EXCEPTION ' ';
        ELSE
            ls_fix_to_ymd := rec_fix_period_date.rs_t_fix_to_ymd;
        END IF;

        IF ps_delete_ymd <= ls_fix_to_ymd THEN
            rs_err_code  := 'ld.E.LDP10091';
            rs_err_msg   := 'For Deletion Date, specify the date later than'
                         || ' the final day of the fixed period of this time.';
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
        rs_err_code  := 'ld.E.LDP10004';
        rs_err_msg   := 'The IC pymac date is not exist.';
        RAISE EXCEPTION ' ';
    END IF;

    /* 2.3.5   Independent Required User Check */
    /* 2.3.5.1 Auto Safety Inventory R/D Check */
    IF EXISTS ( SELECT 1
                  FROM lz_function_parameter
                 WHERE system_code      = 'LE'
                   AND function_id      = 'LEA0002'
                   AND option_code      = '0'
                   AND select_flg       = 'T' ) THEN
        /* Auto Safety Inventory R/D : Not Register */
        IF ps_rd_class = '1' OR ps_rd_class = '4' OR ps_rd_class = '6'  THEN
            ls_operation_flag := '1';
        END IF;
    ELSE
        /* Auto Safety Inventory R/D : Register */
        IF ps_rd_class = '1' OR ps_rd_class = '3' OR ps_rd_class = '4' OR ps_rd_class = '6'  THEN
            ls_operation_flag := '1';
        END IF;
    END IF;

    /* 2.3.5.2 */
    IF ps_rd_class = '2' AND ls_operation_flag <> '1' THEN
        IF TRIM(ps_transfer_class) = '' OR TRIM(ps_transfer_code) = '' THEN
            rs_err_code  := 'ld.E.LDP10092';
            rs_err_msg   := 'Enter the value for Charged'
                         || ' Section Classification and Code.';
            RAISE EXCEPTION ' ';
        END IF;

        IF   ls_item_class <> '1' AND ls_item_class <> '2' AND ls_item_class <> '6' THEN
            rs_err_code  := 'ld.E.LDP10022';
            rs_err_msg   := 'You can specify only the item of which '
                         || 'Item Cl. is 1(Raw Materials) or '
                         || '2(Parts) or 6(Packing Materials).';
            RAISE EXCEPTION ' ';
        END IF;

        IF ls_item_status < '2' OR ls_item_status > '7' THEN
            rs_err_code  := 'ld.E.LDP10025';
            rs_err_msg   := 'You can specify only the item of which Item Status is 2 to 7.';
            RAISE EXCEPTION ' ';
        END IF;

        IF ls_airs_sign = '1' THEN
            rs_err_code  := 'ld.E.LDP10034';
            rs_err_msg   := 'You cannot specify AIRS Item.';
            RAISE EXCEPTION ' ';
        END IF;

        IF ls_demand_policy_code < '2' OR ls_demand_policy_code > '5' THEN
            rs_err_code  := 'ld.E.LDP10027';
            rs_err_msg   := 'You can specify only the item of which MRP Demand Policy Code is 2 to 5.';
            RAISE EXCEPTION ' ';
        END IF;
        IF ln_float_safety_stock_qty = 0 THEN
            rs_err_code  := 'ld.E.LDP10036';
            rs_err_msg   := 'You cannot specify the item of which Variable Safety Stock Quantity is 0.';
            RAISE EXCEPTION ' ';
        END IF;
        ls_operation_flag := '1';
    END IF;
    /* 2.3.5.3 */
    IF ls_operation_flag <> '1' THEN

        /* 2.3.5.3.1 */
        IF TRIM(ps_ind_user_class) = '' OR TRIM(ps_ind_user_code) = '' THEN
            rs_err_code  := 'ld.E.LDP10093';
            rs_err_msg   := 'Enter the value for Independent Requirements Destination Classification and Code.';
            RAISE EXCEPTION ' ';
        END IF;


        /* 2.3.5.3.2 */
        IF ps_ind_user_class <> '1' AND ps_ind_user_class <> '2' THEN
            rs_err_code  := 'ld.E.LDP10094';
            rs_err_msg   := 'You can specify only 1(S/UorP/F), 2(Accounting Code)'
                         || ' or "X" for Independent Requirements'
                         || ' Destination Classificaton.';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    /* 2.3.5.4.1 */
    IF ps_ind_user_class = '1' THEN
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
                ls_operation_flag := '1';
            END IF;

            IF ls_ind_user_eq_transfer_yn = 'Y' THEN
                IF ps_ind_user_code <> ps_transfer_code THEN
                    rs_err_code  := 'ld.E.LDP10095';
                    rs_err_msg   := 'Specify the same value for Ind. Reqts. Destination and Charged Sec. '
                                 || 'when you specify CKD REPLACEMENT value for the both.';
                    RAISE EXCEPTION ' ';
                END IF;
            END IF;
        END IF;
    END IF;

    /* 2.3.5.4.2 */
    IF EXISTS ( SELECT 1
                  FROM la_area_master_su
                 WHERE su_code = ps_ind_user_code )THEN
        SELECT area_category
          INTO STRICT ls_area_category
          FROM la_area_master_su
         WHERE su_code = ps_ind_user_code;
        ls_exist_class1 := '1';
    ELSE
        ls_exist_class1 := '0';
    END IF;

    IF EXISTS ( SELECT 1
                  FROM la_area_master_pf
                 WHERE pf_code = ps_ind_user_code )THEN
        SELECT area_category
          INTO STRICT ls_area_category2
          FROM la_area_master_pf
         WHERE pf_code = ps_ind_user_code;
        ls_exist_class2 := '1';
    ELSE
        ls_exist_class2 := '0';
    END IF;
    IF ls_exist_class1 = '0' AND ls_exist_class2 = '0' THEN
        rs_err_code  := 'ld.E.LDP10097';
        rs_err_msg   := 'Receiver Code of independent demand does not exist in the organization master.';
        RAISE EXCEPTION ' ';
    END IF;

    IF ls_exist_class1 = '1' THEN
        IF ls_area_category = '06' OR ls_area_category = '56' THEN
            IF EXISTS(SELECT 1
                        FROM la_area_master_su su
                        JOIN la_areastrc area
                          ON su.area_code = area.child_area_code
                       WHERE su.su_code = ps_ind_user_code
                         AND area.area_strc_type_code = 'X'
                         AND su.area_code = area.child_area_code
                         AND area.in_effective_ymd <= ls_ic_slip_date
                         AND area.out_effective_ymd  > ls_ic_slip_date
                         AND (area.parent_area_category = '02'
                          OR area.parent_area_category = '51'))THEN
                ls_deal_flag := '1';
            ELSE
                rs_err_code  := 'ld.E.LDP10096';
                rs_err_msg   := 'Upper Company Code is not defined in organization master.';
                RAISE EXCEPTION ' ';
            END IF;
        ELSE
            rs_err_code  := 'ld.E.LDP10097';
            rs_err_msg   := 'Receiver Code of independent demand does not exist in the organization master.';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    IF ls_exist_class2 = '1' THEN
        IF ls_area_category2 = '03' OR ls_area_category2 = '53' THEN
            IF EXISTS(SELECT 1
                        FROM la_area_master_pf pf
                        JOIN la_areastrc area
                          ON pf.area_code           = area.child_area_code
                       WHERE pf.pf_code                 = ps_ind_user_code
                         AND area.area_strc_type_code   = 'X'
                         AND pf.area_code           = area.child_area_code
                         AND area.in_effective_ymd      <= ls_ic_slip_date
                         AND area.out_effective_ymd     > ls_ic_slip_date
                         AND (area.parent_area_category = '02'
                          OR area.parent_area_category  = '51'))THEN
                ls_deal_flag := '1';
            ELSE
                rs_err_code  := 'ld.E.LDP10096';
                rs_err_msg   := 'Upper Company Code is not defined in organization master.';
                RAISE EXCEPTION ' ';
            END IF;
        ELSE
            rs_err_code  := 'ld.E.LDP10097';
            rs_err_msg   := 'Receiver Code of independent demand does not exist in the organization master.';
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
                rs_err_code  := 'ld.E.LDP10090';
                rs_err_msg   := 'The day you specified is not a working-day.';
                RAISE EXCEPTION ' ';
            END IF;
        /* Day Type Data Not Found */
        ELSE
            rs_err_code  := 'ld.E.LDP10064';
            rs_err_msg   := 'Day String does not exist in the common calendar.';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    IF ps_start_date < ls_ic_slip_date THEN
        rs_err_code  := 'ld.E.LDP10066';
        rs_err_msg   := 'You cannot specify the past date for Start Date.';
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
        rs_err_code  := 'ld.E.LDP10098';
        rs_err_msg   := 'Independent Requirements Input Days does not exist in the MRP system parameter.';
        RAISE EXCEPTION ' ';
    END IF;


    /* 2.3.7.2 Day Type Count */
    SELECT  LEYS0001.rn_status
          , LEYS0001.rs_sql_code
          , LEYS0001.rs_err_code
          , LEYS0001.rs_err_msg
          , LEYS0001.rs_target_date
    INTO STRICT rec_day_type
    FROM LEYS0001 ( ls_calendar_code
                   ,ls_ic_slip_date
                   ,ln_rd_input_days
                   );
    -- return item set --
    rs_sql_code      := rec_day_type.rs_sql_code;
    rs_err_code      := rec_day_type.rs_err_code;
    rs_err_msg       := rec_day_type.rs_err_msg;
    IF rec_day_type.rn_status = -1 THEN
        rn_status    := rec_day_type.rn_status;
        rs_err_focus := cs_pgmid;

        RETURN NEXT;
        RETURN;
    ELSIF rec_day_type.rn_status = -2 THEN

        RAISE EXCEPTION ' ';
    ELSE
        IF ps_start_date > rec_day_type.rs_target_date THEN
            rs_err_code  := 'ld.E.LDP10099';
            rs_err_msg   := 'Start Date is over the period in which the date is able to be registered from now on.';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    /* 2.3.8 */
    IF ps_pilot_condition_type = '1' OR ps_pilot_condition_type = '2' THEN
        IF ps_rd_class <> '4' OR ps_pilot_class <> '2' THEN
            rs_err_code  := 'ld.E.LDP10100';
            rs_err_msg   := 'In case of Operation Cl. is 1 or 2,'
                         || ' specify X for Destn. Cd of Ind. Reqts.'
                         || ' and 2(Pilot Prod.) for Production Class.';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    /* 2.3.9 Transfer And Account Heading And Account Detail Check */
    IF ps_rd_class = '0' THEN
        SELECT  LDAS0312.rn_status
              , LDAS0312.rs_sql_code
              , LDAS0312.rs_err_code
              , LDAS0312.rs_err_msg
        INTO STRICT rec_transfer_account
        FROM LDAS0312 ( ps_transfer_class
                       ,ps_transfer_code
                       ,ps_account_heading
                       ,ps_account_code_sales
                       ,ps_start_date
                       ,'1'
                       );
        -- return item set --
        rs_sql_code      := rec_transfer_account.rs_sql_code;
        rs_err_code      := rec_transfer_account.rs_err_code;
        rs_err_msg       := rec_transfer_account.rs_err_msg;
        IF rec_transfer_account.rn_status = -1 THEN
            rn_status    := rec_transfer_account.rn_status;
            rs_err_focus := cs_pgmid;

            RETURN NEXT;
            RETURN;
        ELSIF rec_transfer_account.rn_status = -2 THEN

            RAISE EXCEPTION ' ';
        ELSIF rec_transfer_account.rn_status = 1 THEN
            rn_status    := rec_transfer_account.rn_status;
            rs_err_focus := cs_pgmid;

            RETURN NEXT;
        END IF;
    END IF;
    /* 2.3.10  */
    IF ps_rd_class = '1' THEN
        IF TRIM(ps_delete_ymd) = '' THEN
            rs_err_code  := 'ld.E.LDP10101';
            rs_err_msg   := 'When you register Advanced Production Requirements, specify Deletion Date.';
            RAISE EXCEPTION ' ';
        END IF;
        IF ps_delete_ymd <= ps_start_date THEN
            rs_err_code  := 'ld.E.LDP10102';
            rs_err_msg   := 'For Deletion Date, specify the date later than Start Date.';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    /* 2.3.11 Delete Date Check */
    SELECT  LEYS0001.rn_status,
            LEYS0001.rs_sql_code,
            LEYS0001.rs_err_code,
            LEYS0001.rs_err_msg,
            LEYS0001.rs_target_date
    INTO STRICT rec_delete_ymd
    FROM LEYS0001 ( ls_calendar_code
                   ,ps_start_date
                   ,ln_rd_delete_input_days
                   );
    -- return item set --
    rs_sql_code      := rec_delete_ymd.rs_sql_code;
    rs_err_code      := rec_delete_ymd.rs_err_code;
    rs_err_msg       := rec_delete_ymd.rs_err_msg;
    IF rec_delete_ymd.rn_status = -1 THEN
        rn_status    := rec_delete_ymd.rn_status;
        rs_err_focus := cs_pgmid;

        RETURN NEXT;
        RETURN;
    ELSIF rec_delete_ymd.rn_status = -2 THEN

        RAISE EXCEPTION ' ';
    ELSE
        IF ps_delete_ymd > rec_delete_ymd.rs_target_date THEN
            rs_err_code  := 'ld.E.LDP10103';
            rs_err_msg   := 'Deletion Date is over the period in which the date is able to be registered from Start Date.';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    /* 2.3.12 S#U. Item Registration Check */
    IF ps_rd_class = '0' AND ps_supplier <> ps_usercd THEN
        SELECT area_category
          INTO STRICT ls_area_category3
          FROM la_area_master_su
         WHERE su_code = ps_usercd;
        IF ls_area_category3 = '56' THEN
            rs_err_code  := 'ld.E.LDP10104';
            rs_err_msg   := 'In case User is vendor, you cannot register the item of "S#U."';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    --------------------------------------------------
    --  < STEP3 : Return Value Processing >
    --------------------------------------------------
    RETURN NEXT;
    RETURN;

EXCEPTION
    --------------------------------------------------
    --  Error Handle
    --------------------------------------------------
    --  # Indispensability(End)
    --------------------------------------------------
    WHEN RAISE_EXCEPTION THEN
        IF rn_status <> 0 THEN  -- FOR CALL SP ERROR
            NULL;
        ELSE                    -- FOR PGM ERROR
            rn_status     :=  -2;
            rs_sql_code   := cs_space;
            rs_err_focus  := cs_pgmid;
            IF ps_log_sign = '1' THEN
                SELECT LDAS0409.rn_status
                     , LDAS0409.rs_sql_code
                     , LDAS0409.rs_err_code
                     , LDAS0409.rs_err_msg
                INTO STRICT rec_err_log_login
                FROM LDAS0409 ( '99'                                 --1
                               ,ps_user_id                           --2
                               ,rs_err_code                          --3
                               ,'LD21'                               --4
                               ,'1'                                  --5
                               ,'9'                                  --6
                               ,ps_receive_id                        --7
                               ,ps_request_system_code               --8
                               ,cs_space                             --9
                               ,cs_pgmid                             --10
                               ,ps_itemno                            --11
                               ,ps_supplier                          --12
                               ,ps_usercd                            --13
                               ,ps_order_no                          --14
                               ,cs_space                             --15
                               ,cs_space                             --16
                               ,pn_required_qty                      --17
                               ,ps_reason_code                       --18
                               ,ps_transfer_class                    --19
                               ,ps_transfer_code                     --20
                               ,ps_account_heading                   --21
                               ,ps_budget_no                         --22
                               ,ps_account_code_sales                --23
                               ,ps_pilot_condition_type              --24
                               ,ps_start_date                        --25
                               ,cs_space                             --26
                               ,cs_space                             --27
                               ,cs_space                             --28
                               ,cs_space                             --29
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
                               ,cs_space                             --42
                               ,cs_space                             --43
                               ,0                                    --44
                               ,cs_space                             --45
                               ,cs_space                             --46
                               ,cs_space                             --47
                               ,cs_space                             --48
                               ,cs_space                             --49
                               ,cs_space                             --50
                               ,0                                    --51
                               ,cs_space                             --52
                               ,cs_space                             --53
                               ,cs_space                             --54
                               ,cs_space                             --55
                               ,cs_space                             --56
                               ,cs_space                             --57
                               ,cs_space                             --58
                               ,cs_space                             --59
                               ,cs_space                             --60
                               ,cs_space                             --61
                               ,cs_space                             --62
                               ,cs_space                             --63
                               ,cs_space                             --64
                               ,cs_space                             --65
                               ,ps_itemno                            --66
                               ,ps_supplier                          --67
                               ,ps_usercd                            --68
                               ,pn_required_qty                      --69
                               ,ps_start_date                        --70
                               ,cs_space                             --71
                               ,cs_space                             --72
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
        END IF;

    RETURN NEXT;
    RETURN;

    WHEN OTHERS THEN
        rn_status   := -1;
        rs_sql_code := SQLSTATE;
        rs_err_code := cs_space;
        rs_err_msg  := SQLERRM;
        rs_err_focus:= cs_pgmid;

        RETURN NEXT;
        RETURN;
END;
$BODY$
LANGUAGE 'plpgsql';