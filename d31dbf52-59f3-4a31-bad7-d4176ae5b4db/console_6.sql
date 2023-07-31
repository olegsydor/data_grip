  CREATE TEMP TABLE IF NOT EXISTS temp_lp_exch_recon_tb AS
    SELECT *
    FROM dash_bi.lp_exch_recon_tb
    WHERE date_id = :v_dateid ;

select * from temp_lp_exch_recon_tb;