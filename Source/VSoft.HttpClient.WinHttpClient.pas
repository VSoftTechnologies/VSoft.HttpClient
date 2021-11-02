unit VSoft.HttpClient.WinHttpClient;

interface

uses
  System.TypInfo,
  System.SysUtils,
  System.Generics.Collections,
  System.SyncObjs,
  System.Classes,
  WinApi.Windows,
  VSoft.CancellationToken,
  VSoft.HttpClient,
  VSoft.WinHttp.Api,
  VSoft.HttpClient.Response;


type
  THttpClient = class(TInterfacedObject, IHttpClient, IHttpClientInternal)
  private
    FSession : HINTERNET;
    FBaseUri : string;
    FUserAgent : string;
    FRequests : TList<TRequest>;
    FAuthTyp : THttpAuthType;
    FUserName : string;
    FPassword : string;
    FWaitEvent : TEvent;
    FCurrentRequest : TRequest;
    FResponse : IHttpResponseInternal;
    FReceiveBuffer : TBytes;
    FLastReceiveBlockSize : DWORD;
    FBytesWritten : DWORD;
    FClientError : DWORD;
    FUseHttp2 : boolean;
  protected
    procedure HTTPCallback(hInternet: HINTERNET; dwInternetStatus: DWORD; lpvStatusInformation: Pointer; dwStatusInformationLength: DWORD);

    procedure ReadHeaders(hRequest : HINTERNET);
    function ReadData(hRequest : HINTERNET; dataSize : DWORD) : boolean;

    function WriteData(hRequest : HINTERNET; position : DWORD) : boolean;


    function WriteHeaders(hRequest : HINTERNET; const headers : TStrings) : boolean;

    function ConfigureWinHttpRequest(hRequest : HINTERNET; const request : TRequest) : boolean;


    procedure EnsureSession;

    function GetBaseUri : string;
    procedure SetBaseUri(const value : string);
    function GetUserAgent : string;
    procedure SetUserAgent(const value : string);

    procedure SetAuthType(const value : THttpAuthType);
    function GetAuthType : THttpAuthType;
    function GetUserName : string;
    function GetPassword : string;
    procedure SetUserName(const value : string);
    procedure SetPassword(const value : string);

    function GetUseHttp2 : boolean;
    procedure SetUseHttp2(const value : boolean);


    function CreateRequest(const resource : string) : TRequest;

    procedure UseSerializer(const useFunc : TUseSerializerFunc);overload;
    procedure UseSerializer(const serializer : IRestSerializer);overload;


    function GetResourceFromRequest(const request : TRequest) : string;


    //IHttpClientInternal
    function Send(const request : TRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;overload;
    procedure ReleaseRequest(const request : TRequest);


  public
    constructor Create(const baseUri : string);
    destructor Destroy;override;
  end;


implementation

uses
  System.Math,
  System.StrUtils;

//TODO : What is the optimum buffer size?
const cReceiveBufferSize : DWORD = 32 * 1024;

type
  TRequestCracker = class(TRequest);


procedure _HTTPCallback(hInternet: HINTERNET; dwContext: Pointer; dwInternetStatus: DWORD; lpvStatusInformation: Pointer; dwStatusInformationLength: DWORD); stdcall;
var
  client : THttpClient;
begin
  client := THttpClient(dwContext);
  if client <> nil then
    client.HTTPCallback(hInternet, dwInternetStatus, lpvStatusInformation, dwStatusInformationLength);

end;

function THttpClient.CreateRequest(const resource: string): TRequest;
begin
  result := TRequest.Create(Self, resource);
  FRequests.Add(result); //track requests to ensure they get freed.
end;


{ THttpClient }

function THttpClient.ConfigureWinHttpRequest(hRequest: HINTERNET; const request: TRequest): boolean;
var
  option : DWORD;
begin
  result := WriteHeaders(hRequest, request.Headers);
  if not result then
    exit;

  //it's a rest client, we don't want to send cookies
  option := WINHTTP_DISABLE_COOKIES;
  result := WinHttpSetOption(hRequest, WINHTTP_OPTION_DISABLE_FEATURE, @option, sizeof(option));
  if not result then
    exit;
  if not request.FollowRedirects then
  begin
    option := WINHTTP_DISABLE_REDIRECTS;
    result := WinHttpSetOption(hRequest, WINHTTP_OPTION_DISABLE_FEATURE, @option, sizeof(option));
    if not result then
      exit;
  end;



end;

constructor THttpClient.Create(const baseUri : string);
begin
  FRequests := TList<TRequest>.Create;
  FBaseUri := baseUri;
  FUserAgent := 'VSoft.HttpClient';
  FWaitEvent := TEvent.Create(nil,false, false,'');
end;


destructor THttpClient.Destroy;
var
  i : integer;
begin
  FWaitEvent.SetEvent;
  FWaitEvent.Free;

  if FSession <> nil then
    WinHttpCloseHandle(FSession);
  if FRequests.Count > 0 then
  begin
    //reverse order as they remove themselves from the list.
    for i := FRequests.Count -1 downto 0 do
      FRequests[i].Free;
  end;
  FRequests.Free;
  inherited;
end;

procedure THttpClient.EnsureSession;
begin
  FSession := WinHttpOpen(PWideChar(FUserAgent), WINHTTP_ACCESS_TYPE_NO_PROXY, WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, WINHTTP_FLAG_ASYNC);
  if FSession = nil then
    RaiseLastOSError;
end;


function THttpClient.GetAuthType: THttpAuthType;
begin
  result := FAuthTyp;
end;

function THttpClient.GetBaseUri: string;
begin
  result := FBaseUri;
end;


function THttpClient.GetPassword: string;
begin
  result := FPassword;
end;

function THttpClient.GetResourceFromRequest(const request: TRequest): string;
var
  i : integer;
  queryString : string;
begin
  result := request.Resource;
  if request.HtttpMethod <> THttpMethod.GET then
      exit;

  //for get request, we use the parameters

  if request.UrlSegments.Count > 0 then
  begin
    for i := 0 to request.UrlSegments.Count -1 do
      result := StringReplace(result, '{' + request.UrlSegments.Names[i] + '}', request.UrlSegments.ValueFromIndex[i], [rfReplaceAll,rfIgnoreCase]);
  end;

  if request.Parameters.Count > 0 then
  begin
    for i := 0 to request.Parameters.Count -1 do
    begin
      if i = 0 then
        result := result + '?'
      else
        result := result + '&';
      result := result + request.Parameters.Names[i] + '=' + request.Parameters.ValueFromIndex[i];
    end;
  end;
end;

function THttpClient.GetUseHttp2: boolean;
begin
  result := FUseHttp2;
end;

function THttpClient.GetUserAgent: string;
begin
  result := FUserAgent;
end;

function THttpClient.GetUserName: string;
begin
  result := FUserName;
end;

procedure THttpClient.HTTPCallback(hInternet: HINTERNET; dwInternetStatus: DWORD; lpvStatusInformation: Pointer; dwStatusInformationLength: DWORD);
var
  dataSize : DWORD;
begin
  case dwInternetStatus of

    WINHTTP_CALLBACK_STATUS_REQUEST_ERROR :
    begin
       FClientError := PWinHttpAsyncResult(lpvStatusInformation)^.dwError;
       FWaitEvent.SetEvent;
    end;

    WINHTTP_CALLBACK_STATUS_HEADERS_AVAILABLE :
    begin
      ReadHeaders(hInternet);
      //this will cause a data available callback
      if not WinHttpQueryDataAvailable(hInternet, nil) then
      begin
        FClientError := GetLastError;
        FWaitEvent.SetEvent; //unblock
      end
    end;

    WINHTTP_CALLBACK_STATUS_DATA_AVAILABLE :
    begin
      dataSize := PDWORD(lpvStatusInformation)^;
      if dataSize = 0 then //all data read
      begin
        FResponse.FinalizeContent;
        FWaitEvent.SetEvent; //unblock
      end
      else
      begin
        if not ReadData(hInternet, dataSize) then
        begin
          FClientError := GetLastError;
          FWaitEvent.SetEvent; //unblock
        end;

      end;
    end;

    WINHTTP_CALLBACK_STATUS_READ_COMPLETE :
    begin
      FLastReceiveBlockSize := dwStatusInformationLength;
      //if we didn't receive any more data then we are done.
      if FLastReceiveBlockSize = 0 then
      begin
        FResponse.FinalizeContent;
        FWaitEvent.SetEvent;
        exit;
      end
      else
      begin
        FResponse.WriteBuffer(FReceiveBuffer, FLastReceiveBlockSize);
      end;

      //this will cause a data available callback
      if not WinHttpQueryDataAvailable(hInternet, nil) then
      begin
        FClientError := GetLastError;
        //cleanup.
        FWaitEvent.SetEvent; //unblock
      end
    end;

    WINHTTP_CALLBACK_STATUS_SENDREQUEST_COMPLETE :
    begin
      //write data here?
      if FBytesWritten < FCurrentRequest.ContentLength then
        if FCurrentRequest.HtttpMethod <> THttpMethod.GET then
        begin
          if not WriteData(hInternet, 0) then
          begin
            FClientError := GetLastError;
            FWaitEvent.SetEvent;
          end;
        end;

      if (WinHttpReceiveResponse( hInternet, nil) = false) then
      begin
        FClientError := GetLastError;
        //handle error?
        //cleanup.
        FWaitEvent.SetEvent; //unblock
      end;
    end;

    WINHTTP_CALLBACK_STATUS_WRITE_COMPLETE :
    begin
      dataSize := PDWORD(lpvStatusInformation)^;
      if dataSize = 0 then
        exit;
      Inc(FBytesWritten, dataSize);
      if FBytesWritten < FCurrentRequest.ContentLength then
      begin
        if not WriteData(hInternet, FBytesWritten) then
        begin
           FClientError := GetLastError;
           FWaitEvent.SetEvent; //unblock
           exit;
        end;
      end;

      if not WinHttpReceiveResponse( hInternet, nil) then
      begin
        FClientError := GetLastError;
        FWaitEvent.SetEvent; //unblock
      end;
    end;

    WINHTTP_CALLBACK_STATUS_RESPONSE_RECEIVED :
    begin
      //all done.
      FWaitEvent.SetEvent; //unblock
    end;

  end;




end;

function THttpClient.ReadData(hRequest: HINTERNET; dataSize : DWORD): boolean;
var
  bufferSize : DWORD;
begin
  bufferSize := Min(dataSize + 2, cReceiveBufferSize);
  ZeroMemory(@FReceiveBuffer[0], bufferSize);
  result := WinHttpReadData(hRequest, FReceiveBuffer[0], bufferSize , @FLastReceiveBlockSize);
end;

procedure THttpClient.ReadHeaders(hRequest: HINTERNET);
var
  bufferSize : DWORD;
  headers : string;
  statusCode : DWORD;
  statusCodeSize : DWORD;

begin
  statusCodeSize := Sizeof(DWORD);

  if WinHttpQueryHeaders(hRequest, WINHTTP_QUERY_STATUS_CODE + WINHTTP_QUERY_FLAG_NUMBER, WINHTTP_HEADER_NAME_BY_INDEX,　@statusCode, statusCodeSize, WINHTTP_NO_HEADER_INDEX) then
    FResponse.SetStatusCode(statusCode);

  if not WinHttpQueryHeaders(hRequest, WINHTTP_QUERY_RAW_HEADERS_CRLF, WINHTTP_HEADER_NAME_BY_INDEX, nil, bufferSize, WINHTTP_NO_HEADER_INDEX) then
  begin
    if GetLastError <> ERROR_INSUFFICIENT_BUFFER then
    begin
      FClientError := GetLastError;
      raise EHttpClientException.Create(ClientErrorToString(FClientError), FClientError);
    end;
  end;

  SetLength(headers, bufferSize div SizeOf(Char) - 1);

  if not WinHttpQueryHeaders(hRequest, WINHTTP_QUERY_RAW_HEADERS_CRLF, WINHTTP_HEADER_NAME_BY_INDEX, PChar(headers), bufferSize, WINHTTP_NO_HEADER_INDEX) then
  begin
    FClientError := GetLastError;
    raise EHttpClientException.Create(ClientErrorToString(FClientError), FClientError);
  end;
  FResponse.SetHeaders(headers)
end;

procedure THttpClient.ReleaseRequest(const request: TRequest);
begin
  FRequests.Remove(request);
end;


const http_version = 'HTTP/2';

const WAIT_OBJECT_1 = WAIT_OBJECT_0 + 1;

const tlsProtocols : DWORD =  WINHTTP_FLAG_SECURE_PROTOCOL_TLS1_2 + WINHTTP_FLAG_SECURE_PROTOCOL_TLS1_3;


//simple get/post etc.
function THttpClient.Send(const request: TRequest; const cancellationToken: ICancellationToken): IHttpResponse;
var
  urlComp : TURLComponents;
  host : string;
  bResult : boolean;
  hConnection : HINTERNET;
  hRequest : HINTERNET;
  dwOpenRequestFlags : DWORD;
  pCallBack : TWinHttpStatusCallback;
  waitHandles : array[0..1] of THandle;
  waitRes : integer;
  handleCount : integer;
  option : DWORD;
  method : string;
  dataLength : DWORD;

  data : Pointer;

  stream : TStream;
  buffer : TBytes;
  bufferSize : DWORD;

  sResource : string;

begin
  if FCurrentRequest <> nil then
    raise Exception.Create('A request is in progress.. winhttp is not reentrant!');
  try
    result := nil;
    FClientError := 0;
    FLastReceiveBlockSize := 0;
    FBytesWritten := 0;
    FCurrentRequest := request;
    EnsureSession;

    if not WinHttpSetOption(FSession, WINHTTP_OPTION_SECURE_PROTOCOLS, @tlsProtocols, sizeof(tlsProtocols)) then
    begin
      FClientError := GetLastError;
      raise EHttpClientException.Create(ClientErrorToString(FClientError), FClientError);
    end;


    SetLength(FReceiveBuffer, cReceiveBufferSize);

    ZeroMemory(@urlComp, SizeOf(urlComp));
    urlComp.dwStructSize := SizeOf(urlComp);

    urlComp.dwSchemeLength    := DWORD(-1);
    urlComp.dwHostNameLength  := DWORD(-1);
    urlComp.dwUrlPathLength   := DWORD(-1);
    urlComp.dwExtraInfoLength := DWORD(-1);

    if not WinHttpCrackUrl(PWideChar(FBaseUri), 0, 0, urlComp ) then
    begin
      FClientError := GetLastError;
      raise EHttpClientException.Create(ClientErrorToString(FClientError), FClientError);
    end;

    SetString(host, urlComp.lpszHostName, urlComp.dwHostNameLength);

    hConnection := WinHttpConnect(FSession, PWideChar(host), urlComp.nPort, 0);
    if hConnection = nil then
    begin
      FClientError := GetLastError;
      raise EHttpClientException.Create(ClientErrorToString(FClientError), FClientError);
    end;

    option := 0;
    if FUseHttp2 then
      option := WINHTTP_PROTOCOL_FLAG_HTTP2;

    if not WinHttpSetOption(hConnection,WINHTTP_OPTION_ENABLE_HTTP_PROTOCOL, @option, SizeOf(DWORD)) then
    begin
      FClientError := GetLastError;
      raise EHttpClientException.Create(ClientErrorToString(FClientError), FClientError);
    end;

    dwOpenRequestFlags := WINHTTP_FLAG_REFRESH;
    if urlComp.nScheme = INTERNET_SCHEME_HTTPS then
      dwOpenRequestFlags := dwOpenRequestFlags + WINHTTP_FLAG_SECURE;

    method := HttpMethodToString(request.HtttpMethod);

    sResource := GetResourceFromRequest(request);

    hRequest := WinHttpOpenRequest(hConnection, PWideChar(method), PWideChar(sResource), PWideChar(http_version),WINHTTP_NO_REFERER,WINHTTP_DEFAULT_ACCEPT_TYPES , dwOpenRequestFlags);
    if hRequest = nil then
    begin
      FClientError := GetLastError;
      raise EHttpClientException.Create(ClientErrorToString(FClientError), FClientError);
    end;
    try

      pCallback := WinHttpSetStatusCallback(hRequest, _HTTPCallback, WINHTTP_CALLBACK_FLAG_ALL_COMPLETIONS + WINHTTP_CALLBACK_FLAG_REDIRECT, 0);

      if Assigned(pCallBack) then
        raise Exception.Create('Callback was already set!');

      if not ConfigureWinHttpRequest(hRequest, request) then
        raise Exception.Create('Could not configure request : ' + SysErrorMessage(GetLastError) );

      handleCount := 1;
      waitHandles[0] := FWaitEvent.Handle;
      if cancellationToken <> nil then
      begin
         waitHandles[1] := cancellationToken.Handle;
         Inc(handleCount);
      end;

      dataLength := request.ContentLength;

      if (request.HtttpMethod <> THttpMethod.GET) and (dataLength > 0) then
      begin
        stream := TRequestCracker(FCurrentRequest).GetBody;
        bufferSize := TRequestCracker(FCurrentRequest).GetContentLength;
        SetLength(buffer,bufferSize);
        ZeroMemory(@buffer[0], bufferSize);
        stream.ReadBuffer(buffer,0 , bufferSize);
        data := @buffer[0];
        dataLength := dataLength;
        FBytesWritten := dataLength;
      end
      else
      begin
        data := WINHTTP_NO_REQUEST_DATA;
        dataLength := 0;
      end;

      FResponse := THttpResponse.Create(0,'','',request.SaveAsFile); //for now

      bResult := WinHttpSendRequest(hRequest,WINHTTP_NO_ADDITIONAL_HEADERS,0, data, dataLength, dataLength, NativeUInt(Pointer(Self)) );

      if not bResult then
        exit;

      waitRes := WaitForMultipleObjects(handleCount ,@waitHandles[0],false, INFINITE); //todo - add timeouts!
      case waitRes of
        WAIT_OBJECT_0 :
        begin
          //wait object triggered - need to check if an error occured
          //if all is ok, then return the response.
          if FClientError <> 0 then
          begin
            raise EHttpClientException.Create(ClientErrorToString(FClientError), FClientError);
            //raise exception?
          end;

          result := FResponse;
          FResponse := nil;
        end;
        WAIT_OBJECT_1 :
        begin
          //cancellation token triggered
            raise EHttpClientException.Create(ClientErrorToString(FClientError), FClientError);

          FResponse := nil;
          exit;
        end;
        WAIT_TIMEOUT :
        begin
          //timed out, clean up and return.
          raise EHttpClientException.Create(ClientErrorToString(ERROR_WINHTTP_TIMEOUT), ERROR_WINHTTP_TIMEOUT);
          FResponse := nil;
          exit;
        end;
      end;
    finally
      WinHttpCloseHandle(hRequest);
      WinHttpCloseHandle(hConnection);
    end;
  finally
    FCurrentRequest := nil;
    SetLength(FReceiveBuffer, 0);
  end;
end;


procedure THttpClient.SetAuthType(const value: THttpAuthType);
begin
  FAuthTyp := value;
end;

procedure THttpClient.SetBaseUri(const value: string);
begin
  FBaseUri := value;
end;

procedure THttpClient.SetPassword(const value: string);
begin
  FPassword := value;
end;

procedure THttpClient.SetUseHttp2(const value: boolean);
begin
  FUseHttp2 := value;
end;

procedure THttpClient.SetUserAgent(const value: string);
begin
  FUserAgent := value;
end;

procedure THttpClient.SetUserName(const value: string);
begin
  FUserName := value;
end;


procedure THttpClient.UseSerializer(const serializer: IRestSerializer);
begin
  raise ENotImplemented.Create('Serialization not implemented yet');
end;

procedure THttpClient.UseSerializer(const useFunc: TUseSerializerFunc);
begin
  raise ENotImplemented.Create('Serialization not implemented yet');
end;

function THttpClient.WriteData(hRequest: HINTERNET; position : DWORD): boolean;
var
  stream : TStream;
  buffer : TBytes;
  size : Int64;
  bufferSize : DWORD;
begin
  stream := TRequestCracker(FCurrentRequest).GetBody;
  size := TRequestCracker(FCurrentRequest).GetContentLength;

  size := size - position;

  bufferSize := Min(1024*1024, size);

  SetLength(buffer,bufferSize + 2);
  ZeroMemory(@buffer[0], bufferSize);
  stream.ReadBuffer(buffer, position, bufferSize);

  result := WinHttpWriteData(hRequest, buffer, bufferSize, nil);

end;

function THttpClient.WriteHeaders(hRequest: HINTERNET; const headers: TStrings): boolean;
var
  sHeaders : string;
  i: Integer;
  sCharSet : string;
begin
  if headers.Count = 0 then
    exit(true);

  sCharSet := TRequestCracker(FCurrentRequest).GetCharSet;

  for i := 0 to headers.Count -1 do
  begin
    if (headers.Names[i] = cContentTypeHeader) and (sCharSet <> '') then
      sHeaders := sHeaders + cContentTypeHeader + ': ' +headers.ValueFromIndex[i] + '; charset=' + sCharSet
    else
      sHeaders := sHeaders + headers.Names[i] + ': ' +headers.ValueFromIndex[i];

    if i < headers.count -1 then
      sHeaders := sHeaders + #13#10;
  end;

  result := WinHttpAddRequestHeaders(hRequest, PWideChar(sHeaders), $ffffffff, WINHTTP_ADDREQ_FLAG_ADD);
end;

end.
