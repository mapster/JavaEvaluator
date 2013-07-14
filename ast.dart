library JavaAst;

import 'types.dart';

class Program {
  final List<CompilationUnit> compilationUnits;
  List<MemberSelect> mainSelectors = new List<MemberSelect>();
  
  Program(List<Map<String, dynamic>> ast) : compilationUnits = new List<CompilationUnit>(){
    ast.forEach((Map unit){
      compilationUnits.add(parseObject(unit));
    });
  }
  
  parseObject(Map json){
    if(json == null)
      return;
    //TODO add support for block node
    switch(json['NODE_TYPE']){
      case 'array_access':
        return new ArrayAccess.fromJson(json, parseObject(json['index']), parseObject(json['expr']));
      case 'class':
        return parseClass(json);
      case 'compile_unit':
        return parseCompilationUnit(json);
      case 'method':
        return parseMethod(json);
      case 'variable':
        return parseVar(json);
      case 'method_call':
        return parseMethodCall(json);
      case 'assignment':
        return parseAssignment(json);
      case 'literal':
        return parseLiteral(json);
      case 'if':
        return parseIf(json);
      case 'parenthesized':
        return parseObject(json['body']);
      case 'binary':
        return new BinaryOp.fromJson(json, parseObject(json['left_op']), parseObject(json['right_op']));
      case 'identifier':
        return new Identifier.fromJson(json); 
      case 'array':
        return new TypeNode(parseObject(json['value']));
      case 'primitive':
        return json['value'];
      case 'member_select':
        return new MemberSelect.fromJson(json, parseObject(json['expr']));
      case 'new_array':
        return new NewArray.fromJson(json, new TypeNode(parseObject(json['type'])), json['dimensions'].map(parseObject).toList());
      case 'new':
        return new NewObject.fromJson(json, parseObject(json['name']), json['arguments'].map(parseObject).toList());
      case 'return':
        return new Return.fromJson(json, parseObject(json['expr']));
      default:
        throw "Object type not supported yet: ${json['NODE_TYPE']}";
    }
  }

  parseMethodCall(json) => new MethodCall.fromJson(json, parseObject(json['select']), json['arguments'].map(parseObject).toList());

  parseIf(json){
    List then;
    Map thenJson = json['then'];
    if(thenJson['NODE_TYPE'] == 'block')
      then = thenJson['statements'].map(parseObject).toList();
    else
      then = [parseObject(thenJson)];
    

    List elze;
    Map elzeJson = json['else'];
    if( elzeJson != null){
      if(elzeJson['NODE_TYPE'] == 'block')
        elze = elzeJson['statements'].map(parseObject).toList();
      else 
        elze = [parseObject(elzeJson)];
    }
      
    return new If.fromJson(json, parseObject(json['condition']), then, elze);
  }

  parseLiteral(json) =>  new Literal.fromJson(json);

  parseAssignment(Map json) => new Assignment.fromJson(json, parseObject(json['variable']), parseObject(json['expr']));

  parseMethod(Map json) {
    MethodDecl method = new MethodDecl.fromJson(json, new TypeNode(parseObject(json['type'])), json['parameters'].map(parseObject).toList(), json['body']['statements'].map(parseObject).toList());
    return method;
  }
  
  CompilationUnit parseCompilationUnit(Map json){
    dynamic package = Identifier.DEFAULT_PACKAGE;
    if(json.containsKey('package'))
      package = parseObject(json['package']);
    
    List imports = [];
    if(json.containsKey('imports'))
      imports = json['imports'].map(parseObject).toList();
    
    List typeDeclarations = [];
    var jsonDecl = json['type_declarations'];
    if(jsonDecl != null && jsonDecl is List)
      typeDeclarations = json['type_declarations'].map(parseObject).toList();
    else {
      typeDeclarations = new List<ClassDecl>();
      typeDeclarations.add(parseObject(jsonDecl));
    }
      
    //if a class has a main method, create a selector for it
   List<ClassDecl> mains = typeDeclarations.where((ClassDecl clazz) =>
       clazz.staticMethods.any((MethodDecl m) => m.name == "main" && m.type == MethodType.main)).toList();
   mains.forEach((ClassDecl clazz) {
     mainSelectors.add(new MemberSelect.mainMethod(new MemberSelect(clazz.name, package)));
   });
    
    
    return new CompilationUnit.fromJson(json, package, imports, typeDeclarations);
  }
  
  ClassDecl parseClass(Map json){
    ClassDecl clazz = new ClassDecl.fromJson(json, json['members'].map(parseObject).toList());
    return clazz;  
  }

  Variable parseVar(Map json) {
    return new Variable.fromJson(json, new TypeNode(parseObject(json['type'])), parseObject(json['initializer']));
  }
}

class ASTNode {
  static int _counter = 0;
  
  final int startPos;
  final int endPos;
  final List<String> modifiers;
  final int nodeId;
  
  const ASTNode.fixed({this.startPos, this.endPos, this.modifiers, this.nodeId: -1});
  ASTNode({this.startPos, this.endPos, this.modifiers}) : this.nodeId = _counter++;  
  
  ASTNode.fromJson(Map json) : this.nodeId = _counter++, this.startPos = json['startPos'], this.endPos = json['endPos'], this.modifiers = []{
    Map modifiersJson = json['modifiers']; 
    if(modifiersJson != null && modifiersJson.containsKey('modifiers')){
      if(modifiersJson['modifiers'] is List)
        this.modifiers.addAll(modifiersJson['modifiers']);
      else
        this.modifiers.add(modifiersJson['modifiers']);
    }
  }
  
  bool get isStatic => modifiers != null && modifiers.contains("static");
    
}

class ArrayAccess extends ASTNode {
  final ASTNode index;
  final ASTNode expr;
  
  ArrayAccess.fromJson(Map json, this.index, this.expr) : super.fromJson(json);
}

class Assignment extends ASTNode {
  final ASTNode id;
  final expr;

//  Assignment(this.id, this.expr, [int startPos, int endPos]) : super(startPos, endPos);
  Assignment.fromJson(Map json, this.id, this.expr) : super.fromJson(json);
  
  String toString() => "$id = $expr";
}

class BinaryOp extends ASTNode {
  static const String EQUAL = "EQUAL_TO";
  static const String PLUS = "PLUS";
  static const String MINUS = "MINUS";
  static const String MULT = "MULTIPLY";
  static const String DIV = "DIVIDE";
  static const String AND = "CONDITIONAL_AND";
  static const String OR = "CONDITIONAL_OR";
  
  final String type;
  final left;
  final right;
  
//  BinaryOp(this.type, this.left, this.right, [int startPos, int endPos]) : super(startPos, endPos);
  BinaryOp.fromJson(Map json, this.left, this.right) : this.type = json['type'], super.fromJson(json);
  
  bool operator==(other){
    if(identical(other, this))
      return true;
    
    return type == other.type;
  }
  
  String toString() => "$left ${operatorToString(type)} $right";
  
  static operatorToString(String op){
    switch(op){
      case EQUAL:
        return "==";
      case PLUS:
        return "+";
      case MINUS:
        return "-";
      case MULT:
        return "*";
      case DIV:
        return "/";
      case AND:
        return "&&";
      case OR:
        return "||";
      default:
        throw "Operator toString not supported for: $op";
    }
  }
}

class ClassDecl extends ASTNode {
  final Identifier name;
  
  final List<Variable> instanceVariables;
  final List<Variable> staticVariables;
  final List<MethodDecl> instanceMethods;
  final List<MethodDecl> staticMethods;
  final List<MethodDecl> constructors;
  final List<ASTNode> members;
  
  const ClassDecl(this.name, List<ASTNode> this.members, 
                  {this.instanceMethods, this.staticMethods, this.staticVariables, this.instanceVariables, this.constructors}) : super.fixed();
  
  ClassDecl.fromJson(Map json, List<ASTNode> members) : this.name = new Identifier(json['name']),this.members = members, 
                                      this.staticMethods = members.where((m) => m.isStatic && m is MethodDecl).toList(),
                                      this.instanceMethods = members.where((m) => !m.isStatic && m is MethodDecl).toList(),
                                      this.staticVariables = members.where((v) => v.isStatic && v is Variable).toList(),
                                      this.instanceVariables = members.where((v) => !v.isStatic && v is Variable).toList(),
                                      this.constructors = members.where((m) => m is MethodDecl && m.isConstructor).toList(),
                                      super.fromJson(json){
    this.constructors.forEach((m) => m.publicName = name.name);
  }
}

class CompilationUnit extends ASTNode {
  final package;
  final List<MemberSelect> imports;
  final List<ClassDecl> typeDeclarations;
  
  CompilationUnit.fromJson(Map json, this.package, this.imports, this.typeDeclarations) : super.fromJson(json);
}

class Identifier extends ASTNode {
  final String name;
  
  Identifier(this.name) : super();
  const Identifier.fixed(this.name) : super.fixed();
  Identifier.fromJson(Map json) : name = json['value'], super.fromJson(json);
  static const Identifier CONSTRUCTOR = const Identifier.fixed("<init>");
  static const Identifier DEFAULT_PACKAGE = const Identifier.fixed("");
  
  int get hashCode => 17 * 37 + name.hashCode; 
  
  bool operator==(other){
    if(identical(other, this))
      return true;
    
    Identifier i = other;
    return name == i.name;
  }
  
  String toString() => name;
}

class If extends ASTNode {
  final dynamic condition;
  final List<ASTNode> then;
  final List<ASTNode> elze;
  
  If.fromJson(Map json, this.condition, this.then, [this.elze]) : super.fromJson(json);
}

class Literal extends ASTNode {
  static const String INT = 'INT_LITERAL';
  static const String STRING = 'STRING_LITERAL';
  static const String CHAR = 'CHAR_LITERAL';
  static const String BOOL = 'BOOLEAN_LITERAL';
  static const String DOUBLE = 'DOUBLE_LITERAL';
  static const String NULL = 'NULL_LITERAL';
  
  final String type;
  dynamic get value => _value;  
  dynamic _value;
  bool get isText => type == CHAR || isString;
  bool get isString => type == STRING;
  
  
  String toString() {
    if(type == STRING)
      return "\"$value\"";
    else if(type == CHAR)
      return "'&#$value;'";
    else
      return "$value";
  }
  
  Literal.fromJson(Map json) : this.type = json['type'], super.fromJson(json) {
    switch(type){
      case INT:
        _value = new IntegerValue(int.parse(json['value'])); break;
      case DOUBLE:
        _value = new DoubleValue(double.parse(json['value'])); break;
      case STRING:
        _value = json['value']; break;
      case BOOL:
        _value = new BooleanValue(json['value'] == 'true'); break;
      case CHAR:
        _value = new CharValue(int.parse(json['value'])); break;
      case NULL:
        _value = ReferenceValue.nullRef; break;
      default:
        throw "Literal type not supported yet: ${type}";
    }
  }
}

class MemberSelect extends ASTNode {
  final Identifier member_id;
  final ASTNode owner;
  
  Identifier get getRoot => owner is MemberSelect ? (owner as MemberSelect).getRoot : owner; 
  
//  MemberSelect(final member_id, this.owner, [int startPos, int endPos]) : this.member_id = new Identifier(member_id), super(startPos, endPos);
  MemberSelect.fromJson(Map json, this.owner) : this.member_id = new Identifier(json['member_id']), super.fromJson(json);
  const MemberSelect.mainMethod(this.owner) : member_id = const Identifier.fixed("main"), super.fixed();
  MemberSelect(this.member_id, this.owner) : super();
  
  String toString() => "$owner.$member_id";
}

class MethodCall extends ASTNode {
  final ASTNode select;
  final List<dynamic> arguments;
  
//  MethodCall(this.select, this.arguments, [int startPos, int endPos]) : super(startPos, endPos);
  MethodCall.fromJson(Map json, this.select, this.arguments) : super.fromJson(json);
  
//  MethodCall.main(this.arguments) : super(), this.select = const MemberSelect("main", new Identifier("Mains"));
  
  String toString() => "$select()"; 
}

class MethodDecl extends ASTNode {
  static const String CONSTRUCTOR_NAME = "<init>";
  
  final String _name;
  String _publicName;
  final MethodType type;
  final List<Variable> parameters;
  final List _body;
  List get body => _body.toList();
  
  MethodDecl(this._name, TypeNode returnType, List<Variable> parameters, this._body, [int startPos, int endPos]) : this.type = new MethodType(returnType, parameters.map((v) => v.type).toList()), 
                                                                                                            this.parameters = parameters, super(startPos:startPos, endPos:endPos);
  MethodDecl.fromJson(Map json, TypeNode returnType, parameters, this._body) : this._name = json['name'], this.type = new MethodType(returnType, parameters.map((v) => v.type).toList()), this.parameters = parameters, super.fromJson(json); 
  
  bool get isConstructor => !isStatic && _name == CONSTRUCTOR_NAME;
  String get name => _name;
         set publicName(String name) => _publicName = name;
  String get publicName => _publicName != null ? _publicName : name;
  
  bool operator==(other){
    if(identical(other, this))
      return true;
    
    return _name == other._name && type == other.type; 
  }
  
  String toString() {
    return "$name: $type";
  }
}

class MethodType {
  final TypeNode returnType;
  final List<TypeNode> parameters;
  
  const MethodType(this.returnType, this.parameters);
  
  static const MethodType main = const MethodType(TypeNode.VOID, const [const TypeNode.fixed(TypeNode.STRING)]);
  
  String toString() => "$parameters -> $returnType";
  
  bool operator==(MethodType other){
    if(identical(other, this))
      return true;
    
    if(returnType != other.returnType || parameters.length != other.parameters.length)
      return false;
    
    for(int i = 0; i < parameters.length; i++){
      if(parameters[i] != other.parameters[i])
        return false;
    }

    return true;
  }
}

class NewArray extends ASTNode {
  final TypeNode type;
  final List<ASTNode> dimensions;
  
  NewArray.fromJson(Map json, this.type, this.dimensions) : super.fromJson(json);
}

class NewObject extends ASTNode {
  final Identifier name;
  final List<ASTNode> arguments;
  
  NewObject.fromJson(Map json, this.name, this.arguments) : super.fromJson(json);
}

class Return extends ASTNode {
  final dynamic expr;
  
  Return.fromJson(Map json, this.expr) : super.fromJson(json);
  
  String toString() => "return $expr"; 
}

class TypeNode extends ASTNode {
  final type;

  TypeNode(this.type) : super() {
    if(!(type is String || type is TypeNode || type is Identifier || type == null)){
      throw "Invalid type: ${type.runtimeType}";
    }
  }
  const TypeNode.fixed(this.type) : super.fixed();
  
  bool get isPrimitive => type is String;
  bool get isArray => type is TypeNode;
  bool get isDeclared => type is Identifier;
  bool get isVoid => type == VOID;
  
  static const TypeNode VOID = const TypeNode.fixed("VOID");
  static const TypeNode STRING = const TypeNode.fixed(const Identifier.fixed("String"));
  static const TypeNode INT = const TypeNode.fixed("INT");
  static const TypeNode CHAR = const TypeNode.fixed("CHAR");
  
  String toString(){
    if(isArray)
      return "${type}[]";
    
    if(isPrimitive)
      return "${type.toLowerCase()}";
      
    return "$type";
  }
  
  bool operator==(TypeNode other){
    if(identical(other, this))
      return true;
    
    TypeNode t = other;
    if((isArray && other.isArray) || 
      (isPrimitive && other.isPrimitive) ||
      (isDeclared && other.isDeclared))
      return type == t.type;
    
    return false;
  }
  
  static const Map<String, PrimitiveValue> DEFAULT_VALUES = 
      const {'INT': IntegerValue.defaultValue, 'LONG': LongValue.defaultValue, 
              'FLOAT': FloatValue.defaultValue, 'DOUBLE': DoubleValue.defaultValue};
}

class Variable extends ASTNode {
  final String name;
  final TypeNode type;
  final initializer;
  
//  Variable(this.name, this.type, this.initializer, [int startPos, int endPos, List<String> modifiers]) : super(startPos, endPos, modifiers);
  Variable.fromJson(Map json, this.type, this.initializer) : name = json['name'], super.fromJson(json);
  const Variable(this.name, this.type, this.initializer) : super.fixed();
  
  int get hashCode => 17 * 37 + name.hashCode; 
  
  bool operator==(other){
    if(identical(other, this))
      return true;
    
    return name == other.name;
  }
  
  String toString() => "$type ${name}${initializer != null ? " = $initializer" : ""}";
}