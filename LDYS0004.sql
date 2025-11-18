--------------------------------------------------------------------------------
--@SEE << ld_trn_inv Insert >>
--    @ID      : LDYS0004
--
--    @Written : 1.0.0                   2025.10.14 Sun Sheng / YMSLX
--    --------------------------------------------------------------------------
--    @Update  : xxxxxxxxxxxx            xxxx.xx.xx xxxxxxxx / xx
--     Reason  : xxx
--              xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--
----------------------------------------------------------------------------
--  < INPUT Parameter >
--    @ps_itemno              <I/ >VARCHAR   : Itemno
--    @ps_supplier            <I/ >VARCHAR   : Supplier
--    @ps_usercd              <I/ >VARCHAR   : User Code
--    @pd_update_datetime     <I/ >TIMESTAMP : Update DateTime
--    @ps_update_author       <I/ >VARCHAR   : Update Author
--  < OUTPUT Parameter >
--    @rn_status              < /O> INTEGER  : Return Code
--                                                   (  0 : Normal        )
--                                                   ( -1 : Sql Error     )
--                                                   ( -2 : Program Error )
--    @rs_sql_code            < /O> VARCHAR  : Sql Error Code
--    @rs_err_code            < /O> VARCHAR  : Program Error Code
--    @rs_err_msg             < /O> VARCHAR  : Error Message
--    @rs_err_focus           < /O> VARCHAR  : Error Focus Program ID
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0004(
      ps_itemno          VARCHAR    -- 1 品目番号
    , ps_supplier        VARCHAR    -- 2 供給者
    , ps_usercd          VARCHAR    -- 3 使用者
    , pd_update_datetime TIMESTAMP  -- 4 更新日時
    , ps_update_author   VARCHAR    -- 5 更新者
    )
 RETURNS TABLE(
      rn_status          INTEGER  -- 1 処理ステータス
    , rs_sql_code        VARCHAR  -- 2 SQLコード
    , rs_err_code        VARCHAR  -- 3 エラーコード
    , rs_err_msg         VARCHAR  -- 4 エラーメッセージ
    , rs_err_focus       VARCHAR  -- 5 エラー位置
) AS
$BODY$
DECLARE
    cs_pgmid             CONSTANT VARCHAR(08) := 'LDYS0004';
    cs_space             CONSTANT VARCHAR     := ' ';

BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    /* Return Value Set */
    rn_status   :=   0;
    rs_sql_code := cs_space;
    rs_err_code := cs_space;
    rs_err_msg  := cs_space;
    rs_err_focus:= cs_space;


    /* Argument Check */
    IF ps_itemno IS NULL OR TRIM(ps_itemno) = '' THEN
        rs_err_code := 'ld.E.LDP10011';
        rs_err_msg  := 'Subtraction value error has occurred in the internal processing.'||
                        'Contact the staff in charge of the system.' ;
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_supplier IS NULL OR TRIM(ps_supplier) = '' THEN
        rs_err_code := 'ld.E.LDP10011';
        rs_err_msg  := 'Subtraction value error has occurred in the internal processing.'||
                        'Contact the staff in charge of the system.' ;
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_usercd IS NULL OR TRIM(ps_usercd) = '' THEN
        rs_err_code := 'ld.E.LDP10011';
        rs_err_msg  := 'Subtraction value error has occurred in the internal processing.'||
                        'Contact the staff in charge of the system.';
        RAISE EXCEPTION ' ';
    END IF;

    IF pd_update_datetime IS NULL THEN
        rs_err_code := 'ld.E.LDP10011';
        rs_err_msg  := 'Subtraction value error has occurred in the internal processing.'||
                        'Contact the staff in charge of the system.';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_update_author IS NULL OR TRIM(ps_update_author) = '' THEN
        rs_err_code := 'ld.E.LDP10011';
        rs_err_msg  := 'Subtraction value error has occurred in the internal processing.'||
                        'Contact the staff in charge of the system.';
        RAISE EXCEPTION ' ';
    END IF;

    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    /* ld_trn_inv Insert */
    INSERT INTO ld_trn_inv
    (     itemno
        , supplier
        , usercd
        , next_order_mrp
        , next_ohorder_ic
        , next_odorder_ic
        , next_bhorder_ic
        , next_bdorder_ic
        , oh_qty
        , ordered_qty
        , ind_required_qty
        , dpd_required_qty
        , carry_over_qty
        , hold_qty
        , latest_in_qty
        , latest_in_orderno
        , latest_in_date
        , latest_out_qty
        , latest_out_orderno
        , latest_out_date
        , last_invtake_qty
        , last_invtake_date
        , invtake_sign
        , total_in_qty
        , tiq_back
        , tiq_move
        , tiq_adjust
        , total_out_qty
        , toq_sir
        , toq_hand
        , toq_nonmanufact
        , toq_scrap_use
        , toq_scrap_manufact
        , toq_scrap_sir
        , toq_service
        , toq_ckd
        , toq_ind_required
        , toq_back
        , toq_move
        , total_req_issue_qty
        , total_use_scrap_ratio_qty
        , forecast_plan_exist_div
        , mrp_date
        , ic_update_datetime
        , update_counter
        , create_datetime
        , create_author
        , create_pgmid
        , update_datetime
        , update_author
        , update_pgmid
    )
    VALUES ( ps_itemno           -- itemno
           , ps_supplier         -- supplier
           , ps_usercd           -- usercd
           , '00001'             -- next_order_mrp
           , 'A'                 -- next_ohorder_ic
           , '0001'              -- next_odorder_ic
           , 'P'                 -- next_bhorder_ic
           , '0001'              -- next_bdorder_ic
           , 0                   -- oh_qty
           , 0                   -- ordered_qty
           , 0                   -- ind_required_qty
           , 0                   -- dpd_required_qty
           , 0                   -- carry_over_qty
           , 0                   -- hold_qty
           , 0                   -- latest_in_qty
           , cs_space            -- latest_in_orderno
           , cs_space            -- latest_in_date
           , 0                   -- latest_out_qty
           , cs_space            -- latest_out_orderno
           , cs_space            -- latest_out_date
           , 0                   -- last_invtake_qty
           , cs_space            -- last_invtake_date
           , 0                   -- invtake_sign
           , 0                   -- total_in_qty
           , 0                   -- tiq_back
           , 0                   -- tiq_move
           , 0                   -- tiq_adjust
           , 0                   -- total_out_qty
           , 0                   -- toq_sir
           , 0                   -- toq_hand
           , 0                   -- toq_nonmanufact
           , 0                   -- toq_scrap_use
           , 0                   -- toq_scrap_manufact
           , 0                   -- toq_scrap_sir
           , 0                   -- toq_service
           , 0                   -- toq_ckd
           , 0                   -- toq_ind_required
           , 0                   -- toq_back
           , 0                   -- toq_move
           , 0                   -- total_req_issue_qty
           , 0                   -- total_use_scrap_ratio_qty
           , '0'                 -- forecast_plan_exist_div (forecast_order_exist_sign)
           , cs_space            -- mrp_date
           , pd_update_datetime  -- ic_update_datetime
           , 0                   -- update_counter
           , pd_update_datetime  -- create_datetime
           , ps_update_author    -- create_author
           , cs_pgmid            -- create_pgmid
           , pd_update_datetime  -- update_datetime
           , ps_update_author    -- update_author
           , cs_pgmid            -- update_pgmid
    );

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
        END IF;

        rs_err_focus      := cs_pgmid;
        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN
            rn_status   := -1;
            rs_sql_code := SQLSTATE;
            rs_err_code := cs_space;
            rs_err_msg  := SQLERRM;
            rs_err_focus:= cs_pgmid;

        RETURN NEXT;
        RETURN;
END;
$BODY$
LANGUAGE 'plpgsql';