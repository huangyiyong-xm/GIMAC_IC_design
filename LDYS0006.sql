--------------------------------------------------------------------------------
--@SEE << Order number (5 digits → 3 digits) >>
--    @ID      : LDYS0006
--
--    @Written : 1.0.0                   2012.06.12 T.Ishizuka / YMSL
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
--    @ps_orderno                     <I/ >VARCHAR  : Order No (5 digits)
--    @ps_mrpdatetime                 <I/ >VARCHAR : MRP DateTime (YYYYMMDD)
--  < OUTPUT Parameter >
--    @rn_status            : Return Code (0:Normal, -1:SQL Error, -2:PG Error, 1:Warning)
--    @rs_sql_code          : SQL Code
--    @rs_err_code          : Error Code
--    @rs_err_msg           : Error Message
--    @rs_err_focus         : Error Focus
--    @rs_orderno           : Order No (3 digits)
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION gimac.ldys0006(ps_orderno character varying, ps_mrpdatetime character varying)
 RETURNS TABLE(rn_status integer, rs_sql_code character varying, rs_err_code character varying, rs_err_msg character varying, rs_err_focus character varying, rs_orderno character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    ls_orderno3                   VARCHAR := ' ';
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    /* Return Value Set */
    rn_status    :=   0;
    rs_sql_code  := ' ';
    rs_err_code  := ' ';
    rs_err_msg   := ' ';
    rs_err_focus := ' ';
    rs_orderno   := ' ';

    /* Variable Initialization */

    /* Argument Check */
    IF ps_orderno IS NULL OR LENGTH(TRIM(ps_orderno)) < 5 THEN
        rn_status    := -2;
        rs_err_code  := 'E.LDYS0006.ARG';
        rs_err_msg   := '5けた桁はただしく正しくありません';
        rs_err_focus := 'LDYS0006';
        RETURN NEXT;
        RETURN;
    END IF;
    
    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    /* Order number (5 digits → 3 digits) */
    IF ps_orderno ~ '^[0-9]{5}$' THEN
        -- The situation where all the numbers from 1 to 5 are within the range of 0 to 9
        ls_orderno3 := SUBSTRING(ps_orderno FROM 3 FOR 3);
    ELSE
        -- Not the case of 0 to 9
        ls_orderno3 := SUBSTRING(ps_orderno FROM 1 FOR 1) || SUBSTRING(ps_orderno FROM 4 FOR 2);
    END IF;
    /* Return Value Set */
    rn_status    := 0;
    rs_sql_code  := ' ';
    rs_err_code  := ' ';
    rs_err_msg   := ' ';
    rs_err_focus := ' ';
    rs_orderno   := ls_orderno3;
    --------------------------------------------------
    --  < STEP3 : Return Value Processing >
    --------------------------------------------------
    RETURN NEXT;
    RETURN;
EXCEPTION
    WHEN RAISE_EXCEPTION THEN
        rn_status         :=  -2;
        rs_sql_code       := ' ';

        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN
        rn_status         	:= -1;
        rs_sql_code       	:= SQLSTATE;
        rs_err_code       	:= ' ';
        rs_err_msg        	:= SQLERRM;
        rs_err_focus 		:= 'LDYS0006';
        rs_orderno   		:= ' ';

        RETURN NEXT;
        RETURN;
END;
$function$
;
