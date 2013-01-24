part of JavaEvaluator;

class ASTNode {
  static int _counter = 0;
  
  final int startPos;
  final int endPos;
  final List<String> modifiers;
  final int nodeId = _counter++;
  
  const ASTNode([this.startPos, this.endPos, this.modifiers]);
    
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

class Type extends ASTNode {
  final String id;
  final bool isPrimitive;
  
  Type.fromJson(Map json) : this.id = json['value'], this.isPrimitive = (json['NODE_TYPE'] == "primitive"), super.fromJson(json);
  const Type.primitive(this.id) : this.isPrimitive = true, super();
  const Type.declared(this.id) : this.isPrimitive = false, super();
  
  static const Type VOID = const Type.primitive("VOID");
  static const Type STRING = const Type.declared("String");
  
  String toString(){
    String r = "$id";
    if(isPrimitive)
      r = r.toLowerCase();
    return r;
  }
  
  bool operator==(other){
    if(identical(other, this))
      return true;

    return id == other.id && isPrimitive == other.isPrimitive;
  }
}

class MethodType {
  final Type returnType;
  final List<Type> parameters;
  
  const MethodType(this.returnType, this.parameters);
  
  static const MethodType main = const MethodType(Type.VOID, const [Type.STRING]);
  
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

class MethodDecl extends ASTNode {
  final String name;
  final MethodType type;
  final List<Variable> parameters;
  final List body;
  
  MethodDecl(this.name, Type returnType, List<Variable> parameters, this.body, [int startPos, int endPos]) : this.type = new MethodType(returnType, parameters.mappedBy((v) => v.type).toList()), 
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

class MethodCall extends ASTNode {
  final ASTNode select;
  final List<dynamic> arguments;
  
  const MethodCall(this.select, this.arguments, [int startPos, int endPos]) : super(startPos, endPos);
  MethodCall.fromJson(Map json, this.select, this.arguments) : super.fromJson(json);
  
  MethodCall.main(this.arguments) : super(0,0), this.select = new MemberSelect("main", const Identifier("Mains"));
  
  String toString() => "$select()"; 
}

class Variable extends ASTNode {
  final String name;
  final Type type;
  final initializer;
  
  const Variable(this.name, this.type, this.initializer, [int startPos, int endPos, List<String> modifiers]) : super(startPos, endPos, modifiers);
  Variable.fromJson(Map json, this.type, this.initializer) : name = json['name'], super.fromJson(json);
  
  int get hashCode => 17 * 37 + name.hashCode; 
  
  bool operator==(other){
    if(identical(other, this))
      return true;
    
    return name == other.name;
  }
  
  String toString() => "$type ${name}${initializer != null ? " = $initializer" : ""}";
}

class Assignment extends ASTNode {
  final Identifier id;
  final expr;

  const Assignment(this.id, this.expr, [int startPos, int endPos]) : super(startPos, endPos);
  Assignment.fromJson(Map json, this.id, this.expr) : super.fromJson(json);
  
  String toString() => "$id = $expr";
}

class If extends ASTNode {
  final ASTNode condition;
  final List<ASTNode> then;
  final List<ASTNode> elze;
  
  If.fromJson(Map json, this.condition, this.then, [this.elze]) : super.fromJson(json);
}

class BinaryOp extends ASTNode {
  static const String EQUAL = "EQUAL_TO";
  
  final String type;
  final left;
  final right;
  
  const BinaryOp(this.type, this.left, this.right, [int startPos, int endPos]) : super(startPos, endPos);
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
      default:
        throw "Operator toString not supported for: $op";
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

class Identifier extends ASTNode {
  final String name;
  
  const Identifier(this.name, [int startPos, int endPos]) : super(startPos, endPos);
  Identifier.fromJson(Map json) : name = json['value'], super.fromJson(json);
  
  int get hashCode => 17 * 37 + name.hashCode; 
  
  bool operator==(other){
    if(identical(other, this))
      return true;
    
    return name == other.name;
  }
  
  String toString() => name;
}

class Return extends ASTNode {
  final dynamic expr;
  
  Return.fromJson(Map json, this.expr) : super.fromJson(json);
  
  String toString() => "return $expr"; 
}
