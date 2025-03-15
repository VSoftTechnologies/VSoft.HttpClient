unit VSoft.HttpClient.Request;

interface

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


uses
  System.Classes,
  System.SysUtils,
  VSoft.Uri,
  VSoft.CancellationToken,
  VSoft.HttpClient;

type
  TRequest = class(TInterfacedObject, IHttpRequest)
  private
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

    function GetBody : TStream;
    function GetContentLength : Int64;
    function GetCharSet : string;
  public
    constructor Create(const client : IHttpClient; const resource : string);overload;
    constructor Create(const client : IHttpClient; const uri : IUri);overload;
    destructor Destroy; override;


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


implementation

uses
  System.StrUtils,
  VSoft.HttpClient.MultipartFormData;

{ TRequest }


constructor TRequest.Create(const client: IHttpClient; const uri: IUri);
var
  queryParam : TQueryParam;
begin
  inherited Create;
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


constructor TRequest.Create(const client: IHttpClient;  const resource: string);
var
  uri : IUri;
  error : string;
  clientInf : IHttpClientInternal;
  sBaseUri : string;
begin
  if not Supports(client, IHttpClientInternal, clientInf) then
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



destructor TRequest.Destroy;
begin
  FFiles.Free;
  FHeaders.Free;
  FRequestParams.Free;
  FUrlSegments.Free;
  if FContent <> nil then
    FContent.Free;
  inherited;
end;

function TRequest.ForceFormData(const value: boolean): IHttpRequest;
begin
  result := self;
  FForceFormData := true;
end;

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

function TRequest.GetConnectionTimeout: integer;
begin
  result := FConnectionTimeout;
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

function TRequest.GetFollowRedirects: boolean;
begin
  result := FFollowRedirects;
end;

function TRequest.GetHeaders: TStrings;
begin
  result := FHeaders;
end;

function TRequest.GetHttpMethod: THttpMethod;
begin
  result := FHttpMethod;
end;

function TRequest.GetParameters: TStrings;
begin
  result := FRequestParams;
end;

function TRequest.GetPassword: string;
begin
  result := FPassword;
end;

function TRequest.GetProxyPassword: string;
begin
  result := FProxyPassword;
end;

function TRequest.GetProxyUserName: string;
begin
  result := FProxyUserName;
end;

function TRequest.GetResource: string;
begin
  result := FURI.AbsolutePath;
end;


function TRequest.GetResponseTimeout: integer;
begin
  result := FResponseTimeout;
end;

function TRequest.GetSaveAsFile: string;
begin
  result := FSaveAsFile;
end;

function TRequest.GetSendTimeout: integer;
begin
  result := FSendTimeout;
end;

function TRequest.GetUrlSegments: TStrings;
begin
  result := FUrlSegments;
end;

function TRequest.GetUserName: string;
begin
  result := FUserName;
end;


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

procedure TRequest.SetConnectionTimeout(value: integer);
begin
  FConnectionTimeout := value;
end;

procedure TRequest.SetContentType(const value: string);
begin
  FHeaders.Values[cContentTypeHeader] := value;
end;

procedure TRequest.SetFollowRedirects(value: boolean);
begin
  FFollowRedirects := value;
end;

procedure TRequest.SetHttpMethod(value: THttpMethod);
begin
  FHttpMethod := value;
end;

procedure TRequest.SetPassword(const value: string);
begin
  FPassword := value;
end;

procedure TRequest.SetProxyPassword(const value: string);
begin
  FProxyPassword := value;
end;

procedure TRequest.SetProxyUserName(const value: string);
begin
  FProxyUserName := value;
end;

procedure TRequest.SetResource(const value: string);
begin
 FURI.Path := value;
end;

procedure TRequest.SetResponseTimeout(value: integer);
begin
  FResponseTimeout := value;
end;

procedure TRequest.SetSaveAsFile(const value: string);
begin
  FSaveAsFile := value;
end;

procedure TRequest.SetSendTimeout(value: integer);
begin
  FSendTimeout := value;
end;

procedure TRequest.SetUserName(const value: string);
begin
  FUserName := value;
end;

function TRequest.WillFollowRedirects: IHttpRequest;
begin
  FFollowRedirects := true;
  result := self;
end;

function TRequest.WillNotFollowRedirects: IHttpRequest;
begin
  FFollowRedirects := false;
  result := self;
end;

function TRequest.WillSaveAsFile(const fileName: string): IHttpRequest;
begin
  result := self;
  FSaveAsFile := fileName;
end;

function TRequest.WithAccept(const value: string): IHttpRequest;
begin
  result := self;
  FHeaders.Values[cAcceptHeader] := value;
end;

function TRequest.WithAcceptCharSet(const value: string): IHttpRequest;
begin
  result := self;
  FHeaders.Values[cAcceptCharsetHeader] := value;
end;

function TRequest.WithAcceptEncoding(const value: string): IHttpRequest;
begin
  result := self;
  FHeaders.Values[cAcceptEncodingHeader] := value;
end;

function TRequest.WithAcceptLanguage(const value: string): IHttpRequest;
begin
  result := self;
  FHeaders.Values[cAcceptLanguageHeader] := value;
end;

function TRequest.WithBody(const value: TStream; const takeOwnership: boolean; const encoding: TEncoding): IHttpRequest;
begin
  result := self;
  FContent := value;
  FOwnsContent := takeOwnership;
  FEncoding := encoding;
end;

function TRequest.WithBody(const value: string; const encoding: TEncoding): IHttpRequest;
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

function TRequest.WithContentType(const value: string; const charSet : string = ''): IHttpRequest;
begin
  result := self;
  if charSet <> ''  then
    FHeaders.Values[cContentTypeHeader] := value + '; charset=' + charSet
  else
    FHeaders.Values[cContentTypeHeader] := value;
end;

function TRequest.WithFile(const filePath, fieldName,  contentType: string): IHttpRequest;
begin
  result := Self;
   if fieldName <> '' then
    FFiles.Add(fieldName + ',' + filePath + '=' + contentType)
  else
    FFiles.Add(ExtractFileName(filePath) + ',' + filePath + '=' + contentType);
end;

function TRequest.WithHeader(const name, value: string): IHttpRequest;
begin
  result := self;
  FHeaders.Values[name] := value;
end;

function TRequest.WithParameter(const name, value: string): IHttpRequest;
begin
  result := Self;
  FRequestParams.Values[name] := value;
end;

function TRequest.AddUrlSegement(const name, value: string): IHttpRequest;
begin
  result := Self;
  FUrlSegments.Values[name] := value;
end;


end.
