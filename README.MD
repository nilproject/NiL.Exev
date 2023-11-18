NiL.Exev<br>
==
Custom evaluator and serializer for System.Linq.Expression. 

<br>
What's the point?
<details>
<summary>it's up to 100 times faster then compile-and-run.</summary>

```c#
Expression<Func<string, string, string>> expression = (a, b) => a + b;
var repeats = 100_000;

var sw = Stopwatch.StartNew();
for (var i = 0; i < repeats; i++)
{
    var result = expression.Compile()("hello, ", "world");
    Debug.Assert(result is "hello, world");
}
Console.WriteLine(sw.Elapsed); // 00:00:03.8659292

var evaluator = new ExpressionEvaluator();

sw.Restart();
for (var i = 0; i < repeats; i++)
{
    var result = evaluator.Eval(
        expression.Body,
        new[]
        {
            new Parameter(expression.Parameters[0], "hello, "),
            new Parameter(expression.Parameters[1], "world")
        });
    Debug.Assert(result is "hello, world");
}
Console.WriteLine(sw.Elapsed); // 00:00:00.0391234
```

</details>

<details>
<summary>And only 10 times slower when both are prepared (but you can do not use it in this case, of course)</summary>

```c#
Expression<Func<string, string, string>> expression = (a, b) => a + b;
var repeats = 10_000_000;

var compile = expression.Compile();
var sw = Stopwatch.StartNew();
for (var i = 0; i < repeats; i++)
{
    var result = compile("hello, ", "world");
    Debug.Assert(result is "hello, world");
}
sw.Stop();
Console.WriteLine(sw.Elapsed); // 00:00:00.1274875

var evaluator = new ExpressionEvaluator();

var args = new[]
{
    new Parameter(expression.Parameters[0], ""),
    new Parameter(expression.Parameters[1], "")
};
sw.Restart();
for (var i = 0; i < repeats; i++)
{
    args[0].Value = "hello, ";
    args[1].Value = "world";
    var result = evaluator.Eval(expression.Body, args);
    Debug.Assert(result is "hello, world");
}
sw.Stop();
Console.WriteLine(sw.Elapsed); // 00:00:01.1773341
```

</details>
<br>
And what? When it can be helpful?
<details>
<summary>When you are making you own super-duper-mega RPC protocol</summary>

```C#
// Сharacters
var myDb = new Dictionary<string, string> { ["someKey"] = "someValue" }; // some class to access to data on a server
var serializer = new ExpressionSerializer();
var deserializer = new ExpressionDeserializer();
var evaluator = new ExpressionEvaluator();
var networkStream = new MemoryStream(); // just imagine that this is network stream

// Client
Expression<Func<Dictionary<string, string>, string>> expression = serverDictionary => serverDictionary["someKey"];
var serialized = serializer.Serialize(expression);
            
networkStream.Write(serialized);        // transfer to a server
networkStream.Seek(0, SeekOrigin.Begin);

// Server            
var receivedRequest = new byte[networkStream.Length];
networkStream.Read(receivedRequest, 0, receivedRequest.Length);

var deserialized = deserializer.Deserialize(receivedRequest);            

var result = (evaluator.Eval(deserialized) as Func<Dictionary<string, string>, string>)!(myDb);

var serializedResult = serializer.Serialize(Expression.Constant(result));

networkStream.SetLength(0);             // transfer to a client
networkStream.Write(serializedResult);
networkStream.Seek(0, SeekOrigin.Begin);

// Client
var receivedResponse = new byte[networkStream.Length];
networkStream.Read(receivedResponse, 0, receivedResponse.Length);
var response = deserializer.Deserialize(receivedResponse) as ConstantExpression;

Debug.Assert(response!.Value is "someValue");
```

</details>