import WhileInterpreter = require("../src/while/interpreter");
import WhileParser = require("../src/while/parser");
import Lexer = require("../src/lexer");

describe("WHILE Interpreter", () => {
    test("should execute a simple WHILE program", () => {
        const code = `
            x0 := 5;
            x1 := 0;
            WHILE x0 != 0 DO
                x1 := x1 + 1;
                x0 := x0 - 1;
            END
        `;
        const lexer = new Lexer(code);
        const tokens = lexer.tokenize();
        const parser = new WhileParser(tokens);
        const ast = parser.parse();
        const interpreter = new WhileInterpreter();
        const result = interpreter.evaluate(ast);
        
        expect(result.get("x1")).toBe(5);
    });

    test("should handle IF-THEN-ELSE correctly", () => {
        const code = `
            x0 := 1;
            x1 := 0;
            x2 := 0;
            IF x0 = 1 THEN
                x1 := 1;
            ELSE
                x1 := 2;
            END
            
            IF x0 = 0 THEN
                x2 := 1;
            ELSE
                x2 := 2;
            END
        `;
        const lexer = new Lexer(code);
        const parser = new WhileParser(lexer.tokenize());
        const interpreter = new WhileInterpreter();
        const result = interpreter.evaluate(parser.parse());
        
        expect(result.get("x1")).toBe(1); // True branch
        expect(result.get("x2")).toBe(2); // False branch
    });

    test("should not execute loop body if condition is initially false", () => {
        const code = `
            x0 := 0;
            x1 := 10;
            WHILE x0 != 0 DO
                x1 := x1 + 1;
            END
        `;
        const lexer = new Lexer(code);
        const parser = new WhileParser(lexer.tokenize());
        const interpreter = new WhileInterpreter();
        const result = interpreter.evaluate(parser.parse());
        
        expect(result.get("x1")).toBe(10);
    });

    test("should handle nested IF statements", () => {
        // 2DO
    });

    test("should handle complex comparison operators (<=, >=)", () => {
        // 2DO
    });

    test("should detect infinite loops (safety mechanism)", () => {
        // 2DO
    });
});