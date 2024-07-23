IMPORT FGL fgldialog
IMPORT FGL qbe_wizard
SCHEMA day2db

DEFINE person_rec RECORD LIKE person.*

MAIN
    DEFINE person_count INTEGER
    DEFINE where_clause STRING

    CONNECT TO "day2db"

    CLOSE WINDOW SCREEN
    OPEN WINDOW w1 WITH FORM "form1"

    WHILE TRUE
        CLEAR FORM
        LET int_flag = FALSE
        CONSTRUCT BY NAME where_clause ON person.*
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
            LET person_count = get_person_count(where_clause)
            IF person_count > 0 THEN
                MESSAGE SFMT("%1 rows found.", person_count)
                IF person_select(where_clause) THEN
                    DISPLAY where_clause
                    CALL display_person()
                END IF
            ELSE
                MESSAGE "No rows found"
            END IF
        END IF
    END WHILE
END MAIN

--This function is called by the function query_cust to return the count of rows that would be retrieved by the SELECT statement. The criteria previously entered by the user and stored in the variable where_clause is used.

FUNCTION get_person_count(p_where_clause STRING) RETURNS INTEGER
    DEFINE
        sql_text STRING,
        person_cnt INTEGER
    LET sql_text = "SELECT COUNT(*) FROM person WHERE " || p_where_clause
    PREPARE per_cnt_stmt FROM sql_text
    EXECUTE per_cnt_stmt INTO person_cnt
    FREE per_cnt_stmt
    RETURN person_cnt
END FUNCTION

--This function declares a scroll cursor from the SELECT statement build with the where_clause passed as parameter.

FUNCTION person_select(p_where_clause STRING) RETURNS BOOLEAN
    DEFINE sql_text STRING
    LET sql_text = "SELECT * FROM person WHERE " || p_where_clause || " ORDER BY id "
    TRY
        DECLARE per_curs SCROLL CURSOR FROM sql_text
        OPEN per_curs
        FETCH per_curs INTO person_rec.*
        RETURN TRUE
    CATCH
        ERROR "SQL error: ", SQLERRMESSAGE
        RETURN FALSE
    END TRY
END FUNCTION

FUNCTION display_person() RETURNS()
    DISPLAY BY NAME person_rec.*
END FUNCTION
