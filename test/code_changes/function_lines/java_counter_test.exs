defmodule CodeChanges.FunctionLines.JavaCounterTest do
  use ExUnit.Case, async: true

  alias CodeChanges.FunctionLines.JavaCounter

  describe "count_lines/3" do
    test "returns empty list when no functions are in range" do
      code = """
      public class Example {
        private String name;

        public void setName(String name) {
          this.name = name;
        }
      }
      """

      assert JavaCounter.count_lines(code, 1, 2) == []
    end

    test "counts lines of a simple function" do
      code = """
      public class Example {
        public void setName(String name) {
          this.name = name;
          System.out.println(name);
          notifyListeners();
        }
      }
      """

      assert JavaCounter.count_lines(code, 1, 6) == [3]
    end

    test "counts lines of multiple functions" do
      code = """
      public class Example {
        public void setName(String name) {
          this.name = name;
          System.out.println(name);
        }

        public String getName() {
          return this.name;
        }

        private void notifyListeners() {
          if (listeners != null) {
            listeners.forEach(l -> l.notify());
          }
        }
      }
      """

      assert JavaCounter.count_lines(code, 1, 15) == [2, 1, 2]
    end

    test "counts lines when function is partially in range" do
      code = """
      public class Example {
        public void setName(String name) {
          this.name = name;
          System.out.println(name);
          notifyListeners();
        }

        public String getName() {
          return this.name;
        }
      }
      """

      # Even if we only catch part of the first function, we count all its lines
      assert JavaCounter.count_lines(code, 3, 5) == [3]
    end

    test "ignores comments and blank lines" do
      code = """
      public class Example {
        /**
         * Sets the name and notifies listeners
         */
        public void setName(String name) {
          // Update the name
          this.name = name;

          // Notify all listeners
          notifyListeners();
        }
      }
      """

      assert JavaCounter.count_lines(code, 1, 11) == [2]
    end

    test "handles functions with different brace styles" do
      code = """
      public class Example {
        public void method1() {
          doSomething();
        }

        public void method2()
        {
          doSomething();
          doMore();
        }

        public void method3() { doSomething(); }
      }
      """

      assert JavaCounter.count_lines(code, 1, 13) == [1, 2, 0]
    end

    test "counts lines of functions in inner classes" do
      code = """
      public class Example {
        private class Inner {
          public void innerMethod() {
            doSomething();
            doMore();
          }
        }

        public void outerMethod() {
          prepare();
          execute();
        }
      }
      """

      assert JavaCounter.count_lines(code, 1, 12) == [2, 2]
    end

    test "handles lambda and anonymous functions" do
      code = """
      public class Example {
        public void process() {
          executor.execute(() -> {
            doStep1();
            doStep2();
          });

          callback.onComplete(new Runnable() {
            @Override
            public void run() {
              cleanup();
              notify();
            }
          });
        }
      }
      """

      # The main function englobes the lamdda and anonymous functions
      assert JavaCounter.count_lines(code, 1, 15) == [9]
    end
  end
end
