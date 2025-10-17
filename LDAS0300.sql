--------------------------------------------------------------------------------
--    @SEE << Valid/Compliance Check of Categories >>
--    @ID      : LDAS0300
--
--    @Written : 1.0.0                   2012.07.27 YangMeng / YMSLX
--    @Written : 1.0.0                   2017.02.01 Y.Mochiduki / YMSL
--    --------------------------------------------------------------------------
--    @Update  : xxxxxxxxxxxx            xxxx.xx.xx xxxxxxxx / xx
--     Reason  : xxx
--              xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--
--------------------------------------------------------------------------------
--@SEE < Valid/Compliance Check of Categories >
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
CREATE OR REPLACE FUNCTION gimac.ldas0300(ps_operation_id character varying, ps_itemno character varying, ps_supplier character varying, ps_usercd character varying)
 RETURNS TABLE(rn_status integer, rs_sql_code character varying, rs_err_code character varying, rs_err_msg character varying, rs_err_focus character varying, rs_item_class character varying, rs_item_status character varying, rs_demand_policy_code character varying,rs_airs_sign character varying, rn_float_safety_stock_qty numeric, rs_synchro_control_code character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    ls_item_type                 gimac.la_itemmast.item_type%TYPE;
    ls_item_class                gimac.la_itemmast.item_class%TYPE;
    ls_item_status               gimac.la_itemmast.item_status%TYPE;
    ls_demand_policy_code        gimac.le_mst_mrp_information.demand_policy_code%TYPE;
    ls_wbin_control_code         gimac.le_mst_mrp_information.wbin_control_code%TYPE;
    ls_airs_sign                 gimac.le_mst_mrp_information.airs_sign%TYPE;
    ld_float_safety_stock_qty    gimac.le_mst_mrp_information.float_safety_stock_qty%TYPE;
    ls_synchro_control_code      gimac.le_mst_mrp_information.synchro_control_code%TYPE;
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
    rn_status                 :=   0;
    rs_sql_code               := '0';
    rs_err_code               := '0';
    rs_err_msg                := ' ';
    rs_err_focus              := ' ';
    rs_item_class             := ' ';
    rs_item_status            := ' ';
    rs_demand_policy_code     := ' ';
    rs_airs_sign              := ' ';
    rn_float_safety_stock_qty :=   0;
    rs_synchro_control_code   := ' ';


    /* Variable Initialization */
    ls_item_type              := ' ';
    ls_item_class             := ' ';
    ls_item_status            := ' ';
    ls_demand_policy_code     := ' ';
    ls_wbin_control_code      := ' ';
    ls_airs_sign              := ' ';
    ld_float_safety_stock_qty :=   0;
    ls_synchro_control_code   := ' ';

    /*Flag Initialization*/
    ls_item_type_flag_1          := 'N';
    ls_item_type_flag_2          := 'N';
    ls_item_class_flag_3         := 'N';
    ls_item_class_flag_4         := 'N';
    ls_demand_policy_code_flag_5 := 'N';
    ls_demand_policy_code_flag_6 := 'N';
    ls_wbin_control_code_flag_7  := 'N';
    ls_wbin_control_code_flag_8  := 'N';
    ls_airs_sign_flag_9          := 'N';
    --------------------------------------------------

    /* Argument Check */
    IF ps_operation_id IS NULL OR TRIM(ps_operation_id) = '' THEN
        rs_err_code  := 'E.LDP10914';
        rs_err_msg   := '処理識別を指定してください。' ||
                        COALESCE(ps_operation_id, 'NULL');
        rs_err_focus := 'operation_id ';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_itemno IS NULL OR TRIM(ps_itemno) = '' THEN
        rs_err_code  := 'E.LDP10915';
        rs_err_msg   := '品目番号を指定してください。' ||
                        COALESCE(ps_itemno, 'NULL');
        rs_err_focus := 'itemno';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_supplier IS NULL OR TRIM(ps_supplier) = '' THEN
        rs_err_code  := 'E.LDP10893';
        rs_err_msg   := '供給者を指定してください。' ||
                        COALESCE(ps_supplier, 'NULL');
        rs_err_focus := 'supplier';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_usercd IS NULL OR TRIM(ps_usercd) = '' THEN
        rs_err_code  := 'E.LDP10895';
        rs_err_msg   := '使用者を指定してください。' ||
                        COALESCE(ps_usercd, 'NULL');
        rs_err_focus := 'usercd';
        RAISE EXCEPTION ' ';
    END IF;

    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    -- Item master existence check (SELECT INTO, not EXISTS)
    BEGIN
        IF EXISTS( SELECT 1
                 FROM la_itemmast     item      
                     ,le_mst_mrp_information mrp         
                WHERE  mrp.itemno        = item.itemno
                  AND mrp.supplier      = item.supplier
                  AND mrp.usercd        = item.usercd
                  AND item.itemno       = ps_itemno
                  AND item.supplier     = ps_supplier
                  AND item.usercd       = ps_usercd) THEN
        SELECT 	 item.item_type 
        		,item.item_class
        		,item.item_status
               	,mrp.demand_policy_code 
               	,mrp.wbin_control_code
               	,mrp.airs_sign
               	,mrp.float_safety_stock_qty
               	,mrp.synchro_control_code
          INTO 	 ls_item_type
          		,ls_item_class
          		,ls_item_status
          		,ls_demand_policy_code
          		,ls_wbin_control_code
          		,ls_airs_sign
          		,ld_float_safety_stock_qty
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
        rs_err_code  := 'E.LDP10003';
        rs_err_msg   := '指定品目が品目マスタに存在しません。';
        rs_err_focus := 'itemno';
        rn_status    := -2;
        RETURN NEXT;
        RETURN;
        end IF;
       end;
        -- Item class check (basic validity)
        IF ls_item_class = 'M' OR ls_item_class = 'K' THEN
        rs_err_code  := 'E.LDP10423';
        rs_err_msg   := '商品・ＣＢＵ機種・ＣＫＤ機種品目は指定不可です。';
        rs_err_focus := 'itemno';
        RAISE EXCEPTION ' ';
        END IF;
        --Product status check
        IF ls_item_status = '1' THEN
        rs_err_code  := 'E.LDP10410';
        rs_err_msg   := '品目ステータス＝１（技術試作）の品目は指定不可です。' ;
        rs_err_focus := 'itemno';
        RAISE EXCEPTION ' ';
        END IF;
        --By processing the identification settings to verify the flag
        IF ps_operation_id = 'LD11' THEN
        ls_item_type_flag_2          := 'Y';
        ls_demand_policy_code_flag_5 := 'Y';
        ls_wbin_control_code_flag_7  := 'Y';

     ELSIF ps_operation_id = 'LD41' THEN
        ls_item_type_flag_2          := 'Y';
        ls_item_class_flag_3         := 'Y';
        ls_demand_policy_code_flag_5 := 'Y';
        ls_wbin_control_code_flag_7  := 'Y';

        ELSIF ps_operation_id = 'LD71' THEN
        ls_item_type_flag_2          := 'Y';
        ls_item_class_flag_3         := 'Y';
        ls_demand_policy_code_flag_6 := 'Y';
        ls_wbin_control_code_flag_8  := 'Y';

        ELSIF ps_operation_id = 'LD21' OR
          ps_operation_id = 'LD15' OR ps_operation_id = 'LD18' OR
          ps_operation_id = 'LD28' OR ps_operation_id = 'LD33' OR
          ps_operation_id = 'LD46' OR ps_operation_id = 'LD48' OR
          ps_operation_id = 'LD52' OR ps_operation_id = 'LD68' THEN
        ls_item_type_flag_1 := 'Y';

        ELSIF ps_operation_id = 'LD14' THEN
        ls_item_type_flag_1         := 'Y';
        ls_wbin_control_code_flag_7 := 'Y';
        ls_airs_sign_flag_9         := 'Y';

        ELSIF ps_operation_id = 'LD24' THEN
        ls_item_type_flag_1         := 'Y';
        ls_wbin_control_code_flag_7 := 'Y';

        ELSIF ps_operation_id = 'LD44' THEN
        ls_item_type_flag_1 := 'Y';
        ls_airs_sign_flag_9 := 'Y';

        ELSIF ps_operation_id = 'LD74' THEN
        ls_item_type_flag_1         := 'Y';
        ls_wbin_control_code_flag_8 := 'Y';

        ELSIF ps_operation_id = 'LD78' OR ps_operation_id = 'LD80' THEN
        ls_item_type_flag_2 := 'Y';

        ELSIF ps_operation_id = 'LD81' THEN
        ls_item_class_flag_4 := 'Y';
        END IF;

     /*item_type validate*/
        IF ls_item_type_flag_1 = 'Y' THEN
            IF ls_item_type <> '1' THEN
            rs_err_code  := 'E.LDP10406';
            rs_err_msg   := '品目ステータス＝１（技術試作）の品目は指定不可です。 ' ;
            rs_err_focus := 'itemno';
            RAISE EXCEPTION ' ';
            END IF;
        END IF;

        IF ls_item_type_flag_2 = 'Y' THEN 
            IF ls_item_type <> '1' AND ls_item_type <> '2' THEN
            rs_err_code  := 'E.LDP10407';
            rs_err_msg   := '品目タイプ＝１（標準）、 ' ||
                            '２（通過）の品目のみ指定可能です';
            rs_err_focus := 'itemno';
            RAISE EXCEPTION ' ';
            END IF;
        END IF;

    /*item_class  validate*/
        IF ls_item_class_flag_3 = 'Y' THEN
            IF ls_item_class <> '0' AND
           ls_item_class <> '1' AND
           ls_item_class <> '2' THEN
            rs_err_code  := 'E.LDP10408';
            rs_err_msg   := '品目クラス＝０（梱包資材）、 ' ||
                            '１（原材料）、 ' ||
                            '- - - ２（部品）の品目のみ指定可能です)';
            rs_err_focus := 'itemno';
            RAISE EXCEPTION ' ';
            END IF;
        END IF;

        IF ls_item_class_flag_4 = 'Y' THEN
            IF ls_item_class <> 'E' AND ls_item_class <> 'F' THEN
            rs_err_code  := 'E.LDP10501';
            rs_err_msg   := '部品は指定不可です';
            rs_err_focus := 'itemno';
            RAISE EXCEPTION ' ';
            END IF;
        END IF;
    
    /*demand_policy_code  validate*/
        IF ls_demand_policy_code_flag_5 = 'Y' THEN
            IF ls_demand_policy_code <'1' OR ls_demand_policy_code > '6' THEN
            rs_err_code  := 'E.LDP10412';
            rs_err_msg   := 'ＭＲＰ需要方針コード＝１～６の品目のみ指定可能です';
            rs_err_focus := 'itemno';
            RAISE EXCEPTION ' ';
            END IF;
        END IF;

        IF ls_demand_policy_code_flag_6 = 'Y' THEN
            IF ls_demand_policy_code <> '2' THEN
            rs_err_code  := 'E.LDP10414';
            rs_err_msg   := 'ＭＲＰ需要方針コード＝２（管理対象外） ' ||
                            'の品目のみ指定可能です';
            rs_err_focus := 'itemno';
            RAISE EXCEPTION ' ';
            END IF;
        END IF;

    /*wbin_control_code  validate*/
    IF ls_wbin_control_code_flag_7 = 'Y' THEN
        IF ls_wbin_control_code <> '0' THEN
            rs_err_code  := 'E.LDP10415';
            rs_err_msg   := 'Ｗビン管理コード＝０（管理対象外）' ||
                            'の品目のみ指定可能です';
            rs_err_focus := 'itemno';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    IF ls_wbin_control_code_flag_8 = 'Y' THEN
        IF ls_wbin_control_code <> '1' THEN
            rs_err_code  := 'E.LDP10416';
            rs_err_msg   := 'Ｗビン管理コード＝１（管理対象） ' ||
                            'の品目のみ指定可能です';
            rs_err_focus := 'itemno';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;

    /*airs_sign validate */
    IF ls_airs_sign_flag_9 = 'Y' THEN
        IF ls_airs_sign = '1' THEN
            rs_err_code  := 'E.LDP10420';
            rs_err_msg   := 'ＡＩＲＳ品目は指定できません';
            rs_err_focus := 'itemno';
            RAISE EXCEPTION ' ';
        END IF;
    END IF;



    

    --------------------------------------------------
    --  < STEP3 : Return Value Processing >
    --------------------------------------------------
    rs_item_class             := ls_item_class;
    rs_item_status            := ls_item_status;
    rs_demand_policy_code     := ls_demand_policy_code;
    rs_airs_sign              := ls_airs_sign;
    rn_float_safety_stock_qty := ld_float_safety_stock_qty;
    rs_synchro_control_code   := ls_synchro_control_code;
    RETURN NEXT;
    RETURN;
    EXCEPTION
    WHEN RAISE_EXCEPTION THEN
        rn_status   :=  -2;
        rs_sql_code := ' ';
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
