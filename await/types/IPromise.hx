package await.types;

import await.types.Listener;
import await.types.State;

@:nullSafety(StrictThreaded)
interface IPromise<T> {
  public var state: State<T>;
  var listeners: Array<Listener<T>>;

  final body: ResolverFunc<T>;

  function resolve(value: T): Void;
  function reject(value: Any): Void;

  public function except(callback: RejectFunc): IPromise<T>;
  public function then(callback: ResolveFunc<T>): IPromise<T>;

  public function wait(): IPromise<T>;
  public function await(): T;

  public function toString(): String;
}