import type { Program as LoopProgram, Statement as LoopStatement, Expression as LoopExpression } from "../loop/ast";
import type { Program as WhileProgram, Statement as WhileStatement, Expression as WhileExpression } from "../while/ast";

// LOOP x_i DO body END  =>  x_k := x_i; WHILE x_k != 0 DO body; x_k := x_k - 1 END
export class LoopToWhileTranslator {
    private nextFreshIndex = 0;

    private findMaxVariableIndex(program: LoopProgram): number {
        let maxIndex = -1;

        const checkExpr = (expr: LoopExpression): void => {
            if (expr.type === "variable") {
                const match = expr.name.match(/^x(\d+)$/);
                if (match?.[1]) maxIndex = Math.max(maxIndex, parseInt(match[1], 10));
            } else if (expr.type === "binaryOp") {
                checkExpr(expr.left);
                checkExpr(expr.right);
            }
        };

        const checkStmt = (stmt: LoopStatement): void => {
            if (stmt.type === "assignment") {
                const match = stmt.variable.match(/^x(\d+)$/);
                if (match?.[1]) maxIndex = Math.max(maxIndex, parseInt(match[1], 10));
                checkExpr(stmt.value);
            } else if (stmt.type === "loop") {
                const match = stmt.counter.match(/^x(\d+)$/);
                if (match?.[1]) maxIndex = Math.max(maxIndex, parseInt(match[1], 10));
                stmt.body.forEach(checkStmt);
            }
        };

        program.statements.forEach(checkStmt);
        return maxIndex;
    }

    private freshVar(): string {
        return `x${this.nextFreshIndex++}`;
    }

    public translate(program: LoopProgram): WhileProgram {
        this.nextFreshIndex = this.findMaxVariableIndex(program) + 1;
        return {
            type: "program",
            statements: this.translateStatements(program.statements)
        };
    }

    private translateStatements(statements: LoopStatement[]): WhileStatement[] {
        const result: WhileStatement[] = [];
        for (const stmt of statements) {
            result.push(...this.translateStatement(stmt));
        }
        return result;
    }

    private translateStatement(stmt: LoopStatement): WhileStatement[] {
        if (stmt.type === "assignment") {
            return [{
                type: "assignment",
                variable: stmt.variable,
                value: this.translateExpression(stmt.value)
            }];
        }

        // LOOP => WHILE transformation
        const tempVar = this.freshVar();
        
        const initTemp: WhileStatement = {
            type: "assignment",
            variable: tempVar,
            value: { type: "variable", name: stmt.counter }
        };

        const decrementTemp: WhileStatement = {
            type: "assignment",
            variable: tempVar,
            value: {
                type: "binaryOp",
                operator: "-",
                left: { type: "variable", name: tempVar },
                right: { type: "number", value: 1 }
            }
        };

        const whileLoop: WhileStatement = {
            type: "while",
            condition: {
                type: "condition",
                operator: "!=",
                left: { type: "variable", name: tempVar },
                right: { type: "number", value: 0 }
            },
            body: [...this.translateStatements(stmt.body), decrementTemp]
        };

        return [initTemp, whileLoop];
    }

    private translateExpression(expr: LoopExpression): WhileExpression {
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
