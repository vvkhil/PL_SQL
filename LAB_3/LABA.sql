create or replace procedure check_fk_constraints (
    dev_schema in varchar2,
    prod_schema in varchar2
)
as
    cursor cur_fk_cons is
        select distinct cons.constraint_name, cols.table_name, cols.column_name
        from all_constraints cons
        join all_cons_columns cols on cons.owner = cols.owner and cons.table_name = cols.table_name and cons.constraint_name = cols.constraint_name
        where cons.constraint_type = 'R' and cols.owner = dev_schema;

    v_sql varchar2(4000);
    v_fk_cons_name varchar2(30);
    v_table_name varchar2(30);
    v_column_name varchar2(30);
begin
    for rec_fk_cons in cur_fk_cons loop
    begin
        select rec_fk_cons.constraint_name, rec_fk_cons.table_name, rec_fk_cons.column_name
        into v_fk_cons_name, v_table_name, v_column_name
        from dual
        where not exists (
            select 1
            from all_constraints cons
            join all_cons_columns cols on cons.owner = cols.owner and cons.table_name = cols.table_name and cons.constraint_name = cols.constraint_name and cols.column_name = v_column_name
            where cons.constraint_type = 'r' and cols.owner = prod_schema and cols.table_name = v_table_name and cons.constraint_name = v_fk_cons_name
        );

        if v_fk_cons_name is not null then
            -- create foreign key constraint in prod_schema
            v_sql := 'alter table ' || prod_schema || '.' || v_table_name ||
                     ' add constraint ' || v_fk_cons_name || ' foreign key (' || v_column_name || ') ' ||
                     ' references ' || prod_schema || '.' || substr(v_fk_cons_name, 4) ||
                     ' on delete cascade';
            dbms_output.put_line(v_sql);
        end if;
    exception
      when others then
        dbms_output.put_line('Error removing foreign key ' || rec_fk_cons.constraint_name || ' from table ' || rec_fk_cons.table_name || ': ' || sqlerrm);
    end;
    end loop;

    for rec_fk_cons in (
        select distinct cons.constraint_name, cols.table_name, cols.column_name
        from all_constraints cons
        join all_cons_columns cols on cons.owner = cols.owner and cons.table_name = cols.table_name and cons.constraint_name = cols.constraint_name
        where cons.constraint_type = 'R' and cols.owner = prod_schema
    ) loop
    begin
        select rec_fk_cons.constraint_name, rec_fk_cons.table_name, rec_fk_cons.column_name
        into v_fk_cons_name, v_table_name, v_column_name
        from dual
        where not exists (
            select 1
            from all_constraints cons
            join all_cons_columns cols on cons.owner = cols.owner and cons.table_name = cols.table_name and cons.constraint_name = cols.constraint_name and cols.column_name = v_column_name
            where cons.constraint_type = 'R' and cols.owner = dev_schema and cols.table_name = v_table_name and cons.constraint_name = v_fk_cons_name
        );

        if v_fk_cons_name is not null then
            -- drop foreign key constraint from prod_schema
            v_sql := 'alter table ' || prod_schema || '.' || v_table_name ||
                     ' drop constraint ' || v_fk_cons_name;
            dbms_output.put_line(v_sql);
        end if;
    exception
      when others then
        dbms_output.put_line('Error removing foreign key ' || rec_fk_cons.constraint_name || ' from table ' || rec_fk_cons.table_name || ': ' || sqlerrm);
    end;
    end loop;
end;


create or replace procedure search_for_circular_foreign_key_references(
    schema_name in varchar2
) authid current_user is
    v_count number;
begin
    select count(*) into v_count from (with table_hierarchy as (select child_owner, child_table, parent_owner, parent_table
                                         from (select owner             child_owner,
                                                      table_name        child_table,
                                                      r_owner           parent_owner,
                                                      r_constraint_name constraint_name
                                               from all_constraints
                                               where constraint_type = 'R'
                                                 and owner = schema_name)
                                                  join (select owner parent_owner, constraint_name, table_name parent_table
                                                        from all_constraints
                                                        where constraint_type = 'P'
                                                          and owner = schema_name)
                                                       using (parent_owner, constraint_name))
                select distinct child_owner, child_table
                from (select *
                      from table_hierarchy
                      where (child_owner, child_table) in (select parent_owner, parent_table
                                                           from table_hierarchy)) a
                where connect_by_iscycle = 1
                connect by nocycle (prior child_owner, prior child_table)
                                       = ((parent_owner, parent_table))
                );

    if v_count > 0 then
        dbms_output.put_line('circular foreign key reference detected in ' || schema_name || ' schema.');
    end if;
end;

create or replace procedure compare_procedures (
    dev_schema in varchar2,
    prod_schema in varchar2
)
authid current_user
as
  v_script varchar2(4000);
  v_count number;
begin
  for proc in (select object_name
               from all_procedures
               where owner = dev_schema
               minus
               select object_name
               from all_procedures
               where owner = prod_schema)
  loop
    dbms_output.put_line('Procedure ' || proc.object_name || ' is in ' || dev_schema || ' but not in ' || prod_schema);
  end loop;

    for dev_proc in (select object_name, dbms_metadata.get_ddl('PROCEDURE', object_name, dev_schema) as proc_text from all_objects where object_type = 'PROCEDURE' and owner = dev_schema)
    loop
        v_count := 0;
        select count(*) into v_count from all_objects where object_type = 'PROCEDURE' and object_name = dev_proc.object_name and owner = prod_schema;
        if v_count = 0 then
            v_script := dev_proc.proc_text;
            v_script := replace(v_script, dev_schema, prod_schema);
            dbms_output.put_line(v_script);
        end if;
    end loop;

    -- drop unnecessary procedures from the prod schema
    for prod_proc in (select object_name from all_objects where object_type = 'PROCEDURE' and owner = prod_schema) loop
        v_count := 0;
        select count(*) into v_count from all_objects where object_type = 'PROCEDURE' and object_name = prod_proc.object_name and owner = dev_schema;
        if v_count = 0 then
            dbms_output.put_line('drop procedure ' || prod_schema || '.' || prod_proc.object_name);
        end if;
    end loop;
end;

create or replace procedure compare_functions (
    dev_schema in varchar2,
    prod_schema in varchar2
)
authid current_user
as
    v_script varchar2(4000);
        v_count number;
begin
  for func in (select distinct name
               from all_source
               where all_source.type = 'FUNCTION'
               and owner = dev_schema
               minus
               select distinct name
               from all_source
               where all_source.type = 'FUNCTION'
               and owner = prod_schema)
  loop
    dbms_output.put_line('function ' || func.name || ' is in ' || dev_schema || ' but not in ' || prod_schema);
  end loop;

    for dev_func in (select object_name, dbms_metadata.get_ddl('FUNCTION', object_name, dev_schema) as func_text from all_objects where object_type = 'FUNCTION' and owner = dev_schema)
    loop
        v_count := 0;
        select count(*) into v_count
        from all_objects
        where object_type = 'FUNCTION' and object_name = dev_func.object_name and owner = prod_schema;
        if v_count = 0 then
            v_script := dev_func.func_text;
            v_script := replace(v_script, dev_schema, prod_schema);
            dbms_output.put_line(v_script);
        end if;
    end loop;
    for prod_func in (select object_name from all_objects where object_type = 'FUNCTION' and owner = prod_schema) loop
        v_count := 0;
        select count(*) into v_count
        from all_objects
        where object_type = 'FUNCTION' and object_name = prod_func.object_name and owner = dev_schema;
        if v_count = 0 then
            dbms_output.put_line('drop function ' || prod_func.object_name);
        end if;
    end loop;
end;

create or replace procedure compare_indexes (dev_schema in varchar2, prod_schema in varchar2) authid current_user is
    v_script varchar2(32767);
    v_count pls_integer := 0;
begin
  for i in (select index_name from all_indexes where table_owner = dev_schema and owner = 'SYSTEM' minus select index_name from all_indexes where table_owner = prod_schema and owner = 'SYSTEM') loop
    dbms_output.put_line('index ' || i.index_name || ' exists in ' || dev_schema || ' but not in ' || prod_schema);
  end loop;

  for i in (select index_name from all_indexes where table_owner = prod_schema and owner = 'SYSTEM' minus select index_name from all_indexes where table_owner = dev_schema and owner = 'SYSTEM') loop
    dbms_output.put_line('index ' || i.index_name || ' exists in ' || prod_schema || ' but not in ' || dev_schema);
  end loop;

    for dev_index in (select index_name, table_name, dbms_metadata.get_ddl('INDEX', index_name, 'SYSTEM') as index_text from all_indexes where table_owner = dev_schema and owner = 'SYSTEM')
    loop
        v_script := '';
        select count(*) into v_count from all_indexes where table_owner = prod_schema and owner = 'SYSTEM' and index_name = dev_index.index_name;
        if v_count = 0 then
            v_script := replace(dbms_lob.substr(dev_index.index_text, 32767), dev_schema, prod_schema);
            dbms_output.put_line(v_script);
        end if;
    end loop;
    for prod_index in (select index_name from all_indexes where table_owner = prod_schema and owner = 'SYSTEM') loop
        select count(*) into v_count from all_indexes where table_owner = dev_schema and owner = 'SYSTEM' and index_name = prod_index.index_name;
        if v_count = 0 then
            dbms_output.put_line('drop index ' || prod_schema || '.' || prod_index.index_name);
        end if;
    end loop;
end;

create or replace procedure compare_tables (
    p_dev_schema in varchar2,
    p_prod_schema in varchar2
) authid current_user is
    v_dev_table_name all_tables.table_name%type;
    v_table_count integer;
    v_dev_col_count integer;
    v_prod_col_count integer;

    v_script varchar2(4000);
begin
    for dev_tab_rec in (select table_name from all_tables where owner = p_dev_schema) loop
        v_dev_table_name := dev_tab_rec.table_name;

        select count(*) into v_table_count
        from all_tables
        where owner = p_prod_schema
        and table_name = v_dev_table_name;

        if v_table_count = 0 then
            dbms_output.put_line('Table ' || v_dev_table_name || ' is present in development schema but not in production schema.');
        else
            -- compare table structure
            select count(*) into v_dev_col_count
            from all_tab_cols
            where owner = p_dev_schema
            and table_name = v_dev_table_name;

            select count(*) into v_prod_col_count
            from all_tab_cols
            where owner = p_prod_schema
            and table_name = v_dev_table_name;

            if v_dev_col_count > v_prod_col_count then
                dbms_output.put_line('Table ' || v_dev_table_name || ' has ' || (v_dev_col_count - v_prod_col_count) || ' more columns in development schema.');
            end if;

            for dev_col_rec in (select column_name from all_tab_cols where owner = p_dev_schema and table_name = v_dev_table_name) loop
                select count(*) into v_table_count
                from all_tab_cols
                where owner = p_prod_schema
                and table_name = v_dev_table_name
                and column_name = dev_col_rec.column_name;

                if v_table_count = 0 then
                    dbms_output.put_line('Column ' || dev_col_rec.column_name || ' in table ' || v_dev_table_name || ' is present in development schema but not in production schema.');
                end if;
            end loop;
        end if;
    end loop;

    for dev_tab_rec in (select table_name from all_tables where owner = p_dev_schema) loop
            v_dev_table_name := dev_tab_rec.table_name;

            select count(*) into v_table_count
            from all_tables
            where owner = p_prod_schema
            and table_name = v_dev_table_name;

            if v_table_count = 0 then
                -- table does not exist in production schema, so generate create table statement
                select dbms_metadata.get_ddl('TABLE', v_dev_table_name, p_dev_schema) into v_script
                from dual;
                v_script := replace(v_script, p_dev_schema, p_prod_schema);
                dbms_output.put_line(v_script);
            else
                -- compare table structure
                select count(*) into v_dev_col_count
                from all_tab_cols
                where owner = p_dev_schema
                and table_name = v_dev_table_name;

                select count(*) into v_prod_col_count
                from all_tab_cols
                where owner = p_prod_schema
                and table_name = v_dev_table_name;

                if v_dev_col_count > v_prod_col_count then
                    -- table has more columns in development schema, so generate alter table statement to add missing columns
                    v_script := 'alter table ' || p_prod_schema || '.' || v_dev_table_name || ' add (';
                    for dev_col_rec in (select column_name, data_type, data_length, data_precision, data_scale
                                        from all_tab_cols where owner = p_dev_schema and table_name = v_dev_table_name) loop
                        select count(*) into v_table_count
                        from all_tab_cols
                        where owner = p_prod_schema
                        and table_name = v_dev_table_name
                        and column_name = dev_col_rec.column_name;

                        if v_table_count = 0 then
                            v_script := v_script || dev_col_rec.column_name || ' ' || dev_col_rec.data_type;
                            if dev_col_rec.data_type in ('VARCHAR2', 'NVARCHAR2', 'RAW') then
                                v_script := v_script || '(' || dev_col_rec.data_length || ')';
                            elsif dev_col_rec.data_type in ('NUMBER') then
                                v_script := v_script || '(' || dev_col_rec.data_precision || ', ' || dev_col_rec.data_scale || ')';
                            end if;
                            v_script := v_script || ', ';
                        end if;
                    end loop;
                    v_script := rtrim(v_script, ', ') || ')';
                    dbms_output.put_line(v_script);
                end if;
            end if;
        end loop;

        -- check for tables that exist in the production schema but not in the development schema
        for prod_tab_rec in (select table_name from all_tables where owner = p_prod_schema) loop
            select count(*) into v_table_count
            from all_tables
            where owner = p_dev_schema
            and table_name = prod_tab_rec.table_name;

            if v_table_count = 0 then
                -- table does not exist in development schema, so generate drop table statement
                dbms_output.put_line('drop table ' || p_prod_schema || '.' || prod_tab_rec.table_name);
            end if;
        end loop;
end;

create or replace procedure compare_schemas (
    p_dev_schema varchar2,
    p_prod_schema varchar2
)
    authid current_user
is
begin
    compare_procedures(p_dev_schema, p_prod_schema);
    compare_functions(p_dev_schema, p_prod_schema);
    compare_indexes(p_dev_schema, p_prod_schema);
    compare_tables(p_dev_schema, p_prod_schema);
    check_fk_constraints(p_dev_schema, p_prod_schema);
    search_for_circular_foreign_key_references(p_dev_schema);
    search_for_circular_foreign_key_references(p_prod_schema);
end;

create or replace procedure drop_all_tables_in_schema (
    p_schema_name varchar2
)
    authid current_user
is
begin
    for tab_rec in (select table_name from all_tables where owner = p_schema_name) loop
        execute immediate 'drop table ' || p_schema_name || '.' || tab_rec.table_name || ' cascade constraints';
    end loop;
end;

create or replace procedure get_all_tables_in_schema(schema_name in varchar2) is
  table_count number;
begin
  select count(*) into table_count from all_tables where owner = schema_name;

  if table_count > 0 then
    for t in (select table_name from all_tables where owner = schema_name) loop
      dbms_output.put_line(t.table_name);
    end loop;
  else
    dbms_output.put_line('No tables found in schema ' || schema_name);
  end if;
end;


