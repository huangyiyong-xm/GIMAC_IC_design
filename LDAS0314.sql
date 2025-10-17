--------------------------------------------------------------------------------
--@SEE << Valid / Order Deletion >>
--    @ID      : LCBS3113
--
--    @Written : 1.0.0                2012.07.31 Lian Zhibin / YMSLX
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
--@SEE << Validation for Order Delete >>
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
--  < OUTPUT Parameter >                                                   
--    @rn_status                  < /O> INTEGER     : Return Code
--                                                 (  0 : Normal End    )
--                                                 ( -1 : Abnormal End  )
--                                                 ( -2 : PGM Error     )          
--    @rs_sql_code                < /O> VARCHAR     : Sql Code             
--    @rs_err_code                < /O> VARCHAR     : Error Code           
--    @rs_err_msg                 < /O> VARCHAR     : Error Message              
--    @rs_err_focus               < /O> VARCHAR     : Error Focus       
----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION gimac.ldas0314(
      ps_user_id                         IN VARCHAR                    --1
    , ps_log_sign                        IN VARCHAR                    --2
    , ps_recieve_id                      IN VARCHAR                    --3
    , ps_request_system_code             IN VARCHAR                    --4
    , ps_itemno                          IN VARCHAR                    --5
    , ps_supplier                        IN VARCHAR                    --6
    , ps_usercd                          IN VARCHAR                    --7
    , ps_order_no                        IN VARCHAR                    --8
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
    rec_itemmast_date RECORD;
    rec_err_log_login RECORD;
    ls_order_status   varchar(1);
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
    ls_order_status         := ' ';

    /* Argument Check */
    IF ps_order_no IS NULL OR TRIM(ps_order_no) = '' THEN
        rs_err_code  := 'E.LDP10447';
        rs_err_msg   := 'Enter Order Number.';
        rs_err_focus := 'orderNo';
        RAISE EXCEPTION ' ';
    END IF;
    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    /* Get Itemmast Date */
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
    -- status judgement --
    IF rec_itemmast_date.rn_status = -1 THEN
    
        RETURN NEXT;
        RETURN;
    ELSIF rec_itemmast_date.rn_status = -2 THEN
        
        RAISE EXCEPTION ' ';
    ELSE
        NULL;
    END IF;
    
    /* Order Check */
    IF EXISTS ( SELECT 1
                  FROM le_trn_order
                 WHERE itemno       = ps_itemno
                   AND supplier     = ps_supplier
                   AND usercd       = ps_usercd
                   AND order_no     = ps_order_no ) THEN
        SELECT order_status
          INTO STRICT ls_order_status
          FROM le_trn_order
         WHERE itemno       = ps_itemno
           AND supplier     = ps_supplier
           AND usercd       = ps_usercd
           AND order_no     = ps_order_no;
    /* Order Data Not Found */
    ELSE
        /* Order Forecast Check */
        IF EXISTS ( SELECT 1
                      FROM le_trn_order_forecast
                     WHERE itemno       = ps_itemno
                       AND supplier     = ps_supplier
                       AND usercd       = ps_usercd
                       AND order_no     = ps_order_no ) THEN
            SELECT order_status
              INTO STRICT ls_order_status
              FROM le_trn_order_forecast
             WHERE itemno       = ps_itemno
               AND supplier     = ps_supplier
               AND usercd       = ps_usercd
               AND order_no     = ps_order_no;
        /* Order Forecast Data Not Found */
        ELSE
            rs_err_code  := 'E.LDP10527';
            rs_err_msg   := 'The order you specified does not exist.';
            rs_err_focus := 'orderNo';
            RAISE EXCEPTION ' ';
        END IF;           
    END IF;

    /* Order Status Check */
    IF ls_order_status = '9' THEN
        rs_err_code  := 'E.LDP10528';
        rs_err_msg   := 'You cannot specify the closed order.';
        rs_err_focus := 'orderNo';
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
$function$
;
