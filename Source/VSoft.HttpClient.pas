{***************************************************************************}
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

unit VSoft.HttpClient;

interface

uses
  WinApi.ActiveX,
  System.Classes,
  System.SysUtils,
  VSoft.CancellationToken;


{$SCOPEDENUMS ON}

const
  HTTP_OK = 200;
  HTTP_NOT_MODIFIED = 304;
  HTTP_NOT_FOUND = 404;
  //TODO : add other response types as we need.

type
  THttpAuthType = (None, Basic, ApiKey, GitHubToken);
  THttpMethod = (GET,POST, PUT, DELETE);

  THttpProgressEvent = procedure(const progress : Int64; const size : Int64) of object;

  IHttpRequest = interface
    function GetAccept : string;
    procedure SetAccept(const value : string);

    function GetAcceptCharSet : string;
    procedure SetAcceptCharSet(const value : string);

    function GetAcceptEncoding : string;
    procedure SetAcceptEncoding(const value : string);

    function GetAcceptLanguage : string;
    procedure SetAcceptLanguage(const value : string);

    function GetAuthorization : string;
    procedure SetAuthorization(const value : string);

    function GetContentType : string;
    procedure SetContentType(const value : string);


    function GetResource : string;
    procedure SetResource(const value : string);

    function GetQueryString : string;
    procedure SetQueryString(const value : string);

    function GetFiles : TStrings;
    procedure SetFiles(const value : TStrings);

    function GetHeaders : TStrings;
    procedure SetHeaders(const value : TStrings);

    function GetUrlSegments : TStrings;
    procedure SetUrlSegments(const value : TStrings);

    function GetUserAgent : string;
    procedure SetUserAgent(const value : string);

    function GetHttpMethod : THttpMethod;
    procedure SetHttpMethod(const value : THttpMethod);

    function GetSaveAsFile : string;
    procedure SetSaveAsFile(const value : string);

    function GetForceFormData : boolean;
    procedure SetForceFormData(const value : boolean);

    function GetBodyAsString : string;
    function GetCharSet : string;

    procedure SetBody(const body : TStream; const takeOwnership : boolean; const encoding : TEncoding = nil);overload;
    procedure SetBody(const body : string; const encoding : TEncoding = nil);overload;
    function GetBody : IStream;

    function AddHeader(const name : string; const value : string) : IHttpRequest;

    //borrowed from restsharp doco - we will replciate it's behaviour
    //This behaves differently based on the method. If you execute a GET call,
    //AddParameter will append the parameters to the querystring in the form url?name1=value1&name2=value2
    //On a POST or PUT Requests, it depends on whether or not you have files attached to a Request.
    //If not, the Parameters will be sent as the body of the request in the form name1=value1&name2=value2.
    //Also, the request will be sent as application/x-www-form-urlencoded.
    //In both cases, name and value will automatically be url-encoded.
    function AddParameter(const name : string; const value : string) : IHttpRequest;

    // If you have files, we will send a multipart/form-data request. Your parameters will be part of this request
    function AddFile(const filePath : string; const fieldName : string = ''; const contentType : string = '') : IHttpRequest;

    // Replaces {placeholder} values in the Resource
    function AddUrlSegement(const name : string; const value : string) : IHttpRequest;

    //clears params, headers, files
    procedure Reset;

    //common request headers
    property Accept : string read GetAccept write SetAccept;
    property AcceptEncoding : string read GetAcceptEncoding write setAcceptEncoding;
    property AcceptCharSet : string read GetAcceptCharSet write SetAcceptCharSet;
    property AcceptLanguage: string read GetAcceptLanguage write SetAcceptLanguage;
    property ContentType : string read GetContentType write SetContentType;
    property UserAgent : string read GetUserAgent write SetUserAgent;


    property Authorization : string read GetAuthorization write SetAuthorization;
    property Headers : TStrings read GetHeaders write SetHeaders;
    property Files : TStrings read GetFiles write SetFiles;
    property HttpMethod  : THttpMethod read GetHttpMethod write SetHttpMethod;
    property Resource : string read GetResource write SetResource;
    property QueryString : string read GetQueryString write SetQueryString;
    property UrlSegments : TStrings read GetUrlSegments write SetUrlSegments;
    //when set, will force post/put to use multipart formdata rather than urlencoded.
    property ForceFormData : boolean read GetForceFormData write SetForceFormData;
    //when set, the response will be written directly to the file, saving a copy operation
    property SaveAsFile : string read GetSaveAsFile write SetSaveAsFile;
  end;


  IHttpResponse = interface
  ['{CAF07179-6432-4AFA-8157-CC8DE8600EA9}']
    function GetContentType : string;
    function GetResponseStream : TStream;
    function GetResponse : string;
    function GetHttpResponseCode : integer;
    function GetHeaders : TStrings;
    function GetIsStringResponse : boolean;
    function GetFileName : string;
    function GetContentLength : Int64;
    function GetErrorMessage : string;

    //common Response headers
    property ContentType : string read GetContentType;
    property ContentLength : Int64 read GetContentLength;
    property ErrorMessage : string read GetErrorMessage;


    property ResponseStream : TStream read GetResponseStream;
    property Response : string read GetResponse;
    property ResponseCode : integer read GetHttpResponseCode;
    property Headers : TStrings read GetHeaders;
    //returns true if the contenttype indicates a textual response.
    property IsStringResponse : boolean read GetIsStringResponse;
  end;

  IHttpClient = interface
  ['{27ED69B0-7294-45F8-9DE8-DD0648B2EA80}']
    function GetAuthType : THttpAuthType;
    procedure SetAuthType(const value : THttpAuthType);
    function GetBaseUri : string;
    procedure SetBaseUri(const value : string);
    function GetUserName : string;
    procedure SetUserName(const value : string);
    function GetPassword : string;
    procedure SetPassword(const value : string);
    function GetApiKeyHeaderName : string;
    procedure SetApiKeyHeaderName(const value : string);
    function GetOnProgress : THttpProgressEvent;
    procedure SetOnProgress(const value : THttpProgressEvent);

    //Synchronous
    function Get(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;
    function Post(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse; //not implemented yet.
    function Put(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;
    function Delete(const request : IHttpRequest; const cancellationToken : ICancellationToken = nil) : IHttpResponse;


    property AuthType : THttpAuthType read GetAuthType write SetAuthType;
    property ApiKeyHeaderName : string read GetApiKeyHeaderName write SetApiKeyHeaderName;
    property BaseUri : string read GetBaseUri write SetBaseUri;
    property Password : string read GetPassword write SetPassword;
    property UserName : string read GetUserName write SetUserName;

    //do we really need this.. most requests will be quick, and done in a background thread.
    property OnProgress : THttpProgressEvent read GetOnProgress write SetOnProgress;
  end;

  THttpClientFactory = class
   class function CreateClient(const baseUri: string = ''): IHttpClient;
   class function CreateRequest(const resource: string = ''): IHttpRequest;
  end;

const
  cAcceptHeader = 'Accept';
  cAcceptCharsetHeader = 'Accept-Charset';
  cAcceptEncodingHeader = 'Accept-Encoding';
  cAcceptLanguageHeader = 'Accept-Language';
  sAuthorizationHeader = 'Authorization';
  cContentEncodingHeader = 'Content-Encoding';
  cContentLanguageHeader = 'Content-Language';
  cContentLengthHeader = 'Content-Length';
  cContentTypeHeader = 'Content-Type';
  cContentDispositionHeader = 'Content-Disposition';
  cLastModifiedHeader = 'Last-Modified';
  cUserAgentHeader = 'User-Agent';

implementation

uses
  VSoft.HttpClient.Request,
  VSoft.HttpClient.WinHttpClient;


{ THttpClientFactory }

class function THttpClientFactory.CreateClient(const baseUri: string): IHttpClient;
begin
  result := THttpClientWinHttp.Create(baseUri);
end;

class function THttpClientFactory.CreateRequest(const resource: string): IHttpRequest;
begin
  result := THttpRequest.Create(resource);
end;

end.
