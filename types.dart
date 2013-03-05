part of JavaEvaluator;

abstract class Value<T> {
  final T _value;
  const Value(this._value);
}

abstract class PrimitiveValue<T> extends Value<T> {  
  T get value => _value;
  String get type;
  
  const PrimitiveValue(value) : super(value);
  
  String toString() => "$value";
}

class ReferenceValue extends Value<int> {
  const ReferenceValue(addr) : super(addr);
  static const invalid = const ReferenceValue(-1);
  String toString() => "@$_value";
  
  int get hashCode => 37 + _value;
  bool operator==(other){
    if(identical(other, this))
      return true;
    return _value == other._value;
  }
}


typedef PrimitiveValue BinaryOperation(NumberValue first, NumberValue second);

abstract class NumberValue<T extends num> extends PrimitiveValue<T> {
  const NumberValue(T value) : super(value);
  
  static PrimitiveValue _executeOperation(NumberValue first, NumberValue second, BinaryOperation op){
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
  BooleanValue operator>(NumberValue other) => _executeOperation(this, other, (NumberValue a, NumberValue b) => new BooleanValue(a.value > b.value));

  int promotionCompare(NumberValue other);
  NumberValue promote(NumberValue other);
  NumberValue create(num value);
}


class LongValue extends NumberValue<int> {
  static const int MIN = -9223372036854775808;
  static const int MAX =  9223372036854775807;

  static const TypeNode _type = const TypeNode.fixed("LONG"); 
  String get type => "LONG";
  
  factory LongValue(int value) {
    if(value < MIN)
      return new LongValue._(MAX - (MIN - value) +1);
    else if(value > MAX)
      return new LongValue._(MIN + (value - MAX) -1);
    return new LongValue._(value);
  }
  
  const LongValue._(int value) : super(value);
  LongValue create(num value) => new LongValue(value.toInt());
  static const LongValue defaultValue = const LongValue._(0);
  
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
  
  String get type => "INT";
  
  factory IntegerValue(int value) {
    if(value < MIN)
      return new IntegerValue._(MAX - (MIN - value) +1);
    else if(value > MAX)
      return new IntegerValue._(MIN + (value - MAX) -1);
    return new IntegerValue._(value);
  }
  
  const IntegerValue._(int value) : super(value);
  IntegerValue create(num value) => new IntegerValue(value.toInt());
  static const IntegerValue defaultValue =  const IntegerValue._(0);
  
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
  const DoubleValue(double value) : super(value);
  DoubleValue create(num value) => new DoubleValue(value.toDouble());
  static const DoubleValue defaultValue =  const DoubleValue(0.0);
  
  String get type => "DOUBLE";
  
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
  const FloatValue(double value) : super(value);
  FloatValue create(num value) => new FloatValue(value.toDouble());
  static const FloatValue defaultValue = const FloatValue(0.0);
  
  String get type => "FLOAT";
  
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

class BooleanValue extends PrimitiveValue<bool> {
  const BooleanValue(bool value) : super(value);
  String get type => "boolean";
  
  static const BooleanValue defaultValue = const BooleanValue(false);
  
  BooleanValue and(BooleanValue other) => new BooleanValue(this._value && other.value);
  BooleanValue or(BooleanValue other) => new BooleanValue(this._value || other.value);
}