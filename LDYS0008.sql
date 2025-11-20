--------------------------------------------------------------------------------
--@SEE << TP OPERATION NO NUMBERING >>
--    @ID      : LDYS0008
--
--    @Written : 1.0.0                   2025.11.10 Sun Sheng / YMSLX
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
--  < OUTPUT Parameter >
--    @rn_status                   < /O> INTEGER   : Return Code
--                                                   (  0 : Normal        )
--                                                   ( -1 : Sql Error     )
--                                                   ( -2 : Program Error )
--    @rs_sql_code                 < /O> VARCHAR   : Sql Error Code
--    @rs_err_code                 < /O> VARCHAR   : Program Error Code
--    @rs_err_msg                  < /O> VARCHAR   : Error Message
--    @rs_err_focus                < /O> VARCHAR   : Error Focus
--    @rn_tp_operation_no          < /O> INTEGER   : TP Operation No
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0008(
    ps_user_id        VARCHAR                  --1. ユーザーID
)
RETURNS TABLE(
    rn_status            INTEGER,              --1. 処理ステータス
    rs_sql_code          VARCHAR,              --2. SQLコード
    rs_err_code          VARCHAR,              --3. エラーコード
    rs_err_msg           VARCHAR,              --4. エラーメッセージ
    rs_err_focus         VARCHAR,              --5. エラー位置
    rn_tp_operation_no   INTEGER               --6. TP処理番号
) AS
$BODY$
DECLARE
    --------------------------------------------------
    --  < Definition Local Paramater >
    --------------------------------------------------
    ln_tp_operation_no          ld_mst_tp_num.tp_operation_no%TYPE;
    ln_num_range_from           ld_mst_tp_num.num_range_from%TYPE;
    ln_num_range_to             ld_mst_tp_num.num_range_to%TYPE;
    ld_update_datetime          ld_mst_tp_num.update_datetime%TYPE;

    cs_pgmid                    CONSTANT VARCHAR := 'LDYS0008';
    cs_space                    CONSTANT VARCHAR := ' ';
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    /* Return Value Set */
    rn_status           := 0;
    rs_sql_code         := cs_space;
    rs_err_code         := cs_space;
    rs_err_msg          := cs_space;
    rs_err_focus        := cs_space;
    rn_tp_operation_no  := 0;

    /* Variable Initialization */
    ln_tp_operation_no  := 0;
    ln_num_range_from   := 0;
    ln_num_range_to     := 0;
    ld_update_datetime  := NOW();

    --------------------------------------------------
    --  < STEP2 : Main Process >
    --------------------------------------------------
    /* User ID Check */
    IF ps_user_id IS NULL OR TRIM(ps_user_id) = '' THEN
        rs_err_code     := 'ld.E.LDP10110';
        rs_err_msg      := 'Specify the User ID.';
        RAISE EXCEPTION ' ';
    END IF;

    /* 2.3.1 TP Operation No Numbering */

    /* Check TP Operation No Numbering File existence */
    IF EXISTS ( SELECT 1
                  FROM ld_mst_tp_num ) THEN

        /* Retrieve TP Operation No Numbering File data */
        SELECT tp_operation_no
             , num_range_from
             , num_range_to
          INTO STRICT ln_tp_operation_no
             , ln_num_range_from
             , ln_num_range_to
          FROM ld_mst_tp_num;

        /* Set current TP Operation No to return value */
        rn_tp_operation_no := ln_tp_operation_no;

        /* Calculate next TP Operation No */
        ln_tp_operation_no := ln_tp_operation_no + 1;
        IF ln_tp_operation_no > ln_num_range_to THEN
            ln_tp_operation_no := ln_num_range_from;
        END IF;

        /* Update TP Operation No Numbering File */
        UPDATE ld_mst_tp_num
           SET tp_operation_no = ln_tp_operation_no,
               update_author   = ps_user_id,
               update_counter  = COALESCE(update_counter, 0) + 1,
               update_datetime = ld_update_datetime;
    ELSE
        /* Data not found error */
        rs_err_code := 'ld.E.LDP10134';
        rs_err_msg  := 'Target data does not exist in the'
                    ||' TP Operation No Numbering File table.';
        RAISE EXCEPTION ' ';
    END IF;

    --------------------------------------------------
    --  < STEP3 : Return Value Processing >
    --------------------------------------------------
    RETURN NEXT;
    RETURN;

EXCEPTION
   WHEN RAISE_EXCEPTION THEN
        IF rn_status <> 0 THEN  -- FOR CALL SP ERROR
            NULL;
        ELSE                    -- FOR PGM ERROR
            rn_status         :=  -2;
            rs_sql_code       := cs_space;
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
LANGUAGE 'plpgsql';
