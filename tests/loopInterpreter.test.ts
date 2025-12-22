import LoopInterpreter = require("../src/loop/interpreter");
import LoopParser = require("../src/loop/parser");
import Lexer = require("../src/lexer");

describe("LOOP Interpreter", () => {
    test("should execute a simple LOOP program", () => {
        const code = `
            x0 := 5;
            x1 := 0;
            LOOP x0 DO
                x1 := x1 + 1;
            END
        `;
        const lexer = new Lexer(code);
        const tokens = lexer.tokenize();
        const parser = new LoopParser(tokens);
        const ast = parser.parse();
        const interpreter = new LoopInterpreter();
        const result = interpreter.evaluate(ast);
        
        expect(result.get("x1")).toBe(5);
    });

    test("should handle modified subtraction (monus)", () => {
        const code = `
            x0 := 2;
            x1 := 5;
            x2 := x0 - x1;
        `;
        const lexer = new Lexer(code);
        const parser = new LoopParser(lexer.tokenize());
        const interpreter = new LoopInterpreter();
        const result = interpreter.evaluate(parser.parse());
        
        expect(result.get("x2")).toBe(0); // 2 - 5 = 0 in N_0
    });

    test("should handle nested loops (multiplication)", () => {
        const code = `
            x0 := 3;
            x1 := 4;
            x2 := 0;
            LOOP x0 DO
                LOOP x1 DO
                    x2 := x2 + 1;
                END
            END
        `;
        const lexer = new Lexer(code);
        const parser = new LoopParser(lexer.tokenize());
        const interpreter = new LoopInterpreter();
        const result = interpreter.evaluate(parser.parse());
        
        expect(result.get("x2")).toBe(12);
    });

    test("loop count should be determined before execution", () => {
        // Changing x0 inside the loop should NOT affect iteration count
        const code = `
            x0 := 5;
            x1 := 0;
            LOOP x0 DO
                x1 := x1 + 1;
                x0 := 0; 
            END
        `;
        const lexer = new Lexer(code);
        const parser = new LoopParser(lexer.tokenize());
        const interpreter = new LoopInterpreter();
        const result = interpreter.evaluate(parser.parse());
        
        expect(result.get("x1")).toBe(5); // Should still run 5 times
        expect(result.get("x0")).toBe(0); // x0 is indeed 0 at the end
    });

    test("should handle zero iterations correctly", () => {
        // 2DO
    });

    test("should correctly handle multiple sequential loops", () => {
        // 2DO
    });

    test("should handle addition with variables", () => {
        // 2DO
    });
});