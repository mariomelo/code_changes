# CodeChanges

CodeChanges is a tool that analyzes how functions evolve in Java codebases by examining their size changes across commits.

## How It Works

### Function Size Analysis Heuristics

We use Git patches to identify and measure function changes. Here's how our analysis works:

1. **Function Detection**: We identify Java functions using regex patterns that match:
   - Regular methods
   - Constructors
   - Inner class methods
   - Lambda expressions and anonymous functions (counted as part of their containing method)

2. **Line Counting Rules**:
   - We exclude:
     - Function signatures
     - Opening/closing braces
     - Comments (single-line and multi-line)
     - Empty lines
     - Import statements
   - We include:
     - All executable statements
     - Lambda function bodies (as part of the containing function)
     - Anonymous class method bodies

### Example Analysis

Original file (`Example.java`):
```java
public class Example {
    public void processData(List<String> items) {
        // Prepare data
        Map<String, Integer> counts = new HashMap<>();
        
        items.forEach(item -> {
            counts.merge(item, 1, Integer::sum);
        });
        
        // Print results
        counts.forEach((k, v) -> 
            System.out.println(k + ": " + v)
        );
    }
    
    private void cleanupData() {
        System.gc();
    }
}
```

Git patch showing changes:
```diff
@@ -2,6 +2,7 @@ public class Example {
     public void processData(List<String> items) {
         // Prepare data
         Map<String, Integer> counts = new HashMap<>();
+        System.out.println("Processing " + items.size() + " items");
         
         items.forEach(item -> {
             counts.merge(item, 1, Integer::sum);
@@ -13,6 +14,7 @@ public class Example {
     
     private void cleanupData() {
         System.gc();
+        Runtime.getRuntime().runFinalization();
     }
 }
```

Our analyzer would report:
- `processData`: 5 lines (including lambda bodies, +1 line changed)
- `cleanupData`: 2 lines (+1 line changed)

## Getting Started

### Prerequisites
- Elixir 1.15 or later
- Phoenix Framework
- Git
- [GitHub Personal Access Token](docs/github_token.md)

### Setup and Running

1. Install dependencies:
   ```bash
   mix setup
   ```

2. Start the server:
   ```bash
   mix phx.server
   ```

3. Visit [`localhost:4000`](http://localhost:4000) in your browser

## Popular Java Projects to Analyze

Here are some interesting open-source Java projects you can analyze:

1. [Spring Framework](https://github.com/spring-projects/spring-framework) - Popular Java application framework
2. [Elasticsearch](https://github.com/elastic/elasticsearch) - Distributed search engine
3. [RxJava](https://github.com/ReactiveX/RxJava) - Reactive Extensions for the JVM
4. [Guava](https://github.com/google/guava) - Google Core Libraries for Java
5. [Mockito](https://github.com/mockito/mockito) - Mocking framework for unit tests
6. [Netty](https://github.com/netty/netty) - Asynchronous event-driven network application framework
7. [Jenkins](https://github.com/jenkinsci/jenkins) - Automation server
8. [Hibernate ORM](https://github.com/hibernate/hibernate-orm) - Object/Relational Mapping framework
9. [Apache Kafka](https://github.com/apache/kafka) - Distributed streaming platform
10. [JUnit](https://github.com/junit-team/junit5) - Testing framework

## Security

For information about setting up your GitHub token securely, see our [GitHub Token Guide](docs/github_token.md).

## Check my Blog :)

I like to write about agile software development and other topics that interest me. You can find my blog posts [here](https://changingcode.substack.com).
