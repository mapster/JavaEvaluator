part of JavaEvaluator;

abstract class PrimitiveValue {
  final num value;
  PrimitiveValue(this.value);
}

typedef NumberValue BinaryOperation(NumberValue first, NumberValue second);

abstract class NumberValue extends PrimitiveValue {
  NumberValue(num value) : super(value);
  
  static NumberValue _executeOperation(NumberValue first, NumberValue second, BinaryOperation op){
    if(first.promotionCompare(second) < 0)
      first = second.promote(first);
    else if(second.promotionCompare(first) < 0)
      second = first.promote(second);
    
    assert(first.runtimeType == second.runtimeType);
    if(first.runtimeType != second.runtimeType)
      throw "Unsuccessful type promotion, cannot perform binary operation!";
    
    return op(first, second);
  }
  
  NumberValue operator+(NumberValue other) => _executeOperation(this, other, (NumberValue a, NumberValue b) => a.create(a.value + b.value));
  NumberValue operator-(NumberValue other) => _executeOperation(this, other, (NumberValue a, NumberValue b) => a.create(a.value - b.value));
  NumberValue operator*(NumberValue other) => _executeOperation(this, other, (NumberValue a, NumberValue b) => a.create(a.value * b.value));
  NumberValue operator/(NumberValue other) => _executeOperation(this, other, (NumberValue a, NumberValue b) => a.create(a.value / b.value));

  int promotionCompare(NumberValue other);
  NumberValue promote(NumberValue other);
  NumberValue create(num value);
  
  String toString() => "$value";
}


class LongValue extends NumberValue {
  static const int MIN = -9223372036854775808;
  static const int MAX =  9223372036854775807;
  
  factory LongValue(int value) {
    if(value < MIN)
      return new LongValue._(MAX - (MIN - value) +1);
    else if(value > MAX)
      return new LongValue._(MIN + (value - MAX) -1);
    return new LongValue._(value);
  }
  
  LongValue._(int value) : super(value);
  LongValue create(num value) => new LongValue(value.toInt());
  
  int promotionCompare(NumberValue other){
    if(other is LongValue) //same type
      return 0;
    
    if(other is DoubleValue || other is FloatValue) //lesser type (promote this)
      return -1;
    
    else return 1; //larger type (promote other)  
  }
  
  NumberValue promote(NumberValue other){
    if(promotionCompare(other) < 1)
      throw "Promoting lesser type (${other.runtimeType}) to DoubleValue"; 
    
    return new LongValue(other.value.toInt());
  }
}

class IntegerValue extends NumberValue {
  static const int MIN = -2147483648;
  static const int MAX = 2147483647;
  
  factory IntegerValue(int value) {
    if(value < MIN)
      return new IntegerValue._(MAX - (MIN - value) +1);
    else if(value > MAX)
      return new IntegerValue._(MIN + (value - MAX) -1);
    return new IntegerValue._(value);
  }
  
  IntegerValue._(int value) : super(value);
  IntegerValue create(num value) => new IntegerValue(value.toInt());
  
  int promotionCompare(NumberValue other){
    if(other is IntegerValue) //same type
      return 0;
    
    if(other is DoubleValue || other is FloatValue || other is LongValue) //lesser type (promote this)
      return -1;
    
    else return 1; //larger type (promote other)
  }
  
  NumberValue promote(NumberValue other){
    if(promotionCompare(other) < 1)
      throw "Promoting lesser type (${other.runtimeType}) to IntegerValue"; 
    return new IntegerValue(other.value.toInt());
  }
}

class DoubleValue extends NumberValue {
  DoubleValue(double value) : super(value);
  DoubleValue create(num value) => new DoubleValue(value.toDouble()); 
  
  
  int promotionCompare(NumberValue other){
    if(other is! DoubleValue)
      return 1;
    else return 0;
  }
  
  NumberValue promote(NumberValue other){
    if(promotionCompare(other) < 1)
      throw "Promoting lesser type (${other.runtimeType}) to DoubleValue"; 

    return new DoubleValue(other.value.toDouble());
  }
  
}

class FloatValue extends NumberValue {
  FloatValue(double value) : super(value);
  FloatValue create(num value) => new FloatValue(value.toDouble());
  
  int promotionCompare(NumberValue other){
    if(other is NumberValue) //same type
      return 0;
    
    if(other is DoubleValue) //lesser type (promote this)
      return -1;
    
    else return 1; //larger type (promote other)
  }
  
  NumberValue promote(NumberValue other){
    if(promotionCompare(other) < 1)
      throw "Promoting lesser type (${other.runtimeType}) to FloatValue"; 
    return new FloatValue(other.value.toDouble());
  }
}