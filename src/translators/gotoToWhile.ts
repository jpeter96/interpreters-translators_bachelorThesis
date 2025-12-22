import type { Program as GotoProgram } from "../goto/ast";
import type { Program as WhileProgram } from "../while/ast";

export class GotoToWhileTranslator {
    public translate(program: GotoProgram): WhileProgram {
        throw new Error("Method not implemented.");
    }
}
