part of JavaEvaluator;

class ASTNode {
  final int startPos;
  final int endPos;
  
  const ASTNode(this.startPos, this.endPos);
  const ASTNode.fromJson(Map json) : this(json['startPos'], json['endPos']);
}

class ClassDecl {
  String name;
  List members = [];
  
  ClassDecl(this.name);
  
  addMembers(Collection members) {
    this.members.addAll(members);
  }
  
  String toString() => "class $name $members";
}

class Type {
  static const PRIM = "primitive";
  static const DECL = "declared";
  
  final String id;
  final String type;
  
  const Type.primitive(this.id) : this.type = PRIM;
  const Type.declared(this.id) : this.type = DECL;
  
  static const Type VOID = const Type.primitive("VOID");
  static const Type STRING = const Type.declared("String");
  
  String toString() => "$id";
  
  bool operator==(other){
    if(identical(other, this))
      return true;

    return id == other.id && type == other.type;
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

class MethodDecl {
  final String name;
  final MethodType type;
  final List<Variable> parameters;
  final List body;
  
  MethodDecl(this.name, Type returnType, List<Variable> parameters, this.body) : this.type = new MethodType(returnType, parameters.map((v) => v.type)), this.parameters = parameters;
  
  String toString() => "{$name : $type}";
  
  bool operator==(other){
    if(identical(other, this))
      return true;
    
    return name == other.name && type == other.type; 
  }
}

class Variable extends ASTNode {
  final String name;
  final Type type;
  final initializer;
  
  const Variable(this.name, this.type, this.initializer, int startPos, int endPos) : super(startPos, endPos);
  Variable.fromJson(Map json, this.type, this.initializer) : name = json['name'], super.fromJson(json);
  
  int get hashCode => 17 * 37 + name.hashCode; 
  
  bool operator==(other){
    if(identical(other, this))
      return true;
    
    return name == other.name;
  }
  
  String toString() => "$name : $type";
}

class Assignment {
  final Identifier id;
  final expr;
  
  const Assignment(this.id, this.expr);
}

class If extends ASTNode {
  final condition;
  final then;
  
  const If.fromJson(Map json, this.condition, this.then) : super.fromJson(json);
}

class BinaryOp extends ASTNode {
  static const String _EQUAL = "EQUAL_TO";
  
  final String type;
  final left;
  final right;
  
  const BinaryOp(this.type, [this.left, this.right, startPos, endPos]) : super(startPos, endPos);
  const BinaryOp.fromJson(Map json, this.left, this.right) : this.type = json['type'], super.fromJson(json);
  
  static final BinaryOp Equal = const BinaryOp(_EQUAL);
  
  bool operator==(other){
    if(identical(other, this))
      return true;
    
    return type == other.type;
  }
}

class Identifier extends ASTNode {
  final String name;
  
  const Identifier(this.name, [int startPos, int endPos]) : super(startPos, endPos);
  const Identifier.fromJson(Map json) : name = json['value'], super.fromJson(json);
  
  int get hashCode => 17 * 37 + name.hashCode; 
  
  bool operator==(other){
    if(identical(other, this))
      return true;
    
    return name == other.name;
  }
  
  String toString() => name;
}
