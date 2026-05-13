package;

import sys.thread.Thread;
import promises.Promise;

class Await {
  static public function main() {
    var p = new Promise((resolve, reject) -> {
      Sys.sleep(6);

      trace("hi");
    
      reject("hi");
      reject("hi");
      reject("hi");
    });

    // var p2 = Promise.async(() -> {
    //   return "beh";
    // });

    // todo
    // @async function declr
    // @await p; and this

    p
      .wait()
      .except((e) -> trace("err", e))
      .then((data) -> trace("AAA", data));
    
    // Sys.sleep(3);
    // trace("hi");
  }  
}