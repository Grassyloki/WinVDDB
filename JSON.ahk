; JSON.ahk for AutoHotkey v2
; Provides JSON parsing and serialization

class JSON {
    ; Parse a JSON string into an AHK object
    static Parse(JsonString) {
        JsonObj := JSON._RecursiveParse(Trim(JsonString))
        return JsonObj
    }
    
    ; Convert an AHK object to a JSON string
    static Stringify(obj, pretty := false, indent := 0) {
        if !IsObject(obj)
            return JSON._FormatValue(obj)
            
        indentStr := ""
        if (pretty) {
            Loop indent
                indentStr .= "  "
            
            newIndent := indent + 1
            newIndentStr := ""
            Loop newIndent
                newIndentStr .= "  "
                
            result := "{"
            
            isFirst := true
            for key, value in obj {
                if !isFirst
                    result .= ","
                
                result .= "`n" newIndentStr '"' JSON._EscapeStr(key) '": ' JSON.Stringify(value, pretty, newIndent)
                isFirst := false
            }
            
            result .= "`n" indentStr "}"
            return result
        } else {
            result := "{"
            
            isFirst := true
            for key, value in obj {
                if !isFirst
                    result .= ","
                
                result .= '"' JSON._EscapeStr(key) '":' JSON.Stringify(value, pretty, indent)
                isFirst := false
            }
            
            result .= "}"
            return result
        }
    }
    
    ; Private method to recursively parse JSON
    static _RecursiveParse(json) {
        json := Trim(json)
        
        ; Object or Array
        if SubStr(json, 1, 1) = "{" { ; Object
            obj := Map()
            json := Trim(SubStr(json, 2))
            
            ; Empty object
            if SubStr(json, 1, 1) = "}"
                return obj
                
            while json {
                ; Get the key name
                keyEnd := InStr(json, ":")
                if !keyEnd
                    throw Error("Invalid JSON: missing colon in object definition", -1)
                    
                key := Trim(SubStr(json, 1, keyEnd-1))
                
                ; Remove quotes from key
                if SubStr(key, 1, 1) = '"' && SubStr(key, -1) = '"'
                    key := SubStr(key, 2, StrLen(key)-2)
                    
                json := Trim(SubStr(json, keyEnd+1))
                
                ; Get the value
                valueEnd := JSON._FindValueEnd(json)
                if !valueEnd
                    throw Error("Invalid JSON: incomplete object definition", -1)
                    
                value := Trim(SubStr(json, 1, valueEnd))
                
                ; Add key/value to object
                obj[key] := JSON._RecursiveParse(value)
                
                ; Move past the current value
                json := Trim(SubStr(json, valueEnd+1))
                
                ; Check for comma or end of object
                if SubStr(json, 1, 1) = "," {
                    json := Trim(SubStr(json, 2))
                } else if SubStr(json, 1, 1) = "}" {
                    json := Trim(SubStr(json, 2))
                    break
                } else {
                    throw Error("Invalid JSON: expected comma or closing brace in object", -1)
                }
            }
            
            return obj
            
        } else if SubStr(json, 1, 1) = "[" { ; Array
            arr := []
            json := Trim(SubStr(json, 2))
            
            ; Empty array
            if SubStr(json, 1, 1) = "]"
                return arr
                
            while json {
                ; Get the value
                valueEnd := JSON._FindValueEnd(json)
                if !valueEnd
                    throw Error("Invalid JSON: incomplete array definition", -1)
                    
                value := Trim(SubStr(json, 1, valueEnd))
                
                ; Add value to array
                arr.Push(JSON._RecursiveParse(value))
                
                ; Move past the current value
                json := Trim(SubStr(json, valueEnd+1))
                
                ; Check for comma or end of array
                if SubStr(json, 1, 1) = "," {
                    json := Trim(SubStr(json, 2))
                } else if SubStr(json, 1, 1) = "]" {
                    json := Trim(SubStr(json, 2))
                    break
                } else {
                    throw Error("Invalid JSON: expected comma or closing bracket in array", -1)
                }
            }
            
            return arr
            
        } else if SubStr(json, 1, 1) = '"' { ; String
            strEnd := 1
            while (nextQuote := InStr(json, '"', , strEnd+1)) {
                ; Check if this quote is escaped
                if SubStr(json, nextQuote-1, 1) != "\"
                    break
                strEnd := nextQuote
            }
            
            if !nextQuote
                throw Error("Invalid JSON: unclosed string", -1)
                
            str := SubStr(json, 2, nextQuote-2)
            
            ; Unescape the string
            str := StrReplace(str, "\""", '"')
            str := StrReplace(str, "\\", "\")
            str := StrReplace(str, "\/", "/")
            str := StrReplace(str, "\b", "`b")
            str := StrReplace(str, "\f", "`f")
            str := StrReplace(str, "\n", "`n")
            str := StrReplace(str, "\r", "`r")
            str := StrReplace(str, "\t", "`t")
            
            ; Handle \u escapes
            pos := 1
            while ((pos := InStr(str, "\u", , pos)) && pos <= StrLen(str)) {
                hexCode := SubStr(str, pos+2, 4)
                charCode := Integer("0x" hexCode)
                if !charCode {
                    pos += 2
                    continue
                }
                
                char := Chr(charCode)
                str := SubStr(str, 1, pos-1) char SubStr(str, pos+6)
                pos += StrLen(char)
            }
            
            return str
            
        } else if SubStr(json, 1, 4) = "true" { ; Boolean true
            return true
            
        } else if SubStr(json, 1, 5) = "false" { ; Boolean false
            return false
            
        } else if SubStr(json, 1, 4) = "null" { ; Null
            return ""
            
        } else { ; Number
            ; Try to parse as a number
            if num := JSON._ParseNum(json)
                return num
                
            throw Error("Invalid JSON: invalid value: " json, -1)
        }
    }
    
    ; Find the end index of a JSON value
    static _FindValueEnd(json) {
        firstChar := SubStr(json, 1, 1)
        
        if firstChar = "{" { ; Object
            brackets := 1
            i := 2
            while i <= StrLen(json) {
                char := SubStr(json, i, 1)
                
                ; Skip strings
                if char = '"' {
                    i++
                    while i <= StrLen(json) {
                        if SubStr(json, i, 1) = '"' && SubStr(json, i-1, 1) != "\" {
                            break
                        }
                        i++
                    }
                } else if char = "{" {
                    brackets++
                } else if char = "}" {
                    brackets--
                    if brackets = 0
                        return i
                }
                
                i++
            }
            
        } else if firstChar = "[" { ; Array
            brackets := 1
            i := 2
            while i <= StrLen(json) {
                char := SubStr(json, i, 1)
                
                ; Skip strings
                if char = '"' {
                    i++
                    while i <= StrLen(json) {
                        if SubStr(json, i, 1) = '"' && SubStr(json, i-1, 1) != "\" {
                            break
                        }
                        i++
                    }
                } else if char = "[" {
                    brackets++
                } else if char = "]" {
                    brackets--
                    if brackets = 0
                        return i
                }
                
                i++
            }
            
        } else if firstChar = '"' { ; String
            i := 2
            while i <= StrLen(json) {
                if SubStr(json, i, 1) = '"' && SubStr(json, i-1, 1) != "\" {
                    return i
                }
                i++
            }
            
        } else { ; Number, boolean, or null
            i := 1
            while i <= StrLen(json) {
                char := SubStr(json, i, 1)
                
                if char = "," || char = "}" || char = "]" || char = " " || char = "`t" || char = "`n" || char = "`r" {
                    return i - 1
                }
                
                i++
            }
            
            return StrLen(json)
        }
        
        return 0  ; Failed to find the end
    }
    
    ; Parse a numeric string to a number
    static _ParseNum(str) {
        ; Trim whitespace
        str := Trim(str)
        
        ; Check if it's a number
        if RegExMatch(str, "^\-?\d+(\.\d+)?([eE][\+\-]?\d+)?$") {
            return Number(str)
        }
        
        return ""
    }
    
    ; Format a value for JSON string output
    static _FormatValue(val) {
        if IsNumber(val)
            return val
        
        if val = true
            return "true"
            
        if val = false
            return "false"
            
        if val = ""
            return "null"
            
        return '"' JSON._EscapeStr(val) '"'
    }
    
    ; Escape special characters in a string for JSON
    static _EscapeStr(str) {
        str := StrReplace(str, "\", "\\")
        str := StrReplace(str, '"', '\"')
        str := StrReplace(str, "`b", "\b")
        str := StrReplace(str, "`f", "\f")
        str := StrReplace(str, "`n", "\n")
        str := StrReplace(str, "`r", "\r")
        str := StrReplace(str, "`t", "\t")
        
        return str
    }
}