/**
 * Lib: JSON.ahk
 *     JSON lib for AutoHotkey.
 * Version:
 *     v2.1.3 [updated 04/18/2016 (MM/DD/YYYY)]
 * License:
 *     WTFPL [http://wtfpl.net/]
 * Requirements:
 *     AutoHotkey v1.1.21+
 * Installation:
 *     Use #Include JSON.ahk or copy into a function library folder and then
 *     use #Include <JSON>
 * Links:
 *     GitHub:     - https://github.com/cocobelgica/AutoHotkey-JSON
 *     Forum Topic - http://goo.gl/r0zI8t
 *     Email:      - cocobelgica <at> gmail <dot> com
 */


/**
 * Class: JSON
 *     The JSON object contains methods for parsing JSON and converting values
 *     to JSON strings.
 * Methods:
 *     Load() - see relevant documentation
 *     Dump() - see relevant documentation
 */
class JSON
{
	/**
	 * Method: Load
	 *     Parses a JSON string into an AHK value
	 * Syntax:
	 *     value := JSON.Load( text [, reviver ] )
	 * Parameter(s):
	 *     value      [retval] - parsed value
	 *     text    [in, ByRef] - JSON formatted string
	 *     reviver   [in, opt] - function object, similar to JavaScript's
	 *                            JSON.parse() 'reviver' parameter
	 */
	class Load extends JSON.Functor
	{
		Call(self, ByRef text, reviver:="")
		{
			this.rev := IsObject(reviver) ? reviver : false
		; Object keys(and array indices) are temporarily stored in arrays so that
		; we can enumerate them in the order they appear in the document/text instead
		; of alphabetically. Skip if no reviver function is specified.
			this.keys := this.rev ? {} : false

			static quot := Chr(34), bashq := "\" . quot
			     , json_value := quot . "{[01234567890-tfn"
			     , json_value_or_array_closing := quot . "{[]01234567890-tfn"
			     , object_key_or_object_closing := quot . "}"

			key := ""
			is_key := false
			root := {}
			stack := [root]
			next := json_value
			pos := 0

			while ((ch := SubStr(text, ++pos, 1)) != "") {
				if InStr(" `t`r`n", ch)
					continue
				if !InStr(next, ch, 1)
					this.ParseError(next, text, pos)

				holder := stack[1]
				is_array := holder.IsArray

				if InStr(",:", ch) {
					next := (is_key := !is_array && ch == ",") ? quot : json_value

				} else if InStr("}]", ch) {
					ObjRemoveAt(stack, 1)
					next := stack[1]==root ? "" : stack[1].IsArray ? ",]" : ",}"

				} else {
					if InStr("{[", ch) {
					; Array() is a built-in function in AutoHotkey
						static json_array := Func("Array").IsBuiltIn || [1,2].IsArray ? "Array" : "_Array"

						expr := is_array ? json_array "()" : "{}"
						ObjInsertAt(stack, 1, obj := Func(expr)())
						next := is_array ? "%]" : "%}"
					}

					else if InStr(quot, ch) {
						i := pos
						while (i := InStr(text, quot,, i+1)) {
							value := StrReplace(SubStr(text, pos+1, i-pos-1), "\\", "\u005c")

							static ss_end := A_AhkVersion<"2" ? 0 : -1
							if (SubStr(value, ss_end) != "\")
								break
						}

						if !i
							this.ParseError("'", text, pos)

						  value := StrReplace(value,  "\/",  "/")
						, value := StrReplace(value, bashq, quot)
						, value := StrReplace(value,  "\b", "`b")
						, value := StrReplace(value,  "\f", "`f")
						, value := StrReplace(value,  "\n", "`n")
						, value := StrReplace(value,  "\r", "`r")
						, value := StrReplace(value,  "\t", "`t")

						pos := i ; update pos

						i := 0
						while (i := InStr(value, "\",, i+1)) {
							if !(SubStr(value, i+1, 1) == "u")
								this.ParseError("\", text, pos - StrLen(SubStr(value, i+1)))

							uffff := Abs("0x" . SubStr(value, i+2, 4))
							if (A_IsUnicode || uffff < 0x100)
								value := SubStr(value, 1, i-1) . Chr(uffff) . SubStr(value, i+6)
						}

						if is_key {
							key := value, next := ":"
							continue
						}
					}

					else {
						value := SubStr(text, pos, i := RegExMatch(text, "[\]\},\s]|$",, pos)-pos)

						static number := "number", integer :="integer"
						if value is %number%
						{
							if value is %integer%
								value += 0
						}
						else if (value == "true" || value == "false")
							value := %value% + 0
						else if (value == "null")
							value := ""
						else
						; we can do more here to pinpoint the actual culprit
						; but that's just too much extra work.
							this.ParseError(next, text, pos, i)

						pos += i-1
					}

					next := holder==root ? "" : is_array ? ",]" : ",}"
				} ; If InStr("{[", ch) { ... } else

				is_array? key := ObjPush(holder, value) : holder[key] := value

				if (this.keys && this.keys.HasKey(holder))
					this.keys[holder].Push(key)
			}

			return this.rev ? this.Walk(root, "") : root
		}

		ParseError(expect, ByRef text, pos, len:=1)
		{
			static quot := Chr(34), qurly := quot . "}"
			
			line := StrSplit(SubStr(text, 1, pos), "`n", "`r").Length()
			col := pos - InStr(text, "`n",, -(StrLen(text)-pos+1))

			msg := Format("{1}`n`nLine:`t{2}`nCol:`t{3}`nChar:`t{4}"
			,     (expect == "")     ? "Extra data"
			    : (expect == "'")    ? "Unterminated string starting at"
			    : (expect == "\")    ? "Invalid \escape"
			    : (expect == ":")    ? "Expecting ':' delimiter"
			    : (expect == quot)   ? "Expecting object key enclosed in double quotes"
			    : (expect == qurly)  ? "Expecting object key enclosed in double quotes or object closing '}'"
			    : (expect == ",}")   ? "Expecting ',' delimiter or object closing '}'"
			    : (expect == ",]")   ? "Expecting ',' delimiter or array closing ']'"
			    : InStr(expect, "]") ? "Expecting JSON value or array closing ']'"
			    :                      "Expecting JSON value(string, number, true, false, null, object or array)"
			, line, col, pos)

			static offset := A_AhkVersion<"2" ? -3 : -4
			throw Exception(msg, offset, SubStr(text, pos, len))
		}

		Walk(holder, key)
		{
			value := holder[key]
			if IsObject(value) {
				for i, k in this.keys[value] {
					; check if ObjHasKey(value, k) ??
					v := this.Walk(value, k)
					if (v != JSON.Undefined)
						value[k] := v
					else
						ObjDelete(value, k)
				}
			}
			
			return this.rev.Call(holder, key, value)
		}
	}

	/**
	 * Method: Dump
	 *     Converts an AHK value into a JSON string
	 * Syntax:
	 *     str := JSON.Dump( value [, replacer, space ] )
	 * Parameter(s):
	 *     str        [retval] - JSON representation of an AHK value
	 *     value          [in] - any value(object, string, number)
	 *     replacer  [in, opt] - function object, similar to JavaScript's
	 *                            JSON.stringify() 'replacer' parameter
	 *     space     [in, opt] - similar to JavaScript's JSON.stringify()
	 *                            'space' parameter
	 */
	class Dump extends JSON.Functor
	{
		Call(self, value, replacer:="", space:="")
		{
			this.rep := IsObject(replacer) ? replacer : ""

			this.gap := ""
			if (space) {
				static integer := "integer"
				if space is %integer%
					Loop, % ((n := Abs(space))>10 ? 10 : n)
						this.gap .= " "
				else
					this.gap := SubStr(space, 1, 10)

				this.indent := "`n"
			}

			return this.Str({"": value}, "")
		}

		Str(holder, key)
		{
			value := holder[key]

			if (this.rep)
				value := this.rep.Call(holder, key, ObjHasKey(holder, key) ? value : JSON.Undefined)

			if IsObject(value) {
			; Check object type, skip serialization for other object types such as
			; ComObject, Func, BoundFunc, FileObject, RegExMatchObject, Property, etc.
				static type := A_AhkVersion<"2" ? "" : Func("Type")
				if (type ? type.Call(value) == "Object" : ObjGetCapacity(value) != "") {
					if (this.gap) {
						stepback := this.indent
						this.indent .= this.gap
					}

					is_array := value.IsArray
				; Array() is a built-in function in AutoHotkey
					static json_array := Func("Array").IsBuiltIn || [1,2].IsArray ? "Array" : "_Array"

					if (is_array) { ; Check if object is a JSON array[] or {} object
						str := "["
						Loop, % value.Length() {
							if (A_Index > 1)
								str .= ", "
							
							str .= this.gap . this.Str(value, A_Index)
						}
						
						str .= stepback . "]"
					} else {
						str := "{"
						cnt := 0
						for k, v in value {
							if (cnt++)
								str .= ", "
							
							str .= this.gap . this.Quote(k) . ":" . (this.gap ? " " : "") . this.Str(value, k)
						}
						
						str .= stepback . "}"
					}
					
					return str
				} else
					return ""
			} else
				return ObjGetCapacity([value], 1) == "" ? value : this.Quote(value)
		}

		Quote(string)
		{
			static quot := Chr(34), bashq := "\" . quot

			if (string != "") {
				  string := StrReplace(string,  "\",  "\\")
				; , string := StrReplace(string,  "/",  "\/") ; optional in ECMAScript
				, string := StrReplace(string, quot, bashq)
				, string := StrReplace(string, "`b",  "\b")
				, string := StrReplace(string, "`f",  "\f")
				, string := StrReplace(string, "`n",  "\n")
				, string := StrReplace(string, "`r",  "\r")
				, string := StrReplace(string, "`t",  "\t")

				static rx_escapable := A_AhkVersion<"2" ? "O)[^\x20-\x7e]" : "[^\x20-\x7e]"
				while RegExMatch(string, rx_escapable, m)
					string := StrReplace(string, m.Value, Format("\u{1:04x}", Ord(m.Value)))
			}

			return quot . string . quot
		}
	}

	/**
	 * Property: Undefined
	 *     Proxy for 'undefined' type
	 * Syntax:
	 *     undefined := JSON.Undefined
	 * Remarks:
	 *     For use with reviver and replacer functions since AutoHotkey does not
	 *     have an 'undefined' type. JSON.Null is similar to 'null' in JavaScript
	 *     but is slightly different for use with JSON.Undefined
	 */
	Undefined[]
	{
		get {
			static empty := {}, vt_empty := ComObject(0, &empty, 1)
			return vt_empty
		}
	}

	class Functor
	{
		__Call(method, ByRef arg, args*)
		{
		; When casting to Call(), use a new instance of the "function object"
		; so as to avoid directly storing the properties(used across sub-methods)
		; into the "function object" itself.
			if IsObject(method)
				return (new this).Call(method, arg, args*)
			else if (method == "")
				return (new this).Call(arg, args*)
		}
	}
}