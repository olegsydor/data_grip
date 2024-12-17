select CONCAT(coalesce(nullif(torm.[DashAlias], ''), case
                                                         when ISNULL(u.AORSUsername, Login) = 'BBNTRST' then 'NTRSCBOE'
                                                         else ISNULL(u.AORSUsername, Login)
    end),
              isnull(tor.GiveUpFirm, tr.[ExecutingBroker]),
              case
                  when isnull(tor.GiveUpFirm, '') = '792'
                      then case
                               when isnull(nullif(tor.CMTAFirm, ''), '949') = '949'
                                   then 'PTA'
                               else null
                      end
                  else null
                  end
       ) as account_name_gvp
from t torm;

SELECT CONCAT ('Happy ', 'Birthday ', 11, '/', '25', null) AS Result;