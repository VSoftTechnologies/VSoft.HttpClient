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


unit VSoft.HttpClient.MultipartFormData;


interface

uses
  WinApi.ActiveX,
  System.Classes;

//Note (VP): this is very simplistic, I did enough to make it work where I was using it. For more complex needs, use Indy.

type
  IMultipartFormDataGenerator = interface
  ['{9FB16CA8-0855-49DA-9DFC-BD67456D0A6E}']
    function GetContentType : string;
    function GetBoundary : string;

    procedure AddField(const fieldName : string; const value : string);
    procedure AddFile(const fieldName : string; const filePath : string; const contentType: string = '');
    procedure AddStream(const fieldName: string; stream: TStream; const fileName: string = ''; const contentType: string = '');

    //wraps the stream in an adapter and sets the boundary to a new value, so get the boundary/contenttype first!
    function Generate : TStream;

    property Boundary : string read GetBoundary;
    property ContentType : string read GetContentType;
  end;


  TMultipartFormDataFactory = class
    class function Create : IMultipartFormDataGenerator;
  end;


implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.Win.Registry,
  WinApi.Windows,
  System.Generics.Collections,
  VSoft.HttpClient;

type
  TMultipartFormData = class(TInterfacedObject, IMultipartFormDataGenerator)
  private
    class var
      FMimeTypes : TDictionary<string, string>;
  private
    FDataStream: TMemoryStream;
    FBoundary : string;
  protected
    function GetMimeType(const fileName : string) : string;
    procedure GenerateUniqueBoundry;
    function GetBoundary: string;
    function GetContentType: string;
    function Generate: TStream;

    procedure WriteString(const value : string);

    procedure AddField(const fieldName: string; const value: string);
    procedure AddFile(const fieldName: string; const filePath: string; const contentType: string = '');
    procedure AddStream(const fieldName: string; stream: TStream; const fileName: string = ''; const contentType: string = '');

    class procedure AddDefaultMimeTypes;
    class procedure AddWindowsMimeTypes;
    class constructor Create;
    class destructor Destroy;
  public
    constructor Create;
    destructor Destroy;override;
  end;


{ TMultipartFormDataFactory }

class function TMultipartFormDataFactory.Create: IMultipartFormDataGenerator;
begin
  result := TMultipartFormData.Create;
end;

{ TMultipartFormData }

class procedure TMultipartFormData.AddDefaultMimeTypes;
begin
  FMimeTypes.AddOrSetValue('bin', 'application/octet-stream');
  //TODO : find a regularly update list that is easy to ingest!
  //these came from https://www.sitepoint.com/mime-types-complete-list/ just because it was easy to process.
  FMimeTypes.AddOrSetValue('.3dm', 'x-world/x-3dmf');
  FMimeTypes.AddOrSetValue('.3dm', 'x-world/x-3dmf');
  FMimeTypes.AddOrSetValue('.a', 'application/octet-stream');
  FMimeTypes.AddOrSetValue('.aab', 'application/x-authorware-bin');
  FMimeTypes.AddOrSetValue('.aam', 'application/x-authorware-map');
  FMimeTypes.AddOrSetValue('.aas', 'application/x-authorware-seg');
  FMimeTypes.AddOrSetValue('.abc', 'text/vnd.abc');
  FMimeTypes.AddOrSetValue('.acg', 'text/html');
  FMimeTypes.AddOrSetValue('.afl', 'video/animaflex');
  FMimeTypes.AddOrSetValue('.a', 'application/postscript');
  FMimeTypes.AddOrSetValue('.aif', 'audio/aiff');
  FMimeTypes.AddOrSetValue('.aif', 'audio/x-aiff');
  FMimeTypes.AddOrSetValue('.aif', 'audio/aiff');
  FMimeTypes.AddOrSetValue('.aif', 'audio/x-aiff');
  FMimeTypes.AddOrSetValue('.aif', 'audio/aiff');
  FMimeTypes.AddOrSetValue('.aif', 'audio/x-aiff');
  FMimeTypes.AddOrSetValue('.aim', 'application/x-aim');
  FMimeTypes.AddOrSetValue('.aip', 'text/x-audiosoft-intra');
  FMimeTypes.AddOrSetValue('.ani', 'application/x-navi-animation');
  FMimeTypes.AddOrSetValue('.aos', 'application/x-nokia-9000-communicator-add-on-software');
  FMimeTypes.AddOrSetValue('.aps', 'application/mime');
  FMimeTypes.AddOrSetValue('.arc', 'application/octet-stream');
  FMimeTypes.AddOrSetValue('.arj', 'application/arj');
  FMimeTypes.AddOrSetValue('.arj', 'application/octet-stream');
  FMimeTypes.AddOrSetValue('.art', 'image/x-jg');
  FMimeTypes.AddOrSetValue('.asf', 'video/x-ms-asf');
  FMimeTypes.AddOrSetValue('.asm', 'text/x-asm');
  FMimeTypes.AddOrSetValue('.asp', 'text/asp');
  FMimeTypes.AddOrSetValue('.asx', 'application/x-mplayer2');
  FMimeTypes.AddOrSetValue('.asx', 'video/x-ms-asf');
  FMimeTypes.AddOrSetValue('.asx', 'video/x-ms-asf-plugin');
  FMimeTypes.AddOrSetValue('.a', 'audio/basic');
  FMimeTypes.AddOrSetValue('.a', 'audio/x-au');
  FMimeTypes.AddOrSetValue('.avi', 'application/x-troff-msvideo');
  FMimeTypes.AddOrSetValue('.avi', 'video/avi');
  FMimeTypes.AddOrSetValue('.avi', 'video/msvideo');
  FMimeTypes.AddOrSetValue('.avi', 'video/x-msvideo');
  FMimeTypes.AddOrSetValue('.avs', 'video/avs-video');
  FMimeTypes.AddOrSetValue('.bcpio', 'application/x-bcpio');
  FMimeTypes.AddOrSetValue('.bin', 'application/mac-binary');
  FMimeTypes.AddOrSetValue('.bin', 'application/macbinary');
  FMimeTypes.AddOrSetValue('.bin', 'application/octet-stream');
  FMimeTypes.AddOrSetValue('.bin', 'application/x-binary');
  FMimeTypes.AddOrSetValue('.bin', 'application/x-macbinary');
  FMimeTypes.AddOrSetValue('.b', 'image/bmp');
  FMimeTypes.AddOrSetValue('.bmp', 'image/bmp');
  FMimeTypes.AddOrSetValue('.bmp', 'image/x-windows-bmp');
  FMimeTypes.AddOrSetValue('.boo', 'application/book');
  FMimeTypes.AddOrSetValue('.boo', 'application/book');
  FMimeTypes.AddOrSetValue('.boz', 'application/x-bzip2');
  FMimeTypes.AddOrSetValue('.bsh', 'application/x-bsh');
  FMimeTypes.AddOrSetValue('.b', 'application/x-bzip');
  FMimeTypes.AddOrSetValue('.bz2', 'application/x-bzip2');
  FMimeTypes.AddOrSetValue('.c', 'text/plain');
  FMimeTypes.AddOrSetValue('.c', 'text/x-c');
  FMimeTypes.AddOrSetValue('.c++', 'text/plain');
  FMimeTypes.AddOrSetValue('.cat', 'application/vnd.ms-pki.seccat');
  FMimeTypes.AddOrSetValue('.c', 'text/plain');
  FMimeTypes.AddOrSetValue('.c', 'text/x-c');
  FMimeTypes.AddOrSetValue('.cca', 'application/clariscad');
  FMimeTypes.AddOrSetValue('.cco', 'application/x-cocoa');
  FMimeTypes.AddOrSetValue('.cdf', 'application/cdf');
  FMimeTypes.AddOrSetValue('.cdf', 'application/x-cdf');
  FMimeTypes.AddOrSetValue('.cdf', 'application/x-netcdf');
  FMimeTypes.AddOrSetValue('.cer', 'application/pkix-cert');
  FMimeTypes.AddOrSetValue('.cer', 'application/x-x509-ca-cert');
  FMimeTypes.AddOrSetValue('.cha', 'application/x-chat');
  FMimeTypes.AddOrSetValue('.cha', 'application/x-chat');
  FMimeTypes.AddOrSetValue('.class', 'application/java');
  FMimeTypes.AddOrSetValue('.class', 'application/java-byte-code');
  FMimeTypes.AddOrSetValue('.class', 'application/x-java-class');
  FMimeTypes.AddOrSetValue('.com', 'application/octet-stream');
  FMimeTypes.AddOrSetValue('.com', 'text/plain');
  FMimeTypes.AddOrSetValue('.con', 'text/plain');
  FMimeTypes.AddOrSetValue('.cpi', 'application/x-cpio');
  FMimeTypes.AddOrSetValue('.cpp', 'text/x-c');
  FMimeTypes.AddOrSetValue('.cpt', 'application/mac-compactpro');
  FMimeTypes.AddOrSetValue('.cpt', 'application/x-compactpro');
  FMimeTypes.AddOrSetValue('.cpt', 'application/x-cpt');
  FMimeTypes.AddOrSetValue('.crl', 'application/pkcs-crl');
  FMimeTypes.AddOrSetValue('.crl', 'application/pkix-crl');
  FMimeTypes.AddOrSetValue('.crt', 'application/pkix-cert');
  FMimeTypes.AddOrSetValue('.crt', 'application/x-x509-ca-cert');
  FMimeTypes.AddOrSetValue('.crt', 'application/x-x509-user-cert');
  FMimeTypes.AddOrSetValue('.csh', 'application/x-csh');
  FMimeTypes.AddOrSetValue('.csh', 'text/x-script.csh');
  FMimeTypes.AddOrSetValue('.css', 'application/x-pointplus');
  FMimeTypes.AddOrSetValue('.css', 'text/css');
  FMimeTypes.AddOrSetValue('.cxx', 'text/plain');
  FMimeTypes.AddOrSetValue('.dcr', 'application/x-director');
  FMimeTypes.AddOrSetValue('.deepv', 'application/x-deepv');
  FMimeTypes.AddOrSetValue('.def', 'text/plain');
  FMimeTypes.AddOrSetValue('.der', 'application/x-x509-ca-cert');
  FMimeTypes.AddOrSetValue('.dif', 'video/x-dv');
  FMimeTypes.AddOrSetValue('.dir', 'application/x-director');
  FMimeTypes.AddOrSetValue('.d', 'video/dl');
  FMimeTypes.AddOrSetValue('.d', 'video/x-dl');
  FMimeTypes.AddOrSetValue('.doc', 'application/msword');
  FMimeTypes.AddOrSetValue('.dot', 'application/msword');
  FMimeTypes.AddOrSetValue('.d', 'application/commonground');
  FMimeTypes.AddOrSetValue('.drw', 'application/drafting');
  FMimeTypes.AddOrSetValue('.dum', 'application/octet-stream');
  FMimeTypes.AddOrSetValue('.d', 'video/x-dv');
  FMimeTypes.AddOrSetValue('.dvi', 'application/x-dvi');
  FMimeTypes.AddOrSetValue('.dwf', 'drawing/x-dwf (old)');
  FMimeTypes.AddOrSetValue('.dwf', 'model/vnd.dwf');
  FMimeTypes.AddOrSetValue('.dwg', 'application/acad');
  FMimeTypes.AddOrSetValue('.dwg', 'image/vnd.dwg');
  FMimeTypes.AddOrSetValue('.dwg', 'image/x-dwg');
  FMimeTypes.AddOrSetValue('.dxf', 'application/dxf');
  FMimeTypes.AddOrSetValue('.dxf', 'image/vnd.dwg');
  FMimeTypes.AddOrSetValue('.dxf', 'image/x-dwg');
  FMimeTypes.AddOrSetValue('.dxr', 'application/x-director');
  FMimeTypes.AddOrSetValue('.e', 'text/x-script.elisp');
  FMimeTypes.AddOrSetValue('.elc', 'application/x-bytecode.elisp (compiled elisp)');
  FMimeTypes.AddOrSetValue('.elc', 'application/x-elc');
  FMimeTypes.AddOrSetValue('.env', 'application/x-envoy');
  FMimeTypes.AddOrSetValue('.eps', 'application/postscript');
  FMimeTypes.AddOrSetValue('.e', 'application/x-esrehber');
  FMimeTypes.AddOrSetValue('.etx', 'text/x-setext');
  FMimeTypes.AddOrSetValue('.evy', 'application/envoy');
  FMimeTypes.AddOrSetValue('.evy', 'application/x-envoy');
  FMimeTypes.AddOrSetValue('.exe', 'application/octet-stream');
  FMimeTypes.AddOrSetValue('.f', 'text/plain');
  FMimeTypes.AddOrSetValue('.f', 'text/x-fortran');
  FMimeTypes.AddOrSetValue('.f77', 'text/x-fortran');
  FMimeTypes.AddOrSetValue('.f90', 'text/plain');
  FMimeTypes.AddOrSetValue('.f90', 'text/x-fortran');
  FMimeTypes.AddOrSetValue('.fdf', 'application/vnd.fdf');
  FMimeTypes.AddOrSetValue('.fif', 'application/fractals');
  FMimeTypes.AddOrSetValue('.fif', 'image/fif');
  FMimeTypes.AddOrSetValue('.fli', 'video/fli');
  FMimeTypes.AddOrSetValue('.fli', 'video/x-fli');
  FMimeTypes.AddOrSetValue('.flo', 'image/florian');
  FMimeTypes.AddOrSetValue('.flx', 'text/vnd.fmi.flexstor');
  FMimeTypes.AddOrSetValue('.fmf', 'video/x-atomic3d-feature');
  FMimeTypes.AddOrSetValue('.for', 'text/plain');
  FMimeTypes.AddOrSetValue('.for', 'text/x-fortran');
  FMimeTypes.AddOrSetValue('.fpx', 'image/vnd.fpx');
  FMimeTypes.AddOrSetValue('.fpx', 'image/vnd.net-fpx');
  FMimeTypes.AddOrSetValue('.frl', 'application/freeloader');
  FMimeTypes.AddOrSetValue('.fun', 'audio/make');
  FMimeTypes.AddOrSetValue('.g', 'text/plain');
  FMimeTypes.AddOrSetValue('.g', 'image/g3fax');
  FMimeTypes.AddOrSetValue('.gif', 'image/gif');
  FMimeTypes.AddOrSetValue('.g', 'video/gl');
  FMimeTypes.AddOrSetValue('.g', 'video/x-gl');
  FMimeTypes.AddOrSetValue('.gsd', 'audio/x-gsm');
  FMimeTypes.AddOrSetValue('.gsm', 'audio/x-gsm');
  FMimeTypes.AddOrSetValue('.gsp', 'application/x-gsp');
  FMimeTypes.AddOrSetValue('.gss', 'application/x-gss');
  FMimeTypes.AddOrSetValue('.gta', 'application/x-gtar');
  FMimeTypes.AddOrSetValue('.g', 'application/x-compressed');
  FMimeTypes.AddOrSetValue('.g', 'application/x-gzip');
  FMimeTypes.AddOrSetValue('.gzi', 'application/x-gzip');
  FMimeTypes.AddOrSetValue('.gzi', 'multipart/x-gzip');
  FMimeTypes.AddOrSetValue('.h', 'text/plain');
  FMimeTypes.AddOrSetValue('.h', 'text/x-h');
  FMimeTypes.AddOrSetValue('.hdf', 'application/x-hdf');
  FMimeTypes.AddOrSetValue('.hel', 'application/x-helpfile');
  FMimeTypes.AddOrSetValue('.hgl', 'application/vnd.hp-hpgl');
  FMimeTypes.AddOrSetValue('.h', 'text/plain');
  FMimeTypes.AddOrSetValue('.h', 'text/x-h');
  FMimeTypes.AddOrSetValue('.hlb', 'text/x-script');
  FMimeTypes.AddOrSetValue('.hlp', 'application/hlp');
  FMimeTypes.AddOrSetValue('.hlp', 'application/x-helpfile');
  FMimeTypes.AddOrSetValue('.hlp', 'application/x-winhelp');
  FMimeTypes.AddOrSetValue('.hpg', 'application/vnd.hp-hpgl');
  FMimeTypes.AddOrSetValue('.hpg', 'application/vnd.hp-hpgl');
  FMimeTypes.AddOrSetValue('.hqx', 'application/binhex');
  FMimeTypes.AddOrSetValue('.hqx', 'application/binhex4');
  FMimeTypes.AddOrSetValue('.hqx', 'application/mac-binhex');
  FMimeTypes.AddOrSetValue('.hqx', 'application/mac-binhex40');
  FMimeTypes.AddOrSetValue('.hqx', 'application/x-binhex40');
  FMimeTypes.AddOrSetValue('.hqx', 'application/x-mac-binhex40');
  FMimeTypes.AddOrSetValue('.hta', 'application/hta');
  FMimeTypes.AddOrSetValue('.htc', 'text/x-component');
  FMimeTypes.AddOrSetValue('.htm', 'text/html');
  FMimeTypes.AddOrSetValue('.htm', 'text/html');
  FMimeTypes.AddOrSetValue('.htmls', 'text/html');
  FMimeTypes.AddOrSetValue('.htt', 'text/webviewhtml');
  FMimeTypes.AddOrSetValue('.htx', 'text/html');
  FMimeTypes.AddOrSetValue('.ice', 'x-conference/x-cooltalk');
  FMimeTypes.AddOrSetValue('.ico', 'image/x-icon');
  FMimeTypes.AddOrSetValue('.idc', 'text/plain');
  FMimeTypes.AddOrSetValue('.ief', 'image/ief');
  FMimeTypes.AddOrSetValue('.ief', 'image/ief');
  FMimeTypes.AddOrSetValue('.ige', 'application/iges');
  FMimeTypes.AddOrSetValue('.ige', 'model/iges');
  FMimeTypes.AddOrSetValue('.igs', 'application/iges');
  FMimeTypes.AddOrSetValue('.igs', 'model/iges');
  FMimeTypes.AddOrSetValue('.ima', 'application/x-ima');
  FMimeTypes.AddOrSetValue('.ima', 'application/x-httpd-imap');
  FMimeTypes.AddOrSetValue('.inf', 'application/inf');
  FMimeTypes.AddOrSetValue('.ins', 'application/x-internett-signup');
  FMimeTypes.AddOrSetValue('.i', 'application/x-ip2');
  FMimeTypes.AddOrSetValue('.isu', 'video/x-isvideo');
  FMimeTypes.AddOrSetValue('.i', 'audio/it');
  FMimeTypes.AddOrSetValue('.i', 'application/x-inventor');
  FMimeTypes.AddOrSetValue('.ivr', 'i-world/i-vrml');
  FMimeTypes.AddOrSetValue('.ivy', 'application/x-livescreen');
  FMimeTypes.AddOrSetValue('.jam', 'audio/x-jam');
  FMimeTypes.AddOrSetValue('.jav', 'text/plain');
  FMimeTypes.AddOrSetValue('.jav', 'text/x-java-source');
  FMimeTypes.AddOrSetValue('.jav', 'text/plain');
  FMimeTypes.AddOrSetValue('.jav', 'text/x-java-source');
  FMimeTypes.AddOrSetValue('.jcm', 'application/x-java-commerce');
  FMimeTypes.AddOrSetValue('.jfi', 'image/jpeg');
  FMimeTypes.AddOrSetValue('.jfi', 'image/pjpeg');
  FMimeTypes.AddOrSetValue('.jfi', 'tbnl	image/jpeg');
  FMimeTypes.AddOrSetValue('.jpe', 'image/jpeg');
  FMimeTypes.AddOrSetValue('.jpe', 'image/pjpeg');
  FMimeTypes.AddOrSetValue('.jpe', 'image/jpeg');
  FMimeTypes.AddOrSetValue('.jpe', 'image/pjpeg');
  FMimeTypes.AddOrSetValue('.jpg', 'image/jpeg');
  FMimeTypes.AddOrSetValue('.jpg', 'image/pjpeg');
  FMimeTypes.AddOrSetValue('.jps', 'image/x-jps');
  FMimeTypes.AddOrSetValue('.j', 'application/x-javascript');
  FMimeTypes.AddOrSetValue('.j', 'application/javascript');
  FMimeTypes.AddOrSetValue('.j', 'application/ecmascript');
  FMimeTypes.AddOrSetValue('.j', 'text/javascript');
  FMimeTypes.AddOrSetValue('.j', 'text/ecmascript');
  FMimeTypes.AddOrSetValue('.jut', 'image/jutvision');
  FMimeTypes.AddOrSetValue('.kar', 'audio/midi');
  FMimeTypes.AddOrSetValue('.kar', 'music/x-karaoke');
  FMimeTypes.AddOrSetValue('.ksh', 'application/x-ksh');
  FMimeTypes.AddOrSetValue('.ksh', 'text/x-script.ksh');
  FMimeTypes.AddOrSetValue('.l', 'audio/nspaudio');
  FMimeTypes.AddOrSetValue('.l', 'audio/x-nspaudio');
  FMimeTypes.AddOrSetValue('.lam', 'audio/x-liveaudio');
  FMimeTypes.AddOrSetValue('.latex', 'application/x-latex');
  FMimeTypes.AddOrSetValue('.lha', 'application/lha');
  FMimeTypes.AddOrSetValue('.lha', 'application/octet-stream');
  FMimeTypes.AddOrSetValue('.lha', 'application/x-lha');
  FMimeTypes.AddOrSetValue('.lhx', 'application/octet-stream');
  FMimeTypes.AddOrSetValue('.lis', 'text/plain');
  FMimeTypes.AddOrSetValue('.lma', 'audio/nspaudio');
  FMimeTypes.AddOrSetValue('.lma', 'audio/x-nspaudio');
  FMimeTypes.AddOrSetValue('.log', 'text/plain');
  FMimeTypes.AddOrSetValue('.lsp', 'application/x-lisp');
  FMimeTypes.AddOrSetValue('.lsp', 'text/x-script.lisp');
  FMimeTypes.AddOrSetValue('.lst', 'text/plain');
  FMimeTypes.AddOrSetValue('.lsx', 'text/x-la-asf');
  FMimeTypes.AddOrSetValue('.ltx', 'application/x-latex');
  FMimeTypes.AddOrSetValue('.lzh', 'application/octet-stream');
  FMimeTypes.AddOrSetValue('.lzh', 'application/x-lzh');
  FMimeTypes.AddOrSetValue('.lzx', 'application/lzx');
  FMimeTypes.AddOrSetValue('.lzx', 'application/octet-stream');
  FMimeTypes.AddOrSetValue('.lzx', 'application/x-lzx');
  FMimeTypes.AddOrSetValue('.m', 'text/plain');
  FMimeTypes.AddOrSetValue('.m', 'text/x-m');
  FMimeTypes.AddOrSetValue('.m1v', 'video/mpeg');
  FMimeTypes.AddOrSetValue('.m2a', 'audio/mpeg');
  FMimeTypes.AddOrSetValue('.m2v', 'video/mpeg');
  FMimeTypes.AddOrSetValue('.m3u', 'audio/x-mpequrl');
  FMimeTypes.AddOrSetValue('.man', 'application/x-troff-man');
  FMimeTypes.AddOrSetValue('.map', 'application/x-navimap');
  FMimeTypes.AddOrSetValue('.mar', 'text/plain');
  FMimeTypes.AddOrSetValue('.mbd', 'application/mbedlet');
  FMimeTypes.AddOrSetValue('.mc$', 'application/x-magic-cap-package-1.0');
  FMimeTypes.AddOrSetValue('.mcd', 'application/mcad');
  FMimeTypes.AddOrSetValue('.mcd', 'application/x-mathcad');
  FMimeTypes.AddOrSetValue('.mcf', 'image/vasa');
  FMimeTypes.AddOrSetValue('.mcf', 'text/mcf');
  FMimeTypes.AddOrSetValue('.mcp', 'application/netmc');
  FMimeTypes.AddOrSetValue('.m', 'application/x-troff-me');
  FMimeTypes.AddOrSetValue('.mht', 'message/rfc822');
  FMimeTypes.AddOrSetValue('.mhtml', 'message/rfc822');
  FMimeTypes.AddOrSetValue('.mid', 'application/x-midi');
  FMimeTypes.AddOrSetValue('.mid', 'audio/midi');
  FMimeTypes.AddOrSetValue('.mid', 'audio/x-mid');
  FMimeTypes.AddOrSetValue('.mid', 'audio/x-midi');
  FMimeTypes.AddOrSetValue('.mid', 'music/crescendo');
  FMimeTypes.AddOrSetValue('.mid', 'x-music/x-midi');
  FMimeTypes.AddOrSetValue('.mid', 'application/x-midi');
  FMimeTypes.AddOrSetValue('.mid', 'audio/midi');
  FMimeTypes.AddOrSetValue('.mid', 'audio/x-mid');
  FMimeTypes.AddOrSetValue('.mid', 'audio/x-midi');
  FMimeTypes.AddOrSetValue('.mid', 'music/crescendo');
  FMimeTypes.AddOrSetValue('.mid', 'x-music/x-midi');
  FMimeTypes.AddOrSetValue('.mif', 'application/x-frame');
  FMimeTypes.AddOrSetValue('.mif', 'application/x-mif');
  FMimeTypes.AddOrSetValue('.mim', 'message/rfc822');
  FMimeTypes.AddOrSetValue('.mim', 'www/mime');
  FMimeTypes.AddOrSetValue('.mjf', 'audio/x-vnd.audioexplosion.mjuicemediafile');
  FMimeTypes.AddOrSetValue('.mjp', 'video/x-motion-jpeg');
  FMimeTypes.AddOrSetValue('.m', 'application/base64');
  FMimeTypes.AddOrSetValue('.m', 'application/x-meme');
  FMimeTypes.AddOrSetValue('.mme', 'application/base64');
  FMimeTypes.AddOrSetValue('.mod', 'audio/mod');
  FMimeTypes.AddOrSetValue('.mod', 'audio/x-mod');
  FMimeTypes.AddOrSetValue('.moo', 'video/quicktime');
  FMimeTypes.AddOrSetValue('.mov', 'video/quicktime');
  FMimeTypes.AddOrSetValue('.movie', 'video/x-sgi-movie');
  FMimeTypes.AddOrSetValue('.mp2', 'audio/mpeg');
  FMimeTypes.AddOrSetValue('.mp2', 'audio/x-mpeg');
  FMimeTypes.AddOrSetValue('.mp2', 'video/mpeg');
  FMimeTypes.AddOrSetValue('.mp2', 'video/x-mpeg');
  FMimeTypes.AddOrSetValue('.mp2', 'video/x-mpeq2a');
  FMimeTypes.AddOrSetValue('.mp3', 'audio/mpeg3');
  FMimeTypes.AddOrSetValue('.mp3', 'audio/x-mpeg-3');
  FMimeTypes.AddOrSetValue('.mp3', 'video/mpeg');
  FMimeTypes.AddOrSetValue('.mp3', 'video/x-mpeg');
  FMimeTypes.AddOrSetValue('.mpa', 'audio/mpeg');
  FMimeTypes.AddOrSetValue('.mpa', 'video/mpeg');
  FMimeTypes.AddOrSetValue('.mpc', 'application/x-project');
  FMimeTypes.AddOrSetValue('.mpe', 'video/mpeg');
  FMimeTypes.AddOrSetValue('.mpe', 'video/mpeg');
  FMimeTypes.AddOrSetValue('.mpg', 'audio/mpeg');
  FMimeTypes.AddOrSetValue('.mpg', 'video/mpeg');
  FMimeTypes.AddOrSetValue('.mpg', 'audio/mpeg');
  FMimeTypes.AddOrSetValue('.mpp', 'application/vnd.ms-project');
  FMimeTypes.AddOrSetValue('.mpt', 'application/x-project');
  FMimeTypes.AddOrSetValue('.mpv', 'application/x-project');
  FMimeTypes.AddOrSetValue('.mpx', 'application/x-project');
  FMimeTypes.AddOrSetValue('.mrc', 'application/marc');
  FMimeTypes.AddOrSetValue('.m', 'application/x-troff-ms');
  FMimeTypes.AddOrSetValue('.m', 'video/x-sgi-movie');
  FMimeTypes.AddOrSetValue('.m', 'audio/make');
  FMimeTypes.AddOrSetValue('.mzz', 'application/x-vnd.audioexplosion.mzz');
  FMimeTypes.AddOrSetValue('.nap', 'image/naplps');
  FMimeTypes.AddOrSetValue('.naplp', 'image/naplps');
  FMimeTypes.AddOrSetValue('.n', 'application/x-netcdf');
  FMimeTypes.AddOrSetValue('.ncm', 'application/vnd.nokia.configuration-message');
  FMimeTypes.AddOrSetValue('.nif', 'image/x-niff');
  FMimeTypes.AddOrSetValue('.nif', 'image/x-niff');
  FMimeTypes.AddOrSetValue('.nix', 'application/x-mix-transfer');
  FMimeTypes.AddOrSetValue('.nsc', 'application/x-conference');
  FMimeTypes.AddOrSetValue('.nvd', 'application/x-navidoc');
  FMimeTypes.AddOrSetValue('.o', 'application/octet-stream');
  FMimeTypes.AddOrSetValue('.oda', 'application/oda');
  FMimeTypes.AddOrSetValue('.omc', 'application/x-omc');
  FMimeTypes.AddOrSetValue('.omc', 'application/x-omcdatamaker');
  FMimeTypes.AddOrSetValue('.omc', 'application/x-omcregerator');
  FMimeTypes.AddOrSetValue('.p', 'text/x-pascal');
  FMimeTypes.AddOrSetValue('.p10', 'application/pkcs10');
  FMimeTypes.AddOrSetValue('.p10', 'application/x-pkcs10');
  FMimeTypes.AddOrSetValue('.p12', 'application/pkcs-12');
  FMimeTypes.AddOrSetValue('.p12', 'application/x-pkcs12');
  FMimeTypes.AddOrSetValue('.p7a', 'application/x-pkcs7-signature');
  FMimeTypes.AddOrSetValue('.p7c', 'application/pkcs7-mime');
  FMimeTypes.AddOrSetValue('.p7c', 'application/x-pkcs7-mime');
  FMimeTypes.AddOrSetValue('.p7m', 'application/pkcs7-mime');
  FMimeTypes.AddOrSetValue('.p7m', 'application/x-pkcs7-mime');
  FMimeTypes.AddOrSetValue('.p7r', 'application/x-pkcs7-certreqresp');
  FMimeTypes.AddOrSetValue('.p7s', 'application/pkcs7-signature');
  FMimeTypes.AddOrSetValue('.par', 'application/pro_eng');
  FMimeTypes.AddOrSetValue('.pas', 'text/pascal');
  FMimeTypes.AddOrSetValue('.pbm', 'image/x-portable-bitmap');
  FMimeTypes.AddOrSetValue('.pcl', 'application/vnd.hp-pcl');
  FMimeTypes.AddOrSetValue('.pcl', 'application/x-pcl');
  FMimeTypes.AddOrSetValue('.pct', 'image/x-pict');
  FMimeTypes.AddOrSetValue('.pcx', 'image/x-pcx');
  FMimeTypes.AddOrSetValue('.pdb', 'chemical/x-pdb');
  FMimeTypes.AddOrSetValue('.pdf', 'application/pdf');
  FMimeTypes.AddOrSetValue('.pfunk', 'audio/make');
  FMimeTypes.AddOrSetValue('.pfunk', 'audio/make.my.funk');
  FMimeTypes.AddOrSetValue('.pgm', 'image/x-portable-graymap');
  FMimeTypes.AddOrSetValue('.pgm', 'image/x-portable-greymap');
  FMimeTypes.AddOrSetValue('.pic', 'image/pict');
  FMimeTypes.AddOrSetValue('.pic', 'image/pict');
  FMimeTypes.AddOrSetValue('.pkg', 'application/x-newton-compatible-pkg');
  FMimeTypes.AddOrSetValue('.pko', 'application/vnd.ms-pki.pko');
  FMimeTypes.AddOrSetValue('.p', 'text/plain');
  FMimeTypes.AddOrSetValue('.p', 'text/x-script.perl');
  FMimeTypes.AddOrSetValue('.plx', 'application/x-pixclscript');
  FMimeTypes.AddOrSetValue('.p', 'image/x-xpixmap');
  FMimeTypes.AddOrSetValue('.p', 'text/x-script.perl-module');
  FMimeTypes.AddOrSetValue('.pm4', 'application/x-pagemaker');
  FMimeTypes.AddOrSetValue('.pm5', 'application/x-pagemaker');
  FMimeTypes.AddOrSetValue('.png', 'image/png');
  FMimeTypes.AddOrSetValue('.pnm', 'application/x-portable-anymap');
  FMimeTypes.AddOrSetValue('.pnm', 'image/x-portable-anymap');
  FMimeTypes.AddOrSetValue('.pot', 'application/mspowerpoint');
  FMimeTypes.AddOrSetValue('.pot', 'application/vnd.ms-powerpoint');
  FMimeTypes.AddOrSetValue('.pov', 'model/x-pov');
  FMimeTypes.AddOrSetValue('.ppa', 'application/vnd.ms-powerpoint');
  FMimeTypes.AddOrSetValue('.ppm', 'image/x-portable-pixmap');
  FMimeTypes.AddOrSetValue('.pps', 'application/mspowerpoint');
  FMimeTypes.AddOrSetValue('.pps', 'application/vnd.ms-powerpoint');
  FMimeTypes.AddOrSetValue('.ppt', 'application/mspowerpoint');
  FMimeTypes.AddOrSetValue('.ppt', 'application/powerpoint');
  FMimeTypes.AddOrSetValue('.ppt', 'application/vnd.ms-powerpoint');
  FMimeTypes.AddOrSetValue('.ppt', 'application/x-mspowerpoint');
  FMimeTypes.AddOrSetValue('.ppz', 'application/mspowerpoint');
  FMimeTypes.AddOrSetValue('.pre', 'application/x-freelance');
  FMimeTypes.AddOrSetValue('.prt', 'application/pro_eng');
  FMimeTypes.AddOrSetValue('.p', 'application/postscript');
  FMimeTypes.AddOrSetValue('.psd', 'application/octet-stream');
  FMimeTypes.AddOrSetValue('.pvu', 'paleovu/x-pv');
  FMimeTypes.AddOrSetValue('.pwz', 'application/vnd.ms-powerpoint');
  FMimeTypes.AddOrSetValue('.p', 'text/x-script.phyton');
  FMimeTypes.AddOrSetValue('.pyc', 'application/x-bytecode.python');
  FMimeTypes.AddOrSetValue('.qcp', 'audio/vnd.qcelp');
  FMimeTypes.AddOrSetValue('.qd3', 'x-world/x-3dmf');
  FMimeTypes.AddOrSetValue('.qd3', 'x-world/x-3dmf');
  FMimeTypes.AddOrSetValue('.qif', 'image/x-quicktime');
  FMimeTypes.AddOrSetValue('.q', 'video/quicktime');
  FMimeTypes.AddOrSetValue('.qtc', 'video/x-qtc');
  FMimeTypes.AddOrSetValue('.qti', 'image/x-quicktime');
  FMimeTypes.AddOrSetValue('.qti', 'image/x-quicktime');
  FMimeTypes.AddOrSetValue('.r', 'audio/x-pn-realaudio');
  FMimeTypes.AddOrSetValue('.r', 'audio/x-pn-realaudio-plugin');
  FMimeTypes.AddOrSetValue('.r', 'audio/x-realaudio');
  FMimeTypes.AddOrSetValue('.ram', 'audio/x-pn-realaudio');
  FMimeTypes.AddOrSetValue('.ras', 'application/x-cmu-raster');
  FMimeTypes.AddOrSetValue('.ras', 'image/cmu-raster');
  FMimeTypes.AddOrSetValue('.ras', 'image/x-cmu-raster');
  FMimeTypes.AddOrSetValue('.ras', 'image/cmu-raster');
  FMimeTypes.AddOrSetValue('.rex', 'text/x-script.rexx');
  FMimeTypes.AddOrSetValue('.r', 'image/vnd.rn-realflash');
  FMimeTypes.AddOrSetValue('.rgb', 'image/x-rgb');
  FMimeTypes.AddOrSetValue('.r', 'application/vnd.rn-realmedia');
  FMimeTypes.AddOrSetValue('.r', 'audio/x-pn-realaudio');
  FMimeTypes.AddOrSetValue('.rmi', 'audio/mid');
  FMimeTypes.AddOrSetValue('.rmm', 'audio/x-pn-realaudio');
  FMimeTypes.AddOrSetValue('.rmp', 'audio/x-pn-realaudio');
  FMimeTypes.AddOrSetValue('.rmp', 'audio/x-pn-realaudio-plugin');
  FMimeTypes.AddOrSetValue('.rng', 'application/ringing-tones');
  FMimeTypes.AddOrSetValue('.rng', 'application/vnd.nokia.ringing-tone');
  FMimeTypes.AddOrSetValue('.rnx', 'application/vnd.rn-realplayer');
  FMimeTypes.AddOrSetValue('.rof', 'application/x-troff');
  FMimeTypes.AddOrSetValue('.r', 'image/vnd.rn-realpix');
  FMimeTypes.AddOrSetValue('.rpm', 'audio/x-pn-realaudio-plugin');
  FMimeTypes.AddOrSetValue('.r', 'text/richtext');
  FMimeTypes.AddOrSetValue('.r', 'text/vnd.rn-realtext');
  FMimeTypes.AddOrSetValue('.rtf', 'application/rtf');
  FMimeTypes.AddOrSetValue('.rtf', 'application/x-rtf');
  FMimeTypes.AddOrSetValue('.rtf', 'text/richtext');
  FMimeTypes.AddOrSetValue('.rtx', 'application/rtf');
  FMimeTypes.AddOrSetValue('.rtx', 'text/richtext');
  FMimeTypes.AddOrSetValue('.r', 'video/vnd.rn-realvideo');
  FMimeTypes.AddOrSetValue('.s', 'text/x-asm');
  FMimeTypes.AddOrSetValue('.s3m', 'audio/s3m');
  FMimeTypes.AddOrSetValue('.savem', 'application/octet-stream');
  FMimeTypes.AddOrSetValue('.sbk', 'application/x-tbook');
  FMimeTypes.AddOrSetValue('.scm', 'application/x-lotusscreencam');
  FMimeTypes.AddOrSetValue('.scm', 'text/x-script.guile');
  FMimeTypes.AddOrSetValue('.scm', 'text/x-script.scheme');
  FMimeTypes.AddOrSetValue('.scm', 'video/x-scm');
  FMimeTypes.AddOrSetValue('.sdm', 'text/plain');
  FMimeTypes.AddOrSetValue('.sdp', 'application/sdp');
  FMimeTypes.AddOrSetValue('.sdp', 'application/x-sdp');
  FMimeTypes.AddOrSetValue('.sdr', 'application/sounder');
  FMimeTypes.AddOrSetValue('.sea', 'application/sea');
  FMimeTypes.AddOrSetValue('.sea', 'application/x-sea');
  FMimeTypes.AddOrSetValue('.set', 'application/set');
  FMimeTypes.AddOrSetValue('.sgm', 'text/sgml');
  FMimeTypes.AddOrSetValue('.sgm', 'text/x-sgml');
  FMimeTypes.AddOrSetValue('.sgm', 'text/sgml');
  FMimeTypes.AddOrSetValue('.sgm', 'text/x-sgml');
  FMimeTypes.AddOrSetValue('.s', 'application/x-bsh');
  FMimeTypes.AddOrSetValue('.s', 'application/x-sh');
  FMimeTypes.AddOrSetValue('.s', 'application/x-shar');
  FMimeTypes.AddOrSetValue('.s', 'text/x-script.sh');
  FMimeTypes.AddOrSetValue('.sha', 'application/x-bsh');
  FMimeTypes.AddOrSetValue('.sha', 'application/x-shar');
  FMimeTypes.AddOrSetValue('.shtml', 'text/html');
  FMimeTypes.AddOrSetValue('.shtml', 'text/x-server-parsed-html');
  FMimeTypes.AddOrSetValue('.sid', 'audio/x-psid');
  FMimeTypes.AddOrSetValue('.sit', 'application/x-sit');
  FMimeTypes.AddOrSetValue('.sit', 'application/x-stuffit');
  FMimeTypes.AddOrSetValue('.skd', 'application/x-koan');
  FMimeTypes.AddOrSetValue('.skm', 'application/x-koan');
  FMimeTypes.AddOrSetValue('.skp', 'application/x-koan');
  FMimeTypes.AddOrSetValue('.skt', 'application/x-koan');
  FMimeTypes.AddOrSetValue('.s', 'application/x-seelogo');
  FMimeTypes.AddOrSetValue('.smi', 'application/smil');
  FMimeTypes.AddOrSetValue('.smi', 'application/smil');
  FMimeTypes.AddOrSetValue('.snd', 'audio/basic');
  FMimeTypes.AddOrSetValue('.snd', 'audio/x-adpcm');
  FMimeTypes.AddOrSetValue('.sol', 'application/solids');
  FMimeTypes.AddOrSetValue('.spc', 'application/x-pkcs7-certificates');
  FMimeTypes.AddOrSetValue('.spc', 'text/x-speech');
  FMimeTypes.AddOrSetValue('.spl', 'application/futuresplash');
  FMimeTypes.AddOrSetValue('.spr', 'application/x-sprite');
  FMimeTypes.AddOrSetValue('.sprit', 'application/x-sprite');
  FMimeTypes.AddOrSetValue('.src', 'application/x-wais-source');
  FMimeTypes.AddOrSetValue('.ssi', 'text/x-server-parsed-html');
  FMimeTypes.AddOrSetValue('.ssm', 'application/streamingmedia');
  FMimeTypes.AddOrSetValue('.sst', 'application/vnd.ms-pki.certstore');
  FMimeTypes.AddOrSetValue('.ste', 'application/step');
  FMimeTypes.AddOrSetValue('.stl', 'application/sla');
  FMimeTypes.AddOrSetValue('.stl', 'application/vnd.ms-pki.stl');
  FMimeTypes.AddOrSetValue('.stl', 'application/x-navistyle');
  FMimeTypes.AddOrSetValue('.stp', 'application/step');
  FMimeTypes.AddOrSetValue('.sv4cpio', 'application/x-sv4cpio');
  FMimeTypes.AddOrSetValue('.sv4cr', 'application/x-sv4crc');
  FMimeTypes.AddOrSetValue('.svf', 'image/vnd.dwg');
  FMimeTypes.AddOrSetValue('.svf', 'image/x-dwg');
  FMimeTypes.AddOrSetValue('.svr', 'application/x-world');
  FMimeTypes.AddOrSetValue('.svr', 'x-world/x-svr');
  FMimeTypes.AddOrSetValue('.swf', 'application/x-shockwave-flash');
  FMimeTypes.AddOrSetValue('.t', 'application/x-troff');
  FMimeTypes.AddOrSetValue('.tal', 'text/x-speech');
  FMimeTypes.AddOrSetValue('.tar', 'application/x-tar');
  FMimeTypes.AddOrSetValue('.tbk', 'application/toolbook');
  FMimeTypes.AddOrSetValue('.tbk', 'application/x-tbook');
  FMimeTypes.AddOrSetValue('.tcl', 'application/x-tcl');
  FMimeTypes.AddOrSetValue('.tcl', 'text/x-script.tcl');
  FMimeTypes.AddOrSetValue('.tcs', 'text/x-script.tcsh');
  FMimeTypes.AddOrSetValue('.tex', 'application/x-tex');
  FMimeTypes.AddOrSetValue('.tex', 'application/x-texinfo');
  FMimeTypes.AddOrSetValue('.texinfo', 'application/x-texinfo');
  FMimeTypes.AddOrSetValue('.tex', 'application/plain');
  FMimeTypes.AddOrSetValue('.tex', 'text/plain');
  FMimeTypes.AddOrSetValue('.tgz', 'application/gnutar');
  FMimeTypes.AddOrSetValue('.tgz', 'application/x-compressed');
  FMimeTypes.AddOrSetValue('.tif', 'image/tiff');
  FMimeTypes.AddOrSetValue('.tif', 'image/x-tiff');
  FMimeTypes.AddOrSetValue('.tif', 'image/tiff');
  FMimeTypes.AddOrSetValue('.tif', 'image/x-tiff');
  FMimeTypes.AddOrSetValue('.t', 'application/x-troff');
  FMimeTypes.AddOrSetValue('.tsi', 'audio/tsp-audio');
  FMimeTypes.AddOrSetValue('.tsp', 'application/dsptype');
  FMimeTypes.AddOrSetValue('.tsp', 'audio/tsplayer');
  FMimeTypes.AddOrSetValue('.tsv', 'text/tab-separated-values');
  FMimeTypes.AddOrSetValue('.turbo', 'image/florian');
  FMimeTypes.AddOrSetValue('.txt', 'text/plain');
  FMimeTypes.AddOrSetValue('.uil', 'text/x-uil');
  FMimeTypes.AddOrSetValue('.uni', 'text/uri-list');
  FMimeTypes.AddOrSetValue('.uni', 'text/uri-list');
  FMimeTypes.AddOrSetValue('.unv', 'application/i-deas');
  FMimeTypes.AddOrSetValue('.uri', 'text/uri-list');
  FMimeTypes.AddOrSetValue('.uri', 'text/uri-list');
  FMimeTypes.AddOrSetValue('.ustar', 'application/x-ustar');
  FMimeTypes.AddOrSetValue('.ustar', 'multipart/x-ustar');
  FMimeTypes.AddOrSetValue('.u', 'application/octet-stream');
  FMimeTypes.AddOrSetValue('.u', 'text/x-uuencode');
  FMimeTypes.AddOrSetValue('.uue', 'text/x-uuencode');
  FMimeTypes.AddOrSetValue('.vcd', 'application/x-cdlink');
  FMimeTypes.AddOrSetValue('.vcs', 'text/x-vcalendar');
  FMimeTypes.AddOrSetValue('.vda', 'application/vda');
  FMimeTypes.AddOrSetValue('.vdo', 'video/vdo');
  FMimeTypes.AddOrSetValue('.vew', 'application/groupwise');
  FMimeTypes.AddOrSetValue('.viv', 'video/vivo');
  FMimeTypes.AddOrSetValue('.viv', 'video/vnd.vivo');
  FMimeTypes.AddOrSetValue('.viv', 'video/vivo');
  FMimeTypes.AddOrSetValue('.viv', 'video/vnd.vivo');
  FMimeTypes.AddOrSetValue('.vmd', 'application/vocaltec-media-desc');
  FMimeTypes.AddOrSetValue('.vmf', 'application/vocaltec-media-file');
  FMimeTypes.AddOrSetValue('.voc', 'audio/voc');
  FMimeTypes.AddOrSetValue('.voc', 'audio/x-voc');
  FMimeTypes.AddOrSetValue('.vos', 'video/vosaic');
  FMimeTypes.AddOrSetValue('.vox', 'audio/voxware');
  FMimeTypes.AddOrSetValue('.vqe', 'audio/x-twinvq-plugin');
  FMimeTypes.AddOrSetValue('.vqf', 'audio/x-twinvq');
  FMimeTypes.AddOrSetValue('.vql', 'audio/x-twinvq-plugin');
  FMimeTypes.AddOrSetValue('.vrm', 'application/x-vrml');
  FMimeTypes.AddOrSetValue('.vrm', 'model/vrml');
  FMimeTypes.AddOrSetValue('.vrm', 'x-world/x-vrml');
  FMimeTypes.AddOrSetValue('.vrt', 'x-world/x-vrt');
  FMimeTypes.AddOrSetValue('.vsd', 'application/x-visio');
  FMimeTypes.AddOrSetValue('.vst', 'application/x-visio');
  FMimeTypes.AddOrSetValue('.vsw', 'application/x-visio');
  FMimeTypes.AddOrSetValue('.w60', 'application/wordperfect6.0');
  FMimeTypes.AddOrSetValue('.w61', 'application/wordperfect6.1');
  FMimeTypes.AddOrSetValue('.w6w', 'application/msword');
  FMimeTypes.AddOrSetValue('.wav', 'audio/wav');
  FMimeTypes.AddOrSetValue('.wav', 'audio/x-wav');
  FMimeTypes.AddOrSetValue('.wb1', 'application/x-qpro');
  FMimeTypes.AddOrSetValue('.wbm', 'image/vnd.wap.wbmp');
  FMimeTypes.AddOrSetValue('.web', 'application/vnd.xara');
  FMimeTypes.AddOrSetValue('.wiz', 'application/msword');
  FMimeTypes.AddOrSetValue('.wk1', 'application/x-123');
  FMimeTypes.AddOrSetValue('.wmf', 'windows/metafile');
  FMimeTypes.AddOrSetValue('.wml', 'text/vnd.wap.wml');
  FMimeTypes.AddOrSetValue('.wml', 'application/vnd.wap.wmlc');
  FMimeTypes.AddOrSetValue('.wml', 'text/vnd.wap.wmlscript');
  FMimeTypes.AddOrSetValue('.wmlsc', 'application/vnd.wap.wmlscriptc');
  FMimeTypes.AddOrSetValue('.wor', 'application/msword');
  FMimeTypes.AddOrSetValue('.w', 'application/wordperfect');
  FMimeTypes.AddOrSetValue('.wp5', 'application/wordperfect');
  FMimeTypes.AddOrSetValue('.wp5', 'application/wordperfect6.0');
  FMimeTypes.AddOrSetValue('.wp6', 'application/wordperfect');
  FMimeTypes.AddOrSetValue('.wpd', 'application/wordperfect');
  FMimeTypes.AddOrSetValue('.wpd', 'application/x-wpwin');
  FMimeTypes.AddOrSetValue('.wq1', 'application/x-lotus');
  FMimeTypes.AddOrSetValue('.wri', 'application/mswrite');
  FMimeTypes.AddOrSetValue('.wri', 'application/x-wri');
  FMimeTypes.AddOrSetValue('.wrl', 'application/x-world');
  FMimeTypes.AddOrSetValue('.wrl', 'model/vrml');
  FMimeTypes.AddOrSetValue('.wrl', 'x-world/x-vrml');
  FMimeTypes.AddOrSetValue('.wrz', 'model/vrml');
  FMimeTypes.AddOrSetValue('.wrz', 'x-world/x-vrml');
  FMimeTypes.AddOrSetValue('.wsc', 'text/scriplet');
  FMimeTypes.AddOrSetValue('.wsr', 'application/x-wais-source');
  FMimeTypes.AddOrSetValue('.wtk', 'application/x-wintalk');
  FMimeTypes.AddOrSetValue('.xbm', 'image/x-xbitmap');
  FMimeTypes.AddOrSetValue('.xbm', 'image/x-xbm');
  FMimeTypes.AddOrSetValue('.xbm', 'image/xbm');
  FMimeTypes.AddOrSetValue('.xdr', 'video/x-amt-demorun');
  FMimeTypes.AddOrSetValue('.xgz', 'xgl/drawing');
  FMimeTypes.AddOrSetValue('.xif', 'image/vnd.xiff');
  FMimeTypes.AddOrSetValue('.x', 'application/excel');
  FMimeTypes.AddOrSetValue('.xla', 'application/excel');
  FMimeTypes.AddOrSetValue('.xla', 'application/x-excel');
  FMimeTypes.AddOrSetValue('.xla', 'application/x-msexcel');
  FMimeTypes.AddOrSetValue('.xlb', 'application/excel');
  FMimeTypes.AddOrSetValue('.xlb', 'application/vnd.ms-excel');
  FMimeTypes.AddOrSetValue('.xlb', 'application/x-excel');
  FMimeTypes.AddOrSetValue('.xlc', 'application/excel');
  FMimeTypes.AddOrSetValue('.xlc', 'application/vnd.ms-excel');
  FMimeTypes.AddOrSetValue('.xlc', 'application/x-excel');
  FMimeTypes.AddOrSetValue('.xld', 'application/excel');
  FMimeTypes.AddOrSetValue('.xld', 'application/x-excel');
  FMimeTypes.AddOrSetValue('.xlk', 'application/excel');
  FMimeTypes.AddOrSetValue('.xlk', 'application/x-excel');
  FMimeTypes.AddOrSetValue('.xll', 'application/excel');
  FMimeTypes.AddOrSetValue('.xll', 'application/vnd.ms-excel');
  FMimeTypes.AddOrSetValue('.xll', 'application/x-excel');
  FMimeTypes.AddOrSetValue('.xlm', 'application/excel');
  FMimeTypes.AddOrSetValue('.xlm', 'application/vnd.ms-excel');
  FMimeTypes.AddOrSetValue('.xlm', 'application/x-excel');
  FMimeTypes.AddOrSetValue('.xls', 'application/excel');
  FMimeTypes.AddOrSetValue('.xls', 'application/vnd.ms-excel');
  FMimeTypes.AddOrSetValue('.xls', 'application/x-excel');
  FMimeTypes.AddOrSetValue('.xls', 'application/x-msexcel');
  FMimeTypes.AddOrSetValue('.xlt', 'application/excel');
  FMimeTypes.AddOrSetValue('.xlt', 'application/x-excel');
  FMimeTypes.AddOrSetValue('.xlv', 'application/excel');
  FMimeTypes.AddOrSetValue('.xlv', 'application/x-excel');
  FMimeTypes.AddOrSetValue('.xlw', 'application/excel');
  FMimeTypes.AddOrSetValue('.xlw', 'application/vnd.ms-excel');
  FMimeTypes.AddOrSetValue('.xlw', 'application/x-excel');
  FMimeTypes.AddOrSetValue('.xlw', 'application/x-msexcel');
  FMimeTypes.AddOrSetValue('.x', 'audio/xm');
  FMimeTypes.AddOrSetValue('.xml', 'application/xml');
  FMimeTypes.AddOrSetValue('.xml', 'text/xml');
  FMimeTypes.AddOrSetValue('.xmz', 'xgl/movie');
  FMimeTypes.AddOrSetValue('.xpi', 'application/x-vnd.ls-xpix');
  FMimeTypes.AddOrSetValue('.xpm', 'image/x-xpixmap');
  FMimeTypes.AddOrSetValue('.xpm', 'image/xpm');
  FMimeTypes.AddOrSetValue('.', 'png	image/png');
  FMimeTypes.AddOrSetValue('.xsr', 'video/x-amt-showrun');
  FMimeTypes.AddOrSetValue('.xwd', 'image/x-xwd');
  FMimeTypes.AddOrSetValue('.xwd', 'image/x-xwindowdump');
  FMimeTypes.AddOrSetValue('.xyz', 'chemical/x-pdb');
  FMimeTypes.AddOrSetValue('.z', 'application/x-compress');
  FMimeTypes.AddOrSetValue('.z', 'application/x-compressed');
  FMimeTypes.AddOrSetValue('.zip', 'application/x-compressed');
  FMimeTypes.AddOrSetValue('.zip', 'application/x-zip-compressed');
  FMimeTypes.AddOrSetValue('.zip', 'application/zip');
  FMimeTypes.AddOrSetValue('.zip', 'multipart/x-zip');
  FMimeTypes.AddOrSetValue('.zoo', 'application/octet-stream');
  FMimeTypes.AddOrSetValue('.zsh', 'text/x-script.zsh');

end;

procedure TMultipartFormData.AddField(const fieldName, value: string);
begin
  WriteString('--' + FBoundary);
  WriteString(cContentDispositionHeader + ': form-data; name="' + fieldName + '"' + #13#10);
  WriteString(value);
end;

procedure TMultipartFormData.AddFile(const fieldName, filePath, contentType: string);
var
  fs : TFileStream;
begin
  fs := TFileStream.Create(filePath, fmOpenRead or fmShareDenyWrite);
  try
    AddStream(fieldName, fs, ExtractFileName(filePath), contentType);
  finally
    fs.Free;
  end;
end;

procedure TMultipartFormData.AddStream(const fieldName: string; stream: TStream; const fileName, contentType: string);
var
  sLine, sContentType: string;
begin
  WriteString('--' + FBoundary);
  sLine := cContentDispositionHeader + ': form-data; name="' + fieldName + '"';
  if fileName <> '' then
    sLine := sLine + '; filename="' + fileName + '"';
  WriteString(sLine);

  sContentType := contentType;
  if sContentType = '' then
    sContentType := GetMimeType(fileName);
  WriteString(cContentTypeHeader + ': ' + sContentType + #13#10);
  FDataStream.CopyFrom(stream, 0);
  WriteString('');
end;

class procedure TMultipartFormData.AddWindowsMimeTypes;
const
  contentTypesKey = '\MIME\Database\Content Type\';
var
  reg : TRegistry;
  keys : TStringList;
  i : integer;
  sContentType : string;
  sExt : string;
begin
  reg := TRegistry.Create;
  try
    keys := TStringList.Create;
    try
      reg.RootKey :=HKEY_CLASSES_ROOT;
      //get registred file extensions first.
      if reg.OpenKeyReadOnly('\') then
      begin
        reg.GetKeyNames(keys);
        reg.CloseKey;
        for i := 0 to keys.Count -1 do
        begin
          if StartsText('.',keys[i]) then
          begin
            if reg.OpenKeyReadOnly(keys[i]) then
            begin
              sContentType := reg.ReadString('Content Type');
              reg.CloseKey;
              if sContentType <> '' then
                FMimeTypes.AddOrSetValue(LowerCase(keys[i]), sContentType);
            end;
          end;
        end;
      end;

      if reg.OpenKeyReadOnly('MIME\Database\Content Type') then
      begin
        reg.GetKeyNames(keys);
        reg.CloseKey;
        for i := 0  to keys.Count -1 do
        begin
          if reg.OpenKeyReadOnly(contentTypesKey + keys[i]) then
          begin
            sExt := reg.ReadString('Extension');
            reg.CloseKey;
            if sExt <> '' then
              FMimeTypes.AddOrSetValue(LowerCase(sExt), keys[i]);
          end;
        end;
      end;
    finally
      keys.Free;
    end;
  finally
    reg.Free;
  end;
end;

class constructor TMultipartFormData.Create;
begin
  FMimeTypes := TDictionary<string, string>.Create;
  AddDefaultMimeTypes;
  AddWindowsMimeTypes;


end;

constructor TMultipartFormData.Create;
begin
  FDataStream := TMemoryStream.Create;
  GenerateUniqueBoundry;
end;

class destructor TMultipartFormData.Destroy;
begin
  FMimeTypes.Free;
end;

destructor TMultipartFormData.Destroy;
begin
  if FDataStream <> nil then
    FDataStream.Free;
  inherited;
end;

function TMultipartFormData.Generate: TStream;
begin
  //add the final boundary
  WriteString('--' + FBoundary + '--');
  FDataStream.Seek(0,soFromBeginning); //this is required as the http request doesn't rewind the stream

  result := FDataStream;
//  FDataStream := nil;
  GenerateUniqueBoundry;
end;

procedure TMultipartFormData.GenerateUniqueBoundry;
begin
  FBoundary := '----------------------' + FormatDateTime('mmddyyhhnnsszzz', Now);
end;

function TMultipartFormData.GetBoundary: string;
begin
  result := FBoundary;
end;

function TMultipartFormData.GetContentType: string;
begin
  Result := 'multipart/form-data; boundary=' + FBoundary;
end;

function TMultipartFormData.GetMimeType(const fileName: string): string;
var
  ext : string;
begin
  ext := LowerCase(ExtractFileExt(fileName));
  if not TMultipartFormData.FMimeTypes.TryGetValue(ext, result) then
    result := 'application/octet-stream';//default to this if we can't figure it out.
end;

procedure TMultipartFormData.WriteString(const value: string);
var
  bytes: TBytes;
begin
  bytes := TEncoding.UTF8.GetBytes(value + #13#10);
  //in XE2, using WriteBuffer(bytes, does not work (works in XE7 though).
  FDataStream.WriteBuffer(bytes[0], Length(bytes));
end;
end.
