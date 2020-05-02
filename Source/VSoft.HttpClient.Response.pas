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

procedure THttpResponse.SetContent(const stream: IStream);
var
  adapter : IStream;
  bytesRead, bytesWritten : Int64;
begin
  adapter := TStreamAdapter.Create(FStream) as IStream;
  stream.CopyTo(adapter, High(Int64), bytesRead, bytesWritten);
  FStream.Position := 0;
end;

end.
