part of JavaEvaluator;

class ASTNode {
  static int _counter = 0;
  
  final int startPos;
  final int endPos;
  final List<String> modifiers;
  int nodeId = _counter++;
  
  ASTNode([this.startPos, this.endPos, this.modifiers]);
    
  ASTNode.fromJson(Map json) : this.startPos = json['startPos'], this.endPos = json['endPos'], this.modifiers = []{
    Map modifiersJson = json['modifiers']; 
    if(modifiersJson != null && modifiersJson.containsKey('modifiers')){
      if(modifiersJson['modifiers'] is List)
        this.modifiers.addAll(modifiersJson['modifiers']);
      else
        this.modifiers.add(modifiersJson['modifiers']);
    }
  }
  
  bool isStatic() => modifiers != null && modifiers.contains("static");
    
}

class ArrayAccess extends ASTNode {
  final ASTNode index;
  final ASTNode expr;
  
  ArrayAccess.fromJson(Map json, this.index, this.expr) : super.fromJson(json);
}

class Assignment extends ASTNode {
  final Identifier id;
  final expr;

  Assignment(this.id, this.expr, [int startPos, int endPos]) : super(startPos, endPos);
  Assignment.fromJson(Map json, this.id, this.expr) : super.fromJson(json);
  
  String toString() => "$id = $expr";
}

class BinaryOp extends ASTNode {
  static const String EQUAL = "EQUAL_TO";
  static const String PLUS = "PLUS";
  static const String MINUS = "MINUS";
  static const String MULT = "MULTIPLY";
  static const String DIV = "DIVIDE";
  
  final String type;
  final left;
  final right;
  
  BinaryOp(this.type, this.left, this.right, [int startPos, int endPos]) : super(startPos, endPos);
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
      default:
        throw "Operator toString not supported for: $op";
    }
  }
}

class ClassDecl extends ASTNode {
  String name;
  
  final List<Variable> instanceVariables;
  final List<Variable> staticVariables;
  final List<MethodDecl> instanceMethods;
  final List<MethodDecl> staticMethods;
  final List<ASTNode> members;
  
  ClassDecl.fromJson(Map json, List<ASTNode> members) : this.name = json['name'],this.members = members, 
                                      this.staticMethods = members.where((m) => m.isStatic() && m is MethodDecl).toList(),
                                      this.instanceMethods = members.where((m) => !m.isStatic() && m is MethodDecl).toList(),
                                      this.staticVariables = members.where((v) => v.isStatic() && v is Variable).toList(),
                                      this.instanceVariables = members.where((v) => !v.isStatic() && v is Variable).toList(),
                                      super.fromJson(json);
}

class Identifier extends ASTNode {
  final String name;
  
  Identifier(this.name, [int startPos, int endPos]) : super(startPos, endPos);
  Identifier.fromJson(Map json) : name = json['value'], super.fromJson(json);
  
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
  final String _type;
  dynamic get value => _value;  
  dynamic _value;
  
  String get type {
    switch(_type){
      case 'INT_LITERAL':
        return 'int';
      case 'STRING_LITERAL':
        return 'String';
    }
  }
  
  String toString() {
    if(_type == 'STRING_LITERAL')
      return "\"$value\"";
    else
      return "$value";
  }
  
  Literal.fromJson(Map json) : this._type = json['type'], super.fromJson(json) {
    switch(_type){
      case 'INT_LITERAL':
        _value = new IntegerValue(int.parse(json['value'])); break;
      case 'DOUBLE_LITERAL':
        _value = new DoubleValue(double.parse(json['value'])); break;
      case 'STRING_LITERAL':
        _value = json['value']; break;
      case 'BOOLEAN_LITERAL':
        _value = json['value'] == 'true'; break;
      default:
        throw "Literal type not supported yet: ${_type}";
    }
  }
}

class MemberSelect extends ASTNode {
  final Identifier member_id;
  final ASTNode owner;
  
  MemberSelect(final member_id, this.owner, [int startPos, int endPos]) : this.member_id = new Identifier(member_id), super(startPos, endPos);
  MemberSelect.fromJson(Map json, this.owner) : this.member_id = new Identifier(json['member_id']), super.fromJson(json);
  
  String toString() => "$owner.$member_id";
}

class MethodCall extends ASTNode {
  final ASTNode select;
  final List<dynamic> arguments;
  
  MethodCall(this.select, this.arguments, [int startPos, int endPos]) : super(startPos, endPos);
  MethodCall.fromJson(Map json, this.select, this.arguments) : super.fromJson(json);
  
  MethodCall.main(this.arguments) : super(0,0), this.select = new MemberSelect("main", new Identifier("Mains"));
  
  String toString() => "$select()"; 
}

class MethodDecl extends ASTNode {
  final String name;
  final MethodType type;
  final List<Variable> parameters;
  final List body;
  
  MethodDecl(this.name, TypeNode returnType, List<Variable> parameters, this.body, [int startPos, int endPos]) : this.type = new MethodType(returnType, parameters.mappedBy((v) => v.type).toList()), 
                                                                                                            this.parameters = parameters, super(startPos, endPos);
  MethodDecl.fromJson(Map json, returnType, parameters, this.body) : this.name = json['name'], this.type = new MethodType(returnType, parameters.mappedBy((v) => v.type).toList()), this.parameters = parameters, super.fromJson(json); 
  
  String toString() {
    StringBuffer string = new StringBuffer("<div class=\"line\">${type.returnType} $name(");
    string.add(
        parameters.reduce("", (r,m){
          if(!r.isEmpty)
            r = "$r, ";
          return "$r$m";
        })
    );
    string.add("){</div>");
    string.add(body.reduce("", (r,m) => "$r<div class=\"line\">$m;</div>"));
    string.add("<div class=\"line\">}</div>");
    return string.toString();
  }
  
  bool operator==(other){
    if(identical(other, this))
      return true;
    
    return name == other.name && type == other.type; 
  }
  
}

class MethodType {
  final TypeNode returnType;
  final List<TypeNode> parameters;
  
  const MethodType(this.returnType, this.parameters);
  
  static final MethodType main = new MethodType(TypeNode.VOID, [TypeNode.STRING]);
  
  String toString() => "$parameters -> $returnType";
  
  bool operator==(other){
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

class Return extends ASTNode {
  final dynamic expr;
  
  Return.fromJson(Map json, this.expr) : super.fromJson(json);
  
  String toString() => "return $expr"; 
}

class TypeNode extends ASTNode {
  final type;

  TypeNode(this.type) {
    if(!(type is String || type is TypeNode || type is Identifier)){
      throw "Invalid type: ${type.runtimeType}";
    }
  }
  
  bool get isPrimitive => type is String;
  bool get isArray => type is TypeNode;
  bool get isDeclared => type is Identifier;
  
  static final TypeNode VOID = new TypeNode("VOID");
  static final TypeNode STRING = new TypeNode(new Identifier("String"));
  
  String toString(){
    if(isArray)
      return "[]";
    
    if(isPrimitive)
      return "${type.toLowerCase()}";
      
    return "$type";
  }
  
  bool operator==(other){
    if(identical(other, this))
      return true;
    
    TypeNode t = other;    
    return type == t.type;
  }
  
  bool sameType(other){
    if(other is TypeNode)
      return this == other;
    else if(other is ClassScope){
      return this.isDeclared && type == other.clazz.name; //isDeclared is superfluous
    }
    else if(other is Literal || other is PrimitiveValue){
      return this.isPrimitive && type.toLowerCase() == other.type;  //isPrimitive is superfluous
    }
    else throw "Don't know how to compare type with $other : ${other.runtimeType}";    
  }
  
  static const Map<String, PrimitiveValue> DEFAULT_VALUES = 
      const {'int': IntegerValue.defaultValue, 'long': LongValue.defaultValue, 
              'float': FloatValue.defaultValue, 'double': DoubleValue.defaultValue};
}

class Variable extends ASTNode {
  final String name;
  final TypeNode type;
  final initializer;
  
  Variable(this.name, this.type, this.initializer, [int startPos, int endPos, List<String> modifiers]) : super(startPos, endPos, modifiers);
  Variable.fromJson(Map json, this.type, this.initializer) : name = json['name'], super.fromJson(json);
  
  int get hashCode => 17 * 37 + name.hashCode; 
  
  bool operator==(other){
    if(identical(other, this))
      return true;
    
    return name == other.name;
  }
  
  String toString() => "$type ${name}${initializer != null ? " = $initializer" : ""}";
}
