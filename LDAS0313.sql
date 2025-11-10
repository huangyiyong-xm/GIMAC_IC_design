--------------------------------------------------------------------------------
--@SEE << Valid / Regist Order >>
--    @ID      : LDAS0313
--
--    @Written : 1.0.0                2025.10.16 Sun Sheng / YMSL
--    --------------------------------------------------------------------------
--    @Update  : xxxxxxxxxxxx         xxxx.xx.xx  xxxxxxxx  / xx
--     Reason  : xxx
--               xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--
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
CREATE OR REPLACE FUNCTION LDAS0313(
      ps_user_id                         VARCHAR                         -- 1  ユーザーＩＤ
    , ps_log_sign                        VARCHAR                         -- 2  ログ出力サイン
    , ps_recieve_id                      VARCHAR                         -- 3  受信ID
    , ps_request_system_code             VARCHAR                         -- 4  相手先システム識別
    , ps_itemno                          VARCHAR                         -- 5  品目番号
    , ps_supplier                        VARCHAR                         -- 6  供給者
    , ps_usercd                          VARCHAR                         -- 7  使用者
    , ps_order_no                        VARCHAR                         -- 8  オーダー番号
    , pn_order_qty                       DECIMAL                         -- 9  オーダー数
    , ps_start_date                      VARCHAR                         -- 10 着手日
    , ps_due_date                        VARCHAR                         -- 11 完了日
    , ps_disburse_date                   VARCHAR                         -- 12 払出日
    , ps_due_begin_time                  VARCHAR                         -- 13 完了開始時間
    , ps_due_end_time                    VARCHAR                         -- 14 完了終了時間
    , ps_reason_code                     VARCHAR                         -- 15 理由コード
    , pn_carry_over_qty                  DECIMAL                         -- 16 繰越調整数
    , ps_pilot_class                     VARCHAR                         -- 17 生試初品区分 (生試=２、量産初品=３、量産=SPACE)
    , ps_input_txn                       VARCHAR                         -- 18 入力元トランザクション
)
RETURNS TABLE(
      rn_status    INTEGER
    , rs_sql_code  VARCHAR
    , rs_err_code  VARCHAR
    , rs_err_msg   VARCHAR
    , rs_err_focus VARCHAR
) AS
$BODY$
DECLARE
    -- SP return record  --
    rec_itemmast_date          RECORD;
    rec_err_log_login          RECORD;
    rec_order_date             RECORD;
    ls_demand_policy_code      le_mst_mrp_information.demand_policy_code%TYPE;
    ls_item_status             la_itemmast.item_status%TYPE;
    ln_float_safety_stock_qty  le_mst_mrp_information.float_safety_stock_qty%TYPE;
    ls_order_policy_code       le_mst_mrp_information.order_policy_code%TYPE;
    ld_due_date                TIMESTAMP;
    ls_due_weekday             VARCHAR(3);

    -- Constants definition
    cs_pgmid                   CONSTANT VARCHAR := 'LDAS0313';
    cs_LD11                    CONSTANT VARCHAR := 'LD11';
    cs_space                   CONSTANT VARCHAR := ' ';
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    /* Return Value Set */
    rn_status               :=   0;
    rs_sql_code             := cs_space;
    rs_err_code             := cs_space;
    rs_err_msg              := cs_space;
    rs_err_focus            := cs_space;

    /* Variable Initialization */
    ls_demand_policy_code     := cs_space;
    ls_item_status            := cs_space;
    ln_float_safety_stock_qty :=   0;
    ls_order_policy_code      := cs_space;
    ld_due_date    := TO_TIMESTAMP(ps_due_date,'YYYYMMDD');
    ls_due_weekday := TO_CHAR(ld_due_date,'DY');

    /* Argument Check */
    IF pn_order_qty <= 0 THEN
        rs_err_code  := 'ld.E.LDP10075';
        rs_err_msg   := 'You cannot specify 0 or less than 0.';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_pilot_class <> '2' AND ps_pilot_class <> '3'
                             AND TRIM(ps_pilot_class) <> '' THEN
        rs_err_code  := 'ld.E.LDP10076';
        rs_err_msg   := 'You can specify only 2(Pilot Production),'
                     || ' 3(First Production) or Blank(Mass Production)'
                     || ' for Producion Classsification.';
        RAISE EXCEPTION ' ';
    END IF;

    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    /* Get Itemmast Date Record */
        SELECT    LDAS0300.rn_status
                , LDAS0300.rs_sql_code
                , LDAS0300.rs_err_code
                , LDAS0300.rs_err_msg
                , LDAS0300.rs_err_focus
                , LDAS0300.rs_demand_policy_code
                , LDAS0300.rs_item_status
                , LDAS0300.rn_float_safety_stock_qty
          INTO STRICT rec_itemmast_date
          FROM LDAS0300 ( cs_LD11
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
        ln_float_safety_stock_qty := rec_itemmast_date.rn_float_safety_stock_qty;
    END IF;

    /* Get Order Date Record */
    SELECT    LDAS0301.rn_status
            , LDAS0301.rs_sql_code
            , LDAS0301.rs_err_code
            , LDAS0301.rs_err_msg
            , LDAS0301.rs_err_focus
    INTO STRICT rec_order_date
    FROM LDAS0301 ( cs_LD11
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
        rs_err_code  := 'ld.E.LDP10081';
        rs_err_msg   := 'Reason Code does not exist'
                     || ' in the order reason code table.';
        RAISE EXCEPTION ' ';
    END IF;

    /* Return Pilot Class Check */
    IF (ps_input_txn = '18' OR ps_input_txn = '28') THEN
        IF ls_item_status = '2' THEN
            IF ps_pilot_class <> '2' THEN
                rs_err_code  := 'ld.E.LDP10077';
                rs_err_msg   := 'You cannot register Mass Production Order'
                             || ' for Pilot Production Parts in Parts Return'
                             || ' and Scrap Report Operation.';
                RAISE EXCEPTION ' ';
            END IF;
        END IF;
    END IF;

    /* Safety Stock Check */
    IF ps_input_txn = '28' THEN
        IF ln_float_safety_stock_qty <> 0 THEN
            rs_err_code  := 'ld.E.LDP10078';
            rs_err_msg   := 'In Scrap Report Operation, you cannot register'
                         || ' the order for the item that has safety stock.';
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
                    rs_err_code  := 'ld.E.LDP10079';
                    rs_err_msg   := 'Due Date you entered does not meet with the'
                                 || ' setting of DELIVERY STANDARD DAY TABLE.';
                    RAISE EXCEPTION ' ';
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
                rs_err_code  := 'ld.E.LDP10087';
                rs_err_msg   := 'First production order of'
                             || ' the same item already exists.';
                RAISE EXCEPTION ' ';
            END IF;
        END IF;
    ELSE
        NULL;
    END IF;

    IF ps_pilot_class = '3' THEN
        IF ls_item_status > '3' THEN
            rs_err_code  := 'ld.E.LDP10088';
            rs_err_msg   := 'Because Item Status is not 3(First Production),'
                         || ' you cannot register first production order.';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

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
                rs_err_code  := 'ld.E.LDP10080';
                rs_err_msg   := 'After the mass production order you entered,'
                             || ' first production order exists.';
            END IF;
        END IF;
    END IF;

    --------------------------------------------------
    --  < STEP3 : Return Value Processing >
    --------------------------------------------------
    RETURN NEXT;
    RETURN;
EXCEPTION
    WHEN RAISE_EXCEPTION THEN
        IF rn_status <> 0 THEN  -- FOR CALL SP ERROR
             NULL;
        ELSE
            rn_status    :=  -2;
            rs_sql_code  := cs_space;
            rs_err_focus := cs_pgmid;

            IF ps_log_sign = '1' THEN
                SELECT  LDAS0409.rn_status
                       ,LDAS0409.rs_sql_code
                       ,LDAS0409.rs_err_code
                       ,LDAS0409.rs_err_msg
                       ,LDAS0409.rs_err_focus
                INTO STRICT rec_err_log_login
                               FROM LDAS0409 (
                                '99'                                 --1
                                ,ps_user_id                          --2
                                ,rs_err_code                         --3
                                ,'LD11'                              --4
                                ,'1'                                 --5
                                ,'9'                                 --6
                                ,ps_recieve_id                       --7
                                ,ps_request_system_code              --8
                                ,ps_input_txn                        --9
                                ,cs_pgmid                            --10
                                ,ps_itemno                           --11
                                ,ps_supplier                         --12
                                ,ps_usercd                           --13
                                ,ps_order_no                         --14
                                ,cs_space                            --15
                                ,cs_space                            --16
                                ,pn_order_qty                        --17
                                ,ps_reason_code                      --18
                                ,cs_space                            --19
                                ,cs_space                            --20
                                ,cs_space                            --21
                                ,cs_space                            --22
                                ,cs_space                            --23
                                ,cs_space                            --24
                                ,ps_start_date                       --25
                                ,ps_due_date                         --26
                                ,ps_disburse_date                    --27
                                ,ps_due_begin_time                   --28
                                ,ps_due_end_time                     --29
                                ,pn_carry_over_qty                   --30
                                ,ps_pilot_class                      --31
                                ,cs_space                            --32
                                ,cs_space                            --33
                                ,cs_space                            --34
                                ,cs_space                            --35
                                ,cs_space                            --36
                                ,cs_space                            --37
                                ,cs_space                            --38
                                ,cs_space                            --39
                                ,cs_space                            --40
                                ,cs_space                            --41
                                ,cs_space                            --42
                                ,cs_space                            --43
                                ,0                                   --44
                                ,cs_space                            --45
                                ,cs_space                            --46
                                ,cs_space                            --47
                                ,cs_space                            --48
                                ,cs_space                            --49
                                ,cs_space                            --50
                                ,cs_space                            --51
                                ,cs_space                            --52
                                ,cs_space                            --53
                                ,cs_space                            --54
                                ,cs_space                            --55
                                ,cs_space                            --56
                                ,cs_space                            --57
                                ,cs_space                            --58
                                ,cs_space                            --59
                                ,cs_space                            --60
                                ,cs_space                            --61
                                ,cs_space                            --62
                                ,cs_space                            --63
                                ,cs_space                            --64
                                ,cs_space                            --65
                                ,ps_itemno                           --66
                                ,ps_supplier                         --67
                                ,ps_usercd                           --68
                                ,pn_order_qty                        --69
                                ,ps_start_date                       --70
                                ,ps_due_date                         --71
                                ,ps_disburse_date                    --72
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

    WHEN OTHERS THEN
        rn_status    := -1;
        rs_sql_code  := SQLSTATE;
        rs_err_code  := cs_space;
        rs_err_msg   := SQLERRM;
        rs_err_focus := cs_pgmid;

        RETURN NEXT;
        RETURN;
END;
$BODY$
LANGUAGE 'plpgsql';
