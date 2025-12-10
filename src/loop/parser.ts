import type { Token, TokenType } from "../token";
import type { Program, Statement, Expression, Assignment, Loop } from "./ast";

class Parser {
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
  
  // Parse a loop: LOOP x0 DO ... END
  private parseLoop(): Loop {
    this.expect("keyword"); // LOOP
    const counterToken = this.expect("identifier");
    this.expect("keyword"); // DO
    
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
      type: "loop",
      counter: counterToken.value,
      body: body
    };
  }
  
  // Parse a statement (assignment or loop)
  private parseStatement(): Statement {
    const token = this.peek();
    
    if (!token) {
      throw new Error("Expected statement but got end of input");
    }
    
    if (token.type === "keyword" && token.value === "LOOP") {
      return this.parseLoop();
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

export = Parser;