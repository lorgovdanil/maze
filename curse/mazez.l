%{
#include "mazez.tab.h"
#include <stdlib.h>
%}

%% 

"size"		{ return SIZE; }
"choice"	{ return CHOICE; }
"generate"	{ return GENERATE; }
"position"	{ return POSITION; }
"walk"		{ return WALK; }
"exit"		{ return EXIT; }
"help"		{ return HELP; }
"s"		{ return SOLVE; }
[0-9]+		{ yylval.intval = atoi(yytext); return NUMBER; }
"\n"		{ return NEWLINE; }
[ \t]+		{ /* игнорируем пробелы и табуляцию */ }
.		{ printf("Недопустимый ввод\n"); }

%% 
