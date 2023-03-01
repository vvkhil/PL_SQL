2)
create or replace trigger tr_students_unique_id
    before insert or update on students
    for each row
declare
    v_count int;
    pragma autonomous_transaction;
begin
    select count(*) into v_count
    from students
    where id = :new.id;

    if v_count > 0 then
        raise_application_error(-20001, 'ID должен быть уникальным');
    end if;
end;

-------------------------------------------------------------------------------------------

create sequence students_seq start with 1;

-------------------------------------------------------------------------------------------
2)+
create or replace trigger tr_students_auto_increment_id
    before insert on students
    for each row
declare
    pragma autonomous_transaction;
begin
    select students_seq.nextval into :new.id
    from dual;
end;

*******************************************************************************************
+
create or replace trigger tr_groups_unique_name
    before insert or update on groups
    for each row
declare
    v_count int;
    pragma autonomous_transaction;
begin
    select count(*) into v_count
    from groups
    where name = :new.name;

    if v_count > 0 then
        raise_application_error(-20001, 'NAME должен быть уникальным');
    end if;
end;

-------------------------------------------------------------------------------------------
3)+?
create or replace trigger tr_delete_group_fk
    before delete on groups
    for each row
begin
    delete from students where group_id = :old.id;
end;

*******************************************************************************************
+
create or replace trigger tr_insert_student_fk
    before insert on students
    for each row
declare
    v_count int;
begin
    select count(*) into v_count
    from groups
    where groups.id = :new.group_id;

    if v_count = 0 then
        raise_application_error(-20000, 'Group ID does not exist');
    end if;
end;

-------------------------------------------------------------------------------------------
4)+
create or replace trigger tr_students_logging
    after insert or update or delete on students
    for each row
declare
    v_username varchar2(30) := USER;
    v_date date := SYSDATE;
    v_operation varchar2(20);
begin
    if inserting then
        v_operation := 'INSERT';
        insert into students_log (username, date_of_action, operation, stud_id, stud_name, stud_group_id)
        values (v_username, v_date, v_operation, :new.id, :new.name, :new.group_id);
    elsif updating then
        v_operation := 'UPDATE';
        insert into students_log (username, date_of_action, operation, stud_id, stud_name, stud_group_id)
        values (v_username, v_date, v_operation, :new.id, :new.name, :new.group_id);
    elsif deleting then
        v_operation := 'DELETE';
        insert into students_log (username, date_of_action, operation, stud_id, stud_name, stud_group_id)
        values (v_username, v_date, v_operation, :old.id, :old.name, :old.group_id);
    end if;
end;

-------------------------------------------------------------------------------------------
5)
create or replace procedure restore_students_info_by_date (date_time in timestamp)
as
    cur_date date := SYSDATE;
begin
  delete from students;

  for stud in (select * from students_log where date_of_action <= date_time ORDER BY date_of_action ASC) LOOP
      if stud.operation = 'INSERT' then
        insert into students (id, name, group_id) values (stud.stud_id, stud.stud_name, stud.stud_group_id);
      elsif stud.operation = 'UPDATE' then
        update students set group_id = stud.stud_group_id, name = stud.stud_name where stud.stud_id = id;
      elsif stud.operation = 'DELETE' then
        delete from students where stud.stud_id = id;
      end if;
  end loop;

  delete from STUDENTS_LOG
  where DATE_OF_ACTION >= cur_date;

end;

-------------------------------------------------------------------------------------------
6)+
create or replace trigger tr_group_c_val_students_update
after update on students
for each row
begin
  if (:old.group_id != :new.group_id) then
    update groups set c_val = c_val - 1 where id = :old.group_id;
    update groups set c_val = c_val + 1 where id = :new.group_id;
  end if;
end;

-------------------------------------------------------------------------------------------
6)+
create or replace trigger tr_group_c_val_students_insert
after insert on students
for each row
begin
  update groups set c_val = c_val + 1 where id = :new.group_id;
end;

-------------------------------------------------------------------------------------------
6)+?
create or replace trigger tr_group_c_val_students_delete
after delete on students	
for each row
begin
  update groups set c_val = c_val - 1 where id = :old.group_id;
end;




