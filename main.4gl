IMPORT FGL fgldialog
IMPORT FGL qbe_wizard
SCHEMA day2db

DEFINE person_rec RECORD LIKE person.*
DEFINE person_arr DYNAMIC ARRAY OF RECORD LIKE person.*

MAIN
    DEFINE where_clause STRING
    DEFINE cancelled BOOLEAN

    --TODO, create an inmemory database so portable
    CONNECT TO "day2db"

    CLOSE WINDOW SCREEN
    OPEN WINDOW w1 WITH FORM "form1"

    WHILE TRUE

        LET int_flag = FALSE
        CONSTRUCT BY NAME where_clause ON person.*

            BEFORE CONSTRUCT
                MESSAGE %"qbe_wizard_test.ask_message"
            ON ACTION wizard ATTRIBUTE(ACCELERATOR = "CONTROL-Q", TEXT = "QBE Wizard") #TODO see if can change to Control-Q
                CALL fgl_dialog_setbuffer(NVL(qbe_wizard.wizard(), fgl_dialog_getbuffer()))
            AFTER CONSTRUCT
                IF int_flag THEN
                    EXIT CONSTRUCT
                END IF
                -- Add some tests here if required
        END CONSTRUCT
        LET cancelled = int_flag
        LET int_flag = 0
        DISPLAY where_clause
        
        IF cancelled THEN
            MENU "Exit" ATTRIBUTES(COMMENT = %"qbe_wizard_test.exit_program", STYLE = "dialog")
                COMMAND %"qbe_wizard_test.no"
                COMMAND %"qbe_wizard_test.yes"
                    EXIT PROGRAM 0
            END MENU
        ELSE
            IF populate_result(where_clause) THEN
                -- TODO, move up to near CONSTRUCT and create a multi-dialog                
                DISPLAY ARRAY person_arr TO scr_table.* ATTRIBUTES(CANCEL = FALSE)
                    BEFORE DISPLAY
                        MESSAGE SFMT("%1 rows found.", person_arr.getLength())
                END DISPLAY
                LET int_flag = 0
                CLEAR SCREEN ARRAY scr_form.*
                CLEAR SCREEN ARRAY scr_table.*
            END IF
        END IF
    END WHILE
END MAIN

FUNCTION populate_result(p_where_clause STRING)
    DEFINE sql_text STRING
    LET sql_text = "SELECT * FROM person WHERE " || p_where_clause || " ORDER BY id "
    DISPLAY sql_text
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
