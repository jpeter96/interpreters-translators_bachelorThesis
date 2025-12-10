import type { Token, TokenType } from "../token";
import type { Program, Instruction, Statement, Expression, Condition, Assignment, Goto, IfGoto, Halt } from "./ast";

class GotoParser {
  private tokens: Token[];
  private position: number;
  
  constructor(tokens: Token[]) {
    this.tokens = tokens;
    this.position = 0;
  }
  
  private peek(offset: number = 0): Token | undefined {
    return this.tokens[this.position + offset];
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
  
  // Reuse expression parsing
  private parsePrimary(): Expression {
    const token = this.peek();
    if (!token) throw new Error("Expected expression");
    
    if (token.type === "number") {
      this.advance();
      return { type: "number", value: parseInt(token.value) };
    }
    if (token.type === "identifier") {
      this.advance();
      return { type: "variable", name: token.value };
    }
    throw new Error(`Expected number or identifier but got ${token.type}`);
  }
  
  private parseExpression(): Expression {
    const left = this.parsePrimary();
    const token = this.peek();
    if (token && token.type === "operator") {
      const operator = this.advance().value as "+" | "-";
      const right = this.parsePrimary();
      return { type: "binaryOp", operator, left, right };
    }
    return left;
  }
  
  private parseCondition(): Condition {
      const left = this.parseExpression();
      const token = this.peek();
      if (!token || token.type !== "comparison") throw new Error("Expected comparison operator");
      const operator = this.advance().value as any;
      const right = this.parseExpression();
      return { type: "condition", operator, left, right };
  }

  // Parse specific statements
  private parseAssignment(targetVar: string): Assignment {
      this.expect("assign");
      const value = this.parseExpression();
      this.expect("semicolon");
      return { type: "assignment", variable: targetVar, value };
  }

  private parseGoto(): Goto {
      this.expect("keyword"); // GOTO
      const label = this.expect("identifier").value;
      this.expect("semicolon");
      return { type: "goto", label };
  }

  private parseIfGoto(): IfGoto {
      this.expect("keyword"); // IF
      const condition = this.parseCondition();
      
      const nextToken = this.expect("keyword");
      
      // Support strict script syntax: IF ... THEN GOTO ...
      if (nextToken.value === "THEN") {
          const gotoToken = this.expect("keyword");
          if (gotoToken.value !== "GOTO") throw new Error("Expected GOTO after THEN");
      } 
      // Support relaxed syntax: IF ... GOTO ...
      else if (nextToken.value !== "GOTO") {
          throw new Error("Expected GOTO or THEN after IF condition");
      }
      
      const label = this.expect("identifier").value;
      this.expect("semicolon");
      return { type: "if_goto", condition, label };
  }

  private parseHalt(): Halt {
      this.expect("keyword"); // HALT
      this.expect("semicolon");
      return { type: "halt" };
  }

  // Parse one line/instruction
  private parseInstruction(): Instruction {
      let label: string | undefined;
      let token = this.peek();
      
      // Check for Label: Identifier followed by Colon
      if (token?.type === "identifier") {
          const nextToken = this.peek(1);
          if (nextToken?.type === "colon") {
              label = token.value;
              this.advance(); // consume identifier
              this.advance(); // consume colon
              token = this.peek(); // update current token to start of statement
          }
      }

      if (!token) throw new Error("Unexpected end of input inside instruction");

      let statement: Statement;

      if (token.type === "identifier") {
           statement = this.parseAssignment(this.advance().value);
      } else if (token.type === "keyword") {
          if (token.value === "GOTO") {
              statement = this.parseGoto();
          } else if (token.value === "IF") {
              statement = this.parseIfGoto();
          } else if (token.value === "HALT") {
              statement = this.parseHalt();
          } else {
              throw new Error(`Unexpected keyword: ${token.value}`);
          }
      } else {
          throw new Error(`Unexpected token at start of statement: ${token.type}`);
      }

      if (label !== undefined) {
        return { label, statement };
      }
      return { statement };
  }

  public parse(): Program {
    const instructions: Instruction[] = [];
    while (this.peek()) {
      instructions.push(this.parseInstruction());
    }
    return { type: "program", instructions };
  }
}

export = GotoParser;