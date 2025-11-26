import Lexer = require("./lexer");
import Parser = require("./parser");
import Interpreter = require("./interpreter");

console.log("=== BACHELOR THESIS: INTERPRETERS & TRANSLATORS ===\n");

// EXAMPLE 1: LOOP Program
// Calculates multiplication: x2 = x0 * x1
console.log("--- EXAMPLE 1: LOOP PROGRAM (Multiplication) ---");
const loopProgram = `
x0 := 3;
x1 := 4;
x2 := 0;
LOOP x0 DO
  LOOP x1 DO
    x2 := x2 + 1;
  END
END
`;
console.log("Code:");
console.log(loopProgram.trim());

const lexer = new Lexer(loopProgram);
const tokens = lexer.tokenize();
const parser = new Parser(tokens);
const ast = parser.parse();

console.log("\nRunning Interpreter...");
const interpreter = new Interpreter();
const result = interpreter.evaluate(ast);

console.log("Result Variables:");
result.forEach((value, key) => {
    console.log(`${key} = ${value}`);
});


// EXAMPLE 2: WHILE Program (Conceptual)
console.log("\n\n--- EXAMPLE 2: WHILE PROGRAM (Division - Conceptual) ---");
const whileProgram = `
x0 := 10;
x1 := 2;
x2 := 0;
WHILE x0 >= x1 DO
  x0 := x0 - x1;
  x2 := x2 + 1;
END
`;
console.log("Code (Not yet supported by parser):");
console.log(whileProgram.trim());


// EXAMPLE 3: GOTO Program (Conceptual)
console.log("\n\n--- EXAMPLE 3: GOTO PROGRAM (Simple Loop - Conceptual) ---");
const gotoProgram = `
x0 := 5;
M1: IF x0 = 0 GOTO M2;
    x0 := x0 - 1;
    GOTO M1;
M2: HALT;
`;
console.log("Code (Not yet supported by parser):");
console.log(gotoProgram.trim());
