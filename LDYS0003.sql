--------------------------------------------------------------------------------
--  < ORDERNO NUMBERING >
--    @ID      : LDYS0003
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
--    @ps_user_id                  <I/ > VARCHAR   : User ID
--    @ps_itemno                   <I/ > VARCHAR   : Item Number
--    @ps_supplier                 <I/ > VARCHAR   : Supplier
--    @ps_usercd                   <I/ > VARCHAR   : User Code
--    @ps_input_class              <I/ > VARCHAR   : Input Class
--    @ps_pilot_class              <I/ > VARCHAR   : Pilot Class
--  < OUTPUT Parameter >
--    @rn_status                   < /O> INTEGER   : Return Code
--                                                   (  0 : Normal        )
--                                                   ( -1 : Sql Error     )
--                                                   ( -2 : Program Error )
--    @rs_sql_code                 < /O> VARCHAR   : Sql Error Code
--    @rs_err_code                 < /O> VARCHAR   : Program Error Code
--    @rs_err_msg                  < /O> VARCHAR   : Error Message
--    @rs_err_focus                < /O> VARCHAR   : Error Focus
--    @rs_order_no                 < /O> VARCHAR   : Order Number
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0003(
    ps_user_id             IN VARCHAR,    --1. ユーザーID
    ps_itemno              IN VARCHAR,    --2. 品目番号
    ps_supplier            IN VARCHAR,    --3. 供給者
    ps_usercd              IN VARCHAR,    --4. 使用者
    ps_input_class         IN VARCHAR,    --5. 入力区分
    ps_pilot_class         IN VARCHAR     --6. 生試初品区分
)
RETURNS TABLE(
    rn_status              INTEGER,       --1. 処理ステータス
    rs_sql_code            VARCHAR,       --2. SQLコード
    rs_err_code            VARCHAR,       --3. エラーコード
    rs_err_msg             VARCHAR,       --4. エラーメッセージ
    rs_err_focus           VARCHAR,       --5. エラー位置
    rs_order_no            VARCHAR        --6. オーダNo.
) AS
$BODY$
DECLARE
    --------------------------------------------------
    --  < Definition Local Paramater >
    --------------------------------------------------
    ls_next_ohorder_ic     ld_trn_inv.next_ohorder_ic%TYPE;
    ls_next_odorder_ic     ld_trn_inv.next_odorder_ic%TYPE;
    ls_next_bhorder_ic     ld_trn_inv.next_bhorder_ic%TYPE;
    ls_next_bdorder_ic     ld_trn_inv.next_bdorder_ic%TYPE;
    ls_init_ohorder_ic     VARCHAR;       -- 変数.初回接頭番号（ｵﾝﾗｲﾝ）
    ls_init_odorder_ic     VARCHAR;       -- 変数.初回順序番号（ｵﾝﾗｲﾝ）
    ls_init_bhorder_ic     VARCHAR;       -- 変数.初回接頭番号（ﾊﾞｯﾁ）
    ls_init_bdorder_ic     VARCHAR;       -- 変数.初回順序番号（ﾊﾞｯﾁ）
    ls_carry_flg           VARCHAR(1);
    ls_loop_flg            VARCHAR(1);
    ls_order_no            VARCHAR(5);
    ls_seq_max             VARCHAR(4);
    cs_pgmid               CONSTANT VARCHAR := 'LDYS0003';
    cs_space               CONSTANT VARCHAR := ' ';
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    rn_status              := 0;
    rs_sql_code            := cs_space;
    rs_err_code            := cs_space;
    rs_err_msg             := cs_space;
    rs_err_focus           := cs_space;
    rs_order_no            := cs_space;

    ls_next_ohorder_ic     := cs_space;
    ls_next_odorder_ic     := cs_space;
    ls_next_bhorder_ic     := cs_space;
    ls_next_bdorder_ic     := cs_space;
    ls_init_ohorder_ic     := cs_space;  -- 変数.初回接頭番号（ｵﾝﾗｲﾝ）
    ls_init_odorder_ic     := cs_space;  -- 変数.初回順序番号（ｵﾝﾗｲﾝ）
    ls_init_bhorder_ic     := cs_space;  -- 変数.初回接頭番号（ﾊﾞｯﾁ）
    ls_init_bdorder_ic     := cs_space;  -- 変数.初回順序番号（ﾊﾞｯﾁ）
    ls_carry_flg           := '0';
    ls_loop_flg            := '0';
    ls_order_no            := cs_space;
    ls_seq_max             := '9999';

    --------------------------------------------------
    -- < STEP2 : Argument Check >
    --------------------------------------------------
       IF ps_input_class IS NULL 
       OR ps_input_class =  '' THEN
        ps_input_class := '2';
    END IF;

    --------------------------------------------------
    --  < STEP3 : Main Processing >
    --------------------------------------------------
       IF NOT EXISTS (
        SELECT 1
          FROM ld_trn_inv
         WHERE itemno   = ps_itemno
           AND supplier = ps_supplier
           AND usercd   = ps_usercd
    ) THEN
        rn_status   := -2;
        rs_err_code := 'ld.E.LDP10133';
        rs_err_msg  := 'No framework for order number assignment remains.';
        RAISE EXCEPTION ' ';
    END IF;

    UPDATE ld_trn_inv
       SET ic_update_datetime = statement_timestamp()
          ,update_author      = ps_user_id
          ,update_pgmid       = cs_pgmid
          ,update_counter     = COALESCE(update_counter, 0) + 1
     WHERE itemno   = ps_itemno
       AND supplier = ps_supplier
       AND usercd   = ps_usercd;

    SELECT next_ohorder_ic
         , next_odorder_ic
         , next_bhorder_ic
         , next_bdorder_ic
      INTO STRICT
           ls_next_ohorder_ic
         , ls_next_odorder_ic
         , ls_next_bhorder_ic
         , ls_next_bdorder_ic
      FROM ld_trn_inv
     WHERE itemno   = ps_itemno
       AND supplier = ps_supplier
       AND usercd   = ps_usercd;

       IF ps_input_class = '1' THEN
        ls_init_ohorder_ic := ls_next_ohorder_ic;
        ls_init_odorder_ic := ls_next_odorder_ic;
     ELSE
        ls_init_bhorder_ic := ls_next_bhorder_ic;
        ls_init_bdorder_ic := ls_next_bdorder_ic;
    END IF;

    WHILE ls_loop_flg = '0' LOOP
        -- Generate next order number
           IF ps_pilot_class = '2' 
           OR ps_pilot_class = '4' THEN
               IF ps_input_class = '1' THEN
                ls_order_no := 'M' || ls_next_odorder_ic;
             ELSE
                ls_order_no := 'N' || ls_next_bdorder_ic;
            END IF;
         ELSE
               IF ps_input_class = '1' THEN
                ls_order_no := TRIM(ls_next_ohorder_ic) || ls_next_odorder_ic;
             ELSE
                ls_order_no := TRIM(ls_next_bhorder_ic) || ls_next_bdorder_ic;
            END IF;
        END IF;

        -- Check next order number
           IF NOT EXISTS (
            SELECT 1
              FROM le_trn_order
             WHERE order_no = ls_order_no
               AND itemno   = ps_itemno
               AND supplier = ps_supplier
               AND usercd   = ps_usercd
        ) THEN
            ls_loop_flg := '1';
        END IF;

           IF ls_loop_flg = '1' THEN
               IF EXISTS (
                SELECT 1
                  FROM le_trn_ird
                 WHERE order_no = ls_order_no
                   AND itemno   = ps_itemno
                   AND supplier = ps_supplier
                   AND usercd   = ps_usercd
            ) THEN
                ls_loop_flg := '0';
            END IF;
        END IF;

           IF ls_loop_flg = '1' THEN
               IF EXISTS (
                SELECT 1
                  FROM le_trn_order_forecast
                 WHERE order_no = ls_order_no
                   AND itemno   = ps_itemno
                   AND supplier = ps_supplier
                   AND usercd   = ps_usercd
            ) THEN
                 ls_loop_flg := '0';
            END IF;
        END IF;

        ls_carry_flg := '0';
        IF ps_input_class = '1' THEN
               IF ls_next_odorder_ic <> ls_seq_max THEN
                ls_next_odorder_ic := TO_CHAR(TO_NUMBER(ls_next_odorder_ic, '9999') + 1, 'FM0000');
             ELSE
                ls_next_odorder_ic := '0001';
                ls_carry_flg       := '1';
            END IF;
         ELSE
               IF ls_next_bdorder_ic <> ls_seq_max THEN
                ls_next_bdorder_ic := TO_CHAR(TO_NUMBER(ls_next_bdorder_ic, '9999') + 1, 'FM0000');
             ELSE
                ls_next_bdorder_ic := '0001';
                ls_carry_flg       := '1';
            END IF;
        END IF;

        -- Infinite loop avoidance check
        IF ls_loop_flg = '0' THEN
            IF ps_input_class = '1' THEN
                IF ps_pilot_class = '2' OR ps_pilot_class = '4' THEN
                    IF ls_init_odorder_ic = ls_next_odorder_ic THEN
                        rn_status   := -2;
                        rs_err_code := 'ld.E.LDP10133';
                        rs_err_msg  := 'No framework for order number assignment remains.';
                        RAISE EXCEPTION ' ';
                    END IF;
                ELSE
                    IF ls_init_ohorder_ic = ls_next_ohorder_ic 
                    AND ls_init_odorder_ic = ls_next_odorder_ic THEN
                        rn_status   := -2;
                        rs_err_code := 'ld.E.LDP10133';
                        rs_err_msg  := 'No framework for order number assignment remains.';
                        RAISE EXCEPTION ' ';
                    END IF;
                END IF;
            ELSE
                IF ps_pilot_class = '2' OR ps_pilot_class = '4' THEN
                    IF ls_init_bdorder_ic = ls_next_bdorder_ic THEN
                        rn_status   := -2;
                        rs_err_code := 'ld.E.LDP10133';
                        rs_err_msg  := 'No framework for order number assignment remains.';
                        RAISE EXCEPTION ' ';
                    END IF;
                ELSE
                    IF ls_init_bhorder_ic = ls_next_bhorder_ic 
                    AND ls_init_bdorder_ic = ls_next_bdorder_ic THEN
                        rn_status   := -2;
                        rs_err_code := 'ld.E.LDP10133';
                        rs_err_msg  := 'No framework for order number assignment remains.';
                        RAISE EXCEPTION ' ';
                    END IF;
                END IF;
            END IF;
        ELSE
            rs_order_no := ls_order_no;
        END IF;

        IF ls_carry_flg = '1' THEN
            IF ps_input_class = '1' THEN
                ls_next_odorder_ic := '0001';
                IF ls_next_ohorder_ic = 'H' THEN
                    ls_next_ohorder_ic := 'A';
                ELSE
                    ls_next_ohorder_ic := CHR(ASCII(ls_next_ohorder_ic) + 1);
                END IF;
            ELSE
                ls_next_bdorder_ic := '0001';
                IF ls_next_bhorder_ic = 'V' THEN
                    ls_next_bhorder_ic := 'X';
                ELSIF ls_next_bhorder_ic = 'Z' THEN
                    ls_next_bhorder_ic := 'P';
                ELSE
                    ls_next_bhorder_ic := CHR(ASCII(ls_next_bhorder_ic) + 1);
                END IF;
            END IF;
        END IF;
    END LOOP;

       IF ps_input_class = '1' THEN
        UPDATE ld_trn_inv
           SET next_ohorder_ic    = ls_next_ohorder_ic
              ,next_odorder_ic    = ls_next_odorder_ic
              ,update_counter     = COALESCE(update_counter, 0) + 1
              ,ic_update_datetime = statement_timestamp()
              ,update_author      = ps_user_id
              ,update_pgmid       = cs_pgmid
         WHERE itemno   = ps_itemno
           AND supplier = ps_supplier
           AND usercd   = ps_usercd;
     ELSE
        UPDATE ld_trn_inv
           SET next_bhorder_ic    = ls_next_bhorder_ic
              ,next_bdorder_ic    = ls_next_bdorder_ic
              ,update_counter     = COALESCE(update_counter, 0) + 1
              ,ic_update_datetime = statement_timestamp()
              ,update_author      = ps_user_id
              ,update_pgmid       = cs_pgmid
         WHERE itemno   = ps_itemno
           AND supplier = ps_supplier
           AND usercd   = ps_usercd;
    END IF;
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