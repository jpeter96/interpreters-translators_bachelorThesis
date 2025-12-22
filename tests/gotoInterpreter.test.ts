import GotoInterpreter = require("../src/goto/interpreter");
import GotoParser = require("../src/goto/parser");
import Lexer = require("../src/lexer");

describe("GOTO Interpreter", () => {
    test("should execute simple GOTO program", () => {
        const code = `
            x0 := 5;
            M1: IF x0 = 0 THEN GOTO M2;
            x0 := x0 - 1;
            GOTO M1;
            M2: HALT;
        `;
        const lexer = new Lexer(code);
        const tokens = lexer.tokenize();
        const parser = new GotoParser(tokens);
        const ast = parser.parse();
        const interpreter = new GotoInterpreter();
        const result = interpreter.evaluate(ast);
        
        expect(result.get("x0")).toBe(0);
    });

    test("should handle backward jumps (loop simulation)", () => {
        // Count down from 3
        const code = `
            x0 := 3;
            x1 := 0;
            M1: IF x0 = 0 THEN GOTO M2;
            x1 := x1 + 1;
            x0 := x0 - 1;
            GOTO M1;
            M2: HALT;
        `;
        const lexer = new Lexer(code);
        const parser = new GotoParser(lexer.tokenize());
        const interpreter = new GotoInterpreter();
        const result = interpreter.evaluate(parser.parse());
        
        expect(result.get("x1")).toBe(3);
        expect(result.get("x0")).toBe(0);
    });

    test("should handle unconditional GOTO", () => {
        const code = `
            x0 := 1;
            GOTO M1;
            x0 := 2;
            M1: HALT;
        `;
        const lexer = new Lexer(code);
        const parser = new GotoParser(lexer.tokenize());
        const interpreter = new GotoInterpreter();
        const result = interpreter.evaluate(parser.parse());
        
        expect(result.get("x0")).toBe(1); // "x0 := 2" should be skipped
    });

    test("should handle forward jumps skipping code", () => {
        // 2DO
    });

    test("should handle complex spaghetti code flow", () => {
        // 2DO
    });

    test("should handle HALT in the middle of the program", () => {
        // 2DO
    });
});