--------------------------------------------------------------------------------
--@SEE << Component Quantity Calculation >>
--    @ID      : LDYS0002
--
--    @Written : 1.0.0                   2025.10.14 Zhang Yulin / YMSL
--    --------------------------------------------------------------------------
--    @Update  : xxxxxxxxxxxx            xxxx.xx.xx xxxxxxxx / xx
--     Reason  : xxx
--              xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--
--------------------------------------------------------------------------------
--@SEE < Component Quantity Calculation >
--------------------------------------------------------------------------------
--  < INPUT Parameter >
--    @pn_assyqty             <I/ > DECIMAL   : Quantity
--    @ps_compsign            <I/ > VARCHAR   : Component Sign ('+' or '-')
--    @pn_comp_qty            <I/ > DECIMAL   : Component Quantity (unit usage)
--    @pn_comp_op_percent     <I/ > DECIMAL   : Option Percent
--    @ps_item_class          <I/ > VARCHAR   : Item Class
--  < OUTPUT Parameter >
--    @rn_status                   < /O> INTEGER   : Return Code
--                                                   (  0 : Normal        )
--                                                   ( -1 : Sql Error     )
--                                                   ( -2 : Program Error )
--    @rs_sql_code                 < /O> VARCHAR   : Sql Error Code
--    @rs_err_code                  < /O> VARCHAR   : Program Error Code
--    @rs_err_msg                   < /O> VARCHAR   : Error Message
--    @rs_err_focus                 < /O> VARCHAR   : Error Focus
--    @rn_compqty                  < /O> DECIMAL   : Component Quantity
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0002(
    pn_assyqty        IN DECIMAL,              --1
    ps_compsign       IN VARCHAR,              --2
    pn_comp_qty       IN DECIMAL,              --3
    pn_comp_op_percent IN DECIMAL,             --4
    ps_item_class     IN VARCHAR               --5
)
RETURNS TABLE(
    rn_status            INTEGER,              --1
    rs_sql_code          VARCHAR,              --2
    rs_err_code          VARCHAR,              --3
    rs_err_msg           VARCHAR,              --4
    rs_err_focus         VARCHAR,              --5
    rn_compqty           DECIMAL               --6
) AS
$BODY$
DECLARE
    ln_qty      DECIMAL := 0; -- Working quantity
    ln_compqty  DECIMAL := 0; -- Calculated quantity
BEGIN
    ----------------------------------------------------------------------
    -- < STEP1 : Initialization >
    ----------------------------------------------------------------------
    rn_status    := 0;
    rs_sql_code  := ' ';
    rs_err_code  := ' ';
    rs_err_msg   := ' ';
    rs_err_focus := ' ';
    rn_compqty   := 0;

    ----------------------------------------------------------------------
    -- < STEP2 : Overflow Check >
    ----------------------------------------------------------------------
    IF pn_assyqty >= 9999999999.99999 OR pn_assyqty <= -9999999999.99999 THEN
        rn_compqty := 9999999999.99999;
        RETURN NEXT;
        RETURN;
    END IF;

    ----------------------------------------------------------------------
    -- < STEP3 : Component Sign Judgment >
    ----------------------------------------------------------------------
    IF ps_compsign = '+' THEN
        ln_qty := pn_assyqty;
    ELSE
        ln_qty := pn_assyqty * -1;
    END IF;

    ----------------------------------------------------------------------
    -- < STEP4 : Main Calculation >
    ----------------------------------------------------------------------
    ln_compqty := ln_qty * pn_comp_qty * pn_comp_op_percent / 100;

    IF ps_item_class = '0' OR ps_item_class = '1' THEN
        -- Decimal, 5 digits
        IF ln_compqty < 0 THEN
            ln_compqty := TRUNC(ln_compqty - 0.000009, 5);
        ELSE
            ln_compqty := TRUNC(ln_compqty + 0.000009, 5);
        END IF;
    ELSE
        -- Integer
        IF ln_compqty < 0 THEN
            ln_compqty := TRUNC(ln_compqty - 0.000009);
        ELSE
            ln_compqty := TRUNC(ln_compqty + 0.000009);
        END IF;
    END IF;

    rn_compqty := ln_compqty;

    ----------------------------------------------------------------------
    -- < STEP5 : Return Value Setting >
    ----------------------------------------------------------------------
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
            rs_err_focus      := 'LDYS0002';
            rn_compqty        := 0;
        END IF;

        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN
        rn_status             := -1;
        rs_sql_code           := SQLSTATE;
        rs_err_code           := ' ';
        rs_err_msg            := SQLERRM;
        rs_err_focus          := 'LDYS0002';
        rn_compqty            := 0;

        RETURN NEXT;
        RETURN;
END;
$BODY$
LANGUAGE plpgsql;