@contributor{Vadim Zaytsev - vadim@grammarware.net - SWAT, CWI}
module extract::RascalADT2BGF

import IO;
import List;
import String;
import syntax::BGF;
import normal::BGF;
import io::WriteBGF;

layout LO = [\ \t\n\r]* !>> [\ \t\n\r];
syntax DataDef =  Name "=" {DataExpr "|"}+ ";";
lexical Name = [a-zA-Z_0-9]+ !>> [a-zA-Z_0-9] ; 
syntax DataExpr
	= Name "(" {DataExpr ","}* ")"
	| Name "[" DataExpr "]" Name?
	| Name Name?
	;

public void main(list[str] args)
{
	writeBGF(process(|cwd:///|+args[0]),|cwd:///|+args[1]);
	println("Extraction completed.");
}

public void main()
{
	iprintln(process(|project://fl/src/Abstract.rsc|));
}

BGFGrammar process(loc src)
{
	str gs = readFile(src);
	defs = split("data ",gs);
	list[BGFProduction] ps = [];
	for (d <- slice(defs,1,size(defs)-1))
	{
		str name = trim(split("=",d)[0]);
		println("Parsing <name>...");
		ps += def2prod(parse(#DataDef,trim(d)));
	}
	return normalise(syntax::BGF::grammar([],ps));
}

list[BGFProduction] def2prod((DataDef)`<Name n> = <DataExpr d> ;`)
	= [production("","<n>",expr2expr(d))];
default list[BGFProduction] def2prod((DataDef)`<Name n> = <{DataExpr "|"}+ ds> ;`)
	= [production("","<n>",expr2expr(d)) | d <- ds];

BGFExpression type2expr((Name)`str`) = val(string());
BGFExpression type2expr((Name)`int`) = val(integer());
default BGFExpression type2expr(Name n) = nonterminal("<n>");

BGFExpression expr2expr((DataExpr)`<Name t>`) = nonterminal("<t>");
BGFExpression expr2expr((DataExpr)`<Name t><Name n>`) = selectable("<n>",type2expr(t));
BGFExpression expr2expr((DataExpr)`<Name n>()`) = selectable("<n>",epsilon());
BGFExpression expr2expr((DataExpr)`<Name n>(<DataExpr e>)`) = selectable("<n>",expr2expr(e));
BGFExpression expr2expr((DataExpr)`<Name n>(<{DataExpr ","}* es>)`) = selectable("<n>",sequence([expr2expr(e) | e <- es]));
BGFExpression expr2expr((DataExpr)`list[<DataExpr e>]`) = star(expr2expr(e));
BGFExpression expr2expr((DataExpr)`list[<DataExpr e>] <Name n>`) = selectable("<n>",star(expr2expr(e)));
BGFExpression expr2expr((DataExpr)`set[<DataExpr e>]`) = star(expr2expr(e));
BGFExpression expr2expr((DataExpr)`set[<DataExpr e>] <Name n>`) = selectable("<n>",star(expr2expr(e)));
default BGFExpression expr2expr(DataExpr e) = terminal("UNK<e>");
