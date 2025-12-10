import type { Token, TokenType } from "../token";
import type { Program, Statement, Expression, Assignment, WhileLoop, IfStatement, Condition } from "./ast";

class WhileParser {
  private tokens: Token[];
  private position: number;
  
  constructor(tokens: Token[]) {
    this.tokens = tokens;
    this.position = 0;
  }
  
  private peek(): Token | undefined {
    return this.tokens[this.position];
  }
  
  private advance(): Token {
    const token = this.peek();
    if (!token) {
      throw new Error("Unexpected end of input");
    }
    this.position++;
    return token;
  }
  
  private expect(type: TokenType, errorMessage?: string): Token {
    const token = this.peek();
    if (!token || token.type !== type) {
      throw new Error(
        errorMessage || `Expected ${type} but got ${token?.type || "end of input"}`
      );
    }
    return this.advance();
  }
  
  // Parse a primary expression (number or variable)
  private parsePrimary(): Expression {
    const token = this.peek();
    
    if (!token) {
      throw new Error("Expected expression but got end of input");
    }
    
    if (token.type === "number") {
      this.advance();
      return {
        type: "number",
        value: parseInt(token.value)
      };
    }
    
    if (token.type === "identifier") {
      this.advance();
      return {
        type: "variable",
        name: token.value
      };
    }
    
    throw new Error(`Expected number or identifier but got ${token.type}`);
  }
  
  // Parse an expression (primary or binary operation)
  private parseExpression(): Expression {
    const left = this.parsePrimary();
    
    const token = this.peek();
    if (token && token.type === "operator") {
      const operator = this.advance().value as "+" | "-";
      const right = this.parsePrimary();
      
      return {
        type: "binaryOp",
        operator: operator,
        left: left,
        right: right
      };
    }
    
    return left;
  }

  // Parse a condition: expr op expr
  private parseCondition(): Condition {
      const left = this.parseExpression();
      
      const token = this.peek();
      if (!token || token.type !== "comparison") {
          throw new Error("Expected comparison operator");
      }
      
      const operator = this.advance().value as "=" | "!=" | "<" | ">" | "<=" | ">=";
      const right = this.parseExpression();
      
      return {
          type: "condition",
          operator: operator,
          left: left,
          right: right
      };
  }
  
  // Parse an assignment: x0 := 5;
  private parseAssignment(): Assignment {
    const varToken = this.expect("identifier");
    this.expect("assign");
    const value = this.parseExpression();
    this.expect("semicolon");
    
    return {
      type: "assignment",
      variable: varToken.value,
      value: value
    };
  }
  
  // Parse a loop: WHILE cond DO ... END
  private parseWhile(): WhileLoop {
    this.expect("keyword"); // WHILE (caller checks value)
    const condition = this.parseCondition();
    
    const doToken = this.expect("keyword");
    if (doToken.value !== "DO") {
        throw new Error("Expected DO after WHILE condition");
    }
    
    const body: Statement[] = [];
    while (true) {
      const token = this.peek();
      if (!token) {
        throw new Error("Expected END but got end of input");
      }
      if (token.type === "keyword" && token.value === "END") {
        this.advance();
        break;
      }
      body.push(this.parseStatement());
    }
    
    return {
      type: "while",
      condition: condition,
      body: body
    };
  }

  // Parse IF: IF cond THEN ... END
  private parseIf(): IfStatement {
      this.expect("keyword"); // IF
      const condition = this.parseCondition();
      
      const thenToken = this.expect("keyword");
      if (thenToken.value !== "THEN") {
          throw new Error("Expected THEN after IF condition");
      }

      const thenBody: Statement[] = [];
      let elseBody: Statement[] | undefined = undefined;

      while (true) {
          const token = this.peek();
          if (!token) throw new Error("Expected END or ELSE but got end of input");
          
          if (token.type === "keyword") {
              if (token.value === "END") {
                  this.advance();
                  break;
              }
              if (token.value === "ELSE") {
                  this.advance();
                  elseBody = [];
                  while(true) {
                      const elseToken = this.peek();
                      if (!elseToken) throw new Error("Expected END after ELSE");
                      if (elseToken.type === "keyword" && elseToken.value === "END") {
                          this.advance();
                          break;
                      }
                      elseBody.push(this.parseStatement());
                  }
                  break; // Exit main loop after processing else block
              }
          }
          thenBody.push(this.parseStatement());
      }

      if (elseBody) {
        return {
            type: "if",
            condition: condition,
            thenBody: thenBody,
            elseBody: elseBody
        };
      }
      return {
          type: "if",
          condition: condition,
          thenBody: thenBody
      };
  }
  
  // Parse a statement (assignment or while or if)
  private parseStatement(): Statement {
    const token = this.peek();
    
    if (!token) {
      throw new Error("Expected statement but got end of input");
    }
    
    if (token.type === "keyword") {
        if (token.value === "WHILE") return this.parseWhile();
        if (token.value === "IF") return this.parseIf();
    }
    
    if (token.type === "identifier") {
      return this.parseAssignment();
    }
    
    throw new Error(`Unexpected token: ${token.type}`);
  }
  
  // Parse entire program
  public parse(): Program {
    const statements: Statement[] = [];
    
    while (this.peek()) {
      statements.push(this.parseStatement());
    }
    
    return {
      type: "program",
      statements: statements
    };
  }
}

export = WhileParser;