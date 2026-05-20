package tests;

import utest.Runner;
import utest.ui.Report;

class Main {
  public function promise() {
    
  }

  public function main() {
    var runner = new Runner();

    runner.addCase(new TestCase1());
    runner.addCase(new TestCase2());

    Report.create(runner);

    runner.run();
  } 

  static public function main() 
    new Main()
      .main();
}