unit VSoft.HttpClient;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Typinfo,
  VSoft.CancellationToken,
  VSoft.Uri;


{$IFDEF CONDITIONALEXPRESSIONS}  //Started being defined with D2009
   {$IF CompilerVersion < 23.0} // Before RAD Studio XE2
      {$DEFINE UNSUPPORTED_COMPILER_VERSION}
   {$IFEND}
  {$IF CompilerVersion > 24.0 } //XE4 or later
    {$LEGACYIFEND ON}
  {$IFEND}
{$ELSE}
  {$DEFINE UNSUPPORTED_COMPILER_VERSION}
{$ENDIF}



type
  THttpAuthType = (None, Basic);
  THttpMethod = (GET,POST, PUT, PATCH, DELETE);

type
  IContentDisposition = interface
  ['{BC849CF0-F39F-4258-9964-C6A48FC9F0C2}']
    function GetDispositionType : string;
    function GetFileName : string;

    property DispositionType : string read GetDispositionType;
    property FileName : string read GetFileName;
  end;

  IHttpResponse = interface
  ['{CAF07179-6432-4AFA-8157-CC8DE8600EA9}']
    function GetContentType : string;
    function GetResponseStream : TStream;
    function GetResponse : string;
    function GetStatusCode : integer;
    function GetHeaders : TStrings;
    function GetIsStringResponse : boolean;
    function GetFileName : string;
    function GetContentLength : Int64;
    function GetContentDisposition : IContentDisposition;
    function GetErrorMessage : string;
    procedure SaveTo(const folderName :string; const fileName : string = '');

    //common Response headers
    property ContentType : string read GetContentType;
    property ContentLength : Int64 read GetContentLength;
    property ContentDisposition : IContentDisposition read GetContentDisposition;
    property ErrorMessage : string read GetErrorMessage;

    property ResponseStream : TStream read GetResponseStream;
    property Response : string read GetResponse;
    property StatusCode : integer read GetStatusCode;
    property Headers : TStrings read GetHeaders;
    //returns true if the contenttype indicates a textual response.
    property IsStringResponse : boolean read GetIsStringResponse;
  end;


  IRestSerializer = interface
  ['{80EFB40E-4D10-4E8C-8C61-D2E663391913}']
    function GetSupportedContentTypes : TArray<string>;
    function Deserialize(const returnType : PTypeInfo; const response : IHttpResponse) : TObject;
    function Serialize(const obj : TObject) : string;
    property SupportedContentTypes : TArray<string> read GetSupportedContentTypes;
  end;



  TRequest = class;

  IHttpClientInternal = interface
  ['{1F09A9A8-A32E-41F3-811B-BA7D5B352185}']
    function Send(const request : TRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;overload;
    function GetBaseUri: string;
    function GetUri : IUri;
  end;

  THttpClientBase = class(TInterfacedObject)
  protected
    FConnectionTimeout: Integer;
    FSendTimeout: Integer;
    FResponseTimeout: Integer;
  public
    procedure ReleaseRequest(const request : TRequest);virtual;abstract;
    property ConnectionTimeout: Integer read FConnectionTimeout write FConnectionTimeout;
    property SendTimeout: Integer read FSendTimeout write FSendTimeout;
    property ResponseTimeout: Integer read FResponseTimeout write FResponseTimeout;
  end;


  TRequest = class
  private
    FClient : THttpClientBase;
    FHttpMethod : THttpMethod;
    FHeaders : TStringList;
    FRequestParams : TStringList;
    FFiles : TStringList;
    FUrlSegments : TStringList;
    FContent : TStream;
    FOwnsContent : boolean;
    FSaveAsFile : string;
    FEncoding : TEncoding;
    FForceFormData : boolean;
	  FFollowRedirects : boolean;
    FUserName : string;
    FPassword : string;
    FProxyUserName : string;
    FProxyPassword : string;

    FConnectionTimeout: Integer;
    FSendTimeout: Integer;
    FResponseTimeout: Integer;

    FURI : IUri;
  protected
    function GetHeaders : TStrings;
    function GetParameters : TStrings;
    function GetUrlSegments : TStrings;

    function GetContentType: string;
    function GetAccept: string;
    function GetAcceptCharSet: string;
    function GetAcceptEncoding: string;
    function GetAcceptLanguage: string;
    function GetResource : string;

    procedure SetAccept(const value: string);
    procedure SetAcceptCharSet(const value: string);
    procedure SetAcceptEncoding(const value: string);
    procedure SetAcceptLanguage(const value: string);
    procedure SetContentType(const value: string);
    procedure SetResource(const value : string);

    function GetBody : TStream;
    function GetContentLength : Int64;
    function GetCharSet : string;

    function GetClient : IHttpClientInternal;

  public
    constructor Create(const client : THttpClientBase; const resource : string);overload;
    constructor Create(const client : THttpClientBase; const uri : IUri);overload;
    destructor Destroy; override;


    //configure
    function WithAccept(const value : string) : TRequest;
    function WithAcceptEncoding(const value : string) : TRequest;
    function WithAcceptCharSet(const value : string) : TRequest;
    function WithAcceptLanguage(const value : string) : TRequest;
    function WithContentType(const value : string; const charSet : string = '') : TRequest;

    function WithHeader(const name : string; const value : string) : TRequest;

    function WithBody(const value : string; const encoding : TEncoding = nil) : TRequest;overload;
    function WithBody(const value : TStream; const takeOwnership : boolean;  const encoding : TEncoding = nil) : TRequest;overload;


    // Replaces {placeholder} values in the Resource
    function AddUrlSegement(const name : string; const value : string) : TRequest;

    //borrowed from restsharp doco - we will replciate it's behaviour
    //This behaves differently based on the method. If you execute a GET call,
    //AddParameter will append the parameters to the querystring in the form url?name1=value1&name2=value2
    //On a POST or PUT Requests, it depends on whether or not you have files attached to a Request.
    //If not, the Parameters will be sent as the body of the request in the form name1=value1&name2=value2.
    //Also, the request will be sent as application/x-www-form-urlencoded.
    //In both cases, name and value will automatically be url-encoded.
    function WithParameter(const name : string; const value : string) : TRequest;

    // If you have files, we will send a multipart/form-data request. Your parameters will be part of this request
    function WithFile(const filePath : string; const fieldName : string = ''; const contentType : string = '') : TRequest;

    //if the server sends a file, we'll save it as filename
    function WillSaveAsFile(const fileName : string) : TRequest;

    function WillFollowRedirects : TRequest;
    function WillNotFollowRedirects : TRequest;

    function ForceFormData(const value : boolean = true) : TRequest;

    //Note - ideally these methods would be on the client - but non gerneric interfaces cannot have generic methods.
    //execute
    function Get(const cancellationToken : ICancellationToken = nil) : IHttpResponse;overload;
//    function Get<T : class>(const cancellationToken : ICancellationToken = nil) : T;overload;

    function Post(const cancellationToken : ICancellationToken = nil) : IHttpResponse;overload;
//    function Post<T : class>(const entity : T; const cancellationToken : ICancellationToken = nil) : IHttpResponse;overload;
//    function Post<T : class; R : class>(const entity : T; const cancellationToken : ICancellationToken = nil) : R;overload;

    function Patch(const cancellationToken : ICancellationToken = nil) : IHttpResponse;overload;
//    function Patch<T : class>(const entity : T ; const cancellationToken : ICancellationToken = nil) : IHttpResponse;overload;
//    function Patch<T : class; R : class>(const entity : T; const cancellationToken : ICancellationToken = nil) : R;overload;

    function Put(const cancellationToken : ICancellationToken = nil) : IHttpResponse;overload;
//    function Put<T : class>(const entity : T ; const cancellationToken : ICancellationToken = nil) : IHttpResponse;overload;
//    function Put<T : class; R : class>(const entity : T; const cancellationToken : ICancellationToken = nil) : R;overload;

    function Delete(const cancellationToken : ICancellationToken = nil) : IHttpResponse;overload;
//    function Delete<T : class>(const entity : T; const cancellationToken : ICancellationToken = nil) : IHttpResponse;overload;

    property Headers      : TStrings read GetHeaders;
    property Parameters   : TStrings read GetParameters;
    property UrlSegments  : TStrings read GetUrlSegments;

    property Accept         : string read GetAccept write SetAccept;
    property AcceptEncoding : string read GetAcceptEncoding write setAcceptEncoding;
    property AcceptCharSet  : string read GetAcceptCharSet write SetAcceptCharSet;
    property AcceptLanguage : string read GetAcceptLanguage write SetAcceptLanguage;
    property ContentType    : string read GetContentType write SetContentType;

    property FollowRedirects : boolean read FFollowRedirects write FFollowRedirects;
    property HtttpMethod : THttpMethod read FHttpMethod write FHttpMethod;
    property Resource    : string read GetResource write SetResource;
    property ContentLength : Int64 read GetContentLength;
    property SaveAsFile  : string read FSaveAsFile write FSaveAsFile;
    property UserName  : string read FUserName write FUserName;
    property Passsword : string read FPassword write FPassword;
    property ProxyUserName : string read FProxyUserName write FProxyUserName;
    property ProxyPassword : string read FProxyPassword write FProxyPassword;

    property ConnectionTimeout: Integer read FConnectionTimeout write FConnectionTimeout;
    property SendTimeout: Integer read FSendTimeout write FSendTimeout;
    property ResponseTimeout: Integer read FResponseTimeout write FResponseTimeout;

  end;


  TUseSerializerFunc = reference to function : IRestSerializer;



  IHttpClient = interface
  ['{27ED69B0-7294-45F8-9DE8-DD0648B2EA80}']
    function GetAllowSelfSignedCertificates : boolean;
    procedure SetAllowSelfSignedCertificates(const value : boolean);

    function GetBaseUri : string;
    procedure SetBaseUri(const value : string);

    function GetUserAgent : string;
    procedure SetUserAgent(const value : string);

    procedure SetAuthType(const value : THttpAuthType);
    function GetAuthType : THttpAuthType;

    function GetUseHttp2 : boolean;
    procedure SetUseHttp2(const value : boolean);

    function GetEnableTLS1_3 : boolean;
    procedure SetEnableTLS1_3(const value : boolean);


    function GetUserName : string;
    procedure SetUserName(const value : string);

    function GetPassword : string;
    procedure SetPassword(const value : string);

    function GetConnectionTimeout : integer;
    procedure SetConnectionTimeout(const value : integer);

    function GetSendTimeout : integer;
    procedure SetSendTimeout(const value : integer);

    function GetResponseTimeout : integer;
    procedure SetResponseTimeout(const value : integer);

    function CreateRequest(const resource : string) : TRequest;overload;
    function CreateRequest(const uri : IUri) : TRequest;overload;

    procedure UseSerializer(const useFunc : TUseSerializerFunc);overload;
    procedure UseSerializer(const serializer : IRestSerializer);overload;

    function Send(const request : TRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;

    property AllowSelfSignedCertificates : boolean read GetAllowSelfSignedCertificates write SetAllowSelfSignedCertificates;
    property AuthType   : THttpAuthType read GetAuthType write SetAuthType;
    property BaseUri    : string read GetBaseUri write SetBaseUri;
    property UserAgent  : string read GetUserAgent write SetUserAgent;
    property UserName   : string read GetUserName write SetUserName;
    property Password   : string read GetPassword write SetPassword;

    property ConnectionTimeout: Integer read GetConnectionTimeout write SetConnectionTimeout;
    property SendTimeout: Integer read GetSendTimeout write SetSendTimeout;
    property ResponseTimeout: Integer read GetResponseTimeout write SetResponseTimeout;


    property UseHttp2   : boolean read GetUseHttp2 write SetUseHttp2;
    property EnableTLS1_3 : boolean read GetEnableTLS1_3 write SetEnableTLS1_3;

  end;

  THttpClientFactory = class
  private
   class
    var
      FDefaultConnectionTimeout: Integer;
      FDefaultSendTimeout: Integer;
      FDefaultResponseTimeout: Integer;
    class constructor Create;
  public
    class function CreateClient(const uri: string): IHttpClient;overload;
    class function CreateClient(const uri: IUri): IHttpClient;overload;

    class property DefaultConnectionTimeout: Integer read FDefaultConnectionTimeout write FDefaultConnectionTimeout;
    class property DefaultSendTimeout: Integer read FDefaultSendTimeout write FDefaultSendTimeout;
    class property DefaultResponseTimeout: Integer read FDefaultResponseTimeout write FDefaultResponseTimeout;
  end;

  EHttpClientException = class(Exception)
  private
    FError : NativeUInt;
  public
    constructor Create(const message : string; const errorCode : NativeUInt);reintroduce;
    property ErrorCode : NativeUInt read FError;
  end;


  function HttpMethodToString(const value : THttpMethod) : string;

  function ClientErrorToString(const message : string; const value : HRESULT) : string;

const
  cAcceptHeader = 'Accept';
  cAcceptCharsetHeader = 'Accept-Charset';
  cAcceptEncodingHeader = 'Accept-Encoding';
  cAcceptLanguageHeader = 'Accept-Language';
  cAuthorizationHeader = 'Authorization';
  cContentEncodingHeader = 'Content-Encoding';
  cContentLanguageHeader = 'Content-Language';
  cContentLengthHeader = 'Content-Length';
  cContentTypeHeader = 'Content-Type';
  cContentDispositionHeader = 'Content-Disposition';
  cLastModifiedHeader = 'Last-Modified';
  cUserAgentHeader = 'User-Agent';

implementation

uses
  System.StrUtils,
  VSoft.WinHttp.Api,
  VSoft.HttpClient.WinHttpClient,
  VSoft.HttpClient.MultipartFormData;

function ClientErrorToString(const message : string; const value : HRESULT) : string;
begin
  case value of
    ERROR_WINHTTP_OUT_OF_HANDLES : result := 'Out of handles.';
    ERROR_WINHTTP_TIMEOUT : result := 'Timeout.';
    ERROR_WINHTTP_INTERNAL_ERROR : result := 'Internal error.';
    ERROR_WINHTTP_INVALID_URL : result := 'Invalid url.';
    ERROR_WINHTTP_UNRECOGNIZED_SCHEME : result := 'Unrecognized scheme.';
    ERROR_WINHTTP_NAME_NOT_RESOLVED : result := 'Name not resolved.';
    ERROR_WINHTTP_INVALID_OPTION : result := 'Invalid option.';
    ERROR_WINHTTP_OPTION_NOT_SETTABLE : result := 'Option not settable.';
    ERROR_WINHTTP_SHUTDOWN : result := 'Shutdown.';


    ERROR_WINHTTP_LOGIN_FAILURE : result := 'Login failure.';
    ERROR_WINHTTP_OPERATION_CANCELLED : result := 'Operation cancelled.';
    ERROR_WINHTTP_INCORRECT_HANDLE_TYPE : result := 'Incorrect handle type.';
    ERROR_WINHTTP_INCORRECT_HANDLE_STATE : result := 'Incorrect handle state.';
    ERROR_WINHTTP_CANNOT_CONNECT : result := 'Cannot connect.';
    ERROR_WINHTTP_CONNECTION_ERROR : result := 'Connection error.';
    ERROR_WINHTTP_RESEND_REQUEST : result := 'Resend Request.';

    ERROR_WINHTTP_CLIENT_AUTH_CERT_NEEDED : result := 'The server requires SSL client Authentication.';


  // WinHttpRequest Component errors

    ERROR_WINHTTP_CANNOT_CALL_BEFORE_OPEN : result := 'Cannot call before open.';
    ERROR_WINHTTP_CANNOT_CALL_BEFORE_SEND : result := 'Cannot call before send.';
    ERROR_WINHTTP_CANNOT_CALL_AFTER_SEND : result := 'Cannot call after send.';
    ERROR_WINHTTP_CANNOT_CALL_AFTER_OPEN : result := 'Cannot call after open.';

  // HTTP API errors
    ERROR_WINHTTP_HEADER_NOT_FOUND : result := 'Header not found.';
    ERROR_WINHTTP_INVALID_SERVER_RESPONSE : result := 'Invalid server response.';
    ERROR_WINHTTP_INVALID_HEADER : result := 'Invalid header';
    ERROR_WINHTTP_INVALID_QUERY_REQUEST : result := 'Invalid query request.';
    ERROR_WINHTTP_HEADER_ALREADY_EXISTS : result := 'Header already exists';
    ERROR_WINHTTP_REDIRECT_FAILED : result := 'Redirect failed.';

  // additional WinHttp API error codes

    ERROR_WINHTTP_AUTO_PROXY_SERVICE_ERROR : result := 'A proxy for the specified URL cannot be located.';
    ERROR_WINHTTP_BAD_AUTO_PROXY_SCRIPT : result := 'An error occurred executing the script code in the Proxy Auto-Configuration (PAC) file.';
    ERROR_WINHTTP_UNABLE_TO_DOWNLOAD_SCRIPT : result := 'The PAC file cannot be downloaded.';

    ERROR_WINHTTP_NOT_INITIALIZED : result := 'Not Initialized.';
    ERROR_WINHTTP_SECURE_FAILURE : result := 'One or more errors were found in the Secure Sockets Layer (SSL) certificate sent by the server.';

  // Certificate security errors. These are raised only by the WinHttpRequest
  // component. The WinHTTP Win32 API will return ERROR_WINHTTP_SECURE_FAILE and
  // provide additional information via the WINHTTP_CALLBACK_STATUS_SECURE_FAILURE
  // callback notification.

    ERROR_WINHTTP_SECURE_CERT_DATE_INVALID : result := 'A required certificate is not within its validity period.';
    ERROR_WINHTTP_SECURE_CERT_CN_INVALID : result := 'A certificate CN name does not match the passed value.';
    ERROR_WINHTTP_SECURE_INVALID_CA : result := 'A certificate chain was processed, but terminated in a root certificate that is not trusted by the trust provider.';
    ERROR_WINHTTP_SECURE_CERT_REV_FAILED : result := 'Certificate revocation cannot be checked because the revocation server was offline.';
    ERROR_WINHTTP_SECURE_CHANNEL_ERROR : result := 'An error occurred with a secure channel.';
    ERROR_WINHTTP_SECURE_INVALID_CERT : result := 'Invalid certificate.';
    ERROR_WINHTTP_SECURE_CERT_REVOKED : result := 'A certificate has been revoked';
    ERROR_WINHTTP_SECURE_CERT_WRONG_USAGE : result := 'A certificate is not valid for the requested usage';


    ERROR_WINHTTP_AUTODETECTION_FAILED : result := 'a proxy for the specified URL cannot be located.';
    ERROR_WINHTTP_HEADER_COUNT_EXCEEDED : result := 'A larger number of headers were present in a response than WinHTTP could receive.';
    ERROR_WINHTTP_HEADER_SIZE_OVERFLOW : result := 'The size of headers received exceeds the limit for the request handle';
    ERROR_WINHTTP_CHUNKED_ENCODING_HEADER_SIZE_OVERFLOW : result := 'An overflow condition is encountered in the course of parsing chunked encoding.';
    ERROR_WINHTTP_RESPONSE_DRAIN_OVERFLOW : result := 'An incoming response exceeds an internal WinHTTP size limit.';
    ERROR_WINHTTP_CLIENT_CERT_NO_PRIVATE_KEY : result := 'The context for the SSL client certificate does not have a private key associated with it. The client certificate may have been imported to the computer without the private key.';
    ERROR_WINHTTP_CLIENT_CERT_NO_ACCESS_PRIVATE_KEY : result := 'The application does not have the required privileges to access the private key associated with the client certificate.';

    E_UNEXPECTED : result := 'Unexpected value';
  else
    result := 'Unknown Error 0x' + IntToHex(value,8);
  end;

  result := message + ': ' + result;

end;



function HttpMethodToString(const value : THttpMethod) : string;
begin
  result := GetEnumName(TypeInfo(THttpMethod), Ord(value));
end;


{ TRequest }

function TRequest.GetClient: IHttpClientInternal;
begin
  FClient.GetInterface(IHttpClientInternal, result)
end;

constructor TRequest.Create(const client: THttpClientBase; const uri: IUri);
var
  queryParam : TQueryParam;
begin
  FClient := client;
  FURI := uri;
  FFiles := TStringlist.Create;
  FHeaders := TStringList.Create;
  FRequestParams := TStringList.Create;
  FUrlSegments := TStringList.Create;
  FFollowRedirects := true;

  if Length(uri.QueryParams) > 0 then
  begin
    for queryParam in uri.QueryParams do
      WithParameter(queryParam.Name, queryParam.Value);
  end;
  FConnectionTimeout := client.ConnectionTimeout;
  FSendTimeout := client.SendTimeout;
  FResponseTimeout := client.ResponseTimeout;
end;

function CombineUriParts(const a, b : string) : string;
begin
  result := '';
  if (not EndsText('/', a)) and (not StartsText('/',b)) then //neither
    result := a + '/' + b
  else if (EndsText('/', a)) and StartsText('/',b)  then // both
  begin
    result := Copy(a, 1, Length(a) -1) + b;
  end
  else //one of
    result := a + b
end;


constructor TRequest.Create(const client: THttpClientBase;  const resource: string);
var
  uri : IUri;
  error : string;
  clientInf : IHttpClientInternal;
  sBaseUri : string;
begin
  if not client.GetInterface(IHttpClientInternal, clientInf) then
    raise Exception.Create('Client does not implement interface!');
  sBaseUri := clientInf.GetBaseUri;
  if sBaseUri <> '' then
     sBaseUri := CombineUriParts(sBaseUri, resource)
  else
    sBaseUri := resource;

  if not TUriFactory.TryParseWithError(sBaseUri, true, uri, error) then
    raise EArgumentException.Create('Invalid Uri : ' + error);

  Create(client, uri);

end;

function TRequest.Delete(const cancellationToken: ICancellationToken): IHttpResponse;
var
  lClient : IHttpClientInternal;
begin
  FHttpMethod := THttpMethod.DELETE;
  lClient := GetClient;
  result := lClient.Send(self, cancellationToken);
end;

//function TRequest.Delete<T>(const entity : T; const cancellationToken: ICancellationToken): IHttpResponse;
//var
//  entityType : PTypeInfo;
//  lClient : IHttpClientInternal;
//begin
//  raise ENotImplemented.Create('Serialization/Deserialization not implemented yet');
//  FHttpMethod := THttpMethod.DELETE;
//  entityType := TypeInfo(T);
//  //TODO : Serialize entity
//  lClient := GetClient;
//  result := lClient.Send(self,cancellationToken);
//end;

destructor TRequest.Destroy;
begin
  //cannot use client internal interface here as we are called from the client destructor.
  THttpClientBase(FClient).ReleaseRequest(Self);
  FFiles.Free;
  FHeaders.Free;
  FRequestParams.Free;
  FUrlSegments.Free;
  if FContent <> nil then
    FContent.Free;
  FClient := nil;
  inherited;
end;

function TRequest.ForceFormData(const value: boolean): TRequest;
begin
  result := self;
  FForceFormData := true;
end;

function TRequest.Get(const cancellationToken: ICancellationToken): IHttpResponse;
var
  lClient : IHttpClientInternal;
begin
  FHttpMethod := THttpMethod.GET;
  lClient := GetClient;
  result := lClient.Send(Self, cancellationToken);
end;

//function TRequest.Get<T>(const cancellationToken: ICancellationToken): T;
//var
//  returnType : PTypeInfo;
//  response : IHttpResponse;
//  lClient : IHttpClientInternal;
//begin
//  raise ENotImplemented.Create('Deserialization not implemented yet');
//
//  FHttpMethod := THttpMethod.GET;
//  returnType := TypeInfo(T);
//  lClient := GetClient;
//  response := lClient.Send(self, cancellationToken);
//  //TODO : deserialized the response
//  result := nil
//end;

function TRequest.GetAccept: string;
begin
  result := FHeaders.Values[cAcceptHeader];
end;

function TRequest.GetAcceptCharSet: string;
begin
  result := FHeaders.Values[cAcceptCharsetHeader];
end;

function TRequest.GetAcceptEncoding: string;
begin
  result := FHeaders.Values[cAcceptEncodingHeader];
end;

function TRequest.GetAcceptLanguage: string;
begin
  result := FHeaders.Values[cAcceptLanguageHeader];
end;

function TRequest.GetBody: TStream;
var
  formdata : IMultipartFormDataGenerator;
  i: Integer;
  sBody : string;
  sFileName :string;
  j : integer;
begin
  if FHttpMethod = THttpMethod.GET then
    exit(nil); //no body for get requests.

  if FContent <> nil then
  begin
    FContent.Seek(0, soBeginning);
    result := FContent;
    exit;
  end;

  if (FFiles.Count > 0) or FForceFormData then
  begin
    formdata := TMultipartFormDataFactory.Create;
    for i := 0 to FRequestParams.Count - 1 do
      formdata.AddField(FRequestParams.Names[i], FRequestParams.ValueFromIndex[i] );

    for i := 0 to FFiles.Count -1 do
    begin
      sFileName := FFiles.Names[i];
      j := pos(',', FFiles.Names[i]);
      if j > 0 then
        formdata.AddFile(Copy(sFileName, 1, j-1),  Copy(sFileName, j+1, Length(sFileName)),FFiles.ValueFromIndex[i])
      else
        formdata.AddFile('file' + IntToStr(i),  Copy(sFileName, j+1, Length(sFileName)),FFiles.ValueFromIndex[i]);
    end;
    FContent := formdata.Generate; //taking ownership here!
    SetContentType(formdata.ContentType);
    result := FContent;
  end
  else if FRequestParams.Count > 0 then
  begin
    FEncoding := TEncoding.UTF8;
    SetContentType('application/x-www-form-urlencoded');
    for i := 0 to FRequestParams.Count - 1 do
    begin
      if i > 0 then
        sBody := sBody + '&';
      //seems like winhttp does the encoding for us??
      sBody := sBody + FRequestParams.Names[i] + '=' + FRequestParams.ValueFromIndex[i];
    end;

    FContent := TStringStream.Create(sBody, TEncoding.UTF8);
    FContent.Seek(0,soBeginning);
    result := FContent;
  end
  else
    result := nil;
end;

function TRequest.GetCharSet: string;
begin
  if FEncoding <> nil then
  {$If CompilerVersion > 33.0} //10.4+
    result := FEncoding.MIMEName
  {$ELSE}
    result := FEncoding.EncodingName
  {$IFEND}
  else
    result := '';
end;


function TRequest.GetContentLength: Int64;
var
  stream : TStream;
begin
  stream := GetBody;
  if stream <> nil then
    result := stream.Size
  else
    result := 0;
end;

function TRequest.GetContentType: string;
begin
  result := FHeaders.Values[cContentTypeHeader];
end;

function TRequest.GetHeaders: TStrings;
begin
  result := FHeaders;
end;

function TRequest.GetParameters: TStrings;
begin
  result := FRequestParams;
end;

function TRequest.GetResource: string;
begin
  result := FURI.AbsolutePath;
end;


function TRequest.GetUrlSegments: TStrings;
begin
  result := FUrlSegments;
end;

function TRequest.Patch(const cancellationToken: ICancellationToken): IHttpResponse;
var
  lClient : IHttpClientInternal;
begin
  FHttpMethod := THttpMethod.PATCH;
  lClient := GetClient;
  result := lClient.Send(self, cancellationToken);
end;

//function TRequest.Patch<T, R>(const entity : T; const cancellationToken: ICancellationToken): R;
//var
//  entityType : PTypeInfo;
//  returnType : PTypeInfo;
//  response : IHttpResponse;
//  lClient : IHttpClientInternal;
//begin
//  raise ENotImplemented.Create('Serialization/Deserialization not implemented yet');
//  FHttpMethod := THttpMethod.PATCH;
//  entityType := TypeInfo(T);
//  returnType := TypeInfo(R);
//  lClient := GetClient;
//  response := lClient.Send(Self, cancellationToken);
//
//  result := nil;
//end;

//function TRequest.Patch<T>(const entity : T; const cancellationToken: ICancellationToken): IHttpResponse;
//var
//  entityType : PTypeInfo;
//  response : IHttpResponse;
//  lClient : IHttpClientInternal;
//begin
//  raise ENotImplemented.Create('Serialization/Deserialization not implemented yet');
//
//  FHttpMethod := THttpMethod.PATCH;
//  entityType := TypeInfo(T);
//  lClient := GetClient;
//  response := lClient.Send(self, cancellationToken);
//
//  result := nil;
//end;

function TRequest.Post(const cancellationToken: ICancellationToken): IHttpResponse;
var
  lClient : IHttpClientInternal;
begin
  FHttpMethod := THttpMethod.POST;
  lClient := GetClient;
  result := lClient.Send(self, cancellationToken);
end;

//function TRequest.Post<T, R>(const entity : T; const cancellationToken: ICancellationToken): R;
//var
//  entityType : PTypeInfo;
//  returnType : PTypeInfo;
//  response : IHttpResponse;
//  lClient : IHttpClientInternal;
//begin
//  raise ENotImplemented.Create('Serialization/Deserialization not implemented yet');
//
//  FHttpMethod := THttpMethod.POST;
//  entityType := TypeInfo(T);
//  returnType := TypeInfo(R);
//  lClient := GetClient;
//  response := lClient.Send(Self, cancellationToken );
//  result := nil;
//end;

//function TRequest.Post<T>(const entity : T;  const cancellationToken: ICancellationToken): IHttpResponse;
//var
//  entityType : PTypeInfo;
//  lClient : IHttpClientInternal;
//begin
//  raise ENotImplemented.Create('Serialization not implemented yet');
//
//  FHttpMethod := THttpMethod.POST;
//  entityType := TypeInfo(T);
//
//  //TODO : serialize entity
//  lClient := GetClient;
//  result := lClient.Send(self, cancellationToken);
//end;

function TRequest.Put(const cancellationToken: ICancellationToken): IHttpResponse;
var
  lClient : IHttpClientInternal;
begin
  FHttpMethod := THttpMethod.PUT;
  lClient := GetClient;
  result := lClient.Send(self, cancellationToken);
end;

//function TRequest.Put<T, R>(const entity: T; const cancellationToken: ICancellationToken): R;
//var
//  entityType : PTypeInfo;
//  returnType : PTypeInfo;
//  response : IHttpResponse;
//  lClient : IHttpClientInternal;
//begin
//  raise ENotImplemented.Create('Serialization/Deserialization not implemented yet');
//  FHttpMethod := THttpMethod.PUT;
//  entityType := TypeInfo(T);
//  returnType := TypeInfo(R);
//  lClient := GetClient;
//  response := lClient.Send(Self, cancellationToken );
//
//  result := nil;
//
//end;
//
//function TRequest.Put<T>(const entity : T;  const cancellationToken: ICancellationToken): IHttpResponse;
//var
//  entityType : PTypeInfo;
//  lClient : IHttpClientInternal;
//begin
//  raise ENotImplemented.Create('Serialization/Deserialization not implemented yet');
//  FHttpMethod := THttpMethod.PUT;
//  entityType := TypeInfo(T);
//
//  //TODO : Serialize!
//  lClient := GetClient;
//  result := lClient.Send(self, cancellationToken);
//end;

procedure TRequest.SetAccept(const value: string);
begin
  FHeaders.Values[cAcceptHeader] := value;
end;

procedure TRequest.SetAcceptCharSet(const value: string);
begin
  FHeaders.Values[cAcceptCharsetHeader] := value;
end;

procedure TRequest.SetAcceptEncoding(const value: string);
begin
  FHeaders.Values[cAcceptEncodingHeader] := value;
end;

procedure TRequest.SetAcceptLanguage(const value: string);
begin
  FHeaders.Values[cAcceptLanguageHeader] := value;
end;


procedure TRequest.SetContentType(const value: string);
begin
  FHeaders.Values[cContentTypeHeader] := value;
end;

procedure TRequest.SetResource(const value: string);
begin
 FURI.Path := value;
end;



function TRequest.WillFollowRedirects: TRequest;
begin
  FFollowRedirects := true;
  result := self;
end;

function TRequest.WillNotFollowRedirects: TRequest;
begin
  FFollowRedirects := false;
  result := self;
end;

function TRequest.WillSaveAsFile(const fileName: string): TRequest;
begin
  result := self;
  FSaveAsFile := fileName;
end;

function TRequest.WithAccept(const value: string): TRequest;
begin
  result := self;
  FHeaders.Values[cAcceptHeader] := value;
end;

function TRequest.WithAcceptCharSet(const value: string): TRequest;
begin
  result := self;
  FHeaders.Values[cAcceptCharsetHeader] := value;
end;

function TRequest.WithAcceptEncoding(const value: string): TRequest;
begin
  result := self;
  FHeaders.Values[cAcceptEncodingHeader] := value;
end;

function TRequest.WithAcceptLanguage(const value: string): TRequest;
begin
  result := self;
  FHeaders.Values[cAcceptLanguageHeader] := value;
end;

function TRequest.WithBody(const value: TStream; const takeOwnership: boolean; const encoding: TEncoding): TRequest;
begin
  result := self;
  FContent := value;
  FOwnsContent := takeOwnership;
  FEncoding := encoding;
end;

function TRequest.WithBody(const value: string; const encoding: TEncoding): TRequest;
var
  bytes : TBytes;
begin
  if (FContent <> nil) then
  begin
    //it's already set, so free it if we own it.
    if FOwnsContent then
      FContent.Free;
    FContent := nil;
  end;
  if encoding <> nil then
    FEncoding := encoding
  else
    FEncoding := TEncoding.UTF8;

  bytes := FEncoding.GetBytes(value);
  FContent := TMemoryStream.Create;
  FContent.WriteBuffer(bytes, Length(bytes));
  FOwnsContent := true;
  FContent.Seek(0,TSeekOrigin.soBeginning);
  result := Self;
//  Result := WithHeader(cContentLengthHeader, IntTostr(Length(bytes)));
end;

function TRequest.WithContentType(const value: string; const charSet : string = ''): TRequest;
begin
  result := self;
  if charSet <> ''  then
    FHeaders.Values[cContentTypeHeader] := value + '; charset=' + charSet
  else
    FHeaders.Values[cContentTypeHeader] := value;
end;

function TRequest.WithFile(const filePath, fieldName,  contentType: string): TRequest;
begin
  result := Self;
   if fieldName <> '' then
    FFiles.Add(fieldName + ',' + filePath + '=' + contentType)
  else
    FFiles.Add(ExtractFileName(filePath) + ',' + filePath + '=' + contentType);
end;

function TRequest.WithHeader(const name, value: string): TRequest;
begin
  result := self;
  FHeaders.Values[name] := value;
end;

function TRequest.WithParameter(const name, value: string): TRequest;
begin
  result := Self;
  FRequestParams.Values[name] := value;
end;

function TRequest.AddUrlSegement(const name, value: string): TRequest;
begin
  result := Self;
  FUrlSegments.Values[name] := value;
end;

{ THttpClientFactory }

class function THttpClientFactory.CreateClient(const uri : string): IHttpClient;
var
  theUri : IUri;
  error : string;
begin
  if not TUriFactory.TryParseWithError(uri, true, theUri, error)  then
    raise EArgumentOutOfRangeException.Create('Invalid Uri : ' + error );
  result := THttpClientFactory.CreateClient(theUri);
end;

class constructor THttpClientFactory.Create;
begin
  //1min defaults
  FDefaultConnectionTimeout := 60000;
  FDefaultSendTimeout := 60000;
  FDefaultResponseTimeout := 60000;
end;

class function THttpClientFactory.CreateClient(const uri: IUri): IHttpClient;
begin
  result := THttpClient.Create(uri);
  result.ConnectionTimeout := FDefaultConnectionTimeout;
  result.SendTimeout := FDefaultSendTimeout;
  result.ResponseTimeout := FDefaultResponseTimeout;
end;

{ EHttpClientException }

constructor EHttpClientException.Create(const message: string; const errorCode: NativeUInt);
begin
  inherited Create(message);
  FError := errorCode;
end;

end.
