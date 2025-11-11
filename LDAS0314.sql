--------------------------------------------------------------------------------
--@SEE << Valid / Order Delete >>
--    @ID      : LDAS0314
--
--    @Written : 1.0.0                2025.10.16 Sun Sheng / YMSLX
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
--    @ps_receive_id              <I/ > VARCHAR     : Recieve ID
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
CREATE OR REPLACE FUNCTION LDAS0314(
      ps_user_id                         IN VARCHAR                    --1 ユーザーID
    , ps_log_sign                        IN VARCHAR                    --2 ログ出力サイン
    , ps_receive_id                      IN VARCHAR                    --3 受信ID
    , ps_request_system_code             IN VARCHAR                    --4 相手先システム識別
    , ps_itemno                          IN VARCHAR                    --5 品目番号
    , ps_supplier                        IN VARCHAR                    --6 供給者
    , ps_usercd                          IN VARCHAR                    --7 使用者
    , ps_order_no                        IN VARCHAR                    --8 オーダー番号
)
RETURNS TABLE(
    rn_status    INTEGER,
    rs_sql_code  VARCHAR,
    rs_err_code  VARCHAR,
    rs_err_msg   VARCHAR,
    rs_err_focus VARCHAR
) AS
$BODY$
DECLARE
    -- SP return record  --
    rec_itemmast_date RECORD;
    rec_err_log_login RECORD;
    ls_order_status   le_trn_order.order_status%TYPE;
    pn_order_qty      DECIMAL;
    ps_reason_code    VARCHAR;
    ps_start_date     VARCHAR;
    ps_due_date       VARCHAR;
    ps_disburse_date  VARCHAR;
    ps_due_begin_time VARCHAR;
    ps_due_end_time   VARCHAR;
    pn_carry_over_qty DECIMAL;
    ps_pilot_class    VARCHAR;
    cs_pgmid          CONSTANT VARCHAR := 'LDAS0314';
    cs_space          CONSTANT VARCHAR := ' ';
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
    ls_order_status         := cs_space;

    /* Argument Check */
    IF ps_order_no IS NULL OR TRIM(ps_order_no) = '' THEN
        rs_err_code  := 'ld.E.LDP10050';
        rs_err_msg   := 'Enter Order Number.';
        RAISE EXCEPTION ' ';
    END IF;
    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    /* Get Itemmast Date */
    SELECT LDAS0300.rn_status
         , LDAS0300.rs_sql_code
         , LDAS0300.rs_err_code
         , LDAS0300.rs_err_msg
    INTO STRICT rec_itemmast_date
    FROM LDAS0300 ( 'LD11'
                   ,ps_itemno
                   ,ps_supplier
                   ,ps_usercd
                   );

    -- return item set --
        rs_sql_code  := rec_itemmast_date.rs_sql_code;
        rs_err_code  := rec_itemmast_date.rs_err_code;
        rs_err_msg   := rec_itemmast_date.rs_err_msg;
    -- status judgement --
    IF rec_itemmast_date.rn_status = -1 THEN
        rn_status    := rec_itemmast_date.rn_status;

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
            rs_err_code  := 'ld.E.LDP10018';
            rs_err_msg   := 'The order you specified does not exist.';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    /* Order Status Check */
    IF ls_order_status = '9' THEN
        rs_err_code  := 'ld.E.LDP10038';
        rs_err_msg   := 'You cannot specify the closed order.';
        RAISE EXCEPTION ' ';
    END IF;


    --------------------------------------------------
    --  < STEP3 : Return Value Processing >
    --------------------------------------------------
    RETURN NEXT;
    RETURN;
EXCEPTION
    WHEN RAISE_EXCEPTION THEN
    IF rn_status <> 0 THEN
          NULL;
    ELSE
        rn_status   :=  -2;
        rs_sql_code := cs_space;
        rs_err_focus:= cs_pgmid;

        IF ps_log_sign = '1' THEN
            SELECT LDAS0409.rn_status
                  ,LDAS0409.rs_sql_code
                  ,LDAS0409.rs_err_code
                  ,LDAS0409.rs_err_msg
            INTO STRICT rec_err_log_login
            FROM LDAS0409 ( '99'                                 --1
                           ,ps_user_id                           --2
                           ,rs_err_code                          --3
                           ,'LD11'                               --4
                           ,'3'                                  --5
                           ,'9'                                  --6
                           ,ps_receive_id                        --7
                           ,ps_request_system_code               --8
                           ,''                                   --9
                           ,'LDAS0314'                           --10
                           ,ps_itemno                            --11
                           ,ps_supplier                          --12
                           ,ps_usercd                            --13
                           ,ps_order_no                          --14
                           ,cs_space                             --15
                           ,cs_space                             --16
                           ,pn_order_qty                         --17
                           ,ps_reason_code                       --18
                           ,cs_space                             --19
                           ,cs_space                             --20
                           ,cs_space                             --21
                           ,cs_space                             --22
                           ,cs_space                             --23
                           ,cs_space                             --24
                           ,ps_start_date                        --25
                           ,ps_due_date                          --26
                           ,ps_disburse_date                     --27
                           ,ps_due_begin_time                    --28
                           ,ps_due_end_time                      --29
                           ,pn_carry_over_qty                    --30
                           ,ps_pilot_class                       --31
                           ,cs_space                             --32
                           ,cs_space                             --33
                           ,cs_space                             --34
                           ,cs_space                             --35
                           ,cs_space                             --36
                           ,cs_space                             --37
                           ,cs_space                             --38
                           ,cs_space                             --39
                           ,cs_space                             --40
                           ,cs_space                             --41
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
    END IF;

    RETURN NEXT;
    RETURN;

    WHEN OTHERS THEN       -- FOR SQL ERROR
        rn_status    := -1;
        rs_sql_code  := SQLSTATE;
        rs_err_code  := ' ';
        rs_err_msg   := SQLERRM;
        rs_err_focus := ' ';

        RETURN NEXT;
        RETURN;
END;
$BODY$
LANGUAGE 'plpgsql';
