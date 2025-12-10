import Lexer = require("./lexer");
import LoopParser = require("./loop/parser");
import LoopInterpreter = require("./loop/interpreter");
import WhileParser = require("./while/parser");
import WhileInterpreter = require("./while/interpreter");
import GotoParser = require("./goto/parser");
import GotoInterpreter = require("./goto/interpreter");

// EXAMPLE 1: LOOP Program
// Calculates multiplication: x2 = x0 * x1
console.log("- EX1: LOOP -");
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
const parser = new LoopParser(tokens);
const ast = parser.parse();

console.log("\nInterpreter:");
const interpreter = new LoopInterpreter();
const result = interpreter.evaluate(ast);

console.log("Final Variable State:");
result.forEach((value, key) => {
    console.log(`${key} = ${value}`);
});


// EXAMPLE 2: WHILE Program
console.log("\n\n- EX2: WHILE -");
const whileProgram = `
x0 := 10;
x1 := 2;
x2 := 0;
WHILE x0 >= x1 DO
  x0 := x0 - x1;
  x2 := x2 + 1;
END
`;
console.log("Code:");
console.log(whileProgram.trim());

const whileLexer = new Lexer(whileProgram);
const whileTokens = whileLexer.tokenize();
const whileParser = new WhileParser(whileTokens);
const whileAst = whileParser.parse();

console.log("\nInterpreter:");
const whileInterpreter = new WhileInterpreter();
const whileResult = whileInterpreter.evaluate(whileAst);

console.log("Final Variable State:");
whileResult.forEach((value, key) => {
    console.log(`${key} = ${value}`);
});


// EXAMPLE 3: GOTO Program
console.log("\n\n- EX3: GOTO -");
const gotoProgram = `
x0 := 5;
M1: IF x0 = 0 THEN GOTO M2;
    x0 := x0 - 1;
    GOTO M1;
M2: HALT;
`;
console.log("Code:");
console.log(gotoProgram.trim());

const gotoLexer = new Lexer(gotoProgram);
const gotoTokens = gotoLexer.tokenize();
const gotoParser = new GotoParser(gotoTokens);
const gotoAst = gotoParser.parse();

console.log("\nInterpreter:");
const gotoInterpreter = new GotoInterpreter();
const gotoResult = gotoInterpreter.evaluate(gotoAst);

console.log("Final Variable State:");
gotoResult.forEach((value, key) => {
    console.log(`${key} = ${value}`);
});



