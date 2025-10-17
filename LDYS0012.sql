--------------------------------------------------------------------------------
--@SEE << Pre-process Inventory Quantity Calculation >>
--    @ID      : LDYS0012
--
--    @Written : 1.0.0                   2025.10.13 Zhang Yulin / YMSL
--    --------------------------------------------------------------------------
--    @Update  : xxxxxxxxxxxx            xxxx.xx.xx xxxxxxxx / xx
--     Reason  : xxx
--              xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--
--------------------------------------------------------------------------------
--@SEE < Pre-process Inventory Quantity Calculation >
--------------------------------------------------------------------------------
--  < INPUT Parameter >
--    @ps_itemno                   < /I> VARCHAR   : Item No
--    @ps_supplier                 < /I> VARCHAR   : Supplier
--    @ps_usercd                   < /I> VARCHAR   : User Code
--    @ps_date                     < /I> VARCHAR   : Date (YYYYMMDD)
--    @ps_order_no                 < /I> VARCHAR   : Order No
--  < OUTPUT Parameter >
--    @rn_status                   < /O> INTEGER   : Return Code
--                                                   (  0 : Normal        )
--                                                   ( 100 : Notfound     )
--                                                   ( -1 : Sql Error     )
--                                                   ( -2 : Program Error )
--    @rs_sql_code                 < /O> VARCHAR   : Sql Error Code
--    @rs_err_code                 < /O> VARCHAR   : Program Error Code
--    @rs_err_msg                  < /O> VARCHAR   : Error Message
--    @rs_err_focus                < /O> VARCHAR   : Error Focus
--    @rs_system_msg               < /O> VARCHAR   : System Message
--    @rs_cal_cresult              < /O> VARCHAR   : Calculation Result (0: Calculable, 1: Not Calculable)
--    @rs_oh_qty                   < /O> DECIMAL(18,6) : On-hand Quantity
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0012(
    ps_itemno           VARCHAR,              --1
    ps_supplier         VARCHAR,              --2
    ps_usercd           VARCHAR,              --3
    ps_date             VARCHAR,              --4
    ps_order_no         VARCHAR               --5
)
RETURNS TABLE(
    rn_status           INTEGER,              --1
    rs_sql_code         VARCHAR,              --2
    rs_err_code         VARCHAR,              --3
    rs_err_msg          VARCHAR,              --4
    rs_err_focus        VARCHAR,              --5
    rs_cal_cresult      VARCHAR,              --6 (0:算出可能1:算出不可)
    rs_oh_qty           DECIMAL (18,6)        --7
) AS
$$
DECLARE
    ls_itemno          gimac.la_prodstrc.comp_itemno%TYPE := ' ';
    ls_supplier        gimac.la_prodstrc.comp_supplier%TYPE := ' ';
    ls_usercd          gimac.la_prodstrc.comp_usercd%TYPE := ' ';
    ls_cal_cresult     VARCHAR(1) := '0';
    ls_airs_sign       gimac.le_mst_mrp_information.airs_sign%TYPE := ' ';
    ls_oh_qty          gimac.ld_trn_inv.oh_qty%TYPE := 0;
    ln_count           INTEGER := 0;
BEGIN
    --------------------------------------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------------------------------------
    ls_itemno        := ' ';
    ls_supplier      := ' ';
    ls_usercd        := ' ';
    rs_cal_cresult   := '0';
    ls_airs_sign     := ' ';
    rs_oh_qty        := 0;
    rn_status        := 0;
    rs_sql_code      := ' ';
    rs_err_code      := ' ';
    rs_err_msg       := ' ';
    rs_err_focus     := ' ';
    --------------------------------------------------------------------------------
    --  < STEP2 : Argument Check >
    --------------------------------------------------------------------------------
    IF TRIM(ps_itemno) IS NULL OR TRIM(ps_itemno) = '' THEN
        rn_status := -2;
        rs_err_code := 'E.LDP10451';
        rs_err_msg := 'Enter Item Number.';
        RETURN NEXT;
        RETURN;
    END IF;

    IF LENGTH(TRIM(ps_itemno)) > 30 THEN
        rn_status := -2;
        rs_err_code := 'E.LDP10892';
        rs_err_msg := 'Specify 30 digits or less for the Item Number.';
        RETURN NEXT;
        RETURN;
    END IF;

    IF TRIM(ps_supplier) IS NULL OR TRIM(ps_supplier) = '' THEN
        rn_status := -2;
        rs_err_code := 'E.LDP10893';
        rs_err_msg := 'Specify the Supplier.';
        RETURN NEXT;
        RETURN;
    END IF;

    IF LENGTH(TRIM(ps_supplier)) <> 4 THEN
        rn_status := -2;
        rs_err_code := 'E.LDP10894';
        rs_err_msg := 'Specify Item of which Supplier is 4 digits.';
        RETURN NEXT;
        RETURN;
    END IF;

    IF TRIM(ps_usercd) IS NULL OR TRIM(ps_usercd) = '' THEN
        rn_status := -2;
        rs_err_code := 'E.LDP10895';
        rs_err_msg := 'Specify the User.';
        RETURN NEXT;
        RETURN;
    END IF;

    IF TRIM(ps_date) IS NULL OR TRIM(ps_date) = '' THEN
        rn_status := -2;
        rs_err_code := 'E.LDP10897';
        rs_err_msg := 'Specify the Date.';
        RETURN NEXT;
        RETURN;
    END IF;

    IF LENGTH(TRIM(ps_date)) <> 8 THEN
        rn_status := -2;
        rs_err_code := 'E.LDP10898';
        rs_err_msg := 'Specify Item of which Date is 8 digits.';
        RETURN NEXT;
        RETURN;
    END IF;

    IF TRIM(ps_order_no) IS NULL OR TRIM(ps_order_no) = '' THEN
        rn_status := -2;
        rs_err_code := 'E.LDP10908';
        rs_err_msg := 'Specify the Order Number.';
        RETURN NEXT;
        RETURN;
    END IF;

    IF LENGTH(TRIM(ps_order_no)) <> 4 THEN
        rn_status := -2;
        rs_err_code := 'E.LDP10909';
        rs_err_msg := 'Specify Item of which Order Numbers 5 digits.';
        RETURN NEXT;
        RETURN;
    END IF;

    --------------------------------------------------------------------------------
    --  < STEP3 : Main Processing >
    --------------------------------------------------------------------------------
    SELECT COUNT(*)
      INTO ln_count
      FROM le_trn_ird
     WHERE itemno = ps_itemno
       AND supplier = ps_supplier
       AND usercd = ps_usercd
       AND order_no = ps_order_no
       AND rd_class = '0';

    IF ln_count > 0 THEN
        ls_itemno := ps_itemno;
        ls_supplier := ps_supplier;
        ls_usercd := ps_usercd;
    ELSE
        IF ps_supplier = ps_usercd THEN
            SELECT COUNT(*)
              INTO ln_count
              FROM la_prodstrc
             WHERE parent_itemno = ps_itemno
               AND parent_supplier = ps_supplier
               AND parent_usercd = ps_usercd
               AND in_effective_ymd <= ps_date
               AND out_effective_ymd > ps_date;

            IF ln_count <> 1 THEN
                ls_cal_cresult := '1';
            ELSE
                SELECT comp_itemno
                      ,comp_supplier
                      ,comp_usercd
                  INTO ls_itemno
                      ,ls_supplier
                      ,ls_usercd
                  FROM la_prodstrc
                 WHERE parent_itemno = ps_itemno
                   AND parent_supplier = ps_supplier
                   AND parent_usercd = ps_usercd
                   AND in_effective_ymd <= ps_date
                   AND out_effective_ymd > ps_date;
                ls_cal_cresult := '0';
            END IF;
        ELSE
            ls_itemno := ps_itemno;
            ls_supplier := ps_supplier;
            ls_usercd := ps_usercd;
        END IF;
    END IF;

    IF ls_cal_cresult = '0' THEN
        SELECT airs_sign
          INTO ls_airs_sign
          FROM le_mst_mrp_information
         WHERE itemno = ps_itemno
           AND supplier = ps_supplier
           AND usercd = ps_usercd;

        IF NOT FOUND THEN
            ls_cal_cresult := '1';
        END IF;

        WHILE ls_airs_sign <> '0' AND ls_cal_cresult = '0' LOOP
            SELECT COUNT(*)
              INTO ln_count
              FROM la_prodstrc
             WHERE parent_itemno = ls_itemno
               AND parent_supplier = ls_supplier
               AND parent_usercd = ls_usercd
               AND in_effective_ymd <= ps_date
               AND out_effective_ymd > ps_date;

            IF ln_count <> 1 THEN
                ls_cal_cresult := '1';
            ELSE
                SELECT comp_itemno
                      ,comp_supplier
                      ,comp_usercd
                  INTO ls_itemno
                      ,ls_supplier
                      ,ls_usercd
                  FROM la_prodstrc
                 WHERE parent_itemno = ls_itemno
                   AND parent_supplier = ls_supplier
                   AND parent_usercd = ls_usercd
                   AND in_effective_ymd <= ps_date
                   AND out_effective_ymd > ps_date;
                ls_cal_cresult := '0';
            END IF;

            SELECT airs_sign
              INTO ls_airs_sign
              FROM le_mst_mrp_information
             WHERE itemno = ls_itemno
               AND supplier = ls_supplier
               AND usercd = ls_usercd;

            IF NOT FOUND THEN
                ls_cal_cresult := '1';
            END IF;
        END LOOP;

        IF ls_cal_cresult = '0' THEN
            SELECT oh_qty
              INTO ls_oh_qty
              FROM ld_trn_inv
             WHERE itemno = ls_itemno
               AND supplier = ls_supplier
               AND usercd = ls_usercd;

            IF NOT FOUND THEN
                ls_cal_cresult := '1';
            END IF;
        END IF;
    END IF;

    --------------------------------------------------------------------------------
    --  < STEP4 : Return Value Setting >
    --------------------------------------------------------------------------------
    rs_cal_cresult := ls_cal_cresult;
    rs_oh_qty := ls_oh_qty;

    RETURN NEXT;

EXCEPTION
    --------------------------------------------------------------------------------
    --  Error Handle
    --------------------------------------------------------------------------------
    WHEN RAISE_EXCEPTION THEN
        IF rn_status <> 0 THEN
            NULL;
        ELSE
            rn_status         := -2;
            rs_sql_code       := ' ';
            rs_err_code       := ' ';
            rs_err_msg        := 'PGM Error';
            rs_err_focus      := 'LDYS0012';
        END IF;

        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN
        rn_status             := -1;
        rs_sql_code           := SQLSTATE;
        rs_err_code           := ' ';
        rs_err_msg            := SQLERRM;
        rs_err_focus          := 'LDYS0012';

        RETURN NEXT;
        RETURN;
END;
$$
LANGUAGE 'plpgsql';