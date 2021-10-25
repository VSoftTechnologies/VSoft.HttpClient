unit VSoft.HttpClient.Request;

//not used

interface

uses
  System.Classes,
  System.SysUtils,
  VSoft.CancellationToken,
  VSoft.HttpClient,
  VSoft.WinHttp.Api;


type
  IHttpRequest = interface

  end;

  THttpRequest = class(TinterfacedObject)
  private
    FHeaders : TStringList;
    FRequestParams : TStringList;
    FUrlSegments : TStringList;
    FFiles : TStringList;
    FQueryString : string;
    FHttpMethod : THttpMethod;
    FResource : string;
    FContent : TStream;
    FOwnsContent : boolean;
    FSaveAsFile : string;
    FEncoding : TEncoding;
    FForceFormData : boolean;
	  FFollowRedirects : boolean;
    FResolveTimeout : integer;
    FConnectTimeout : integer;
    FSendTimeout : integer;
    FReceiveTimeout : integer;
  protected
    function GetAuthorization: string;
    function GetBodyAsString: string;
    function GetContentType: string;
    function GetAccept: string;
    function GetAcceptCharSet: string;
    function GetAcceptEncoding: string;
    function GetAcceptLanguage: string;
    function GetHeaders: TStrings;
    function GetFiles: TStrings;
    function GetHttpMethod: THttpMethod;
    function GetResource: string;
    function GetQueryString : string;
    function GetUserAgent : string;
    function GetUrlSegments : TStrings;
    function GetForceFormData : boolean;
    function GetFollowRedirects : boolean;
    function GetResolveTimeout : integer;
    function GetConnectTimeout : integer;
    function GetSendTimeout : integer;
    function GetReceiveTimeout : integer;


    procedure SetAccept(const value: string);
    procedure SetAcceptCharSet(const value: string);
    procedure SetAcceptEncoding(const value: string);
    procedure SetAcceptLanguage(const value: string);
    procedure SetAuthorization(const value: string);
    procedure SetContentType(const value: string);
    procedure SetBody(const body : TStream; const takeOwnership : boolean ; const encoding : TEncoding = nil);overload;
    procedure SetBody(const body : string; const encoding : TEncoding = nil);overload;
    procedure SetHeaders(const value: TStrings);
    procedure SetFiles(const value: TStrings);
    procedure SetHttpMethod(const value: THttpMethod);
    procedure SetResource(const value: string);
    procedure SetQueryString(const value : string);
    procedure SetUserAgent(const value : string);
    procedure SetUrlSegments(const value : TStrings);
    procedure SetForceFormData(const value : boolean);


    procedure SetResolveTimeout(const value : integer);
    procedure SetConnectTimeout(const value : integer);
    procedure SetSendTimeout(const value : integer);
    procedure SetReceiveTimeout(const value : integer);


    procedure SetFollowRedirects(const value : boolean);
    function GetSaveAsFile: string;
    procedure SetSaveAsFile(const value: string);
    function GetCharSet : string;

    function AddHeader(const name : string; const value : string) : IHttpRequest;
    function AddParameter(const name : string; const value : string) : IHttpRequest;
    function AddUrlSegement(const name : string; const value : string) : IHttpRequest;
    function AddFile(const filePath : string; const fieldName : string = ''; const contentType : string = '') : IHttpRequest;
    procedure Reset;
  public
    constructor Create(const resource : string; const httpMethod : THttpMethod = THttpMethod.GET);
    destructor Destroy;override;

  end;


implementation

function THttpRequest.AddFile(const filePath, fieldName, contentType: string): IHttpRequest;
begin
  if fieldName <> '' then
    FFiles.Add(fieldName + ',' + filePath + '=' + contentType)
  else
    FFiles.Add('files,' + filePath + '=' + contentType);
end;

function THttpRequest.AddHeader(const name, value: string): IHttpRequest;
begin
//  result := Self;
  FHeaders.Values[name] := value
end;

function THttpRequest.AddParameter(const name, value: string): IHttpRequest;
begin
  //result := Self;
  if value <> '' then
    FRequestParams.Values[name] := value
  else
    FRequestParams.Add(name + '=');
end;

function THttpRequest.AddUrlSegement(const name, value: string): IHttpRequest;
begin
//  result := Self;
  FUrlSegments.Values[name] := value
end;

constructor THttpRequest.Create(const resource: string; const httpMethod: THttpMethod);
begin
  FHeaders := TStringList.Create;
  FRequestParams := TStringList.Create;
  FUrlSegments := TStringList.Create;
  FFiles := TStringList.Create;

  FHttpMethod := httpMethod;
  FResource := resource;
  FContent := nil;
  FOwnsContent := false;
  FFollowRedirects := true;

  //defaults from https://docs.microsoft.com/en-us/windows/win32/winhttp/iwinhttprequest-settimeouts
  //the std defaults are very conservative - changing to lower
  FResolveTimeout := 0;
  FConnectTimeout := 20000; //60000;
  FSendTimeout := 30000; //leaving send higher for uploading files.
  FReceiveTimeout := 15000;//30000;
end;

destructor THttpRequest.Destroy;
begin
  FHeaders.Free;
  FRequestParams.Free;
  FUrlSegments.Free;
  FFiles.Free;

  if FOwnsContent and (FContent <> nil)  then
    FContent.Free;
  inherited;
end;

function THttpRequest.GetAccept: string;
begin
  result :=  FHeaders.Values[cAcceptHeader];
end;

function THttpRequest.GetAcceptCharSet: string;
begin
  result :=  FHeaders.Values[cAcceptCharsetHeader];
end;

function THttpRequest.GetAcceptEncoding: string;
begin
  result :=  FHeaders.Values[cAcceptEncodingHeader];
end;

function THttpRequest.GetAcceptLanguage: string;
begin
  result :=  FHeaders.Values[cAcceptLanguageHeader];
end;

function THttpRequest.GetAuthorization: string;
begin
  result := FHeaders.Values['sAuthorizationHeader'];
end;

//function THttpRequest.GetBody: IStream;
//var
//  ownership : TStreamOwnership;
//  formdata : IMultipartFormDataGenerator;
//  i: Integer;
//  sBody : string;
//  ss : TStringStream;
//  sFileName :string;
//  j : integer;
//begin
//  if FContent <> nil then
//  begin
//    FContent.Seek(0, soBeginning);
//
//    if FOwnsContent then
//      ownership := soOwned
//    else
//      ownership := soReference;
//    result := TStreamAdapter.Create(FContent,ownership);
//    FOwnsContent := false;
//    FContent := nil;
//  end
//  else if (FFiles.Count > 0) or FForceFormData then
//  begin
//    formdata := TMultipartFormDataFactory.Create;
//    for i := 0 to FRequestParams.Count - 1 do
//      formdata.AddField(FRequestParams.Names[i], FRequestParams.ValueFromIndex[i] );
//
//    for i := 0 to FFiles.Count -1 do
//    begin
//      sFileName := FFiles.Names[i];
//      j := pos(',', FFiles.Names[i]);
//      if j > 0 then
//        formdata.AddFile(Copy(sFileName, 1, j-1),  Copy(sFileName, j+1, Length(sFileName)),FFiles.ValueFromIndex[i])
//      else
//        formdata.AddFile('files',  Copy(sFileName, j+1, Length(sFileName)),FFiles.ValueFromIndex[i]);
//    end;
//    //generate creates a new boundary so we need to upate the contentype before generating
//    SetContentType(formdata.ContentType);
//    result := formdata.Generate;
//  end
//  else if FRequestParams.Count > 0 then
//  begin
//    FEncoding := TEncoding.UTF8;
//    SetContentType('application/x-www-form-urlencoded');
//    for i := 0 to FRequestParams.Count - 1 do
//    begin
//      if i > 0 then
//        sBody := sBody + '&';
//      //seems like winhttp does the encoding for us??
//      sBody := sBody + FRequestParams.Names[i] + '=' + FRequestParams.ValueFromIndex[i];
//    end;
//    ss := TStringStream.Create(sBody, TEncoding.UTF8);
//    ss.Seek(0,soBeginning);
//    result := TStreamAdapter.Create(ss,soOwned);
//  end
//  else
//    result := nil;
//end;

function THttpRequest.GetBodyAsString: string;
begin
  if (FContent <> nil) and (FContent is TStringStream) then
    result := TStringStream(FContent).DataString
  else
    result := '';
end;

function THttpRequest.GetCharSet: string;
begin
  if FEncoding <> nil then
  begin
    if FEncoding = TEncoding.UTF8 then
      result := 'utf-8'
    else
      result := LowerCase(FEncoding.EncodingName);
  end
  else
    result := '';
end;

function THttpRequest.GetConnectTimeout: integer;
begin
  result := FConnectTimeout;
end;

function THttpRequest.GetContentType: string;
begin
  result := FHeaders.Values['Content-Type'];
end;

function THttpRequest.GetFiles: TStrings;
begin
  result := FFiles;
end;

function THttpRequest.GetFollowRedirects: boolean;
begin
  result := FFollowRedirects;
end;

function THttpRequest.GetForceFormData: boolean;
begin
  result := FForceFormData;
end;

function THttpRequest.GetHeaders: TStrings;
begin
  result := FHeaders;
end;

function THttpRequest.GetHttpMethod: THttpMethod;
begin
  result := FHttpMethod;
end;

function THttpRequest.GetQueryString: string;

  function BuildQueryString : string;
  var
    i : integer;
  begin
    for i := 0 to FRequestParams.Count -1 do
    begin
      if i > 0 then
        result := result + '&';
      result := result + FRequestParams.Strings[i];
    end;
  end;

begin
  result := FQueryString;
  if (result <> '') or (FRequestParams.Count = 0) then
    exit;

  case FHttpMethod of
    THttpMethod.GET,
    THttpMethod.DELETE: result := BuildQueryString;
  else
    result := '' //with post or put the parameters are form parameters in the body.
  end;


end;

function THttpRequest.GetReceiveTimeout: integer;
begin
  result := FReceiveTimeout
end;

function THttpRequest.GetResolveTimeout: integer;
begin
  result := FResolveTimeout;
end;

function THttpRequest.GetResource: string;
begin
  result := FResource;
end;

function THttpRequest.GetSaveAsFile: string;
begin
  result := FSaveAsFile;
end;

function THttpRequest.GetSendTimeout: integer;
begin
  result := FSendTimeout;
end;

function THttpRequest.GetUrlSegments: TStrings;
begin
  result := FUrlSegments;
end;

function THttpRequest.GetUserAgent: string;
begin
  result := FHeaders.Values[cUserAgentHeader];
end;

procedure THttpRequest.Reset;
begin
  FHeaders.Clear;
  FRequestParams.Clear;
  FUrlSegments.Clear;
  FFiles.Clear;
  FQueryString := '';
  FResource := '';
  FSaveAsFile := '';
  if FOwnsContent and (FContent <> nil) then
    FContent.Free;
  FOwnsContent := false;
  FContent := nil;
  FEncoding := nil;
  FForceFormData := false;

end;

procedure THttpRequest.SetAccept(const value: string);
begin
  FHeaders.Values[cAcceptHeader] := value;
end;

procedure THttpRequest.SetAcceptCharSet(const value: string);
begin
  FHeaders.Values[cAcceptCharsetHeader] := value;
end;

procedure THttpRequest.SetAcceptEncoding(const value: string);
begin
  FHeaders.Values[cAcceptEncodingHeader] := value;
end;

procedure THttpRequest.SetAcceptLanguage(const value: string);
begin
  FHeaders.Values[cAcceptLanguageHeader] := value;
end;

procedure THttpRequest.SetAuthorization(const value: string);
begin
  FHeaders.Values[cAuthorizationHeader] := value;
end;

procedure THttpRequest.SetBody(const body: string; const encoding: TEncoding);
begin
  if (FContent <> nil) then
  begin
    //it's already set, so free it if we own it.
    if FOwnsContent then
      FContent.Free;
    FContent := nil;
  end;
  FContent := TStringStream.Create(body, encoding);
  FOwnsContent := true;
  FEncoding := encoding;
end;

procedure THttpRequest.SetBody(const body : TStream; const takeOwnership : boolean; const encoding : TEncoding = nil);
begin
  FContent := body;
  FOwnsContent := takeOwnership;
  FEncoding := encoding;
end;


procedure THttpRequest.SetConnectTimeout(const value: integer);
begin
  if value >= 0 then
    FConnectTimeout := value
  else
    raise EArgumentOutOfRangeException.Create('ConnectTimeout cannot be less than zero');
end;

procedure THttpRequest.SetContentType(const value: string);
begin
  FHeaders.Values['Content-Type'] := value;
end;

procedure THttpRequest.SetFiles(const value: TStrings);
begin
  FFiles.Assign(value);
end;

procedure THttpRequest.SetFollowRedirects(const value: boolean);
begin
  FFollowRedirects := value;
end;

procedure THttpRequest.SetForceFormData(const value: boolean);
begin
  FForceFormData := value;
end;

procedure THttpRequest.SetHeaders(const value: TStrings);
begin
  FHeaders.Assign(value);
end;

procedure THttpRequest.SetHttpMethod(const value: THttpMethod);
begin
  FHttpMethod := value;
end;

procedure THttpRequest.SetQueryString(const value: string);
begin
  FQueryString := value;
end;

procedure THttpRequest.SetReceiveTimeout(const value: integer);
begin
  if value >= 0 then
    FReceiveTimeout := value
  else
    raise EArgumentOutOfRangeException.Create('ReceiveTimeout cannot be less than zero');
end;

procedure THttpRequest.SetResolveTimeout(const value: integer);
begin
  if value >= 0 then
    FResolveTimeout := value
  else
    raise EArgumentOutOfRangeException.Create('ResolveTimeout cannot be less than zero');
end;

procedure THttpRequest.SetResource(const value: string);
begin
  FResource := value;
end;

procedure THttpRequest.SetSaveAsFile(const value: string);
begin
  FSaveAsFile := value;
end;

procedure THttpRequest.SetSendTimeout(const value: integer);
begin
  if value >= 0 then
    FSendTimeout := value
  else
    raise EArgumentOutOfRangeException.Create('SendTimeout cannot be less than zero');
end;

procedure THttpRequest.SetUrlSegments(const value: TStrings);
begin
  FUrlSegments.Assign(value);
end;

procedure THttpRequest.SetUserAgent(const value: string);
begin
  FHeaders.Values[cUserAgentHeader] := value;
end;


end.
