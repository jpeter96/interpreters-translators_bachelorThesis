export type TokenType = 
    | "keyword"
    | "identifier"
    | "number" 
    | "operator"
    | "assign"
    | "semicolon";


export type Token = {
    type: TokenType;
    value: string;
}