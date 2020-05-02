{***************************************************************************}
{                                                                           }
{           VSoft.HttpClient - A wrapper over WinHttp                       }
{                              modelled on restSharp                        }
{                                                                           }
{           Copyright � 2020 Vincent Parrett and contributors               }
{                                                                           }
{           vincent@finalbuilder.com                                        }
{           https://www.finalbuilder.com                                    }
{                                                                           }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}

//We are using the com api at he moment, which has some limitations
//When time permits we'll re-implement this using the C api.

unit VSoft.HttpClient.WinHttpClient;

interface

uses
  Winapi.ActiveX,
  VSoft.CancellationToken,
  System.SyncObjs,
  VSoft.HttpClient.WinHttp,
  VSoft.HttpClient;


type
  TWinHttpOnError = procedure(ErrorNumber: Integer; const ErrorDescription: WideString) of object;
  TWinHttpOnResponseDataAvailable = procedure(var Data: PSafeArray) of object;
  TWinHttpOnResponseFinished = procedure of object;
  TWinHttpOnResponseStart = procedure (Status: Integer; const ContentType: WideString) of object;

  //https://docs.microsoft.com/en-us/windows/win32/winhttp/iwinhttprequestevents-interface
  //only really need the events if we are going to support async.
  //note we are using a separate object to avoid circular references
  TWinHttpEvents = class(TInterfacedObject, IWinHttpRequestEvents)
  private
    FOnError : TWinHttpOnError;
    FOnResponseDataAvailable : TWinHttpOnResponseDataAvailable;
    FOnResponseFinished :TWinHttpOnResponseFinished;
    FOnResponseStart : TWinHttpOnResponseStart;
  protected
    procedure OnError(ErrorNumber: Integer; const ErrorDescription: WideString); stdcall;
    procedure OnResponseDataAvailable(var Data: PSafeArray); stdcall;
    procedure OnResponseFinished; stdcall;
    procedure OnResponseStart(Status: Integer; const ContentType: WideString); stdcall;
  public
    constructor Create(const onError : TWinHttpOnError; const onResponseDataAvailable : TWinHttpOnResponseDataAvailable;
                       const onResponseFinished :TWinHttpOnResponseFinished; const onResponseStart : TWinHttpOnResponseStart);
  end;

  THttpClientWinHttp = class(TInterfacedObject, IHttpClient)
  private
    FWinHttpRequest: IWinHttpRequest;
    FWinHttpEvents : IWinHttpRequestEvents;
    FEventsId : integer;
    FWinHttpThreadId : Cardinal;

    FAuthType : THttpAuthType;
    FApiKeyHeaderName : string;
    FBaseUri : string;
    FPassword : string;
    FUserName : string;
    FOnProgress : THttpProgressEvent;

    //async support
    FWaitEvent : TEvent;
    FError : string;
    FErrorCode : integer;

  protected
    procedure ConnectEvents;
    procedure DisconnectEvents;
    procedure CreateWinHttpRequest;
    procedure DoOnError(ErrorNumber: Integer; const ErrorDescription: WideString);
    procedure DoOnResponseDataAvailable(var Data: PSafeArray);
    procedure DoOnResponseFinished;
    procedure DoOnResponseStart(Status: Integer; const ContentType: WideString);


    function GetApiKeyHeaderName: string;
    function GetAuthType: THttpAuthType;
    function GetBaseUri: string;
    function GetOnProgress: THttpProgressEvent;
    function GetPassword: string;
    function GetUserName: string;

    //actual calls
    function DoGet(const request : IHttpRequest; const cancellationToken : ICancellationToken) : IHttpResponse;
    function DoPost(const request : IHttpRequest; const cancellationToken : ICancellationToken) : IHttpResponse;
    function DoPut(const request : IHttpRequest; const cancellationToken : ICancellationToken) : IHttpResponse;
    function DoDelete(const request : IHttpRequest; const cancellationToken : ICancellationToken) : IHttpResponse;

    function UrlFromRequest(const request : IHttpRequest) : string;

    //sanity check
    function Send(const request : IHttpRequest; const cancellationToken : ICancellationToken) : IHttpResponse;

    //interface
    function Post(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;
    function Get(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;
    function Put(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;
    function Delete(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;


    procedure SetApiKeyHeaderName(const value: string);
    procedure SetAuthType(const value: THttpAuthType);
    procedure SetBaseUri(const value: string);
    procedure SetOnProgress(const value: THttpProgressEvent);
    procedure SetPassword(const value: string);
    procedure SetUserName(const value: string);
  public
    constructor Create(const baseUri : string);
    destructor Destroy;override;
  end;

implementation

uses
  System.StrUtils,
  System.VarUtils,
  WinApi.Windows,
  System.Classes,
  System.SysUtils,
  VSoft.HttpClient.Response;

const
  HTTP_METHOD : array[THttpMethod] of string = ('GET', 'POST', 'PUT', 'DELETE');


{ THttpClientWinInet }

function THttpClientWinHttp.Get(const request: IHttpRequest; const cancellationToken: ICancellationToken): IHttpResponse;
begin
  request.HttpMethod := THttpMethod.GET;
  result := Send(request, cancellationToken);
end;

function THttpClientWinHttp.Post(const request: IHttpRequest; const cancellationToken: ICancellationToken): IHttpResponse;
begin
  request.HttpMethod := THttpMethod.POST;
  result := Send(request, cancellationToken);
end;

function THttpClientWinHttp.Put(const request: IHttpRequest; const cancellationToken: ICancellationToken): IHttpResponse;
begin
  request.HttpMethod := THttpMethod.PUT;
  result := Send(request, cancellationToken);
end;

function THttpClientWinHttp.Send(const request: IHttpRequest; const cancellationToken: ICancellationToken): IHttpResponse;
var
  sUrl : string;
  i: Integer;
  async : boolean;
begin
  CreateWinHttpRequest;
  result := nil;
  sUrl := UrlFromRequest(request);

  //TODO : validate uri;
  if sUrl = '' then
    raise Exception.Create('Empty Uri');

  //if a cancellation token is passed in, we will use async mode.
  async := cancellationToken <> nil;
  FWinHttpRequest.Open(HTTP_METHOD[request.HttpMethod],sUrl, async );

  //apply headers
  for i := 0 to request.Headers.Count -1 do
  begin
    //TODO : check when valuefromindex was added > XE2?
    if (request.Headers.Names[i] = 'Content-Type') and (request.GetCharSet <> '') then
      FWinHttpRequest.SetRequestHeader('Content-Type', request.ContentType + '; charset=' + request.GetCharSet )
    else
      FWinHttpRequest.SetRequestHeader(request.Headers.Names[i], request.Headers.ValueFromIndex[i] );
  end;

  //if we set the header on the request then use that!
  if request.Authorization = '' then
  begin
    case FAuthType of
      THttpAuthType.None: ;
      THttpAuthType.Basic:
      begin
        //TODO : Add basic auth header

      end;
      THttpAuthType.ApiKey:
      begin
        if (FApiKeyHeaderName <> '') and (FPassword <> '')  then
          FWinHttpRequest.SetRequestHeader(FApiKeyHeaderName, FPassword );
      end;
      THttpAuthType.GitHubToken:
      begin
        FWinHttpRequest.SetRequestHeader('Authorization', 'Bearer ' + FPassword);
      end;
    end;
  end;

  case request.HttpMethod of
    THttpMethod.GET    : result := DoGet(request, cancellationToken);
    THttpMethod.POST   : result := DoPost(request, cancellationToken);
    THttpMethod.PUT    : result := DoPut(request, cancellationToken);
    THttpMethod.DELETE : result := DoDelete(request, cancellationToken);
  else
     raise Exception.Create('Not implemented!');
  end;
end;

procedure THttpClientWinHttp.ConnectEvents;
var
   connPointContainer : IConnectionPointContainer;
   connPoint: IConnectionPoint;
begin
  if (FWinHttpRequest = nil) or (FEventsId <> -1) then
    exit;
  if Supports(FWinHttpRequest, IConnectionPointContainer, connPointContainer) then
  begin
    if connPointContainer.FindConnectionPoint(IID_IWinHttpRequestEvents, connPoint) = S_OK then
      connPoint.Advise(FWinHttpEvents, FEventsId);
  end;

end;

constructor THttpClientWinHttp.Create(const baseUri: string);
begin
  FBaseUri := baseUri;
  FWinHttpRequest := nil;
  FWinHttpEvents := TWinHttpEvents.Create(DoOnError, DoOnResponseDataAvailable, DoOnResponseFinished, DoOnResponseStart);
  FEventsId := -1;
  FWaitEvent := TEvent.Create(nil,false, false,'');
end;

function THttpClientWinHttp.Delete(const request: IHttpRequest; const cancellationToken: ICancellationToken): IHttpResponse;
begin
  request.HttpMethod := THttpMethod.DELETE;
  result := Send(request, cancellationToken);
end;

destructor THttpClientWinHttp.Destroy;
begin
  FWaitEvent.SetEvent;
  FWaitEvent.Free;
  if FWinHttpRequest <> nil then
    DisconnectEvents;
  FWinHttpRequest := nil;
  inherited;
end;


procedure THttpClientWinHttp.DisconnectEvents;
var
   connPointContainer : IConnectionPointContainer;
   connPoint: IConnectionPoint;
begin
  if (FWinHttpRequest = nil) or (FEventsId = -1) then
    exit;
  if Supports(FWinHttpRequest, IConnectionPointContainer, connPointContainer) then
  begin
    if connPointContainer.FindConnectionPoint(IID_IWinHttpRequestEvents, connPoint) = S_OK then
    begin
      connPoint.Unadvise(FEventsId);
      FEventsId := -1;
    end;
  end;
end;

function THttpClientWinHttp.DoDelete(const request: IHttpRequest; const cancellationToken: ICancellationToken): IHttpResponse;
begin
  raise ENotImplemented.Create('Delete method not implemented');
end;

function THttpClientWinHttp.DoGet(const request : IHttpRequest; const cancellationToken : ICancellationToken): IHttpResponse;
var
  httpResult : integer;
  responseStream  : IStream;
  response : IHttpResponseInternal;
  waitHandles : array[0..1] of THandle;
  waitRes : integer;
begin
  result := nil;

  result := nil;
  FWinHttpRequest.Send(''); //no body.

  //if we have a cancellationToken then we are using async mode.
  if cancellationToken <> nil then
  begin
    waitHandles[0] := FWaitEvent.Handle;
    waitHandles[1] := cancellationToken.Handle;
    waitRes := WaitForMultipleObjects(2,@waitHandles[0],false, INFINITE); //todo - add timeouts!
    if waitRes <> WAIT_OBJECT_0 then
    begin
      //it wasn't the event being set, so it must have been the cancellation token.
      FWinHttpRequest.Abort;
      DisconnectEvents;
      exit;
    end;
  end;

  httpResult := FWinHttpRequest.Status;

  response := THttpResponse.Create(httpResult, FError,  FWinHttpRequest.GetAllResponseHeaders, request.SaveAsFile);
  result := response;

  if httpResult = HTTP_OK then
  begin
    responseStream := IUnknown(FWinHttpRequest.ResponseStream) as IStream;
    response.SetContent(responseStream);
  end;
end;

function THttpClientWinHttp.DoPost(const request : IHttpRequest; const cancellationToken : ICancellationToken): IHttpResponse;
var
  httpResult : integer;
  responseStream  : IStream;
  response : IHttpResponseInternal;
  waitHandles : array[0..1] of THandle;
  waitRes : integer;
  body : IStream;
begin
  result := nil;
  body := request.GetBody;
  //formdata can change the contentType
  if request.ContentType <> '' then
  begin
    if request.GetCharSet <> '' then
      FWinHttpRequest.SetRequestHeader('Content-Type', request.ContentType + '; charset=' + request.GetCharSet)
    else
      FWinHttpRequest.SetRequestHeader('Content-Type', request.ContentType);
  end;

  FWinHttpRequest.Send(body);

  //if we have a cancellationToken then we are using async mode.
  if cancellationToken <> nil then
  begin
    waitHandles[0] := FWaitEvent.Handle;
    waitHandles[1] := cancellationToken.Handle;
    waitRes := WaitForMultipleObjects(2,@waitHandles[0],false, INFINITE); //todo - add timeouts!
    if waitRes <> WAIT_OBJECT_0 then
    begin
      //it wasn't the event being set, so it must have been the cancellation token.
      FWinHttpRequest.Abort;
      DisconnectEvents;
      exit;
    end;
  end;

  httpResult := FWinHttpRequest.Status;
  FError := FWinHttpRequest.StatusText;
  response := THttpResponse.Create(httpResult, FError, FWinHttpRequest.GetAllResponseHeaders, request.SaveAsFile);
  result := response;

  if httpResult = HTTP_OK then
  begin
    responseStream := IUnknown(FWinHttpRequest.ResponseStream) as IStream;
    response.SetContent(responseStream);
  end;
end;


function THttpClientWinHttp.DoPut(const request: IHttpRequest; const cancellationToken: ICancellationToken): IHttpResponse;
begin
  result := DoPost(request,cancellationToken);
end;

procedure THttpClientWinHttp.DoOnError(ErrorNumber: Integer; const ErrorDescription: WideString);
begin
  FErrorCode := ErrorNumber;
  FError := ErrorDescription;
  FWaitEvent.SetEvent;
end;

procedure THttpClientWinHttp.DoOnResponseDataAvailable(var Data: PSafeArray);
begin

end;

procedure THttpClientWinHttp.DoOnResponseFinished;
begin
  FWaitEvent.SetEvent;
end;

procedure THttpClientWinHttp.DoOnResponseStart(Status: Integer; const ContentType: WideString);
begin

end;
procedure THttpClientWinHttp.CreateWinHttpRequest;
begin
  //winhttp is a com object and cannot be shared accross threads.
  if (FWinHttpRequest = nil) or (FWinHttpThreadId <> TThread.CurrentThread.ThreadID)  then
  begin
    if FWinHttpRequest <> nil then
      DisconnectEvents;
    FWinHttpRequest := CoWinHttpRequest.Create;
    FWinHttpThreadId := TThread.CurrentThread.ThreadID;
    ConnectEvents;
  end;
end;

function THttpClientWinHttp.GetApiKeyHeaderName: string;
begin
  result := FApiKeyHeaderName;
end;

function THttpClientWinHttp.GetAuthType: THttpAuthType;
begin
  result := FAuthType;
end;

function THttpClientWinHttp.GetBaseUri: string;
begin
  result := FBaseUri;
end;

function THttpClientWinHttp.GetOnProgress: THttpProgressEvent;
begin
  result := FOnProgress;
end;

function THttpClientWinHttp.GetPassword: string;
begin
  result := FPassword;
end;

function THttpClientWinHttp.GetUserName: string;
begin
  result := FUserName;
end;

procedure THttpClientWinHttp.SetApiKeyHeaderName(const value: string);
begin
  FApiKeyHeaderName := value;
end;

procedure THttpClientWinHttp.SetAuthType(const value: THttpAuthType);
begin
  FAuthType := value;
end;

procedure THttpClientWinHttp.SetBaseUri(const value: string);
begin
  //TODO : use VSoft.Uri to validate uri.
  FBaseUri := value;
end;

procedure THttpClientWinHttp.SetOnProgress(const value: THttpProgressEvent);
begin
  FOnProgress := value;
end;

procedure THttpClientWinHttp.SetPassword(const value: string);
begin
  FPassword := value;
end;

procedure THttpClientWinHttp.SetUserName(const value: string);
begin
  FUserName := value;
end;

function THttpClientWinHttp.UrlFromRequest(const request: IHttpRequest): string;
var
  i : integer;
  queryString : string;
begin
  result := FBaseUri;

  if (request.Resource <> '') and (request.Resource <> '/') then
  begin
    if not EndsText('/', result) then
      result := result + '/';
    result := result + request.Resource;
  end;

  if request.UrlSegments.Count > 0 then
  begin
    for i := 0 to request.UrlSegments.Count -1 do
      result := StringReplace(result, '{' + request.UrlSegments.Names[i] + '}', request.UrlSegments.ValueFromIndex[i], [rfReplaceAll,rfIgnoreCase]);
  end;

  queryString := request.QueryString;
  if queryString <> '' then
    result := result + '?' + queryString;
end;

{ TWinHttpEvents }

constructor TWinHttpEvents.Create(const onError: TWinHttpOnError; const onResponseDataAvailable: TWinHttpOnResponseDataAvailable; const onResponseFinished: TWinHttpOnResponseFinished; const onResponseStart: TWinHttpOnResponseStart);
begin
  FOnError := onError;
  FOnResponseDataAvailable := onResponseDataAvailable;
  FOnResponseFinished := onResponseFinished;
  FOnResponseStart := onResponseStart;
end;

procedure TWinHttpEvents.OnError(ErrorNumber: Integer; const ErrorDescription: WideString);
begin
  if Assigned(FOnError) then
    FOnError(ErrorNumber, ErrorDescription);
end;

procedure TWinHttpEvents.OnResponseDataAvailable(var Data: PSafeArray);
begin
  if Assigned(FOnResponseDataAvailable) then
    FOnResponseDataAvailable(Data);
end;

procedure TWinHttpEvents.OnResponseFinished;
begin
  if Assigned(FOnResponseFinished) then
    FOnResponseFinished;
end;

procedure TWinHttpEvents.OnResponseStart(Status: Integer; const ContentType: WideString);
begin
  if Assigned(FOnResponseStart) then
    FOnResponseStart(Status, ContentType);
end;

end.
