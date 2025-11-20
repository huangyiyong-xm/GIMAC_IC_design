--------------------------------------------------------------------------------
--@SEE << Number Caliculate >>
--    @ID      : LDYS0002
--
--    @Written : 1.0.0                   2025.10.14 Zhang Yulin / YMSLX
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
--    @pn_assyqty                  <I/ > DECIMAL   : Quantity
--    @ps_compsign                 <I/ > VARCHAR   : Component Sign ('+' or '-')
--    @pn_comp_qty                 <I/ > DECIMAL   : Component Quantity (unit usage)
--    @pn_comp_op_percent          <I/ > DECIMAL   : Option Percent
--    @ps_item_class               <I/ > VARCHAR   : Item Class
--  < OUTPUT Parameter >
--    @rn_status                   < /O> INTEGER   : Return Code
--                                                   (  0 : Normal        )
--                                                   ( -1 : Sql Error     )
--                                                   ( -2 : Program Error )
--    @rs_sql_code                 < /O> VARCHAR   : Sql Error Code
--    @rs_err_code                 < /O> VARCHAR   : Program Error Code
--    @rs_err_msg                  < /O> VARCHAR   : Error Message
--    @rs_err_focus                < /O> VARCHAR   : Error Focus
--    @rn_compqty                  < /O> DECIMAL   : Component Quantity
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0002(
    pn_assyqty           IN DECIMAL,    --1. 数量
    ps_compsign          IN VARCHAR,    --2. 構成品サイン
    pn_comp_qty          IN DECIMAL,    --3. 員数
    pn_comp_op_percent   IN DECIMAL,    --4. オプション％
    ps_item_class        IN VARCHAR     --5. 品目クラス
)
RETURNS TABLE(
    rn_status            INTEGER,       --1. 処理ステータス
    rs_sql_code          VARCHAR,       --2. SQLコード
    rs_err_code          VARCHAR,       --3. エラーコード
    rs_err_msg           VARCHAR,       --4. エラーメッセージ
    rs_err_focus         VARCHAR,       --5. エラー位置
    rn_compqty           DECIMAL        --6. 計算数量
) AS
$BODY$
DECLARE
    --------------------------------------------------
    --  < Definition Local Paramater >
    --------------------------------------------------
    ln_qty              DECIMAL(15,5) := 0;          --1. 数量
    ln_compqty          DECIMAL(16,6) := 0;          --2. 員数
    cs_pgmid            VARCHAR(20)   := 'LDYS0002';
    cs_space            VARCHAR(1)    := ' ';
BEGIN
    -----------------------------------------------------
    --  < STEP1 : Initialization >
    -----------------------------------------------------
    rn_status    := 0;
    rs_sql_code  := cs_space;
    rs_err_code  := cs_space;
    rs_err_msg   := cs_space;
    rs_err_focus := cs_space;
    rn_compqty   := 0;

    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    IF pn_assyqty  >= 9999999999.99999 OR pn_assyqty <= -9999999999.99999 THEN
        rn_compqty := 9999999999.99999;
        RETURN NEXT;
        RETURN;
    END IF;

    IF ps_compsign = '+' THEN
        ln_qty := pn_assyqty;
    ELSE
        ln_qty := pn_assyqty * -1;
    END IF;

    ln_compqty := TRUNC(ln_qty * pn_comp_qty * pn_comp_op_percent / 100, 6);

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
            ln_compqty := TRUNC(ln_compqty - 0.999999);
        ELSE
            ln_compqty := TRUNC(ln_compqty + 0.999999);
        END IF;
    END IF;

    rn_compqty := ln_compqty;

    RETURN NEXT;
    RETURN;

EXCEPTION
    -----------------------------------------------------
    --  Error Handle
    -----------------------------------------------------
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