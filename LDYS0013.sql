--------------------------------------------------------------------------------
--@SEE << PP Order Number Update >>
--    @ID      : LDYS0013
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
--@SEE < PP Order Number Update >
--------------------------------------------------------------------------------
--  < INPUT Parameter >
--    @ps_itemno                   < /I> VARCHAR   : Item Number
--    @ps_supplier                 < /I> VARCHAR   : Supplier
--    @ps_usercd                   < /I> VARCHAR   : User Code
--    @ps_next_ohorder_ic          < /I> VARCHAR   : Next OH Order IC
--    @ps_next_odorder_ic          < /I> VARCHAR   : Next OD Order IC
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
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0013(
    ps_itemno           VARCHAR,              --1
    ps_supplier         VARCHAR,              --2
    ps_usercd           VARCHAR,              --3
    ps_next_ohorder_ic  VARCHAR,              --4
    ps_next_odorder_ic  VARCHAR               --5
)
RETURNS TABLE(
    rn_status           INTEGER,              --1
    rs_sql_code         VARCHAR,              --2
    rs_err_code         VARCHAR,              --3
    rs_err_msg          VARCHAR,              --4
    rs_err_focus        VARCHAR,              --5
    rs_system_msg       VARCHAR               --6
) AS
$$
DECLARE
    ln_count            INTEGER;
BEGIN
    --------------------------------------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------------------------------------
    rn_status        := 0;
    rs_sql_code      := ' ';
    rs_err_code      := ' ';
    rs_err_msg       := ' ';
    rs_err_focus     := ' ';
    rs_system_msg    := ' ';

    --------------------------------------------------------------------------------
    --  < STEP2 : Argument Check >
    --------------------------------------------------------------------------------
    IF ps_itemno IS NULL OR TRIM(ps_itemno) = '' THEN
        rn_status := -2;
        rs_err_code := 'E.LDP10451';
        rs_err_msg := 'Enter Item Number.';
        RETURN NEXT;
        RETURN;
    END IF;

    IF ps_supplier IS NULL OR TRIM(ps_supplier) = '' THEN
        rn_status := -2;
        rs_err_code := 'E.LDP10893';
        rs_err_msg := 'Specify the Supplier.';
        RETURN NEXT;
        RETURN;
    END IF;

    IF ps_usercd IS NULL OR TRIM(ps_usercd) = '' THEN
        rn_status := -2;
        rs_err_code := 'E.LDP10895';
        rs_err_msg := 'Specify the User.';
        RETURN NEXT;
        RETURN;
    END IF;

    IF ps_next_ohorder_ic IS NULL OR TRIM(ps_next_ohorder_ic) = '' THEN
        rn_status := -2;
        rs_err_code := 'E.LDP100XX';
        rs_err_msg := 'ps_next_ohorder_ic is empty or NULL.';
        RETURN NEXT;
        RETURN;
    END IF;

    IF ps_next_odorder_ic IS NULL OR TRIM(ps_next_odorder_ic) = '' THEN
        rn_status := -2;
        rs_err_code := 'E.LDP100XX';
        rs_err_msg := 'ps_next_odorder_ic is empty or NULL.';
        RETURN NEXT;
        RETURN;
    END IF;

    --------------------------------------------------------------------------------
    --  < STEP3 : Main Processing >
    --------------------------------------------------------------------------------
    SELECT COUNT(1)
      INTO ln_count
      FROM ld_trn_inv
     WHERE itemno = ps_itemno
       AND supplier = ps_supplier
       AND usercd = ps_usercd;

    IF ln_count = 0 THEN
        rn_status := 100;
        rs_err_code := 'E.10006';
        rs_err_msg := 'The item is not exist in inventory.';
        RETURN NEXT;
        RETURN;
    END IF;

    UPDATE ld_trn_inv
       SET next_ohorder_ic = ps_next_ohorder_ic,
           next_odorder_ic = ps_next_odorder_ic,
           update_counter = COALESCE(update_counter, 0) + 1,
           update_datetime = CURRENT_TIMESTAMP,
           update_author = 'SYSTEM',
           update_pgmid = 'LDYS0013'
     WHERE itemno = ps_itemno
       AND supplier = ps_supplier
       AND usercd = ps_usercd;

    --------------------------------------------------------------------------------
    --  < STEP4 : Return Value Setting >
    --------------------------------------------------------------------------------
    RETURN NEXT;
    RETURN;

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
            rs_err_focus      := 'LDYS0013';
            rs_system_msg     := ' ';
        END IF;

        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN
        rn_status             := -1;
        rs_sql_code           := SQLSTATE;
        rs_err_code           := ' ';
        rs_err_msg            := SQLERRM;
        rs_err_focus          := 'LDYS0013';
        rs_system_msg         := ' ';

        RETURN NEXT;
        RETURN;
END;
$$
LANGUAGE 'plpgsql';