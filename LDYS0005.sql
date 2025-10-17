--------------------------------------------------------------------------------
--@SEE << Operation Day Check >>
--    @ID      : LDYS0005
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
--    @ps_calder_cd                 <I/ >VARCHAR  : Calendar Code (VARCHAR)
--    @ps_std_ymd                   <I/ >VARCHAR : Target Date (YYYYMMDD, VARCHAR)
--  < OUTPUT Parameter >
--    @rn_status            : Return Code (0:Normal, -1:SQL Error, -2:PG Error, 1:Warning)
--    @rs_sql_code          : SQL Code
--    @rs_err_code          : Error Code
--    @rs_err_msg           : Error Message
--    @rs_err_focus         : Error Focus
--    @rn_is_operationday   : 0:Operation Day, 1:Non-Operation Day, 2:Invalid Date
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION gimac.ldys0005(
    ps_calder_cd    IN VARCHAR, ---------------1
    ps_std_ymd      IN VARCHAR  ---------------2
)
RETURNS TABLE(
    rn_status            INTEGER,
    rs_sql_code          VARCHAR,
    rs_err_code          VARCHAR,
    rs_err_msg           VARCHAR,
    rs_err_focus         VARCHAR,
    rn_is_operationday   INTEGER
)
LANGUAGE plpgsql
AS $function$
DECLARE
    ln_length            INTEGER := LENGTH(TRIM(ps_std_ymd));	--------------1
    ln_counter           INTEGER := 1;      					--------------2
    ls_char              VARCHAR := ' ';    					--------------3
    ln_is_operationday   INTEGER := 2;     						--------------4
    ls_calendar_content  VARCHAR := ' ';    					--------------5
    ls_check_char2       VARCHAR := ' ';    					--------------6
    ls_month             VARCHAR := ' ';
    ls_day               VARCHAR := ' ';
    ln_day_idx           INTEGER := 0;    
    
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    rn_status               := 0;
    rs_sql_code             := ' ';
    rs_err_code             := ' ';
    rs_err_msg              := ' ';
    rs_err_focus            := ' ';
    rn_is_operationday      := 2;

    -- Argument validation: check if ps_std_ymd is 8 digits and all numeric
    
    WHILE ln_counter <= ln_length LOOP
        ls_char := SUBSTRING(TRIM(ps_std_ymd) FROM ln_counter FOR 1);
        IF ls_char < '0' OR ls_char > '9' THEN
            rn_is_operationday := 2;
            RETURN NEXT;
            RETURN;
        END IF;
        ln_counter := ln_counter + 1;
    END LOOP;

    -- Check month and day range

    ln_length := LENGTH(TRIM(ps_std_ymd));
    IF ln_length <> 8 then
   		rn_status    := 1;
        rs_err_code  := '10024';
        rs_err_msg   := 'Target date was not found in the calendar.';
        rs_err_focus := 'LDYS0005';
        rn_is_operationday := 2;
        RETURN NEXT;
        RETURN;
    END IF;

    ls_month := SUBSTRING(ps_std_ymd FROM 5 FOR 2);
    ls_day   := SUBSTRING(ps_std_ymd FROM 7 FOR 2);
    IF ls_month < '01' OR ls_month > '12' then
    	rn_status    := 1;
        rs_err_code  := '10024';
        rs_err_msg   := 'Target date was not found in the calendar.';
        rs_err_focus := 'LDYS0005';
        rn_is_operationday := 2;
        RETURN NEXT;
        RETURN;
    END IF;
    IF ls_day < '01' OR ls_day > '31' THEN
        rn_is_operationday := 2;
        RETURN NEXT;
        RETURN;
    END IF;
    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------

    -- Daily work inspection
        SELECT calendar_data
          INTO ls_calendar_content
          FROM le_mst_calendar
         WHERE calendar_code = ps_calder_cd
           AND calendar_ym = SUBSTRING(ps_std_ymd FROM 1 FOR 6);
   
  
          
    --If the data exists
    ln_length := LENGTH(TRIM(ps_std_ymd));
    ln_day_idx := CAST(SUBSTRING(ps_std_ymd FROM 7 FOR 2) AS INTEGER);
    ln_counter := 1;
    WHILE ln_counter <= ln_length LOOP
    ls_char := SUBSTRING(ls_calendar_content FROM ln_counter FOR 1);
    IF ln_counter = ln_day_idx THEN
        ls_check_char2 := ls_char;
        EXIT;
    END IF;
    ln_counter := ln_counter + 1;
    END LOOP;

    -- Get operation day flag from calendar content
    ls_check_char2 := SUBSTRING(ls_calendar_content FROM CAST(SUBSTRING(ps_std_ymd FROM 7 FOR 2) AS INTEGER) FOR 1);
    
    IF ls_check_char2 = '0' THEN
        ln_is_operationday := 0;
    ELSIF ls_check_char2 = '1' THEN
        ln_is_operationday := 1;
    ELSE
        ln_is_operationday := 2;
    END IF;

    -- Set return values
    rn_status      		:= 0;
    rs_sql_code    		:= ' ';
    rs_err_code   		:= ' ';
    rs_err_msg     		:= ' ';
    rs_err_focus   		:= ' ';
    rn_is_operationday  := ln_is_operationday;

    RETURN NEXT;
    RETURN;

EXCEPTION
    --------------------------------------------------
    --  Error Handle
    --------------------------------------------------
    --  # Indispensability(End)
    --------------------------------------------------

 
	WHEN OTHERS THEN
        rn_status           := -1;
        rs_sql_code         := SQLSTATE;
        rs_err_code         := ' ';
        rs_err_msg          := SQLERRM;
        rs_err_focus        := 'LDYS0005';
        rn_is_operationday  := 2;
        RETURN NEXT;
        RETURN;
END;
$function$;
