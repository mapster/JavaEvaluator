
class ClassDecl {
  String name;
  List members = [];
  
  ClassDecl(this.name);
  
  addMembers(Collection members) {
    this.members.addAll(members);
  }
  
  String toString(){
    return "class $name $members";
  }
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
  
  String toString(){
    return "$id";
  }
  
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
  
  static final MethodType main = const MethodType(Type.VOID, const [Type.STRING]);
  
  String toString(){
    return "$parameters -> $returnType";
  }
  
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
  String name;
  MethodType type;
  List<Variable> parameters;
  Map<String, dynamic> body;
  
  MethodDecl(this.name, Type returnType, List<Variable> parameters, this.body) : this.type = new MethodType(returnType, parameters.map((v){return v.type;})), this.parameters = parameters;
  
  String toString(){
    return "{$name : $type}";
  }
}

class Variable {
  String name;
  final Type type;
  
  Variable(this.name, this.type);
  
  String toString(){
    return "$name : $type";
  }
}

