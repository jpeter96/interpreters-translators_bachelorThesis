import * as fs from 'fs';
import * as path from 'path';

// 2DO: Import interpreters and parsers

function runLoop(code: string, args: Map<string, number>) {
    console.log("Running LOOP program...");
    // 2DO: Implement execution logic
}

function runWhile(code: string, args: Map<string, number>) {
    console.log("Running WHILE program...");
    // 2DO: Implement execution logic
}

function runGoto(code: string, args: Map<string, number>) {
    console.log("Running GOTO program...");
    // 2DO: Implement execution logic
}

function parseArgs(args: string[]): { filePath: string, variables: Map<string, number> } {
    const variables = new Map<string, number>();
    let filePath = "";

    args.forEach(arg => {
        if (arg.startsWith("-")) {
            // Parse variable: -x0=5
            const match = arg.match(/-([a-zA-Z0-9]+)=(\d+)/);
            if (match && match[1] && match[2]) {
                variables.set(match[1], parseInt(match[2]));
            }
        } else {
            filePath = arg;
        }
    });

    return { filePath, variables };
}

function main() {
    const args = process.argv.slice(2);
    
    if (args.length < 2) {
        console.error("Usage: npm run cli <language> <file> [-x0=5 -x1=10 ...]");
        console.error("Languages: loop, while, goto");
        process.exit(1);
    }

    const language = args[0] || "";
    const { filePath, variables } = parseArgs(args.slice(1));

    if (!filePath) {
        console.error("Error: No file specified.");
        process.exit(1);
    }

    try {
        const absolutePath = path.resolve(filePath);
        const code = fs.readFileSync(absolutePath, 'utf-8');

        console.log(`Executing ${language} program from ${filePath}`);
        console.log("Input variables:", Object.fromEntries(variables));

        switch (language.toLowerCase()) {
            case 'loop':
                runLoop(code, variables);
                break;
            case 'while':
                runWhile(code, variables);
                break;
            case 'goto':
                runGoto(code, variables);
                break;
            default:
                console.error(`Unknown language: ${language}`);
                process.exit(1);
        }

    } catch (error: any) {
        console.error("Error:", error.message);
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}
