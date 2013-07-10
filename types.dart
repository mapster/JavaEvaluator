library PrimitiveTypes;

abstract class Value<T> {
  final T _value;
  const Value(this._value);
 
  bool operator==(other){
    if(identical(other, this))
      return true;
    return _value == other._value;
  }
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
  static const nullRef = const ReferenceValue(-2);
  String toString() {
    if(_value == -1)
      return "@undef";
    else if(_value == -2)
      return "null";
    else
      return "@$_value";
  }
  
  int get hashCode => 37 + _value;
}


typedef PrimitiveValue BinaryOperation(NumberValue first, NumberValue second);

abstract class NumberValue<T extends num> extends PrimitiveValue<T> {
  const NumberValue(T value) : super(value);
  
  static PrimitiveValue _executeOperation(NumberValue first, NumberValue second, BinaryOperation op){
    first = first.binaryPromotion(second);
    second = second.binaryPromotion(second);
    
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

  NumberValue binaryPromotion(NumberValue other);
  NumberValue create(num value);
}


class LongValue extends NumberValue<int> {
  static const int MIN = -9223372036854775808;
  static const int MAX =  9223372036854775807;

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
  
  LongValue binaryPromotion(NumberValue other){
    if(other is DoubleValue || other is FloatValue) //lesser type (promote this)
      return other.create(this.value);
    
    else return this; //do not promote this  
  }
}

class IntegerValue extends NumberValue<int> {
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
  
  NumberValue binaryPromotion(NumberValue other){
    if(other is DoubleValue || other is FloatValue || other is LongValue) //lesser type (promote this)
      return other.create(this.value);
    
    else return this; //do not promote
  }
}

class DoubleValue extends NumberValue<double> {
  const DoubleValue(double value) : super(value);
  DoubleValue create(num value) => new DoubleValue(value.toDouble());
  static const DoubleValue defaultValue =  const DoubleValue(0.0);
  
  String get type => "DOUBLE";
  
  NumberValue binaryPromotion(NumberValue other) => this;
}

class FloatValue extends NumberValue<double> {
  const FloatValue(double value) : super(value);
  FloatValue create(num value) => new FloatValue(value.toDouble());
  static const FloatValue defaultValue = const FloatValue(0.0);
  
  String get type => "FLOAT";
  
  NumberValue binaryPromotion(NumberValue other){
    if(other is DoubleValue) //lesser type (promote this)
      return other.create(this.value);
    
    else return this;
  }
}

class CharValue extends NumberValue<int> {
  static const int MIN = 0;
  static const int MAX = 65535;
  
  const CharValue._(int value) : super(value);
  CharValue create(num value) => new CharValue(value.toInt());
  static const CharValue defaultValue = const CharValue._(0); 

  String get type => "CHAR";
  
  NumberValue binaryPromotion(NumberValue other){
    return new IntegerValue(this.value);
  }
  
  factory CharValue(int value) {
    if(value < MIN)
      return new CharValue._(MAX - (MIN - value) +1);
    else if(value > MAX)
      return new CharValue._(MIN + (value - MAX) -1);
    return new CharValue._(value);
  }
}

class BooleanValue extends PrimitiveValue<bool> {
  const BooleanValue(bool value) : super(value);
  String get type => "boolean";
  
  static const BooleanValue defaultValue = const BooleanValue(false);
  
  BooleanValue and(BooleanValue other) => new BooleanValue(this._value && other.value);
  BooleanValue or(BooleanValue other) => new BooleanValue(this._value || other.value);
}