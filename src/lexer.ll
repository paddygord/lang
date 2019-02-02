%option noyywrap nodefault

%{
#include "driver.hh"
#include "utils.hh"
#include "parser.hh"
%}

%x COMMENT

%{
#define YY_USER_ACTION loc.columns(yyleng);
%}

%%

%{
yy::location& loc = drv.location;
loc.step();
%}

[ \t]+  loc.step();
\n+     loc.lines(yyleng); loc.step();
";"  return yy::parser::make_SEMICOLON(loc);
","  return yy::parser::make_COMMA(loc);

true                    return yy::parser::make_LITERAL_BOOL_T(ast::literal{true}, loc);
false                   return yy::parser::make_LITERAL_BOOL_F(ast::literal{false}, loc);
[+-]?[0-9_]+            return yy::parser::make_LITERAL_INTEGER(ast::literal{parse_integer(yytext, 10)}, loc);
[+-]?0[xX][0-9a-fA-F_]+ return yy::parser::make_LITERAL_INTEGER(ast::literal{parse_integer(yytext, 16)}, loc);
[+-]?0[oO][0-7_]+       return yy::parser::make_LITERAL_INTEGER(ast::literal{parse_integer(yytext, 8)}, loc);
[+-]?0[bB][0-1_]+       return yy::parser::make_LITERAL_INTEGER(ast::literal{parse_integer(yytext, 2)}, loc);
[+-]?[0-9]+\.[0-9]+     return yy::parser::make_LITERAL_FLOAT(ast::literal{atof(yytext)}, loc);

"="  return yy::parser::make_OP_ASSIGN(loc);

"+"  return yy::parser::make_OP_A_ADD(loc);
"-"  return yy::parser::make_OP_A_SUB(loc);
"*"  return yy::parser::make_OP_A_MUL(loc);
"/"  return yy::parser::make_OP_A_DIV(loc);
"%"  return yy::parser::make_OP_A_MOD(loc);

"&"  return yy::parser::make_OP_B_AND(loc);
"|"  return yy::parser::make_OP_B_OR(loc);
"^"  return yy::parser::make_OP_B_XOR(loc);
"~"  return yy::parser::make_OP_B_NOT(loc);
"<<" return yy::parser::make_OP_B_SHL(loc);
">>" return yy::parser::make_OP_B_SHR(loc);

"&&" return yy::parser::make_OP_L_AND(loc);
"||" return yy::parser::make_OP_L_OR(loc);
"!"  return yy::parser::make_OP_L_NOT(loc);

"==" return yy::parser::make_OP_C_EQ(loc);
"!=" return yy::parser::make_OP_C_NE(loc);
">"  return yy::parser::make_OP_C_GT(loc);
">=" return yy::parser::make_OP_C_GE(loc);
"<"  return yy::parser::make_OP_C_LT(loc);
"<=" return yy::parser::make_OP_C_LE(loc);

"("  return yy::parser::make_OPEN_R_BRACKET(loc);
")"  return yy::parser::make_CLOSE_R_BRACKET(loc);
"["  return yy::parser::make_OPEN_S_BRACKET(loc);
"]"  return yy::parser::make_CLOSE_S_BRACKET(loc);
"{"  return yy::parser::make_OPEN_C_BRACKET(loc);
"}"  return yy::parser::make_CLOSE_C_BRACKET(loc);

if      return yy::parser::make_IF(loc);
else    return yy::parser::make_ELSE(loc);
for     return yy::parser::make_FOR(loc);
while   return yy::parser::make_WHILE(loc);
fn      return yy::parser::make_FUNCTION(loc);
return  return yy::parser::make_RETURN(loc);

bool return yy::parser::make_TYPE(ast::type::t_bool, loc);
u8   return yy::parser::make_TYPE(ast::type::u8, loc);
u16  return yy::parser::make_TYPE(ast::type::u16, loc);
u32  return yy::parser::make_TYPE(ast::type::u32, loc);
u64  return yy::parser::make_TYPE(ast::type::u64, loc);
i8   return yy::parser::make_TYPE(ast::type::i8, loc);
i16  return yy::parser::make_TYPE(ast::type::i16, loc);
i32  return yy::parser::make_TYPE(ast::type::i32, loc);
i64  return yy::parser::make_TYPE(ast::type::i64, loc);
f8   return yy::parser::make_TYPE(ast::type::f8, loc);
f16  return yy::parser::make_TYPE(ast::type::f16, loc);
f32  return yy::parser::make_TYPE(ast::type::f32, loc);
f64  return yy::parser::make_TYPE(ast::type::f64, loc);

[a-zA-Z_][a-zA-Z0-9_]* return yy::parser::make_IDENTIFIER(lookup_or_insert(yytext), loc);

"//".*

"/*" BEGIN(COMMENT);
<COMMENT>"*/" BEGIN(INITIAL);
<COMMENT>.
<COMMENT>\n+  loc.lines(yyleng); loc.step();

<<EOF>> return yy::parser::make_T_EOF(loc);

. throw yy::parser::syntax_error(loc, "unexpected token: " + std::string(yytext));
