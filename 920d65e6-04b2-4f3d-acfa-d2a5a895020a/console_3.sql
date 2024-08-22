select mic_code,
       security_type,
       venue_exchange,
       business_name,
       ex_destination,
       venue_fix_code,
       exchange_code,
       is_exchange,
       applicable_spread_type,
       supports_bi,
       supports_cob
from blaze7_configuration.exchange_map x;

