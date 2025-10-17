--------------------------------------------------------------------------------
--@SEE << Workday Interval Calculation Function >>
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
--@SEE < Workday Interval Calculation Function >
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
--    @rn_interval                  < /O> INTEGER   : Interval Days
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LDYS0010(
    ps_calder_cd    VARCHAR,   --1
    ps_std_ymd      VARCHAR,   --2
    ps_apt_ymd      VARCHAR    --3
)
RETURNS TABLE(
    rn_status       INTEGER,   --1
    rs_sql_code     VARCHAR,   --2
    rs_err_code     VARCHAR,   --3
    rs_err_msg      VARCHAR,   --4
    rs_err_focus    VARCHAR,   --5
    rn_interval     INTEGER    --6
) AS
$$
DECLARE
    ln_year            INTEGER;
    ls_month           VARCHAR(2);
    ls_day             VARCHAR(2);
    ln_remainder       INTEGER;
    ls_leap_flag       VARCHAR(1);
    ls_calendar_data   gimac.le_mst_calendar.calendar_data%TYPE;
    ln_interval        INTEGER := 0;
    ld_std_date        DATE;
    ld_apt_date        DATE;
    ld_small_date      DATE;
    ld_large_date      DATE;
    ls_small_ym        VARCHAR(6);
    ls_large_ym        VARCHAR(6);
    ln_small_day       INTEGER;
    ln_large_day       INTEGER;
    ls_current_ym      VARCHAR(6);
BEGIN
    --------------------------------------------------------------------------------
    --  < STEP1 : Initialization >
    --------------------------------------------------------------------------------
    ln_year := 0;
    ln_remainder := 0;
    ln_interval := 0;
    ln_small_day := 0;
    ln_large_day := 0;

    ls_month := ' ';
    ls_day := ' ';
    ls_calendar_data := ' ';
    ls_current_ym := ' ';
    ls_small_ym := ' ';
    ls_large_ym := ' ';

    ld_small_date := NULL;
    ld_large_date := NULL;

    ls_leap_flag := ' ';

    rn_status := 0;
    rs_sql_code := ' ';
    rs_err_code := ' ';
    rs_err_msg := ' ';
    rs_err_focus := ' ';
    rn_interval := 0;

    IF ps_std_ymd IS NULL THEN ps_std_ymd := ' '; END IF;
    IF ps_apt_ymd IS NULL THEN ps_apt_ymd := ' '; END IF;

    --------------------------------------------------------------------------------
    --  < STEP2 : Argument Check >
    --------------------------------------------------------------------------------
    IF LENGTH(ps_std_ymd) != 8 OR ps_std_ymd !~ '^[0-9]{8}$' THEN
        rn_status := -2;
        rs_err_code := 'E.LDP10376';
        rs_err_msg := 'Date format is illegal.';
        rs_err_focus := 'LDYS0010';
        RETURN NEXT;
        RETURN;
    END IF;

    IF LENGTH(ps_apt_ymd) != 8 OR ps_apt_ymd !~ '^[0-9]{8}$' THEN
        rn_status := -2;
        rs_err_code := 'E.LDP10376';
        rs_err_msg := 'Date format is illegal.';
        rs_err_focus := 'LDYS0010';
        RETURN NEXT;
        RETURN;
    END IF;

    IF ps_calder_cd IS NULL OR ps_calder_cd = '' THEN
        rn_status := -2;
        rs_err_code := 'E.LDP10376';
        rs_err_msg := 'Date format is illegal.';
        rs_err_focus := 'LDYS0010';
        RETURN NEXT;
        RETURN;
    END IF;

    ln_year := SUBSTRING(ps_std_ymd, 1, 4)::INTEGER;
    ls_month := SUBSTRING(ps_std_ymd, 5, 2);
    ls_day := SUBSTRING(ps_std_ymd, 7, 2);

    ln_remainder := ln_year - (ln_year / 4) * 4;
    IF ln_remainder = 0 THEN
        ln_remainder := ln_year - (ln_year / 100) * 100;
        IF ln_remainder = 0 THEN
            ln_remainder := ln_year - (ln_year / 400) * 400;
            ls_leap_flag := CASE WHEN ln_remainder = 0 THEN '1' ELSE '0' END;
        ELSE
            ls_leap_flag := '1';
        END IF;
    ELSE
        ls_leap_flag := '0';
    END IF;

    IF ls_month IN ('01','03','05','07','08','10','12') THEN
        IF ls_day::INTEGER < 1 OR ls_day::INTEGER > 31 THEN
            rn_status := -2;
            rs_err_code := 'E.LDP10376';
            rs_err_msg := 'Date format is illegal.';
            rs_err_focus := 'LDYS0010';
            RETURN NEXT; RETURN;
        END IF;
    ELSIF ls_month = '02' THEN
        IF ls_leap_flag = '0' THEN
            IF ls_day::INTEGER < 1 OR ls_day::INTEGER > 28 THEN
                rn_status := -2; rs_err_code := 'E.LDP10376'; rs_err_msg := 'Date format is illegal.'; rs_err_focus := 'LDYS0010';
                RETURN NEXT; RETURN;
            END IF;
        ELSE
            IF ls_day::INTEGER < 1 OR ls_day::INTEGER > 29 THEN
                rn_status := -2; rs_err_code := 'E.LDP10376'; rs_err_msg := 'Date format is illegal.'; rs_err_focus := 'LDYS0010';
                RETURN NEXT; RETURN;
            END IF;
        END IF;
    ELSIF ls_month IN ('04','06','09','11') THEN
        IF ls_day::INTEGER < 1 OR ls_day::INTEGER > 30 THEN
            rn_status := -2; rs_err_code := 'E.LDP10376'; rs_err_msg := 'Date format is illegal.'; rs_err_focus := 'LDYS0010';
            RETURN NEXT; RETURN;
        END IF;
    ELSE
        rn_status := -2; rs_err_code := 'E.LDP10376'; rs_err_msg := 'Date format is illegal.'; rs_err_focus := 'LDYS0010';
        RETURN NEXT; RETURN;
    END IF;

    ld_std_date := TO_DATE(ps_std_ymd, 'YYYYMMDD');

    ln_year := SUBSTRING(ps_apt_ymd, 1, 4)::INTEGER;
    ls_month := SUBSTRING(ps_apt_ymd, 5, 2);
    ls_day := SUBSTRING(ps_apt_ymd, 7, 2);

    ln_remainder := ln_year - (ln_year / 4) * 4;
    IF ln_remainder = 0 THEN
        ln_remainder := ln_year - (ln_year / 100) * 100;
        IF ln_remainder = 0 THEN
            ln_remainder := ln_year - (ln_year / 400) * 400;
            ls_leap_flag := CASE WHEN ln_remainder = 0 THEN '1' ELSE '0' END;
        ELSE
            ls_leap_flag := '1';
        END IF;
    ELSE
        ls_leap_flag := '0';
    END IF;

    IF ls_month IN ('01','03','05','07','08','10','12') THEN
        IF ls_day::INTEGER < 1 OR ls_day::INTEGER > 31 THEN
            rn_status := -2; rs_err_code := 'E.LDP10376'; rs_err_msg := 'Date format is illegal.'; rs_err_focus := 'LDYS0010';
            RETURN NEXT; RETURN;
        END IF;
    ELSIF ls_month = '02' THEN
        IF ls_leap_flag = '0' THEN
            IF ls_day::INTEGER < 1 OR ls_day::INTEGER > 28 THEN
                rn_status := -2; rs_err_code := 'E.LDP10376'; rs_err_msg := 'Date format is illegal.'; rs_err_focus := 'LDYS0010';
                RETURN NEXT; RETURN;
            END IF;
        ELSE
            IF ls_day::INTEGER < 1 OR ls_day::INTEGER > 29 THEN
                rn_status := -2; rs_err_code := 'E.LDP10376'; rs_err_msg := 'Date format is illegal.'; rs_err_focus := 'LDYS0010';
                RETURN NEXT; RETURN;
            END IF;
        END IF;
    ELSIF ls_month IN ('04','06','09','11') THEN
        IF ls_day::INTEGER < 1 OR ls_day::INTEGER > 30 THEN
            rn_status := -2; rs_err_code := 'E.LDP10376'; rs_err_msg := 'Date format is illegal.'; rs_err_focus := 'LDYS0010';
            RETURN NEXT; RETURN;
        END IF;
    ELSE
        rn_status := -2; rs_err_code := 'E.LDP10376'; rs_err_msg := 'Date format is illegal.'; rs_err_focus := 'LDYS0010';
        RETURN NEXT; RETURN;
    END IF;

    ld_apt_date := TO_DATE(ps_apt_ymd, 'YYYYMMDD');

    --------------------------------------------------------------------------------
    --  < STEP3 : Main Processing >
    --------------------------------------------------------------------------------
    IF ld_std_date = ld_apt_date THEN
        ln_interval := 0;
        rn_interval := ln_interval;
        rn_status := 0;
        RETURN NEXT; RETURN;
    END IF;

    IF ld_std_date < ld_apt_date THEN
        ld_small_date := ld_std_date + 1;  -- date + int
        ld_large_date := ld_apt_date;
    ELSE
        ld_small_date := ld_apt_date;
        ld_large_date := ld_std_date - 1;
    END IF;

    ls_small_ym := TO_CHAR(ld_small_date, 'YYYYMM');
    ls_large_ym := TO_CHAR(ld_large_date, 'YYYYMM');
    ln_small_day := EXTRACT(DAY FROM ld_small_date)::INTEGER;
    ln_large_day := EXTRACT(DAY FROM ld_large_date)::INTEGER;

    IF ls_small_ym = ls_large_ym THEN
        SELECT calendar_data 
          INTO ls_calendar_data
          FROM gimac.le_mst_calendar
         WHERE calendar_code = ps_calder_cd 
           AND calendar_ym   = ls_small_ym;

        IF NOT FOUND THEN
            rn_status := 1; rs_err_code := ' '; rs_err_msg := ' '; rs_err_focus := ' ';
            RETURN NEXT; RETURN;
        END IF;

        FOR i IN ln_small_day .. ln_large_day LOOP
            IF SUBSTRING(ls_calendar_data, i, 1) = '0' THEN
                ln_interval := ln_interval + 1;
            END IF;
        END LOOP;
    END IF;

    IF ls_small_ym <> ls_large_ym THEN
        SELECT calendar_data 
          INTO ls_calendar_data
          FROM gimac.le_mst_calendar
         WHERE calendar_code = ps_calder_cd 
           AND calendar_ym   = ls_small_ym;

        IF NOT FOUND THEN
            rn_status := 1; rs_err_code := ' '; rs_err_msg := ' '; rs_err_focus := ' ';
            RETURN NEXT; RETURN;
        END IF;

        ln_large_day := EXTRACT(DAY FROM (date_trunc('month', ld_small_date)::date + INTERVAL '1 month - 1 day'))::INTEGER;
        FOR i IN ln_small_day .. ln_large_day LOOP
            IF SUBSTRING(ls_calendar_data, i, 1) = '0' THEN
                ln_interval := ln_interval + 1;
            END IF;
        END LOOP;

        SELECT calendar_data 
          INTO ls_calendar_data
          FROM gimac.le_mst_calendar
         WHERE calendar_code = ps_calder_cd 
           AND calendar_ym   = ls_large_ym;

        IF NOT FOUND THEN
            rn_status := 1; rs_err_code := ' '; rs_err_msg := ' '; rs_err_focus := ' ';
            RETURN NEXT; RETURN;
        END IF;

        ln_large_day := EXTRACT(DAY FROM ld_large_date)::INTEGER;
        FOR i IN 1 .. ln_large_day LOOP
            IF SUBSTRING(ls_calendar_data, i, 1) = '0' THEN
                ln_interval := ln_interval + 1;
            END IF;
        END LOOP;

        -- 中间整月（若存在）
        ls_current_ym := TO_CHAR((date_trunc('month', ld_small_date)::date + INTERVAL '1 month')::date, 'YYYYMM');
        WHILE ls_current_ym < ls_large_ym LOOP
            SELECT calendar_data 
              INTO ls_calendar_data
              FROM gimac.le_mst_calendar
             WHERE calendar_code = ps_calder_cd 
               AND calendar_ym   = ls_current_ym;

            IF NOT FOUND THEN
                rn_status := 1; rs_err_code := ' '; rs_err_msg := ' '; rs_err_focus := ' ';
                RETURN NEXT; RETURN;
            END IF;

            ln_large_day := EXTRACT(DAY FROM (TO_DATE(ls_current_ym || '01', 'YYYYMMDD') + INTERVAL '1 month - 1 day'))::INTEGER;
            FOR i IN 1 .. ln_large_day LOOP
                IF SUBSTRING(ls_calendar_data, i, 1) = '0' THEN
                    ln_interval := ln_interval + 1;
                END IF;
            END LOOP;

            ls_current_ym := TO_CHAR((TO_DATE(ls_current_ym || '01', 'YYYYMMDD') + INTERVAL '1 month')::date, 'YYYYMM');
        END LOOP;
    END IF;

    IF ld_std_date > ld_apt_date THEN
        ln_interval := 0 - ln_interval;
    END IF;

    --------------------------------------------------------------------------------
    --  < STEP4 : Return Value Setting >
    --------------------------------------------------------------------------------
    rn_interval := ln_interval;
    rn_status := 0;
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
            rs_err_focus      := 'LDYS0010';
        END IF;
        RETURN NEXT;
        RETURN;

    WHEN OTHERS THEN
        IF SQLSTATE IN ('22007', '22008') THEN
            rn_status       := -2;
            rs_sql_code     := SQLSTATE;
            rs_err_code     := 'E.LDP10376';
            rs_err_msg      := 'Date format is illegal.';
            rs_err_focus    := 'LDYS0010';
        ELSE
            rn_status       := -1;
            rs_sql_code     := SQLSTATE;
            rs_err_code     := ' ';
            rs_err_msg      := SQLERRM;
            rs_err_focus    := 'LDYS0010';
        END IF;
        RETURN NEXT;
        RETURN;
END;
$$
LANGUAGE 'plpgsql';