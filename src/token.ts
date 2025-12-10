export type TokenType = 
    | "keyword"
    | "identifier"
    | "number" 
    | "operator"
    | "comparison" // New: =, !=, <, >, <=, >=
    | "assign"
    | "semicolon"
    | "colon";     // New: used for labels like M1:

export type Token = {
    type: TokenType;
    value: string;
}
