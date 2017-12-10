module Obfuscator where

import qualified Data.Map as Map
import           Data.Char          (toLower)
import           Data.List          (intercalate)
import           Parser
import           Syntax
import           System.Environment


writeToFile fileName (CompilationUnit package imports classDecl) = writeFile fileName (
            (getPackage package)
         ++ (getImports imports)
         ++ (getClassDecl classDecl Map.empty)
         )


toLowerStr str = [toLower singleChar | singleChar <- str]


getClassDecl (ClassDecl modifiers name body) mapping = (getModifiers modifiers) ++ "class " ++ (getName name)
                                                ++ "{\n" ++ (getClassBody body mapping) ++ "\n}"


getMethod (MethodDecl modifiers ret_type name params statements) mapping =
                                    (getModifiers modifiers)
                                    ++ (getType ret_type)
                                    ++ (getName name)
                                    ++ "(" ++ formal_params ++ ")"
                                    ++ "{\n" ++ (getStatement statements mapping') ++ "\n}"
                                    where (formal_params, mapping') = (getParams params mapping)


getLiteral literal = case literal of
    Int i -> show i
    Boolean bool -> show bool
    Real double -> show double


getBinOp x = case x of
    Plus -> "+"
    Minus -> "-"
    Times -> "*"
    Divide -> "/"
    Gt -> ">"
    Ge -> ">="
    Lt -> "<"
    Le -> "<="


getObfName name mapping = case (Map.lookup orig_name mapping) of
                                 Just s' -> s'
                                 Nothing -> orig_name
                          where orig_name = getName name


storeObfName name mapping = Map.insert orig_name ("_o_" ++ orig_name ++ "_o_") mapping
                          where orig_name = getName name


getExpr exp mapping = case exp of
    Lit literal -> getLiteral literal
    Var (VarAcc name) -> getObfName name mapping
    Op binOp exp1 exp2 -> (getExpr exp1 mapping) ++ (getBinOp binOp) ++ (getExpr exp2 mapping)



getAltStatement statement mapping = case statement of
    Sequence st1 st2 -> (firstStatement ++ "\n" ++ secondStatement, mapping'')
                    where (firstStatement, mapping') = (getAltStatement st1 mapping)
                          (secondStatement, mapping'') = (getAltStatement st2 mapping')

    Declare (VarDecl _type name) exp -> (((getType _type)
                                   ++ (getObfName name mapping')
                                   ++ (case exp of
                                         Just exp' -> "=" ++ (getExpr exp' mapping')
                                         Nothing -> "")
                                   ++ ";"), mapping')
                                   where mapping' = storeObfName name mapping

    Assign (VarAcc name) exp -> (((getObfName name mapping) ++ "=" ++ (getExpr exp mapping) ++ ";"), mapping)


getStatement statement mapping = statementStrs
    where (statementStrs, mapping') = getAltStatement statement mapping


getParams params mapping = (intercalate ", " [newParam | newParam <- newParamList], new_mapping)
    where (newParamList, new_mapping) = foldl storeParams ([], mapping) params


storeParams (acc_args, acc_mapping) param = ((param' : acc_args), new_acc_mapping)
    where (param', new_acc_mapping) = getParam param acc_mapping


getParam (FormalParameterDecl isFinal _type name) mapping = ((if isFinal then "final " else "")
                                    ++ (getType _type)
                                    ++ (getObfName name mapping'), mapping')
                                    where mapping' = storeObfName name mapping


getType _type = case _type of
    PrimType VoidType                   -> "void "
    PrimType BooleanType                -> "bool "
    PrimType ByteType                   -> "byte "
    PrimType ShortType                  -> "short "
    PrimType IntType                    -> "int "
    PrimType LongType                   -> "long "
    PrimType CharType                   -> "char "
    PrimType FloatType                  -> "float "
    PrimType DoubleType                 -> "double "
    ClassRefType (Identifier className) -> className ++ " "




getClassBody (ClassBody methods) mapping = intercalate "\n" [getMethod method mapping| method <- methods]

getModifiers modifiers = (intercalate " " [getModifier modifier | modifier <- modifiers]) ++ " "

getModifier modifier = toLowerStr $ show modifier


getImports imports = (intercalate "\n" [(getImport _import) | _import <- imports]) ++ "\n"

getImport (ImportDecl isStatic name isWildCard) = "import " ++ (if isStatic then "static " else "")
                                                    ++ (getName name) ++ (if isWildCard then ".*;" else ";")

getPackage packageName = case packageName of
        Just (PackageDecl name) -> "package " ++ (getName name) ++ ";\n"

getName (Name identifiers) = intercalate "." [ x | (Identifier x) <- identifiers]





main = do
    args <- getArgs
    p <- getParsedExp $ head args
    case p of
        Left parseErr -> print parseErr
        Right ast     -> do
            writeFile ((head args) ++ "_obf.ast") (show ast)
            writeToFile ((head args) ++ "_obf.java") ast


