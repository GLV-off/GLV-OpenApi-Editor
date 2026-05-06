unit Editor_UiUtils;

{$I 'editor.inc'}

interface

procedure ShowFileNotSuported;

function FileSuported(const APath: string): Boolean;

implementation

uses
  SysUtils,
  Dialogs,
  Editor_Localization;

procedure ShowFileNotSuported;
begin
  ShowMessage(RC_FILE_NOT_SUPPORTED);
end;

function FileSuported(const APath: string): Boolean;
var
  Ext: string;
begin
  Ext := ExtractFileExt(APath);
  Result := Ext = '.json';
end;

end.

