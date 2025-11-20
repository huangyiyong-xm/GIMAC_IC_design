--------------------------------------------------------------------------------
--@SEE << IC Main Proc - Airs Sign Change >>
--    @ID      : LDPS0004
--
--    @Written : 1.0.0                   2025.10.15 Zhang Yulin / YMSLX
--    --------------------------------------------------------------------------
--    @Update  : xxxxxxxxxxxx            xxxx.xx.xx xxxxxxxx / xx
--     Reason  : xxx
--              xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--------------------------------------------------------------------------------
--  < INPUT Parameter >
--    (none)
--  < OUTPUT Parameter >
--    @rn_status                   < /O> INTEGER   : Return Code
--                                                   (  0 : Normal        )
--                                                   ( -1 : Sql Error     )
--                                                   ( -2 : Program Error )
--                                                   (100 : NotDataFound  )
--    @rs_sql_code                 < /O> VARCHAR   : Sql Error Code
--    @rs_err_code                 < /O> VARCHAR   : Program Error Code
--    @rs_err_msg                  < /O> VARCHAR   : Error Message
--    @rs_err_focus                < /O> VARCHAR   : Error Focus
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDPS0004()
RETURNS TABLE(
    rn_status           INTEGER,              --1. 処理ステータス
    rs_sql_code         VARCHAR,              --2. SQLコード
    rs_err_code         VARCHAR,              --3. エラーコード
    rs_err_msg          VARCHAR,              --4. エラーメッセージ
    rs_err_focus        VARCHAR               --5. エラー位置
) AS
$BODY$
DECLARE
    --------------------------------------------------
    --  < Definition Local Paramater >
    --------------------------------------------------
    cs_pgmid                    CONSTANT VARCHAR(8)   := 'LDPS0004';
    cs_space                    CONSTANT VARCHAR(1)   := ' ';

    ls_parent_itemno            ld_trn_derev_trn.parent_itemno%TYPE;
    ls_parent_supplier          ld_trn_derev_trn.parent_supplier%TYPE;
    ls_parent_usercd            ld_trn_derev_trn.parent_usercd%TYPE;
    ls_structure_seq            ld_trn_derev_trn.structure_seq%TYPE;
    ls_comp_itemno              ld_trn_derev_trn.comp_itemno%TYPE;
    ls_comp_supplier            ld_trn_derev_trn.comp_supplier%TYPE;
    ls_comp_usercd              ld_trn_derev_trn.comp_usercd%TYPE;
    ls_message_code             ld_trn_derev_trn.message_code%TYPE;
    ldt_maintenance_datetime    ld_trn_derev_trn.maintenance_datetime%TYPE;
    ls_airs_sign                le_mst_mrp_information.airs_sign%TYPE;
    ls_target_item_flag         VARCHAR;

    ln_derev_trn_read_count     INTEGER;
-- 2025/11/19 YMSLX Zhang Yulin DEL
/*
    -- Variables for delete function return
    ln_del_status               INTEGER;
    ls_del_sql_code             VARCHAR;
    ls_del_err_code             VARCHAR;
    ls_del_err_msg              VARCHAR;
    ls_del_err_focus            VARCHAR;
*/
-- 2025/11/19 YMSLX Zhang Yulin DEL
    rec_derev_trn               RECORD;
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    rn_status                   := 0;
    rs_sql_code                 := cs_space;
    rs_err_code                 := cs_space;
    rs_err_msg                  := cs_space;
    rs_err_focus                := cs_space;


    ls_parent_itemno            := cs_space;
    ls_parent_supplier          := cs_space;
    ls_parent_usercd            := cs_space;
    ls_structure_seq            := cs_space;
    ls_comp_itemno              := cs_space;
    ls_comp_supplier            := cs_space;
    ls_comp_usercd              := cs_space;
    ls_message_code             := cs_space;
    ldt_maintenance_datetime    := NULL;
    ls_airs_sign                := cs_space;
    ls_target_item_flag         := cs_space;
    ln_derev_trn_read_count     := 0;

    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    FOR rec_derev_trn IN
        SELECT t.parent_itemno
             , t.parent_supplier
             , t.parent_usercd
             , t.structure_seq
             , t.comp_itemno
             , t.comp_supplier
             , t.comp_usercd
             , t.message_code
             , t.maintenance_datetime
             , t.airs_sign
          FROM ld_trn_derev_trn AS t
         WHERE t.close_sign    = '0'
           AND t.message_code  = '300'
    LOOP
        ln_derev_trn_read_count := ln_derev_trn_read_count + 1;

        -- Assign record values to variables
        ls_parent_itemno         := rec_derev_trn.parent_itemno;
        ls_parent_supplier       := rec_derev_trn.parent_supplier;
        ls_parent_usercd         := rec_derev_trn.parent_usercd;
        ls_structure_seq         := rec_derev_trn.structure_seq;
        ls_comp_itemno           := rec_derev_trn.comp_itemno;
        ls_comp_supplier         := rec_derev_trn.comp_supplier;
        ls_comp_usercd           := rec_derev_trn.comp_usercd;
        ls_message_code          := rec_derev_trn.message_code;
        ldt_maintenance_datetime := rec_derev_trn.maintenance_datetime;
        ls_airs_sign             := rec_derev_trn.airs_sign;

        -- Check if target item exists in MRP information
        IF EXISTS (
            SELECT 1
              FROM le_mst_mrp_information
             WHERE itemno    = ls_parent_itemno
               AND supplier  = ls_parent_supplier
               AND usercd    = ls_parent_usercd
               AND airs_sign = '1'
        ) THEN
            SELECT airs_sign
              INTO ls_airs_sign
              FROM le_mst_mrp_information
             WHERE itemno    = ls_parent_itemno
               AND supplier  = ls_parent_supplier
               AND usercd    = ls_parent_usercd
               AND airs_sign = '1';

            ls_target_item_flag := '1';
        ELSE
            ls_target_item_flag := '0';
        END IF;
-- 2025/11/19 YMSLX Zhang Yulin DEL
/*
        -- Delete current product ticket data if conditions met
        IF ls_target_item_flag = '1' AND ls_parent_supplier <> ls_parent_usercd AND ls_airs_sign = '1' THEN
            SELECT t.rn_status
                  ,t.rs_sql_code
                  ,t.rs_err_code
                  ,t.rs_err_msg
                   ,t.rs_err_focus
              INTO ln_del_status
                  ,ls_del_sql_code
                  ,ls_del_err_code
                  ,ls_del_err_msg
                  ,ls_del_err_focus
              FROM LDAS0439(
                  ls_parent_itemno
                  ,ls_parent_supplier
                  ,ls_parent_usercd
                  ,'1'
              ) AS t;

            IF ln_del_status <> 0 THEN
                rn_status     := ln_del_status;
                rs_sql_code   := ls_del_sql_code;
                rs_err_code   := ls_del_err_code;
                rs_err_msg    := ' ' || '<<SP ld0slb111 Error Return>>' || 'Return:     ' || ln_del_status || ',' || ls_del_sql_code || ',' || ls_del_err_code || ',' || ls_del_err_msg || ',' || ls_del_err_focus;
                rs_err_focus  := ls_del_err_focus;
                RETURN NEXT;
                RETURN;
            END IF;
        END IF;
*/
-- 2025/11/19 YMSLX Zhang Yulin DEL
        UPDATE ld_trn_derev_trn
           SET close_sign           = '1'
             , update_author        = cs_pgmid
             , update_counter       = update_counter + 1
             , update_datetime      = CURRENT_TIMESTAMP
             , update_pgmid         = cs_pgmid
         WHERE close_sign           = '0'
           AND parent_itemno        = ls_parent_itemno
           AND parent_supplier      = ls_parent_supplier
           AND parent_usercd        = ls_parent_usercd
           AND structure_seq        = ls_structure_seq
           AND comp_itemno          = ls_comp_itemno
           AND comp_supplier        = ls_comp_supplier
           AND comp_usercd          = ls_comp_usercd
           AND message_code         = ls_message_code
           AND maintenance_datetime = ldt_maintenance_datetime;

    END LOOP;

    -- Output processing count
    RAISE NOTICE '<ld_trn_derev_trn> Read Count  = % Normal End.', ln_derev_trn_read_count;
    --------------------------------------------------
    --  < STEP3 : Return Value Setting >
    --------------------------------------------------
    RETURN NEXT;
    RETURN;

EXCEPTION
    --------------------------------------------------
    --  Error Handle
    --------------------------------------------------
    WHEN RAISE_EXCEPTION THEN
        IF rn_status <> 0 THEN  -- FOR CALL SP ERROR
            NULL;
        ELSE                    -- FOR PGM ERROR
            rn_status     :=  -2;
            rs_sql_code   := cs_space;
        END IF;

        rs_err_focus      := cs_pgmid;
        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN            -- FOR SQL ERROR
        rn_status         := -1;
        rs_sql_code       := SQLSTATE;
        rs_err_code       := cs_space;
        rs_err_msg        := SQLERRM;
        rs_err_focus      := cs_pgmid;

        RETURN NEXT;
        RETURN;
END;
$BODY$
LANGUAGE plpgsql;
