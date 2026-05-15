package types;

import haxe.Exception;

enum State<T> {
  Fulfilled(value: T);
  Rejected(value: Any);
  Pending;
}