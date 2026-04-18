unit Editor_Cfg_Ini;

{$I 'editor.inc'}

interface

uses
  IniFiles,
  Editor_Cfg;

type
  TIniCfg = class(TCfg)
  strict private
    FIni: TCustomIniFile;
    FFilename: string;
  strict protected
    function GetLastOpenedFile: string; override;
    procedure SetLastOpenedFile(const AValue: string); override;
  public
    constructor Create(const AIni: TCustomIniFile; const AFilename: string); overload;
    constructor Create(const AFilename: string); overload;
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils;

const
  CFG_ROOT: string = 'cfg';
  CFG_LAST_OPENED: string = 'last_opened';

constructor TIniCfg.Create(const AIni: TCustomIniFile; const AFilename: string);
begin
  inherited Create;
  FIni := AIni;
  FFilename := AFilename;
end;

constructor TIniCfg.Create(const AFilename: string);
begin
  Self.Create(TIniFile.Create(AFilename), AFilename);
end;

destructor TIniCfg.Destroy;
begin
  FreeAndNil(FIni);
  FFilename := '';
  inherited Destroy;
end;

function TIniCfg.GetLastOpenedFile: string;
begin
  Result := FIni.ReadString(CFG_ROOT, CFG_LAST_OPENED, '');
end;

procedure TIniCfg.SetLastOpenedFile(const AValue: string);
begin
  FIni.WriteString(CFG_ROOT, CFG_LAST_OPENED, AValue);
end;

end.

