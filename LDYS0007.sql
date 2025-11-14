--------------------------------------------------------------------------------
--@SEE << The processing date at the factory is now obtained. >>
--    @ID      : LDYS0007
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
--    @ps_process_id                     <I/ >VARCHAR  : Process ID   
--  < OUTPUT Parameter >
--    @rn_status            : Return Code (0:Normal, -1:SQL Error, -2:PG Error, 1:Warning)
--    @rs_sql_code          : SQL Code
--    @rs_err_code          : Error Code
--    @rs_err_msg           : Error Message
--    @rs_err_focus         : Error Focus
--    @rs_date_yyyymmdd     : Date (YYYYMMDD)
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION gimac.ldys0007(ps_process_id character varying)
 RETURNS TABLE(rn_status integer, rs_sql_code character varying, rs_err_code character varying, rs_err_msg character varying, rs_err_focus character varying, rs_date_yyyymmdd character varying)
 LANGUAGE plpgsql
AS $function$ 
DECLARE
      ls_date            gimac.ld_mst_slip_date.ic_slip_date%type;
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    /* Return Value Set */
    rn_status         :=   0;
    rs_sql_code       := ' ';
    rs_err_code       := ' ';
    rs_err_msg        := ' ';
    rs_err_focus      := ' ';
    rs_Date_YYYYMMDD  := ' ';
    /* Variable Initialization */


    ls_date  := ' ';

    /* Argument Check */
    

    

    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    SELECT ld_mst_slip_date 
    	INTO ls_date
      	FROM ld_mst_slip_date
      WHERE operation_type = ps_process_id;
	
     -- If not exist
    IF NOT FOUND OR ls_date IS NULL OR TRIM(ls_date) = '' THEN
        rn_status    := -2;
        rs_sql_code  := ' ';
        rs_err_code  := 'E.LDP10911';
        rs_err_msg   := 'The IC pymac date is not exist.';
        rs_err_focus := 'LDYS0007';
        rs_Date_YYYYMMDD := ' ';
        RETURN NEXT;
        RETURN;
    END IF;
     
    rn_status        :=   0;
    rs_sql_code      := ' ';
    rs_err_code      := ' ';
    rs_err_msg       := ' ';
    rs_err_focus     := ' ';
    rs_Date_YYYYMMDD := ls_date;

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
            rs_sql_code   := ' ';
        END IF;

        rs_Date_YYYYMMDD  := ' ';

        RETURN NEXT;
        RETURN;

     WHEN OTHERS THEN
        rn_status        := -1;
        rs_sql_code      := SQLSTATE;
        rs_err_code      := ' ';
        rs_err_msg       := SQLERRM;
        rs_err_focus     := 'LDYS0007';
        rs_Date_YYYYMMDD := ' ';
        RETURN NEXT;
        RETURN;
END;
$function$
;
