﻿{***************************************************************************}
{                                                                           }
{           VSoft.HttpClient - A wrapper over WinHttp                       }
{                              modelled on restSharp                        }
{                                                                           }
{           Copyright © 2020 Vincent Parrett and contributors               }
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

unit VSoft.HttpClient.Response;

interface

uses
  WinApi.ActiveX,
  System.Classes,
  VSoft.HttpClient;

type
  IHttpResponseInternal = interface(IHttpResponse)
  ['{CD23F38C-69E8-40F5-99B6-6308B57C2F34}']
    procedure SetContent(const stream : IStream);
  end;

  THttpResponse = class(TInterfacedObject, IHttpResponse, IHttpResponseInternal)
  private
    FHeaders : TStringList;
    FStream : TStream;
    FHttpResult : integer;
    FFileName : string;
    FErrorMessage : string;
  protected
    function GetContentType: string;
    function GetHeaders: TStrings;
    function GetHttpResponseCode: Integer;
    function GetIsStringResponse: Boolean;
    function GetResponse: string;
    function GetResponseStream: TStream;
    function GetFileName : string;
    function GetContentLength: Int64;
    procedure SetContent(const stream: IStream);
    function GetErrorMessage: string;
    function HttpResultString : string;
    function IsSuccess : boolean;
  public
    constructor Create(const httpResult : integer; const errorMsg : string; const headers : string; const fileName : string);
    destructor Destroy;override;
  end;


implementation

uses
  System.SysUtils;

{ THttpResponse }

constructor THttpResponse.Create(const httpResult: integer; const errorMsg : string; const headers : string; const fileName : string);
var
  i: Integer;
begin
  FHttpResult := httpResult;
  FErrorMessage := errorMsg;
  if not IsSuccess and (FErrorMessage = '') then
    FErrorMessage := HttpResultString;

  FHeaders := TStringList.Create;
  FHeaders.Text := headers;
  for i := 0 to FHeaders.Count -1 do
  begin
    FHeaders[i] := StringReplace(FHeaders[i], ':', '=',[]);
    FHeaders[i] := Trim(FHeaders.Names[i]) + '=' + Trim(FHeaders.ValueFromIndex[i]);
  end;


  if fileName <> '' then
    FStream := TFileStream.Create(fileName, fmCreate)
  else
    FStream := TMemoryStream.Create;


end;

destructor THttpResponse.Destroy;
begin
  FStream.Free;
  inherited;
end;

function THttpResponse.GetContentLength: Int64;
begin
  result := FStream.Size; //or should we use the header.
end;

function THttpResponse.GetContentType: string;
begin
  result := FHeaders.Values['Content-Type'];
end;

function THttpResponse.GetErrorMessage: string;
begin
  result := FErrorMessage;
end;

function THttpResponse.GetFileName: string;
begin
  result := FFileName;
end;

function THttpResponse.GetHeaders: TStrings;
begin
  result := FHeaders;
end;

function THttpResponse.GetHttpResponseCode: Integer;
begin
  result := FHttpResult;
end;

function THttpResponse.GetIsStringResponse: Boolean;
begin
  result := FFileName = ''; //TODO : use content-type too
end;

function THttpResponse.GetResponse: string;
var
  textStream : TStringStream;
begin
  if GetIsStringResponse then
  begin
    textStream := TStringStream.Create('', TEncoding.UTF8);
    try
      FStream.Seek(0,soBeginning);
      textStream.CopyFrom(FStream,FStream.Size);
      result := textStream.DataString;
    finally
      textStream.Free;
    end;
  end
  else
    result := ''; //should we raise instead.
end;

function THttpResponse.GetResponseStream: TStream;
begin
  result := FStream;
end;

function THttpResponse.HttpResultString: string;
begin
  case FHttpResult of
    100 : result := 'Continue';
    101 : result := 'Switching Protocols';
    200 : result := 'OK';
    201 : result := 'Created';
    202 : result := 'Accepted';
    203 : result := 'Non-Authoritative Information';
    204 : result := 'No Content';
    205 : result := 'Reset Content';
    206 : result := 'Partial Content';
    300 : result := 'Multiple Choices';
    301 : result := 'Moved Permanently';
    302 : result := 'Moved Temporarily';
    303 : result := 'See Other';
    304 : result := 'Not Modified';
    305 : result := 'Use Proxy';
    400 : result := 'Bad Request';
    401 : result := 'Unauthorized';
    402 : result := 'Payment Required';
    403 : result := 'Forbidden';
    404 : result := 'Not Found';
    405 : result := 'Method Not Allowed';
    406 : result := 'Not Acceptable';
    407 : result := 'Proxy Authentication Required';
    408 : result := 'Request Time-out';
    409 : result := 'Conflict';
    410 : result := 'Gone';
    411 : result := 'Length Required';
    412 : result := 'Precondition Failed';
    413 : result := 'Request Entity Too Large';
    414 : result := 'Request-URI Too Large';
    415 : result := 'Unsupported Media Type';
    416 : result := 'Range Not Satisfiaable';
    417 : result := 'Expectation Failed';
    418 : result := 'I''m a teapot';
    422 : result := 'Unprocessable Entity';
    425 : result := 'Too Early';
    426 : result := 'Upgrade Required';
    429 : result := 'Too Many Requests';
    431 : result := 'Request Header Fields Too Large';
    451 : result := 'Unavailable for Legal Reasons';
    500 : result := 'Internal Server Error';
    501 : result := 'Not Implemented';
    502 : result := 'Bad Gateway';
    503 : result := 'Service Unavailable';
    504 : result := 'Gateway Time-out';
    505 : result := 'HTTP Version not supported';
    506 : result := 'Variant Also Negotiates';
    507 : result := 'Insuffcient Storage';
    508 : result := 'Loop Detected';
    510 : result := 'Not Extended';
    511 : result := 'Network Authentication Required';
  else
  begin
    result := 'Unknown error.'
  end;
 end;
end;

function THttpResponse.IsSuccess: boolean;
begin
  result := FHttpResult = 200;
end;

procedure THttpResponse.SetContent(const stream: IStream);
var
  adapter : IStream;
  {$IF CompilerVersion >= 29.0}
  bytesRead, bytesWritten : UInt64;
  {$ELSE}
  bytesRead, bytesWritten : Int64;
  {$IFEND}
begin
  if stream = nil then
    exit;
  adapter := TStreamAdapter.Create(FStream) as IStream;
  {$IF CompilerVersion >= 29.0}
  stream.CopyTo(adapter, High(UInt64), bytesRead, bytesWritten);
  {$ELSE}
  stream.CopyTo(adapter, High(Int64), bytesRead, bytesWritten);
  {$IFEND}
  FStream.Position := 0;
end;

end.
