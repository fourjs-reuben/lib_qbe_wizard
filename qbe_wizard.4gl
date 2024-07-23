FUNCTION wizard()
    DEFINE rec RECORD
        criteria STRING,
        one STRING,
        from, to STRING,
        many DYNAMIC ARRAY OF STRING
    END RECORD
    DEFINE result STRING
    DEFINE ok BOOLEAN

    OPEN WINDOW wizard WITH FORM "qbe_wizard" ATTRIBUTES(STYLE = "dialog")

    #TODO consider writing this as ui.Dialog (generic)
    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec.criteria ATTRIBUTES(WITHOUT DEFAULTS = TRUE)
            AFTER INPUT
                # TODO show/hide grids in form based on criteria value
        END INPUT

        #TODO Add sub-input to be used with equals, <, <=, >, >=, begins with, contains, end with
        #TODO add sub-input to be used with between
        #TODO add sub-input array to be used with many
        #TODO add sub-input to be used with complex matches
        ON ACTION ACCEPT
            LET ok = TRUE
            ACCEPT DIALOG
            EXIT DIALOG

        ON ACTION CANCEL
            LET ok = FALSE
            CANCEL DIALOG

            EXIT DIALOG
    END DIALOG
    CLOSE WINDOW wizard

    IF ok THEN
        CASE rec.criteria
            WHEN "="
                LET result = "="
            WHEN "!="
                LET result = "!="
                #TODO add other criteria
        END CASE
    ELSE
        INITIALIZE result TO NULL
    END IF
    RETURN result
END FUNCTION

FUNCTION populate_criteria(cb)
    DEFINE cb ui.ComboBox

    CALL cb.clear()

    CALL cb.addItem("=", "IS NULL")
    CALL cb.addItem("!=", "IS NOT NULL")

    #TODO equals
    #TDOD Add <, <=, >, >=
    #TODO Add begins with, contains, ends with
    #TODO Add BETWEEN
    #TODO Add IN
    #TODO Add complex matches/like
END FUNCTION
