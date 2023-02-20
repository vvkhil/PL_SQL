drop table MyTable;

1)
CREATE TABLE MyTable (id NUMBER, val NUMBER);

---------------------------------------------------------------------------------------------------------------------------

2)
DECLARE
  i INT := 1;
BEGIN
  FOR i IN 1..10000 LOOP
    INSERT INTO MyTable (id, val) VALUES (i, TRUNC(DBMS_RANDOM.value(1, 1000000)));
  END LOOP;
END;

select * from MyTable;

---------------------------------------------------------------------------------------------------------------------------

3)
create or replace function comp_odd_even return VARCHAR2 IS
    even INT;
    odd INT;
begin
      select count(*) into even
      from   MyTable
      where  MOD(val, 2) = 0;
      
      select count(*) into odd
      from   MyTable
      where  MOD(val, 2) = 1;
      
      IF even > odd THEN
        return 'TRUE';
      ELSIF even < odd THEN
        return 'FALSE';
      ELSE
        RETURN 'EQUAL';
      END IF;
end comp_odd_even;
	

select count(*) from MyTable where mod(val, 2) = 0;
select count(*) from MyTable where mod(val, 2) = 1;

select comp_odd_even() from dual;

---------------------------------------------------------------------------------------------------------------------------

4)
create or replace function generate_insert_command (
  in_id in number,
  in_val in number
) return VARCHAR2 is
begin
  return 'INSERT INTO MyTable (id, val) VALUES (' || in_id || ', ' || in_val || ');';
end;

select generate_insert_command(10, 666) from dual;

---------------------------------------------------------------------------------------------------------------------------
5)

create or replace procedure insert_into_mytable (
  p_id in number,
  p_val in number
) as
begin
  insert into MyTable (id, val) values (p_id, p_val);
end;

EXECUTE insert_into_mytable(1,1);
***************************************************************************************************************************

create or replace procedure update_mytable (
  p_id in number,
  p_val in number
) as
begin
  update MyTable
  set val = p_val
  where id = p_id;
end;

EXECUTE update_mytable(2,1);
***************************************************************************************************************************

create or replace procedure delete_from_mytable (
  p_id in number
) as
begin
  delete from MyTable
  where id = p_id;
end;

EXECUTE delete_from_mytable(1);
---------------------------------------------------------------------------------------------------------------------------

6)
create or replace function calculate_annual_compensation (monthly_salary number, annual_bonus_percentage number)
return number
is
begin
  if monthly_salary <= 0 then
    RAISE_APPLICATION_ERROR(-20000, 'Invalid monthly salary');
  end if;

  if annual_bonus_percentage <= 0 then
    RAISE_APPLICATION_ERROR(-20000, 'Invalid annual bonus percentage');
  end if;

  return (1 + annual_bonus_percentage / 100) * 12 * monthly_salary;
end;

select calculate_annual_compensation(1500, 50) from dual;

