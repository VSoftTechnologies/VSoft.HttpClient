unit VSoftHttpClientTests;

interface

uses
  DUnitX.TestFramework,
  VSoft.HttpClient;

type
  [TestFixture]
  TMyTestObject = class
  public
//    [Test]
    procedure TestGet;

//    [Test]
    procedure TestUploadFiles;

//    [Test]
    procedure TestPostForm;

//    [Test]
    procedure TestParameters;

//    [Test]
    procedure TestWithUri;

    [Test]
    procedure TestResponseStream;
  end;

implementation
uses
  WinApi.ActiveX,
  System.SysUtils,
  System.Classes,
  VSoft.CancellationToken,
  VSoft.Uri,
  JsonDataObjects;

procedure TMyTestObject.TestGet;
var
  client : IHttpClient;
  response : IHttpResponse;
  i : integer;
  cancelTokenSource : ICancellationTokenSource;
begin
  cancelTokenSource := TCancellationTokenSourceFactory.Create;

  client := THttpClientFactory.CreateClient('https://localhost:5001');
  response := client.CreateRequest('api/v1/index.json')
    .WithParameter('name', 'the value')
  .Get(cancelTokenSource.Token);



  if response.StatusCode <> 200 then
    WriteLn(response.ErrorMessage);

  Assert.AreEqual<integer>(200, response.StatusCode);
  Assert.AreNotEqual<integer>(0, response.ContentLength);

  for i := 0 to response.Headers.Count -1 do
    Writeln(response.Headers.Strings[i]);


end;


procedure TMyTestObject.TestParameters;
var
  client : IHttpClient;
  response : IHttpResponse;
  request : TRequest;
  cancelTokenSource : ICancellationTokenSource;
begin
  exit;
  cancelTokenSource := TCancellationTokenSourceFactory.Create;

  client := THttpClientFactory.CreateClient('https://localhost:5001');

  request := client.CreateRequest('/api/v1/package/spring4d.core/10.4/Win32/versionswithdependencies');

  request.WithAccept('application/json')
         .WithParameter('versionRange', '[0.0.2,2.0.0]')// versionRange.ToString)
         .WithParameter('prerel', 'true');
  response := request.Get(cancelTokenSource.Token);

  if response.StatusCode <> 200 then
    WriteLn(response.ErrorMessage);

  Assert.AreEqual<integer>(200, response.StatusCode);
  Assert.AreNotEqual<integer>(0, response.ContentLength);

//  jsonObj := TJsonObject.Parse(response.Response);


end;

procedure TMyTestObject.TestPostForm;
var
  client : IHttpClient;
  response : IHttpResponse;
  request : TRequest;
  cancelTokenSource : ICancellationTokenSource;
begin
  cancelTokenSource := TCancellationTokenSourceFactory.Create;

  client := THttpClientFactory.CreateClient('https://localhost:5001');


  request := client.CreateRequest('/api/v1/package');

  request.WithHeader('X-ApiKey', 'foobar')
         .WithFile('i:\dpmfeed\ADUG.BasicLib-10.1-Win32-1.0.24.dpkg');
  response := request.Put(cancelTokenSource.Token);

  if response.StatusCode <> 200 then
    WriteLn(response.ErrorMessage);

  Assert.AreEqual<integer>(200, response.StatusCode);

  Assert.Pass;
end;

procedure TMyTestObject.TestResponseStream;
var
  client : IHttpClient;
  response : IHttpResponse;
  cancelTokenSource : ICancellationTokenSource;
  stream : TMemoryStream;
begin
  cancelTokenSource := TCancellationTokenSourceFactory.Create;

  client := THttpClientFactory.CreateClient('https://localhost:5002');
  response := client.CreateRequest('/api/v1/package/VSoft.DUnitX/11.0/Win32/0.3.3/icon')
  .Get(cancelTokenSource.Token);


  if response.StatusCode <> 200 then
    WriteLn(response.ErrorMessage);

  Assert.AreEqual<integer>(200, response.StatusCode);
  Assert.AreNotEqual<integer>(0, response.ContentLength);

  stream := TMemoryStream.Create;
  try
    stream.CopyFrom(response.ResponseStream,response.ResponseStream.Size);
    Assert.AreEqual(response.ContentLength, stream.Size);

  finally
    stream.Free;
  end;


end;

procedure TMyTestObject.TestUploadFiles;
//var
//  client : IHttpClient;
//  response : IHttpResponse;
//  i : integer;
begin
//  client := THttpClientFactory.CreateClient('http://localhost:55542');
//  request := THttpClientFactory.CreateRequest('weatherforecast/upload');
//  request.AddParameter('one', 'value1');
//  request.AddFile('c:\temp\style.png');
//  request.AddFile('c:\temp\request.txt');
//
//  response := client.Post(request);
//
//  for i := 0 to response.Headers.Count -1 do
//    Writeln(response.Headers.Strings[i]);
//
//
//  Assert.AreEqual<integer>(200, response.ResponseCode);
//  Assert.AreEqual<integer>(0, response.ContentLength);
//
  Assert.Pass;
end;

procedure TMyTestObject.TestWithUri;
var
  uri : IUri;
  client : IHttpClient;
  response : IHttpResponse;
  request : TRequest;
  cancelTokenSource : ICancellationTokenSource;
begin
  cancelTokenSource := TCancellationTokenSourceFactory.Create;
  uri := TUriFactory.Parse('https://delphi.dev');
  client := THttpClientFactory.CreateClient(uri);
  request := client.CreateRequest('/api/v1/searchbyids')
    .WithBody('{"compiler": "XE7","platform": "Win32","packageids": [{"id": "Spring4D.Data","version": "2.0.0-rc.2"},{"id": "Spring4D.Base","version": "2.0.0-rc.2"}]}', TEncoding.UTF8)
    .WithContentType('application/json', 'utf-8');

  response := request.Post(cancelTokenSource.Token);
  Assert.AreEqual<integer>(200, response.StatusCode);
end;

initialization
  TDUnitX.RegisterTestFixture(TMyTestObject);
  CoInitializeEx(nil, COINIT_APARTMENTTHREADED); //needed for winhttp.
end.
