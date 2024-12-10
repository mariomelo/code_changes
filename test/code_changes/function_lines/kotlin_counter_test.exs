defmodule CodeChanges.FunctionLines.KotlinCounterTest do
  use ExUnit.Case
  alias CodeChanges.FunctionLines.KotlinCounter

  describe "count_lines/3" do
    test "counts lines of a simple function" do
      code = """
      class Example {
        private var name: String = ""
        
        fun setName(name: String) {
          this.name = name
        }
      }
      """

      assert KotlinCounter.count_lines(code, 1, 6) == [1]
    end

    test "counts lines of multiple functions" do
      code = """
      class Example {
        private var name: String = ""
        
        fun setName(name: String) {
          this.name = name
          println(name)
        }

        fun getName(): String {
          return name
        }
        
        private fun notifyListeners() {
          listeners?.forEach { it.notify() }
        }
      }
      """

      assert KotlinCounter.count_lines(code, 1, 15) == [2, 1, 1]
    end

    test "counts lines when function is partially in range" do
      code = """
      class Example {
        fun setName(name: String) {
          this.name = name
          println(name)
          notifyListeners()
        }
      }
      """

      assert KotlinCounter.count_lines(code, 3, 5) == [3]
    end

    test "ignores comments and blank lines" do
      code = """
      class Example {
        // This is a function to set the name
        fun setName(name: String) {
          // Update the name
          this.name = name
          
          /* Notify all listeners
             about the change */
          notifyListeners()
        }
      }
      """

      assert KotlinCounter.count_lines(code, 1, 11) == [3]
    end

    test "handles different function styles" do
      code = """
      class Example {
        fun method1() {
          doSomething()
        }
        
        fun method2()
        {
          doSomething()
        }

        fun method3() = doSomething()
      }
      """

      assert KotlinCounter.count_lines(code, 1, 12) == [1, 1, 0]
    end

    test "handles extension functions and properties" do
      code = """
      class Example {
        private val listeners = mutableListOf<Listener>()
        
        val isValid: Boolean
          get() {
            return name.isNotEmpty()
          }
        
        fun String.validate() {
          require(isNotEmpty()) { "Name cannot be empty" }
          require(length <= 100) { "Name too long" }
        }
      }
      """

      assert KotlinCounter.count_lines(code, 1, 12) == [2]
    end

    test "handles higher-order functions and lambdas" do
      code = """
      class Example {
        fun processItems(callback: (String) -> Unit) {
          items.forEach { item ->
            prepareItem(item)
            callback(item)
          }
          
          runBlocking {
            launch {
              processAsync()
            }
          }
        }
      }
      """

      assert KotlinCounter.count_lines(code, 1, 13) == [4]
    end
  end
end
