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
  Result := FIni.ReadString('cfg', 'last_opened', '');
end;

procedure TIniCfg.SetLastOpenedFile(const AValue: string);
begin
  FIni.WriteString('cfg', 'last_opened', AValue);
end;

end.

