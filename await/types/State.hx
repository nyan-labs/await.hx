package types;

enum State<T> {
  Fulfilled(value: T);
  Rejected(value: Any);
  Pending;
}