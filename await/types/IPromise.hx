package types;

import types.Listener;
import types.State;

@:nullSafety(StrictThreaded)
interface IPromise<T> {
  public var state: State<T>;
  var listeners: Array<Listener<T>>;

  final body: ResolverFunc<T>;

  function resolve(value: T): Void;
  function reject(value: Any): Void;

  public function except(callback: RejectFunc): IPromise<T>;
  public function then(callback: ResolveFunc<T>): IPromise<T>;

  // @async context only
  private function wait(): IPromise<T>;
  private function await(): T;

  public function toString(): String;
}