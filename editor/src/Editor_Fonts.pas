unit Editor_Fonts;

{$I 'editor.inc'}

interface

function FontInstalled(const AFont: string): Boolean;
procedure FontLoad(const AFile: string);
procedure FontUnload(const AFile: string);

implementation

function FontInstalled(const AFont: string): Boolean;
begin
  Result := False;
end;

procedure FontLoad(const AFile: string);
begin

end;

procedure FontUnload(const AFile: string);
begin

end;

end.

