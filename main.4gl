IMPORT FGL fgldialog
IMPORT FGL qbe_wizard

SCHEMA day2db

    DEFINE person_rec RECORD LIKE person.*
    DEFINE person_arr DYNAMIC ARRAY OF RECORD LIKE person.*

MAIN
    DEFINE where_clause STRING

    CONNECT TO ":memory:+driver='dbmsqt'"
    CALL create_test_database()
    CALL populate_test_database()

    
    CLOSE WINDOW SCREEN
    OPEN WINDOW w1 WITH FORM "form1"

    WHILE TRUE

        LET int_flag = FALSE
        CONSTRUCT BY NAME where_clause ON person.*
            BEFORE CONSTRUCT
                MESSAGE "Enter QBE Criteria, Press Ctrl-W for Field QBE Wizard"
        
            ON ACTION wizard ATTRIBUTE(ACCELERATOR = "CONTROL-W", TEXT = "QBE Wizard") #TODO see if can change to Control-Q
                CALL FGL_DIALOG_SETBUFFER(NVL(qbe_wizard.wizard(), FGL_DIALOG_GETBUFFER()))

            AFTER CONSTRUCT
                IF int_flag THEN
                    EXIT CONSTRUCT
                END IF
                -- Add some tests here if required
        END CONSTRUCT
        
        IF int_flag THEN
            MENU "Exit" ATTRIBUTES(COMMENT = "Exit Test Program?", STYLE = "dialog")
                COMMAND "No"
                COMMAND "Yes"
                    EXIT PROGRAM 0
            END MENU
        ELSE
            IF populate_result(where_clause) THEN
                -- TODO, move up to near CONSTRUCT and create a multi-dialog
                DISPLAY ARRAY person_arr TO record1.* ATTRIBUTES(CANCEL=FALSE)
                    BEFORE DISPLAY
                        MESSAGE SFMT("%1 rows found.", person_arr.getLength())
                END DISPLAY
                CLEAR SCREEN ARRAY record1.*
            END IF
        END IF
    END WHILE
END MAIN

FUNCTION populate_result(p_where_clause STRING)
    DEFINE sql_text STRING

    LET sql_text = "SELECT * FROM person WHERE " || p_where_clause || " ORDER BY id "
    TRY
        DECLARE per_curs SCROLL CURSOR FROM sql_text
        CALL person_arr.clear()
        FOREACH per_curs INTO person_rec.*
            CALL person_arr.appendElement()
            LET person_arr[person_arr.getLength()].* = person_rec.*
        END FOREACH
        RETURN TRUE
    CATCH
        ERROR "SQL error: ", SQLERRMESSAGE
        RETURN FALSE
    END TRY
END FUNCTION

FUNCTION create_test_database()
    EXECUTE IMMEDIATE "CREATE TABLE person (
        id SMALLINT,
        first_name CHAR(20),
        last_name CHAR(20),
        alive BOOLEAN,
        birthdate DATE,
        height_in_inches DECIMAL(5,2),
        CONSTRAINT sqlite_autoindex_person_1 PRIMARY KEY(id))"
END FUNCTION

FUNCTION populate_test_database()

    # Use this if not using bin folder
    #  LOAD FROM "day2db.unl" INSERT INTO person

    # use this if using bin folder to simplify (or else gets confusing is unl file in source or bin folder
    INSERT INTO person VALUES(1,"Fred","Flintstone",0,"2004-10-10",50.20)
    INSERT INTO person VALUES(2,"Barney","Rubble",1,"2004-09-09",40.30)
    INSERT INTO person VALUES(3,"Wilmar","Flintstone",1,"2006-03-21",48.60)
    INSERT INTO person VALUES(4,"Betty","Rubble",1,"2006-07-30",47.80)
    INSERT INTO person VALUES(5,"George","Washington",1,"1732-02-22",74.00)
    INSERT INTO person VALUES(6,"Mahima","Singh",1,"1732-02-22",134.00)
END FUNCTION
