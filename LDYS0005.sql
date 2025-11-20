--------------------------------------------------------------------------------
--@SEE << CHECK OPERATION DAY >>
--    @ID      : LDYS0005
--
--    @Written : 1.0.0                   2025.10.14 Sun Sheng / YMSLX
--    --------------------------------------------------------------------------
--    @Update  : xxxxxxxxxxxx            xxxx.xx.xx xxxxxxxx / xx
--     Reason  : xxx
--              xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--    --------------------------------------------------------------------------
--
--    @Version : 1.0.0
--
----------------------------------------------------------------------------
--  < INPUT Parameter >
--    @ps_calder_cd          <I/ > VARCHAR : Calendar Code (VARCHAR)
--    @ps_std_ymd            <I/ > VARCHAR : Target Date (YYYYMMDD, VARCHAR)
--  < OUTPUT Parameter >
--    @rn_status             < /O> INTEGER : Return Code
--                                           (  0 : Normal        )
--                                           ( -1 : Sql Error     )
--                                           ( -2 : Program Error )
--    @rs_sql_code           < /O> VARCHAR : SQL Code
--    @rs_err_code           < /O> VARCHAR : Program Error Code
--    @rs_err_msg            < /O> VARCHAR : Error Message
--    @rs_err_focus          < /O> VARCHAR : Error Focus Program ID
--    @rn_is_operationday    < /O> INTEGER : 0:Operation Day, 1:Non-Operation Day, 2:Invalid Date
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0005(
      ps_calder_cd         VARCHAR  -- 1 カレンダーコード
    , ps_std_ymd           VARCHAR  -- 2 指定日
)
RETURNS TABLE(
      rn_status            INTEGER  -- 1 処理ステータス
    , rs_sql_code          VARCHAR  -- 2 SQLコード
    , rs_err_code          VARCHAR  -- 3 エラーコード
    , rs_err_msg           VARCHAR  -- 4 エラーメッセージ
    , rs_err_focus         VARCHAR  -- 5 エラー位置
    , rn_is_operationday   INTEGER  -- 6 稼働日かどうか
) AS
$BODY$
DECLARE
    ln_length              INTEGER;
    ln_counter             INTEGER;
    ls_char                VARCHAR;
    ln_is_operationday     INTEGER;
    ls_calendar_content    le_mst_calendar.calendar_data%TYPE;
    ls_char2               VARCHAR;
    ls_month               VARCHAR;
    ls_day                 VARCHAR;
    ln_day_idx             INTEGER;
    cs_pgmid               CONSTANT VARCHAR := 'LDYS0005';
    cs_space               CONSTANT VARCHAR := ' ';

BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    rn_status               := 0;
    rs_sql_code             := cs_space;
    rs_err_code             := cs_space;
    rs_err_msg              := cs_space;
    rs_err_focus            := cs_space;
    rn_is_operationday      := 0;

    ln_length               := LENGTH(TRIM(ps_std_ymd));
    ln_counter              := 1;
    ls_char                 := cs_space;
    ln_is_operationday      := 0;
    ls_calendar_content     := cs_space;
    ls_char2                := cs_space;

    ls_month                := cs_space;
    ls_day                  := cs_space;
    ln_day_idx              := 0;

    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    -- Argument Check
    WHILE ln_counter <= ln_length LOOP
        ls_char := SUBSTRING(TRIM(ps_std_ymd) FROM ln_counter FOR 1);
        IF ls_char < '0' OR ls_char > '9' THEN
            rn_is_operationday := 2;

            RETURN NEXT;
            RETURN;
        END IF;
        ln_counter := ln_counter + 1;
    END LOOP;

    IF ln_length <> 8 then
        rn_is_operationday := 2;

        RETURN NEXT;
        RETURN;
    END IF;

    ls_month := SUBSTRING(ps_std_ymd FROM 5 FOR 2);
    ls_day   := SUBSTRING(ps_std_ymd FROM 7 FOR 2);
    IF ls_month < '01' OR ls_month > '12' then
        rn_is_operationday := 2;

        RETURN NEXT;
        RETURN;
    END IF;

    IF ls_day < '01' OR ls_day > '31' THEN
        rn_is_operationday := 2;

        RETURN NEXT;
        RETURN;
    END IF;

    -- Daily work inspection
    IF EXISTS ( SELECT 1
                  FROM le_mst_calendar
                 WHERE calendar_code = ps_calder_cd
                   AND calendar_ym = SUBSTRING(ps_std_ymd FROM 1 FOR 6)
    ) THEN
        SELECT calendar_data
          INTO STRICT ls_calendar_content
          FROM le_mst_calendar
         WHERE calendar_code = ps_calder_cd
           AND calendar_ym = SUBSTRING(ps_std_ymd FROM 1 FOR 6);
    ELSE
        rs_err_code  :='ld.E.10011';
        rs_err_msg   :='Target date was not found in the calendar.';
        RAISE EXCEPTION ' ';
    END IF;

    --If the data exists
    ln_length  := LENGTH(TRIM(ps_std_ymd));
    ln_counter := 1;
    ls_char    := cs_space;
    ln_day_idx := CAST(SUBSTRING(ps_std_ymd FROM 7 FOR 2) AS INTEGER);

    WHILE ln_counter <= ln_length LOOP
        ls_char := SUBSTRING(ls_calendar_content FROM ln_counter FOR 1);
        IF  ln_counter = ln_day_idx THEN
            ls_char2  := ls_char;
            EXIT;
        END IF;
        ln_counter := ln_counter + 1;
    END LOOP;

    IF ls_char2 = '0' THEN
        ln_is_operationday := 0;
    ELSIF ls_char2 = '1' THEN
        ln_is_operationday := 1;
    ELSE
        ln_is_operationday := 2;
    END IF;

    -- Set return values
    rn_status           := 0;
    rs_sql_code         := cs_space;
    rs_err_code         := cs_space;
    rs_err_msg          := cs_space;
    rs_err_focus        := cs_space;
    rn_is_operationday  := ln_is_operationday;

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

    WHEN OTHERS THEN           -- FOR SQL ERROR
        rn_status           := -1;
        rs_sql_code         := SQLSTATE;
        rs_err_code         := cs_space;
        rs_err_msg          := SQLERRM;
        rs_err_focus        := cs_pgmid;
        rn_is_operationday  := 2;

        RETURN NEXT;
        RETURN;
END;
$BODY$
LANGUAGE 'plpgsql';