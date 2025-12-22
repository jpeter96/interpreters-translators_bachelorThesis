import type { Program as LoopProgram } from "../loop/ast";
import type { Program as WhileProgram } from "../while/ast";

export class LoopToWhileTranslator {
    public translate(program: LoopProgram): WhileProgram {
        throw new Error("Method not implemented.");
    }
}
