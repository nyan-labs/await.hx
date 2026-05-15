package;

import haxe.EntryPoint;
import haxe.MainLoop;
import sys.thread.Thread;
// todo: dont alllow chaining on promises that have @await
//       add target-specific implementations of promise (as of right now it only works on sys targets)
//       fix haxelib.json lol
class Await {
  @async static function test1(a: Int = 0) {
    Sys.sleep(1);
    return 1;
  }
  @async static function test2(): Int {
    // trace(@await test1(@await test1(2))); // TODO, this doesnt work

    Sys.sleep(6);
    throw "erm";
    return 2;
  }

  static public function main() {
    // var p = new Promise((resolve, reject) -> {
      // Sys.sleep(6);

      // trace("hi");
    
      // reject("ermff");
    //   reject("hi");
    //   reject("hi");
    // });

    // p
      // .except((e) -> trace("err", e));
    //   .then((data) -> trace("AAA", data));
    
    trace(test1().wait().state);
    trace(test2().wait().state);


    // trace("hi");
    // trace("hi2");
    // Sys.sleep(3);
    // trace("hi");
  }  
}