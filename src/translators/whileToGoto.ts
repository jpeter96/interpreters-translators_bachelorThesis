import type { Program as WhileProgram, Statement as WhileStatement, Expression as WhileExpression, Condition as WhileCondition } from "../while/ast";
import type { Program as GotoProgram, Instruction, Statement as GotoStatement, Expression as GotoExpression, Condition as GotoCondition } from "../goto/ast";

// WHILE cond DO body END  =>  M_i: IF NOT cond THEN GOTO M_j; body; GOTO M_i; M_j: ...
export class WhileToGotoTranslator {
    private labelCounter = 0;
    private nextFreshVarIndex = 0;

    private findMaxVariableIndex(program: WhileProgram): number {
        let maxIndex = -1;

        const checkExpr = (expr: WhileExpression): void => {
            if (expr.type === "variable") {
                const match = expr.name.match(/^x(\d+)$/);
                if (match?.[1]) maxIndex = Math.max(maxIndex, parseInt(match[1], 10));
            } else if (expr.type === "binaryOp") {
                checkExpr(expr.left);
                checkExpr(expr.right);
            }
        };

        const checkStmt = (stmt: WhileStatement): void => {
            if (stmt.type === "assignment") {
                const match = stmt.variable.match(/^x(\d+)$/);
                if (match?.[1]) maxIndex = Math.max(maxIndex, parseInt(match[1], 10));
                checkExpr(stmt.value);
            } else if (stmt.type === "while") {
                checkExpr(stmt.condition.left);
                checkExpr(stmt.condition.right);
                stmt.body.forEach(checkStmt);
            } else if (stmt.type === "if") {
                checkExpr(stmt.condition.left);
                checkExpr(stmt.condition.right);
                stmt.thenBody.forEach(checkStmt);
                stmt.elseBody?.forEach(checkStmt);
            }
        };

        program.statements.forEach(checkStmt);
        return maxIndex;
    }

    private freshLabel(): string {
        return `M${this.labelCounter++}`;
    }

    private freshVar(): string {
        return `x${this.nextFreshVarIndex++}`;
    }

    public translate(program: WhileProgram): GotoProgram {
        this.labelCounter = 0;
        this.nextFreshVarIndex = this.findMaxVariableIndex(program) + 1;
        
        const instructions = this.translateStatements(program.statements);
        instructions.push({ statement: { type: "halt" } });
        
        return { type: "program", instructions };
    }

    private translateStatements(statements: WhileStatement[]): Instruction[] {
        const result: Instruction[] = [];
        for (const stmt of statements) {
            result.push(...this.translateStatement(stmt));
        }
        return result;
    }

    private createNoop(): GotoStatement {
        return {
            type: "assignment",
            variable: this.freshVar(),
            value: { type: "number", value: 0 }
        };
    }

    private translateStatement(stmt: WhileStatement): Instruction[] {
        if (stmt.type === "assignment") {
            return [{
                statement: {
                    type: "assignment",
                    variable: stmt.variable,
                    value: this.translateExpression(stmt.value)
                }
            }];
        }

        if (stmt.type === "while") {
            const labelStart = this.freshLabel();
            const labelEnd = this.freshLabel();

            return [
                {
                    label: labelStart,
                    statement: {
                        type: "if_goto",
                        condition: this.negateCondition(this.translateCondition(stmt.condition)),
                        label: labelEnd
                    }
                },
                ...this.translateStatements(stmt.body),
                { statement: { type: "goto", label: labelStart } },
                { label: labelEnd, statement: this.createNoop() }
            ];
        }

        // IF statement
        const labelElse = this.freshLabel();
        const labelEnd = this.freshLabel();
        const instructions: Instruction[] = [];

        if (stmt.elseBody && stmt.elseBody.length > 0) {
            instructions.push({
                statement: {
                    type: "if_goto",
                    condition: this.negateCondition(this.translateCondition(stmt.condition)),
                    label: labelElse
                }
            });
            instructions.push(...this.translateStatements(stmt.thenBody));
            instructions.push({ statement: { type: "goto", label: labelEnd } });

            const elseInstructions = this.translateStatements(stmt.elseBody);
            if (elseInstructions.length > 0) {
                elseInstructions[0] = { label: labelElse, statement: elseInstructions[0]!.statement };
                instructions.push(...elseInstructions);
            } else {
                instructions.push({ label: labelElse, statement: this.createNoop() });
            }
            instructions.push({ label: labelEnd, statement: this.createNoop() });
        } else {
            instructions.push({
                statement: {
                    type: "if_goto",
                    condition: this.negateCondition(this.translateCondition(stmt.condition)),
                    label: labelEnd
                }
            });
            instructions.push(...this.translateStatements(stmt.thenBody));
            instructions.push({ label: labelEnd, statement: this.createNoop() });
        }

        return instructions;
    }

    private negateCondition(cond: GotoCondition): GotoCondition {
        const negMap: Record<string, GotoCondition["operator"]> = {
            "=": "!=", "!=": "=", "<": ">=", ">": "<=", "<=": ">", ">=": "<"
        };
        return { type: "condition", operator: negMap[cond.operator]!, left: cond.left, right: cond.right };
    }

    private translateCondition(cond: WhileCondition): GotoCondition {
        return {
            type: "condition",
            operator: cond.operator,
            left: this.translateExpression(cond.left),
            right: this.translateExpression(cond.right)
        };
    }

    private translateExpression(expr: WhileExpression): GotoExpression {
        switch (expr.type) {
            case "number": return { type: "number", value: expr.value };
            case "variable": return { type: "variable", name: expr.name };
            case "binaryOp": return {
                type: "binaryOp",
                operator: expr.operator,
                left: this.translateExpression(expr.left),
                right: this.translateExpression(expr.right)
            };
        }
    }
}
