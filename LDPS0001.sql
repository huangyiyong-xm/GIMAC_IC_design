--------------------------------------------------------------------------------
--@SEE << Product Configuration/Required Quantity Management Change >>
--    @ID      : LDPS0001
--
--    @Written : 1.0.0                   2025.10.23 ZhuYong / YMSLX
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
--    (No Input Parameter)
--  < OUTPUT Parameter >
--    @rn_status                < /O> INTEGER   : Return Code
--                                                (  0 : Normal     )
--                                                (100 : Not Found  )
--                                                ( -1 : Sql Error  )
--                                                ( -2 : PG Error   )
--    @rs_sql_code              < /O> VARCHAR   : Sql Error Code
--    @rs_err_code              < /O> VARCHAR   : Program Error Code
--    @rs_err_msg               < /O> VARCHAR   : Error Message
--    @rs_err_focus             < /O> VARCHAR   : Error Focus Program ID
--    @rs_msg                   < /O> VARCHAR   : Message
--------------------------------------------------------------------------------
--DROP FUNCTION LDPS0001();
CREATE OR REPLACE FUNCTION LDPS0001()
RETURNS TABLE (
    rn_status    INTEGER,
    rs_sql_code  VARCHAR,
    rs_err_code  VARCHAR,
    rs_err_msg   VARCHAR,
    rs_err_focus VARCHAR,
    rs_msg       VARCHAR
) AS $BODY$
DECLARE
    --------------------------------------------------
    --  < Definition Local Paramater >
    --------------------------------------------------
    --  < Constant Definitions >
    --------------------------------------------------
    cs_keyfield_icrevc            CONSTANT VARCHAR := 'ICREVC';
    cs_close_sign_open            CONSTANT VARCHAR := '0';
    cs_close_sign_closed          CONSTANT VARCHAR := '1';
    cs_message_code_200           CONSTANT VARCHAR := '200';
    cs_message_code_210           CONSTANT VARCHAR := '210';
    cs_order_status_cancelled     CONSTANT VARCHAR := '9';
    cs_req_issue_ctrl_00          CONSTANT VARCHAR := '00';
    cs_req_issue_ctrl_11          CONSTANT VARCHAR := '11';
    cs_pgmid                      CONSTANT VARCHAR := 'LDPS0001';

    --------------------------------------------------
    --  < Local Variables >
    --------------------------------------------------
    ls_parent_itemno                      VARCHAR;
    ls_parent_supplier                    VARCHAR;
    ls_parent_usercd                      VARCHAR;
    ls_structure_seq                      VARCHAR;
    ls_comp_itemno                        VARCHAR;
    ls_comp_supplier                      VARCHAR;
    ls_comp_usercd                        VARCHAR;
    ls_message_code                       VARCHAR;
    ld_maintenance_datetime               TIMESTAMP;
    ls_in_effective_ymd                   VARCHAR;
    ls_out_effective_ymd                  VARCHAR;
    ls_comp_sign                          VARCHAR;
    ln_comp_qty                           NUMERIC;
    ls_comp_qty_type                      VARCHAR;
    ln_comp_op_percent                    NUMERIC;
    ls_req_issue_control                  VARCHAR;
    ls_order_no                           VARCHAR;
    ls_start_date                         VARCHAR;
    ls_rls_start_date                     VARCHAR;
    ls_parent_disburse_date               VARCHAR;
    ls_order_status                       VARCHAR;
    ls_pilot_class                        VARCHAR;
    ln_order_qty                          NUMERIC;
    ln_receipt_qty                        NUMERIC;
    ln_scrap_qty                          NUMERIC;
    ls_drd_item_type                      VARCHAR;
    ls_drd_comp_sign                      VARCHAR;
    ln_drd_comp_qty                       NUMERIC;
    ln_drd_comp_op_percent                NUMERIC;
    ls_drd_start_date                     VARCHAR;
    ls_drd_order_status                   VARCHAR;
    ln_drd_required_qty                   NUMERIC;
    ln_drd_ship_qty                       NUMERIC;
    ls_drd_forecast_item_type             VARCHAR;
    ls_drd_forecast_comp_sign             VARCHAR;
    ln_drd_forecast_comp_qty              NUMERIC;
    ln_drd_forecast_comp_op_percent       NUMERIC;
    ls_drd_forecast_start_date            VARCHAR;
    ls_drd_forecast_order_status          VARCHAR;
    ln_drd_forecast_required_qty          NUMERIC;
    ln_drd_forecast_ship_qty              NUMERIC;
    ln_add_cnt1                           INTEGER;
    ln_add_cnt2                           INTEGER;
    ln_del_cnt1                           INTEGER;
    ln_del_cnt2                           INTEGER;
    ln_rn_cnt_ins_lg1                     INTEGER;
    ln_rn_cnt_ins_lg2                     INTEGER;
    ln_derev_trn_cnt                      INTEGER;
    ln_order_cnt                          INTEGER;
    ln_order_forecast_cnt                 INTEGER;
    ls_through_no                         VARCHAR;
    ls_through_no_source_flg              VARCHAR;
    ls_start_shift_no                     VARCHAR;
    ls_item_type                          VARCHAR;
    ls_strc_lt_start_date                 VARCHAR;
    ls_strc_lt_start_time_shift_no        VARCHAR;
    ls_strc_lt_start_shift_no             VARCHAR;
    ls_message                            VARCHAR;

    rec_sub01_result RECORD;
    rec_sub02_result RECORD;

    rec_derev        RECORD;
    rec_order        RECORD;
    rec_forecast     RECORD;

BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    /* Initialize return values */
    rn_status       := 0  ;
    rs_sql_code     := ' ';
    rs_err_code     := ' ';
    rs_err_msg      := ' ';
    rs_msg          := ' ';
    rs_err_focus    := ' ';

    /* Initialize local variables */
    ls_parent_itemno                := ' ';
    ls_parent_supplier              := ' ';
    ls_parent_usercd                := ' ';
    ls_structure_seq                := ' ';
    ls_comp_itemno                  := ' ';
    ls_comp_supplier                := ' ';
    ls_comp_usercd                  := ' ';
    ls_message_code                 := ' ';
    ld_maintenance_datetime         := NULL;
    ls_in_effective_ymd             := ' ';
    ls_out_effective_ymd            := ' ';
    ls_comp_sign                    := ' ';
    ln_comp_qty                     := 0  ;
    ls_comp_qty_type                := ' ';
    ln_comp_op_percent              := 0  ;
    ls_req_issue_control            := ' ';
    ls_order_no                     := ' ';
    ls_start_date                   := ' ';
    ls_rls_start_date               := ' ';
    ls_parent_disburse_date         := ' ';
    ls_order_status                 := ' ';
    ls_pilot_class                  := ' ';
    ln_order_qty                    := 0  ;
    ln_receipt_qty                  := 0  ;
    ln_scrap_qty                    := 0  ;
    ls_drd_item_type                := ' ';
    ls_drd_comp_sign                := ' ';
    ln_drd_comp_qty                 := 0  ;
    ln_drd_comp_op_percent          := 0  ;
    ls_drd_start_date               := ' ';
    ls_drd_order_status             := ' ';
    ln_drd_required_qty             := 0  ;
    ln_drd_ship_qty                 := 0  ;
    ls_drd_forecast_item_type       := ' ';
    ls_drd_forecast_comp_sign       := ' ';
    ln_drd_forecast_comp_qty        := 0  ;
    ln_drd_forecast_comp_op_percent := 0  ;
    ls_drd_forecast_start_date      := ' ';
    ls_drd_forecast_order_status    := ' ';
    ln_drd_forecast_required_qty    := 0  ;
    ln_drd_forecast_ship_qty        := 0  ;
    ln_add_cnt1                     := 0  ;
    ln_add_cnt2                     := 0  ;
    ln_del_cnt1                     := 0  ;
    ln_del_cnt2                     := 0  ;
    ln_rn_cnt_ins_lg1               := 0  ;
    ln_rn_cnt_ins_lg2               := 0  ;
    ln_derev_trn_cnt                := 0  ;
    ln_order_cnt                    := 0  ;
    ln_order_forecast_cnt           := 0  ;
    ls_through_no                   := ' ';
    ls_through_no_source_flg        := ' ';
    ls_start_shift_no               := ' ';
    ls_item_type                    := ' ';
    ls_strc_lt_start_date           := ' ';
    ls_strc_lt_start_time_shift_no  := ' ';
    ls_strc_lt_start_shift_no       := ' ';
    ls_message                      := ' ';

    --------------------------------------------------
    --  < STEP2 : Main Process >
    --------------------------------------------------
    FOR rec_derev IN
        SELECT parent_itemno
             , parent_supplier
             , parent_usercd
             , structure_seq
             , comp_itemno
             , comp_supplier
             , comp_usercd
             , message_code
             , maintenance_datetime
             , in_effective_ymd
             , out_effective_ymd
             , item_type
             , comp_sign
             , comp_qty
             , comp_qty_type
             , comp_op_percent
             , req_issue_control
             , ' ' AS strc_lt_start_shift_no
        FROM ld_trn_derev_trn
       WHERE close_sign    = cs_close_sign_open
         AND message_code IN (cs_message_code_200, cs_message_code_210)
    LOOP
        ls_parent_itemno            := rec_derev.parent_itemno;
        ls_parent_supplier          := rec_derev.parent_supplier;
        ls_parent_usercd            := rec_derev.parent_usercd;
        ls_structure_seq            := rec_derev.structure_seq;
        ls_comp_itemno              := rec_derev.comp_itemno;
        ls_comp_supplier            := rec_derev.comp_supplier;
        ls_comp_usercd              := rec_derev.comp_usercd;
        ls_message_code             := rec_derev.message_code;
        ld_maintenance_datetime     := rec_derev.maintenance_datetime;
        ls_in_effective_ymd         := rec_derev.in_effective_ymd;
        ls_out_effective_ymd        := rec_derev.out_effective_ymd;
        ls_item_type                := rec_derev.item_type;
        ls_comp_sign                := rec_derev.comp_sign;
        ln_comp_qty                 := rec_derev.comp_qty;
        ls_comp_qty_type            := rec_derev.comp_qty_type;
        ln_comp_op_percent          := rec_derev.comp_op_percent;
        ls_req_issue_control        := rec_derev.req_issue_control;
        ls_strc_lt_start_shift_no   := rec_derev.strc_lt_start_shift_no;

        ln_derev_trn_cnt := ln_derev_trn_cnt + 1;

        FOR rec_order IN
            SELECT order_no
                , start_date
                , rls_start_date
                , disburse_date
                , order_status
                , pilot_class
                , order_qty
                , receipt_qty
                , scrap_qty
                , through_no
                , through_no_source_flg
                , start_shift_no
            FROM le_trn_order
           WHERE itemno        = ls_parent_itemno
             AND supplier      = ls_parent_supplier
             AND usercd        = ls_parent_usercd
             AND order_status <> cs_order_status_cancelled
        LOOP
            ls_order_no                     := rec_order.order_no;
            ls_start_date                   := rec_order.start_date;
            ls_strc_lt_start_date           := rec_order.start_date;
            ls_rls_start_date               := rec_order.rls_start_date;
            ls_parent_disburse_date         := rec_order.disburse_date;
            ls_order_status                 := rec_order.order_status;
            ls_pilot_class                  := rec_order.pilot_class;
            ln_order_qty                    := rec_order.order_qty;
            ln_receipt_qty                  := rec_order.receipt_qty;
            ln_scrap_qty                    := rec_order.scrap_qty;
            ls_through_no                   := rec_order.through_no;
            ls_through_no_source_flg        := rec_order.through_no_source_flg;
            ls_start_shift_no               := rec_order.start_shift_no;
            ls_strc_lt_start_time_shift_no  := rec_order.start_shift_no;

            ln_order_cnt := ln_order_cnt + 1;

            SELECT item_type
                , comp_sign
                , comp_qty
                , comp_op_percent
                , start_date
                , order_status
                , required_qty
                , ship_qty
            INTO ls_drd_item_type
                , ls_drd_comp_sign
                , ln_drd_comp_qty
                , ln_drd_comp_op_percent
                , ls_drd_start_date
                , ls_drd_order_status
                , ln_drd_required_qty
                , ln_drd_ship_qty
            FROM le_trn_drd
           WHERE parent_itemno     = ls_parent_itemno
             AND parent_supplier   = ls_parent_supplier
             AND parent_usercd     = ls_parent_usercd
             AND order_no          = ls_order_no
             AND structure_seq     = ls_structure_seq
             AND comp_itemno       = ls_comp_itemno
             AND comp_supplier     = ls_comp_supplier
             AND comp_usercd       = ls_comp_usercd;

            IF NOT FOUND THEN
                IF ls_req_issue_control      = cs_req_issue_ctrl_00
                    AND ls_in_effective_ymd <= ls_rls_start_date
                    AND ls_out_effective_ymd > ls_rls_start_date THEN

                    SELECT t.rn_status
                        ,t.rs_sql_code
                        ,t.rs_err_code
                        ,t.rs_err_msg
                        ,t.rs_err_focus
                        ,t.rn_cnt_ins_lg
                    INTO STRICT rec_sub02_result
                    FROM LDPS0001_02(
                         ls_parent_itemno
                        ,ls_parent_supplier
                        ,ls_parent_usercd
                        ,ls_order_no
                        ,ls_comp_itemno
                        ,ls_comp_supplier
                        ,ls_comp_usercd
                        ,ld_maintenance_datetime
                        ,ls_structure_seq
                        ,ls_through_no
                        ,ls_through_no_source_flg
                        ,ls_start_date
                        ,ls_start_shift_no
                        ,ls_rls_start_date
                        ,ls_strc_lt_start_date
                        ,ls_strc_lt_start_time_shift_no
                        ,ls_order_status
                        ,ls_pilot_class
                        ,ls_item_type
                        ,'0'
                        ,ls_comp_sign
                        ,ls_req_issue_control
                        ,ln_comp_qty
                        ,ls_comp_qty_type
                        ,ls_strc_lt_start_shift_no
                        ,ln_comp_op_percent
                        ,ln_order_qty
                        ,ln_receipt_qty
                        ,ln_scrap_qty
                        ,ls_parent_disburse_date
                        ,ls_message_code
                        ,ls_in_effective_ymd
                        ,ls_out_effective_ymd
                    ) AS t;

                    IF rec_sub02_result.rn_status <> 0 THEN
                        rs_err_code := 'ld.E.LDP10145';
                        rs_err_msg  := 'le_trn_drd <<SP:LDPS0001_02 Error Return>> '
                                   || 'Return:  ' || rec_sub02_result.rn_status || ','
                                   || rec_sub02_result.rs_sql_code || ','
                                   || rec_sub02_result.rs_err_code || ','
                                   || rec_sub02_result.rs_err_msg || ','
                                   || rec_sub02_result.rs_err_focus;
                        RAISE EXCEPTION ' ';
                    END IF;

                    ln_add_cnt1       := ln_add_cnt1 + 1;
                    ln_rn_cnt_ins_lg2 := ln_rn_cnt_ins_lg2 + rec_sub02_result.rn_cnt_ins_lg;
                END IF;
            ELSE
                IF ls_req_issue_control = cs_req_issue_ctrl_11 THEN
                    SELECT t.rn_status
                        ,t.rs_sql_code
                        ,t.rs_err_code
                        ,t.rs_err_msg
                        ,t.rs_err_focus
                        ,t.rn_cnt_ins_lg
                    INTO rec_sub01_result
                    FROM LDPS0001_01(
                        ls_parent_itemno
                        ,ls_parent_supplier
                        ,ls_parent_usercd
                        ,ls_order_no
                        ,ls_structure_seq
                        ,ls_comp_itemno
                        ,ls_comp_supplier
                        ,ls_comp_usercd
                        ,ld_maintenance_datetime
                        ,ls_drd_order_status
                        ,ls_drd_start_date
                        ,ln_drd_required_qty
                        ,ln_drd_ship_qty
                        ,ls_in_effective_ymd
                        ,ls_out_effective_ymd
                        ,ls_drd_comp_sign
                        ,ln_drd_comp_op_percent
                        ,ls_message_code
                        ,ls_parent_disburse_date
                    ) AS t;

                    IF rec_sub01_result.rn_status <> 0 THEN
                        rs_err_code := 'ld.E.LDP10146';
                        rs_err_msg  := 'le_trn_drd <<SP:LDPS0001_01 Error Return>> '
                                || 'Return:  ' ||  rec_sub01_result.rn_status || ','|| rec_sub01_result.rs_sql_code || ','
                                || rec_sub01_result.rs_err_code || ','|| rec_sub01_result.rs_err_msg || ','|| rec_sub01_result.rs_err_focus;
                        RAISE EXCEPTION ' ';
                    END IF;

                    ln_del_cnt1       := ln_del_cnt1 + 1;
                    ln_rn_cnt_ins_lg1 := ln_rn_cnt_ins_lg1 + rec_sub01_result.rn_cnt_ins_lg;
                ELSIF ls_req_issue_control   <> cs_req_issue_ctrl_11
                    AND ls_in_effective_ymd  <= ls_rls_start_date
                    AND ls_out_effective_ymd > ls_rls_start_date THEN

                    IF ls_item_type           <> ls_drd_item_type
                        OR ls_comp_sign       <> ls_drd_comp_sign
                        OR ln_comp_qty        <> ln_drd_comp_qty
                        OR ln_comp_op_percent <> ln_drd_comp_op_percent THEN

                        SELECT t.rn_status
                            ,t.rs_sql_code
                            ,t.rs_err_code
                            ,t.rs_err_msg
                            ,t.rs_err_focus
                            ,t.rn_cnt_ins_lg
                        INTO STRICT rec_sub01_result
                        FROM LDPS0001_01(
                             ls_parent_itemno
                            ,ls_parent_supplier
                            ,ls_parent_usercd
                            ,ls_order_no
                            ,ls_structure_seq
                            ,ls_comp_itemno
                            ,ls_comp_supplier
                            ,ls_comp_usercd
                            ,ld_maintenance_datetime
                            ,ls_drd_order_status
                            ,ls_drd_start_date
                            ,ln_drd_required_qty
                            ,ln_drd_ship_qty
                            ,ls_in_effective_ymd
                            ,ls_out_effective_ymd
                            ,ls_drd_comp_sign
                            ,ln_drd_comp_op_percent
                            ,ls_message_code
                            ,ls_parent_disburse_date
                        ) AS t;

                        IF rec_sub01_result.rn_status <> 0 THEN
                            rs_err_code := 'ld.E.LDP10146';
                            rs_err_msg  := 'le_trn_drd <<SP:LDPS0001_01 Error Return>> '
                                || 'Return:  ' ||  rec_sub01_result.rn_status || ','|| rec_sub01_result.rs_sql_code || ','
                                || rec_sub01_result.rs_err_code || ','|| rec_sub01_result.rs_err_msg || ','|| rec_sub01_result.rs_err_focus;
                            RAISE EXCEPTION ' ';
                        END IF;

                        ln_del_cnt1       := ln_del_cnt1 + 1;
                        ln_rn_cnt_ins_lg1 := ln_rn_cnt_ins_lg1 + rec_sub01_result.rn_cnt_ins_lg;

                        SELECT t.rn_status
                            ,t.rs_sql_code
                            ,t.rs_err_code
                            ,t.rs_err_msg
                            ,t.rs_err_focus
                            ,t.rn_cnt_ins_lg
                        INTO STRICT rec_sub02_result
                        FROM LDPS0001_02(
                            ls_parent_itemno
                            ,ls_parent_supplier
                            ,ls_parent_usercd
                            ,ls_order_no
                            ,ls_comp_itemno
                            ,ls_comp_supplier
                            ,ls_comp_usercd
                            ,ld_maintenance_datetime
                            ,ls_structure_seq
                            ,ls_through_no
                            ,ls_through_no_source_flg
                            ,ls_start_date
                            ,ls_start_shift_no
                            ,ls_rls_start_date
                            ,ls_strc_lt_start_date
                            ,ls_strc_lt_start_time_shift_no
                            ,ls_order_status
                            ,ls_pilot_class
                            ,ls_item_type
                            ,'0'
                            ,ls_comp_sign
                            ,ls_req_issue_control
                            ,ln_comp_qty
                            ,ls_comp_qty_type
                            ,ls_strc_lt_start_shift_no
                            ,ln_comp_op_percent
                            ,ln_order_qty
                            ,ln_receipt_qty
                            ,ln_scrap_qty
                            ,ls_parent_disburse_date
                            ,ls_message_code
                            ,ls_in_effective_ymd
                            ,ls_out_effective_ymd
                        ) AS t;

                        IF rec_sub02_result.rn_status <> 0 THEN
                            rs_err_code := 'ld.E.LDP10145';
                            rs_err_msg  := 'le_trn_drd <<SP:LDPS0001_02 Error Return>> '
                                || 'Return:  ' ||  rec_sub02_result.rn_status || ','|| rec_sub02_result.rs_sql_code || ','
                                || rec_sub02_result.rs_err_code || ','|| rec_sub02_result.rs_err_msg || ','|| rec_sub02_result.rs_err_focus;
                            RAISE EXCEPTION ' ';
                        END IF;

                        ln_add_cnt1       := ln_add_cnt1 + 1;
                        ln_rn_cnt_ins_lg2 := ln_rn_cnt_ins_lg2 + rec_sub02_result.rn_cnt_ins_lg;
                    END IF;
                ELSE
                    SELECT t.rn_status
                        ,t.rs_sql_code
                        ,t.rs_err_code
                        ,t.rs_err_msg
                        ,t.rs_err_focus
                        ,t.rn_cnt_ins_lg
                    INTO STRICT rec_sub01_result
                    FROM LDPS0001_01(
                        ls_parent_itemno
                        ,ls_parent_supplier
                        ,ls_parent_usercd
                        ,ls_order_no
                        ,ls_structure_seq
                        ,ls_comp_itemno
                        ,ls_comp_supplier
                        ,ls_comp_usercd
                        ,ld_maintenance_datetime
                        ,ls_drd_order_status
                        ,ls_drd_start_date
                        ,ln_drd_required_qty
                        ,ln_drd_ship_qty
                        ,ls_in_effective_ymd
                        ,ls_out_effective_ymd
                        ,ls_drd_comp_sign
                        ,ln_drd_comp_op_percent
                        ,ls_message_code
                        ,ls_parent_disburse_date
                    ) AS t;

                    IF rec_sub01_result.rn_status <> 0 THEN
                        rs_err_code := 'ld.E.LDP10146';
                        rs_err_msg := 'le_trn_drd <<SP:LDPS0001_01 Error Return>> '
                                || 'Return:  ' ||  rec_sub01_result.rn_status || ','|| rec_sub01_result.rs_sql_code || ','
                                || rec_sub01_result.rs_err_code || ','|| rec_sub01_result.rs_err_msg || ','|| rec_sub01_result.rs_err_focus;
                        RAISE EXCEPTION ' ';
                    END IF;

                    ln_del_cnt1       := ln_del_cnt1 + 1;
                    ln_rn_cnt_ins_lg1 := ln_rn_cnt_ins_lg1 + rec_sub01_result.rn_cnt_ins_lg;
                END IF;
            END IF;
        END LOOP;

        FOR rec_forecast IN
            SELECT order_no
                ,start_date
                ,rls_start_date
                ,disburse_date
                ,order_status
                ,pilot_class
                ,order_qty
                ,receipt_qty
                ,scrap_qty
                ,through_no
                ,through_no_source_flg
                ,start_shift_no
            FROM le_trn_order_forecast
            WHERE itemno         = ls_parent_itemno
                AND supplier     = ls_parent_supplier
                AND usercd       = ls_parent_usercd
                AND order_status <> cs_order_status_cancelled
        LOOP
            ls_order_no                     := rec_forecast.order_no;
            ls_start_date                   := rec_forecast.start_date;
            ls_strc_lt_start_date           := rec_forecast.start_date;
            ls_rls_start_date               := rec_forecast.rls_start_date;
            ls_parent_disburse_date         := rec_forecast.disburse_date;
            ls_order_status                 := rec_forecast.order_status;
            ls_pilot_class                  := rec_forecast.pilot_class;
            ln_order_qty                    := rec_forecast.order_qty;
            ln_receipt_qty                  := rec_forecast.receipt_qty;
            ln_scrap_qty                    := rec_forecast.scrap_qty;
            ls_through_no                   := rec_forecast.through_no;
            ls_through_no_source_flg        := rec_forecast.through_no_source_flg;
            ls_start_shift_no               := rec_forecast.start_shift_no;
            ls_strc_lt_start_time_shift_no  := rec_forecast.start_shift_no;

            ln_order_forecast_cnt := ln_order_forecast_cnt + 1;

            SELECT item_type
                ,comp_sign
                ,comp_qty
                ,comp_op_percent
                ,start_date
                ,order_status
                ,required_qty
                ,ship_qty
            INTO ls_drd_forecast_item_type
                ,ls_drd_forecast_comp_sign
                ,ln_drd_forecast_comp_qty
                ,ln_drd_forecast_comp_op_percent
                ,ls_drd_forecast_start_date
                ,ls_drd_forecast_order_status
                ,ln_drd_forecast_required_qty
                ,ln_drd_forecast_ship_qty
            FROM le_trn_drd_forecast
            WHERE parent_itemno     = ls_parent_itemno
                AND parent_supplier = ls_parent_supplier
                AND parent_usercd   = ls_parent_usercd
                AND order_no        = ls_order_no
                AND structure_seq   = ls_structure_seq
                AND comp_itemno     = ls_comp_itemno
                AND comp_supplier   = ls_comp_supplier
                AND comp_usercd     = ls_comp_usercd;

            IF NOT FOUND THEN
                IF ls_req_issue_control      = cs_req_issue_ctrl_00
                    AND ls_in_effective_ymd  <= ls_rls_start_date
                    AND ls_out_effective_ymd > ls_rls_start_date THEN

                    SELECT t.rn_status
                        ,t.rs_sql_code
                        ,t.rs_err_code
                        ,t.rs_err_msg
                        ,t.rs_err_focus
                        ,t.rn_cnt_ins_lg
                    INTO STRICT rec_sub02_result
                    FROM LDPS0001_02(
                        ls_parent_itemno
                        ,ls_parent_supplier
                        ,ls_parent_usercd
                        ,ls_order_no
                        ,ls_comp_itemno
                        ,ls_comp_supplier
                        ,ls_comp_usercd
                        ,ld_maintenance_datetime
                        ,ls_structure_seq
                        ,ls_through_no
                        ,ls_through_no_source_flg
                        ,ls_start_date
                        ,ls_start_shift_no
                        ,ls_rls_start_date
                        ,ls_strc_lt_start_date
                        ,ls_strc_lt_start_time_shift_no
                        ,ls_order_status
                        ,ls_pilot_class
                        ,ls_item_type
                        ,'0'
                        ,ls_comp_sign
                        ,ls_req_issue_control
                        ,ln_comp_qty
                        ,ls_comp_qty_type
                        ,ls_strc_lt_start_shift_no
                        ,ln_comp_op_percent
                        ,ln_order_qty
                        ,ln_receipt_qty
                        ,ln_scrap_qty
                        ,ls_parent_disburse_date
                        ,ls_message_code
                        ,ls_in_effective_ymd
                        ,ls_out_effective_ymd
                    ) AS t;

                    IF rec_sub02_result.rn_status <> 0 THEN
                        rs_err_code := 'ld.E.LDP10147';
                        rs_err_msg := 'le_trn_drd_forecast <<SP:LDPS0001_02 Error Return>> '
                                || 'Return:  ' ||  rec_sub02_result.rn_status || ','|| rec_sub02_result.rs_sql_code || ','
                                || rec_sub02_result.rs_err_code || ','|| rec_sub02_result.rs_err_msg || ','|| rec_sub02_result.rs_err_focus;
                        RAISE EXCEPTION ' ';
                    END IF;

                    ln_add_cnt2       := ln_add_cnt2 + 1;
                    ln_rn_cnt_ins_lg2 := ln_rn_cnt_ins_lg2 + rec_sub02_result.rn_cnt_ins_lg;
                END IF;
            ELSE
                IF ls_req_issue_control = cs_req_issue_ctrl_11 THEN
                    SELECT t.rn_status
                        ,t.rs_sql_code
                        ,t.rs_err_code
                        ,t.rs_err_msg
                        ,t.rs_err_focus
                        ,t.rn_cnt_ins_lg
                    INTO STRICT rec_sub01_result
                    FROM LDPS0001_01(
                         ls_parent_itemno
                        ,ls_parent_supplier
                        ,ls_parent_usercd
                        ,ls_order_no
                        ,ls_structure_seq
                        ,ls_comp_itemno
                        ,ls_comp_supplier
                        ,ls_comp_usercd
                        ,ld_maintenance_datetime
                        ,ls_drd_forecast_order_status
                        ,ls_drd_forecast_start_date
                        ,ln_drd_forecast_required_qty
                        ,ln_drd_forecast_ship_qty
                        ,ls_in_effective_ymd
                        ,ls_out_effective_ymd
                        ,ls_drd_forecast_comp_sign
                        ,ln_drd_forecast_comp_op_percent
                        ,ls_message_code
                        ,ls_parent_disburse_date
                    ) AS t;

                    IF rec_sub01_result.rn_status <> 0 THEN
                        rs_err_code := 'ld.E.LDP10148';
                        rs_err_msg  := 'le_trn_drd_forecast <<SP:LDPS0001_01 Error Return>> '
                                || 'Return:  ' ||  rec_sub01_result.rn_status || ','|| rec_sub01_result.rs_sql_code || ','
                                || rec_sub01_result.rs_err_code || ','|| rec_sub01_result.rs_err_msg || ','|| rec_sub01_result.rs_err_focus;
                        RAISE EXCEPTION ' ';
                    END IF;

                    ln_del_cnt2       := ln_del_cnt2 + 1;
                    ln_rn_cnt_ins_lg1 := ln_rn_cnt_ins_lg1 + rec_sub01_result.rn_cnt_ins_lg;
                ELSIF ls_req_issue_control   <> cs_req_issue_ctrl_11
                    AND ls_in_effective_ymd  <= ls_rls_start_date
                    AND ls_out_effective_ymd > ls_rls_start_date THEN

                    IF ls_item_type           <> ls_drd_forecast_item_type
                        OR ls_comp_sign       <> ls_drd_forecast_comp_sign
                        OR ln_comp_qty        <> ln_drd_forecast_comp_qty
                        OR ln_comp_op_percent <> ln_drd_forecast_comp_op_percent THEN

                        SELECT t.rn_status
                            ,t.rs_sql_code
                            ,t.rs_err_code
                            ,t.rs_err_msg
                            ,t.rs_err_focus
                            ,t.rn_cnt_ins_lg
                        INTO STRICT rec_sub01_result
                        FROM LDPS0001_01(
                            ls_parent_itemno
                            ,ls_parent_supplier
                            ,ls_parent_usercd
                            ,ls_order_no
                            ,ls_structure_seq
                            ,ls_comp_itemno
                            ,ls_comp_supplier
                            ,ls_comp_usercd
                            ,ld_maintenance_datetime
                            ,ls_drd_forecast_order_status
                            ,ls_drd_forecast_start_date
                            ,ln_drd_forecast_required_qty
                            ,ln_drd_forecast_ship_qty
                            ,ls_in_effective_ymd
                            ,ls_out_effective_ymd
                            ,ls_drd_forecast_comp_sign
                            ,ln_drd_forecast_comp_op_percent
                            ,ls_message_code
                            ,ls_parent_disburse_date
                        ) AS t;

                        IF rec_sub01_result.rn_status <> 0 THEN
                            rs_err_code := 'ld.E.LDP10148';
                            rs_err_msg  := 'le_trn_drd_forecast <<SP:LDPS0001_01 Error Return>> '
                                || 'Return:  ' ||  rec_sub01_result.rn_status || ','|| rec_sub01_result.rs_sql_code || ','
                                || rec_sub01_result.rs_err_code || ','|| rec_sub01_result.rs_err_msg || ','|| rec_sub01_result.rs_err_focus;
                            RAISE EXCEPTION ' ';
                        END IF;

                        ln_del_cnt2       := ln_del_cnt2 + 1;
                        ln_rn_cnt_ins_lg1 := ln_rn_cnt_ins_lg1 + rec_sub01_result.rn_cnt_ins_lg;

                        SELECT t.rn_status
                            ,t.rs_sql_code
                            ,t.rs_err_code
                            ,t.rs_err_msg
                            ,t.rs_err_focus
                            ,t.rn_cnt_ins_lg
                        INTO STRICT rec_sub02_result
                        FROM LDPS0001_02(
                             ls_parent_itemno
                            ,ls_parent_supplier
                            ,ls_parent_usercd
                            ,ls_order_no
                            ,ls_comp_itemno
                            ,ls_comp_supplier
                            ,ls_comp_usercd
                            ,ld_maintenance_datetime
                            ,ls_structure_seq
                            ,ls_through_no
                            ,ls_through_no_source_flg
                            ,ls_start_date
                            ,ls_start_shift_no
                            ,ls_rls_start_date
                            ,ls_strc_lt_start_date
                            ,ls_strc_lt_start_time_shift_no
                            ,ls_order_status
                            ,ls_pilot_class
                            ,ls_item_type
                            ,'0'
                            ,ls_comp_sign
                            ,ls_req_issue_control
                            ,ln_comp_qty
                            ,ls_comp_qty_type
                            ,ls_strc_lt_start_shift_no
                            ,ln_comp_op_percent
                            ,ln_order_qty
                            ,ln_receipt_qty
                            ,ln_scrap_qty
                            ,ls_parent_disburse_date
                            ,ls_message_code
                            ,ls_in_effective_ymd
                            ,ls_out_effective_ymd
                        ) AS t;

                        IF rec_sub02_result.rn_status <> 0 THEN
                            rs_err_code := 'ld.E.LDP10147';
                            rs_err_msg  := 'le_trn_drd_forecast <<SP:LDPS0001_02 Error Return>> '
                                || 'Return:  ' ||  rec_sub02_result.rn_status || ','|| rec_sub02_result.rs_sql_code || ','
                                || rec_sub02_result.rs_err_code || ','|| rec_sub02_result.rs_err_msg || ','|| rec_sub02_result.rs_err_focus;
                            RAISE EXCEPTION ' ';
                        END IF;

                        ln_add_cnt2       := ln_add_cnt2 + 1;
                        ln_rn_cnt_ins_lg2 := ln_rn_cnt_ins_lg2 + rec_sub02_result.rn_cnt_ins_lg;
                    END IF;
                ELSE
                    SELECT t.rn_status
                        ,t.rs_sql_code
                        ,t.rs_err_code
                        ,t.rs_err_msg
                        ,t.rs_err_focus
                        ,t.rn_cnt_ins_lg
                    INTO STRICT rec_sub01_result
                    FROM LDPS0001_01(
                        ls_parent_itemno
                        ,ls_parent_supplier
                        ,ls_parent_usercd
                        ,ls_order_no
                        ,ls_structure_seq
                        ,ls_comp_itemno
                        ,ls_comp_supplier
                        ,ls_comp_usercd
                        ,ld_maintenance_datetime
                        ,ls_drd_forecast_order_status
                        ,ls_drd_forecast_start_date
                        ,ln_drd_forecast_required_qty
                        ,ln_drd_forecast_ship_qty
                        ,ls_in_effective_ymd
                        ,ls_out_effective_ymd
                        ,ls_drd_forecast_comp_sign
                        ,ln_drd_forecast_comp_op_percent
                        ,ls_message_code
                        ,ls_parent_disburse_date
                    ) AS t;

                    IF rec_sub01_result.rn_status <> 0 THEN
                        rs_err_code := 'ld.E.LDP10148';
                        rs_err_msg  := 'le_trn_drd_forecast <<SP:LDPS0001_01 Error Return>> '
                                || 'Return:  ' ||  rec_sub01_result.rn_status || ','|| rec_sub01_result.rs_sql_code || ','
                                || rec_sub01_result.rs_err_code || ','|| rec_sub01_result.rs_err_msg || ','|| rec_sub01_result.rs_err_focus;
                        RAISE EXCEPTION ' ';
                    END IF;

                    ln_del_cnt2       := ln_del_cnt2 + 1;
                    ln_rn_cnt_ins_lg1 := ln_rn_cnt_ins_lg1 + rec_sub01_result.rn_cnt_ins_lg;
                END IF;
            END IF;
        END LOOP;

        UPDATE ld_trn_derev_trn
        SET close_sign      = cs_close_sign_closed,
            update_author   = cs_pgmid,
            update_counter  = update_counter + 1,
            update_datetime = CURRENT_TIMESTAMP,
            update_pgmid    = cs_pgmid
        WHERE close_sign               = cs_close_sign_open
            AND parent_itemno          = ls_parent_itemno
            AND parent_supplier        = ls_parent_supplier
            AND parent_usercd          = ls_parent_usercd
            AND structure_seq          = ls_structure_seq
            AND comp_itemno            = ls_comp_itemno
            AND comp_supplier          = ls_comp_supplier
            AND comp_usercd            = ls_comp_usercd
            AND message_code           = ls_message_code
            AND maintenance_datetime   = ld_maintenance_datetime;
    END LOOP;

    --------------------------------------------------
    --  < STEP3 : Return Value Processing >
    --------------------------------------------------
    rs_msg := '<ld_trn_derev_trn>  SEL:' || COALESCE(ln_derev_trn_cnt::TEXT, '0')
           || ',' || '<le_trn_order>  SEL:' || COALESCE(ln_order_cnt::TEXT, '0')
           || '  DEL:' || COALESCE(ln_del_cnt1::TEXT, '0')
           || '  INS:' || COALESCE(ln_add_cnt1::TEXT, '0')
           || ',' || '<le_trn_order_forecast>  SEL:' || COALESCE(ln_order_forecast_cnt::TEXT, '0')
           || '  DEL:' || COALESCE(ln_del_cnt2::TEXT, '0')
           || '  INS:' || COALESCE(ln_add_cnt2::TEXT, '0')
           || ',' || '<ld_trn_reqchg_log> INS(as DEL):' || COALESCE(ln_rn_cnt_ins_lg1::TEXT, '0')
           || '  INS(as ADD):' || COALESCE(ln_rn_cnt_ins_lg2::TEXT, '0');
    rn_status := 0;
    RETURN NEXT;
    RETURN;

EXCEPTION
    WHEN RAISE_EXCEPTION THEN
        IF rn_status <> 0 THEN  -- FOR CALL SP ERROR
            NULL;
        ELSE                    -- FOR PGM ERROR
            rn_status         :=  -2;
            rs_sql_code       := ' ';
        END IF;

        rs_err_focus      := cs_pgmid;
        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN            -- FOR SQL ERROR
        rn_status         := -1;
        rs_sql_code       := SQLSTATE;
        rs_err_code       := ' ';
        rs_err_msg        := SQLERRM;
        rs_err_focus      := cs_pgmid;

        RETURN NEXT;
        RETURN;
END;
$BODY$
LANGUAGE plpgsql;
