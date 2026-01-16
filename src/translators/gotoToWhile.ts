import type { Program as GotoProgram, Instruction, Expression as GotoExpression, Condition as GotoCondition } from "../goto/ast";
import type { Program as WhileProgram, Statement as WhileStatement, Expression as WhileExpression, Condition as WhileCondition } from "../while/ast";

// PC with x_k := 1; WHILE x_k != 0 DO IF x_k = i THEN ... END END
export class GotoToWhileTranslator {
    private labelMap: Map<string, number> = new Map();
    private pcVar: string = "x0";

    private findMaxVariableIndex(program: GotoProgram): number {
        let maxIndex = -1;

        const checkExpr = (expr: GotoExpression): void => {
            if (expr.type === "variable") {
                const match = expr.name.match(/^x(\d+)$/);
                if (match?.[1]) maxIndex = Math.max(maxIndex, parseInt(match[1], 10));
            } else if (expr.type === "binaryOp") {
                checkExpr(expr.left);
                checkExpr(expr.right);
            }
        };

        for (const instr of program.instructions) {
            const stmt = instr.statement;
            if (stmt.type === "assignment") {
                const match = stmt.variable.match(/^x(\d+)$/);
                if (match?.[1]) maxIndex = Math.max(maxIndex, parseInt(match[1], 10));
                checkExpr(stmt.value);
            } else if (stmt.type === "if_goto") {
                checkExpr(stmt.condition.left);
                checkExpr(stmt.condition.right);
            }
        }

        return maxIndex;
    }

    public translate(program: GotoProgram): WhileProgram {
        const instructions = program.instructions;
        
        // Use fresh variable for PC
        this.pcVar = `x${this.findMaxVariableIndex(program) + 1}`;

        // Build label map (1-based)
        this.labelMap = new Map();
        instructions.forEach((instr, i) => {
            if (instr?.label) this.labelMap.set(instr.label, i + 1);
        });

        // Build IF blocks for each instruction
        const ifBlocks: WhileStatement[] = [];
        for (let i = 0; i < instructions.length; i++) {
            const instr = instructions[i];
            if (!instr) continue;
            ifBlocks.push(this.createInstructionBlock(instr, i + 1, i + 2, instructions.length));
        }

        return {
            type: "program",
            statements: [
                { type: "assignment", variable: this.pcVar, value: { type: "number", value: 1 } },
                {
                    type: "while",
                    condition: {
                        type: "condition",
                        operator: "!=",
                        left: { type: "variable", name: this.pcVar },
                        right: { type: "number", value: 0 }
                    },
                    body: ifBlocks
                }
            ]
        };
    }

    private createInstructionBlock(instr: Instruction, pcValue: number, nextPc: number, total: number): WhileStatement {
        const stmt = instr.statement;
        const thenBody: WhileStatement[] = [];
        const nextPcVal = nextPc > total ? 0 : nextPc;

        switch (stmt.type) {
            case "assignment":
                thenBody.push({
                    type: "assignment",
                    variable: stmt.variable,
                    value: this.translateExpression(stmt.value)
                });
                thenBody.push({
                    type: "assignment",
                    variable: this.pcVar,
                    value: { type: "number", value: nextPcVal }
                });
                break;

            case "goto": {
                const targetPc = this.labelMap.get(stmt.label);
                if (targetPc === undefined) throw new Error(`Unknown label: ${stmt.label}`);
                thenBody.push({
                    type: "assignment",
                    variable: this.pcVar,
                    value: { type: "number", value: targetPc }
                });
                break;
            }

            case "if_goto": {
                const targetPc = this.labelMap.get(stmt.label);
                if (targetPc === undefined) throw new Error(`Unknown label: ${stmt.label}`);
                thenBody.push({
                    type: "if",
                    condition: this.translateCondition(stmt.condition),
                    thenBody: [{
                        type: "assignment",
                        variable: this.pcVar,
                        value: { type: "number", value: targetPc }
                    }],
                    elseBody: [{
                        type: "assignment",
                        variable: this.pcVar,
                        value: { type: "number", value: nextPcVal }
                    }]
                });
                break;
            }

            case "halt":
                thenBody.push({
                    type: "assignment",
                    variable: this.pcVar,
                    value: { type: "number", value: 0 }
                });
                break;
        }

        return {
            type: "if",
            condition: {
                type: "condition",
                operator: "=",
                left: { type: "variable", name: this.pcVar },
                right: { type: "number", value: pcValue }
            },
            thenBody
        };
    }

    private translateCondition(cond: GotoCondition): WhileCondition {
        return {
            type: "condition",
            operator: cond.operator,
            left: this.translateExpression(cond.left),
            right: this.translateExpression(cond.right)
        };
    }

    private translateExpression(expr: GotoExpression): WhileExpression {
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
