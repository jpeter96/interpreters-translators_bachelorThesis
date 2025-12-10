// Expressions (Same as LOOP)
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

// Conditions
export type Condition = {
    type: "condition";
    operator: "=" | "!=" | "<" | ">" | "<=" | ">=";
    left: Expression;
    right: Expression;
};

// Statements
export type Assignment = {
    type: "assignment";
    variable: string;
    value: Expression;
};

export type WhileLoop = {
    type: "while";
    condition: Condition;
    body: Statement[];
};

export type IfStatement = {
    type: "if";
    condition: Condition;
    thenBody: Statement[];
    elseBody?: Statement[];
};

export type Statement = Assignment | WhileLoop | IfStatement;

// Program
export type Program = {
    type: "program";
    statements: Statement[];
};
