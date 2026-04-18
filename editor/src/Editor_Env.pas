unit Editor_Env;

{$I 'editor.inc'}

interface

type
  TEnv = class
  public
    class function Root: string; static;

    class function AssetDir: string; static;

    class function Asset(const AName: string): string; static;

    class function EditorFont: string; static;

    class function EditorFontFIlename: string; static;

    class function ConfigFilepath: string; static;
  end;

implementation

uses
  SysUtils;

class function TEnv.Root: string;
begin
  Result := ExtractFilePath(ParamStr(0));
end;

class function TEnv.AssetDir: string;
begin
  Result := Root() + '\asset';
end;

class function TEnv.Asset(const AName: string): string;
begin
  Result := AssetDir() + '\' + AName;
end;

class function TEnv.EditorFont: string;
const
  ASSET_FILEPATH_FONT: string = 'BigBlueTermPlus Nerd Font';
begin
  Result := ASSET_FILEPATH_FONT;
end;

class function TEnv.EditorFontFIlename: string;
begin
  Result := Asset('BigBlueTermPlus Nerd Font');
end;

class function TEnv.ConfigFilepath: string;
begin
  Result := Root() + 'cfg.ini';
end;

end.

