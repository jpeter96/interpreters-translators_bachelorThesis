import type { Program, Instruction, Statement, Expression, Condition, BinaryExpression } from "./ast";

class GotoInterpreter {
    private variables: Map<string, number>;
    private labelMap: Map<string, number>;

    constructor() {
        this.variables = new Map();
        this.labelMap = new Map();
    }

    public evaluate(program: Program): Map<string, number> {
        this.variables.clear();
        this.labelMap.clear();

        // 1. Build Label Map
        program.instructions.forEach((instr, index) => {
            if (instr.label) {
                if (this.labelMap.has(instr.label)) {
                    throw new Error(`Duplicate label: ${instr.label}`);
                }
                this.labelMap.set(instr.label, index);
            }
        });

        // 2. Execute
        let pc = 0; 
        const instructions = program.instructions;
        let safetyCounter = 0;

        while (pc < instructions.length) {
            if (safetyCounter++ > 1000) throw new Error("Infinite loop detected (safety limit)");

            const instr = instructions[pc];
            if (!instr) break;
            const statement = instr.statement;
            
            let jumped = false;

            switch (statement.type) {
                case "assignment":
                    const value = this.evaluateExpression(statement.value);
                    this.variables.set(statement.variable, value);
                    break;
                case "goto":
                    pc = this.getLabelIndex(statement.label);
                    jumped = true;
                    break;
                case "if_goto":
                    if (this.evaluateCondition(statement.condition)) {
                        pc = this.getLabelIndex(statement.label);
                        jumped = true;
                    }
                    break;
                case "halt":
                    return this.variables;
            }

            if (!jumped) {
                pc++;
            }
        }

        return this.variables;
    }

    private getLabelIndex(label: string): number {
        const index = this.labelMap.get(label);
        if (index === undefined) {
            throw new Error(`Undefined label: ${label}`);
        }
        return index;
    }

    private evaluateExpression(expression: Expression): number {
        switch (expression.type) {
            case "number": return expression.value;
            case "variable": return this.getVariableValue(expression.name);
            case "binaryOp": return this.evaluateBinaryExpression(expression);
        }
    }

    private evaluateBinaryExpression(expression: BinaryExpression): number {
        const left = this.evaluateExpression(expression.left);
        const right = this.evaluateExpression(expression.right);
        switch (expression.operator) {
            case "+": return left + right;
            case "-": return Math.max(0, left - right);
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

export = GotoInterpreter;