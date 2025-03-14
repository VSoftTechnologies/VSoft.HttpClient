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
  THttpAuthType = (None, Basic, NegotiateOrNtlm);
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

  IHttpRequest = interface
  ['{6F143FFA-3F48-44C5-8462-4D8DF5B041BB}']
    function GetHeaders : TStrings;
    function GetParameters : TStrings;
    function GetUrlSegments : TStrings;

    function GetContentType: string;
    function GetAccept: string;
    function GetAcceptCharSet: string;
    function GetAcceptEncoding: string;
    function GetAcceptLanguage: string;
    function GetFollowRedirects : boolean;
    function GetHttpMethod : THttpMethod;
    function GetSaveAsFile : string;
    function GetResource : string;

    function GetUserName : string;
    function GetPassword : string;
    function GetProxyUserName : string;
    function GetProxyPassword : string;
    function GetConnectionTimeout : integer;
    function GetSendTimeout : integer;
    function GetResponseTimeout : integer;

    procedure SetAccept(const value: string);
    procedure SetAcceptCharSet(const value: string);
    procedure SetAcceptEncoding(const value: string);
    procedure SetAcceptLanguage(const value: string);
    procedure SetContentType(const value: string);
    procedure SetFollowRedirects(value : boolean);
    procedure SetHttpMethod(value : THttpMethod);
    procedure SetSaveAsFile(const value : string);
    procedure SetResource(const value : string);
    procedure SetUserName(const value : string);
    procedure SetPassword(const value : string);
    procedure SetProxyUserName(const value : string);
    procedure SetProxyPassword(const value : string);

    procedure SetConnectionTimeout(value : integer);
    procedure SetSendTimeout(value : integer);
    procedure SetResponseTimeout(value : integer);
    function GetContentLength : Int64;
    //todo - these should not be on the interface
    function GetBody : TStream;
    function GetCharSet : string;


    //configure
    function WithAccept(const value : string) : IHttpRequest;
    function WithAcceptEncoding(const value : string) : IHttpRequest;
    function WithAcceptCharSet(const value : string) : IHttpRequest;
    function WithAcceptLanguage(const value : string) : IHttpRequest;
    function WithContentType(const value : string; const charSet : string = '') : IHttpRequest;

    function WithHeader(const name : string; const value : string) : IHttpRequest;

    function WithBody(const value : string; const encoding : TEncoding = nil) : IHttpRequest;overload;
    function WithBody(const value : TStream; const takeOwnership : boolean;  const encoding : TEncoding = nil) : IHttpRequest;overload;


    // Replaces {placeholder} values in the Resource
    function AddUrlSegement(const name : string; const value : string) : IHttpRequest;

    //borrowed from restsharp doco - we will replciate it's behaviour
    //This behaves differently based on the method. If you execute a GET call,
    //AddParameter will append the parameters to the querystring in the form url?name1=value1&name2=value2
    //On a POST or PUT Requests, it depends on whether or not you have files attached to a Request.
    //If not, the Parameters will be sent as the body of the request in the form name1=value1&name2=value2.
    //Also, the request will be sent as application/x-www-form-urlencoded.
    //In both cases, name and value will automatically be url-encoded.
    function WithParameter(const name : string; const value : string) : IHttpRequest;

    // If you have files, we will send a multipart/form-data request. Your parameters will be part of this request
    function WithFile(const filePath : string; const fieldName : string = ''; const contentType : string = '') : IHttpRequest;

    //if the server sends a file, we'll save it as filename
    function WillSaveAsFile(const fileName : string) : IHttpRequest;

    function WillFollowRedirects : IHttpRequest;
    function WillNotFollowRedirects : IHttpRequest;

    function ForceFormData(const value : boolean = true) : IHttpRequest;

    property Headers      : TStrings read GetHeaders;
    property Parameters   : TStrings read GetParameters;
    property UrlSegments  : TStrings read GetUrlSegments;

    property Accept         : string read GetAccept write SetAccept;
    property AcceptEncoding : string read GetAcceptEncoding write setAcceptEncoding;
    property AcceptCharSet  : string read GetAcceptCharSet write SetAcceptCharSet;
    property AcceptLanguage : string read GetAcceptLanguage write SetAcceptLanguage;
    property ContentType    : string read GetContentType write SetContentType;

    property FollowRedirects : boolean read GetFollowRedirects write SetFollowRedirects;
    property HtttpMethod : THttpMethod read GetHttpMethod write SetHttpMethod;
    property Resource    : string read GetResource write SetResource;
    property ContentLength : Int64 read GetContentLength;
    property SaveAsFile  : string read GetSaveAsFile write SetSaveAsFile;
    property UserName  : string read GetUserName write SetUserName;
    property Passsword : string read GetPassword write SetPassword;
    property ProxyUserName : string read GetProxyUserName write SetProxyUserName;
    property ProxyPassword : string read GetProxyPassword write SetProxyPassword;

    property ConnectionTimeout: Integer read GetConnectionTimeout write SetConnectionTimeout;
    property SendTimeout: Integer read GetSendTimeout write SetSendTimeout;
    property ResponseTimeout: Integer read GetResponseTimeout write SetResponseTimeout;
  end;



  IRestSerializer = interface
  ['{80EFB40E-4D10-4E8C-8C61-D2E663391913}']
    function GetSupportedContentTypes : TArray<string>;
    function Deserialize(const returnType : PTypeInfo; const response : IHttpResponse) : TObject;
    function Serialize(const obj : TObject) : string;
    property SupportedContentTypes : TArray<string> read GetSupportedContentTypes;
  end;


  IHttpClientInternal = interface
  ['{1F09A9A8-A32E-41F3-811B-BA7D5B352185}']
    function Send(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;overload;
    function GetBaseUri: string;
    function GetUri : IUri;
  end;

  THttpClientBase = class(TInterfacedObject)
  protected
    FConnectionTimeout: Integer;
    FSendTimeout: Integer;
    FResponseTimeout: Integer;
  public
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

    function CreateRequest(const resource : string) : IHttpRequest;overload;
    function CreateRequest(const uri : IUri) : IHttpRequest;overload;

    procedure UseSerializer(const useFunc : TUseSerializerFunc);overload;
    procedure UseSerializer(const serializer : IRestSerializer);overload;

    //execute
    function Get(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;
    function Post(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;
    function Patch(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;
    function Put(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;
    function Delete(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;
    function Send(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;

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
