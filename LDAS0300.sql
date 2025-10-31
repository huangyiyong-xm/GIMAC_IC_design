--------------------------------------------------------------------------------
--    @SEE << Valid Common/Item Validity Check >>
--    @ID      : LDAS0300
--
--    @Written : 1.0.0                   2025.10.14 Sun Sheng / YMSLX
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--
--------------------------------------------------------------------------------
--@SEE << Valid Common/Item Validity Check >>
--------------------------------------------------------------------------------
--  < INPUT Parameter >
--    @ps_operation_id           <I/ > VARCHAR   : Operation Id
--    @ps_itemno                 <I/ > VARCHAR   : Itemno
--    @ps_supplier               <I/ > VARCHAR   : Supplier
--    @ps_usercd                 <I/ > VARCHAR   : Usercd
--  < OUTPUT Parameter >
--    @rn_status                 < /O> INTEGER   : Return Code
--                                                   (  0 : Normal End     )
--                                                   ( -1 : Abnormal End   )
--                                                   ( -2 : PGM Error      )
--    @rs_sql_code               < /O> VARCHAR   : Sql Error Code
--    @rs_err_code               < /O> VARCHAR   : Program Error Code
--    @rs_err_msg                < /O> VARCHAR   : Error Message
--    @rs_err_focus              < /O> VARCHAR   : Error Focus
--    @rs_item_class             < /O> VARCHAR   : Item Class
--    @rs_item_status            < /O> VARCHAR   : Item Status
--    @rs_demand_policy_code     < /O> VARCHAR   : Demand Policy Code
--    @rs_airs_sign              < /O> VARCHAR   : Airs Sign
--    @rn_float_safety_stock_qty < /O> DECIMAL   : Float Safety Stock Qty
--    @rs_synchro_control_code   < /O> VARCHAR   : Synchro Control Code
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ldas0300(
    ps_operation_id character varying,  --1.処理識別
    ps_itemno character varying,        --2.品目番号
    ps_supplier character varying,      --3.供給者
    ps_usercd character varying)        --4.使用者
 RETURNS TABLE(
    rn_status integer,                         --1.ステータス
    rs_sql_code character varying,             --2.SQLコード
    rs_err_code character varying,             --3.エラーコード
    rs_err_msg character varying,              --4.エラーメッセージ
    rs_err_focus character varying,            --5.エラー位置
    rs_item_class character varying,           --6.品目クラス
    rs_item_status character varying,          --7.品目ステータス
    rs_demand_policy_code character varying,   --8.MRP需要方針コード
    rs_airs_sign character varying,            --9.AIRSサイン
    rn_float_safety_stock_qty numeric,         --10.変動安全在庫数
    rs_synchro_control_code character varying  --11.シンクロ管理コード
    )
AS
$BODY$
DECLARE
    ls_item_type                 la_itemmast.item_type%TYPE;
    ls_item_class                la_itemmast.item_class%TYPE;
    ls_item_status               la_itemmast.item_status%TYPE;
    ls_demand_policy_code        le_mst_mrp_information.demand_policy_code%TYPE;
    ls_wbin_control_code         le_mst_mrp_information.wbin_control_code%TYPE;
    ls_airs_sign                 le_mst_mrp_information.airs_sign%TYPE;
    ln_float_safety_stock_qty    le_mst_mrp_information.float_safety_stock_qty%TYPE;
    ls_synchro_control_code      le_mst_mrp_information.synchro_control_code%TYPE;
    -- Error Code Constants
    cs_err_no_operation_id       CONSTANT VARCHAR := 'ld.E.LDP10054';
    cs_err_no_itemno             CONSTANT VARCHAR := 'ld.E.LDP10055';
    cs_err_no_supplier           CONSTANT VARCHAR := 'ld.E.LDP10056';
    cs_err_no_usercd             CONSTANT VARCHAR := 'ld.E.LDP10057';
    cs_err_item_not_exist        CONSTANT VARCHAR := 'ld.E.LDP10019';
    cs_err_invalid_item_class    CONSTANT VARCHAR := 'ld.E.LDP10037';
    cs_err_item_status_trial     CONSTANT VARCHAR := 'ld.E.LDP10024';
    cs_err_item_type_trial       CONSTANT VARCHAR := 'ld.E.LDP10020';
    cs_err_item_type_standard    CONSTANT VARCHAR := 'ld.E.LDP10021';
    cs_err_item_class_materials  CONSTANT VARCHAR := 'ld.E.LDP10022';
    cs_err_item_class_parts      CONSTANT VARCHAR := 'ld.E.LDP10058';
    cs_err_demand_policy_range   CONSTANT VARCHAR := 'ld.E.LDP10026';
    cs_err_demand_policy_manual  CONSTANT VARCHAR := 'ld.E.LDP10028';
    cs_err_wbin_out_control      CONSTANT VARCHAR := 'ld.E.LDP10029';
    cs_err_wbin_in_control       CONSTANT VARCHAR := 'ld.E.LDP10030';
    cs_err_airs_item             CONSTANT VARCHAR := 'ld.E.LDP10034';

    -- Operation IDs
    cs_LD11                      CONSTANT VARCHAR := 'LD11';
    cs_LD41                      CONSTANT VARCHAR := 'LD41';
    cs_LD71                      CONSTANT VARCHAR := 'LD71';
    cs_LD21                      CONSTANT VARCHAR := 'LD21';
    cs_LD15                      CONSTANT VARCHAR := 'LD15';
    cs_LD18                      CONSTANT VARCHAR := 'LD18';
    cs_LD28                      CONSTANT VARCHAR := 'LD28';
    cs_LD33                      CONSTANT VARCHAR := 'LD33';
    cs_LD46                      CONSTANT VARCHAR := 'LD46';
    cs_LD48                      CONSTANT VARCHAR := 'LD48';
    cs_LD52                      CONSTANT VARCHAR := 'LD52';
    cs_LD68                      CONSTANT VARCHAR := 'LD68';
    cs_LD14                      CONSTANT VARCHAR := 'LD14';
    cs_LD24                      CONSTANT VARCHAR := 'LD24';
    cs_LD44                      CONSTANT VARCHAR := 'LD44';
    cs_LD74                      CONSTANT VARCHAR := 'LD74';
    cs_LD78                      CONSTANT VARCHAR := 'LD78';
    cs_LD80                      CONSTANT VARCHAR := 'LD80';
    cs_LD81                      CONSTANT VARCHAR := 'LD81';

    -- Item Class values
    cs_ITEM_CLASS_M              CONSTANT VARCHAR := 'M';
    cs_ITEM_CLASS_K              CONSTANT VARCHAR := 'K';
    cs_ITEM_CLASS_0              CONSTANT VARCHAR := '0';
    cs_ITEM_CLASS_1              CONSTANT VARCHAR := '1';
    cs_ITEM_CLASS_2              CONSTANT VARCHAR := '2';
    cs_ITEM_CLASS_E              CONSTANT VARCHAR := 'E';
    cs_ITEM_CLASS_F              CONSTANT VARCHAR := 'F';

    -- Item Type and Status values
    cs_ITEM_TYPE_1               CONSTANT VARCHAR := '1';
    cs_ITEM_TYPE_2               CONSTANT VARCHAR := '2';
    cs_ITEM_STATUS_1             CONSTANT VARCHAR := '1';

    -- Demand Policy Code values
    cs_DEMAND_1                  CONSTANT VARCHAR := '1';
    cs_DEMAND_2                  CONSTANT VARCHAR := '2';
    cs_DEMAND_6                  CONSTANT VARCHAR := '6';

    -- W-bin Control Code values
    cs_WBIN_0                    CONSTANT VARCHAR := '0';
    cs_WBIN_1                    CONSTANT VARCHAR := '1';

    -- AIRS Sign values
    cs_AIRS_1                    CONSTANT VARCHAR := '1';

    -- Flag values
    cs_FLAG_Y                    CONSTANT VARCHAR := 'Y';
    cs_FLAG_N                    CONSTANT VARCHAR := 'N';
    -- Standard values
    cn_STATUS_NORMAL             CONSTANT INTEGER := 0;
    cn_STATUS_SQL_ERROR          CONSTANT INTEGER := -1;
    cn_STATUS_PROGRAM_ERROR      CONSTANT INTEGER := -2;

    -- Common values
    cs_ZERO                      CONSTANT VARCHAR := '0';
    cs_SPACE                     CONSTANT VARCHAR := ' ';
    cs_EMPTY                     CONSTANT VARCHAR := '';
    cn_ZERO                      CONSTANT NUMERIC := 0;

    --Initialize the flags to be used.
    ls_item_type_flag_1          VARCHAR(01);
    ls_item_type_flag_2          VARCHAR(01);
    ls_item_class_flag_3         VARCHAR(01);
    ls_item_class_flag_4         VARCHAR(01);
    ls_demand_policy_code_flag_5 VARCHAR(01);
    ls_demand_policy_code_flag_6 VARCHAR(01);
    ls_wbin_control_code_flag_7  VARCHAR(01);
    ls_wbin_control_code_flag_8  VARCHAR(01);
    ls_airs_sign_flag_9          VARCHAR(01);
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    /* Return Value Set */
    rn_status                 := cn_STATUS_NORMAL;
    rs_sql_code               := cs_ZERO;
    rs_err_code               := cs_ZERO;
    rs_err_msg                := cs_SPACE;
    rs_err_focus              := cs_SPACE;
    rs_item_class             := cs_SPACE;
    rs_item_status            := cs_SPACE;
    rs_demand_policy_code     := cs_SPACE;
    rs_airs_sign              := cs_SPACE;
    rn_float_safety_stock_qty := cn_ZERO;
    rs_synchro_control_code   := cs_SPACE;


    /* Variable Initialization */
    ls_item_type              := cs_SPACE;
    ls_item_class             := cs_SPACE;
    ls_item_status            := cs_SPACE;
    ls_demand_policy_code     := cs_SPACE;
    ls_wbin_control_code      := cs_SPACE;
    ls_airs_sign              := cs_SPACE;
    ln_float_safety_stock_qty := cn_ZERO;
    ls_synchro_control_code   := cs_SPACE;

    /*Flag Initialization*/
    ls_item_type_flag_1          := cs_FLAG_N;
    ls_item_type_flag_2          := cs_FLAG_N;
    ls_item_class_flag_3         := cs_FLAG_N;
    ls_item_class_flag_4         := cs_FLAG_N;
    ls_demand_policy_code_flag_5 := cs_FLAG_N;
    ls_demand_policy_code_flag_6 := cs_FLAG_N;
    ls_wbin_control_code_flag_7  := cs_FLAG_N;
    ls_wbin_control_code_flag_8  := cs_FLAG_N;
    ls_airs_sign_flag_9          := cs_FLAG_N;
    --------------------------------------------------

    /* Argument Check */
       IF ps_operation_id IS NULL OR TRIM(ps_operation_id) = cs_EMPTY THEN
        rs_err_code  := cs_err_no_operation_id;
        rs_err_msg   := 'Specify the Deal Flag.' ||
                        COALESCE(ps_operation_id, 'NULL');
        rs_err_focus := 'operation_id ';
        RAISE EXCEPTION SQLSTATE 'P0001' USING MESSAGE = rs_err_msg;
    END IF;

        IF ps_itemno IS NULL OR TRIM(ps_itemno) = cs_EMPTY THEN
        rs_err_code  := cs_err_no_itemno;
        rs_err_msg   := 'Specify the Item Number' ||
                        COALESCE(ps_itemno, 'NULL');
        rs_err_focus := 'itemno';
        RAISE EXCEPTION SQLSTATE 'P0001' USING MESSAGE = rs_err_msg;
    END IF;

    IF ps_supplier IS NULL OR TRIM(ps_supplier) = cs_EMPTY THEN
        rs_err_code  := cs_err_no_supplier;
        rs_err_msg   := 'Specify the Supplier' ||
                        COALESCE(ps_supplier, 'NULL');
        rs_err_focus := 'supplier';
        RAISE EXCEPTION SQLSTATE 'P0001' USING MESSAGE = rs_err_msg;
    END IF;

    IF ps_usercd IS NULL OR TRIM(ps_usercd) = cs_EMPTY THEN
        rs_err_code  := cs_err_no_usercd;
        rs_err_msg   := 'Specify the User.' ||
                        COALESCE(ps_usercd, 'NULL');
        rs_err_focus := 'usercd';
        RAISE EXCEPTION SQLSTATE 'P0001' USING MESSAGE = rs_err_msg;
    END IF;

    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    BEGIN
        IF EXISTS( SELECT 1
                 FROM la_itemmast item
                 INNER JOIN le_mst_mrp_information mrp
                    ON mrp.itemno   = item.itemno
                   AND mrp.supplier = item.supplier
                   AND mrp.usercd   = item.usercd
                WHERE item.itemno   = ps_itemno
                  AND item.supplier = ps_supplier
                  AND item.usercd   = ps_usercd) THEN
        SELECT   item.item_type
        	    ,item.item_class
        	    ,item.item_status
                ,mrp.demand_policy_code
                ,mrp.wbin_control_code
                ,mrp.airs_sign
                ,mrp.float_safety_stock_qty
                ,mrp.synchro_control_code
          INTO 	STRICT ls_item_type
          		      ,ls_item_class
          		      ,ls_item_status
          		      ,ls_demand_policy_code
          		      ,ls_wbin_control_code
          		      ,ls_airs_sign
          		      ,ln_float_safety_stock_qty
          		      ,ls_synchro_control_code
          FROM la_itemmast item
          JOIN le_mst_mrp_information mrp
            ON mrp.itemno = item.itemno
           AND mrp.supplier = item.supplier
           AND mrp.usercd = item.usercd
         WHERE item.itemno = ps_itemno
           AND item.supplier = ps_supplier
           AND item.usercd = ps_usercd;
        ELSE
        rs_err_code  := cs_err_item_not_exist;
        rs_err_msg   := 'Item does not exist in the item master';
        rs_err_focus := 'LDAS0300';
        rn_status    := cn_STATUS_PROGRAM_ERROR;
        RETURN NEXT;
        RETURN;
        END IF;
       END;
        -- Item class check (basic validity)
        IF ls_item_class = cs_ITEM_CLASS_M OR ls_item_class = cs_ITEM_CLASS_K THEN
        rs_err_code  := cs_err_invalid_item_class;
        rs_err_msg   := 'You cannot specify Product, CBU Model or CKD Model';
        rs_err_focus := 'LDAS0300';
        RAISE EXCEPTION SQLSTATE 'P0001' USING MESSAGE = rs_err_msg;
        END IF;
        --Product status check
        IF ls_item_status = cs_ITEM_STATUS_1 THEN
        rs_err_code  := cs_err_item_status_trial;
        rs_err_msg   := 'You cannot specify the item of which Item Status is 1(Technical Trial)' ;
        rs_err_focus := 'LDAS0300';
        RAISE EXCEPTION SQLSTATE 'P0001' USING MESSAGE = rs_err_msg;
        END IF;
        --By processing the identification settings to verify the flag
        IF ps_operation_id = cs_LD11 THEN
        ls_item_type_flag_2          := cs_FLAG_Y;
        ls_demand_policy_code_flag_5 := cs_FLAG_Y;
        ls_wbin_control_code_flag_7  := cs_FLAG_Y;

        ELSIF ps_operation_id = cs_LD41 THEN
        ls_item_type_flag_2          := cs_FLAG_Y;
        ls_item_class_flag_3         := cs_FLAG_Y;
        ls_demand_policy_code_flag_5 := cs_FLAG_Y;
        ls_wbin_control_code_flag_7  := cs_FLAG_Y;

        ELSIF ps_operation_id = cs_LD71 THEN
        ls_item_type_flag_2          := cs_FLAG_Y;
        ls_item_class_flag_3         := cs_FLAG_Y;
        ls_demand_policy_code_flag_6 := cs_FLAG_Y;
        ls_wbin_control_code_flag_8  := cs_FLAG_Y;

         ELSIF ps_operation_id = cs_LD21 OR
          ps_operation_id = cs_LD15 OR ps_operation_id = cs_LD18 OR
          ps_operation_id = cs_LD28 OR ps_operation_id = cs_LD33 OR
          ps_operation_id = cs_LD46 OR ps_operation_id = cs_LD48 OR
          ps_operation_id = cs_LD52 OR ps_operation_id = cs_LD68 THEN
        ls_item_type_flag_1 := cs_FLAG_Y;

         ELSIF ps_operation_id = cs_LD14 THEN
        ls_item_type_flag_1         := cs_FLAG_Y;
        ls_wbin_control_code_flag_7 := cs_FLAG_Y;
        ls_airs_sign_flag_9         := cs_FLAG_Y;

        ELSIF ps_operation_id = cs_LD24 THEN
        ls_item_type_flag_1         := cs_FLAG_Y;
        ls_wbin_control_code_flag_7 := cs_FLAG_Y;

        ELSIF ps_operation_id = cs_LD44 THEN
        ls_item_type_flag_1 := cs_FLAG_Y;
        ls_airs_sign_flag_9 := cs_FLAG_Y;

        ELSIF ps_operation_id = cs_LD74 THEN
        ls_item_type_flag_1         := cs_FLAG_Y;
        ls_wbin_control_code_flag_8 := cs_FLAG_Y;

        ELSIF ps_operation_id = cs_LD78 OR ps_operation_id = cs_LD80 THEN
        ls_item_type_flag_2 := cs_FLAG_Y;

        ELSIF ps_operation_id = cs_LD81 THEN
        ls_item_class_flag_4 := cs_FLAG_Y;
        END IF;

     /*item_type validate*/
        IF ls_item_type_flag_1 = cs_FLAG_Y THEN
            IF ls_item_type <> cs_ITEM_TYPE_1 THEN
            rs_err_code  := cs_err_item_type_trial;
            rs_err_msg   := 'You cannot specify the item of which Item Status'||
                            ' is 1(Technical Trial) ' ;
            rs_err_focus := 'LDAS0300';
            RAISE EXCEPTION SQLSTATE 'P0001' USING MESSAGE = rs_err_msg;
            END IF;
        END IF;

          IF ls_item_type_flag_2 = cs_FLAG_Y THEN
            IF ls_item_type <> cs_ITEM_TYPE_1 AND ls_item_type <> cs_ITEM_TYPE_2 THEN
            rs_err_code  := cs_err_item_type_standard;
            rs_err_msg   := 'You can specify only the item of which Item Type' ||
                            ' is 1(Standard) or 2(B/T)' ;
            rs_err_focus := 'LDAS0300';
            RAISE EXCEPTION SQLSTATE 'P0001' USING MESSAGE = rs_err_msg;
            END IF;
        END IF;

    /*item_class  validate*/
        IF ls_item_class_flag_3 = cs_FLAG_Y THEN
            IF  ls_item_class <> cs_ITEM_CLASS_0 AND
                ls_item_class <> cs_ITEM_CLASS_1 AND
                ls_item_class <> cs_ITEM_CLASS_2 THEN
                rs_err_code  := cs_err_item_class_materials;
                rs_err_msg   := 'You can specify only the item of which Item Cl. ' ||
                            'is 0(Packing Materials) or 1(Raw Materials) or 2(Parts)  ';
                rs_err_focus := 'LDAS0300';
                RAISE EXCEPTION SQLSTATE 'P0001' USING MESSAGE = rs_err_msg;
            END IF;
        END IF;

        IF ls_item_class_flag_4 = cs_FLAG_Y THEN
            IF ls_item_class <> cs_ITEM_CLASS_E AND ls_item_class <> cs_ITEM_CLASS_F THEN
            rs_err_code  := cs_err_item_class_parts;
            rs_err_msg   := 'You cannot specify Parts';
            rs_err_focus := 'LDAS0300';
            RAISE EXCEPTION SQLSTATE 'P0001' USING MESSAGE = rs_err_msg;
            END IF;
        END IF;

    /*demand_policy_code  validate*/
        IF ls_demand_policy_code_flag_5 = cs_FLAG_Y THEN
            IF ls_demand_policy_code < cs_DEMAND_1 OR ls_demand_policy_code > cs_DEMAND_6 THEN
            rs_err_code  := cs_err_demand_policy_range;
            rs_err_msg   := 'You can specify only the item of which MRP Demand Policy Code is 1 to 6';
            rs_err_focus := 'LDAS0300';
            RAISE EXCEPTION SQLSTATE 'P0001' USING MESSAGE = rs_err_msg;
            END IF;
        END IF;

         IF ls_demand_policy_code_flag_6 = cs_FLAG_Y THEN
            IF ls_demand_policy_code <> cs_DEMAND_2 THEN
            rs_err_code  := cs_err_demand_policy_manual;
            rs_err_msg   := 'You can specify only the item of which ' ||
                            'MRP Demand Policy Code is 2(Manual Control) ';
            rs_err_focus := 'LDAS0300';
            RAISE EXCEPTION SQLSTATE 'P0001' USING MESSAGE = rs_err_msg;
            END IF;
        END IF;

    /*wbin_control_code  validate*/
    IF ls_wbin_control_code_flag_7 = cs_FLAG_Y THEN
        IF ls_wbin_control_code <> cs_WBIN_0 THEN
            rs_err_code  := cs_err_wbin_out_control;
            rs_err_msg   := 'You can specify only the item of which ' ||
                            'W-bin Control Code is 0(Out of an object of control)';
            rs_err_focus := 'LDAS0300';
            RAISE EXCEPTION SQLSTATE 'P0001' USING MESSAGE = rs_err_msg;
        END IF;
    END IF;

    IF ls_wbin_control_code_flag_8 = cs_FLAG_Y THEN
        IF ls_wbin_control_code <> cs_WBIN_1 THEN
            rs_err_code  := cs_err_wbin_in_control;
            rs_err_msg   := 'You can specify only the item of which  ' ||
                            'W-bin Control Code is 1(An object of control)';
            rs_err_focus := 'LDAS0300';
            RAISE EXCEPTION SQLSTATE 'P0001' USING MESSAGE = rs_err_msg;
        END IF;
    END IF;

    /*airs_sign validate */
    IF ls_airs_sign_flag_9 = cs_FLAG_Y THEN
        IF ls_airs_sign = cs_AIRS_1 THEN
            rs_err_code  := cs_err_airs_item;
            rs_err_msg   := 'You cannot specify AIRS Item';
            rs_err_focus := 'LDAS0300';
            RAISE EXCEPTION SQLSTATE 'P0001' USING MESSAGE = rs_err_msg;
        END IF;
    END IF;





    --------------------------------------------------
    --  < STEP3 : Return Value Processing >
    --------------------------------------------------
    rs_item_class             := ls_item_class;
    rs_item_status            := ls_item_status;
    rs_demand_policy_code     := ls_demand_policy_code;
    rs_airs_sign              := ls_airs_sign;
    rn_float_safety_stock_qty := ln_float_safety_stock_qty;
    rs_synchro_control_code   := ls_synchro_control_code;
    RETURN NEXT;
    RETURN;
    EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        rn_status   :=  cn_STATUS_PROGRAM_ERROR;
        rs_sql_code := cs_SPACE;
        RETURN NEXT;
        RETURN;
    WHEN OTHERS THEN
        rn_status    := cn_STATUS_SQL_ERROR;
        rs_sql_code  := SQLSTATE;
        rs_err_code  := cs_SPACE;
        rs_err_msg   := SQLERRM;
        rs_err_focus := cs_SPACE;
        RETURN NEXT;
        RETURN;
END;
$BODY$
LANGUAGE 'plpgsql';

