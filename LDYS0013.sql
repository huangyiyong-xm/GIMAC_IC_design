--------------------------------------------------------------------------------
--@SEE << PP Order Number Update >>
--    @ID      : LDYS0013
--
--    @Written : 1.0.0                   2025.10.13 Zhang Yulin / YMSLX
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
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0013(
    ps_itemno           VARCHAR,        --1. 品目番号
    ps_supplier         VARCHAR,        --2. 供給者
    ps_usercd           VARCHAR,        --3. 使用者
    ps_next_ohorder_ic  VARCHAR,        --4. 接頭番号(オンライン)
    ps_next_odorder_ic  VARCHAR         --5. 順序番号(オンライン)
)
RETURNS TABLE(
    rn_status           INTEGER,        --1. 処理ステータス
    rs_sql_code         VARCHAR,        --2. SQLコード
    rs_err_code         VARCHAR,        --3. エラーコード
    rs_err_msg          VARCHAR,        --4. エラーメッセージ
    rs_err_focus        VARCHAR         --5. エラー位置
) AS
$BODY$
  DECLARE
    --------------------------------------------------
    --  < Definition Local Paramater >
    --------------------------------------------------
    ln_count            INTEGER := 0;
    rs_system_msg       VARCHAR;
    ld_system_date      TIMESTAMP;
    cs_space            CONSTANT VARCHAR := ' ';
    cs_pgmid            CONSTANT VARCHAR := 'LDYS0013';
  BEGIN
    ----------------------------------------------------------------------------
    --  < STEP1 : Initialization >
    ----------------------------------------------------------------------------
    ld_system_date     := CURRENT_TIMESTAMP;
    rn_status          := 0;
    rs_sql_code        := cs_space;
    rs_err_code        := cs_space;
    rs_err_msg         := cs_space;
    rs_err_focus       := cs_space;
    rs_system_msg      := cs_space;
    ----------------------------------------------------------------------------
    --  < STEP2 : Argument Check >
    ----------------------------------------------------------------------------
      IF ps_itemno IS NULL OR TRIM(ps_itemno) = cs_space THEN
        rn_status   := -2;
        rs_err_code := 'ld.E.LDP10055';
        rs_err_msg  := 'Enter Item Number.';
        RETURN NEXT;
        RETURN;
      END IF;

      IF ps_supplier IS NULL OR TRIM(ps_supplier) = cs_space THEN
        rn_status   := -2;
        rs_err_code := 'ld.E.LDP10056';
        rs_err_msg  := 'Specify the Supplier.';
        RETURN NEXT;
        RETURN;
      END IF;

      IF ps_usercd IS NULL OR TRIM(ps_usercd) = cs_space THEN
        rn_status   := -2;
        rs_err_code := 'ld.E.LDP10057';
        rs_err_msg  := 'Specify the User.';
        RETURN NEXT;
        RETURN;
      END IF;

      IF ps_next_ohorder_ic IS NULL OR TRIM(ps_next_ohorder_ic) = cs_space THEN
        rn_status   := -2;
        rs_err_code := 'ld.E.LDP10142';
        rs_err_msg  := 'ps_next_ohorder_ic is empty or NULL.';
        RETURN NEXT;
        RETURN;
      END IF;

      IF ps_next_odorder_ic IS NULL OR TRIM(ps_next_odorder_ic) = cs_space THEN
        rn_status   := -2;
        rs_err_code := 'ld.E.LDP10143';
        rs_err_msg  := 'ps_next_odorder_ic is empty or NULL.';
        RETURN NEXT;
        RETURN;
      END IF;

    ----------------------------------------------------------------------------
    --  < STEP3 : Main Processing >
    ----------------------------------------------------------------------------
         IF EXISTS (
             SELECT 1
               FROM ld_trn_inv
              WHERE itemno   = ps_itemno
                AND supplier = ps_supplier
                AND usercd   = ps_usercd
         ) THEN
           NULL;
         ELSE
           rn_status   := -2;
           rs_err_code := 'ld.E.10012';
           rs_err_msg  := 'The item is not exist in inventory.';
           RETURN NEXT;
           RETURN;
         END IF;

         UPDATE ld_trn_inv
             SET next_ohorder_ic    = ps_next_ohorder_ic,
                 next_odorder_ic    = ps_next_odorder_ic,
                 latest_in_orderno  = CONCAT(ps_next_ohorder_ic, ps_next_odorder_ic),
                 update_counter     = COALESCE(update_counter, 0) + 1,
                 update_datetime    = ld_system_date,
                 update_author      = 'SYSTEM',
                 update_pgmid       = cs_pgmid
           WHERE itemno             = ps_itemno
             AND supplier           = ps_supplier
             AND usercd             = ps_usercd;

    ----------------------------------------------------------------------------
    --  < STEP4 : Return Value Setting >
    ----------------------------------------------------------------------------
    RETURN NEXT;
    RETURN;

  EXCEPTION
    ----------------------------------------------------------------------------
    --  Error Handle
    ----------------------------------------------------------------------------
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