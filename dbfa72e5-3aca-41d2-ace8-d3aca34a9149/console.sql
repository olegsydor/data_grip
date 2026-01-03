with base as (select rank() over (order by count(*) desc) as cnt_film,
                     array_agg(frst.film_id)              as film_ids,
                     frst.actor_id                        as first_actor_id,
                     sec.actor_id                         as second_actor_id
              from film_actor as frst
                       join film_actor as sec on sec.actor_id > frst.actor_id and sec.film_id = frst.film_id
              group by frst.actor_id, sec.actor_id
              )
select concat_ws(' ', fa.first_name, fa.last_name) as first_actor,
       concat_ws(' ', se.first_name, se.last_name) as second_actor,
       fm.title
from base
         join actor fa on fa.actor_id = base.first_actor_id
         join actor se on se.actor_id = base.second_actor_id
         join film fm on fm.film_id = any (base.film_ids)
where cnt_film = 1
order by 3;

