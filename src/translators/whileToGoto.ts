import type { Program as WhileProgram } from "../while/ast";
import type { Program as GotoProgram } from "../goto/ast";

export class WhileToGotoTranslator {
    public translate(program: WhileProgram): GotoProgram {
        throw new Error("Method not implemented.");
    }
}
