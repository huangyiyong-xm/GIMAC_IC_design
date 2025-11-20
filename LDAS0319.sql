--------------------------------------------------------------------------------
--@SEE << Raw Materials Price Copy >>
--    @ID      : LDAS0319
--
--    @Written : 1.0.0                2025.11.17 SunSheng / YMSLX
--    --------------------------------------------------------------------------
--    @Update  : xxxxxxxxxxxx         xxxx.xx.xx xxxxxxxx / xx
--     Reason  : xxx
--              xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--
----------------------------------------------------------------------------
--  < INPUT Parameter >
--    @ps_user_id                     <I/ > VARCHAR       : User Id
--    @ps_log_sign                    <I/ > VARCHAR       : Supplier
--    @ps_receive_id                  <I/ > VARCHAR       : Recieve Id
--    @ps_request_system_code         <I/ > VARCHAR       : Request System Code
--    @ps_itemno                      <I/ > VARCHAR       : Itemno
--    @ps_supplier                    <I/ > VARCHAR       : Supplier
--    @ps_usercd                      <I/ > VARCHAR       : Usercd
--    @ps_order_no                    <I/ > VARCHAR       : Order No
--    @ps_delete_ymd                  <I/ > VARCHAR       : Delete Ymd
--  < OUTPUT Parameter >
--    @rn_status                      < /O> INTEGER       : Return Code
--                                                         (  0 : Normal       )
--                                                         ( -1 : Sql Error    )
--                                                         ( -2 : Program Error)
--    @rs_sql_code                    < /O> VARCHAR       : Sql Code
--    @rs_err_code                    < /O> VARCHAR       : Error Code
--    @rs_err_msg                     < /O> VARCHAR       : Error Message
--    @rs_err_focus                   < /O> VARCHAR       : Error Focus
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDAS0319(
      ps_user_id              VARCHAR       -- 1 ユーザーＩＤ
    , ps_log_sign             VARCHAR       -- 2 ログ出力サイン
    , ps_receive_id           VARCHAR       -- 3 受信ID
    , ps_request_system_code  VARCHAR       -- 4 相手先システム識別
    , ps_itemno               VARCHAR       -- 5 品目番号
    , ps_supplier             VARCHAR       -- 6 供給者
    , ps_usercd               VARCHAR       -- 7 使用者
    , ps_order_no             VARCHAR       -- 8 オーダー番号
    , ps_delete_ymd           VARCHAR       -- 9 削除日付
)
RETURNS TABLE(
      rn_status               INTEGER       -- 1 処理ステータス
    , rs_sql_code             VARCHAR       -- 2 SQLコード
    , rs_err_code             VARCHAR       -- 3 エラーコード
    , rs_err_msg              VARCHAR       -- 4 エラーメッセージ
    , rs_err_focus            VARCHAR       -- 5 エラー位置
) AS
$BODY$
DECLARE
    -- SP return record  --
    rec_sp_leys0001                RECORD;
    rec_sp_ldas0409                RECORD;
    ls_calendar_code               la_area_master_su.calendar_code%TYPE;
    ls_day_type                    le_mst_calendar_sum.day_type%TYPE;
    ls_ic_slip_date                ld_mst_slip_date.ic_slip_date%TYPE;
    ls_start_date                  le_trn_ird.start_date%TYPE;
    ls_rls_start_date              le_trn_ird.rls_start_date%TYPE;
    ln_rd_delete_input_days        le_system_parameter.rd_delete_input_days%TYPE;
    ln_change_rd_delete_input_days INTEGER;
    cs_space                        CONSTANT VARCHAR := ' ';
    cs_pgmid                        CONSTANT VARCHAR := 'LDAS0319';
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    /* Return Value Set */
    rn_status    := 0;
    rs_sql_code  := cs_space;
    rs_err_code  := cs_space;
    rs_err_msg   := cs_space;
    rs_err_focus := cs_space;

    /* Variable Initialization */
    ls_calendar_code               := cs_space;
    ls_day_type                    := cs_space;
    ls_ic_slip_date                := cs_space;
    ls_start_date                  := cs_space;
    ls_rls_start_date              := cs_space;
    ln_rd_delete_input_days        := 0;
    ln_change_rd_delete_input_days := 0;

    /* Argument Check */
    IF ps_order_no IS NULL OR TRIM (ps_order_no) = '' THEN
        rs_err_code  := 'ld.E.LDP10050';
        rs_err_msg   := 'Enter Order Number.';
        RAISE EXCEPTION ' ';
    END IF;
    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    IF EXISTS(SELECT 1
                FROM la_area_master_su
               WHERE su_code = ps_usercd)THEN
        SELECT calendar_code
          INTO ls_calendar_code
          FROM la_area_master_su
         WHERE su_code = ps_usercd;
    ELSE
        rs_err_code := 'ld.E.LDP10062';
        rs_err_msg  := 'Effective calendar does not exist ' ||
                       'by the specified Supplier/User.';
        RAISE EXCEPTION ' ';
    END IF;

    IF EXISTS(SELECT 1
                FROM le_mst_calendar_sum
               WHERE calendar_code = ls_calendar_code
                 AND calendar_ymd  = ps_delete_ymd) THEN
        SELECT day_type
          INTO ls_day_type
          FROM le_mst_calendar_sum
         WHERE calendar_code = ls_calendar_code
           AND calendar_ymd  = ps_delete_ymd;

        IF ls_day_type <> '0' THEN
            rs_err_code := 'ld.E.LDP10090';
            rs_err_msg  := 'The day you specified is not a working-day.';
            RAISE EXCEPTION ' ';
        END IF;
    ELSE
        rs_err_code := 'ld.E.LDP10064';
        rs_err_msg  := 'Day String does not exist in the common calendar.';
        RAISE EXCEPTION ' ';
    END IF;

    IF EXISTS( SELECT 1
                 FROM ld_mst_slip_date
                WHERE operation_type = 'STD')THEN
        SELECT ic_slip_date
          INTO ls_ic_slip_date
          FROM ld_mst_slip_date
         WHERE operation_type = 'STD';
    ELSE
        rs_err_code := 'ld.E.LDP10004';
        rs_err_msg  := 'The IC pymac date is not exist.';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_delete_ymd < ls_ic_slip_date THEN
        rs_err_code := 'ld.E.LDP10091';
        rs_err_msg  := 'For Deletion Date, specify the date later than ' ||
                       'the final day of the fixed period of this time.';
        RAISE EXCEPTION ' ';
    END IF;

    IF EXISTS( SELECT 1
                 FROM le_trn_ird
                WHERE itemno     =  ps_itemno
                  AND supplier   =  ps_supplier
                  AND usercd     =  ps_usercd
                  AND order_no   =  ps_order_no
                  AND delete_ymd =  cs_space
                  AND rd_class   =  '1'
                  AND start_date <> rls_start_date)THEN
        SELECT start_date
              ,rls_start_date
          INTO ls_start_date
              ,ls_rls_start_date
          FROM le_trn_ird
         WHERE itemno     =  ps_itemno
           AND supplier   =  ps_supplier
           AND usercd     =  ps_usercd
           AND order_no   =  ps_order_no
           AND delete_ymd =  cs_space
           AND rd_class   =  '1'
           AND start_date <> rls_start_date;
    ELSE
        rs_err_code := 'ld.E.LDP10039';
        rs_err_msg  := 'The requirements you specified '||
                       'does not exist.';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_delete_ymd = ls_start_date THEN
        rs_err_code := 'ld.E.LDP10106';
        rs_err_msg  := 'Change Deletion Date.';
        RAISE EXCEPTION ' ';
    END IF;
    IF ps_delete_ymd <= ls_rls_start_date THEN
        rs_err_code := 'ld.E.LDP10102';
        rs_err_msg  := 'For Deletion Date, specify the date '||
                       'later than Start Date.';
        RAISE EXCEPTION ' ';
    END IF;

    IF EXISTS( SELECT 1
                 FROM le_system_parameter
                WHERE system_code = 'LE')THEN
        SELECT rd_delete_input_days
          INTO ln_rd_delete_input_days
          FROM le_system_parameter
         WHERE system_code = 'LE';

    ELSE
        rs_err_code := 'ld.E.LDP10107';
        rs_err_msg  := 'Advanced Production Deletion Date Input '||
                       'Days does not exist in the MRP system parameter.';
        RAISE EXCEPTION ' ';
    END IF;

    ln_change_rd_delete_input_days := ln_rd_delete_input_days;

        SELECT LEYS0001.rn_status
             , LEYS0001.rs_sql_code
             , LEYS0001.rs_err_code
             , LEYS0001.rs_err_msg
             , LEYS0001.rs_target_date
          INTO STRICT rec_sp_leys0001
          FROM LEYS0001(ls_calendar_code
                      , ls_rls_start_date
                      , ln_change_rd_delete_input_days
                    );

    -- return item set --
    rs_sql_code := rec_sp_leys0001.rs_sql_code;
    rs_err_code := rec_sp_leys0001.rs_err_code;
    rs_err_msg  := rec_sp_leys0001.rs_err_msg;

    IF rec_sp_leys0001.rn_status = -1 THEN
        rn_status    := rec_sp_leys0001.rn_status;
        rs_err_focus := cs_pgmid;

        RETURN NEXT;
        RETURN;

    ELSIF rec_sp_leys0001.rn_status = -2 THEN
        RAISE EXCEPTION ' ';

    ELSE
        IF ps_delete_ymd > rec_sp_leys0001.rs_target_date THEN
            rs_err_code  := 'ld.E.LDP10103';
            rs_err_msg   := 'Deletion Date is over the period in ' ||
                            'which the date is able to be ' ||
                            'resistered from Start Date.';
            RAISE EXCEPTION ' ';
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
        ELSE                    -- FOR PGM ERROR
            rn_status         :=  -2;
            rs_sql_code       := cs_space;
            rs_err_focus      := cs_pgmid;

            IF ps_log_sign = '1' THEN
                SELECT LDAS0409.rn_status
                     , LDAS0409.rs_sql_code
                     , LDAS0409.rs_err_code
                     , LDAS0409.rs_err_msg
                  INTO STRICT rec_sp_ldas0409
                  FROM LDAS0409( '99'                                 --1
                                ,ps_user_id                           --2
                                ,rs_err_code                          --3
                                ,'LD21'                               --4
                                ,'2'                                  --5
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
                                ,0                                    --17
                                ,cs_space                             --18
                                ,cs_space                             --19
                                ,cs_space                             --20
                                ,cs_space                             --21
                                ,cs_space                             --22
                                ,cs_space                             --23
                                ,cs_space                             --24
                                ,cs_space                             --25
                                ,cs_space                             --26
                                ,cs_space                             --27
                                ,cs_space                             --28
                                ,cs_space                             --29
                                ,0                                    --30
                                ,cs_space                             --31
                                ,cs_space                             --32
                                ,cs_space                             --33
                                ,cs_space                             --34
                                ,cs_space                             --35
                                ,ps_delete_ymd                        --36
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
                                ,0                                    --69
                                ,cs_space                             --70
                                ,cs_space                             --71
                                ,cs_space                             --72
                        );

                IF rec_sp_ldas0409.rn_status <> 0 THEN
                    rn_status   := rec_sp_ldas0409.rn_status;
                    rs_sql_code := rec_sp_ldas0409.rs_sql_code;
                    rs_err_code := rec_sp_ldas0409.rs_err_code;
                    rs_err_msg  := rec_sp_ldas0409.rs_err_msg ;

                    RETURN NEXT;
                    RETURN;
                END IF;
            END IF;
        END IF;

        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN
        rn_status         := -1;
        rs_sql_code       := SQLSTATE;
        rs_err_code       := cs_space;
        rs_err_msg        := SQLERRM;
        rs_err_focus      := cs_pgmid;

        RETURN NEXT;
        RETURN;
END;
$BODY$
LANGUAGE 'plpgsql';

