FUNCTION wizard()
    DEFINE rec RECORD
        criteria STRING,
        one STRING,
        from, to STRING,
        many DYNAMIC ARRAY OF STRING,
        complex DYNAMIC ARRAY OF RECORD
            rule STRING, #specific, one wildcard, many wildcard, rnage
            value1 STRING,
            value2 STRING
        END RECORD
        -- Rule                 | Value 1     | Value 2
        -- Character            | A
        -- Range                | A           | M
        -- Any Digit            |             |
        -- Any One Character    |             |
        -- Any Characters       |  
        -- 
        -- Result = A[A-M][0-9]?*

        -- Any Digit            | 
        -- Any Character        | 
        --
        -- Result = [0-9]*
        --
        -- Any Letter           |
        -- Any Number           |
        --
        -- Result = [A-Z][0-9]
        --
        -- Character            | A
        -- One Of               | CF
        -- Any Characters       
        -- Result = A[CF]*
        
        
    END RECORD
    DEFINE result STRING
    DEFINE ok BOOLEAN
    DEFINE i INTEGER

    OPEN WINDOW wizard WITH FORM "qbe_wizard" ATTRIBUTES(STYLE = "dialog")
    MESSAGE "Select Criteria"
    LET rec.criteria = "eq"
    -- TODO consider writing this as ui.Dialog (generic)
    DIALOG ATTRIBUTES(UNBUFFERED)
            
        INPUT BY NAME rec.criteria ATTRIBUTES(WITHOUT DEFAULTS = TRUE)
            ON CHANGE criteria
                CALL criteria_state(rec.criteria)
                
        END INPUT

        -- Sub-input used by eq, lt, lte, gt, gte, starts, ends, contains
        INPUT BY NAME rec.one
        END INPUT

        -- sub-input used by between
        INPUT BY NAME rec.from, rec.to
        END INPUT
        
        -- sub-input used by ymany
        INPUT ARRAY rec.many FROM scr.*
        END INPUT

        --TODO add sub-input to be used with complex criteria

        BEFORE DIALOG
            CALL criteria_state(rec.criteria)
            
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
            WHEN "isnull"
                LET result = "="
            WHEN "isnotnull"
                LET result = "!="
            WHEN "eq"
                LET result = rec.one
            WHEN "lt"
                LET result = "<", rec.one
            WHEN "lte"
                LET result = "<=", rec.one
            WHEN "gt"
                LET result = ">", rec.one
            WHEN "gte"
                LET result = ">=", rec.one
            WHEN "start"
                LET result = rec.one, "*"
            WHEN "end"
                LET result = "*", rec.one
            WHEN "contains"
                LET result = "*", rec.one, "*"
            WHEN "between"
                LET result = rec.from, ":", rec.to
            WHEN "in" 
                FOR i = 1 TO rec.many.getLength()
                    IF i > 1 THEN
                        LET result = result, "|"
                    END IF
                    LET result = result,rec.many[i]
                END FOR 
            WHEN "like" 
                -- TODO
                LET result = rec.one
        END CASE
    ELSE
        INITIALIZE result TO NULL
    END IF
    RETURN result
END FUNCTION

PRIVATE FUNCTION criteria_state(l_criteria STRING)
DEFINE f ui.Form

    LET f = ui.Window.getCurrent().getForm()
    CALL f.setElementHidden("grp_one", l_criteria NOT IN("eq","lt","lte","gt","gte","start","contains","end"))
    CALL f.setElementHidden("grp_range", l_criteria != "between")
    CALL f.setElementHidden("grp_many", L_criteria != "in")
    -- TODO add logic for complex sub-dialog to appear
END FUNCTION



--TODO Delete these lines if we commit to using Radiogroup
--FUNCTION populate_criteria(cb)
--    DEFINE cb ui.ComboBox
--
--    -- TODO Make translatable 
--    CALL cb.clear()
--    CALL cb.addItem("isnull", "Blank (is null)")
--    CALL cb.addItem("isnotnull", "Populated (is not null)")
--    CALL cb.addItem("eq", "Equal To (=)")
--    CALL cb.addItem("lt", "Less Than (<)")
--    CALL cb.addItem("lte", "Less Than or Equal To (<=)")
--    CALL cb.addItem("gt", "Greater Than (>)")
--    CALL cb.addItem("gte", "Greater or Equal To (>=)")
--    CALL cb.addItem("start", "Begins With")
--    CALL cb.addItem("end", "Ends With")
--    CALL cb.addItem("contains", "Contains")
--    CALL cb.addItem("between", "Between")
--    CALL cb.addItem("in", "In")
--    CALL cb.addItem("complex", "Complex Criteria")
--END FUNCTION
