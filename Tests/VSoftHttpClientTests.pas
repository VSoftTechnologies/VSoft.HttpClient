unit VSoftHttpClientTests;

interface

uses
  DUnitX.TestFramework,
  VSoft.HttpClient;

type
  [TestFixture]
  TMyTestObject = class
  public
    [Test]
    procedure TestGet;

    [Test]
    procedure TestUploadFiles;

    [Test]
    procedure TestPostForm;
  end;

implementation
uses
  WinApi.ActiveX;

procedure TMyTestObject.TestGet;
var
  client : IHttpClient;
  request : IHttpRequest;
  response : IHttpResponse;
  i : integer;
begin
  client := THttpClientFactory.CreateClient('https://localhost:5001/api/v1/index.json');
  request := THttpClientFactory.CreateRequest('');
  request.AddParameter('name', 'the value');

  response := client.Get(request);

  if response.ResponseCode <> 200 then
    WriteLn(response.ErrorMessage);


  Assert.AreEqual<integer>(200, response.ResponseCode);
  Assert.AreNotEqual<integer>(0, response.ContentLength);

  for i := 0 to response.Headers.Count -1 do
    Writeln(response.Headers.Strings[i]);


end;


procedure TMyTestObject.TestPostForm;
var
  client : IHttpClient;
  request : IHttpRequest;
  response : IHttpResponse;
  i : integer;
begin
  client := THttpClientFactory.CreateClient('http://localhost:55542');
  request := THttpClientFactory.CreateRequest('weatherforecast/formtest');
  request.AddParameter('one', 'value1');
  request.AddParameter('two', 'value2');
  request.AddParameter('three', 'the value 3');
  request.ForceFormData := true;

  response := client.Post(request);

  for i := 0 to response.Headers.Count -1 do
    Writeln(response.Headers.Strings[i]);


  Assert.AreEqual<integer>(200, response.ResponseCode);
  Assert.AreEqual<integer>(0, response.ContentLength);


end;

procedure TMyTestObject.TestUploadFiles;
var
  client : IHttpClient;
  request : IHttpRequest;
  response : IHttpResponse;
  i : integer;
begin
  client := THttpClientFactory.CreateClient('http://localhost:55542');
  request := THttpClientFactory.CreateRequest('weatherforecast/upload');
  request.AddParameter('one', 'value1');
  request.AddFile('c:\temp\style.png');
  request.AddFile('c:\temp\request.txt');

  response := client.Post(request);

  for i := 0 to response.Headers.Count -1 do
    Writeln(response.Headers.Strings[i]);


  Assert.AreEqual<integer>(200, response.ResponseCode);
  Assert.AreEqual<integer>(0, response.ContentLength);


end;

initialization
  TDUnitX.RegisterTestFixture(TMyTestObject);
  CoInitialize(nil); //needed for winhttp.
end.
