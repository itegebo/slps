declare default element namespace "fl";
declare variable $context external;
declare variable $evalexpr external;

declare function local:evalbinary($left,$op,$right)
{
 let $n := $op/text()
 return
  if ($n = 'Plus')
  then data($left)+data($right)
  else
	if ($n = 'Minus')
	then data($left)-data($right)
	else
		if ($left eq $right)
		then 1
		else 0
};

declare function local:fetchfun($prg,$name,$arglen)
{
 for $f in $prg//function
 where data($f/name)=data($name)   (:  and count($f/arg)=$arglen :)
 return $f
};

declare function local:buildsymtab($fun,$expr,$prg)
{
<symtab>
{
 for $cx in 1 to count($fun/arg)
 let
 	 $argname  := $fun/arg[$cx],
	 $argvalue := local:evaluate($expr/arg[$cx],$prg)
 return
	<var>
		<name>{data($argname)}</name>
		<value>{$argvalue}</value>
	</var>
	}
</symtab>
};

declare function local:lookup($name,$table)
{
 for $var in $table/var
 where data($var/name) = $name
 return data($var/value)
};

declare function local:evalapply($prg,$expr)
{
 let
 	$fundef := local:fetchfun($prg,$expr[1]/name/text(),count($expr[1]/arg)),
	$symtab := local:buildsymtab($fundef,$expr,$prg)
 return 
 	 local:evaluate(local:subs($fundef/rhs,$symtab),$prg)  
};

declare function local:subs($expr,$st)
{
 let $type := data($expr[1]/@xsi:type)
 return
  if ($type = "Argument")
  then 
	element{local-name($expr)}
		{
		attribute{"xsi:type"}{"Literal"},
		element{"info"}{local:lookup($expr/name/text(),$st)}
		}
  else 
   	element{local-name($expr)}
		{
		for $at in $expr/@*
		return $at,
		for $el in $expr/*
		return
			if (data($el[1]/@xsi:type))
			then local:subs($el,$st)
			else $el
		}
};

declare function local:evaluate($expr,$prg)
{
 let $type := data($expr[1]/@xsi:type)
 return
  if ($type = "Literal")
  then $expr/info/text()
  else if ($type = "Binary")
  then local:evalbinary(local:evaluate($expr/left,$prg),
                        $expr/ops,
		                local:evaluate($expr/right,$prg))
  else if ($type = "IfThenElse")
  then
  		if (data(local:evaluate($expr/ifExpr,$prg)))
  			then local:evaluate($expr/thenExpr,$prg)
  			else local:evaluate($expr/elseExpr,$prg)  
  else if ($type = "Apply")
  then local:evalapply($prg,$expr)
  else 0 (:("null" ,data($type)) :)
};

let $prg := $context
for $expr in $evalexpr//Fragment
return
	<Fragment xsi:type="Literal">
		<info>{local:evaluate($expr,$prg)}</info>
	</Fragment>
