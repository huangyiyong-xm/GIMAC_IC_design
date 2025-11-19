--------------------------------------------------------------------------------
--@SEE << Work Days Calculate >>
--    @ID      : LDYS0010
--
--    @Written : 1.0.0                   2025.10.15 Zhang Yulin / YMSL
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
--    @ps_calder_cd                < /I> VARCHAR   : Calendar Code
--    @ps_std_ymd                  < /I> VARCHAR   : Standard Date (yyyyMMdd)
--    @ps_apt_ymd                  < /I> VARCHAR   : Appointment Date (yyyyMMdd)
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
--    @rn_interval                 < /O> INTEGER   : Interval Days
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0010(
    ps_calder_cd    VARCHAR,   --1. カレンダーコード
    ps_std_ymd      VARCHAR,   --2. 基準日
    ps_apt_ymd      VARCHAR    --3. 指定日
)
RETURNS TABLE(
    rn_status       INTEGER,   --1. ステータス
    rs_sql_code     VARCHAR,   --2. SQLコード
    rs_err_code     VARCHAR,   --3. エラーコード
    rs_err_msg      VARCHAR,   --4. エラーメッセージ
    rs_err_focus    VARCHAR,   --5. エラー位置
    rn_interval     INTEGER    --6. 間隔日数
) AS
$BODY$
DECLARE
    --------------------------------------------------
    --  < Definition Local Paramater >
    --------------------------------------------------
    ln_year            INTEGER;
    ls_month           VARCHAR(2);
    ls_day             VARCHAR(2);
    ln_remainder       INTEGER;
    ls_leap_flag       VARCHAR(1);
    ls_calendar_data   le_mst_calendar.calendar_data%TYPE;
    ln_interval        INTEGER := 0;
    ld_std_date        DATE;
    ld_apt_date        DATE;
    ld_small_date      DATE;
    ld_large_date      DATE;
    ls_small_ym        VARCHAR(6);
    ls_large_ym        VARCHAR(6);
    ls_current_ym      VARCHAR(6);
    rec_value          RECORD;
    cs_pgmid           CONSTANT VARCHAR := 'LDYS0010';
    cs_space           CONSTANT VARCHAR := ' ';
    -- Variable for loop
    i                  INTEGER;
BEGIN
    --------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------
    ln_year           := 0;
    ln_remainder      := 0;
    ln_interval       := 0;
    ls_month          := cs_space;
    ls_day            := cs_space;
    ls_leap_flag      := cs_space;
    ls_calendar_data  := cs_space;
    ls_small_ym       := cs_space;
    ls_large_ym       := cs_space;
    ls_current_ym     := cs_space;

    rn_status         := 0;
    rs_sql_code       := cs_space;
    rs_err_code       := cs_space;
    rs_err_msg        := cs_space;
    rs_err_focus      := cs_space;
    rn_interval       := 0;

    IF ps_std_ymd IS NULL THEN
        ps_std_ymd := cs_space;
    END IF;

    --------------------------------------------------
    --  < STEP2 : Main Processing >
    --------------------------------------------------
    -- Check if ps_std_ymd contains non-numeric characters
    IF ps_std_ymd !~ '^[0-9]*$' THEN
        rn_status := -2;
        rs_err_code := 'ld.E.LDP10114';
        rs_err_msg := 'Date format is illegal.';
        RAISE EXCEPTION ' ';
    END IF;

    -- Check if ps_apt_ymd contains non-numeric characters
    IF ps_apt_ymd !~ '^[0-9]*$' THEN
        rn_status := -2;
        rs_err_code := 'ld.E.LDP10114';
        rs_err_msg := 'Date format is illegal.';
        RAISE EXCEPTION ' ';
    END IF;

    ln_year := SUBSTRING(ps_std_ymd, 1, 4)::INTEGER;
    ls_month := SUBSTRING(ps_std_ymd, 5, 2);
    ls_day := SUBSTRING(ps_std_ymd, 7, 2);

    ln_remainder := ln_year - (ln_year / 4) * 4;
    IF ln_remainder = 0 THEN
        ln_remainder := ln_year / 100;
        ln_remainder := ln_year - (ln_remainder * 100);
        IF ln_remainder = 0 THEN
            ln_remainder := ln_year / 400;
            ln_remainder := ln_year - (ln_remainder * 400);
            IF ln_remainder = 0 THEN
                ls_leap_flag := '1';
            ELSE
                ls_leap_flag := '0';
            END IF;
        ELSE
            ls_leap_flag := '1';
        END IF;
    ELSE
        ls_leap_flag := '0';
    END IF;

    IF ls_month IN ('01', '03', '05', '07', '08', '10', '12') THEN
        IF ls_day::INTEGER < 1 OR ls_day::INTEGER > 31 THEN
            rn_status := -2;
            rs_err_code := 'ld.E.LDP10114';
            rs_err_msg := 'Date format is illegal.';
            RAISE EXCEPTION ' ';
        END IF;
    ELSIF ls_month = '02' THEN
        IF ls_leap_flag = '0' THEN
            IF ls_day::INTEGER < 1 OR ls_day::INTEGER > 28 THEN
                rn_status := -2;
                rs_err_code := 'ld.E.LDP10114';
                rs_err_msg := 'Date format is illegal.';
                RAISE EXCEPTION ' ';
            END IF;
        ELSE
            IF ls_day::INTEGER < 1 OR ls_day::INTEGER > 29 THEN
                rn_status := -2;
                rs_err_code := 'ld.E.LDP10114';
                rs_err_msg := 'Date format is illegal.';
                RAISE EXCEPTION ' ';
            END IF;
        END IF;
    ELSIF ls_month IN ('04', '06', '09', '11') THEN
        IF ls_day::INTEGER < 1 OR ls_day::INTEGER > 30 THEN
            rn_status := -2;
            rs_err_code := 'ld.E.LDP10114';
            rs_err_msg := 'Date format is illegal.';
            RAISE EXCEPTION ' ';
        END IF;
    ELSE
        rn_status := -2;
        rs_err_code := 'ld.E.LDP10114';
        rs_err_msg := 'Date format is illegal.';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_apt_ymd IS NULL THEN
        ps_apt_ymd := cs_space;
    END IF;
    ln_year := SUBSTRING(ps_apt_ymd, 1, 4)::INTEGER;
    ls_month := SUBSTRING(ps_apt_ymd, 5, 2);
    ls_day := SUBSTRING(ps_apt_ymd, 7, 2);

    ln_remainder := ln_year / 4;
    ln_remainder := ln_year - (ln_remainder * 4);
    IF ln_remainder = 0 THEN
        ln_remainder := ln_year / 100;
        ln_remainder := ln_year - ln_remainder * 100;
        IF ln_remainder = 0 THEN
            ln_remainder := ln_year / 400;
            ln_remainder := ln_year - ln_remainder * 400;
            IF ln_remainder = 0 THEN
                ls_leap_flag := '1';
            ELSE
                ls_leap_flag := '0';
            END IF;
        ELSE
            ls_leap_flag := '1';
        END IF;
    ELSE
        ls_leap_flag := '0';
    END IF;

    IF ls_month IN ('01', '03', '05', '07', '08', '10', '12') THEN
        IF ls_day::INTEGER < 1 OR ls_day::INTEGER > 31 THEN
            rn_status := -2;
            rs_err_code := 'ld.E.LDP10114';
            rs_err_msg := 'Date format is illegal.';
            RAISE EXCEPTION ' ';
        END IF;
    ELSIF ls_month = '02' THEN
        IF ls_leap_flag = '0' THEN
            IF ls_day::INTEGER < 1 OR ls_day::INTEGER > 28 THEN
                rn_status := -2;
                rs_err_code := 'ld.E.LDP10114';
                rs_err_msg := 'Date format is illegal.';
                RAISE EXCEPTION ' ';
            END IF;
        ELSE
            IF ls_day::INTEGER < 1 OR ls_day::INTEGER > 29 THEN
                rn_status := -2;
                rs_err_code := 'ld.E.LDP10114';
                rs_err_msg := 'Date format is illegal.';
                RAISE EXCEPTION ' ';
            END IF;
        END IF;
    ELSIF ls_month IN ('04', '06', '09', '11') THEN
        IF ls_day::INTEGER < 1 OR ls_day::INTEGER > 30 THEN
            rn_status := -2;
            rs_err_code := 'ld.E.LDP10114';
            rs_err_msg := 'Date format is illegal.';
            RAISE EXCEPTION ' ';
        END IF;
    ELSE
        rn_status := -2;
        rs_err_code := 'ld.E.LDP10114';
        rs_err_msg := 'Date format is illegal.';
        RAISE EXCEPTION ' ';
    END IF;

    IF ps_std_ymd = ps_apt_ymd THEN
        ln_interval := 0;
    ELSE
        ld_std_date := TO_DATE(SUBSTRING(ps_std_ymd, 1, 4) || '-' || SUBSTRING(ps_std_ymd, 5, 2) || '-' || SUBSTRING(ps_std_ymd, 7, 2), 'YYYY-MM-DD');
        ld_apt_date := TO_DATE(SUBSTRING(ps_apt_ymd, 1, 4) || '-' || SUBSTRING(ps_apt_ymd, 5, 2) || '-' || SUBSTRING(ps_apt_ymd, 7, 2), 'YYYY-MM-DD');
        
        IF ps_std_ymd < ps_apt_ymd THEN
            ld_small_date := ld_std_date + 1;
            ld_large_date := ld_apt_date;
        ELSE
            ld_small_date := ld_apt_date;
            ld_large_date := ld_std_date - 1;
        END IF;

        ls_small_ym := TO_CHAR(ld_small_date, 'YYYYMM');
        ls_large_ym := TO_CHAR(ld_large_date, 'YYYYMM');

        IF ls_small_ym = ls_large_ym THEN
            IF NOT EXISTS (
                SELECT 1
                  FROM le_mst_calendar
                 WHERE calendar_code = ps_calder_cd
                   AND calendar_ym   = ls_small_ym
            ) THEN
                rn_status := -2;
                rs_err_code := 'ld.E.LDP10115';
                rs_err_msg := 'The date is not found in calendar.';
                RAISE EXCEPTION ' ';
            END IF;

            SELECT calendar_data
              INTO ls_calendar_data
              FROM le_mst_calendar
             WHERE calendar_code = ps_calder_cd
               AND calendar_ym   = ls_small_ym;

            FOR i IN EXTRACT(DAY FROM ld_small_date)::INTEGER .. EXTRACT(DAY FROM ld_large_date)::INTEGER LOOP
                IF SUBSTRING(ls_calendar_data, i, 1) = '0' THEN
                    ln_interval := ln_interval + 1;
                END IF;
            END LOOP;
        ELSE
            IF NOT EXISTS (
                SELECT 1
                  FROM le_mst_calendar
                 WHERE calendar_code = ps_calder_cd
                   AND calendar_ym   = ls_small_ym
            ) THEN
                rn_status := -2;
                rs_err_code := 'ld.E.LDP10115';
                rs_err_msg := 'The date is not found in calendar.';
                RAISE EXCEPTION ' ';
            END IF;

            SELECT calendar_data
              INTO ls_calendar_data
              FROM le_mst_calendar
             WHERE calendar_code = ps_calder_cd
               AND calendar_ym   = ls_small_ym;

            FOR i IN EXTRACT(DAY FROM ld_small_date)::INTEGER .. 31 LOOP
                IF i <= LENGTH(ls_calendar_data) AND SUBSTRING(ls_calendar_data, i, 1) = '0' THEN
                    ln_interval := ln_interval + 1;
                END IF;
            END LOOP;

            FOR rec_value IN
                SELECT calendar_data
                  FROM le_mst_calendar
                 WHERE calendar_code = ps_calder_cd
                   AND calendar_ym > ls_small_ym
                   AND calendar_ym < ls_large_ym
                 ORDER BY calendar_ym
            LOOP
                FOR i IN 1 .. 31 LOOP
                    IF i <= LENGTH(rec_value.calendar_data) AND SUBSTRING(rec_value.calendar_data, i, 1) = '0' THEN
                        ln_interval := ln_interval + 1;
                    END IF;
                END LOOP;
            END LOOP;

            IF NOT EXISTS (
                SELECT 1
                  FROM le_mst_calendar
                 WHERE calendar_code = ps_calder_cd
                   AND calendar_ym   = ls_large_ym
            ) THEN
                rn_status := -2;
                rs_err_code := 'ld.E.LDP10115';
                rs_err_msg := 'The date is not found in calendar.';
                RAISE EXCEPTION ' ';
            END IF;

            SELECT calendar_data
              INTO ls_calendar_data
              FROM le_mst_calendar
             WHERE calendar_code = ps_calder_cd
               AND calendar_ym   = ls_large_ym;

            FOR i IN 1 .. EXTRACT(DAY FROM ld_large_date)::INTEGER LOOP
                IF i <= LENGTH(ls_calendar_data) AND SUBSTRING(ls_calendar_data, i, 1) = '0' THEN
                    ln_interval := ln_interval + 1;
                END IF;
            END LOOP;
        END IF;

        IF ps_std_ymd > ps_apt_ymd THEN
            ln_interval := 0 - ln_interval;
        END IF;
    END IF;

    --------------------------------------------------
    --  < STEP3 : Return Value Setting >
    --------------------------------------------------
    rn_interval := ln_interval;
    rn_status := 0;
    RETURN NEXT;
    RETURN;

EXCEPTION
    --------------------------------------------------
    --  Error Handle
    --------------------------------------------------
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