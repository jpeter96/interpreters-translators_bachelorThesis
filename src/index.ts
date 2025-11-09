import type { Program, Assignment, Expression } from "./ast";

// 1. Example: Simple assignment => x0 := 5
const simpleAssignment: Assignment = {
    type: "assignment",
    variable: "x0",
    value: { type: "number", value: 5 }
};

console.log("Simple Assignment:", JSON.stringify(simpleAssignment, null, 2));

// 2. Example: Assignment with expression => x1 := x0 + 3
const expressionAssignment: Assignment = {
    type: "assignment",
    variable: "x1",
    value: {
        type: "binaryOp",
        operator: "+",
        left: { type: "variable", name: "x0" },
        right: { type: "number", value: 3 }
    }
};

console.log("\nExpression Assignment:", JSON.stringify(expressionAssignment, null, 2));

// 3. Example: Complete program => x0 := 5; LOOP x0 DO x1 := x1 + 1 END
const program: Program = {
    type: "program",
    statements: [
        {
            type: "assignment",
            variable: "x0",
            value: { type: "number", value: 5 }
        },
        {
            type: "loop",
            counter: "x0",
            body: [
                {
                    type: "assignment",
                    variable: "x1",
                    value: {
                        type: "binaryOp",
                        operator: "+",
                        left: { type: "variable", name: "x1" },
                        right: { type: "number", value: 1 }
                    }
                }
            ]
        }
    ]
};

console.log("\nComplete Program:", JSON.stringify(program, null, 2));