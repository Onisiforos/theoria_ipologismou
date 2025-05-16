%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <math.h>
	#include <string.h>
	#include "cgen.h"
	
	extern int yylex(void); //after flex file.l yylex.c is created, there you can find yylex()
	extern int lineNum;
		// Useful buffers
	char function_names[1000] = "";
	char function_in_c[1000] = "";
	char comp_type_var[1000] = "";
	
	// Flag inside comp or not
	int flag = 0;
	
%}

%union{
	char* string;
	int num;
}


/* --- Tokens  --- */
%token KW_IF
%token KW_ELSE
%token KW_ENDIF
%token KW_FOR
%token KW_IN
%token KW_ENDFOR
%token KW_WHILE
%token KW_ENDWHILE
%token KW_BREAK
%token KW_CONTINUE
%token KW_DEF
%token KW_ENDDEF
%token KW_MAIN
%token KW_RETURN
%token KW_COMP
%token KW_ENDCOMP
%token KW_OF
%token KW_INTEGER
%token KW_SCALAR
%token KW_STR
%token KW_BOOL
%token KW_CONST

%token TK_TRUE
%token TK_FALSE

%token DEL_SEMI_COL
%token DEL_COMMA
%token DEL_COLON


%token <string> VAR_IDENT
%token <string> VAR_INT
%token <string> VAR_FLOAT
%token <string> VAR_CONST_STR
%token <string> VAR_COMP_IDENT //NEW TOKEN IDENTIFIERS FOR COMP CHARACTERS

%token DEFMACRO

// Tokens with associativity and precedence
%right	OP_ASSGN OP_PLUS_EQ OP_MINUS_EQ OP_MULT_EQ OP_DIV_EQ OP_MOD_EQ OP_COL_EQ
%left	TK_OR
%left	TK_AND
%right 	TK_NOT
%left	OP_EQ OP_NEQ
%left	OP_L OP_LE OP_G OP_GE
%left 	TK_PLUS TK_MINUS
%left	OP_MULT OP_DIV OP_MOD 
%right	OP_POWER
%left	DEL_PERIOD DEL_LPAREN DEL_RPAREN DEL_LBRACKET DEL_RBRACKET


// Type declaration
%type <string> program
%type <string> expr
%type <string> data_type
%type <string> variable_declaration
%type <string> variable_list
%type <string> main_function
%type <string> main_body
%type <string> statements
%type <string> type_declaration
%type <string> const_declaration

%type <string> function_declaration
%type <string> function_body
%type <string> param_list
%type <string> parameters
%type <string> return_type
%type <string> multifunctiom_declaration

%type <string>  comp_declaration
%type <string>  comp_body
%type <string> comp_field
%type <string> comp_function
%type <string> comp_field_list
%type <string> comp_function_body
%type <string>  assignment_statement
%type <string>  if_statement
%type <string> statement
%type <string>  for_statement
%type <string>  while_statement
%type <string>  break_statement
%type <string>  continue_statement
%type <string>  return_statement
%type <string> function_call
%type <string> arg_list
%type <string> simple_table_statement
%type <string>  complex_table_statement
%type <string>  empty_statement

%start program 

%%
//*******************************Program Body*******************************

program:
	comp_declaration program  {printf("%s\n%s", $1, $2);} // try below or theirs
	|multifunctiom_declaration main_function {printf("%s\n%s", $1, $2);}
	|main_function {printf("%s\n", $1);}
;
//|multifunctiom_declaration main_function {printf("%s\n%s", $1, $2);}



multifunctiom_declaration:
	multifunctiom_declaration function_declaration { $$ = template("%s\n%s", $1, $2);}
	| function_declaration { $$ = $1; }
;

/******************************* Main function *******************************/
main_function:
	KW_DEF KW_MAIN DEL_LPAREN DEL_RPAREN DEL_COLON main_body KW_ENDDEF DEL_SEMI_COL { $$ = template("int main(){\n%s\n}", $6); }
;

/******************************* Main body *******************************/
main_body:
	statements { $$ = $1; }
	  //printf("%s\n", $1);
	
;


//	main_body statements { $$ = template("%s\n%s", $1, $2);
//		       // printf("%s\n", $2);
//	}
	  
//	  | statements { $$ = $1; }
	  //printf("%s\n", $1); old
	

/******************************* Statements *******************************/
statements:
	statements statement {$$ = template("%s\n%s", $1, $2);}
	|statement { $$ = $1; }
; // because multi statement were often

statement:
	type_declaration { $$ = $1; }
	|const_declaration { $$ = $1; }
	// |expr { $$ = $1; } //remember why or remove    //temp out due to shift/reduce conflic
	|assignment_statement { $$ = $1; }
	|if_statement { $$ = $1; }
	|for_statement { $$ = $1; }
	|while_statement { $$ = $1; }
	|break_statement { $$ = $1; }
	|continue_statement { $$ = $1; }
	|return_statement { $$ = $1; } //move it here, change what is need
	| function_call { $$ = $1; }
	| simple_table_statement { $$ = $1; }
	|complex_table_statement { $$ = $1; }
	|empty_statement { $$ = $1; }
;



assignment_statement:
	VAR_IDENT OP_ASSGN expr DEL_SEMI_COL{$$ = template("%s = %s;", $1, $3);}
;

if_statement:
	KW_IF DEL_LPAREN expr DEL_RPAREN DEL_COLON statements KW_ELSE DEL_COLON statements KW_ENDIF DEL_SEMI_COL { $$ = template("if (%s){\n%s\n} else {\n%s\n}", $3, $6, $9); }
	|KW_IF DEL_LPAREN expr DEL_RPAREN DEL_COLON statements KW_ELSE DEL_COLON KW_ENDIF DEL_SEMI_COL { $$ = template("if (%s){\n%s\n} else {}", $3, $6); }
	|KW_IF DEL_LPAREN expr DEL_RPAREN DEL_COLON KW_ELSE DEL_COLON statements KW_ENDIF DEL_SEMI_COL { $$ = template("if (%s){} else {\n%s\n}", $3, $8); }
	|KW_IF DEL_LPAREN expr DEL_RPAREN DEL_COLON KW_ELSE DEL_COLON KW_ENDIF DEL_SEMI_COL { $$ = template("if (%s){} else {}", $3); }
	|KW_IF DEL_LPAREN expr DEL_RPAREN DEL_COLON statements KW_ENDIF DEL_SEMI_COL { $$ = template("if (%s){\n%s\n} ", $3, $6); }
	|KW_IF DEL_LPAREN expr DEL_RPAREN DEL_COLON KW_ENDIF DEL_SEMI_COL { $$ = template("if (%s){} ", $3); }
;	
	
for_statement: 
	KW_FOR VAR_IDENT KW_IN DEL_LBRACKET VAR_INT DEL_COLON VAR_INT DEL_COLON VAR_INT DEL_RBRACKET DEL_COLON statements KW_ENDFOR DEL_SEMI_COL { $$ = template("for(int %s=%s; %s<=%s; %s+=%s){\n%s\n} ", $2, $5, $2, $7, $2, $9, $12); }
	| KW_FOR VAR_IDENT KW_IN DEL_LBRACKET VAR_INT DEL_COLON VAR_INT DEL_COLON DEL_RBRACKET DEL_COLON statements KW_ENDFOR DEL_SEMI_COL { $$ = template("for(int %s=%s; %s<=%s; %s+=1){\n%s\n} ", $2, $5, $2, $7, $2, $11); }
	|KW_FOR VAR_IDENT KW_IN DEL_LBRACKET VAR_INT DEL_COLON VAR_INT DEL_COLON VAR_INT DEL_RBRACKET DEL_COLON KW_ENDFOR DEL_SEMI_COL { $$ = template("for(int %s=%s; %s<=%s; %s+=%s){} ", $2, $5, $2, $7, $2, $9); }
	| KW_FOR VAR_IDENT KW_IN DEL_LBRACKET VAR_INT DEL_COLON VAR_INT DEL_COLON DEL_RBRACKET DEL_COLON KW_ENDFOR DEL_SEMI_COL { $$ = template("for(int %s=%s; %s<=%s; %s+=1){} ", $2, $5, $2, $7, $2); }
;

while_statement:
	KW_WHILE DEL_LPAREN expr DEL_RPAREN DEL_COLON statements KW_ENDWHILE DEL_SEMI_COL { $$ = template("while(%s){\n%s\n}", $3, $6); }
	|KW_WHILE DEL_LPAREN expr DEL_RPAREN DEL_COLON KW_ENDWHILE DEL_SEMI_COL { $$ = template("while(%s){}", $3); }

;

	
break_statement:
	KW_BREAK DEL_SEMI_COL { $$ = template("break;"); }
	;

continue_statement:
	KW_CONTINUE DEL_SEMI_COL { $$ = template("continue;"); }
	;
	
return_statement:
	KW_RETURN DEL_SEMI_COL {$$ = template("return;");}
	| KW_RETURN expr DEL_SEMI_COL {$$ = template("return %s;", $2);}
	
;

function_call:
	VAR_IDENT DEL_LPAREN arg_list DEL_RPAREN DEL_SEMI_COL	{ $$ = template("%s(%s);", $1, $3); }
;

arg_list:
	expr DEL_COMMA arg_list {$$ = template("%s, %s", $1, $3);}
	| expr {$$ = $1;}
	| %empty {$$ = template("");}
;

simple_table_statement:
	VAR_IDENT OP_COL_EQ DEL_LBRACKET expr KW_FOR VAR_IDENT DEL_COLON expr DEL_RBRACKET DEL_COLON data_type DEL_SEMI_COL 
	{ 
	$$ = template("%s* %s = (%s*)malloc(%s * sizeof(%s));\nfor (int %s = 0; %s < %s; ++%s){\n\t%s[%s] = %s;\n}", $11, $1, $11, $8, $11, $6, $6, $8, $6, $1, $6, $4);
	}
	; 
	
	
complex_table_statement: 
    VAR_IDENT OP_COL_EQ DEL_LBRACKET expr KW_FOR VAR_IDENT DEL_COLON data_type KW_IN VAR_IDENT KW_OF expr DEL_RBRACKET DEL_COLON data_type DEL_SEMI_COL 
	{ 
        char* old_exp = template(" %s ", $4);	// Copy of the expression to be processed
	char new_exp[1000] = "";       		// Buffer for the new expression with elements replaced
	const char* elm = $6;          		// Element in the expression to be replaced

	// Create the replacement string "array[array_i]"
	char* replace_elm = template("%s[%s_i]", $10, $10);


	// Tokenize the expression 'old_exp' using 'elm' as the delimiter
	char* token = strtok(old_exp, elm);

	while (token != NULL) {
	    strcat(new_exp, token);
	    token = strtok(NULL, elm);
	    if (token != NULL) {
		strcat(new_exp, replace_elm);
	    }
	}

	
	$$ = template("%s* %s = (%s*)malloc(%s * sizeof(%s));\nfor(int %s_i = 0; %s_i < %s; ++%s_i) {\n\t%s[%s_i] = %s;\n}", $15, $1, $15, $12, $15, $10, $10, $12, $10, $1, $10, new_exp);

	free(old_exp);
	free(replace_elm);
	
	}
	;

empty_statement:
	DEL_SEMI_COL { $$ = template(";"); }
	;

/******************************* Expressions *******************************/
expr:
	VAR_INT { $$ = $1; }
	| VAR_FLOAT { $$ = $1; }
	| VAR_CONST_STR { $$ = $1; }
	| VAR_IDENT { $$ = $1; }
	| TK_TRUE { $$ = "1"; }
	| TK_FALSE { $$ = "0"; }
	
	// | DEL_PERIOD  //access member of complex type
	| VAR_IDENT DEL_LBRACKET expr DEL_RBRACKET {$$ = template("%s[%s]", $1, $3);}
	| VAR_IDENT DEL_LPAREN expr DEL_RPAREN {$$ = template("%s(%s)", $1, $3);}  //expr other have arg_list
	| DEL_LPAREN expr DEL_RPAREN {$$ = template("(%s)", $2);} //expr other have arg_list
	| expr OP_POWER expr {$$ = template("pow(%s, %s)", $1, $3);}

	| TK_PLUS expr {$$ = template("(+%s)", $2);}
	| TK_MINUS expr {$$ = template("(-%s)", $2);}
	
	| expr OP_MULT expr {$$ = template("%s * %s", $1, $3);}
	| expr OP_DIV expr {$$ = template("%s / %s", $1, $3);}
	| expr OP_MOD expr {$$ = template("%s %% %s", $1, $3);}
	| expr TK_PLUS expr {$$ = template("%s + %s", $1, $3);}
	| expr TK_MINUS expr {$$ = template("%s - %s", $1, $3);}
	| expr OP_L expr {$$ = template("%s < %s", $1, $3);}
	| expr OP_LE expr {$$ = template("%s <= %s", $1, $3);}
	| expr OP_G expr {$$ = template("%s > %s", $1, $3);}
	| expr OP_GE expr {$$ = template("%s >= %s", $1, $3);}
	| expr OP_EQ expr {$$ = template("%s == %s", $1, $3);}
	| expr OP_NEQ expr {$$ = template("%s != %s", $1, $3);}
	| TK_NOT expr {$$ = template("!%s", $2);}
	| expr TK_AND expr {$$ = template("%s && %s", $1, $3);}
	| expr TK_OR expr {$$ = template("%s || %s", $1, $3);}
	| expr OP_ASSGN expr {$$ = template("%s = %s", $1, $3);}
	| expr OP_PLUS_EQ expr {$$ = template("%s += %s", $1, $3);} 
	| expr OP_MINUS_EQ expr {$$ = template("%s -= %s", $1, $3);} 
	| expr OP_MULT_EQ expr {$$ = template("%s *= %s", $1, $3);}
	| expr OP_DIV_EQ expr {$$ = template("%s /= %s", $1, $3);}
	| expr OP_MOD_EQ expr {$$ = template("%s %= %s", $1, $3);}
	| expr OP_COL_EQ expr {$$ = template("%s := %s", $1, $3);}
	//check in in c its correct the last := 
;

/***************************** Type declarations ****************************/
type_declaration:
	//type_declaration variable_declaration { $$ = template("%s\n%s", $1, $2);// Print C code section header to the console

		        //printf("%s\n", $2);
	//}
	   variable_declaration { $$ = $1; } // above removed due to shift reduce conflic, if used on in statement maybe(yes) promblem
	  //printf("%s\n", $1);
;



/******************************* Data types *******************************/
data_type :
	KW_INTEGER { $$ = template("int"); }  //template("C99 antistoixisi"")
	| KW_SCALAR { $$ = template("double"); }
	| KW_STR { $$ = template("char*"); }
	| KW_BOOL { $$ = template("int"); }
	//| <- that was here why
;



/******************************* Variables *******************************/
variable_declaration :
	variable_list DEL_COLON data_type DEL_SEMI_COL {$$ = template("%s %s;", $3 , $1);} 
	| VAR_IDENT DEL_LBRACKET VAR_INT DEL_RBRACKET  DEL_COLON data_type DEL_SEMI_COL {$$ = template("%s %s[%s];", $6 , $1, $3);}
	| VAR_IDENT DEL_LBRACKET DEL_RBRACKET DEL_COLON data_type DEL_SEMI_COL {$$ = template("%s* %s;", $5, $1);}  //shift/reduce conflict!!!
;

variable_list:
	VAR_IDENT {$$ = $1;}
	| variable_list DEL_COMMA VAR_IDENT {$$ = template("%s, %s", $1 , $3);}  //px//  i,j : scalar
;


//****************************** Constants ******************************

const_declaration:
	KW_CONST VAR_IDENT OP_ASSGN expr DEL_COLON data_type DEL_SEMI_COL {$$ = template("const %s %s = %s;", $6, $2, $4);}  //const pi = 3.14: scalar;
	;
	
// ****************************** Functions ******************************
function_declaration:
	KW_DEF VAR_IDENT DEL_LPAREN param_list DEL_RPAREN TK_MINUS OP_G return_type DEL_COLON function_body KW_ENDDEF DEL_SEMI_COL { $$ = template("%s %s(%s){\n%s\n}", $8, $2, $4, $10 );}
	| KW_DEF VAR_IDENT DEL_LPAREN param_list DEL_RPAREN DEL_COLON function_body KW_ENDDEF DEL_SEMI_COL { $$ = template("void %s(%s){\n%s\n}", $2, $4, $7 );}

	|KW_DEF VAR_IDENT DEL_LPAREN  DEL_RPAREN TK_MINUS OP_G return_type DEL_COLON function_body KW_ENDDEF DEL_SEMI_COL { $$ = template("%s %s(){\n%s\n}", $7, $2, $9 );}
	| KW_DEF VAR_IDENT DEL_LPAREN  DEL_RPAREN DEL_COLON function_body KW_ENDDEF DEL_SEMI_COL { $$ = template("void %s(){\n%s\n}", $2, $6 );}
;

function_body:
	statements { $$ = template("%s\n", $1);}
;

param_list:
	param_list DEL_COMMA parameters { $$ = template("%s, %s", $1, $3);}
	| parameters { $$ = $1; }
;

parameters:
	VAR_IDENT DEL_COLON data_type  {$$ = template("%s %s", $3 , $1);} 
	| VAR_IDENT DEL_LBRACKET VAR_INT DEL_RBRACKET  DEL_COLON data_type  {$$ = template("%s %s[%s]", $6 , $1, $3);}
	| VAR_IDENT DEL_LBRACKET DEL_RBRACKET DEL_COLON data_type  {$$ = template("%s* %s", $5, $1);}  //shift/reduce conflict!!!
;


return_type:
	data_type { $$ = $1; }
;

// ****************************** Complex Types ******************************
comp_declaration:
	KW_COMP VAR_IDENT DEL_COLON comp_body KW_ENDCOMP DEL_SEMI_COL   
	{} 
;

comp_body:
	comp_body comp_field { $$ = template("%s\n%s", $1, $2);}
	| comp_body comp_function { $$ = template("%s\n%s", $1, $2);}
	| %empty { $$ = template(""); }
;

comp_field:
	comp_field_list DEL_COLON data_type DEL_SEMI_COL { flag = 1; $$ = template("%s %s;", $3, $1); }
;

comp_field_list:
	VAR_COMP_IDENT DEL_COMMA comp_field_list DEL_COLON {$$ = template("%s, %s", $1, $3);}
	|VAR_COMP_IDENT DEL_LBRACKET expr DEL_RBRACKET DEL_COMMA comp_field_list {$$ = template("%s[%s], %s", $1, $3, $6);}
	|VAR_COMP_IDENT DEL_LBRACKET DEL_RBRACKET DEL_COMMA comp_field_list {$$ = template("%s[], %s", $1, $5);}
	|VAR_COMP_IDENT DEL_LBRACKET DEL_RBRACKET {$$ = template("%s[]", $1);}
	|VAR_COMP_IDENT DEL_LBRACKET expr DEL_RBRACKET {$$ = template("%s[%s]", $1, $3);}
	|VAR_COMP_IDENT {$$ = $1;}
;

comp_function:
	KW_DEF VAR_IDENT DEL_LPAREN param_list DEL_RPAREN TK_MINUS OP_G return_type DEL_COLON comp_function_body KW_ENDDEF DEL_SEMI_COL //with param and return type
	 { $$ = template("%s (*%s) (struct type_name *self, %s);", $8, $2, $4);}
	|KW_DEF VAR_IDENT DEL_LPAREN param_list DEL_RPAREN DEL_COLON comp_function_body KW_ENDDEF DEL_SEMI_COL //with param no return type
	  { $$ = template("void (*%s) (struct type_name *self, %s);", $2, $4);}
	|KW_DEF VAR_IDENT DEL_LPAREN DEL_RPAREN TK_MINUS OP_G return_type DEL_COLON comp_function_body KW_ENDDEF DEL_SEMI_COL //no param and return type
	 { $$ = template("%s (*%s) (struct type_name *self);", $7, $2);}
	|KW_DEF VAR_IDENT DEL_LPAREN DEL_RPAREN DEL_COLON comp_function_body KW_ENDDEF DEL_SEMI_COL //no param no return type
	 { $$ = template("void (*%s) (struct type_name *self);", $2);}
;

comp_function_body:
	statements { $$ = $1; }
	;	
	


%%
int main(){
//printf("%d\n", yylex());
	if(yyparse() != 0)  //calls yylex()  to take the tokens and do syntax analysis
		printf("\nRejected!\n");
	else
		printf("\nAccepted!\n");
}
