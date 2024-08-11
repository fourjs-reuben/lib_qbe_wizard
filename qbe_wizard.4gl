TYPE genericType RECORD
   str STRING,
   num INTEGER,
   flt FLOAT,
   dmy DATE
END RECORD

FUNCTION wizard()
   DEFINE rec RECORD
        criteria STRING,
        one genericType,
        from genericType,
        to genericType,
        many DYNAMIC ARRAY OF genericType,
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
    DEFINE data_type STRING
    DEFINE widget STRING
    DEFINE om om.DomNode
    LET om = ui.Interface.getDocument().getElementById(ui.Interface.getRootNode().getAttribute("focus"))
    LET data_type = om.getAttribute("sqlType")
    LET widget = om.getFirstChild().getTagName()
    DISPLAY data_type

    OPEN WINDOW wizard WITH FORM "qbe_wizard" ATTRIBUTES(STYLE = "dialog")
    MESSAGE %"qbe_wizard.select_criteria"
    LET rec.criteria = "eq"
    -- TODO consider writing this as ui.Dialog (generic)
    DIALOG ATTRIBUTES(UNBUFFERED)

        INPUT BY NAME rec.criteria ATTRIBUTES(WITHOUT DEFAULTS = TRUE)
            ON CHANGE criteria
                DISPLAY rec.criteria
                CALL criteria_state(rec.criteria)
                CALL check_type(data_type)
        END INPUT

        -- Sub-input used by eq, lt, lte, gt, gte, starts, ends, contains
       -- INPUT BY NAME rec.one.*
       -- END INPUT

        INPUT rec.one.* FROM scr_one.* ATTRIBUTES(WITHOUT DEFAULTS = TRUE)
        END INPUT
       
        -- sub-input used by between
        INPUT rec.from.* FROM scr_from.* ATTRIBUTES(WITHOUT DEFAULTS = TRUE)
        END INPUT

        INPUT rec.to.* FROM scr_to.* ATTRIBUTES(WITHOUT DEFAULTS = TRUE)
        END INPUT
        
        -- sub-input used by ymany
        INPUT ARRAY rec.many FROM scr_many.* ATTRIBUTES(WITHOUT DEFAULTS = TRUE)
        END INPUT

        --TODO add sub-input to be used with complex criteria
        INPUT ARRAY rec.complex FROM scr_like.* ATTRIBUTES(WITHOUT DEFAULTS = TRUE)
        END INPUT

        BEFORE DIALOG
            CALL criteria_state(rec.criteria)
            CALL check_type(data_type)

        ON ACTION ACCEPT
            LET ok = TRUE
            ACCEPT DIALOG
            EXIT DIALOG

        ON ACTION CANCEL
            LET ok = FALSE
            CANCEL DIALOG

            EXIT DIALOG
    END DIALOG
    LET int_flag = 0
    CLOSE WINDOW wizard
    
    IF ok THEN
        CASE rec.criteria
            WHEN "isnull"
                LET result = "="
            WHEN "isnotnull"
                LET result = "!="
            WHEN "eq"
                LET result = get_variable_by_type(data_type,rec.one)
            WHEN "lt"
                LET result = "<", get_variable_by_type(data_type,rec.one)
            WHEN "lte"
                LET result = "<=", get_variable_by_type(data_type,rec.one)
            WHEN "gt"
                LET result = ">", get_variable_by_type(data_type,rec.one)
            WHEN "gte"
                LET result = ">=", get_variable_by_type(data_type,rec.one)
            WHEN "start"
                LET result = get_variable_by_type(data_type,rec.one), "*"
            WHEN "end"
                LET result = "*",get_variable_by_type(data_type,rec.one)
            WHEN "contains"
                LET result = "*", get_variable_by_type(data_type,rec.one), "*"
            WHEN "between"
                LET result =  get_variable_by_type(data_type,rec.from) , "..", get_variable_by_type(data_type,rec.to)
            WHEN "in"
                FOR i = 1 TO rec.many.getLength()
                    IF i > 1 THEN
                        LET result = result, "|"
                    END IF
                    LET result = result, get_variable_by_type(data_type,rec.many[i])
                END FOR
                DISPLAY result
            WHEN "complex"
                FOR i = 1 TO rec.complex.getLength()
                    CASE rec.complex[i].rule
                        WHEN "anydigit"
                            LET result = result, "[0-9]"
                        WHEN "anyletter"
                            LET result = result, '[A-Z]'
                        WHEN "character"
                            LET result = result, rec.complex[i].value1
                        WHEN "range"
                            LET result =
                                result,
                                "[",
                                rec.complex[i].value1,
                                "-",
                                rec.complex[i].value2,
                                "]"
                        WHEN "anyonecharacter"
                            LET result = result, "?"
                        WHEN "anycharacter"
                            LET result = result, "*"
                        WHEN "onecharacter"
                            LET result = result, "[", rec.complex[i].value1, "]"
                        WHEN "notinrange"
                            LET result =
                                result,
                                "[^",
                                rec.complex[i].value1,
                                "-",
                                rec.complex[i].value2,
                                "]"
                        WHEN "notthischaracter"
                            LET result =
                                result,
                                "[^",
                                rec.complex[i].value1,
                                "]"
                    END CASE
                END FOR
        END CASE
    ELSE
        INITIALIZE result TO NULL
    END IF

    RETURN result
END FUNCTION

PRIVATE FUNCTION criteria_state(l_criteria STRING)
    DEFINE f ui.Form

    LET f = ui.Window.getCurrent().getForm()
    CALL f.setElementHidden(
        "grp_one",
        l_criteria
            NOT IN ("eq", "lt", "lte", "gt", "gte", "start", "contains", "end"))
    CALL f.setElementHidden("grp_range", l_criteria != "between")
    CALL f.setElementHidden("grp_many", l_criteria != "in")
    CALL f.setElementHidden("grp_like", l_criteria != "complex")
    -- TODO add logic for complex sub-dialog to appear
END FUNCTION

PRIVATE FUNCTION check_type(data_type1 STRING)
# hiding the elements
    DEFINE f ui.Form
    LET f = ui.Window.getCurrent().getForm()

    #TODO -- this is horrible and needs to be rewritten, Reuben.  Works for purposes of demo ...
    CALL f.setFieldHidden("oneflt", data_type1 IN ("CHAR(20)", "SMALLINT" ,"DATE"))
    CALL f.setFieldHidden("onedmy", data_type1 IN ("CHAR(20)", "SMALLINT", "DECIMAL(5,2)"))
    CALL f.setFieldHidden("onenum", data_type1 IN ("CHAR(20)" ,"DATE" , "DECIMAL(5,2)"))
    CALL f.setFieldHidden("onestr", data_type1 IN ("SMALLINT" ,"DATE" , "DECIMAL(5,2)"))
    CALL f.setFieldHidden("manyflt", data_type1 IN ("CHAR(20)", "SMALLINT" ,"DATE"))
    CALL f.setFieldHidden("manydmy", data_type1 IN ("CHAR(20)", "SMALLINT", "DECIMAL(5,2)"))
    CALL f.setFieldHidden("manynum", data_type1 IN ("CHAR(20)" ,"DATE" , "DECIMAL(5,2)"))
    CALL f.setFieldHidden("manystr", data_type1 IN ("SMALLINT" ,"DATE" , "DECIMAL(5,2)"))
    CALL f.setFieldHidden("fromflt", data_type1 IN ("CHAR(20)", "SMALLINT" ,"DATE"))
    CALL f.setFieldHidden("fromdmy", data_type1 IN ("CHAR(20)", "SMALLINT", "DECIMAL(5,2)"))
    CALL f.setFieldHidden("fromnum", data_type1 IN ("CHAR(20)" ,"DATE" , "DECIMAL(5,2)"))
    CALL f.setFieldHidden("fromstr", data_type1 IN ("SMALLINT" ,"DATE" , "DECIMAL(5,2)"))
    CALL f.setFieldHidden("toflt", data_type1 IN ("CHAR(20)", "SMALLINT" ,"DATE"))
    CALL f.setFieldHidden("todmy", data_type1 IN ("CHAR(20)", "SMALLINT", "DECIMAL(5,2)"))
    CALL f.setFieldHidden("tonum", data_type1 IN ("CHAR(20)" ,"DATE" , "DECIMAL(5,2)"))
    CALL f.setFieldHidden("tostr", data_type1 IN ("SMALLINT" ,"DATE" , "DECIMAL(5,2)"))

END FUNCTION


FUNCTION get_variable_by_type(data_type1 STRING, var genericType)
DEFINE result STRING
        CASE data_type1
        WHEN "CHAR(20)"
          LET result = var.str
        WHEN "SMALLINT"
          LET result = var.num
        WHEN "DECIMAL(5,2)"
          LET result = var.flt
        WHEN  "DATE"
          LET result = var.dmy
          DISPLAY var.dmy
        END CASE
RETURN result
END FUNCTION


FUNCTION populate_rule(cb1)
    DEFINE cb1 ui.ComboBox
    DEFINE db_type CHAR(3)
    LET db_type = fgl_db_driver_type()
    CALL cb1.clear()
    CALL cb1.addItem("anydigit", %"qbe_wizard_test.anydigit")
    CALL cb1.addItem("anyletter", %"qbe_wizard_test.anyletter")
    CALL cb1.addItem("range", %"qbe_wizard_test.range")
    CALL cb1.addItem("character", %"qbe_wizard_test.character")
    CALL cb1.addItem("anycharacter", %"qbe_wizard_test.anycharacter")
    CALL cb1.addItem("anyonecharacter", %"qbe_wizard_test.anyonecharacter")
    CALL cb1.addItem("onecharacter", %"qbe_wizard_test.onecharacter")
    CALL cb1.addItem("notinrange", %"qbe_wizard_test.notinrange")
    CALL cb1.addItem("notthischaracter", %"qbe_wizard_test.notthischaracter")

    IF (db_type IN ('sqt', 'mys', 'pgs')) THEN
        CALL cb1.removeItem("anydigit")
        CALL cb1.removeItem("anyletter")
        CALL cb1.removeItem("range")
        CALL cb1.removeItem("onecharacter")
        CALL cb1.removeItem("notinrange")
        CALL cb1.removeItem("notthischaracter")
    END IF
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
