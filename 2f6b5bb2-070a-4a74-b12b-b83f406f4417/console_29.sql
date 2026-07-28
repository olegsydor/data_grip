SELECT e.employee_id,
       e.first_name,
       e.last_name,
       d.department_name,
       e.salary AS old_salary,
       e.salary * (1 + pctIncrease(e.department_id)) AS new_salary
  FROM employees   e,
       departments d
 WHERE e.department_id = d.department_id
 ORDER BY 1;

with dep as (select department_id, department_name, pctIncrease(e.department_id) as incr from departments)
SELECT e.employee_id,
       e.first_name,
       e.last_name,
       d.department_name,
       e.salary              AS old_salary,
       e.salary * (1 + incr) AS new_salary
FROM employees e,
     dep d
WHERE e.department_id = d.department_id
ORDER BY 1;

create table training.users
(
    id   int4 not null
        constraint users_pk primary key,
    info jsonb
);

insert into training.users
values ('Oleh', '{
  "Archi": "Dog",
  "Timosha": "Cat"
}')