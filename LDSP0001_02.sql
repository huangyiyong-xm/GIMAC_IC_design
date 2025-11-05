-------------------------------------------------------------------------------
--@SEE << Additional Processing Of Dependent Quantity Details >>
--    @ID      : LDPS0001_02
--
--    @Written : 1.0.0                   2025.10.22 GuoYiFeng / YMSLX
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
--    @ps_parent_itemno                        <I/ > VARCHAR
--    @ps_parent_supplier                      <I/ > VARCHAR
--    @ps_parent_usercd                        <I/ > VARCHAR
--    @ps_order_no                             <I/ > VARCHAR
--    @ps_comp_itemno                          <I/ > VARCHAR
--    @ps_comp_supplier                        <I/ > VARCHAR
--    @ps_comp_usercd                          <I/ > VARCHAR
--    @pd_maintenance_datetime                 <I/ > TIMESTAMP
--    @ps_structure_seq                        <I/ > VARCHAR
--    @ps_order_through_no                     <I/ > VARCHAR
--    @ps_order_through_no_source_flg          <I/ > VARCHAR
--    @ps_start_date                           <I/ > VARCHAR
--    @ps_start_shift_no                       <I/ > VARCHAR
--    @ps_rls_start_date                       <I/ > VARCHAR
--    @ps_strc_lt_onset_start_date             <I/ > VARCHAR
--    @ps_strc_lt_onset_start_time_shift_no    <I/ > VARCHAR
--    @ps_order_status                         <I/ > VARCHAR
--    @ps_pilot_class                          <I/ > VARCHAR
--    @ps_item_type                            <I/ > VARCHAR
--    @ps_comp_type                            <I/ > VARCHAR
--    @ps_comp_sign                            <I/ > VARCHAR
--    @ps_req_issue_control                    <I/ > VARCHAR
--    @pn_comp_qty                             <I/ > DECIMAL
--    @ps_comp_qty_type                        <I/ > VARCHAR
--    @ps_strc_lt_proc_no                      <I/ > VARCHAR
--    @pn_comp_op_percent                      <I/ > DECIMAL
--    @pn_order_qty                            <I/ > DECIMAL
--    @pn_receipt_qty                          <I/ > DECIMAL
--    @pn_scrap_qty                            <I/ > DECIMAL
--    @ps_parent_disburse_date                 <I/ > VARCHAR
--    @ps_message_code                         <I/ > VARCHAR
--    @ps_in_effective_date                    <I/ > VARCHAR
--    @ps_out_effective_date                   <I/ > VARCHAR
--  < OUTPUT Parameter >
--   @rn_status                 < /O> INTEGER   : Return Code
--                                                (  0 : Normal     )
--                                                (100 : Not Found  )
--                                                ( -1 : Sql Error  )
--                                                ( -2 : PG Error   )
--    @rs_sql_code              < /O> VARCHAR   : Sql Error Code
--    @rs_err_code              < /O> VARCHAR   : Program Error Code
--    @rs_err_msg               < /O> VARCHAR   : Error Message
--    @rn_cnt_ins_lg            < /O> VARCHAR   : Error Message
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION LDPS0001_02(
    ps_parent_itemno                         VARCHAR
    ,ps_parent_supplier                      VARCHAR
    ,ps_parent_usercd                        VARCHAR
    ,ps_order_no                             VARCHAR
    ,ps_comp_itemno                          VARCHAR
    ,ps_comp_supplier                        VARCHAR
    ,ps_comp_usercd                          VARCHAR
    ,pd_maintenance_datetime                 TIMESTAMP
    ,ps_structure_seq                        VARCHAR
    ,ps_order_through_no                     VARCHAR
    ,ps_order_through_no_source_flg          VARCHAR
    ,ps_start_date                           VARCHAR
    ,ps_start_shift_no                       VARCHAR
    ,ps_rls_start_date                       VARCHAR
    ,ps_strc_lt_onset_start_date             VARCHAR
    ,ps_strc_lt_onset_start_time_shift_no    VARCHAR
    ,ps_order_status                         VARCHAR
    ,ps_pilot_class                          VARCHAR
    ,ps_item_type                            VARCHAR
    ,ps_comp_type                            VARCHAR
    ,ps_comp_sign                            VARCHAR
    ,ps_req_issue_control                    VARCHAR
    ,pn_comp_qty                             DECIMAL
    ,ps_comp_qty_type                        VARCHAR
    ,ps_strc_lt_proc_no                      VARCHAR
    ,pn_comp_op_percent                      DECIMAL
    ,pn_order_qty                            DECIMAL
    ,pn_receipt_qty                          DECIMAL
    ,pn_scrap_qty                            DECIMAL
    ,ps_parent_disburse_date                 VARCHAR
    ,ps_message_code                         VARCHAR
    ,ps_in_effective_date                    VARCHAR
    ,ps_out_effective_date                   VARCHAR
)
RETURNS TABLE (
    rn_status              INTEGER
    ,rs_sql_code           VARCHAR
    ,rs_err_code           VARCHAR
    ,rs_err_msg            VARCHAR
    ,rs_err_focus          VARCHAR
    ,rn_cnt_ins_lg         INTEGER
)AS 
$BODY$
DECLARE
    --------------------------------------------------
    --  < Definition Local Paramater >
    --------------------------------------------------
    -- Constants
    cs_author                 CONSTANT VARCHAR(10) := 'IC_REV';
    cs_program_id             CONSTANT VARCHAR(20) := 'LDPS0001_02';
    cs_add_sign               CONSTANT VARCHAR(1)  := '1';
    cs_list_flg               CONSTANT VARCHAR(1)  := '1';
    cn_insert_count           CONSTANT INTEGER     := 1;

    -- System variables
    ld_system_time          TIMESTAMP := CURRENT_TIMESTAMP;

    -- Local variables for processing
    ls_department           VARCHAR;
    ls_responsible_person   VARCHAR;
    ln_log_insert_count     INTEGER;
    ls_item_class           VARCHAR;
    ln_required_qty         DECIMAL;
    ln_issued_qty           DECIMAL;

    -- Record type for function calls
    rec_ldys0002_result     RECORD;
    rec_ldas0416_result     RECORD;
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    /* Initialize return values */
    rn_status              := 0;
    rs_sql_code            := ' ';
    rs_err_code            := ' ';
    rs_err_msg             := ' ';
    rs_err_focus           := ' ';
    rn_cnt_ins_lg          := 0;
    ls_department          := ' ';
    ls_responsible_person  := ' ';
    ln_log_insert_count    := 0;
    ln_required_qty        := 0;
    ln_issued_qty          := 0;

--------------------------------------------------
--  < STEP2 : Main Process >
--------------------------------------------------
--------------------------------------------------
--  < STEP2.1 : Obtain item category >
--------------------------------------------------
  SELECT 
        item_class 
    INTO ls_item_class
    FROM la_itemmast
   WHERE itemno   = ps_comp_itemno
     AND supplier = ps_comp_supplier
     AND usercd   = ps_comp_usercd;
    IF NOT FOUND THEN
        rs_err_code  := 'ld.E.LDP10149';
        rs_err_msg   := 'Data does not exist in the la_itemmast. Item No:' || ps_comp_itemno || 
                       ' Supplier:' || ps_comp_supplier || ' User CD:' || ps_comp_usercd;
        RAISE EXCEPTION ' ';
    END IF;

    --------------------------------------------------
    --  < STEP2.2 : Call LDYS0002 to calculate the demand quantity >
    --------------------------------------------------
    SELECT 
         LDYS0002.rn_status
        ,LDYS0002.rs_sql_code
        ,LDYS0002.rs_err_code
        ,LDYS0002.rs_err_msg
        ,LDYS0002.rs_err_focus
        ,LDYS0002.rn_compqty
     INTO rec_ldys0002_result
     FROM LDYS0002(
         pn_order_qty
        ,ps_comp_sign
        ,pn_comp_qty
        ,pn_comp_op_percent
        ,ls_item_class
    );
    
    ln_required_qty := rec_ldys0002_result.rn_compqty;
    
    IF rec_ldys0002_result.rn_status <> 0 THEN
        rs_err_code  := 'ld.E.LDP10151';
        rs_err_msg   := '<<SP:LDYS0002 Error Return>> Return: ' || rec_ldys0002_result.rn_status || ',' || 
                        rec_ldys0002_result.rs_sql_code || ',' || rec_ldys0002_result.rs_err_code || ',' || 
                        rec_ldys0002_result.rs_err_msg || ',' || rec_ldys0002_result.rs_err_focus;
        RAISE EXCEPTION ' ';
    END IF;
    
--------------------------------------------------
--  < STEP2.3 : Call LDYS0002 to calculate the outbound quantity >
--------------------------------------------------
   SELECT 
         LDYS0002.rn_status
        ,LDYS0002.rs_sql_code
        ,LDYS0002.rs_err_code
        ,LDYS0002.rs_err_msg
        ,LDYS0002.rs_err_focus
        ,LDYS0002.rn_compqty
    INTO rec_ldys0002_result
    FROM LDYS0002(
        pn_receipt_qty + pn_scrap_qty
       ,ps_comp_sign
       ,pn_comp_qty
       ,pn_comp_op_percent
       ,ls_item_class
    );
   
   ln_issued_qty := rec_ldys0002_result.rn_compqty;
   
   IF rec_ldys0002_result.rn_status <> 0 THEN
       rs_err_code  := 'ld.E.LDP10151';
       rs_err_msg   := '<<SP:LDYS0002 Error Return>> Return: ' || rec_ldys0002_result.rn_status || ',' || 
                       rec_ldys0002_result.rs_sql_code || ',' || rec_ldys0002_result.rs_err_code || ',' || 
                       rec_ldys0002_result.rs_err_msg || ',' || rec_ldys0002_result.rs_err_focus;
       RAISE EXCEPTION ' ';
   END IF;

--------------------------------------------------
--  < STEP2.4 : Detailed registration of subordinate demand quantity >
--------------------------------------------------
    SELECT 
         LDAS0416.status
        ,LDAS0416.sql_code
        ,LDAS0416.err_code
        ,LDAS0416.err_msg
        ,LDAS0416.err_focus
    INTO rec_ldas0416_result
    FROM LDAS0416(
         ps_parent_itemno
        ,ps_parent_supplier
        ,ps_parent_usercd, ps_order_no
        ,ps_comp_itemno
        ,ps_comp_supplier
        ,ps_comp_usercd, ps_structure_seq
        ,ps_order_through_no
        ,ps_order_through_no_source_flg
        ,ps_start_date
        ,ps_start_shift_no
        ,ps_rls_start_date
        ,ps_strc_lt_onset_start_date
        ,ps_strc_lt_onset_start_time_shift_no
        ,ps_order_status, ps_pilot_class
        ,ln_required_qty
        ,ln_issued_qty
        ,ps_item_type
        ,ps_comp_type
        ,ps_comp_sign
        ,ps_req_issue_control
        ,pn_comp_qty
        ,ps_comp_qty_type
        ,ps_strc_lt_proc_no
        ,pn_comp_op_percent
        ,cs_author
    );
    
    IF rec_ldas0416_result.status <> 0 THEN
        rs_err_code  := 'ld.E.LDP10152';
        rs_err_msg   := '<<SP:LDAS0416 Error Return>> Return: ' || rec_ldas0416_result.status || ',' || 
                        rec_ldas0416_result.sql_code || ',' || rec_ldas0416_result.err_code || ',' || 
                        rec_ldas0416_result.err_msg || ',' || rec_ldas0416_result.err_focus;
        RAISE EXCEPTION ' ';
    END IF;
    
    --------------------------------------------------
    --  < STEP2.5 : Design change requirement update log registration >
    --------------------------------------------------
    IF ps_order_status IN ('1', '2') THEN
      SELECT 
             b.area_section_code
            ,b.area_person_code
        INTO ls_department
             ,ls_responsible_person
        FROM la_area_master_su a
        JOIN la_area_master b 
          ON a.area_code = b.area_code
       WHERE a.su_code = ps_comp_supplier;
        IF NOT FOUND THEN
            ls_department          := ' ';
            ls_responsible_person  := ' ';
        END IF;
    ELSE
        ls_department         := '';
        ls_responsible_person := '';
    END IF;
    
    INSERT INTO ld_trn_reqchg_log(
         add_del_sign
        ,parent_itemno
        ,parent_supplier
        ,parent_usercd
        ,maintenance_datetime
        ,parent_disburse_date
        ,order_no
        ,structure_seq
        ,comp_itemno
        ,comp_supplier
        ,comp_usercd
        ,list_flg
        ,message_code
        ,org_section_mrp
        ,org_person_mrp
        ,order_status
        ,start_date
        ,required_qty
        ,out_qty
        ,in_effective_ymd
        ,out_effective_ymd
        ,comp_sign
        ,comp_op_percent
        ,update_counter
        ,create_datetime
        ,create_author
        ,create_pgmid
        ,update_datetime
        ,update_author
        ,update_pgmid
    )
    VALUES (
         cs_add_sign
        ,ps_parent_itemno
        ,ps_parent_supplier
        ,ps_parent_usercd
        ,pd_maintenance_datetime
        ,ps_parent_disburse_date
        ,ps_order_no
        ,ps_structure_seq
        ,ps_comp_itemno
        ,ps_comp_supplier
        ,ps_comp_usercd
        ,cs_list_flg
        ,ps_message_code
        ,ls_department
        ,ls_responsible_person
        ,ps_order_status
        ,ps_start_date
        ,ln_required_qty
        ,ln_issued_qty
        ,ps_in_effective_date
        ,ps_out_effective_date
        ,ps_comp_sign
        ,pn_comp_op_percent
        ,0
        ,ld_system_time
        ,cs_author
        ,cs_program_id
        ,ld_system_time
        ,cs_author
        ,cs_program_id
    );
    ln_log_insert_count := cn_insert_count;
    
    rn_status     := 0;
    rn_cnt_ins_lg := ln_log_insert_count;
    RETURN NEXT;
    RETURN;
EXCEPTION
    WHEN RAISE_EXCEPTION THEN
        IF rn_status <> 0 THEN  -- FOR CALL SP ERROR
            NULL;
        ELSE                    -- FOR PGM ERROR
            rn_status     :=  -2;
            rs_sql_code   := ' ';
        END IF;

        rs_err_focus      := cs_program_id;
        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN            -- FOR SQL ERROR
        rn_status         := -1;
        rs_sql_code       := SQLSTATE;
        rs_err_code       := ' ';
        rs_err_msg        := SQLERRM;
        rs_err_focus      := cs_program_id;

        RETURN NEXT;
        RETURN;
END;
$BODY$
LANGUAGE plpgsql;