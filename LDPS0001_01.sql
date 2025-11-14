--------------------------------------------------------------------------------
--@SEE << subroutine subordinate required detail delete process >>
--    @ID      : LDPS0001_01
--
--    @Written : 1.0.0                   2025.10.23 LiuBinhong / YMSLX
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
--    @ps_itemno                <I/ > VARCHAR
--    @ps_supplier              <I/ > VARCHAR
--    @ps_usercd                <I/ > VARCHAR
--    @ps_orderno               <I/ > VARCHAR
--    @ps_structure_seq         <I/ > VARCHAR
--    @ps_c_itemno              <I/ > VARCHAR
--    @ps_c_supplier            <I/ > VARCHAR
--    @ps_c_usercd              <I/ > VARCHAR
--    @pd_maintenance_datetime  <I/ > TIMESTAMP
--    @ps_order_status          <I/ > VARCHAR
--    @ps_start_date            <I/ > VARCHAR
--    @pn_required_qty          <I/ > DECIMAL
--    @pn_delivery_qty          <I/ > DECIMAL
--    @ps_in_effective_date     <I/ > VARCHAR
--    @ps_out_effective_date    <I/ > VARCHAR
--    @ps_comp_sign             <I/ > VARCHAR
--    @pn_option_percent        <I/ > DECIMAL
--    @ps_message_code          <I/ > VARCHAR
--    @ps_disburse_date         <I/ > VARCHAR
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
--    @rn_cnt_ins_lg            < /O> INTEGER   : Count of Inserted Logs
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDPS0001_01 (
    ps_itemno               VARCHAR
   ,ps_supplier             VARCHAR
   ,ps_usercd               VARCHAR
   ,ps_orderno              VARCHAR
   ,ps_structure_seq        VARCHAR
   ,ps_c_itemno             VARCHAR
   ,ps_c_supplier           VARCHAR
   ,ps_c_usercd             VARCHAR
   ,pd_maintenance_datetime TIMESTAMP
   ,ps_order_status         VARCHAR
   ,ps_start_date           VARCHAR
   ,pn_required_qty         DECIMAL
   ,pn_delivery_qty         DECIMAL
   ,ps_in_effective_date    VARCHAR
   ,ps_out_effective_date   VARCHAR
   ,ps_comp_sign            VARCHAR
   ,pn_option_percent       DECIMAL
   ,ps_message_code         VARCHAR
   ,ps_disburse_date        VARCHAR
)
RETURNS TABLE (
    rn_status      INTEGER
   ,rs_sql_code    VARCHAR
   ,rs_err_code    VARCHAR
   ,rs_err_msg     VARCHAR
   ,rs_err_focus   VARCHAR
   ,rn_cnt_ins_lg  INTEGER
)
LANGUAGE plpgsql
AS $BODY$
DECLARE
    --------------------------------------------------
    --  < Definition Local Parameter >
    --------------------------------------------------
    cs_space               CONSTANT VARCHAR := ' ';
    cs_system_author       CONSTANT VARCHAR := 'IC_REV';
    cs_program_id          CONSTANT VARCHAR := 'LDPS0001_01';
    cs_add_del_sign        CONSTANT VARCHAR := '3';
    cn_zero                CONSTANT INTEGER := 0;
    cn_list_flag           CONSTANT INTEGER := 1;

    -- Working variables
    ls_charge_section       VARCHAR;
    ls_charge_person        VARCHAR;
    ln_log_insert_count     INTEGER;
    ln_sp_status            INTEGER;
    ls_sp_sql_code          VARCHAR;  -- external SP sql code or state
    ls_sp_err_code          VARCHAR;  -- external SP error code
    ls_sp_err_msg           VARCHAR;  -- external SP error message
    ls_sp_err_focus         VARCHAR;  -- external SP error focus
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    /* Initialize return values */
    rn_status     := 0;
    rs_sql_code   := cs_space;
    rs_err_code   := cs_space;
    rs_err_msg    := cs_space;
    rs_err_focus  := cs_space;
    rn_cnt_ins_lg := 0;
    ln_log_insert_count := 0;
    --------------------------------------------------------------------------
    -- STEP 2 : Main Process
    --------------------------------------------------------------------------
    SELECT LDAS0417.rn_status
         , LDAS0417.rs_sql_code
         , LDAS0417.rs_err_code
         , LDAS0417.rs_err_msg
         , LDAS0417.rs_err_focus
      INTO ln_sp_status
         , ls_sp_sql_code
         , ls_sp_err_code
         , ls_sp_err_msg
         , ls_sp_err_focus
      FROM LDAS0417(
            ps_itemno
           ,ps_supplier
           ,ps_usercd
           ,ps_orderno
           ,ps_c_itemno
           ,ps_c_supplier
           ,ps_c_usercd
           ,ps_structure_seq
           ,cs_system_author
      );

    IF ln_sp_status <> 0 THEN
        rs_err_code  := 'ld.E.LDP10150';
        rs_err_msg   := '<<SP:LDAS0417 Error Return>>' || 'Return:  ' || ln_sp_status || ','|| ls_sp_sql_code || ','
                        || ls_sp_err_code || ','|| ls_sp_err_msg || ','|| ls_sp_err_focus;
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_order_status IN ('1', '2') THEN
        IF EXISTS (
            SELECT 1
              FROM la_area_master_su a
              JOIN la_area_master b 
                ON a.area_code = b.area_code
             WHERE a.su_code = ps_c_supplier
        ) THEN
            SELECT b.area_section_code
                 , b.area_person_code
              INTO STRICT ls_charge_section
                 , ls_charge_person
              FROM la_area_master_su a
              JOIN la_area_master b 
                ON a.area_code = b.area_code
             WHERE a.su_code   = ps_c_supplier;
        ELSE
            ls_charge_section := cs_space;
            ls_charge_person  := cs_space;
        END IF;

    --------------------------------------------------------------------------
    -- Insert log
    --------------------------------------------------------------------------
        INSERT INTO ld_trn_reqchg_log (
              add_del_sign
            , parent_itemno
            , parent_supplier
            , parent_usercd
            , parent_disburse_date
            , order_no
            , structure_seq
            , comp_itemno
            , comp_supplier
            , comp_usercd
            , maintenance_datetime
            , list_flg
            , message_code
            , org_section_mrp
            , org_person_mrp
            , order_status
            , start_date
            , required_qty
            , out_qty
            , in_effective_ymd
            , out_effective_ymd
            , comp_sign
            , comp_op_percent
            , update_counter
            , create_datetime
            , create_author
            , create_pgmid
            , update_datetime
            , update_author
            , update_pgmid
        ) VALUES (
              cs_add_del_sign
            , ps_itemno
            , ps_supplier
            , ps_usercd
            , ps_disburse_date
            , ps_orderno
            , ps_structure_seq
            , ps_c_itemno
            , ps_c_supplier
            , ps_c_usercd
            , pd_maintenance_datetime
            , cn_list_flag
            , ps_message_code
            , ls_charge_section
            , ls_charge_person
            , ps_order_status
            , ps_start_date
            , pn_required_qty
            , pn_delivery_qty
            , ps_in_effective_date
            , ps_out_effective_date
            , ps_comp_sign
            , pn_option_percent
            , cn_zero
            , CURRENT_TIMESTAMP
            , cs_system_author
            , cs_program_id
            , CURRENT_TIMESTAMP
            , cs_system_author
            , cs_program_id
        );
        ln_log_insert_count := ln_log_insert_count + 1;
    END IF;

    --------------------------------------------------
    --  < STEP3 : Return Value Processing >
    --------------------------------------------------
    rn_cnt_ins_lg := ln_log_insert_count;
    RETURN NEXT;
    RETURN;
EXCEPTION
    WHEN RAISE_EXCEPTION THEN
        IF rn_status <> 0 THEN  -- FOR CALL SP ERROR
            NULL;
        ELSE                    -- FOR PGM ERROR
            rn_status     :=  -2;
            rs_sql_code   := cs_space;
        END IF;

        rs_err_focus      := cs_program_id;
        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN            -- FOR SQL ERROR
        rn_status         := -1;    
        rs_sql_code       := SQLSTATE;
        rs_err_code       := cs_space;
        rs_err_msg        := SQLERRM;
        rs_err_focus      := cs_program_id;

        RETURN NEXT;
        RETURN;
END;
$BODY$
;