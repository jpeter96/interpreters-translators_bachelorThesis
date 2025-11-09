// Expressions 
export type NumberLiteral = {
    type: "number";
    value: number;
};

export type Variable = {
    type: "variable";
    name: string; // things like x0, x1, x2, etc.
};

export type BinaryExpression = {
    type: "binaryOp";
    operator: "+" | "-";
    left: Expression;
    right: Expression;
};


export type Expression = NumberLiteral | Variable | BinaryExpression; // Union of all possible expressions


// Statements
export type Assignment = {
    type: "assignment";
    variable: string; // things like x0, x1, x2, etc.
    value: Expression;
};

export type Loop = {
    type: "loop";
    counter: string; // things like x0, x1, x2, etc.
    body: Statement[];
};

export type Statement = Assignment | Loop;


// Program
export type Program = {
    type: "program";
    statements: Statement[];
};
