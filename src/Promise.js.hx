package;

import types.Listener;
import types.State;
import types.IPromise;

//TODO
class Promise<T> implements IPromise<T> {
	public var state = Pending;
	public var listeners = new Array();
	public final body: ResolverFunc<T>;
  
  public function new(resolver: ResolverFunc<T>) {
    body = resolver;
  }

  public function wait() {
    return this;
  }

  public function then(callback:ResolveFunc<T>) {   
    return this;
  }

  public function except(callback:RejectFunc):IPromise<T> {
    return this;
  }

  public function reject(reason:Any) {}

  public function resolve(value:T) {}

  
}