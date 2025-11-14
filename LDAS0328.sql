--------------------------------------------------------------------------------
--    @SEE << VALID W BIN ORDER REGISTRATION >>
--    @ID      : LDAS0328
--
--    @Written : 1.0.0                   2025.10.24 Sun Sheng / YMSLX
--    --------------------------------------------------------------------------
--    @Update  : xxxxxxxxxxxx            xxxx.xx.xx xxxxxxxx / xx
--     Reason  : xxx
--              xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--    --------------------------------------------------------------------------
--    @Version : 1.0.0
--
--------------------------------------------------------------------------------
--  < INPUT Parameter >
--    @ps_user_id          <I/ > VARCHAR    : User Id
--    @ps_log_sign         <I/ > VARCHAR    : Log Sign
--    @ps_receive_id       <I/ > VARCHAR    : Receive Id
--    @ps_system_id        <I/ > VARCHAR    : System Id
--    @ps_itemno           <I/ > VARCHAR    : Itemno
--    @ps_supplier         <I/ > VARCHAR    : Supplier
--    @ps_usercd           <I/ > VARCHAR    : Usercd
--    @ps_order_no         <I/ > VARCHAR    : Order_no
--    @pn_order_qty        <I/ > DECIMAL    : Order_qty
--    @ps_start_date       <I/ > VARCHAR    : Start_date
--    @ps_end_date         <I/ > VARCHAR    : End_date
--    @ps_disburse_date    <I/ > VARCHAR    : Disburse_date
--  < OUTPUT Parameter >
--    @rn_status           < /O> INTEGER    : Return Code
--                                            (  0 : Normal End     )
--                                            (100 : Notfound       )
--                                            ( -1 : Abnormal End   )
--                                            ( -2 : PGM Error      )
--    @rs_sql_code         < /O> VARCHAR    : Sql Error Code
--    @rs_err_code         < /O> VARCHAR    : Program Error Code
--    @rs_err_msg          < /O> VARCHAR    : Error Message
--    @rs_err_focus        < /O> VARCHAR    : Error Focus
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDAS0328(
     ps_user_id            VARCHAR    -- 1  ユーザーＩＤ
    ,ps_log_sign           VARCHAR    -- 2  ログ出力サイン
    ,ps_receive_id         VARCHAR    -- 3  受信ID
    ,ps_system_id          VARCHAR    -- 4  相手先システム識別
    ,ps_itemno             VARCHAR    -- 5  品目番号
    ,ps_supplier           VARCHAR    -- 6  供給者
    ,ps_usercd             VARCHAR    -- 7  使用者
    ,ps_order_no           VARCHAR    -- 8  オーダー番号
    ,pn_order_qty          DECIMAL    -- 9  オーダー数
    ,ps_start_date         VARCHAR    -- 10 着手日
    ,ps_end_date           VARCHAR    -- 11 完了日
    ,ps_disburse_date      VARCHAR    -- 12 払出日
)
RETURNS TABLE(
    rn_status      INTEGER,
    rs_sql_code    VARCHAR,
    rs_err_code    VARCHAR,
    rs_err_msg     VARCHAR,
    rs_err_focus   VARCHAR
) AS
$BODY$
DECLARE
    rec_sp_ldas0300         RECORD;
    rec_sp_ldas0301         RECORD;
    rec_sp_ldas0409         RECORD;
    cs_pgmid                CONSTANT VARCHAR := 'LDAS0328';
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    /* Argument Check */
    IF ps_user_id IS NULL THEN
        rs_err_code  := 'ld.E.LDP10110';
        rs_err_msg   := 'Specify the User ID.';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_log_sign IS NULL OR TRIM(ps_log_sign) = '' THEN
        rs_err_code  := 'ld.E.LDP10111';
        rs_err_msg   := 'Specify the Log Sign.';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_receive_id IS NULL THEN
        rs_err_code  := 'ld.E.LDP10112';
        rs_err_msg   := 'Specify the Receive ID.';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_system_id IS NULL THEN
        rs_err_code  := 'ld.E.LDP10113';
        rs_err_msg   := 'Specify the System ID.';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_itemno IS NULL OR TRIM(ps_itemno) = '' THEN
        rs_err_code  := 'ld.E.LDP10915';
        rs_err_msg   := 'Specify the Item Number.';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_supplier IS NULL OR TRIM(ps_supplier) = '' THEN
        rs_err_code  := 'ld.E.LDP10055';
        rs_err_msg   := 'Specify the Supplier.' ;
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_usercd IS NULL OR TRIM(ps_usercd) = '' THEN
        rs_err_code  := 'ld.E.LDP10057';
        rs_err_msg   := 'Specify the User.';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_order_no IS NULL OR TRIM(ps_order_no) = '' THEN
        rs_err_code  := 'ld.E.LDP10130';
        rs_err_msg   := 'Specify the Order Number.';
        RAISE EXCEPTION ' ';
    ELSE
        IF SUBSTRING(ps_order_no,1,1) <> 'W' THEN
            rs_err_code  := 'ld.E.LDP10131';
            rs_err_msg   := 'Specify "W" in the first digit of Order Number.';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    IF pn_order_qty IS NULL THEN
        rs_err_code  := 'ld.E.LDP10132';
        rs_err_msg   := 'Specify the Order Qty.' ;
        RAISE EXCEPTION ' ';
    ELSE
        IF pn_order_qty <= 0 THEN
            rs_err_code  := 'ld.E.LDP10075';
            rs_err_msg   := 'You cannot specify 0 or less than 0.';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    IF ps_start_date IS NULL OR TRIM(ps_start_date) = '' THEN
        rs_err_code  := 'ld.E.LDP10059';
        rs_err_msg   := 'Specify Start Date.';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_end_date IS NULL OR TRIM(ps_end_date) = '' THEN
        rs_err_code  := 'ld.E.LDP10060';
        rs_err_msg   := 'Specify Due Date.' ;
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_disburse_date IS NULL OR TRIM(ps_disburse_date) = '' THEN
        rs_err_code  := 'ld.E.LDP10061';
        rs_err_msg   := 'Specify Disburse Date.';
        RAISE EXCEPTION ' ';
    END IF;

    /* Return Value Set */
    rn_status    :=   0;
    rs_sql_code  := ' ';
    rs_err_code  := ' ';
    rs_err_msg   := ' ';
    rs_err_focus := ' ';

    /* Variable Initialization */
--    ls_line_order_class := ' ';            -- 2017/02/01 Y.Mochiduki DEL

    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    SELECT *
      INTO STRICT rec_sp_ldas0300
      FROM LDAS0300 ( 'LD71'
                       , ps_itemno
                       , ps_supplier
                       , ps_usercd
                    );
    rn_status           := rec_sp_ldas0300.rn_status;
    rs_sql_code         := rec_sp_ldas0300.rs_sql_code;
    rs_err_code         := rec_sp_ldas0300.rs_err_code;
    rs_err_msg          := rec_sp_ldas0300.rs_err_msg;
    rs_err_focus        := rec_sp_ldas0300.rs_err_focus;

    IF rn_status = -1 THEN
        rs_err_msg  := '<<SP:LDAS0300 Error Return>> '
                || 'Return:  ' ||  rec_sp_ldas0300.rn_status || ','|| rec_sp_ldas0300.rs_sql_code || ','
                || rec_sp_ldas0300.rs_err_code || ','|| rec_sp_ldas0300.rs_err_msg || ','|| rec_sp_ldas0300.rs_err_focus;
        RAISE EXCEPTION ' ';
    END IF;
    IF rn_status = -2 THEN
        RAISE EXCEPTION ' ';
    END IF;

    SELECT *
      INTO STRICT rec_sp_ldas0301
      FROM LDAS0301 ( 'LD71'
                    , ps_start_date
                    , ps_end_date
                    , ps_disburse_date
                    , ps_itemno
                    , ps_supplier
                    , ps_usercd
                    , ' '
                    );
    rn_status    := rec_sp_ldas0301.rn_status;
    rs_sql_code  := rec_sp_ldas0301.rs_sql_code;
    rs_err_code  := rec_sp_ldas0301.rs_err_code;
    rs_err_msg   := rec_sp_ldas0301.rs_err_msg;
    rs_err_focus := rec_sp_ldas0301.rs_err_focus;

    IF rn_status = -1 THEN
        rs_err_msg  := '<<SP:LDAS0301 Error Return>> '
                || 'Return:  ' ||  rec_sp_ldas0301.rn_status || ','|| rec_sp_ldas0301.rs_sql_code || ','
                || rec_sp_ldas0301.rs_err_code || ','|| rec_sp_ldas0301.rs_err_msg || ','|| rec_sp_ldas0301.rs_err_focus;
        RAISE EXCEPTION ' ';
    END IF;
    IF rn_status = -2 THEN
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
            rn_status    :=  -2;
            rs_sql_code  := ' ';
            rs_err_focus := cs_pgmid;

        IF ps_log_sign = '1' THEN
            SELECT *
              INTO STRICT rec_sp_ldas0409
              FROM LDAS0409 ( '99'                               --1
                           ,ps_user_id                           --2
                           ,rs_err_code                          --3
                           ,'LD71'                               --4
                           ,'1'                                  --5
                           ,'9'                                  --6
                           ,ps_receive_id                        --7
                           ,ps_system_id                         --8
                           ,' '                                  --9
                           ,cs_pgmid                             --10
                           ,ps_itemno                            --11
                           ,ps_supplier                          --12
                           ,ps_usercd                            --13
                           ,ps_order_no                          --14
                           ,' '                                  --15
                           ,' '                                  --16
                           ,0                                    --17
                           ,' '                                  --18
                           ,' '                                  --19
                           ,' '                                  --20
                           ,' '                                  --21
                           ,' '                                  --22
                           ,' '                                  --23
                           ,' '                                  --24
                           ,ps_start_date                        --25
                           ,' '                                  --26
                           ,' '                                  --27
                           ,' '                                  --28
                           ,' '                                  --29
                           ,0                                    --30
                           ,' '                                  --31
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
                           ,0                                    --69
                           ,ps_start_date                        --70
                           ,' '                                  --71
                           ,' '                                  --72
                           );
            rn_status    := rec_sp_ldas0409.rn_status;
            rs_sql_code  := rec_sp_ldas0409.rs_sql_code;
            rs_err_code  := rec_sp_ldas0409.rs_err_code;
            rs_err_msg   := rec_sp_ldas0409.rs_err_msg;
            rs_err_focus := rec_sp_ldas0409.rs_err_focus;
            IF rec_sp_ldas0409.rn_status <> 0 THEN
                rs_err_msg  := '<<SP:LDAS0409 Error Return>> '
                || 'Return:  ' ||  rec_sp_ldas0409.rn_status || ','|| rec_sp_ldas0409.rs_sql_code || ','
                || rec_sp_ldas0409.rs_err_code || ','|| rec_sp_ldas0409.rs_err_msg || ','|| rec_sp_ldas0409.rs_err_focus;

            END IF;
        END IF;
    END IF;
    RETURN NEXT;
    RETURN;


    WHEN OTHERS THEN                         -- FOR SQL ERROR
        rn_status    := -1;
        rs_sql_code  := SQLSTATE;
        rs_err_code  := ' ';
        rs_err_msg   := SQLERRM;
        rs_err_focus := cs_pgmid;

        RETURN NEXT;
        RETURN;
END;
$BODY$
LANGUAGE 'plpgsql';
