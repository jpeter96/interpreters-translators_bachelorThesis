import LoopInterpreter from "../src/loop/interpreter";
import LoopParser from "../src/loop/parser";
import Lexer from "../src/lexer";

describe("LOOP Interpreter", () => {
    test("simple loop", () => {
        const code = `
            x0 := 5;
            x1 := 0;
            LOOP x0 DO
                x1 := x1 + 1;
            END
        `;
        const lexer = new Lexer(code);
        const parser = new LoopParser(lexer.tokenize());
        const interpreter = new LoopInterpreter();
        const result = interpreter.evaluate(parser.parse());
        
        expect(result.get("x1")).toBe(5);
    });

    test("monus subtraction (no negatives)", () => {
        const code = `
            x0 := 2;
            x1 := 5;
            x2 := x0 - x1;
        `;
        const lexer = new Lexer(code);
        const parser = new LoopParser(lexer.tokenize());
        const interpreter = new LoopInterpreter();
        const result = interpreter.evaluate(parser.parse());
        
        expect(result.get("x2")).toBe(0);
    });

    test("nested loops (multiplication)", () => {
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

    test("loop count captured before execution", () => {
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
        
        expect(result.get("x1")).toBe(5);
        expect(result.get("x0")).toBe(0);
    });

    test("zero iterations", () => {
        const code = `
            x0 := 0;
            x1 := 10;
            LOOP x0 DO
                x1 := x1 + 1;
            END
        `;
        const lexer = new Lexer(code);
        const parser = new LoopParser(lexer.tokenize());
        const interpreter = new LoopInterpreter();
        const result = interpreter.evaluate(parser.parse());
        
        expect(result.get("x1")).toBe(10);
    });

    test("sequential loops", () => {
        const code = `
            x0 := 3;
            x1 := 0;
            LOOP x0 DO
                x1 := x1 + 1;
            END
            x2 := 2;
            LOOP x2 DO
                x1 := x1 + 1;
            END
        `;
        const lexer = new Lexer(code);
        const parser = new LoopParser(lexer.tokenize());
        const interpreter = new LoopInterpreter();
        const result = interpreter.evaluate(parser.parse());
        
        expect(result.get("x1")).toBe(5);
    });

    test("addition", () => {
        const code = `
            x0 := 5;
            x1 := 3;
            x2 := x0 + x1;
        `;
        const lexer = new Lexer(code);
        const parser = new LoopParser(lexer.tokenize());
        const interpreter = new LoopInterpreter();
        const result = interpreter.evaluate(parser.parse());
        
        expect(result.get("x2")).toBe(8);
    });
});

describe("LOOP with initial variables", () => {
    test("initial vars override program assignments", () => {
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
        
        const initialVars = new Map([["x0", 5], ["x1", 6]]);
        const result = interpreter.evaluate(parser.parse(), { initialVariables: initialVars });
        
        expect(result.get("x0")).toBe(5);
        expect(result.get("x1")).toBe(6);
        expect(result.get("x2")).toBe(30);
    });

    test("initial vars work with subsequent modifications", () => {
        const code = `
            x0 := 10;
            x1 := 0;
            LOOP x0 DO
                x1 := x1 + 1;
                x0 := x0 - 1;
            END
        `;
        const lexer = new Lexer(code);
        const parser = new LoopParser(lexer.tokenize());
        const interpreter = new LoopInterpreter();
        
        const initialVars = new Map([["x0", 3]]);
        const result = interpreter.evaluate(parser.parse(), { initialVariables: initialVars });
        
        expect(result.get("x1")).toBe(3);
        expect(result.get("x0")).toBe(0);
    });

    test("partial initial vars", () => {
        const code = `
            x0 := 2;
            x1 := 3;
            x2 := x0 + x1;
        `;
        const lexer = new Lexer(code);
        const parser = new LoopParser(lexer.tokenize());
        const interpreter = new LoopInterpreter();
        
        const initialVars = new Map([["x0", 10]]);
        const result = interpreter.evaluate(parser.parse(), { initialVariables: initialVars });
        
        expect(result.get("x0")).toBe(10);
        expect(result.get("x1")).toBe(3);
        expect(result.get("x2")).toBe(13);
    });
});
