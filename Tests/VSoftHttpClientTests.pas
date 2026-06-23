unit VSoftHttpClientTests;

interface

uses
  DUnitX.TestFramework,
  VSoft.HttpClient;

type
  //These tests hit live endpoints and are disabled by default - they are kept for
  //manual/integration testing. Enable the [Test] attributes when a server is available.
  [TestFixture]
  TNetworkTests = class
  public
//    [Test]
    procedure TestGet;
//    [Test]
    procedure TestUploadFiles;
//    [Test]
    procedure TestPostForm;
//    [Test]
    procedure TestWithUri;
//    [Test]
    procedure TestResponseStream;
  end;

  //offline tests for the public UrlEncode function.
  [TestFixture]
  TUrlEncodeTests = class
  public
    [Test]
    procedure UnreservedCharsArePassedThrough;
    [Test]
    procedure SpaceIsEncodedAsPlus;
    [Test]
    procedure ReservedCharsArePercentEncoded;
    [Test]
    procedure PlusSignIsPercentEncoded;
    [Test]
    procedure UnicodeIsUtf8PercentEncoded;
    [Test]
    procedure EmptyStringReturnsEmpty;
    [Test]
    procedure HexIsUpperCase;
    [Test]
    procedure MixedStringIsEncoded;
  end;

  //offline tests for the small helper functions in VSoft.HttpClient.
  [TestFixture]
  THelperFunctionTests = class
  public
    [Test]
    procedure HttpMethodToStringReturnsName;
    [Test]
    procedure ClientErrorToStringPrefixesMessage;
    [Test]
    procedure ClientErrorToStringFormatsUnknownCode;
  end;

  //offline tests for request building - parameters, query parameters, headers,
  //url segments, body generation and content types. None of these touch the network.
  [TestFixture]
  TRequestTests = class
  public
    [Test]
    procedure GetAppendsParametersToQueryString;
    [Test]
    procedure GetEncodesParameterNameAndValue;
    [Test]
    procedure DuplicateParameterNameOverwrites;
    [Test]
    procedure PostDoesNotPutParametersOnUrl;
    [Test]
    procedure QueryParameterAlwaysOnUrlForPut;
    [Test]
    procedure QueryParameterAndParameterCombineOnGet;
    [Test]
    procedure QueryParameterIsUrlEncoded;
    [Test]
    procedure ParameterEncodeFalseIsNotEncoded;
    [Test]
    procedure ParameterEncodeTrueStillEncodes;
    [Test]
    procedure QueryParameterEncodeFalseIsNotEncoded;
    [Test]
    procedure FormParameterEncodeFalseIsNotEncoded;
    [Test]
    procedure UriQueryStringRoutedToQueryParameters;
    [Test]
    procedure UriQueryStringSurvivesPut;
    [Test]
    procedure UrlSegmentsReplacedOnGet;
    [Test]
    procedure UrlSegmentsReplacedOnPut;
    [Test]
    procedure HeaderIsStored;
    [Test]
    procedure AcceptHelpersSetHeaders;
    [Test]
    procedure ContentTypeWithCharSet;
    [Test]
    procedure ContentTypeWithoutCharSet;
    [Test]
    procedure GetHasNoBody;
    [Test]
    procedure PostWithParametersIsFormUrlEncoded;
    [Test]
    procedure StringBodyIsReturnedAsContent;
    [Test]
    procedure StringBodyTakesPrecedenceOverParameters;
    [Test]
    procedure ContentLengthMatchesBody;
    [Test]
    procedure FluentMethodsReturnSameInstance;
    [Test]
    procedure FollowRedirectsToggles;
    [Test]
    procedure DefaultFollowRedirectsIsTrue;
    [Test]
    procedure StreamBodyIsReturnedAsContent;
    [Test]
    procedure WithBodyReplacesPreviousBody;
    [Test]
    procedure PatchWithParametersIsFormUrlEncoded;
    [Test]
    procedure DeleteWithParametersIsFormUrlEncoded;
    [Test]
    procedure MultipleUrlSegmentsReplaced;
    [Test]
    procedure UrlSegmentReplacementIsCaseInsensitive;
    [Test]
    procedure EmptyParameterValueIsAllowed;
    [Test]
    procedure EmptyQueryParameterValueIsAllowed;
    [Test]
    procedure EmptyUrlSegmentValueReplaces;
    [Test]
    procedure ResourceReflectsCreationPath;
    [Test]
    procedure WillSaveAsFileSetsSaveAsFile;
    [Test]
    procedure AllowHttpDowngradeDefaultsFalse;
    [Test]
    procedure AllowHttpDowngradeToggles;
    [Test]
    procedure TimeoutsInheritClientDefaults;
    [Test]
    procedure TimeoutsAreSettable;
    [Test]
    procedure DefaultHttpMethodIsGet;
  end;

  //offline tests for request building that involve files / multipart form data.
  [TestFixture]
  TRequestFileTests = class
  public
    [Test]
    procedure FileProducesMultipartContentType;
    [Test]
    procedure ParameterBecomesMultipartField;
    [Test]
    procedure QueryParameterIsNotInMultipartBody;
    [Test]
    procedure ForceFormDataWithoutFileIsMultipart;
    [Test]
    procedure DefaultFieldNameIsFileName;
    [Test]
    procedure MultipleFilesAreAllIncluded;
  end;

  //offline tests for the multipart form data generator.
  [TestFixture]
  TMultipartFormDataTests = class
  public
    [Test]
    procedure ContentTypeContainsBoundary;
    [Test]
    procedure BoundaryIsUniquePerInstance;
    [Test]
    procedure AddFieldWritesContentDisposition;
    [Test]
    procedure GenerateAppendsClosingBoundary;
    [Test]
    procedure GenerateRewindsStream;
    [Test]
    procedure AddStreamUsesExplicitContentType;
    [Test]
    procedure AddStreamFallsBackToOctetStream;
    [Test]
    procedure MultipleFieldsAreWritten;
    [Test]
    procedure BoundaryStartsWithDashes;
    [Test]
    procedure AddStreamWithoutFileNameOmitsFileName;
  end;

  //offline tests for response parsing.
  [TestFixture]
  TResponseTests = class
  public
    [Test]
    procedure SuccessStatusHasNoErrorMessage;
    [Test]
    procedure FailureStatusSetsErrorMessage;
    [Test]
    procedure IsSuccessBoundaries;
    [Test]
    procedure HeadersAreParsed;
    [Test]
    procedure ContentTypeReadFromHeaders;
    [Test]
    procedure StatusLineIsIgnored;
    [Test]
    procedure WrittenContentReadAsString;
    [Test]
    procedure ContentLengthMatchesWrittenBytes;
    [Test]
    procedure MaxResponseSizeIsEnforced;
    [Test]
    procedure MaxResponseSizeZeroIsUnlimited;
    [Test]
    procedure ContentDispositionParsedFromHeaders;
    [Test]
    procedure FileResponseIsNotStringResponse;
    [Test]
    procedure SaveToWritesFile;
    [Test]
    procedure ConstructorParsesHeaderString;
    [Test]
    procedure ConstructorUsesProvidedErrorMessage;
    [Test]
    procedure ServerErrorStatusMessage;
    [Test]
    procedure TeapotStatusMessage;
    [Test]
    procedure EmptyResponseIsEmptyString;
    [Test]
    procedure SetContentReplacesStream;
    [Test]
    procedure MultipleWritesAccumulate;
    [Test]
    procedure FileNameFromContentDisposition;
    [Test]
    procedure DefaultIsStringResponse;
  end;

  //offline tests for the content-disposition header parser.
  [TestFixture]
  TContentDispositionTests = class
  public
    [Test]
    procedure ParsesDispositionType;
    [Test]
    procedure ParsesFileName;
    [Test]
    procedure HandlesExtendedFileNameParameter;
    [Test]
    procedure ParsesInlineDisposition;
    [Test]
    procedure NoFileNameReturnsEmpty;
  end;

  //offline tests for client and factory configuration.
  [TestFixture]
  TClientTests = class
  public
    [Test]
    procedure FactoryAppliesDefaultTimeouts;
    [Test]
    procedure FactoryDefaultTimeoutsAreOneMinute;
    [Test]
    procedure CreateClientFromUri;
    [Test]
    procedure UserAgentRoundTrips;
    [Test]
    procedure CredentialsRoundTrip;
    [Test]
    procedure ProxySettingsRoundTrip;
    [Test]
    procedure AuthTypeRoundTrips;
    [Test]
    procedure BooleanFlagsRoundTrip;
    [Test]
    procedure MaxResponseSizeRoundTrips;
    [Test]
    procedure TimeoutsRoundTrip;
    [Test]
    procedure SetBaseUriUpdatesBaseUri;
  end;

implementation

uses
  WinApi.ActiveX,
  System.SysUtils,
  System.StrUtils,
  System.Classes,
  System.IOUtils,
  VSoft.CancellationToken,
  VSoft.Uri,
  VSoft.WinHttp.Api,
  VSoft.HttpClient.Response,
  VSoft.HttpClient.Headers,
  VSoft.HttpClient.MultipartFormData,
  JsonDataObjects;


//------------------------------------------------------------------------------
// helpers
//------------------------------------------------------------------------------

function StreamToString(const stream : TStream) : string;
var
  ss : TStringStream;
begin
  ss := TStringStream.Create('', TEncoding.UTF8);
  try
    stream.Seek(0, soBeginning);
    if stream.Size > 0 then
      ss.CopyFrom(stream, stream.Size);
    result := ss.DataString;
  finally
    ss.Free;
  end;
end;

function BytesOf(const value : string) : TBytes;
begin
  result := TEncoding.UTF8.GetBytes(value);
end;

//Generate transfers ownership of the stream to the caller, so we must free it.
function GenerateToString(const formData : IMultipartFormDataGenerator) : string;
var
  stream : TStream;
begin
  stream := formData.Generate;
  try
    result := StreamToString(stream);
  finally
    stream.Free;
  end;
end;

function NewTempFileName(const ext : string) : string;
var
  g : TGUID;
begin
  CreateGUID(g);
  result := TPath.Combine(TPath.GetTempPath, GUIDToString(g) + ext);
end;

function WriteTempFile(const content : string; const ext : string) : string;
var
  bytes : TBytes;
  fs : TFileStream;
begin
  result := NewTempFileName(ext);
  bytes := BytesOf(content);
  fs := TFileStream.Create(result, fmCreate);
  try
    if Length(bytes) > 0 then
      fs.WriteBuffer(bytes[0], Length(bytes));
  finally
    fs.Free;
  end;
end;

//create a request without touching the network. The client is never sent a request.
function NewRequest(const resource : string; const method : THttpMethod) : IHttpRequest;
var
  client : IHttpClient;
begin
  client := THttpClientFactory.CreateClient('https://localhost');
  result := client.CreateRequest(resource);
  result.HttpMethod := method;
end;

//build the assembled url for a request (base uri + resource + query string).
function UrlFor(const request : IHttpRequest) : string;
var
  client : IHttpClient;
begin
  client := THttpClientFactory.CreateClient('https://localhost');
  result := client.GetRequestUrl(request);
end;


//------------------------------------------------------------------------------
// TNetworkTests
//------------------------------------------------------------------------------

procedure TNetworkTests.TestGet;
var
  client : IHttpClient;
  response : IHttpResponse;
  request : IHttpRequest;
  cancelTokenSource : ICancellationTokenSource;
begin
  cancelTokenSource := TCancellationTokenSourceFactory.Create;
  client := THttpClientFactory.CreateClient('https://delphi.dev');
  request := client.CreateRequest('api/v1/index.json');
  response := client.Get(request, cancelTokenSource.Token);

  if response.StatusCode <> 200 then
    WriteLn(response.ErrorMessage);

  Assert.AreEqual<integer>(200, response.StatusCode);
  Assert.AreNotEqual<integer>(0, response.ContentLength);
  Assert.IsNotEmpty(response.Response, 'response is empty');
end;

procedure TNetworkTests.TestPostForm;
var
  client : IHttpClient;
  response : IHttpResponse;
  request : IHttpRequest;
  cancelTokenSource : ICancellationTokenSource;
begin
  cancelTokenSource := TCancellationTokenSourceFactory.Create;
  client := THttpClientFactory.CreateClient('https://localhost:5001');
  request := client.CreateRequest('/api/v1/package');
  request.WithHeader('X-ApiKey', 'foobar')
         .WithFile('i:\dpmfeed\ADUG.BasicLib-10.1-Win32-1.0.24.dpkg');
  response := client.Put(request, cancelTokenSource.Token);

  if response.StatusCode <> 200 then
    WriteLn(response.ErrorMessage);

  Assert.AreEqual<integer>(200, response.StatusCode);
  Assert.Pass;
end;

procedure TNetworkTests.TestResponseStream;
var
  client : IHttpClient;
  response : IHttpResponse;
  request : IHttpRequest;
  cancelTokenSource : ICancellationTokenSource;
  stream : TMemoryStream;
begin
  cancelTokenSource := TCancellationTokenSourceFactory.Create;
  client := THttpClientFactory.CreateClient('https://localhost:5002');
  request := client.CreateRequest('/api/v1/package/VSoft.DUnitX/11.0/Win32/0.3.3/icon');
  response := client.Get(request, cancelTokenSource.Token);

  if response.StatusCode <> 200 then
    WriteLn(response.ErrorMessage);

  Assert.AreEqual<integer>(200, response.StatusCode);
  Assert.AreNotEqual<integer>(0, response.ContentLength);

  stream := TMemoryStream.Create;
  try
    stream.CopyFrom(response.ResponseStream, response.ResponseStream.Size);
    Assert.AreEqual(response.ContentLength, stream.Size);
  finally
    stream.Free;
  end;
end;

procedure TNetworkTests.TestUploadFiles;
begin
  Assert.Pass;
end;

procedure TNetworkTests.TestWithUri;
var
  uri : IUri;
  client : IHttpClient;
  response : IHttpResponse;
  request : IHttpRequest;
  cancelTokenSource : ICancellationTokenSource;
begin
  cancelTokenSource := TCancellationTokenSourceFactory.Create;
  uri := TUriFactory.Parse('https://delphi.dev');
  client := THttpClientFactory.CreateClient(uri);
  request := client.CreateRequest('/api/v1/searchbyids')
    .WithBody('{"compiler": "XE7","platform": "Win32","packageids": [{"id": "Spring4D.Data","version": "2.0.0-rc.2"}]}', TEncoding.UTF8)
    .WithContentType('application/json', 'utf-8');

  response := client.Post(request, cancelTokenSource.Token);
  Assert.AreEqual<integer>(200, response.StatusCode);
end;


//------------------------------------------------------------------------------
// TUrlEncodeTests
//------------------------------------------------------------------------------

procedure TUrlEncodeTests.UnreservedCharsArePassedThrough;
begin
  Assert.AreEqual('abcXYZ0189', UrlEncode('abcXYZ0189'));
  Assert.AreEqual('-_.~', UrlEncode('-_.~'));
end;

procedure TUrlEncodeTests.SpaceIsEncodedAsPlus;
begin
  Assert.AreEqual('a+b+c', UrlEncode('a b c'));
end;

procedure TUrlEncodeTests.ReservedCharsArePercentEncoded;
begin
  Assert.AreEqual('%2F', UrlEncode('/'));
  Assert.AreEqual('%3A', UrlEncode(':'));
  Assert.AreEqual('%3F', UrlEncode('?'));
  Assert.AreEqual('%26', UrlEncode('&'));
  Assert.AreEqual('%3D', UrlEncode('='));
  Assert.AreEqual('%40', UrlEncode('@'));
  Assert.AreEqual('%5B', UrlEncode('['));
  Assert.AreEqual('%5D', UrlEncode(']'));
  Assert.AreEqual('%2C', UrlEncode(','));
end;

procedure TUrlEncodeTests.PlusSignIsPercentEncoded;
begin
  //a literal plus must not collide with the space->plus encoding.
  Assert.AreEqual('%2B', UrlEncode('+'));
end;

procedure TUrlEncodeTests.UnicodeIsUtf8PercentEncoded;
begin
  //é is U+00E9 which is C3 A9 in UTF-8.
  Assert.AreEqual('%C3%A9', UrlEncode(#$00E9));
end;

procedure TUrlEncodeTests.EmptyStringReturnsEmpty;
begin
  Assert.AreEqual('', UrlEncode(''));
end;

procedure TUrlEncodeTests.HexIsUpperCase;
begin
  //tilde stays, but '{' -> %7B (uppercase hex digits)
  Assert.AreEqual('%7B', UrlEncode('{'));
end;

procedure TUrlEncodeTests.MixedStringIsEncoded;
begin
  Assert.AreEqual('name%3DJohn+Doe%26age%3D30', UrlEncode('name=John Doe&age=30'));
end;


//------------------------------------------------------------------------------
// THelperFunctionTests
//------------------------------------------------------------------------------

procedure THelperFunctionTests.HttpMethodToStringReturnsName;
begin
  Assert.AreEqual('GET', HttpMethodToString(THttpMethod.GET));
  Assert.AreEqual('POST', HttpMethodToString(THttpMethod.POST));
  Assert.AreEqual('PUT', HttpMethodToString(THttpMethod.PUT));
  Assert.AreEqual('PATCH', HttpMethodToString(THttpMethod.PATCH));
  Assert.AreEqual('DELETE', HttpMethodToString(THttpMethod.DELETE));
end;

procedure THelperFunctionTests.ClientErrorToStringPrefixesMessage;
begin
  Assert.AreEqual('Sending: Timeout.', ClientErrorToString('Sending', ERROR_WINHTTP_TIMEOUT));
end;

procedure THelperFunctionTests.ClientErrorToStringFormatsUnknownCode;
begin
  Assert.AreEqual('x: Unknown Error 0x000000FE', ClientErrorToString('x', $FE));
end;


//------------------------------------------------------------------------------
// TRequestTests
//------------------------------------------------------------------------------

procedure TRequestTests.GetAppendsParametersToQueryString;
var
  request : IHttpRequest;
  url : string;
begin
  request := NewRequest('/api/values', THttpMethod.GET);
  request.WithParameter('a', '1').WithParameter('b', '2');
  url := UrlFor(request);
  Assert.IsTrue(ContainsStr(url, '?a=1&b=2'), url);
end;

procedure TRequestTests.GetEncodesParameterNameAndValue;
var
  request : IHttpRequest;
  url : string;
begin
  request := NewRequest('/api/values', THttpMethod.GET);
  request.WithParameter('q', 'a b&c');
  url := UrlFor(request);
  Assert.IsTrue(ContainsStr(url, '?q=a+b%26c'), url);
end;

procedure TRequestTests.DuplicateParameterNameOverwrites;
var
  request : IHttpRequest;
  url : string;
begin
  request := NewRequest('/api/values', THttpMethod.GET);
  request.WithParameter('a', '1').WithParameter('a', '2');
  url := UrlFor(request);
  Assert.IsTrue(ContainsStr(url, 'a=2'), url);
  Assert.IsFalse(ContainsStr(url, 'a=1'), url);
  Assert.AreEqual<integer>(1, request.Parameters.Count);
end;

procedure TRequestTests.PostDoesNotPutParametersOnUrl;
var
  request : IHttpRequest;
  url : string;
begin
  request := NewRequest('/api/values', THttpMethod.POST);
  request.WithParameter('a', '1');
  url := UrlFor(request);
  Assert.IsFalse(ContainsStr(url, 'a=1'), url);
end;

procedure TRequestTests.QueryParameterAlwaysOnUrlForPut;
var
  request : IHttpRequest;
  url : string;
begin
  request := NewRequest('/api/values', THttpMethod.PUT);
  request.WithParameter('b', '2').WithQueryParameter('a', '1');
  url := UrlFor(request);
  Assert.IsTrue(EndsStr('?a=1', url), 'query parameter not on url : ' + url);
  Assert.IsFalse(ContainsStr(url, 'b=2'), 'WithParameter value leaked onto url : ' + url);
end;

procedure TRequestTests.QueryParameterAndParameterCombineOnGet;
var
  request : IHttpRequest;
  url : string;
begin
  request := NewRequest('/api/values', THttpMethod.GET);
  request.WithParameter('p', '1').WithQueryParameter('q', '2');
  url := UrlFor(request);
  Assert.IsTrue(ContainsStr(url, '?'), url);
  Assert.IsTrue(ContainsStr(url, '&'), url);
  Assert.IsTrue(ContainsStr(url, 'p=1'), url);
  Assert.IsTrue(ContainsStr(url, 'q=2'), url);
end;

procedure TRequestTests.QueryParameterIsUrlEncoded;
var
  request : IHttpRequest;
  url : string;
begin
  request := NewRequest('/api/values', THttpMethod.PUT);
  request.WithQueryParameter('versionRange', '[0.0.2,2.0.0]');
  url := UrlFor(request);
  Assert.IsTrue(ContainsStr(url, 'versionRange=%5B0.0.2%2C2.0.0%5D'), url);
end;

procedure TRequestTests.ParameterEncodeFalseIsNotEncoded;
var
  request : IHttpRequest;
  url : string;
begin
  request := NewRequest('/api/values', THttpMethod.GET);
  request.WithParameter('q', 'a/b', false);
  url := UrlFor(request);
  Assert.IsTrue(ContainsStr(url, 'q=a/b'), url);
  Assert.IsFalse(ContainsStr(url, 'q=a%2Fb'), url);
end;

procedure TRequestTests.ParameterEncodeTrueStillEncodes;
var
  request : IHttpRequest;
  url : string;
begin
  //the default (and an explicit true) still url-encodes the value.
  request := NewRequest('/api/values', THttpMethod.GET);
  request.WithParameter('q', 'a/b', true);
  url := UrlFor(request);
  Assert.IsTrue(ContainsStr(url, 'q=a%2Fb'), url);
end;

procedure TRequestTests.QueryParameterEncodeFalseIsNotEncoded;
var
  request : IHttpRequest;
  url : string;
begin
  request := NewRequest('/api/values', THttpMethod.PUT);
  request.WithQueryParameter('q', 'a/b', false);
  url := UrlFor(request);
  Assert.IsTrue(ContainsStr(url, 'q=a/b'), url);
  Assert.IsFalse(ContainsStr(url, 'q=a%2Fb'), url);
end;

procedure TRequestTests.FormParameterEncodeFalseIsNotEncoded;
var
  request : IHttpRequest;
  body : string;
begin
  request := NewRequest('/api', THttpMethod.POST);
  request.WithParameter('q', 'a b', false);
  body := StreamToString(request.GetBody);
  Assert.AreEqual('q=a b', body);
end;

procedure TRequestTests.UriQueryStringRoutedToQueryParameters;
var
  request : IHttpRequest;
begin
  request := NewRequest('/api/values?x=1&y=2', THttpMethod.GET);
  Assert.AreEqual<integer>(2, request.QueryParameters.Count);
  Assert.AreEqual<integer>(0, request.Parameters.Count);
end;

procedure TRequestTests.UriQueryStringSurvivesPut;
var
  request : IHttpRequest;
  url : string;
begin
  request := NewRequest('/api/values?x=1', THttpMethod.PUT);
  url := UrlFor(request);
  Assert.IsTrue(ContainsStr(url, '?x=1'), url);
end;

procedure TRequestTests.UrlSegmentsReplacedOnGet;
var
  request : IHttpRequest;
  url : string;
begin
  request := NewRequest('/api/{id}/details', THttpMethod.GET);
  request.AddUrlSegement('id', '42');
  url := UrlFor(request);
  Assert.IsTrue(ContainsStr(url, '/api/42/details'), url);
  Assert.IsFalse(ContainsStr(url, '{id}'), url);
end;

procedure TRequestTests.UrlSegmentsReplacedOnPut;
var
  request : IHttpRequest;
  url : string;
begin
  request := NewRequest('/api/{id}/details', THttpMethod.PUT);
  request.AddUrlSegement('id', '42');
  url := UrlFor(request);
  Assert.IsTrue(ContainsStr(url, '/api/42/details'), url);
  Assert.IsFalse(ContainsStr(url, '{id}'), url);
end;

procedure TRequestTests.HeaderIsStored;
var
  request : IHttpRequest;
begin
  request := NewRequest('/api', THttpMethod.GET);
  request.WithHeader('X-Custom', 'hello');
  Assert.AreEqual('hello', request.Headers.Values['X-Custom']);
end;

procedure TRequestTests.AcceptHelpersSetHeaders;
var
  request : IHttpRequest;
begin
  request := NewRequest('/api', THttpMethod.GET);
  request.WithAccept('application/json')
         .WithAcceptEncoding('gzip')
         .WithAcceptCharSet('utf-8')
         .WithAcceptLanguage('en');
  Assert.AreEqual('application/json', request.Accept);
  Assert.AreEqual('gzip', request.AcceptEncoding);
  Assert.AreEqual('utf-8', request.AcceptCharSet);
  Assert.AreEqual('en', request.AcceptLanguage);
end;

procedure TRequestTests.ContentTypeWithCharSet;
var
  request : IHttpRequest;
begin
  request := NewRequest('/api', THttpMethod.POST);
  request.WithContentType('application/json', 'utf-8');
  Assert.AreEqual('application/json; charset=utf-8', request.ContentType);
end;

procedure TRequestTests.ContentTypeWithoutCharSet;
var
  request : IHttpRequest;
begin
  request := NewRequest('/api', THttpMethod.POST);
  request.WithContentType('application/json');
  Assert.AreEqual('application/json', request.ContentType);
end;

procedure TRequestTests.GetHasNoBody;
var
  request : IHttpRequest;
begin
  request := NewRequest('/api', THttpMethod.GET);
  request.WithParameter('a', '1');
  Assert.IsNull(request.GetBody);
  Assert.AreEqual<Int64>(0, request.ContentLength);
end;

procedure TRequestTests.PostWithParametersIsFormUrlEncoded;
var
  request : IHttpRequest;
  body : string;
begin
  request := NewRequest('/api', THttpMethod.POST);
  request.WithParameter('a', '1').WithParameter('b', 'x y');
  body := StreamToString(request.GetBody);
  Assert.AreEqual('a=1&b=x+y', body);
  Assert.AreEqual('application/x-www-form-urlencoded', request.ContentType);
end;

procedure TRequestTests.StringBodyIsReturnedAsContent;
var
  request : IHttpRequest;
  body : string;
begin
  request := NewRequest('/api', THttpMethod.POST);
  request.WithBody('{"a":1}');
  body := StreamToString(request.GetBody);
  Assert.AreEqual('{"a":1}', body);
end;

procedure TRequestTests.StringBodyTakesPrecedenceOverParameters;
var
  request : IHttpRequest;
  body : string;
begin
  request := NewRequest('/api', THttpMethod.POST);
  request.WithParameter('a', '1').WithBody('raw');
  body := StreamToString(request.GetBody);
  Assert.AreEqual('raw', body);
end;

procedure TRequestTests.ContentLengthMatchesBody;
var
  request : IHttpRequest;
begin
  request := NewRequest('/api', THttpMethod.POST);
  request.WithBody('hello');
  Assert.AreEqual<Int64>(5, request.ContentLength);
end;

procedure TRequestTests.FluentMethodsReturnSameInstance;
var
  request : IHttpRequest;
begin
  request := NewRequest('/api', THttpMethod.GET);
  Assert.IsTrue(request.WithHeader('a', 'b') = request, 'WithHeader did not return self');
  Assert.IsTrue(request.WithParameter('a', 'b') = request, 'WithParameter did not return self');
  Assert.IsTrue(request.WithQueryParameter('a', 'b') = request, 'WithQueryParameter did not return self');
end;

procedure TRequestTests.FollowRedirectsToggles;
var
  request : IHttpRequest;
begin
  request := NewRequest('/api', THttpMethod.GET);
  request.WillNotFollowRedirects;
  Assert.IsFalse(request.FollowRedirects);
  request.WillFollowRedirects;
  Assert.IsTrue(request.FollowRedirects);
end;

procedure TRequestTests.DefaultFollowRedirectsIsTrue;
var
  request : IHttpRequest;
begin
  request := NewRequest('/api', THttpMethod.GET);
  Assert.IsTrue(request.FollowRedirects);
end;

procedure TRequestTests.StreamBodyIsReturnedAsContent;
var
  request : IHttpRequest;
  source : TStringStream;
  body : string;
begin
  request := NewRequest('/api', THttpMethod.POST);
  //take ownership so the request frees the stream.
  source := TStringStream.Create('streambody', TEncoding.UTF8);
  request.WithBody(source, true);
  body := StreamToString(request.GetBody);
  Assert.AreEqual('streambody', body);
end;

procedure TRequestTests.WithBodyReplacesPreviousBody;
var
  request : IHttpRequest;
  body : string;
begin
  request := NewRequest('/api', THttpMethod.POST);
  request.WithBody('first').WithBody('second');
  body := StreamToString(request.GetBody);
  Assert.AreEqual('second', body);
end;

procedure TRequestTests.PatchWithParametersIsFormUrlEncoded;
var
  request : IHttpRequest;
  body : string;
begin
  request := NewRequest('/api', THttpMethod.PATCH);
  request.WithParameter('a', '1');
  body := StreamToString(request.GetBody);
  Assert.AreEqual('a=1', body);
  Assert.AreEqual('application/x-www-form-urlencoded', request.ContentType);
end;

procedure TRequestTests.DeleteWithParametersIsFormUrlEncoded;
var
  request : IHttpRequest;
  body : string;
begin
  request := NewRequest('/api', THttpMethod.DELETE);
  request.WithParameter('a', '1');
  body := StreamToString(request.GetBody);
  Assert.AreEqual('a=1', body);
end;

procedure TRequestTests.MultipleUrlSegmentsReplaced;
var
  request : IHttpRequest;
  url : string;
begin
  request := NewRequest('/api/{group}/{id}/details', THttpMethod.GET);
  request.AddUrlSegement('group', 'users').AddUrlSegement('id', '7');
  url := UrlFor(request);
  Assert.IsTrue(ContainsStr(url, '/api/users/7/details'), url);
end;

procedure TRequestTests.UrlSegmentReplacementIsCaseInsensitive;
var
  request : IHttpRequest;
  url : string;
begin
  request := NewRequest('/api/{ID}/details', THttpMethod.GET);
  request.AddUrlSegement('id', '99');
  url := UrlFor(request);
  Assert.IsTrue(ContainsStr(url, '/api/99/details'), url);
end;

procedure TRequestTests.EmptyParameterValueIsAllowed;
var
  request : IHttpRequest;
  url : string;
begin
  request := NewRequest('/api', THttpMethod.GET);
  request.WithParameter('flag', '');
  Assert.AreEqual<integer>(1, request.Parameters.Count);
  url := UrlFor(request);
  Assert.IsTrue(ContainsStr(url, '?flag='), url);
end;

procedure TRequestTests.EmptyQueryParameterValueIsAllowed;
var
  request : IHttpRequest;
  url : string;
begin
  request := NewRequest('/api', THttpMethod.PUT);
  request.WithQueryParameter('flag', '');
  Assert.AreEqual<integer>(1, request.QueryParameters.Count);
  url := UrlFor(request);
  Assert.IsTrue(ContainsStr(url, '?flag='), url);
end;

procedure TRequestTests.EmptyUrlSegmentValueReplaces;
var
  request : IHttpRequest;
  url : string;
begin
  request := NewRequest('/api/{x}/y', THttpMethod.GET);
  request.AddUrlSegement('x', '');
  url := UrlFor(request);
  Assert.IsFalse(ContainsStr(url, '{x}'), url);
  Assert.IsTrue(ContainsStr(url, '/api//y'), url);
end;

procedure TRequestTests.ResourceReflectsCreationPath;
var
  request : IHttpRequest;
begin
  request := NewRequest('/api/v1/values', THttpMethod.GET);
  Assert.AreEqual('/api/v1/values', request.Resource);
end;

procedure TRequestTests.WillSaveAsFileSetsSaveAsFile;
var
  request : IHttpRequest;
begin
  request := NewRequest('/api', THttpMethod.GET);
  request.WillSaveAsFile('output.bin');
  Assert.AreEqual('output.bin', request.SaveAsFile);
end;

procedure TRequestTests.AllowHttpDowngradeDefaultsFalse;
var
  request : IHttpRequest;
begin
  request := NewRequest('/api', THttpMethod.GET);
  Assert.IsFalse(request.AllowHttpDowngrade);
end;

procedure TRequestTests.AllowHttpDowngradeToggles;
var
  request : IHttpRequest;
begin
  request := NewRequest('/api', THttpMethod.GET);
  request.AllowHttpDowngrade := true;
  Assert.IsTrue(request.AllowHttpDowngrade);
end;

procedure TRequestTests.TimeoutsInheritClientDefaults;
var
  request : IHttpRequest;
begin
  //the factory sets 1 minute defaults on the client, which the request inherits.
  request := NewRequest('/api', THttpMethod.GET);
  Assert.AreEqual<integer>(60000, request.ConnectionTimeout);
  Assert.AreEqual<integer>(60000, request.SendTimeout);
  Assert.AreEqual<integer>(60000, request.ResponseTimeout);
end;

procedure TRequestTests.TimeoutsAreSettable;
var
  request : IHttpRequest;
begin
  request := NewRequest('/api', THttpMethod.GET);
  request.ConnectionTimeout := 1000;
  request.SendTimeout := 2000;
  request.ResponseTimeout := 3000;
  Assert.AreEqual<integer>(1000, request.ConnectionTimeout);
  Assert.AreEqual<integer>(2000, request.SendTimeout);
  Assert.AreEqual<integer>(3000, request.ResponseTimeout);
end;

procedure TRequestTests.DefaultHttpMethodIsGet;
var
  client : IHttpClient;
  request : IHttpRequest;
begin
  //a freshly created request defaults to GET (the enum's zero value).
  client := THttpClientFactory.CreateClient('https://localhost');
  request := client.CreateRequest('/api');
  Assert.IsTrue(request.HttpMethod = THttpMethod.GET);
end;


//------------------------------------------------------------------------------
// TRequestFileTests
//------------------------------------------------------------------------------

procedure TRequestFileTests.FileProducesMultipartContentType;
var
  request : IHttpRequest;
  tempFile : string;
  body : string;
begin
  tempFile := WriteTempFile('the file content', '.txt');
  try
    request := NewRequest('/api/upload', THttpMethod.POST);
    request.WithFile(tempFile, 'upload', 'text/plain');
    body := StreamToString(request.GetBody);
    Assert.StartsWith('multipart/form-data; boundary=', request.ContentType);
    Assert.IsTrue(ContainsStr(body, 'name="upload"'), body);
    Assert.IsTrue(ContainsStr(body, 'filename="' + ExtractFileName(tempFile) + '"'), body);
    Assert.IsTrue(ContainsStr(body, 'text/plain'), body);
    Assert.IsTrue(ContainsStr(body, 'the file content'), body);
  finally
    TFile.Delete(tempFile);
  end;
end;

procedure TRequestFileTests.ParameterBecomesMultipartField;
var
  request : IHttpRequest;
  tempFile : string;
  body : string;
begin
  tempFile := WriteTempFile('data', '.bin');
  try
    request := NewRequest('/api/upload', THttpMethod.POST);
    request.WithFile(tempFile, 'upload', 'application/octet-stream')
           .WithParameter('foo', 'bar');
    body := StreamToString(request.GetBody);
    Assert.IsTrue(ContainsStr(body, 'name="foo"'), body);
    Assert.IsTrue(ContainsStr(body, 'bar'), body);
  finally
    TFile.Delete(tempFile);
  end;
end;

procedure TRequestFileTests.QueryParameterIsNotInMultipartBody;
var
  request : IHttpRequest;
  tempFile : string;
  body : string;
begin
  tempFile := WriteTempFile('data', '.bin');
  try
    request := NewRequest('/api/upload', THttpMethod.PUT);
    request.WithFile(tempFile, 'upload', 'application/octet-stream')
           .WithQueryParameter('qp', 'shouldNotBeInBody');
    body := StreamToString(request.GetBody);
    Assert.IsFalse(ContainsStr(body, 'name="qp"'), body);
    Assert.IsFalse(ContainsStr(body, 'shouldNotBeInBody'), body);
  finally
    TFile.Delete(tempFile);
  end;
end;

procedure TRequestFileTests.ForceFormDataWithoutFileIsMultipart;
var
  request : IHttpRequest;
  body : string;
begin
  request := NewRequest('/api/upload', THttpMethod.POST);
  request.ForceFormData(true).WithParameter('a', '1');
  body := StreamToString(request.GetBody);
  Assert.StartsWith('multipart/form-data; boundary=', request.ContentType);
  Assert.IsTrue(ContainsStr(body, 'name="a"'), body);
end;

procedure TRequestFileTests.DefaultFieldNameIsFileName;
var
  request : IHttpRequest;
  tempFile : string;
  body : string;
begin
  tempFile := WriteTempFile('data', '.bin');
  try
    request := NewRequest('/api/upload', THttpMethod.POST);
    //no field name supplied - the file name is used as the field name.
    request.WithFile(tempFile);
    body := StreamToString(request.GetBody);
    Assert.IsTrue(ContainsStr(body, 'name="' + ExtractFileName(tempFile) + '"'), body);
  finally
    TFile.Delete(tempFile);
  end;
end;

procedure TRequestFileTests.MultipleFilesAreAllIncluded;
var
  request : IHttpRequest;
  fileA : string;
  fileB : string;
  body : string;
begin
  fileA := WriteTempFile('aaa', '.bin');
  fileB := WriteTempFile('bbb', '.bin');
  try
    request := NewRequest('/api/upload', THttpMethod.POST);
    request.WithFile(fileA, 'first', 'application/octet-stream')
           .WithFile(fileB, 'second', 'application/octet-stream');
    body := StreamToString(request.GetBody);
    Assert.IsTrue(ContainsStr(body, 'name="first"'), body);
    Assert.IsTrue(ContainsStr(body, 'name="second"'), body);
    Assert.IsTrue(ContainsStr(body, 'aaa'), body);
    Assert.IsTrue(ContainsStr(body, 'bbb'), body);
  finally
    TFile.Delete(fileA);
    TFile.Delete(fileB);
  end;
end;


//------------------------------------------------------------------------------
// TMultipartFormDataTests
//------------------------------------------------------------------------------

procedure TMultipartFormDataTests.ContentTypeContainsBoundary;
var
  formData : IMultipartFormDataGenerator;
begin
  formData := TMultipartFormDataFactory.Create;
  Assert.StartsWith('multipart/form-data; boundary=', formData.ContentType);
  Assert.IsTrue(ContainsStr(formData.ContentType, formData.Boundary), formData.ContentType);
end;

procedure TMultipartFormDataTests.BoundaryIsUniquePerInstance;
var
  a : IMultipartFormDataGenerator;
  b : IMultipartFormDataGenerator;
begin
  a := TMultipartFormDataFactory.Create;
  b := TMultipartFormDataFactory.Create;
  Assert.AreNotEqual(a.Boundary, b.Boundary);
end;

procedure TMultipartFormDataTests.AddFieldWritesContentDisposition;
var
  formData : IMultipartFormDataGenerator;
  content : string;
begin
  formData := TMultipartFormDataFactory.Create;
  formData.AddField('name', 'value');
  content := GenerateToString(formData);
  Assert.IsTrue(ContainsStr(content, 'Content-Disposition: form-data; name="name"'), content);
  Assert.IsTrue(ContainsStr(content, 'value'), content);
end;

procedure TMultipartFormDataTests.GenerateAppendsClosingBoundary;
var
  formData : IMultipartFormDataGenerator;
  boundary : string;
  content : string;
begin
  formData := TMultipartFormDataFactory.Create;
  boundary := formData.Boundary;
  formData.AddField('a', 'b');
  content := GenerateToString(formData);
  //the content has a trailing CRLF after the closing boundary, so check it is present
  //rather than that it is the very last thing in the buffer.
  Assert.IsTrue(ContainsStr(content, '--' + boundary + '--'), content);
end;

procedure TMultipartFormDataTests.GenerateRewindsStream;
var
  formData : IMultipartFormDataGenerator;
  stream : TStream;
begin
  formData := TMultipartFormDataFactory.Create;
  formData.AddField('a', 'b');
  stream := formData.Generate;
  try
    Assert.AreEqual<Int64>(0, stream.Position);
  finally
    stream.Free;
  end;
end;

procedure TMultipartFormDataTests.AddStreamUsesExplicitContentType;
var
  formData : IMultipartFormDataGenerator;
  source : TStringStream;
  content : string;
begin
  formData := TMultipartFormDataFactory.Create;
  source := TStringStream.Create('hello', TEncoding.UTF8);
  try
    formData.AddStream('field', source, 'thing.dat', 'application/x-custom');
  finally
    source.Free;
  end;
  content := GenerateToString(formData);
  Assert.IsTrue(ContainsStr(content, 'Content-Type: application/x-custom'), content);
  Assert.IsTrue(ContainsStr(content, 'filename="thing.dat"'), content);
end;

procedure TMultipartFormDataTests.AddStreamFallsBackToOctetStream;
var
  formData : IMultipartFormDataGenerator;
  source : TStringStream;
  content : string;
begin
  formData := TMultipartFormDataFactory.Create;
  source := TStringStream.Create('hello', TEncoding.UTF8);
  try
    //unknown extension and no explicit content type => octet-stream
    formData.AddStream('field', source, 'thing.unknownext12345');
  finally
    source.Free;
  end;
  content := GenerateToString(formData);
  Assert.IsTrue(ContainsStr(content, 'Content-Type: application/octet-stream'), content);
end;

procedure TMultipartFormDataTests.MultipleFieldsAreWritten;
var
  formData : IMultipartFormDataGenerator;
  content : string;
begin
  formData := TMultipartFormDataFactory.Create;
  formData.AddField('first', 'one');
  formData.AddField('second', 'two');
  content := GenerateToString(formData);
  Assert.IsTrue(ContainsStr(content, 'name="first"'), content);
  Assert.IsTrue(ContainsStr(content, 'one'), content);
  Assert.IsTrue(ContainsStr(content, 'name="second"'), content);
  Assert.IsTrue(ContainsStr(content, 'two'), content);
end;

procedure TMultipartFormDataTests.BoundaryStartsWithDashes;
var
  formData : IMultipartFormDataGenerator;
begin
  formData := TMultipartFormDataFactory.Create;
  Assert.StartsWith('-----------', formData.Boundary);
end;

procedure TMultipartFormDataTests.AddStreamWithoutFileNameOmitsFileName;
var
  formData : IMultipartFormDataGenerator;
  source : TStringStream;
  content : string;
begin
  formData := TMultipartFormDataFactory.Create;
  source := TStringStream.Create('hello', TEncoding.UTF8);
  try
    formData.AddStream('field', source, '', 'application/x-custom');
  finally
    source.Free;
  end;
  content := GenerateToString(formData);
  Assert.IsTrue(ContainsStr(content, 'name="field"'), content);
  Assert.IsFalse(ContainsStr(content, 'filename='), content);
end;


//------------------------------------------------------------------------------
// TResponseTests
//------------------------------------------------------------------------------

procedure TResponseTests.SuccessStatusHasNoErrorMessage;
var
  response : IHttpResponseInternal;
begin
  response := THttpResponse.Create(0, '', '', '');
  response.SetStatusCode(200);
  Assert.AreEqual<integer>(200, response.StatusCode);
  Assert.AreEqual('', response.ErrorMessage);
end;

procedure TResponseTests.FailureStatusSetsErrorMessage;
var
  response : IHttpResponseInternal;
begin
  response := THttpResponse.Create(0, '', '', '');
  response.SetStatusCode(404);
  Assert.AreEqual<integer>(404, response.StatusCode);
  Assert.AreEqual('Not Found', response.ErrorMessage);
end;

procedure TResponseTests.IsSuccessBoundaries;
var
  response : IHttpResponseInternal;
begin
  response := THttpResponse.Create(0, '', '', '');
  response.SetStatusCode(299);
  Assert.AreEqual('', response.ErrorMessage, '299 should be success');
  response.SetStatusCode(300);
  Assert.AreNotEqual('', response.ErrorMessage, '300 should not be success');
end;

procedure TResponseTests.HeadersAreParsed;
var
  response : IHttpResponseInternal;
begin
  response := THttpResponse.Create(0, '', '', '');
  response.SetHeaders('Content-Type: application/json'#13#10 +
                      'X-Custom: abc'#13#10);
  Assert.AreEqual('application/json', response.Headers.Values['Content-Type']);
  Assert.AreEqual('abc', response.Headers.Values['X-Custom']);
end;

procedure TResponseTests.ContentTypeReadFromHeaders;
var
  response : IHttpResponseInternal;
begin
  response := THttpResponse.Create(0, '', '', '');
  response.SetHeaders('Content-Type: text/plain'#13#10);
  Assert.AreEqual('text/plain', response.ContentType);
end;

procedure TResponseTests.StatusLineIsIgnored;
var
  response : IHttpResponseInternal;
begin
  //a request/method echo line should not be parsed as a header.
  response := THttpResponse.Create(0, '', '', '');
  response.SetHeaders('GET /index.html'#13#10 +
                      'Content-Type: text/html'#13#10);
  Assert.AreEqual('text/html', response.ContentType);
  Assert.AreEqual<integer>(-1, response.Headers.IndexOfName('GET /index.html'));
end;

procedure TResponseTests.WrittenContentReadAsString;
var
  response : IHttpResponseInternal;
  bytes : TBytes;
begin
  response := THttpResponse.Create(0, '', '', '');
  bytes := BytesOf('hello world');
  response.WriteBuffer(bytes, Length(bytes));
  response.FinalizeContent;
  Assert.AreEqual('hello world', response.Response);
end;

procedure TResponseTests.ContentLengthMatchesWrittenBytes;
var
  response : IHttpResponseInternal;
  bytes : TBytes;
begin
  response := THttpResponse.Create(0, '', '', '');
  bytes := BytesOf('12345');
  response.WriteBuffer(bytes, Length(bytes));
  response.FinalizeContent;
  Assert.AreEqual<Int64>(5, response.ContentLength);
end;

procedure TResponseTests.MaxResponseSizeIsEnforced;
var
  response : IHttpResponseInternal;
  bytes : TBytes;
begin
  response := THttpResponse.Create(0, '', '', '');
  response.SetMaxResponseSize(4);
  bytes := BytesOf('too long');
  Assert.WillRaise(
    procedure
    begin
      response.WriteBuffer(bytes, Length(bytes));
    end, EHttpClientException);
end;

procedure TResponseTests.MaxResponseSizeZeroIsUnlimited;
var
  response : IHttpResponseInternal;
  bytes : TBytes;
begin
  response := THttpResponse.Create(0, '', '', '');
  response.SetMaxResponseSize(0);
  bytes := BytesOf('this can be any length at all');
  response.WriteBuffer(bytes, Length(bytes));
  response.FinalizeContent;
  Assert.AreEqual('this can be any length at all', response.Response);
end;

procedure TResponseTests.ContentDispositionParsedFromHeaders;
var
  response : IHttpResponseInternal;
begin
  response := THttpResponse.Create(0, '', '', '');
  response.SetHeaders('Content-Disposition: attachment; filename=test.dpkg'#13#10);
  Assert.IsNotNull(response.ContentDisposition);
  Assert.AreEqual('test.dpkg', response.ContentDisposition.FileName);
end;

procedure TResponseTests.FileResponseIsNotStringResponse;
var
  response : IHttpResponseInternal;
begin
  response := THttpResponse.Create(0, '', '', '');
  response.SetHeaders('Content-Disposition: attachment; filename=test.dpkg'#13#10);
  Assert.IsFalse(response.IsStringResponse);
end;

procedure TResponseTests.SaveToWritesFile;
var
  response : IHttpResponseInternal;
  bytes : TBytes;
  savedBytes : TBytes;
  folder : string;
  savedFile : string;
begin
  response := THttpResponse.Create(0, '', '', '');
  bytes := BytesOf('payload');
  response.WriteBuffer(bytes, Length(bytes));
  response.FinalizeContent;

  folder := TPath.Combine(TPath.GetTempPath, 'vsoft_httpclient_test');
  savedFile := TPath.Combine(folder, 'out.bin');
  try
    response.SaveTo(folder, 'out.bin');
    Assert.IsTrue(TFile.Exists(savedFile), savedFile);
    //read the raw bytes back - TFile.ReadAllText with an explicit encoding strips a
    //preamble-length prefix even when the file has no BOM, so compare bytes directly.
    savedBytes := TFile.ReadAllBytes(savedFile);
    Assert.AreEqual<integer>(Length(bytes), Length(savedBytes));
    Assert.AreEqual('payload', TEncoding.UTF8.GetString(savedBytes));
  finally
    if TFile.Exists(savedFile) then
      TFile.Delete(savedFile);
    if TDirectory.Exists(folder) then
      TDirectory.Delete(folder, true);
  end;
end;

procedure TResponseTests.ConstructorParsesHeaderString;
var
  response : IHttpResponse;
begin
  //the constructor accepts a raw header block and parses it into the headers list.
  response := THttpResponse.Create(200, '', 'Content-Type: application/json'#13#10, '');
  Assert.AreEqual('application/json', response.ContentType);
end;

procedure TResponseTests.ConstructorUsesProvidedErrorMessage;
var
  response : IHttpResponse;
begin
  response := THttpResponse.Create(500, 'custom error', '', '');
  Assert.AreEqual('custom error', response.ErrorMessage);
end;

procedure TResponseTests.ServerErrorStatusMessage;
var
  response : IHttpResponseInternal;
begin
  response := THttpResponse.Create(0, '', '', '');
  response.SetStatusCode(500);
  Assert.AreEqual('Internal Server Error', response.ErrorMessage);
end;

procedure TResponseTests.TeapotStatusMessage;
var
  response : IHttpResponseInternal;
begin
  response := THttpResponse.Create(0, '', '', '');
  response.SetStatusCode(418);
  Assert.AreEqual('I''m a teapot', response.ErrorMessage);
end;

procedure TResponseTests.EmptyResponseIsEmptyString;
var
  response : IHttpResponseInternal;
begin
  response := THttpResponse.Create(0, '', '', '');
  response.FinalizeContent;
  Assert.AreEqual('', response.Response);
end;

procedure TResponseTests.SetContentReplacesStream;
var
  response : IHttpResponseInternal;
  source : TStringStream;
begin
  response := THttpResponse.Create(0, '', '', '');
  source := TStringStream.Create('abc', TEncoding.UTF8);
  try
    //SetContent copies from the source's current position, so rewind first.
    source.Position := 0;
    response.SetContent(source);
  finally
    source.Free;
  end;
  Assert.AreEqual('abc', response.Response);
end;

procedure TResponseTests.MultipleWritesAccumulate;
var
  response : IHttpResponseInternal;
  first : TBytes;
  second : TBytes;
begin
  response := THttpResponse.Create(0, '', '', '');
  first := BytesOf('foo');
  second := BytesOf('bar');
  response.WriteBuffer(first, Length(first));
  response.WriteBuffer(second, Length(second));
  response.FinalizeContent;
  Assert.AreEqual('foobar', response.Response);
  Assert.AreEqual<Int64>(6, response.ContentLength);
end;

procedure TResponseTests.FileNameFromContentDisposition;
var
  response : IHttpResponseInternal;
begin
  response := THttpResponse.Create(0, '', '', '');
  response.SetHeaders('Content-Disposition: attachment; filename=download.zip'#13#10);
  Assert.AreEqual('download.zip', response.GetFileName);
end;

procedure TResponseTests.DefaultIsStringResponse;
var
  response : IHttpResponseInternal;
begin
  //with no content-disposition, a response is assumed to be a string response.
  response := THttpResponse.Create(0, '', '', '');
  Assert.IsTrue(response.IsStringResponse);
end;


//------------------------------------------------------------------------------
// TContentDispositionTests
//------------------------------------------------------------------------------

procedure TContentDispositionTests.ParsesDispositionType;
var
  cd : IContentDisposition;
begin
  cd := TContentDisposition.Create('attachment; filename=test.dpkg');
  Assert.AreEqual('attachment', cd.DispositionType);
end;

procedure TContentDispositionTests.ParsesFileName;
var
  cd : IContentDisposition;
begin
  cd := TContentDisposition.Create('attachment; filename=test.dpkg');
  Assert.AreEqual('test.dpkg', cd.FileName);
end;

procedure TContentDispositionTests.HandlesExtendedFileNameParameter;
var
  cd : IContentDisposition;
begin
  cd := TContentDisposition.Create('attachment; filename=test.dpkg; filename*=UTF-8''''test.dpkg');
  Assert.AreEqual('test.dpkg', cd.FileName);
end;

procedure TContentDispositionTests.ParsesInlineDisposition;
var
  cd : IContentDisposition;
begin
  cd := TContentDisposition.Create('inline; filename=preview.png');
  Assert.AreEqual('inline', cd.DispositionType);
  Assert.AreEqual('preview.png', cd.FileName);
end;

procedure TContentDispositionTests.NoFileNameReturnsEmpty;
var
  cd : IContentDisposition;
begin
  cd := TContentDisposition.Create('attachment');
  Assert.AreEqual('attachment', cd.DispositionType);
  Assert.AreEqual('', cd.FileName);
end;


//------------------------------------------------------------------------------
// TClientTests
//------------------------------------------------------------------------------

procedure TClientTests.FactoryAppliesDefaultTimeouts;
var
  client : IHttpClient;
begin
  client := THttpClientFactory.CreateClient('https://localhost');
  Assert.AreEqual<integer>(THttpClientFactory.DefaultConnectionTimeout, client.ConnectionTimeout);
  Assert.AreEqual<integer>(THttpClientFactory.DefaultSendTimeout, client.SendTimeout);
  Assert.AreEqual<integer>(THttpClientFactory.DefaultResponseTimeout, client.ResponseTimeout);
end;

procedure TClientTests.FactoryDefaultTimeoutsAreOneMinute;
begin
  Assert.AreEqual<integer>(60000, THttpClientFactory.DefaultConnectionTimeout);
  Assert.AreEqual<integer>(60000, THttpClientFactory.DefaultSendTimeout);
  Assert.AreEqual<integer>(60000, THttpClientFactory.DefaultResponseTimeout);
end;

procedure TClientTests.CreateClientFromUri;
var
  uri : IUri;
  client : IHttpClient;
begin
  uri := TUriFactory.Parse('https://example.com:9000');
  client := THttpClientFactory.CreateClient(uri);
  Assert.IsTrue(ContainsStr(client.BaseUri, 'example.com'), client.BaseUri);
end;

procedure TClientTests.UserAgentRoundTrips;
var
  client : IHttpClient;
begin
  client := THttpClientFactory.CreateClient('https://localhost');
  client.UserAgent := 'MyAgent/1.0';
  Assert.AreEqual('MyAgent/1.0', client.UserAgent);
end;

procedure TClientTests.CredentialsRoundTrip;
var
  client : IHttpClient;
begin
  client := THttpClientFactory.CreateClient('https://localhost');
  client.UserName := 'alice';
  client.Password := 'secret';
  Assert.AreEqual('alice', client.UserName);
  Assert.AreEqual('secret', client.Password);
end;

procedure TClientTests.ProxySettingsRoundTrip;
var
  client : IHttpClient;
begin
  client := THttpClientFactory.CreateClient('https://localhost');
  client.ProxyUrl := 'http://proxy:8080';
  client.ProxyUserName := 'bob';
  client.ProxyPassword := 'pwd';
  client.ProxyBypass := 'localhost';
  Assert.AreEqual('http://proxy:8080', client.ProxyUrl);
  Assert.AreEqual('bob', client.ProxyUserName);
  Assert.AreEqual('pwd', client.ProxyPassword);
  Assert.AreEqual('localhost', client.ProxyBypass);
end;

procedure TClientTests.AuthTypeRoundTrips;
var
  client : IHttpClient;
begin
  client := THttpClientFactory.CreateClient('https://localhost');
  client.AuthType := THttpAuthType.Basic;
  Assert.IsTrue(client.AuthType = THttpAuthType.Basic);
end;

procedure TClientTests.BooleanFlagsRoundTrip;
var
  client : IHttpClient;
begin
  client := THttpClientFactory.CreateClient('https://localhost');
  client.UseHttp2 := true;
  client.EnableTLS1_3 := true;
  client.EnableCertificateRevocationCheck := true;
  client.AllowSelfSignedCertificates := true;
  Assert.IsTrue(client.UseHttp2, 'UseHttp2');
  Assert.IsTrue(client.EnableTLS1_3, 'EnableTLS1_3');
  Assert.IsTrue(client.EnableCertificateRevocationCheck, 'EnableCertificateRevocationCheck');
  Assert.IsTrue(client.AllowSelfSignedCertificates, 'AllowSelfSignedCertificates');
end;

procedure TClientTests.MaxResponseSizeRoundTrips;
var
  client : IHttpClient;
begin
  client := THttpClientFactory.CreateClient('https://localhost');
  client.MaxResponseSize := 1048576;
  Assert.AreEqual<Int64>(1048576, client.MaxResponseSize);
end;

procedure TClientTests.TimeoutsRoundTrip;
var
  client : IHttpClient;
begin
  client := THttpClientFactory.CreateClient('https://localhost');
  client.ConnectionTimeout := 1111;
  client.SendTimeout := 2222;
  client.ResponseTimeout := 3333;
  Assert.AreEqual<integer>(1111, client.ConnectionTimeout);
  Assert.AreEqual<integer>(2222, client.SendTimeout);
  Assert.AreEqual<integer>(3333, client.ResponseTimeout);
end;

procedure TClientTests.SetBaseUriUpdatesBaseUri;
var
  client : IHttpClient;
begin
  client := THttpClientFactory.CreateClient('https://localhost');
  client.BaseUri := 'https://example.org';
  Assert.IsTrue(ContainsStr(client.BaseUri, 'example.org'), client.BaseUri);
end;


initialization
  TDUnitX.RegisterTestFixture(TNetworkTests);
  TDUnitX.RegisterTestFixture(TUrlEncodeTests);
  TDUnitX.RegisterTestFixture(THelperFunctionTests);
  TDUnitX.RegisterTestFixture(TRequestTests);
  TDUnitX.RegisterTestFixture(TRequestFileTests);
  TDUnitX.RegisterTestFixture(TMultipartFormDataTests);
  TDUnitX.RegisterTestFixture(TResponseTests);
  TDUnitX.RegisterTestFixture(TContentDispositionTests);
  TDUnitX.RegisterTestFixture(TClientTests);
  CoInitializeEx(nil, COINIT_APARTMENTTHREADED); //needed for winhttp.
end.
