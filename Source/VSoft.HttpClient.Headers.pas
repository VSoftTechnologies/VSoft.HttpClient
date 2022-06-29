unit VSoft.HttpClient.Headers;


interface

uses
  VSoft.HttpClient;

type
  TContentDisposition = class(TInterfacedObject, IContentDisposition)
  private
    FDisposition : string;
    FFileName   : string;
  protected
    function GetDispositionType: string;
    function GetFileName: string;
  public
    constructor Create(const headerValue : string);
  end;



implementation

uses
  System.Classes;

{ TContentDisposition }

constructor TContentDisposition.Create(const headerValue: string);
var
  sl : TStringList;
begin
//attachment; filename=vsoft.weakreference-11.0-win32-0.1.1.dpkg; filename*=UTF-8''vsoft.weakreference-11.0-win32-0.1.1.dpkg
  sl := TStringList.Create;
  try
    sl.Delimiter := ';';
    sl.DelimitedText := headerValue;
    FDisposition := sl.Strings[0];
    FFileName := sl.Values['filename'];
  finally
    sl.Free;
  end;
end;

function TContentDisposition.GetDispositionType: string;
begin
  result := FDisposition;
end;

function TContentDisposition.GetFileName: string;
begin
  result := FFileName;
end;

end.
