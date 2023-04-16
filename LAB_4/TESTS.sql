DECLARE
    v_address VARCHAR2(100);
    v_name VARCHAR2(100);
    json_data CLOB := '{
                          "query_type": "SELECT",
                          "columns": ["address", "name"],
                          "tables": ["table1", "table2"],
                          "join_conditions": ["table1.id = table2.id", "table1.age > 25"],
                          "filter_conditions": [
                            {
			                  "condition_type": "included",
                              "condition": {
                                                "query_type": "SELECT", 
                                                "column": "name", 
                                                "tables": ["table1"], 
                                                "filter_conditions": [ 
                                                                        { 
                                                                            "condition_type": "plain",
                                                                            "condition": "age > 29", 
                                                                            "operator": "AND"
                                                                        } 
                                                                      ], 
                                                "operator": "IN", 
                                                "search_col": "name"
                                            },
                              "operator": "AND"
                            }
                          ]
                        }';
    result SYS_REFCURSOR;
BEGIN
    result := json_orm(json_data);

    LOOP
        FETCH result INTO v_address, v_name;
        EXIT WHEN result%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Address: ' || v_address || ', Name: ' || v_name);
    END LOOP;

END;

SELECT address, name FROM table1, table2 WHERE table1.id = table2.id AND table1.age > 25 AND name = 'John' AND (name IN (SELECT name FROM table1 WHERE age > 30))

select * from table1;
select * from table2;

DECLARE
    json_data CLOB := '{
      "query_type": "SELECT",
      "columns": ["table1.name", "table2.address"],
      "tables": ["table1", "table2"],
      "join_conditions": ["table1.id = table2.id"],
      "filter_conditions": [
                            {
			                  "condition_type": "plain",
                              "condition": "table1.age > 25",
                              "operator": ""
                            }]
    }';
    result SYS_REFCURSOR;
BEGIN
    result := json_orm(json_data);
END;

DECLARE
    json_data CLOB := '{
      "query_type": "UPDATE",
      "table": "table1",
      "set": [ ["age", "100"], ["name", "''Vlad''"]],
      "filter_conditions": ["id = 1"]
    }';
    result SYS_REFCURSOR;
BEGIN
    result := json_orm(json_data);
END;

DECLARE
    json_data CLOB := '{
      "query_type": "INSERT",
      "table": "table1",
      "columns": ["id", "name", "age"],
      "values": ["4", "''John''", "30"]
    }';
    result SYS_REFCURSOR;
BEGIN
    result := json_orm(json_data);
END;

DECLARE
    json_data CLOB := '{
      "query_type": "DELETE",
      "table": "table1",
      "filter_conditions": ["id = 4"]
    }';
    result SYS_REFCURSOR;
BEGIN
    result := json_orm(json_data);
END;

DECLARE
   json_data CLOB := '{
      "query_type": "CREATE TABLE",
      "table": "employees",
      "columns": [
         {
            "name": "id", "type": "NUMBER"
         },
         {
            "name": "first_name", "type": "VARCHAR2(100)"
         },
         {"name": "last_name", "type": "VARCHAR2(100)"},
         {"name": "salary", "type": "NUMBER"}
      ],
      "primary_keys": ["id"]
   }';
    result SYS_REFCURSOR;
BEGIN
    result := json_orm(json_data);
END;

DECLARE
   json_data CLOB := '{
      "query_type": "DROP TABLE",
      "table": "employees"
   }';
    result SYS_REFCURSOR;
BEGIN
    result := json_orm(json_data);
END;


select * from TABLE1;
select * from TABLE2;


SELECT address, name FROM table1, table2 WHERE table1.age > 25 AND table1.id = table2.id AND name IN (SELECT name FROM table1 WHERE age > 30)