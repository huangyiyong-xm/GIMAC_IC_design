--------------------------------------------------------------------------------
--@SEE << Valid Common/Regist Order Date Check >>
--    @ID      : LDAS0301
--
--    @Written : 1.0.0                2025.10.15 Sun Sheng / YMSLX
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
--    @ps_operation_id       <I/ > VARCHAR       : Operation Id
--    @ps_start_date         <I/ > VARCHAR       : Start Date
--    @ps_due_date           <I/ > VARCHAR       : Due Date
--    @ps_disburse_date      <I/ > VARCHAR       : Disburse Date
--    @ps_itemno             <I/ > VARCHAR       : Item No
--    @ps_supplier           <I/ > VARCHAR       : Supplier
--    @ps_usercd             <I/ > VARCHAR       : Usercd
--    @ps_demand_pol_cd      <I/ > VARCHAR       : Demand Policy Code
--  < OUTPUT Parameter >
--    @rn_status             < /O> INTEGER       : Return Code
--                                              (  0 : Normal        )
--                                              ( -1 : Sql Error     )
--                                              ( -2 : PGM Error     )
--    @rs_sql_code           < /O> VARCHAR       : Sql Code
--    @rs_err_code           < /O> VARCHAR       : Error Code
--    @rs_err_msg            < /O> VARCHAR       : Error Message
--    @rs_err_focus          < /O> VARCHAR       : Error Focus
----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDAS0301(
      ps_operation_id     VARCHAR       -- 1 処理識別
    , ps_start_date       VARCHAR       -- 2 着手日
    , ps_due_date         VARCHAR       -- 3 完了日
    , ps_disburse_date    VARCHAR       -- 4 払出日
    , ps_itemno           VARCHAR       -- 5 品目番号
    , ps_supplier         VARCHAR       -- 6 供給者
    , ps_usercd           VARCHAR       -- 7 使用者
    , ps_demand_pol_cd    VARCHAR       -- 8 MRP需要方針コード
)
RETURNS TABLE(
     rn_status            INTEGER       -- 1 ステータス
   , rs_sql_code          VARCHAR       -- 2 SQLコード
   , rs_err_code          VARCHAR       -- 3 エラーコード
   , rs_err_msg           VARCHAR       -- 4 エラーメッセージ
   , rs_err_focus         VARCHAR       -- 5 エラー位置
) AS
$BODY$
DECLARE
    --------------------------------------------------
    --  < Definition Local Paramater >
    --------------------------------------------------
    rec_fix_period_date RECORD;
    ls_calendar_code    la_area_master_su.calendar_code%TYPE;
    ls_day_type         le_mst_calendar_sum.day_type%TYPE;
    ls_ic_slip_date     ld_mst_slip_date.ic_slip_date%TYPE;
    ls_option_code      lz_function_parameter.option_code%TYPE;
    ls_item_type        la_itemmast.item_type%TYPE;
    ls_fix_to_ymd       VARCHAR;
    ln_mon_diff         INTEGER;

    cs_empty_string     CONSTANT VARCHAR := '';
    cs_org_type         CONSTANT VARCHAR := '000';
    cs_LE               CONSTANT VARCHAR := 'LE';
    cs_STD              CONSTANT VARCHAR := 'STD';
    cs_T                CONSTANT VARCHAR := 'T';
    cs_LD11             CONSTANT VARCHAR := 'LD11';
    cs_LD41             CONSTANT VARCHAR := 'LD41';
    cs_LD71             CONSTANT VARCHAR := 'LD71';
    cs_OPTION_0         CONSTANT VARCHAR := '0';
    cs_DEMAND_1         CONSTANT VARCHAR := '1';
    cs_DEMAND_2         CONSTANT VARCHAR := '2';
    cs_SPACE            CONSTANT VARCHAR := ' ';
    cs_pgmid            CONSTANT VARCHAR := 'LDAS0301';
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    /* Return Value Set */
    rn_status               :=               0;
    rs_sql_code             := cs_empty_string;
    rs_err_code             := cs_empty_string;
    rs_err_msg              := cs_empty_string;
    rs_err_focus            := cs_empty_string;

    /* Variable Initialization */
    ls_calendar_code        := cs_empty_string;
    ls_day_type             := cs_empty_string;
    ls_ic_slip_date         := cs_empty_string;
    ls_option_code          := cs_empty_string;
    ls_item_type            := cs_empty_string;
    ls_fix_to_ymd           := cs_empty_string;
    ln_mon_diff             :=               0;

    /* Argument Check */
    IF ps_start_date IS NULL OR TRIM(ps_start_date) = '' THEN
        rs_err_code  := 'ld.E.LDP10059';
        rs_err_msg   := 'Specify Start Date.';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_due_date IS NULL OR TRIM(ps_due_date) = '' THEN
        rs_err_code  := 'ld.E.LDP10060';
        rs_err_msg   := 'Specify Due Date.';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_disburse_date IS NULL OR TRIM(ps_disburse_date) = '' THEN
        rs_err_code  := 'ld.E.LDP10061';
        rs_err_msg   := 'Specify Disburse Date.';
        RAISE EXCEPTION ' ';
    END IF;
    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    /* Get Calendar Code */
    IF EXISTS ( SELECT 1
                  FROM la_area_master_su
                 WHERE su_code     = ps_usercd ) THEN
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

    /* Day Type Does Not Exist Error */
    IF EXISTS ( SELECT 1
                  FROM le_mst_calendar_sum
                 WHERE calendar_code = ls_calendar_code
                   AND calendar_ymd  = ps_start_date ) THEN
    SELECT day_type
      INTO STRICT ls_day_type
      FROM le_mst_calendar_sum
     WHERE calendar_code = ls_calendar_code
       AND calendar_ymd  = ps_start_date;
        IF ls_day_type <> cs_OPTION_0 THEN
            rs_err_code  := 'ld.E.LDP10063';
            rs_err_msg   := 'The day you specified is not a working-day.';
            RAISE EXCEPTION ' ';
        END IF;

    /* Day Type Data Not Found */
    ELSE
        rs_err_code  := 'ld.E.LDP10064';
        rs_err_msg   := 'Day String does not exist in the common calendar.';
        RAISE EXCEPTION ' ';
    END IF;

    /* Get Fix Period */
    IF EXISTS ( SELECT 1
                  FROM le_mst_mrp_information
                 WHERE   itemno     = ps_itemno
                   AND     supplier = ps_supplier
                   AND     usercd   = ps_usercd    ) THEN
        SELECT     fix_period_id
          INTO     STRICT ls_fix_to_ymd
          FROM     le_mst_mrp_information
         WHERE     itemno   = ps_itemno
           AND     supplier = ps_supplier
           AND     usercd   = ps_usercd;
        SELECT LEBS0010.rn_status
             , LEBS0010.rs_sql_code
             , LEBS0010.rs_err_code
             , LEBS0010.rs_err_msg
             , LEBS0010.rs_t_fix_to_ymd
          INTO rec_fix_period_date
          FROM LEBS0010(ls_fix_to_ymd,'T');
         IF rec_fix_period_date.rn_status <> 0 THEN
            rs_err_msg  := '<<SP:LEBS0010 Error Return>> '
                        || 'Return:  ' ||  rec_fix_period_date.rn_status || ','|| rec_fix_period_date.rs_sql_code || ','
                        || rec_fix_period_date.rs_err_code || ','|| rec_fix_period_date.rs_err_msg;
            RAISE EXCEPTION ' ';
        ELSE
            ls_fix_to_ymd  := rec_fix_period_date.rs_t_fix_to_ymd;
        END IF;
    ELSE
        rs_err_code  := 'ld.E.LDP10129';
        rs_err_msg   := 'Item does not exist in the itemmast mrp.';
        RAISE EXCEPTION ' ';
    END IF;

    /* Get Ic Slip Date */
    IF EXISTS ( SELECT 1
                  FROM ld_mst_slip_date
                 WHERE operation_type = cs_STD )THEN
                SELECT ic_slip_date
                  INTO STRICT ls_ic_slip_date
                  FROM ld_mst_slip_date
                 WHERE operation_type = cs_STD;
    ELSE
        rs_err_code  := 'ld.E.LDP10004';
        rs_err_msg   := 'The IC pymac date is not exist.';
        RAISE EXCEPTION ' ';
    END IF;

    /* Start Date Check */
    IF ( ps_operation_id = cs_LD11 OR ps_operation_id = cs_LD41 ) THEN
        IF ( ps_demand_pol_cd <> cs_DEMAND_1 AND
             ps_demand_pol_cd <> cs_DEMAND_2 ) THEN
            IF ( ps_start_date     > ls_fix_to_ymd ) THEN
                rs_err_code  := 'ld.E.LDP10065';
                rs_err_msg   := 'For Start Date, specify the date former than'
                             || ' the final day of the fixed order period.';
                RAISE EXCEPTION ' ';
            END IF;
        END IF;
    ELSE
        IF ps_operation_id = cs_LD71 THEN
            IF ps_start_date > ls_fix_to_ymd THEN
                rs_err_code  := 'ld.E.LDP10065';
                rs_err_msg   := 'For Start Date, specify the date former than'
                             || ' the final day of the fixed order period.';
                RAISE EXCEPTION ' ';
            ELSIF ps_start_date < ls_ic_slip_date THEN
                rs_err_code  := 'ld.E.LDP10066';
                rs_err_msg   := 'You cannot specify the past date for'
                             || ' Start Date.';
                RAISE EXCEPTION ' ';
            ELSE
                NULL;
            END IF;
        END IF;
    END IF;

    /* Get Option Code */
    IF EXISTS ( SELECT 1
                  FROM lz_function_parameter
                WHERE system_code = cs_LE
                  AND function_id = 'LEA0001'
                  AND select_flg = cs_T )THEN
                SELECT option_code
                  INTO STRICT ls_option_code
                  FROM lz_function_parameter
                 WHERE system_code = cs_LE
                   AND function_id = 'LEA0001'
                   AND select_flg = cs_T;

    /* Option Code Not Found */
    ELSE
        rs_err_code  := 'ld.E.LDP10002';
        rs_err_msg   := 'Target data does not exist'
                     || ' in the Function Parameter table.';
        RAISE EXCEPTION ' ';
    END IF;

    /* Get Item Type */
    IF EXISTS ( SELECT 1
                  FROM la_itemmast
                 WHERE itemno   = ps_itemno
                   AND supplier = ps_supplier
                   AND usercd   = ps_usercd )THEN
                SELECT item_type
                  INTO STRICT ls_item_type
                  FROM la_itemmast
                 WHERE itemno   = ps_itemno
                   AND supplier = ps_supplier
                   AND usercd   = ps_usercd;
    /* Item Type Not Found */
    ELSE
        rs_err_code  := 'ld.E.LDP10067';
        rs_err_msg   := 'Data does not exist in the item master.';
        RAISE EXCEPTION ' ';
    END IF;

    /* Due Date Check */
    IF (ls_option_code = cs_OPTION_0   AND ps_due_date < ls_ic_slip_date
                              AND ls_item_type <> cs_DEMAND_2 ) OR
       (ls_option_code <> cs_OPTION_0  AND ps_due_date < ls_ic_slip_date )THEN
        rs_err_code  := 'ld.E.LDP10068';
        rs_err_msg   := 'You cannot specify the past date for due date.';
        RAISE EXCEPTION ' ';
    END IF;

    /* Day Type Does Not Exist Error */
    IF EXISTS ( SELECT 1
                  FROM le_mst_calendar_sum
                 WHERE calendar_code = ls_calendar_code
                   AND calendar_ymd  = ps_due_date ) THEN
        SELECT day_type
          INTO STRICT ls_day_type
          FROM le_mst_calendar_sum
         WHERE calendar_code = ls_calendar_code
           AND calendar_ymd  = ps_due_date;
        IF ls_day_type <> cs_OPTION_0 THEN
            rs_err_code  := 'ld.E.LDP10069';
            rs_err_msg   := 'The day you specified is not a working-day.' ;
            RAISE EXCEPTION ' ';
        END IF;

    /* Day Type Does Not Exist  */
    ELSE
        rs_err_code  := 'ld.E.LDP10064';
        rs_err_msg   := 'Day String does not exist in the common calendar.';
        RAISE EXCEPTION ' ';
    END IF;

    /* Due Date Less Then Start Date */
    IF ps_due_date < ps_start_date THEN
        IF ( ps_operation_id = cs_LD11 OR ps_operation_id = cs_LD41 ) THEN
            rs_err_code  := 'ld.E.LDP10070';
            rs_err_msg   := 'For Due Date, specify the date later than'
                         || ' Start Date.';
            RAISE EXCEPTION ' ';
        ELSE
            IF ps_operation_id = cs_LD71 THEN
                rs_err_code  := 'ld.E.LDP10071';
                rs_err_msg   := 'For Start Date, specify the date former than'
                             || ' Due Date.';
                RAISE EXCEPTION ' ';
            END IF;
        END IF;
    END IF;

    /* Day Type Does Not Exist AND Demand Policy Code Equal 2 */
    IF EXISTS ( SELECT 1
                  FROM le_mst_calendar_sum
                 WHERE calendar_code = ls_calendar_code
                   AND calendar_ymd  = ps_disburse_date) THEN
        SELECT day_type
          INTO STRICT ls_day_type
          FROM le_mst_calendar_sum
         WHERE  calendar_code = ls_calendar_code
           AND calendar_ymd   = ps_disburse_date;
        IF ls_day_type <> cs_OPTION_0 AND ps_demand_pol_cd <> cs_DEMAND_2  THEN
            rs_err_code  := 'ld.E.LDP10072';
            rs_err_msg   := 'The day you specified is not a working-day.' ;
            RAISE EXCEPTION ' ';
        END IF;
        /* Suitable Data Not Found */
    ELSE
        rs_err_code  := 'ld.E.LDP10064';
        rs_err_msg   := 'Day String does not exist in the common calendar.';
        RAISE EXCEPTION ' ';
    END IF;

    /* Disburse Date Less Then Due Date */
    IF ps_disburse_date < ps_due_date THEN
        rs_err_code  := 'ld.E.LDP10073';
        rs_err_msg   := 'For Disburse Date, specify the date later than'
                     || ' Due Date.';
        RAISE EXCEPTION ' ';
    END IF;

    ln_mon_diff := ( TO_NUMBER(SUBSTR(ps_disburse_date,1,4), '9999')
                   - TO_NUMBER(SUBSTR(ps_start_date,1,4), '9999'))*12
                   + TO_NUMBER(SUBSTR(ps_disburse_date,5,2), '99')
                   - TO_NUMBER(SUBSTR(ps_start_date,5,2), '99');
    IF ln_mon_diff > 6
        OR (ln_mon_diff = 6 AND (TO_NUMBER(SUBSTR(ps_disburse_date,7,2), '99')
                        - TO_NUMBER(SUBSTR(ps_start_date,7,2), '99')) > 0)THEN
        rs_err_code  := 'ld.E.LDP10074';
        rs_err_msg   := 'Make the difference between Start Date'
                     || ' and Disburse Date within 6 months.';
        RAISE EXCEPTION ' ';
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
        ELSE                    -- FOR PGM ERROR
            rn_status   :=  -2;
            rs_sql_code := cs_empty_string;
            rs_err_focus:= cs_pgmid;
        END IF;

        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN           -- FOR SQL ERROR
        rn_status    := -1;
        rs_sql_code  := SQLSTATE;
        rs_err_code  := cs_empty_string;
        rs_err_msg   := SQLERRM;
        rs_err_focus := cs_pgmid;

        RETURN NEXT;
        RETURN;
END;
$BODY$
LANGUAGE 'plpgsql';
