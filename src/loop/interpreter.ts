import type { Program, Statement, Expression, BinaryExpression } from "./ast";

class Interpreter {
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
            case "loop":
                const iterations = this.getVariableValue(statement.counter);
                for (let i = 0; i < iterations; i++) {
                    for (const bodyStatement of statement.body) {
                        this.executeStatement(bodyStatement);
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

    private getVariableValue(name: string): number {
        return this.variables.get(name) || 0;
    }
}

export = Interpreter;

