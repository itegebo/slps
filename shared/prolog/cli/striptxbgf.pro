:- ensure_loaded('../slps.pro').

stript(p(As,N,X1),[abstractize(p(As,N,X2))]) 
 :-
    transform(try(stript_rule),X1,X2),
    \+ X1 == X2,
    !.

stript(_,[]).

stript_rule(X,{X}) :- X = t(_).

main :- 
   current_prolog_flag(argv,Argv),
   append(_,['--',BgfFile,XbgfFile],Argv),
   loadXml(BgfFile,BgfXml),
   xmlToG(BgfXml,g(_,Ps)),
   maplist(stript,Ps,Tss),
   concat(Tss,Ts),
   xbgf2xml(sequence(Ts),Xbgf),
   saveXml(XbgfFile,Xbgf),
   halt.

:- run.
