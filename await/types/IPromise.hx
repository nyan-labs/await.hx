package await.types;

import await.types.Listener;
import await.types.State;

// extern interfaces support `static` fields, 
// that's the reasoning, but hashlink doesn't support externs
// so we remove the interface before generation
@:remove
@:nullSafety(StrictThreaded)
extern interface IPromise<T> {
  public var state: State<T>;
  var listeners: Array<Listener<T>>;

  final body: ResolverFunc<T>;

  // blame js
  static function transform<T>(body: ResolverFunc<T>): ResolveFunc<T>;

  function resolve(value: T): Void;
  function reject(value: Any): Void;

  public function except(callback: RejectFunc): IPromise<T>;
  public function then(callback: ResolveFunc<T>): IPromise<T>;

  // @async context only
  private function wait(): Void;
  private function await(): T;

  public function toString(): String;
}