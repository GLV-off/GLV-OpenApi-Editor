unit Editor_UiUtils;

{$I 'editor.inc'}

interface

procedure ShowFileNotSuported;

function FileSuported(const APath: string): Boolean;

implementation

uses
  SysUtils,
  Dialogs;

procedure ShowFileNotSuported;
begin
  ShowMessage('Открываемый файл не поддерживается!');
end;

function FileSuported(const APath: string): Boolean;
var
  Ext: string;
begin
  Ext := ExtractFileExt(APath);
  Result := Ext = 'json';
end;

end.

