﻿unit VSoft.HttpClient.WinHttpClient;

interface

uses
  System.TypInfo,
  System.SysUtils,
  System.SyncObjs,
  System.Classes,
  WinApi.Windows,
  VSoft.CancellationToken,
  VSoft.URI,
  VSoft.HttpClient,
  VSoft.WinHttp.Api,
  VSoft.HttpClient.Response;


type
  THttpClient = class(THttpClientBase, IHttpClient, IHttpClientInternal)
  private
    FUri : IUri;

    FSession : HINTERNET;
    FUserAgent : string;
    FAuthTyp : THttpAuthType;
    FUserName : string;
    FPassword : string;
    FProxyUserName : string;
    FProxyPassword : string;

    FWaitEvent : TEvent;
    FCurrentRequest : IHttpRequest;
    FResponse : IHttpResponseInternal;
    FReceiveBuffer : TBytes;
    FLastReceiveBlockSize : DWORD;
    FBytesWritten : DWORD;
    FClientError : DWORD;
    FUseHttp2 : boolean;
    FEnableTLS1_3 : boolean;
    FAllowSelfSignedCertificates : boolean;
    FLastStatusCode : DWORD;
    FProxyAuthScheme : DWORD;

    FData : Pointer;
    FDataLength : DWORD;


  protected
    procedure OnHTTPCallback(hInternet: HINTERNET; dwInternetStatus: DWORD; lpvStatusInformation: Pointer; dwStatusInformationLength: DWORD);
    function OnHeadersAvailable(hRequest: HINTERNET; dwInternetStatus: DWORD; lpvStatusInformation: Pointer; dwStatusInformationLength: DWORD) : DWORD;
    function HandleProxyAuthResponse(hRequest : HINTERNET) : DWORD;
    function HandleAccessDeniedResponse(hRequest : HINTERNET) : DWORD;
    function DoAuthentication(hRequest : HINTERNET; dwAuthenticationScheme : DWORD; dwAuthTarget : DWORD) : HRESULT;
    function ReadData(hRequest : HINTERNET; dataSize : DWORD) : boolean;

    function WriteData(hRequest : HINTERNET; position : DWORD) : boolean;
    function WriteHeaders(hRequest : HINTERNET; const headers : TStrings) : DWORD;

    function ConfigureWinHttpRequest(hRequest : HINTERNET; const request : IHttpRequest) : DWORD;

    function ChooseAuth(dwSupportedSchemes : DWORD) : DWORD;

    procedure EnsureSession;

    function GetAllowSelfSignedCertificates : boolean;
    procedure SetAllowSelfSignedCertificates(const value : boolean);

    function GetBaseUri : string;
    procedure SetBaseUri(const value : string);
    function GetUserAgent : string;
    procedure SetUserAgent(const value : string);
    function GetUri : IUri;

    procedure SetAuthType(const value : THttpAuthType);
    function GetAuthType : THttpAuthType;
    function GetUserName : string;
    function GetPassword : string;
    procedure SetUserName(const value : string);
    procedure SetPassword(const value : string);
    function GetProxyUserName : string;
    procedure SetProxyUserName(const value : string);

    function GetProxyPassword : string;
    procedure SetProxyPassword(const value : string);



    function GetUseHttp2 : boolean;
    procedure SetUseHttp2(const value : boolean);
    function GetEnableTLS1_3 : boolean;
    procedure SetEnableTLS1_3(const value : boolean);


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


    function GetResourceFromRequest(const request : IHttpRequest) : string;


    function Send(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;
    function Get(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;
    function Post(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;
    function Patch(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;
    function Put(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;
    function Delete(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;


  public
    constructor Create(const uri : IUri);
    destructor Destroy;override;
  end;


implementation

uses
  System.RTLConsts,
  System.Math,
  System.StrUtils,
  VSoft.HttpClient.Request;

//TODO : What is the optimum buffer size?
const cReceiveBufferSize : DWORD = 32 * 1024;

//const E_UNEXPECTED = HRESULT($8000FFFF);

//type
//  TRequestCracker = class(TRequest);


procedure _HTTPCallback(hInternet: HINTERNET; dwContext: Pointer; dwInternetStatus: DWORD; lpvStatusInformation: Pointer; dwStatusInformationLength: DWORD); stdcall;
var
  client : THttpClient;
begin
  client := THttpClient(dwContext);
  if client <> nil then
    client.OnHTTPCallback(hInternet, dwInternetStatus, lpvStatusInformation, dwStatusInformationLength);

end;

function THttpClient.CreateRequest(const resource: string): IHttpRequest;
begin
  if resource = '' then
    result := TRequest.Create(Self, FUri)
  else
    result := TRequest.Create(Self, resource);
end;

function THttpClient.CreateRequest(const uri: IUri): IHttpRequest;
begin
  result := TRequest.Create(Self, uri);
end;


{ THttpClient }

function THttpClient.ChooseAuth(dwSupportedSchemes: DWORD): DWORD;
begin
  result := 0; //none

  case FAuthTyp of
    None: exit;
    Basic:
    begin
      if dwSupportedSchemes and WINHTTP_AUTH_SCHEME_BASIC > 0 then
        exit(WINHTTP_AUTH_SCHEME_BASIC);
    end;
    THttpAuthType.NegotiateOrNtlm:
    begin
      if dwSupportedSchemes and WINHTTP_AUTH_SCHEME_NEGOTIATE > 0 then
        exit(WINHTTP_AUTH_SCHEME_NEGOTIATE);
      //fall back to ntlm if supported.
      if dwSupportedSchemes and WINHTTP_AUTH_SCHEME_NTLM > 0 then
        exit(WINHTTP_AUTH_SCHEME_NTLM);
    end;
  end;

  //TODO : can we log an error here?

//  if dwSupportedSchemes and WINHTTP_AUTH_SCHEME_NEGOTIATE > 0 then
//    exit(WINHTTP_AUTH_SCHEME_NEGOTIATE);
//  if dwSupportedSchemes and WINHTTP_AUTH_SCHEME_NTLM > 0 then
//    exit(WINHTTP_AUTH_SCHEME_NTLM);
//  if dwSupportedSchemes and WINHTTP_AUTH_SCHEME_PASSPORT > 0 then
//    exit(WINHTTP_AUTH_SCHEME_PASSPORT);
//  if dwSupportedSchemes and WINHTTP_AUTH_SCHEME_DIGEST > 0 then
//    exit(WINHTTP_AUTH_SCHEME_DIGEST);
//  if dwSupportedSchemes and WINHTTP_AUTH_SCHEME_BASIC > 0 then
//    exit(WINHTTP_AUTH_SCHEME_BASIC);
//
//  result := 0;

end;

function THttpClient.ConfigureWinHttpRequest(hRequest: HINTERNET; const request: IHttpRequest): DWORD;
var
  option : DWORD;
begin
  result := WriteHeaders(hRequest, request.Headers);
  if result <> S_OK then
    exit;

  //it's a rest client, we don't want to send cookies
  option := WINHTTP_DISABLE_COOKIES;
  if not WinHttpSetOption(hRequest, WINHTTP_OPTION_DISABLE_FEATURE, @option, sizeof(option)) then
    exit(GetLastError);

  if not request.FollowRedirects then
  begin
    option := WINHTTP_DISABLE_REDIRECTS;
    if not WinHttpSetOption(hRequest, WINHTTP_OPTION_DISABLE_FEATURE, @option, sizeof(option)) then
      exit(GetLastError);
  end;

  if FAllowSelfSignedCertificates then
  begin
    option := SECURITY_FLAG_IGNORE_UNKNOWN_CA +
              SECURITY_FLAG_IGNORE_CERT_WRONG_USAGE +
              SECURITY_FLAG_IGNORE_CERT_CN_INVALID +
              SECURITY_FLAG_IGNORE_CERT_DATE_INVALID;
    if not WinHttpSetOption(hRequest, WINHTTP_OPTION_SECURITY_FLAGS,@option,sizeof(option)) then
      result := GetLastError;
  end;
end;

constructor THttpClient.Create(const uri : IUri);
begin
  FUri := uri;
  FUserAgent := 'VSoft.HttpClient';
  FWaitEvent := TEvent.Create(nil,false, false,'');
  FEnableTLS1_3 := false;
end;



function THttpClient.Delete(const request: IHttpRequest; const cancellationToken: ICancellationToken): IHttpResponse;
begin
  request.HtttpMethod := THttpMethod.DELETE;
  result := Send(request, cancellationToken);
end;

destructor THttpClient.Destroy;
begin
  FWaitEvent.SetEvent;

  if FSession <> nil then
    WinHttpCloseHandle(FSession);
  FWaitEvent.Free;

  inherited;
end;

procedure THttpClient.EnsureSession;
begin
  FSession := WinHttpOpen(PWideChar(FUserAgent), WINHTTP_ACCESS_TYPE_NO_PROXY, WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, WINHTTP_FLAG_ASYNC);
  if FSession = nil then
    RaiseLastOSError;
end;


function THttpClient.Get(const request: IHttpRequest; const cancellationToken: ICancellationToken): IHttpResponse;
begin
  request.HtttpMethod := THttpMethod.GET;
  result := Send(request, cancellationToken);
end;

function THttpClient.GetAllowSelfSignedCertificates: boolean;
begin
  result := FAllowSelfSignedCertificates;
end;

function THttpClient.GetAuthType: THttpAuthType;
begin
  result := FAuthTyp;
end;

function THttpClient.GetBaseUri: string;
begin
  result := FUri.BaseUriString;
end;


function THttpClient.GetConnectionTimeout: integer;
begin
  result := FConnectionTimeout;
end;

function THttpClient.GetEnableTLS1_3: boolean;
begin
  result := FEnableTLS1_3;
end;

function THttpClient.GetPassword: string;
begin
  result := FPassword;
end;

function THttpClient.GetProxyPassword: string;
begin
  result := FProxyPassword;
end;

function THttpClient.GetProxyUserName: string;
begin
  result := FProxyUserName;
end;

function THttpClient.GetResourceFromRequest(const request: IHttpRequest): string;
var
  i : integer;
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

function THttpClient.GetResponseTimeout: integer;
begin
  result := FResponseTimeout;
end;

function THttpClient.GetSendTimeout: integer;
begin
  result := FSendTimeout;
end;

function THttpClient.GetUri: IUri;
begin
  result := FUri;
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

function THttpClient.DoAuthentication(hRequest : HINTERNET; dwAuthenticationScheme : DWORD; dwAuthTarget : DWORD) : HRESULT;
begin
  result := ERROR_WINHTTP_LOGIN_FAILURE;
  case dwAuthTarget  of
    WINHTTP_AUTH_TARGET_SERVER :
    begin
      if FUserName <> '' then
      begin
        if not WinHttpSetCredentials(hRequest, dwAuthTarget, dwAuthenticationScheme, PChar(FUserName), PChar(FPassword),nil) then
          result := S_OK
        else
          result := GetLastError;
      end;

    end;
    WINHTTP_AUTH_TARGET_PROXY :
    begin
      if FProxyUserName <> '' then
      begin
        if WinHttpSetCredentials(hRequest, dwAuthTarget, dwAuthenticationScheme, PChar(FProxyUserName), PChar(FProxyPassword),nil) then
          result := S_OK
        else
          result := GetLastError;
      end;

    end;
  else
    result := E_UNEXPECTED;
  end;
end;

function THttpClient.HandleAccessDeniedResponse(hRequest : HINTERNET): DWORD;
var
  dwSupportedSchemes  : DWORD;
  dwFirstScheme       : DWORD;
  dwAuthTarget        : DWORD;
  dwAuthenticationScheme : DWORD;
begin
  //fail if we get the same response code again
  if FLastStatusCode = HTTP_STATUS_DENIED then
    exit(ERROR_WINHTTP_LOGIN_FAILURE);

  if not WinHttpQueryAuthSchemes(hRequest, dwSupportedSchemes, dwFirstScheme, dwAuthTarget) then
    exit(GetLastError);

  dwAuthenticationScheme := ChooseAuth(dwSupportedSchemes);
  if dwAuthenticationScheme = 0 then  //no supported scheme so we have no way to authenticate.
    exit(ERROR_WINHTTP_LOGIN_FAILURE);

  result := DoAuthentication(hRequest, dwAuthenticationScheme, dwAuthTarget);
  if result <> S_OK then
    exit;

  //Resend the Proxy authentication details also if used before, otherwise we could end up in a 407-401-407-401 loop
  if FProxyAuthScheme <> 0 then
  begin
    result := DoAuthentication(hRequest, dwAuthenticationScheme, WINHTTP_AUTH_TARGET_PROXY);
    if result <> S_OK then
      exit;
  end;

  FLastStatusCode := HTTP_STATUS_DENIED;

  //need to send the request again
  //not sure if we need to configure the headers again?
  ConfigureWinHttpRequest(hRequest, FCurrentRequest);
  if not WinHttpSendRequest(hRequest,WINHTTP_NO_ADDITIONAL_HEADERS,0, FData, FDataLength, FDataLength, NativeUInt(Pointer(Self))) then
    result := GetLastError
  else
    result := S_OK;

end;

function THttpClient.HandleProxyAuthResponse(hRequest : HINTERNET): DWORD;
var
  dwSupportedSchemes  : DWORD;
  dwFirstScheme       : DWORD;
  dwAuthTarget        : DWORD;
begin
  //fail if we get the same response code again
  if FLastStatusCode = HTTP_STATUS_PROXY_AUTH_REQ then
    exit(ERROR_WINHTTP_LOGIN_FAILURE);

  if not WinHttpQueryAuthSchemes(hRequest, dwSupportedSchemes, dwFirstScheme, dwAuthTarget) then
    exit(GetLastError);

  FProxyAuthScheme := ChooseAuth(dwSupportedSchemes);
  if FProxyAuthScheme = 0 then  //no supported scheme so we have no way to authenticate.
    exit(ERROR_WINHTTP_LOGIN_FAILURE);

  result := DoAuthentication(hRequest, FProxyAuthScheme, dwAuthTarget);
  if result <> S_OK then
    exit;

  FLastStatusCode := HTTP_STATUS_PROXY_AUTH_REQ;

  //need to send the request again
  //not sure if we need to configure the headers again?
  ConfigureWinHttpRequest(hRequest, FCurrentRequest);
  if not WinHttpSendRequest(hRequest,WINHTTP_NO_ADDITIONAL_HEADERS,0, FData, FDataLength, FDataLength, NativeUInt(Pointer(Self))) then
    result := GetLastError
  else
    result := S_OK;


end;

function QueryStatusCode(hRequest: HINTERNET; var statusCode : DWORD) : DWORD;
var
  statusCodeSize : DWORD;
begin
  statusCodeSize := Sizeof(DWORD);
  result := S_OK;
  if not WinHttpQueryHeaders(hRequest, WINHTTP_QUERY_STATUS_CODE + WINHTTP_QUERY_FLAG_NUMBER, WINHTTP_HEADER_NAME_BY_INDEX, @statusCode, statusCodeSize, WINHTTP_NO_HEADER_INDEX) then
    result := GetLastError;
end;

function THttpClient.OnHeadersAvailable(hRequest : HINTERNET;  dwInternetStatus: DWORD; lpvStatusInformation: Pointer;  dwStatusInformationLength: DWORD) : DWORD;
var
  statusCode : DWORD;
  bufferSize : DWORD;
  headers : string;
  lastError : DWORD;
begin
  result := QueryStatusCode(hRequest, statusCode);
  if result <> S_OK then
    exit;
  FLastStatusCode := statusCode;
  FResponse.SetStatusCode(statusCode);
  if statusCode = HTTP_STATUS_PROXY_AUTH_REQ then
    HandleProxyAuthResponse(hRequest)
  else if statusCode = HTTP_STATUS_DENIED then
    HandleAccessDeniedResponse(hRequest);
//  else if ((statusCode div 100) <> 2) then //any 2xx is good
//    exit(ERROR_WINHTTP_INVALID_HEADER);

  FLastStatusCode := statusCode;


  if not WinHttpQueryHeaders(hRequest, WINHTTP_QUERY_RAW_HEADERS_CRLF, WINHTTP_HEADER_NAME_BY_INDEX, nil, bufferSize, WINHTTP_NO_HEADER_INDEX) then
  begin
    lastError := GetLastError;
    if lastError <> ERROR_INSUFFICIENT_BUFFER then
      Exit(lastError);
  end;

  SetLength(headers, bufferSize div SizeOf(Char) - 1);

  if not WinHttpQueryHeaders(hRequest, WINHTTP_QUERY_RAW_HEADERS_CRLF, WINHTTP_HEADER_NAME_BY_INDEX, PChar(headers), bufferSize, WINHTTP_NO_HEADER_INDEX) then
    Exit(GetLastError);

  FResponse.SetHeaders(headers);

  //this will cause a data available callback
  if not WinHttpQueryDataAvailable(hRequest, nil) then
    exit(GetLastError);
end;

procedure THttpClient.OnHTTPCallback(hInternet: HINTERNET; dwInternetStatus: DWORD; lpvStatusInformation: Pointer; dwStatusInformationLength: DWORD);
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
      FClientError := OnHeadersAvailable(hInternet, dwInternetStatus, lpvStatusInformation, dwStatusInformationLength);
      if FClientError <> S_OK then
        FWaitEvent.SetEvent; //unblock
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

function THttpClient.Patch(const request: IHttpRequest; const cancellationToken: ICancellationToken): IHttpResponse;
begin
  request.HtttpMethod := THttpMethod.PATCH;
  result := Send(request, cancellationToken);
end;

function THttpClient.Post(const request: IHttpRequest; const cancellationToken: ICancellationToken): IHttpResponse;
begin
  request.HtttpMethod := THttpMethod.POST;
  result := Send(request, cancellationToken);
end;

function THttpClient.Put(const request: IHttpRequest; const cancellationToken: ICancellationToken): IHttpResponse;
begin
  request.HtttpMethod := THttpMethod.PUT;
  result := Send(request, cancellationToken);
end;

function THttpClient.ReadData(hRequest: HINTERNET; dataSize : DWORD): boolean;
//var
//  bufferSize : DWORD;
begin
//  bufferSize := Min(dataSize + 2, cReceiveBufferSize);
  ZeroMemory(@FReceiveBuffer[0], cReceiveBufferSize);
  result := WinHttpReadData(hRequest, FReceiveBuffer[0], cReceiveBufferSize , @FLastReceiveBlockSize);
end;


const http_version = 'HTTP/2';

const WAIT_OBJECT_1 = WAIT_OBJECT_0 + 1;



//simple get/post etc.
function THttpClient.Send(const request: IHttpRequest; const cancellationToken: ICancellationToken): IHttpResponse;
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

  stream : TStream;
  buffer : TBytes;
  bufferSize : DWORD;

  sResource : string;
  hr : DWORD;
  tlsProtocols : DWORD;


begin
  if FCurrentRequest <> nil then
    raise Exception.Create('A request is in progress.. winhttp is not reentrant!');
  try
    result := nil;
    FClientError := 0;
    FLastStatusCode := 0;
    FProxyAuthScheme := 0;
    FLastReceiveBlockSize := 0;
    FBytesWritten := 0;
    FCurrentRequest := request;
    EnsureSession;
    tlsProtocols := WINHTTP_FLAG_SECURE_PROTOCOL_TLS1_2;
    if FEnableTLS1_3 then
      tlsProtocols := tlsProtocols + WINHTTP_FLAG_SECURE_PROTOCOL_TLS1_3;

    if not WinHttpSetOption(FSession, WINHTTP_OPTION_SECURE_PROTOCOLS, @tlsProtocols, sizeof(tlsProtocols)) then
    begin
      FClientError := GetLastError;
      raise EHttpClientException.Create(ClientErrorToString('Error setting secure protocol options',FClientError), FClientError);
    end;


    SetLength(FReceiveBuffer, cReceiveBufferSize);

    ZeroMemory(@urlComp, SizeOf(urlComp));
    urlComp.dwStructSize := SizeOf(urlComp);

    urlComp.dwSchemeLength    := DWORD(-1);
    urlComp.dwHostNameLength  := DWORD(-1);
    urlComp.dwUrlPathLength   := DWORD(-1);
    urlComp.dwExtraInfoLength := DWORD(-1);

    if not WinHttpCrackUrl(PWideChar(FUri.BaseUriString), 0, 0, urlComp ) then
    begin
      FClientError := GetLastError;
      raise EHttpClientException.Create(ClientErrorToString('Error parsing Uri', FClientError), FClientError);
    end;

    SetString(host, urlComp.lpszHostName, urlComp.dwHostNameLength);

    hConnection := WinHttpConnect(FSession, PWideChar(host), urlComp.nPort, 0);
    if hConnection = nil then
    begin
      FClientError := GetLastError;
      raise EHttpClientException.Create(ClientErrorToString('Error connecting', FClientError), FClientError);
    end;

    option := 0;
    if FUseHttp2 then
      option := WINHTTP_PROTOCOL_FLAG_HTTP2;

    if not WinHttpSetOption(hConnection,WINHTTP_OPTION_ENABLE_HTTP_PROTOCOL, @option, SizeOf(DWORD)) then
    begin
      FClientError := GetLastError;
      raise EHttpClientException.Create(ClientErrorToString('Error setting http options', FClientError), FClientError);
    end;

    dwOpenRequestFlags := WINHTTP_FLAG_REFRESH + WINHTTP_FLAG_ESCAPE_PERCENT;
    if urlComp.nScheme = INTERNET_SCHEME_HTTPS then
      dwOpenRequestFlags := dwOpenRequestFlags + WINHTTP_FLAG_SECURE;

    method := HttpMethodToString(request.HtttpMethod);

    sResource := GetResourceFromRequest(request);

    hRequest := WinHttpOpenRequest(hConnection, PWideChar(method), PWideChar(sResource), PWideChar(http_version),WINHTTP_NO_REFERER,WINHTTP_DEFAULT_ACCEPT_TYPES , dwOpenRequestFlags);
    if hRequest = nil then
    begin
      FClientError := GetLastError;
      raise EHttpClientException.Create(ClientErrorToString('Error opening request', FClientError), FClientError);
    end;

    if WinHttpSetTimeouts(hRequest, request.ConnectionTimeout, request.ConnectionTimeout, request.SendTimeout, request.ResponseTimeout) = False then
      raise EHttpClientException.Create(SysErrorMessage(GetLastError), GetLastError);


    //set timeouts on the request.

    try
      pCallback := WinHttpSetStatusCallback(hRequest, _HTTPCallback, WINHTTP_CALLBACK_FLAG_ALL_COMPLETIONS + WINHTTP_CALLBACK_FLAG_REDIRECT, 0);

      if Assigned(pCallBack) then
        raise Exception.Create('Callback was already set!');

      FDataLength := request.ContentLength;    //need to do this before configurerequest as if there are files it will set the content type.

      hr := ConfigureWinHttpRequest(hRequest, request);
      if hr <> S_OK then
        raise Exception.Create('Could not configure request : ' + SysErrorMessage(GetLastError) );

      handleCount := 1;
      waitHandles[0] := FWaitEvent.Handle;
      if cancellationToken <> nil then
      begin
         waitHandles[1] := cancellationToken.Handle;
         Inc(handleCount);
      end;


      if (request.HtttpMethod <> THttpMethod.GET) and (FDataLength > 0) then
      begin
        stream := FCurrentRequest.GetBody;
        bufferSize := FCurrentRequest.GetContentLength;
        SetLength(buffer,bufferSize);
        ZeroMemory(@buffer[0], bufferSize);
        {$IF CompilerVersion > 25.0} //XE5+
        stream.ReadBuffer(buffer,0 , bufferSize);
        {$ELSE}
        stream.ReadBuffer(buffer, bufferSize);
        {$IFEND}
        FData := @buffer[0];
        FBytesWritten := FDataLength;
      end
      else
      begin
        FData := WINHTTP_NO_REQUEST_DATA;
        FDataLength := 0;
      end;

      FResponse := THttpResponse.Create(0,'','',request.SaveAsFile); //for now

      bResult := WinHttpSendRequest(hRequest,WINHTTP_NO_ADDITIONAL_HEADERS,0, FData, FDataLength, FDataLength, NativeUInt(Pointer(Self)) );

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
            raise EHttpClientException.Create(ClientErrorToString('',FClientError), FClientError);
            //raise exception?
          end;

          result := FResponse;
          FResponse := nil;
        end;
        WAIT_OBJECT_1 :
        begin
          //cancellation token triggered
            raise EHttpClientException.Create(ClientErrorToString('',FClientError), FClientError);

          FResponse := nil;
          exit;
        end;
        WAIT_TIMEOUT :
        begin
          //timed out, clean up and return.
          raise EHttpClientException.Create(ClientErrorToString('Timed out',ERROR_WINHTTP_TIMEOUT), ERROR_WINHTTP_TIMEOUT);
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



procedure THttpClient.SetAllowSelfSignedCertificates(const value: boolean);
begin
  FAllowSelfSignedCertificates := value;
end;

procedure THttpClient.SetAuthType(const value: THttpAuthType);
begin
  FAuthTyp := value;
end;

procedure THttpClient.SetBaseUri(const value: string);
begin
  FUri.BaseUriString := value;
end;

procedure THttpClient.SetConnectionTimeout(const value: integer);
begin
  FConnectionTimeout := value;
end;

procedure THttpClient.SetEnableTLS1_3(const value: boolean);
begin
  FEnableTLS1_3 := false;
end;

procedure THttpClient.SetPassword(const value: string);
begin
  FPassword := value;
end;

procedure THttpClient.SetProxyPassword(const value: string);
begin
  FProxyPassword := value;
end;

procedure THttpClient.SetProxyUserName(const value: string);
begin
  FProxyUserName := value;
end;

procedure THttpClient.SetResponseTimeout(const value: integer);
begin
  FResponseTimeout := value;
end;

procedure THttpClient.SetSendTimeout(const value: integer);
begin
  FSendTimeout := value;
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

function StreamReadBuffer(const stream : TStream; var Buffer: TBytes; Offset, Count: integer) : integer;
var
  LTotalCount,
  LReadCount: integer;
begin
  { Perform a read directly. Most of the time this will succeed
    without the need to go into the WHILE loop. }
  stream.Seek(Offset, soFromBeginning);
  LTotalCount := Stream.Read(Buffer, Count);
  { Check if there was an error }
  if LTotalCount < 0 then
    raise EReadError.CreateRes(@SReadError) at ReturnAddress;;

  while (LTotalCount < Count) do
  begin
    { Try to read a contiguous block of <Count> size }
    LReadCount := StreamReadBuffer(stream, Buffer, Offset + LTotalCount, (Count - LTotalCount));

    { Check if we read something and decrease the number of bytes left to read }
    if LReadCount <= 0 then
      raise EReadError.CreateRes(@SReadError) at ReturnAddress
    else
      Inc(LTotalCount, LReadCount);
  end;
  result := LTotalCount;
end;


function THttpClient.WriteData(hRequest: HINTERNET; position : DWORD): boolean;
var
  stream : TStream;
  buffer : TBytes;
  size : Int64;
  bufferSize : DWORD;
begin
  stream := FCurrentRequest.GetBody;
  size := FCurrentRequest.GetContentLength;

  size := size - position;

  bufferSize := Min(1024*1024, size);

  SetLength(buffer,bufferSize + 2);
  ZeroMemory(@buffer[0], bufferSize);

  streamReadBuffer(stream, buffer, position, bufferSize);

  result := WinHttpWriteData(hRequest, buffer, bufferSize, nil);

end;

function THttpClient.WriteHeaders(hRequest: HINTERNET; const headers: TStrings): DWORD;
var
  sHeaders : string;
  i: Integer;
  sCharSet : string;
begin
  result := S_OK;
  if headers.Count = 0 then
    exit;

  sCharSet := FCurrentRequest.GetCharSet;

  for i := 0 to headers.Count -1 do
  begin
    if (headers.Names[i] = cContentTypeHeader) and (sCharSet <> '') then
      sHeaders := sHeaders + cContentTypeHeader + ': ' +headers.ValueFromIndex[i] + '; charset=' + sCharSet
    else
      sHeaders := sHeaders + headers.Names[i] + ': ' +headers.ValueFromIndex[i];
    sHeaders := sHeaders + #13#10;
  end;

  if not WinHttpAddRequestHeaders(hRequest, PWideChar(sHeaders), $ffffffff, WINHTTP_ADDREQ_FLAG_ADD) then
    result := GetLastError;
end;

end.
