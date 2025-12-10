import type { Program, Statement, Expression, BinaryExpression, Condition } from "./ast";

class WhileInterpreter {
    private variables: Map<string, number>;

    constructor() {
        this.variables = new Map();
    }

    public evaluate(program: Program): Map<string, number> {
        this.variables.clear();
        for (const statement of program.statements) {
            this.executeStatement(statement);
        }
        return this.variables;
    }

    private executeStatement(statement: Statement): void {
        switch (statement.type) {
            case "assignment":
                const value = this.evaluateExpression(statement.value);
                this.variables.set(statement.variable, value);
                break;
            case "while":
                let safetyCounter = 0;
                while (this.evaluateCondition(statement.condition)) {
                    if (safetyCounter++ > 1000) throw new Error("Infinite loop detected (safety limit)");
                    
                    for (const bodyStatement of statement.body) {
                        this.executeStatement(bodyStatement);
                    }
                }
                break;
            case "if":
                if (this.evaluateCondition(statement.condition)) {
                    for (const stmt of statement.thenBody) {
                        this.executeStatement(stmt);
                    }
                } else if (statement.elseBody) {
                    for (const stmt of statement.elseBody) {
                        this.executeStatement(stmt);
                    }
                }
                break;
        }
    }

    private evaluateExpression(expression: Expression): number {
        switch (expression.type) {
            case "number":
                return expression.value;
            case "variable":
                return this.getVariableValue(expression.name);
            case "binaryOp":
                return this.evaluateBinaryExpression(expression);
        }
    }

    private evaluateBinaryExpression(expression: BinaryExpression): number {
        const left = this.evaluateExpression(expression.left);
        const right = this.evaluateExpression(expression.right);

        switch (expression.operator) {
            case "+":
                return left + right;
            case "-":
                return Math.max(0, left - right); 
        }
    }

    private evaluateCondition(condition: Condition): boolean {
        const left = this.evaluateExpression(condition.left);
        const right = this.evaluateExpression(condition.right);

        switch (condition.operator) {
            case "=": return left === right;
            case "!=": return left !== right;
            case "<": return left < right;
            case ">": return left > right;
            case "<=": return left <= right;
            case ">=": return left >= right;
        }
    }

    private getVariableValue(name: string): number {
        return this.variables.get(name) || 0;
    }
}

export = WhileInterpreter;