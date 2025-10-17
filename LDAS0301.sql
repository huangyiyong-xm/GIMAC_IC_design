--------------------------------------------------------------------------------
--@SEE << Valid / Order Login Date Check >>
--    @ID      : LDAS0301
--
--    @Written : 1.0.0                2012.07.26 Lian Zhibin / YMSLX
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
--@SEE << Order Login Date Check >>
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
CREATE OR REPLACE FUNCTION gimac.ldas0301(
    ps_operation_id      IN VARCHAR             -----------1
    ,ps_start_date       IN VARCHAR             -----------2 
    ,ps_due_date         IN VARCHAR             -----------3
    ,ps_disburse_date    IN VARCHAR             -----------4   
    ,ps_itemno           IN VARCHAR             -----------5
    ,ps_supplier         IN VARCHAR             -----------6
    ,ps_usercd           IN VARCHAR             -----------7
    ,ps_demand_pol_cd    IN VARCHAR             -----------8
)
RETURNS TABLE(
   rn_status         integer                    -----------1
    ,rs_sql_code     VARCHAR                    -----------2
    ,rs_err_code     VARCHAR                    -----------3
    ,rs_err_msg      VARCHAR                    -----------4
    ,rs_err_focus    VARCHAR                    -----------5 
) LANGUAGE plpgsql
AS $function$
DECLARE
    -- SP return record  --
    rec_fix_period_date RECORD;
    ls_calendar_code    gimac.la_area_master_su.calendar_code%TYPE;
    ls_day_type         gimac.le_mst_calendar_sum.day_type%TYPE;
    ls_ic_slip_date     gimac.ld_mst_slip_date.ic_slip_date%TYPE;
    ls_option_code      gimac.lz_function_parameter.option_code%TYPE;
    ls_item_type        gimac.la_itemmast.item_type%TYPE;
    ls_fix_to_ymd       VARCHAR;
    ls_mon_diff         INTEGER;
    cs_org_type         CONSTANT  VARCHAR(03) := '000';
    cs_system_code      CONSTANT  VARCHAR(02) := 'LC';
    cs_id_code          CONSTANT  VARCHAR(07) := 'LCB0001';
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
    ls_calendar_code         := ' ';
    ls_day_type              := ' ';
    ls_ic_slip_date          := ' ';
    ls_option_code           := ' ';
    ls_item_type             := ' ';
    ls_fix_to_ymd            := ' ';
    ls_mon_diff              :=   0;

    /* Argument Check */
    IF ps_start_date IS NULL OR TRIM(ps_start_date) = '' THEN
        rs_err_code  := 'E.LDP10354';
        rs_err_msg   := 'Specify Start Date.';
        rs_err_focus := 'startDate';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_due_date IS NULL OR TRIM(ps_due_date) = '' THEN
        rs_err_code  := 'E.LDP10355';
        rs_err_msg   := 'Specify Due Date.';
        rs_err_focus := 'dueDate';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_disburse_date IS NULL OR TRIM(ps_disburse_date) = '' THEN
        rs_err_code  := 'E.LDP10356';
        rs_err_msg   := 'Specify Disburse Date.';
        rs_err_focus := 'disburseDate';
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
        rs_err_code  := 'E.LDP10910';
        rs_err_msg   := 'Effective calendar does not exist by'
                     || ' the specified Supplier/User.';
        rs_err_focus := 'usercd';
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
        IF ls_day_type <> '0' THEN
            rs_err_code  := 'E.LDP10377';   
            rs_err_msg   := 'The day you specified is not a working-day.' ||
            COALESCE( ps_start_date , 'NULL' );
            rs_err_focus := 'startDate';
            RAISE EXCEPTION ' ';
        END IF;
    /* Day Type Data Not Found */
    IF NOT EXISTS ( SELECT 1
                  FROM le_mst_calendar_sum
                 WHERE calendar_code = ls_calendar_code
                   AND calendar_ymd  = ps_start_date ) THEN
        rs_err_code  := 'E.LDP10106';
        rs_err_msg   := 'Day String does not exist in the common calendar.';
        rs_err_focus := 'startDate';
        RAISE EXCEPTION ' ';
    END IF;

    /* Get Fix Period */
      IF EXISTS ( SELECT 1
                  FROM le_mst_mrp_information
                    WHERE   itemno   = ps_itemno
                    AND     supplier = ps_supplier
                    AND     usercd   = ps_usercd    ) THEN
        SELECT      fix_period_id
        INTO    ls_fix_to_ymd
        FROM    le_mst_mrp_information
        WHERE   itemno = ps_itemno
        AND     supplier = ps_supplier
        AND     usercd = ps_usercd;
    SELECT *
        INTO STRICT rec_fix_period_date
        FROM LEBS0010(ls_fix_to_ymd,'T');
        IF rec_fix_period_date.rn_status <> 0 THEN
            rn_status   := rec_fix_period_date.rn_status;
            rs_sql_code := rec_fix_period_date.rs_sql_code;
            rs_err_code := rec_fix_period_date.rs_err_code;
            rs_err_msg  := rec_fix_period_date.rs_err_msg;

            RETURN NEXT;
            RETURN;
            ELSE
            ls_fix_to_ymd     := rec_fix_period_date.rs_l_fix_to_ymd;
            END IF;
     ELSE
        rs_err_code  := 'E.LDP10916';
        rs_err_msg   := 'Item does not exist in the itemmast mrp.';
        rs_err_focus := 'startDate';
        RAISE EXCEPTION ' ';
        END IF;
    END IF;

    /* Get Ic Slip Date */
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

    /* Start Date Check */
    IF ( ps_operation_id = 'LD11' OR ps_operation_id = 'LD41' ) THEN
        IF ( ps_demand_pol_cd <> '1' AND
             ps_demand_pol_cd <> '2' ) THEN
            IF ( ps_start_date     > ls_fix_to_ymd ) THEN
                rs_err_code  := 'E.LDP10367';
                rs_err_msg   := 'For Start Date, specify the date former than'
                             || ' the final day of the fixed order period.';
                rs_err_focus := 'startDate';
                RAISE EXCEPTION ' ';
            END IF;
        END IF;
    ELSE
        IF ps_operation_id = 'LD71' THEN
            IF ps_start_date > ls_fix_to_ymd THEN
                rs_err_code  := 'E.LDP10367';
                rs_err_msg   := 'For Start Date, specify the date former than'
                             || ' the final day of the fixed order period.';
                rs_err_focus := 'startDate';
                RAISE EXCEPTION ' ';
            ELSIF ps_start_date < ls_ic_slip_date THEN
                rs_err_code  := 'E.LDP10357';
                rs_err_msg   := 'You cannot specify the past date for'
                             || ' Start Date.';
                rs_err_focus := 'startDate';
                RAISE EXCEPTION ' ';
            ELSE
                NULL;
            END IF;
        END IF;
    END IF;

    /* Get Option Code */
    IF EXISTS ( SELECT 1
                  FROM lz_function_parameter
                WHERE system_code = 'LC'
                  AND function_id = 'LCB0001'
                  AND select_flg = 'T' )THEN
        SELECT option_code
          INTO STRICT ls_option_code
          FROM lz_function_parameter
          WHERE system_code = 'LC'
            AND function_id = 'LCB0001'
            AND select_flg = 'T';
    /* Option Code Not Found */
    ELSE
        rs_err_code  := 'E.LDP10912';
        rs_err_msg   := 'Target data does not exist'
                     || ' in the Function Parameter table.';
        rs_err_focus := ' ';
        RAISE EXCEPTION ' ';
    END IF;

    /* Get Item Type */
    IF EXISTS ( SELECT 1
                  FROM la_itemmast
                 WHERE itemno = ps_itemno
                    AND supplier = ps_supplier
                    AND usercd = ps_usercd )THEN
        SELECT item_type
          INTO STRICT ls_item_type
          FROM la_itemmast
         WHERE itemno = ps_itemno
                AND supplier = ps_supplier
                AND usercd = ps_usercd;
    /* Item Type Not Found */
    ELSE
        rs_err_code  := 'E.LDP10726';
        rs_err_msg   := 'Data does not exist in the item master.';
        rs_err_focus := 'itemno';
        RAISE EXCEPTION ' ';
    END IF;

    /* Due Date Check */
    IF (ls_option_code = '0'  AND ps_due_date < ls_ic_slip_date
                              AND ls_item_type <> '2' ) OR
       (ls_option_code <> '0' AND ps_due_date < ls_ic_slip_date )THEN
        rs_err_code  := 'E.LDP10398';
        rs_err_msg   := 'You cannot specify the past date for due date.';
        rs_err_focus := 'dueDate';
        RAISE EXCEPTION ' ';
    END IF;

    /* Day Type Does Not Exist Error */
    IF EXISTS ( SELECT 1
                  FROM le_mst_calendar_sum
                 WHERE calendar_code = ls_calendar_code
                    AND calendar_ymd = ps_due_date ) THEN
        SELECT day_type
          INTO STRICT ls_day_type
          FROM le_mst_calendar_sum
         WHERE calendar_code = ls_calendar_code
            AND calendar_ymd = ps_due_date;
        IF ls_day_type <> '0' THEN
            rs_err_code  := 'E.LDP10936';
            rs_err_msg   := 'The day you specified is not a working-day.' ||
            '[ ps_due_date  ] = ' ||
            COALESCE( ps_due_date , 'NULL' );
            rs_err_focus := 'dueDate';
            RAISE EXCEPTION ' ';
        END IF;
    /* Day Type Does Not Exist  */
        ELSE
        rs_err_code  := 'E.LDP10106';
        rs_err_msg   := 'Day String does not exist in the common calendar.';
        rs_err_focus := 'dueDate';
        RAISE EXCEPTION ' ';
    END IF;

    /* Due Date Less Then Start Date */
    IF ps_due_date < ps_start_date THEN
        IF ( ps_operation_id = 'LD11' OR ps_operation_id = 'LD41' ) THEN
            rs_err_code  := 'E.LDP10360';
            rs_err_msg   := 'For Due Date, specify the date later than'
                         || ' Start Date.';
            rs_err_focus := 'dueDate';
            RAISE EXCEPTION ' ';
        ELSE
            IF ps_operation_id = 'LD71' THEN
                rs_err_code  := 'E.LDP10358';
                rs_err_msg   := 'For Start Date, specify the date former than'
                             || ' Due Date.';
                rs_err_focus := 'startDate';
                RAISE EXCEPTION ' ';
            END IF;
        END IF;
    END IF;

    /* Day Type Does Not Exist AND Demand Policy Code Equal 2 */
    IF EXISTS ( SELECT 1
                  FROM le_mst_calendar_sum
                 WHERE calendar_code = ls_calendar_code
                    AND calendar_ymd = ps_disburse_date) THEN
        SELECT day_type
          INTO STRICT ls_day_type
          FROM le_mst_calendar_sum
         WHERE  calendar_code = ls_calendar_code
            AND calendar_ymd = ps_disburse_date;
        IF ls_day_type <> '0' AND ps_demand_pol_cd <> '2' THEN
            rs_err_code  := 'E.LDP10750';
            rs_err_msg   := 'The day you specified is not a working-day.' ||
            '[ ps_disburse_date  ] = ' ||
            COALESCE( ps_disburse_date , 'NULL' );
            rs_err_focus := 'disburseDate';
           RAISE EXCEPTION ' ';
        END IF;
        /* Suitable Data Not Found */
        ELSE
        rs_err_code  := 'E.LDP10106';
        rs_err_msg   := 'Day String does not exist in the common calendar.';
        rs_err_focus := 'disburseDate';
        RAISE EXCEPTION ' ';
    END IF;

    /* Disburse Date Less Then Due Date */
    IF ps_disburse_date < ps_due_date THEN
        rs_err_code  := 'E.LDP10361';
        rs_err_msg   := 'For Disburse Date, specify the date later than'
                     || ' Due Date.';
        rs_err_focus := 'disburseDate';
        RAISE EXCEPTION ' ';
    END IF;

    ls_mon_diff := ( TO_NUMBER(SUBSTR(ps_disburse_date,1,4), '9999')
                   - TO_NUMBER(SUBSTR(ps_start_date,1,4), '9999'))*12
                   + TO_NUMBER(SUBSTR(ps_disburse_date,5,2), '99')
                   - TO_NUMBER(SUBSTR(ps_start_date,5,2), '99');
    IF ls_mon_diff > 6
        OR (ls_mon_diff = 6 AND (TO_NUMBER(SUBSTR(ps_disburse_date,7,2), '99')
                        - TO_NUMBER(SUBSTR(ps_start_date,7,2), '99')) > 0)THEN
        rs_err_code  := 'E.LDP10397';
        rs_err_msg   := 'Make the difference between Start Date'
                     || ' and Disburse Date within 6 months.';
        rs_err_focus := 'startDate';
        RAISE EXCEPTION ' ';
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
$function$;
