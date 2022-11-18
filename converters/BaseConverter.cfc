component {
	variables.options = {};
	public function init(options) {
		variables._outputContent = 1;
		variables.options = arguments.options;
		return this;
	}

	public string function toScript(tag) {
		if (listFindNoCase("cfcontent,cfcookie,cfheader,cfdbinfo,cfdirectory,cfexecute,cffeed,cffile,cffileupload,cfflush,cfftp,cfimage,cfldap,cflog,cfparam,cfpop,cfprint,cfquery,cfqueryparam,cfprocparam,cfhttp,cfhttpparam,cfoutput,cfinvokeargument,cfsetting,cfprocessingdirective,cfmailparam,cflogout,cfloginuser", tag.getName())) {
			//do generic CF11+ conversion
			return toScriptGeneric(tag);
		}
		throw(message="Unable to convert tag: " & tag.getName() & " to CFML Script");
	}

	public string function toScriptEndTag(tag) {
		return "";
	}

	public boolean function indentBody(tag) {
		return false;
	}

	public string function convertOperators(str) {
		arguments.str = replaceNoCase(arguments.str, " EQ ", " == ", "ALL");
		arguments.str = replaceNoCase(arguments.str, " NEQ ", " != ", "ALL");
		arguments.str = replaceNoCase(arguments.str, " IS NOT ", " != ", "ALL");
		arguments.str = replaceNoCase(arguments.str, " IS ", " == ", "ALL");
		arguments.str = replaceNoCase(arguments.str, " GT ", " > ", "ALL");
		arguments.str = replaceNoCase(arguments.str, " LT ", " < ", "ALL");
		arguments.str = replaceNoCase(arguments.str, " LTE ", " <= ", "ALL");
		arguments.str = replaceNoCase(arguments.str, " GTE ", " >= ", "ALL");
		arguments.str = replaceNoCase(arguments.str, " NOT ", " !", "ALL");
		arguments.str = replaceNoCase(arguments.str, " AND ", " && ", "ALL");
		arguments.str = replaceNoCase(arguments.str, " OR ", " || ", "ALL");
		return arguments.str;
	}

	public string function unPound(str) {
		if (left(arguments.str, 1) == "##" && right(arguments.str,1) == "##" && len(arguments.str) > 2) {
			return mid(arguments.str, 2, len(arguments.str)-2);
		} else if (isNumeric(str)) {
			return arguments.str;
		} else if (str == "yes") {
			return "true";
		} else if (str == "no") {
			return "false";
		} else if (str == "true" || str == "false") {
			return arguments.str;
		}
		return """" & arguments.str & """";
	}

	/**
	 * Does the generic CF11+ conversion format cftag(arg1=a,arg2=b) 
	 */
	public string function toScriptGeneric(tag) {
		var s = trim(lCase(tag.getName())) & "( ";
		var attributes = tag.getAttributes();
		var attr = "";
		var first = true;
		for (attr in attributes) {
			if (!first) { 
				s&= ", "; 
			}
			s &= attr & "=" & unPound(attributes[attr]);
			first = false;
		}
		return s & " );";
	}

	public string function getIndentChars() {
		if (structKeyExists(variables.options, "indentChars")) {
			return variables.options.indentChars;
		} else {
			return Chr(9);
		}
	}

	public string function getLineBreak() {
		return Chr(13) & Chr(10);
	}

	public string function formatStruct(required struct data) {
		var elems = [];
		var s = "";
		for (local.key in arguments.data) {
			local.value = arguments.data[local.key];
			s = getIndentChars() & local.key & " = ";
			if (isStruct(local.value)) {
				local.vals = [];
				for (local.subkey in local.value) {
					local.vals.append(local.subkey & "=" & checkQuotedVar(local.value[local.subkey]));
				}
				s &= "{" & local.vals.toList(", ") & "}";
			}
			else if (isArray(local.value)) {
				s &= "[" & listQualify(arrayToList(local.value), """",",","char") & "]";
			}
			else {
				s &= """" & local.value & """";
			}
			elems.append(s);
		}

		return getIndentChars() & "{"  & getLineBreak() & elems.toList("," & getLineBreak()) & "}";
	}

	/**
	 * @hint Add quotes for a struct entry if needed
	 *
	 * Wrap a values in quotes if it isn't a variable name. Test is whether it starts and
	 * ends with # or if it's true|fase
	 * 
	 * For values parsed from a tag entry e.g ="true" or ="#myval#", 
	 * 
	 * @value   
	 */
	private string function checkQuotedVar(required string value) {

		if ((Left(arguments.value,1) eq "##" AND Right(arguments.value,1) eq "##")) {
			arguments.value = ListFirst(arguments.value,"##");	
		} 
		else if (NOT listFindNoCase("true,false", arguments.value)) {
			arguments.value =  """" & arguments.value & """";
		}

		return arguments.value;

	}

	/**
	 * Whether to show the tag content in a cfouput tag (default) or to suppress e.g for cfquery
	 * where it is processed sepately.
	 * 
	 * @return {[type]} [description]
	 */
	public boolean function outputContent() {
		return variables._outputContent;
	}

}