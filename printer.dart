part of JavaEvaluator;

class Printer {
  
  static DivElement _createLineDiv([String text]){
    DivElement div = new DivElement();
    div.attributes['class'] = "line";
    if(?text)
      div.text = text;
    return div;
  }
  
  static DivElement _createIndentDiv(){
    DivElement div = new DivElement();
    div.attributes['class'] = "indent";
    return div;
  }

  static SpanElement _createSpan(String clazz){
    SpanElement sp = new SpanElement();
    sp.attributes['class'] = clazz;
    return sp;
  }
  
  static SpanElement _keyword(String keyword){
    SpanElement span = _createSpan("keyword");
    span.text = keyword;
    return span;
  }
  
  static SpanElement _code(String code){
    SpanElement sp = _createSpan("code");
    sp.text = code;
    return sp;
  }
  
  static Element toHtml(ASTNode node){
    DivElement root = new DivElement();
    root.attributes['id'] = "javasource";
    _toHtml(node, root);
    return root;
  } 
  
  
  static _toHtml(ASTNode astNode, DivElement root){
    if(astNode is ClassDecl){
      ClassDecl node = astNode;
      
      DivElement div = _createLineDiv();
      div.children.add(_keyword("class"));
      div.children.add(_code(" ${node.name} {"));
      root.children.add(div);
      
      DivElement members = _createIndentDiv();
      node.members.map((e) => _toHtml(e, members));
      
      root.children.addAll([members, _createLineDiv("}")]);
    }
    else if(astNode is MethodDecl){
      MethodDecl node = astNode;
      
      DivElement div = _createLineDiv();
      if(node.type.returnType.isPrimitive())
        div.children.add(_keyword("${node.type.returnType}"));
      else
        div.children.add(_code("${node.type.returnType}"));
      div.children.add(_code(" ${node.name}(${node.parameters.reduce("", reduceList)}){"));
      root.children.add(div);
      
      DivElement body = _createIndentDiv();
      node.body.map((e) => _toHtml(e, body));
      
      root.children.addAll([body, _createLineDiv("}")]);
    }
//    else if(astNode is MethodCall){
//     MethodCall node = astNode;
//     node.select
//    }
    else if(astNode is If){
      If node = astNode;
      DivElement div = _createLineDiv();
      div.text = "if(${node.condition}){";
      root.children.add(div);
      
      //add then block
      DivElement then = _createIndentDiv();
      node.then.map((e) => _toHtml(e, then));
      root.children.addAll([then, _createLineDiv("}")]);
      
      //add else block
      if(node.elze != null){
        root.children.add(_createLineDiv("else {"));
        DivElement elze = _createIndentDiv();
        node.elze.map((e) => _toHtml(e, elze));
        root.children.addAll([elze, _createLineDiv("}")]);
      }
      
    }
    else {
      DivElement div = _createLineDiv();
      div.text = "$astNode;";
      root.children.add(div);
    }
  }
  
  static String reduceList(String reduct, e){
    if(reduct.isEmpty)
      return "$e";

    return "$reduct, $e";
  }
}
