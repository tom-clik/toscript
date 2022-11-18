component extends="BaseConverter" {
	
	public function init(options) {
		super.init(argumentCollection = arguments);
		variables._outputContent = 0;
		return this;
	}
	
	public string function toScript(tag) {
		var q = {
			"sql" = "",
			"params" = {},
			"options" = tag.getAttributes()
		};

		q.sql = arguments.tag.getInnerContent();

		// Parse params
		// leave this - syntax parsing won't let you use <cfqueryparam>
		local.re = "<cf" & "queryparam" & "[^\>]*>";
		local.params = reMatchNoCase(local.re, q.sql);
		local.count = 1;
		
		for (local.param in local.params) {
			
			// TODO: better extraction of text use pattern with group
			local.tagContent = ReplaceNoCase(ListFirst(local.param,"</>"),"cfqueryparam","");
			local.tagContent = reReplace(local.tagContent, "\(\s+", "(","all");
			local.tagContent = reReplace(local.tagContent, "\s+\)", ")","all");
			q.params["param#local.count#"] = {};
			for (local.attribute in ListToArray(local.tagContent," ")) {
				local.key = ListFirst(local.attribute,"=""'");
				local.value = ListLast(local.attribute,"=""'");
				q.params["param#local.count#"][local.key] = local.value;
			}

			q.sql = ReplaceNoCase(q.sql,local.param,":param#local.count# ");
			local.count ++;
		}
		

		// confusion over name and result. In the test, the name is "local.result"
		// Note that result is a different thing and name is the variable to assign to.
		if (structKeyExists(q.options, "name")) {
			local.name = q.options.name & " = ";
			structDelete(q.options, "name");
		}
		else {
			local.name = "";
		}

		local.sql =  getIndentChars() & "local.sql = """ & q.sql &  """;" & getLineBreak();
		local.sql &= getIndentChars() & "local.params = " & formatStruct(q.params) & ";" & getLineBreak();
		if (structCount(q.options)) {
			local.sql &= getIndentChars() & "local.options = " & formatStruct(q.options) & ";" & getLineBreak();
			local.options_str  = ",options=local.options";
		}
		else {
			local.options_str  = "";
		}
		local.sql &=  getIndentChars() & local.name & "queryExecute(sql=local.sql,params=local.params#local.options_str#);" & getLineBreak();
				
		return local.sql;
	}
	

}