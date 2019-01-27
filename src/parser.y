%error-verbose

%code requires {
#include "ast.hh"
}

%{
#include "lexer.hh"
#include "utils.hh"
%}

%union {
    ast::identifier identifier;
    ast::block *block;
    ast::if_statement *if_statement;
    ast::for_loop *for_loop;
    ast::while_loop *while_loop;
    ast::function *function;
    ast::assignment *assignment;
    ast::statement *statement;
    ast::program *program;
    ast::literal *literal;
    ast::binary_operator *binary_operator;
    ast::unary_operator *unary_operator;
    ast::expression *expression;
    ast::type type;
    ast::optional_else *optional_else;
    ast::else_if_list *else_if_list;
    ast::statement_list *statement_list;
    ast::parameter_list *parameter_list;
}

%left OP_L_OR
%left OP_L_AND
%left OP_C_EQ OP_C_NE OP_C_GT OP_C_LT OP_C_GE OP_C_LE
%left OP_B_OR
%left OP_B_XOR
%left OP_B_AND
%left OP_B_SHL OP_B_SHR
%left OP_A_ADD OP_A_SUB
%left OP_A_MUL OP_A_DIV OP_A_MOD
%precedence OP_B_NOT OP_L_NOT

%token OP_ASSIGN
%token OPEN_R_BRACKET CLOSE_R_BRACKET
%token OPEN_C_BRACKET CLOSE_C_BRACKET
%token OPEN_S_BRACKET CLOSE_S_BRACKET
%token IF ELSE
%token FOR WHILE
%token FUNCTION RETURN
%token SEMICOLON
%token COMMA
%token <type> TYPE
%token <literal> LITERAL_FLOAT LITERAL_INTEGER LITERAL_BOOL_T LITERAL_BOOL_F
%token <identifier> IDENTIFIER

%type <program> program
%type <literal> literal
%type <expression> exp
%type <statement> statement
%type <block> block
%type <optional_else> optional_else
%type <else_if_list> else_if_list
%type <statement_list> statement_list
%type <parameter_list> parameter_list
%type <assignment> assignment
%type <if_statement> if_statement
%type <for_loop> for_loop
%type <while_loop> while_loop
%type <function> function

%%

program: statement_list { program_ast = $$; };

statement_list: %empty {
              $$ = new ast::statement_list;
              }
              | statement_list statement {
              $1->push_back(*$2);
              }
              ;

statement: block
         { $$ = new ast::statement; $$->type = ast::statement::S_BLOCK; $$->block = $1; }
         | assignment
         { $$ = new ast::statement; $$->type = ast::statement::S_ASSIGNMENT; $$->assignment = $1; }
         | if_statement
         { $$ = new ast::statement; $$->type = ast::statement::S_IF; $$->if_statement = $1; }
         | for_loop
         { $$ = new ast::statement; $$->type = ast::statement::S_FOR; $$->for_loop = $1; }
         | while_loop
         { $$ = new ast::statement; $$->type = ast::statement::S_WHILE; $$->while_loop = $1; }
         | function
         { $$ = new ast::statement; $$->type = ast::statement::S_FUNCTION; $$->function = $1; }
         ;
if_statement: IF OPEN_R_BRACKET exp CLOSE_R_BRACKET block else_if_list optional_else {
            $$ = new ast::if_statement;
            $$->first.push_back(*$3);
            $$->second.push_back(*$5);
            $$->first.insert($$->first.end(), $6->first.begin(), $6->first.end());
            $$->second.insert($$->second.end(), $6->second.begin(), $6->second.end());
            if ($7->has_value()) {
                $$->second.push_back($7->value());
            }
            }
for_loop: FOR OPEN_R_BRACKET exp SEMICOLON exp SEMICOLON exp CLOSE_R_BRACKET block {
        $$ = new ast::for_loop;
        $$->initial = $3;
        $$->condition = $5;
        $$->step = $7;
        $$->block = $9;
        }
while_loop: WHILE OPEN_R_BRACKET exp CLOSE_R_BRACKET block {
          $$ = new ast::while_loop;
          $$->condition = $3;
          $$->block = $5;
          }
function: FUNCTION TYPE IDENTIFIER OPEN_R_BRACKET parameter_list CLOSE_R_BRACKET block {
        $$ = new ast::function;
        $$->returntype = $2;
        $$->parameter_list = *$5;
        }
assignment: TYPE IDENTIFIER OP_ASSIGN exp SEMICOLON {
          $$ = new ast::assignment;
          $$->identifier = $1;
          $$->expression = $4;
          }

optional_else: %empty {
             $$ = new ast::optional_else;
             *$$ = std::nullopt;
             }
             | ELSE block {
             $$ = new std::optional<ast::block>;
             *$$ = *$2;
             }
             ;

else_if_list: %empty {
            $$ = new ast::else_if_list;
            }
            | else_if_list ELSE IF OPEN_R_BRACKET exp CLOSE_R_BRACKET block {
            $1->first.push_back(*$5);
            $1->second.push_back(*$7);
            }
            ;

parameter_list: %empty {
              $$ = new ast::parameter_list;
              }
              | TYPE IDENTIFIER {
              $$ = new ast::parameter_list;
              $$->push_back(std::make_pair($1, $2));
              }
              | parameter_list COMMA TYPE IDENTIFIER {
              $1->push_back(std::make_pair($3, $4));
              }
              ;

block: OPEN_C_BRACKET statement_list CLOSE_C_BRACKET {
     $$ = new ast::block;
     $$->statements = *$2;
     }
     ;

literal: LITERAL_FLOAT
       | LITERAL_INTEGER
       | LITERAL_BOOL_T
       | LITERAL_BOOL_F
       ;

exp: IDENTIFIER {
   $$ = new ast::expression;
   $$->type = ast::expression::VARIABLE;
   $$->variable = $1;
   }
   | literal {
   $$ = new ast::expression;
   $$->type = ast::expression::LITERAL;
   $$->literal = $1; }
   | exp OP_A_ADD exp { $$ = new_bin_op($1, $3, ast::binary_operator::A_ADD); }
   | exp OP_A_SUB exp { $$ = new_bin_op($1, $3, ast::binary_operator::A_SUB); }
   | exp OP_A_MUL exp { $$ = new_bin_op($1, $3, ast::binary_operator::A_MUL); }
   | exp OP_A_DIV exp { $$ = new_bin_op($1, $3, ast::binary_operator::A_DIV); }
   | exp OP_A_MOD exp { $$ = new_bin_op($1, $3, ast::binary_operator::A_MOD); }

   | exp OP_B_AND exp { $$ = new_bin_op($1, $3, ast::binary_operator::B_AND); }
   | exp OP_B_OR  exp { $$ = new_bin_op($1, $3, ast::binary_operator::B_OR ); }
   | exp OP_B_XOR exp { $$ = new_bin_op($1, $3, ast::binary_operator::B_XOR); }
   | OP_B_NOT exp { $$ = new_unary_op($2, ast::unary_operator::B_NOT); }
   | exp OP_B_SHL exp { $$ = new_bin_op($1, $3, ast::binary_operator::B_SHL); }
   | exp OP_B_SHR exp { $$ = new_bin_op($1, $3, ast::binary_operator::B_SHR); }

   | exp OP_C_EQ  exp { $$ = new_bin_op($1, $3, ast::binary_operator::C_EQ ); }
   | exp OP_C_NE  exp { $$ = new_bin_op($1, $3, ast::binary_operator::C_NE ); }
   | exp OP_C_GT  exp { $$ = new_bin_op($1, $3, ast::binary_operator::C_GT ); }
   | exp OP_C_GE  exp { $$ = new_bin_op($1, $3, ast::binary_operator::C_GE ); }
   | exp OP_C_LT  exp { $$ = new_bin_op($1, $3, ast::binary_operator::C_LT ); }
   | exp OP_C_LE  exp { $$ = new_bin_op($1, $3, ast::binary_operator::C_LE ); }

   | exp OP_L_AND exp { $$ = new_bin_op($1, $3, ast::binary_operator::L_AND); }
   | exp OP_L_OR  exp { $$ = new_bin_op($1, $3, ast::binary_operator::L_OR ); }
   | OP_L_NOT exp     { $$ = new_unary_op($2, ast::unary_operator::L_NOT); }

   | OPEN_R_BRACKET exp CLOSE_R_BRACKET { $$ = $2; }
   ;
