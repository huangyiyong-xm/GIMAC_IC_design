<<<<<<< HEAD
--------------------------------------------------------------------------------
--    @SEE << USER NAME GET >>
--    @ID      : LDYS0009
--
--    @Written : 1.0.0                   2025.11.20 Sun Sheng / YMSLX
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
--    @ps_userid                 <I/ > VARCHAR    : User ID
--    @ps_locate                 <I/ > VARCHAR    : Location (01:Japanese/02:English)
--  < OUTPUT Parameter >
--    @rn_status                 < /O> INTEGER    : Return Code
--                                               (  0 : Normal End     )
--                                               ( -1 : Abnormal End   )
--                                               ( -2 : PGM Error      )
--    @rs_sql_code               < /O> VARCHAR    : SQL Error Code
--    @rs_err_code               < /O> VARCHAR    : Program Error Code
--    @rs_err_msg                < /O> VARCHAR    : Error Message
--    @rs_err_focus              < /O> VARCHAR    : Error Focus
--    @rs_username               < /O> VARCHAR    : User Name
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0009(
    ps_userid                 VARCHAR  -- 1 ユーザーID
  , ps_locate                 VARCHAR  -- 2 ロケーション (01:日本語/02:英語)
)
RETURNS TABLE(
    rn_status                 INTEGER  -- 1 ステータス
  , rs_sql_code               VARCHAR  -- 2 SQLコード
  , rs_err_code               VARCHAR  -- 3 エラーコード
  , rs_err_msg                VARCHAR  -- 4 エラーメッセージ
  , rs_err_focus              VARCHAR  -- 5 エラー位置
  , rs_username               VARCHAR  -- 6 ユーザ名称
) AS
$BODY$
DECLARE
    ls_username                 lz_if_user_mst.local_nm%TYPE;

    cs_space                    CONSTANT VARCHAR := ' ';
    cs_pgmid                    CONSTANT VARCHAR := 'LDYS0009';

BEGIN
--------------------------------------------------------------------------------
------  < STEP1 : Initialization >
--------------------------------------------------------------------------------
    /* Return Value Set */
    rn_status       :=   0;
    rs_sql_code     := cs_space;
    rs_err_code     := cs_space;
    rs_err_msg      := cs_space;
    rs_err_focus    := cs_space;
    rs_username     := cs_space;

    /* Variable Initialization */
    ls_username     := cs_space;

/* STEP2 : Argument Check */
    IF ps_userid IS NULL OR TRIM(ps_userid) = '' THEN
        rs_err_code  := 'ld.E.LDP10110';
        rs_err_msg   := 'Specify the User ID.';
        RAISE EXCEPTION ' ';
    END IF;

--------------------------------------------------------------------------------
------  < STEP2 : Main Processing >
--------------------------------------------------------------------------------
    IF ps_locate = '01' THEN
        IF EXISTS (
            SELECT 1
              FROM lz_if_user_mst
             WHERE user_id = ps_userid
        ) THEN
            SELECT local_nm
              INTO STRICT ls_username
              FROM lz_if_user_mst
             WHERE user_id = ps_userid;
        ELSE
            ls_username := cs_space;
        END IF;
    ELSE
        IF EXISTS (
            SELECT 1
              FROM lz_if_user_mst
             WHERE user_id = ps_userid
        ) THEN
            SELECT en_nm
              INTO STRICT ls_username
              FROM lz_if_user_mst
             WHERE user_id = ps_userid;
        ELSE
            ls_username := cs_space;
        END IF;
    END IF;

--------------------------------------------------------------------------------
------  < STEP3 : Return Value Processing >
--------------------------------------------------------------------------------
    rs_username := ls_username;

    RETURN NEXT;
    RETURN;

EXCEPTION
    WHEN RAISE_EXCEPTION THEN
        IF rn_status <> 0 THEN  -- FOR CALL SP ERROR
            NULL;
        ELSE                    -- FOR PGM ERROR
            rn_status         :=  -2;
            rs_sql_code       := cs_space;
            rs_err_focus      := cs_pgmid;
        END IF;

        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN
        rn_status    := -1;
        rs_sql_code  := SQLSTATE;
        rs_err_code  := cs_space;
        rs_err_msg   := SQLERRM;
        rs_err_focus := cs_space;

        RETURN NEXT;
        RETURN;
END;
$BODY$
=======
--------------------------------------------------------------------------------
--    @SEE << USER NAME GET >>
--    @ID      : LDYS0009
--
--    @Written : 1.0.0                   2025.11.20 Sun Sheng / YMSLX
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
--    @ps_userid                 <I/ > VARCHAR    : User ID
--    @ps_locate                 <I/ > VARCHAR    : Location (01:Japanese/02:English)
--  < OUTPUT Parameter >
--    @rn_status                 < /O> INTEGER    : Return Code
--                                               (  0 : Normal End     )
--                                               ( -1 : Abnormal End   )
--                                               ( -2 : PGM Error      )
--    @rs_sql_code               < /O> VARCHAR    : SQL Error Code
--    @rs_err_code               < /O> VARCHAR    : Program Error Code
--    @rs_err_msg                < /O> VARCHAR    : Error Message
--    @rs_err_focus              < /O> VARCHAR    : Error Focus
--    @rs_username               < /O> VARCHAR    : User Name
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0009(
    ps_userid                 VARCHAR  -- 1 ユーザーID
  , ps_locate                 VARCHAR  -- 2 ロケーション (01:日本語/02:英語)
)
RETURNS TABLE(
    rn_status                 INTEGER  -- 1 ステータス
  , rs_sql_code               VARCHAR  -- 2 SQLコード
  , rs_err_code               VARCHAR  -- 3 エラーコード
  , rs_err_msg                VARCHAR  -- 4 エラーメッセージ
  , rs_err_focus              VARCHAR  -- 5 エラー位置
  , rs_username               VARCHAR  -- 6 ユーザ名称
) AS
$BODY$
DECLARE
    ls_username                 lz_if_user_mst.local_nm%TYPE;

    cs_space                    CONSTANT VARCHAR := ' ';
    cs_pgmid                    CONSTANT VARCHAR := 'LDYS0009';

BEGIN
--------------------------------------------------------------------------------
------  < STEP1 : Initialization >
--------------------------------------------------------------------------------
    /* Return Value Set */
    rn_status       :=   0;
    rs_sql_code     := cs_space;
    rs_err_code     := cs_space;
    rs_err_msg      := cs_space;
    rs_err_focus    := cs_space;
    rs_username     := cs_space;

    /* Variable Initialization */
    ls_username     := cs_space;

/* STEP2 : Argument Check */
    IF ps_userid IS NULL OR TRIM(ps_userid) = '' THEN
        rs_err_code  := 'ld.E.LDP10110';
        rs_err_msg   := 'Specify the User ID.';
        RAISE EXCEPTION ' ';
    END IF;

--------------------------------------------------------------------------------
------  < STEP2 : Main Processing >
--------------------------------------------------------------------------------
    IF ps_locate = '01' THEN
        IF EXISTS (
            SELECT 1
              FROM lz_if_user_mst
             WHERE user_id = ps_userid
        ) THEN
            SELECT local_nm
              INTO STRICT ls_username
              FROM lz_if_user_mst
             WHERE user_id = ps_userid;
        ELSE
            ls_username := cs_space;
        END IF;
    ELSE
        IF EXISTS (
            SELECT 1
              FROM lz_if_user_mst
             WHERE user_id = ps_userid
        ) THEN
            SELECT en_nm
              INTO STRICT ls_username
              FROM lz_if_user_mst
             WHERE user_id = ps_userid;
        ELSE
            ls_username := cs_space;
        END IF;
    END IF;

--------------------------------------------------------------------------------
------  < STEP3 : Return Value Processing >
--------------------------------------------------------------------------------
    rs_username := ls_username;

    RETURN NEXT;
    RETURN;

EXCEPTION
    WHEN RAISE_EXCEPTION THEN
        IF rn_status <> 0 THEN  -- FOR CALL SP ERROR
            NULL;
        ELSE                    -- FOR PGM ERROR
            rn_status         :=  -2;
            rs_sql_code       := cs_space;
            rs_err_focus      := cs_pgmid;
        END IF;

        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN
        rn_status    := -1;
        rs_sql_code  := SQLSTATE;
        rs_err_code  := cs_space;
        rs_err_msg   := SQLERRM;
        rs_err_focus := cs_space;

        RETURN NEXT;
        RETURN;
END;
$BODY$
>>>>>>> 5722c70f339d04755a3363fef9bc299892b95fde
LANGUAGE 'plpgsql';