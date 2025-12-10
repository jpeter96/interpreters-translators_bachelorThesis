// Reuse common types
export type NumberLiteral = {
    type: "number";
    value: number;
};

export type Variable = {
    type: "variable";
    name: string;
};

export type BinaryExpression = {
    type: "binaryOp";
    operator: "+" | "-";
    left: Expression;
    right: Expression;
};

export type Expression = NumberLiteral | Variable | BinaryExpression;

export type Condition = {
    type: "condition";
    operator: "=" | "!=" | "<" | ">" | "<=" | ">=";
    left: Expression;
    right: Expression;
};

// GOTO specific statements
export type Assignment = {
    type: "assignment";
    variable: string;
    value: Expression;
};

export type Goto = {
    type: "goto";
    label: string;
};

export type IfGoto = {
    type: "if_goto";
    condition: Condition;
    label: string;
};

export type Halt = {
    type: "halt";
};

export type Statement = Assignment | Goto | IfGoto | Halt;

export type Instruction = {
    label?: string; // Optional label (e.g., "M1")
    statement: Statement;
};

export type Program = {
    type: "program";
    instructions: Instruction[];
};
